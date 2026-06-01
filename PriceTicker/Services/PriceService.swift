import Foundation
import Combine

class PriceService: ObservableObject {
    @Published var prices: [UUID: TickerPrice] = [:]
    @Published var errors: [UUID: String] = [:]
    @Published var lastUpdated: [UUID: Date] = [:]
    @Published var isConnected: Bool = true

    /// Fires once per fetch cycle on the first successful ticker response.
    /// Consumers (e.g. AppDelegate) use this to trigger a heartbeat pulse.
    let fetchPulse = PassthroughSubject<Void, Never>()

    private let store: TickerStore
    private var timerCancellable: AnyCancellable?
    private var storeCancellable: AnyCancellable?
    private var proxyCancellable: AnyCancellable?
    private var networkCancellable: AnyCancellable?
    /// One entry per ticker — assigning a new value cancels the previous in-flight request.
    private var fetchTasks: [UUID: AnyCancellable] = [:]

    private let session = NetworkSession.shared
    private let decoder = JSONDecoder()

    // MARK: - Backoff
    // Tracks consecutive fetch *cycles* (not individual ticker failures) that had
    // at least one failure. With N tickers, all can fail in one cycle but streak
    // only increments once. Resets to 0 on any success.
    // Interval: 5s -> 10s -> 20s -> 30s (capped).
    private var failureStreak = 0
    private var cycleHadSuccess = false   // true if any ticker succeeded this cycle
    private var currentInterval: TimeInterval = 5
    private let minInterval: TimeInterval = 5
    private let maxInterval: TimeInterval = 30

    private func backoffInterval() -> TimeInterval {
        min(minInterval * pow(2.0, Double(min(failureStreak, 4))), maxInterval)
    }

    deinit {
        cancelAllFetches()
    }

    // MARK: - Init

    init(store: TickerStore) {
        self.store = store

        storeCancellable = store.$tickers
            .map { $0.map { "\($0.id)\($0.symbol)\($0.marketType.rawValue)" } }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.syncPollingWithWatchlist()
            }

        isConnected = NetworkStatus.shared.isConnected
        networkCancellable = NetworkStatus.shared.$isConnected
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in self?.handleConnectivityChanged(connected) }

        proxyCancellable = NotificationCenter.default
            .publisher(for: ProxySettings.didApplyNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleNetworkSettingsChanged() }

        syncPollingWithWatchlist()
    }

    private func handleConnectivityChanged(_ connected: Bool) {
        isConnected = connected
        if connected {
            // Reset backoff when connectivity is restored.
            failureStreak = 0
            resumePollingIfNeeded(fetchImmediately: true)
        } else {
            stopTimer()
            cancelAllFetches()
        }
    }

    // MARK: - Timer

    private func startTimer(interval: TimeInterval) {
        guard isConnected, !store.tickers.isEmpty else { return }
        guard timerCancellable == nil else { return }
        currentInterval = interval
        timerCancellable = Timer
            .publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchAll() }
    }

    /// Restart with a new interval only when the interval actually changes.
    private func restartTimer(interval: TimeInterval) {
        guard interval != currentInterval || timerCancellable == nil else { return }
        timerCancellable = nil
        startTimer(interval: interval)
    }

    private func stopTimer() {
        timerCancellable = nil
    }

    private func resumePollingIfNeeded(fetchImmediately: Bool) {
        guard isConnected, !store.tickers.isEmpty else {
            stopTimer()
            return
        }
        restartTimer(interval: minInterval)
        if fetchImmediately {
            fetchAll()
        }
    }

    private func syncPollingWithWatchlist() {
        pruneRemovedTickerState()
        guard !store.tickers.isEmpty else {
            stopTimer()
            cancelAllFetches()
            return
        }
        resumePollingIfNeeded(fetchImmediately: isConnected)
    }

    private func handleNetworkSettingsChanged() {
        failureStreak = 0
        resumePollingIfNeeded(fetchImmediately: true)
    }

    private func cancelAllFetches() {
        fetchTasks.values.forEach { $0.cancel() }
        fetchTasks.removeAll()
    }

    private func pruneRemovedTickerState() {
        let liveIDs = Set(store.tickers.map(\.id))
        for id in fetchTasks.keys where !liveIDs.contains(id) {
            fetchTasks[id]?.cancel()
            fetchTasks.removeValue(forKey: id)
            prices.removeValue(forKey: id)
            errors.removeValue(forKey: id)
            lastUpdated.removeValue(forKey: id)
        }
    }

    // MARK: - Fetch

    private func fetchAll() {
        guard isConnected, !store.tickers.isEmpty else { return }
        cycleHadSuccess = false
        store.tickers.forEach { fetch($0) }
    }

    private func fetch(_ ticker: Ticker) {
        guard var components = URLComponents(string: ticker.marketType.apiBase) else { return }
        components.queryItems = [URLQueryItem(name: "symbol", value: ticker.symbol.uppercased())]
        guard let url = components.url else { return }

        fetchTasks[ticker.id] = session.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: BinanceTicker24h.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case .failure(let err) = completion {
                        guard self.isConnected else { return }
                        self.errors[ticker.id] = err.localizedDescription
                        // Only increment once per cycle (after all tickers have reported).
                        if !self.cycleHadSuccess {
                            self.failureStreak += 1
                            self.restartTimer(interval: self.backoffInterval())
                        }
                    }
                },
                receiveValue: { [weak self] result in
                    guard let self else { return }
                    self.errors.removeValue(forKey: ticker.id)
                    self.prices[ticker.id] = TickerPrice(
                        price: Double(result.lastPrice) ?? 0,
                        changePercent: Double(result.priceChangePercent) ?? 0,
                        priceDisplay: result.lastPrice
                    )
                    self.lastUpdated[ticker.id] = Date()
                    // First success in a cycle: fire the heartbeat pulse signal.
                    if !self.cycleHadSuccess {
                        self.fetchPulse.send()
                    }
                    self.cycleHadSuccess = true
                    if self.failureStreak > 0 {
                        self.failureStreak = 0
                        self.restartTimer(interval: self.minInterval)
                    }
                }
            )
    }
}

// MARK: - Binance Response

private struct BinanceTicker24h: Decodable {
    let lastPrice: String
    let priceChangePercent: String
}

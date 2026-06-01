import Foundation
import Combine

/// Fetches 24 × 1h klines for the menu bar sparkline.
/// Refreshes every 5 minutes — the current candle's close changes gradually,
/// and a 44 pt sparkline has no meaningful visual delta at sub-minute resolution.
class BtcSparklineService: ObservableObject {
    @Published var prices: [Double] = []
    @Published var lastPriceDisplay: String = ""   // raw string from last kline close

    private var timer: AnyCancellable?
    private var task: AnyCancellable?
    private var proxyCancellable: AnyCancellable?
    private var networkCancellable: AnyCancellable?
    private var isStarted = false
    private var isConnected = NetworkStatus.shared.isConnected

    private let url = URL(string:
        "https://fapi.binance.com/fapi/v1/klines?symbol=BTCUSDT&interval=1h&limit=24")!

    // Backoff: 5 min normal, up to 40 min on failure.
    private var failureStreak = 0
    private var currentInterval: TimeInterval = 300
    private let minInterval: TimeInterval = 300
    private let maxInterval: TimeInterval = 2400

    private func backoffInterval() -> TimeInterval {
        min(minInterval * pow(2.0, Double(min(failureStreak, 3))), maxInterval)
    }

    init() {
        proxyCancellable = NotificationCenter.default
            .publisher(for: ProxySettings.didApplyNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleNetworkSettingsChanged() }

        networkCancellable = NetworkStatus.shared.$isConnected
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in self?.handleConnectivityChanged(connected) }
    }

    func start() {
        isStarted = true
        guard isConnected else { return }
        fetch()
        startTimer(interval: minInterval)
    }

    func stop() {
        isStarted = false
        timer = nil
        task?.cancel()
        task = nil
    }

    private func startTimer(interval: TimeInterval) {
        guard isStarted, isConnected else { return }
        guard interval != currentInterval || timer == nil else { return }
        currentInterval = interval
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetch() }
    }

    private func handleNetworkSettingsChanged() {
        guard isStarted, isConnected else { return }
        failureStreak = 0
        startTimer(interval: minInterval)
        fetch()
    }

    private func handleConnectivityChanged(_ connected: Bool) {
        isConnected = connected
        guard isStarted else { return }
        if connected {
            failureStreak = 0
            startTimer(interval: minInterval)
            fetch()
        } else {
            timer = nil
            task?.cancel()
            task = nil
        }
    }

    private func fetch() {
        guard isStarted, isConnected else { return }
        task = NetworkSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> [(Double, String)] in
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                    throw URLError(.cannotParseResponse)
                }
                // Index 4 is the close price string
                return rows.compactMap { row -> (Double, String)? in
                    guard row.count > 4, let s = row[4] as? String,
                          let d = Double(s) else { return nil }
                    return (d, s)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case .failure = completion {
                        guard self.isConnected else { return }
                        self.failureStreak += 1
                        self.startTimer(interval: self.backoffInterval())
                    }
                },
                receiveValue: { [weak self] pairs in
                    guard let self else { return }
                    // Set lastPriceDisplay first — AppDelegate's $prices subscriber reads it
                    // synchronously, so it must be up-to-date before prices is published.
                    self.lastPriceDisplay = pairs.last.map(\.1) ?? ""
                    self.prices = pairs.map(\.0)
                    if self.failureStreak > 0 {
                        self.failureStreak = 0
                        self.startTimer(interval: self.minInterval)
                    }
                }
            )
    }
}

import Foundation
import Combine
import Network

/// Shared network layer. Exposes `dataTaskPublisher` so callers are decoupled
/// from URLSession directly — this lets us rebuild the session transparently
/// when proxy settings change without touching any call site.
final class NetworkSession {
    static let shared = NetworkSession()

    private var urlSession: URLSession = NetworkSession.buildSession()

    private init() {}

    /// Called by ProxySettings.apply() after new settings are saved.
    /// Invalidates the old session first to release its connection pool.
    func rebuild() {
        urlSession.invalidateAndCancel()
        urlSession = NetworkSession.buildSession()
    }

    func dataTaskPublisher(for url: URL) -> URLSession.DataTaskPublisher {
        urlSession.dataTaskPublisher(for: url)
    }

    private static func buildSession() -> URLSession {
        let s = ProxySettings.shared
        let config = URLSessionConfiguration.ephemeral
        if !AppEnvironment.isRunningTests {
            config.connectionProxyDictionary = makeProxyDictionary(
                useProxy: s.useProxy,
                host: s.host,
                port: s.port
            )
        }
        config.timeoutIntervalForRequest  = 8
        config.timeoutIntervalForResource = 12
        return URLSession(configuration: config)
    }

    /// CFNetwork expects CFString keys with CFString/CFNumber values. Converting
    /// these explicitly avoids ambiguous Swift bridging on older macOS releases.
    static func makeProxyDictionary(
        useProxy: Bool,
        host: String,
        port: Int
    ) -> [AnyHashable: Any]? {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard useProxy, !trimmedHost.isEmpty, (1...65535).contains(port) else {
            return nil
        }

        let enabled = NSNumber(value: true)
        let proxyPort = NSNumber(value: port)
        let proxyHost = NSString(string: trimmedHost)
        return [
            kCFNetworkProxiesHTTPEnable as String: enabled,
            kCFNetworkProxiesHTTPProxy as String: proxyHost,
            kCFNetworkProxiesHTTPPort as String: proxyPort,
            kCFNetworkProxiesHTTPSEnable as String: enabled,
            kCFNetworkProxiesHTTPSProxy as String: proxyHost,
            kCFNetworkProxiesHTTPSPort as String: proxyPort,
        ]
    }
}

final class NetworkStatus: ObservableObject {
    static let shared = NetworkStatus()

    @Published private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.priceticker.network-status")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

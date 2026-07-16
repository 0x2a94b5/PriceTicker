import CoreGraphics
import CFNetwork
import XCTest
@testable import PriceTicker

final class TickerTests: XCTestCase {
    func testFormatBinancePriceTrimsTrailingZeros() {
        XCTAssertEqual(formatBinancePrice("1.1900000"), "$1.19")
        XCTAssertEqual(formatBinancePrice("42.000"), "$42")
        XCTAssertEqual(formatBinancePrice("0.0011575"), "$0.0011575")
    }

    func testFormatBinancePriceHandlesMissingAndUnusualValues() {
        XCTAssertEqual(formatBinancePrice(""), "--")
        XCTAssertEqual(formatBinancePrice("not-a-price"), "$not-a-price")
    }

    func testWindowPositionRoundTrip() {
        var ticker = Ticker(
            symbol: "BTCUSDT",
            displayName: "BTC",
            marketType: .spot
        )

        ticker.windowPosition = CGPoint(x: 120.5, y: 88.25)

        XCTAssertEqual(ticker.windowX, 120.5)
        XCTAssertEqual(ticker.windowY, 88.25)
        XCTAssertEqual(ticker.windowPosition, CGPoint(x: 120.5, y: 88.25))
    }

    func testMarketEndpointsUseHTTPS() {
        for market in Ticker.MarketType.allCases {
            XCTAssertTrue(market.apiBase.hasPrefix("https://"))
            XCTAssertTrue(market.apiBase.hasSuffix("/ticker/24hr"))
        }
    }

    func testProxyDictionaryUsesCFNetworkCompatibleTypes() throws {
        let dictionary = try XCTUnwrap(NetworkSession.makeProxyDictionary(
            useProxy: true,
            host: " 127.0.0.1 ",
            port: 7890
        ))

        XCTAssertEqual(
            (dictionary[kCFNetworkProxiesHTTPEnable as String] as? NSNumber)?.boolValue,
            true
        )
        XCTAssertEqual(
            (dictionary[kCFNetworkProxiesHTTPProxy as String] as? NSString) as String?,
            "127.0.0.1"
        )
        XCTAssertEqual(
            (dictionary[kCFNetworkProxiesHTTPPort as String] as? NSNumber)?.intValue,
            7890
        )
    }

    func testProxyDictionaryRejectsInvalidConfiguration() {
        XCTAssertNil(NetworkSession.makeProxyDictionary(
            useProxy: false,
            host: "127.0.0.1",
            port: 7890
        ))
        XCTAssertNil(NetworkSession.makeProxyDictionary(
            useProxy: true,
            host: "   ",
            port: 7890
        ))
        XCTAssertNil(NetworkSession.makeProxyDictionary(
            useProxy: true,
            host: "127.0.0.1",
            port: 70_000
        ))
    }
}

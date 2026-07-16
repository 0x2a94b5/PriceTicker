import Foundation

enum AppEnvironment {
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["PRICETICKER_TESTING"] == "1"
    }
}

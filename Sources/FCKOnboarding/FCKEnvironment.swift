import Foundation
import UIKit

/// Environment detection for automatic sandbox/production routing
public enum FCKEnvironment {
    case production
    case sandbox

    /// Automatic detection based on build configuration and environment
    public static var current: FCKEnvironment {
        // Check for Xcode Preview
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return .sandbox
        }

        // Check for debug build
        #if DEBUG
        return .sandbox
        #else
        // Check for TestFlight or sandbox receipt
        if isTestFlightBuild() || isSandboxReceipt() {
            return .sandbox
        }
        return .production
        #endif
    }

    /// Check if running in TestFlight
    private static func isTestFlightBuild() -> Bool {
        // Check for sandbox receipt
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }

        // TestFlight builds have "sandboxReceipt" in the path
        let receiptPath = receiptURL.path
        return receiptPath.contains("sandboxReceipt")
    }

    /// Check if app has sandbox receipt (development/TestFlight)
    private static func isSandboxReceipt() -> Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }

        // Check if file exists
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: receiptURL.path) {
            // No receipt = likely development build
            return true
        }

        // Check receipt URL for sandbox indicator
        return receiptURL.lastPathComponent == "sandboxReceipt"
    }

    /// Check if running in simulator
    private static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// The base URL for API calls (same for both environments)
    public var baseURL: String {
        return "https://fckonboarding.com"
    }

    /// Headers to include with API requests
    public var headers: [String: String] {
        var headers = [
            "X-Environment": self == .sandbox ? "sandbox" : "production",
            "X-SDK-Version": FCKOnboarding.version,
            "X-Platform": "ios",
            "X-Device-Model": UIDevice.current.model,
            "X-OS-Version": UIDevice.current.systemVersion
        ]

        // Add app version if available
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers["X-App-Version"] = appVersion
        }

        // Add build number if available
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            headers["X-App-Build"] = buildNumber
        }

        // Add simulator flag if running in simulator
        if Self.isSimulator() {
            headers["X-Is-Simulator"] = "true"
        }

        return headers
    }

    /// Display name for debugging
    public var displayName: String {
        switch self {
        case .production:
            return "Production"
        case .sandbox:
            return "Sandbox"
        }
    }

    /// Log current environment details (for debugging)
    public static func logEnvironmentInfo() {
        let env = FCKEnvironment.current
        print("🌍 FCKOnboarding Environment:")
        print("  - Mode: \(env.displayName)")
        print("  - Debug Build: \(isDebugBuild())")
        print("  - TestFlight: \(isTestFlightBuild())")
        print("  - Simulator: \(isSimulator())")
        print("  - Headers: \(env.headers)")
    }

    private static func isDebugBuild() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
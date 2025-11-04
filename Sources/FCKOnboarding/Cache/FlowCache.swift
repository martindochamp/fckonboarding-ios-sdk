import Foundation

/// Cache manager for storing flows locally
public class FlowCache {
    private let userDefaults: UserDefaults
    private let cacheKey = "com.fckonboarding.cachedFlow"
    private let versionKey = "com.fckonboarding.cachedFlowVersion"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Save flow to cache
    public func saveFlow(_ flow: FlowResponse) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(flow)
        userDefaults.set(data, forKey: cacheKey)
        userDefaults.set(flow.version, forKey: versionKey)
        userDefaults.synchronize()
    }

    /// Load cached flow
    public func loadFlow() throws -> FlowResponse? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(FlowResponse.self, from: data)
    }

    /// Get cached flow version
    public func getCachedVersion() -> Int? {
        let version = userDefaults.integer(forKey: versionKey)
        return version > 0 ? version : nil
    }

    /// Clear cached flow
    public func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
        userDefaults.removeObject(forKey: versionKey)
        userDefaults.synchronize()
    }

    /// Check if cached flow is stale (optional future enhancement)
    public func isCacheStale(maxAge: TimeInterval = 86400) -> Bool {
        // Could add timestamp tracking here
        return false
    }
}

/// UserDefaults extension for onboarding state
public extension UserDefaults {
    private static let completedKey = "com.fckonboarding.completed"
    private static let responsesKey = "com.fckonboarding.responses"

    /// Check if user has completed onboarding
    var hasCompletedOnboarding: Bool {
        get { bool(forKey: Self.completedKey) }
        set { set(newValue, forKey: Self.completedKey) }
    }

    /// Get user responses from onboarding
    var onboardingResponses: [String: String] {
        get {
            (dictionary(forKey: Self.responsesKey) as? [String: String]) ?? [:]
        }
        set {
            set(newValue, forKey: Self.responsesKey)
        }
    }

    /// Reset onboarding state
    func resetOnboarding() {
        removeObject(forKey: Self.completedKey)
        removeObject(forKey: Self.responsesKey)
        synchronize()
    }
}

import Foundation

/// Main SDK class for FCKOnboarding
public class FCKOnboarding {
    public static let shared = FCKOnboarding()

    private var apiClient: FCKAPIClient?
    private let cache = FlowCache()
    private var currentPlacementResponse: PlacementFlowResponse?
    private var customUserId: String?

    public enum CachePolicy {
        case cacheFirst    // Try cache first, fallback to network
        case networkFirst  // Try network first, fallback to cache
        case networkOnly   // Always fetch from network
    }

    private var cachePolicy: CachePolicy = .cacheFirst

    private init() {}

    /// Configure the SDK with your API key
    public static func configure(
        apiKey: String,
        environment: FCKAPIClient.Environment = .production,
        cachePolicy: CachePolicy = .cacheFirst
    ) {
        shared.apiClient = FCKAPIClient(
            apiKey: apiKey,
            environment: environment
        )
        shared.cachePolicy = cachePolicy
    }

    /// Set custom user ID (optional - defaults to device ID)
    public func setUserId(_ userId: String?) {
        customUserId = userId
    }

    /// Fetch flow for a placement
    /// Returns nil if user has completed or is in holdout group
    public func fetchFlow(
        for placement: String = "main",
        userProperties: [String: Any]? = nil
    ) async throws -> PlacementFlowResponse? {
        guard let apiClient = apiClient else {
            throw FCKError.notConfigured
        }

        let response = try await apiClient.fetchFlowForPlacement(
            placement,
            userId: customUserId,
            userProperties: userProperties
        )

        currentPlacementResponse = response
        return response
    }

    /// Present onboarding if needed
    /// Returns flow config if should be shown, nil if completed or in holdout
    @MainActor
    public func presentIfNeeded(
        for placement: String = "main",
        userProperties: [String: Any]? = nil
    ) async throws -> FlowConfig? {
        // Fetch flow for placement
        let response = try await fetchFlow(for: placement, userProperties: userProperties)

        // User completed or in holdout
        guard let flowConfig = response?.config else {
            return nil
        }

        return flowConfig
    }

    /// Check if user has completed onboarding (from backend)
    public func checkCompletion() async throws -> Bool {
        guard let apiClient = apiClient else {
            throw FCKError.notConfigured
        }

        let response = try await apiClient.checkCompletion(userId: customUserId)
        return response.completed
    }

    /// Mark onboarding as completed (syncs with backend)
    public func markCompleted() async {
        guard let apiClient = apiClient else {
            return
        }

        do {
            try await apiClient.recordCompletion(
                userId: customUserId,
                flowId: currentPlacementResponse?.flowId,
                placementId: currentPlacementResponse?.placementId,
                campaignId: currentPlacementResponse?.campaignId,
                variantId: currentPlacementResponse?.variantId,
                responses: getUserResponses()
            )

            // Also mark locally for offline access
            UserDefaults.standard.hasCompletedOnboarding = true

            // Track completion event
            if let flowId = currentPlacementResponse?.flowId {
                try? await trackEvent(name: "flow_completed", flowId: flowId)
            }
        } catch {
            print("Failed to record completion: \(error)")
        }
    }

    /// Get user responses from onboarding
    public func getUserResponses() -> [String: String] {
        return UserDefaults.standard.onboardingResponses
    }

    /// Save a user response
    public func saveResponse(key: String, value: String) {
        var responses = UserDefaults.standard.onboardingResponses
        responses[key] = value
        UserDefaults.standard.onboardingResponses = responses
    }

    /// Reset onboarding state (for testing)
    public func reset() {
        UserDefaults.standard.resetOnboarding()
        cache.clearCache()
        currentPlacementResponse = nil
    }

    /// Track analytics event
    public func trackEvent(
        name: String,
        flowId: String? = nil,
        screenId: String? = nil,
        properties: [String: Any]? = nil
    ) async throws {
        guard let apiClient = apiClient else {
            throw FCKError.notConfigured
        }

        let finalFlowId = flowId ?? currentPlacementResponse?.flowId
        try await apiClient.trackEvent(
            eventName: name,
            flowId: finalFlowId,
            screenId: screenId,
            properties: properties
        )
    }
}

/// SDK errors
public enum FCKError: Error, LocalizedError {
    case notConfigured

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "FCKOnboarding not configured. Call FCKOnboarding.configure() first."
        }
    }
}

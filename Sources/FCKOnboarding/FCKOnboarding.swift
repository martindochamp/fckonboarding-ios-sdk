import Foundation

/// Main SDK class for FCKOnboarding
public class FCKOnboarding {
    public static let shared = FCKOnboarding()

    private var apiClient: FCKAPIClient?
    private let cache = FlowCache()
    private var currentFlow: FlowResponse?

    public enum CachePolicy {
        case cacheFirst    // Try cache first, fallback to network
        case networkFirst  // Try network first, fallback to cache
        case networkOnly   // Always fetch from network
    }

    private var cachePolicy: CachePolicy = .cacheFirst

    private init() {}

    /// Configure the SDK with your project credentials
    public static func configure(
        projectId: String,
        apiKey: String? = nil,
        environment: FCKAPIClient.Environment = .production,
        cachePolicy: CachePolicy = .cacheFirst
    ) {
        shared.apiClient = FCKAPIClient(
            projectId: projectId,
            apiKey: apiKey,
            environment: environment
        )
        shared.cachePolicy = cachePolicy
    }

    /// Fetch the active onboarding flow
    public func fetchFlow() async throws -> FlowResponse {
        guard let apiClient = apiClient else {
            throw FCKError.notConfigured
        }

        switch cachePolicy {
        case .cacheFirst:
            // Try cache first
            if let cached = try? cache.loadFlow() {
                currentFlow = cached
                // Fetch new version in background
                Task {
                    try? await fetchFromNetwork()
                }
                return cached
            }
            // Cache miss, fetch from network
            return try await fetchFromNetwork()

        case .networkFirst:
            do {
                return try await fetchFromNetwork()
            } catch {
                // Network failed, try cache
                if let cached = try? cache.loadFlow() {
                    currentFlow = cached
                    return cached
                }
                throw error
            }

        case .networkOnly:
            return try await fetchFromNetwork()
        }
    }

    private func fetchFromNetwork() async throws -> FlowResponse {
        guard let apiClient = apiClient else {
            throw FCKError.notConfigured
        }

        let flow = try await apiClient.fetchActiveFlow()
        currentFlow = flow

        // Cache the flow
        try? cache.saveFlow(flow)

        // Track fetch event
        try? await trackEvent(name: "flow_fetched", flowId: flow.flowId)

        return flow
    }

    /// Check if user has completed onboarding
    public func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.hasCompletedOnboarding
    }

    /// Mark onboarding as completed
    public func markCompleted() {
        UserDefaults.standard.hasCompletedOnboarding = true

        // Track completion
        if let flowId = currentFlow?.flowId {
            Task {
                try? await trackEvent(name: "flow_completed", flowId: flowId)
            }
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
        currentFlow = nil
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

        let finalFlowId = flowId ?? currentFlow?.flowId
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

import Foundation
import UIKit

/// API client for fetching onboarding flows
public class FCKAPIClient {
    private let apiKey: String
    private let session: URLSession
    private let environment: FCKEnvironment
    private let debugMode: Bool

    public enum APIError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError(Error)
        case networkError(Error)
        case serverError(Int, String?)
        case noActiveFlow
        case usageLimitExceeded

        public var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .noData:
                return "No data received from server"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .serverError(let code, let message):
                return "Server error (\(code)): \(message ?? "Unknown error")"
            case .noActiveFlow:
                return "No active onboarding flow found"
            case .usageLimitExceeded:
                return "Usage limit exceeded. Please upgrade your plan."
            }
        }
    }

    public init(apiKey: String, debugMode: Bool = false) {
        self.apiKey = apiKey
        self.debugMode = debugMode
        self.environment = FCKEnvironment.current

        // Configure URLSession - disable caching on simulator for development
        #if targetEnvironment(simulator)
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        if debugMode {
            print("🔧 [FCKOnboarding] Running on SIMULATOR - All caching disabled")
        }
        #else
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,  // 10 MB
            diskCapacity: 50 * 1024 * 1024,     // 50 MB
            diskPath: "FCKOnboardingCache"
        )
        if debugMode {
            print("📱 [FCKOnboarding] Running on DEVICE - Caching enabled")
        }
        #endif

        self.session = URLSession(configuration: config)

        if debugMode {
            FCKEnvironment.logEnvironmentInfo()
        }
    }

    /// Fetch flow for a specific placement
    public func fetchFlow(
        placement: String = "main",
        userId: String? = nil,
        deviceId: String? = nil,
        userProperties: [String: Any]? = nil
    ) async throws -> PlacementFlowResponse {
        // Build URL with query parameters
        var components = URLComponents(string: "\(environment.baseURL)/api/sdk/placement/\(placement)")
        guard components != nil else {
            throw APIError.invalidURL
        }

        var queryItems: [URLQueryItem] = []

        // Add userId or deviceId as query parameters (at least one is required)
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "userId", value: userId))
        }
        if let deviceId = deviceId {
            queryItems.append(URLQueryItem(name: "deviceId", value: deviceId))
        }

        // Add user properties as JSON in query param if provided
        if let properties = userProperties,
           let jsonData = try? JSONSerialization.data(withJSONObject: properties),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            queryItems.append(URLQueryItem(name: "userProperties", value: jsonString))
        }

        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add headers
        var headers = environment.headers
        headers["X-API-Key"] = apiKey
        request.allHTTPHeaderFields = headers

        if debugMode {
            print("🌐 FCKOnboarding API Request:")
            print("  - URL: \(url.absoluteString)")
            print("  - Environment: \(environment.displayName)")
            print("  - Placement: \(placement)")
            print("  - UserId: \(userId ?? "nil")")
            print("  - DeviceId: \(deviceId ?? "nil")")
            print("  - Headers: \(headers)")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(URLError(.badServerResponse))
            }

            if debugMode {
                print("📡 FCKOnboarding API Response:")
                print("  - Status: \(httpResponse.statusCode)")
                print("  - Data size: \(data.count) bytes")
            }

            // Handle specific status codes
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                do {
                    let flowResponse = try decoder.decode(PlacementFlowResponse.self, from: data)

                    // Check if it's a "no flow" response
                    if flowResponse.flowId == nil && flowResponse.message != nil {
                        if debugMode {
                            print("ℹ️ No flow available: \(flowResponse.message ?? "")")
                        }
                        throw APIError.noActiveFlow
                    }

                    return flowResponse
                } catch {
                    if debugMode {
                        print("❌ Decoding error: \(error)")
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("Raw response: \(jsonString)")
                        }
                    }
                    throw APIError.decodingError(error)
                }

            case 401:
                throw APIError.serverError(401, "Invalid API key")
            case 404:
                throw APIError.noActiveFlow
            case 429:
                throw APIError.usageLimitExceeded
            default:
                let message = String(data: data, encoding: .utf8)
                throw APIError.serverError(httpResponse.statusCode, message)
            }
        } catch {
            if error is APIError {
                throw error
            }
            throw APIError.networkError(error)
        }
    }

    /// Mark onboarding as completed
    public func markCompleted(
        userId: String? = nil,
        deviceId: String? = nil,
        flowId: String? = nil,
        responses: [String: Any]? = nil
    ) async throws {
        let urlString = "\(environment.baseURL)/api/sdk/completion"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Add headers
        var headers = environment.headers
        headers["X-API-Key"] = apiKey
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers

        // Build request body - ensure at least userId or deviceId is present
        var body: [String: Any] = [:]
        if let userId = userId {
            body["userId"] = userId
        }
        if let deviceId = deviceId {
            body["deviceId"] = deviceId
        }
        if let flowId = flowId {
            body["flowId"] = flowId
        }
        if let responses = responses {
            body["responses"] = responses
        }

        // Validate that we have at least userId or deviceId
        if body["userId"] == nil && body["deviceId"] == nil {
            throw APIError.serverError(400, "Missing required parameter: userId or deviceId")
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        if debugMode {
            print("📤 Marking onboarding completed:")
            print("  - User ID: \(userId ?? "N/A")")
            print("  - Device ID: \(deviceId ?? "N/A")")
            print("  - Flow ID: \(flowId ?? "N/A")")
        }

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode != 200 {
            throw APIError.serverError(httpResponse.statusCode, "Failed to mark completion")
        }

        if debugMode {
            print("✅ Onboarding marked as completed")
        }
    }

    /// Track analytics event
    public func trackEvent(
        eventType: String,
        userId: String? = nil,
        sessionId: String? = nil,
        flowId: String? = nil,
        screenIndex: Int? = nil,
        metadata: [String: Any]? = nil
    ) async throws {
        let urlString = "\(environment.baseURL)/api/sdk/events"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Add headers
        var headers = environment.headers
        headers["X-API-Key"] = apiKey
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers

        // Build event body
        var body: [String: Any] = [
            "eventType": eventType,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        if let userId = userId {
            body["userId"] = userId
        }
        if let sessionId = sessionId {
            body["sessionId"] = sessionId
        }
        if let flowId = flowId {
            body["flowId"] = flowId
        }
        if let screenIndex = screenIndex {
            body["screenIndex"] = screenIndex
        }
        if let metadata = metadata {
            body["metadata"] = metadata
        }

        // Add device info
        body["platform"] = "ios"
        body["deviceInfo"] = [
            "osVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.model,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Fire and forget - don't wait for response
        Task {
            do {
                let (_, response) = try await session.data(for: request)
                if debugMode, let httpResponse = response as? HTTPURLResponse {
                    print("📊 Event tracked: \(eventType) - Status: \(httpResponse.statusCode)")
                }
            } catch {
                if debugMode {
                    print("⚠️ Failed to track event: \(error)")
                }
            }
        }
    }
}
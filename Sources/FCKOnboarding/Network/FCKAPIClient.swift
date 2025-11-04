import Foundation

/// API client for fetching onboarding flows
public class FCKAPIClient {
    private let baseURL: String
    private let projectId: String
    private let apiKey: String?
    private let session: URLSession

    public enum Environment {
        case production
        case staging
        case custom(String)

        var baseURL: String {
            switch self {
            case .production:
                return "https://fckonboarding.com/api/sdk"
            case .staging:
                return "https://staging.fckonboarding.com/api/sdk"
            case .custom(let url):
                return url
            }
        }
    }

    public enum APIError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError(Error)
        case networkError(Error)
        case serverError(Int, String?)
        case noActiveFlow

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
                return "No active onboarding flow found for this project"
            }
        }
    }

    public init(
        projectId: String,
        apiKey: String? = nil,
        environment: Environment = .production,
        session: URLSession = .shared
    ) {
        self.projectId = projectId
        self.apiKey = apiKey
        self.baseURL = environment.baseURL
        self.session = session
    }

    /// Fetch the active onboarding flow for the configured project
    public func fetchActiveFlow() async throws -> FlowResponse {
        var components = URLComponents(string: "\(baseURL)/flows/active")
        components?.queryItems = [
            URLQueryItem(name: "projectId", value: projectId)
        ]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                let flowResponse = try decoder.decode(FlowResponse.self, from: data)
                return flowResponse
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Track analytics event
    public func trackEvent(
        eventName: String,
        flowId: String?,
        screenId: String?,
        properties: [String: Any]? = nil
    ) async throws {
        var components = URLComponents(string: "\(baseURL)/events")
        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }

        var body: [String: Any] = [
            "projectId": projectId,
            "eventName": eventName,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        if let flowId = flowId {
            body["flowId"] = flowId
        }
        if let screenId = screenId {
            body["screenId"] = screenId
        }
        if let properties = properties {
            body["properties"] = properties
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Fire and forget - don't block on analytics
        Task.detached {
            _ = try? await self.session.data(for: request)
        }
    }
}

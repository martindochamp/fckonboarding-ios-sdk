import Foundation

/// A single screen in the onboarding flow
public struct FlowScreen: Codable, Equatable, Identifiable {
    public let id: String
    public let type: ScreenType
    private let _showProgressBar: Bool?
    public let root: FlowElement  // Single root element (usually a stack)

    // Router for conditional navigation (optional)
    public let router: FlowRouter?

    /// Whether to show progress indicator (defaults to true if not specified)
    public var showProgress: Bool {
        return _showProgressBar ?? true
    }

    /// Helper: Get root element's children if it's a stack
    public var elements: [FlowElement] {
        switch root {
        case .stack(let stack):
            return stack.children
        default:
            return [root]
        }
    }

    public enum ScreenType: String, Codable {
        case informational
        case question
        case unknown = "" // Fallback for any unexpected types

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = ScreenType(rawValue: rawValue) ?? .unknown
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, root, router
        case _showProgressBar = "showProgressBar"
    }

    public init(
        id: String,
        type: ScreenType,
        showProgressBar: Bool = true,
        root: FlowElement,
        router: FlowRouter? = nil
    ) {
        self.id = id
        self.type = type
        self._showProgressBar = showProgressBar
        self.root = root
        self.router = router
    }
}

/// Router for conditional screen navigation
public struct FlowRouter: Codable, Equatable {
    public let routes: [Route]?

    public struct Route: Codable, Equatable {
        public let condition: String?
        public let targetScreenId: String?
    }
}

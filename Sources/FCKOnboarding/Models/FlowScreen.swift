import Foundation

/// A single screen in the onboarding flow
public struct FlowScreen: Codable, Equatable, Identifiable {
    public let id: String
    public let type: ScreenType
    public let title: String?
    public let subtitle: String?
    private let _showProgress: Bool?
    public let elements: [FlowElement]

    /// Whether to show progress indicator (defaults to true if not specified)
    public var showProgress: Bool {
        return _showProgress ?? true
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
        case id, type, title, subtitle, elements
        case _showProgress = "showProgress"
    }

    public init(
        id: String,
        type: ScreenType,
        title: String? = nil,
        subtitle: String? = nil,
        showProgress: Bool = true,
        elements: [FlowElement]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self._showProgress = showProgress
        self.elements = elements
    }
}

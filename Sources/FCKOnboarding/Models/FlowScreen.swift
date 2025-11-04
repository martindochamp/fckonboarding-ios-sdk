import Foundation

/// A single screen in the onboarding flow
public struct FlowScreen: Codable, Equatable, Identifiable {
    public let id: String
    public let type: ScreenType
    public let title: String?
    public let subtitle: String?
    public let showProgress: Bool
    public let elements: [FlowElement]

    public enum ScreenType: String, Codable {
        case informational
        case question
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
        self.showProgress = showProgress
        self.elements = elements
    }
}

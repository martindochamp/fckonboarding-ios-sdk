import Foundation

/// Root configuration for an onboarding flow
public struct FlowConfig: Codable, Equatable {
    public let flowId: String
    public let name: String
    public let version: Int
    public let screens: [FlowScreen]
    public let theme: FlowTheme?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case flowId, name, version, screens, theme, updatedAt
    }

    public init(
        flowId: String,
        name: String,
        version: Int,
        screens: [FlowScreen],
        theme: FlowTheme? = nil,
        updatedAt: Date? = nil
    ) {
        self.flowId = flowId
        self.name = name
        self.version = version
        self.screens = screens
        self.theme = theme
        self.updatedAt = updatedAt
    }
}

/// Theme configuration for the flow
public struct FlowTheme: Codable, Equatable {
    public let primaryColor: String?
    public let backgroundColor: String?
    public let textColor: String?
    public let fontFamily: String?

    public init(
        primaryColor: String? = nil,
        backgroundColor: String? = nil,
        textColor: String? = nil,
        fontFamily: String? = nil
    ) {
        self.primaryColor = primaryColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontFamily = fontFamily
    }
}

/// API response wrapper
public struct FlowResponse: Codable {
    public let flowId: String
    public let name: String
    public let config: FlowConfig
    public let version: Int
    public let updatedAt: String

    public init(
        flowId: String,
        name: String,
        config: FlowConfig,
        version: Int,
        updatedAt: String
    ) {
        self.flowId = flowId
        self.name = name
        self.config = config
        self.version = version
        self.updatedAt = updatedAt
    }
}

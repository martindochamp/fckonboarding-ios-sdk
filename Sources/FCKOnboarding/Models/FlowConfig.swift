import Foundation

/// Root configuration for an onboarding flow - matches builder output
public struct FlowConfig: Codable, Equatable {
    public let flowId: String?
    public let name: String?
    public let version: Int
    public let screens: [FlowScreen]
    public let theme: FlowTheme?
    public let variables: [FlowVariable]? // NEW: For data collection
    public let updatedAt: Date?
    public let config: InnerConfig? // Some responses nest the config

    // The actual flow config might be nested in a 'config' property
    public struct InnerConfig: Codable, Equatable {
        public let version: Int
        public let screens: [FlowScreen]
        public let theme: FlowTheme?
        public let variables: [FlowVariable]?
    }

    enum CodingKeys: String, CodingKey {
        case flowId, name, version, screens, theme, variables, updatedAt, config
    }

    // Custom decoder to handle both flat and nested config formats
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode the outer properties
        self.flowId = try? container.decode(String.self, forKey: .flowId)
        self.name = try? container.decode(String.self, forKey: .name)
        self.updatedAt = try? container.decode(Date.self, forKey: .updatedAt)

        // Check if config is nested
        if let innerConfig = try? container.decode(InnerConfig.self, forKey: .config) {
            self.version = innerConfig.version
            self.screens = innerConfig.screens
            self.theme = innerConfig.theme
            self.variables = innerConfig.variables
            self.config = innerConfig
        } else {
            // Config is flat
            self.version = try container.decode(Int.self, forKey: .version)
            self.screens = try container.decode([FlowScreen].self, forKey: .screens)
            self.theme = try? container.decode(FlowTheme.self, forKey: .theme)
            self.variables = try? container.decode([FlowVariable].self, forKey: .variables)
            self.config = nil
        }
    }

    public init(
        flowId: String? = nil,
        name: String? = nil,
        version: Int,
        screens: [FlowScreen],
        theme: FlowTheme? = nil,
        variables: [FlowVariable]? = nil,
        updatedAt: Date? = nil
    ) {
        self.flowId = flowId
        self.name = name
        self.version = version
        self.screens = screens
        self.theme = theme
        self.variables = variables
        self.updatedAt = updatedAt
        self.config = nil
    }
}

/// Theme configuration with variables - matches builder output
public struct FlowTheme: Codable, Equatable {
    public let variables: [ThemeVariable]?

    // Legacy properties for backward compatibility
    public let primaryColor: String?
    public let backgroundColor: String?
    public let textColor: String?
    public let fontFamily: String?

    public struct ThemeVariable: Codable, Equatable {
        public let id: String
        public let key: String
        public let name: String
        public let type: String // "color", "number", "string", etc.
        public let category: String?
        public let darkValue: String? // For now using String, can be enhanced
        public let lightValue: String?
        public let defaultValue: String?
        public let description: String?
    }

    public init(
        variables: [ThemeVariable]? = nil,
        primaryColor: String? = nil,
        backgroundColor: String? = nil,
        textColor: String? = nil,
        fontFamily: String? = nil
    ) {
        self.variables = variables
        self.primaryColor = primaryColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontFamily = fontFamily
    }
}

/// Flow variables for data collection
public struct FlowVariable: Codable, Equatable {
    public let id: String
    public let key: String
    public let name: String
    public let type: String // "text", "number", "array", "boolean", etc.
    public let defaultValue: String?

    public init(
        id: String,
        key: String,
        name: String,
        type: String,
        defaultValue: String? = nil
    ) {
        self.id = id
        self.key = key
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }
}

/// API response wrapper for placement endpoint
public struct PlacementFlowResponse: Codable {
    public let flowId: String?
    public let name: String?
    public let config: FlowConfig?
    public let version: Int?
    public let placementId: String?
    public let placementName: String?
    public let campaignId: String?
    public let variantId: String?
    public let isControl: Bool?
    public let isSticky: Bool?
    public let message: String? // For when no flow is available

    public init(
        flowId: String? = nil,
        name: String? = nil,
        config: FlowConfig? = nil,
        version: Int? = nil,
        placementId: String? = nil,
        placementName: String? = nil,
        campaignId: String? = nil,
        variantId: String? = nil,
        isControl: Bool? = nil,
        isSticky: Bool? = nil,
        message: String? = nil
    ) {
        self.flowId = flowId
        self.name = name
        self.config = config
        self.version = version
        self.placementId = placementId
        self.placementName = placementName
        self.campaignId = campaignId
        self.variantId = variantId
        self.isControl = isControl
        self.isSticky = isSticky
        self.message = message
    }
}

/// Simple flow response for active endpoint
public struct FlowResponse: Codable {
    public let flowId: String
    public let name: String
    public let config: FlowConfig
    public let version: Int
    public let updatedAt: String
    public let campaignId: String?
    public let variantId: String?

    public init(
        flowId: String,
        name: String,
        config: FlowConfig,
        version: Int,
        updatedAt: String,
        campaignId: String? = nil,
        variantId: String? = nil
    ) {
        self.flowId = flowId
        self.name = name
        self.config = config
        self.version = version
        self.updatedAt = updatedAt
        self.campaignId = campaignId
        self.variantId = variantId
    }
}
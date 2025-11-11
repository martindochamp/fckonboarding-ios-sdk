import Foundation

/// Base protocol for all flow elements
public protocol FlowElementProtocol: Codable, Equatable, Identifiable {
    var id: String { get }
    var type: String { get } // Changed to String to handle any element type
}

/// Type-erased wrapper for flow elements - matches builder output
public enum FlowElement: Codable, Equatable, Identifiable {
    case stack(StackElement)
    case text(TextElement)
    case image(ImageElement)
    case button(ButtonElement)
    case input(InputElement)
    case datePicker(DatePickerElement)
    case options(OptionsElement) // NEW: Matches builder "options" type
    case progressbar(ProgressBarElement) // NEW: Matches builder "progressbar" type
    case unknown(String) // Fallback for new element types - store just the type name

    public var id: String {
        switch self {
        case .stack(let el): return el.id
        case .text(let el): return el.id
        case .image(let el): return el.id
        case .button(let el): return el.id
        case .input(let el): return el.id
        case .datePicker(let el): return el.id
        case .options(let el): return el.id
        case .progressbar(let el): return el.id
        case .unknown: return UUID().uuidString
        }
    }

    // Manual Equatable conformance
    public static func == (lhs: FlowElement, rhs: FlowElement) -> Bool {
        switch (lhs, rhs) {
        case (.stack(let l), .stack(let r)): return l == r
        case (.text(let l), .text(let r)): return l == r
        case (.image(let l), .image(let r)): return l == r
        case (.button(let l), .button(let r)): return l == r
        case (.input(let l), .input(let r)): return l == r
        case (.datePicker(let l), .datePicker(let r)): return l == r
        case (.options(let l), .options(let r)): return l == r
        case (.progressbar(let l), .progressbar(let r)): return l == r
        case (.unknown(let l), .unknown(let r)): return l == r
        default: return false
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "stack":
            self = .stack(try StackElement(from: decoder))
        case "text":
            self = .text(try TextElement(from: decoder))
        case "image":
            self = .image(try ImageElement(from: decoder))
        case "button":
            self = .button(try ButtonElement(from: decoder))
        case "input":
            self = .input(try InputElement(from: decoder))
        case "datepicker", "datePicker":
            self = .datePicker(try DatePickerElement(from: decoder))
        case "options": // NEW: Handle options from builder
            self = .options(try OptionsElement(from: decoder))
        case "progressbar": // NEW: Handle progressbar from builder
            self = .progressbar(try ProgressBarElement(from: decoder))
        default:
            // Handle unknown types gracefully - just store the type name
            self = .unknown(type)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .stack(let el): try el.encode(to: encoder)
        case .text(let el): try el.encode(to: encoder)
        case .image(let el): try el.encode(to: encoder)
        case .button(let el): try el.encode(to: encoder)
        case .input(let el): try el.encode(to: encoder)
        case .datePicker(let el): try el.encode(to: encoder)
        case .options(let el): try el.encode(to: encoder)
        case .progressbar(let el): try el.encode(to: encoder)
        case .unknown(let typeName):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(typeName, forKey: .type)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
    }
}

// MARK: - Common Properties

/// Base properties shared by all elements
public struct ElementBase {
    public let width: Dimension?
    public let height: Dimension?
    public let margin: Spacing?
    public let padding: Spacing?
    public let backgroundColor: String?
    public let borderRadius: Double?
    public let borderColor: String?
    public let borderWidth: Double?
    public let opacity: Double?
    public let shadow: Shadow?
    public let transform: Transform?
    public let animation: Animation?
    public let tapBehaviors: [TapBehavior]?
}

// MARK: - Tap Behaviors (NEW)

public struct TapBehavior: Codable, Equatable {
    public let type: String
    public let targetScreenId: String?
    public let intensity: String? // For haptics
    public let scale: Double? // For bump animation
    public let duration: Double? // For bump animation
    public let delay: Double? // Delay before navigation

    enum CodingKeys: String, CodingKey {
        case type
        case targetScreenId
        case intensity
        case scale
        case duration
        case delay
    }

    /// Check if this is a navigation behavior
    public var isNavigation: Bool {
        return type == "navigate"
    }

    /// Check if this is a back navigation behavior
    public var isBack: Bool {
        return type == "back"
    }
}

// MARK: - Dimensions

public enum Dimension: Codable, Equatable {
    case fill
    case auto
    case fixed(Double)
    case percentage(Double)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            switch string.lowercased() {
            case "fill": self = .fill
            case "auto": self = .auto
            default:
                if string.hasSuffix("%"), let value = Double(string.dropLast()) {
                    self = .percentage(value)
                } else if let value = Double(string) {
                    self = .fixed(value)
                } else {
                    self = .auto
                }
            }
        } else if let number = try? container.decode(Double.self) {
            self = .fixed(number)
        } else {
            self = .auto
        }
    }
}

// MARK: - Spacing

public struct Spacing: Codable, Equatable {
    public let top: Double
    public let right: Double
    public let bottom: Double
    public let left: Double

    public init(top: Double = 0, right: Double = 0, bottom: Double = 0, left: Double = 0) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
}

// MARK: - Shadow

public struct Shadow: Codable, Equatable {
    public let type: String?
    public let color: String?
    public let blur: Double?
    public let spread: Double?
    public let offsetX: Double?
    public let offsetY: Double?
}

// MARK: - Transform

public struct Transform: Codable, Equatable {
    public let translateX: Double?
    public let translateY: Double?
    public let rotate: Double?
    public let scale: Double?
}

// MARK: - Animation

public struct Animation: Codable, Equatable {
    public let properties: [String]?
    public let duration: Double?
    public let easing: String?
    public let delay: Double?
}

// MARK: - Stack Element (UPDATED)

public struct StackElement: FlowElementProtocol {
    public let id: String
    public let type: String = "stack"
    public let axis: String // Changed from 'direction' to match builder
    public let spacing: Double?
    public let distribution: String? // Now optional and uses string
    public let alignItems: String? // NEW: Added to match builder
    public let backgroundColor: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?
    public let borderRadius: Double?
    public let borderColor: String?
    public let borderWidth: Double?
    public let tapBehaviors: [TapBehavior]?
    public let children: [FlowElement]

    enum CodingKeys: String, CodingKey {
        case id, type, axis, spacing, distribution, alignItems
        case backgroundColor, padding, margin, width, height
        case borderRadius, borderColor, borderWidth
        case tapBehaviors, children
    }

    // Custom decoder to auto-generate ID if missing
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.axis = try container.decode(String.self, forKey: .axis)
        self.spacing = try? container.decode(Double.self, forKey: .spacing)
        self.distribution = try? container.decode(String.self, forKey: .distribution)
        self.alignItems = try? container.decode(String.self, forKey: .alignItems)
        self.backgroundColor = try? container.decode(String.self, forKey: .backgroundColor)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
        self.borderRadius = try? container.decode(Double.self, forKey: .borderRadius)
        self.borderColor = try? container.decode(String.self, forKey: .borderColor)
        self.borderWidth = try? container.decode(Double.self, forKey: .borderWidth)
        self.tapBehaviors = try? container.decode([TapBehavior].self, forKey: .tapBehaviors)
        self.children = (try? container.decode([FlowElement].self, forKey: .children)) ?? []
    }
}

// MARK: - Text Element (UPDATED)

public struct TextElement: FlowElementProtocol {
    public let id: String
    public let type: String = "text"
    public let content: String
    public let fontSize: Double?
    public let color: String?
    public let alignment: String?
    public let fontWeight: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?
    public let tapBehaviors: [TapBehavior]?

    enum CodingKeys: String, CodingKey {
        case id, type, content, fontSize, color, alignment, fontWeight
        case padding, margin, width, height, tapBehaviors
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.content = try container.decode(String.self, forKey: .content)
        self.fontSize = try? container.decode(Double.self, forKey: .fontSize)
        self.color = try? container.decode(String.self, forKey: .color)
        self.alignment = try? container.decode(String.self, forKey: .alignment)
        self.fontWeight = try? container.decode(String.self, forKey: .fontWeight)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
        self.tapBehaviors = try? container.decode([TapBehavior].self, forKey: .tapBehaviors)
    }
}

// MARK: - Image Element (UPDATED)

public struct ImageElement: FlowElementProtocol {
    public let id: String
    public let type: String = "image"
    public let url: String
    public let alt: String?
    public let width: Dimension?
    public let height: Dimension?
    public let objectFit: String?
    public let borderRadius: Double?
    public let padding: Spacing?
    public let margin: Spacing?
    public let tapBehaviors: [TapBehavior]?

    enum CodingKeys: String, CodingKey {
        case id, type, url, alt, width, height, objectFit
        case borderRadius, padding, margin, tapBehaviors
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.url = try container.decode(String.self, forKey: .url)
        self.alt = try? container.decode(String.self, forKey: .alt)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
        self.objectFit = try? container.decode(String.self, forKey: .objectFit)
        self.borderRadius = try? container.decode(Double.self, forKey: .borderRadius)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.tapBehaviors = try? container.decode([TapBehavior].self, forKey: .tapBehaviors)
    }
}

// MARK: - Button Element (UPDATED)

public struct ButtonElement: FlowElementProtocol {
    public let id: String
    public let type: String = "button"
    public let text: String?
    public let action: String?
    public let style: String?
    public let backgroundColor: String?
    public let textColor: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?
    public let borderRadius: Double?
    public let tapBehaviors: [TapBehavior]?
    public let children: [FlowElement]?

    enum CodingKeys: String, CodingKey {
        case id, type, text, action, style, backgroundColor, textColor
        case padding, margin, width, height, borderRadius, tapBehaviors, children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.text = try? container.decode(String.self, forKey: .text)
        self.action = try? container.decode(String.self, forKey: .action)
        self.style = try? container.decode(String.self, forKey: .style)
        self.backgroundColor = try? container.decode(String.self, forKey: .backgroundColor)
        self.textColor = try? container.decode(String.self, forKey: .textColor)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
        self.borderRadius = try? container.decode(Double.self, forKey: .borderRadius)
        self.tapBehaviors = try? container.decode([TapBehavior].self, forKey: .tapBehaviors)
        self.children = try? container.decode([FlowElement].self, forKey: .children)
    }
}

// MARK: - Input Element

public struct InputElement: FlowElementProtocol {
    public let id: String
    public let type: String = "input"
    public let placeholder: String?
    public let label: String?
    public let inputType: String?
    public let required: Bool?
    public let variableKey: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?
    public let tapBehaviors: [TapBehavior]?

    enum CodingKeys: String, CodingKey {
        case id, type, placeholder, label, inputType, required, variableKey
        case padding, margin, width, height, tapBehaviors
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.placeholder = try? container.decode(String.self, forKey: .placeholder)
        self.label = try? container.decode(String.self, forKey: .label)
        self.inputType = try? container.decode(String.self, forKey: .inputType)
        self.required = try? container.decode(Bool.self, forKey: .required)
        self.variableKey = try? container.decode(String.self, forKey: .variableKey)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
        self.tapBehaviors = try? container.decode([TapBehavior].self, forKey: .tapBehaviors)
    }
}

// MARK: - DatePicker Element

public struct DatePickerElement: FlowElementProtocol {
    public let id: String
    public let type: String = "datepicker"
    public let label: String?
    public let mode: String?
    public let variableKey: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?

    enum CodingKeys: String, CodingKey {
        case id, type, label, mode, variableKey
        case padding, margin, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.label = try? container.decode(String.self, forKey: .label)
        self.mode = try? container.decode(String.self, forKey: .mode)
        self.variableKey = try? container.decode(String.self, forKey: .variableKey)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
    }
}

// MARK: - Options Element (NEW - Matches Builder)

public struct OptionsElement: FlowElementProtocol {
    public let id: String
    public let type: String = "options"
    public let options: [Option]
    public let multiple: Bool?
    public let selectedTextColor: String?
    public let optionBorderRadius: Double?
    public let optionBackgroundColor: String?
    public let selectedBackgroundColor: String?
    public let variableKey: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?

    public struct Option: Codable, Equatable, Identifiable {
        public let id: String
        public let label: String
        public let value: String
        public let icon: String?

        enum CodingKeys: String, CodingKey {
            case id, label, value, icon
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
            self.label = try container.decode(String.self, forKey: .label)
            self.value = try container.decode(String.self, forKey: .value)
            self.icon = try? container.decode(String.self, forKey: .icon)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, options, multiple, selectedTextColor
        case optionBorderRadius, optionBackgroundColor, selectedBackgroundColor
        case variableKey, padding, margin, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.options = (try? container.decode([Option].self, forKey: .options)) ?? []
        self.multiple = try? container.decode(Bool.self, forKey: .multiple)
        self.selectedTextColor = try? container.decode(String.self, forKey: .selectedTextColor)
        self.optionBorderRadius = try? container.decode(Double.self, forKey: .optionBorderRadius)
        self.optionBackgroundColor = try? container.decode(String.self, forKey: .optionBackgroundColor)
        self.selectedBackgroundColor = try? container.decode(String.self, forKey: .selectedBackgroundColor)
        self.variableKey = try? container.decode(String.self, forKey: .variableKey)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
    }
}

// MARK: - Progress Bar Element (NEW - Matches Builder)

public struct ProgressBarElement: FlowElementProtocol {
    public let id: String
    public let type: String = "progressbar"
    public let progress: Double
    public let barColor: String?
    public let trackColor: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?

    enum CodingKeys: String, CodingKey {
        case id, type, progress, barColor, trackColor
        case padding, margin, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.progress = (try? container.decode(Double.self, forKey: .progress)) ?? 0.0
        self.barColor = try? container.decode(String.self, forKey: .barColor)
        self.trackColor = try? container.decode(String.self, forKey: .trackColor)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
    }
}


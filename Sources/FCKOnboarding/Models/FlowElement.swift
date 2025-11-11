import Foundation
import SwiftUI

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
    case email(EmailInputElement)
    case phone(PhoneInputElement)
    case number(NumberInputElement)
    case toggle(ToggleElement)
    case datePicker(DatePickerElement)
    case choice(ChoiceElement)
    case options(OptionsElement)
    case progressbar(ProgressBarElement)
    case unknown(String) // Fallback for new element types - store just the type name

    public var id: String {
        switch self {
        case .stack(let el): return el.id
        case .text(let el): return el.id
        case .image(let el): return el.id
        case .button(let el): return el.id
        case .input(let el): return el.id
        case .email(let el): return el.id
        case .phone(let el): return el.id
        case .number(let el): return el.id
        case .toggle(let el): return el.id
        case .datePicker(let el): return el.id
        case .choice(let el): return el.id
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
        case (.email(let l), .email(let r)): return l == r
        case (.phone(let l), .phone(let r)): return l == r
        case (.number(let l), .number(let r)): return l == r
        case (.toggle(let l), .toggle(let r)): return l == r
        case (.datePicker(let l), .datePicker(let r)): return l == r
        case (.choice(let l), .choice(let r)): return l == r
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
        case "email":
            self = .email(try EmailInputElement(from: decoder))
        case "phone":
            self = .phone(try PhoneInputElement(from: decoder))
        case "number":
            self = .number(try NumberInputElement(from: decoder))
        case "toggle":
            self = .toggle(try ToggleElement(from: decoder))
        case "datepicker", "datePicker":
            self = .datePicker(try DatePickerElement(from: decoder))
        case "choice":
            self = .choice(try ChoiceElement(from: decoder))
        case "options":
            self = .options(try OptionsElement(from: decoder))
        case "progressbar":
            self = .progressbar(try ProgressBarElement(from: decoder))
        default:
            // Handle unknown types gracefully - just store the type name
            print("⚠️ [FCKOnboarding] Unknown element type '\(type)' - rendering as empty")
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
        case .email(let el): try el.encode(to: encoder)
        case .phone(let el): try el.encode(to: encoder)
        case .number(let el): try el.encode(to: encoder)
        case .toggle(let el): try el.encode(to: encoder)
        case .datePicker(let el): try el.encode(to: encoder)
        case .choice(let el): try el.encode(to: encoder)
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
    case rem(Double)
    case em(Double)
    case vw(Double)
    case vh(Double)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as UnitValue object first: {value: 16, unit: "px"}
        if let unitValue = try? container.decode(UnitValue.self) {
            switch unitValue.unit.lowercased() {
            case "px": self = .fixed(unitValue.value)
            case "%": self = .percentage(unitValue.value)
            case "rem": self = .rem(unitValue.value)
            case "em": self = .em(unitValue.value)
            case "vw": self = .vw(unitValue.value)
            case "vh": self = .vh(unitValue.value)
            case "auto": self = .auto
            default: self = .fixed(unitValue.value) // Default to fixed pixels
            }
        }
        // Try string format
        else if let string = try? container.decode(String.self) {
            switch string.lowercased() {
            case "fill": self = .fill
            case "auto": self = .auto
            default:
                if string.hasSuffix("%"), let value = Double(string.dropLast()) {
                    self = .percentage(value)
                } else if string.hasSuffix("rem"), let value = Double(string.dropLast(3)) {
                    self = .rem(value)
                } else if string.hasSuffix("em"), let value = Double(string.dropLast(2)) {
                    self = .em(value)
                } else if string.hasSuffix("vw"), let value = Double(string.dropLast(2)) {
                    self = .vw(value)
                } else if string.hasSuffix("vh"), let value = Double(string.dropLast(2)) {
                    self = .vh(value)
                } else if string.hasSuffix("px"), let value = Double(string.dropLast(2)) {
                    self = .fixed(value)
                } else if let value = Double(string) {
                    self = .fixed(value)
                } else {
                    self = .auto
                }
            }
        }
        // Try number format (legacy)
        else if let number = try? container.decode(Double.self) {
            self = .fixed(number)
        }
        // Fallback
        else {
            self = .auto
        }
    }

    /// Helper struct to decode UnitValue objects from builder
    private struct UnitValue: Codable {
        let value: Double
        let unit: String
    }

    /// Convert to CGFloat for use in SwiftUI (with screen width context)
    public func toCGFloat(screenWidth: CGFloat = 375, baseFontSize: CGFloat = 16) -> CGFloat? {
        switch self {
        case .fill: return nil // Use .infinity in SwiftUI
        case .auto: return nil // Use automatic sizing
        case .fixed(let value): return CGFloat(value)
        case .percentage(let value): return screenWidth * CGFloat(value / 100)
        case .rem(let value): return baseFontSize * CGFloat(value)
        case .em(let value): return baseFontSize * CGFloat(value)
        case .vw(let value): return screenWidth * CGFloat(value / 100)
        case .vh(let value): return screenWidth * 1.77 * CGFloat(value / 100) // Approximate 16:9 ratio
        }
    }
}

// MARK: - Spacing

/// Represents a spacing value that can be a number, UnitValue object, or 'auto'
public enum SpacingValue: Codable, Equatable {
    case fixed(Double)
    case auto
    case dimension(Dimension)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try UnitValue object: {value: 16, unit: "px"}
        if let unitValue = try? container.decode(UnitValueHelper.self) {
            switch unitValue.unit.lowercased() {
            case "px": self = .fixed(unitValue.value)
            case "rem": self = .dimension(.rem(unitValue.value))
            case "em": self = .dimension(.em(unitValue.value))
            case "%": self = .dimension(.percentage(unitValue.value))
            case "vw": self = .dimension(.vw(unitValue.value))
            case "vh": self = .dimension(.vh(unitValue.value))
            case "auto": self = .auto
            default: self = .fixed(unitValue.value)
            }
        }
        // Try string
        else if let string = try? container.decode(String.self) {
            if string.lowercased() == "auto" {
                self = .auto
            } else if let value = Double(string) {
                self = .fixed(value)
            } else {
                self = .fixed(0) // Fallback
            }
        }
        // Try number
        else if let number = try? container.decode(Double.self) {
            self = .fixed(number)
        }
        // Fallback
        else {
            self = .fixed(0)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fixed(let value):
            try container.encode(value)
        case .auto:
            try container.encode("auto")
        case .dimension(let dim):
            try container.encode(dim)
        }
    }

    /// Convert to CGFloat (0 if auto)
    public func toDouble() -> Double {
        switch self {
        case .fixed(let value): return value
        case .auto: return 0
        case .dimension(let dim): return dim.toCGFloat() ?? 0
        }
    }

    private struct UnitValueHelper: Codable {
        let value: Double
        let unit: String
    }
}

public struct Spacing: Codable, Equatable {
    public let top: SpacingValue
    public let right: SpacingValue
    public let bottom: SpacingValue
    public let left: SpacingValue

    public init(top: SpacingValue = .fixed(0), right: SpacingValue = .fixed(0), bottom: SpacingValue = .fixed(0), left: SpacingValue = .fixed(0)) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }

    /// Convenience initializer from doubles
    public init(top: Double = 0, right: Double = 0, bottom: Double = 0, left: Double = 0) {
        self.top = .fixed(top)
        self.right = .fixed(right)
        self.bottom = .fixed(bottom)
        self.left = .fixed(left)
    }

    /// Get edge insets for use in SwiftUI
    public var edgeInsets: EdgeInsets {
        EdgeInsets(
            top: top.toDouble(),
            leading: left.toDouble(),
            bottom: bottom.toDouble(),
            trailing: right.toDouble()
        )
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

// MARK: - Email Input Element (NEW - Matches Builder)

public struct EmailInputElement: FlowElementProtocol {
    public let id: String
    public let type: String = "email"
    public let placeholder: String?
    public let label: String?
    public let inputType: String?
    public let required: Bool?
    public let variableKey: String?
    public let backgroundColor: String?
    public let borderRadius: Double?
    public let borderColor: String?
    public let borderWidth: Double?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?

    enum CodingKeys: String, CodingKey {
        case id, type, placeholder, label, inputType, required, variableKey
        case backgroundColor, borderRadius, borderColor, borderWidth
        case padding, margin, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.placeholder = try? container.decode(String.self, forKey: .placeholder)
        self.label = try? container.decode(String.self, forKey: .label)
        self.inputType = try? container.decode(String.self, forKey: .inputType)
        self.required = try? container.decode(Bool.self, forKey: .required)
        self.variableKey = try? container.decode(String.self, forKey: .variableKey)
        self.backgroundColor = try? container.decode(String.self, forKey: .backgroundColor)
        self.borderRadius = try? container.decode(Double.self, forKey: .borderRadius)
        self.borderColor = try? container.decode(String.self, forKey: .borderColor)
        self.borderWidth = try? container.decode(Double.self, forKey: .borderWidth)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
    }
}

// MARK: - Phone Input Element (NEW - Matches Builder)

public struct PhoneInputElement: FlowElementProtocol {
    public let id: String
    public let type: String = "phone"
    public let placeholder: String?
    public let label: String?
    public let inputType: String?
    public let required: Bool?
    public let countryCode: String?
    public let variableKey: String?
    public let backgroundColor: String?
    public let borderRadius: Double?
    public let borderColor: String?
    public let borderWidth: Double?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?

    enum CodingKeys: String, CodingKey {
        case id, type, placeholder, label, inputType, required, countryCode, variableKey
        case backgroundColor, borderRadius, borderColor, borderWidth
        case padding, margin, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.placeholder = try? container.decode(String.self, forKey: .placeholder)
        self.label = try? container.decode(String.self, forKey: .label)
        self.inputType = try? container.decode(String.self, forKey: .inputType)
        self.required = try? container.decode(Bool.self, forKey: .required)
        self.countryCode = try? container.decode(String.self, forKey: .countryCode)
        self.variableKey = try? container.decode(String.self, forKey: .variableKey)
        self.backgroundColor = try? container.decode(String.self, forKey: .backgroundColor)
        self.borderRadius = try? container.decode(Double.self, forKey: .borderRadius)
        self.borderColor = try? container.decode(String.self, forKey: .borderColor)
        self.borderWidth = try? container.decode(Double.self, forKey: .borderWidth)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
    }
}

// MARK: - Number Input Element (NEW - Matches Builder)

public struct NumberInputElement: FlowElementProtocol {
    public let id: String
    public let type: String = "number"
    public let placeholder: String?
    public let label: String?
    public let inputType: String?
    public let required: Bool?
    public let min: Double?
    public let max: Double?
    public let step: Double?
    public let showStepper: Bool?
    public let variableKey: String?
    public let backgroundColor: String?
    public let borderRadius: Double?
    public let borderColor: String?
    public let borderWidth: Double?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?

    enum CodingKeys: String, CodingKey {
        case id, type, placeholder, label, inputType, required
        case min, max, step, showStepper, variableKey
        case backgroundColor, borderRadius, borderColor, borderWidth
        case padding, margin, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.placeholder = try? container.decode(String.self, forKey: .placeholder)
        self.label = try? container.decode(String.self, forKey: .label)
        self.inputType = try? container.decode(String.self, forKey: .inputType)
        self.required = try? container.decode(Bool.self, forKey: .required)
        self.min = try? container.decode(Double.self, forKey: .min)
        self.max = try? container.decode(Double.self, forKey: .max)
        self.step = try? container.decode(Double.self, forKey: .step)
        self.showStepper = try? container.decode(Bool.self, forKey: .showStepper)
        self.variableKey = try? container.decode(String.self, forKey: .variableKey)
        self.backgroundColor = try? container.decode(String.self, forKey: .backgroundColor)
        self.borderRadius = try? container.decode(Double.self, forKey: .borderRadius)
        self.borderColor = try? container.decode(String.self, forKey: .borderColor)
        self.borderWidth = try? container.decode(Double.self, forKey: .borderWidth)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
    }
}

// MARK: - Toggle Element (NEW - Matches Builder)

public struct ToggleElement: FlowElementProtocol {
    public let id: String
    public let type: String = "toggle"
    public let label: String?
    public let labelPosition: String?
    public let value: Bool?
    public let defaultValue: Bool?
    public let onColor: String?
    public let offColor: String?
    public let thumbColor: String?
    public let variableKey: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?

    enum CodingKeys: String, CodingKey {
        case id, type, label, labelPosition, value, defaultValue
        case onColor, offColor, thumbColor, variableKey
        case padding, margin, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.label = try? container.decode(String.self, forKey: .label)
        self.labelPosition = try? container.decode(String.self, forKey: .labelPosition)
        self.value = try? container.decode(Bool.self, forKey: .value)
        self.defaultValue = try? container.decode(Bool.self, forKey: .defaultValue)
        self.onColor = try? container.decode(String.self, forKey: .onColor)
        self.offColor = try? container.decode(String.self, forKey: .offColor)
        self.thumbColor = try? container.decode(String.self, forKey: .thumbColor)
        self.variableKey = try? container.decode(String.self, forKey: .variableKey)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
    }
}

// MARK: - Choice Element (NEW - Matches Builder)

public struct ChoiceElement: FlowElementProtocol {
    public let id: String
    public let type: String = "choice"
    public let selectionMode: String
    public let label: String?
    public let required: Bool?
    public let options: [ChoiceOption]
    public let defaultValue: [String]?
    public let layout: String?
    public let checkboxPosition: String?
    public let optionBackgroundColor: String?
    public let optionBorderColor: String?
    public let optionBorderRadius: Double?
    public let selectedBackgroundColor: String?
    public let selectedBorderColor: String?
    public let selectedTextColor: String?
    public let variableKey: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let width: Dimension?
    public let height: Dimension?

    public struct ChoiceOption: Codable, Equatable, Identifiable {
        public let id: String
        public let label: String
        public let value: String?
        public let icon: String?

        enum CodingKeys: String, CodingKey {
            case id, label, value, icon
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
            self.label = try container.decode(String.self, forKey: .label)
            self.value = try? container.decode(String.self, forKey: .value)
            self.icon = try? container.decode(String.self, forKey: .icon)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, selectionMode, label, required, options, defaultValue
        case layout, checkboxPosition
        case optionBackgroundColor, optionBorderColor, optionBorderRadius
        case selectedBackgroundColor, selectedBorderColor, selectedTextColor
        case variableKey, padding, margin, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.selectionMode = (try? container.decode(String.self, forKey: .selectionMode)) ?? "single"
        self.label = try? container.decode(String.self, forKey: .label)
        self.required = try? container.decode(Bool.self, forKey: .required)
        self.options = (try? container.decode([ChoiceOption].self, forKey: .options)) ?? []

        // Handle defaultValue as either single string or array
        if let singleValue = try? container.decode(String.self, forKey: .defaultValue) {
            self.defaultValue = [singleValue]
        } else {
            self.defaultValue = try? container.decode([String].self, forKey: .defaultValue)
        }

        self.layout = try? container.decode(String.self, forKey: .layout)
        self.checkboxPosition = try? container.decode(String.self, forKey: .checkboxPosition)
        self.optionBackgroundColor = try? container.decode(String.self, forKey: .optionBackgroundColor)
        self.optionBorderColor = try? container.decode(String.self, forKey: .optionBorderColor)
        self.optionBorderRadius = try? container.decode(Double.self, forKey: .optionBorderRadius)
        self.selectedBackgroundColor = try? container.decode(String.self, forKey: .selectedBackgroundColor)
        self.selectedBorderColor = try? container.decode(String.self, forKey: .selectedBorderColor)
        self.selectedTextColor = try? container.decode(String.self, forKey: .selectedTextColor)
        self.variableKey = try? container.decode(String.self, forKey: .variableKey)
        self.padding = try? container.decode(Spacing.self, forKey: .padding)
        self.margin = try? container.decode(Spacing.self, forKey: .margin)
        self.width = try? container.decode(Dimension.self, forKey: .width)
        self.height = try? container.decode(Dimension.self, forKey: .height)
    }
}


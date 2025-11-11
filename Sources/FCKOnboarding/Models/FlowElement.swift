import Foundation

/// Base protocol for all flow elements
public protocol FlowElementProtocol: Codable, Equatable, Identifiable {
    var id: String { get }
    var type: String { get } // Changed to String to handle any element type
}

/// Type-erased wrapper for flow elements - matches builder output
public enum FlowElement: Codable, Identifiable {
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
    public let customAction: String?

    enum CodingKeys: String, CodingKey {
        case type
        case targetScreenId
        case intensity
        case customAction
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

    // Custom decoder to handle both old and new format
    enum CodingKeys: String, CodingKey {
        case id, type, axis, spacing, distribution, alignItems
        case backgroundColor, padding, margin, width, height
        case borderRadius, borderColor, borderWidth
        case tapBehaviors, children
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
    public let children: [FlowElement]? // Buttons can have child elements (like text)
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
}

// MARK: - Helper Extensions for Decoding Any

extension KeyedDecodingContainer {
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any]? {
        guard contains(key) else { return nil }
        return try decode(type, forKey: key)
    }

    func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: [Any].Type, forKey key: K) throws -> [Any]? {
        guard contains(key) else { return nil }
        return try decode(type, forKey: key)
    }
}

struct JSONCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

extension KeyedDecodingContainer where K == JSONCodingKey {
    func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()

        for key in allKeys {
            if let value = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode([String: Any].self, forKey: key) {
                dictionary[key.stringValue] = value
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array = [Any]()

        while !isAtEnd {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Int.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let value = try? decode([Any].self) {
                array.append(value)
            } else if let value = try? decode([String: Any].self) {
                array.append(value)
            } else {
                _ = try? decode(String.self) // Skip unknown
            }
        }
        return array
    }
}
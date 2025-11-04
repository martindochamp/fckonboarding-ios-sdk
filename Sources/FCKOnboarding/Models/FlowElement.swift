import Foundation

/// Base protocol for all flow elements
public protocol FlowElementProtocol: Codable, Equatable, Identifiable {
    var id: String { get }
    var type: ElementType { get }
}

/// All supported element types
public enum ElementType: String, Codable {
    case stack
    case text
    case image
    case button
    case input
    case datePicker
    case singleChoice
    case multipleChoice
}

/// Type-erased wrapper for flow elements
public enum FlowElement: Codable, Equatable, Identifiable {
    case stack(StackElement)
    case text(TextElement)
    case image(ImageElement)
    case button(ButtonElement)
    case input(InputElement)
    case datePicker(DatePickerElement)
    case singleChoice(SingleChoiceElement)
    case multipleChoice(MultipleChoiceElement)

    public var id: String {
        switch self {
        case .stack(let el): return el.id
        case .text(let el): return el.id
        case .image(let el): return el.id
        case .button(let el): return el.id
        case .input(let el): return el.id
        case .datePicker(let el): return el.id
        case .singleChoice(let el): return el.id
        case .multipleChoice(let el): return el.id
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ElementType.self, forKey: .type)

        switch type {
        case .stack:
            self = .stack(try StackElement(from: decoder))
        case .text:
            self = .text(try TextElement(from: decoder))
        case .image:
            self = .image(try ImageElement(from: decoder))
        case .button:
            self = .button(try ButtonElement(from: decoder))
        case .input:
            self = .input(try InputElement(from: decoder))
        case .datePicker:
            self = .datePicker(try DatePickerElement(from: decoder))
        case .singleChoice:
            self = .singleChoice(try SingleChoiceElement(from: decoder))
        case .multipleChoice:
            self = .multipleChoice(try MultipleChoiceElement(from: decoder))
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
        case .singleChoice(let el): try el.encode(to: encoder)
        case .multipleChoice(let el): try el.encode(to: encoder)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
    }
}

// MARK: - Spacing

public struct Spacing: Codable, Equatable {
    public let top: SpacingValue
    public let right: SpacingValue
    public let bottom: SpacingValue
    public let left: SpacingValue

    public init(top: SpacingValue = .px(0), right: SpacingValue = .px(0), bottom: SpacingValue = .px(0), left: SpacingValue = .px(0)) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
}

public enum SpacingValue: Codable, Equatable {
    case px(Double)
    case percent(Double)
    case rem(Double)
    case em(Double)
    case vh(Double)
    case vw(Double)
    case auto

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            if string.lowercased() == "auto" {
                self = .auto
            } else if let value = Self.parse(string) {
                self = value
            } else {
                self = .px(0)
            }
        } else if let number = try? container.decode(Double.self) {
            self = .px(number)
        } else {
            self = .px(0)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .px(let val): try container.encode("\(val)px")
        case .percent(let val): try container.encode("\(val)%")
        case .rem(let val): try container.encode("\(val)rem")
        case .em(let val): try container.encode("\(val)em")
        case .vh(let val): try container.encode("\(val)vh")
        case .vw(let val): try container.encode("\(val)vw")
        case .auto: try container.encode("auto")
        }
    }

    private static func parse(_ string: String) -> SpacingValue? {
        let trimmed = string.trimmingCharacters(in: .whitespaces).lowercased()

        if trimmed == "auto" {
            return .auto
        }

        // Extract number and unit
        let pattern = "^(-?\\d*\\.?\\d+)\\s*(px|%|rem|em|vh|vw)?$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let numberRange = Range(match.range(at: 1), in: trimmed),
              let number = Double(trimmed[numberRange]) else {
            return nil
        }

        let unitRange = match.range(at: 2)
        let unit = unitRange.location != NSNotFound ? String(trimmed[Range(unitRange, in: trimmed)!]) : "px"

        switch unit {
        case "%": return .percent(number)
        case "rem": return .rem(number)
        case "em": return .em(number)
        case "vh": return .vh(number)
        case "vw": return .vw(number)
        default: return .px(number)
        }
    }
}

// MARK: - Stack Element

public struct StackElement: FlowElementProtocol {
    public let id: String
    public let type: ElementType = .stack
    public let direction: Direction
    public let spacing: Double
    public let distribution: Distribution
    public let backgroundColor: String?
    public let padding: Spacing?
    public let margin: Spacing?
    public let children: [FlowElement]

    public enum Direction: String, Codable {
        case vertical
        case horizontal
    }

    public enum Distribution: String, Codable {
        case start
        case center
        case end
        case spaceBetween = "space-between"
        case spaceAround = "space-around"
    }
}

// MARK: - Text Element

public struct TextElement: FlowElementProtocol {
    public let id: String
    public let type: ElementType = .text
    public let content: String
    public let fontSize: Double
    public let color: String
    public let alignment: Alignment
    public let fontWeight: FontWeight
    public let padding: Spacing?
    public let margin: Spacing?

    public enum Alignment: String, Codable {
        case left, center, right
    }

    public enum FontWeight: String, Codable {
        case normal, medium, bold, black
    }
}

// MARK: - Image Element

public struct ImageElement: FlowElementProtocol {
    public let id: String
    public let type: ElementType = .image
    public let url: String
    public let alt: String?
    public let height: HeightValue
    public let objectFit: ObjectFit
    public let borderRadius: Double
    public let padding: Spacing?
    public let margin: Spacing?

    public enum HeightValue: Codable, Equatable {
        case auto
        case fixed(Double)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self), string == "auto" {
                self = .auto
            } else if let number = try? container.decode(Double.self) {
                self = .fixed(number)
            } else {
                self = .auto
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .auto: try container.encode("auto")
            case .fixed(let val): try container.encode(val)
            }
        }
    }

    public enum ObjectFit: String, Codable {
        case cover, contain, fill
    }
}

// MARK: - Button Element

public struct ButtonElement: FlowElementProtocol {
    public let id: String
    public let type: ElementType = .button
    public let text: String
    public let action: Action
    public let style: Style
    public let backgroundColor: String
    public let textColor: String
    public let padding: Spacing?
    public let margin: Spacing?

    public enum Action: String, Codable {
        case next, skip, complete
    }

    public enum Style: String, Codable {
        case filled, outline
    }
}

// MARK: - Input Element

public struct InputElement: FlowElementProtocol {
    public let id: String
    public let type: ElementType = .input
    public let placeholder: String?
    public let label: String?
    public let inputType: InputType
    public let required: Bool
    public let padding: Spacing?
    public let margin: Spacing?

    public enum InputType: String, Codable {
        case text, email, number, phone
    }
}

// MARK: - DatePicker Element

public struct DatePickerElement: FlowElementProtocol {
    public let id: String
    public let type: ElementType = .datePicker
    public let label: String?
    public let mode: Mode
    public let padding: Spacing?
    public let margin: Spacing?

    public enum Mode: String, Codable {
        case date, time, dateTime = "datetime"
    }
}

// MARK: - SingleChoice Element

public struct SingleChoiceElement: FlowElementProtocol {
    public let id: String
    public let type: ElementType = .singleChoice
    public let question: String
    public let options: [ChoiceOption]
    public let padding: Spacing?
    public let margin: Spacing?
}

// MARK: - MultipleChoice Element

public struct MultipleChoiceElement: FlowElementProtocol {
    public let id: String
    public let type: ElementType = .multipleChoice
    public let question: String
    public let options: [ChoiceOption]
    public let padding: Spacing?
    public let margin: Spacing?
}

// MARK: - Choice Option

public struct ChoiceOption: Codable, Equatable, Identifiable {
    public let id: String
    public let text: String
    public let icon: String?
}

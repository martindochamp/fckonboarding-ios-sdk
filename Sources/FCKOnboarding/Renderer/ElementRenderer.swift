import SwiftUI

/// Renders flow elements as native SwiftUI views
enum ElementRenderer {
    @ViewBuilder
    static func render(element: FlowElement) -> some View {
        switch element {
        case .stack(let el):
            StackElementView(element: el)
        case .text(let el):
            TextElementView(element: el)
        case .image(let el):
            ImageElementView(element: el)
        case .button(let el):
            ButtonElementView(element: el)
        case .input(let el):
            InputElementView(element: el)
        case .datePicker(let el):
            DatePickerElementView(element: el)
        case .singleChoice(let el):
            SingleChoiceElementView(element: el)
        case .multipleChoice(let el):
            MultipleChoiceElementView(element: el)
        }
    }
}

// MARK: - Stack Element

struct StackElementView: View {
    let element: StackElement

    var body: some View {
        let stack = Group {
            if element.direction == .vertical {
                VStack(spacing: element.spacing) {
                    ForEach(element.children) { child in
                        ElementRenderer.render(element: child)
                    }
                }
            } else {
                HStack(spacing: element.spacing) {
                    ForEach(element.children) { child in
                        ElementRenderer.render(element: child)
                    }
                }
            }
        }

        stack
            .frame(maxWidth: element.direction == .vertical ? .infinity : nil)
            .applySpacing(padding: element.padding, margin: element.margin)
            .background(element.backgroundColor.flatMap { Color(hex: $0) })
    }
}

// MARK: - Text Element

struct TextElementView: View {
    let element: TextElement

    var body: some View {
        Text(element.content)
            .font(.system(size: element.fontSize, weight: element.fontWeight.swiftUIWeight))
            .foregroundColor(Color(hex: element.color))
            .multilineTextAlignment(element.alignment.swiftUIAlignment)
            .frame(maxWidth: .infinity, alignment: element.alignment.frameAlignment)
            .applySpacing(padding: element.padding, margin: element.margin)
    }
}

// MARK: - Image Element

struct ImageElementView: View {
    let element: ImageElement
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(height: heightValue)
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: element.objectFit.swiftUIContentMode)
                    .frame(height: heightValue)
                    .cornerRadius(element.borderRadius)
            } else {
                // Placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: heightValue)
                    .cornerRadius(element.borderRadius)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .task {
            await loadImage()
        }
    }

    private var heightValue: CGFloat? {
        switch element.height {
        case .auto: return nil
        case .fixed(let val): return CGFloat(val)
        }
    }

    private func loadImage() async {
        guard let url = URL(string: element.url) else {
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = uiImage
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Button Element

struct ButtonElementView: View {
    let element: ButtonElement

    var body: some View {
        Button(action: handleAction) {
            Text(element.text)
                .font(.headline)
                .foregroundColor(Color(hex: element.textColor))
                .frame(maxWidth: .infinity)
                .padding()
                .background(element.style == .filled ? Color(hex: element.backgroundColor) : Color.clear)
                .overlay(
                    element.style == .outline ?
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: element.backgroundColor), lineWidth: 2)
                    : nil
                )
                .cornerRadius(12)
        }
        .applySpacing(padding: element.padding, margin: element.margin)
    }

    private func handleAction() {
        // Actions handled by parent views
        print("Button action: \(element.action)")
    }
}

// MARK: - Input Element

struct InputElementView: View {
    let element: InputElement
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = element.label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            TextField(element.placeholder ?? "", text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(element.inputType.keyboardType)
                .textContentType(element.inputType.textContentType)
                .onChange(of: text) { newValue in
                    FCKOnboarding.shared.saveResponse(key: element.id, value: newValue)
                }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
    }
}

// MARK: - DatePicker Element

struct DatePickerElementView: View {
    let element: DatePickerElement
    @State private var selectedDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = element.label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: element.mode.displayedComponents
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
        .applySpacing(padding: element.padding, margin: element.margin)
    }
}

// MARK: - SingleChoice Element

struct SingleChoiceElementView: View {
    let element: SingleChoiceElement
    @State private var selectedOption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(element.question)
                .font(.headline)

            ForEach(element.options) { option in
                Button(action: {
                    selectedOption = option.id
                    FCKOnboarding.shared.saveResponse(key: element.id, value: option.text)
                }) {
                    HStack(spacing: 12) {
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .font(.title2)
                        }

                        Text(option.text)
                            .font(.body)

                        Spacer()

                        if selectedOption == option.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedOption == option.id ?
                                  Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedOption == option.id ?
                                    Color.accentColor : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
    }
}

// MARK: - MultipleChoice Element

struct MultipleChoiceElementView: View {
    let element: MultipleChoiceElement
    @State private var selectedOptions: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(element.question)
                .font(.headline)

            ForEach(element.options) { option in
                Button(action: {
                    if selectedOptions.contains(option.id) {
                        selectedOptions.remove(option.id)
                    } else {
                        selectedOptions.insert(option.id)
                    }

                    let selected = element.options.filter { selectedOptions.contains($0.id) }.map { $0.text }
                    FCKOnboarding.shared.saveResponse(key: element.id, value: selected.joined(separator: ", "))
                }) {
                    HStack(spacing: 12) {
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .font(.title2)
                        }

                        Text(option.text)
                            .font(.body)

                        Spacer()

                        if selectedOptions.contains(option.id) {
                            Image(systemName: "checkmark.square.fill")
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "square")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedOptions.contains(option.id) ?
                                  Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedOptions.contains(option.id) ?
                                    Color.accentColor : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
    }
}

// MARK: - Helper Extensions

extension View {
    func applySpacing(padding: Spacing?, margin: Spacing?) -> some View {
        self
            .padding(.top, padding?.top.cgFloatValue ?? 0)
            .padding(.trailing, padding?.right.cgFloatValue ?? 0)
            .padding(.bottom, padding?.bottom.cgFloatValue ?? 0)
            .padding(.leading, padding?.left.cgFloatValue ?? 0)
            // Note: SwiftUI doesn't have margin, we use padding as approximation
    }
}

extension SpacingValue {
    var cgFloatValue: CGFloat {
        switch self {
        case .px(let val): return CGFloat(val)
        case .percent(let val): return CGFloat(val) // Would need screen context
        case .rem(let val): return CGFloat(val * 16) // 1rem = 16pt
        case .em(let val): return CGFloat(val * 16)
        case .vh(let val): return CGFloat(val) // Would need screen height
        case .vw(let val): return CGFloat(val) // Would need screen width
        case .auto: return 0
        }
    }
}

extension TextElement.FontWeight {
    var swiftUIWeight: Font.Weight {
        switch self {
        case .normal: return .regular
        case .medium: return .medium
        case .bold: return .bold
        case .black: return .black
        }
    }
}

extension TextElement.Alignment {
    var swiftUIAlignment: TextAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}

extension ImageElement.ObjectFit {
    var swiftUIContentMode: ContentMode {
        switch self {
        case .cover, .fill: return .fill
        case .contain: return .fit
        }
    }
}

extension InputElement.InputType {
    var keyboardType: UIKeyboardType {
        switch self {
        case .text: return .default
        case .email: return .emailAddress
        case .number: return .numberPad
        case .phone: return .phonePad
        }
    }

    var textContentType: UITextContentType? {
        switch self {
        case .email: return .emailAddress
        case .phone: return .telephoneNumber
        default: return nil
        }
    }
}

extension DatePickerElement.Mode {
    var displayedComponents: DatePickerComponents {
        switch self {
        case .date: return .date
        case .time: return .hourAndMinute
        case .dateTime: return [.date, .hourAndMinute]
        }
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

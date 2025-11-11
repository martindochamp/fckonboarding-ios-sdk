import SwiftUI

/// Renders flow elements as native SwiftUI views
enum ElementRenderer {
    @ViewBuilder
    static func render(element: FlowElement, onNavigate: @escaping (FlowElement) -> Void) -> some View {
        Group {
            switch element {
            case .stack(let el):
                StackElementView(element: el, onNavigate: onNavigate)
            case .text(let el):
                TextElementView(element: el)
            case .image(let el):
                ImageElementView(element: el)
            case .button(let el):
                ButtonElementView(element: el, onNavigate: onNavigate)
            case .input(let el):
                InputElementView(element: el)
            case .datePicker(let el):
                DatePickerElementView(element: el)
            case .options(let el):
                OptionsElementView(element: el)
            case .progressbar(let el):
                ProgressBarElementView(element: el)
            case .unknown:
                EmptyView() // Silently skip unknown elements
            }
        }
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            onNavigate(element)
        }
    }
}

// MARK: - Stack Element

struct StackElementView: View {
    let element: StackElement
    let onNavigate: (FlowElement) -> Void

    var body: some View {
        let isVertical = element.axis.lowercased() == "vertical"
        let stack = Group {
            if isVertical {
                VStack(alignment: horizontalAlignment, spacing: element.spacing ?? 0) {
                    applyDistribution(vertical: true) {
                        ForEach(element.children) { child in
                            ElementRenderer.render(element: child, onNavigate: onNavigate)
                        }
                    }
                }
            } else {
                HStack(alignment: verticalAlignment, spacing: element.spacing ?? 0) {
                    applyDistribution(vertical: false) {
                        ForEach(element.children) { child in
                            ElementRenderer.render(element: child, onNavigate: onNavigate)
                        }
                    }
                }
            }
        }

        stack
            .frame(maxWidth: isVertical ? .infinity : nil)
            .applySpacing(padding: element.padding, margin: element.margin)
            .background(element.backgroundColor.flatMap { Color(hex: $0) })
            .applyDimensions(width: element.width, height: element.height)
            .applyBorder(radius: element.borderRadius, color: element.borderColor, width: element.borderWidth)
    }

    @ViewBuilder
    private func applyDistribution<Content: View>(vertical: Bool, @ViewBuilder content: () -> Content) -> some View {
        let dist = element.distribution?.lowercased()

        switch dist {
        case "center":
            if vertical {
                Spacer()
                content()
                Spacer()
            } else {
                Spacer()
                content()
                Spacer()
            }
        case "space-between":
            if vertical {
                content()
                Spacer()
            } else {
                content()
                Spacer()
            }
        case "space-around", "space-evenly":
            if vertical {
                Spacer()
                content()
                Spacer()
            } else {
                Spacer()
                content()
                Spacer()
            }
        case "flex-end", "end":
            if vertical {
                Spacer()
                content()
            } else {
                Spacer()
                content()
            }
        default: // "flex-start", "start", or nil
            content()
        }
    }

    // Map alignItems to SwiftUI alignment for VStack (horizontal alignment of children)
    private var horizontalAlignment: HorizontalAlignment {
        switch element.alignItems?.lowercased() {
        case "center": return .center
        case "flex-end", "end", "right": return .trailing
        case "flex-start", "start", "left": return .leading
        default: return .center
        }
    }

    // Map alignItems to SwiftUI alignment for HStack (vertical alignment of children)
    private var verticalAlignment: VerticalAlignment {
        switch element.alignItems?.lowercased() {
        case "center": return .center
        case "flex-end", "end", "bottom": return .bottom
        case "flex-start", "start", "top": return .top
        default: return .center
        }
    }
}

// MARK: - Text Element

struct TextElementView: View {
    let element: TextElement

    var body: some View {
        Text(element.content)
            .font(.system(size: element.fontSize ?? 16, weight: fontWeight))
            .foregroundColor(Color(hex: element.color ?? "#000000"))
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .applySpacing(padding: element.padding, margin: element.margin)
            .applyDimensions(width: element.width, height: element.height)
    }

    private var fontWeight: Font.Weight {
        switch element.fontWeight?.lowercased() {
        case "bold": return .bold
        case "semibold": return .semibold
        case "medium": return .medium
        case "light": return .light
        case "thin": return .thin
        case "black": return .black
        default: return .regular
        }
    }

    private var textAlignment: TextAlignment {
        switch element.alignment?.lowercased() {
        case "center": return .center
        case "right", "trailing": return .trailing
        default: return .leading
        }
    }

    private var frameAlignment: Alignment {
        switch element.alignment?.lowercased() {
        case "center": return .center
        case "right", "trailing": return .trailing
        default: return .leading
        }
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
                    .frame(width: defaultSize, height: defaultSize)
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(
                        width: element.width == nil ? defaultSize : nil,
                        height: element.height == nil ? defaultSize : nil
                    )
                    .cornerRadius(element.borderRadius ?? 0)
            } else {
                // Placeholder - image failed to load
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: defaultSize, height: defaultSize)
                    .cornerRadius(element.borderRadius ?? 0)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
        .task {
            await loadImage()
        }
    }

    // Default size if no dimensions specified
    private var defaultSize: CGFloat {
        return 100
    }

    private var contentMode: ContentMode {
        switch element.objectFit?.lowercased() {
        case "cover", "fill": return .fill
        case "contain", "fit": return .fit
        default: return .fit
        }
    }

    private func loadImage() async {
        guard let url = URL(string: element.url) else {
            print("⚠️ [FCKOnboarding] Invalid image URL: \(element.url)")
            isLoading = false
            return
        }

        print("🖼️ [FCKOnboarding] Loading image from: \(url)")

        do {
            // Create URLRequest with cache policy to always fetch fresh
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

            // Create session configuration with no cache
            let config = URLSessionConfiguration.ephemeral
            config.urlCache = nil
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let session = URLSession(configuration: config)

            let (data, _) = try await session.data(for: request)
            if let uiImage = UIImage(data: data) {
                print("✅ [FCKOnboarding] Successfully loaded image: \(url.lastPathComponent), size: \(uiImage.size)")
                await MainActor.run {
                    self.image = uiImage
                    self.isLoading = false
                }
            } else {
                print("⚠️ [FCKOnboarding] Failed to decode image data from URL: \(url)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            print("⚠️ [FCKOnboarding] Network error loading image from URL: \(url)")
            print("   Error: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Button Element

struct ButtonElementView: View {
    let element: ButtonElement
    let onNavigate: (FlowElement) -> Void

    var body: some View {
        Button(action: handleAction) {
            Group {
                if let children = element.children, !children.isEmpty {
                    // Render child elements
                    VStack {
                        ForEach(children) { child in
                            ElementRenderer.render(element: child, onNavigate: onNavigate)
                        }
                    }
                } else if let text = element.text {
                    // Fallback to text property
                    Text(text)
                        .font(.headline)
                        .foregroundColor(Color(hex: element.textColor ?? "#FFFFFF"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(element.padding?.top ?? 12)
            .background(isFilled ? (Color(hex: element.backgroundColor ?? "#007AFF")) : Color.clear)
            .overlay(
                isOutline ?
                RoundedRectangle(cornerRadius: element.borderRadius ?? 12)
                    .stroke(Color(hex: element.backgroundColor ?? "#007AFF"), lineWidth: 2)
                : nil
            )
            .cornerRadius(element.borderRadius ?? 12)
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
    }

    private var isFilled: Bool {
        element.style?.lowercased() == "filled" || element.style == nil
    }

    private var isOutline: Bool {
        element.style?.lowercased() == "outline"
    }

    private func handleAction() {
        // Actions handled by parent views
        if let action = element.action {
            print("Button action: \(action)")
        }
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
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .onChange(of: text) { newValue in
                    if let variableKey = element.variableKey {
                        FCKOnboarding.shared.saveResponse(key: variableKey, value: newValue)
                    }
                }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
    }

    private var keyboardType: UIKeyboardType {
        switch element.inputType?.lowercased() {
        case "email": return .emailAddress
        case "number": return .numberPad
        case "phone": return .phonePad
        default: return .default
        }
    }

    private var textContentType: UITextContentType? {
        switch element.inputType?.lowercased() {
        case "email": return .emailAddress
        case "phone": return .telephoneNumber
        default: return nil
        }
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
                displayedComponents: displayedComponents
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .onChange(of: selectedDate) { newValue in
                if let variableKey = element.variableKey {
                    FCKOnboarding.shared.saveResponse(key: variableKey, value: newValue.ISO8601Format())
                }
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
    }

    private var displayedComponents: DatePickerComponents {
        switch element.mode?.lowercased() {
        case "date": return .date
        case "time": return .hourAndMinute
        case "datetime": return [.date, .hourAndMinute]
        default: return .date
        }
    }
}

// MARK: - Options Element

struct OptionsElementView: View {
    let element: OptionsElement
    @State private var selectedOptions: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(element.options) { option in
                Button(action: {
                    if element.multiple == true {
                        // Multiple selection
                        if selectedOptions.contains(option.id) {
                            selectedOptions.remove(option.id)
                        } else {
                            selectedOptions.insert(option.id)
                        }
                        let selected = element.options.filter { selectedOptions.contains($0.id) }.map { $0.value }
                        if let variableKey = element.variableKey {
                            FCKOnboarding.shared.saveResponse(key: variableKey, value: selected.joined(separator: ", "))
                        }
                    } else {
                        // Single selection
                        selectedOptions = [option.id]
                        if let variableKey = element.variableKey {
                            FCKOnboarding.shared.saveResponse(key: variableKey, value: option.value)
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .font(.title2)
                        }

                        Text(option.label)
                            .font(.body)

                        Spacer()

                        if selectedOptions.contains(option.id) {
                            Image(systemName: element.multiple == true ? "checkmark.square.fill" : "checkmark.circle.fill")
                                .foregroundColor(Color(hex: element.selectedTextColor ?? "#007AFF"))
                        } else {
                            Image(systemName: element.multiple == true ? "square" : "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: element.optionBorderRadius ?? 12)
                            .fill(selectedOptions.contains(option.id) ?
                                  Color(hex: element.selectedBackgroundColor ?? "#007AFF").opacity(0.1) :
                                  Color(hex: element.optionBackgroundColor ?? "#F5F5F5"))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
    }
}

// MARK: - ProgressBar Element

struct ProgressBarElementView: View {
    let element: ProgressBarElement

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color(hex: element.trackColor ?? "#E5E5E5"))
                    .frame(height: geometry.size.height)

                // Progress
                Rectangle()
                    .fill(Color(hex: element.barColor ?? "#007AFF"))
                    .frame(width: geometry.size.width * CGFloat(element.progress), height: geometry.size.height)
                    .animation(.easeInOut, value: element.progress)
            }
        }
        .frame(height: 8)
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
    }
}

// MARK: - Helper Extensions

extension View {
    func applySpacing(padding: Spacing?, margin: Spacing?) -> some View {
        self
            // Apply padding first (inside the element)
            .padding(.top, CGFloat(padding?.top ?? 0))
            .padding(.trailing, CGFloat(padding?.right ?? 0))
            .padding(.bottom, CGFloat(padding?.bottom ?? 0))
            .padding(.leading, CGFloat(padding?.left ?? 0))
            // Then apply margin as additional padding (outside the element)
            .padding(.top, CGFloat(margin?.top ?? 0))
            .padding(.trailing, CGFloat(margin?.right ?? 0))
            .padding(.bottom, CGFloat(margin?.bottom ?? 0))
            .padding(.leading, CGFloat(margin?.left ?? 0))
    }

    func applyDimensions(width: Dimension?, height: Dimension?) -> some View {
        self
            .frame(
                minWidth: width?.minValue,
                maxWidth: width?.maxValue,
                minHeight: height?.minValue,
                maxHeight: height?.maxValue
            )
    }

    func applyBorder(radius: Double?, color: String?, width: Double?) -> some View {
        self
            .cornerRadius(CGFloat(radius ?? 0))
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(radius ?? 0))
                    .stroke(Color(hex: color ?? ""), lineWidth: CGFloat(width ?? 0))
            )
    }
}

extension Dimension {
    var minValue: CGFloat? {
        switch self {
        case .auto: return nil
        case .fill: return 0
        case .fixed(let val): return CGFloat(val)
        case .percentage: return nil
        }
    }

    var maxValue: CGFloat? {
        switch self {
        case .auto: return nil
        case .fill: return .infinity
        case .fixed(let val): return CGFloat(val)
        case .percentage: return nil // Would need parent context
        }
    }
}

extension Color {
    init(hex: String) {
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
            // Invalid hex, return clear
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 0)
            return
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

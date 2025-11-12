import SwiftUI

/// Renders flow elements as native SwiftUI views
enum ElementRenderer {
    @ViewBuilder
    static func render(element: FlowElement, onNavigate: @escaping (FlowElement) -> Void) -> some View {
        // Render element WITHOUT global tap gesture (stacks/buttons handle their own taps)
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
        case .email(let el):
            EmailInputElementView(element: el)
        case .phone(let el):
            PhoneInputElementView(element: el)
        case .number(let el):
            NumberInputElementView(element: el)
        case .toggle(let el):
            ToggleElementView(element: el)
        case .datePicker(let el):
            DatePickerElementView(element: el)
        case .choice(let el):
            ChoiceElementView(element: el)
        case .options(let el):
            OptionsElementView(element: el)
        case .progressbar(let el):
            ProgressBarElementView(element: el)
        case .unknown:
            EmptyView() // Silently skip unknown elements
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

        Group {
            stack
                .frame(maxWidth: isVertical ? .infinity : nil)
                .applySpacing(padding: element.padding, margin: element.margin)
                .background(element.backgroundColor.flatMap { Color(hex: $0) })
                .applyDimensions(width: element.width, height: element.height)
                .applyBorder(radius: element.borderRadius, color: element.borderColor, width: element.borderWidth)
        }
        .onAppear {
            print("📐 [Stack \(element.id)] Rendered")
            if let padding = element.padding {
                print("   Padding - top: \(padding.top.toDouble()), right: \(padding.right.toDouble()), bottom: \(padding.bottom.toDouble()), left: \(padding.left.toDouble())")
            } else {
                print("   Padding - none")
            }
            if let margin = element.margin {
                print("   Margin - top: \(margin.top.toDouble()), right: \(margin.right.toDouble()), bottom: \(margin.bottom.toDouble()), left: \(margin.left.toDouble())")
            } else {
                print("   Margin - none")
            }
            if let tapBehaviors = element.tapBehaviors {
                print("   👆 Has \(tapBehaviors.count) tap behavior(s)")
                for behavior in tapBehaviors {
                    print("      - \(behavior.type)\(behavior.targetScreenId.map { " → \($0)" } ?? "")")
                }
            } else {
                print("   No tap behaviors")
            }
        }
        .contentShape(Rectangle()) // Make entire stack tappable
        .onTapGesture {
            // Only handle tap if this stack has tap behaviors
            if let tapBehaviors = element.tapBehaviors, !tapBehaviors.isEmpty {
                print("🔔 [Stack \(element.id)] Tapped (has tap behaviors)")
                onNavigate(.stack(element))
            } else {
                print("🔔 [Stack \(element.id)] Tapped (no tap behaviors - ignoring)")
            }
        }
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

        #if targetEnvironment(simulator)
        print("🔧 [FCKOnboarding] Simulator: Loading image with no cache from: \(url)")
        #else
        print("🖼️ [FCKOnboarding] Loading image from: \(url)")
        #endif

        do {
            // Create URLRequest with cache policy
            var request = URLRequest(url: url)

            // On simulator: always fetch fresh, on device: use cache
            #if targetEnvironment(simulator)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let config = URLSessionConfiguration.ephemeral
            config.urlCache = nil
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            #else
            request.cachePolicy = .returnCacheDataElseLoad
            let config = URLSessionConfiguration.default
            #endif

            let session = URLSession(configuration: config)

            let (data, response) = try await session.data(for: request)

            // Log response info for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("   Response status: \(httpResponse.statusCode)")
                print("   Content-Type: \(httpResponse.allHeaderFields["Content-Type"] ?? "unknown")")
                print("   Data size: \(data.count) bytes")
            }

            if let uiImage = UIImage(data: data) {
                print("✅ [FCKOnboarding] Successfully loaded image: \(url.lastPathComponent), size: \(uiImage.size)")
                await MainActor.run {
                    self.image = uiImage
                    self.isLoading = false
                }
            } else {
                print("❌ [FCKOnboarding] Failed to decode image data from URL: \(url)")
                print("   Data size: \(data.count) bytes")
                print("   First 100 bytes: \(data.prefix(100).map { String(format: "%02x", $0) }.joined())")

                // Check if data looks like HTML (common error response)
                if let dataString = String(data: data, encoding: .utf8), dataString.contains("<!DOCTYPE") || dataString.contains("<html") {
                    print("   ⚠️ Response appears to be HTML, not an image!")
                    print("   HTML preview: \(dataString.prefix(200))")
                }

                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            print("❌ [FCKOnboarding] Network error loading image from URL: \(url)")
            print("   Error: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("   URLError code: \(urlError.code.rawValue)")
            }
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
            .padding(element.padding?.top.toDouble() ?? 12)
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

// MARK: - Email Input Element

struct EmailInputElementView: View {
    let element: EmailInputElement
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = element.label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            TextField(element.placeholder ?? "email@example.com", text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .onChange(of: text) { newValue in
                    if let variableKey = element.variableKey {
                        FCKOnboarding.shared.saveResponse(key: variableKey, value: newValue)
                    }
                }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
    }
}

// MARK: - Phone Input Element

struct PhoneInputElementView: View {
    let element: PhoneInputElement
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = element.label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(countryFlag)
                    .font(.title3)
                TextField(element.placeholder ?? "Phone number", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .onChange(of: text) { newValue in
                        if let variableKey = element.variableKey {
                            FCKOnboarding.shared.saveResponse(key: variableKey, value: newValue)
                        }
                    }
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
    }

    private var countryFlag: String {
        switch element.countryCode?.uppercased() {
        case "US": return "🇺🇸"
        case "GB": return "🇬🇧"
        case "CA": return "🇨🇦"
        case "AU": return "🇦🇺"
        case "DE": return "🇩🇪"
        case "FR": return "🇫🇷"
        case "ES": return "🇪🇸"
        case "IT": return "🇮🇹"
        case "MX": return "🇲🇽"
        case "BR": return "🇧🇷"
        default: return "🇺🇸"
        }
    }
}

// MARK: - Number Input Element

struct NumberInputElementView: View {
    let element: NumberInputElement
    @State private var value: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = element.label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if element.showStepper == true {
                Stepper(value: $value,
                        in: (element.min ?? 0)...(element.max ?? 100),
                        step: element.step ?? 1) {
                    Text("\(Int(value))")
                }
                .onChange(of: value) { newValue in
                    if let variableKey = element.variableKey {
                        FCKOnboarding.shared.saveResponse(key: variableKey, value: "\(newValue)")
                    }
                }
            } else {
                TextField(element.placeholder ?? "0", value: $value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .onChange(of: value) { newValue in
                        if let variableKey = element.variableKey {
                            FCKOnboarding.shared.saveResponse(key: variableKey, value: "\(newValue)")
                        }
                    }
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
    }
}

// MARK: - Toggle Element

struct ToggleElementView: View {
    let element: ToggleElement
    @State private var isOn: Bool = false

    var body: some View {
        HStack {
            if element.labelPosition?.lowercased() != "right" {
                if let label = element.label {
                    Text(label)
                        .font(.body)
                }
                Spacer()
            }

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: element.onColor ?? "#00ff41"))
                .onChange(of: isOn) { newValue in
                    if let variableKey = element.variableKey {
                        FCKOnboarding.shared.saveResponse(key: variableKey, value: "\(newValue)")
                    }
                }

            if element.labelPosition?.lowercased() == "right" {
                if let label = element.label {
                    Text(label)
                        .font(.body)
                }
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
        .onAppear {
            isOn = element.value ?? element.defaultValue ?? false
        }
    }
}

// MARK: - Choice Element

struct ChoiceElementView: View {
    let element: ChoiceElement
    @State private var selectedOptions: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let label = element.label {
                Text(label)
                    .font(.headline)
            }

            ForEach(element.options) { option in
                Button(action: {
                    handleSelection(optionId: option.id)
                }) {
                    HStack(spacing: 12) {
                        // Checkbox/Radio indicator
                        if element.checkboxPosition?.lowercased() != "hidden" &&
                           element.checkboxPosition?.lowercased() != "right" {
                            selectionIndicator(isSelected: selectedOptions.contains(option.id))
                        }

                        if let icon = option.icon {
                            Text(icon)
                                .font(.title2)
                        }

                        Text(option.label)
                            .font(.body)
                            .foregroundColor(selectedOptions.contains(option.id) ?
                                           Color(hex: element.selectedTextColor ?? "#000000") :
                                           .primary)

                        Spacer()

                        if element.checkboxPosition?.lowercased() == "right" {
                            selectionIndicator(isSelected: selectedOptions.contains(option.id))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: element.optionBorderRadius ?? 12)
                            .fill(selectedOptions.contains(option.id) ?
                                  Color(hex: element.selectedBackgroundColor ?? "#00ff41").opacity(0.2) :
                                  Color(hex: element.optionBackgroundColor ?? "#F5F5F5"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: element.optionBorderRadius ?? 12)
                            .stroke(selectedOptions.contains(option.id) ?
                                  Color(hex: element.selectedBorderColor ?? "#00ff41") :
                                  Color(hex: element.optionBorderColor ?? "#E5E5E5"),
                                  lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .applySpacing(padding: element.padding, margin: element.margin)
        .applyDimensions(width: element.width, height: element.height)
        .onAppear {
            if let defaults = element.defaultValue {
                selectedOptions = Set(defaults)
            }
        }
    }

    @ViewBuilder
    private func selectionIndicator(isSelected: Bool) -> some View {
        if element.selectionMode.lowercased() == "multiple" {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundColor(isSelected ? Color(hex: element.selectedBorderColor ?? "#00ff41") : .gray)
        } else {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color(hex: element.selectedBorderColor ?? "#00ff41") : .gray)
        }
    }

    private func handleSelection(optionId: String) {
        if element.selectionMode.lowercased() == "multiple" {
            // Toggle selection
            if selectedOptions.contains(optionId) {
                selectedOptions.remove(optionId)
            } else {
                selectedOptions.insert(optionId)
            }
        } else {
            // Single selection
            selectedOptions = [optionId]
        }

        // Save to responses
        if let variableKey = element.variableKey {
            let selectedValues = element.options
                .filter { selectedOptions.contains($0.id) }
                .map { $0.value ?? $0.label }

            if element.selectionMode.lowercased() == "multiple" {
                FCKOnboarding.shared.saveResponse(key: variableKey, value: selectedValues.joined(separator: ", "))
            } else {
                FCKOnboarding.shared.saveResponse(key: variableKey, value: selectedValues.first ?? "")
            }
        }
    }
}

// MARK: - Helper Extensions

extension View {
    func applySpacing(padding: Spacing?, margin: Spacing?) -> some View {
        let paddingTop = CGFloat(padding?.top.toDouble() ?? 0)
        let paddingRight = CGFloat(padding?.right.toDouble() ?? 0)
        let paddingBottom = CGFloat(padding?.bottom.toDouble() ?? 0)
        let paddingLeft = CGFloat(padding?.left.toDouble() ?? 0)

        let marginTop = CGFloat(margin?.top.toDouble() ?? 0)
        let marginRight = CGFloat(margin?.right.toDouble() ?? 0)
        let marginBottom = CGFloat(margin?.bottom.toDouble() ?? 0)
        let marginLeft = CGFloat(margin?.left.toDouble() ?? 0)

        return self
            // Apply padding first (inside the element)
            .padding(.top, paddingTop)
            .padding(.trailing, paddingRight)
            .padding(.bottom, paddingBottom)
            .padding(.leading, paddingLeft)
            // Then apply margin as additional padding (outside the element)
            .padding(.top, marginTop)
            .padding(.trailing, marginRight)
            .padding(.bottom, marginBottom)
            .padding(.leading, marginLeft)
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
        case .rem, .em, .vw, .vh: return nil // These will be converted to fixed values
        }
    }

    var maxValue: CGFloat? {
        switch self {
        case .auto: return nil
        case .fill: return .infinity
        case .fixed(let val): return CGFloat(val)
        case .percentage: return nil // Would need parent context
        case .rem(let val): return CGFloat(val * 16) // 1rem = 16px
        case .em(let val): return CGFloat(val * 16) // 1em = 16px
        case .vw(let val): return CGFloat(val * 3.75) // 100vw = 375px (iPhone width)
        case .vh(let val): return CGFloat(val * 6.67) // 100vh = 667px (iPhone height approx)
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

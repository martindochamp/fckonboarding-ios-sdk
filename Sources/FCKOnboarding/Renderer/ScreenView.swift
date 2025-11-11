import SwiftUI

/// View for rendering a single screen
struct ScreenView: View {
    let screen: FlowScreen
    let screenIndex: Int
    let totalScreens: Int
    let allScreens: [FlowScreen]?
    let onNext: () -> Void
    let onSkip: () -> Void
    let onNavigate: ((String) -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                if screen.showProgress {
                    ProgressBar(
                        current: screenIndex + 1,
                        total: totalScreens
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // Screen content - centered in remaining space
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(screen.elements) { element in
                                ElementRenderer.render(
                                    element: element,
                                    onNavigate: handleTapBehavior
                                )
                            }
                        }
                        .frame(minHeight: geometry.size.height)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear {
            Task {
                try? await FCKOnboarding.shared.trackEvent(
                    name: "screen_viewed",
                    screenIndex: screenIndex
                )
            }
        }
    }

    private func handleTapBehavior(for element: FlowElement) {
        // Extract tap behaviors from element
        let behaviors: [TapBehavior]? = {
            switch element {
            case .button(let el): return el.tapBehaviors
            case .image(let el): return el.tapBehaviors
            case .text(let el): return el.tapBehaviors
            case .stack(let el): return el.tapBehaviors
            default: return nil
            }
        }()

        guard let behaviors = behaviors else { return }

        // Handle each behavior
        for behavior in behaviors {
            if behavior.isNavigation, let targetScreenId = behavior.targetScreenId {
                // Navigate to specific screen
                onNavigate?(targetScreenId)
            } else if behavior.isBack {
                // Go back (same as skip for now)
                onSkip()
            }
        }
    }
}

/// Progress bar component
struct ProgressBar: View {
    let current: Int
    let total: Int

    var progress: Double {
        Double(current) / Double(total)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)

                // Progress
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .cornerRadius(2)
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 4)
    }
}

#if DEBUG
struct ScreenView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview requires decoding from JSON due to custom decoders
        // Simple placeholder view instead
        VStack {
            Text("ScreenView Preview")
                .font(.headline)
            Text("Load actual flow data to preview")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}
#endif

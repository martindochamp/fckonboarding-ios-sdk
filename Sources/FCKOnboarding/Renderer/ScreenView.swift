import SwiftUI

/// View for rendering a single screen
struct ScreenView: View {
    let screen: FlowScreen
    let screenIndex: Int
    let totalScreens: Int
    let onNext: () -> Void
    let onSkip: () -> Void

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

                // Screen content
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(screen.elements) { element in
                            ElementRenderer.render(element: element)
                        }
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
        ScreenView(
            screen: FlowScreen(
                id: "1",
                type: .informational,
                title: "Welcome",
                subtitle: "Get started",
                showProgress: true,
                elements: []
            ),
            screenIndex: 0,
            totalScreens: 3,
            onNext: {},
            onSkip: {}
        )
    }
}
#endif

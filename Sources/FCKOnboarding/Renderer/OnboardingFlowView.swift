import SwiftUI

/// Main view for displaying an onboarding flow
public struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingFlowViewModel()
    @State private var currentScreenIndex = 0

    private let onComplete: (Bool) -> Void

    public init(onComplete: @escaping (Bool) -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading...")
                    .progressViewStyle(.circular)

            case .loaded(let flow):
                flowContent(flow: flow)

            case .error(let error):
                errorView(error: error)
            }
        }
        .task {
            await viewModel.loadFlow()
        }
    }

    @ViewBuilder
    private func flowContent(flow: FlowResponse) -> some View {
        ZStack {
            TabView(selection: $currentScreenIndex) {
                ForEach(Array(flow.config.screens.enumerated()), id: \.element.id) { index, screen in
                    ScreenView(
                        screen: screen,
                        screenIndex: index,
                        totalScreens: flow.config.screens.count,
                        onNext: {
                            if index < flow.config.screens.count - 1 {
                                withAnimation {
                                    currentScreenIndex = index + 1
                                }
                            } else {
                                completeFlow()
                            }
                        },
                        onSkip: {
                            skipFlow()
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func errorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Failed to load onboarding")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task {
                    await viewModel.loadFlow()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Skip") {
                skipFlow()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func completeFlow() {
        Task {
            try? await FCKOnboarding.shared.trackEvent(name: "flow_completed")
        }
        onComplete(true)
    }

    private func skipFlow() {
        Task {
            try? await FCKOnboarding.shared.trackEvent(name: "flow_skipped")
        }
        onComplete(false)
    }
}

/// ViewModel for managing flow state
@MainActor
class OnboardingFlowViewModel: ObservableObject {
    @Published var state: LoadingState = .loading

    enum LoadingState {
        case loading
        case loaded(FlowResponse)
        case error(Error)
    }

    func loadFlow() async {
        state = .loading

        do {
            let flow = try await FCKOnboarding.shared.fetchFlow()
            state = .loaded(flow)

            // Track view event
            try? await FCKOnboarding.shared.trackEvent(name: "flow_viewed", flowId: flow.flowId)
        } catch {
            state = .error(error)
        }
    }
}

#if DEBUG
struct OnboardingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlowView { completed in
            print("Completed: \(completed)")
        }
    }
}
#endif

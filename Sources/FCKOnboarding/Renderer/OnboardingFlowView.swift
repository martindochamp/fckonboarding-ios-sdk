import SwiftUI

/// Main view for displaying an onboarding flow
public struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingFlowViewModel()
    @State private var currentScreenIndex = 0

    private let config: FlowConfig?
    private let onComplete: (Bool) -> Void

    /// Initialize with a pre-fetched config (used by OnboardingGate)
    public init(config: FlowConfig, onComplete: @escaping (Bool) -> Void) {
        self.config = config
        self.onComplete = onComplete
    }

    /// Initialize without config - will fetch flow automatically
    public init(onComplete: @escaping (Bool) -> Void) {
        self.config = nil
        self.onComplete = onComplete
    }

    public var body: some View {
        Group {
            // If config was provided, use it directly
            if let config = config {
                flowContentFromConfig(config: config)
            } else {
                // Otherwise load via view model
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
        }
        .task {
            // Only load if config wasn't provided
            if config == nil {
                await viewModel.loadFlow()
            }
        }
    }

    @ViewBuilder
    private func flowContentFromConfig(config: FlowConfig) -> some View {
        ZStack {
            TabView(selection: $currentScreenIndex) {
                ForEach(Array(config.screens.enumerated()), id: \.element.id) { index, screen in
                    ScreenView(
                        screen: screen,
                        screenIndex: index,
                        totalScreens: config.screens.count,
                        allScreens: config.screens,
                        onNext: {
                            if index < config.screens.count - 1 {
                                withAnimation {
                                    currentScreenIndex = index + 1
                                }
                            } else {
                                completeFlow()
                            }
                        },
                        onSkip: {
                            skipFlow()
                        },
                        onNavigate: { targetScreenId in
                            navigateToScreen(targetScreenId, in: config.screens)
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
    }

    private func navigateToScreen(_ screenId: String, in screens: [FlowScreen]) {
        if let targetIndex = screens.firstIndex(where: { $0.id == screenId }) {
            withAnimation {
                currentScreenIndex = targetIndex
            }
        }
    }

    @ViewBuilder
    private func flowContent(flow: PlacementFlowResponse) -> some View {
        if let config = flow.config {
            ZStack {
                TabView(selection: $currentScreenIndex) {
                    ForEach(Array(config.screens.enumerated()), id: \.element.id) { index, screen in
                        ScreenView(
                            screen: screen,
                            screenIndex: index,
                            totalScreens: config.screens.count,
                            allScreens: config.screens,
                            onNext: {
                                if index < config.screens.count - 1 {
                                    withAnimation {
                                        currentScreenIndex = index + 1
                                    }
                                } else {
                                    completeFlow()
                                }
                            },
                            onSkip: {
                                skipFlow()
                            },
                            onNavigate: { targetScreenId in
                                navigateToScreen(targetScreenId, in: config.screens)
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        } else {
            Text("No flow configuration available")
                .foregroundColor(.secondary)
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
        case loaded(PlacementFlowResponse)
        case error(Error)
    }

    func loadFlow() async {
        state = .loading

        do {
            guard let response = try await FCKOnboarding.shared.fetchFlow() else {
                // No flow available (user completed or in holdout)
                state = .error(NSError(domain: "FCKOnboarding", code: 404, userInfo: [
                    NSLocalizedDescriptionKey: "No onboarding flow available"
                ]))
                return
            }

            state = .loaded(response)

            // Track view event
            if let flowId = response.flowId {
                try? await FCKOnboarding.shared.trackEvent(name: "flow_viewed", flowId: flowId)
            }
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

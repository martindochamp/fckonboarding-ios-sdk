import SwiftUI

/// A SwiftUI view that automatically presents onboarding when needed
@available(iOS 15.0, *)
public struct OnboardingGate<Content: View>: View {
    let placement: String
    let userProperties: [String: Any]?
    let onComplete: (() -> Void)?
    let content: Content

    @State private var flowConfig: FlowConfig?
    @State private var isLoading = true
    @State private var showOnboarding = false

    public init(
        placement: String = "main",
        userProperties: [String: Any]? = nil,
        onComplete: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.placement = placement
        self.userProperties = userProperties
        self.onComplete = onComplete
        self.content = content()
    }

    public var body: some View {
        ZStack {
            // Main content
            content
                .opacity(isLoading || showOnboarding ? 0 : 1)

            // Loading state
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }

            // Onboarding flow
            if showOnboarding, let config = flowConfig {
                OnboardingFlowView(config: config, onComplete: { completed in
                    // User completed or skipped onboarding
                    Task {
                        if completed {
                            await FCKOnboarding.shared.markCompleted()
                        }
                        withAnimation {
                            showOnboarding = false
                        }
                        onComplete?()
                    }
                })
                .transition(.opacity)
            }
        }
        .task {
            await checkAndPresentOnboarding()
        }
    }

    private func checkAndPresentOnboarding() async {
        do {
            // Check if should present onboarding
            if let config = try await FCKOnboarding.shared.presentIfNeeded(
                for: placement,
                userProperties: userProperties
            ) {
                await MainActor.run {
                    flowConfig = config
                    withAnimation {
                        isLoading = false
                        showOnboarding = true
                    }
                }
            } else {
                // No onboarding needed
                await MainActor.run {
                    withAnimation {
                        isLoading = false
                    }
                }
            }
        } catch {
            print("Error checking onboarding: \(error)")
            // On error, don't block user from accessing app
            await MainActor.run {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

/// A modifier-style version of OnboardingGate
@available(iOS 15.0, *)
public extension View {
    func onboardingGate(
        placement: String = "main",
        userProperties: [String: Any]? = nil,
        onComplete: (() -> Void)? = nil
    ) -> some View {
        OnboardingGate(
            placement: placement,
            userProperties: userProperties,
            onComplete: onComplete
        ) {
            self
        }
    }
}

import SwiftUI
import FCKOnboarding

/// Manual control over onboarding presentation
///
/// This example shows:
/// - Using presentIfNeeded() for manual control
/// - Passing user properties for targeting
/// - Handling different presentation styles
/// - Error handling
struct ManualExample: View {
    @State private var flowConfig: FlowConfig?
    @State private var showOnboarding = false
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        ZStack {
            // Main content
            mainContent
                .opacity(showOnboarding ? 0.3 : 1.0)

            // Loading indicator
            if isLoading {
                ProgressView("Checking onboarding...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .task {
            await checkOnboarding()
        }
        .sheet(isPresented: $showOnboarding) {
            onboardingSheet
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 30) {
            Text("Manual Control Example")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 10) {
                InfoRow(title: "User Plan", value: "Free")
                InfoRow(title: "Country", value: "US")
                InfoRow(title: "Cart Value", value: "$75.00")
            }

            Button("Show Checkout Upsell") {
                Task {
                    await showCheckoutUpsell()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Reset Onboarding") {
                FCKOnboarding.shared.reset()
                Task { await checkOnboarding() }
            }
            .buttonStyle(.bordered)

            if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }

    // MARK: - Onboarding Sheet

    @ViewBuilder
    private var onboardingSheet: some View {
        if let config = flowConfig {
            OnboardingFlowView(config: config) {
                Task {
                    await handleCompletion()
                }
            }
        } else {
            Text("No flow configuration available")
        }
    }

    // MARK: - Methods

    private func checkOnboarding() async {
        isLoading = true
        error = nil

        do {
            // Check if onboarding should be shown for "main" placement
            if let config = try await FCKOnboarding.shared.presentIfNeeded(
                for: "main",
                userProperties: [
                    "plan": "free",
                    "country": "US",
                    "daysSinceSignup": 1
                ]
            ) {
                await MainActor.run {
                    flowConfig = config
                    showOnboarding = true
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func showCheckoutUpsell() async {
        do {
            // Show upsell for users with high cart value
            if let config = try await FCKOnboarding.shared.presentIfNeeded(
                for: "premium_upsell",
                userProperties: [
                    "cart_value": 75.0,
                    "plan": "free"
                ]
            ) {
                await MainActor.run {
                    flowConfig = config
                    showOnboarding = true
                }
            } else {
                print("No upsell flow available or user not eligible")
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }

    private func handleCompletion() async {
        // Mark as completed (syncs with backend)
        await FCKOnboarding.shared.markCompleted()

        // Get user responses
        let responses = FCKOnboarding.shared.getUserResponses()
        print("User responses: \(responses)")

        // Check if user wants premium
        if let wantsPremium = responses["wants_premium"],
           wantsPremium == "yes" {
            // Show premium signup
            print("User wants premium!")
        }

        // Track completion event
        try? await FCKOnboarding.shared.trackEvent(
            name: "onboarding_completed_manual",
            properties: [
                "placement": "checkout",
                "method": "manual"
            ]
        )

        // Close sheet
        await MainActor.run {
            showOnboarding = false
        }
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct ManualExample_Previews: PreviewProvider {
    static var previews: some View {
        ManualExample()
    }
}

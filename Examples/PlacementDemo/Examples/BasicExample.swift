import SwiftUI
import FCKOnboarding

/// The simplest possible integration of FCKOnboarding with placements
///
/// This example shows:
/// - Basic OnboardingGate usage
/// - Automatic presentation on app launch
/// - Handling completion callback
struct BasicExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to My App!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your main content goes here")
                .foregroundColor(.gray)

            // Example buttons
            Button("Button 1") { }
                .buttonStyle(.borderedProminent)

            Button("Button 2") { }
                .buttonStyle(.bordered)
        }
        .padding()
        // ✨ This is all you need to add onboarding
        .onboardingGate(
            placement: "main",
            onComplete: {
                print("User completed onboarding!")
                // Here you can:
                // - Track analytics
                // - Update user preferences
                // - Show a welcome message
            }
        )
    }
}

// MARK: - App Entry Point

@main
struct BasicExampleApp: App {
    init() {
        // Step 1: Configure SDK with your API key
        FCKOnboarding.configure(
            apiKey: "your-api-key-here",
            environment: .production
        )

        // Optional: Set custom user ID for authenticated users
        // FCKOnboarding.shared.setUserId("user-123")
    }

    var body: some Scene {
        WindowGroup {
            BasicExample()
        }
    }
}

// MARK: - Preview

struct BasicExample_Previews: PreviewProvider {
    static var previews: some View {
        BasicExample()
    }
}

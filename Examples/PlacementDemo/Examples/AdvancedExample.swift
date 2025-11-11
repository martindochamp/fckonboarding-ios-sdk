import SwiftUI
import FCKOnboarding

/// Advanced example showing all placement features
///
/// This example demonstrates:
/// - Multiple placements in one app
/// - Tab-based navigation with different onboarding per tab
/// - User session management with properties
/// - Audience targeting
/// - Response collection and storage
/// - Custom analytics tracking
@main
struct AdvancedExampleApp: App {
    init() {
        // Configure SDK
        FCKOnboarding.configure(
            apiKey: "your-api-key-here",
            environment: .production,
            cachePolicy: .cacheFirst
        )

        // Set user ID if authenticated
        if let userId = UserSession.shared.userId {
            FCKOnboarding.shared.setUserId(userId)
        }
    }

    var body: some Scene {
        WindowGroup {
            AdvancedExample()
        }
    }
}

struct AdvancedExample: View {
    @StateObject private var session = UserSession.shared

    var body: some View {
        TabView {
            // Home tab with main onboarding
            HomeTab()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            // Features tab with discovery onboarding
            FeaturesTab()
                .tabItem {
                    Label("Features", systemImage: "star")
                }

            // Checkout tab with upsell
            CheckoutTab()
                .tabItem {
                    Label("Checkout", systemImage: "cart")
                }

            // Settings tab
            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Home Tab

struct HomeTab: View {
    @StateObject private var session = UserSession.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Welcome, \(session.userName ?? "Guest")!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 15) {
                    StatCard(title: "Total Users", value: "1,234")
                    StatCard(title: "Active Today", value: "567")
                    StatCard(title: "Conversion Rate", value: "12.3%")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            // Main app onboarding - shown on first launch
            .onboardingGate(
                placement: "main",
                userProperties: session.onboardingProperties,
                onComplete: {
                    handleMainOnboardingComplete()
                }
            )
        }
    }

    private func handleMainOnboardingComplete() {
        let responses = FCKOnboarding.shared.getUserResponses()

        // Save user name if provided
        if let name = responses["name_input"] {
            session.userName = name
        }

        // Save user goals
        if let goals = responses["goals_choice"] {
            session.userGoals = goals
        }

        // Track completion
        Task {
            try? await FCKOnboarding.shared.trackEvent(
                name: "main_onboarding_completed",
                properties: [
                    "has_name": responses["name_input"] != nil,
                    "has_goals": responses["goals_choice"] != nil
                ]
            )
        }

        print("Main onboarding completed! Name: \(session.userName ?? "none")")
    }
}

// MARK: - Features Tab

struct FeaturesTab: View {
    @StateObject private var session = UserSession.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(features, id: \.title) { feature in
                        FeatureCard(feature: feature)
                    }
                }
                .padding()
            }
            .navigationTitle("Features")
            // Feature discovery - only shown to free users
            .onboardingGate(
                placement: "feature_discovery",
                userProperties: session.onboardingProperties,
                onComplete: {
                    print("Feature discovery completed!")
                    session.hasSeenFeatureDiscovery = true
                }
            )
        }
    }

    private let features = [
        Feature(title: "Analytics", description: "Track your metrics", isPremium: false),
        Feature(title: "Advanced Reports", description: "Detailed insights", isPremium: true),
        Feature(title: "Team Collaboration", description: "Work together", isPremium: true),
        Feature(title: "API Access", description: "Integrate anywhere", isPremium: true)
    ]
}

struct Feature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let isPremium: Bool
}

struct FeatureCard: View {
    let feature: Feature

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if feature.isPremium {
                Text("PREMIUM")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple)
                    .cornerRadius(5)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Checkout Tab

struct CheckoutTab: View {
    @StateObject private var session = UserSession.shared
    @State private var cartValue: Double = 75.0
    @State private var flowConfig: FlowConfig?
    @State private var showUpsell = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Checkout")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 15) {
                    HStack {
                        Text("Cart Total:")
                            .font(.headline)
                        Spacer()
                        Text("$\(cartValue, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    Stepper(value: $cartValue, in: 0...200, step: 25) {
                        Text("Adjust cart value for testing")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                Button("Complete Purchase") {
                    completePurchase()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()
            }
            .padding()
            .navigationTitle("Checkout")
            // Manual upsell check
            .task {
                await checkUpsell()
            }
            .sheet(isPresented: $showUpsell) {
                if let config = flowConfig {
                    OnboardingFlowView(config: config) {
                        Task {
                            await handleUpsellComplete()
                        }
                    }
                }
            }
        }
    }

    private func checkUpsell() async {
        // Only show upsell for high-value carts
        guard cartValue > 50, session.userPlan == "free" else {
            return
        }

        do {
            if let config = try await FCKOnboarding.shared.presentIfNeeded(
                for: "premium_upsell",
                userProperties: [
                    "cart_value": cartValue,
                    "plan": session.userPlan,
                    "country": session.userCountry
                ]
            ) {
                await MainActor.run {
                    flowConfig = config
                    showUpsell = true
                }
            }
        } catch {
            print("Error checking upsell: \(error)")
        }
    }

    private func handleUpsellComplete() async {
        await FCKOnboarding.shared.markCompleted()

        let responses = FCKOnboarding.shared.getUserResponses()

        if responses["upgrade_now"] == "yes" {
            // Upgrade user to premium
            await MainActor.run {
                session.userPlan = "premium"
            }
            print("User upgraded to premium!")
        }

        await MainActor.run {
            showUpsell = false
        }
    }

    private func completePurchase() {
        print("Purchase completed: $\(cartValue)")
    }
}

// MARK: - Settings Tab

struct SettingsTab: View {
    @StateObject private var session = UserSession.shared
    @State private var showingResetAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section("User Info") {
                    LabeledContent("Name", value: session.userName ?? "Not set")
                    LabeledContent("Plan", value: session.userPlan.capitalized)
                    LabeledContent("Country", value: session.userCountry)
                }

                Section("Onboarding") {
                    LabeledContent("Days Since Signup", value: "\(session.daysSinceSignup)")
                    LabeledContent("Has Completed Profile", value: session.hasCompletedProfile ? "Yes" : "No")
                }

                Section("Testing") {
                    Button("Reset Onboarding") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)

                    Toggle("Simulate Free User", isOn: Binding(
                        get: { session.userPlan == "free" },
                        set: { session.userPlan = $0 ? "free" : "premium" }
                    ))

                    Stepper("Days Since Signup: \(session.daysSinceSignup)", value: $session.daysSinceSignup, in: 0...365)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Onboarding?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    FCKOnboarding.shared.reset()
                    print("Onboarding reset! Restart app to see onboarding again.")
                }
            } message: {
                Text("This will clear all onboarding completion status. You'll need to restart the app to see onboarding flows again.")
            }
        }
    }
}

// MARK: - Helper Views

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - User Session Manager

class UserSession: ObservableObject {
    static let shared = UserSession()

    @Published var userId: String? = nil
    @Published var userName: String? = UserDefaults.standard.string(forKey: "userName")
    @Published var userPlan: String = UserDefaults.standard.string(forKey: "userPlan") ?? "free"
    @Published var userCountry: String = "US"
    @Published var daysSinceSignup: Int = UserDefaults.standard.integer(forKey: "daysSinceSignup")
    @Published var hasCompletedProfile: Bool = false
    @Published var hasSeenFeatureDiscovery: Bool = false
    @Published var userGoals: String? = nil

    private init() {
        // Load initial values
        if daysSinceSignup == 0 {
            daysSinceSignup = 1 // Default to 1 day
        }
    }

    /// User properties for onboarding targeting
    var onboardingProperties: [String: Any] {
        return [
            "plan": userPlan,
            "country": userCountry,
            "daysSinceSignup": daysSinceSignup,
            "hasCompletedProfile": hasCompletedProfile,
            "hasSeenFeatureDiscovery": hasSeenFeatureDiscovery
        ]
    }
}

// MARK: - Preview

struct AdvancedExample_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedExample()
    }
}

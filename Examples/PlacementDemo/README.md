# Placement Demo - Example iOS App

This example demonstrates how to use FCKOnboarding's placement-based system to show different onboarding flows at different points in your app.

## What This Example Shows

1. **Multiple Placements** - Different flows for different parts of the app
2. **User Properties** - Targeting specific user segments
3. **OnboardingGate Component** - Easy integration with SwiftUI
4. **Manual Control** - Alternative approach with more control
5. **User Responses** - Collecting and using user input
6. **Completion Tracking** - Backend-synced completion status

## Features Demonstrated

### 1. Main App Onboarding
- Shows on first app launch
- Uses `"main"` placement
- Collects user name and goals
- Automatic presentation with OnboardingGate

### 2. Feature Discovery
- Shows when user navigates to premium features
- Uses `"feature_discovery"` placement
- Only shown to free users
- User property targeting

### 3. Checkout Upsell
- Shows before checkout
- Uses `"premium_upsell"` placement
- Targets users with cart value > $50
- Manual control example

### 4. Settings Onboarding
- Shows in settings tab
- Uses `"settings_help"` placement
- Reset button to test onboarding again

## File Structure

```
PlacementDemo/
├── README.md                  # This file
├── App/
│   ├── PlacementDemoApp.swift # App entry point with SDK configuration
│   ├── ContentView.swift      # Main app with tab navigation
│   └── UserSession.swift      # User session management
├── Views/
│   ├── HomeView.swift         # Home tab with main onboarding
│   ├── FeaturesView.swift     # Features tab with discovery onboarding
│   ├── CheckoutView.swift     # Checkout with upsell (manual control)
│   └── SettingsView.swift     # Settings with reset
└── Examples/
    ├── BasicExample.swift     # Simplest possible integration
    ├── ManualExample.swift    # Manual control approach
    └── AdvancedExample.swift  # All features combined
```

## Quick Start

### 1. Configure SDK

```swift
import FCKOnboarding

@main
struct PlacementDemoApp: App {
    init() {
        // Configure with your API key
        FCKOnboarding.configure(
            apiKey: "your-api-key-here",
            environment: .production
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Create Placements in Dashboard

1. Go to your dashboard at https://fckonboarding.com
2. Create these placements:
   - `main` - Main app onboarding
   - `feature_discovery` - Feature introduction
   - `premium_upsell` - Upsell flow
   - `settings_help` - Help/tips

3. Create flows for each placement
4. Link them via campaigns

### 3. Run the Example

```bash
# Clone the repository
git clone https://github.com/yourorg/fckonboarding-ios-sdk

# Open in Xcode
cd sdk-ios/Examples/PlacementDemo
open PlacementDemo.xcodeproj

# Run on simulator
# Cmd+R
```

## Code Examples

### Basic - Automatic Presentation

```swift
import SwiftUI
import FCKOnboarding

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Welcome Home!")
                .font(.largeTitle)

            Text("Your main content here")
                .foregroundColor(.gray)
        }
        .onboardingGate(
            placement: "main",
            onComplete: {
                print("User completed main onboarding!")
            }
        )
    }
}
```

### With User Properties - Targeting

```swift
struct FeaturesView: View {
    @StateObject var session = UserSession.shared

    var body: some View {
        VStack {
            Text("Premium Features")
                .font(.largeTitle)

            FeatureGrid()
        }
        .onboardingGate(
            placement: "feature_discovery",
            userProperties: [
                "plan": session.userPlan,           // "free" or "premium"
                "country": session.userCountry,      // "US", "UK", etc.
                "daysSinceSignup": session.daysSinceSignup
            ],
            onComplete: {
                print("User discovered features!")
            }
        )
    }
}
```

### Manual Control - More Flexibility

```swift
struct CheckoutView: View {
    @State private var flowConfig: FlowConfig?
    @State private var showUpsell = false
    @State private var cartValue: Double = 75.0

    var body: some View {
        VStack {
            Text("Checkout")
            Text("Cart: $\(cartValue, specifier: "%.2f")")

            Button("Complete Purchase") {
                // Process checkout
            }
        }
        .task {
            // Check if we should show upsell
            if let config = try? await FCKOnboarding.shared.presentIfNeeded(
                for: "premium_upsell",
                userProperties: [
                    "cart_value": cartValue,
                    "plan": "free"
                ]
            ) {
                flowConfig = config
                showUpsell = true
            }
        }
        .sheet(isPresented: $showUpsell) {
            if let config = flowConfig {
                OnboardingFlowView(config: config) {
                    Task {
                        await FCKOnboarding.shared.markCompleted()

                        // Get user's response
                        let responses = FCKOnboarding.shared.getUserResponses()
                        if responses["wants_premium"] == "yes" {
                            // Show premium signup
                        }

                        showUpsell = false
                    }
                }
            }
        }
    }
}
```

### Collecting User Responses

```swift
.onboardingGate(
    placement: "main",
    onComplete: {
        // Get all user responses
        let responses = FCKOnboarding.shared.getUserResponses()

        // Access specific fields
        let userName = responses["name_input"]
        let userEmail = responses["email_input"]
        let selectedGoals = responses["goals_choice"]

        // Save to your app's storage
        UserDefaults.standard.set(userName, forKey: "userName")

        // Or send to your backend
        saveUserProfile(name: userName, email: userEmail)
    }
)
```

## Dashboard Setup Guide

### Step 1: Create Placements

Navigate to **Placements** tab:

1. Click "New Placement"
2. Name: `main`
3. Description: "Main app onboarding on first launch"
4. Save

Repeat for:
- `feature_discovery`
- `premium_upsell`
- `settings_help`

### Step 2: Create Audiences (Optional)

Navigate to **Audiences** tab to target specific users:

**Free Users Audience:**
- Name: "Free Users"
- Filters: `plan` equals `free`
- Logic: AND

**High Value Cart Audience:**
- Name: "High Value Cart"
- Filters: `cart_value` greater than `50`
- Logic: AND

**US Free Users Audience:**
- Name: "US Free Users"
- Filters:
  - `plan` equals `free`
  - `country` equals `US`
- Logic: AND

### Step 3: Create Campaigns

Navigate to **Campaigns** tab:

**Main Onboarding Campaign:**
- Name: "Main App Onboarding"
- Placement: `main`
- Flow: Select your welcome flow
- Audience: All Users (or leave blank)
- Status: Active

**Feature Discovery Campaign:**
- Name: "Feature Discovery for Free Users"
- Placement: `feature_discovery`
- Flow: Select your feature discovery flow
- Audience: Free Users
- Status: Active

**Upsell Campaign:**
- Name: "Premium Upsell"
- Placement: `premium_upsell`
- Flow: Select your upsell flow
- Audience: High Value Cart
- Status: Active

### Step 4: A/B Testing (Optional)

To run an A/B test:

1. Create a campaign
2. Add multiple variants:
   - Variant A: 50% traffic, Flow 1
   - Variant B: 50% traffic, Flow 2
3. View results in Analytics tab

## Testing

### Reset Onboarding

To see the onboarding again during development:

```swift
Button("Reset Onboarding") {
    FCKOnboarding.shared.reset()
    // Restart your app to see onboarding again
}
```

### Force Network Fetch

For testing without cache:

```swift
FCKOnboarding.configure(
    apiKey: "your-key",
    cachePolicy: .networkOnly  // Always fetch fresh
)
```

### Test Different User Properties

```swift
// Test as free user
.onboardingGate(
    placement: "premium_upsell",
    userProperties: ["plan": "free"]
)

// Test as premium user (shouldn't see upsell)
.onboardingGate(
    placement: "premium_upsell",
    userProperties: ["plan": "premium"]
)
```

## Common Patterns

### 1. Conditional Placement

Only show onboarding if certain conditions are met:

```swift
.onboardingGate(
    placement: showWelcome ? "main" : nil,
    onComplete: { showWelcome = false }
)
```

### 2. Chained Onboarding

Show multiple onboardings in sequence:

```swift
@State private var currentStep = 0

var body: some View {
    content
        .onboardingGate(
            placement: steps[currentStep],
            onComplete: {
                if currentStep < steps.count - 1 {
                    currentStep += 1
                }
            }
        )
}
```

### 3. User Property Helpers

Create a helper to get consistent user properties:

```swift
extension UserSession {
    var onboardingProperties: [String: Any] {
        return [
            "plan": userPlan,
            "country": userCountry,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "daysSinceSignup": daysSinceSignup,
            "hasCompletedProfile": hasCompletedProfile
        ]
    }
}

// Use everywhere:
.onboardingGate(
    placement: "feature",
    userProperties: UserSession.shared.onboardingProperties
)
```

## Troubleshooting

### Onboarding Not Showing?

1. **Check API Key**: Verify it's correct in configuration
2. **Check Placement Name**: Must match exactly in dashboard
3. **Check Campaign**: Ensure campaign is active and linked to placement
4. **Check Audience**: User properties might not match filters
5. **Check Completion**: User may have already completed
6. **Check Console**: Look for error messages

### User Already Completed

```swift
// Check completion status
let completed = try await FCKOnboarding.shared.checkCompletion()
print("Has completed: \(completed)")

// Reset to test again
FCKOnboarding.shared.reset()
```

### Testing A/B Variants

Variants are assigned randomly, but sticky. To test both:

1. Reset SDK: `FCKOnboarding.shared.reset()`
2. Delete and reinstall app (new device ID)
3. Or use different simulators

## Next Steps

- 📖 Read the [full SDK documentation](../../README.md)
- 🎨 Design flows in the [visual builder](https://fckonboarding.com/builder)
- 📊 View analytics in the [dashboard](https://fckonboarding.com/dashboard)
- 💬 Join our [Discord community](https://discord.gg/fckonboarding)

## License

MIT License - See LICENSE file in repository root

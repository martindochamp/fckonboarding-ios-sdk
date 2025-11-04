# FCKOnboarding iOS SDK - Quick Start

Get your onboarding flow running in 5 minutes!

## Step 1: Add Package Dependency

In Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/yourorg/fckonboarding-ios`
3. Add to your app target

Or in `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/yourorg/fckonboarding-ios", from: "1.0.0")
]
```

## Step 2: Configure SDK

In your `App.swift` or `AppDelegate.swift`:

```swift
import FCKOnboarding

@main
struct MyApp: App {
    init() {
        // Configure with your project ID from dashboard
        FCKOnboarding.configure(
            projectId: "f3aa686d-4b22-4a41-a314-f3a162473342", // Your project ID
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

## Step 3: Show Onboarding

In any view:

```swift
import SwiftUI
import FCKOnboarding

struct ContentView: View {
    @State private var showOnboarding = false

    var body: some View {
        VStack {
            Text("Welcome to My App!")
                .font(.largeTitle)

            Button("Show Onboarding") {
                showOnboarding = true
            }
        }
        .onAppear {
            // Show onboarding on first launch
            if !FCKOnboarding.shared.hasCompletedOnboarding() {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingFlowView { completed in
                if completed {
                    // User completed onboarding
                    FCKOnboarding.shared.markCompleted()

                    // Access user responses
                    let responses = FCKOnboarding.shared.getUserResponses()
                    print("User's name: \(responses["name"] ?? "Unknown")")
                }
                showOnboarding = false
            }
        }
    }
}
```

## Step 4: Test It!

1. Run your app in simulator or device
2. The onboarding flow will automatically fetch from your dashboard
3. Any changes you make in the visual builder will appear instantly!

## Common Use Cases

### Full-Screen Modal (Recommended)
```swift
.sheet(isPresented: $showOnboarding) {
    OnboardingFlowView { completed in
        // Handle completion
    }
}
```

### Full-Screen Cover
```swift
.fullScreenCover(isPresented: $showOnboarding) {
    OnboardingFlowView { completed in
        // Handle completion
    }
}
```

### Navigation Push
```swift
NavigationLink(destination: OnboardingFlowView { completed in
    // Handle completion
}, isActive: $showOnboarding) {
    EmptyView()
}
```

## Getting User Responses

If your flow has input fields:

```swift
OnboardingFlowView { completed in
    if completed {
        let responses = FCKOnboarding.shared.getUserResponses()

        // Access specific fields by their element ID
        let userName = responses["user_name_input_id"]
        let userEmail = responses["email_input_id"]
        let selectedGoals = responses["goals_choice_id"]

        print("Name: \(userName ?? "")")
        print("Email: \(userEmail ?? "")")
        print("Goals: \(selectedGoals ?? "")")

        // Save to your backend or UserDefaults
        UserDefaults.standard.set(userName, forKey: "userName")
    }
}
```

## Reset Onboarding (For Testing)

```swift
// Clear onboarding state and cache
FCKOnboarding.shared.reset()

// Show onboarding again
showOnboarding = true
```

## Offline Support

The SDK automatically caches flows locally:

```swift
// Cache-first (default) - Fast, uses cache then updates
FCKOnboarding.configure(
    projectId: "your-id",
    cachePolicy: .cacheFirst
)

// Network-first - Always fresh, falls back to cache
FCKOnboarding.configure(
    projectId: "your-id",
    cachePolicy: .networkFirst
)

// Network-only - Always fetch, no cache
FCKOnboarding.configure(
    projectId: "your-id",
    cachePolicy: .networkOnly
)
```

## Custom Analytics

Track custom events:

```swift
// Track custom event
try? await FCKOnboarding.shared.trackEvent(
    name: "premium_feature_tapped",
    properties: [
        "feature": "dark_mode",
        "source": "onboarding"
    ]
)
```

## Troubleshooting

### Flow Not Loading?
1. Check your project ID is correct
2. Ensure you have an active flow published in dashboard
3. Check network connection
4. Look for errors in console

### Need to Test Changes?
1. Clear app cache: Delete app and reinstall
2. Or reset SDK: `FCKOnboarding.shared.reset()`
3. Force network fetch: Use `.networkOnly` cache policy

### Simulator Issues?
- Make sure simulator has internet access
- Try resetting simulator: Device → Erase All Content and Settings

## Next Steps

- 📖 Read full [API Documentation](README.md)
- 🎨 Customize flows in [Dashboard](https://fckonboarding.com/dashboard)
- 💬 Join [Discord Community](https://discord.gg/fckonboarding)
- 📧 Email support: support@fckonboarding.com

## Example Project

Check out the complete example app in `Examples/BasicIntegration/`

---

**Built with 💚 by the FCKOnboarding team**

# FCKOnboarding iOS SDK

Native SwiftUI SDK for rendering dynamic onboarding flows created with the fckonboarding visual builder.

## Features

- 🎨 **Native SwiftUI Rendering** - All elements render as native SwiftUI views
- ⚡️ **Fast & Lightweight** - No web views, pure native code
- 💾 **Smart Caching** - Flows cached locally for offline support
- 📊 **Analytics Built-in** - Track views, completions, drop-offs automatically
- 🔄 **Auto-Updates** - Flows update without app releases
- 🎯 **Type-Safe** - Full Swift type safety with Codable

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourorg/fckonboarding-ios", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter repository URL
3. Add to your target

## Quick Start

### 1. Initialize SDK

```swift
import FCKOnboarding

// In your App struct
@main
struct YourApp: App {
    init() {
        FCKOnboarding.configure(
            projectId: "your-project-id",
            apiKey: "your-api-key", // Optional for now
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

### 2. Show Onboarding Flow

```swift
import SwiftUI
import FCKOnboarding

struct ContentView: View {
    @State private var showOnboarding = false

    var body: some View {
        VStack {
            Text("Your App")
        }
        .onAppear {
            // Check if user needs onboarding
            if !FCKOnboarding.shared.hasCompletedOnboarding() {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingFlowView { completed in
                if completed {
                    FCKOnboarding.shared.markCompleted()
                    showOnboarding = false
                }
            }
        }
    }
}
```

### 3. Handle Completion

```swift
OnboardingFlowView { completed in
    if completed {
        // User completed onboarding
        FCKOnboarding.shared.markCompleted()

        // Get user responses (if using input fields)
        let responses = FCKOnboarding.shared.getUserResponses()
        print("User name: \(responses["name"] ?? "")")

        showOnboarding = false
    } else {
        // User skipped or dismissed
        showOnboarding = false
    }
}
```

## API Reference

### Configuration

```swift
FCKOnboarding.configure(
    projectId: String,          // Your project ID from dashboard
    apiKey: String?,            // Optional API key
    environment: Environment,   // .production or .staging
    cachePolicy: CachePolicy    // .cacheFirst or .networkFirst
)
```

### Check Onboarding Status

```swift
// Check if user has completed onboarding
let hasCompleted = FCKOnboarding.shared.hasCompletedOnboarding()

// Reset onboarding (for testing)
FCKOnboarding.shared.reset()
```

### User Responses

```swift
// Get all user responses from input fields
let responses: [String: String] = FCKOnboarding.shared.getUserResponses()

// Get specific response
if let userName = responses["name"] {
    print("User entered name: \(userName)")
}
```

### Analytics

```swift
// Manually track custom events
FCKOnboarding.shared.trackEvent(
    name: "custom_action",
    properties: ["button": "skip"]
)
```

## Architecture

```
sdk-ios/
├── Package.swift              # SPM manifest
├── README.md                  # This file
└── Sources/
    └── FCKOnboarding/
        ├── Models/            # Flow, Screen, Element models
        │   ├── FlowConfig.swift
        │   ├── FlowScreen.swift
        │   └── FlowElement.swift
        ├── Network/           # API client
        │   ├── FCKAPIClient.swift
        │   └── FCKEndpoints.swift
        ├── Renderer/          # SwiftUI views
        │   ├── OnboardingFlowView.swift
        │   ├── ScreenView.swift
        │   └── ElementRenderer.swift
        ├── Cache/             # Local storage
        │   ├── FlowCache.swift
        │   └── UserDefaults+Extension.swift
        └── FCKOnboarding.swift # Main SDK class
```

## Element Support

All elements from the visual builder are supported:

- ✅ **Stack** - Vertical/horizontal containers
- ✅ **Text** - Rich text with styling
- ✅ **Image** - Network images with caching
- ✅ **Button** - Tap actions (next, skip, complete)
- ✅ **Input** - Text input fields
- ✅ **DatePicker** - Date selection
- ✅ **SingleChoice** - Radio buttons with icons
- ✅ **MultipleChoice** - Checkboxes with icons

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Examples

See the `Examples/` folder for:
- Basic integration
- Custom styling
- Advanced flows with logic
- Testing & debugging

## License

MIT License - See LICENSE file

## Support

- 📧 Email: support@fckonboarding.com
- 💬 Discord: [Join our community](https://discord.gg/fckonboarding)
- 📖 Docs: https://docs.fckonboarding.com

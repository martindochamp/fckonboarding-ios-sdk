# FCKOnboarding iOS SDK

**Build onboarding flows visually. Display them natively. Update them instantly.**

No code changes. No app releases. Just beautiful, native SwiftUI onboarding that you control from a dashboard.

---

## Why FCKOnboarding?

```swift
// Traditional approach: Hardcoded onboarding in your app
// ❌ Requires code changes to update
// ❌ Requires app releases for tweaks
// ❌ Can't A/B test without complex setup

// FCKOnboarding approach: Visual builder + native SDK
.onboardingGate()  // ← That's it!

// ✅ Update flows instantly from dashboard
// ✅ A/B test different variations
// ✅ Target specific user segments
// ✅ Native SwiftUI rendering (no web views)
```

---

## Quick Start

**Just want to get started?** → [60-Second Quickstart Guide](QUICKSTART.md)

Or follow these 3 steps:

### 1. Install SDK

```swift
// In Xcode: File → Add Package Dependencies
https://github.com/martindochamp/fckonboarding-ios-sdk
```

### 2. Configure

```swift
import FCKOnboarding

@main
struct YourApp: App {
    init() {
        FCKOnboarding.configure(
            apiKey: "YOUR_API_KEY",
            environment: .production
        )
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

### 3. Add OnboardingGate

```swift
struct ContentView: View {
    var body: some View {
        YourMainView()
            .onboardingGate()  // ← Shows onboarding when needed
    }
}
```

**Done!** Now create flows in the [dashboard](https://fckonboarding.com/dashboard) and they'll appear in your app automatically.

---

## Features

### For Product Teams
- 🎨 **Visual Flow Builder** - Design onboarding without coding
- 🚀 **Instant Updates** - Change flows without app releases
- 📊 **Built-in Analytics** - Track views, completions, drop-offs
- 🔬 **A/B Testing** - Test different flows and variants
- 🎯 **User Targeting** - Show different flows to different users
- 🎭 **Multiple Placements** - Different flows at different trigger points

### For Developers
- ⚡️ **3-Line Integration** - Seriously, just 3 lines of code
- 🎨 **Native SwiftUI** - No web views, pure native rendering
- 💾 **Smart Caching** - Offline support out of the box
- 🔒 **Type-Safe** - Full Swift type safety
- 📦 **Zero Dependencies** - No external frameworks
- 🧪 **Easy Testing** - Simple reset() for development

---

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  Dashboard (You)                                            │
│  ↓                                                          │
│  1. Create flow visually (drag & drop)                     │
│  2. Publish flow                                            │
│  3. Create campaign linking flow to placement "main"        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  iOS App (User)                                             │
│  ↓                                                          │
│  1. App launches                                            │
│  2. SDK checks placement "main"                             │
│  3. SDK fetches flow JSON from API                          │
│  4. SDK renders flow as native SwiftUI                      │
│  5. User interacts with native UI                           │
│  6. SDK saves responses & tracks analytics                  │
└─────────────────────────────────────────────────────────────┘
```

**The magic:** Change the flow in the dashboard → It updates in the app → No code, no release.

---

## Usage Examples

### Basic Integration

```swift
import SwiftUI
import FCKOnboarding

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Welcome to My App")
            // Your app content
        }
        .onboardingGate()  // ← Automatically shows/hides onboarding
    }
}
```

### Multiple Placements

Show different flows at different points in your app:

```swift
// Main onboarding when app launches
MainView()
    .onboardingGate(placement: "main")

// Feature tutorial when user opens a feature
FeatureView()
    .onboardingGate(placement: "feature_discovery")

// Upsell flow before checkout
CheckoutView()
    .onboardingGate(placement: "premium_upsell")
```

**In Dashboard:** Create separate campaigns for each placement name.

### User Targeting

Show flows only to specific users:

```swift
.onboardingGate(
    placement: "premium_upsell",
    userProperties: [
        "plan": "free",              // User's subscription plan
        "country": "US",             // User's country
        "appVersion": "2.1.0",       // App version
        "daysSinceSignup": 7,        // Account age
        "hasCompletedProfile": false // Custom property
    ]
)
```

**In Dashboard:** Create audiences with AND/OR conditions matching these properties.

### Handle Completion

Get notified and access user responses:

```swift
.onboardingGate(
    placement: "main",
    onComplete: {
        print("User completed onboarding!")

        // Access user input from forms
        let responses = FCKOnboarding.shared.getUserResponses()
        let name = responses["name_input"]
        let email = responses["email_input"]
        let goals = responses["goals_choice"]

        // Save to your backend
        saveUserProfile(name: name, email: email, goals: goals)
    }
)
```

### Manual Control (Advanced)

If you need more control over when/how onboarding appears:

```swift
struct ContentView: View {
    @State private var flowConfig: FlowConfig?
    @State private var showOnboarding = false

    var body: some View {
        YourMainView()
            .task {
                // Check if onboarding should show
                if let config = try? await FCKOnboarding.shared.presentIfNeeded(
                    for: "main",
                    userProperties: ["plan": "free"]
                ) {
                    flowConfig = config
                    showOnboarding = true
                }
            }
            .sheet(isPresented: $showOnboarding) {
                if let config = flowConfig {
                    OnboardingFlowView(config: config) {
                        Task {
                            await FCKOnboarding.shared.markCompleted()
                            showOnboarding = false
                        }
                    }
                }
            }
    }
}
```

---

## API Reference

### Configuration

```swift
FCKOnboarding.configure(
    apiKey: String,             // Required: Get from dashboard
    environment: Environment,   // .production, .staging, or .custom(url)
    cachePolicy: CachePolicy    // .cacheFirst, .networkFirst, .networkOnly
)
```

**Environments:**
- `.production` → `https://fckonboarding.com/api/sdk`
- `.staging` → `https://staging.fckonboarding.com/api/sdk`
- `.custom("https://your-url.com/api/sdk")` → Custom URL

**Cache Policies:**
- `.cacheFirst` (default) → Fast startup, uses cache then updates in background
- `.networkFirst` → Always fetch fresh, fallback to cache if offline
- `.networkOnly` → Always fetch fresh, no caching (testing only)

### Set User ID

```swift
// Optional: Set custom user ID for authenticated users
// If not set, SDK uses device ID (IDFV) automatically
FCKOnboarding.shared.setUserId("user-123")
```

### Present Onboarding

```swift
// Easy way: Using OnboardingGate modifier
.onboardingGate(
    placement: String = "main",           // Placement name
    userProperties: [String: Any]? = nil, // User targeting properties
    onComplete: (() -> Void)? = nil       // Completion callback
)

// Manual way: Fetch and present yourself
let config = try await FCKOnboarding.shared.presentIfNeeded(
    for: "main",
    userProperties: ["plan": "free"]
)
```

### Completion Status

```swift
// Check if user has completed (queries backend)
let hasCompleted = try await FCKOnboarding.shared.checkCompletion()

// Mark as completed (syncs with backend)
await FCKOnboarding.shared.markCompleted()

// Reset for testing (clears local cache and completion)
FCKOnboarding.shared.reset()
```

### User Responses

```swift
// Get all responses from input fields
let responses: [String: String] = FCKOnboarding.shared.getUserResponses()

// Access specific response (key = element ID from builder)
let userName = responses["name_input"]
let userEmail = responses["email_input"]

// Manually save a response
FCKOnboarding.shared.saveResponse(key: "preference", value: "darkMode")
```

### Custom Analytics

```swift
// Track custom events
try await FCKOnboarding.shared.trackEvent(
    name: "button_tapped",
    flowId: nil,           // Auto-detected if in onboarding flow
    screenId: nil,         // Auto-detected if on specific screen
    properties: [
        "button": "upgrade",
        "source": "onboarding"
    ]
)
```

---

## Dashboard Setup

### 1. Get API Key

1. Go to [Dashboard → Settings → API Keys](https://fckonboarding.com/dashboard/settings)
2. Copy your project's API key
3. Use in `FCKOnboarding.configure(apiKey: "...")`

### 2. Create a Flow

1. Go to [Dashboard → Flows](https://fckonboarding.com/dashboard/flows)
2. Click **"New Flow"**
3. Design your onboarding:
   - Add screens
   - Drag elements (text, images, buttons, inputs)
   - Customize styles and spacing
4. Click **"Publish"**

**Supported Elements:**
- **Stack** - Container (vertical/horizontal)
- **Text** - Styled text labels
- **Image** - Images from URLs
- **Button** - Tap actions (next, skip, complete)
- **Input** - Text input fields
- **DatePicker** - Date selection
- **SingleChoice** - Radio buttons with icons
- **MultipleChoice** - Checkboxes with icons

### 3. Create a Placement

1. Go to [Dashboard → Placements](https://fckonboarding.com/dashboard/placements)
2. Click **"New Placement"**
3. Name it (e.g., "main", "feature_tutorial", "checkout")
4. Click **"Create"**

**What are placements?** Simple trigger point names that match your code:
```swift
.onboardingGate(placement: "main")  // ← Must match placement name
```

### 4. Create a Campaign

1. Go to [Dashboard → Campaigns](https://fckonboarding.com/dashboard/campaigns)
2. Click **"New Campaign"**
3. Configure:
   - **Name**: Give it a descriptive name
   - **Placement**: Select the placement
   - **Flow**: Select your published flow
   - **Audience** (optional): Target specific users
   - **Priority**: Higher number = higher priority
4. Click **"Save"**
5. Toggle to **"Active"** ✅

### 5. (Optional) Create Audiences

For user targeting:

1. Go to [Dashboard → Audiences](https://fckonboarding.com/dashboard/audiences)
2. Click **"New Audience"**
3. Add filters with AND/OR logic:
   - `plan equals "free"`
   - `country equals "US"`
   - `daysSinceSignup greater than 7`
4. Use in campaigns to target specific users

---

## Advanced Features

### A/B Testing

Create campaign variants to test different flows:

1. Create multiple variants in a campaign
2. Assign traffic allocation % to each
3. SDK automatically assigns users to variants
4. View results in analytics dashboard

```swift
// No code changes needed!
.onboardingGate(placement: "main")

// SDK handles variant assignment automatically
```

### Sticky Sessions

Users are "sticky" assigned to variants:
- Once a user sees variant A, they'll always see variant A
- Prevents confusing experience from seeing different flows

### Holdout/Control Groups

Test if onboarding helps:
- Create a "control" variant with no flow
- Compare completion rates vs. flow variants
- See if onboarding actually improves engagement

### Traffic Allocation

Control what % of users see campaigns:
- Set total traffic % on campaign (e.g., 50%)
- Gradually roll out to more users
- Stop immediately if issues arise

---

## Requirements

- **iOS**: 15.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Dependencies**: None! Zero external dependencies.

---

## Installation

### Swift Package Manager (Recommended)

#### In Xcode

1. **File → Add Package Dependencies**
2. Enter repository URL:
   ```
   https://github.com/martindochamp/fckonboarding-ios-sdk
   ```
3. Select version and add to target

#### In Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/martindochamp/fckonboarding-ios-sdk", from: "1.0.0")
]
```

### CocoaPods (Coming Soon)

```ruby
pod 'FCKOnboarding', '~> 1.0'
```

### Carthage (Coming Soon)

```
github "martindochamp/fckonboarding-ios-sdk" ~> 1.0
```

---

## Examples

Check out the `Examples/` folder for complete sample apps:

- **[BasicExample](Examples/PlacementDemo/Examples/BasicExample.swift)** - Simplest possible integration
- **[ManualExample](Examples/PlacementDemo/Examples/ManualExample.swift)** - Manual control over presentation
- **[AdvancedExample](Examples/PlacementDemo/Examples/AdvancedExample.swift)** - User targeting, multiple placements

---

## Troubleshooting

### Flow not showing?

**Common causes:**

1. **API Key incorrect**
   - Check in `FCKOnboarding.configure()`
   - Get fresh key from dashboard settings

2. **Placement name mismatch**
   - Code: `.onboardingGate(placement: "main")`
   - Dashboard: Campaign must target placement "main" (exact match)

3. **Campaign not active**
   - Check campaign is toggled "Active" ✅
   - Check campaign dates (start/end)

4. **Flow not published**
   - Draft flows won't show
   - Click "Publish" in flow editor

5. **User already completed**
   - Once completed, won't show again (by design)
   - Use `FCKOnboarding.shared.reset()` during testing

6. **User in holdout group**
   - Check campaign traffic allocation %
   - Check variant assignment (might be control variant)

7. **Audience filters not matching**
   - Check userProperties passed to SDK
   - Check audience filters in campaign

### Debugging Tips

```swift
// Enable verbose logging (in debug builds)
#if DEBUG
FCKOnboarding.shared.setUserId("test-user-\(UUID().uuidString)")
print("Device ID:", UIDevice.current.identifierForVendor?.uuidString ?? "unknown")
#endif

// Check API response
Task {
    do {
        let response = try await FCKOnboarding.shared.fetchFlow(
            for: "main",
            userProperties: ["plan": "free"]
        )
        print("API Response:", response)
    } catch {
        print("API Error:", error)
    }
}

// Check completion status
Task {
    let completed = try await FCKOnboarding.shared.checkCompletion()
    print("User completed:", completed)
}
```

### Network Issues

- Check internet connection (especially in Simulator)
- Check firewall/VPN not blocking requests
- Try `.networkOnly` cache policy to bypass cache
- Check Console app for detailed network logs

### Build Issues

```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset package cache
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build

# Resolve packages fresh
File → Packages → Reset Package Caches
File → Packages → Update to Latest Package Versions
```

---

## Performance

### Metrics

- **Cold start**: ~200ms (cache hit)
- **Network fetch**: ~300-500ms (typical)
- **Memory usage**: ~2MB per flow
- **Binary size impact**: ~100KB

### Optimization Tips

- Use `.cacheFirst` in production (default)
- Cache expires after 24h by default
- Flows are cached per-placement
- Images lazy-load and cache automatically

---

## Architecture

For deep technical details, see [ARCHITECTURE.md](ARCHITECTURE.md).

**Quick overview:**

```
┌─────────────────────────────────────────────────┐
│  Your App                                       │
│  ↓                                             │
│  .onboardingGate(placement: "main")            │
│  ↓                                             │
│  FCKOnboarding.shared                          │
│  ↓                                             │
│  FCKAPIClient → /api/sdk/placement/main        │
│  ↓                                             │
│  FlowCache (UserDefaults + FileManager)        │
│  ↓                                             │
│  OnboardingFlowView (SwiftUI)                  │
│  ↓                                             │
│  ElementRenderer → Native SwiftUI Views        │
└─────────────────────────────────────────────────┘
```

---

## Roadmap

### v1.1 (Next)
- [ ] Unit test suite
- [ ] CocoaPods support
- [ ] Carthage support
- [ ] SwiftUI previews for flows

### v1.2
- [ ] Custom fonts support
- [ ] Lottie animations
- [ ] Video elements
- [ ] iPad-specific layouts

### v2.0 (Future)
- [ ] visionOS support
- [ ] watchOS support
- [ ] macOS support
- [ ] Advanced animations

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Areas where we'd love help:**
- Unit tests
- Example apps
- Documentation improvements
- Bug fixes
- Feature requests

---

## Support

- **📖 Documentation**: You're reading it!
- **🚀 Quickstart**: [60-Second Guide](QUICKSTART.md)
- **🏗️ Architecture**: [Technical Deep-Dive](ARCHITECTURE.md)
- **💬 Discord**: [Join Community](https://discord.gg/fckonboarding)
- **📧 Email**: [support@fckonboarding.com](mailto:support@fckonboarding.com)
- **🐛 Issues**: [GitHub Issues](https://github.com/martindochamp/fckonboarding-ios-sdk/issues)

---

## License

MIT License - see [LICENSE](LICENSE) file.

---

## Credits

Built with ❤️ by the FCKOnboarding team.

Inspired by [Superwall](https://superwall.com) but fully open-source and developer-friendly.

---

**Ready to get started?** → [60-Second Quickstart](QUICKSTART.md)

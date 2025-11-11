# iOS SDK - 60-Second Quickstart

Get beautiful native onboarding flows running in **under 60 seconds**.

## What You'll Get

A fully functional onboarding flow that:
- Shows automatically on app launch
- Renders natively in SwiftUI (no web views)
- Updates instantly without app releases
- Tracks analytics automatically

## Prerequisites

- iOS 15.0+
- Xcode 15.0+
- A free fckonboarding account

---

## Step 1: Get Your API Key (10 seconds)

1. Go to [fckonboarding.com/dashboard](https://fckonboarding.com/dashboard)
2. Sign up or log in
3. Navigate to **Settings → API Keys**
4. Copy your API key

---

## Step 2: Add the SDK (15 seconds)

### Using Xcode

1. Open your project in Xcode
2. **File → Add Package Dependencies**
3. Paste this URL:
   ```
   https://github.com/martindochamp/fckonboarding-ios-sdk
   ```
4. Click **Add Package**
5. Select your app target
6. Click **Add Package** again

### Or Using Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/martindochamp/fckonboarding-ios-sdk", from: "1.0.0")
]
```

---

## Step 3: Configure SDK (20 seconds)

Open your `App.swift` file and add these lines:

```swift
import SwiftUI
import FCKOnboarding  // ← Add this

@main
struct YourApp: App {
    init() {
        // ← Add this configuration
        FCKOnboarding.configure(
            apiKey: "YOUR_API_KEY_HERE",  // Paste your API key
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

**That's it for code setup!** ✨

---

## Step 4: Add Onboarding Gate (15 seconds)

Open your main `ContentView.swift` and add `.onboardingGate()`:

```swift
import SwiftUI
import FCKOnboarding  // ← Add this if not already there

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Welcome to My App!")
                .font(.largeTitle)

            // Your app content here
        }
        .onboardingGate()  // ← Add this single line!
    }
}
```

**Done!** Your app is now ready to show onboarding flows. 🎉

---

## Step 5: Create Your First Flow (Dashboard)

Now let's create a flow in the dashboard:

### 5a. Create a Flow

1. Go to [Dashboard → Flows](https://fckonboarding.com/dashboard/flows)
2. Click **"New Flow"**
3. Design your onboarding (drag & drop interface)
4. Click **"Publish"**

### 5b. Create a Placement

1. Go to [Dashboard → Placements](https://fckonboarding.com/dashboard/placements)
2. Click **"New Placement"**
3. Name it: **`main`** (this matches the code)
4. Click **"Create"**

### 5c. Create a Campaign

1. Go to [Dashboard → Campaigns](https://fckonboarding.com/dashboard/campaigns)
2. Click **"New Campaign"**
3. Fill in:
   - **Name**: "Welcome Campaign"
   - **Placement**: Select "main"
   - **Flow**: Select your published flow
4. Click **"Save"**
5. Toggle the campaign to **"Active"** ✅

---

## Step 6: Test It! 🚀

1. Build and run your app (⌘R)
2. Your onboarding flow appears automatically!
3. Complete it
4. Check your dashboard to see analytics

---

## What Just Happened?

```
You created a flow visually → Published it → Connected it to "main" placement
                                                                    ↓
Your app checks the "main" placement → SDK fetches the flow → Renders natively
```

**The magic:** Change your flow in the dashboard and it updates in your app instantly - no code changes, no app release needed!

---

## Common Patterns

### Multiple Placements

Show different flows at different points:

```swift
// Main onboarding on launch
ContentView()
    .onboardingGate(placement: "main")

// Feature tutorial when user navigates to feature
FeatureView()
    .onboardingGate(placement: "feature_tutorial")

// Premium upsell before checkout
CheckoutView()
    .onboardingGate(placement: "premium_upsell")
```

**In Dashboard:** Create campaigns for "feature_tutorial" and "premium_upsell"

### User Targeting

Show flows to specific users:

```swift
.onboardingGate(
    placement: "premium_upsell",
    userProperties: [
        "plan": "free",
        "country": "US",
        "signupDate": "2024-01-15"
    ]
)
```

**In Dashboard:** Create audiences with filters matching these properties

### Access User Responses

Get input from onboarding forms:

```swift
.onboardingGate(
    placement: "main",
    onComplete: {
        let responses = FCKOnboarding.shared.getUserResponses()
        let userName = responses["name_input"]
        let userEmail = responses["email_input"]

        print("User: \(userName ?? ""), Email: \(userEmail ?? "")")

        // Save to your backend or UserDefaults
    }
)
```

---

## Reset Onboarding (For Testing)

During development, reset to see onboarding again:

```swift
FCKOnboarding.shared.reset()
// Then restart your app
```

---

## Troubleshooting

### Flow not showing?

1. **Check API Key**: Make sure it's correct in `configure()`
2. **Check Placement**: Name must match exactly ("main" in code = "main" in dashboard)
3. **Check Campaign**: Must be **Active** and linked to your placement
4. **Check Flow**: Must be **Published** (not draft)
5. **Try Reset**: `FCKOnboarding.shared.reset()` then restart app

### Already completed?

Once a user completes onboarding, they won't see it again (by design). Use `reset()` during testing.

### Simulator not loading?

- Check internet connection
- Check Console for error messages
- Try clearing derived data: Xcode → Product → Clean Build Folder

---

## What's Next?

- **[Full API Documentation](README.md)** - All SDK features and options
- **[Dashboard Guide](DASHBOARD.md)** - Visual guide to dashboard features
- **[Examples](Examples/)** - Sample apps showing different patterns
- **[Architecture Guide](ARCHITECTURE.md)** - How the SDK works internally

---

## Need Help?

- 📖 [Full Documentation](README.md)
- 💬 [Discord Community](https://discord.gg/fckonboarding)
- 📧 [Email Support](mailto:support@fckonboarding.com)
- 🐛 [GitHub Issues](https://github.com/martindochamp/fckonboarding-ios-sdk/issues)

---

**You're all set!** 🎉

Your app now has professional onboarding that you can update anytime, without code changes or app releases.

# FCKOnboarding iOS SDK - Architecture

> **📚 Advanced Documentation**
> This guide is for SDK contributors, advanced users, and those curious about internals.
> **Just getting started?** → See [60-Second Quickstart](QUICKSTART.md) or [README](README.md) instead.

---

## Overview

The iOS SDK is a native Swift Package that renders onboarding flows created in the fckonboarding visual builder. It uses SwiftUI for rendering and fetches flow configurations from the API at runtime using a **placement-based architecture** similar to Superwall.

## Design Principles

1. **Native First** - Pure SwiftUI, no web views
2. **Type Safe** - Full Codable support with Swift types
3. **Offline Ready** - Smart caching with fallbacks
4. **Placement-Based** - Show different flows at different trigger points
5. **Audience Targeting** - User property-based segmentation
6. **Backend-First** - Completion tracking and variant assignment on server
7. **Extensible** - Easy to customize and extend

## Module Structure

```
FCKOnboarding/
├── Models/              # Data models matching JSON schema
│   ├── FlowConfig.swift      # Root flow configuration
│   ├── FlowScreen.swift      # Individual screens
│   └── FlowElement.swift     # All element types (Stack, Text, Image, etc.)
│
├── Network/             # API communication
│   └── FCKAPIClient.swift    # HTTP client with placement-based endpoints
│       - fetchFlowForPlacement()
│       - checkCompletion()
│       - recordCompletion()
│       - trackEvent()
│
├── Cache/               # Local persistence
│   └── FlowCache.swift       # UserDefaults-based caching
│
├── Renderer/            # SwiftUI views
│   ├── OnboardingFlowView.swift   # Main entry point (TabView with screens)
│   ├── ScreenView.swift           # Individual screen renderer
│   └── ElementRenderer.swift      # Renders each element type
│
├── OnboardingGate.swift  # SwiftUI component for automatic presentation
└── FCKOnboarding.swift   # Main SDK singleton with placement methods
```

## Data Flow

### Placement-Based Flow Fetching

```
┌──────────────────┐
│   iOS App        │
│   ContentView    │
└──────┬───────────┘
       │ .onboardingGate(placement: "main", userProperties: {...})
       ▼
┌──────────────────┐
│ OnboardingGate   │
│ (SwiftUI)        │
└──────┬───────────┘
       │ 1. checkAndPresentOnboarding()
       ▼
┌──────────────────┐
│ FCKOnboarding    │
│ .presentIfNeeded │
└──────┬───────────┘
       │ 2. fetchFlowForPlacement("main", userProps)
       ▼
┌──────────────────────────────────┐     ┌──────────────┐
│  FCKAPIClient                     │────▶│  Cache       │
│  GET /api/sdk/placement/{name}    │     │  (UserDefs)  │
│  ?deviceId=xxx&userProperties={} │     └──────────────┘
└──────┬───────────────────────────┘
       │ 3. Return PlacementFlowResponse {
       │     flowId, config, placementId,
       │     campaignId, variantId, isControl
       │ }
       ▼
┌──────────────────┐
│ OnboardingGate   │ ← Return FlowConfig or nil
└──────┬───────────┘
       │ 4. If config exists, show OnboardingFlowView
       ▼
┌──────────────────┐
│ OnboardingFlowView│
│  (SwiftUI)       │
└──────┬───────────┘
       │ 5. Render screens
       ▼
┌──────────────────┐
│   ScreenView     │ → ForEach elements
└──────┬───────────┘
       │ 6. Render elements
       ▼
┌──────────────────┐
│ ElementRenderer  │
│ - StackView      │
│ - TextView       │
│ - ImageView      │
│ - ButtonView     │
│ - InputView      │
│ - DatePickerView │
│ - ChoiceView     │
└──────┬───────────┘
       │ 7. User completes
       ▼
┌──────────────────────────────┐
│ FCKOnboarding.markCompleted()│
│ POST /api/sdk/completion      │
│ {deviceId, flowId, variantId, │
│  responses, ...}              │
└───────────────────────────────┘
```

## Placement-Based Architecture

### Key Concepts

**Placements**: Trigger points in your app where onboarding can appear
- Each placement has a unique name (e.g., "main", "checkout", "feature_discovery")
- Multiple campaigns can target the same placement
- Priority-based selection when multiple campaigns match

**Audiences**: User segments defined by filter conditions
- Filters based on user properties (plan, country, etc.)
- AND/OR logic for complex targeting
- Evaluated on backend for each request

**Campaigns**: Connect flows to placements with targeting rules
- Link a flow to a placement
- Optional audience targeting
- Start/end dates
- Priority for conflict resolution
- A/B testing with variants

**Variants**: Different versions of a flow for A/B testing
- Each campaign can have multiple variants
- Traffic split percentage (e.g., 50% variant A, 50% variant B)
- Control group support (no flow shown)
- Sticky assignment (user always sees same variant)

### Backend Decision Logic

When SDK calls `GET /api/sdk/placement/{name}`:

1. **Find Active Campaigns**
   - Get all campaigns for the placement
   - Filter by active status and date range
   - Check if user completed this flow before

2. **Audience Matching**
   - Evaluate user properties against audience filters
   - Skip campaigns where audience doesn't match

3. **Select Campaign**
   - Sort by priority (highest first)
   - Return highest priority matching campaign

4. **Variant Assignment**
   - Check if user already assigned to variant (sticky)
   - If not, randomly assign based on traffic split
   - Store assignment for future requests
   - Return flow config or null (if control group)

5. **Response**
```json
{
  "flowId": "abc123",
  "name": "Welcome Flow",
  "config": { /* Full flow config */ },
  "placementId": "pl_main",
  "placementName": "main",
  "campaignId": "camp_001",
  "variantId": "var_a",
  "isControl": false,
  "isSticky": true,
  "message": "Flow matched"
}
```

### Completion Tracking

When user completes onboarding:

```swift
await FCKOnboarding.shared.markCompleted()
```

SDK sends to backend:
```json
POST /api/sdk/completion
{
  "deviceId": "XXX",
  "userId": "user-123",     // Optional
  "flowId": "abc123",
  "placementId": "pl_main",
  "campaignId": "camp_001",
  "variantId": "var_a",
  "responses": {            // User input data
    "name": "John",
    "email": "john@example.com"
  }
}
```

Backend:
- Records completion in database
- Links to specific variant for A/B test results
- Future requests for this placement return `null` (user completed)

### User Identification

SDK supports two user identification methods:

1. **Device ID (Automatic)**
   - Uses iOS IDFV (Identifier For Vendor)
   - Persists across app reinstalls (same vendor)
   - Unique per device

2. **Custom User ID (Optional)**
   ```swift
   FCKOnboarding.shared.setUserId("user-123")
   ```
   - For authenticated users
   - Enables cross-device tracking
   - Syncs completion status across devices

## JSON to SwiftUI Mapping

### Stack Element
```json
{
  "type": "stack",
  "direction": "vertical",
  "spacing": 16,
  "children": [...]
}
```
↓
```swift
VStack(spacing: 16) {
  ForEach(children) { child in
    ElementRenderer.render(child)
  }
}
```

### Text Element
```json
{
  "type": "text",
  "content": "Welcome!",
  "fontSize": 24,
  "color": "#000000",
  "fontWeight": "bold"
}
```
↓
```swift
Text("Welcome!")
  .font(.system(size: 24, weight: .bold))
  .foregroundColor(Color(hex: "#000000"))
```

### Image Element
```json
{
  "type": "image",
  "url": "https://cdn.example.com/logo.png",
  "height": 200,
  "objectFit": "cover"
}
```
↓
```swift
AsyncImage(url: URL(string: "...")) { image in
  image
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(height: 200)
}
```

## Caching Strategy

### Cache Policies

1. **cacheFirst** (Default)
   - Check cache → Use if exists
   - Fetch from network in background
   - Update cache silently
   - **Best for**: Fast app startup

2. **networkFirst**
   - Try network first
   - Fall back to cache if network fails
   - **Best for**: Always fresh content

3. **networkOnly**
   - Always fetch from network
   - No caching
   - **Best for**: Testing/debugging

### Cache Implementation

```swift
// Save to cache
let data = try JSONEncoder().encode(flow)
UserDefaults.standard.set(data, forKey: "cachedFlow")

// Load from cache
guard let data = UserDefaults.standard.data(forKey: "cachedFlow") else { return nil }
return try JSONDecoder().decode(FlowResponse.self, from: data)
```

## Analytics Tracking

Events automatically tracked:
- `flow_fetched` - When flow is loaded
- `flow_viewed` - When user sees onboarding
- `screen_viewed` - Each screen view
- `flow_completed` - User finishes onboarding
- `flow_skipped` - User dismisses onboarding

Custom events:
```swift
try? await FCKOnboarding.shared.trackEvent(
  name: "custom_action",
  properties: ["button": "premium"]
)
```

## User Response Storage

Input fields and choices save to UserDefaults:

```swift
// SDK saves automatically
element.id = "name_input"
→ UserDefaults["onboarding_responses"]["name_input"] = "John Doe"

// App retrieves
let responses = FCKOnboarding.shared.getUserResponses()
let name = responses["name_input"] // "John Doe"
```

## Spacing System

The SDK supports multiple CSS-like units:

```swift
"16px"    → 16 points
"2rem"    → 32 points (2 × 16)
"50%"     → 50% of parent width
"10vh"    → 10% of screen height
"auto"    → Automatic spacing
```

Converted to SwiftUI:
```swift
extension SpacingValue {
  var cgFloatValue: CGFloat {
    switch self {
    case .px(let val): return CGFloat(val)
    case .rem(let val): return CGFloat(val * 16)
    case .percent(let val): return /* Calculate from parent */
    // ...
    }
  }
}
```

## Error Handling

All API calls use Swift's async/await with proper error handling:

```swift
do {
  let flow = try await FCKOnboarding.shared.fetchFlow()
  // Success
} catch FCKAPIClient.APIError.noActiveFlow {
  // No flow published
} catch FCKAPIClient.APIError.networkError(let error) {
  // Network issue
} catch {
  // Other errors
}
```

## Threading Model

- **Main Thread**: All SwiftUI views, state updates
- **Background**: API calls, image loading, caching
- **Fire & Forget**: Analytics tracking (doesn't block)

```swift
// API call on background
Task {
  let flow = try await apiClient.fetchActiveFlow()
  await MainActor.run {
    // Update UI on main thread
    self.state = .loaded(flow)
  }
}
```

## Testing

### Unit Tests
- Model encoding/decoding
- API client responses
- Cache operations
- Spacing calculations

### Integration Tests
- Full flow fetch and render
- User interaction flows
- Error scenarios

### UI Tests
- SwiftUI preview providers
- Snapshot testing (future)

## Performance Considerations

1. **Image Loading**: Async with caching
2. **JSON Parsing**: Efficient Codable
3. **Lazy Loading**: TabView loads screens on demand
4. **Memory**: Weak references, value types
5. **Network**: URLSession with timeout

## Security

1. **HTTPS Only**: All API calls use TLS
2. **No Secrets**: API keys optional, safe to embed
3. **Sandbox**: UserDefaults app-scoped
4. **Input Validation**: Sanitize user inputs

## Future Enhancements

1. **SwiftUI Previews**: Better design-time preview
2. **Custom Renderers**: Let apps override element rendering
3. **Animation Library**: More transitions
4. **Offline Queue**: Retry analytics when back online
5. **Push Notifications**: Notify of flow updates

## Dependencies

**Zero external dependencies!**
- Pure Swift 5.9+
- SwiftUI (iOS 15+)
- Foundation (URLSession, Codable, UserDefaults)

## Contributing

See CONTRIBUTING.md for:
- Code style guide
- PR process
- Testing requirements
- Release process

---

**Questions?** Open an issue or join our Discord!

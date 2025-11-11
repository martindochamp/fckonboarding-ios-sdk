# Dashboard Setup Guide

Visual guide to setting up your first onboarding flow.

---

## Overview

The FCKOnboarding dashboard is where you design, publish, and manage onboarding flows. Think of it like this:

```
Dashboard           iOS App
---------           -------
Create Flow    →    Renders as native SwiftUI
Publish Flow   →    Available to SDK
Create Campaign →   Links flow to placement
Toggle Active  →    Users see it
```

---

## Step 1: Get Your API Key

**What it's for:** Authenticates your iOS app with the backend.

### How to get it:

1. Go to **[Dashboard](https://fckonboarding.com/dashboard)**
2. Sign up or log in
3. Click **Settings** (gear icon in sidebar)
4. Click **API Keys** tab
5. Copy your project's API key

### Where to use it:

```swift
FCKOnboarding.configure(
    apiKey: "YOUR_API_KEY_HERE",  // ← Paste it here
    environment: .production
)
```

**Security Notes:**
- API key is safe to use in mobile apps (read-only)
- Don't commit API keys to public repos (use environment variables)
- Regenerate if compromised

---

## Step 2: Create a Flow

**What it is:** The actual onboarding experience - screens, text, images, buttons, forms.

### How to create:

1. Go to **Dashboard → Flows**
2. Click **"New Flow"** button
3. Enter a name (e.g., "Welcome Onboarding")
4. Click **"Create"**

### Design your flow:

You're now in the **Flow Builder**. This is a drag-and-drop visual editor.

#### Add Screens:

- Click **"+ Add Screen"** button
- Each screen is one step in your onboarding
- Users swipe or tap buttons to navigate between screens

#### Add Elements:

Drag elements from the left panel onto your screen:

| Element | Use For |
|---------|---------|
| **Stack** | Container for other elements (vertical/horizontal layout) |
| **Text** | Headings, paragraphs, labels |
| **Image** | Photos, illustrations, logos |
| **Button** | Navigation (Next, Skip, Get Started) |
| **Input** | Collect text (name, email, etc.) |
| **DatePicker** | Collect dates (birthday, etc.) |
| **SingleChoice** | Pick one option (radio buttons) |
| **MultipleChoice** | Pick multiple options (checkboxes) |

#### Customize Styles:

Click any element to edit:
- **Text**: Font size, weight, color, alignment
- **Images**: URL, size, border radius
- **Buttons**: Text, action (next/skip/complete), color
- **Spacing**: Padding, margin (supports px, rem, %, vh, vw, auto)
- **Layout**: Alignment, direction (for stacks)

#### Set Element IDs:

For inputs and choices, set an **Element ID**:
- Used to retrieve user responses in your app
- Example: `"name_input"`, `"email_input"`, `"goals_choice"`

```swift
// Later in your app:
let responses = FCKOnboarding.shared.getUserResponses()
let userName = responses["name_input"]  // ← Matches element ID
```

### Publish:

1. Click **"Publish"** button (top right)
2. Confirm publishing
3. Flow is now available to SDK

**Draft vs. Published:**
- **Draft**: Still editing, not visible to SDK
- **Published**: Live, SDK can fetch it
- You can have multiple published versions

---

## Step 3: Create a Placement

**What it is:** A trigger point name that connects your dashboard to your code.

### How to create:

1. Go to **Dashboard → Placements**
2. Click **"New Placement"** button
3. Enter a name: `main` (or any name you want)
4. Click **"Create"**

### Common placement names:

| Placement Name | Use Case |
|----------------|----------|
| `main` | Main onboarding on app launch |
| `feature_discovery` | Tutorial when user opens a feature |
| `premium_upsell` | Upsell before checkout |
| `tips` | Helpful tips at certain points |
| `survey` | Feedback surveys |

### How it works:

```swift
// In your code:
.onboardingGate(placement: "main")  // ← Must match placement name in dashboard
```

When the SDK checks the "main" placement, the dashboard decides which flow to show based on campaigns.

**Note:** Placements are just names - no configuration needed! The logic lives in campaigns.

---

## Step 4: Create a Campaign

**What it is:** Links a flow to a placement and defines WHO sees it and WHEN.

### How to create:

1. Go to **Dashboard → Campaigns**
2. Click **"New Campaign"** button
3. Fill in the form:

#### Basic Settings:

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | Campaign name (for you) | "Welcome Campaign" |
| **Placement** | WHERE to show | "main" |
| **Status** | Active or Paused | Active ✅ |

#### Flow Assignment:

**Simple Mode** (Most common):
- Select one flow to show to all users

**A/B Test Mode**:
- Create multiple variants
- Assign traffic % to each
- SDK randomly assigns users to variants
- Compare performance in analytics

#### Audience Targeting (Optional):

- **No audience**: Show to all users
- **Select audience**: Show only to users matching filters

#### Advanced Settings:

| Field | Description | Default |
|-------|-------------|---------|
| **Priority** | If multiple campaigns match, higher wins | 0 |
| **Total Traffic** | % of users who see this campaign | 100% |
| **Start Date** | When campaign begins | Now |
| **End Date** | When campaign ends | Never |

### Save and Activate:

1. Click **"Save"**
2. Toggle the switch to **"Active"** ✅
3. Campaign is now live!

---

## Step 5: (Optional) Create Audiences

**What it is:** User segments based on properties you pass from your app.

### Why use audiences:

- Show different flows to free vs. premium users
- Target specific countries or languages
- Show onboarding based on feature usage
- Personalize based on signup date

### How to create:

1. Go to **Dashboard → Audiences**
2. Click **"New Audience"** button
3. Enter a name (e.g., "Free US Users")

#### Add Filters:

| Operator | Description | Example |
|----------|-------------|---------|
| **equals** | Exact match | `plan equals "free"` |
| **not_equals** | Doesn't match | `plan not_equals "premium"` |
| **contains** | Substring match | `email contains "@gmail.com"` |
| **greater_than** | Number comparison | `daysSinceSignup > 7` |
| **less_than** | Number comparison | `age < 18` |
| **in** | Matches any value in list | `country in ["US", "CA", "GB"]` |
| **exists** | Property is set | `email exists` |

#### Logic:

- **AND**: All conditions must match
- **OR**: Any condition matches
- **Nested**: Combine AND/OR groups

**Example:**
```
AND
  - plan equals "free"
  - country equals "US"
  OR
    - daysSinceSignup greater_than 7
    - hasCompletedProfile equals false
```

### Pass properties from app:

```swift
.onboardingGate(
    placement: "premium_upsell",
    userProperties: [
        "plan": "free",              // ← Must match filter property name
        "country": "US",
        "daysSinceSignup": 14,
        "hasCompletedProfile": true
    ]
)
```

### Use in campaigns:

When creating a campaign:
1. Select **Audience**
2. Choose your audience
3. Only users matching filters will see the flow

---

## Common Workflows

### Simple Onboarding (Most Common)

```
1. Create Flow → "Welcome Flow"
2. Publish Flow
3. Create Placement → "main"
4. Create Campaign:
   - Placement: "main"
   - Flow: "Welcome Flow"
   - No audience (show to all)
   - Active ✅
```

### A/B Test Two Flows

```
1. Create Flow → "Version A"
2. Create Flow → "Version B"
3. Publish both
4. Create Placement → "main"
5. Create Campaign:
   - Placement: "main"
   - Variants:
     - Version A: 50% traffic
     - Version B: 50% traffic
   - Active ✅
6. Check analytics to see which performs better
```

### Targeted Upsell

```
1. Create Flow → "Premium Benefits"
2. Publish Flow
3. Create Audience → "Free Users":
   - plan equals "free"
   - daysSinceSignup greater_than 7
4. Create Placement → "premium_upsell"
5. Create Campaign:
   - Placement: "premium_upsell"
   - Flow: "Premium Benefits"
   - Audience: "Free Users"
   - Active ✅
```

### Gradual Rollout

```
1. Create Flow → "New Onboarding"
2. Publish Flow
3. Create Placement → "main"
4. Create Campaign:
   - Placement: "main"
   - Flow: "New Onboarding"
   - Total Traffic: 10%  ← Start small
   - Active ✅
5. Monitor analytics
6. Increase traffic % over time (20%, 50%, 100%)
```

---

## Testing Your Setup

### In the Dashboard:

1. Go to **Dashboard → Flows**
2. Click **"Preview"** on your flow
3. Test the flow in the browser

### In Your App:

1. Build and run your iOS app
2. Flow should appear automatically
3. Complete the flow
4. Check **Dashboard → Analytics** to see the event

### Debugging Checklist:

- [ ] API key is correct in code
- [ ] Flow is **Published** (not draft)
- [ ] Placement name matches code exactly
- [ ] Campaign is **Active** ✅
- [ ] Campaign targets correct placement
- [ ] If using audience, properties match filters
- [ ] User hasn't already completed (try `FCKOnboarding.shared.reset()`)

---

## Analytics Dashboard

After users interact with your flows, check analytics:

### Where to find:

**Dashboard → Analytics**

### Metrics Available:

| Metric | Description |
|--------|-------------|
| **Total Views** | How many users saw the flow |
| **Completions** | How many finished the flow |
| **Completion Rate** | % of viewers who completed |
| **Drop-offs** | Where users quit |
| **Time to Complete** | Average duration |
| **Unique Users** | Distinct users |

### By Dimension:

- **By Flow**: Compare different flows
- **By Campaign**: Compare campaign performance
- **By Variant**: A/B test results
- **By Screen**: See drop-off points in flows
- **By Date**: Trends over time

### Export Data:

- Click **"Export CSV"** to download data
- Use for custom analysis or presentations

---

## Tips & Best Practices

### Flow Design:

- ✅ **Keep it short**: 3-5 screens max
- ✅ **Clear value prop**: Show benefits early
- ✅ **Use images**: Visual > text
- ✅ **Simple language**: Avoid jargon
- ✅ **Skip button**: Let users opt out
- ✅ **Mobile-first**: Test on iPhone SE size

### Campaigns:

- ✅ **Start with 100% traffic**: Validate it works first
- ✅ **Use descriptive names**: "Q1 2024 Welcome Campaign"
- ✅ **Set end dates**: For seasonal campaigns
- ✅ **Monitor analytics**: Check daily during rollout

### A/B Testing:

- ✅ **Test one thing**: Don't change everything
- ✅ **Wait for significance**: At least 100 users per variant
- ✅ **Define success metric**: Completion rate? Time? Engagement?
- ✅ **Document learnings**: Note what worked/didn't

### Audiences:

- ✅ **Start broad**: Don't over-target initially
- ✅ **Test filters**: Make sure properties are passed correctly
- ✅ **Document properties**: Keep a list of available properties
- ✅ **Use descriptive names**: "Free US Users 7+ Days"

---

## Troubleshooting

### "Flow not showing in app"

1. Check **Flow** is **Published**
2. Check **Campaign** is **Active** ✅
3. Check **Placement name** matches exactly
4. Check **API key** is correct
5. Try `FCKOnboarding.shared.reset()` in app

### "Audience not working"

1. Check **userProperties** passed from app
2. Check property **names match exactly** (case-sensitive)
3. Check property **types** (string vs. number)
4. Test with simpler audience first

### "Analytics not showing"

1. Check internet connection in app
2. Wait a few minutes (can be delayed)
3. Check Console for error messages
4. Verify API key is correct

---

## What's Next?

- **[iOS SDK Quickstart](QUICKSTART.md)** - Integrate SDK in 60 seconds
- **[Full SDK Documentation](README.md)** - All SDK features
- **[Architecture Guide](ARCHITECTURE.md)** - How it all works

---

## Need Help?

- 💬 **Discord**: [Join Community](https://discord.gg/fckonboarding)
- 📧 **Email**: [support@fckonboarding.com](mailto:support@fckonboarding.com)
- 📖 **Docs**: [docs.fckonboarding.com](https://docs.fckonboarding.com)

---

**You're all set!** 🎉

Start creating beautiful onboarding flows that you can update instantly!

# iOS Release Guide — dollars_to_yuan (no Mac required)

**Goal:** Get the app onto TestFlight and then the App Store using a *cloud Mac*
(Codemagic), since neither you nor your friend owns a Mac. Your **paid Apple
Developer account** authorizes distribution; Codemagic's rented Mac does the
compiling. You only need a browser + your iPhone.

> Bundle ID used in this project: **`com.wcs.DollarsToYuan`** (case-sensitive — registered in
> `ios/Runner.xcodeproj/project.pbxproj` and `codemagic.yaml`). This must exactly match what your
> friend registers in the Apple Developer portal (Part A1), including capitalization.

---

## Pre-reqs already done in code (no action needed)

These were implemented in the repo so the App Store review doesn't bounce the build:

- **App Tracking Transparency (ATT).** AdMob uses the IDFA, so iOS requires a
  tracking-permission prompt **before** any ad loads. `lib/main.dart` requests
  `AppTrackingTransparency.requestTrackingAuthorization()` *before*
  `MobileAds.instance.initialize()`, and `pubspec.yaml` includes
  `app_tracking_transparency`. `ios/Runner/Info.plist` has the
  `NSUserTrackingUsageDescription` string and **32** Google `SKAdNetworkItems`
  IDs. On first launch the user sees "Allow tracking?" — if they allow, ads are
  personalized; if they decline, the app still works (non-personalized ads).
- **Privacy Manifest (`PrivacyInfo.xcprivacy`).** Declares `NSPrivacyTracking =
  true`, the tracking domains (doubleclick.net, googleadservices.com, etc.),
  collected data types, and required-access API reasons. It's registered in
  `ios/Runner.xcodeproj/project.pbxproj` so it bundles into the IPA.

You do **not** need to touch any of this — it's already wired. Just be aware the
ATT prompt appears on first launch (Part C, step 4).

---

## Part A — One-time Apple setup (your friend / account holder, browser only)

All of this is done at **[developer.apple.com/account](https://developer.apple.com/account)**
and **[appstoreconnect.apple.com](https://appstoreconnect.apple.com)**. No Xcode,
no Mac.

### A1. Register the App ID / Bundle ID
1. Go to **Certificates, IDs & Profiles → Identifiers → + (New)**.
2. Choose **App IDs** → **App** → Continue.
3. Description: `Dollars To Yuan`.
4. Bundle ID: select **Explicit**, type `com.wcs.DollarsToYuan` **exactly as shown
   (capitalization matters — Apple is case-sensitive)**.
5. Under **Capabilities**, no special toggles are needed (no push/iCloud). Continue → Register.

### A2. Create the app record in App Store Connect
1. Open **[appstoreconnect.apple.com](https://appstoreconnect.apple.com)** → **Apps → + (New App)**.
2. Platform: **iOS**.
3. Name: `Dollars To Yuan`.
4. Primary language: your choice.
5. Bundle ID: pick **`com.wcs.DollarsToYuan`** (from A1).
6. SKU: anything unique, e.g. `dt2y-ios-1`.
7. User access: Full. → Create.

### A3. Generate an App Store Connect API key (so Codemagic can upload)
1. App Store Connect → **Users and Access → Integrations → App Store Connect API**.
2. **+ (Generate API Key)**.
3. Name: `Codemagic CI`. Access: **App Manager** (or Admin).
4. Download the `.p8` file (you only get it once — save it). Note the **Key ID** and **Issuer ID** (shown on the same page).

> Keep the `.p8`, Key ID, and Issuer ID handy for Part B.

---

## Part B — Codemagic setup (you, browser only)

1. Sign in at **[codemagic.io](https://codemagic.io)** with your GitHub account.
2. **Add application** → pick the **dollars_to_yuan** GitHub repo → **Flutter App**.
3. Under **Environment variables / Integrations**, add the **App Store Connect**
   integration and paste the **Key ID**, **Issuer ID**, and **Private Key** (the
   `.p8` contents) from A3. Save.
4. In the workflow editor, point Codemagic at the `codemagic.yaml` already in the
   repo (it's committed). Settings it needs (all in that file):
   - `APP_STORE_CONNECT_BUNDLE_ID = com.wcs.DollarsToYuan`
   - Flutter: **stable**, Xcode: **latest**
   - **Automatic code signing** enabled (uses the integration from step 3).
5. **Start new build** (or just push to `main` — the YAML triggers on push).

What Codemagic does automatically (per `codemagic.yaml`):
- `flutter pub get` → `pod install` (installs the AdMob & RevenueCat pods) →
  `flutter analyze` → `flutter test` → fetches signing → `flutter build ipa`
  → uploads to App Store Connect → **pushes to TestFlight**.

If any step fails, Codemagic emails you the log. Common fix: the bundle ID in
A1 must match `APP_STORE_CONNECT_BUNDLE_ID` exactly.

---

## Part C — Verify ads + premium on your iPhone (TestFlight)

This is your "confirm it works before release" gate:

1. App Store Connect → the app → **TestFlight** tab. Wait for the build to finish
   processing (can take a few minutes).
2. Add your Apple ID as an **Internal Tester** (Users and Access → TestFlight →
   Internal Testers → +).
3. On your iPhone, install **TestFlight** from the App Store, then open the
   invitation / redeem the code.
4. On first launch you'll see the **App Tracking Transparency** prompt
   ("Allow tracking?"). Tap **Allow** so AdMob can serve personalized ads (tapping
   Don't Allow is fine too — the app still works, just with non-personalized ads).
5. Test:
   - **Ads:** do enough conversions to cross the interstitial threshold — verify
     an interstitial actually shows (the iOS AdMob unit IDs are already real in
     `app_config.dart` / `Info.plist`).
   - **Premium:** open the paywall, tap a package → it should prompt a real
     **sandbox** purchase (Apple sandbox, not production). Complete it → ads
     should stop. Use **Settings → Restore Purchases** to confirm entitlement
     reloads.
   - (Sandbox testers are managed at App Store Connect → Users and Access →
     Sandbox → Testers. Add your Apple ID there so purchases use the test
     environment, not real money.)

---

## Part D — Submit for review

Only after Part C passes:

1. App Store Connect → app → **App Store** tab → fill **Required Information**
   (privacy policy URL, category, screenshots, description, age rating).
2. **TestFlight** tab → select the build → **Submit to App Review**.
3. Wait for Apple's review (usually 24–48h). Fix any rejection and rebuild via
   Codemagic.

---

## Gotchas / notes
- **Android AdMob IDs are still sample IDs** (`ca-app-pub-3940…`) in
  `app_config.dart`. They don't affect the iOS build but must be replaced before
  any Google Play release.
- The **RevenueCat Google key** is a placeholder test key — same, Android-only concern.
- **No Mac is ever required** from you. If Codemagic's free tier is insufficient,
  the alternative is a GitHub Actions macOS runner, but that needs more YAML wiring.
- Version is `1.0.0+1` in `pubspec.yaml`. Bump `version:` before each new
  TestFlight upload (Apple rejects duplicate build numbers).

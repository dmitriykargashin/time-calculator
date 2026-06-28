# iOS App Store Deployment Guide — Time Calculator Cardamon

<!-- Researched & web-verified June 2026. The volatile specifics (current Xcode
version, screenshot pixel sizes, fees, exact menu labels) change often — verify
them against the official Apple pages linked inline before you rely on them. -->

> **Build status (this repo).** The iOS app already **compiles, installs, launches,
> and renders** cleanly on the iOS Simulator (verified on iPhone 17 / iOS 26). Two
> build-config fixes were needed to get there and live in this branch:
> CocoaPods `1.10.1 → 1.16.2`, and the iOS deployment target `13.0 → 15.0` (required
> by `firebase_analytics`). So the remaining work below is **account / store / signing /
> listing** — not code.

A complete, beginner-friendly playbook to take this Flutter app from "no Apple account" to live on the App Store, and to serve as the team's reference. All file paths assume the Flutter project lives at `flutter_app/`.

> **Identity facts used throughout**
> - **App name:** Time Calculator Cardamon
> - **iOS bundle ID:** `com.cardamon.timeCalculator` (the **company** prefix — *deliberately independent* of the Android package `com.dmitriykargashin.cardamontimecalculator`; the two need not match, and Android's is locked because it is already published)
> - **Legal entity:** Cardamon Inc · **Account holder:** Dmitrii Kargashin · **Apple ID:** dmitriy.kargashin@gmail.com
> - **Version:** `2.4.0+28` → marketing version **2.4.0**, build number **28**
> - **Category:** Utilities · **Support email:** support@cardamon.org
> - **Privacy policy:** https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator

---

## Current state of THIS project

### Already configured (no action needed)

| Item | Value / status |
|---|---|
| iOS bundle identifier | `com.cardamon.timeCalculator` (Debug + Release + Profile) |
| Code-signing style | `CODE_SIGN_STYLE = Automatic` (correct; just needs a Team) |
| iOS deployment target | **iOS 15.0** (already raised from 13 — see note below) |
| Device family | iPhone **and** iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) → iPad screenshots are **required** |
| Orientations | iPhone: portrait + landscape; iPad: portrait, upside-down, landscape |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` set in `Info.plist` (lines 11–12) → no encryption prompt at upload |
| In-app purchase (iOS) | Freemium **Pro** paywall is fully implemented but **dormant** (`kApplePurchasesEnabled=false`; no StoreKit UI ships until flipped — see "Enable the iOS freemium / Pro paywall") |
| Firebase Analytics (iOS) | OFF (no `GoogleService-Info.plist`; `Firebase.initializeApp()` is try/caught, so it's silently disabled — no crash) |
| Plugin privacy manifests | Firebase + shared_preferences pods ship their own `PrivacyInfo.xcprivacy` (already present under `ios/Pods/...`) |

> **Note on the deployment target.** This project was raised from iOS 13 → **15.0** in this branch because **`firebase_analytics` 12.x (Firebase iOS SDK 12) requires iOS 15** — `pod install` fails with a lower target. This also aligns with the current Xcode toolchain's supported minimum. Dropping iOS 13/14 is a negligible slice of active devices (~99% are on iOS 15+). ([Xcode system requirements](https://developer.apple.com/xcode/system-requirements/))

### Still PENDING (this guide covers all of it)

- [ ] **Apple Developer Program** membership (the app has no account yet — this is step 0)
- [ ] **Signing Team** selected in Xcode (will auto-inject `DEVELOPMENT_TEAM`)
- [ ] **App ID** registered in the developer portal
- [ ] **App Store Connect** app record created
- [ ] **App-level `PrivacyInfo.xcprivacy`** in the Runner target (optional but recommended; see Privacy section)
- [ ] **App icon** (opaque 1024×1024) + **screenshots** (iPhone 6.9" *and* iPad 13")
- [ ] **App Privacy questionnaire** + **age rating** completed in App Store Connect
- [ ] *(Optional, later)* `GoogleService-Info.plist` to enable iOS Analytics; StoreKit/Pro for IAP

---

## Roadmap: from no account to live + updates

1. **Phase 0 — Prerequisites:** Mac + Xcode 26 or later, $99/yr account budget.
2. **Phase 1 — Enroll** in the Apple Developer Program (Organization, for Cardamon Inc — needs a D-U-N-S number).
3. **Phase 2 — Register the App ID** (bundle identifier) in the developer portal.
4. **Phase 3 — Code signing:** open the Flutter `.xcworkspace`, pick the Team (automatic signing).
5. **Phase 4 — Create the App Store Connect record** (name, SKU, bundle ID).
6. **Phase 5 — Privacy:** add the app privacy manifest; verify export compliance; plan the App Privacy label.
7. **Phase 6 — Build & upload** the IPA from Flutter (`flutter build ipa`), then Transporter or Xcode Organizer.
8. **Phase 7 — TestFlight** (optional but recommended): test the processed build on a real device.
9. **Phase 8 — Listing:** icon, screenshots, text, URLs, age rating, category, pricing.
10. **Phase 9 — Submit for review**, pass, release.
11. **Phase 10 — Post-launch:** updates, build-number bumps, and (optionally) enabling Analytics/Pro.

---

## Phase 0 — Prerequisites & cost

| Item | Detail |
|---|---|
| Mac | Required. App Store builds/signing/archiving need macOS + Xcode. |
| Xcode | **Xcode 26 or later** is mandatory: since **April 28, 2026**, every App Store upload must be built with Xcode 26+ using an iOS 26+ SDK. ([Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)) Install from the Mac App Store; in mid-2026 the current line is Xcode 27. |
| Apple Developer Program | **USD $99/year**, shown in local currency at enrollment. Renews automatically when enrolled via the Apple Developer app; on the website, auto-renew is **opt-in and region-limited** (US included). ([Compare memberships](https://developer.apple.com/support/compare-memberships/)) |
| Flutter | Verified against installed **Flutter 3.38.5 (stable, Dart 3)**. Flutter 3.38+ added full iOS 26 / Xcode 26 support. |
| Transporter | Free Mac App Store app — easiest first-time upload tool. |

> The $99 fee is the only mandatory cost. There are no fee waivers for a for-profit entity like Cardamon Inc.

---

## Phase 1 — Enrollment: Individual vs Organization

Because the seller is the legal entity **Cardamon Inc**, enroll as an **Organization**, not Individual. This makes the App Store "seller"/developer name show as the company.

| | Individual | Organization (use this) |
|---|---|---|
| Developer name shown | Your personal name | **Cardamon Inc** |
| D-U-N-S number | Not required | **Required** |
| Who can be on the team | Just you | Multiple members/roles |

### D-U-N-S number

- Organization enrollment requires a **D-U-N-S Number** to verify the legal entity. It is **free** in most jurisdictions via Dun & Bradstreet.
- DBAs, trade names, and branches are **not** accepted — it must be the real legal entity.
- Check/request it during enrollment: ([Apple D-U-N-S help](https://developer.apple.com/help/account/membership/D-U-N-S/))

### Enroll

1. Go to **https://developer.apple.com/programs/enroll/** and sign in with **dmitriy.kargashin@gmail.com**.
2. Choose **Company / Organization**, supply the legal entity name **Cardamon Inc** and its D-U-N-S number; Dmitrii Kargashin is the **Account Holder**.
3. Pay the $99 fee. Apple verifies the legal entity. For a **first-time organization** this realistically takes **several days to a few weeks** (no published SLA) — and obtaining the D-U-N-S from Dun & Bradstreet beforehand can add ~5 business days. ([Program enrollment help](https://developer.apple.com/help/account/membership/program-enrollment/))

> You **cannot** create a distribution certificate, App Store provisioning profile, or App Store Connect record until this membership is **active**.

After enrollment, add the account to Xcode once: **Xcode → Settings → Accounts → "+" → Apple ID**, sign in. This downloads the Cardamon Inc team so it appears in the Team dropdown.

---

## Phase 2 — App ID & capabilities

Register the bundle identifier once.

1. Go to **https://developer.apple.com/account** → **Certificates, Identifiers & Profiles → Identifiers → "+"**.
2. Choose **App IDs → App → Continue**.
3. Set **Type = Explicit**, **Description = `Time Calculator Cardamon`**, **Bundle ID = `com.cardamon.timeCalculator`** (must byte-match the Xcode project, **case-sensitive**).
4. **Leave ALL capabilities OFF.** This app needs none:
   - **No** In-App Purchase capability (IAP ships disabled at launch — adding it would force an unneeded entitlement into the profile).
   - **No** Push, Sign in with Apple, etc.
   - Firebase needs nothing from signing/provisioning.
5. **Continue → Register.**

> A bundle-ID mismatch between this App ID and the Xcode project is the **#1 cause** of "No profiles for … were found." Copy-paste, don't retype.

---

## Phase 3 — Code signing in Xcode (Flutter workspace)

### Background (read once)

- A **signing certificate** identifies your team; a **provisioning profile** ties one certificate + the App ID + entitlements + devices together.
- Apple's two everyday certificate types: **Apple Development** (run on your devices) and **Apple Distribution** (TestFlight / App Store). They do **not** mix with the wrong profile type.
- **Automatic signing** (this project's setting) lets Xcode create/renew the right cert and an "Xcode Managed" App Store profile for you at archive time.
- The iOS **Simulator needs no signing**; a real device needs Development; **App Store/TestFlight needs Apple Distribution + App Store profile** (applied to Release when you Archive).
- **Standard certificate validity is 1 year** (Apple emails a 30-day warning). The "2-year" figure circulating online is wrong for standard distribution certs. You can hold **one of each distribution certificate type per team** at a time. ([Certificates overview](https://developer.apple.com/help/account/certificates/certificates-overview/))

### Steps (automatic signing — recommended)

Always open the **workspace**, never the bare `.xcodeproj` (this app uses CocoaPods — Firebase, in_app_purchase, etc.; the bare project breaks Pods integration):

```bash
open "/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/flutter_app/ios/Runner.xcworkspace"
```

1. In the left navigator click the blue **Runner** project → select the **Runner TARGET** (not RunnerTests) → **Signing & Capabilities** tab.
2. Confirm **"Automatically manage signing"** is ticked for **Debug** and **Release** (the project already has `CODE_SIGN_STYLE = Automatic`).
3. In the **Team** dropdown pick **Cardamon Inc**. Xcode writes your 10-char `DEVELOPMENT_TEAM` into build settings and provisions. After a few seconds you should see *Provisioning Profile: Xcode Managed Profile* and *Signing Certificate: Apple Development* with no error.
4. Verify the **Bundle Identifier** reads `com.cardamon.timeCalculator`.

> **Project specifics:**
> - The only signing change needed is selecting the Team — there is no `DEVELOPMENT_TEAM` line yet, which is *correct* for the pre-account state.
> - The project contains a legacy `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer"` string. Under automatic signing this is **harmless** — Xcode maps it to Apple Development/Distribution. **Do not hand-edit it.**

### Manual signing (only if team policy requires it)

Untick automatic signing, then in the portal create an **Apple Distribution** certificate (generate a CSR via *Keychain Access → Certificate Assistant → Request a Certificate from a CA*, upload, download the `.cer`, double-click to install), create an **App Store** distribution profile bound to your App ID + that cert, download it, and select it in Xcode under *Provisioning Profile*.

### Headless / CI signing

Create an **App Store Connect API key**: **App Store Connect → Users and Access → Integrations → App Store Connect API → "+"**. For a **Team key** the creator must be **Account Holder or Admin** (App Manager alone cannot create Team keys). Download the **`.p8` immediately — Apple lets you download it only ONCE** (lost = revoke + regenerate). Store the `.p8`, **Key ID**, and **Issuer ID** as CI secrets; fastlane (`match`/`sigh`/`pilot`) or Xcode authenticate with them without a password/2FA. ([API key help](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/))

---

## Phase 4 — App Store Connect app record

1. **https://appstoreconnect.apple.com → Apps → "+" → New App.**
2. Fill in:
   - **Platform:** iOS
   - **Name:** `Time Calculator Cardamon` (globally unique, ≤ 30 chars)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** select `com.cardamon.timeCalculator` (appears because you registered it)
   - **SKU:** an internal-only string you invent, e.g. `CARDAMON-TIMECALC-IOS` (never shown to users; must start with a letter/number; may contain letters, numbers, `-`, `.`, `_`)
   - **User Access:** Full Access
3. **Create.** Status becomes **"Prepare for Submission."**

> **Bundle ID and SKU are permanent** once set. The build number must always increase (see versioning).

Then, before the app can go live: under **Business / Agreements**, confirm the **Cardamon Inc** developer name and that the **Account Holder has accepted the latest Paid/Free Apps agreement**. ([Create an app record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/))

---

## Phase 5 — Privacy

Three **independent** obligations, all of which must be correct:

| What | Where it lives |
|---|---|
| (A) Privacy manifest `PrivacyInfo.xcprivacy` | A file inside the app binary |
| (B) App Privacy "nutrition label" | A web questionnaire in App Store Connect |
| (C) `ITSAppUsesNonExemptEncryption` | A key in `Info.plist` |

### (C) Export compliance — already done

`ios/Runner/Info.plist` has `ITSAppUsesNonExemptEncryption = false` (lines 11–12). Correct for an offline calculator using only Apple's standard crypto (HTTPS/TLS, keychain). Result: **no encryption questionnaire at upload**, and any "Missing Compliance" warning auto-clears. ([ITSAppUsesNonExemptEncryption](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption))

### (A) Privacy manifest

Since **May 1, 2024**, Apple rejects at upload any app that uses a "required-reason" API or links a listed SDK without proper manifest declarations. ([Apple news](https://developer.apple.com/news/?id=3d8a9yyh))

- **Third-party SDKs already handle themselves.** Firebase (`FirebaseCore`, `GoogleUtilities`, `FirebaseInstallations`, `nanopb`, `PromisesObjC`, …) and `shared_preferences` ship their **own signed** `PrivacyInfo.xcprivacy` — confirmed present under `ios/Pods/...`. **Do not hand-write these.** Just keep versions current (yours are: `firebase_core ^4.11.0`, `firebase_analytics ^12.4.3`, `shared_preferences ^2.5.5`) and run `pod install`. Note: `FirebaseAnalytics`/`GoogleAppMeasurement` themselves are **not** on Apple's third-party SDK list.
- **The Runner (app) target should still carry its own manifest** declaring required-reason APIs your *own* code calls. `shared_preferences` uses `NSUserDefaults` (a required-reason API); the bundled plugin manifest already covers it (with reason `1C8F.1`), but adding an app-level declaration is the safe, beginner-correct move and is harmless.

**Create it:** open `Runner.xcworkspace` → **File → New → File…** → *Resource* section → **App Privacy** template → name it `PrivacyInfo.xcprivacy` → ensure **Target Membership: Runner** is checked (produces `ios/Runner/PrivacyInfo.xcprivacy`). ([Adding a privacy manifest](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk))

Fill it as a property list:

| Key | Value |
|---|---|
| `NSPrivacyTracking` | `false` |
| `NSPrivacyTrackingDomains` | empty array |
| `NSPrivacyCollectedDataTypes` | empty array (Analytics is OFF) |
| `NSPrivacyAccessedAPITypes` | one dict: `NSPrivacyAccessedAPIType = NSPrivacyAccessedAPICategoryUserDefaults`, `NSPrivacyAccessedAPITypeReasons = [CA92.1]` |

`CA92.1` = "access user defaults to read/write information only accessible to the app itself." Only add a **File Timestamp** entry (`NSPrivacyAccessedAPICategoryFileTimestamp`, reason e.g. `C617.1` or `DDA9.1`) if your code actually reads file modification/creation times — a calculator generally does not. Do **not** add reasons you cannot justify. ([Required-reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api))

### (B) App Privacy nutrition label

You answer this regardless of manifests. **At launch, Firebase Analytics is OFF on iOS and nothing leaves the device**, so:

- In App Store Connect → **App Privacy → Get Started**, select **"Data Not Collected."** (`shared_preferences` data stays on-device and is not "collected" in Apple's sense.)
- A **Privacy Policy URL is mandatory even when answering "Data Not Collected."** Enter `https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator`. ([Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/))

### ATT / IDFA — leave it OUT

Do **not** add `NSUserTrackingUsageDescription` and do **not** call the App Tracking Transparency prompt. Firebase Analytics is first-party and **does not access IDFA by default** (it falls back to IDFV), so it is not "tracking." Only add ATT if you later link `GoogleAppMeasurementWithAdIdSupport`/`AdSupport.framework` or share data with ad networks. ([Firebase data collection](https://firebase.google.com/docs/analytics/ios/configure-data-collection))

---

## Phase 6 — Building & uploading the IPA from Flutter

### Build

```bash
cd "/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/flutter_app"
flutter clean
flutter build ipa --export-method app-store
```

- Output: Xcode archive at `build/ios/archive/` and the uploadable file at `build/ios/ipa/*.ipa`.
- `app-store` is the **default** export method (verified in `flutter build ipa --help` on Flutter 3.38.5); both `--export-method app-store` and `--export-method=app-store` work.
- Optional overrides / hardening:

```bash
flutter build ipa --export-method app-store \
  --build-name=2.4.0 --build-number=28 \
  --obfuscate --split-debug-info=build/symbols
```

> **Guideline 2.3.10 pre-flight:** the iOS build must **not** reference or link to Google Play. Audit `url_launcher`/`share_plus` strings and any "rate us" links so **no `play.google.com` URL is compiled into the iOS binary**. `in_app_review` opens the App Store rating sheet natively, which is fine. App Review — not signing — catches this.

### Upload — pick one

**Easiest for a first-timer — Transporter:**
1. Install **Transporter** from the Mac App Store.
2. Open it, sign in with **dmitriy.kargashin@gmail.com**.
3. Drag `build/ios/ipa/*.ipa` into the window → **Deliver**.

**Xcode Organizer (most "official" GUI):** **Window → Organizer**, select the archive → **Distribute App → App Store Connect → Upload**, accept signing, submit.

**CI / scripted** (using an API key):
```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```
`altool` still works for App Store *uploads* in 2026 (Apple steers automation toward the App Store Connect API / Transporter CLI). **Do not use `notarytool`** — notarization is only for apps distributed *outside* the App Store. ([Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/))

### After upload — processing

The build does **not** appear instantly. Apple processes it server-side and **emails you** when done. Apple publishes **no guaranteed SLA**; commonly observed is ~10–30 minutes, occasionally longer. Track it under **App Store Connect → your app → TestFlight** (or the version's **Build** section). "Processing" is normal. Because `ITSAppUsesNonExemptEncryption=false` is set, **no "Missing Compliance" warning** appears.

---

## Phase 7 — TestFlight (recommended)

Once the build is processed:

1. **App Store Connect → your app → TestFlight tab.** The build appears once it finishes server-side **Processing** (you get an email; no guaranteed SLA — if it sits in Processing for >24 h, something's wrong).
2. **Internal testing** — add yourself/team (App Store Connect users with a role). **Up to 100 internal testers**, and **no Beta App Review** — they can install as soon as the build is processed. This is all you need for a solo pre-launch check.
3. **External testing** *(optional)* — invite up to **10,000 testers** by email or a public link. This **requires TestFlight Beta App Review** of the build (the first build of a version gets a full review; later builds may not). Use it only if you want a wider beta.
4. Install **TestFlight** on an iPhone/iPad, accept the invite, run the build. **Builds expire 90 days after upload.**
5. Sanity-check: calculator math, history, share/url actions, both orientations, iPhone *and* iPad layouts.

This catches real-device-only issues (signing, layout, crashes) before App Review sees them.

---

## Phase 8 — Listing assets & metadata

### App icon

- One **1024×1024 PNG**, **fully opaque** (no alpha/transparency), **no manually rounded corners** (Apple masks the squircle), sRGB or Display P3, RGB. A single transparent pixel = rejection.
- The store icon now comes **from the build's asset catalog** (uploaded with the binary), not the web UI. Make sure the `AppIcon.appiconset` is opaque before you archive.
- Generate it in Flutter from one source PNG with `flutter_launcher_icons` (set `ios: true`, `remove_alpha_ios: true`, `background_color_ios: "#RRGGBB"`), then:

```bash
cd "/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/flutter_app"
dart run flutter_launcher_icons
```

### Screenshots — **iPhone AND iPad both required** (this app targets `1,2`)

Capture from the iOS Simulator (run the app, **Cmd+S** saves at exact native pixels). PNG/JPEG, RGB, **no alpha**, exact dimensions, **1–10 per class** (3+ recommended as ASO guidance, not an Apple rule).

| Display class | Accepted portrait size | How to capture |
|---|---|---|
| iPhone **6.9"** (primary, required) | **1260 × 2736** | iPhone 6.9" simulator (e.g. 17 Pro Max / 16 Pro Max) |
| iPhone 6.5" (only if no 6.9" provided) | 1284 × 2778 (or 1242 × 2688) | fallback class; Apple scales 6.9" if neither given |
| iPad **13"** (required — app runs on iPad) | **2064 × 2752** | 13" iPad Pro (M4) simulator |

> Only **1260 × 2736** is Apple's *accepted upload* size for the 6.9" class — native resolutions like 1320×2868 or 1290×2796 are device pixels, not the accepted-upload size. Verify alpha/dimensions with `sips -g pixelWidth -g pixelHeight file.png`; strip alpha via Preview → Export if needed. App preview videos are optional. ([Screenshot specs](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/))

### Text fields & limits

| Field | Limit | Notes |
|---|---|---|
| App Name | 30 | Globally unique |
| Subtitle | 30 | |
| Keywords | 100 total | Comma-separated, **no spaces** between terms (saves characters) |
| Promotional Text | 170 | Editable anytime **without** a new build |
| Description | 4000 | |

([Product page reference](https://developer.apple.com/app-store/product-page/)) Keep **all** text free of any Android/Google Play mention (guideline 2.3.10).

### URLs

| URL | Required? | Value |
|---|---|---|
| Privacy Policy | **Mandatory** | https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator |
| Support | **Effectively required** (live page with a working contact, e.g. for support@cardamon.org) | your support page |
| Marketing | Optional | product page if you have one |

### Age rating

Complete the **2026 questionnaire** (mandatory). The scale is now **4+, 9+, 13+, 16+, 18+** (12+ and 17+ were removed; the deadline to answer the new questions was **Jan 31, 2026**). For a content-free calculator, answer **None/No** to everything → **4+**. ([Age ratings news](https://developer.apple.com/news/?id=ks775ehf))

### Category & pricing

- **Primary Category:** Utilities (Productivity is a valid alternative if it fits better). Optionally a Secondary.
- **Pricing:** **Free** tier. Because IAP is OFF at launch, **do not** create any in-app purchase products.

---

## Phase 9 — Submit for review + rejection-risk checklist

On the version page: attach the processed **build 28**, add screenshots (iPhone 6.9" + iPad 13"), complete metadata, **Add for Review → Submit for Review.**

### Rejection risks tailored to this app

**Guideline 4.2 — Minimum functionality.** A bare calculator can be rejected as "too simple." Mitigate:
- Lead screenshots/description with the app's real value (time math, history, multiple result formats, rate calculator).
- Make sure it's polished, crash-free, and uses native iOS conventions; a thin single-purpose tool with no depth is the typical 4.2 target.

**Guideline 2.3.10 — No other-platform references.** Ensure no "Get it on Google Play" strings, links, or screenshots appear anywhere in the iOS build or listing.

**Donations / IAP (deferred at launch — relevant when you enable "Pro" later).** Apple's rules:
- To **unlock features/content/a full version**, you **must use In-App Purchase** (Guideline 3.1.1).
- A pure **developer "tip"/donation that unlocks nothing** *may* be offered — but only **via IAP** in-app. You **cannot** use Apple Pay, a credit-card field, or a "Buy Me a Coffee"/Safari link to collect a developer tip in-app (Apple Pay/credit-card entry is reserved for **physical** goods/services consumed outside the app — 3.1.3(e)). Real apps have been rejected for external tip links.
- **Charitable fundraising in-app** is restricted to **approved nonprofits** (3.2.1(vi)); a for-profit must keep such collection **outside** the app (Safari/SMS).
- ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/))

Since **no StoreKit UI ships at launch and `kApplePurchasesEnabled=false`**, none of this blocks the first release — just don't mention Pro/donations in the listing yet.

---

## Phase 10 — Post-launch updates & versioning

Flutter maps `pubspec.yaml` `version: <name>+<build>` → `CFBundleShortVersionString` (marketing) + `CFBundleVersion` (build number).

- **Every new upload must have a build number strictly higher** than any previously uploaded build for that marketing version, or Apple rejects it as a duplicate.
- Bug-fix upload, same marketing version: `2.4.0+29`, `2.4.0+30`, …
- New feature release: `2.5.0+31`, etc.

```yaml
# pubspec.yaml
version: 2.4.0+29   # bump the build (+NN) for every App Store Connect upload
```

Update flow: bump version → `flutter build ipa --export-method app-store` → upload → attach build → update "What's New" → submit. **Promotional Text** can be edited live without a new build.

---

## Optional later: enabling iOS Firebase Analytics + IAP/Pro

### Enable Firebase Analytics on iOS

1. Add `ios/Runner/GoogleService-Info.plist` (from the Firebase console for this bundle ID).
2. Rerun `flutter pub get && (cd ios && pod install)`.
3. **Update the App Privacy label** — it can no longer be "Data Not Collected." Typically declare, under **Used for: Analytics · Linked to user: No · Used to track you: No**:
   - **Usage Data → Product Interaction**
   - **Identifiers → Device ID (IDFV)**
   - **Diagnostics** (if crash/perf enabled)
   - possibly **Location → Coarse** (general location from masked IP)

   These four are a reasonable developer-side declaration; Firebase/Google does not publish a verbatim Apple-category mapping. ([Firebase App Store data collection](https://firebase.google.com/docs/ios/app-store-data-collection))
4. Still **no ATT** unless you add the IDFA/AdSupport variant.

### Enable the iOS freemium / Pro paywall

iOS uses a **freemium** model (a one-time "Pro" unlock), **not** the Android donation/"cup of tea" model — Apple forbids a for-profit taking tips/donations outside IAP (see Phase 9). The split is **already implemented** and runtime-branched by platform, so Android keeps donations and iOS gets the paywall from the same codebase. It stays dormant until you flip one flag.

**The coded free-vs-Pro split:**

| Tier | Contents |
|---|---|
| **Free** | Core calculator · the basic result formats · **2 keypad presets (Standard, Stopwatch), no custom unit picker** · **history capped at the latest 5** · **light *and* dark/system theme (theme is free)** · share/copy |
| **Pro — one-time `pro_unlock`** | The Rate/"Per" calculator · **all** result formats · **all keypad presets + the custom unit picker** · **unlimited history** |

The boundary lives in [`lib/services/entitlements.dart`](../lib/services/entitlements.dart) (`kFreeFormatNames`, `kFreeKeypadPresetNames`, `kFreeHistoryLimit`, `canCustomizeKeypad`, `hasUnlimitedHistory`) — edit those constants to re-balance the tiers. The paywall is `showProPaywall()` in [`lib/ui/pro_screen.dart`](../lib/ui/pro_screen.dart); the product id is `kProSku = 'pro_unlock'` (a **non-consumable**).

**Mechanism:** `Monetization.isProGated = isApplePlatform && kApplePurchasesEnabled`. Android/web report `false`, so nothing is ever gated there; `Monetization.hasPro` is the single "is it unlocked" getter the UI reads.

**To go live with Pro on iOS — do these IN ORDER:**

1. **Add the In-App Purchase capability:** developer portal → Identifiers → your App ID → enable **In-App Purchase**; then in Xcode (Runner target → Signing & Capabilities → "+ Capability") add **In-App Purchase**.
2. **Create the product** in App Store Connect → your app → **Monetization → In-App Purchases → +**: type **Non-Consumable**, Product ID **exactly** `pro_unlock` (must byte-match `kProSku`), reference name "Pro Unlock", a price (e.g. **$2.99**), one localization (display name + description), and a review screenshot. Submit it **with** the first Pro build.
3. **Flip the switch:** set `kApplePurchasesEnabled = true` in [`lib/config.dart`](../lib/config.dart) — **only after** step 2 exists. (Safety net: `canBuyPro` is false until the real product loads, so the button shows "Coming soon" rather than a dead buy — but don't ship the gated state without a live product.)
4. **Sandbox-test:** create a Sandbox Apple Account (App Store Connect → Users and Access → Sandbox), sign into it on a real device, run a TestFlight/dev build, and verify: locked feature → paywall → buy → unlocks; **Restore Purchases** re-grants on a fresh install.
5. **App Privacy:** only declare purchase data if *you* log it (the StoreKit transaction via Apple does not, by itself, need a label entry).
6. **Review-safety:** the paywall shows the price + a working **Restore Purchases** (it does), and gates *real features* (rate calc, formats, keypad, history) — not cosmetics — so it is compliant. Theme/dark mode is intentionally **free** to avoid rating backlash.

> The Android donation tiers (`support_1/3/5/9`) are untouched and never sold on iOS — `Monetization.isBillingAvailable` is Android-only.

#### Test the paywall locally — no Apple Developer account needed

You can run the full buy/restore flow on the **simulator** using a **StoreKit Configuration file** (fake products served on-device). This repo is already wired for it:

- `kApplePurchasesEnabled = true` is flipped on (⚠️ **temporary** — see the warning in [`lib/config.dart`](../lib/config.dart); revert before shipping a non-Pro build).
- [`ios/Runner/Configuration.storekit`](../ios/Runner/Configuration.storekit) defines the `pro_unlock` non-consumable at $2.99.
- The Runner scheme's Launch action references it (StoreKit configuration).

**See the locks + paywall UI** (any launch — `flutter run` or Xcode): gating is on, so the Per icon shows a lock, the locked keypad presets/custom picker and the history-cap upsell appear, and tapping any opens the paywall sheet.

**Test an actual purchase** (buy/restore) — run from **Xcode** so the StoreKit configuration is applied:

```bash
open "ios/Runner.xcworkspace"   # from flutter_app/
```
1. Pick an iOS simulator, press **Run** (▶).
2. In the app: tap a locked feature → paywall → **Unlock Pro – $2.99** → confirm. The fake purchase completes locally and the locks vanish; "Restore Purchases" re-grants it.
3. Reset between runs: Xcode menu **Debug → StoreKit → Manage Transactions** (delete the transaction).

> If the scheme ever reports the StoreKit file "not found", re-point it via **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → Configuration.storekit**.

**Before shipping:** revert `kApplePurchasesEnabled` to `false` (or keep `true` only once the real `pro_unlock` product is live in App Store Connect). The `.storekit` file is dev-only and never affects production.

---

## Pre-submission checklist

- [ ] Apple Developer Program (Organization, Cardamon Inc) **active**; Paid/Free Apps agreement accepted
- [ ] App ID `com.cardamon.timeCalculator` registered, **all capabilities OFF**
- [ ] Xcode **Team = Cardamon Inc** selected on the Runner target (automatic signing, no errors)
- [ ] Built with **Xcode 26+ / iOS 26+ SDK** (April 28, 2026 rule)
- [ ] `ITSAppUsesNonExemptEncryption = false` present in `Info.plist`
- [ ] `ios/Runner/PrivacyInfo.xcprivacy` added (Runner membership; `NSUserDefaults` → `CA92.1`); Firebase/shared_preferences pod manifests present after `pod install`
- [ ] App Store Connect record created (name ≤ 30, SKU set, bundle ID linked)
- [ ] App Privacy label completed ("Data Not Collected" at launch) + **Privacy Policy URL entered**
- [ ] **No ATT** prompt / `NSUserTrackingUsageDescription` (Analytics off)
- [ ] Opaque **1024×1024** icon in the build's asset catalog (no alpha)
- [ ] Screenshots: **iPhone 6.9" (1260×2736)** *and* **iPad 13" (2064×2752)**, RGB, no alpha
- [ ] Text metadata within limits; **no Google Play references** anywhere (Guideline 2.3.10)
- [ ] Support URL live with a real contact; Privacy Policy URL set
- [ ] Age rating questionnaire completed (expect **4+**); Category = **Utilities**; Price = **Free**
- [ ] No IAP products / no Pro or donation copy in the listing (deferred)
- [ ] `version: 2.4.0+28` (bump build number for every subsequent upload)
- [ ] IPA built (`flutter build ipa --export-method app-store`), uploaded, **processed**, attached to the version
- [ ] (Recommended) verified on a real device via **TestFlight**

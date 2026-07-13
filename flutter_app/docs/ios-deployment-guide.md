# iOS App Store Deployment Guide — Time Calculator Cardamon

<!-- Researched & web-verified June 2026; REVISED 2026-07-03 to match the two
product decisions now in effect: (1) the Apple Developer Program account is
ACTIVE (Organization / Cardamon Inc), and (2) iOS ships WITH the Pro paywall —
NOT a free-first build. Analytics is now wired ON (real GoogleService-Info.plist
in the Runner target); on 2026-07-09 the App Store listing copy (app name,
subtitle, keywords, description, IAP copy, review notes) was folded inline so
this guide is the single source. The volatile specifics (Xcode version,
screenshot pixel sizes, fees, menu labels) change often — verify against the
linked Apple pages before you rely on them. -->

> **Where this project stands.** The iOS app **compiles, installs, launches, and
> renders** cleanly on the Simulator (verified on iPhone 17 / iOS 26). The two
> build-config fixes that got it there are already in this branch: CocoaPods
> `1.10.1 → 1.16.2`, and the iOS deployment target `13.0 → 15.0` (required by
> `firebase_analytics`). **The remaining work is account / store / signing /
> listing / IAP — not code.** You are now enrolled, so this guide is the
> step-by-step to get from "account active" to "live on the App Store."

All file paths assume the Flutter project lives at `flutter_app/`.

> **Identity facts used throughout**
> - **App name:** Time Calculator Cardamon
> - **iOS bundle ID:** `com.cardamon.timeCalculator` (the **company** prefix — *deliberately independent* of the Android package `com.dmitriykargashin.cardamontimecalculator`; the two need not match, and Android's is locked because it is already published)
> - **Legal entity:** Cardamon Inc · **Account holder:** Dmitrii Kargashin · **Apple ID:** dmitriy.kargashin@gmail.com
> - **Version:** `2.4.0+28` → marketing version **2.4.0**, build number **28**
> - **Category:** Utilities · **Support email:** support@cardamon.org
> - **Privacy policy:** https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator
> - **Monetization:** iOS ships **freemium** — a one-time **`pro_unlock`** non-consumable (target price **$3.99**). This is a firm product decision; iOS is **not** launching free. (Android keeps its "cup of tea" donations; the two never mix — see Phase 5.)

---

## The two things that make THIS launch different

1. **You are enrolled as an Organization (Cardamon Inc).** So the account, D-U-N-S, and developer name are done. What's left starts at the App ID.
2. **iOS launches WITH the Pro paywall.** `kApplePurchasesEnabled = true` stays true. That adds three hard gates the free path didn't have, and if any is missing the reviewer's buy tap fails → **Guideline 2.1 rejection**:
   - Create the `pro_unlock` **non-consumable** in App Store Connect and submit it **with** the build (Phase 6).
   - Accept the **Paid Applications agreement** and complete **tax + banking** (Phase 3) — required before any IAP can be sold or even clear "Missing Metadata."
   - Set **`kAppleAppId`** to the App Store Connect numeric id (Phase 5), then build (Phase 8).

---

## Current state of THIS project

### Already done (no action needed)

| Item | Value / status |
|---|---|
| **Apple Developer Program** | **ACTIVE — Organization, Cardamon Inc** (enrolled 2026-07). Developer/seller name shows as the company. |
| iOS bundle identifier | `com.cardamon.timeCalculator` (Debug + Release + Profile) |
| Code-signing style | `CODE_SIGN_STYLE = Automatic` (correct; just needs the Team picked once) |
| iOS deployment target | **iOS 15.0** (already raised from 13 — `firebase_analytics` 12.x needs it) |
| Device family | iPhone **and** iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) → **iPad screenshots are required** |
| Orientations | iPhone: portrait + landscape; iPad: portrait, upside-down, landscape |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` in `Info.plist` → no encryption prompt at upload |
| **Pro paywall (iOS)** | **LIVE at launch.** `kApplePurchasesEnabled = true` in `lib/config.dart`; the freemium split, paywall (`showProPaywall()`), and StoreKit wiring all ship. It gates real features (see the tier table below). |
| **Firebase Analytics (iOS)** | **WIRED ON.** A real `ios/Runner/GoogleService-Info.plist` (project `cardamon-time-calculator`) is present and in the Runner target; `Firebase.initializeApp()` picks it up and the app collects usage analytics (Consent Mode gates EEA/UK/CH). → **App Privacy must declare data** (Phase 7). |
| Listing assets | **COMPLETE.** iPhone 6.9" ×8 (1290×2796) and iPad 13" ×8 (2064×2752) under `store-listings/ios/` + `ios-tab-13/`; opaque 1024×1024 icon + full icon set generated from the green Cardamon clock. Captures grant Pro so shots show the unlocked app. |
| Plugin privacy manifests | Firebase + `shared_preferences` pods ship their own `PrivacyInfo.xcprivacy` (present under `ios/Pods/...`) |

### Still to do (this guide covers all of it)

- [ ] Add the account to **Xcode** and pick the **Team** on the Runner target (auto-injects `DEVELOPMENT_TEAM`)
- [ ] Register the **App ID** in the developer portal
- [ ] Accept the **Paid Applications agreement** + complete **tax & banking** (required to sell `pro_unlock`)
- [ ] Complete **EU DSA trader status** (declare trader, verify email + phone, upload business doc) — required to submit **and** for EU availability
- [ ] Create the **App Store Connect** app record, then copy its numeric **Apple ID** into **`kAppleAppId`** (`lib/config.dart`)
- [ ] Create the **`pro_unlock`** non-consumable IAP (price, localization, review screenshot)
- [ ] App-level **`PrivacyInfo.xcprivacy`** in the Runner target (recommended)
- [ ] Complete the **App Privacy** questionnaire (**declares analytics** — not "Data Not Collected") + **age rating**
- [ ] **Sandbox-test** the buy + Restore Purchases flow on a real device
- [ ] Build, upload, attach to the version, **submit the app + IAP together**

---

## Roadmap

0. **Phase 0 — Prerequisites:** Mac + Xcode 26+, the account (done).
1. **Phase 1 — Account → Xcode:** add the Apple ID so the Cardamon Inc team appears.
2. **Phase 2 — Register the App ID** (`com.cardamon.timeCalculator`).
3. **Phase 3 — Agreements, tax, banking & EU DSA trader status:** accept the Paid Apps agreement (needed for IAP) + declare/verify trader status (needed for EU + to submit).
4. **Phase 4 — App Store Connect record** (name, SKU, bundle ID) → grab the numeric Apple ID.
5. **Phase 5 — Set `kAppleAppId` + create the `pro_unlock` IAP.**
6. **Phase 6 — Code signing** in the Flutter `.xcworkspace` (pick the Team).
7. **Phase 7 — Privacy:** app manifest; export compliance; App Privacy label that **declares analytics**.
8. **Phase 8 — Build & upload** the IPA (`flutter build ipa`) → Transporter / Organizer.
9. **Phase 9 — TestFlight + sandbox-test** the purchase and Restore on a real device.
10. **Phase 10 — Listing:** icon, screenshots, text, URLs, age rating, category, price = Free + IAP.
11. **Phase 11 — Submit** the app **and** the IAP for review; pass; release.
12. **Phase 12 — Post-launch:** updates, build-number bumps.

---

## Phase 0 — Prerequisites & cost

| Item | Detail |
|---|---|
| Mac | Required for builds/signing/archiving. |
| Xcode | **Xcode 26 or later** is mandatory: since **April 28, 2026**, every App Store upload must be built with Xcode 26+ using an iOS 26+ SDK. ([Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)) |
| Apple Developer Program | **Active** (Organization). Renews at **USD $99/year**. ([Compare memberships](https://developer.apple.com/support/compare-memberships/)) |
| Flutter | Verified against **Flutter 3.38.5 (stable, Dart 3)**; 3.38+ has full iOS 26 / Xcode 26 support. |
| Transporter | Free Mac App Store app — easiest first-time upload tool. |

---

## Phase 1 — Connect the active account to Xcode

Enrollment is complete (Organization / Cardamon Inc), so there is no D-U-N-S or verification step left. Just make the team available to Xcode:

**Xcode → Settings → Accounts → "+" → Apple ID**, sign in with **dmitriy.kargashin@gmail.com**. Xcode downloads the **Cardamon Inc** team so it appears in the Team dropdown during signing (Phase 6).

> The seller/developer name on the store will read **Cardamon Inc** because you enrolled as an Organization.

---

## Phase 2 — App ID & capabilities

Register the bundle identifier once.

1. **https://developer.apple.com/account** → **Certificates, Identifiers & Profiles → Identifiers → "+"**.
2. **App IDs → App → Continue**.
3. **Type = Explicit**, **Description = `Time Calculator Cardamon`**, **Bundle ID = `com.cardamon.timeCalculator`** (must byte-match the Xcode project, **case-sensitive**).
4. **Leave every capability OFF.** In particular:
   - **In-App Purchase needs NO capability toggle.** StoreKit purchases work by default — there is no entitlement to add in the portal or in Xcode. Selling `pro_unlock` is an App Store Connect + agreements task (Phases 3–5), not a signing one.
   - **No** Push, Sign in with Apple, etc. Firebase needs nothing from signing/provisioning.
5. **Continue → Register.**

> A bundle-ID mismatch between this App ID and the Xcode project is the **#1 cause** of "No profiles for … were found." Copy-paste, don't retype.

---

## Phase 3 — Agreements, tax, banking & EU trader status

Three things live in the **Business** area, and each one blocks either submission or EU availability if skipped. Do them early — verification takes time.

### 3a. Paid Applications agreement + tax + banking (required to sell IAP)

1. **https://appstoreconnect.apple.com → Business** (a.k.a. **Agreements, Tax, and Banking**).
2. Have the **Account Holder** (Dmitrii Kargashin) accept the latest **Paid Applications Agreement**.
3. Complete **Tax** forms and add a **Bank Account** for payouts (Cardamon Inc details).

> Until the Paid Apps agreement is **Active** and banking/tax are filled, your `pro_unlock` product stays stuck in **"Missing Metadata"** and cannot be submitted or sold — and the app would fail review when the buy button can't complete. ([Manage agreements](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/))

### 3b. EU Digital Services Act (DSA) trader status — required, and displayed publicly

The **"Complete Compliance Requirements"** banner is this. DSA Articles 30–31 make Apple verify and **publicly display** trader contact info for anyone distributing in the EU. **Cardamon Inc is a trader** — a for-profit company selling an app/IAP meets the DSA definition, so this is not optional.

**Path:** **Business → Agreements** tab → **Compliance** section → next to **Digital Services Act**, click **Complete Compliance Requirements** (Account Holder or Admin).

1. Select **"This is a trader account."**
2. Provide **address** (auto-filled from your D-U-N-S for the org, not editable here), **phone**, **email**, your **payment account** details, and **certify** you only offer EU-law-compliant products.
3. **Verify** the email and phone by 2FA (request manual phone verification if 2FA can't reach the number).
4. **Upload** a current business document proving Cardamon Inc's name + address.
5. **Review → Confirm.** Apple verifies before it goes live.

> ⚠️ **Shown publicly** on your EU product page (all 27 territories): the address, phone, and email. The org address comes from your D-U-N-S; for phone/email, use business contact you're fine publishing (a business line + **support@cardamon.org**), not personal details.

> **Timing / consequence:** since **Oct 16, 2024**, trader info is required to **submit apps for review**; since **Feb 17, 2025**, apps without verified trader status are **removed from the EU App Store**. Complete and verify this **before Phase 11**, or the submission is blocked and the app never appears in the EU. ([DSA trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/) · [Apple news](https://developer.apple.com/news/?id=einwn76m))

---

## Phase 4 — App Store Connect app record

1. **App Store Connect → Apps → "+" → New App.**
2. Fill in:
   - **Platform:** iOS
   - **Name:** `Time Calculator Cardamon` (globally unique, ≤ 30 chars)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** select `com.cardamon.timeCalculator`
   - **SKU:** an internal-only string, e.g. `CARDAMON-TIMECALC-IOS`
   - **User Access:** Full Access
3. **Create.** Status becomes **"Prepare for Submission."**
4. Open **App Information** and copy the numeric **Apple ID** (e.g. `6480000000`) — you need it in the next phase.

> **Bundle ID and SKU are permanent** once set. The build number must always increase (see Phase 12).

---

## Phase 5 — Wire the App Store id + create the Pro product

### 5a. Set `kAppleAppId`

Paste the numeric Apple ID from Phase 4 into [`lib/config.dart`](../lib/config.dart):

```dart
const String kAppleAppId = '6480000000'; // was '' — the ASC numeric id
```

Why it matters: `storeUrlForCurrentPlatform`, `shareAppText`, and the "rate us" link all resolve from this. While it's empty, `storeUrlForCurrentPlatform` returns `null` (so iOS shows no store link, which is safe but unpolished). **Set it before you build in Phase 8** so the shipped binary has a working App Store URL. It never contains the Play link on Apple.

### 5b. Create the `pro_unlock` non-consumable

**App Store Connect → your app → Monetization → In-App Purchases → "+":**

| Field | Value | Limit |
|---|---|---|
| Type | **Non-Consumable** | — |
| Product ID | **`pro_unlock`** — must **byte-match** `kProSku` in `config.dart` | — |
| Reference Name (internal) | `Pro Unlock` | 64 |
| Price | **$3.99** (raise to $4.99 later anytime — existing buyers keep it) | — |
| Localization language | English (U.S.) | — |
| Display Name (user-facing) | `Time Calculator Pro` | 30 (19 used) |
| Description | `Rate calc, all formats, custom keypad, full history` | 55 (51 used) |
| Review screenshot | `store-listings/ios/iap-review/pro_unlock-paywall.png` | see below |
| Image (Optional) — promo image | **leave blank at launch** | — |

The **Display Name** shows in the iOS purchase sheet; the **Description** surfaces in App Review (and on the product page only if you later promote the IAP).

**Review Notes** — paste this so the reviewer can reach the paywall:

```
pro_unlock is a one-time non-consumable. It unlocks the Rate ("Per") calculator, all result formats, all keypad presets plus the custom unit picker, and unlimited history. The core calculator, unit conversion, and all themes stay free.

To reach the purchase: launch the app and tap the "Per" (Rate) icon in the toolbar. Tapping a locked result format, a locked keypad preset, or the "history limited to 5" banner also opens it. The paywall shows the $3.99 price, the feature list, an Unlock button, and Restore Purchases.

No account, login, or demo credentials are needed.
```

**Review screenshot:** a ready-made **1242×2688** capture of the paywall (at $3.99, with Restore Purchases) sits at `store-listings/ios/iap-review/pro_unlock-paywall.png`. Upload it on the product page (NOT the app-screenshots section). ⚠️ App Store Connect rejects a plain "≥640×920" image with *"the dimensions … are wrong"* — it must be an **accepted iPhone screenshot size** (1242×2688 works). Regenerate anytime with `flutter test test/golden_capture_test.dart --update-goldens --plain-name "paywall"`, then flatten to opaque RGB.

**Image (Optional)** is the *promotional* image (1024×1024), NOT the review screenshot — it only appears in offer-code redemptions and, if you enable App Store Promotion, as a product-page/search tile. Skip it at launch; if added later: 1024×1024, opaque, no rounded corners, no price/"sale" text, not the app icon.

Set the product to **"Ready to Submit."** You will attach it to the version's review in Phase 11 (the first IAP is reviewed **with** the first app version). It stays in **"Missing Metadata"** until price + localization + review screenshot are all present (and it can't sell until Phase 3a's Paid Apps agreement is active).

> The product ID is permanent and can never be reused. `pro_unlock` is Apple-only; Android never sells it.

### What Pro actually unlocks (the coded split)

The boundary lives in [`lib/services/entitlements.dart`](../lib/services/entitlements.dart). Verified current:

| Tier | Contents |
|---|---|
| **Free** | Core calculator · **7 free result formats** (`Hour Minute, Hour, Minute, Second, MSecond, Day, Year`) · **2 keypad presets** (Standard, Stopwatch), no custom unit picker · **history capped at 5** · **light *and* dark/System theme (theme is FREE)** · share/copy |
| **Pro — one-time `pro_unlock`** | The **Rate / "Per"** calculator · **all** result formats · **all** keypad presets + the **custom unit picker** · **unlimited history** |

Theme is deliberately **free** (no `effectiveThemeMode` gate) to avoid rating backlash. To re-balance tiers, edit the constants `kFreeFormatNames`, `kFreeKeypadPresetNames`, `kFreeHistoryLimit`, `canCustomizeKeypad`, `hasUnlimitedHistory`. Gating master switch: `Monetization.isProGated = isApplePlatform && kApplePurchasesEnabled`; `Monetization.hasPro` is the single "is it unlocked" getter the UI reads.

---

## Phase 6 — Code signing in Xcode (Flutter workspace)

### Background (read once)

- A **signing certificate** identifies your team; a **provisioning profile** ties a certificate + the App ID + entitlements + devices together.
- **Apple Development** = run on your devices; **Apple Distribution** = TestFlight / App Store. They don't mix with the wrong profile type.
- **Automatic signing** (this project's setting) creates/renews the right cert and an "Xcode Managed" App Store profile at archive time.
- Standard distribution certificate validity is **1 year** (Apple emails a 30-day warning). ([Certificates overview](https://developer.apple.com/help/account/certificates/certificates-overview/))

### Steps (automatic signing — recommended)

Always open the **workspace**, never the bare `.xcodeproj` (this app uses CocoaPods — Firebase, in_app_purchase):

```bash
open "/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/flutter_app/ios/Runner.xcworkspace"
```

1. Left navigator → blue **Runner** project → **Runner TARGET** (not RunnerTests) → **Signing & Capabilities**.
2. Click the **All** sub-tab and tick **"Automatically manage signing."**
3. **Team** dropdown → **Cardamon Inc**. Xcode writes your 10-char `DEVELOPMENT_TEAM` and provisions.
4. Verify **Bundle Identifier** reads `com.cardamon.timeCalculator`.

Only **Release** must be signed for the App Store, and its distribution profile needs **no registered device** — Xcode creates it at archive time. **Debug** and **Profile** are for running on a physical iPhone (`flutter run` / `--profile`), and those *development* profiles DO need a registered device.

> **If you see "Your team has no devices…" or "No profiles for 'com.cardamon.timeCalculator' were found":** that is Xcode failing to build a **Development** profile because a brand-new team has zero registered devices. It does **not** block the App Store build — the **Release** archive uses an Apple Distribution cert + App Store profile, neither of which needs a device. To clear the errors, register one: connect an iPhone/iPad by USB (unlock → **Trust**) and Xcode adds it, or enter a device UDID in the portal (**Devices → +**). No iOS device? Ignore the Debug/Profile error and make sure **Release** is signed — `flutter build ipa` (Phase 8) still archives and uploads. (Heads-up: Phase 9's real sandbox purchase test needs a device; without one you can only exercise the paywall via the simulator StoreKit config.)

> **Project specifics:** selecting the Team is the only signing change needed. The legacy `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer"` string is **harmless** under automatic signing — **don't hand-edit it.** Do **not** add an In-App Purchase capability here; StoreKit needs none.

### Headless / CI signing

Create an **App Store Connect API key**: **Users and Access → Integrations → App Store Connect API → "+"**. For a **Team key** the creator must be **Account Holder or Admin**. Download the **`.p8` immediately — Apple lets you download it only ONCE**. Store the `.p8`, **Key ID**, and **Issuer ID** as CI secrets. ([API key help](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/))

---

## Phase 7 — Privacy

Three **independent** obligations:

| What | Where it lives |
|---|---|
| (A) Privacy manifest `PrivacyInfo.xcprivacy` | A file inside the app binary |
| (B) App Privacy "nutrition label" | A questionnaire in App Store Connect |
| (C) `ITSAppUsesNonExemptEncryption` | A key in `Info.plist` |

### (C) Export compliance — already done

`ios/Runner/Info.plist` has `ITSAppUsesNonExemptEncryption = false`. Correct for an app using only Apple's standard crypto (HTTPS/TLS, keychain). Result: **no encryption questionnaire at upload**, and any "Missing Compliance" auto-clears. ([Docs](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption))

### (A) Privacy manifest

Since **May 1, 2024**, Apple rejects any app that uses a required-reason API or links a listed SDK without proper manifest declarations. ([Apple news](https://developer.apple.com/news/?id=3d8a9yyh))

- **Third-party SDKs handle themselves.** Firebase (`FirebaseCore`, `GoogleUtilities`, `FirebaseInstallations`, `nanopb`, …) and `shared_preferences` ship their **own** `PrivacyInfo.xcprivacy` (present under `ios/Pods/...`) — including Firebase's declaration of the analytics data it collects. **Don't hand-write these.** Keep versions current (`firebase_core ^4.11.0`, `firebase_analytics ^12.4.3`, `shared_preferences ^2.5.5`) and run `pod install`.
- **The Runner (app) target should still carry its own manifest** for required-reason APIs your own code calls. `shared_preferences` uses `NSUserDefaults`.

**Create it:** `Runner.xcworkspace` → **File → New → File…** → **App Privacy** template → name `PrivacyInfo.xcprivacy` → **Target Membership: Runner** checked. Fill:

| Key | Value |
|---|---|
| `NSPrivacyTracking` | `false` (no cross-app tracking; see ATT below) |
| `NSPrivacyTrackingDomains` | empty array |
| `NSPrivacyCollectedDataTypes` | may stay empty at the app level — Firebase's pod manifest declares the analytics types Apple aggregates into the privacy report |
| `NSPrivacyAccessedAPITypes` | one dict: `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` |

`CA92.1` = "access user defaults to read/write information only accessible to the app itself." Don't add reasons you can't justify. ([Required-reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api))

### (B) App Privacy nutrition label — **declare analytics** (this changed)

Because a real `GoogleService-Info.plist` is now in the Runner target, `Firebase.initializeApp()` succeeds on iOS and the app **collects usage analytics** (on by default outside EEA/UK/CH; Consent Mode holds it until consent inside those regions). So you can **no longer** answer "Data Not Collected."

In **App Store Connect → App Privacy → Get Started**: answer **"Yes, we collect data from this app,"** then declare exactly these **3 types** (mirroring the Android Data-safety declaration and Firebase's mapping) — for **each**, set **Used for: Analytics only · Linked to you: No · Used for tracking: No**:

- **Usage Data → Product Interaction**
- **Identifiers → Device ID** (Firebase uses the IDFV on iOS, not the IDFA — so no advertising purpose, unlike the Android form)
- **Location → Coarse Location** (approximate, inferred from IP — matches the Android "Approximate location")

**Do NOT declare Diagnostics / Crash / Performance** — the app ships `firebase_analytics` only (no Crashlytics/Performance SDK), and the Android Data-safety form excluded it too. Then **Publish** (no build required).

The **Privacy Policy URL** is separate — set it under **App Information → General → Privacy Policy** (mandatory): `https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator`. ([Firebase App Store data collection](https://firebase.google.com/docs/ios/app-store-data-collection) · [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/))

> **If you would rather launch iOS analytics OFF:** remove `GoogleService-Info.plist` from the Runner target so `Firebase.initializeApp()` no-ops, confirm `AnalyticsService.isEnabled` is false, then you may answer "Data Not Collected." (The plist's internal `IS_ANALYTICS_ENABLED=false` alone is **not** enough — the app's consent code calls `setAnalyticsCollectionEnabled(true)` at runtime, so the integration still counts as collection.) The current, intended state is analytics **ON**.

### ATT / IDFA — leave it OUT

Do **not** add `NSUserTrackingUsageDescription` and do **not** call the ATT prompt. Firebase Analytics on iOS falls back to the **IDFV**, not the IDFA, so it isn't "tracking." Only add ATT if you later link `GoogleAppMeasurementWithAdIdSupport` / `AdSupport.framework`. ([Firebase data collection](https://firebase.google.com/docs/analytics/ios/configure-data-collection))

---

## Phase 8 — Building & uploading the IPA

> **Do Phase 5a first.** Set `kAppleAppId` before building so the shipped binary has a working App Store URL.

### Build

**Use the wrapper script** — it runs `flutter build ipa` and then backfills the `objective_c` native-assets dSYM so the archive uploads **warning-free** (see the dSYM note under "After upload"):

```bash
cd "/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/flutter_app"
flutter clean
./scripts/build_ios_ipa.sh
```

Output: archive at `build/ios/archive/`, uploadable IPA at `build/ios/ipa/*.ipa`. The `app-store` export method is the default. Hardening flags pass straight through:

```bash
./scripts/build_ios_ipa.sh --obfuscate --split-debug-info=build/symbols
```

> **Guideline 2.3.10 pre-flight:** the iOS build must **not** reference or link to Google Play. Audit `url_launcher`/`share_plus` strings so **no `play.google.com` URL is compiled into the iOS binary** (`storeUrlForCurrentPlatform`/`shareAppText` already guard this — they never emit the Play link on Apple). `in_app_review` opens the native App Store rating sheet, which is fine.

### Upload — pick one

**Transporter (easiest):** install from the Mac App Store → sign in with **dmitriy.kargashin@gmail.com** → drag `build/ios/ipa/*.ipa` → **Deliver**.

**Xcode Organizer:** **Window → Organizer** → select archive → **Distribute App → App Store Connect → Upload**.

**CI / scripted:**
```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```
Do **not** use `notarytool` — notarization is only for apps distributed outside the App Store. ([Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/))

### After upload

Apple processes the build server-side and **emails you** when done (commonly ~10–30 min, no SLA). Track it under **TestFlight** or the version's **Build** section. Because `ITSAppUsesNonExemptEncryption=false` is set, **no "Missing Compliance"** appears.

> **"archive did not include a dSYM for objective_c.framework" — FIXED by the build script.** `objective_c` is a Dart **native-assets** package (built via `hook/build.dart` + `code_assets`, **not** CocoaPods — so a Podfile `dwarf-with-dsym` hook would NOT touch it). Flutter's native-assets pipeline doesn't copy the framework's dSYM into the archive. **`scripts/build_ios_ipa.sh` regenerates it with `dsymutil`** (the framework binary keeps its DWARF UUID) and drops it into the archive's `dSYMs/` folder, so the Organizer upload is warning-free. The script loops over every embedded framework, so it self-heals for any future native-assets framework too. If you ever build with raw `flutter build ipa` instead, the warning returns (still harmless — it only affects crash symbolication inside that framework); just re-run `./scripts/build_ios_ipa.sh`, or upstream fixes it eventually ([flutter/flutter](https://github.com/flutter/flutter) · [dart-lang/native](https://github.com/dart-lang/native/issues)).

---

## Phase 9 — TestFlight + sandbox purchase test (do NOT skip)

Because Pro ships at launch, the buy/restore flow **must** work on a real device before review.

1. **TestFlight tab** → the build appears after Processing. **Internal testing:** add yourself (up to 100 internal testers, **no Beta App Review**).
2. Install **TestFlight** on an iPhone/iPad, accept the invite, run the build.
3. **Test the purchase.** How you test decides whether you need a sandbox account:
   - **Via TestFlight (simplest):** IAP is **automatically sandbox and free**, charged to the Apple ID logged into TestFlight — **no sandbox account, no Settings menu needed**. Just tap **Unlock**; the sheet may say `[Environment: Sandbox]`; confirm; it completes free.
   - **Via a dev build run from Xcode:** create a Sandbox Apple Account (App Store Connect → **Users and Access → Sandbox**, using a Gmail `+alias`), and sign in under **Settings → App Store → Sandbox Account** (only shows after a sandbox build is installed) — or just tap Buy and iOS prompts at purchase time.
   - **Local StoreKit config (no account at all):** run from Xcode with `Configuration.storekit` for a fully local fake `pro_unlock` — best for exercising the UI before the real product is live.

   Either real path needs the product **loaded** — that requires the **Paid Apps agreement Active** + a few hours' propagation. Until then the paywall shows **"Coming soon"** (the coded safety net), which is not a bug. Then check:
   - Locked feature (Per icon, a locked format, a locked keypad preset, the history-cap upsell) → **paywall** → **Unlock Pro – $3.99** → completes → locks vanish.
   - **Restore Purchases** re-grants Pro on a fresh install.
   - Confirm the product **loads** (price shows, not "Coming soon"/"still loading") — that requires the `pro_unlock` product to exist and the Paid Apps agreement to be active.
4. Sanity-check the rest: calculator math, history, share/rate, both orientations, iPhone **and** iPad layouts.

> Builds expire **90 days** after upload. External testing (up to 10,000 testers) is optional and needs Beta App Review.

---

## Phase 10 — Listing assets & metadata

### App icon

- One **1024×1024 PNG**, **fully opaque** (no alpha), **no rounded corners** (Apple masks the squircle), sRGB/RGB. Already generated (opaque, from the green Cardamon clock) and shipped in the asset catalog with the build. A single transparent pixel = rejection.

### Screenshots — **iPhone AND iPad both required** (app targets `1,2`) — **DONE**

Your assets are already captured at accepted sizes (verified against Apple's spec, 2026):

| Display class | Your asset size | Also accepted |
|---|---|---|
| iPhone **6.9"** (required) | **1290 × 2796** ✅ | 1260×2736, 1320×2868 |
| iPad **13"** (required) | **2064 × 2752** ✅ | 2048×2732 |

PNG/JPEG, RGB, **no alpha**, 1–10 per class. The captures grant Pro, so they show the fully unlocked app. Verify with `sips -g pixelWidth -g pixelHeight -g hasAlpha file.png`. ([Screenshot specs](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/))

### Text fields (paste-ready)

| Field | Value | Chars / limit |
|---|---|---|
| **App Name** | `Time Calculator Cardamon` | 24 / 30 |
| **Subtitle** | `Add, subtract & convert hours` | 29 / 30 |
| **Keywords** (comma-separated, **no spaces**) | `duration,minute,second,day,timesheet,work,payroll,overtime,difference,elapsed,decimal,hourly,rate` | 97 / 100 |
| **Promotional Text** (editable anytime, no build) | `Add, subtract, multiply, and divide hours and minutes, then convert to any unit. Keep a running history and work out per-unit rates. Free, offline, no sign-up.` | 159 / 170 |

Keyword tips: don't repeat words already in the Name/Subtitle (Apple indexes those separately, so repeats waste characters); Apple auto-combines terms (`work`+`hours`→"work hours", `hourly`+`rate`→"hourly rate"); singular covers plural. Denser-keyword subtitle alternative: `Hours, minutes, duration math` (29).

**Description** (4000 limit; ~1,500 used). Apple doesn't index it for search, so it's written for a reader deciding to install. Paste as-is:

```
Time Calculator adds, subtracts, multiplies, and divides durations, then converts the result into any unit you need. Type 5h 30m + 2h 15m and read the total. Work out 8h 15m × 3, or split 3d 4h ÷ 2. It carries minutes into hours for you, so you never do it by hand.

WHAT YOU CAN DO
• Add and subtract times: 40h − 6h 30m gives you the difference in one tap.
• Multiply and divide a duration by a number: 45m × 12, or 90m ÷ 4.
• Convert any result across units, from years down to milliseconds.
• Read the answer your way: hours and minutes, decimal hours, or a clock format like H:MM:SS.
• Save past calculations to a history and reuse them.
• Pick light, dark, or system theme. Theme stays free.

COMMON USES
• Timesheets and payroll: total the week, subtract breaks, find overtime.
• Billing: turn tracked time into round numbers or decimal hours.
• Cooking, workouts, and video editing: add up steps and segments.
• Planning: split a duration across people or sessions.

PRO (one-time unlock)
Unlock the extras once and keep them:
• The Rate calculator: cost or output per hour, minute, or any unit.
• Every result format beyond the core set.
• All keypad presets plus a custom unit picker.
• Unlimited history.
The core calculator, unit conversion, and every theme stay free. No ads.

PRIVACY
The math runs on your device, and your history stays on your phone. Analytics consent controls live in Settings, and you can open the full policy any time.

Questions or ideas? Email support@cardamon.org. We read every message.
```

> **Operators:** this iOS copy uses `×` and `÷` (the mobile keypad has those keys). The web/extension copy uses `*` and `/` because those are keyboard-typed — keep the two versions separate. Keep all copy free of Android/Google Play mentions (Guideline 2.3.10). ([Product page reference](https://developer.apple.com/app-store/product-page/))

### URLs

| URL | Required? | Value |
|---|---|---|
| Privacy Policy | **Mandatory** | https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator |
| Support | **Effectively required** | a live page with a working contact for support@cardamon.org |
| Marketing | Optional | product page if you have one |

### Age rating

Complete the **2026 questionnaire** (scale **4+, 9+, 13+, 16+, 18+**). For a content-free calculator, answer **None/No** to everything → **4+**. ([Age ratings news](https://developer.apple.com/news/?id=ks775ehf))

### Category & pricing

- **Primary Category:** Utilities (Productivity is a valid alternative). Optional Secondary.
- **Pricing:** the app itself is **Free**, **with** the `pro_unlock` in-app purchase. Do **not** price the app itself.

---

## Phase 11 — Submit the app AND the IAP for review

On the version page: attach the processed **build 28**, add screenshots (iPhone 6.9" + iPad 13"), complete metadata, and in the **In-App Purchases** section **add `pro_unlock`** so it's reviewed **with** this first version. Then **Add for Review → Submit for Review.**

### Rejection risks tailored to this app

**Guideline 2.1 — the IAP must actually work.** The reviewer will tap Pro. If `pro_unlock` isn't attached/approved, or the Paid Apps agreement isn't active, the buy fails → rejection. Confirm the sandbox flow (Phase 9) and that the product is **Ready to Submit** and added to the version.

**Guideline 3.1.1 — paywall compliance (this app passes).** Pro unlocks **real features** (Rate calc, formats, keypad, history) via **StoreKit IAP**, the sheet shows the **price** and a working **Restore Purchases**, and cosmetic theme/dark mode stays **free**. No external purchase links, no Apple Pay/credit-card field for the unlock.

**Guideline 4.2 — minimum functionality.** A bare calculator can be judged "too simple." Lead the screenshots/description with real value (time math, history, multiple formats, the Rate calculator), and keep it polished and crash-free.

**Guideline 2.3.10 — no other-platform references.** No "Get it on Google Play" strings, links, or screenshots anywhere in the iOS build or listing.

([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/))

---

## Phase 12 — Post-launch updates & versioning

Flutter maps `pubspec.yaml` `version: <name>+<build>` → `CFBundleShortVersionString` (marketing) + `CFBundleVersion` (build number).

- **Every new upload needs a build number strictly higher** than any prior upload for that marketing version.
- Bug-fix, same version: `2.4.0+30`, `2.4.0+31`, …
- New feature release: `2.5.0+32`, etc.
- ⚠️ **Bump `kAppVersionCode` in `lib/config.dart` to the SAME build number.** The app prints its version from that hardcoded constant (no `package_info_plus`, by design), so if you bump `pubspec` but not this, Settings shows the wrong version (build 29 shipped showing "28" for exactly this reason). `scripts/build_ios_ipa.sh` now **refuses to build** if the two disagree.

```yaml
# pubspec.yaml
version: 2.4.0+30   # bump +NN every upload; keep kAppVersionCode (config.dart) EQUAL
```

Update flow: bump `pubspec` version **and** `kAppVersionCode` → `./scripts/build_ios_ipa.sh` → upload → attach build → update "What's New" → submit. **Promotional Text** edits go live without a new build.

---

## Reference — testing the paywall locally (no device / sandbox needed)

Already wired in this repo for simulator testing via a **StoreKit Configuration file** (fake products, on-device):

- `ios/Runner/Configuration.storekit` defines `pro_unlock` at $3.99; the Runner scheme's Launch action references it.
- **See the locks + paywall** on any launch (`flutter run` or Xcode): gating is on, so the Per icon shows a lock, locked presets/custom picker and the history-cap upsell appear, and tapping opens the paywall.
- **Test an actual (fake) purchase** — run from **Xcode** so the StoreKit config applies:

```bash
open "ios/Runner.xcworkspace"   # from flutter_app/
```
Pick a simulator → **Run** ▶ → tap a locked feature → paywall → **Unlock Pro – $3.99** → confirm. Reset via **Debug → StoreKit → Manage Transactions**. If the scheme reports the file "not found," re-point it via **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration**.

> The `.storekit` file is **dev-only** and never affects production. Production purchases require the real `pro_unlock` product (Phase 5) + the active Paid Apps agreement (Phase 3).

---

## Reference — the Android side never mixes in

Android sells **donations** (`support_1/3/5/9`, "cup of tea"), **never** `pro_unlock`. `Monetization.isBillingAvailable` is Android-only; iOS/macOS/web hide donation UI. iOS sells **only** `pro_unlock`. Nothing is gated on Android/web. (See [[android-iap-status]] / [[flutter-port-overview]] in project memory.)

---

## Pre-submission checklist

- [x] Apple Developer Program (Organization, Cardamon Inc) **active**
- [ ] **Paid Applications agreement accepted** + tax + banking complete (needed to sell `pro_unlock`)
- [ ] **EU DSA trader status** completed + verified (trader account, contact info, business doc) — else submission is blocked / the app is removed from the EU
- [ ] App ID `com.cardamon.timeCalculator` registered (no capabilities — IAP needs none)
- [ ] Xcode **Team = Cardamon Inc** on the Runner target (automatic signing, no errors)
- [ ] Built with **Xcode 26+ / iOS 26+ SDK** (April 28, 2026 rule)
- [ ] App Store Connect record created; numeric **Apple ID copied into `kAppleAppId`**
- [ ] **`pro_unlock`** non-consumable created (ID byte-matches `kProSku`), priced, review screenshot, **Ready to Submit**
- [ ] `kApplePurchasesEnabled = true` (it is) — paywall + gating ship
- [ ] `ITSAppUsesNonExemptEncryption = false` present in `Info.plist`
- [ ] `ios/Runner/PrivacyInfo.xcprivacy` added (Runner membership; `NSUserDefaults` → `CA92.1`); Firebase/`shared_preferences` pod manifests present after `pod install`
- [ ] App Privacy label **declares analytics** (Usage Data / Device ID / Diagnostics, all Analytics·not-linked·no-tracking) + **Privacy Policy URL** entered — **NOT** "Data Not Collected"
- [ ] **No ATT** prompt / `NSUserTrackingUsageDescription` (IDFV only)
- [ ] Opaque **1024×1024** icon in the build's asset catalog (no alpha)
- [ ] Screenshots: **iPhone 6.9" (1290×2796)** *and* **iPad 13" (2064×2752)**, RGB, no alpha
- [ ] Text metadata within limits; **no Google Play references** (Guideline 2.3.10)
- [ ] Support URL live with a real contact; Privacy Policy URL set
- [ ] Age rating completed (expect **4+**); Category = **Utilities**; app Price = **Free** (with IAP)
- [ ] **Sandbox-tested**: buy `pro_unlock` unlocks; **Restore Purchases** re-grants
- [ ] `version: 2.4.0+28` (bump the build number for every subsequent upload)
- [ ] IPA built, uploaded, **processed**, attached; **app + IAP submitted together**

# Publishing guide — Time Calculator (Flutter) to Google Play

The new Flutter app uses the **same applicationId** as the live Kotlin app
(`com.dmitriykargashin.cardamontimecalculator`), so uploading its AAB **updates /
replaces** the live app for users. There's no new listing to create.

Legend: **[YOU]** = in Play Console / Firebase / your site · **[ME]** = a code/build
step Claude does · **[BOTH]** = you give a value, Claude uses it.

---

## A. Before building (prep)

1. **[YOU → ME] Firebase config.** Firebase console → your existing project →
   Project settings → the Android app (`com.dmitriykargashin.cardamontimecalculator`)
   → download **`google-services.json`** → put it at
   `flutter_app/android/app/google-services.json`.
   *Why: turns analytics ON. Without it analytics is a silent no-op — and your
   Data safety form (which declares analytics) would then over-state what the
   build does.*

2. **[YOU → ME] Live versionCode.** Play Console → **Test and release →
   Production → Releases** (or "App bundle explorer") → note the **versionCode**
   of the current live release. The new AAB must be **higher**. Tell Claude the
   number.

3. **[YOU] In-app products exist & Active.** Play Console → **Monetize →
   Products → In-app products** → confirm `support_1`, `support_3`, `support_5`,
   `support_9` are listed and **Active** (they likely already exist from the old
   build). Don't create `pro_unlock` (Apple-only).

## B. Build the release AAB

4. **[ME] Bump versionCode + build.** Claude sets `version:` in `pubspec.yaml`
   (and the synced `_appVersionCode` in `feedback_service.dart`) above the live
   number, then runs `flutter build appbundle --release` (upload-key signed via
   `android/key.properties`). Output:
   `build/app/outputs/bundle/release/app-release.aab`.

## C. Complete the App content declarations  (these BLOCK the review if missing)

Play Console → **Policy → App content**:

5. **[YOU] Data safety** — collected data types:
   - **App activity → App interactions** — Collected · **Shared = Yes** ·
     Optional · purposes **Analytics + Advertising/marketing**
   - **Device or other IDs** (app-instance ID **+ Advertising ID**) — Collected ·
     **Shared = Yes** · Optional · **Analytics + Advertising/marketing**
   - **Location → Approximate location** — Collected · Not shared · Optional ·
     **Analytics**
   - All: encrypted in transit **Yes**; deletion method **No**.
6. **[YOU] Advertising ID** — **Yes** → purpose **Advertising or marketing**.
7. **[YOU] Ads** — does the app *show* ads? **No** (the Flutter app shows no ads;
   the ad-ID is for *measurement* only). If the listing still says "contains ads"
   from the Kotlin build, change it to **No**.
8. **[YOU] Financial features** — **No financial features**.
9. **[YOU] Health** — **No health features**.
10. **[YOU] Privacy policy** — paste the live URL
    `https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator`
    (publish the updated page first; content in `docs/privacy-policy-requirements.md`).

## D. Upload to a testing track FIRST (verify before production)

11. **[YOU] Internal testing.** Play Console → **Test and release → Testing →
    Internal testing → Create new release** → upload `app-release.aab` → name the
    release → **Save → Review → Start rollout**.
12. **[YOU] Testers + license testing.** Add your Google account as an **internal
    tester** (Testers tab → copy the opt-in link) AND as a **license tester**
    (Setup → License testing) so test purchases are free.
13. **[YOU] Install via the opt-in link** on your phone (sign in with the tester
    account; install through Play, not sideload — it updates the live app in
    place). Verify:
    - Calculator works; the new bigger keypad/fonts look right.
    - Support screen → buy buttons show **prices** → tap → **test purchase
      dialog** → completes → star appears.
    - Analytics: `adb shell setprop debug.firebase.analytics.app
      com.dmitriykargashin.cardamontimecalculator` → events show in Firebase
      **DebugView**.
    - If your device region is EEA/UK/CH: the **consent dialog** appears on first
      launch; Settings → Privacy shows the Privacy Policy + analytics toggle.

## E. Promote to Production

14. **[YOU] Production release.** Play Console → **Production → Create new
    release** → **"Add from library"** and pick the build you just tested (or
    upload the AAB again) → release notes → **Save → Review → Start rollout to
    Production**. Consider a **staged rollout** (e.g. 20%) first.
15. **[YOU] Submit for review.** Google reviews it (hours to a few days). Once
    approved, the Flutter app rolls out as an **update** over the Kotlin app for
    all users.

## F. After it's live

16. Watch **Play Console → Crashes & ANRs** and **Firebase Analytics** for the
    first day. If anything's wrong, halt the staged rollout.
17. Set up your **Google Ads ↔ Play link** + link **Firebase ↔ Google Ads** when
    you start your install campaign (the ad-ID + event-conversions are already
    wired).

---

### What Claude needs from you to start
- `google-services.json` placed in `android/app/` (step 1)
- the **live versionCode** (step 2)

Then Claude does step 4 (bump + build the AAB) and hands you the file to upload.

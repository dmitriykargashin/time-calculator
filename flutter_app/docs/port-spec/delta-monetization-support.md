# RemoveADS branch delta: monetization-support

## Summary
origin/RemoveADS deletes ALL advertising (AdView layouts, firebase-ads dep, AdMob manifest meta-data, MobileAds code) and the Facebook SDK, and replaces the remove_ads monetization with a voluntary "buy me cups of tea" support model: a new full-screen Support overlay (opened via a new tea-mug toolbar button with a red attention badge until the user buys anything) selling four INAPP non-consumables — support_1/support_3/support_5/support_9 ("buy 1/3/5/9 Cup(s)", former support_15/support_29 removed) — each rewarding a green star and a disabled buy button, with legacy remove_ads grandfathered as support_3; entitlements are acknowledged (never consumed), never persisted locally, and re-derived from Play's purchase cache on every resume. The FAB speed-dial is gone, replaced by a 4-icon action row (Formats, Per, Tea/Support, Settings) and circular-reveal overlays; Rate moved to a "Leave a review" button using the new awesome-app-rating 2.3.0 custom star dialog (5 launches/7 days, show-again 5/10, NEVER after 3 shows, threshold 4 full stars -> store, else mail to support@cardamon.org), a "Share the app" button shares a fixed emoji text with https://bit.ly/TimeCalcCardamon, feedback email changed to support@cardamon.org, billing upgraded to 3.0.3, Firebase Analytics button events added, free flavor bumped to versionCode 20 / 2.0.5, minSdk 21.

## Detailed spec
# Monetization & Support — Delta Spec: master → origin/RemoveADS

All deltas are expressed against `flutter_app/docs/port-spec/ui-activity.md` §§5, 12–17 (the master behavior). Source of truth: end-state `app/src/main/java/com/dmitriykargashin/cardamontimecalculator/ui/calculator/CalculatorActivity.kt` (1629 lines, read in full), `app/build.gradle`, `AndroidManifest.xml`, `res/layout/view_support_app.xml` (NEW), `res/values/strings.xml` on `origin/RemoveADS`.

## 1. Ads: FULLY REMOVED (confirmed)

- spec §14 ("Monetization — AdMob") is **entirely obsolete**. Verified by grep over the whole branch tree:
  - No `<com.google.android.gms.ads.AdView>` in ANY layout (`layout/`, `layout-land/`, new `layout-sw600dp/` — zero matches).
  - Dependency `com.google.firebase:firebase-ads:18.3.0` deleted from `app/build.gradle`.
  - Manifest meta-data `com.google.android.gms.ads.APPLICATION_ID` (`ca-app-pub-1503550792620709~9288270264`) deleted.
  - All `MobileAds.initialize` / `AdRequest` / `adView.loadAd|pause|resume|destroy` code is commented out (kept only as comments in onCreate/onResume/onDestroy/checkPurchases); `isRemoveAdsPurchased` field and `removeAds()` function are gone (field exists only as a comment).
  - No interstitials (still none).
- Dead leftovers (do NOT port): `strings.xml` still contains `banner_ad_unit_id` (`ca-app-pub-1503550792620709/2350324800`) and `facebook_app_id` (`2341977856105223`) but nothing references them.
- Facebook SDK fully removed: dependency `com.facebook.android:facebook-android-sdk:5.13.0` deleted, manifest meta-data `com.facebook.sdk.ApplicationId` deleted, the unused `import com.facebook.FacebookSdk` deleted. (spec §17 obsolete.)
- Manifest delta: ADDED `<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />`; `INTERNET` kept.
- Marketing copy confirms intent: "the application is now free and ad-free" (support screen text).

## 2. Build / flavors / dependencies (spec §15 last bullet delta)

- Both flavors KEPT, `buildConfigField "boolean", "PRO_VERSION"` kept, `isPaidVersion() = BuildConfig.PRO_VERSION` kept — but it now ONLY gates `setupBillingClient()` (there is no ad code left for it to gate). Pro = no billing at all (support buttons inert).
- minSdkVersion: defaultConfig 19→21, free 19→21, pro 20→21.
- free: versionCode 15→**20**, versionName "1.0.11"→**"2.0.5"**. pro: versionCode 6 / "1.0.4" unchanged (stale).
- Dependency deltas:
  - REMOVED: `com.google.firebase:firebase-ads:18.3.0`, `com.github.hotchemi:android-rate:1.0.1`, `com.facebook.android:facebook-android-sdk:5.13.0`.
  - ADDED: `platform('com.google.firebase:firebase-bom:26.8.0')` + `com.google.firebase:firebase-analytics-ktx` (Firebase Analytics is NEW), `com.suddenh4x.ratingdialog:awesome-app-rating:2.3.0`.
  - UPGRADED: billing `2.1.0` → `com.android.billingclient:billing:3.0.3` + `billing-ktx:3.0.3` (still SkuDetails/queryPurchases API shape); appcompat 1.2.0; constraintlayout 2.0.4; material 1.4.0-alpha01; lifecycle-extensions 2.2.0 / viewmodel-ktx 2.3.0.
  - Root: AGP 3.5.2→4.2.0-alpha16, Kotlin 1.3.50→1.4.10, google-services 4.3.2→4.3.4 (plugin still applied at bottom of app/build.gradle).

## 3. Support ("cups of tea") purchase model — replaces remove_ads (spec §15 delta)

### 3.1 Product catalog
`skuList = listOf("support_1", "support_3", "support_5", "support_9", "remove_ads")` — all queried as `SkuType.INAPP`. `"support_15"` and `"support_29"` existed in earlier branch commits and were removed in commit cf8e0ce ("Removed more than 9 cups buttons") — they remain only as commented-out code/IDs; do not port. Every product is **non-consumable**: acknowledged via `acknowledgePurchase`, never consumed (consume code exists only in comments labeled "test case use only"). Each can therefore be bought exactly once per Google account.

The legacy `remove_ads` SKU is kept for grandfathering: it is treated everywhere as equivalent to `support_3` (see 3.4/3.5).

### 3.2 Support screen (NEW overlay, `view_support_app.xml`)
Full-screen overlay (`support_appLayout`, an `<include>` in all three activity_main variants) with background `@color/colorSecondaryBackgroundForSupport`:
- Toolbar `toolbarSupport_app`, nav icon = homeAsUpIndicator, title verbatim: **"The app development support"**.
- ScrollView body, all children centered:
  - `labelSupport` TextView, centered, text = `@string/support_app_text` verbatim:
    `"For your best user experience, the application is now free and ad-free.\n If you would like to support me, as a developer of the app, you can buy me some CUPS of TEA.\nAny purchase will give you a green star to the right of the corresponding button\n\nYou can also leave a review or share to help improve the app."`
    (note the literal leading space after the first `\n`).
  - Four 200dp-wide buttons, stacked (32dp top margin on the first, then 16dp), each with left drawable `ic_food` (a tea-mug vector):
    - `btnSupport1` — text "buy 1 Cup" → SKU `support_1`
    - `btnSupport3` — text "buy 3 Cups" → SKU `support_3` (and legacy `remove_ads`)
    - `btnSupport5` — text "buy 5 Cups" → SKU `support_5`
    - `btnSupport9` — text "buy 9 Cups" → SKU `support_9`
  - Next to each buy button: `imageStar1/3/5/9` ImageView, `ic_star_green_24dp`, 16dp start margin, initially `visibility="gone"` — the "thank-you" green star.
  - `btnSupportRate` — 200dp, left drawable `ic_star_blue_24dp` (accent-colored star), text "Leave a review" → shows the rate dialog immediately (see §5).
  - `btnShareTheApp` — 200dp, left drawable `ic_baseline_share_24`, text "Share the app" → share sheet (see §6).

### 3.3 Entry point: `buttonFood`
New ImageButton in the main screen's action row (see §7), contentDescription "Tea", default src `ic_food_checked`. Click → circular-reveal open of `support_appLayout` (center = buttonFood on-screen center, radius 0→hypot(commonW, commonH), AccelerateDecelerate, 600ms; `setIsSupportAppLayoutVisible(true)` + VISIBLE before start; API<21 just sets visible) + analytics event `button_support`.
Icon semantics (set in `checkPurchases()`): user owns ≥1 purchase → `ic_food` (plain mug); owns none → `ic_food_checked` (same mug **plus a red dot badge** top-right, `#FF0000` circle) — i.e. the red dot is an attention nudge for non-supporters and disappears once anything was bought.

### 3.4 Billing flow (free flavor only)
- `setupBillingClient()` unchanged in shape: `BillingClient.newBuilder(this).enablePendingPurchases().setListener(this).build()`; `startConnection`; on `onBillingSetupFinished` OK → `loadAllSKUs()` + `checkPurchases()`; `onBillingServiceDisconnected` → logs "Failed" only (no retry).
- `loadAllSKUs()`: if `billingClient.isReady` → `querySkuDetailsAsync(SkuDetailsParams(skuList, INAPP))`; on OK and non-empty list, for each `skuDetails` attaches buy-click listeners:
  - `sku == "remove_ads" || sku == "support_3"` → `btnSupport3` listener
  - `sku == "support_1"` → `btnSupport1`; `"support_5"` → `btnSupport5`; `"support_9"` → `btnSupport9`
  - Each listener: `launchBillingFlow(this, BillingFlowParams.newBuilder().setSkuDetails(skuDetails).build())` + Firebase event `button_support_N { button_name: "buttonSupportN" }`. (No FAB fade-out anymore — there is no FAB.)
- `onPurchasesUpdated(result, purchases)`: identical to master — OK + non-null → for each purchase `acknowledgePurchase(purchase.purchaseToken)` then `handlePurchase(purchase)`; USER_CANCELED → logs only; any other code → logs + `Snackbar.make(commonConstraintLayout, "Purchase is pending. Please wait", LENGTH_SHORT)`.
- `acknowledgePurchase(token)`: unchanged (logs only in callback).

### 3.5 Purchase application — `handlePurchase(purchase)`
If `purchaseState == PURCHASED`:
- `sku == "remove_ads" || sku == "support_3"` → `imageStar3.visibility = VISIBLE; btnSupport3.isEnabled = false; btnSupport3.alpha = 0.5f`
- `sku == "support_1"` → same for `imageStar1`/`btnSupport1`
- `sku == "support_5"` → same for `imageStar5`/`btnSupport5`
- `sku == "support_9"` → same for `imageStar9`/`btnSupport9`
So an owned product = green star visible + its buy button disabled at 50% opacity. Legacy `remove_ads` owners are shown as owning the 3-cups tier.
If `PENDING` → logs "Purchase pending" only. (No removeAds() — deleted.)

### 3.6 `checkPurchases()` — entitlement refresh
Called from `onBillingSetupFinished` and from **every `onResume()`** (now unconditionally — master gated nothing differently here, but see suspected bug #1). Synchronous `billingClient.queryPurchases(INAPP)`:
- non-empty list → `handlePurchase` each, then `buttonFood.setImageResource(R.drawable.ic_food)` (badge off);
- empty/null → `buttonFood.setImageResource(R.drawable.ic_food_checked)` (red-dot badge on). **No ad loading anymore** in the empty branch (commented out).
- logs "Purchases checked".

### 3.7 Thank-you state persistence
**None.** No SharedPreferences key, no DB: stars/disabled buttons/tea-badge are purely re-derived from Play's purchase cache on every resume and after billing setup (same in-memory-only philosophy as master's `isRemoveAdsPurchased`). `PrefRepository` (new on branch) persists ONLY the theme (`PREF_THEME_COLOR` in prefs file `MY_APP_PREF`). Overlay visibility (`isInSupportAppViewMode`, `isInSettingsViewMode`) lives in the in-memory `UtilityRepository` singleton (survives rotation, not process death).

## 4. Old remove_ads SKU & "Remove Ads" UI

- The "Remove Ads" FAB row (`removeads`/`tvRemoveAds`), `removeAds()`, and the `isRemoveAdsPurchased` flag are deleted. Strings `remove_ads`/`removeads` ("Remove Ads") remain in strings.xml but are unreferenced.
- The SKU id `remove_ads` itself is still queried and honored, mapped 1:1 onto the `support_3` row (listener attachment and entitlement display), so prior buyers keep a visible thank-you and cannot be double-charged for that row.

## 5. Rate dialog — replaced library + new explicit Review button (spec §16 replaced)

hotchemi android-rate (installDays 10 / launchTimes 10 / remindInterval 2 / `new_rate_dialog_message`) is REMOVED (dep deleted; `setupRateMe()`/`rateMeOnGooglePlay()` survive only as commented code; `new_rate_dialog_message` string is now dead). Replaced by **`com.suddenh4x.ratingdialog:awesome-app-rating:2.3.0`** — a custom Material star-rating dialog flow (NOT the Google Play in-app review API; this library can optionally use it but this app does not).

Shared builder `rateBuilder()` config (verbatim):
```
AppRating.Builder(this)
  .setMinimumLaunchTimes(5)
  .setMinimumDays(7)
  .setMinimumLaunchTimesToShowAgain(5)
  .setMinimumDaysToShowAgain(10)
  .setRatingThreshold(RatingThreshold.FOUR)
  .setShowOnlyFullStars(true)
  .setTitleTextId(R.string.rate_main_text)
  .setMessageTextId(R.string.rate_second_text)
  .setStoreRatingMessageTextId(R.string.rate_store_second_text)
  .setMailFeedbackMessageTextId(R.string.rate_feedback_main_text)
  .setMailSettingsForFeedbackDialog(MailSettings(
      mailAddress = "support@cardamon.org",
      subject = "Feedback Time Calculator Cardamon v.${BuildConfig.VERSION_CODE}"))
```
Strings verbatim:
- `rate_main_text` = "How was your experience with the Time Calculator?"
- `rate_second_text` = "The app is absolutely free.\nYou can contribute to the development of the app by writing a review!"
- `rate_store_second_text` = "If you enjoy using this app, would you mind taking a moment to rate it in the store?\n\nYour review will help this app develop further."
- `rate_feedback_main_text` = "I want to improve the App with your help. Don't hesitate to send an email with your suggestions.\n\nSend an email?"
- `never_show_ratetheapp` = "NEVER"

Behavior:
1. **Auto prompt** — in `onCreate`, ONLY when `savedInstanceState == null` (i.e. not on rotation/recreation — master showed it on every onCreate):
   `rateBuilder().showRateNeverButtonAfterNTimes(R.string.never_show_ratetheapp, null, 3).showIfMeetsConditions()`
   Conditions: ≥5 launches AND ≥7 days since install; after the user picks "later", needs 5 more launches AND 10 more days. A "NEVER" opt-out button appears only from the 3rd time the dialog is shown; tapping it suppresses the auto prompt forever. (Library tracks launch count/dates/agreed state in its own SharedPreferences.)
2. **Dialog flow** (library): star bar restricted to FULL stars (1–5), title `rate_main_text`, message `rate_second_text`, Confirm/Later(/Never) buttons. After confirming a rating:
   - rating ≥ 4 stars (`RatingThreshold.FOUR`) → second "store rating" dialog with message `rate_store_second_text` (default library title — `setStoreRatingTitleTextId` is commented out); its positive button opens the app's Play Store listing.
   - rating < 4 → "mail feedback" dialog with message `rate_feedback_main_text`; positive button composes an email to **support@cardamon.org** with subject **"Feedback Time Calculator Cardamon v.{versionCode}"** (note the `v.` prefix; versionCode = 20 for the free flavor).
3. **Explicit Review button** — `btnSupportRate` ("Leave a review") on the support screen: `rateBuilder().dontCountThisAsAppLaunch().showNow()` — shows the same rating dialog IMMEDIATELY, bypassing all conditions and without incrementing the launch counter; the manual path does NOT add the NEVER button. Fires analytics `button_support_rate`.

## 6. Share-the-app button (NEW)

`btnShareTheApp` ("Share the app", support screen) → `shareTheApp()` + analytics `button_share_the_app`:
- `Intent(Intent.ACTION_SEND)`, `type = "text/plain"`, `EXTRA_TEXT` verbatim (no chooser title, no EXTRA_SUBJECT):
  `"😍 The Best Time Calculator.\n  ✅ Work Hours\n  ✅ Allows you to select different time formats for the result\n  ✅ Convert any Time Units\n  ✅ Calculates Salary, Distance, etc\n\n🔥 Please, try it: https://bit.ly/TimeCalcCardamon"`
  (😍 = U+1F60D, ✅ = U+2705, 🔥 = U+1F525; each bullet line is indented with two spaces; URL is the bit.ly short link, not a market:// link.)

## 7. FAB speed-dial REMOVED — replaced by an action-button row + two new overlays (spec §12 replaced)

Deleted entirely: `fab`, `dimmedBackground` scrim, `rateApp`/`tvRateApp`, `feedback`/`tvFeedback`, `removeads`/`tvRemoveAds`, `fabInitalize()`, `fadeIn/fadeOut/fadeInFABs/fadeOutFABs/showIn/showOut`, FAB strings usage, `ic_menu/ic_close` toggling.

End-state main screen has a horizontal row of 4 borderless ImageButtons (between the keypad and the result divider `tvSpaceWithShadowOnly`, replacing master's text buttons `buttonFormats`/`buttonPer` and the FAB cluster). Left → right:
1. `buttonFormats` — icon `ic_convert_24` — opens formats overlay (existing behavior, 600ms reveal) + NEW analytics `button_formats`.
2. `buttonPer` — icon `ic_per` — opens Per overlay + NEW analytics `button_per`.
3. `buttonFood` — icon `ic_food_checked`/`ic_food` (tea mug ± red badge) — opens NEW support overlay + analytics `button_support`.
4. `buttonSettings` — icon `ic_settings` — opens NEW settings overlay (theme radio group System default/Light/Dark + "Send Feedback" button `buttonFeedback_Sendfeedback`); no analytics event.
(The disabled-state alpha-0.2 gating of buttonPer/buttonFormats via `getIsPerViewButtonDisabled()`/NEW `getIsFormatsViewButtonDisabled()` LiveData applies to the icon buttons.)

All four overlays (`formatsLayout`, `perLayout`, `support_appLayout`, `settingsLayout`) use the same circular-reveal open (600ms, from the launching button's center) and close (450ms, toward (10,10) from toolbar nav icon / back). `onBackPressed` priority chain: formats → per → **support** → **settings** → `moveTaskToBack(true)`.

Former FAB actions relocated:
- "Rate the App" → support screen "Leave a review" (and the auto prompt).
- "Send Feedback" → settings screen `buttonFeedback_Sendfeedback` → `sendFeedback()` + analytics `button_feedback`. `sendFeedback()` is unchanged in mechanism (ACTION_SENDTO `mailto:`, subject `"Feedback Time Calculator Cardamon ${BuildConfig.VERSION_CODE}"` — no `v.` prefix here, start only if resolvable) but the EMAIL CHANGED: `dmitrii.kargashin@cardamon.org` → **`support@cardamon.org`**.
- "Remove Ads" → the four tea purchases.

## 8. Firebase Analytics (NEW, replaces nothing)

`mFirebaseAnalytics = Firebase.analytics` in onCreate (all flavors). Events, all with a single param `button_name`:
| event | button_name | trigger |
|---|---|---|
| `button_support_1` | buttonSupport1 | buy 1 Cup |
| `button_support_3` | buttonSupport3 | buy 3 Cups |
| `button_support_5` | buttonSupport5 | buy 5 Cups |
| `button_support_9` | buttonSupport9 | buy 9 Cups |
| `button_support_rate` | buttonSupportRate | Leave a review |
| `button_share_the_app` | buttonShareTheApp | Share the app |
| `button_support` | buttonSupport | tea button (open support screen) |
| `button_formats` | buttonFormats | open formats |
| `button_per` | buttonPer | open per |
| `button_feedback` | buttonFeedback | Send Feedback (settings) |
| `button_long_delete` | buttonLongDelete | long-press clear |

## 9. Constants quick table (delta of spec §19)

| Item | Old (master) | New (RemoveADS) |
|---|---|---|
| AdMob app id / banner unit / test device | present | **deleted** (dead strings remain) |
| Facebook app id | 2341977856105223 | **deleted from manifest/deps** (dead string remains) |
| Billing SKUs | `remove_ads` | `support_1`, `support_3`, `support_5`, `support_9`, legacy `remove_ads`≡support_3 — all INAPP non-consumable |
| Billing library | 2.1.0 | 3.0.3 (+ktx) |
| Feedback email | dmitrii.kargashin@cardamon.org | **support@cardamon.org** |
| Feedback subject | "Feedback Time Calculator Cardamon {vc}" | unchanged; rate-dialog mail uses "Feedback Time Calculator Cardamon v.{vc}" |
| Rate library | hotchemi android-rate 1.0.1 (10 days/10 launches/remind 2) | awesome-app-rating 2.3.0 (5 launches/7 days; again 5/10; NEVER after 3 shows; threshold 4 full stars) |
| Snackbar "Purchase is pending. Please wait" | kept | kept (unchanged) |
| FAB scrim/items | 100ms/200ms speed-dial | **deleted** |
| free versionCode/Name | 15 / 1.0.11 | 20 / 2.0.5 |
| minSdk | 19 (pro 20) | 21 everywhere |

## Suspected bugs
- Pro-flavor crash: onResume() calls checkPurchases() unconditionally, but billingClient (lateinit) is only initialized inside `if (!isPaidVersion())` in onCreate -> UninitializedPropertyAccessException on every pro-build resume. Master gated the resume-path work; the branch lost the guard.
- checkPurchases() runs on every onResume even before the billing connection is established; queryPurchases on an unconnected client returns a null/empty list, so the code momentarily treats a paying user as a non-supporter (red-dot ic_food_checked, all buy buttons enabled) until onBillingSetupFinished fires.
- loadAllSKUs: `skuDetailsList?.isNotEmpty()!!` throws NPE when Play returns a null list (possible in billing 3.x on error).
- remove_ads and support_3 both match the btnSupport3 click-listener condition; if Play returns SkuDetails for both, whichever appears later in the iteration overwrites the listener, so 'buy 3 Cups' may actually launch the legacy remove_ads purchase flow. (Mapping remove_ads OWNERSHIP onto the 3-cups star is clearly intentional grandfathering; the listener overwrite is not.)
- onPurchasesUpdated acknowledges EVERY purchase (acknowledgePurchase(purchase.purchaseToken)) before checking purchaseState - acknowledging a PENDING purchase is a billing error; carried over from master.
- The 'other error' branch of onPurchasesUpdated shows the snackbar 'Purchase is pending. Please wait' for ANY non-OK/non-USER_CANCELED result (ITEM_ALREADY_OWNED, network failure, etc.) - misleading copy, carried over from master.
- buttonFood icon naming looks inverted: HAS purchases -> ic_food (plain mug), NO purchases -> ic_food_checked (mug + red dot). Since ic_food_checked's extra path is a red attention dot, the behavior (badge nudging non-supporters) is plausibly intended, but the '_checked' name suggests the assignments may have been swapped; the Flutter port should treat it as 'red attention badge while user owns nothing'.
- Support entitlements (stars/disabled buttons) are never persisted locally; with Play unavailable/offline the support screen lets an owner re-tap a buy button (Play will reject with ITEM_ALREADY_OWNED -> the misleading pending snackbar).
- radio_buttons_supportview.xml is a malformed dead resource: a <selector> carrying layout_width/height attributes whose checked and unchecked states both map to ic_food; nothing references it - do not port.
- setSupportActionBar is called three times in a row (toolbarSupport_app, toolbarPer, toolbar) - only the last call wins; harmless because all overlay toolbars get manual setNavigationOnClickListener, but it signals the toolbars are not real action bars.
- Pro flavor (if the resume crash were fixed) would show the support screen with buy buttons that never get click listeners (setupBillingClient skipped), i.e. silently dead buttons; only 'Leave a review' and 'Share the app' would work.
- Dead strings left behind on purpose or by accident: banner_ad_unit_id, facebook_app_id, remove_ads/removeads, new_rate_dialog_message are all unreferenced after the change.

## Flutter porting notes
- lib/ui/widgets/ad_banner.dart: DELETE the whole file. Remove `const AdBannerSlot()` from lib/ui/calculator_screen.dart (~line 287) and drop the google_mobile_ads dependency from pubspec.yaml. No ad SDK initialization remains anywhere.
- lib/services/monetization.dart: rewrite from a single remove_ads non-consumable to a catalog of four non-consumables: 'support_1', 'support_3', 'support_5', 'support_9', plus legacy 'remove_ads' treated as equivalent to support_3 (ownership of remove_ads marks the 3-cups tier owned; do NOT sell remove_ads). Replace adsEnabled/adsRemoved/canPurchaseRemoveAds with: Set<String> ownedTiers, bool hasAnyPurchase, ProductDetails per tier, and buy(productId) using buyNonConsumable + completePurchase (acknowledge). Keep the Android-free-build gating (kProVersion) and the restorePurchases-on-init/refresh pattern; refresh on app resume to mirror checkPurchases-every-onResume. The Android original persists nothing; the port may keep its deliberate SharedPreferences persistence but it must become per-product (e.g. 'owned_support_skus') instead of the single 'ads_removed' bool.
- lib/ui/widgets/fab_menu.dart: DELETE. In lib/ui/calculator_screen.dart replace the FabMenu (and its onRateApp/onFeedback/onRemoveAds wiring at ~lines 253-258) with the 4-button action row: Formats (convert icon), Per, Tea/Support (mug icon with a red dot badge while Monetization.hasAnyPurchase == false), Settings. The Formats/Per buttons already exist as actions - they just change to icon buttons; Tea opens the new support overlay, Settings opens the settings overlay (settings overlay itself is another owner's area, but it hosts the relocated Send Feedback button).
- NEW widget (suggest lib/ui/support_screen.dart): full-screen support overlay opened with the existing lib/ui/widgets/circular_reveal.dart (600ms open from the tea button center, 450ms close toward top-left; back-press chain formats > per > support > settings > background). Content per spec §3.2: toolbar 'The app development support', the support_app_text paragraph, four 200dp 'buy N Cup(s)' buttons with mug icon, green star + disabled@50% per owned tier, 'Leave a review' button, 'Share the app' button.
- lib/services/rate_service.dart: thresholds and flow change completely. Replace android-rate (10 days/10 launches/2-day remind) with awesome-app-rating semantics: min 5 launches AND 7 days; after a 'later' answer require 5 more launches AND 10 more days; a 'NEVER' opt-out option only from the 3rd time the dialog shows; auto-prompt fired once per cold start (not on rotation/state-restore). The branch uses a CUSTOM star dialog (full stars only, threshold 4): >=4 stars -> store-rating step (openStoreListing stays useful here, message rate_store_second_text); <4 stars -> mail-feedback step composing to support@cardamon.org with subject 'Feedback Time Calculator Cardamon v.{versionCode}'. The current in_app_review-based maybeAutoPrompt() is a behavioral mismatch now: either implement the two-step custom dialog (preferred, also needed for the explicit button) or document keeping the native sheet as a deviation. Add a showNow() entry point (bypasses all counters, does not increment launch count, no NEVER button) for the support screen's 'Leave a review' button - it must NOT just call openStoreListing() as calculator_screen.dart does today.
- lib/config.dart: change kFeedbackEmail from 'dmitrii.kargashin@cardamon.org' to 'support@cardamon.org'. lib/services/feedback_service.dart: bump _appVersionCode 16 -> 20 (pubspec version should become 2.0.5+20 to match free versionCode 20 / versionName 2.0.5); subject pattern unchanged ('Feedback Time Calculator Cardamon 20' - note the rate-dialog mail variant adds a 'v.' prefix). The Send Feedback action moves from the FAB to the Settings overlay.
- NEW share function (extend lib/services/feedback_service.dart or add lib/services/share_service.dart) using the already-imported share_plus: plain-text share with the exact text '😍 The Best Time Calculator.\n  ✅ Work Hours\n  ✅ Allows you to select different time formats for the result\n  ✅ Convert any Time Units\n  ✅ Calculates Salary, Distance, etc\n\n🔥 Please, try it: https://bit.ly/TimeCalcCardamon' (no subject, no chooser title). Wire to the support screen's 'Share the app' button.
- lib/main.dart: keep Monetization.instance.init() (now purchases-only - ensure it no longer calls MobileAds.instance.initialize) and RateService registerLaunch/maybeAutoPrompt with the new 5/7/5/10/NEVER-after-3 semantics; the auto prompt should run only on a fresh launch.
- Analytics (optional): the branch adds Firebase Analytics events button_support_{1,3,5,9}, button_support_rate, button_share_the_app, button_support, button_formats, button_per, button_feedback, button_long_delete - each with param button_name. If parity is wanted, add firebase_analytics and a thin analytics service; otherwise record as a known deviation.
- Snackbar parity: keep showing 'Purchase is pending. Please wait' (SnackBar) on purchase-stream errors other than user-cancel, anchored over the calculator screen.

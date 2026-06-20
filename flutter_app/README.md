# Time Calculator Cardamon (Flutter)

Flutter port of the Android app **Time Calculator Cardamon** (originally
Kotlin, `app/src` in this repository). The app is a calculator for time
values: add, subtract, multiply and divide expressions written in hours,
minutes, seconds, days, weeks, months and years, choose the output format,
and use the "Per" view to derive an amount (salary, distance, etc.) for a
time interval.

- Calculation engine: `lib/engine/` (lexer, interpreter, result conversion) -
  a faithful port of the Kotlin engine, covered by the tests in `test/`.
- UI: `lib/ui/` - a **Material 3 Expressive** restyle of the calculator
  screen: two large rounded tonal cards (a hero display card with the
  format chip, expression, and big live result, over a keypad card), every
  key its own soft ~18dp tonal cell (blue-tonal operators, green-tonal
  time-unit keys, neutral digits) preserving the green=time / blue=accent
  identity, and the tools row + format selector as filled-tonal chips.
  Includes the filled-tonal action buttons (Per / Support / Settings +
  backspace), Formats / Per / Support / Settings circular-reveal overlays,
  a responsive keypad (4x6 portrait, 7-column landscape/tablet), and the
  full light/dark theme pair switched from the Settings overlay; the
  ads-era FAB menu and banner slot are gone. The **Formats, Per and
  Settings overlays share the same Material 3 Expressive styling** as the
  calculator: a clean header with the calculator's filled-tonal rounded
  back button, content floating on the main background (the old flat grey
  panels + dated toolbars are retired), and the calculator's tonal-card
  idiom carried through - Formats and Per results are soft rounded tonal
  cards (`displayCardSurface` + 32dp `cardRadius`) with the green unit
  emphasis preserved (the selected format card is highlighted with an
  accent ring + green-tonal fill + check), the Per inputs are M3 filled
  text fields, and Settings rows are grouped into rounded tonal sections.
  Every overlay reuses the same palette tokens so the whole app reads as
  one design family in both light and dark.
- Services: `lib/services/` (support "cups of tea" IAPs, rating dialog flow,
  feedback email, share) and `lib/config.dart` (flavor flag, package id,
  feedback address, store URL, share text).

## Port provenance

The port was written against the exhaustive behavior specs in
`docs/port-spec/*.md`, which were extracted from and verified against the
original Kotlin source. The base port follows the MASTER branch specs; the
`delta-*.md` specs capture the RemoveADS branch changes that were applied on
top. `docs/port-spec/critic-gaps.md` and `docs/port-spec/delta-critic-gaps.md`
record corrections and a few deliberate divergences from the original app:

- The Facebook SDK was dropped entirely.
- Crash guards: the Per view no longer crashes on zero/ERROR results (an
  empty conversion is treated as 0 / Per is disabled), and a lone "." in the
  amount input is try-parsed instead of throwing.
- Donation IAPs run only on the Android free build (see "Monetization status"
  below). Apple platforms additionally have an opt-in one-time "Pro" unlock
  that gates three features (see "iOS Pro (freemium)"), dormant until
  `kApplePurchasesEnabled` is flipped on. Ads were removed entirely (RemoveADS
  branch).
- The RemoveADS branch's Firebase Analytics events (`button_support_{1,3,5,9}`,
  `button_support_rate`, `button_share_the_app`, `button_support`,
  `button_formats`, `button_per`, `button_feedback`, `button_long_delete`)
  are SKIPPED in this port: the repository ships no `google-services.json`,
  so Firebase cannot be configured. Known deviation, not a TODO.
- Four RemoveADS branch bugs are deliberately NOT replicated (each marked
  with a `DELIBERATE FIX` comment at the relevant code site): unit plurals
  derive from the number token's current value instead of the first
  keypress (`lib/engine/lexical_analyzer.dart`), `Tokens.clone` no longer
  double-appends `s` (`lib/engine/token.dart` / `tokens.dart`), the dark
  shadow-strip stripe uses `#30222222` instead of the branch's `#00222222`
  typo (`lib/ui/theme.dart`), and the leftover translucent-yellow
  `#9AFDD835` ToolbarTheme literals were not ported. The branch's pro-flavor
  billing crash also stays fixed (see "Build commands").
- Two additional lexer deviations (both sanctioned by
  `delta-engine-delta.md`'s "decide whether to reproduce or fix" notes, both
  pinned by `test/engine_delta_test.dart`): unit tokens consume the matched
  singular keyword plus an optional trailing `s` instead of the branch's
  pluralized-length cursor advance, which over-advanced and corrupted its own
  seeded format previews (`lib/engine/lexical_analyzer.dart`,
  `_consumedLength`); and malformed numbers like `1.2.3` get a
  `BigDecimal.tryParse` fallback value of 1 instead of the branch's lex-time
  `NumberFormatException` (`_findCurrentDigitalToken`).
- Rating flow store step: after a >=4-star rating the port tries the NATIVE
  in-app review sheet first, then falls back to the Play listing
  (`lib/services/rate_service.dart`); the Android branch opened the Play
  listing directly. Kept as a deliberate UX improvement.

## Theme and Settings

The Settings overlay (gear icon in the action row, `lib/ui/settings_screen.dart`)
offers a three-way theme choice: **System** (default), **Light**, **Dark**.
The full dark palette from the RemoveADS branch is ported in
`lib/ui/theme.dart` (`AppPalette.dark`), and `MaterialApp.themeMode` follows
the choice live. The selection persists across launches via
`shared_preferences` using the original Android key verbatim
(`PREF_THEME_COLOR`, values `0`=system / `1`=light / `2`=dark — see
`lib/state/settings_model.dart`).

## Play Store listing preservation

The Google Play listing is preserved exactly:

- **applicationId**: `com.dmitriykargashin.cardamontimecalculator`,
  configured in `android/app/build.gradle.kts`. Do not change it.
  (The legacy paid `....pro` listing is abandoned; its build flavor was
  removed in June 2026 - the app is free with donation purchases only. The
  flavor setup is recoverable from git history if ever needed.)
- **versionCode policy**: the original listing ended at versionCode 15
  (1.0.11); the RemoveADS branch reached 20 (2.0.5), so the Flutter era
  continues from `version: 2.0.5+20` in `pubspec.yaml`. Bump the `+N` build
  number for every release (it becomes the Android `versionCode`, which must
  always increase). Keep `_appVersionCode` in
  `lib/services/feedback_service.dart` in sync.
- **Upload key**: release signing is configured via `android/key.properties`
  (kept out of source control). The keystore itself is backed up on Google
  Drive; restore it to the path referenced by `storeFile` in `key.properties`
  before building a release.

## Build commands

Run everything from this directory (`flutter_app/`).

| Target | Command |
| --- | --- |
| Android (Play release) | `flutter build appbundle --release` |
| Android debug APK | `flutter build apk --debug` |
| Web | `flutter build web --release` |
| iOS | `flutter build ios --release` |
| macOS | `flutter build macos --release` |

`android/app/build.gradle.kts` fails any release build when
`android/key.properties` is missing instead of silently falling back to the
debug signing key.

Development:

```sh
flutter run -d <device> --flavor free   # flavor required on Android
flutter test                            # engine + widget tests
flutter analyze
```

## Monetization status per platform

There are NO ads anywhere. Monetization is voluntary "buy me cups of tea"
donations: four non-consumable IAPs (`support_1`, `support_3`, `support_5`,
`support_9`); the legacy `remove_ads` purchase is grandfathered as owning
`support_3`.

| Platform | Status |
| --- | --- |
| Android | Live: the four support in-app purchases (+ legacy `remove_ads` restore). |
| iOS / macOS | Disabled. Enabling requires the support products in App Store Connect, then widening the platform gate. |
| Web | Disabled. No IAP plugin support on web; would need a web payments integration. |

`lib/services/monetization.dart` gates everything: outside Android it is a
no-op (`isOwned`/`hasAnySupport` are always false), so the rest of the app
needs no platform checks.

## iOS Pro (freemium)

Apple platforms (iOS/macOS) have an **additional**, Apple-only one-time "Pro"
unlock — a single non-consumable IAP, product id `pro_unlock` (`kProSku` in
`lib/config.dart`). It gates three features behind a paywall; everything else
stays free. **Android and web are never gated** — they get every feature for
free, plus the "cups of tea" donations on Android. None of this depends on
the donations, which remain Android-only.

The three Pro-gated features (each routes a locked tap to the paywall):

1. **The value / "Per" calculator** — the `more_time` action icon shows a lock
   badge; tapping it opens the paywall instead of the Per overlay.
2. **All result formats** — only the free set selects normally; every other
   format card shows a trailing lock and opens the paywall (the selection does
   not change).
3. **Dark theme** — the Settings System/Dark radio rows are locked; while
   gated the app is clamped to `ThemeMode.light` (the stored `0`/`1`/`2`
   choice is preserved and re-applies instantly on unlock).

The always-free result formats are configurable via `kFreeFormatNames` in
`lib/services/entitlements.dart` (matched against
`ResultFormat.textPresentationOfTokens`):

```
Hour Minute, Hour, Minute, Second, Day, Year
```

Change that set to move formats between the free and Pro tiers.

### How the gate is wired

`lib/services/monetization.dart` exposes the entitlement contract the UI uses:

- `isProGated` — `true` **only** on Apple platforms **and** when
  `kApplePurchasesEnabled` is `true`. Android, web, and Apple-before-go-live
  all report `false`, so **nothing is ever gated and no half-built locks ship**
  until Pro billing is actually live.
- `isProUnlocked` — `pro_unlock` is owned (persisted in the existing owned-SKU
  cache, restored like the donations; grant-only).
- `hasPro` — `!isProGated || isProUnlocked`; the single getter the UI reads to
  decide whether premium features are available (always `true` off Apple).
- `canBuyPro` / `proPrice` — drive the paywall's purchase button and its
  localized price.
- `buyPro()` / `restore()` — purchase and restore (no-ops while billing is
  inactive).

`isFormatFree(name)` (`lib/services/entitlements.dart`) and
`SettingsModel.effectiveThemeMode` apply the same rule consistently. The
paywall itself is `showProPaywall(context)` in `lib/ui/pro_screen.dart` (a
modal bottom sheet, callable from any screen). Both gating states are covered
by `test/pro_gating_test.dart`, which forces gating on via the
`@visibleForTesting` `Monetization.debugSetProGated` seam (so the tests do not
depend on the `kApplePurchasesEnabled` const).

### Go-live steps (iOS/macOS)

While `kApplePurchasesEnabled` is `false` (the shipped default) NOTHING is
gated on any platform — the paywall and all locks are dormant. To turn Pro on:

1. Create the `pro_unlock` **non-consumable** product in App Store Connect
   (price it, submit it for review with the build). The product id must match
   `kProSku` exactly.
2. Set `kAppleAppId` in `lib/config.dart` to the App Store Connect numeric app
   id (needed for the store/review links).
3. Flip `kApplePurchasesEnabled` to `true` in `lib/config.dart`.
4. Ship. Gating, the paywall, and Pro billing all turn on for Apple platforms
   only; Android and web are unaffected.

## Project layout

```
lib/
  config.dart        compile-time flavor flag, package id, feedback email
  engine/            lexer, interpreter, result conversion (ported, tested)
  data/  state/      persistence (shared_preferences) and app state
  services/          monetization (support IAPs), rating flow, feedback, share
  ui/                screens and widgets
docs/port-spec/      behavior specs the port was written against
test/                engine and widget tests
```

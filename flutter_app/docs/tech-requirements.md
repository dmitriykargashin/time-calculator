# Cardamon Time Calculator — Technical Requirements (v1.1)

**Date:** 2026-06-20
**Version:** 1.1
**Source:** improvement-backlog.md (256 Google Play reviews, Oct 2019 – Jul 2023)

---

## Ship Order Recommendation

**Start with F1 → F2 → F3 → F4, then F5 → F6 → F7.**

**Rationale:** F1, F2, F3 are P0 (highest impact-per-effort); they solve 60–70% of user friction. F1 (empty-result hint) is the single biggest driver of negative reviews. F4 surfaces already-shipped features (dark theme, post-"=" editing) — zero build cost, pure discoverability. F5 improves robustness. F6 and F7 are P2 (lower priority, higher complexity).

---

## F1: Empty/Invalid-Result Hint — "Add a Time Unit"

**Feature ID:** F1
**Priority:** P0
**Impact-per-Effort:** High/Low

### Problem Statement

~8–9 of the 14 sub-3★ reviews stem from a single misunderstanding: users type plain arithmetic (e.g., `2+3`, `5-2`) without time units, the app returns an empty result, and they assume it's broken.

**Review quotes:**
- _"+, - not working"_ → dev: _"This is a TIME Calculator… You have to write the unit of time after the number, e.g. '2 hours + 3 minutes'"_
- _"It doesn't add anything"_ → dev: _"This is a TIME calculator… You need to enter 2 minutes + 2 minutes"_
- _"Wow, does not work at all!"_ / _"Garbage"_ / _"Bad"_ — all trace to users expecting a general arithmetic calculator

**Root cause:** When parsing fails (no time unit detected), the app silently returns nothing. New users interpret silence as failure and leave a 0–1★ rage review instead of asking.

### Goal / Success Criteria

**Done when:**
- Typing `2+3` (no unit) shows an inline hint: _"Add a time unit — try `2 hours + 3 minutes`"_
- Hint appears only on empty/invalid input (invisible during normal use)
- Hint clearly explains the concept with a concrete example
- No UI clutter; respects "simplicity is sacred"

**Measurable success:** Vague "not working" / "garbage" reviews should drop by ~50% within 4 weeks of release.

### Functional Requirements

1. Detect when user input produces an empty or invalid parse result (e.g., `2+3`, `hello`, blank input after operators)
2. Generate a one-line inline hint message: _"Add a time unit — try `2 hours + 3 minutes`"_ or similar
3. Display hint below the input field or as a light red/orange background on the result display
4. Dismiss hint automatically when user adds a valid time unit
5. Do NOT show hint if input is simply blank (user is still typing)
6. Do NOT show hint for valid expressions that produce zero as a legitimate result (e.g., `0 hours`)

### UI/UX Spec

- **Trigger:** Input is non-empty AND parsing fails (no time units detected)
- **Location:** Inline below the input field, or as a faint background tint on the result display area
- **Visual style:** Small text (secondary color, e.g. orange or light red); non-intrusive; consistent with app's minimalist design
- **Interaction:** Hint disappears when user edits input; no dismissal button needed
- **Simplicity respect:** This hint is context-sensitive error feedback — it only shows when needed, adds zero permanent UI surface

### Out of Scope

- Do NOT auto-correct or auto-insert units
- Do NOT suggest alternative interpretations (e.g., "Did you mean [suggestion]?")
- Do NOT add unit picker chips or dropdowns on first load (separate discoverability fix; see F2)
- Do NOT change the parser or input validation logic itself

### Acceptance / Test Criteria

- [ ] Type `2+3` → hint appears within 500ms
- [ ] Type `2 hours + 3` → no hint (valid partial expression)
- [ ] Type `2 hours + 3 minutes` → no hint (valid full expression)
- [ ] Type `hello` → hint appears
- [ ] Clear input field → no hint (blank state is not an error)
- [ ] Hint text is readable and accurately suggests a format
- [ ] Dismissing by editing input removes hint immediately
- [ ] Hint does NOT appear for valid results that are numerically zero (e.g., `0 minutes`)

### Dependencies / Risks

- **Low risk:** Hint is conditional and non-intrusive; no changes to calculation logic
- **Dependency:** Requires access to parser's error state (must distinguish "empty result" from "valid zero")
- **Testing:** Needs exhaustive input matrix (blank, operators alone, numbers alone, mixed valid/invalid units)

---

## F2: Make Result-Format Toggle Discoverable

**Feature ID:** F2
**Priority:** P0
**Impact-per-Effort:** High/Medium

### Problem Statement

The result-format toggle button (↔ — "two arrows") is the app's main declared feature but is not obviously interactive. Users cannot find it and think the app is non-functional or too restrictive.

**Review quotes:**
- _"Not bad once you work it out. Still there are easier, more intuitive apps out there."_
- _"Well, this is crap... it's completely unclear to operate and non-functional"_

**Developer reply (from play-store feedback):**
> _"To change the result format, press a two arrows button in the top left above the numbers keyboard."_

**Root cause:** The button lacks affordance (visual cue that it's interactive). Users see an icon but do not realize it's a button.

### Goal / Success Criteria

**Done when:**
- The toggle button is visually obvious as interactive (e.g., highlights on hover, has a slight 3D depth, glows subtly, or is labeled with "Format")
- First-time users recognize it as a control within the first 30 seconds of opening the app
- Button tooltip appears on long-press or first hover
- Tutorial overlay highlights the button and explains its function

**Measurable success:** User confusion about result formats should drop; support replies about "how to change format" should decline.

### Functional Requirements

1. Add a visual affordance to the toggle button (glow, shadow, highlight on first load, or slight animation)
2. Add a tooltip/hint that appears on long-press or hover: _"Tap to change result format"_
3. Optionally add a text label below or beside the arrows icon (e.g., "Format")
4. Highlight the button in the F3 tutorial overlay (first-launch onboarding)
5. Ensure the affordance is consistent with the app's minimalist design (no over-animation)

### UI/UX Spec

- **Location:** Top-left area (above number pad), same position as current implementation
- **Visual treatment:** Choose ONE (not all):
  - Option A: Subtle glow or shadow on the button (4–6px shadow, low opacity)
  - Option B: Slightly larger size than other buttons, or rounded corners to distinguish it
  - Option C: Light background box around the button (respects simplicity better than animations)
  - Option D: Text label "Format" in small text below the icon
- **Tooltip:** "Tap to change result format (decimal, hours:minutes, etc.)" — appears on 800ms long-press or on first app launch with a dismiss-able pointer
- **Simplicity respect:** Affordance is VISUAL feedback only, not new functionality. The button already works; users just need to know it exists and is interactive.

### Out of Scope

- Do NOT change the button's function or add new format options
- Do NOT add format presets or suggestions (separate feature, if needed)
- Do NOT add animation loops or distraction (one-time highlight is OK)

### Acceptance / Test Criteria

- [ ] Button is visually distinguishable from non-interactive elements
- [ ] Tooltip appears and is readable
- [ ] Tooltip is dismissible (tap elsewhere or auto-hide after 3 sec)
- [ ] Tutorial overlay (F3) explicitly highlights this button
- [ ] Button still functions identically (toggle between formats works)
- [ ] Affordance works on small screens (e.g., 4-5 inch phones)
- [ ] High-contrast mode (accessibility) still shows the affordance

### Dependencies / Risks

- **Low risk:** Pure UI polish; no backend or logic changes
- **Dependency:** Requires F3 (tutorial) to be mostly complete so the overlay can highlight this button
- **Testing:** Visual regression testing on multiple screen sizes and Android versions

---

## F3: In-App Tutorial / Quick-Start Overlay

**Feature ID:** F3
**Priority:** P0
**Impact-per-Effort:** High/Medium

### Problem Statement

Demo videos and screenshots exist in the Google Play Store, but are not discoverable from within the app. New users, especially non-English speakers, abandon the app within 30 seconds if they do not understand the UI.

**Review quotes:**
- _"Incomprehensible. I just installed it. I'm uninstalling it."_ (French user)
- _"Not bad once you work it out."_

**Root cause:** No in-app guidance. Users are expected to find the Play Store listing or ask in reviews for help.

### Goal / Success Criteria

**Done when:**
- On first launch, a 3-step animated overlay introduces: (1) how to enter a calculation, (2) how to toggle result format, (3) how to copy the result
- Overlay is dismissible in one tap (does not annoy returning users)
- A "Help" button in the app UI allows users to re-play the tutorial any time
- Overlay respects simplicity and does not add permanent UI surface

**Measurable success:** Day-1 abandonment rate should drop; support load should decline.

### Functional Requirements

1. Detect first app launch (track via SharedPreferences / app-level flag)
2. On first launch, show a full-screen modal overlay with 3 steps:
   - **Step 1:** _"Enter a time calculation (e.g., 5 hours + 30 minutes)"_ — with an example on-screen
   - **Step 2:** _"Press the ↔ button (top-left) to change the result format"_ — highlight the toggle button
   - **Step 3:** _"Tap the result to copy it to your clipboard"_ — show result area with a highlight
3. Each step auto-advances or waits for a user tap to proceed
4. At the end, offer a "Done" or "Got it" button to close overlay
5. Add a "Help" or "?" button in the app UI (e.g., top-right menu) that re-plays the tutorial
6. Ensure overlay dismisses with a single tap if user is uninterested (no forced multi-step flow)
7. Store the "seen tutorial" flag so it only plays once per device

### UI/UX Spec

- **Trigger:** First app launch (check SharedPreferences `tutorial_seen = false`)
- **Visual style:** Semi-transparent overlay (black or dark background) with highlights on relevant UI elements (input field, toggle button, result display)
- **Animation:** Subtle fade-in/fade-out between steps; highlight elements with a brief glow or border highlight
- **Text:** Large, clear font; 2-3 sentences per step (not paragraph-length)
- **Dismissal paths:**
  - Tap "Done" / "Got it" button at the end → closes overlay
  - Tap outside the highlighted element (optional quick-dismiss) → completes that step or closes overlay
- **Help button:** Small icon (?) in app UI (not obtrusive); placed in top-right corner or menu; re-plays tutorial on tap
- **Simplicity respect:** Overlay is one-time and dismissible. It does not add permanent UI; "Help" button is small and hidden in a menu if possible.

### Out of Scope

- Do NOT show tutorial on every launch (track state to show only on first launch)
- Do NOT add written documentation or external links (play store description is separate; see marketing)
- Do NOT make tutorial mandatory (user can dismiss at any time)
- Do NOT add advanced features or settings explanations (keep it to the top 3 use cases)

### Acceptance / Test Criteria

- [ ] On fresh install, overlay appears on app start
- [ ] All 3 steps are visible and readable on screen sizes from 4" to 6.5"
- [ ] Overlay is dismissible with a single tap
- [ ] "Help" button is accessible from the main screen
- [ ] Tapping "Help" re-plays the tutorial
- [ ] On second app launch, overlay does NOT appear (flag is persisted)
- [ ] Overlay does NOT break calculation input (calculator still works in background)
- [ ] Tutorial text is accurate and matches current app functionality

### Dependencies / Risks

- **Low risk:** Modal overlay; does not change app logic
- **Design dependency:** Tutorial must highlight the toggle button (F2) — if F2 is redesigned, tutorial assets must update
- **Testing:** Multi-device testing (screen sizes, Android versions); confirmation that tutorial text is not cut off

---

## F4: Surface Already-Shipped Features (Dark Theme + Post-"=" Editing)

**Feature ID:** F4
**Priority:** P0-adjacent (Discoverability Only)
**Impact-per-Effort:** High/Low (Zero Build Cost)

### Problem Statement

Two features are already implemented and shipped in the app, but are not discoverable. Users review them as missing features, not recognizing they are present and just hidden:

1. **Dark theme** — already exists; accessible via system settings on Android 9+ (auto-detect), but toggle may not be visible
2. **Expression editing after "="** — already works; users can edit the expression and recalculate, but the affordance is not obvious

**Review quotes:**
- Dark theme: _"A handy calculator. A dark theme would be nice"_ (#238); _"No dark mode, harsh on the eyes"_ (#279)
- Post-"=" editing: _"When I press the =, and I want to correct the sum, it erases it and I have to write the sum again."_

**Root cause:** Both features exist but lack surfacing or affordance.

### Goal / Success Criteria

**Done when:**
- Dark theme is clearly visible in the tutorial (F3) and/or settings
- Android 9+ devices auto-enable dark theme based on system settings (no user action needed)
- A visible toggle in settings/menu allows users to manually override system preference
- Post-"=" editing is mentioned in the tutorial or has an inline hint (e.g., "Tip: You can edit the expression after tapping =")

**Measurable success:** No more reviews requesting dark theme or complaining about result editing.

### Functional Requirements

#### Dark Theme Discoverability:
1. Implement system-level auto-detect for dark theme on Android 9+ (use `Configuration.UI_MODE_NIGHT_YES`)
2. Add a theme toggle in Settings (or a menu) so users can manually override system preference (Light / Dark / System)
3. Highlight the dark theme toggle in the F3 tutorial (Step 2 or 3)
4. Ensure the toggle persists across app restarts

#### Post-"=" Editing Discoverability:
1. After user taps "=", show a subtle inline hint: _"Tip: Tap the expression to edit it"_ or _"You can edit this calculation"_
2. Or include a tutorial step in F3: _"You can always edit your expression after pressing ="_
3. Ensure the hint disappears after a few seconds (non-obtrusive)

### UI/UX Spec

#### Dark Theme:
- **Setting location:** Settings menu or app drawer (consistent with Android conventions)
- **Options:** Light / Dark / System (default: System)
- **Visual:** Use standard Android Material 3 dark-mode colors
- **Simplicity respect:** One toggle; no color customization or advanced theme options

#### Post-"=" Editing:
- **Hint location:** Below or near the result display, after "=" is tapped
- **Text:** _"Tip: Tap the expression to edit"_ (2–4 words; small, secondary text)
- **Behavior:** Hint auto-dismisses after 3–5 seconds or when user taps elsewhere
- **Simplicity respect:** Non-obtrusive hint; disappears automatically

### Out of Scope

- Do NOT add new color themes or customization (System/Light/Dark only)
- Do NOT change the dark-mode implementation itself (system auto-detect already works)
- Do NOT add tutorial steps beyond mentioning these features in F3
- Do NOT build additional expression editing features (it already works)

### Acceptance / Test Criteria

**Dark Theme:**
- [ ] Android 9+ device with dark system theme enabled → app auto-starts in dark mode
- [ ] Android 9+ device with light system theme enabled → app auto-starts in light mode
- [ ] Settings toggle to override system preference works
- [ ] App returns to system theme preference when override is cleared
- [ ] Dark mode renders all UI elements (buttons, text, icons) with sufficient contrast (WCAG AA)
- [ ] Tutorial (F3) mentions dark theme and shows how to find the toggle

**Post-"=" Editing:**
- [ ] After tapping "=", hint appears (optional; only if adding an affordance)
- [ ] User can tap the expression area after "=" and edit it
- [ ] Calculation updates correctly when user re-edits
- [ ] Tutorial (F3) optionally mentions this capability

### Dependencies / Risks

- **Very low risk:** Dark theme is system-built; post-"=" editing already works. This is pure surfacing.
- **No new dependencies:** System auto-detect requires Android 9+; no external libraries needed
- **Testing:** Device testing on Android 8 (verify fallback), Android 9+, and various device themes

---

## F5: Error Handling & In-App "Report an Issue"

**Feature ID:** F5
**Priority:** P1
**Impact-per-Effort:** Low/Low

### Problem Statement

~5 vague reviews report "not working" or "garbage" with no detail. App should catch common input errors and provide helpful guidance, plus offer users a way to report genuine bugs.

**Review quotes:**
- _"Not working correctly"_
- _"Wow, does not work at all!"_
- _"It doesn't add anything"_

**Root cause:** Many of these are likely user error (missing units, misunderstanding features), but some may be genuine bugs hidden in vague feedback. The app has no feedback mechanism.

### Goal / Success Criteria

**Done when:**
- Common input errors show helpful error messages (e.g., "Please include a time unit")
- App offers a "Report an Issue" button accessible from the main UI
- Tapping "Report an Issue" opens an email compose or in-app form pre-populated with app version, Android version, and last calculation for debugging
- Error messages are friendly and suggest next steps

**Measurable success:** Vague "not working" complaints should decline; real bug reports should become actionable (include version, device, reproduction steps).

### Functional Requirements

1. Catch and display error messages for:
   - Missing time units: _"Please include a unit (e.g., '5 hours' not just '5')"_
   - Invalid syntax: _"Invalid format. Try '5 hours 30 minutes' or '5h 30m'"_
   - Unsupported characters: _"Unsupported character. Use numbers, units, and operators (+, -, *)."_
2. Add a "Report an Issue" button in the app menu (e.g., Settings or Help menu)
3. Tapping "Report an Issue" opens an email compose or in-app form with:
   - Subject: "Cardamon Time Calculator — Issue Report"
   - Pre-filled fields: App version, Android version, Device model, Last calculation (if available)
   - Open text field for user to describe the problem
4. Ensure error messages are friendly and non-judgmental (avoid "ERROR" in red; use warm tone)
5. Do NOT change parser logic; only add user-facing error messages

### UI/UX Spec

**Error Messages:**
- **Location:** Inline below input, or in a light toast/snackbar (non-modal)
- **Color:** Warm orange or amber (not aggressive red)
- **Text:** 1–2 sentences; specific and actionable
- **Example:** _"No time unit found. Try adding hours, minutes, or seconds (e.g., '5 hours + 30 minutes')"_

**"Report an Issue" Button:**
- **Location:** Settings menu or "?" (Help) menu
- **Behavior:** Tap → opens email compose (or in-app form) with pre-filled fields
- **Email recipient:** Support email (configured by developer; e.g., team@cardamon.app or feedback form)

**Form/Email Fields:**
- App Version: auto-filled (e.g., "1.5")
- Android Version: auto-filled (e.g., "Android 14")
- Device: auto-filled (e.g., "Samsung Galaxy S23")
- Last Calculation: auto-filled (if available; e.g., "5 hours + 30 minutes = 5h 30m")
- Description: open text field (user types their issue)

### Out of Scope

- Do NOT add automatic crash reporting (no telemetry without explicit user opt-in)
- Do NOT log detailed user data or analytics
- Do NOT build an in-app ticket system or support dashboard (email is sufficient)
- Do NOT change error messages for internal developer-facing errors (only user-facing messages)

### Acceptance / Test Criteria

- [ ] Typing `5` (no unit) shows an error message within 500ms
- [ ] Typing `@@@` shows a format error message
- [ ] Error message is readable and suggests a solution
- [ ] "Report an Issue" button is accessible from the menu
- [ ] Tapping "Report an Issue" opens email compose or form with all pre-filled fields
- [ ] Pre-filled fields are accurate (version, device, last calculation)
- [ ] User can edit and add to the form before sending
- [ ] Form submission (email send) works on devices with and without Gmail configured

### Dependencies / Risks

- **Low risk:** Error handling is additive; does not change core logic
- **Email dependency:** Requires a valid support email (configure in app settings/constants)
- **Testing:** Multi-device testing; confirm error handling on edge cases (very long input, special characters, etc.)

---

## F6: History / Calculation Log

**Feature ID:** F6
**Priority:** P2
**Impact-per-Effort:** Medium/High (Deferred)

### Problem Statement

2 users request the ability to view previous calculations without retyping. This is useful for power users but risks adding complexity to the app.

**Review quotes:**
- _"I should've given this a 5 but the only thing lacking is that, there's no way to view your previous conversion... you have no choice but to retype it from scratch."_
- _"Super, convenient app. Please add history feature!"_

**Root cause:** No persistent storage of calculation history.

### Goal / Success Criteria

**Done when:**
- History is stored locally (SharedPreferences or SQLite; no cloud sync)
- History is gated behind a Settings toggle (opt-in; off by default)
- Only 5–10 most recent calculations are shown (not 100+)
- Tapping a history item copies it to the input field and recalculates
- Clearing history removes all entries

**Measurable success:** Users with history enabled should report higher satisfaction; check in 6+ months if demand increases beyond 5 mentions.

### Functional Requirements

1. Store last 5–10 calculations in local SharedPreferences or lightweight SQLite database
2. Add a collapsible "History" section at the bottom of the input area (below the number pad)
3. Add a Settings toggle to enable/disable history (default: disabled)
4. Each history item shows: calculation + result (e.g., "5 hours + 30 minutes = 5h 30m")
5. Tapping a history item: copies the expression to the input field, auto-calculates, and displays the result
6. Add a "Clear history" button in Settings
7. Do NOT add export, sync, or analytics

### UI/UX Spec

- **Location:** Collapsible section below the number pad (or in a drawer/menu if space is tight)
- **Default state:** Hidden (unless enabled in Settings)
- **History list:** Vertical list of 5–10 items; each item is a row (calculation + result)
- **Interaction:** Tap item → input field updates + auto-calculate
- **Simplicity respect:** History is behind a toggle; power users opt-in; casual users never see it

### Out of Scope

- Do NOT add search or filter in history
- Do NOT add tags or categories for calculations
- Do NOT add cloud sync or backup
- Do NOT add export (CSV, JSON, etc.)
- Do NOT track timestamps or metadata (just store the calculation)

### Acceptance / Test Criteria

- [ ] History toggle appears in Settings
- [ ] Toggling history off hides the history section
- [ ] After enabling history, first calculation is stored
- [ ] Up to 10 calculations are stored; oldest ones are removed when 11th is added
- [ ] Tapping a history item populates the input field and recalculates
- [ ] "Clear history" button removes all entries
- [ ] App does not crash if history is corrupt or empty
- [ ] Storage size remains <1 MB even with 10,000 calculations (unlikely but should be safe)

### Dependencies / Risks

- **Moderate risk:** Adds persistent storage and local database logic; increases app size and memory footprint
- **Storage dependency:** Requires SharedPreferences or SQLite; confirm no data loss on app updates
- **Testing:** Test with large histories (1000+ items); ensure performance is not degraded

---

## F7: Language Localization

**Feature ID:** F7
**Priority:** P2
**Impact-per-Effort:** Low/Medium

### Problem Statement

2 users request UI localization to Russian and French. The app has minimal UI text, so localization is straightforward but lower priority.

**Review quotes:**
- _"The application is in English and cannot be switched to French!"_
- _"Everything is very convenient, but how do I make it Russian?"_

**Developer commitment:** Russian localization is in the backlog.

### Goal / Success Criteria

**Done when:**
- App UI is available in Russian (committed by developer)
- Spanish, French, German translations are added (in priority order)
- A language selector in Settings allows users to choose their language
- All UI strings are externalized to localization files (strings.xml per locale)

**Measurable success:** Russian-speaking users should see Russian UI; new locales may unlock growth in those markets.

### Functional Requirements

1. Extract all UI strings from code into strings.xml (Android standard i18n)
2. Create localized strings files: strings-ru.xml, strings-es.xml, strings-fr.xml, strings-de.xml
3. Translate all UI strings (use professional translator for accuracy):
   - Button labels (e.g., "=", "Clear", "Help")
   - Menu items (e.g., "Settings", "History", "Report an Issue")
   - Hints and tooltips (e.g., "Add a time unit…", "Tap to change format")
   - Error messages
4. Add a "Language" setting in Settings (spinner/dropdown with options: English, Русский (Russian), Español (Spanish), Français (French), Deutsch (German))
5. Persist language selection in SharedPreferences
6. Load localized strings at app start based on user preference or system locale
7. App restart or locale change should immediately switch language

### UI/UX Spec

- **Setting location:** Settings menu
- **Language selector:** Dropdown / spinner list with language names in their native scripts
- **Default behavior:** Respect system locale on first install (e.g., Russian device → Russian UI by default)
- **Fallback:** If system locale is not available, fall back to English
- **Simplicity respect:** One language setting; no regional variants (just RU, not RU-BY, etc.)

### Out of Scope

- Do NOT translate app store description or marketing materials (that's marketing's task; see README)
- Do NOT add right-to-left (RTL) language support (no Arabic, Hebrew, etc.)
- Do NOT localize number formats or time units (e.g., 12-hour vs. 24-hour; units remain standardized)
- Do NOT add in-app language switcher (Settings menu is sufficient)

### Acceptance / Test Criteria

- [ ] Russian strings are complete and accurate
- [ ] Spanish, French, German strings are complete and translated professionally
- [ ] Language selector appears in Settings
- [ ] Changing language immediately reflects all UI text
- [ ] System locale on first install correctly sets the default language
- [ ] English fallback works if system locale is unsupported
- [ ] Text does not overflow or truncate in any locale (test with long German/French strings)
- [ ] Special characters (accents, Cyrillic) render correctly on all Android versions

### Dependencies / Risks

- **Medium risk:** Requires professional translation (can be expensive; outsource or use community volunteers)
- **Maintenance dependency:** Every new UI string must be added to all localization files
- **Testing:** Language-specific testing (e.g., Cyrillic rendering, RTL considerations if adding them later)
- **App size:** Localization files add ~5–10 KB per language; negligible but worth noting

---

## Summary

| Feature | ID | Priority | Ship Order | Scope | Effort |
|---------|----|-----------|-----------| ------|--------|
| Empty/invalid-result hint | F1 | P0 | 1st | Error UX feedback | Small |
| Make format toggle discoverable | F2 | P0 | 2nd | Visual affordance | Small–Medium |
| In-app tutorial overlay | F3 | P0 | 3rd | Onboarding modal | Medium |
| Surface dark theme & post-"=" editing | F4 | P0-adj | 4th | Discoverability only (zero build) | Low |
| Error handling & "Report Issue" | F5 | P1 | 5th | Error messages + feedback | Small |
| History / calculation log | F6 | P2 | 6th | Persistent storage (opt-in) | Medium–High |
| Language localization | F7 | P2 | 7th | i18n infrastructure + translations | Medium |

**Total sections:** 7 features (one per section above)

---

## Key Constraints

1. **Simplicity is sacred** — every feature must be justified; UI surface is minimized
2. **No new data harvesting** — local storage only; no analytics or telemetry (unless explicitly opt-in)
3. **No ads or freemium model** — users value simplicity and ad-free experience
4. **Each feature is self-contained** — can be picked up, built, tested, shipped independently

---

**Document version:** 1.1
**Last updated:** 2026-06-20
**Status:** Ready for implementation (ship in order: F1 → F2 → F3 → F4 → F5 → F6 → F7)

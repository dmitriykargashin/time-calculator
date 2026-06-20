# Requirements — Privacy Policy page for Time Calculator Cardamon

Purpose: publish a privacy policy page for the **Time Calculator Cardamon**
Android app that satisfies Google Play's User Data policy and matches the
existing Cardamon house style (the Relay Autobooker policy). The page must be
**consistent with the app's Play Console Data safety section** — Google checks
that the two agree.

---

## 1. Page location & metadata

| Field | Value |
|---|---|
| **URL (must be live)** | `https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator` |
| **Page / document title** | `Privacy Policy for Time Calculator Cardamon` |
| **Entity (legal)** | Cardamon Inc |
| **Contact email** | support@cardamon.org |
| **Sibling page to match for layout** | `https://www.cardamon.org/products/relay-autobooker/privacy-policy-booker` |

## 2. Format / house-style requirements (mirror the Relay Autobooker page)

- Same page template, fonts, and layout as the Relay Autobooker policy.
- Title format: **"Privacy Policy for Time Calculator Cardamon"**.
- Opening line, verbatim with the house style: **"Your privacy is critically important to us."**
- Conversational-yet-formal tone; bullet points for data categories.
- Use the **same section headings, in the same order** as the existing policy:
  1. Personal Information We Collect
  2. How We Use Your Information
  3. Sharing Your Information
  4. Data Retention
  5. Your Rights
  6. Changes
  7. Contact Us
- (Relay Autobooker has no "last updated" date — omit it here too for
  consistency, unless the site adds dates globally.)

## 3. Google Play compliance requirements (hard rules)

- Hosted on an **active, publicly accessible, non-geofenced** URL. ✅ (own domain)
- **Not** a PDF, **not** behind a login, **non-editable** (a normal web page, not
  a shareable Google Doc).
- Clearly labelled as a privacy policy (the title above satisfies this).
- Discloses: developer identity + contact, the data collected/used/shared and the
  parties, security practices, and retention/deletion.
- **Must be consistent with the Data safety section** (see §5).
- The same URL is also set in the app (`kPrivacyPolicyUrl` in `lib/config.dart`)
  and shown on the in-app consent dialog / Settings, satisfying Google's
  "privacy policy reachable from inside the app" rule.

## 4. Content to publish (ready to paste under each heading)

> Your privacy is critically important to us. Time Calculator Cardamon (the
> "App") is a free, ad-free time calculator published by Cardamon Inc. This
> policy explains what the App collects and how it is handled.

**1. Personal Information We Collect**

The App does **not** require an account and does **not** collect personal
information such as your name, email address, contacts, photos, files, messages,
or precise/GPS location. The only data collected is **anonymous usage analytics**,
via **Google Analytics for Firebase**:

- **App activity (app interactions)** — which features and screens are used (for
  example, opening the formats or support screens, or tapping calculator keys).
- **Device identifier** — an app-instance ID that Firebase assigns to your
  installation of the App, and your device's **Advertising ID**, used to measure
  our Google Ads campaigns and build advertising audiences. (The App itself
  displays no ads.)
- **Approximate location** — coarse, city-level location derived from your
  device's IP address (never precise/GPS location).

The App also offers optional "buy me a cup of tea" donations through Google
Play's billing system. Payments are processed by Google; we do not receive or
store your payment details.

**2. How We Use Your Information**

The data is used to understand how the App is used and to improve it
(**analytics**), and to measure and optimise our Google Ads campaigns and build
advertising audiences (**advertising / marketing**). The App itself displays no
ads. In the EEA, the UK and Switzerland, this data is collected **only after you
give consent** (requested when you first open the App). You can change this at any
time in **Settings → Privacy**.

**3. Sharing Your Information**

We do **not** sell your data. Google Analytics for Firebase processes the
analytics data on our behalf as a service provider. For advertising measurement,
your Advertising ID and related data are **shared with Google** (Google Ads) to
measure campaign performance and build audiences. Google's handling is governed
by the Google Privacy Policy (https://policies.google.com/privacy).

**4. Data Retention**

Analytics data is retained by Google for the period configured in our analytics
account and is then deleted. Data is encrypted in transit using TLS.

**5. Your Rights**

Depending on where you live, you may have the right to access, correct, or delete
your data, or to withdraw consent. To withdraw analytics consent at any time, use
**Settings → Privacy** in the App. For any other request, contact
support@cardamon.org.

**6. Changes**

We may update this policy from time to time. Any changes will be posted on this
page.

**7. Contact Us**

If you have any questions about this policy, contact us at support@cardamon.org.

## 5. Consistency check vs. the Play Data safety section (must match)

The page above is written to agree with the Data safety answers. Keep them in
sync — if one changes, change both:

| Data safety declaration | Reflected in the policy |
|---|---|
| Data types: **App interactions**, **Device or other IDs (incl. Advertising ID)**, **Approximate location** | §1 lists these |
| Purposes: **Analytics + Advertising/marketing** | §2 analytics + Google Ads measurement/audiences |
| **Shared = Yes** (Advertising ID + ad-conversion data → Google/Google Ads) | §3 "shared with Google (Google Ads)" |
| **Optional** (consent + opt-out) | §2/§5 consent + Settings → Privacy |
| **Encrypted in transit** | §4 "encrypted in transit using TLS" |
| **Advertising ID** declaration = **Yes**, purpose **Advertising/marketing** | §1 Advertising ID bullet |

## 6. If anything changes later

- The **Advertising ID is ENABLED** (Google Ads measurement/audiences). If you
  ever drop Google Ads, disable it again (manifest
  `google_analytics_adid_collection_enabled=false`) and revert §1/§2/§3 +
  the Data safety + Advertising-ID declarations to analytics-only.
- If **Crashlytics / Performance Monitoring** is ever added: add an "App info
  and performance" disclosure in §1 and the Data safety section.

## 7. After publishing

1. Confirm the URL loads publicly (incognito, no login).
2. Paste it into **Play Console → App content → Privacy policy**.
3. Tell the app maintainer the final URL so `kPrivacyPolicyUrl` in
   `lib/config.dart` is set to it (the consent dialog then links to it).

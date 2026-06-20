import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/analytics_service.dart';
import 'services/monetization.dart';
import 'services/rate_service.dart';
import 'state/settings_model.dart';
import 'ui/calculator_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets/consent_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge: draw behind the system bars (the Android 15+ default for
  // targetSdk 35+). The app already handles the insets via SafeArea, and the
  // bars are kept transparent (see _Home) instead of colored - the deprecated
  // bar-color setters are no-ops under edge-to-edge. Applied on every platform
  // (no-op off Android); on Android <15 it makes the look consistent.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Firebase Analytics: best-effort. initializeApp() succeeds ONLY when a real
  // google-services.json was bundled at build time; otherwise it throws here
  // (no default options) and analytics stays disabled - the app runs normally
  // (the .dev build, web, CI, tests). Never blocks startup.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // No Firebase config bundled - analytics stays off for this build.
  }
  // Loads the persisted consent choice and applies Consent Mode before the
  // first frame; best-effort (never blocks startup). The consent DIALOG (for
  // EEA/UK/CH users who haven't chosen) is shown after first frame in _Home.
  try {
    await AnalyticsService.instance.init();
  } catch (_) {
    // Analytics stays off for this session.
  }
  // The persisted theme choice loads BEFORE runApp so the first frame
  // already renders in the chosen theme (no light->dark flash).
  try {
    await SettingsModel.instance.load();
  } catch (_) {
    // Theme preference is best-effort; fall back to follow-system.
  }
  // Guarded: monetization / rate bookkeeping failures must never block
  // startup. init() awaits only the local entitlement read; the Play Billing
  // store sync continues in the background after the first frame.
  try {
    await Monetization.instance.init();
  } catch (_) {
    // Support purchases stay unavailable for this session.
  }
  try {
    await RateService.instance.registerLaunch();
  } catch (_) {
    // Rate-prompt counters are best-effort.
  }
  runApp(const TimeCalculatorApp());
}

/// Root widget: "Time Calculator Cardamon". Light/dark themes from the
/// RemoveADS palette; themeMode follows the persisted Settings choice
/// (System default / Light / Dark) and switches instantly.
class TimeCalculatorApp extends StatelessWidget {
  const TimeCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds on BOTH the theme choice AND Monetization changes: the latter
    // so unlocking Pro instantly applies the stored dark theme (effective
    // theme mode is clamped to light while Pro-gated-and-not-unlocked).
    return ListenableBuilder(
      listenable: Listenable.merge(
        [SettingsModel.instance, Monetization.instance],
      ),
      builder: (context, _) => MaterialApp(
        title: 'Time Calculator Cardamon',
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: SettingsModel.instance.effectiveThemeMode,
        debugShowCheckedModeBanner: false,
        home: const _Home(),
      ),
    );
  }
}

/// Hosts the calculator under the per-theme system chrome and fires the
/// automatic rating prompt once per cold start, after the first frame
/// (the Android branch: `savedInstanceState == null` ->
/// `showIfMeetsConditions()`).
class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterFirstFrame());
    // checkPurchases() parity: the Android branch re-queried purchases on
    // every onResume. refresh() no-ops on inert platforms and coalesces
    // concurrent calls, so it is safe to call unconditionally.
    _lifecycleListener = AppLifecycleListener(
      onResume: () => Monetization.instance.refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  /// After the first frame: ask for analytics consent FIRST (EEA/UK/CH users
  /// who haven't chosen), then run the automatic rating prompt. Consent goes
  /// first so a supporter isn't hit with two dialogs at once / out of order.
  Future<void> _afterFirstFrame() async {
    await _maybeShowConsent();
    await _maybeAutoRate();
  }

  Future<void> _maybeShowConsent() async {
    try {
      if (!AnalyticsService.instance.needsConsentPrompt) return;
      if (!mounted) return;
      await showAnalyticsConsentDialog(context);
    } catch (_) {
      // Consent-dialog failures must never block the app.
    }
  }

  Future<void> _maybeAutoRate() async {
    try {
      if (await RateService.instance.shouldAutoShow()) {
        if (!mounted) return;
        await RateService.instance.showRatingFlow(context);
      }
    } catch (_) {
      // Never surface rate-prompt failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Edge-to-edge: TRANSPARENT system bars - the app draws behind them and the
    // insets are handled by SafeArea. We set ONLY the icon brightness (dark
    // icons on the light theme, light icons on the dark theme). Bar colors are
    // left transparent on purpose: setting an opaque bar color is deprecated and
    // ignored under edge-to-edge on Android 15+.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: const CalculatorScreen(),
    );
  }
}

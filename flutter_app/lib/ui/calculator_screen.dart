import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/result_format.dart';
import '../engine/tokens.dart';
import '../services/analytics_service.dart';
import '../services/monetization.dart';
import '../services/share_service.dart';
import '../state/calculator_model.dart';
import '../state/settings_model.dart';
import 'clipboard_feedback.dart';
import 'formats_screen.dart';
import 'history_screen.dart';
import 'per_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'spans.dart';
import 'support_screen.dart';
import 'theme.dart';
import 'widgets/circular_reveal.dart';
import 'widgets/keypad.dart';

/// Outer screen padding around the two cards (proto: 16/8/16/16). Kept local
/// (screen glue): the L/R/bottom margins and the smaller top margin under the
/// status bar. The bottom value is used by the clear-flash geometry to find
/// the keypad card's top edge.
const double _kScreenPadH = 16;
const double _kScreenPadTop = 8;
// Small margin between the keypad card and the PHYSICAL bottom edge. With
// SafeArea(bottom: false) the card now extends past the system gesture-nav
// inset, so this is the only bottom gap left (matched to _kScreenPadTop).
const double _kScreenPadBottom = 8;

/// Vertical extent the DRAGGABLE DIVIDER occupies between the two cards in
/// portrait (its full-width hit area). Set >=24dp so the slim grabber pill is
/// easy to grab; it sits in place of the card gap (a hair taller than cardGap's
/// 16dp so the touch zone clears the 24dp floor while keeping the cards close).
const double _kHandleHeight = 24;

/// Landscape/tablet (sevenColumn) display-fraction clamp. The same draggable
/// handle + persisted [SettingsModel.displayFraction] split is used there, but
/// the short landscape height needs a TIGHTER, more keypad-favored range than
/// portrait so the 7-column grid keeps its four rows tappable and never
/// overflows: the display may grow to at most [_kWideMaxDisplayFraction] of the
/// slack (the keypad keeps the rest), and may shrink to at least
/// [_kWideMinDisplayFraction] so the display never collapses behind the format
/// chip. The max was widened (0.45 -> 0.52) so the landscape handle also has
/// real drag travel; the per-viewport [_kMinKeyHeight] floor still tightens it
/// on a short landscape PHONE so the four rows stay tappable and never overflow.
/// These remain tighter than the portrait
/// [SettingsModel.minDisplayFraction]..maxDisplayFraction; the SAME persisted
/// fraction is re-clamped sensibly per layout.
// A looser fraction floor (the ABSOLUTE px floor below now guarantees the
// controls fit, regardless of device), so tall landscape devices keep real
// drag travel.
const double _kWideMinDisplayFraction = 0.25;

/// ABSOLUTE minimum height (logical px) of the wide/landscape display card: it
/// must always fit the LEFT control column (action icons ~48 + 8 gap + the
/// format dropdown ~48 = ~104, plus the card's top/bottom padding). A
/// screen-relative fraction floor alone let the dropdown overflow on short
/// landscape phones; this device-independent floor fixes that.
const double _kWideMinDisplayHeight = 150;
// Raised so the LANDSCAPE keypad can be dragged smaller (more display, smaller
// keys - the keys' glyphs scale down proportionally).
const double _kWideMaxDisplayFraction = 0.66;

/// Tap-target FLOOR for a single keypad key cell, applied in EVERY layout and
/// at EVERY drag size. The draggable split is capped so dragging can never
/// shrink a key below this. RELAXED from the old 44dp hard floor to ~30dp: the
/// 44dp floor pinned the portrait display-fraction ceiling almost exactly at
/// the default split, so dragging the divider barely resized the keys. A ~30dp
/// floor (still a comfortably tappable cell whose FittedBox label stays
/// legible) lets the display grow MUCH more - so the handle has real travel and
/// dragging UP/DOWN noticeably changes key size again - while the keys never
/// become unusably tiny and nothing overflows or scrolls. The display
/// fraction's per-layout MAX is derived from it so the keypad card always keeps
/// enough height for its rows to clear the floor (see
/// [_CalculatorScreenState._splitLayout]).
const double _kMinKeyHeight = 24;

/// Row counts of the two keypad grids (no utility row now - the single
/// Backspace delete key lives in the grid's bottom-right slot): portrait is the
/// 6-row 4-column grid, landscape/tablet the 4-row 6-column grid. Used to
/// convert the per-key [_kMinKeyHeight] floor into a minimum keypad-card height.
const int _kPortraitKeypadRows = 6;
const int _kWideKeypadRows = 4;

/// The single screen of the app - Material 3 Expressive redesign. A slim TOP
/// BAR (Per / Support-tea / Settings as right-aligned filled-tonal icon
/// buttons) sits above two large rounded tonal surfaces: a HERO DISPLAY card
/// (expression on top, the green format chip in the MIDDLE as a divider-like
/// selector, big bold live result hero anchored at the bottom) and a KEYPAD
/// card below (the soft tonal key grid with the single Backspace delete key in
/// its bottom-right slot - 4 cols portrait / 6 cols land+sw600). The format chip (a
/// green M3 assist-style tonal chip) opens the Formats overlay; the four
/// circular-reveal overlays launch from their buttons' centers (the secondary
/// three from the top bar). The old six-stripe fake drop shadow is retired -
/// the card gap replaces it.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

/// One circular-reveal overlay: 600ms open from the launching button's
/// center, 450ms close collapsing to (10,10) (or the screen center when the
/// model closed it without a button press, e.g. selecting a format).
class _RevealOverlay {
  _RevealOverlay({required TickerProvider vsync, required bool visible})
      : controller = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 600),
          reverseDuration: const Duration(milliseconds: 450),
          value: visible ? 1 : 0,
        ) {
    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
  }

  final AnimationController controller;
  late final CurvedAnimation animation;

  /// Center the current open/close animation plays around.
  Offset? revealCenter;

  /// Close center staged by the close request (consumed on reverse start).
  Offset? closeCenter;

  void dispose() {
    animation.dispose();
    controller.dispose();
  }
}

/// Resolved heights for the draggable display/keypad split over one content
/// area. Produced by [_CalculatorScreenState._splitLayout]; the screen sizes
/// the two cards from it and the clear-flash geometry reads
/// [keypadCardHeight].
class _SplitLayout {
  const _SplitLayout({
    required this.displayHeight,
    required this.keypadCardHeight,
    required this.hasHandle,
    required this.minFraction,
    required this.maxFraction,
  });

  /// Outer height of the HERO DISPLAY card.
  final double displayHeight;

  /// Outer height of the KEYPAD card (paddings + the key grid, whose
  /// bottom-right slot is the single Backspace delete key).
  final double keypadCardHeight;

  /// Whether the draggable handle is shown (both layouts now: always true).
  final bool hasHandle;

  /// The EFFECTIVE drag clamp for this layout/viewport: the layout's own
  /// min..max tightened by the tap-target height ceiling (so a drag can never
  /// shrink a key below the per-layout [_kMinKeyHeight] floor, ~30dp portrait).
  /// The drag handler clamps to these so the live drag stops exactly where the
  /// height-derived split does.
  final double minFraction;
  final double maxFraction;
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with TickerProviderStateMixin {
  final CalculatorModel _model = CalculatorModel.instance;

  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _formatsButtonKey = GlobalKey();
  final GlobalKey _perButtonKey = GlobalKey();
  final GlobalKey _foodButtonKey = GlobalKey();
  final GlobalKey _settingsButtonKey = GlobalKey();
  final GlobalKey _historyButtonKey = GlobalKey();
  final GlobalKey _deleteKey = GlobalKey();

  /// Marks the bottom edge of the live-result band inside the hero display
  /// card: the long-press clear flash reveals from this point's y. Captured
  /// in the layout via this key so the flash geometry follows the real card
  /// layout instead of summed estimated heights.
  final GlobalKey _resultBandKey = GlobalKey();

  /// The hero display card's root box. The long-press clear flash is positioned
  /// and clipped to THIS card's rect (with its rounded corners), and the flash
  /// reveal centre is measured relative to it - so the green wipe stays inside
  /// the expression/result card instead of covering the whole background band.
  final GlobalKey _displayCardKey = GlobalKey();

  late final _RevealOverlay _formatsOverlay =
      _RevealOverlay(vsync: this, visible: _model.isFormatsLayoutVisible);
  late final _RevealOverlay _perOverlay =
      _RevealOverlay(vsync: this, visible: _model.isPerLayoutVisible);
  late final _RevealOverlay _supportOverlay =
      _RevealOverlay(vsync: this, visible: _model.isSupportAppLayoutVisible);
  late final _RevealOverlay _settingsOverlay =
      _RevealOverlay(vsync: this, visible: _model.isSettingsLayoutVisible);
  late final _RevealOverlay _historyOverlay =
      _RevealOverlay(vsync: this, visible: _model.isHistoryLayoutVisible);

  // Long-press-delete clear flash: 400ms, colorResultTime (RemoveADS; was
  // holo_blue_dark on master).
  late final AnimationController _flashController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  Offset? _flashCenter;

  /// DRAGGABLE SPLIT: the fraction of the available content height that the
  /// HERO DISPLAY card occupies (the keypad card takes the remainder, minus the
  /// card gap and the drag handle). Seeded from the persisted
  /// [SettingsModel.displayFraction] and updated live while the handle is
  /// dragged; persisted on drag END. Always within
  /// [SettingsModel.minDisplayFraction] .. [SettingsModel.maxDisplayFraction]
  /// so both cards stay usable (the keypad never shrinks below ~30dp keys, the
  /// [_kMinKeyHeight] floor).
  double _displayFraction = SettingsModel.instance.displayFraction;

  /// The hero display card's height for the current layout, captured during
  /// build so the long-press clear flash can be positioned and clipped to the
  /// card's exact rect. The card's top/left/right are the constant screen
  /// paddings ([_kScreenPadTop]/[_kScreenPadH]); only the height varies with the
  /// draggable split, so this is the one geometry value the flash needs.
  double _displayCardHeight = 0;

  @override
  void initState() {
    super.initState();
    _model.addListener(_onModelChanged);
    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _model.clearAll();
        _flashController.value = 0;
      }
    });
    // Pick up a display fraction restored after this screen mounted (load runs
    // before runApp, but subscribing keeps the screen correct regardless of
    // load ordering). The drag handler writes through this notifier too, so the
    // guard avoids a redundant rebuild for our own drag-end writes.
    SettingsModel.instance.displayFractionListenable
        .addListener(_onDisplayFractionChanged);
    // Rebuild the keypad when the Year/Msec swap key choice changes in Settings
    // (SettingsModel notifies on the toggle; theme changes also rebuild the
    // screen via the Theme dependency, so this extra setState is cheap).
    SettingsModel.instance.addListener(_onSettingsChanged);
    // Snackbar parity with the Android branch: billing failures surface as
    // "Purchase is pending. Please wait" anchored over the calculator. The
    // notifier re-fires identical messages via a null-then-value transition.
    Monetization.instance.lastUserMessage.addListener(_onBillingMessage);
  }

  @override
  void dispose() {
    Monetization.instance.lastUserMessage.removeListener(_onBillingMessage);
    SettingsModel.instance.displayFractionListenable
        .removeListener(_onDisplayFractionChanged);
    SettingsModel.instance.removeListener(_onSettingsChanged);
    _model.removeListener(_onModelChanged);
    _formatsOverlay.dispose();
    _perOverlay.dispose();
    _supportOverlay.dispose();
    _settingsOverlay.dispose();
    _historyOverlay.dispose();
    _flashController.dispose();
    super.dispose();
  }

  /// Rebuild when a SettingsModel value the keypad depends on changes (the
  /// Year/Msec swap key). Cheap; the keypad reads the current choice in build.
  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  /// Adopt a display fraction that changed in [SettingsModel] (e.g. restored on
  /// launch). Guarded so our own drag-end write doesn't trigger a no-op rebuild.
  void _onDisplayFractionChanged() {
    final restored = SettingsModel.instance.displayFraction;
    if (restored != _displayFraction && mounted) {
      setState(() => _displayFraction = restored);
    }
  }

  void _onBillingMessage() {
    final message = Monetization.instance.lastUserMessage.value;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onModelChanged() {
    _syncOverlay(visible: _model.isFormatsLayoutVisible, overlay: _formatsOverlay);
    _syncOverlay(
      visible: _model.isPerLayoutVisible,
      overlay: _perOverlay,
      onClose: () {
        // The Per overlay stays mounted (Offstage) after closing, so drop
        // focus here or the soft keyboard would stay up and keep editing the
        // hidden amount/unit field (the original hid the IME on every touch).
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
    _syncOverlay(
      visible: _model.isSupportAppLayoutVisible,
      overlay: _supportOverlay,
    );
    _syncOverlay(
      visible: _model.isSettingsLayoutVisible,
      overlay: _settingsOverlay,
    );
    _syncOverlay(
      visible: _model.isHistoryLayoutVisible,
      overlay: _historyOverlay,
    );
    setState(() {});
  }

  void _syncOverlay({
    required bool visible,
    required _RevealOverlay overlay,
    VoidCallback? onClose,
  }) {
    final status = overlay.controller.status;
    if (visible) {
      if (status != AnimationStatus.forward &&
          status != AnimationStatus.completed) {
        overlay.controller.forward();
      }
    } else {
      if (status != AnimationStatus.reverse &&
          status != AnimationStatus.dismissed) {
        onClose?.call();
        overlay.revealCenter = overlay.closeCenter ?? _stackCenter();
        overlay.closeCenter = null;
        overlay.controller.reverse();
      }
    }
  }

  Offset? _centerOfKey(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    final stackObject = _stackKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        stackObject is! RenderBox ||
        !renderObject.attached) {
      return null;
    }
    return renderObject.localToGlobal(
      renderObject.size.center(Offset.zero),
      ancestor: stackObject,
    );
  }

  Offset _stackCenter() {
    final stackObject = _stackKey.currentContext?.findRenderObject();
    if (stackObject is RenderBox && stackObject.hasSize) {
      return stackObject.size.center(Offset.zero);
    }
    return Offset.zero;
  }

  /// The bottom-RIGHT corner of [key]'s box, in [ancestorKey]'s local
  /// coordinates. Used for the clear-flash reveal origin: the result band's
  /// bottom-right corner, measured relative to the DISPLAY CARD, is a point
  /// INSIDE the flashed card region that coincides with where the right-aligned
  /// result figures actually sit, so the green wipe grows from the result it is
  /// about to erase.
  Offset? _bottomRightOfKey(GlobalKey key, GlobalKey ancestorKey) {
    final renderObject = key.currentContext?.findRenderObject();
    final ancestorObject = ancestorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        ancestorObject is! RenderBox ||
        !renderObject.attached) {
      return null;
    }
    return renderObject.localToGlobal(
      renderObject.size.bottomRight(Offset.zero),
      ancestor: ancestorObject,
    );
  }

  void _openFormats() {
    if (_model.isFormatsViewButtonDisabled) return;
    AnalyticsService.instance.buttonFormats();
    _model.updateResultFormats();
    _formatsOverlay.revealCenter =
        _centerOfKey(_formatsButtonKey) ?? _stackCenter();
    _model.setIsFormatsLayoutVisible(true);
  }

  void _openPer() {
    if (_model.isPerViewButtonDisabled) return;
    AnalyticsService.instance.buttonPer();
    // Pro gate: where gating is on and Pro is not owned, the Per (value/Per
    // calculator) feature is locked - tapping a valid-result icon opens the
    // paywall instead of the overlay. Where gating is off (Android/web/not
    // enabled) hasPro is always true, so this is a no-op there.
    if (!Monetization.instance.hasPro) {
      showProPaywall(context);
      return;
    }
    _model.updatePerUnits();
    _perOverlay.revealCenter = _centerOfKey(_perButtonKey) ?? _stackCenter();
    _model.setIsPerLayoutVisible(true);
  }

  void _openSupport() {
    AnalyticsService.instance.buttonSupport();
    _supportOverlay.revealCenter =
        _centerOfKey(_foodButtonKey) ?? _stackCenter();
    _model.setIsSupportAppLayoutVisible(true);
  }

  void _openSettings() {
    _settingsOverlay.revealCenter =
        _centerOfKey(_settingsButtonKey) ?? _stackCenter();
    _model.setIsSettingsLayoutVisible(true);
  }

  void _openHistory() {
    _historyOverlay.revealCenter =
        _centerOfKey(_historyButtonKey) ?? _stackCenter();
    _model.setIsHistoryLayoutVisible(true);
  }

  void _closeFormats(Offset center) {
    _formatsOverlay.closeCenter = center;
    _model.setIsFormatsLayoutVisible(false);
  }

  void _closePer(Offset center) {
    _perOverlay.closeCenter = center;
    _model.setIsPerLayoutVisible(false);
  }

  void _closeSupport(Offset center) {
    _supportOverlay.closeCenter = center;
    _model.setIsSupportAppLayoutVisible(false);
  }

  void _closeSettings(Offset center) {
    _settingsOverlay.closeCenter = center;
    _model.setIsSettingsLayoutVisible(false);
  }

  void _closeHistory(Offset center) {
    _historyOverlay.closeCenter = center;
    _model.setIsHistoryLayoutVisible(false);
  }

  void _onBackspaceLongPress() {
    if (_model.isExpressionEmpty()) return;
    if (_flashController.isAnimating) return;
    AnalyticsService.instance.buttonLongDelete();
    // Reveal origin: the bottom-RIGHT corner of the live-result band inside the
    // hero display card - a point that lives INSIDE the flashed region (the
    // flash is clipped to the display card) and sits where the right-aligned
    // result figures actually are, so the green wipe grows from the result it
    // erases. Measured relative to the DISPLAY CARD (the flash overlay's own
    // box), so the centre is already in the clip's local coordinates.
    _flashCenter = _bottomRightOfKey(_resultBandKey, _displayCardKey) ??
        Offset.zero;
    _flashController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    final overlayOpen = _model.isFormatsLayoutVisible ||
        _model.isPerLayoutVisible ||
        _model.isSupportAppLayoutVisible ||
        _model.isSettingsLayoutVisible ||
        _model.isHistoryLayoutVisible;
    // Back-press cascade (RemoveADS onBackPressed): close Formats, else Per,
    // else Support, else Settings, else pop normally. The original instead
    // called moveTaskToBack(true) (backgrounding the task, preserving the
    // in-memory expression); accepting the normal pop is the deviation
    // explicitly sanctioned by ui-activity.md's porting notes.
    return PopScope(
      canPop: !overlayOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_model.isFormatsLayoutVisible) {
          _closeFormats(const Offset(10, 10));
        } else if (_model.isPerLayoutVisible) {
          _closePer(const Offset(10, 10));
        } else if (_model.isSupportAppLayoutVisible) {
          _closeSupport(const Offset(10, 10));
        } else if (_model.isSettingsLayoutVisible) {
          _closeSettings(const Offset(10, 10));
        } else if (_model.isHistoryLayoutVisible) {
          _closeHistory(const Offset(10, 10));
        }
      },
      child: Scaffold(
        backgroundColor: palette.mainBackground,
        // bottom: false so the content runs to the PHYSICAL bottom edge instead
        // of stopping above the system gesture-nav inset. That inset (~24dp on a
        // gesture-nav phone) plus the old 16dp bottom screen pad left a dead
        // strip below the keypad card; now the keypad card extends down into it
        // (the keys grow with the taller card), leaving only the small
        // [_kScreenPadBottom] margin from the screen edge. Top/left/right stay
        // safe (status bar + any side cutout in landscape).
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Tablets (sw600) use the 7-column layout in BOTH
              // orientations; phones only in landscape.
              final sevenColumn = dim.bucket != DimensBucket.base;
              // The content area below the screen padding: the two cards, the
              // card gap and the drag handle share this height. The display
              // card takes [_displayFraction] of the slack and the keypad card
              // the rest (the draggable split); see _mainContent for the math.
              // (The old separate top bar is gone - its tools are now bare
              // icons inside the display card.)
              final contentHeight = constraints.maxHeight -
                  _kScreenPadTop -
                  _kScreenPadBottom;
              final layout = _splitLayout(
                dim,
                sevenColumn,
                contentHeight,
              );
              // The clear flash is positioned and clipped to the display card's
              // exact rect; capture its height here (top/left/right are the
              // constant screen paddings).
              _displayCardHeight = layout.displayHeight;
              return Stack(
                key: _stackKey,
                children: [
                  Positioned.fill(
                    child: _mainContent(
                      dim,
                      palette,
                      sevenColumn,
                      layout,
                    ),
                  ),
                  _clearFlash(palette, dim),
                  _overlay(
                    overlay: _formatsOverlay,
                    visible: _model.isFormatsLayoutVisible,
                    child: FormatsScreen(
                      model: _model,
                      onClose: () => _closeFormats(const Offset(10, 10)),
                      // Drives auto-scroll-to-selection: each false->true
                      // transition re-centres the selected format on open.
                      visible: _model.isFormatsLayoutVisible,
                    ),
                  ),
                  _overlay(
                    overlay: _perOverlay,
                    visible: _model.isPerLayoutVisible,
                    child: PerScreen(
                      model: _model,
                      onClose: () => _closePer(const Offset(10, 10)),
                    ),
                  ),
                  _overlay(
                    overlay: _supportOverlay,
                    visible: _model.isSupportAppLayoutVisible,
                    child: SupportScreen(
                      onClose: () => _closeSupport(const Offset(10, 10)),
                    ),
                  ),
                  _overlay(
                    overlay: _settingsOverlay,
                    visible: _model.isSettingsLayoutVisible,
                    child: SettingsScreen(
                      onClose: () => _closeSettings(const Offset(10, 10)),
                    ),
                  ),
                  _overlay(
                    overlay: _historyOverlay,
                    visible: _model.isHistoryLayoutVisible,
                    child: HistoryScreen(
                      onClose: () => _closeHistory(const Offset(10, 10)),
                      onSelect: (entry) {
                        _model.loadFromHistory(entry);
                        _closeHistory(const Offset(10, 10));
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The display-fraction clamp range for the active layout. Portrait (base)
  /// uses the wide [SettingsModel.minDisplayFraction]..maxDisplayFraction;
  /// landscape/tablet (sevenColumn) uses the tighter
  /// [_kWideMinDisplayFraction]..[_kWideMaxDisplayFraction] so the short
  /// landscape height keeps the 7-column keypad's four rows tappable. The SAME
  /// persisted [SettingsModel.displayFraction] feeds both; it is re-clamped per
  /// layout so a fraction saved in one orientation lands sensibly in the other.
  (double, double) _fractionBounds(bool sevenColumn) => sevenColumn
      ? (_kWideMinDisplayFraction, _kWideMaxDisplayFraction)
      : (SettingsModel.minDisplayFraction, SettingsModel.maxDisplayFraction);

  /// Resolves the draggable split into concrete card heights over the given
  /// [contentHeight] (the column area inside the screen padding: display card +
  /// card gap + drag handle + keypad card).
  ///
  /// BOTH layouts now use the SAME draggable handle + persisted
  /// [SettingsModel.displayFraction] split: the display card gets the clamped
  /// fraction of the slack remaining after the gap + handle are reserved; the
  /// keypad card gets the rest.
  ///
  /// PORTRAIT (base): clamped in [SettingsModel.minDisplayFraction] ..
  /// [SettingsModel.maxDisplayFraction], FURTHER tightened by the tap-target
  /// ceiling below so the keypad always keeps >= [_kMinKeyHeight] (~30dp
  /// portrait) key cells at every drag size.
  ///
  /// LANDSCAPE / TABLET (sevenColumn): clamped in the TIGHTER
  /// [_kWideMinDisplayFraction]..[_kWideMaxDisplayFraction] (see
  /// [_fractionBounds]). Tablets clear the [_kMinKeyHeight] floor with room to
  /// spare; the SHORT landscape PHONE cannot fit four [_kMinKeyHeight] rows
  /// under the top bar/handle plus a visible display at ANY split, so the
  /// ceiling does not apply there
  /// (it would only starve the display) - the handle lets the user trade display
  /// height for the largest keys the viewport allows.
  _SplitLayout _splitLayout(
    Dimens dim,
    bool sevenColumn,
    double contentHeight,
  ) {
    final slack = math.max(0.0, contentHeight - dim.cardGap - _kHandleHeight);
    final (minFractionBase, maxFraction) = _fractionBounds(sevenColumn);
    // Fold the ABSOLUTE display-height floor into the minimum fraction (wide
    // only): the left control column must fit on any device, so the display
    // never drops below [_kWideMinDisplayHeight] px (the dropdown was
    // overflowing on short landscape phones where a fraction floor wasn't
    // enough). Capped at maxFraction so it can never invert the range.
    final minFraction = (sevenColumn && slack > 0)
        ? math.min(
            maxFraction,
            math.max(minFractionBase, _kWideMinDisplayHeight / slack))
        : minFractionBase;
    // TAP-TARGET FLOOR: cap how short the keypad card may get so its equal-flex
    // rows never shrink a key below the minimum hit area. Each row is
    // (gridHeight - interRowGaps)/rowCount; require that >= the per-layout key
    // floor, where gridHeight = keypadCardHeight - top/bottom card padding. The
    // resulting minimum keypad-card height yields a per-layout MAXIMUM display
    // height (slack - minKeypadCard), hence a height-derived fraction ceiling
    // the (possibly portrait-saved) fraction is re-clamped against, so dragging
    // can never push cells below the [_kMinKeyHeight] (~30dp portrait) hit-area
    // floor.
    final minKeypadCardHeight = _minGridHeight(dim, sevenColumn) +
        dim.keypadCardPaddingTop +
        dim.keypadCardPaddingBottom;
    // The fraction ceiling the keypad floor implies: the display may take at
    // most the slack left once the keypad has its [minKeypadCardHeight]. When
    // that ceiling sits within the layout's own range, it TIGHTENS the max so a
    // drag can't starve the keys below the floor. When the viewport is too short
    // to honor the floor at ANY split (ceiling <= minFraction - e.g. a landscape
    // PHONE that can't fit four [_kMinKeyHeight] rows plus the top bar/handle/display), the
    // ceiling is meaningless: tightening would only slam the split to its
    // minimum and clip the display without ever reaching the floor, so we DON'T
    // tighten there - the layout keeps its normal max, the keys land at the
    // largest the viewport allows, and the display stays usable.
    final heightCeiling =
        slack > 0 ? (slack - minKeypadCardHeight) / slack : maxFraction;
    // The display-height floor takes PRIORITY over the keypad tap-target ceiling
    // (a short landscape must keep the controls fully visible even if the keys
    // get small), so never let the max fall below the min - that would also make
    // clamp() throw on lowerLimit > upperLimit.
    final effectiveMax = math.max(
      minFraction,
      heightCeiling > minFraction ? math.min(maxFraction, heightCeiling) : maxFraction,
    );
    final fraction = _displayFraction.clamp(minFraction, effectiveMax);
    final displayHeight = slack * fraction;
    final keypadCardHeight = slack - displayHeight;
    // The grid fills the remaining keypad card height via [Expanded] in
    // _keypadCard (both layouts), so the grid height no longer needs to be
    // precomputed here - the drag-sized keypad card drives it directly.
    return _SplitLayout(
      displayHeight: displayHeight,
      keypadCardHeight: keypadCardHeight,
      hasHandle: true,
      minFraction: minFraction,
      maxFraction: effectiveMax,
    );
  }

  /// Apply a vertical drag delta to the split. [primaryDelta] is the handle's
  /// movement in logical px (positive = downward = grow the display). The
  /// fraction is converted from px via [slack] (the shared card height) and
  /// re-clamped to the active layout's [minFraction]..[maxFraction] so the drag
  /// feels free within bounds and stops at the edges (portrait and landscape
  /// share the handler but clamp to their own tighter/looser ranges).
  void _onHandleDrag(
    double primaryDelta,
    double slack,
    double minFraction,
    double maxFraction,
  ) {
    if (slack <= 0) return;
    final next = (_displayFraction + primaryDelta / slack)
        .clamp(minFraction, maxFraction);
    if (next != _displayFraction) {
      setState(() => _displayFraction = next);
    }
  }

  Widget _mainContent(
    Dimens dim,
    AppPalette palette,
    bool sevenColumn,
    _SplitLayout layout,
  ) {
    final callbacks = KeypadCallbacks(
      onToken: _model.addToExpression,
      onUnit: _model.addToExpressionTimeUnit,
      onEquals: _model.sendResultToExpression,
      onBackspace: _model.clearOneLastSymbol,
      onBackspaceLongPress: _onBackspaceLongPress,
    );
    // The slack the two cards share: used to convert a handle drag delta in px
    // into a fraction delta, and to persist on drag end. The drag is clamped to
    // the active layout's bounds (portrait wide range / landscape tighter range)
    // over the SAME persisted fraction.
    final slack = layout.displayHeight + layout.keypadCardHeight;
    // Drag against the layout's EFFECTIVE bounds (the per-layout range tightened
    // by the tap-target height ceiling), so the live drag stops exactly where
    // the split does and a key can never be dragged below the [_kMinKeyHeight]
    // (~30dp portrait) floor.
    final minFraction = layout.minFraction;
    final maxFraction = layout.maxFraction;
    // Outer screen padding mirroring the proto (16/8/16/16): the two cards
    // float on the mainBackground with consistent screen margins.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kScreenPadH,
        _kScreenPadTop,
        _kScreenPadH,
        _kScreenPadBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The display card is sized from the draggable fraction; on wide/tall
          // buckets its content is anchored bottom-right so the result hero hugs
          // the keypad and the breathing room sits up top under the chip. The
          // three SECONDARY tools (Per / Support-tea / Settings) are now BARE
          // icons at the top-right INSIDE this card (no top bar), and the
          // circular-reveal GlobalKeys ride them.
          SizedBox(
            height: layout.displayHeight,
            child: _heroDisplayCard(dim, palette),
          ),
          // Both layouts now carry the draggable handle (hasHandle is always
          // true); it sits in place of the card gap.
          if (layout.hasHandle)
            _dragHandle(dim, palette, slack, minFraction, maxFraction)
          else
            SizedBox(height: dim.cardGap),
          SizedBox(
            height: layout.keypadCardHeight,
            child: _keypadCard(
              dim,
              palette,
              sevenColumn,
              callbacks,
            ),
          ),
        ],
      ),
    );
  }

  /// DRAGGABLE DIVIDER sitting in the card gap between the display and keypad
  /// cards. The hit area is the full width and [_kHandleHeight] tall (>=24dp,
  /// so it is easy to grab even though the visible grabber is a slim pill).
  /// Dragging it vertically grows the display card and shrinks the keypad
  /// (the keys reflow smaller via the keypad grid's Expanded rows). The new
  /// fraction is persisted on drag END (not every frame).
  Widget _dragHandle(
    Dimens dim,
    AppPalette palette,
    double slack,
    double minFraction,
    double maxFraction,
  ) {
    return Semantics(
      label: 'Resize display',
      slider: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) => _onHandleDrag(
          details.primaryDelta ?? 0,
          slack,
          minFraction,
          maxFraction,
        ),
        onVerticalDragEnd: (_) =>
            SettingsModel.instance.setDisplayFraction(_displayFraction),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeRow,
          child: SizedBox(
            height: _kHandleHeight,
            width: double.infinity,
            child: Center(
              // The visible grabber: a ~32x4dp rounded pill at controlsStrong's
              // low alpha so it reads as a quiet affordance, not a hard rule.
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.controlsStrong.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// HERO DISPLAY card: a large rounded tonal surface (displayCardSurface)
  /// holding the expression (top), the green format chip (middle, a
  /// divider-like selector) and the big live result hero anchored at the
  /// bottom. The chip moved OUT of the card's top-left to sit between the
  /// expression and the result.
  Widget _heroDisplayCard(Dimens dim, AppPalette palette) {
    return Container(
      key: _displayCardKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.displayCardSurface,
        borderRadius: BorderRadius.all(Radius.circular(dim.cardRadius)),
      ),
      padding: EdgeInsets.fromLTRB(
        dim.displayCardPaddingH,
        dim.displayCardPaddingTop,
        dim.displayCardPaddingH,
        dim.displayCardPaddingBottom,
      ),
      child: _heroContent(dim, palette),
    );
  }

  /// The expression -> format chip -> live-result group that fills the hero.
  /// The format chip sits BETWEEN the expression and the result hero, reading
  /// as a divider-like selector. Two compositions:
  ///
  /// * PORTRAIT (base): the narrow card's layout - the expression takes the
  ///   vertical slack (Expanded, bottom-right), then the centered chip, then
  ///   the result content-sized below it (Flexible). Right-alignment reads as
  ///   intentional on a narrow card, so no width cap is applied.
  /// * WIDE (landscape / tablet): FULL-WIDTH - the top line is [action icons |
  ///   format selector | expression filling to the right] and the result hero
  ///   spans the whole width below (right-aligned internally). No width cap, so
  ///   the expression uses the full card width instead of being cramped into a
  ///   right-pinned block that wasted the left half.
  Widget _heroContent(Dimens dim, AppPalette palette) {
    final result = KeyedSubtree(
      key: _resultBandKey,
      child: _resultDisplay(dim, palette),
    );
    if (!dim.isWideHero) {
      // PORTRAIT: the chip is a divider-like selector BETWEEN the expression and
      // the result hero - expression (top) -> chip (middle, left-aligned) ->
      // result (bottom). The narrow card has the vertical budget for the chip on
      // its own line.
      final chip = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _formatChip(dim, palette),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _displayTopIcons(dim, palette),
          Expanded(child: _expressionDisplay(dim, palette)),
          chip,
          // Flexible (not fixed) so the Column can compress it if needed.
          Flexible(child: result),
        ],
      );
    }
    // WIDE (landscape / tablet): a two-pane layout. A narrow LEFT control
    // column stacks the action icons over the format dropdown; the rest of the
    // card (the full height to the right of the column) is the display area -
    // the expression fills it and the result sits content-sized below. This
    // frees the top horizontal strip the controls used to occupy, so the
    // expression gets both the extra vertical AND horizontal space.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT control column: bare action icons on top, format dropdown below.
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _displayTopIcons(dim, palette, inline: true),
            const SizedBox(height: 8),
            // Capped so a long format name ellipsizes and the control column
            // never grows too wide / steals the expression's space.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: _formatChip(dim, palette),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // RIGHT display pane: expression fills the slack + full remaining width;
        // the result is content-sized (Flexible so it shrinks when cramped).
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _expressionDisplay(dim, palette)),
              Flexible(child: result),
            ],
          ),
        ),
      ],
    );
  }

  /// KEYPAD card: a large rounded tonal surface (keypadCardSurface) holding the
  /// soft tonal key grid. The single Backspace delete key lives in the grid's
  /// bottom-right slot (the secondary Per/Support/Settings tools moved to the
  /// top bar). The keypad keys are transparent-bg tonal cells, so this card
  /// shows through.
  ///
  /// The card fills the height the draggable split allots it (an outer
  /// SizedBox); the grid takes the WHOLE card so shrinking the keypad card
  /// auto-resizes the key cells (their FittedBox labels keep fitting). Dragging
  /// the handle reflows the grid in portrait AND landscape/tablet.
  ///
  /// The card fills the height the draggable split allots it; the grid takes the
  /// WHOLE card via [Expanded], so shrinking the keypad card auto-resizes the
  /// key cells (their FittedBox labels keep fitting). The [_splitLayout] clamp
  /// caps the display so the keypad card keeps enough height for [_kMinKeyHeight]
  /// rows wherever that is geometrically possible at a usable split (portrait at
  /// any drag size, tablets, roomy landscape windows). On the genuinely short
  /// landscape PHONE - where four [_kMinKeyHeight] rows plus the top bar, handle and a
  /// visible display cannot all fit at ANY split - the keys are instead
  /// maximized by the user via the resize handle (down to the keypad-favored
  /// [_kWideMinDisplayFraction]); the grid still fills cleanly (no scroll, no
  /// overflow), preserving the always-fully-visible landscape keypad identity.
  Widget _keypadCard(
    Dimens dim,
    AppPalette palette,
    bool sevenColumn,
    KeypadCallbacks callbacks,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.keypadCardSurface,
        borderRadius: BorderRadius.all(Radius.circular(dim.cardRadius)),
      ),
      padding: EdgeInsets.fromLTRB(
        dim.keypadCardPaddingH,
        dim.keypadCardPaddingTop,
        dim.keypadCardPaddingH,
        dim.keypadCardPaddingBottom,
      ),
      child: SizedBox(
        width: double.infinity,
        // The enabled time-unit keys (Settings -> Keypad keys). Read live here;
        // the screen rebuilds on changes via the SettingsModel listener added in
        // initState.
        child: Builder(
          builder: (context) {
            final units = SettingsModel.instance.enabledUnits;
            return sevenColumn
                ? LandscapeKeypad(
                    callbacks: callbacks,
                    units: units,
                    backspaceKey: _deleteKey,
                  )
                : PortraitKeypad(
                    callbacks: callbacks,
                    units: units,
                    backspaceKey: _deleteKey,
                  );
          },
        ),
      ),
    );
  }

  /// The minimum height the key grid needs for every key cell to clear the
  /// tap-target floor: [rowCount] keys at [_kMinKeyHeight] plus the
  /// (rowCount-1) inter-row [Dimens.keyGap]s. Drives the [_splitLayout] display
  /// ceiling that keeps the keypad card tall enough for the floor.
  double _minGridHeight(Dimens dim, bool sevenColumn) {
    final rowCount = sevenColumn ? _kWideKeypadRows : _kPortraitKeypadRows;
    return rowCount * _kMinKeyHeight + (rowCount - 1) * dim.keyGap;
  }

  Widget _expressionDisplay(Dimens dim, AppPalette palette) {
    // No opaque background now: it sits INSIDE the hero display card, which
    // owns the surface. The expression is the secondary line, bottom-right
    // aligned, just above the result hero. Bottom padding separates it from
    // the result band.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      alignment: Alignment.bottomRight,
      child: SelectionArea(
        child: ValueListenableBuilder<Tokens>(
          valueListenable: _model.expression,
          builder: (context, tokens, _) => _autoSizeTokens(
            spansBuilder: (fontSize) => tokensToSpans(
              tokens,
              fontSize: fontSize,
              palette: palette,
            ),
            color: palette.expressionNums,
            bold: false,
            minSize: dim.expressionMinTextSize,
            // Wide buckets cap the expression below the result hero so it can
            // never render larger and invert the hierarchy; portrait keeps the
            // full ceiling (heroExpressionMaxTextSize resolves accordingly).
            maxSize: dim.heroExpressionMaxTextSize,
            step: dim.autoSizeStep,
            reverseScroll: true,
          ),
        ),
      ),
    );
  }

  /// The selected-format selector, now an M3 Expressive assist-style tonal
  /// chip pinned to the top-left of the hero display card. The Android branch
  /// rendered it as a PLAIN label at colorControls (no container, no icon, no
  /// ripple) which read as a static caption; users did not discover it opens
  /// the Formats overlay.
  ///
  /// REDESIGN: a green-tonal pill (timeKeyFill fill + timeKeyText glyphs, the
  /// green=time identity expressed as a tonal fill) with a leading schedule
  /// glyph, the format name, and a trailing dropdown caret ("Hour Minute v"),
  /// a pill-clipped ink ripple and a >=48dp tap target. It is gated exactly
  /// like the old Formats button (disabled => dimmed + non-interactive) and
  /// carries the circular-reveal GlobalKey (_formatsButtonKey) so the Formats
  /// overlay animates out of the chip the user actually tapped.
  Widget _formatChip(Dimens dim, AppPalette palette) {
    final disabled = _model.isFormatsViewButtonDisabled;
    return ValueListenableBuilder<ResultFormat?>(
      valueListenable: _model.selectedFormat,
      builder: (context, format, _) {
        final name = format?.textPresentationOfTokens ?? 'Hour Minute';
        return Semantics(
          button: true,
          label: 'Result format: $name. Tap to change.',
          child: Opacity(
            opacity: disabled ? 0.38 : 1.0,
            child: Material(
              color: palette.timeKeyFill,
              borderRadius: BorderRadius.circular(dim.formatChipRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: _formatsButtonKey,
                onTap: disabled ? null : _openFormats,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(16, 9, 12, 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 18, color: palette.timeKeyText),
                        const SizedBox(width: 8),
                        Flexible(
                          child: ExcludeSemantics(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: TextStyle(
                                color: palette.timeKeyText,
                                fontSize: dim.separatorTimeTextSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.expand_more,
                          size: dim.separatorTimeTextSize + 4,
                          color: palette.timeKeyText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The big live RESULT hero, anchored at the bottom of the hero display
  /// card. It sits ON the card surface (no opaque background now) and renders
  /// at HERO scale: the bold figures auto-size DOWN from heroResultBaseSize so
  /// they never overflow at 320dp / on long results, while keeping spans.dart
  /// styling (green time-unit spans + grey/strong figures via 0.7x spans).
  Widget _resultDisplay(Dimens dim, AppPalette palette) {
    return Container(
      width: double.infinity,
      // Portrait keeps the result content-sized and vertically centered in its
      // small Flexible slot. On wide buckets the result lives in an Expanded
      // slot and is anchored to the BOTTOM-right so the hero grows up from the
      // card bottom instead of floating in the middle of the tall slot.
      alignment:
          dim.isWideHero ? Alignment.bottomRight : Alignment.centerRight,
      // Rebuild on result OR expression changes: the F1 "Add a time unit"
      // hint depends on both (shown only when the input is unitless
      // arithmetic with no result).
      child: ListenableBuilder(
        listenable: Listenable.merge([_model.resultTokens, _model.expression]),
        builder: (context, _) {
          final tokens = _model.resultTokens.value;
          // F1: unitless arithmetic ("5", "5 x 3") never produces a result -
          // explain why instead of showing a blank slot.
          if (tokens.isEmpty && _model.shouldShowAddUnitHint) {
            return _addUnitHint(palette);
          }
          final result = _autoSizeTokens(
            spansBuilder: (fontSize) => [
              // Subtle "= " prefix so the live result reads as the answer
              // ("= 4 Hours 50 Minutes"). Only emitted when there IS a result;
              // it rides the SAME Text.rich as the figures so AutoSizeText
              // still scales the whole line uniformly and never overflows.
              // Strong-grey (controlsStrong) at the figures' 0.7x size so it
              // sits beside the numbers as a quiet leading mark.
              if (tokens.isNotEmpty)
                TextSpan(
                  text: '= ',
                  style: TextStyle(
                    color: palette.controlsStrong,
                    fontSize: fontSize * 0.7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ...tokensToLightSpans(
                tokens,
                fontSize: fontSize,
                palette: palette,
              ),
            ],
            // Every light span carries its own color; the base color only
            // matters for hypothetical unspanned segments.
            color: palette.nums,
            bold: true,
            minSize: dim.resultOutputMinTextSize,
            // Hero scale: the result is the visual anchor of the card, so it
            // grows to heroResultBaseSize (46 with the 0.7x unit spans =>
            // ~32dp unit words).
            maxSize: dim.heroResultBaseSize,
            step: dim.autoSizeStep,
            reverseScroll: false,
          );
          if (tokens.isEmpty) return result;
          final resultText = tokens.toStringWithSpaces();
          // The result is the single tappable hero (no separate copy button):
          //  - a SHORT TAP opens the action menu (copy / change result format /
          //    rate / share);
          //  - a LONG PRESS hands off to the wrapping SelectionArea for native
          //    text selection + the system copy/select-all toolbar.
          // InkWell registers only a tap recognizer (no onLongPress), so the
          // long press falls through to SelectionArea while the tap is claimed
          // by the deeper InkWell. The Material gives the InkWell its ripple
          // over the otherwise non-Material card.
          //
          // Semantics: expose it as a labelled BUTTON (mirroring the format
          // chip) so screen-reader users get a discoverable, activatable entry
          // point to the menu - otherwise Copy/Share (which live only in the
          // sheet) would be unreachable. ExcludeSemantics on the figures drops
          // a redundant text node; on-screen text selection still works (it is
          // a render-level feature, independent of the semantics tree).
          return SelectionArea(
            child: Semantics(
              button: true,
              label: 'Result $resultText. '
                  'Tap for actions: copy, change format, rate, share.',
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const ValueKey('result-tappable'),
                  onTap: () => _showResultMenu(context, resultText),
                  borderRadius: BorderRadius.circular(10),
                  child: ExcludeSemantics(child: result),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Copies [text] to the clipboard and shows a brief confirmation - EXCEPT on
  /// Android, which since 13 pops its OWN system "Copied" preview for every
  /// clipboard write; adding our snackbar on top is the "two toasts" the user
  /// saw. So we only show our own confirmation where the platform gives no
  /// native copy feedback (iOS / web / desktop). Where shown, any current toast
  /// is removed INSTANTLY first (removeCurrentSnackBar, no exit animation) so a
  /// repeat copy replaces it rather than stacking.
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (platformConfirmsCopy) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(milliseconds: 1300),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Single-tap on the result opens this action sheet - a tidy M3 bottom sheet
  /// (drag handle, rounded top) so the result stays the one tappable hero with
  /// no button clutter: copy, change the result format, open the rate
  /// calculator, or share. Each action closes the sheet first, then runs.
  void _showResultMenu(BuildContext context, String resultText) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Size to content rather than the default 9/16-of-screen cap, and let the
      // rows scroll if the screen is too short - otherwise the four actions
      // overflow the squeezed landscape sheet height.
      isScrollControlled: true,
      builder: (sheetContext) {
        Widget action(IconData icon, String label, VoidCallback onTap) {
          return ListTile(
            leading: Icon(icon),
            title: Text(label),
            onTap: () {
              Navigator.of(sheetContext).pop();
              onTap();
            },
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                action(
                  Icons.content_copy,
                  'Copy result',
                  () => _copyToClipboard(context, resultText),
                ),
                action(Icons.swap_horiz, 'Change result format', _openFormats),
                action(Icons.more_time, 'Rate calculator', _openPer),
                action(
                  Icons.share_outlined,
                  'Share',
                  () => shareText(resultText),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// F1 (empty/invalid-result hint): the small "Add a time unit" hint shown in
  /// the result slot when the input is unitless arithmetic (e.g. "5", "5 x 3")
  /// that can never produce a time result. Quiet muted-grey ([AppPalette.controls]
  /// - the same secondary tint as the version footer) at a normal weight so it
  /// reads as a gentle nudge, not an error; a concrete example teaches the format
  /// so a new user does not assume the app is broken. ASCII-only text (ABeeZee
  /// has no em dash / "≈").
  Widget _addUnitHint(AppPalette palette) {
    return Text(
      "Add a time unit - try '2 Hours 5 Minutes + 15 Minutes'",
      textAlign: TextAlign.end,
      style: TextStyle(
        color: palette.controls,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.3,
      ),
    );
  }

  /// The slim TOP BAR (both orientations): the three SECONDARY tools as
  /// right-aligned filled-tonal icon buttons - Per (more_time), Support-tea
  /// (emoji_food_beverage, with the red attention Badge on Android-when-nothing-
  /// owned + the iOS rules), Settings (settings). They carry the
  /// circular-reveal GlobalKeys (_perButtonKey / _foodButtonKey /
  /// _settingsButtonKey) so the overlays animate out of the bar buttons. The
  /// Per Pro-lock badge (iOS gated) rides the Per button here.
  ///
  /// Backspace/Clear are NOT here - they moved into the keypad as real keys.
  /// The three SECONDARY action icons as filled-tonal TOOL buttons: Per,
  /// Food/Tea, Settings (left-to-right order in the top bar). Backspace moved
  /// to a real keypad key (the blue operator accent) and Formats is the tonal
  /// format chip in the hero card, so neither is here anymore. All three are
  /// neutral tool buttons (toolButtonFill cell + controlsStrong glyph).
  List<Widget> _actionIcons(Dimens dim, AppPalette palette) {
    return [
      // ic_per (clock + plus). When Pro gating is on and not yet unlocked the
      // glyph carries a small lock badge (tap still routes through _openPer,
      // which opens the paywall once a valid result exists). The
      // ListenableBuilder drops the lock the instant Pro is unlocked.
      ListenableBuilder(
        listenable: Monetization.instance,
        builder: (context, _) {
          final per = Icon(
            Icons.more_time,
            size: dim.actionGlyphSize,
            color: palette.controlsStrong,
            semanticLabel: 'Per',
          );
          final locked = Monetization.instance.isProGated &&
              !Monetization.instance.hasPro;
          return _actionIcon(
            key: _perButtonKey,
            dim: dim,
            icon: locked
                ? _withLockBadge(per, dim, palette)
                : per,
            disabled: _model.isPerViewButtonDisabled,
            onTap: _openPer,
          );
        },
      ),
      // F6: the History entry point sits next to Per (Rate). It appears only
      // while history is enabled in Settings (on by default); turning it off
      // hides it. The screen rebuilds on the SettingsModel listener, so the
      // toggle shows/hides it live.
      if (SettingsModel.instance.historyEnabled)
        _actionIcon(
          key: _historyButtonKey,
          dim: dim,
          icon: Icon(
            Icons.history,
            size: dim.actionGlyphSize,
            color: palette.controlsStrong,
            semanticLabel: 'History',
          ),
          onTap: _openHistory,
        ),
      // The tea-cup "Support the app" (donations) entry is shown ONLY where
      // buying actually works (Android). On iOS/web there are no donations -
      // Rate/Share live in Settings (HELP section) and monetization is the Pro
      // paywall - so the button is omitted there entirely. The red attention
      // badge shows while the user owns NO support purchase yet.
      if (Monetization.instance.isBillingAvailable)
        ListenableBuilder(
          listenable: Monetization.instance,
          builder: (context, _) {
            final cup = Icon(
              Icons.emoji_food_beverage,
              size: dim.actionGlyphSize,
              color: palette.controlsStrong,
              semanticLabel: 'Tea',
            );
            final showBadge = !Monetization.instance.hasAnySupport;
            return _actionIcon(
              key: _foodButtonKey,
              dim: dim,
              icon: showBadge
                  ? Badge(
                      backgroundColor: AppPalette.badge,
                      smallSize: 9,
                      child: cup,
                    )
                  : cup,
              onTap: _openSupport,
            );
          },
        ),
      _actionIcon(
        key: _settingsButtonKey,
        dim: dim,
        icon: Icon(
          Icons.settings,
          size: dim.actionGlyphSize,
          color: palette.controlsStrong,
          semanticLabel: 'Settings',
        ),
        onTap: _openSettings,
      ),
    ];
  }

  /// Overlays a small lock_outline glyph on the bottom-end corner of a Pro-
  /// gated action icon (the controls tint matches the icon itself, so the lock
  /// reads as part of the same affordance rather than a separate badge).
  Widget _withLockBadge(Icon icon, Dimens dim, AppPalette palette) {
    final lockSize = dim.actionGlyphSize * 0.5;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        PositionedDirectional(
          end: -lockSize * 0.25,
          bottom: -lockSize * 0.25,
          child: Icon(
            Icons.lock_outline,
            size: lockSize,
            color: palette.controlsStrong,
            semanticLabel: 'Locked (Pro)',
          ),
        ),
      ],
    );
  }

  /// One BARE action icon sitting on the hero display card (Per / Tea /
  /// Settings): just the glyph in a [Dimens.toolButtonSize] (48dp) tap cell
  /// with a circular ink ripple - NO filled-tonal background (the user wanted
  /// the top icons without visible buttons, on the expression card). The
  /// reveal GlobalKey rides the InkResponse so the circular-reveal launches
  /// from the cell center; any red/lock badge baked into [icon] sits over the
  /// centered glyph. The ripple needs a Material ancestor - [_displayTopIcons]
  /// supplies a transparent one.
  ///
  /// Disabled (gated Per) renders at Material's 0.38 alpha and is
  /// non-interactive - the branch's 0.2 made them near-invisible ghosts.
  Widget _actionIcon({
    required GlobalKey key,
    required Dimens dim,
    required Widget icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool disabled = false,
  }) {
    final button = InkResponse(
      key: key,
      onTap: disabled ? null : onTap,
      onLongPress: disabled ? null : onLongPress,
      radius: dim.toolButtonSize * 0.5,
      child: SizedBox(
        width: dim.toolButtonSize,
        height: dim.toolButtonSize,
        child: Center(child: icon),
      ),
    );
    return Opacity(
      opacity: disabled ? 0.38 : 1.0,
      child: button,
    );
  }

  /// The bare action-icon row (Per / Tea / Settings) shown at the TOP-RIGHT of
  /// the hero display card. A transparent [Material] hosts the InkResponses'
  /// ripples (the display card is a plain Container). Replaces the old
  /// filled-tonal top bar.
  Widget _displayTopIcons(Dimens dim, AppPalette palette, {bool inline = false}) {
    final icons = _actionIcons(dim, palette);
    return Material(
      type: MaterialType.transparency,
      child: Row(
        // Portrait reserves a full-width row (LEFT-aligned); landscape/tablet
        // inlines a content-sized cluster at the START of the top line.
        mainAxisSize: inline ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (var i = 0; i < icons.length; i++) ...[
            if (i != 0) const SizedBox(width: 4),
            icons[i],
          ],
        ],
      ),
    );
  }

  /// Auto-sizing rich text replicating Android autoSizeTextType=uniform:
  /// shrinks from [maxSize] to [minSize] in [step] increments; if the text
  /// still overflows at [minSize] it becomes vertically scrollable.
  Widget _autoSizeTokens({
    required List<TextSpan> Function(double fontSize) spansBuilder,
    required Color color,
    required bool bold,
    required double minSize,
    required double maxSize,
    required double step,
    required bool reverseScroll,
  }) {
    TextStyle styleFor(double size) => TextStyle(
      color: color,
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    final minSizeText = Text.rich(
      TextSpan(style: styleFor(minSize), children: spansBuilder(minSize)),
      textAlign: TextAlign.right,
    );
    return AutoSizeText.rich(
      TextSpan(children: spansBuilder(maxSize)),
      style: styleFor(maxSize),
      textAlign: TextAlign.right,
      presetFontSizes: autoSizePresets(min: minSize, max: maxSize, step: step),
      overflowReplacement: SingleChildScrollView(
        reverse: reverseScroll,
        child: Align(alignment: Alignment.centerRight, child: minSizeText),
      ),
    );
  }

  /// Green (colorResultTime) circular flash, 400ms; clears everything when the
  /// reveal completes. (RemoveADS recolored tvFakeForClear from holo_blue_dark
  /// to colorResultTime.) Positioned at - and clipped to - the hero display
  /// card's EXACT rect (the constant screen paddings + [_displayCardHeight]),
  /// with the card's rounded corners via the [ClipRRect], so the wipe reveals
  /// INSIDE the expression/result card instead of over the whole background band
  /// above the keypad.
  Widget _clearFlash(AppPalette palette, Dimens dim) {
    return Positioned(
      left: _kScreenPadH,
      right: _kScreenPadH,
      top: _kScreenPadTop,
      height: _displayCardHeight,
      child: AnimatedBuilder(
        animation: _flashController,
        builder: (context, _) {
          if (_flashController.isDismissed) return const SizedBox.shrink();
          return IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(dim.cardRadius)),
              child: ClipPath(
                clipper: CircularRevealClipper(
                  fraction: Curves.easeInOut.transform(_flashController.value),
                  center: _flashCenter,
                ),
                child: ColoredBox(color: palette.resultTime),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _overlay({
    required _RevealOverlay overlay,
    required bool visible,
    required Widget child,
  }) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: overlay.controller,
        builder: (context, builtChild) {
          final hidden = overlay.controller.isDismissed && !visible;
          return Offstage(
            offstage: hidden,
            // A closed overlay stays mounted; keep its text fields out of the
            // focus tree so they cannot hold or regain an IME connection.
            child: ExcludeFocus(
              excluding: hidden,
              child: ClipPath(
                clipper: CircularRevealClipper(
                  fraction: overlay.animation.value,
                  center: overlay.revealCenter,
                ),
                child: builtChild,
              ),
            ),
          );
        },
        child: child,
      ),
    );
  }
}

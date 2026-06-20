import 'package:flutter/material.dart';

import '../data/result_format.dart';
import '../data/result_formats.dart';
import '../services/entitlements.dart';
import '../services/monetization.dart';
import '../state/calculator_model.dart';
import 'pro_screen.dart';
import 'spans.dart';
import 'theme.dart';

/// Full-screen "Result format" chooser overlay (view_formats.xml).
///
/// Material 3 Expressive restyle (matching the calculator's two tonal cards):
/// the flat grey panel + dated toolbar are gone. The overlay floats on
/// [AppPalette.mainBackground] under the shared [overlayHeader] (a tonal
/// rounded back button + ABeeZee title), with a one-line helper underneath so
/// the screen's purpose is obvious at a glance.
///
/// INTUITIVE-UX pass: the 24 formats are split into clearly-labelled sections -
/// "Single unit" (the eight one-unit formats) and "Combined" (every multi-unit
/// format, including "All Units") - derived from each format's time-unit token
/// count so the grouping stays correct if the list changes, while keeping the
/// repository order within each group. Each row is compact and scannable: the
/// green format NAME is the title, a grey live preview of the CURRENT result in
/// that format is the secondary line, and a trailing chevron makes tappability
/// obvious. The preview number is rounded to a readable precision (a leading
/// "≈" marks when it was rounded) - a display hint only, never the committed
/// result. The CURRENTLY-SELECTED row is highlighted with a green-tonal fill +
/// accent ring + check so it reads as picked. Tapping a row selects the format
/// (single-select) and closes the overlay; Pro-gated formats keep their lock
/// affordance and route the tap to the paywall.
///
/// AUTO-SCROLL-TO-SELECTION: the default "Hour Minute" format sits deep in the
/// COMBINED section, below the fold, so opening the overlay used to land the
/// user at the top with no visible cue as to which format is picked. On open we
/// now scroll the CURRENTLY-SELECTED row to the middle of the viewport ONCE (a
/// post-frame [Scrollable.ensureVisible] guarded by a one-shot flag), so the
/// highlighted format is comfortably visible from the first revealed frame. The
/// user can then scroll freely; the jump never fires again.
class FormatsScreen extends StatefulWidget {
  const FormatsScreen({
    super.key,
    required this.model,
    required this.onClose,
    this.visible = true,
  });

  final CalculatorModel model;

  /// Toolbar back-arrow handler (closes with the top-left reveal center).
  final VoidCallback onClose;

  /// Whether the overlay is currently open. The overlay widget stays mounted
  /// (Offstage) when closed and is re-shown via a circular reveal, so we re-arm
  /// the auto-scroll-to-selection each time this transitions false -> true (see
  /// [_FormatsScreenState.didUpdateWidget]) rather than only once at mount.
  final bool visible;

  @override
  State<FormatsScreen> createState() => _FormatsScreenState();
}

class _FormatsScreenState extends State<FormatsScreen> {
  /// Attached to the SELECTED row only, so we can scroll it into view on open.
  final GlobalKey _selectedRowKey = GlobalKey();

  /// Drives the list so the selected row can be jumped to on open even when it
  /// starts below the fold (a lazy [ListView] doesn't lay out off-screen rows,
  /// so the keyed row has no context until we scroll near it).
  final ScrollController _controller = ScrollController();

  /// One-shot-per-open guard: the auto-scroll-to-selection runs once after the
  /// overlay opens; cleared on close so a later reopen re-centres. This lets the
  /// user freely scroll while the overlay stays open without it snapping back.
  bool _didScrollToSelection = false;

  /// True for a single-time-unit format (Year, Month, ... Msec): exactly one
  /// of its format tokens is a time keyword. Derived from the tokens, NOT a
  /// hardcoded name list, so it stays correct if the repository list changes.
  static bool _isSingleUnit(ResultFormat format) =>
      format.formatTokens.where((t) => t.type.isTimeKeyword).length == 1;

  @override
  void initState() {
    super.initState();
    // If the overlay is mounted already-open (e.g. the smoke/golden harness
    // builds it visible), centre the selection after the first layout.
    if (widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelection());
    }
  }

  @override
  void didUpdateWidget(FormatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      // The overlay just opened: re-arm and centre the selection on the next
      // frame (the rows are mounted while Offstage, so the key resolves).
      _didScrollToSelection = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelection());
    } else if (!widget.visible && oldWidget.visible) {
      // Closed: re-arm so the next open re-centres rather than no-ops.
      _didScrollToSelection = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Centres the selected row in the viewport ONCE per open.
  ///
  /// A lazy [ListView] only lays out the visible rows (plus a small cache
  /// extent), so when the selected format starts below the fold (the default
  /// "Hour Minute" sits deep in COMBINED) its [GlobalKey] has no context yet and
  /// [Scrollable.ensureVisible] has nothing to target. We therefore walk the
  /// list toward it: each frame, if the keyed row isn't mounted, jump a
  /// viewport-height further down (bounded by [maxScrollExtent]) so the sliver
  /// builds the rows near the bottom, then retry on the next frame. Once the row
  /// is mounted we ensureVisible at 0.5 to centre it. A bounded step count
  /// guards against looping if the row never resolves. Rows already on-screen
  /// (e.g. "Year" at index 0) resolve on the first pass and clamp to a no-op.
  void _scrollToSelection({int step = 0}) {
    if (_didScrollToSelection || !mounted || !widget.visible) return;
    final selectedContext = _selectedRowKey.currentContext;
    if (selectedContext != null) {
      _didScrollToSelection = true;
      // A zero-duration jump positions the list BEFORE the circular reveal
      // finishes animating it in, so the highlighted format is already centred
      // when revealed (no visible scroll jank).
      Scrollable.ensureVisible(
        selectedContext,
        alignment: 0.5, // centre the selected row in the viewport
        duration: Duration.zero,
      );
      return;
    }
    // Row not laid out yet (below the fold). Step the scroll toward the bottom
    // so the sliver builds rows near the selection, then retry next frame.
    if (!_controller.hasClients || step > 30) return; // nothing selected / guard
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent) {
      return; // reached the end without finding it (nothing selected)
    }
    final next = (position.pixels + position.viewportDimension)
        .clamp(0.0, position.maxScrollExtent);
    _controller.jumpTo(next);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToSelection(step: step + 1));
  }

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    return Material(
      color: palette.mainBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          overlayHeader(
            title: 'Result format',
            onClose: widget.onClose,
            dim: dim,
            palette: palette,
          ),
          // One-line helper so the screen's purpose is obvious.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
            child: Text(
              'Tap a format to show your result that way.',
              style: TextStyle(fontSize: 14, color: palette.controlsStrong),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<ResultFormats>(
              valueListenable: widget.model.resultFormats,
              builder: (context, formats, _) {
                // Pro gating drives a per-row lock; rebuild the whole list on
                // unlock so the locks clear at once. Where gating is off,
                // isFormatFree is always true and no locks render.
                return ListenableBuilder(
                  listenable: Monetization.instance,
                  builder: (context, _) => _buildList(context, formats, dim,
                      palette),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the grouped, scannable list. Sections are derived from the token
  /// count (1 time unit = "Single unit", >1 = "Combined"), keeping repository
  /// order within each group. Rows carry the original repository index so
  /// selection (and the gating tests' index assumptions) stay intact.
  Widget _buildList(
    BuildContext context,
    ResultFormats formats,
    Dimens dim,
    AppPalette palette,
  ) {
    final single = <int>[];
    final combined = <int>[];
    for (var i = 0; i < formats.length; i++) {
      (_isSingleUnit(formats[i]) ? single : combined).add(i);
    }
    final children = <Widget>[];
    void addSection(String label, List<int> indices) {
      if (indices.isEmpty) return;
      children.add(_sectionLabel(label, palette));
      for (final index in indices) {
        children.add(_formatRow(context, formats, index, dim, palette));
      }
    }

    addSection('Single unit', single);
    addSection('Combined', combined);
    return ListView(
      // Owns scrolling so the open animation can jump the selected row into
      // view (auto-scroll-to-selection).
      controller: _controller,
      // Cards carry their own margins; the list keeps the screen's side gutters
      // + a little top/bottom air so the first/last card doesn't kiss the
      // header/edge.
      padding: EdgeInsets.fromLTRB(
        dim.margin8,
        0,
        dim.margin8,
        dim.margin16,
      ),
      children: children,
    );
  }

  /// A small all-caps section label, like the Settings overlay's group
  /// headers, so the two groups read as deliberate sections.
  Widget _sectionLabel(String text, AppPalette palette) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 16, 12, 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: palette.controlsStrong,
          ),
        ),
      );

  /// Trailing affordance for a Pro-locked row: a small accent "Pro" pill with
  /// a lock glyph, so the lock reason is VISIBLE (not only announced via the
  /// semanticLabel). The whole badge carries the "Locked (Pro)" semantics; the
  /// tap still routes to the paywall (handled by the row's InkWell).
  Widget _proLockBadge(AppPalette palette) => Semantics(
        label: 'Locked (Pro)',
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 10, 4),
          decoration: BoxDecoration(
            color: AppPalette.accent.withAlpha(0x1F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 15,
                color: AppPalette.accent,
              ),
              const SizedBox(width: 4),
              const Text(
                'Pro',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.accent,
                ),
              ),
            ],
          ),
        ),
      );

  /// One compact, scannable format row: green NAME title, rounded grey preview
  /// secondary line, and a trailing chevron / check / lock affordance.
  Widget _formatRow(
    BuildContext context,
    ResultFormats formats,
    int index,
    Dimens dim,
    AppPalette palette,
  ) {
    final format = formats[index];
    // Compact, scannable sizes (more rows fit on screen): the name reads as a
    // clear title, the preview as a calm secondary line.
    const nameSize = 19.0;
    const previewSize = 16.0;
    // Pro gate: free formats select normally; locked formats route the tap to
    // the paywall and carry a trailing lock. Where gating is off, every format
    // is free (isFormatFree always true) so this is a no-op.
    final free = isFormatFree(format.textPresentationOfTokens);
    final selected = format.isSelected;
    final radius = BorderRadius.circular(dim.cardRadius);

    // Round the preview number for readability; a leading "~" marks a value
    // that was rounded (an approximation), so the preview reads as a hint, not
    // the committed result. ("~" is the ASCII approximation sign - ABeeZee, the
    // app's only bundled face, has no U+2248 "≈" glyph, which would render as
    // tofu both in goldens and on devices that lack a system fallback.)
    final rounded = roundPreviewTokens(format.convertedResultTokens);
    final previewSpans = <TextSpan>[
      if (rounded.wasRounded)
        TextSpan(
          text: '~',
          style: TextStyle(fontSize: previewSize, color: palette.resultNums),
        ),
      ...tokensToLightSpans(
        rounded.tokens,
        fontSize: previewSize,
        palette: palette,
      ),
    ];

    final Widget trailing;
    if (!free) {
      // Locked rows pair the lock glyph with a VISIBLE "Pro" chip so a sighted
      // newcomer sees the reason (not only the screen-reader semanticLabel) -
      // rubric axis 5: locked states say why. The chip uses the accent identity
      // and the row content is dimmed below, so locked rows also read as
      // "not directly selectable" by a second cue, not color alone.
      trailing = _proLockBadge(palette);
    } else if (selected) {
      trailing = const Icon(
        Icons.check_circle,
        size: 22,
        color: AppPalette.accent,
        semanticLabel: 'Selected',
      );
    } else {
      trailing = Icon(
        Icons.chevron_right,
        size: 22,
        color: palette.controlsStrong.withAlpha(0x99),
      );
    }

    return Container(
      // The selected row carries the GlobalKey so its context can be scrolled
      // into view on open (auto-scroll-to-selection). Only ONE row is selected,
      // so only one row ever gets the key.
      key: selected ? _selectedRowKey : null,
      margin: EdgeInsets.symmetric(
        horizontal: dim.margin8,
        vertical: dim.margin8 * 0.5,
      ),
      decoration: BoxDecoration(
        // Selected: a green-tonal fill (timeKeyFill, the green=time identity)
        // so the picked format reads as filled, not just outlined. Unselected:
        // the neutral display-card surface, matching the calculator's cards.
        color: selected ? palette.timeKeyFill : palette.displayCardSurface,
        borderRadius: radius,
        // Flat tonal surface like the calculator/Settings cards: no drop shadow
        // and no hairline outline on unselected cards. Only the SELECTED row
        // carries a 2dp accent ring (a meaningful state cue, redundant with the
        // green fill + check icon) so it reads as picked at a glance.
        border: selected
            ? Border.all(color: AppPalette.accent, width: 2)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: free
              ? () => widget.model.setSelectedFormat(index)
              : () => showProPaywall(context),
          // >=48dp tap target even though the visual row is compact.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    // Locked rows dim their name+preview (a second, non-color
                    // cue that they aren't directly selectable); the trailing
                    // "Pro" badge stays full-strength so the reason is clear.
                    child: Opacity(
                      opacity: free ? 1.0 : 0.55,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                greenSpan(
                                  format.textPresentationOfTokens,
                                  // greenSpan applies a 0.7x factor; pass the
                                  // pre-scaled size so the name lands at
                                  // nameSize.
                                  fontSize: nameSize / kTokenRelativeSize,
                                  palette: palette,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: previewSize,
                                color: palette.nums,
                              ),
                              children: previewSpans,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 10),
                    child: trailing,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared modern overlay header for the Formats / Per overlays, replacing the
/// dated flat-grey `?attr/colorPrimary` toolbar. It sits on
/// [AppPalette.mainBackground] (the same surface the cards float on) and uses
/// the calculator's tonal-tool-button idiom for the back affordance: a soft
/// rounded [AppPalette.toolButtonFill] cell ([Dimens.toolButtonRadius]) with an
/// inked ripple and a >=48dp tap target, plus an ABeeZee title in the strong
/// control tint. Kept as a top-level helper so both overlays render an
/// identical header without duplicating the chrome.
Widget overlayHeader({
  required String title,
  required VoidCallback onClose,
  required Dimens dim,
  required AppPalette palette,
}) {
  return Container(
    color: palette.mainBackground,
    padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 16, 8),
    child: Row(
      children: [
        Material(
          color: palette.toolButtonFill,
          borderRadius: BorderRadius.circular(dim.toolButtonRadius),
          clipBehavior: Clip.antiAlias,
          child: InkResponse(
            onTap: onClose,
            containedInkWell: true,
            highlightShape: BoxShape.rectangle,
            child: SizedBox(
              width: dim.toolButtonSize,
              height: dim.toolButtonSize,
              child: Center(
                child: Icon(
                  Icons.arrow_back,
                  size: dim.actionGlyphSize,
                  color: palette.controlsStrong,
                  semanticLabel: 'Back',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: palette.controlsStrong,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

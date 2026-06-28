import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/lexical_analyzer.dart';
import '../services/entitlements.dart';
import '../services/history_service.dart';
import '../services/monetization.dart';
import 'clipboard_feedback.dart';
import 'formats_screen.dart' show overlayHeader;
import 'pro_screen.dart' show showProPaywall;
import 'spans.dart';
import 'theme.dart';

/// F6 calculation-history overlay. Opened from the top-bar History icon (only
/// present while history is enabled in Settings) with the same circular reveal
/// as Formats/Per/Support/Settings, and styled to match them: the shared
/// [overlayHeader], a [AppPalette.mainBackground] float, and rounded tonal
/// section cards of rows.
///
/// Each row shows the entered expression over its "= result" (both re-lexed so
/// the green time-unit spans match the calculator). Tapping a row reloads that
/// calculation into the input and recomputes (via [onSelect]); a "Clear
/// history" card wipes the log (with a confirmation). The empty state explains
/// how entries get here.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.onClose,
    required this.onSelect,
  });

  /// Toolbar back-arrow handler (closes with the top-left reveal center).
  final VoidCallback onClose;

  /// Loads the chosen entry back into the calculator (restoring its saved
  /// result format) and closes the overlay.
  final ValueChanged<HistoryEntry> onSelect;

  static const double _screenPadH = 16;

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    return Material(
      color: palette.mainBackground,
      // Wrap the whole overlay so the header's "clear all" action appears/hides
      // with the entries (and the body switches between the list and the hint).
      child: ListenableBuilder(
        // Monetization too: buying Pro from the upsell must reveal the full log.
        listenable: Listenable.merge(
            [HistoryService.instance, Monetization.instance]),
        builder: (context, _) {
          final all = HistoryService.instance.entries;
          // Free (gated, non-Pro) users see only the most recent
          // [kFreeHistoryLimit]; older entries stay in storage and reappear the
          // moment Pro is unlocked. Everywhere gating is off the full log shows.
          final entries = hasUnlimitedHistory
              ? all
              : all.take(kFreeHistoryLimit).toList();
          final hiddenCount = all.length - entries.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              overlayHeader(
                title: 'History',
                onClose: onClose,
                dim: dim,
                palette: palette,
                // "Clear all" lives in the header so it is always reachable -
                // not buried below a long, scrolled list. Only when non-empty.
                trailing: entries.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined),
                        color: palette.controlsStrong,
                        tooltip: 'Clear history',
                        onPressed: () => confirmClearHistory(context),
                      ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? _emptyHint(palette)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                            _screenPadH, 4, _screenPadH, 24),
                        child: _section(
                          dim,
                          palette,
                          children: [
                            ..._entryRows(context, entries, dim, palette),
                            if (hiddenCount > 0) ...[
                              _innerDivider(palette),
                              _proHistoryUpsellRow(
                                  context, hiddenCount, dim, palette),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _entryRows(
    BuildContext context,
    List<HistoryEntry> entries,
    Dimens dim,
    AppPalette palette,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) rows.add(_innerDivider(palette));
      rows.add(_entryRow(context, entries[i], i, dim, palette));
    }
    return rows;
  }

  /// One history row: the optional note (top), the expression over its
  /// "= result", and a footer with the saved date plus quiet edit-note/delete
  /// icon buttons. Tapping the card reloads the calc.
  Widget _entryRow(
    BuildContext context,
    HistoryEntry entry,
    int index,
    Dimens dim,
    AppPalette palette,
  ) {
    final exprTokens = LexicalAnalyzer.analyze(entry.expression);
    final resultTokens = LexicalAnalyzer.analyze(entry.result);
    final date = _formatTimestamp(entry.timestamp);
    return InkWell(
      key: ValueKey('history-entry-$index'),
      onTap: () => onSelect(entry),
      child: Container(
        constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
        // Comfortable, symmetric horizontal breathing room (the text was hugging
        // the card edges). The footer icon buttons carry their own inner padding,
        // so they still sit a touch off the right edge.
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 8),
        // The note (title) and date sit LEFT; the expression and result are
        // RIGHT-aligned like the main display (result = bold hero). Edit-note
        // and delete are quiet icon buttons in the footer row.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.note.isNotEmpty) ...[
              Text(
                entry.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: AppPalette.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text.rich(
              TextSpan(
                children:
                    tokensToSpans(exprTokens, fontSize: 20, palette: palette),
              ),
              style: TextStyle(color: palette.nums, fontSize: 20),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '= '),
                  ...tokensToSpans(resultTokens, fontSize: 22, palette: palette),
                ],
              ),
              style: TextStyle(
                color: palette.nums,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Footer: the saved date on the LEFT, the actions on the RIGHT.
            Row(
              children: [
                if (date.isNotEmpty)
                  Expanded(
                    child: Text(
                      date,
                      textAlign: TextAlign.start,
                      style: TextStyle(color: palette.controls, fontSize: 12),
                    ),
                  )
                else
                  const Spacer(),
                _miniAction(
                  Icons.content_copy,
                  'Copy',
                  () => _copyEntry(context, entry),
                  palette,
                ),
                _miniAction(
                  Icons.edit_outlined,
                  entry.note.isEmpty ? 'Add note' : 'Edit note',
                  () => _editNote(context, index, entry),
                  palette,
                ),
                _miniAction(
                  Icons.delete_outline,
                  'Delete',
                  () => _confirmDelete(context, index),
                  palette,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Copies the record's "expression = result" to the clipboard. On Android the
  /// OS shows its own "Copied" confirmation, so we skip our snackbar there (it
  /// would read as two toasts); on iOS/web/desktop we show our own. Where shown,
  /// any current toast is removed instantly so a repeat copy replaces it.
  void _copyEntry(BuildContext context, HistoryEntry entry) {
    Clipboard.setData(
      ClipboardData(text: '${entry.expression} = ${entry.result}'),
    );
    if (platformConfirmsCopy) return;
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

  /// Confirms before deleting a single history record (destructive, no undo).
  Future<void> _confirmDelete(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this calculation?'),
        content: const Text('It will be removed from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppPalette.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) HistoryService.instance.removeAt(index);
  }

  /// A quiet footer icon-button for a per-record action (edit note / delete) -
  /// replaces the dated overflow kebab with discoverable inline controls. The
  /// IconButton claims its own tap, so it never triggers the row's reload.
  Widget _miniAction(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    AppPalette palette,
  ) {
    return IconButton(
      icon: Icon(icon, size: 20, color: palette.controlsStrong.withAlpha(0xB3)),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }

  /// Prompts for the record's note (a short label) and stores it. The dialog is
  /// a [_NoteDialog] StatefulWidget so it owns its TextEditingController and
  /// disposes it only after the dialog is fully removed from the tree - disposing
  /// it inline right after `await showDialog` (while the dialog is still
  /// animating out) corrupts the live EditableText (the InheritedElement
  /// `_dependents.isEmpty` assertion).
  Future<void> _editNote(
    BuildContext context,
    int index,
    HistoryEntry entry,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _NoteDialog(initialNote: entry.note),
    );
    if (result != null) HistoryService.instance.setNote(index, result);
  }

  /// Compact absolute date+time for a saved record (e.g. "Jun 21, 14:30").
  /// Empty for a legacy entry with no timestamp.
  String _formatTimestamp(int millis) {
    if (millis <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hh:$mm';
  }

  /// Shown to a free (gated) user once the stored history exceeds
  /// [kFreeHistoryLimit]: a tappable row at the bottom of the list that opens
  /// the Pro paywall to reveal the full log. [hiddenCount] entries are kept in
  /// storage and reappear the instant Pro is unlocked.
  Widget _proHistoryUpsellRow(
    BuildContext context,
    int hiddenCount,
    Dimens dim,
    AppPalette palette,
  ) {
    return InkWell(
      key: const ValueKey('history-pro-upsell'),
      onTap: () => showProPaywall(context),
      child: Container(
        constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: palette.controlsStrong),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unlock Pro for unlimited history — $hiddenCount more saved',
                style: TextStyle(
                  color: palette.resultNums,
                  fontSize: dim.settingsItemTextSize,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: palette.controls),
          ],
        ),
      ),
    );
  }

  Widget _emptyHint(AppPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: palette.controls),
            const SizedBox(height: 12),
            Text(
              'No calculations yet.\nPress = to save one here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.controlsStrong,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A rounded tonal SECTION card (the Settings/Support idiom).
  Widget _section(
    Dimens dim,
    AppPalette palette, {
    required List<Widget> children,
  }) {
    return Material(
      color: palette.displayCardSurface,
      borderRadius: BorderRadius.circular(dim.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// Soft inset hairline between rows WITHIN a card.
  Widget _innerDivider(AppPalette palette) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      // controlsStrong adapts (dark line in light theme, light line in dark),
      // so the separator stays visible on the near-black dark card surface.
      color: palette.controlsStrong.withValues(alpha: 0.25),
    );
  }
}

/// The "Add/Edit note" dialog. A StatefulWidget so the TextEditingController is
/// disposed with the dialog (after its exit animation), not mid-flight. Returns
/// the entered text on Save, or null on Cancel.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initialNote});

  final String initialNote;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialNote.isEmpty ? 'Add note' : 'Edit note'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: 'e.g. Project A payroll'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Shared confirmation for clearing the history (used by the History overlay
/// and the Settings "Clear history" row). Clears only on explicit confirm.
Future<void> confirmClearHistory(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Clear history?'),
      content: const Text(
        'This removes all saved calculations. It cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) HistoryService.instance.clear();
}

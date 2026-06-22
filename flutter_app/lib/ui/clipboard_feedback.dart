import 'package:flutter/foundation.dart';

/// True when the host platform shows its OWN confirmation for a clipboard copy,
/// so the app must NOT also show a "Copied to clipboard" snackbar - otherwise
/// the two stack as a double toast.
///
/// Android (12L / 13+) pops a system clipboard preview on every write; iOS, web
/// and desktop give no such native feedback, so there the app's own snackbar is
/// the only confirmation and should be shown.
bool get platformConfirmsCopy =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

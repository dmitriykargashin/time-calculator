import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../config.dart';

/// "Share the app" (support screen button) - the original `shareTheApp()`:
/// a plain ACTION_SEND text/plain share of [shareAppText] (platform-aware:
/// Apple builds never share the Google Play link), with no subject and no
/// chooser title. Never throws.
Future<void> shareTheApp() async {
  try {
    await SharePlus.instance.share(ShareParams(text: shareAppText));
  } catch (e) {
    debugPrint('shareTheApp: share failed: $e');
  }
}

/// Plain-text share of an arbitrary [text] (e.g. a calculation result from the
/// result action menu). Never throws.
Future<void> shareText(String text) async {
  try {
    await SharePlus.instance.share(ShareParams(text: text));
  } catch (e) {
    debugPrint('shareText: share failed: $e');
  }
}

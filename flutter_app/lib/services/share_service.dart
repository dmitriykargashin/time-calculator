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

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'documentation_webview_support.dart';

/// Registers the platform WebView implementation when the embedder plugin
/// has not already done so (common in tests and some desktop builds).
void ensureDocumentationWebViewPlatform() {
  if (!isDocumentationWebViewSupported || WebViewPlatform.instance != null) {
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      WebViewPlatform.instance = AndroidWebViewPlatform();
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      WebViewPlatform.instance = WebKitWebViewPlatform();
    case TargetPlatform.linux:
    case TargetPlatform.windows:
    case TargetPlatform.fuchsia:
      break;
  }
}

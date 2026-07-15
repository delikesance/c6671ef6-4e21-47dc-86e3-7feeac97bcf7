import 'package:flutter/foundation.dart';

/// Whether the current platform can embed documentation in a [WebViewWidget].
bool get isDocumentationWebViewSupported {
  if (kIsWeb) {
    return false;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    case TargetPlatform.linux:
    case TargetPlatform.windows:
    case TargetPlatform.fuchsia:
      return false;
  }
}

import 'package:bot_creator/features/documentation/documentation_webview_support.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isDocumentationWebViewSupported is false on Linux desktop', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(isDocumentationWebViewSupported, isFalse);
  });
}

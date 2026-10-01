import 'dart:async';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:bot_creator/features/documentation/documentation_webview_support.dart';
import 'package:bot_creator/features/documentation/webview_platform_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Gesture recognizers forwarded to the documentation WebView platform view.
///
/// Required when the WebView lives inside scrollable parents (e.g. TabBarView)
/// so vertical scroll reaches the native web content on Android/iOS.
final Set<Factory<OneSequenceGestureRecognizer>>
documentationWebViewGestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
      Factory<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer(),
      ),
      Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
    };

/// Builds the documentation [WebViewWidget] with scroll-friendly layout.
Widget buildDocumentationWebViewWidget(WebViewController controller) {
  return SizedBox.expand(
    child: WebViewWidget(
      controller: controller,
      gestureRecognizers: documentationWebViewGestureRecognizers,
    ),
  );
}

/// In-app WebView for external documentation sites.
class WebDocumentationView extends StatefulWidget {
  const WebDocumentationView({
    super.key,
    required this.initialUrl,
    this.controller,
    this.showAppBar = false,
  });

  final String initialUrl;
  final WebViewController? controller;
  final bool showAppBar;

  @override
  State<WebDocumentationView> createState() => _WebDocumentationViewState();
}

class _WebDocumentationViewState extends State<WebDocumentationView> {
  WebViewController? _controller;
  final bool _webViewSupported = isDocumentationWebViewSupported;
  bool _loading = true;
  String? _error;
  bool _canGoBack = false;
  bool _acceptWebViewCallbacks = true;

  @override
  void dispose() {
    _acceptWebViewCallbacks = false;
    // Detach web content so Android WebChromeClient stops posting platform
    // messages after this State is torn down.
    if (widget.controller == null) {
      final controller = _controller;
      if (controller != null) {
        unawaited(controller.loadRequest(Uri.parse('about:blank')));
      }
    }
    super.dispose();
  }

  bool get _webViewCallbacksActive => _acceptWebViewCallbacks && mounted;

  @override
  void initState() {
    super.initState();
    if (!_webViewSupported) {
      _loading = false;
      return;
    }

    ensureDocumentationWebViewPlatform();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (!_webViewCallbacksActive) return;
              _setLoading(true);
            },
            onPageFinished: (_) async {
              if (!_webViewCallbacksActive) return;
              final controller = _controller;
              if (controller == null) return;
              final canGoBack = await controller.canGoBack();
              if (!_webViewCallbacksActive) return;
              setState(() {
                _loading = false;
                _error = null;
                _canGoBack = canGoBack;
              });
            },
            onWebResourceError: (error) {
              if (!_webViewCallbacksActive) return;
              setState(() {
                _loading = false;
                _error = error.description;
              });
            },
            onNavigationRequest: (request) {
              final uri = Uri.tryParse(request.url);
              if (uri == null || !isDocumentationHostAllowed(uri)) {
                openExternalUrl(uri ?? Uri.parse(request.url));
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.initialUrl));
    }
  }

  void _setLoading(bool loading) {
    if (!_webViewCallbacksActive) return;
    setState(() {
      _loading = loading;
      if (loading) {
        _error = null;
      }
    });
  }

  Future<void> _reload() async {
    if (_controller == null) {
      await _openExternally();
      return;
    }
    if (!_webViewCallbacksActive) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _controller!.reload();
  }

  Future<void> _openExternally() async {
    if (_controller != null) {
      final current = await _controller!.currentUrl();
      final url = current ?? widget.initialUrl;
      await openExternalUrl(Uri.parse(url));
      return;
    }
    await openExternalUrl(Uri.parse(widget.initialUrl));
  }

  Future<void> _goBack() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (await controller.canGoBack()) {
      await controller.goBack();
      final canGoBack = await controller.canGoBack();
      if (mounted) {
        setState(() => _canGoBack = canGoBack);
      }
    }
  }

  Widget _buildUnsupportedFallback(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.menu_book_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr.docs_webview_unavailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openExternally,
              icon: const AppIcon.fromMaterial(Icons.open_in_browser),
              label: Text(context.tr.docs_open_in_browser),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_webViewSupported || _controller == null) {
      final fallback = _buildUnsupportedFallback(context);
      if (!widget.showAppBar) {
        return fallback;
      }
      return Column(
        children: [
          Material(
            elevation: 1,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    tooltip: context.tr.docs_open_in_browser,
                    onPressed: _openExternally,
                    icon: const AppIcon.fromMaterial(Icons.open_in_browser),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: fallback),
        ],
      );
    }

    final controller = _controller!;
    final content = Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: buildDocumentationWebViewWidget(controller)),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null && !_loading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon.fromMaterial(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr.docs_webview_error,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_error!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const AppIcon.fromMaterial(Icons.refresh),
                        label: Text(context.tr.docs_reload),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openExternally,
                        icon: const AppIcon.fromMaterial(Icons.open_in_browser),
                        label: Text(context.tr.docs_open_in_browser),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (!widget.showAppBar) {
      return SizedBox.expand(child: content);
    }

    return Column(
      children: [
        Material(
          elevation: 1,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: _canGoBack ? _goBack : null,
                  icon: const AppIcon.fromMaterial(Icons.arrow_back),
                ),
                IconButton(
                  tooltip: context.tr.docs_reload,
                  onPressed: _reload,
                  icon: const AppIcon.fromMaterial(Icons.refresh),
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.tr.docs_open_in_browser,
                  onPressed: _openExternally,
                  icon: const AppIcon.fromMaterial(Icons.open_in_browser),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}

/// Creates a [WebViewController] preconfigured for documentation sites.
WebViewController? createDocumentationWebController(String initialUrl) {
  if (!isDocumentationWebViewSupported) {
    return null;
  }
  ensureDocumentationWebViewPlatform();
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null || !isDocumentationHostAllowed(uri)) {
            openExternalUrl(uri ?? Uri.parse(request.url));
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(Uri.parse(initialUrl));
  return controller;
}

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => _setLoading(true),
            onPageFinished: (_) async {
              final canGoBack = await _controller.canGoBack();
              if (mounted) {
                setState(() {
                  _loading = false;
                  _error = null;
                  _canGoBack = canGoBack;
                });
              }
            },
            onWebResourceError: (error) {
              if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _loading = loading;
      if (loading) {
        _error = null;
      }
    });
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _controller.reload();
  }

  Future<void> _openExternally() async {
    final current = await _controller.currentUrl();
    final url = current ?? widget.initialUrl;
    await openExternalUrl(Uri.parse(url));
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      final canGoBack = await _controller.canGoBack();
      if (mounted) {
        setState(() => _canGoBack = canGoBack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null && !_loading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
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
                        icon: const Icon(Icons.refresh),
                        label: Text(context.tr.docs_reload),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openExternally,
                        icon: const Icon(Icons.open_in_browser),
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
      return content;
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
                  icon: const Icon(Icons.arrow_back),
                ),
                IconButton(
                  tooltip: context.tr.docs_reload,
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.tr.docs_open_in_browser,
                  onPressed: _openExternally,
                  icon: const Icon(Icons.open_in_browser),
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
WebViewController createDocumentationWebController(String initialUrl) {
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

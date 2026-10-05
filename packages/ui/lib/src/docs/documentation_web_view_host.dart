import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/tr_extension.dart';
import '../widgets/app_icon.dart';
import '../utils/external_link.dart';

/// Page web intégrée de la documentation (discord.js, pages sans version
/// native). L'app y branche sa `WebView` ; sans elle (le Studio), la page
/// propose simplement de l'ouvrir dans le navigateur.
abstract final class DocumentationWebViewHost {
  static Widget Function(String url) builder = (url) => _OpenInBrowser(url);
}

class _OpenInBrowser extends StatelessWidget {
  const _OpenInBrowser(this.url);

  final String url;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: () => unawaited(openExternalUrl(Uri.parse(url))),
      icon: const AppIcon.fromMaterial(Icons.open_in_browser),
      label: Text(context.tr.docs_open_in_browser),
    ),
  );
}

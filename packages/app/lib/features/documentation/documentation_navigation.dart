import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/documentation/documentation_article_page.dart';
import 'package:bot_creator/features/documentation/documentation_hub_page.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:flutter/material.dart';

bool isDocumentationArticleUrl(Uri uri) =>
    uri.scheme == 'https' &&
    uri.host == 'bot-creator.fr' &&
    ([
          '/docs',
          '/blog',
          '/guides',
        ].contains(uri.path.replaceFirst(RegExp(r'/$'), '')) ||
        uri.path.startsWith('/docs/') ||
        RegExp(r'/\d{4}/\d{2}/\d{2}/').hasMatch(uri.path));

Future<bool> openAppLink(BuildContext context, Uri uri) async {
  if (!isDocumentationArticleUrl(uri)) return openExternalUrl(uri);
  final path = uri.path.replaceFirst(RegExp(r'/$'), '');
  if (['/docs', '/blog', '/guides'].contains(path)) {
    await openDocumentationHub(
      context,
      initialSection: path == '/docs'
          ? DocumentationSection.botCreatorDocs
          : DocumentationSection.guide,
    );
  } else {
    await openDocumentationArticle(
      context,
      url: uri.toString(),
      title: context.tr.docs_hub_title,
    );
  }
  return true;
}

Future<void> openDocumentationArticle(
  BuildContext context, {
  required String url,
  required String title,
}) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => DocumentationArticlePage(url: url, title: title),
    ),
  );
}

Future<void> openDocumentationHub(
  BuildContext context, {
  DocumentationSection initialSection = DocumentationSection.guide,
  bool showDiscordJsTab = false,
}) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => DocumentationHubPage(
        initialSection: initialSection,
        showDiscordJsTab: showDiscordJsTab,
      ),
    ),
  );
}

Future<void> openDocumentationHubForBot(
  BuildContext context, {
  required String? botId,
  DocumentationSection initialSection = DocumentationSection.guide,
}) async {
  var showDiscordJs = false;
  if (botId != null) {
    final engine = await getBotRuntimeEngine(botId);
    showDiscordJs = engine == runtimeEngineJavascript;
  }
  if (!context.mounted) {
    return;
  }
  await openDocumentationHub(
    context,
    initialSection: initialSection,
    showDiscordJsTab: showDiscordJs,
  );
}

import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/documentation/documentation_hub_page.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:flutter/material.dart';

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

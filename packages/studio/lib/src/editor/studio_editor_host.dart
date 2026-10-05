import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../screens/variables_page.dart';
import '../screens/workflows_page.dart';

/// [EditorHost] du Studio : tout passe par l'API du Manager.
///
/// Pas d'éditeur BDFD ni d'éditeur d'image pour l'instant : les champs
/// correspondants restent éditables en texte (`supportsBdfdEditor` = faux).
class StudioEditorHost extends EditorHost {
  const StudioEditorHost({required this.api, required this.bot});

  final StudioApi api;
  final StudioBot bot;

  @override
  Future<List<Map<String, dynamic>>> scopedVariableDefinitions(
    String botId,
  ) async => [
    for (final def in await api.scopedDefinitions(botId))
      {
        'key': def.key,
        'scope': def.scope,
        'valueType': def.valueType,
        'defaultValue': def.defaultValue,
      },
  ];

  @override
  Future<Map<String, dynamic>> globalVariables(String botId) =>
      api.globalVariables(botId);

  @override
  Future<List<Map<String, dynamic>>> workflows(String botId) async => [
    for (final w in await api.listWorkflows(botId))
      {
        'name': w.name,
        'workflowType': w.type,
        'executionMode': w.executionMode,
      },
  ];

  @override
  Future<List<Map<String, dynamic>>> appCommands(String botId) async => [
    for (final c in await api.listCommands(botId))
      {'name': c.name, 'folder': ''},
  ];

  @override
  bool get supportsBdfdEditor => true;

  @override
  Future<String?> editBdfdScript(
    BuildContext context, {
    required String initialCode,
    required String backend,
  }) => Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) =>
          BdfdEditorPage(initialCode: initialCode, bdfdBackend: backend),
    ),
  );

  @override
  bool get supportsJavascriptEditor => true;

  @override
  Future<String?> editJavascript(
    BuildContext context, {
    required String initialCode,
    required String title,
    required List<Object> snippets,
  }) => Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => JsEditorPage(
        initialCode: initialCode,
        title: title,
        snippets: snippets.cast<JsEditorSnippet>(),
      ),
    ),
  );

  @override
  Future<void> manageGlobalVariables(BuildContext context, String botId) =>
      _push(context, VariablesPage(api: api, bot: bot));

  @override
  Future<void> manageWorkflows(BuildContext context, String botId) =>
      _push(context, WorkflowsPage(api: api, bot: bot));

  Future<void> _push(BuildContext context, Widget page) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Scaffold(appBar: AppBar(), body: page),
        ),
      );
}

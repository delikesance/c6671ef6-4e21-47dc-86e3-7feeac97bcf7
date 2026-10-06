import 'package:bot_creator/core/bdfd_editor/bdfd_validation.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/global.variables.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflows.page.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// [EditorHost] de l'app : données locales (SQLite) ou, quand le bot tourne sur
/// un runtime distant (Manager / runner), celles du runtime.
class AppEditorHost extends EditorHost {
  const AppEditorHost();

  Future<ResolvedRemoteRuntime?> _remote(String botId) async {
    try {
      return await resolveRemoteRuntime(
        supportsManagerRuntime: !kIsWeb,
        botId: botId,
        getTimeout: const Duration(seconds: 4),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> scopedVariableDefinitions(
    String botId,
  ) async {
    final remote = await _remote(botId);
    try {
      if (remote != null &&
          remote.isManager &&
          remote.client is MainApiClient) {
        return await (remote.client as MainApiClient)
            .getScopedVariableDefinitions(botId);
      }
      if (remote != null && remote.isRunner && remote.client is RunnerClient) {
        return await (remote.client as RunnerClient)
            .getScopedVariableDefinitions(botId);
      }
    } catch (_) {
      // Repli sur SQLite local quand le runtime distant échoue ou expire.
    }
    return appManager.getScopedVariableDefinitions(botId);
  }

  @override
  Future<Map<String, dynamic>> globalVariables(String botId) async {
    final remote = await _remote(botId);
    try {
      if (remote != null &&
          remote.isManager &&
          remote.client is MainApiClient) {
        return await (remote.client as MainApiClient).getGlobalVariables(botId);
      }
      if (remote != null && remote.isRunner && remote.client is RunnerClient) {
        return await (remote.client as RunnerClient).getGlobalVariables(botId);
      }
    } catch (_) {
      // Repli sur SQLite local quand le runtime distant échoue ou expire.
    }
    return appManager.getGlobalVariables(botId);
  }

  @override
  Future<List<Map<String, dynamic>>> workflows(String botId) =>
      appManager.getWorkflows(botId);

  @override
  Future<List<Map<String, dynamic>>> appCommands(String botId) =>
      appManager.listAppCommands(botId);

  @override
  Future<void> manageGlobalVariables(BuildContext context, String botId) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GlobalVariablesPage(botId: botId),
        ),
      );

  @override
  Future<void> manageWorkflows(BuildContext context, String botId) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => WorkflowsPage(botId: botId)),
      );

  @override
  bool get supportsBdfdEditor => true;

  @override
  List<EditorDiagnostic> bdfdDiagnostics(String source, String backend) => [
    for (final d in bdfdDiagnosticsFor(source, backend: backend))
      EditorDiagnostic(
        message: d.message,
        isError: d.severity == BdfdCompileDiagnosticSeverity.error,
        line: d.line,
        column: d.column,
      ),
  ];

  @override
  Future<String?> editBdfdScript(
    BuildContext context, {
    required String initialCode,
    required String backend,
  }) => Navigator.push<String>(
    context,
    MaterialPageRoute<String>(
      builder: (_) =>
          BdfdEditorPage(initialCode: initialCode, bdfdBackend: backend),
    ),
  );

  @override
  Future<bool> isJavascriptBot(String botId) async =>
      isJavascriptRuntimeEngine(await getBotRuntimeEngine(botId));

  @override
  bool get supportsJavascriptEditor => true;

  @override
  Future<String?> editJavascript(
    BuildContext context, {
    required String initialCode,
    required String title,
    required List<Object> snippets,
  }) => Navigator.push<String>(
    context,
    MaterialPageRoute<String>(
      builder: (_) => JsEditorPage(
        initialCode: initialCode,
        title: title,
        snippets: snippets.cast<ScriptEditorSnippet>(),
      ),
    ),
  );

  @override
  bool get supportsImageEditor => true;

  @override
  Future<List<Map<String, dynamic>>?> editImageOperations(
    BuildContext context, {
    required List<Map<String, dynamic>> operations,
    required List<VariableSuggestion> variableSuggestions,
  }) => Navigator.push<List<Map<String, dynamic>>>(
    context,
    MaterialPageRoute<List<Map<String, dynamic>>>(
      builder: (_) => ImageEditorPage(
        operations: operations,
        variableSuggestions: variableSuggestions,
      ),
    ),
  );
}

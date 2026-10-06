// L'écran « Tester la commande » vit dans `bot_creator_ui` (le Studio affiche le
// même). Ce fichier n'en garde que l'adaptateur de l'app : le moteur de
// simulation tourne ICI, sur l'appareil, sans Discord ni données du bot.
library;

import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/function_suite.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

/// Where the app runs the simulation: the embedded Dart engine, on the device.
class AppSandboxHost extends ui.SandboxHost {
  const AppSandboxHost({this.runner});

  /// Test seam: replaces the engine entry point.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)? runner;

  @override
  Future<Map<String, dynamic>> runCommand(Map<String, dynamic> request) =>
      (runner ?? testCommandInSandbox)(request);

  /// The cases are static for a build: converted once, shared by every page.
  static final List<ui.SandboxFunctionCaseInfo> _cases = [
    for (final sample in sandboxFunctionCases)
      ui.SandboxFunctionCaseInfo.fromWire(sample.toJson()),
  ];

  @override
  List<ui.SandboxFunctionCaseInfo> get preloadedFunctionCases => _cases;

  @override
  Future<List<ui.SandboxFunctionCaseInfo>> loadFunctionCases() async => _cases;
}

/// Tests the editor's draft, without saving or registering a Discord command.
class CommandSandboxPage extends StatelessWidget {
  const CommandSandboxPage({
    super.key,
    this.script,
    this.bdfdBackend = 'native-v1',
    this.runner,
    this.editableScript = false,
    this.initialScenario = const {},
    this.expectedResponse,
    this.expectedValues = const {},
    this.actions,
    this.options = const [],
    this.definitions = const [],
  });
  final String? script;
  final String bdfdBackend;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)? runner;
  final bool editableScript;
  final Map<String, dynamic> initialScenario;
  final String? expectedResponse;
  final Map<String, dynamic> expectedValues;
  final List<Map<String, dynamic>>? actions;
  final List<Map<String, dynamic>> options;
  final List<Map<String, dynamic>> definitions;

  @override
  Widget build(BuildContext context) => ui.CommandSandboxPage(
    host: AppSandboxHost(runner: runner),
    script: script,
    bdfdBackend: bdfdBackend,
    editableScript: editableScript,
    initialScenario: initialScenario,
    expectedResponse: expectedResponse,
    expectedValues: expectedValues,
    actions: actions,
    options: options,
    definitions: definitions,
  );
}

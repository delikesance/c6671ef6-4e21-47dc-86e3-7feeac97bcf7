import 'dart:async';

import 'package:bot_creator/core/ui_hooks.dart';
import 'package:bot_creator/features/bot_editor/presentation/app_editor_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';

/// Les widgets d'édition partagés (`bot_creator_ui`) lisent leur hôte dans un
/// [EditorHostScope] ; les tests qui les montent seuls retombent sur celui de
/// l'app, comme en production.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  EditorHostScope.fallback = const AppEditorHost();
  bindUiPackageHooks();
  await testMain();
}

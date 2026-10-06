// Le laboratoire de fonctions vit dans `bot_creator_ui` (le Studio affiche le
// même). Ce fichier n'en garde que l'adaptateur de l'app : les cas de régression
// sont lus dans le moteur embarqué.
library;

import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

import 'command_sandbox_page.dart';

/// Every registered function is discoverable. Missing regression cases are
/// visible, and users can test their own source/fixtures for that function.
class SandboxFunctionsPage extends StatelessWidget {
  const SandboxFunctionsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const ui.SandboxFunctionsPage(host: AppSandboxHost());
}

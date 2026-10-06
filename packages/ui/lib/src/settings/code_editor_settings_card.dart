import 'package:flutter/material.dart';

import '../code/code_editor_settings_page.dart';
import '../l10n/tr_extension.dart';
import '../widgets/app_icon.dart';

/// Entrée des Paramètres qui ouvre la personnalisation de l'éditeur de code
/// (thème, police, indentation). Identique dans l'app et dans le Studio.
class CodeEditorSettingsCard extends StatelessWidget {
  const CodeEditorSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: AppIcon.fromMaterial(
          Icons.code_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(context.tr.code_editor_settings_title),
        subtitle: Text(context.tr.code_editor_settings_subtitle),
        trailing: const AppIcon.fromMaterial(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CodeEditorSettingsPage(),
          ),
        ),
      ),
    );
  }
}

import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../editor/studio_editor_host.dart';
import '../l10n_ext.dart';

/// Script (JavaScript ou BDFD) d'une commande ou d'un workflow : aperçu et
/// éditeur plein écran de l'app. Chaque langage a son éditeur (coloration,
/// snippets, diagnostics) : un script BDFD ne passe pas par celui du JavaScript.
class ScriptCard extends StatelessWidget {
  const ScriptCard({
    super.key,
    required this.api,
    required this.bot,
    required this.title,
    required this.code,
    required this.bdfd,
    required this.onChanged,
  });

  final StudioApi api;
  final StudioBot bot;

  /// Nom de la commande ou du workflow, affiché dans l'éditeur plein écran.
  final String title;
  final String code;
  final bool bdfd;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ScratchBlock(
      color: AppTheme.warning,
      icon: bdfd ? Icons.code : Icons.javascript,
      title: bdfd ? 'BDFD' : 'JavaScript',
      required: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 80),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.codeSurfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.grey),
              ),
              child: Text(
                code.trim().isEmpty ? '// …' : code,
                maxLines: 12,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<String>(
                  MaterialPageRoute<String>(
                    builder: (_) => EditorHostScope(
                      host: StudioEditorHost(api: api, bot: bot),
                      child: bdfd
                          ? BdfdEditorPage(initialCode: code, title: title)
                          : JsEditorPage(initialCode: code, title: title),
                    ),
                  ),
                );
                if (result != null) onChanged(result);
              },
              icon: const AppIcon.fromMaterial(Icons.edit_note, size: 18),
              label: Text(context.l10n.scriptEdit),
            ),
          ],
        ),
      ),
    );
  }
}

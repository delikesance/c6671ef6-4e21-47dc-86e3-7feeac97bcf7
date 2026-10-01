import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/home/logic/bot_start_target.dart';
import 'package:flutter/material.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Demande OÙ démarrer le bot, à chaque démarrage.
///
/// Pourquoi à chaque fois : les deux exécutions n'ont pas les mêmes conséquences —
/// en local c'est gratuit et le bot s'arrête avec l'application, sur le serveur
/// cela consomme des minutes d'hébergement (ou la formule) mais tourne sans le
/// poste. Mémoriser le choix ferait repartir un bot sur un chemin payant sans le
/// redire, donc la question est posée, pas devinée.
///
/// Une option impossible n'est pas proposée : sa raison est écrite à la place, en
/// une ligne. Proposer une porte qui échouerait se paierait plus tard, et ne rien
/// dire ferait chercher où elle est passée.
Future<BotStartTarget?> showBotStartTargetDialog(
  BuildContext context, {
  required String botName,
  required BotStartChoices choices,
}) {
  return showDialog<BotStartTarget>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.tr.bot_start_target_title(botName)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in choices.options) ...[
            _BotStartOptionTile(option: option),
            const SizedBox(height: 8),
          ],
          if (choices.serverUnavailableReason != null)
            _UnavailableReason(text: choices.serverUnavailableReason!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.tr.common_cancel),
        ),
      ],
    ),
  );
}

class _BotStartOptionTile extends StatelessWidget {
  const _BotStartOptionTile({required this.option});

  final BotStartOption option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isServer = option.target == BotStartTarget.server;
    return OutlinedButton(
      onPressed: () {
        // Trace du GESTE, AVANT de rendre la cible : c'est ce que l'utilisateur croit
        // avoir choisi. Sans cette ligne, un choix non honoré plus loin ne laisserait
        // aucune preuve de ce qui a été cliqué. Une ligne par tuile, texte distinct.
        appendBotStartTrace(
          isServer ? 'clic=serveurs Bot Creator' : 'clic=ce poste',
        );
        Navigator.of(context).pop(option.target);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(14),
        alignment: Alignment.centerLeft,
        minimumSize: const Size(0, 0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.fromMaterial(
            isServer ? Icons.cloud_outlined : Icons.computer_outlined,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pourquoi l'option « sur le serveur » n'est pas proposée (une ligne, pas un bouton).
class _UnavailableReason extends StatelessWidget {
  const _UnavailableReason({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon.fromMaterial(
          Icons.cloud_off_outlined,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

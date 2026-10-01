import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:flutter/material.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Ligne affichée à la place de l'action d'achat quand une capacité PREMIUM manque
/// à cause de la FORMULE DU COMPTE sur une plateforme sans boutique native.
///
/// Pourquoi une brique unique plutôt que quatre textes : les quatre pages qui
/// verrouillent une capacité (Scheduler, Inbound webhooks, analytique du tableau
/// de bord, rejeu de debug) racontaient chacune autre chose, et deux d'entre elles
/// affichaient « Not available on this platform. » dès que la boutique native était
/// absente — c'est-à-dire sur un poste de travail. Cette phrase parle de la FONCTION
/// alors qu'elle ne décrit que l'ACHAT : un poste de travail lisait donc « le
/// scheduler n'existe pas ici » alors que son compte est simplement en formule
/// gratuite, et la page ne proposait plus AUCUNE action.
///
/// La cause réelle du verrou est toujours la même (la formule du compte, une vérité
/// serveur), et l'endroit où l'abonnement s'active ne dépend que de la plateforme :
/// une phrase, un style, un seul endroit à corriger.
class PremiumLockedHint extends StatelessWidget {
  const PremiumLockedHint({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon.fromMaterial(
          Icons.lock_outline_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.tr.premium_locked_hint,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

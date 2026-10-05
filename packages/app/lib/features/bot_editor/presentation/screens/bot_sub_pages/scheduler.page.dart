import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_feature_gate.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:bot_creator/features/subscriptions/presentation/widgets/premium_locked_hint.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

/// Planificateur d'un bot : l'écran vit dans `bot_creator_ui` (partagé avec le
/// Studio) ; l'app lui donne ses données locales et ses règles de forfait.
class SchedulerPage extends StatelessWidget {
  const SchedulerPage({super.key, required this.botId});

  final String botId;

  @override
  Widget build(BuildContext context) =>
      SchedulerView(controller: _AppSchedulerController(botId));
}

class _AppSchedulerController extends SchedulerController {
  const _AppSchedulerController(this.botId);

  final String botId;

  @override
  Future<List<Map<String, dynamic>>> triggers() =>
      appManager.getScheduledTriggers(botId);

  @override
  Future<List<Map<String, dynamic>>> workflows() =>
      appManager.getWorkflows(botId);

  @override
  Future<void> save({
    required String workflowName,
    required int everyMinutes,
    required bool enabled,
    String? triggerId,
    String? label,
  }) => appManager.saveScheduledTrigger(
    botId,
    workflowName: workflowName,
    everyMinutes: everyMinutes,
    enabled: enabled,
    triggerId: triggerId,
    label: label,
  );

  @override
  Future<void> delete(String triggerId) =>
      appManager.deleteScheduledTrigger(botId, triggerId);

  /// La capacité dépend de l'ENDROIT où le bot tourne, pas de l'OS : sur un
  /// poste de travail avec un bot local, les déclencheurs s'exécutent chez
  /// l'utilisateur, donc ils sont ouverts sans abonnement.
  @override
  bool get hasCapability => premiumCapabilityAvailableForBot(
    PremiumCapability.schedulerTriggers,
    botId: botId,
  );

  @override
  int get limit =>
      PremiumCapabilities.limitFor(PremiumCapability.schedulerTriggers);

  @override
  Widget? upsell(BuildContext context, Future<void> Function() reload) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ModuleUpsellCard(
        title: context.tr.subscription_feature_scheduler_title,
        description: context.tr.subscription_feature_scheduler_desc,
        action: PremiumCapabilities.canShowPurchaseUI
            ? FilledButton.icon(
                onPressed: () async {
                  await SubscriptionPage.show(context);
                  await reload();
                },
                icon: const AppIcon.fromMaterial(
                  Icons.workspace_premium_rounded,
                ),
                label: Text(context.tr.premium_card_button),
              )
            // Verrou de FORMULE, pas de plateforme (voir PremiumLockedHint).
            : const PremiumLockedHint(),
      ),
    );
  }
}

import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:bot_creator/features/subscriptions/presentation/widgets/premium_locked_hint.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

/// Webhooks entrants d'un bot : l'écran vit dans `bot_creator_ui` (partagé avec
/// le Studio) ; l'app lui donne ses données locales, le runner et ses règles de
/// forfait.
class InboundWebhooksPage extends StatelessWidget {
  const InboundWebhooksPage({super.key, required this.botId});

  final String botId;

  @override
  Widget build(BuildContext context) =>
      InboundWebhooksView(controller: _AppInboundWebhooksController(botId));
}

class _AppInboundWebhooksController extends InboundWebhooksController {
  const _AppInboundWebhooksController(this.botId);

  final String botId;

  @override
  Future<List<Map<String, dynamic>>> webhooks() =>
      appManager.getInboundWebhooks(botId);

  @override
  Future<List<Map<String, dynamic>>> workflows() =>
      appManager.getWorkflows(botId);

  @override
  Future<String?> save({
    required String path,
    required String workflowName,
    required String? secret,
    required bool enabled,
    String? webhookId,
  }) async {
    await appManager.saveInboundWebhook(
      botId,
      path: path,
      workflowName: workflowName,
      secret: secret ?? '',
      enabled: enabled,
      webhookId: webhookId,
    );
    return null;
  }

  @override
  Future<void> delete(String webhookId) =>
      appManager.deleteInboundWebhook(botId, webhookId);

  @override
  Future<String?> fullUrl(Map<String, dynamic> webhook) async {
    final normalizedBase = ((await RunnerSettings.getUrl()) ?? '').trim();
    final path = (webhook['path'] ?? '').toString().trim();
    final secret = (webhook['secret'] ?? '').toString().trim();
    if (normalizedBase.isEmpty || path.isEmpty || secret.isEmpty) return null;
    try {
      final baseUri = Uri.parse(normalizedBase);
      return baseUri
          .replace(
            pathSegments: [
              ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
              'bots',
              botId,
              'inbound',
              ...path.split('/').where((segment) => segment.trim().isNotEmpty),
            ],
            queryParameters: <String, String>{'secret': secret},
          )
          .toString();
    } catch (_) {
      return null;
    }
  }

  @override
  bool get hasCapability =>
      PremiumCapabilities.hasCapability(PremiumCapability.inboundWebhooks);

  @override
  int get limit =>
      PremiumCapabilities.limitFor(PremiumCapability.inboundWebhooks);

  @override
  Widget? upsell(BuildContext context, Future<void> Function() reload) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ModuleUpsellCard(
        title: context.tr.subscription_feature_webhooks_title,
        description: context.tr.subscription_feature_webhooks_desc,
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

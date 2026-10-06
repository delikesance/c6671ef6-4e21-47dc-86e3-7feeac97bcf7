import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../auth/studio_session.dart';
import '../l10n_ext.dart';
import '../premium/premium_gate.dart';
import '../premium/studio_feature.dart';
import '../theme.dart';

/// Le rejeu du débogueur tel que le Studio le lit : par l'API du Manager, qui
/// relaie vers le runner du bot (`/gateway/bots/{id}/debug-replays`). L'écran
/// (`DebugReplayPage`) est celui de l'app.
///
/// Le Studio n'exécute rien lui-même : aucune mémoire locale (les valeurs par
/// défaut de l'hôte). La formule est celle du compte ; le Manager l'applique
/// aussi (réponse refusée hors premium), l'écran ne l'interroge donc pas sur un
/// compte gratuit.
class StudioDebugReplayHost extends DebugReplayHost {
  const StudioDebugReplayHost(this.api, {required this.plan});

  final StudioApi api;
  final StudioPlan plan;

  @override
  bool hasCapability(String? botId) =>
      StudioFeature.debugReplay.isAvailableFor(plan);

  /// Le Studio n'a aucun moyen d'achat : il dit où l'abonnement s'active (même
  /// mention que les autres fonctions premium).
  @override
  Widget buildUpgradeAction(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: AppIcon.fromMaterial(
              Icons.lock_outline_rounded,
              size: 16,
              color: StudioColors.muted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.premiumHint,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: StudioColors.muted,
              ),
            ),
          ),
        ],
      ),
      const PremiumViewPlansButton(),
    ],
  );

  @override
  Future<DebugReplaySnapshot?> fetchReplays(
    String botId, {
    int limit = 30,
  }) async {
    // Compte gratuit : pas de requête, le Manager répondrait « premium requis ».
    if (!hasCapability(botId)) return null;
    return DebugReplaySnapshot.fromWire(
      await api.debugReplaysWire(botId, limit: limit),
    );
  }

  @override
  Future<void> clearReplays(String botId) => api.clearDebugReplays(botId);

  @override
  Future<bool> setCapturing(String botId, bool enabled) =>
      api.setDebugReplayCapturing(botId, enabled);
}

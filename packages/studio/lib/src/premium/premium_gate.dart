import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../auth/studio_session.dart';
import '../l10n_ext.dart';
import '../theme.dart';
import 'studio_feature.dart';

/// Affiche [child] si [plan] donne accès à [feature], sinon la carte de
/// verrouillage (équivalent du `ModuleUpsellCard` de l'app, sans bouton
/// d'achat : le Studio renvoie vers l'app).
class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.feature,
    required this.plan,
    required this.child,
  });

  final StudioFeature feature;
  final StudioPlan plan;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (feature.isAvailableFor(plan)) return child;
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: PremiumLockedCard(feature: feature),
      ),
    );
  }
}

class PremiumLockedCard extends StatelessWidget {
  const PremiumLockedCard({super.key, required this.feature});

  final StudioFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudioColors.containerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudioColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon.fromMaterial(
                Icons.workspace_premium_rounded,
                color: StudioColors.premiumGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature.title(context.l10n),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feature.description(context.l10n),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: StudioColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: AppIcon.fromMaterial(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: StudioColors.muted,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.premiumHint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: StudioColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

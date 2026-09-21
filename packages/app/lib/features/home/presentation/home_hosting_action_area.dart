import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/home/logic/hosting_time_offer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bas de la carte « temps total » d'hébergement : ce que l'écran a le DROIT
/// d'offrir à l'utilisateur.
///
/// Trois rendus, une seule décision ([HostingTimeOffer]) :
///   * [HostingTimeOffer.addTime] — le bouton « Ajouter du temps ». Mobile non
///     abonné seulement : c'est là que se regarde une pub récompensée ;
///   * [HostingTimeOffer.adsOnMobileOnly] — une LIGNE d'explication. Sur un poste
///     de travail, le bouton promettait un geste impossible (le flux
///     publicitaire ne fait rien hors mobile) ; on l'explique au lieu de l'offrir ;
///   * [HostingTimeOffer.unlimited] — rien. Un abonné n'a ni pub à regarder, ni
///     temps à obtenir : l'état « illimité » est porté par le surtitre et la
///     valeur de la carte, donc aucune action n'est rendue ici.
class HomeHostingActionArea extends StatelessWidget {
  const HomeHostingActionArea({
    super.key,
    required this.offer,
    this.onAddTime,
    this.isAddingTime = false,
  });

  final HostingTimeOffer offer;

  /// Action « ajouter du temps » ; ignorée par les offres qui n'ont pas de geste
  /// à proposer (poste de travail, abonné).
  final VoidCallback? onAddTime;

  final bool isAddingTime;

  @override
  Widget build(BuildContext context) {
    return switch (offer) {
      HostingTimeOffer.unlimited => const SizedBox.shrink(),
      HostingTimeOffer.adsOnMobileOnly => const Padding(
        padding: EdgeInsets.only(top: 16),
        child: _MobileAdsExplanation(),
      ),
      HostingTimeOffer.addTime => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: _AddTimeButton(
          onAddTime: onAddTime,
          isAddingTime: isAddingTime,
        ),
      ),
    };
  }
}

/// Explication affichée à la place du bouton sur un poste de travail.
///
/// Le temps crédité par une pub reste valable sur toutes les plateformes : c'est
/// le GESTE qui est mobile, pas la récompense. Le dire évite de laisser croire
/// que le temps gagné ailleurs serait perdu.
class _MobileAdsExplanation extends StatelessWidget {
  const _MobileAdsExplanation();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? scheme.onSurfaceVariant
        : scheme.onSurfaceVariant.withValues(alpha: 0.9);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.tr.home_add_time_mobile_only,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton historique d'ajout de temps — mobile non abonné uniquement.
class _AddTimeButton extends StatelessWidget {
  const _AddTimeButton({required this.onAddTime, required this.isAddingTime});

  final VoidCallback? onAddTime;
  final bool isAddingTime;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: (onAddTime == null || isAddingTime) ? null : onAddTime,
        icon: isAddingTime
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded, size: 18),
        label: Text(context.tr.home_add_time),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm + 6),
          ),
        ),
      ),
    );
  }
}

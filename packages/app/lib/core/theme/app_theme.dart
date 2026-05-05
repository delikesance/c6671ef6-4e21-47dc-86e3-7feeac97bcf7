import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Bot Creator — Design System & Charte Graphique
// ═══════════════════════════════════════════════════════════════════════════════
//
// Ce fichier est la source unique de vérité pour tous les tokens visuels de
// l'application. Aucune couleur, rayon, espacement ou style typographique ne
// doit être défini en dur dans les widgets. Référencer ce fichier à la place.
//
// Usage :
//   import 'package:bot_creator/core/theme/app_theme.dart';
//   AppTheme.brandPrimary
//   AppTheme.spacingLg
//   AppTheme.lightTheme()
//
// ═══════════════════════════════════════════════════════════════════════════════

abstract final class AppTheme {
  // ─── Couleurs de marque ──────────────────────────────────────────────────

  /// Violet foncé — couleur principale de la marque Bot Creator.
  static const brandPrimary = Color(0xFF6A0FA2);

  /// Violet vif — couleur secondaire pour les gradients.
  static const brandSecondary = Color(0xFF9B30FF);

  /// Gradient standard de la marque (AppBar, FAB, éléments de marque).
  static const brandGradient = LinearGradient(
    colors: [brandPrimary, brandSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Couleurs neutres ──────────────────────────────────────────────────

  /// Gris neutre pour bordures, icônes désactivées, textes secondaires.
  static const grey = Color(0xFF9E9E9E);

  // ─── Couleurs sémantiques ───────────────────────────────────────────────

  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFF4CAF50);
  static const successAccent = Color(0xFF69F0AE); // greenAccent.shade200

  static const error = Color(0xFFE53935);
  static const errorLight = Color(0xFFEF5350);

  static const warning = Color(0xFFFFA726);

  /// Or premium — pour les éléments liés aux abonnements pro.
  static const premiumGold = Colors.amber;

  static const info = Color(0xFF1976D2);

  /// Bleu Discord « blurple » — pour les éléments liés à Discord.
  static const discord = Color(0xFF5865F2);

  /// Variant clair du blurple Discord.
  static const discordLight = Color(0xFF7983F5);

  /// Palette Discord dark-mode (embeds, previews).
  static const discordDarkBg = Color(0xFF2B2D31);
  static const discordDarkerBg = Color(0xFF1E1F22);
  static const discordBorder = Color(0xFF404249);
  static const discordText = Color(0xFFB5BAC1);

  /// Couleur syntaxe : orange pour mots-clés / avertissements dans BDFD.
  static const syntaxOrange = Color(0xFFFF9800);

  /// Couleur syntaxe : rouge clair pour erreurs.
  static const syntaxRed = Color(0xFFEF5350);

  /// Couleur syntaxe : cyan pour types / infos BDFD.
  static const syntaxCyan = Color(0xFF00ACC1);

  /// Couleur syntaxe : gris clair pour texte secondaire / bordures.
  static const syntaxGrey = Color(0xFFE0E0E0);

  // ─── Surfaces sombres (BotCard, éditeurs de code) ───────────────────────

  static const darkSurface = Color(0xFF2C2C3A);
  static const darkSurfaceVariant = Color(0xFF3A3A4A);

  static const codeSurface = Color(0xFF1E1E1E);
  static const codeSurfaceVariant = Color(0xFF263238);

  /// Background Darcula (éditeurs de code avancés).
  static const codeSurfaceDarcula = Color(0xFF2B2B2B);

  // ─── BotCard gradients ──────────────────────────────────────────────────

  static const botCardOnlineGradient = [Color(0xFF1B5E20), Color(0xFF2E7D32)];
  static const botCardOfflineGradient = [darkSurface, darkSurfaceVariant];

  // ─── Espacement ─────────────────────────────────────────────────────────

  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 20.0;
  static const spacingXxl = 24.0;

  // ─── Rayons de bordure ──────────────────────────────────────────────────

  /// Micro éléments : indicateurs, petits détails.
  static const radiusXs = 4.0;

  /// Petits éléments : badges, tags, chips.
  static const radiusSm = 8.0;

  /// Cartes, boutons, champs de saisie, blocs.
  static const radiusMd = 12.0;

  /// Modals, grandes cartes, onboarding cards.
  static const radiusLg = 16.0;

  /// Pills, badges de statut, capsules.
  static const radiusPill = 999.0;

  // ─── Formes réutilisables ───────────────────────────────────────────────

  static final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radiusMd),
  );

  static final dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radiusLg),
  );

  static final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radiusMd),
  );

  // ─── Breakpoints ────────────────────────────────────────────────────────

  /// Petit téléphone : breakpoint largeur < 420.
  static const smallPhoneWidth = 420.0;

  /// Téléphone : breakpoint largeur < 600.
  static const compactWidth = 600.0;

  /// Tablette : breakpoint largeur 600–899.
  static const mediumWidth = 900.0;

  /// Desktop : breakpoint largeur ≥ 1200.
  static const expandedWidth = 1200.0;

  /// Vrai si la largeur d'écran est < [smallPhoneWidth].
  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < smallPhoneWidth;

  /// Vrai si la largeur d'écran est < [compactWidth].
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidth;

  /// Vrai si la largeur d'écran est ≥ [mediumWidth].
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mediumWidth;

  // ─── Élévation ──────────────────────────────────────────────────────────

  static const elevationNone = 0.0;
  static const elevationLow = 1.0;
  static const elevationMedium = 3.0;
  static const elevationHigh = 6.0;

  // ─── Typographie (compléments au thème M3) ──────────────────────────────

  static const fontWeightSemiBold = FontWeight.w600;
  static const fontWeightBold = FontWeight.w700;

  // ─── Opacités standard ──────────────────────────────────────────────────

  static const opacityDisabled = 0.38;
  static const opacitySubtle = 0.10;
  static const opacityOverlay = 0.15;
  static const opacitySecondaryText = 0.60;
  static const opacityPrimaryText = 0.90;

  // ─── Durées d'animation ─────────────────────────────────────────────────

  static const animFast = Duration(milliseconds: 200);
  static const animNormal = Duration(milliseconds: 300);

  // ═══════════════════════════════════════════════════════════════════════════
  // ThemeData — thèmes Light & Dark
  // ═══════════════════════════════════════════════════════════════════════════

  /// Thème clair Material 3 avec seed color brand.
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(seedColor: brandPrimary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // ── Cards ──
      cardTheme: CardThemeData(
        shape: cardShape,
        elevation: elevationMedium,
        clipBehavior: Clip.antiAlias,
      ),
      // ── Dialogs ──
      dialogTheme: DialogThemeData(shape: dialogShape),
      // ── Bottom Sheets ──
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
      // ── Filled Buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
        ),
      ),
      // ── Text Buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape),
      ),
      // ── Elevated Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
        ),
      ),
      // ── Outlined Buttons ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: buttonShape),
      ),
      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        isDense: true,
      ),
      // ── Chips ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      // ── Snack Bars ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    );
  }

  /// Thème sombre Material 3 avec seed color brand.
  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // ── Cards ──
      cardTheme: CardThemeData(
        shape: cardShape,
        elevation: elevationMedium,
        clipBehavior: Clip.antiAlias,
      ),
      // ── Dialogs ──
      dialogTheme: DialogThemeData(shape: dialogShape),
      // ── Bottom Sheets ──
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
      // ── Filled Buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
        ),
      ),
      // ── Text Buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape),
      ),
      // ── Elevated Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
        ),
      ),
      // ── Outlined Buttons ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: buttonShape),
      ),
      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        isDense: true,
      ),
      // ── Chips ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      // ── Snack Bars ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dialog & Bottom Sheet helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Affiche un dialog de confirmation avec deux boutons (annuler / confirmer).
  ///
  /// Si [isDestructive] est vrai, le bouton confirmer est rouge.
  /// Retourne `true` si confirmé, `false` sinon.
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = isDestructive ? scheme.error : brandPrimary;
    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: dialogShape,
            icon: Icon(
              icon ??
                  (isDestructive
                      ? Icons.warning_amber_rounded
                      : Icons.help_outline_rounded),
              color: accentColor,
              size: 32,
            ),
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(
              spacingLg,
              0,
              spacingLg,
              spacingLg,
            ),
            actionsOverflowButtonSpacing: spacingSm,
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: spacingLg,
                    vertical: spacingMd,
                  ),
                  shape: buttonShape,
                ),
                child: Text(
                  cancelLabel ??
                      MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              if (isDestructive)
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: spacingLg,
                      vertical: spacingMd,
                    ),
                    shape: buttonShape,
                  ),
                  child: Text(confirmLabel),
                )
              else
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: spacingLg,
                      vertical: spacingMd,
                    ),
                    shape: buttonShape,
                  ),
                  child: Text(confirmLabel),
                ),
            ],
          ),
    );
    return result ?? false;
  }

  /// Affiche un bottom sheet (mobile) ou un dialog (desktop) selon la largeur.
  ///
  /// Le [builder] reçoit le `BuildContext` du sheet/dialog.
  static Future<T?> showAdaptiveSheet<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext) builder,
    double dialogWidth = 520,
  }) {
    if (isCompact(context)) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder:
            (sheetContext) => Padding(
              padding: const EdgeInsets.fromLTRB(
                spacingLg,
                0,
                spacingLg,
                spacingLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: spacingMd),
                  Flexible(child: builder(sheetContext)),
                ],
              ),
            ),
      );
    }

    return showDialog<T>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: dialogShape,
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: dialogWidth,
              child: builder(dialogContext),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding: const EdgeInsets.fromLTRB(
              spacingLg,
              0,
              spacingLg,
              spacingMd,
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: spacingXl,
                    vertical: spacingMd,
                  ),
                  shape: buttonShape,
                ),
                child: Text(
                  MaterialLocalizations.of(dialogContext).closeButtonTooltip,
                ),
              ),
            ],
          ),
    );
  }

  // ─── Widget helpers ─────────────────────────────────────────────────────

  /// Construit un badge pill (capsule) avec texte et point coloré.
  static Widget statusPill({
    required String label,
    required Color dotColor,
    Color? backgroundColor,
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            backgroundColor ?? Colors.white.withValues(alpha: opacityOverlay),
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: opacityPrimaryText),
              fontSize: 10,
              fontWeight: fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un AppBar avec le gradient de marque.
  static PreferredSizeWidget brandAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      bottom: bottom,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: brandGradient),
      ),
    );
  }
}

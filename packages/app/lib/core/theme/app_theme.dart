import 'package:flutter/material.dart';

import 'app_appearance.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';
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

  /// Violet clair lisible en texte/icône sur fond sombre (refonte home).
  static const brandPurpleSoft = Color(0xFFB19DF7);

  /// Gradient violet signature de la marque Bot Creator.
  static const brandGradient = LinearGradient(
    colors: [brandPrimary, brandSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Graine neutre ───────────────────────────────────────────────────────

  /// Graine des `ColorScheme` : graphite sombre désaturé.
  ///
  /// Un seed `tonalSpot` (variante M3 par défaut) **ré-injecte** de la chroma
  /// sur la teinte du seed : même une graine grise ressort saturée (bleu/teal),
  /// et l'ancienne graine violette teintait *tous* les rôles dérivés
  /// (`primaryContainer`, `secondary`, `tertiary`, `surfaceTint`, les rôles
  /// `surfaceContainer*` non surchargés…), d'où l'aspect « lavande » de l'app.
  /// On combine donc deux leviers : une graine graphite + la variante
  /// [DynamicSchemeVariant.neutral] (chroma ≈ 6), qui produit des gris/graphites
  /// de même *ton* M3 — donc de même luminance, à teinte près — que la palette
  /// violette précédente : les contrastes WCAG sont préservés (voir darkTheme).
  static const neutralSeed = Color(0xFF33343B);

  // ─── Surfaces neutres (graphite) ─────────────────────────────────────────
  // Valeurs obtenues en conservant la *luminance relative* de chaque ancienne
  // teinte violette (donc les ratios de contraste) en annulant sa saturation.

  /// Fond scaffold sombre de la refonte (graphite neutre ; ex-Figma #111117).
  static const scaffoldDark = Color(0xFF111111);

  /// Surface des cartes home (graphite neutre ; ex-Figma #1F1A2D).
  static const homeCard = Color(0xFF1D1D1D);

  /// Bordure des cartes home (graphite neutre ; ex-Figma #2C2540).
  static const homeCardBorder = Color(0xFF292929);

  /// Fond de la barre d'onglets flottante (graphite neutre ; ex-Figma #120F1C).
  ///
  /// Une unité plus sombre que [scaffoldDark] (même famille de luminance) pour
  /// rester une signature de couleur unique : les tests de navigation
  /// identifient la barre flottante par `BoxDecoration.color == homeNavBar`.
  static const homeNavBar = Color(0xFF101010);

  /// Fond de l'onglet sélectionné (graphite neutre ; ex-Figma #2A2140).
  static const homeNavSelected = Color(0xFF262626);

  /// CTA « créer un bot » (fond + avatar).
  static const homeCreateFill = homeNavSelected;

  /// Bordure dashed / pastille du CTA créer.
  ///
  /// Graphite de même luminance que l'ancienne lavande [brandPurpleSoft] :
  /// le violet n'est plus un remplissage, seulement un accent (sélection +
  /// action principale).
  static const homeCreateBorder = Color(0xFFAAAAAA);

  /// Fond du bloc serveurs dans une carte bot (graphite neutre ; ex #151226).
  static const homeClusterBg = Color(0xFF151515);

  /// Bordure du bloc serveurs (graphite neutre ; ex #2B264D).
  static const homeClusterBorder = Color(0xFF2B2B2B);

  /// Fond le plus bas de la refonte (rôle M3 surfaceContainerLowest, graphite
  /// neutre ; ex-Figma #0C0B12).
  static const homeContainerLowest = Color(0xFF0C0C0C);

  /// Bordure des boutons ghost (Manage / Add time) — graphite neutre (#333333).
  static const homeGhostBorder = Color(0xFF333333);

  /// Texte secondaire home (graphite neutre de même luminance que #8A84A3).
  static const homeMuted = Color(0xFF888888);

  /// Gris moyen pour métadonnées (WCAG-friendly sur fond sombre).
  static const metaText = homeMuted;

  /// Accent pastel pour données dynamiques (compteurs, badges).
  static const dataAccent = Color(0xFFDCF0FF);

  /// Vert « en ligne » de la refonte (Figma #10B981).
  static const online = Color(0xFF10B981);

  /// Rouge danger / arrêt de la refonte (Figma #FF4D4D).
  static const danger = Color(0xFFFF4D4D);

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

  /// Couleur syntaxe : cyan pour types / infos BDFD.
  static const syntaxCyan = Color(0xFF00ACC1);

  /// Couleur syntaxe : gris clair pour texte secondaire / bordures.
  static const syntaxGrey = Color(0xFFE0E0E0);

  // ─── Surfaces sombres (BotCard, éditeurs de code) ───────────────────────

  /// Surface sombre neutre (graphite de même luminance que l'ancien #2C2C3A).
  static const darkSurface = Color(0xFF2D2D2D);

  static const codeSurface = Color(0xFF1E1E1E);
  static const codeSurfaceVariant = Color(0xFF263238);

  /// Background Darcula (éditeurs de code avancés).
  static const codeSurfaceDarcula = Color(0xFF2B2B2B);

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

  /// Cartes home refonte (collapsible bot cards, turnkey).
  static const radiusCard = 24.0;

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

  /// Refonte home : bascule layout desktop (2 colonnes, FAB masqué, header create).
  static const desktopBreakpoint = 720.0;

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
  static const elevationMedium = 3.0;

  // ─── Typographie (compléments au thème M3) ──────────────────────────────

  static const fontWeightSemiBold = FontWeight.w600;
  static const fontWeightBold = FontWeight.w700;

  // ─── Durées d'animation ─────────────────────────────────────────────────

  static const animFast = Duration(milliseconds: 200);
  static const animNormal = Duration(milliseconds: 300);

  // ═══════════════════════════════════════════════════════════════════════════
  // ThemeData — thèmes Light & Dark
  // ═══════════════════════════════════════════════════════════════════════════

  /// Thème clair Material 3, dérivé de la graine graphite (ou du preset choisi
  /// via [AppAppearanceConfig]).
  ///
  /// L'AppBar reste NEUTRE (`surface` + `onSurface`), comme dans les apps
  /// Material 3 : une barre pleine couleur de marque faisait « ancienne
  /// colorisation » et écrasait toute la page de couleur en thème clair.
  ///
  /// Le violet n'y revient que par l'ACCENT d'action ([HomeTokens.accent]) :
  /// boutons principaux, anneaux de focus, états actifs. Sans argument, le
  /// rendu reste celui du défaut historique à cet accent près.
  static ThemeData lightTheme({AppAppearanceConfig? appearance}) {
    final config = appearance ?? AppAppearanceConfig.defaults;
    final preset = config.preset;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: config.seedColor,
      dynamicSchemeVariant: preset.variant,
      contrastLevel: preset.contrastLevel,
    );
    final tokens = _tokensFor(colorScheme, config);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actionsIconTheme: const IconThemeData(size: 20),
        iconTheme: const IconThemeData(size: 20),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        elevation: elevationNone,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
      ),
      // ── List Tiles ──
      // style=list prevents ListTile's own background from conflicting with
      // parent DecoratedBox widgets that provide a background color.
      listTileTheme: const ListTileThemeData(style: ListTileStyle.list),
      // ── Dialogs ──
      dialogTheme: DialogThemeData(shape: dialogShape),
      // ── Bottom Sheets ──
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
      // ── Filled Buttons ──
      // Action principale : c'est LE rôle de l'accent coloré (violet de marque
      // par défaut). Le premier plan suit le contraste calculé
      // (`HomeTokens.onAccent`) et non un blanc systématique — un accent clair
      // (ambre, cyan) exige un texte sombre pour rester lisible.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
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
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingLg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        // Anneau de focus : variante d'accent garantie ≥ 3:1 sur les surfaces
        // du thème (`HomeTokens.accentRing`), y compris sur les fonds clairs.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: tokens.accentRing, width: 2),
        ),
        isDense: false,
      ),
      // ── Accent d'action (le violet, et seulement là) ──────────────────────
      // Décision produit verrouillée par `test/theme_no_purple_test.dart` :
      // l'AppBar, les fonds et `colorScheme.primary` restent NEUTRES ;
      // l'accent coloré ne peint que les commandes actives et le focus.
      tabBarTheme: TabBarThemeData(indicatorColor: tokens.accentRing),
      // Contrôles actifs : hors sélection, les propriétés renvoient `null` et
      // les widgets reprennent les rôles M3 neutres.
      switchTheme: SwitchThemeData(
        thumbColor: _selectedForeground(tokens),
        trackColor: _selectedFill(tokens),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: _selectedFill(tokens),
        checkColor: WidgetStatePropertyAll<Color>(tokens.onAccent),
      ),
      radioTheme: RadioThemeData(fillColor: _selectedFill(tokens)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: tokens.accent,
          selectedForegroundColor: tokens.onAccent,
        ),
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

  /// Thème sombre Material 3, dérivé de la graine graphite (ou du preset choisi
  /// via [AppAppearanceConfig]).
  ///
  /// Sans argument, le rendu reste celui du défaut historique : surfaces
  /// graphite neutres ([HomeTokens.neutral]) et accent d'action violet.
  static ThemeData darkTheme({AppAppearanceConfig? appearance}) {
    final config = appearance ?? AppAppearanceConfig.defaults;
    final preset = config.preset;
    // Graine personnalisée (preset de couleur) : les surfaces M3 teintées
    // remplacent alors les surfaces graphite — c'est le rôle d'un preset de
    // couleur. Le défaut graphite garde, lui, des surfaces strictement neutres.
    final neutralSurfaces = config.usesNeutralSurfaces;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: config.seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: preset.variant,
      contrastLevel: preset.contrastLevel,
    );

    // Les rôles `on*` doivent être fournis explicitement : `ColorScheme.fromSeed`
    // les dérive du `primary`/`secondary`/`error` générés (ton 80 clair + ton 20
    // sombre) et deviennent illisibles dès qu'on écrase ces rôles par des teintes
    // de la marque. Contrastes WCAG mesurés sur cette palette :
    // onPrimary/primary 8.12:1 — onSecondary/secondary 8.12:1 — onError/error 5.77:1
    // — primary/card 7.25:1 — onPrimaryContainer/primaryContainer 6.51:1
    // — onSurfaceVariant/card 4.76:1 (seuil texte ≥ 4.5:1).
    //
    // Les rôles non surchargés (`secondaryContainer`, `tertiary`,
    // `surfaceTint`, `errorContainer`…) restent dérivés du seed graphite :
    // plus aucune surface lavande, et leurs paires `on*` conservent le ton M3
    // d'origine (donc ≥ 4.5:1 : ex. onSecondaryContainer/secondaryContainer
    // 7.23:1, onTertiary/tertiary 7.68:1).
    final colorScheme = neutralSurfaces
        ? baseScheme.copyWith(
            // AUCUN override de l'accent : `primary`, `secondary` et leurs
            // conteneurs restent les rôles M3 dérivés de la graine graphite
            // (variante `neutral`). C'était la dernière source de violet « dans
            // plein de pages » : les ~43 usages de `colorScheme.primary` (états
            // sélectionnés, liens, accents) reprenaient `brandPurpleSoft`
            // partout, dans TOUS les écrans. Les paires `on*` dérivées par M3
            // sont correctes par construction (contrastes mesurés :
            // `tool/contrast_check.dart`).
            surface: homeCard,
            surfaceContainerLowest: homeContainerLowest,
            surfaceContainerLow: homeClusterBg,
            surfaceContainer: homeCard,
            surfaceContainerHigh: homeCard,
            surfaceContainerHighest: homeNavSelected,
            onSurface: Colors.white,
            onSurfaceVariant: homeMuted,
            outline: homeGhostBorder,
            outlineVariant: homeCardBorder,
            error: danger,
            onError: scaffoldDark,
          )
        // Preset de couleur : les rôles de surface viennent de la palette M3
        // teintée ; seules les paires d'erreur restent celles de la charte
        // (rouge `danger` + `onError` sombre, contraste 5.77:1).
        : baseScheme.copyWith(error: danger, onError: scaffoldDark);
    final tokens = _tokensFor(colorScheme, config);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      extensions: <ThemeExtension<dynamic>>[tokens],
      scaffoldBackgroundColor: neutralSurfaces
          ? scaffoldDark
          : colorScheme.surface,
      canvasColor: neutralSurfaces ? scaffoldDark : colorScheme.surface,
      // ── AppBar ──
      // Toujours neutre : même surface que le fond, jamais de bandeau teinté.
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: neutralSurfaces ? scaffoldDark : colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actionsIconTheme: const IconThemeData(size: 20),
        iconTheme: const IconThemeData(size: 20),
      ),
      // ── Cards ──
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        elevation: elevationNone,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
      ),
      // ── List Tiles ──
      // style=list prevents ListTile's own background from conflicting with
      // parent DecoratedBox widgets that provide a background color.
      listTileTheme: const ListTileThemeData(style: ListTileStyle.list),
      // ── Dialogs ──
      dialogTheme: DialogThemeData(shape: dialogShape),
      // ── Bottom Sheets ──
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
      // ── Filled Buttons ──
      // Action principale : c'est LE rôle de l'accent coloré (violet de marque
      // par défaut), avec un premier plan calculé pour rester lisible sur cet
      // accent (`HomeTokens.onAccent`).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
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
      // Remplissage et bordure issus de la palette Discord dark de la charte
      // (discordDarkerBg / discordBorder) : valeurs identiques à celles codées
      // en dur auparavant, désormais référencées par token.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: discordDarkerBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingLg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: discordBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: discordBorder),
        ),
        // Anneau de focus : variante d'accent garantie ≥ 3:1 sur les surfaces
        // sombres du thème (`HomeTokens.accentRing`) — le violet de marque brut
        // (#6A0FA2) ne donne que 1.7:1 sur un fond graphite.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: tokens.accentRing, width: 2),
        ),
        isDense: false,
      ),
      // ── Accent d'action (le violet, et seulement là) ──────────────────────
      // Décision produit verrouillée par `test/theme_no_purple_test.dart` :
      // l'AppBar, les fonds et `colorScheme.primary` restent NEUTRES ;
      // l'accent coloré ne peint que les commandes actives et le focus.
      tabBarTheme: TabBarThemeData(indicatorColor: tokens.accentRing),
      // Contrôles actifs : hors sélection, les propriétés renvoient `null` et
      // les widgets reprennent les rôles M3 du thème.
      switchTheme: SwitchThemeData(
        thumbColor: _selectedForeground(tokens),
        trackColor: _selectedFill(tokens),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: _selectedFill(tokens),
        checkColor: WidgetStatePropertyAll<Color>(tokens.onAccent),
      ),
      radioTheme: RadioThemeData(fillColor: _selectedFill(tokens)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: tokens.accent,
          selectedForegroundColor: tokens.onAccent,
        ),
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
  // Palette dérivée : jetons « home » + accent d'action
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ratio de contraste WCAG 2.1 entre deux couleurs (de 1:1 à 21:1).
  ///
  /// Sert aux dérivations d'accent ci-dessous, et à afficher le ratio dans la
  /// future page Apparence. Seuils de référence : ≥ 4.5:1 pour du texte,
  /// ≥ 3:1 pour les éléments d'interface (anneau de focus, bordure
  /// d'indicateur, icône).
  static double contrastRatio(Color a, Color b) {
    final luminanceA = a.computeLuminance();
    final luminanceB = b.computeLuminance();
    final brighter = luminanceA > luminanceB ? luminanceA : luminanceB;
    final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
    return (brighter + 0.05) / (darker + 0.05);
  }

  /// Jetons « home » du thème : constantes historiques pour le défaut graphite
  /// sombre, valeurs dérivées de la palette M3 sinon (mode clair, preset teinté).
  /// L'accent est celui du MODE courant : les presets portent une variante
  /// claire et une variante sombre ([AppAppearanceConfig.accentFor]).
  static HomeTokens _tokensFor(ColorScheme scheme, AppAppearanceConfig config) {
    if (config.usesNeutralSurfaces && scheme.brightness == Brightness.dark) {
      return HomeTokens.neutral(
        accent: config.accentFor(scheme.brightness),
        scheme: scheme,
      );
    }
    return HomeTokens.fromScheme(
      scheme,
      accent: config.accentFor(scheme.brightness),
    );
  }

  /// Remplissage des contrôles ACTIFS (switch, checkbox, radio) : l'accent quand
  /// l'état est sélectionné, `null` sinon — au repos, les rôles M3 neutres
  /// reprennent la main.
  static WidgetStateProperty<Color?> _selectedFill(HomeTokens tokens) =>
      WidgetStateProperty.resolveWith<Color?>(
        (states) =>
            states.contains(WidgetState.selected) ? tokens.accent : null,
      );

  /// Premier plan des contrôles actifs, lisible sur [HomeTokens.accent].
  static WidgetStateProperty<Color?> _selectedForeground(HomeTokens tokens) =>
      WidgetStateProperty.resolveWith<Color?>(
        (states) =>
            states.contains(WidgetState.selected) ? tokens.onAccent : null,
      );

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
    final accentColor = isDestructive ? scheme.error : scheme.primary;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: dialogShape,
        icon: AppIcon.fromMaterial(
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
                // `filledButtonTheme` force un premier plan blanc (pensé pour le
                // remplissage brandPrimary) ; sur `error` ce blanc ne donne que
                // 3.27:1, alors que `onError` atteint 5.75:1 en sombre.
                foregroundColor: scheme.onError,
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
        builder: (sheetContext) => Padding(
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
              Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: spacingMd),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        ),
      );
    }

    return showDialog<T>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: dialogShape,
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(width: dialogWidth, child: builder(dialogContext)),
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

  /// Construit un AppBar standard (titre centré, actions, `bottom`).
  ///
  /// L'ancien `flexibleSpace` peignait le gradient violet de la marque
  /// (`AppTheme.brandGradient`) : retiré avec le reste de la charte violette, la
  /// barre suit désormais la surface du thème. Le helper est conservé car
  /// `bot_stats.dart` l'utilise.
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Jetons « home » (ThemeExtension) & dérivations d'accent
// ═══════════════════════════════════════════════════════════════════════════════

/// Jetons de la refonte « home » (surfaces, bordures, textes secondaires)
/// portés par le thème sous forme de [ThemeExtension].
///
/// Les valeurs du défaut graphite sombre ([HomeTokens.neutral]) sont
/// **exactement** les constantes `AppTheme.home*` : les ~50 sites consommateurs
/// qui les référencent directement continuent d'afficher la même chose. La vague
/// suivante les migrera vers `HomeTokens.of(context)`, ce qui permettra aux
/// presets de teinter ces surfaces-là aussi.
@immutable
class HomeTokens extends ThemeExtension<HomeTokens> {
  const HomeTokens({
    required this.card,
    required this.cardBorder,
    required this.navBar,
    required this.navSelected,
    required this.createFill,
    required this.createBorder,
    required this.clusterBg,
    required this.clusterBorder,
    required this.containerLowest,
    required this.ghostBorder,
    required this.muted,
    required this.dataAccent,
    required this.online,
    required this.danger,
    required this.accent,
    required this.onAccent,
    required this.accentRing,
    required this.accentIndicator,
  });

  /// Fond des cartes (défaut : `AppTheme.homeCard`).
  final Color card;

  /// Bordure des cartes (défaut : `AppTheme.homeCardBorder`).
  final Color cardBorder;

  /// Fond de la barre de navigation flottante (défaut : `AppTheme.homeNavBar`).
  final Color navBar;

  /// Fond de l'item de navigation sélectionné (défaut :
  /// `AppTheme.homeNavSelected`) — reste NEUTRE : l'accent ne peint que
  /// l'indicateur, jamais le remplissage.
  final Color navSelected;

  /// Remplissage du CTA « créer un bot » (défaut : `AppTheme.homeCreateFill`).
  final Color createFill;

  /// Bordure du CTA « créer un bot » (défaut : `AppTheme.homeCreateBorder`).
  final Color createBorder;

  /// Fond du bloc serveurs d'une carte bot (défaut :
  /// `AppTheme.homeClusterBg`).
  final Color clusterBg;

  /// Bordure du bloc serveurs (défaut : `AppTheme.homeClusterBorder`).
  final Color clusterBorder;

  /// Fond le plus bas du thème (défaut : `AppTheme.homeContainerLowest`).
  final Color containerLowest;

  /// Bordure des boutons « ghost » (défaut : `AppTheme.homeGhostBorder`).
  final Color ghostBorder;

  /// Texte secondaire (défaut : `AppTheme.homeMuted`).
  final Color muted;

  /// Accent pastel des données dynamiques (défaut : `AppTheme.dataAccent`).
  final Color dataAccent;

  /// Vert « en ligne » (défaut : `AppTheme.online`).
  final Color online;

  /// Rouge danger / arrêt (défaut : `AppTheme.danger`).
  final Color danger;

  /// Accent d'action du thème : boutons principaux, anneaux de focus,
  /// indicateurs d'état actif. C'est LE canal par lequel une couleur de marque
  /// revient dans l'interface (défaut : `AppTheme.brandPrimary`).
  final Color accent;

  /// Premier plan lisible sur [accent] (texte/icône des boutons et contrôles
  /// actifs).
  final Color onAccent;

  /// Variante de [accent] garantie ≥ 3:1 sur les surfaces de FOCUS du thème
  /// (`surface`, `surfaceContainerHighest`) : anneau des champs de saisie,
  /// indicateur d'onglet actif. Sur fond sombre, l'accent brut est éclairci (le
  /// violet #6A0FA2 n'y donne que 1.7:1) ; sur fond clair, il est assombri.
  /// Tant qu'une même variante reste lisible aussi sur la pastille de
  /// sélection, c'est elle qui sert aux deux rôles (voir [accentIndicator]).
  final Color accentRing;

  /// Anneau de l'INDICATEUR d'état actif : bordure de l'item sélectionné de la
  /// navigation, peinte sur la pastille de sélection (`secondaryContainer`).
  ///
  /// Ce fond n'a pas la luminance des surfaces : le preset `high_contrast` le
  /// pousse même à l'extrême opposé (pastille très SOMBRE en mode clair, très
  /// CLAIRE en mode sombre). Aucune variante unique ne peut alors être ≥ 3:1 à
  /// la fois sur les surfaces et sur la pastille — les contraintes sont
  /// contradictoires — d'où ce rôle dédié. Il vaut [accentRing] partout où
  /// celui-ci est déjà lisible sur la pastille (accent homogène) ; sinon une
  /// variante est dérivée contre la pastille, teinte d'accent conservée.
  final Color accentIndicator;

  /// Jetons du défaut graphite sombre : valeurs historiques + accent d'action.
  static HomeTokens neutral({
    required Color accent,
    required ColorScheme scheme,
  }) {
    final rings = _accentRingsFor(scheme, accent);
    return HomeTokens(
      card: AppTheme.homeCard,
      cardBorder: AppTheme.homeCardBorder,
      navBar: AppTheme.homeNavBar,
      navSelected: AppTheme.homeNavSelected,
      createFill: AppTheme.homeCreateFill,
      createBorder: AppTheme.homeCreateBorder,
      clusterBg: AppTheme.homeClusterBg,
      clusterBorder: AppTheme.homeClusterBorder,
      containerLowest: AppTheme.homeContainerLowest,
      ghostBorder: AppTheme.homeGhostBorder,
      muted: AppTheme.homeMuted,
      dataAccent: AppTheme.dataAccent,
      online: AppTheme.online,
      danger: AppTheme.danger,
      accent: accent,
      onAccent: _onAccentFor(accent),
      accentRing: rings.ring,
      accentIndicator: rings.indicator,
    );
  }

  /// Jetons dérivés de la palette M3 du thème : mode clair, et presets qui
  /// teintent les surfaces. Chaque jeton reprend le rôle M3 de même sens, donc
  /// les paires clair/sombre restent cohérentes par construction.
  factory HomeTokens.fromScheme(ColorScheme scheme, {required Color accent}) {
    final rings = _accentRingsFor(scheme, accent);
    return HomeTokens(
      card: scheme.surfaceContainer,
      cardBorder: scheme.outlineVariant,
      navBar: scheme.surfaceContainerLowest,
      navSelected: scheme.surfaceContainerHighest,
      createFill: scheme.surfaceContainerHighest,
      createBorder: scheme.outline,
      clusterBg: scheme.surfaceContainerLow,
      clusterBorder: scheme.outlineVariant,
      containerLowest: scheme.surfaceContainerLowest,
      ghostBorder: scheme.outline,
      muted: scheme.onSurfaceVariant,
      dataAccent: scheme.secondary,
      online: AppTheme.online,
      danger: scheme.error,
      accent: accent,
      onAccent: _onAccentFor(accent),
      accentRing: rings.ring,
      accentIndicator: rings.indicator,
    );
  }

  /// Alias historique de `AppTheme.metaText` (identique à [muted]).
  Color get metaText => muted;

  /// Jetons du thème courant. Si le thème n'en porte pas (thème construit à la
  /// main dans un test, par exemple), ils sont dérivés de sa palette.
  static HomeTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<HomeTokens>() ??
        HomeTokens.fromScheme(theme.colorScheme, accent: AppTheme.brandPrimary);
  }

  @override
  HomeTokens copyWith({
    Color? card,
    Color? cardBorder,
    Color? navBar,
    Color? navSelected,
    Color? createFill,
    Color? createBorder,
    Color? clusterBg,
    Color? clusterBorder,
    Color? containerLowest,
    Color? ghostBorder,
    Color? muted,
    Color? dataAccent,
    Color? online,
    Color? danger,
    Color? accent,
    Color? onAccent,
    Color? accentRing,
    Color? accentIndicator,
  }) {
    return HomeTokens(
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      navBar: navBar ?? this.navBar,
      navSelected: navSelected ?? this.navSelected,
      createFill: createFill ?? this.createFill,
      createBorder: createBorder ?? this.createBorder,
      clusterBg: clusterBg ?? this.clusterBg,
      clusterBorder: clusterBorder ?? this.clusterBorder,
      containerLowest: containerLowest ?? this.containerLowest,
      ghostBorder: ghostBorder ?? this.ghostBorder,
      muted: muted ?? this.muted,
      dataAccent: dataAccent ?? this.dataAccent,
      online: online ?? this.online,
      danger: danger ?? this.danger,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentRing: accentRing ?? this.accentRing,
      accentIndicator: accentIndicator ?? this.accentIndicator,
    );
  }

  @override
  HomeTokens lerp(ThemeExtension<HomeTokens>? other, double t) {
    if (other is! HomeTokens) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return HomeTokens(
      card: mix(card, other.card),
      cardBorder: mix(cardBorder, other.cardBorder),
      navBar: mix(navBar, other.navBar),
      navSelected: mix(navSelected, other.navSelected),
      createFill: mix(createFill, other.createFill),
      createBorder: mix(createBorder, other.createBorder),
      clusterBg: mix(clusterBg, other.clusterBg),
      clusterBorder: mix(clusterBorder, other.clusterBorder),
      containerLowest: mix(containerLowest, other.containerLowest),
      ghostBorder: mix(ghostBorder, other.ghostBorder),
      muted: mix(muted, other.muted),
      dataAccent: mix(dataAccent, other.dataAccent),
      online: mix(online, other.online),
      danger: mix(danger, other.danger),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentRing: mix(accentRing, other.accentRing),
      accentIndicator: mix(accentIndicator, other.accentIndicator),
    );
  }
}

// ─── Dérivations d'accent ────────────────────────────────────────────────────
//
// L'accent est peint sur deux fonds d'usage de natures très différentes :
//   * l'anneau de FOCUS (bordure des champs, indicateur d'onglet actif), posé
//     sur les SURFACES du thème (`surface`, `surfaceContainerHighest`) ;
//   * l'indicateur d'état actif (bordure de l'item sélectionné de la
//     navigation), posé sur la PASTILLE de sélection (`secondaryContainer`).
//
// La pastille ne suit pas la luminance des surfaces : le preset `high_contrast`
// la pousse à l'extrême opposé (très sombre en mode clair, très claire en mode
// sombre). Dans ce cas, aucune couleur ne peut atteindre 3:1 des deux côtés à
// la fois — les contraintes sont mathématiquement contradictoires — d'où deux
// jetons. L'anneau de focus reste préféré « tout-terrain » : tant qu'une même
// variante couvre aussi la pastille, elle sert aux deux rôles (accent
// homogène) ; c'est le cas de tous les presets sauf `high_contrast`.

/// Seuil WCAG 2.1 des éléments d'interface (bordures, anneaux, indicateurs).
const double _uiContrastThreshold = 3.0;

/// Paliers de mélange des candidats d'accent (4 % chacun) : assez fins pour
/// conserver la teinte d'accent, assez peu nombreux pour rester triviaux.
const int _accentBlendSteps = 25;

/// Vrai si [candidate] atteint le seuil d'interface sur tous les [backgrounds].
bool _readableOn(Color candidate, List<Color> backgrounds) => backgrounds.every(
  (background) =>
      AppTheme.contrastRatio(candidate, background) >= _uiContrastThreshold,
);

/// Variante d'[accent] garantie ≥ 3:1 sur tous les [backgrounds].
///
/// Sélection de candidat « maximin » : l'accent est évalué tel quel, puis
/// mélangé par paliers croissants vers le BLANC et vers le NOIR (blanc et noir
/// purs compris). Le premier candidat qui atteint le seuil sur TOUS les fonds
/// est retenu : c'est la plus petite dérive possible, donc la teinte d'accent
/// la mieux préservée. Si aucun mélange n'y parvient (fonds contradictoires —
/// ex. pastille extrême face aux surfaces), le candidat qui maximise le PIRE
/// contraste est renvoyé : un blanc ou un noir pur en dernier recours.
Color _derivedAccentOn(Color accent, List<Color> backgrounds) {
  double worstContrast(Color candidate) => backgrounds
      .map((background) => AppTheme.contrastRatio(candidate, background))
      .reduce((a, b) => a < b ? a : b);

  final baseContrast = worstContrast(accent);
  if (baseContrast >= _uiContrastThreshold) {
    return accent;
  }

  var best = accent;
  var bestContrast = baseContrast;
  for (var step = 1; step <= _accentBlendSteps; step++) {
    final amount = step / _accentBlendSteps;
    for (final target in const <Color>[Colors.white, Colors.black]) {
      final candidate = Color.lerp(accent, target, amount)!;
      final contrast = worstContrast(candidate);
      if (contrast >= _uiContrastThreshold) {
        return candidate;
      }
      if (contrast > bestContrast) {
        best = candidate;
        bestContrast = contrast;
      }
    }
  }
  return best;
}

/// Anneaux d'accent du thème, dérivés du fond RÉEL de chaque rôle.
///
/// `ring` (focus) et `indicator` (pastille de sélection) partagent la même
/// valeur tant qu'elle couvre les deux fonds ; sinon — fonds incompatibles —
/// l'indicateur reçoit une variante dédiée dérivée contre la pastille seule.
({Color ring, Color indicator}) _accentRingsFor(
  ColorScheme scheme,
  Color accent,
) {
  final focusBackgrounds = <Color>[
    scheme.surface,
    scheme.surfaceContainerHighest,
  ];
  final indicatorBackgrounds = <Color>[scheme.secondaryContainer];
  final unifiedBackgrounds = <Color>[
    ...focusBackgrounds,
    ...indicatorBackgrounds,
  ];

  final unified = _derivedAccentOn(accent, unifiedBackgrounds);
  final ring = _readableOn(unified, unifiedBackgrounds)
      ? unified
      : _derivedAccentOn(accent, focusBackgrounds);

  final indicator =
      AppTheme.contrastRatio(ring, scheme.secondaryContainer) >=
          _uiContrastThreshold
      ? ring
      : _derivedAccentOn(accent, indicatorBackgrounds);

  return (ring: ring, indicator: indicator);
}

/// Premier plan lisible sur [accent] : blanc tant qu'il atteint 4.5:1, noir
/// sinon — un accent clair (ambre, cyan, violet clair) exige du texte sombre.
Color _onAccentFor(Color accent) =>
    AppTheme.contrastRatio(Colors.white, accent) >= 4.5
    ? Colors.white
    : Colors.black;

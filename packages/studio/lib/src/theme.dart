import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

/// Alias des jetons de [AppTheme] (le design de l'app) : le Studio n'a plus de
/// palette propre, toute couleur vient de `bot_creator_ui`.
abstract final class StudioColors {
  static const scaffold = AppTheme.scaffoldDark;
  static const card = AppTheme.homeCard;
  static const cardBorder = AppTheme.homeCardBorder;
  static const rail = AppTheme.homeNavBar;
  static const selected = AppTheme.homeNavSelected;
  static const clusterBorder = AppTheme.homeClusterBorder;
  static const containerLowest = AppTheme.homeContainerLowest;
  static const ghostBorder = AppTheme.homeGhostBorder;
  static const muted = AppTheme.homeMuted;
  static const action = AppTheme.actionViolet;
  static const actionSoft = AppTheme.actionVioletSoft;
  static const brandPrimary = AppTheme.brandPrimary;
  static const brandSecondary = AppTheme.brandSecondary;
  static const discord = AppTheme.discord;
  static const inputFill = AppTheme.discordDarkerBg;
  static const inputBorder = AppTheme.discordBorder;
  static const online = AppTheme.statusOnline;
  static const errorText = AppTheme.statusErrorText;
  static const error = AppTheme.statusError;
  static const premiumGold = Color(0xFFFFC107);
  static const countChip = Color(0xFF1F222C);
}

abstract final class StudioTheme {
  static const fontFamily = 'Inter';
  static const monoFamily = 'JetBrainsMono';

  /// Thème sombre de l'app, tel quel (Inter par-dessus pour le web).
  static ThemeData dark({AppAppearanceConfig? appearance}) {
    final base = AppTheme.darkTheme(appearance: appearance);
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }
}

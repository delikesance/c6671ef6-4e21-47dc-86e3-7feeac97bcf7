/// Dialogue de confirmation du refus SERVEUR de sur-réduction
/// (`409 bot_config_overshrink`).
///
/// POURQUOI un fichier à part : l'écran qui pousse une configuration
/// (`AppHomePage`) n'est pas montable en test dans ce dépôt. Isolée ici, la
/// question — ses quatre phrases, ses deux issues — se prouve dans un test de
/// widget, sans monter l'écran entier.
///
/// Ce que le dialogue doit dire, et que l'utilisateur ne peut pas deviner : RIEN
/// n'a encore été envoyé, sa configuration locale est intacte, et le serveur fait
/// toujours tourner la version précédente. C'est pour cela qu'un tel refus ne
/// doit jamais être présenté comme une panne.
library;

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Demande si la configuration réduite doit VRAIMENT être poussée.
///
/// Rend `true` uniquement sur un accord EXPLICITE (bouton de confirmation) ;
/// `false` sur annulation, fermeture par la barre système ou clic hors du
/// dialogue — seule la valeur `true` autorise la poussée avec le drapeau du
/// contrat.
Future<bool> showBotConfigOvershrinkConfirmation(BuildContext context) {
  final confirmation = localizedBotConfigOvershrinkConfirmation(context.tr);
  return AppTheme.showConfirmDialog(
    context,
    title: confirmation.title,
    content: confirmation.body,
    confirmLabel: confirmation.confirmLabel,
    cancelLabel: confirmation.keepLocalLabel,
    // Confirmer cet envoi remplace la configuration vivante d'un bot par une
    // version nettement plus petite : c'est destructif, donc rouge.
    isDestructive: true,
  );
}

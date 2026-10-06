import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Couleur d'un état de conteneur : vert en marche, orange pendant la
/// préparation, gris à l'arrêt, rouge en échec.
Color containerStateColor(String state) {
  switch (state) {
    case 'RUNNING':
      return Colors.green;
    case 'PENDING':
    case 'PROVISIONING':
      return Colors.orange;
    case 'STOPPED':
    case 'STOPPING':
      return Colors.grey;
    case 'FAILED':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Libellé localisé d'un état de conteneur ; l'état brut quand il est inconnu.
String containerStateLabel(String state, AppLocalizations tr) {
  switch (state) {
    case 'RUNNING':
      return tr.container_state_running;
    case 'PENDING':
      return tr.container_state_pending;
    case 'PROVISIONING':
      return tr.container_state_provisioning;
    case 'STOPPED':
      return tr.container_state_stopped;
    case 'STOPPING':
      return tr.container_state_stopping;
    case 'FAILED':
      return tr.container_state_failed;
    default:
      return state;
  }
}

/// Temps d'hébergement restant (« 2h 30m restantes »), ou « Expiré » une fois
/// l'échéance passée. [now] est injectable pour les tests.
String containerExpiryLabel(
  DateTime expiresAt,
  AppLocalizations tr, {
  DateTime? now,
}) {
  final remaining = expiresAt.toUtc().difference(
    (now ?? DateTime.now()).toUtc(),
  );
  if (remaining.isNegative) return tr.container_list_expired;
  final totalMinutes = remaining.inMinutes;
  if (totalMinutes < 1) return tr.container_list_expiry_minutes(1);
  if (totalMinutes < 60) return tr.container_list_expiry_minutes(totalMinutes);
  final hours = totalMinutes ~/ 60;
  if (hours < 24) {
    return tr.container_list_expiry_hours(hours, totalMinutes % 60);
  }
  return tr.container_list_expiry_days(hours ~/ 24, hours % 24);
}

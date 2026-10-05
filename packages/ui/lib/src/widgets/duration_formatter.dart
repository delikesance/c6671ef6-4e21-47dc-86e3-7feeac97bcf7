import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/tr_extension.dart';

/// Décomposition d'une durée d'hébergement en unités brutes.
typedef HostingDurationParts = ({int months, int days, int hours, int minutes});

/// Décompose [totalMinutes] en mois (30 jours), jours, heures et minutes.
///
/// Sert aux affichages segmentés (une colonne par unité) qui ne passent pas par
/// une chaîne déjà formatée. Les valeurs négatives sont ramenées à zéro.
HostingDurationParts splitHostingDuration(int totalMinutes) {
  if (totalMinutes <= 0) {
    return (months: 0, days: 0, hours: 0, minutes: 0);
  }

  const minutesPerHour = 60;
  const minutesPerDay = minutesPerHour * 24;
  const minutesPerMonth = minutesPerDay * 30;

  var remaining = totalMinutes;
  final months = remaining ~/ minutesPerMonth;
  remaining %= minutesPerMonth;
  final days = remaining ~/ minutesPerDay;
  remaining %= minutesPerDay;
  final hours = remaining ~/ minutesPerHour;

  return (
    months: months,
    days: days,
    hours: hours,
    minutes: remaining % minutesPerHour,
  );
}

/// Formats a duration in minutes into a human-readable localized string
/// (e.g. "2 jours, 3 heures, 15 minutes" or "45 minutes").
String formatHostingDuration(BuildContext context, int totalMinutes) {
  if (totalMinutes <= 0) {
    return context.tr.unit_minute(0);
  }

  final parts = splitHostingDuration(totalMinutes);
  final units = <String>[];

  if (parts.months > 0) {
    units.add(context.tr.unit_month(parts.months));
  }
  if (parts.days > 0) {
    units.add(context.tr.unit_day(parts.days));
  }
  if (parts.hours > 0) {
    units.add(context.tr.unit_hour(parts.hours));
  }
  if (parts.minutes > 0 || units.isEmpty) {
    units.add(context.tr.unit_minute(parts.minutes));
  }

  return units.join(', ');
}

/// Formate une expiration d'hébergement en date + heure absolues, sans verbe
/// (le surtitre porte le sens) : « 21 nov. 2037 à 17:55 ».
///
/// Contrairement à [formatSessionExpiration] — plus bavard et utilisé par les
/// cartes de bots — cet affichage alimente le bloc « Expiration prévue » de la
/// carte « temps total ».
String formatHostingExpiration(BuildContext context, DateTime expiresAt) {
  final local = expiresAt.toLocal();
  final locale = Localizations.localeOf(context).toString();

  return context.tr.home_hosting_expires_at(
    DateFormat.yMMMd(locale).format(local),
    DateFormat.jm(locale).format(local),
  );
}

/// Formats a session expiration DateTime into a user-friendly localized string
/// including date/day info (e.g. "Expire aujourd'hui à 15:30", "Expire demain à 15:30",
/// or "Expire le 2 sept. 2026, 15:30").
String formatSessionExpiration(BuildContext context, DateTime expiresAt) {
  final local = expiresAt.toLocal();
  final now = DateTime.now();
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final tomorrow = now.add(const Duration(days: 1));
  final isTomorrow =
      local.year == tomorrow.year &&
      local.month == tomorrow.month &&
      local.day == tomorrow.day;

  final locale = Localizations.localeOf(context).toString();
  final timeStr = DateFormat.jm(locale).format(local);

  if (isToday) {
    return context.tr.home_hosting_expires_today(timeStr);
  } else if (isTomorrow) {
    return context.tr.home_hosting_expires_tomorrow(timeStr);
  } else {
    final dateFormatted = DateFormat.yMMMd(locale).add_jm().format(local);
    return context.tr.container_hosted_expires_at(dateFormatted);
  }
}

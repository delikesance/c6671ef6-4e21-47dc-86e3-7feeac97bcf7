import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:bot_creator/core/i18n/extensions.dart';

/// Formats a duration in minutes into a human-readable localized string
/// (e.g. "2 jours, 3 heures, 15 minutes" or "45 minutes").
String formatHostingDuration(BuildContext context, int totalMinutes) {
  if (totalMinutes <= 0) {
    return context.tr.unit_minute(0);
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
  remaining %= minutesPerHour;
  final minutes = remaining;

  final parts = <String>[];
  if (months > 0) {
    parts.add(context.tr.unit_month(months));
  }
  if (days > 0) {
    parts.add(context.tr.unit_day(days));
  }
  if (hours > 0) {
    parts.add(context.tr.unit_hour(hours));
  }
  if (minutes > 0 || parts.isEmpty) {
    parts.add(context.tr.unit_minute(minutes));
  }

  return parts.join(', ');
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

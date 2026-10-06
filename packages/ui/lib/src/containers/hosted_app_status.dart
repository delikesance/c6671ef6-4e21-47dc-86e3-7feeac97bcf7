import '../l10n/app_localizations.dart';

/// Describes the current health/status of a hosted app container in a
/// user-facing way, combining the container [state] with the backend
/// `health_status` / `status_code` / `status_message` signals.
///
/// Returns an empty string when the container is healthy and running (i.e.
/// there is nothing noteworthy to show the user).
String describeHostedAppStatus({
  required String? healthStatus,
  required String? statusCode,
  required String? statusMessage,
  required String state,
  required AppLocalizations tr,
}) {
  final health = (healthStatus ?? '').trim().toLowerCase();
  final code = (statusCode ?? '').trim().toLowerCase();
  final message = (statusMessage ?? '').trim();

  String withDetail(String base) {
    if (message.isEmpty || message == base) return base;
    return '$base ($message)';
  }

  if (health == 'image_pull_failed' || code == 'image_pull_failed') {
    return withDetail(tr.container_health_image_pull_failed);
  }
  if (health == 'crash_loop' || code == 'crash_loop') {
    return withDetail(tr.container_health_crash_loop);
  }
  if (state == 'PROVISIONING' ||
      state == 'PENDING' ||
      health == 'starting' ||
      code == 'starting') {
    return withDetail(tr.container_health_starting);
  }
  if (state == 'RUNNING' &&
      (health.isEmpty || health == 'healthy' || health == 'unknown')) {
    return '';
  }

  return message;
}

/// True when the given health/status signals indicate a container that is
/// unhealthy and should show a warning/error card to the user.
bool isHostedAppUnhealthy({
  required String? healthStatus,
  required String? statusCode,
}) {
  final health = (healthStatus ?? '').trim().toLowerCase();
  final code = (statusCode ?? '').trim().toLowerCase();
  return health == 'image_pull_failed' ||
      code == 'image_pull_failed' ||
      health == 'crash_loop' ||
      code == 'crash_loop';
}

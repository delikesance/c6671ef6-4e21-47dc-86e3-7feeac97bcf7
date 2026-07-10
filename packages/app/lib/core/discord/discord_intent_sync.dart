import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator_shared/utils/application_intent_sync.dart';
import 'package:bot_creator_shared/utils/intent_resolver.dart';

/// Outcome of fetching portal intents, including auto-enable status.
class PortalIntentFetchOutcome {
  const PortalIntentFetchOutcome({
    required this.intents,
    this.autoEnabled = false,
    this.verifiedBotManualRequired = false,
    this.autoEnableFailed = false,
  });

  final Map<String, bool> intents;
  final bool autoEnabled;
  final bool verifiedBotManualRequired;
  final bool autoEnableFailed;
}

/// Fetches the current portal-enabled intents map for a bot token.
///
/// Attempts to auto-enable missing privileged intents via PATCH when allowed.
Future<Map<String, bool>> fetchPortalIntents(String token) async {
  final outcome = await fetchPortalIntentsWithOutcome(token);
  return outcome.intents;
}

/// Like [fetchPortalIntents] but exposes auto-enable status for UI feedback.
Future<PortalIntentFetchOutcome> fetchPortalIntentsWithOutcome(
  String token,
) async {
  try {
    final result = await fetchPortalEnabledPrivilegedIntents(token);
    return PortalIntentFetchOutcome(
      intents: buildPortalIntentsMapFromPrivileged(result.enabled),
      autoEnabled: result.didAutoEnable,
    );
  } on PortalIntentAutoEnableError {
    final privileged = await readPortalEnabledPrivilegedIntents(token);
    return PortalIntentFetchOutcome(
      intents: buildPortalIntentsMapFromPrivileged(privileged),
      verifiedBotManualRequired: true,
    );
  } on PortalIntentPatchFailedException {
    final privileged = await readPortalEnabledPrivilegedIntents(token);
    return PortalIntentFetchOutcome(
      intents: buildPortalIntentsMapFromPrivileged(privileged),
      autoEnableFailed: true,
    );
  }
}

bool intentsMapsEqual(Map<String, bool> a, Map<String, bool> b) {
  final keys = {...a.keys, ...b.keys};
  for (final key in keys) {
    if ((a[key] ?? false) != (b[key] ?? false)) {
      return false;
    }
  }
  return true;
}

Map<String, bool> intentsFromAppData(Map<String, dynamic> appData) {
  return Map<String, bool>.from(
    (appData['intents'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value == true),
        ) ??
        const {},
  );
}

/// Syncs portal intents into [appData] and persists when changed.
///
/// Returns `true` when stored intents were updated.
Future<bool> refreshAppIntentsFromPortal({
  required String botId,
  required Map<String, dynamic> appData,
  required String token,
}) async {
  final portalIntents = await fetchPortalIntents(token);
  final currentIntents = intentsFromAppData(appData);
  if (intentsMapsEqual(currentIntents, portalIntents)) {
    return false;
  }

  appData['intents'] = portalIntents;
  await AppManager().saveApp(botId, appData);
  return true;
}

/// Whether all privileged intents are enabled in [intents].
bool hasAllPrivilegedIntents(Map<String, bool> intents) {
  for (final key in privilegedIntentKeys) {
    if (intents[key] != true) {
      return false;
    }
  }
  return true;
}

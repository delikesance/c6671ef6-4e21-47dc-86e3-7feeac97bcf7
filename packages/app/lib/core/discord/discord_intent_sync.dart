import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator_shared/utils/application_intent_sync.dart';
import 'package:bot_creator_shared/utils/intent_resolver.dart';
import 'package:http/http.dart' as http;

/// Outcome of fetching portal intents from the Developer Portal.
class PortalIntentFetchOutcome {
  const PortalIntentFetchOutcome({
    required this.intents,
    this.missingPrivilegedIntents = const [],
  });

  final Map<String, bool> intents;
  final List<String> missingPrivilegedIntents;
}

/// Fetches the current portal-enabled intents map for a bot token.
Future<Map<String, bool>> fetchPortalIntents(String token) async {
  final outcome = await fetchPortalIntentsWithOutcome(token);
  return outcome.intents;
}

/// Like [fetchPortalIntents] but exposes missing privileged intent keys for UI feedback.
Future<PortalIntentFetchOutcome> fetchPortalIntentsWithOutcome(
  String token, {
  http.Client? client,
}) async {
  final result = await fetchPortalEnabledPrivilegedIntents(
    token,
    client: client,
  );
  final intents = buildPortalIntentsMapFromPrivileged(result.enabled);
  final missing = privilegedIntentKeys
      .where((key) => intents[key] != true)
      .toList(growable: false);
  return PortalIntentFetchOutcome(
    intents: intents,
    missingPrivilegedIntents: missing,
  );
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

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator_shared/utils/application_intent_sync.dart';
import 'package:nyxx/nyxx.dart';

/// Fetches the current portal-enabled intents map for a bot token.
Future<Map<String, bool>> fetchPortalIntents(String token) async {
  final tempClient = await Nyxx.connectRest(token);
  try {
    final app = await tempClient.applications.fetchCurrentApplication();
    return buildPortalIntentsMap(app);
  } finally {
    await tempClient.close();
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

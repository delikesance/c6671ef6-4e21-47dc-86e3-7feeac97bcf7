// Les modèles du catalogue (offres, traductions, liaisons de boutique) vivent dans
// `bot_creator_ui` (partagés avec le Studio) ; l'app y ajoute la LECTURE : session
// locale, appel au Manager, cache hors ligne.
import 'dart:convert';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' show CommerceCatalog;
import 'package:shared_preferences/shared_preferences.dart';

export 'package:bot_creator_ui/src/subscriptions/commerce_models.dart';

/// Le catalogue publié, lu auprès du Manager (repli sur le dernier exemplaire
/// en cache quand le serveur est injoignable). `null` : rien de publié ou pas
/// de session.
Future<CommerceCatalog?> loadCommerceCatalog() async {
  final config = await MainApiSettingsStore.loadConfig();
  final session = await MainApiSettingsStore.loadSession();
  if (!config.isConfigured || session == null || session.isExpired) {
    return null;
  }
  final preferences = await SharedPreferences.getInstance();
  final key = 'commerce_catalog_v1:${config.baseUrl}';
  try {
    final client = MainApiClient(
      baseUrl: config.baseUrl,
      accessToken: session.accessToken,
    );
    final raw = await client.getCommerceCatalog();
    final catalog = CommerceCatalog.fromJson(raw);
    if (!catalog.published) {
      await preferences.remove(key);
      return null;
    }
    await preferences.setString(key, jsonEncode(raw));
    return catalog;
  } catch (_) {
    final cached = preferences.getString(key);
    if (cached == null) return null;
    try {
      return CommerceCatalog.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
    } catch (_) {
      await preferences.remove(key);
      return null;
    }
  }
}

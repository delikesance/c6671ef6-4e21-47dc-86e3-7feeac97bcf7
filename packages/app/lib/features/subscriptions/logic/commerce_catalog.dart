import 'dart:convert';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommerceText {
  CommerceText.fromJson(Map<String, dynamic> json)
    : title = json['title'] as String,
      description = json['description'] as String? ?? '',
      benefits = List<String>.from(json['benefits'] as List? ?? const []);
  final String title;
  final String description;
  final List<String> benefits;
}

class CommerceBinding {
  CommerceBinding.fromJson(Map<String, dynamic> json)
    : provider = json['provider'] as String,
      platform = json['platform'] as String,
      productId = json['product_id'] as String? ?? '',
      basePlanId = json['base_plan_id'] as String?;
  final String provider;
  final String platform;
  final String productId;
  final String? basePlanId;
}

class CommerceOffer {
  CommerceOffer.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = json['kind'] as String,
      period = json['period'] as String? ?? '',
      enabled = json['enabled'] == true,
      startsAt = DateTime.tryParse(json['starts_at']?.toString() ?? ''),
      endsAt = DateTime.tryParse(json['ends_at']?.toString() ?? ''),
      translations = (json['translations'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          CommerceText.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      bindings = (json['bindings'] as List? ?? const [])
          .map(
            (value) => CommerceBinding.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(),
      requiredCapabilities = List<String>.from(
        json['required_capabilities'] as List? ?? const [],
      );
  final String id;
  final String kind;
  final String period;
  final bool enabled;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final Map<String, CommerceText> translations;
  final List<CommerceBinding> bindings;
  final List<String> requiredCapabilities;

  CommerceText? text(String locale, String fallback) {
    final normalized = locale.replaceAll('_', '-').toLowerCase();
    return translations[normalized] ??
        translations[normalized.split('-').first] ??
        translations[fallback];
  }

  CommerceBinding? nativeBinding(String platform) {
    for (final binding in bindings) {
      if (binding.platform == platform &&
          binding.provider == (platform == 'ios' ? 'apple' : 'google')) {
        return binding;
      }
    }
    return null;
  }

  bool visible(DateTime now, Set<String> capabilities) =>
      enabled &&
      (startsAt == null || !now.isBefore(startsAt!)) &&
      (endsAt == null || now.isBefore(endsAt!)) &&
      requiredCapabilities.every(capabilities.contains);
}

class CommerceCatalog {
  CommerceCatalog.fromJson(Map<String, dynamic> json) {
    final doc = Map<String, dynamic>.from(json['document'] as Map);
    if (doc['schema_version'] != 1) {
      throw const FormatException('Unsupported commerce catalog');
    }
    published = json['published'] == true;
    final rawGrants = json['grants'];
    grants = rawGrants is Map
        ? rawGrants.map(
            (key, value) => MapEntry(
              key.toString(),
              value is Map ? Map<String, dynamic>.from(value) : const {},
            ),
          )
        : const {};
    defaultLocale = doc['default_locale'] as String;
    offers = (doc['offers'] as List)
        .map(
          (value) =>
              CommerceOffer.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    if (offers.any(
      (offer) => offer.text(defaultLocale, defaultLocale) == null,
    )) {
      throw const FormatException('Missing commerce translation');
    }
  }
  late final bool published;

  /// Ce que chaque offre octroie, calcule par le serveur (`grants[offerId]`).
  /// Vide quand le serveur est plus ancien : le client ne devine rien.
  late final Map<String, Map<String, dynamic>> grants;

  /// Credits IA donnes une seule fois par un pack, en tokens ; 0 si inconnu.
  int aiCreditsOnce(String offerId) =>
      (grants[offerId]?['ai_credits_once'] as num?)?.toInt() ?? 0;

  /// Packs de credits IA achetables sur [platform] (`ios` / `android`).
  List<CommerceOffer> aiPacks(String platform, DateTime now) => offers
      .where(
        (offer) =>
            offer.kind == 'ai_pack' &&
            offer.visible(now, const <String>{}) &&
            offer.nativeBinding(platform) != null,
      )
      .toList();
  late final String defaultLocale;
  late final List<CommerceOffer> offers;

  static Future<CommerceCatalog?> load() async {
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
}

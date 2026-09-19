// Lavalink — schéma de configuration FIGÉ (contrat avec le runner) :
//
//   "lavalink": {
//     "enabled": true,
//     "custom_servers": [
//       {"host": "mon.lavalink.tld", "port": 2333, "password": "secret",
//        "secure": false}
//     ]
//   }
//
// La liste publique n'est JAMAIS stockée en configuration : le bot la sonde
// lui-même au démarrage et n'utilise `custom_servers` qu'en REPLI. La page de
// l'app ne pilote donc que `enabled` et les serveurs personnels — plus aucun
// serveur public choisi à la main, plus aucune forme héritée envoyée.
//
// Rétrocompatibilité en LECTURE uniquement : l'ancienne forme décrivait un seul
// serveur en clair au même niveau (`host`/`port`/`password`/`useSsl`) ; elle est
// relue comme `custom_servers[0]` pour qu'un bot déjà configuré ne perde pas sa
// musique au déploiement suivant.
import 'dart:convert';

/// Clé du schéma figé dans la config du bot.
const String kLavalinkConfigKey = 'lavalink';

/// Clé de l'ancienne forme — jamais réécrite, seulement relue.
const String kLegacyLavalinkConfigKey = 'lavalinkConfig';

const int kLavalinkDefaultPort = 2333;
const String kLavalinkDefaultPassword = 'youshallnotpass';

/// Serveurs de repli normalisés au schéma figé, dans l'ordre d'essai.
List<Map<String, dynamic>> lavalinkCustomServersFromConfig(
  Map<String, dynamic>? raw,
) {
  final servers = <Map<String, dynamic>>[];
  final rawList = raw?['custom_servers'];
  if (rawList is List) {
    for (final entry in rawList.whereType<Map>()) {
      final normalized = normalizeLavalinkServer(Map<String, dynamic>.from(entry));
      if (normalized != null) servers.add(normalized);
    }
  }
  if (servers.isEmpty && raw != null) {
    final legacy = normalizeLavalinkServer(raw);
    if (legacy != null) servers.add(legacy);
  }
  return servers;
}

/// Vrai si l'utilitaire musique est activé.
///
/// Nouvelle forme : seule la clé `enabled` compte (absente = désactivée).
/// Ancienne forme (aucune clé `enabled`) : un serveur déjà configuré vaut
/// activation, sinon un bot existant perdrait sa musique.
bool lavalinkEnabledFromConfig(Map<String, dynamic>? raw) {
  if (raw == null) return false;
  final enabled = raw['enabled'];
  if (enabled is bool) return enabled;
  if ((raw['host'] ?? '').toString().trim().isNotEmpty) return true;
  return raw['custom_servers'] is List &&
      (raw['custom_servers'] as List).isNotEmpty;
}

/// Entrée de serveur normalisée (jamais `null` dès que l'hôte est renseigné).
Map<String, dynamic>? normalizeLavalinkServer(Map<String, dynamic> raw) {
  final host = (raw['host'] ?? '').toString().trim();
  if (host.isEmpty) return null;
  final parsedPort = int.tryParse((raw['port'] ?? '').toString().trim());
  final port = (parsedPort == null || parsedPort < 1 || parsedPort > 65535)
      ? kLavalinkDefaultPort
      : parsedPort;
  return <String, dynamic>{
    'host': host,
    'port': port,
    'password': (raw['password'] ?? '').toString(),
    'secure': raw['secure'] == true || raw['useSsl'] == true || raw['ssl'] == true,
  };
}

/// Charge utile conforme au schéma figé — la seule forme que l'app écrit.
Map<String, dynamic> buildLavalinkConfigPayload({
  required bool enabled,
  required List<Map<String, dynamic>> customServers,
}) {
  return <String, dynamic>{
    'enabled': enabled,
    'custom_servers': customServers
        .map(normalizeLavalinkServer)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false),
  };
}

/// Saisie d'un serveur de repli valide : hôte non vide, port 1..65535.
bool isLavalinkServerInputValid(String host, String port) {
  final parsedPort = int.tryParse(port.trim());
  return host.trim().isNotEmpty &&
      parsedPort != null &&
      parsedPort >= 1 &&
      parsedPort <= 65535;
}

/// Signature du contenu persisté (sert à détecter un rechargement réel).
String lavalinkConfigSignature(Map<String, dynamic>? raw) =>
    jsonEncode(raw ?? const <String, dynamic>{});

/// Injecte le schéma figé dans un payload sortant et supprime l'ancienne forme.
///
/// C'est le seul point qui décide de la forme envoyée au manager et au runner :
/// `buildBotPayload` ne doit jamais laisser passer `lavalinkConfig`.
void applyLavalinkSchema(
  Map<String, dynamic> payload,
  Map<String, dynamic>? storedConfig,
) {
  payload.remove(kLegacyLavalinkConfigKey);
  payload[kLavalinkConfigKey] = buildLavalinkConfigPayload(
    enabled: lavalinkEnabledFromConfig(storedConfig),
    customServers: lavalinkCustomServersFromConfig(storedConfig),
  );
}

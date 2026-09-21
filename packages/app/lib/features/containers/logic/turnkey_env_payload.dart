import 'hosted_app_templates.dart';

/// Clé du token Discord dans un schéma d'environnement de template clé en main.
const String kTurnkeyTokenEnvKey = 'TOKEN';

/// Vrai si [key] désigne le champ token Discord (comparaison insensible à la
/// casse et aux espaces : le template fait foi sur la casse de la clé).
bool isTurnkeyTokenKey(String key) => key.trim().toUpperCase() == kTurnkeyTokenEnvKey;

/// Champs d'environnement d'un template qui SONT le token Discord (clé `TOKEN`).
List<HostedAppEnvField> turnkeyTokenEnvFields(HostedAppTemplate template) {
  return template.envFields
      .where((field) => field.key.trim().isNotEmpty && isTurnkeyTokenKey(field.key))
      .toList(growable: false);
}

/// Champs d'environnement à saisir par l'utilisateur, c'est-à-dire tous SAUF le
/// token Discord (qui garde son champ de saisie dédié, partagé avec le
/// sélecteur de bot local). Les clés vides et les doublons sont écartés.
List<HostedAppEnvField> turnkeyUserEnvFields(HostedAppTemplate template) {
  final seen = <String>{};
  final fields = <HostedAppEnvField>[];
  for (final field in template.envFields) {
    final key = field.key.trim();
    if (key.isEmpty || isTurnkeyTokenKey(key)) continue;
    if (!seen.add(key)) continue;
    fields.add(field);
  }
  return fields;
}

/// Valeur affichée au départ dans le formulaire pour un champ : la valeur par
/// défaut DÉCLARÉE par le template. Un champ verrouillé reste en lecture seule —
/// c'est la même valeur que celle transmise au déploiement, jamais une saisie.
String initialTurnkeyEnvValue(HostedAppEnvField field) => field.defaultValue;

/// Env envoyé au déploiement d'un bot clé en main, construit à partir du SCHÉMA
/// déclaré par le template — l'app ne suppose aucun nom de variable
/// (`LAVALINK_*` n'existe nulle part ici : elle rend ce que le template déclare).
///
/// Règles, champ par champ :
///  - champ VERROUILLÉ (`fixed` ou `source == 'node'`) : jamais de valeur
///    inventée. Seule la valeur DÉCLARÉE part ; sans valeur déclarée la clé
///    n'est pas envoyée du tout — c'est le serveur qui l'impose ;
///  - champ token (clé `TOKEN`, insensible à la casse) et `secret` : la valeur
///    du champ token dédié ([botToken]) ;
///  - sinon : la valeur saisie par l'utilisateur si elle est non vide, sinon la
///    valeur par défaut déclarée par le template ;
///  - clés vides et valeurs vides : ignorées (aucune clé vide dans l'env).
Map<String, String> buildTurnkeyEnvPayload({
  required HostedAppTemplate template,
  required String botToken,
  Map<String, String> userValues = const <String, String>{},
}) {
  final payload = <String, String>{};
  final token = botToken.trim();

  for (final field in template.envFields) {
    final key = field.key.trim();
    if (key.isEmpty) continue;

    if (field.isLocked) {
      // Le serveur décide : on ne transmet que ce que le template déclare, et
      // surtout rien qui vienne d'une saisie utilisateur.
      final declared = field.defaultValue.trim();
      if (declared.isNotEmpty) payload[key] = declared;
      continue;
    }

    if (field.secret && isTurnkeyTokenKey(key)) {
      if (token.isNotEmpty) payload[key] = token;
      continue;
    }

    final userValue = (userValues[key] ?? '').trim();
    final value = userValue.isNotEmpty ? userValue : field.defaultValue.trim();
    if (value.isNotEmpty) payload[key] = value;
  }

  return payload;
}

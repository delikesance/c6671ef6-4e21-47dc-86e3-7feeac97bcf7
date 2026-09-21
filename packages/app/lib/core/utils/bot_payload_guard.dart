/// Garde PARTAGÉE contre la poussée d'une charge utile de bot VIDE.
///
/// POURQUOI : un incident a remplacé la configuration d'un bot (~1 Mo) par une
/// charge utile de 378 octets — `commands` et `events` vides, plus
/// `runtimeEngine`, `presence`, `intents`, `scriptTimeoutMs`. C'est exactement
/// le profil rendu par `buildJsBotPayload` dès qu'aucune commande ne porte de
/// script JS. Un bot réduit à un jeton n'exécute plus rien : la poussée ne doit
/// donc jamais partir. La garde vit en `core` pour qu'aucun chemin ne puisse la
/// contourner : le constructeur de charge JS ET le client réseau l'appliquent.
library;

/// Familles d'automatisation d'une charge utile de bot, sous toutes les formes
/// présentes dans le dépôt :
/// - `commands` : commandes (les deux moteurs, dart et javascript) ;
/// - `events` / `eventWorkflows` : déclencheurs d'événement ;
/// - `scheduled` / `scheduledTriggers` : déclencheurs planifiés ;
/// - `inboundWebhooks` / `inboundWebhookEndpoints` : webhooks entrants ;
/// - `globalVariables` / `scopedVariables` / `scopedVariableDefinitions` :
///   variables partagées et définitions de variables à portée.
const List<String> botPayloadAutomationKeys = <String>[
  'commands',
  'events',
  'eventWorkflows',
  'scheduled',
  'scheduledTriggers',
  'inboundWebhooks',
  'inboundWebhookEndpoints',
  'globalVariables',
  'scopedVariables',
  'scopedVariableDefinitions',
];

/// Refus TYPÉ d'une charge utile vide : jamais un retour vide silencieux.
///
/// [source] nomme le chemin fautif (`buildJsBotPayload`, `syncBot`,
/// `saveDiscordBotSnapshot`...) : il sert aux journaux et aux tests. Les écrans
/// qui peuvent rencontrer ce refus affichent leur propre traduction — le texte
/// ci-dessous est un diagnostic, pas un libellé d'interface.
class DegenerateBotPayloadException implements Exception {
  const DegenerateBotPayloadException(this.source);

  /// Chemin qui a refusé la poussée.
  final String source;

  @override
  String toString() =>
      'empty bot payload refused by $source: no command, no event, '
      'no webhook, no variable';
}

/// Lève [DegenerateBotPayloadException] si [config] est une charge utile de bot
/// dégénérée. À appeler AVANT toute écriture ou tout appel réseau.
void assertNonDegenerateBotPayload(
  Map<String, dynamic> config, {
  required String source,
}) {
  if (!isDegenerateBotPayload(config)) {
    return;
  }
  throw DegenerateBotPayloadException(source);
}

/// Vrai quand [config] est une charge utile de bot DÉCLARÉE — elle annonce au
/// moins une famille d'automatisation — dont toutes les familles sont vides.
///
/// Le second point compte : les poussées de métadonnées (fiche locale d'un app
/// réduite au jeton et au pseudo, portée par `syncBot`) n'annoncent AUCUNE
/// famille. Elles ne sont pas des charges utiles de bot et ne sont donc pas
/// jugées ici ; sinon la garde refuserait des écritures légitimes.
bool isDegenerateBotPayload(Map<String, dynamic> config) {
  var declaresAutomation = false;
  for (final key in botPayloadAutomationKeys) {
    if (!config.containsKey(key)) {
      continue;
    }
    declaresAutomation = true;
    if (_holdsEntries(config[key])) {
      return false;
    }
  }
  return declaresAutomation;
}

/// Une famille « porte » quelque chose dès qu'elle contient une entrée : liste
/// non vide ou map non vide. Toute autre valeur (absente, nulle, scalaire) est
/// traitée comme vide — une charge utile ne se sauve pas avec un `null`.
bool _holdsEntries(Object? family) {
  if (family is Map) {
    return family.isNotEmpty;
  }
  if (family is Iterable) {
    return family.isNotEmpty;
  }
  return false;
}

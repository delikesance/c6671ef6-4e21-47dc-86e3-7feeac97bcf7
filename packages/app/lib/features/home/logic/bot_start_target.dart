import 'package:bot_creator/core/i18n/i18n.dart';

/// Où l'utilisateur veut démarrer son bot.
///
/// Pourquoi ce choix est devenu explicite : l'association du bot décidait à sa
/// place. Un bot associé au manager (`RunnerSettings.getAssociatedRunnerId(botId)
/// == 'manager'`) repartait sur le serveur sans que rien ne le dise, alors que ce
/// chemin CONSOMME des minutes d'hébergement (ou la formule) ; un bot non associé
/// démarrait en local. Deux exécutions aux conséquences très différentes, aucune
/// question posée.
enum BotStartTarget {
  /// Sur ce poste, par le runner embarqué.
  local,

  /// Sur l'infrastructure Bot Creator, financée par les minutes d'hébergement.
  server,
}

/// Une option telle qu'elle doit être présentée : un titre, une conséquence.
class BotStartOption {
  const BotStartOption({
    required this.target,
    required this.title,
    required this.description,
  });

  final BotStartTarget target;
  final String title;
  final String description;
}

/// Ce qui peut être proposé pour un bot, et pourquoi l'autre choix manque.
///
/// L'option impossible est RETIRÉE (décision produit : ne pas proposer une porte
/// qui échouerait), mais sa raison est rendue à part : sans elle, l'utilisateur
/// chercherait où est passée l'option, et le message serait muet.
class BotStartChoices {
  const BotStartChoices({required this.options, this.serverUnavailableReason});

  final List<BotStartOption> options;
  final String? serverUnavailableReason;

  bool get offersServer => options.any((o) => o.target == BotStartTarget.server);
}

/// Construit les choix de démarrage pour un bot, à partir de l'état RÉEL du compte.
///
/// Les conditions du démarrage distant sont celles du serveur, pas une politique
/// inventée ici : il faut pouvoir le joindre (poste de travail ou mobile, mais pas
/// le web qui n'a pas d'accès direct), une session valide, et un financement —
/// formule PREMIUM, ou minutes d'hébergement restantes pour un compte ad-financé.
/// Un compte PREMIUM dont le serveur a coupé l'hébergement cloud n'y a pas droit
/// non plus : c'est un interrupteur de déploiement, pas un droit de la formule.
BotStartChoices resolveBotStartChoices({
  required bool supportsManagerRuntime,
  required bool hasValidSession,
  required bool premium,
  required bool cloudDisabledByServer,
  required int freeMinutesBalance,
  required AppLocalizations tr,
}) {
  final options = <BotStartOption>[
    BotStartOption(
      target: BotStartTarget.local,
      title: tr.bot_start_local_title,
      description: tr.bot_start_local_desc,
    ),
  ];

  String? serverReason;
  if (!supportsManagerRuntime) {
    serverReason = tr.bot_start_server_reason_platform;
  } else if (!hasValidSession) {
    serverReason = tr.bot_start_server_reason_no_account;
  } else if (premium && cloudDisabledByServer) {
    serverReason = tr.bot_start_server_reason_cloud_disabled;
  } else if (!premium && freeMinutesBalance <= 0) {
    serverReason = tr.bot_start_server_reason_no_minutes;
  }

  if (serverReason == null) {
    options.add(
      BotStartOption(
        target: BotStartTarget.server,
        title: tr.bot_start_server_title,
        description: tr.bot_start_server_desc,
      ),
    );
  }

  return BotStartChoices(
    options: options,
    serverUnavailableReason: serverReason,
  );
}

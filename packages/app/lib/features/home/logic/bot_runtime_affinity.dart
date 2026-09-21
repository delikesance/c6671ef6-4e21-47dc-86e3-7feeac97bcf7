import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/network/runner_settings.dart';

/// Enregistre OÙ tourne un bot d'après ce que dit le canal temps réel du serveur.
///
/// Pourquoi c'est nécessaire : l'association du bot (`RunnerSettings`) est ce qui
/// décide où partent les ordres — « manager » pour Bot Creator Server, « local » pour
/// ce poste. Elle était posée uniquement quand l'application DÉMARRAIT le bot
/// elle-même. Un bot lancé depuis un autre appareil (mobile, ou par le manager)
/// n'avait donc aucune association sur ce poste : le bouton Stop résolvait « local »,
/// n'arrêtait rien, et le bot continuait de tourner en consommant des minutes
/// d'hébergement — le bouton semblait simplement « ne pas marcher ».
///
/// Le serveur est la seule autorité sur l'endroit où il exécute un bot : dès qu'il
/// l'annonce en cours d'exécution, la trace devient « manager ». Ce n'est pas un
/// choix d'utilisateur, c'est une constatation — et c'est elle qui rend le Stop
/// efficace quel que soit l'appareil qui a démarré le bot.
///
/// Un bot ANNONCÉ ARRÊTÉ ne modifie rien : après un arrêt, l'association reste celle
/// du dernier démarrage, et rien ne prouve qu'un autre appareil l'a repris.
bool noteManagerReportedRuntime(GatewayBotEventPayload bot) {
  final botId = bot.botId.trim();
  if (botId.isEmpty || !bot.isRunning) return false;
  RunnerSettings.associateBotWithRunner(botId, 'manager');
  return true;
}

// La demande de démarrage au manager, ENCADRÉE par ses traces.
//
// Pourquoi : mesuré chez le propriétaire, l'application annonçait un démarrage sans
// qu'on puisse savoir si la demande était seulement PARTIE, ni ce que le serveur
// avait répondu — `desired_state` restait `STOPPED` côté serveur et rien ne le
// disait. Deux lignes suffisent à rendre la question et la réponse visibles :
// « demande envoyee », puis le RÉSULTAT.
//
// Ce qui n'y apparaît JAMAIS : un jeton (même tronqué) ni le corps brut d'une
// réponse. Un code HTTP et le message applicatif que `MainApiClient` a retenu
// suffisent au diagnostic.
//
// Le texte est rendu à l'appelant, qui l'écrit dans la trace de démarrage : la
// fonction reste donc prouvable sans réseau.

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';

/// Demande au manager de démarrer [botId], en traçant l'envoi puis le résultat.
///
/// [trace] est le même canal que le reste des traces de démarrage ; le succès est
/// tracé ici, le refus aussi, puis l'erreur est RELANCÉE telle quelle pour que le
/// diagnostic d'exécution existant (`describeManagerRuntimeFailure`) et les messages
/// de formule continuent d'être produits par le chemin qui les connaît.
Future<void> requestManagerBotStartWithTraces({
  required MainApiClient client,
  required String botId,
  String? botName,
  required void Function(String trace) trace,
}) async {
  trace('serveur: demande envoyee');
  try {
    await startManagerBotWithCreditRetry(
      client: client,
      botId: botId,
      botName: botName,
    );
  } catch (error) {
    trace('serveur: ${describeManagerStartRefusal(error)}');
    rethrow;
  }
  trace('serveur: accepte');
}

/// « REFUSE (403: message du serveur) », ou la raison brute quand le serveur n'a
/// rien dit d'exploitable.
///
/// [MainApiClientException.message] est EXACTEMENT le message applicatif du serveur
/// (`error` / `message` du corps), jamais le corps entier : c'est ce qui permet de
/// journaliser un refus sans recopier une réponse.
String describeManagerStartRefusal(Object error) {
  if (error is! MainApiClientException) {
    return 'REFUSE (echec sans reponse exploitable du serveur)';
  }
  final code = error.statusCode;
  final message = error.message.trim();
  if (code != null && message.isNotEmpty) {
    return 'REFUSE ($code: $message)';
  }
  if (code != null) {
    return 'REFUSE ($code, sans message)';
  }
  return message.isEmpty
      ? 'REFUSE (sans code ni message)'
      : 'REFUSE (sans code: $message)';
}

// Le Stop doit viser l'endroit où le bot tourne VRAIMENT.
//
// Bug corrigé : l'association du bot (ce qui décide si un ordre part vers Bot Creator
// Server ou vers ce poste) n'était posée que lorsque l'application DÉMARRAIT le bot
// elle-même. Un bot lancé depuis le mobile n'avait donc aucune association sur un poste
// de travail : le Stop résolvait « local », n'arrêtait rien, et le bot continuait de
// tourner — le bouton semblait simplement inopérant.
//
// La règle testée ici : dès que le canal temps réel du serveur annonce un bot en cours
// d'exécution, la trace devient « manager ». C'est une constatation sur ce que fait le
// serveur, pas une préférence d'utilisateur.

import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/home/logic/bot_runtime_affinity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un message du canal temps réel, réduit à ce qui décide ici.
GatewayBotEventPayload _payload({
  required String botId,
  String lastRuntimeState = 'running',
  String desiredState = 'RUNNING',
}) {
  return GatewayBotEventPayload.fromJson(<String, dynamic>{
    'bot_id': botId,
    'bot_name': 'Bot $botId',
    'last_runtime_state': lastRuntimeState,
    'desired_state': desiredState,
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RunnerSettings.resetAssociationsForTests();
  });

  test('un bot que le serveur exécute devient « manager »', () {
    // Aucune association au départ : c'est le cas d'un bot démarré depuis le mobile.
    expect(RunnerSettings.getAssociatedRunnerId('bot-mobile'), isNull);

    final noted = noteManagerReportedRuntime(_payload(botId: 'bot-mobile'));

    expect(noted, isTrue);
    expect(
      RunnerSettings.getAssociatedRunnerId('bot-mobile'),
      'manager',
      reason: 'sans cette trace, le Stop résolverait « local » et n\'arrêterait rien',
    );
  });

  test('un bot déjà localement associé bascule vers le serveur quand il y tourne', () {
    // L'utilisateur l'avait démarré sur ce poste, puis l'a repris depuis le mobile :
    // la trace doit suivre la réalité, sinon le Stop local ne ferait rien pendant que
    // le serveur continue de consommer des minutes.
    RunnerSettings.associateBotWithRunner('bot-1', 'local');

    noteManagerReportedRuntime(_payload(botId: 'bot-1'));

    expect(RunnerSettings.getAssociatedRunnerId('bot-1'), 'manager');
  });

  test('un bot annoncé arrêté ne touche pas à la trace', () {
    // Après un arrêt, rien ne prouve qu'un autre appareil a repris le bot : l'association
    // reste celle du dernier démarrage, et surtout on n'affirme rien de faux.
    RunnerSettings.associateBotWithRunner('bot-1', 'local');

    final noted = noteManagerReportedRuntime(
      _payload(botId: 'bot-1', lastRuntimeState: 'stopped', desiredState: 'STOPPED'),
    );

    expect(noted, isFalse);
    expect(RunnerSettings.getAssociatedRunnerId('bot-1'), 'local');
  });

  test('un identifiant vide est ignoré au lieu d\'écrire une trace fantôme', () {
    final noted = noteManagerReportedRuntime(_payload(botId: '   '));

    expect(noted, isFalse);
    expect(RunnerSettings.getAssociatedRunnerId(''), isNull);
  });

  test('un état désiré « RUNNING » sans état réel posé compte comme en cours', () {
    // Le serveur peut annoncer le démarrage avant d'avoir un état réel : le bot va
    // tourner, donc le Stop devra viser le serveur.
    final noted = noteManagerReportedRuntime(
      _payload(botId: 'bot-2', lastRuntimeState: '', desiredState: 'RUNNING'),
    );

    expect(noted, isTrue);
    expect(RunnerSettings.getAssociatedRunnerId('bot-2'), 'manager');
  });

  test('la trace est écrite dans les préférences (sinon perdue au redémarrage)', () async {
    // Sans cette écriture, le Stop redevient inopérant au prochain lancement de
    // l'application — exactement le bug rapporté. On relit donc le magasin BRUT.
    noteManagerReportedRuntime(_payload(botId: 'bot-3'));

    // L'écriture est asynchrone et non attendue par l'appelant : on laisse la boucle
    // d'événements la terminer avant de relire.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('runner_bot_associations'), contains('bot-3'));
    expect(prefs.getString('runner_bot_associations'), contains('manager'));
  });
}

// Le choix de l'utilisateur doit réellement décider — sinon la pop-up est décorative.
//
// Contexte mesuré : sans choix explicite, `resolveRemoteRuntime` tranche par
// l'ASSOCIATION du bot (`RunnerSettings.getAssociatedRunnerId(botId) == 'manager'` →
// distant, sinon local). C'est ce qui faisait repartir sur Bot Creator Server, sans
// rien dire, un bot qui consomme des minutes d'hébergement.
//
// Ce que ce test verrouille :
//   * l'association décide toujours par défaut (comportement historique conservé) ;
//   * `forcedSource: local` GAGNE sur une association au manager — c'est la promesse
//     de l'option « démarrer en local » ;
//   * `forcedSource: manager` vise le serveur même SANS association — c'est la promesse
//     de l'option « démarrer sur Bot Creator Server ».
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _botId = '1350824555119382678';

/// Compte connecté sur ce poste : sans session, le chemin serveur est impossible —
/// c'est justement ce que la pop-up vérifie avant de le proposer.
Future<void> _connecterLeCompte() async {
  await MainApiSettingsStore.saveConfig(
    const MainApiConfig(baseUrl: 'https://manager-demarrage.test'),
  );
  await MainApiSettingsStore.saveSession(
    MainApiSession(
      accessToken: 'session-de-test',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('par défaut, l\'association au manager décide (comportement historique)', () async {
    // La plateforme se force ET se restaure DANS le corps du test : l'invariant de
    // `flutter_test` vérifie les variables de debug à la fin du corps, un `addTearDown`
    // ou un `setUp` de groupe ne suffit pas.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await _connecterLeCompte();
      RunnerSettings.associateBotWithRunner(_botId, 'manager');

      final runtime = await resolveRemoteRuntime(
        supportsManagerRuntime: true,
        botId: _botId,
      );

      expect(runtime.source, RemoteRuntimeSource.manager);
      expect(runtime.client, isNotNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('« en local » gagne sur une association au manager', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await _connecterLeCompte();
      RunnerSettings.associateBotWithRunner(_botId, 'manager');

      final runtime = await resolveRemoteRuntime(
        supportsManagerRuntime: true,
        botId: _botId,
        forcedSource: RemoteRuntimeSource.local,
      );

      expect(
        runtime.source,
        RemoteRuntimeSource.local,
        reason: 'la pop-up promet un démarrage local : il doit être local',
      );
      expect(runtime.client, isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('« sur le serveur » vise le manager même sans association', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await _connecterLeCompte();

      final runtime = await resolveRemoteRuntime(
        supportsManagerRuntime: true,
        botId: _botId,
        forcedSource: RemoteRuntimeSource.manager,
      );

      expect(runtime.source, RemoteRuntimeSource.manager);
      expect(runtime.client, isNotNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('« sur le serveur » sans session ne bascule PAS en local : elle le dit', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      // Le magasin de réglages garde la session en MÉMOIRE : vider les préférences
      // bouchonnées ne suffit pas à simuler « aucun compte sur ce poste ».
      await MainApiSettingsStore.clearAll();

      final runtime = await resolveRemoteRuntime(
        supportsManagerRuntime: true,
        botId: _botId,
        forcedSource: RemoteRuntimeSource.manager,
      );

      // La cible DEMANDÉE est rendue, sans client : le blocage du repli local devient
      // vrai, donc l'écran explique que le serveur est hors de portée. Exécuter sur la
      // machine autre chose que ce que l'utilisateur a choisi, sans le lui dire, était
      // le mensonge que ce test verrouille désormais.
      expect(runtime.source, RemoteRuntimeSource.manager);
      expect(runtime.client, isNull);
      expect(
        runtime.blocksLocalFallback,
        isTrue,
        reason: 'sinon l\'app demarrerait en local en silence apres un choix « serveur »',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

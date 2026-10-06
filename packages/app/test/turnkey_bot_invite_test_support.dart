// Harnais partagé des tests d'invitation du bot clé en main.
//
// Trois choses doivent être observables pour que ces tests prouvent quelque
// chose :
//   * le NOMBRE et la FORME des requêtes réellement émises (un `MockClient` qui
//     les compte) — c'est lui qui distingue « lien direct » de « résolution par
//     le serveur », et qui prouve qu'un second clic n'ajoute rien ;
//   * l'URI réellement ouverte (un ouvreur injecté) — surtout PAS
//     `openExternalUrl`, qui lance un vrai `xdg-open` sous Linux ;
//   * le texte exact des clés i18n, lu dans l'ARB français : comparer à la valeur
//     du getter seul validerait n'importe quoi, y compris une chaîne vide.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator_ui/src/l10n/app_localizations_fr.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Traduction française de référence des messages d'invitation.
final AppLocalizationsFr tr = AppLocalizationsFr();

/// Texte d'une clé du fichier ARB français, lu à la source du fichier.
String arbFrText(String key) {
  final decoded =
      jsonDecode(File('../ui/lib/src/l10n/app_fr.arb').readAsStringSync())
          as Map<String, dynamic>;
  return decoded[key]?.toString() ?? '';
}

/// Faux manager : répond la décision du test et COMPTE ce qu'il reçoit.
class FakeMainApiManager {
  FakeMainApiManager({
    this.baseUrl = 'https://manager.test',
    this.statusCode = 200,
    this.body = const <String, dynamic>{},
    this.networkFailure = false,
    this.delay = Duration.zero,
  });

  /// Une URL par test quand la panne doit être simulée : le disjoncteur du
  /// client est statique et indexé par URL, une base partagée ferait fuir
  /// l'état d'un test à l'autre.
  final String baseUrl;

  final int statusCode;
  final Map<String, dynamic> body;

  /// Vrai pour simuler une coupure réseau (exception du client HTTP).
  final bool networkFailure;

  /// Délai avant réponse : laisse une requête EN VOL observable, ce dont le
  /// test de double clic a besoin.
  final Duration delay;

  /// Nombre de requêtes HTTP reçues.
  int requests = 0;

  /// Requêtes reçues, dans l'ordre, sous la forme `POST /chemin`.
  final List<String> calls = <String>[];

  MainApiClient client() {
    return MainApiClient(
      baseUrl: baseUrl,
      accessToken: 'jeton-de-test',
      httpClient: MockClient((http.Request request) async {
        requests++;
        calls.add('${request.method} ${request.url.path}');
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
        if (networkFailure) {
          throw http.ClientException('réseau coupé');
        }
        return http.Response(
          jsonEncode(body),
          statusCode,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
  }
}

/// Conteneur clé en main tel que `GET /containers` le renvoie.
///
/// [discordApplicationId] est ABSENT par défaut : c'est l'état des conteneurs
/// déployés avant que le serveur ne mémorise l'identité, donc le chemin qui
/// passe par le manager.
ContainerInfo turnkeyContainer({
  String id = '95d85ac8-bd42-41c6-9392-3a1f0c9b7d21',
  String? discordApplicationId,
  String state = 'RUNNING',
}) {
  final now = DateTime.now().toUtc();
  return ContainerInfo.fromJson(<String, dynamic>{
    'id': id,
    'owner_id': 'owner-1',
    'swarm_service_id': 'svc-1',
    'image': 'ghcr.io/albertgzmz/beatdock:latest',
    'cpu_millis': 250,
    'memory_mb': 256,
    'storage_gb': 1,
    'state': state,
    'discord_application_id': ?discordApplicationId,
    'expires_at': now.add(const Duration(hours: 3)).toIso8601String(),
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });
}

/// Ouvreur enregistreur : aucune fenêtre n'est ouverte, l'URI remise à
/// l'ouvreur est observable. [result] simule un navigateur qui refuse.
Future<bool> Function(Uri) recordingOpener(
  List<Uri> sink, {
  bool result = true,
}) {
  return (Uri uri) async {
    sink.add(uri);
    return result;
  };
}

/// Capture les événements analytics émis pendant un test.
class AnalyticsRecorder {
  final List<String> names = <String>[];
  final List<Map<String, Object>?> parameters = <Map<String, Object>?>[];

  void install() {
    AppAnalytics.debugSetEventObserver((name, params) {
      names.add(name);
      parameters.add(params);
    });
  }

  void uninstall() => AppAnalytics.debugResetObservers();
}

// POSTE DE TRAVAIL (desktop) : la formule et le solde de temps viennent du SERVEUR.
//
// Le propriétaire a été clair : « Desktop ne fournit AUCUNE pub, et le temps pub est
// bien récupéré par le serveur ». Le solde d'hebergement (dont les minutes gagnées par
// pub sur mobile) est donc une valeur serveur (`/containers/eligibility` :
// `hosting_minutes_balance`, `ad_reward_minutes`, `premium`, `plan_tier_code`) : sur un
// poste de travail, l'application doit la LIRE, jamais la déduire de l'OS.
//
// Avant ce lot, `SubscriptionService` répondait « premium » sur desktop sans rien
// demander au serveur (`if (_isDesktop) return true;`) : un compte FREE connecté était
// donc présenté comme premium, avec un solde de temps faux. Le repli « desktop =
// premium » n'est conservé QUE hors connexion, là où le serveur n'est pas joignable.
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Répond comme le manager : `plan` porte la formule, `display_name`/`tier_code`
/// l'identité de la formule.
MainApiClient _clientSaying(String plan) {
  return MainApiClient(
    baseUrl: 'https://api.example.com',
    accessToken: 'token',
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/gateway/runtime')) {
        return http.Response(
          '{"plan":"$plan","display_name":"Pro","tier_code":"PRO"}',
          200,
        );
      }
      return http.Response('not found', 404);
    }),
  );
}

Future<void> _connecter() async {
  await MainApiSettingsStore.saveConfig(
    const MainApiConfig(baseUrl: 'https://api.example.com'),
  );
  await MainApiSettingsStore.saveSession(
    MainApiSession(
      accessToken: 'token',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Un seul levier pour dire « poste de travail » : le seam partagé, que le service et
    // les écrans interrogent de la même façon.
    SubscriptionService.debugSetDesktopForTests(true);
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await MainApiSettingsStore.clearConfig();
    await MainApiSettingsStore.clearSession();
    await SubscriptionService.debugResetForTests();
    SubscriptionService.debugSetDesktopForTests(true);
    MainApiClient.resetCircuitBreakers();
  });

  tearDown(() async {
    SubscriptionService.debugSetDesktopForTests(null);
    debugDefaultTargetPlatformOverride = null;
    await MainApiSettingsStore.clearConfig();
    await MainApiSettingsStore.clearSession();
    await SubscriptionService.debugResetForTests();
  });

  test(
    'poste de travail connecté : une formule FREE du serveur prime sur la supposition locale',
    () async {
      await _connecter();

      final premium = await SubscriptionService.refreshPremiumFromServer(
        client: _clientSaying('FREE'),
        forceRefresh: true,
      );

      expect(
        premium,
        isFalse,
        reason:
            'le serveur vient de dire FREE : sur un poste de travail connecté, la '
            'supposition « desktop = premium » ne doit plus décider',
      );
      expect(SubscriptionService.isSubscribed, isFalse);
    },
  );

  test(
    'poste de travail connecté : une formule PREMIUM du serveur est appliquée telle quelle',
    () async {
      await _connecter();

      final premium = await SubscriptionService.refreshPremiumFromServer(
        client: _clientSaying('PREMIUM'),
        forceRefresh: true,
      );

      expect(premium, isTrue);
      expect(SubscriptionService.isSubscribed, isTrue);
      expect(
        SubscriptionService.activePlanDisplayName,
        'Pro',
        reason: 'la formule affichée doit être celle du serveur, pas une déduction locale',
      );
      expect(SubscriptionService.activePlanTierCode, 'PRO');
    },
  );

  test(
    'poste de travail hors connexion : le repli « premium par défaut » est conservé',
    () async {
      // Manager jamais configuré : le poste de travail n'a rien à interroger, il garde
      // le comportement historique (aucune boutique native ne peut prouver un
      // abonnement sur desktop).
      final premium = await SubscriptionService.refreshPremiumFromServer(
        forceRefresh: true,
      );

      expect(premium, isTrue);
      expect(SubscriptionService.isSubscribed, isTrue);
    },
  );

  test(
    'poste de travail : une formule FREE poussée par le canal temps réel est appliquée',
    () async {
      await _connecter();
      // Le chemin poussé (`account.updated`) ne fait aucune requête : il applique
      // directement l'état annoncé par le serveur.
      await SubscriptionService.applyPushedAccountState(
        const <String, dynamic>{'plan': 'FREE'},
      );

      expect(
        SubscriptionService.isSubscribed,
        isFalse,
        reason: 'un état poussé FREE doit retirer le premium, y compris sur desktop',
      );
    },
  );

  test(
    'aucune publicité à sauter sur un poste de travail : la formule serveur suffit',
    () async {
      await _connecter();

      final canSkipAds = await SubscriptionService.canSkipRewardedAds(
        forceRefresh: true,
        allowStoredManagerSession: false,
      );

      expect(
        canSkipAds,
        isTrue,
        reason:
            'il n\'y a aucune pub à sauter sur desktop : la seule chose qui compte est '
            'que le solde de temps reste celui du serveur',
      );
    },
  );

  test('le forçage « desktop » des tests passe par le seam partagé', () {
    SubscriptionService.debugSetDesktopForTests(true);

    expect(
      isDesktopRunPlatform,
      isTrue,
      reason:
          'une seule notion de poste de travail : si le service et le seam divergeaient, '
          'un test « desktop » pourrait passer en empruntant le chemin mobile',
    );

    SubscriptionService.debugSetDesktopForTests(false);
    expect(isDesktopRunPlatform, isFalse);
  });
}

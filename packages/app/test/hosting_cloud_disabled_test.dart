// L'hébergement cloud est coupé par un INTERRUPTEUR DE DÉPLOIEMENT, pas par la plateforme.
//
// Mesure : le serveur renvoie `premium_cloud_enabled: false` sur le compte de développement
// alors que la cause n'est pas ce compte — côté serveur la condition est
// `plan == PREMIUM && PREMIUM_CLOUD_ENABLED`, le second terme venant de
// `envBoolOrDefault("PREMIUM_CLOUD_ENABLED", false)`. Sans cette information, l'application
// ne pouvait dire qu'un cadenas générique : elle proposait donc de regarder une publicité ou
// d'acheter une formule pour rouvrir un hébergement que le serveur n'a pas activé.
//
// Ce que ce test verrouille :
//   * le drapeau est retenu quand le serveur le dit, et il reste INCONNU quand le serveur ne
//     le dit pas (on n'invente jamais un refus) ;
//   * une remise à zéro (déconnexion, changement de compte) l'oublie : un « non » du compte
//     précédent ne doit pas bloquer le suivant ;
//   * la phrase affichée est bien celle du cloud coupé, distincte de celle des minutes —
//     laquelle propose une publicité, ce que le cas cloud ne peut pas promettre.
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'turnkey_bot_invite_test_support.dart' show arbFrText;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await SubscriptionService.debugResetForTests();
  });

  test('le serveur dit le cloud coupé : l\'app le retient', () async {
    await SubscriptionService.applyPushedAccountState(const <String, dynamic>{
      'plan': 'FREE',
      'premium_cloud_enabled': false,
    });

    expect(SubscriptionService.premiumCloudEnabled, isFalse);
    expect(SubscriptionService.premiumCloudDisabled, isTrue);
  });

  test('cloud activé : l\'app ne bloque aucun déploiement', () async {
    await SubscriptionService.applyPushedAccountState(const <String, dynamic>{
      'plan': 'PREMIUM',
      'premium_cloud_enabled': true,
    });

    expect(SubscriptionService.premiumCloudEnabled, isTrue);
    expect(SubscriptionService.premiumCloudDisabled, isFalse);
  });

  test('champ absent : état INCONNU, aucune affirmation', () async {
    await SubscriptionService.applyPushedAccountState(const <String, dynamic>{
      'plan': 'FREE',
    });

    expect(
      SubscriptionService.premiumCloudEnabled,
      isNull,
      reason: 'un serveur plus ancien ne renvoie pas ce champ : on ne peut rien en déduire',
    );
    expect(
      SubscriptionService.premiumCloudDisabled,
      isFalse,
      reason: 'n\'affirmer « coupé » que sur une parole explicite du serveur',
    );
  });

  test('une remise à zéro oublie l\'interrupteur du compte précédent', () async {
    await SubscriptionService.applyPushedAccountState(const <String, dynamic>{
      'plan': 'FREE',
      'premium_cloud_enabled': false,
    });
    expect(SubscriptionService.premiumCloudDisabled, isTrue);

    await SubscriptionService.debugResetForTests();

    expect(SubscriptionService.premiumCloudEnabled, isNull);
    expect(
      SubscriptionService.premiumCloudDisabled,
      isFalse,
      reason: 'sinon la déconnexion laisserait un refus qui bloquerait le compte suivant',
    );
  });

  test('la phrase du cloud coupé ne promet pas de publicité', () {
    final cloud = arbFrText('container_deploy_blocked_cloud_disabled');
    final minutes = arbFrText('container_deploy_blocked_no_minutes');

    expect(cloud, isNotEmpty, reason: 'la clé doit exister dans l\'ARB français');
    expect(cloud, isNot(minutes), reason: 'deux causes distinctes, deux phrases');
    expect(
      minutes.toLowerCase(),
      contains('publicit'),
      reason:
          'la phrase des minutes propose la publicité récompensée : c\'est exactement ce que la '
          'phrase du cloud coupé ne doit pas faire, puisqu\'aucune pub ne rouvrirait le service',
    );
    expect(
      cloud.toLowerCase(),
      isNot(contains('publicit')),
      reason: 'ne jamais envoyer regarder une publicité qui ne débloquerait rien',
    );
  });
}

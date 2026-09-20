// Contexte SSV des annonces récompensées : ces tests verrouillent ce qui, en
// production, décide si la récompense est créditée ou perdue.
//
// Ils portent sur des fonctions PURES (`ad_ssv_context.dart`), donc sans aucun
// plugin de plateforme : le `custom_data` produit ici est exactement celui que
// `parseAdMobCustomMapping` relit côté Manager.
import 'dart:io';

import 'package:bot_creator/features/ads/logic/ad_ssv_context.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relit `custom_data` comme le fait le Manager (`url.ParseQuery` en Go).
Map<String, String> _queryOf(AdRewardSsvContext context) =>
    Uri.splitQueryString(context.customData!);

void main() {
  group('contexte du flux « app hébergée »', () {
    test('porte owner_id + placement + container_id, et pas de bot_id', () {
      final context = buildHostedAppAdSsvContext(
        ownerId: 'owner-42',
        placement: hostedAppAdSsvPlacement,
        containerId: 'container-abc',
      );

      expect(context, isNotNull);
      expect(context!.hasValues, isTrue);
      expect(context.userId, 'owner-42');

      final query = _queryOf(context);
      expect(query['owner_id'], 'owner-42');
      expect(query['placement'], 'hosted_app_topup');
      expect(query['container_id'], 'container-abc');
      expect(
        query.containsKey('bot_id'),
        isFalse,
        reason: 'Ce flux n\'a pas de bot : un bot_id inventé serait un faux mapping.',
      );
    });

    test('sans container_id connu : owner_id + placement suffisent', () {
      final context = buildHostedAppAdSsvContext(
        ownerId: 'owner-42',
        placement: hostedAppAdSsvPlacement,
      );

      expect(context, isNotNull);
      final query = _queryOf(context!);
      expect(query['owner_id'], 'owner-42');
      expect(query['placement'], 'hosted_app_topup');
      expect(query.containsKey('container_id'), isFalse);
    });

    test('sans owner_id : aucun contexte exploitable (annonce refusée)', () {
      expect(
        buildHostedAppAdSsvContext(
          ownerId: '   ',
          placement: hostedAppAdSsvPlacement,
          containerId: 'container-abc',
        ),
        isNull,
      );
    });
  });

  group('contexte du flux « bot »', () {
    test('porte owner_id + bot_id + placement admob_rewarded', () {
      final context = buildBotAdSsvContext(
        ownerId: 'owner-7',
        botId: '123456789012345678',
      );

      expect(context, isNotNull);
      expect(context!.hasValues, isTrue);
      expect(context.userId, 'owner-7');

      final query = _queryOf(context);
      expect(query['owner_id'], 'owner-7');
      expect(query['bot_id'], '123456789012345678');
      expect(query['placement'], 'admob_rewarded');
      expect(query.containsKey('discord_owner_id'), isFalse);
      expect(
        query.containsKey('container_id'),
        isFalse,
        reason: 'Le flux bot ne connaît pas de conteneur.',
      );
    });

    test('inclut discord_owner_id seulement quand il est connu', () {
      final withDiscord = buildBotAdSsvContext(
        ownerId: 'owner-7',
        botId: '123456789012345678',
        discordOwnerId: '999888777666555444',
      );
      expect(_queryOf(withDiscord!)['discord_owner_id'], '999888777666555444');

      final blankDiscord = buildBotAdSsvContext(
        ownerId: 'owner-7',
        botId: '123456789012345678',
        discordOwnerId: '  ',
      );
      expect(
        _queryOf(blankDiscord!).containsKey('discord_owner_id'),
        isFalse,
        reason: 'Un identifiant Discord vide ne doit pas polluer le callback.',
      );
    });

    test('sans bot_id ou sans owner_id : aucun contexte exploitable', () {
      expect(buildBotAdSsvContext(ownerId: 'owner-7', botId: '  '), isNull);
      expect(
        buildBotAdSsvContext(ownerId: '', botId: '123456789012345678'),
        isNull,
      );
    });
  });

  group('construction partagée du flux bot (accueil + éditeur)', () {
    test('compose le contexte dès que les identifiants sont résolus', () async {
      final context = await buildMainApiAdSsvContext(
        botId: '123456789012345678',
        resolveOwnerIds: () async =>
            const BotAdSsvOwnerIds(ownerId: 'owner-7'),
      );

      expect(context, isNotNull);
      final query = _queryOf(context!);
      expect(query['owner_id'], 'owner-7');
      expect(query['bot_id'], '123456789012345678');
      expect(query['placement'], 'admob_rewarded');
    });

    test('transmet discord_owner_id quand l\'écran sait le résoudre', () async {
      final context = await buildMainApiAdSsvContext(
        botId: '123456789012345678',
        resolveOwnerIds: () async => const BotAdSsvOwnerIds(
          ownerId: 'owner-7',
          discordOwnerId: '999888777666555444',
        ),
      );

      expect(_queryOf(context!)['discord_owner_id'], '999888777666555444');
    });

    test('refuse (null) quand le token/la session manquent', () async {
      var resolverCalled = false;

      final context = await buildMainApiAdSsvContext(
        botId: '123456789012345678',
        resolveOwnerIds: () async {
          resolverCalled = true;
          return null;
        },
      );

      expect(context, isNull);
      expect(resolverCalled, isTrue);
    });

    test('refuse (null) sur un bot_id vide, sans même résoudre le propriétaire',
        () async {
      var resolverCalled = false;

      final context = await buildMainApiAdSsvContext(
        botId: '   ',
        resolveOwnerIds: () async {
          resolverCalled = true;
          return const BotAdSsvOwnerIds(ownerId: 'owner-7');
        },
      );

      expect(context, isNull);
      expect(resolverCalled, isFalse);
    });
  });

  group('AdRewardSsvContext.hasValues', () {
    test('un contexte vide n\'a pas de valeurs (garde-fou du refus)', () {
      expect(const AdRewardSsvContext().hasValues, isFalse);
      expect(const AdRewardSsvContext(userId: '  ').hasValues, isFalse);
      expect(
        const AdRewardSsvContext(customData: '   ').hasValues,
        isFalse,
        reason:
            'C\'est exactement ce cas que `_applySsvContext` refuse désormais.',
      );
      expect(
        const AdRewardSsvContext(userId: 'owner-7').hasValues,
        isTrue,
      );
    });
  });

  group('canShowRewardedAdWithSsv (règle de refus utilisée par le service)', () {
    test('refuse un contexte absent ou vide', () {
      expect(canShowRewardedAdWithSsv(null), isFalse);
      expect(canShowRewardedAdWithSsv(const AdRewardSsvContext()), isFalse);
      expect(
        canShowRewardedAdWithSsv(
          const AdRewardSsvContext(userId: '  ', customData: ''),
        ),
        isFalse,
      );
    });

    test('accepte les contextes réellement produits par les deux flux', () {
      final hosted = buildHostedAppAdSsvContext(
        ownerId: 'owner-42',
        placement: hostedAppAdSsvPlacement,
        containerId: 'container-abc',
      );
      final bot = buildBotAdSsvContext(
        ownerId: 'owner-7',
        botId: '123456789012345678',
      );

      expect(canShowRewardedAdWithSsv(hosted), isTrue);
      expect(canShowRewardedAdWithSsv(bot), isTrue);
    });
  });

  // Garde-fou de câblage : les fonctions pures ci-dessus ne servent à rien si le
  // service ne les appelle pas. Le scan de source est le même outillage que le
  // garde-fou i18n (`test/i18n_guard_test.dart`).
  group('câblage du service d\'annonces', () {
    test('_applySsvContext refuse via canShowRewardedAdWithSsv', () {
      final source = File(
        'lib/features/ads/logic/ad_reward_service.dart',
      ).readAsStringSync();

      expect(source, contains('canShowRewardedAdWithSsv(context)'));
      expect(source, contains('Rewarded ad refused'));
      expect(
        source,
        isNot(contains('if (ssvContext == null || !ssvContext.hasValues) {')),
        reason: 'L\'ancien garde-fou qui montait l\'annonce doit avoir disparu.',
      );
    });

    test('aucun chemin ne monte plus d\'annonce sans SSV '
        '(showRewardedAdNonBlocking supprimé)', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where(
            (file) =>
                file.readAsStringSync().contains('showRewardedAdNonBlocking'),
          )
          .map((file) => file.path)
          .toList(growable: false);

      expect(offenders, isEmpty);
    });
  });
}

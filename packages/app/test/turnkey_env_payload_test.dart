// Le schéma d'environnement d'un template clé en main est DÉCLARATIF : c'est le
// template qui dit quelles variables existent, lesquelles sont secrètes,
// lesquelles ont une valeur par défaut et lesquelles sont imposées par le
// serveur (`fixed` / `source == "node"`). L'app ne suppose AUCUN nom de variable
// (LAVALINK_* n'existe nulle part ici : elle rend ce que le template déclare) et
// n'envoie plus un « TOKEN » en dur.
//
// Ce fichier verrouille les trois maillons : le PARSING de `env_fields_schema`
// (la clé réellement servie par le manager — lue autrefois sous le nom
// `env_fields`, d'où un formulaire toujours vide), le PAYLOAD construit pour le
// déploiement, et le FORMULAIRE (un champ par variable, verrouillé en lecture
// seule quand le serveur impose la valeur).
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_templates.dart';
import 'package:bot_creator/features/containers/logic/turnkey_env_payload.dart';
import 'package:bot_creator/features/containers/presentation/turnkey_env_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Réponse type du manager : le schéma est servi sous `env_fields_schema`, avec
/// des variables de natures différentes (token, saisie libre avec défaut, valeur
/// imposée par un nœud, valeur figée, variable sans valeur déclarée).
Map<String, dynamic> _schemaJson() => <String, dynamic>{
  'title': 'Test Bot',
  'image': 'ghcr.io/example/test-bot:latest',
  'category': 'music',
  'env_fields_schema': <Map<String, dynamic>>[
    <String, dynamic>{
      'key': 'TOKEN',
      'label': 'Discord token',
      'required': true,
      'secret': true,
      'default_value': '',
      'fixed': false,
      'source': '',
    },
    <String, dynamic>{
      'key': 'LAVALINK_URL',
      'label': 'Lavalink URL',
      'required': false,
      'secret': false,
      'default_value': 'ws://node:2333',
    },
    <String, dynamic>{
      'key': 'NODE_PASSWORD',
      'label': 'Node password',
      'required': true,
      'secret': true,
      'source': 'node',
      'source_node_id': 'node-1',
      'source_variable': 'node.password',
    },
    <String, dynamic>{
      'key': 'REGION',
      'label': 'Region',
      'required': false,
      'fixed': true,
      'default_value': 'eu-west',
    },
    <String, dynamic>{
      'key': 'NODE_ID',
      'label': 'Node id',
      'required': false,
      'source': 'node',
      'source_variable': 'node.id',
    },
  ],
};

HostedAppTemplate _template() => HostedAppTemplate.fromJson(_schemaJson());

HostedAppEnvField _field(String key) =>
    _template().envFields.firstWhere((f) => f.key == key);

void main() {
  group('HostedAppTemplate.fromJson — schéma d’environnement', () {
    test('lit env_fields_schema (la clé réellement servie) et tout le schéma', () {
      final template = _template();

      // NON-VACUITÉ : avant le correctif, cette liste était TOUJOURS vide (la clé
      // lue était `env_fields`, absente de la réponse du manager).
      expect(
        template.envFields,
        isNotEmpty,
        reason:
            'le schéma doit être lu sous `env_fields_schema` — une liste vide '
            'signifie que l’app lit encore la mauvaise clé',
      );
      expect(
        template.envFields.map((f) => f.key),
        <String>[
          'TOKEN',
          'LAVALINK_URL',
          'NODE_PASSWORD',
          'REGION',
          'NODE_ID',
        ],
        reason: 'aucun nom de variable ne doit être filtré ni renommé',
      );
    });

    test('conserve label / required / secret / default_value', () {
      final token = _field('TOKEN');
      expect(token.displayLabel, 'Discord token');
      expect(token.required, isTrue);
      expect(token.secret, isTrue);
      expect(token.defaultValue, isEmpty);

      final url = _field('LAVALINK_URL');
      expect(url.displayLabel, 'Lavalink URL');
      expect(url.required, isFalse);
      expect(url.secret, isFalse);
      expect(url.defaultValue, 'ws://node:2333');
    });

    test('lit fixed / source / source_variable et en déduit le verrouillage', () {
      final region = _field('REGION');
      expect(region.fixed, isTrue);
      expect(region.source, isEmpty);
      expect(region.isLocked, isTrue, reason: 'fixed => champ verrouillé');

      final nodePassword = _field('NODE_PASSWORD');
      expect(nodePassword.source, 'node');
      expect(nodePassword.nodeVariable, 'node.password');
      expect(
        nodePassword.isLocked,
        isTrue,
        reason: 'source "node" => la valeur vient du nœud d’hébergement',
      );

      final nodeId = _field('NODE_ID');
      expect(nodeId.fixed, isFalse);
      expect(nodeId.isLocked, isTrue);
      expect(nodeId.defaultValue, isEmpty);

      expect(_field('TOKEN').isLocked, isFalse);
      expect(_field('LAVALINK_URL').isLocked, isFalse);
    });

    test('repli : env_fields reste accepté (réponse plus ancienne)', () {
      final template = HostedAppTemplate.fromJson(<String, dynamic>{
        'title': 'Legacy',
        'image': 'legacy:latest',
        'env_fields': <Map<String, dynamic>>[
          <String, dynamic>{'key': 'TOKEN', 'secret': true},
        ],
      });
      expect(template.envFields.length, 1);
      expect(template.envFields.first.key, 'TOKEN');
    });

    test('le préfixe LAVALINK n’est jamais supposé : un schéma sans lui reste lu', () {
      final template = HostedAppTemplate.fromJson(<String, dynamic>{
        'title': 'Sans préfixe connu',
        'image': 'x:latest',
        'env_fields_schema': <Map<String, dynamic>>[
          <String, dynamic>{'key': 'MON_SUPER_REGLAGE', 'default_value': 'v'},
        ],
      });
      expect(template.envFields.single.key, 'MON_SUPER_REGLAGE');
      expect(template.envFields.single.defaultValue, 'v');
    });
  });

  group('buildTurnkeyEnvPayload', () {
    test('le token du champ dédié alimente la variable TOKEN déclarée', () {
      final payload = buildTurnkeyEnvPayload(
        template: _template(),
        botToken: 'MON-TOKEN-DISCORD',
      );

      expect(payload['TOKEN'], 'MON-TOKEN-DISCORD');
      // Contrôle de non-vacuité : sans token saisi, la clé ne peut PAS être
      // remplie — donc la valeur ci-dessus vient bien du champ token dédié et pas
      // d'une valeur vide devenue « présente » par accident.
      final withoutToken = buildTurnkeyEnvPayload(
        template: _template(),
        botToken: '   ',
      );
      expect(
        withoutToken.containsKey('TOKEN'),
        isFalse,
        reason:
            'un token vide ne doit pas produire une clé TOKEN (mapping '
            'insensible à la casse, mais pas à une valeur vide)',
      );
    });

    test('la valeur par défaut du template part quand l’utilisateur ne saisit rien', () {
      final payload = buildTurnkeyEnvPayload(
        template: _template(),
        botToken: 'token',
      );

      expect(payload['LAVALINK_URL'], 'ws://node:2333');
      expect(
        payload['LAVALINK_URL'],
        isNotEmpty,
        reason: 'le défaut déclaré doit réellement être transmis',
      );
    });

    test('la valeur saisie par l’utilisateur prime sur le défaut', () {
      final payload = buildTurnkeyEnvPayload(
        template: _template(),
        botToken: 'token',
        userValues: <String, String>{'LAVALINK_URL': 'ws://mon-noeud:443'},
      );

      expect(payload['LAVALINK_URL'], 'ws://mon-noeud:443');
    });

    test('un champ verrouillé n’est jamais écrasé par une saisie', () {
      final payload = buildTurnkeyEnvPayload(
        template: _template(),
        botToken: 'token',
        userValues: <String, String>{
          'REGION': 'us-east',
          'NODE_ID': 'noeud-pirate',
          'NODE_PASSWORD': 'mot-de-passe-invente',
        },
      );

      // REGION est figé par le serveur avec une valeur déclarée : c'est la valeur
      // déclarée qui part, pas la saisie.
      expect(payload['REGION'], 'eu-west');
      // NODE_ID et NODE_PASSWORD sont alimentés par le nœud et n'ont AUCUNE valeur
      // déclarée : la clé ne part pas du tout — le serveur l'impose, l'app
      // n'invente rien.
      expect(payload.containsKey('NODE_ID'), isFalse);
      expect(payload.containsKey('NODE_PASSWORD'), isFalse);
    });

    test('les clés vides et les valeurs vides sont ignorées', () {
      final template = HostedAppTemplate.fromJson(<String, dynamic>{
        'title': 'Vides',
        'image': 'x:latest',
        'env_fields_schema': <Map<String, dynamic>>[
          <String, dynamic>{'key': 'TOKEN', 'secret': true},
          <String, dynamic>{'key': 'VIDE', 'default_value': '   '},
          <String, dynamic>{'key': '', 'default_value': 'orpheline'},
          <String, dynamic>{'key': '   ', 'default_value': 'orpheline'},
        ],
      });

      final payload = buildTurnkeyEnvPayload(
        template: template,
        botToken: 'token',
        userValues: <String, String>{'VIDE': '  ', 'AUTRE': 'inconnu'},
      );

      expect(payload, <String, String>{'TOKEN': 'token'});
    });

    test('un template sans schéma n’invente aucune variable', () {
      final template = HostedAppTemplate.fromJson(<String, dynamic>{
        'title': 'Sans env',
        'image': 'x:latest',
        'env_fields_schema': <dynamic>[],
      });

      expect(
        buildTurnkeyEnvPayload(template: template, botToken: 'token'),
        isEmpty,
        reason:
            'l’app ne doit plus envoyer un TOKEN en dur quand le template ne '
            'déclare rien',
      );
    });

    test('le token est reconnu quelle que soit la casse de la clé déclarée', () {
      final template = HostedAppTemplate.fromJson(<String, dynamic>{
        'title': 'Casse',
        'image': 'x:latest',
        'env_fields_schema': <Map<String, dynamic>>[
          <String, dynamic>{'key': 'token', 'secret': true},
        ],
      });

      final payload = buildTurnkeyEnvPayload(
        template: template,
        botToken: 'token-minuscule',
      );
      expect(payload['token'], 'token-minuscule');
      expect(payload.containsKey('TOKEN'), isFalse);
    });

    test('sélection des champs du formulaire : le token reste à part', () {
      final template = _template();
      expect(
        turnkeyUserEnvFields(template).map((f) => f.key),
        <String>['LAVALINK_URL', 'NODE_PASSWORD', 'REGION', 'NODE_ID'],
        reason:
            'le token a son champ dédié sur l’écran ; il ne doit pas être rendu '
            'deux fois',
      );
      expect(
        turnkeyTokenEnvFields(template).map((f) => f.key),
        <String>['TOKEN'],
      );
    });
  });

  group('TurnkeyEnvFieldsSection — formulaire', () {
    /// Monte la section seule, avec SES contrôleurs (ceux de l'écran de
    /// déploiement) : la pré-saisie vient du template, pas du test.
    Future<void> pumpSection(
      WidgetTester tester, {
      required HostedAppTemplate template,
      GlobalKey<FormState>? formKey,
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: TurnkeyEnvFieldsSection(template: template),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    /// Champ (TextFormField) portant le libellé [label].
    Finder fieldWithLabel(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(TextFormField),
    );

    testWidgets('un champ verrouillé est en LECTURE SEULE et annoncé comme fourni '
        'par le serveur', (WidgetTester tester) async {
      final tr = await AppLocalizations.delegate.load(const Locale('fr'));
      await pumpSection(tester, template: _template());

      final locked = fieldWithLabel('Region');
      expect(locked, findsOneWidget);
      expect(
        tester.widget<TextField>(find.descendant(
          of: locked,
          matching: find.byType(TextField),
        )).enabled,
        isFalse,
        reason:
            'une valeur imposée par le serveur ne doit pas être saisissable',
      );
      expect(
        find.descendant(of: locked, matching: find.byIcon(Icons.lock_outline)),
        findsOneWidget,
        reason: 'le cadenas signale le champ verrouillé',
      );
      expect(
        find.descendant(
          of: locked,
          matching: find.text(tr.container_deploy_env_server_provided),
        ),
        findsOneWidget,
        reason:
            'le libellé « ${tr.container_deploy_env_server_provided} » doit '
            'expliquer pourquoi le champ est figé',
      );
      // La valeur déclarée par le template est montrée (même valeur que celle
      // transmise au déploiement), mais elle n'est pas modifiable.
      expect(
        find.descendant(of: locked, matching: find.text('eu-west')),
        findsOneWidget,
      );
    });

    testWidgets('un champ du schéma est pré-rempli avec sa valeur par défaut',
        (WidgetTester tester) async {
      await pumpSection(tester, template: _template());

      final url = fieldWithLabel('Lavalink URL');
      expect(url, findsOneWidget);
      expect(
        find.descendant(of: url, matching: find.text('ws://node:2333')),
        findsOneWidget,
        reason:
            'le défaut déclaré par le template (et non un nom de variable '
            'supposé par l’app) doit pré-remplir le champ',
      );
      expect(
        tester.widget<TextField>(find.descendant(
          of: url,
          matching: find.byType(TextField),
        )).enabled,
        isTrue,
        reason: 'un champ libre reste saisissable',
      );

      // Le token a son propre champ sur l'écran de déploiement : la section ne le
      // rend pas (sinon il serait saisi deux fois).
      expect(find.text('Discord token'), findsNothing);

      // Un champ secret verrouillé (NODE_PASSWORD, alimenté par le nœud) est lui
      // aussi en lecture seule, et masqué.
      final nodePassword = fieldWithLabel('Node password');
      expect(nodePassword, findsOneWidget);
      expect(
        tester.widget<TextField>(find.descendant(
          of: nodePassword,
          matching: find.byType(TextField),
        )).enabled,
        isFalse,
      );
    });

    testWidgets('un champ requis vide bloque la validation', (WidgetTester tester) async {
      final tr = await AppLocalizations.delegate.load(const Locale('fr'));
      final formKey = GlobalKey<FormState>();
      final template = HostedAppTemplate.fromJson(<String, dynamic>{
        'title': 'Requis',
        'image': 'x:latest',
        'env_fields_schema': <Map<String, dynamic>>[
          <String, dynamic>{'key': 'TOKEN', 'secret': true},
          <String, dynamic>{
            'key': 'CLIENT_ID',
            'label': 'Client ID',
            'required': true,
            'default_value': '',
          },
        ],
      });
      await pumpSection(tester, template: template, formKey: formKey);

      final clientId = fieldWithLabel('Client ID');

      // CLIENT_ID est déclaré REQUIS par le template et n'a aucune valeur par
      // défaut : le formulaire ne doit pas se valider en l'état.
      expect(
        formKey.currentState!.validate(),
        isFalse,
        reason: 'un champ requis sans valeur déclarée doit bloquer le lancement',
      );
      await tester.pump();
      expect(
        find.text(tr.container_deploy_env_field_required('Client ID')),
        findsOneWidget,
        reason: 'l’erreur doit dire QUEL champ du schéma manque',
      );

      await tester.enterText(clientId, '1234567890');
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(
        find.text(tr.container_deploy_env_field_required('Client ID')),
        findsNothing,
      );
    });
  });
}

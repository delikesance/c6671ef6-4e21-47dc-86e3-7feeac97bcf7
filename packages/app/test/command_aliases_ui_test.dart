import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/entry_point_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Harnais qui reproduit le parent réel : la liste d'alias est contrôlée par
/// l'état local et remontée à chaque changement, comme `CommandCreatePage`.
class _AliasesHarness extends StatefulWidget {
  const _AliasesHarness({
    required this.initialAliases,
    required this.owners,
    required this.onChanged,
  });

  final List<String> initialAliases;
  final Map<String, String> owners;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_AliasesHarness> createState() => _AliasesHarnessState();
}

class _AliasesHarnessState extends State<_AliasesHarness> {
  late List<String> _aliases;

  @override
  void initState() {
    super.initState();
    _aliases = List<String>.of(widget.initialAliases);
  }

  @override
  Widget build(BuildContext context) {
    return EntryPointBlock(
      entryPointType: CommandEntryPointType.message,
      onEntryPointTypeChanged: (_) {},
      legacyModeEnabled: true,
      legacyAliases: _aliases,
      onLegacyAliasesChanged: (aliases) {
        setState(() => _aliases = aliases);
        widget.onChanged(aliases);
      },
      legacyAliasOwners: widget.owners,
    );
  }
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// Le champ de saisie des alias : le `TextField` interne du formulaire,
  /// identifié par son libellé localisé (`TextFormField` n'expose ni
  /// `decoration` ni `enabled`, seuls ses paramètres de construction).
  Finder aliasField() => find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.labelText == l10n.command_alias_label,
  );

  /// La chip d'un alias donné. Les recherches sont cadrées sur les chips :
  /// le `hintText` du champ vaut littéralement `!p`, un `find.text('!p')`
  /// global matcherait aussi le texte d'aide affiché quand le champ est vide.
  Finder aliasChip(String alias) =>
      find.descendant(of: find.byType(InputChip), matching: find.text(alias));

  Future<void> pumpBlock(
    WidgetTester tester, {
    List<String> aliases = const <String>[],
    Map<String, String> owners = const <String, String>{},
    required ValueChanged<List<String>> onChanged,
  }) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: _AliasesHarness(
              initialAliases: aliases,
              owners: owners,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // La configuration Message Texte est repliée par défaut.
    await tester.tap(find.text(l10n.scratch_legacy_config));
    await tester.pumpAndSettle();
  }

  Future<void> submitAlias(WidgetTester tester, String raw) async {
    await tester.enterText(aliasField(), raw);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('Entrée ajoute l\'alias normalisé et vide le champ', (
    tester,
  ) async {
    final received = <List<String>>[];
    await pumpBlock(tester, onChanged: received.add);

    await submitAlias(tester, 'p');

    expect(received, <List<String>>[
      <String>['p'],
    ]);
    expect(aliasChip('!p'), findsOneWidget);
    expect(tester.widget<TextField>(aliasField()).controller?.text, isEmpty);
  });

  testWidgets('un doublon est refusé avec un message d\'erreur', (
    tester,
  ) async {
    final received = <List<String>>[];
    await pumpBlock(
      tester,
      aliases: const <String>['p'],
      onChanged: received.add,
    );

    // « P » est un doublon de « p » : le parent n'est jamais notifié.
    await submitAlias(tester, 'P');

    expect(received, isEmpty);
    expect(find.text(l10n.command_alias_duplicate), findsOneWidget);
    expect(aliasChip('!p'), findsOneWidget);
  });

  testWidgets('la croix d\'une chip retire l\'alias', (tester) async {
    final received = <List<String>>[];
    await pumpBlock(
      tester,
      aliases: const <String>['p', 'c'],
      onChanged: received.add,
    );

    expect(aliasChip('!p'), findsOneWidget);
    expect(aliasChip('!c'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, '!p'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();

    expect(received, <List<String>>[
      <String>['c'],
    ]);
    expect(aliasChip('!p'), findsNothing);
    expect(aliasChip('!c'), findsOneWidget);
  });

  testWidgets('à 10 alias le champ est désactivé et la limite s\'affiche', (
    tester,
  ) async {
    final aliases = List<String>.generate(10, (index) => 'a$index');
    await pumpBlock(tester, aliases: aliases, onChanged: (_) {});

    expect(find.byType(InputChip), findsNWidgets(10));
    expect(find.text(l10n.command_alias_limit(10)), findsOneWidget);
    expect(tester.widget<TextField>(aliasField()).enabled, isFalse);
  });

  testWidgets('les entrées sales sont normalisées avant d\'être remontées', (
    tester,
  ) async {
    final received = <List<String>>[];
    await pumpBlock(tester, onChanged: received.add);

    // Espaces + majuscule → minuscule sans espaces.
    await submitAlias(tester, '  P ');
    // Préfixe `!` saisi par l'utilisateur → retiré.
    await submitAlias(tester, '!c');

    expect(received, <List<String>>[
      <String>['p'],
      <String>['p', 'c'],
    ]);
  });

  testWidgets(
    'plusieurs alias séparés par des virgules sont ajoutés d\'un coup',
    (tester) async {
      final received = <List<String>>[];
      await pumpBlock(tester, onChanged: received.add);

      await tester.enterText(aliasField(), 'p, c,');
      await tester.pumpAndSettle();

      // Une seule mise à jour, avec tous les fragments terminés.
      expect(received, <List<String>>[
        <String>['p', 'c'],
      ]);
      expect(tester.widget<TextField>(aliasField()).controller?.text, isEmpty);
    },
  );

  testWidgets('un alias porté par une autre commande est signalé', (
    tester,
  ) async {
    await pumpBlock(
      tester,
      aliases: const <String>['p'],
      owners: const <String, String>{'p': 'ping'},
      onChanged: (_) {},
    );

    final warning = find.textContaining(l10n.command_alias_collision('ping'));
    expect(warning, findsOneWidget);

    // Avertissement non bloquant : l'alias reste supprimable.
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, '!p'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();

    expect(warning, findsNothing);
  });
}

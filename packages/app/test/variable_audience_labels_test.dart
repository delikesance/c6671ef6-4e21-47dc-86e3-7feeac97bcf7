// Variables are described by who they are for, never by the raw scope name or by "globale / scopée".
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scoped_variables_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _scopes = [
  'global',
  'guild',
  'guildMember',
  'user',
  'channel',
  'message',
];

Future<BuildContext> _context(WidgetTester tester, Locale locale) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  for (final locale in [const Locale('fr'), const Locale('en')]) {
    testWidgets(
      'every audience has a readable label and an example (${locale.languageCode})',
      (tester) async {
        final context = await _context(tester, locale);
        final labels = <String>{};
        for (final scope in _scopes) {
          final label = scopedVariableScopeLabel(context, scope);
          final description = scopedVariableScopeDescription(context, scope);
          expect(
            label,
            isNot(scope),
            reason: '$scope must not leak its raw name',
          );
          expect(
            label,
            isNot(anyOf('guild', 'channel', 'message', 'serveur', 'salon')),
          );
          expect(description.length, greaterThan(20), reason: scope);
          labels.add(label);
        }
        expect(
          labels,
          hasLength(_scopes.length),
          reason: 'two audiences must never share a label',
        );
      },
    );
  }

  testWidgets('French wording: no more "globale" or "scopée" for variables', (
    tester,
  ) async {
    final context = await _context(tester, const Locale('fr'));
    final t = AppLocalizations.of(context);
    expect(
      scopedVariableScopeLabel(context, 'guildMember'),
      'Chaque membre (par serveur)',
    );
    expect(
      scopedVariableScopeLabel(context, 'user'),
      'Chaque utilisateur (tous serveurs)',
    );
    expect(scopedVariableScopeLabel(context, 'global'), 'Tout le bot');
    for (final text in [
      t.globals_tab,
      t.globals_mode_global,
      t.globals_mode_scoped,
      t.globals_add_global,
      t.globals_add_scoped,
      t.globals_empty,
      t.scoped_title,
      t.scoped_empty,
      t.modules_desc_globals,
      t.action_name_setScopedVariable,
      t.action_name_getGlobalVariable,
    ]) {
      expect(text.toLowerCase(), isNot(contains('scopé')), reason: text);
      expect(text.toLowerCase(), isNot(contains('globale')), reason: text);
    }
    expect(t.globals_tab, 'Variables');
  });
}

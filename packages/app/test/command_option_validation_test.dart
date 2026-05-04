import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

CommandOptionBuilder _opt(
  CommandOptionType type,
  String name, {
  String description = 'desc',
  bool? isRequired,
  List<CommandOptionBuilder>? options,
  List<CommandOptionChoiceBuilder>? choices,
  num? minValue,
  num? maxValue,
}) {
  final b = CommandOptionBuilder(
    type: type,
    name: name,
    description: description,
    isRequired: isRequired ?? false,
    minValue: minValue,
    maxValue: maxValue,
  );
  if (options != null) b.options = options;
  if (choices != null) b.choices = choices;
  return b;
}

Future<String?> _validate(WidgetTester tester, List<CommandOptionBuilder> options,
    {int level = 0, CommandOptionType? parentType}) async {
  String? result;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: widgets.Builder(builder: (context) {
      result = validateOptionsForLevel(context, options,
          level: level, parentType: parentType);
      return const SizedBox();
    }),
  ));
  return result;
}

void main() {
  group('validateOptionsForLevel', () {
    // ── Valid cases ──────────────────────────────────────────────────────────

    testWidgets('valid flat command (only leaf options)', (tester) async {
      final options = [
        _opt(CommandOptionType.string, 'msg', isRequired: true),
        _opt(CommandOptionType.user, 'target'),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNull,
      );
    });

    testWidgets('valid subcommand-only root', (tester) async {
      final options = [
        _opt(CommandOptionType.subCommand, 'ping', options: []),
        _opt(CommandOptionType.subCommand, 'pong', options: []),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNull,
      );
    });

    testWidgets('valid group/subcommand tree', (tester) async {
      final options = [
        _opt(
          CommandOptionType.subCommandGroup,
          'admin',
          options: [
            _opt(
              CommandOptionType.subCommand,
              'ban',
              options: [
                _opt(CommandOptionType.user, 'target', isRequired: true),
              ],
            ),
            _opt(CommandOptionType.subCommand, 'kick', options: []),
          ],
        ),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNull,
      );
    });

    testWidgets('empty option list is valid', (tester) async {
      expect(await _validate(tester, [], level: 0, parentType: null), isNull);
    });

    // ── Cardinalité ──────────────────────────────────────────────────────────

    testWidgets('rejects more than 25 options at the same level',
        (tester) async {
      final options = List.generate(
        26,
        (i) => _opt(CommandOptionType.string, 'opt$i'),
      );
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNotNull,
      );
    });

    // ── Mélange root flat + subcommands ──────────────────────────────────────

    testWidgets('rejects mix of subcommands and leaf options at root',
        (tester) async {
      final options = [
        _opt(CommandOptionType.subCommand, 'ping', options: []),
        _opt(CommandOptionType.string, 'extra'),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNotNull,
      );
    });

    // ── Contraintes de contenu des groupes ───────────────────────────────────

    testWidgets('rejects non-subCommand inside a subCommandGroup',
        (tester) async {
      final options = [_opt(CommandOptionType.string, 'bad')];
      expect(
        await _validate(tester, options,
            level: 1, parentType: CommandOptionType.subCommandGroup),
        isNotNull,
      );
    });

    testWidgets('rejects hierarchy type inside a subCommand', (tester) async {
      final options = [
        _opt(CommandOptionType.subCommand, 'nested', options: []),
      ];
      expect(
        await _validate(tester, options,
            level: 1, parentType: CommandOptionType.subCommand),
        isNotNull,
      );
    });

    // ── Profondeur maximale ───────────────────────────────────────────────────

    testWidgets('rejects subCommandGroup at level > 0', (tester) async {
      final nested = [
        _opt(CommandOptionType.subCommandGroup, 'deep', options: []),
      ];
      expect(
        await _validate(tester, nested, level: 1, parentType: null),
        isNotNull,
      );
    });

    testWidgets('rejects subCommand at level > 1 (detected via recursive call)',
        (tester) async {
      // group -> subCommand -> subCommand  (level 2 subcommand is illegal)
      final options = [
        _opt(
          CommandOptionType.subCommandGroup,
          'g',
          options: [
            _opt(
              CommandOptionType.subCommand,
              'sub',
              options: [
                _opt(CommandOptionType.subCommand, 'deepsub', options: []),
              ],
            ),
          ],
        ),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNotNull,
      );
    });

    // ── Noms dupliqués ───────────────────────────────────────────────────────

    testWidgets('rejects duplicate option names at the same level',
        (tester) async {
      final options = [
        _opt(CommandOptionType.string, 'msg'),
        _opt(CommandOptionType.string, 'msg'),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNotNull,
      );
    });

    // ── Nom/description manquants ─────────────────────────────────────────────

    testWidgets('rejects option with empty name', (tester) async {
      final options = [
        _opt(CommandOptionType.string, '', description: 'some desc'),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNotNull,
      );
    });

    testWidgets('rejects option with empty description', (tester) async {
      final options = [_opt(CommandOptionType.string, 'msg', description: '')];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNotNull,
      );
    });

    // ── Contraintes isRequired / choices / minMax sur types hiérarchiques ─────

    testWidgets('rejects isRequired=true on a subCommand', (tester) async {
      final options = [
        _opt(
          CommandOptionType.subCommand,
          'ping',
          isRequired: true,
          options: [],
        ),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNotNull,
      );
    });

    testWidgets('rejects choices on a subCommandGroup', (tester) async {
      final options = [
        _opt(
          CommandOptionType.subCommandGroup,
          'admin',
          choices: [CommandOptionChoiceBuilder(name: 'x', value: 'x')],
          options: [],
        ),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNotNull,
      );
    });

    testWidgets('rejects minValue on a subCommand', (tester) async {
      final options = [
        _opt(CommandOptionType.subCommand, 'ping', minValue: 1, options: []),
      ];
      expect(
        await _validate(tester, options, level: 0, parentType: null),
        isNotNull,
      );
    });
  });
}

import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_ast.dart';
import 'package:test/test.dart';

Action _role(
  String? key, {
  BotCreatorActionType type = BotCreatorActionType.addRole,
  bool enabled = true,
  Map<String, String> error = const {},
  Map<String, dynamic>? payload,
}) => Action(
  type: type,
  key: key,
  enabled: enabled,
  payload: {'userId': '1', 'roleId': '2', ...?payload},
)..error.addAll(error);

Action _if(
  String key, {
  List<Action> then = const [],
  List<Action> otherwise = const [],
  List<Map<String, dynamic>> elseIf = const [],
  Map<String, dynamic>? extra,
}) => Action(
  type: BotCreatorActionType.ifBlock,
  key: key,
  payload: {
    'variable': 'a',
    'operator': 'equals',
    'value': '1',
    'thenActions': then.map((a) => a.toJson()).toList(),
    'elseActions': otherwise.map((a) => a.toJson()).toList(),
    if (elseIf.isNotEmpty) 'elseIfConditions': elseIf,
    ...?extra,
  },
);

String _name(BdfdStatement statement) =>
    (statement.node as BdfdFunctionCallAst).name;

void main() {
  group('BdfdProgram.fromStatements', () {
    test('wraps hand-built statements and validates locations', () {
      const source = 'first call\nsecond call';
      final program = BdfdProgram.fromStatements(source, [
        BdfdExpression(BdfdFunctionCallAst(name: 'a', start: 0, end: 10)),
        BdfdExpression(BdfdFunctionCallAst(name: 'b', start: 11, end: 22)),
      ]);
      expect(program.source, source);
      expect(program.statements.map(_name), ['a', 'b']);
      expect(
        () => program.statements.add(program.statements.first),
        throwsUnsupportedError,
      );
      final location = BdfdLocation(source, 11, functionName: 'b');
      expect([location.line, location.column], [2, 1]);
    });

    test('executes on the runtime like a parsed program', () async {
      final seen = <String>[];
      final runtime = BdfdRuntime(
        functions: {
          'probe': BdfdNativeFunction(
            minArguments: 1,
            maxArguments: 1,
            handler: (call) async {
              seen.add('${await call.argument(0)}@${call.location.line}');
              return '';
            },
          ),
        },
      );
      const source = 'line one\nline two';
      final program = BdfdProgram.fromStatements(source, [
        BdfdExpression(
          BdfdFunctionCallAst(
            name: 'probe',
            arguments: [
              [BdfdTextAst('x')],
            ],
            start: 0,
            end: 8,
          ),
        ),
        BdfdExpression(
          BdfdFunctionCallAst(
            name: 'probe',
            arguments: [
              [BdfdTextAst('y')],
            ],
            start: 9,
            end: 17,
          ),
        ),
      ]);
      await runtime.executeProgram(program);
      expect(seen, ['x@1', 'y@2']);
    });

    test('parsing a script still works', () {
      final program = BdfdProgram.parse(r'$c[a]$c[b]');
      expect(program.statements, hasLength(2));
    });
  });

  group('ActionTranslator.supports', () {
    const translator = ActionTranslator();
    test('addRole and removeRole grants and replacements', () {
      expect(translator.supports(_role('a')), isTrue);
      expect(
        translator.supports(_role('a', type: BotCreatorActionType.removeRole)),
        isTrue,
      );
      expect(
        translator.supports(
          _role(
            'a',
            payload: {
              'setRoles': ['1'],
            },
          ),
        ),
        isTrue,
      );
    });

    test('role definitions are native; unmigrated types are not', () {
      expect(
        translator.supports(_role('a', payload: {'createNew': true})),
        isTrue,
      );
      expect(
        translator.supports(_role('a', payload: {'modify': true})),
        isTrue,
      );
      expect(
        translator.supports(
          Action(type: BotCreatorActionType.updateGuild, payload: {}),
        ),
        isFalse,
      );
    });

    test('an ifBlock is native only when all its children are', () {
      expect(translator.supports(_if('i', then: [_role('a')])), isTrue);
      expect(
        translator.supports(
          _if(
            'i',
            then: [_role('a')],
            otherwise: [
              Action(type: BotCreatorActionType.createPoll, payload: {}),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        translator.supports(
          _if(
            'i',
            elseIf: [
              {
                'variable': 'a',
                'actions': [
                  Action(
                    type: BotCreatorActionType.updateGuild,
                    payload: {},
                  ).toJson(),
                ],
              },
            ],
          ),
        ),
        isFalse,
      );
      expect(
        translator.supports(
          _if(
            'i',
            then: [
              _if('j', then: [_role('a')]),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('blocks with their own error handling are native too', () {
      expect(translator.supports(_if('i', extra: {'tryCatch': true})), isTrue);
      expect(
        translator.supports(_if('i', extra: {'suppressErrors': true})),
        isTrue,
      );
      for (final mode in [
        {'mode': 'skip', 'skipCount': '1'},
        {'mode': 'jump', 'jumpToActionId': 'z'},
        {'mode': 'continue'},
      ]) {
        expect(translator.supports(_if('i')..error.addAll(mode)), isTrue);
      }
      // Still all-or-nothing: an unsupported child keeps the block historical.
      expect(
        translator.supports(
          _if(
            'i',
            extra: {'tryCatch': true},
            otherwise: [
              Action(type: BotCreatorActionType.createPoll, payload: {}),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('an undecodable child leaves the block historical', () {
      expect(
        translator.supports(
          Action(
            type: BotCreatorActionType.ifBlock,
            payload: {
              'thenActions': [
                {'type': 'doesNotExist'},
              ],
            },
          ),
        ),
        isFalse,
      );
    });

    test('none() supports nothing', () {
      expect(const ActionTranslator.none().supports(_role('a')), isFalse);
    });
  });

  group('ActionTranslator.translate', () {
    const translator = ActionTranslator();

    test('one statement per action, disabled ones as no-ops', () {
      final result = translator.translate([
        _role('a'),
        _role('b', enabled: false),
        _role(null, type: BotCreatorActionType.removeRole),
      ]);
      expect(result.program.statements.map(_name), [
        'bc_addRole',
        'c',
        'bc_removeRole',
      ]);
      expect(result.topLevel.map((r) => r.key), ['a', 'b', 'action_2']);
      expect(result.topLevel.map((r) => r.ordinal), [1, 2, 3]);
    });

    test('the synthetic source has one line per action and valid ranges', () {
      final result = translator.translate([
        _role('a'),
        _role('b', enabled: false),
      ]);
      final source = result.program.source;
      expect(source.split('\n').where((l) => l.isNotEmpty), [
        '#1 addRole key=a',
        '#2 addRole key=b (disabled)',
      ]);
      for (final statement in result.program.statements) {
        final node = statement.node;
        final location = BdfdLocation(source, node.start!);
        expect(result.refs[location.line]!.action, isNotNull);
        expect(source.substring(node.start!, node.end!), startsWith('#'));
      }
      expect(result.refs[1]!.key, 'a');
      expect(result.refs[2]!.action.enabled, isFalse);
    });

    test('arguments are literal data: key, payload JSON and options', () {
      final result = translator.translate([
        _role('a', payload: {'reason': r'$weird;]((x))'}),
      ]);
      final call = result.program.statements.single.node as BdfdFunctionCallAst;
      final texts = [
        for (final argument in call.arguments)
          (argument.single as BdfdTextAst).value,
      ];
      expect(texts[0], 'a');
      expect(texts[1], contains(r'$weird;]((x))'));
      expect(texts[2], '{"path":[]}');
    });

    test('the translated Action model is not modified', () {
      final action = _role('a', error: {'mode': 'continue'});
      final before = action.toJson().toString();
      translator.translate([
        action,
        _if('i', then: [_role('c')]),
      ]);
      expect(action.toJson().toString(), before);
    });

    test('error modes become call options; jump targets become ordinals', () {
      final result = translator.translate([
        _role('stop'),
        _role('continue', error: {'mode': 'continue'}),
        _role('skip', error: {'mode': 'skip', 'skipCount': '2'}),
        _role('skip0', error: {'mode': 'skip'}),
        _role('jump', error: {'mode': 'jump', 'jumpToActionId': 'target'}),
        _role('back', error: {'mode': 'jump', 'jumpToActionId': 'stop'}),
        _role('byId', error: {'mode': 'jump', 'jumpToActionId': 'id9'}),
        _role('x', payload: {'_actionId': 'id9'}),
        _role('target'),
      ]);
      String options(int index) =>
          ((result.program.statements[index].node as BdfdFunctionCallAst)
                      .arguments[2]
                      .single
                  as BdfdTextAst)
              .value;
      expect(options(0), '{"path":[]}');
      expect(options(1), '{"path":[],"mode":"continue"}');
      expect(options(2), '{"path":[],"mode":"skip","count":2}');
      expect(options(3), '{"path":[],"mode":"continue"}');
      expect(options(4), '{"path":[],"mode":"jump","ordinal":9}');
      expect(options(5), '{"path":[]}'); // backwards: fails like stop
      expect(options(6), '{"path":[],"mode":"jump","ordinal":8}');
    });

    test('top-level error modes can be left to the caller', () {
      final result = translator.translate([
        _role('a', error: {'mode': 'continue'}),
      ], topLevelErrorModes: false);
      final call = result.program.statements.single.node as BdfdFunctionCallAst;
      expect((call.arguments[2].single as BdfdTextAst).value, '{"path":[]}');
    });

    test('ifBlock becomes a conditional with one body per branch', () {
      final result = translator.translate([
        _if(
          'gate',
          then: [_role('a'), _role('off', enabled: false)],
          elseIf: [
            {
              'variable': 'a',
              'value': '2',
              'actions': [_role('b').toJson()],
            },
          ],
          otherwise: [_role('c')],
        ),
      ]);
      final statement = result.program.statements.single as BdfdConditional;
      expect(statement.branches, hasLength(3));
      expect(statement.branches.map((b) => b.body.length), [2, 1, 1]);
      expect(statement.branches[2].condition, isNull);
      expect(
        statement.branches
            .take(2)
            .map((b) => (b.condition!.single as BdfdFunctionCallAst).name),
        everyElement('bc_cond'),
      );
      // Children keep their own ordinals and sit under the block's key.
      final refs = result.refs.values.where((r) => !r.topLevel).toList();
      expect(refs.map((r) => r.key), ['a', 'off', 'b', 'c']);
      expect(refs.map((r) => r.ordinal), [1, 2, 1, 1]);
      expect(refs.every((r) => r.path.single == 'gate'), isTrue);
      expect(result.topLevel.single.key, 'gate');
    });

    test('an unsupported action cannot be translated', () {
      expect(
        () => translator.translate([
          Action(type: BotCreatorActionType.updateGuild, payload: {}),
        ]),
        throwsArgumentError,
      );
    });

    test('acknowledgement metadata follows executeVisualWorkflow', () {
      expect(_metadata([]).shouldAutoDefer, isTrue);
      final withModal = _metadata([BotCreatorActionType.respondWithModal]);
      expect(withModal.hasModal, isTrue);
      expect(withModal.shouldAutoDefer, isFalse);
      final withDefer = _metadata([BotCreatorActionType.deferInteraction]);
      expect(withDefer.hasDefer, isTrue);
      expect(withDefer.shouldAutoDefer, isFalse);
      expect(translator.translate([]).shouldAutoDefer, isFalse);
      final hint = const ActionTranslator().translate([
        Action(
          type: BotCreatorActionType.respondWithMessage,
          enabled: false,
          payload: {'ephemeral': true},
        ),
      ]);
      expect(hint.ephemeralHint, isTrue);
      expect(_metadata([]).ephemeralHint, isFalse);
    });
  });
}

/// Metadata for a list holding [extra] types (disabled, so they translate).
BdfdActionProgram _metadata(List<BotCreatorActionType> extra) =>
    const ActionTranslator().translate([
      _role('a'),
      for (final type in extra) Action(type: type, enabled: false, payload: {}),
    ]);

import 'dart:convert';

import '../../../services/action_condition.dart' show parseActionBooleanFlag;
import '../../../types/action.dart';
import '../../../utils/bdfd_ast.dart';
import '../loop_syntax.dart';
import '../program.dart';
import 'action_functions.dart';
import 'admin_actions.dart';
import 'channel_actions.dart';
import 'component_actions.dart';
import 'control_flow_actions.dart';
import 'control_flow_state.dart';
import 'emoji_actions.dart';
import 'guild_actions.dart';
import 'image_actions.dart';
import 'invite_actions.dart';
import 'listener_actions.dart';
import 'member_actions.dart';
import 'message_actions.dart';
import 'moderation_actions.dart';
import 'music_actions.dart';
import 'role_actions.dart';
import 'variable_actions.dart';
import 'webhook_actions.dart';

/// Where a statement of a translated program comes from, for diagnostics and
/// error bookkeeping.
class ActionRef {
  ActionRef({
    required this.action,
    required this.key,
    required this.ordinal,
    required this.path,
    required this.topLevel,
  });
  final Action action;

  /// `action.key ?? 'action_<index>'`, the key of its `results` entry.
  final String key;

  /// 1-based position in its own list, the number `$skipActions` and
  /// `$jumpToAction` count.
  final int ordinal;

  /// Result keys of the enclosing blocks.
  final List<String> path;
  final bool topLevel;
}

/// A native program for a list of actions plus what the runner needs to know
/// about the list.
class BdfdActionProgram {
  BdfdActionProgram({
    required this.program,
    required this.refs,
    required this.topLevel,
    required this.hasModal,
    required this.hasDefer,
    required this.ephemeralHint,
  });
  final BdfdProgram program;

  /// Statement origin by line of the synthetic source (1-based).
  final Map<int, ActionRef> refs;

  /// The actions of the translated list, in order.
  final List<ActionRef> topLevel;

  /// A `respondWithModal` is present: it must be the first response, so the
  /// interaction must not be auto-deferred.
  final bool hasModal;

  /// A `deferInteraction` is present: it acknowledges the interaction itself.
  final bool hasDefer;

  /// The auto-defer, if any, must be ephemeral: `respondWithMessage` with
  /// `ephemeral: true` (a deferral cannot change visibility afterwards).
  final bool ephemeralHint;

  /// Same predicate as `executeVisualWorkflow`: acknowledge before the actions
  /// unless the list does it (or opens a modal) itself.
  bool get shouldAutoDefer => !hasDefer && !hasModal && topLevel.isNotEmpty;
}

/// Translates visual actions into native BDFD programs, directly as AST (no
/// BDFD text is generated or parsed, so data never needs escaping).
///
/// The translation is pure: it reads the [Action] model, never changes it, and
/// performs no effect. One statement per action, disabled ones included (as
/// `$c`), so `skip`/`jump` ordinals and result keys keep their meaning.
///
/// Routing is per action ([supports]) and static: an unsupported action keeps
/// running on the historical executor, and nothing is ever retried on the other
/// engine after a failure.
class ActionTranslator {
  const ActionTranslator() : _enabled = true;

  /// Supports nothing: every action stays on the historical executors. Used to
  /// run the historical path in parity tests.
  const ActionTranslator.none() : _enabled = false;

  final bool _enabled;

  static final _leafPredicates = <BotCreatorActionType, bool Function(Action)>{
    BotCreatorActionType.addRole: supportsRoleAction,
    BotCreatorActionType.removeRole: supportsRoleAction,
    ...variableLeafPredicates,
    ...moderationLeafPredicates,
    ...guildLeafPredicates,
    ...channelLeafPredicates,
    ...controlLeafPredicates,
    ...messageLeafPredicates,
    ...componentLeafPredicates,
    ...listenerLeafPredicates,
    ...adminLeafPredicates,
    ...webhookLeafPredicates,
    ...emojiLeafPredicates,
    ...memberLeafPredicates,
    ...inviteLeafPredicates,
    ...musicLeafPredicates,
    ...imageLeafPredicates,
  };

  /// Whether [action] runs on the native engine. A leaf needs a handler (and a
  /// payload variant the handler covers). A block (`ifBlock`, `forLoop`,
  /// `jsonForEachLoop`) is native only when every action of every list it owns
  /// is: otherwise the whole block stays historical.
  bool supports(Action action) {
    if (!_enabled) return false;
    if (visualBlockTypes.contains(action.type)) return _supportsBlock(action);
    final predicate = _leafPredicates[action.type];
    return predicate != null &&
        bdfdVisualActionHandlers.containsKey(action.type) &&
        predicate(action);
  }

  bool _supportsBlock(Action action) {
    try {
      for (final list in _childLists(action)) {
        for (final child in list.actions) {
          if (!supports(child)) return false;
        }
      }
    } catch (_) {
      return false; // Invalid nested action: the historical path reports it.
    }
    return true;
  }

  static bool _isTryCatch(Action action) =>
      action.type == BotCreatorActionType.ifBlock &&
      action.payload['tryCatch'] == true;

  static bool _suppresses(Action action) =>
      action.type == BotCreatorActionType.ifBlock &&
      !_isTryCatch(action) &&
      parseActionBooleanFlag(action.payload['suppressErrors']);

  static List<Action> _decode(dynamic raw) => [
    if (raw is List)
      for (final item in raw)
        if (item is Map) Action.fromJson(Map<String, dynamic>.from(item)),
  ];

  /// The lists of actions a block owns (their children's own support decides).
  List<_Branch> _childLists(Action action) {
    switch (action.type) {
      case BotCreatorActionType.ifBlock:
        if (_isTryCatch(action)) {
          return [
            _Branch(0, action.payload, _decode(action.payload['thenActions'])),
            _Branch(-1, const {}, _decode(action.payload['elseActions'])),
          ];
        }
        return _branches(action.payload);
      default:
        return [
          _Branch(0, action.payload, _decode(action.payload['bodyActions'])),
        ];
    }
  }

  List<_Branch> _branches(Map<String, dynamic> payload) {
    List<Action> decode(dynamic raw) => [
      if (raw is List)
        for (final item in raw)
          if (item is Map) Action.fromJson(Map<String, dynamic>.from(item)),
    ];
    final branches = <_Branch>[
      _Branch(0, payload, decode(payload['thenActions'])),
    ];
    final elseIf = payload['elseIfConditions'];
    if (elseIf is List) {
      for (var index = 0; index < elseIf.length; index++) {
        final entry = elseIf[index];
        if (entry is! Map) continue;
        final map = Map<String, dynamic>.from(entry);
        branches.add(_Branch(index + 1, map, decode(map['actions'])));
      }
    }
    final otherwise = decode(payload['elseActions']);
    if (otherwise.isNotEmpty) branches.add(_Branch(-1, const {}, otherwise));
    return branches;
  }

  /// Translate [actions]. [firstIndex] is the position of the first action in
  /// its real list (default result keys are `action_<index>`).
  /// [topLevelErrorModes] false leaves the per-action error mode of the
  /// translated list itself to the caller (the historical loop owns it when it
  /// routes one action at a time); nested lists always carry theirs.
  BdfdActionProgram translate(
    List<Action> actions, {
    int firstIndex = 0,
    bool topLevelErrorModes = true,
  }) {
    final source = _Source();
    final refs = <int, ActionRef>{};
    final topLevel = <ActionRef>[];
    final statements = _list(
      actions,
      const [],
      0,
      firstIndex,
      topLevelErrorModes,
      false,
      source,
      refs,
      topLevel,
    );
    return BdfdActionProgram(
      program: BdfdProgram.fromStatements(source.text, statements),
      refs: refs,
      topLevel: topLevel,
      hasModal: actions.any(
        (a) => a.type == BotCreatorActionType.respondWithModal,
      ),
      hasDefer: actions.any(
        (a) => a.type == BotCreatorActionType.deferInteraction,
      ),
      ephemeralHint: actions.any(
        (a) =>
            a.type == BotCreatorActionType.respondWithMessage &&
            a.payload['ephemeral'] == true,
      ),
    );
  }

  static const _conditionKeys = [
    'condition.group',
    'group',
    'condition.conditions',
    'conditions',
    'condition.negate',
    'negate',
    'condition.variable',
    'variable',
    'condition.operator',
    'operator',
    'condition.value',
    'value',
  ];

  /// [errorModes]: apply the per-action error modes of this list. [protected]:
  /// the list runs inside a try/catch or suppressErrors block, whose actions
  /// (and everything nested in them) always fail outright, ignoring modes.
  List<BdfdStatement> _list(
    List<Action> actions,
    List<String> path,
    int depth,
    int firstIndex,
    bool errorModes,
    bool protected,
    _Source source,
    Map<int, ActionRef> refs,
    List<ActionRef> topLevel,
  ) {
    final statements = <BdfdStatement>[];
    for (var index = 0; index < actions.length; index++) {
      final action = actions[index];
      final key = action.key ?? 'action_${firstIndex + index}';
      final ordinal = index + 1;
      final label =
          '${'  ' * depth}#$ordinal ${action.type.name} key=$key'
          '${action.enabled ? '' : ' (disabled)'}';
      final range = source.add(label);
      refs[source.lines] = ActionRef(
        action: action,
        key: key,
        ordinal: ordinal,
        path: path,
        topLevel: depth == 0,
      );
      if (depth == 0) topLevel.add(refs[source.lines]!);

      BdfdFunctionCallAst call(String name, List<String> args) =>
          BdfdFunctionCallAst(
            name: name,
            arguments: [
              for (final arg in args)
                [BdfdTextAst(arg, start: range.$1, end: range.$2)],
            ],
            start: range.$1,
            end: range.$2,
          );

      if (!action.enabled) {
        // A no-op that still occupies its ordinal.
        statements.add(BdfdExpression(call('c', ['disabled'])));
        continue;
      }
      if (!supports(action)) {
        throw ArgumentError(
          'Action type ${action.type.name} has no native translation.',
        );
      }
      final modes = !protected && (depth > 0 || errorModes);
      if (visualBlockTypes.contains(action.type)) {
        final block = _block(
          action,
          key,
          path,
          depth,
          protected,
          call,
          source,
          refs,
          topLevel,
        );
        final options = _options(action, actions, index, path, modes);
        final mode = options['mode'];
        if (mode != null) {
          // The block's own error mode: its failure is caught here and the
          // mode applied to this list (a request made from the catch body).
          if (action.type != BotCreatorActionType.ifBlock) {
            options['loop'] = block.loopId;
          }
          statements.add(
            BdfdTry(
              block.statement.node,
              [block.statement],
              [
                BdfdExpression(
                  call(bdfdVisualBlockErrorFunction, [
                    key,
                    action.type.name,
                    jsonEncode(path),
                    jsonEncode(options),
                  ]),
                ),
              ],
            ),
          );
        } else {
          statements.add(block.statement);
        }
        continue;
      }
      statements.add(
        BdfdExpression(
          call(bdfdVisualFunctionFor(action.type), [
            key,
            jsonEncode(action.payload),
            jsonEncode(_options(action, actions, index, path, modes)),
          ]),
        ),
      );
    }
    return statements;
  }

  _Block _block(
    Action action,
    String key,
    List<String> path,
    int depth,
    bool protected,
    BdfdFunctionCallAst Function(String, List<String>) call,
    _Source source,
    Map<int, ActionRef> refs,
    List<ActionRef> topLevel,
  ) {
    List<BdfdStatement> children(
      List<Action> list,
      List<String> childPath,
      bool childrenProtected,
    ) => _list(
      list,
      childPath,
      depth + 1,
      0,
      true,
      childrenProtected,
      source,
      refs,
      topLevel,
    );

    if (action.type != BotCreatorActionType.ifBlock) {
      return _loop(action, key, path, protected, call, children, source);
    }
    final childPath = [...path, key];
    final node = call('bc_ifBlock', const []);
    if (_isTryCatch(action)) {
      final id = source.nextId();
      final args = [id, key, jsonEncode(path)];
      return _Block(
        BdfdTry(
          node,
          children(_decode(action.payload['thenActions']), childPath, true),
          children(_decode(action.payload['elseActions']), childPath, true),
          enter: call(bdfdVisualTryEnterFunction, args),
          onCatch: call(bdfdVisualTryCatchFunction, [key, jsonEncode(path)]),
          exit: call(bdfdVisualTryExitFunction, [id]),
        ),
      );
    }
    final suppress = _suppresses(action);
    final branches = <BdfdBranch>[];
    for (final branch in _branches(action.payload)) {
      var body = children(branch.actions, childPath, protected || suppress);
      if (suppress && body.isNotEmpty) {
        // Only the selected branch is protected; an empty one has nothing to
        // fail. The failure is swallowed (and reported) by `bc_suppress`.
        body = [
          BdfdTry(node, body, [
            BdfdExpression(
              call(bdfdVisualSuppressFunction, [
                key,
                jsonEncode({
                  for (final name in const [
                    'suppressErrorsMessage',
                    'suppressErrorsEmbed',
                  ])
                    if (action.payload.containsKey(name))
                      name: action.payload[name],
                }),
                jsonEncode(path),
              ]),
            ),
          ]),
        ];
      }
      if (branch.index < 0) {
        branches.add(BdfdBranch(null, body));
        continue;
      }
      branches.add(
        BdfdBranch([
          call(bdfdVisualConditionFunction, [
            key,
            '${branch.index}',
            jsonEncode({
              for (final name in _conditionKeys)
                if (branch.payload.containsKey(name))
                  name: branch.payload[name],
            }),
            jsonEncode(path),
          ]),
        ], body),
      );
    }
    return _Block(BdfdConditional(node, branches));
  }

  /// `forLoop` / `jsonForEachLoop`: a native `$while` whose condition,
  /// `bc_loopnext`, publishes the `_loop.*` variables and counts the iterations.
  /// Each iteration's results live under `<key>.iter<N>` (see
  /// [visualIterationMarker]).
  _Block _loop(
    Action action,
    String key,
    List<String> path,
    bool protected,
    BdfdFunctionCallAst Function(String, List<String>) call,
    List<BdfdStatement> Function(List<Action>, List<String>, bool) children,
    _Source source,
  ) {
    final id = source.nextId();
    final body = _decode(action.payload['bodyActions']);
    final descriptor = <String, dynamic>{
      for (final entry in action.payload.entries)
        if (entry.key != 'bodyActions') entry.key: entry.value,
      'empty': body.isEmpty,
      if (action.type == BotCreatorActionType.jsonForEachLoop)
        'loopType': 'json',
    };
    final next = call(bdfdVisualLoopFunction, [
      id,
      key,
      jsonEncode(descriptor),
      jsonEncode(path),
    ]);
    final syntax = BdfdLoopSyntax.parse(
      BdfdFunctionCallAst(
        name: 'while',
        arguments: [
          [next],
        ],
        start: next.start,
        end: next.end,
      ),
    );
    final node = BdfdFunctionCallAst(
      name: 'bc_${action.type.name}',
      arguments: [
        [next],
      ],
      start: next.start,
      end: next.end,
    );
    return _Block(
      BdfdLoop(
        node,
        children(body, [...path, key, '$visualIterationMarker$id'], protected),
        syntax,
      ),
      loopId: id,
    );
  }

  /// Call options: where the action's results live and what a failure does.
  /// Returns a mutable map.
  Map<String, dynamic> _options(
    Action action,
    List<Action> siblings,
    int index,
    List<String> path,
    bool modes,
  ) {
    final options = <String, dynamic>{'path': path};
    if (action.type == BotCreatorActionType.jumpToAction) {
      _jumpTable(options, action, siblings, index);
    }
    if (!modes) return options;
    switch (action.onErrorMode) {
      case ActionOnErrorMode.stop:
        break;
      case ActionOnErrorMode.continueMode:
        options['mode'] = 'continue';
      case ActionOnErrorMode.skip:
        // A count of zero falls through to the next action, like `continue`.
        options['mode'] = 'continue';
        if (action.skipCount > 0) {
          options
            ..['mode'] = 'skip'
            ..['count'] = action.skipCount;
        }
      case ActionOnErrorMode.jump:
        final target = action.jumpToActionId;
        if (target != null) {
          final targetIndex = siblings.indexWhere(
            (a) =>
                (a.key != null && a.key == target) ||
                a.payload['_actionId'] == target,
          );
          // Only forward: anything else fails like the default mode.
          if (targetIndex > index) {
            options
              ..['mode'] = 'jump'
              ..['ordinal'] = targetIndex + 1;
          }
        }
    }
    return options;
  }

  /// What `jumpToAction` needs to turn its target into an ordinal of its own
  /// list: every sibling's key and `_actionId` (first match wins, as in the
  /// historical lookup), its own position and the list length (a target may be
  /// a 1-based position).
  void _jumpTable(
    Map<String, dynamic> options,
    Action action,
    List<Action> siblings,
    int index,
  ) {
    final targets = <String, int>{};
    for (var i = 0; i < siblings.length; i++) {
      final sibling = siblings[i];
      final names = [sibling.key, sibling.payload['_actionId']?.toString()];
      for (final name in names) {
        if (name != null) targets.putIfAbsent(name, () => i + 1);
      }
    }
    options
      ..['own'] = index + 1
      ..['count'] = siblings.length
      ..['targets'] = targets;
  }
}

class _Block {
  _Block(this.statement, {this.loopId});
  final BdfdStatement statement;
  final String? loopId;
}

class _Branch {
  _Branch(this.index, this.payload, this.actions);

  /// 0 = `if`, n = n-th `else if`, -1 = `else`.
  final int index;
  final Map<String, dynamic> payload;
  final List<Action> actions;
}

/// The synthetic source behind a translated program: one line per action
/// (`#3 addRole key=welcome`), so locations, error details and replay frames
/// point at the action.
class _Source {
  final _buffer = StringBuffer();
  int lines = 0;
  int _ids = 0;
  String get text => _buffer.toString();

  /// A name unique within the program, for block state at run time.
  String nextId() => 't${_ids++}';

  (int, int) add(String line) {
    final start = _buffer.length;
    _buffer.write(line);
    final end = _buffer.length;
    _buffer.write('\n');
    lines++;
    return (start, end);
  }
}

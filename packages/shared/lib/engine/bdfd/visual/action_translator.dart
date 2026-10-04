import 'dart:convert';

import '../../../services/action_condition.dart' show parseActionBooleanFlag;
import '../../../types/action.dart';
import '../../../utils/bdfd_ast.dart';
import '../program.dart';
import 'action_functions.dart';
import 'role_actions.dart';

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

  static const _leafPredicates = <BotCreatorActionType, bool Function(Action)>{
    BotCreatorActionType.addRole: supportsRoleAction,
    BotCreatorActionType.removeRole: supportsRoleAction,
  };

  /// Whether [action] runs on the native engine. A leaf needs a handler (and a
  /// payload variant the handler covers). An `ifBlock` is native only when every
  /// action of every branch is: otherwise the whole block stays historical.
  bool supports(Action action) {
    if (!_enabled) return false;
    if (action.type == BotCreatorActionType.ifBlock) return _supportsIf(action);
    final predicate = _leafPredicates[action.type];
    return predicate != null &&
        bdfdVisualActionHandlers.containsKey(action.type) &&
        predicate(action);
  }

  bool _supportsIf(Action action) {
    final payload = action.payload;
    // try/catch and suppressErrors blocks keep the historical error handling.
    if (payload['tryCatch'] == true ||
        parseActionBooleanFlag(payload['suppressErrors'])) {
      return false;
    }
    // jump/skip on a block would need a flow request made from its catch body,
    // which the interpreter would consume inside that body.
    final mode = action.onErrorMode;
    if (mode != ActionOnErrorMode.stop &&
        mode != ActionOnErrorMode.continueMode) {
      return false;
    }
    try {
      for (final branch in _branches(payload)) {
        for (final child in branch.actions) {
          if (!supports(child)) return false;
        }
      }
    } catch (_) {
      return false; // Invalid nested action: the historical path reports it.
    }
    return true;
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

  List<BdfdStatement> _list(
    List<Action> actions,
    List<String> path,
    int depth,
    int firstIndex,
    bool errorModes,
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
      final modes = depth > 0 || errorModes;
      if (action.type == BotCreatorActionType.ifBlock) {
        final block = _ifBlock(
          action,
          key,
          path,
          depth,
          call,
          source,
          refs,
          topLevel,
        );
        if (modes && action.onErrorMode == ActionOnErrorMode.continueMode) {
          statements.add(
            BdfdTry(
              block.node,
              [block],
              [
                BdfdExpression(
                  call(bdfdVisualBlockErrorFunction, [
                    key,
                    action.type.name,
                    jsonEncode(path),
                  ]),
                ),
              ],
            ),
          );
        } else {
          statements.add(block);
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

  BdfdConditional _ifBlock(
    Action action,
    String key,
    List<String> path,
    int depth,
    BdfdFunctionCallAst Function(String, List<String>) call,
    _Source source,
    Map<int, ActionRef> refs,
    List<ActionRef> topLevel,
  ) {
    final node = call('bc_ifBlock', const []);
    final branches = <BdfdBranch>[];
    for (final branch in _branches(action.payload)) {
      final children = _list(
        branch.actions,
        [...path, key],
        depth + 1,
        0,
        true,
        source,
        refs,
        topLevel,
      );
      if (branch.index < 0) {
        branches.add(BdfdBranch(null, children));
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
        ], children),
      );
    }
    return BdfdConditional(node, branches);
  }

  /// Call options: where the action's results live and what a failure does.
  Map<String, dynamic> _options(
    Action action,
    List<Action> siblings,
    int index,
    List<String> path,
    bool modes,
  ) {
    final options = <String, dynamic>{'path': path};
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
  String get text => _buffer.toString();

  (int, int) add(String line) {
    final start = _buffer.length;
    _buffer.write(line);
    final end = _buffer.length;
    _buffer.write('\n');
    lines++;
    return (start, end);
  }
}

import 'dart:async';
import 'dart:math' as math;

import '../../utils/bdfd_ast.dart';
import '../../services/json_document.dart';
import '../../services/time_operations.dart';
import '../../services/text_operations.dart';
import '../../services/math_operations.dart';
import '../../services/text_utility_operations.dart'
    show bdfdDecimalInteger, bdfdFiniteDecimal;
import '../../services/http_service.dart';
import '../../utils/bdfd_functions.dart';
import '../../utils/math_parser.dart';
import '../../utils/template_resolver.dart';
import '../execution_budget.dart';
import 'program.dart';
import 'loop_syntax.dart';

String removeBdfdLinks(String text) =>
    text.replaceAll(RegExp(r'https?://[^\s<>]+', caseSensitive: false), '');

/// Shared by nested scripts; adapters own the actual Discord acknowledgement.
class BdfdResponseState {
  bool acknowledged = false;

  /// Set by an explicit `$defer`; the adapter owns the Discord acknowledgement.
  bool deferred = false;
  bool originalResponseCompleted = false;
  bool ephemeral = false;
  String? messageId;
}

/// Optional message adapter. Only statement output reaches this sink;
/// evaluated arguments remain data and never become implicit responses.
abstract interface class BdfdOutput {
  void append(String text);
  Future<void> flush(BdfdContext context, BdfdLocation location);
  void discard();
}

/// Optional response builder capability used by native error policies.
abstract interface class BdfdErrorOutput {
  void replaceErrorEmbed(Map<String, dynamic> embed);
}

class _UserFunction {
  _UserFunction(this.definition, this.program);
  final BdfdFunctionDefinition definition;
  final BdfdProgram program;
}

class _FunctionFrame {
  _FunctionFrame(this.arguments);
  final Map<String, String> arguments;
  String? returnValue;
}

/// Observations emitted by the interpreter, never by compiled block actions.
class BdfdTraceEvent {
  const BdfdTraceEvent({
    required this.kind,
    required this.status,
    required this.location,
    required this.scriptDepth,
    required this.functionDepth,
    this.value,
    this.branch,
    this.iteration,
    this.durationMicroseconds,
  });
  final String kind;
  final String status;
  final BdfdLocation location;
  final int scriptDepth;
  final int functionDepth;
  final String? value;
  final int? branch;
  final int? iteration;
  final int? durationMicroseconds;
}

class BdfdContext {
  BdfdContext({
    Map<String, String>? variables,
    Map<String, String>? temporaryVariables,
    CommandExecutionBudget? budget,
    BdfdResponseState? response,
    Set<String>? activeWorkflows,
    math.Random? random,
    DateTime Function()? clock,
    this.output,
    this.onTrace,
    this.maxSteps = 100000,
    this.maxDepth = 128,
  }) : variables = variables ?? {},
       temporaryVariables = temporaryVariables ?? {},
       budget = budget ?? CommandExecutionBudget(),
       response = response ?? BdfdResponseState(),
       activeWorkflows = activeWorkflows ?? {},
       random = random ?? math.Random(),
       time = BdfdTimeState(clock: clock);

  final Map<String, String> variables;
  final Map<String, String> temporaryVariables;
  final Map<String, String> results = {};
  JsonDocument json = JsonDocument();
  final TextSplitState textSplit = TextSplitState();
  final HttpSession http = HttpSession();
  final CommandExecutionBudget budget;
  final BdfdResponseState response;
  final Set<String> activeWorkflows;

  /// Optional hook mapping a canvas image source to loadable bytes (data URL
  /// or base64). Hosts such as the sandbox use it to supply local fixtures.
  Future<String> Function(String source)? imageSourceResolver;

  /// Callbacks run once, before the buffered output is flushed (for example to
  /// render canvases that must be attached to the response).
  final List<Future<void> Function()> beforeFlush = [];

  /// Receives `$log` messages; hosts decide where diagnostics go.
  void Function(String message)? onLog;

  /// Shared by nested execution; injectable to reproduce random choices in tests.
  final math.Random random;
  final BdfdTimeState time;

  /// Math and random decimals are disabled by default and shared by nested code.
  bool decimalsEnabled = false;
  bool removeLinks = false;
  bool suppressErrorLogging = false;
  String? _suppressedError;
  Map<String, dynamic>? _errorEmbed;
  final Map<String, _UserFunction> _userFunctions = {};
  final List<_FunctionFrame> _functionFrames = [];
  int _captureDepth = 0;
  BdfdOutput? output;
  void Function(BdfdTraceEvent event)? onTrace;

  /// Adapters may tighten it around a nested program (see [steps]).
  int maxSteps;
  final int maxDepth;
  final List<BdfdLocation> _calls = [];
  final List<int> _loops = [];
  final List<Map<String, String>> _loopVariables = [];
  List<BdfdLocation> get callStack => List.unmodifiable(_calls);
  bool stopped = false;
  int _steps = 0;
  int? _pendingSkip;
  int? _pendingJump;
  int? _outerSkip;
  int? _outerJump;
  int _depth = 0;

  /// Same effect as `$skipActions`/`$jumpToAction` for adapters whose
  /// statements carry their own error policy. Consumed by the statement list
  /// that is executing the calling statement.
  ///
  /// With [outer], issued from the catch body of a `BdfdTry`: the request is
  /// not consumed by that body's own statement list but handed to the list that
  /// contains the try statement (how an adapter applies a block's own
  /// jump/skip error mode).
  void requestSkip(int count, {bool outer = false}) =>
      outer ? _outerSkip = count : _pendingSkip = count;
  void requestJump(int ordinal, {bool outer = false}) =>
      outer ? _outerJump = ordinal : _pendingJump = ordinal;

  /// Steps consumed so far by every program sharing this context.
  int get steps => _steps;

  /// Programs currently executing on this context (nested ones included).
  int get depth => _depth;

  /// Forget what a previous script left behind (user functions, error
  /// handling flags, the stop flag): what the outermost execution does.
  void startScript() {
    stopped = false;
    _userFunctions.clear();
    _suppressedError = null;
    _errorEmbed = null;
    suppressErrorLogging = false;
    removeLinks = false;
  }

  String? loopVariable(String name) {
    for (final frame in _loopVariables.reversed) {
      if (frame.containsKey(name)) return frame[name];
    }
    return null;
  }

  void _trace(
    String kind,
    String status,
    BdfdLocation location, {
    String? value,
    int? branch,
    int? iteration,
    int? durationMicroseconds,
  }) {
    final observer = onTrace;
    if (observer == null) return;
    try {
      observer(
        BdfdTraceEvent(
          kind: kind,
          status: status,
          location: location,
          scriptDepth: _depth,
          functionDepth: _calls.length,
          value: value,
          branch: branch,
          iteration: iteration,
          durationMicroseconds: durationMicroseconds,
        ),
      );
    } catch (_) {
      // A diagnostics observer cannot interrupt or retry command effects.
    }
  }

  void _check(BdfdLocation location) {
    budget.check();
    if (++_steps > maxSteps) {
      throw BdfdNativeError('Execution step limit exceeded.', location);
    }
  }
}

typedef BdfdFunctionHandler = FutureOr<String> Function(BdfdInvocation call);

/// Functions supplied by native libraries or service adapters. Arguments are
/// deliberately lazy: getters, effects and code branches run only when asked.
class BdfdNativeFunction {
  const BdfdNativeFunction({
    required this.handler,
    required this.minArguments,
    required this.maxArguments,
    this.allowedArgumentCounts,
  });
  final BdfdFunctionHandler handler;
  final int minArguments;
  final int maxArguments;

  /// For signatures with gaps, such as random's zero or two arguments.
  final Set<int>? allowedArgumentCounts;
}

/// The part of a native function that preparation checks: which names exist
/// and how many arguments they accept. Handlers are never needed to validate.
class BdfdFunctionSignature {
  const BdfdFunctionSignature(
    this.minArguments,
    this.maxArguments, [
    this.allowedArgumentCounts,
  ]);
  final int minArguments;
  final int maxArguments;
  final Set<int>? allowedArgumentCounts;

  @override
  bool operator ==(Object other) =>
      other is BdfdFunctionSignature &&
      other.minArguments == minArguments &&
      other.maxArguments == maxArguments &&
      _sameCounts(other.allowedArgumentCounts, allowedArgumentCounts);

  @override
  int get hashCode => Object.hash(
    minArguments,
    maxArguments,
    allowedArgumentCounts == null
        ? null
        : Object.hashAllUnordered(allowedArgumentCounts!),
  );

  @override
  String toString() =>
      'BdfdFunctionSignature($minArguments, $maxArguments, '
      '$allowedArgumentCounts)';

  static bool _sameCounts(Set<int>? a, Set<int>? b) => a == null || b == null
      ? a == b
      : a.length == b.length && a.containsAll(b);
}

class BdfdInvocation {
  BdfdInvocation._(this._runtime, this._program, this.node, this.context);
  final BdfdRuntime _runtime;
  final BdfdProgram _program;
  final BdfdFunctionCallAst node;
  final BdfdContext context;
  final Map<int, String> _arguments = {};
  final Map<BdfdAstNode, String> _argumentParts = {};
  List<String>? _expandedArguments;
  int get argumentCount => node.arguments.length;
  BdfdLocation get location => _runtime._location(_program, node);

  /// Evaluate once on first demand. An evaluated value is data, never reparsed.
  Future<String> argument(int index) async {
    if (index < 0 || index >= argumentCount) {
      throw BdfdNativeError('Missing argument ${index + 1}.', location);
    }
    if (_arguments.containsKey(index)) return _arguments[index]!;
    final buffer = StringBuffer();
    for (final part in node.arguments[index]) {
      buffer.write(await _argumentPart(part));
    }
    final value = buffer.toString();
    _arguments[index] = value;
    return value;
  }

  Future<String> _argumentPart(BdfdAstNode part) async {
    if (_argumentParts.containsKey(part)) return _argumentParts[part]!;
    final text = await _runtime._evaluate([part], _program, context);
    _argumentParts[part] = text;
    return text;
  }

  /// Explicit $unescape can turn semicolons into argument boundaries. Text
  /// returned by every other function stays literal, including dollar syntax.
  Future<List<String>> expandedArguments() async {
    if (_expandedArguments != null) return _expandedArguments!;
    final result = <String>[];
    for (var i = 0; i < argumentCount; i++) {
      final parts = node.arguments[i];
      if (!parts.any(
        (part) =>
            part is BdfdFunctionCallAst && part.normalizedName == 'unescape',
      )) {
        result.add(await argument(i));
        continue;
      }
      var current = '';
      for (final part in parts) {
        final text = await _argumentPart(part);
        if (part is BdfdFunctionCallAst && part.normalizedName == 'unescape') {
          final segments = text.split(';');
          current += segments.first;
          for (final segment in segments.skip(1)) {
            result.add(current);
            current = segment;
          }
        } else {
          current += text;
        }
      }
      result.add(current);
    }
    return _expandedArguments = List.unmodifiable(result);
  }

  /// Only explicit dynamic evaluation converts evaluated text back into code.
  Future<String> eval(String source) async {
    final value = await executeScript(prepare(source));
    return context.output == null ? value : '';
  }

  BdfdProgram prepare(String source) => _runtime.prepare(source);

  /// Execute prepared stored source in the same invocation as the caller.
  Future<String> executeScript(BdfdProgram program) async {
    await context.output?.flush(context, location);
    return _runtime._execute(program, context);
  }

  bool condition(String value) => _runtime._condition(value, location);

  /// End the current script through the same control path as native guards.
  Never stop([String? message]) => throw _Stop(message);
}

/// Executes a structured AST directly. Does not compile to or execute blocks.
class BdfdRuntime {
  BdfdRuntime({Map<String, BdfdNativeFunction> functions = const {}}) {
    _functions.addAll(_coreFunctions());
    for (final entry in functions.entries) {
      final name = normalizeBdfdFunctionName(entry.key);
      if (_functions.containsKey(name)) {
        throw ArgumentError('Cannot override native core function \$$name.');
      }
      _functions[name] = entry.value;
    }
  }
  final Map<String, BdfdNativeFunction> _functions = {};
  Set<String> get supportedFunctions => Set.unmodifiable({
    ..._functions.keys,
    ...BdfdProgram.structuralFunctionNames,
  });

  /// Registered functions (core and supplied) reduced to what `prepare` checks.
  Map<String, BdfdFunctionSignature> get functionSignatures =>
      Map.unmodifiable({
        for (final entry in _functions.entries)
          entry.key: BdfdFunctionSignature(
            entry.value.minArguments,
            entry.value.maxArguments,
            entry.value.allowedArgumentCounts,
          ),
      });

  /// Structural and capability validation; performs no service calls.
  BdfdProgram prepare(String source) {
    final program = BdfdProgram.parse(source);
    _validate(program);
    return program;
  }

  Future<String> executeProgram(
    BdfdProgram program, {
    BdfdContext? context,
  }) async {
    final invocation = context ?? BdfdContext();
    _startInvocation(invocation);
    return invocation.budget.run(() => _execute(program, invocation));
  }

  Future<String> execute(String source, {BdfdContext? context}) async {
    final invocation = context ?? BdfdContext();
    _startInvocation(invocation);
    return invocation.budget.run(
      () => _execute(BdfdProgram.parse(source), invocation),
    );
  }

  void _startInvocation(BdfdContext context) {
    if (context._depth != 0) return;
    context.startScript();
  }

  BdfdLocation _location(BdfdProgram program, BdfdAstNode node) => BdfdLocation(
    program.source,
    node.start ?? 0,
    functionName: node is BdfdFunctionCallAst ? node.name : null,
  );

  /// Check the entire program before any effect, including untaken branches.
  void _validate(BdfdProgram program) {
    void expressions(
      List<BdfdAstNode> nodes,
      int depth,
      Set<String> loopBindings,
    ) {
      if (depth > 128) {
        throw BdfdNativeError(
          'AST nesting limit exceeded.',
          _location(program, nodes.first),
        );
      }
      for (final node in nodes) {
        if (node is! BdfdFunctionCallAst) continue;
        if (node.arguments.isEmpty &&
            loopBindings.contains(node.normalizedName)) {
          continue;
        }
        final function = _functions[node.normalizedName];
        if (function == null) {
          if (!allBdfdFunctions.contains(node.normalizedName)) continue;
          throw BdfdNativeError(
            'Unsupported native function ${node.name}.',
            _location(program, node),
          );
        }
        // `$fn[]` on a function without parameters is the same as `$fn`.
        final argumentCount =
            function.maxArguments == 0 &&
                node.arguments.length == 1 &&
                node.arguments.single.isEmpty
            ? 0
            : node.arguments.length;
        if (argumentCount < function.minArguments ||
            argumentCount > function.maxArguments ||
            (function.allowedArgumentCounts != null &&
                !function.allowedArgumentCounts!.contains(argumentCount))) {
          throw BdfdNativeError(
            'Invalid argument count for ${node.name}: $argumentCount.',
            _location(program, node),
          );
        }
        if (node.normalizedName == 'c') continue;
        for (final argument in node.arguments) {
          if (argument.isNotEmpty) {
            expressions(argument, depth + 1, loopBindings);
          }
        }
      }
    }

    void statements(
      List<BdfdStatement> body, [
      Set<String> loopBindings = const {},
    ]) {
      for (final statement in body) {
        switch (statement) {
          case BdfdExpression():
            expressions([statement.node], 0, loopBindings);
          case BdfdConditional():
            for (final branch in statement.branches) {
              if (branch.condition != null) {
                expressions(branch.condition!, 0, loopBindings);
              }
              statements(branch.body, loopBindings);
            }
          case BdfdLoop():
            final bindings = {...loopBindings, ...statement.syntax.bindings};
            for (final argument
                in (statement.node as BdfdFunctionCallAst).arguments) {
              expressions(argument, 0, bindings);
            }
            statements(statement.body, bindings);
          case BdfdJsonForEach():
            for (final argument
                in (statement.node as BdfdFunctionCallAst).arguments) {
              expressions(argument, 0, loopBindings);
            }
            statements(statement.body, {
              ...loopBindings,
              'jsonkey',
              'jsonvalue',
              'jsonindex',
            });
          case BdfdTry():
            for (final hook in [
              statement.enter,
              statement.onCatch,
              statement.exit,
            ]) {
              if (hook != null) expressions([hook], 0, loopBindings);
            }
            statements(statement.body, loopBindings);
            statements(statement.catchBody, loopBindings);
          case BdfdFunctionDefinition():
            statements(statement.body, loopBindings);
        }
      }
    }

    statements(program.statements);
  }

  Future<String> _execute(BdfdProgram program, BdfdContext context) async {
    context._check(BdfdLocation(program.source, 0));
    if (++context._depth > context.maxDepth) {
      context._depth--;
      throw BdfdNativeError(
        'Script recursion limit exceeded.',
        BdfdLocation(program.source, 0),
      );
    }
    final output = StringBuffer();
    try {
      try {
        _validate(program);
        await _statements(program.statements, program, context, output);
      } on _Stop catch (stop) {
        context.stopped = true;
        // Stop this script. Already performed effects are never retried.
        if (stop.message != null) {
          output.clear();
          final message = _replaceError(context, stop.message!);
          output.write(message);
          context.output?.discard();
          _appendError(context, message, stop.message!);
        }
      } on BdfdNativeError catch (error) {
        if (context._suppressedError == null && context._errorEmbed == null) {
          rethrow;
        }
        context.stopped = true;
        context.results['error.message'] = error.message;
        output.clear();
        final message = _replaceError(context, error.message);
        output.write(message);
        context.output?.discard();
        _appendError(context, message, error.message);
      }
      while (context.beforeFlush.isNotEmpty) {
        await context.beforeFlush.removeAt(0)();
      }
      await context.output?.flush(
        context,
        BdfdLocation(program.source, program.source.length),
      );
      context.output?.discard();
    } on BdfdNativeError catch (error) {
      context.output?.discard();
      if (context._suppressedError == null && context._errorEmbed == null) {
        rethrow;
      }
      context.stopped = true;
      context.results['error.message'] = error.message;
      final message = _replaceError(context, error.message);
      output.clear();
      output.write(message);
      _appendError(context, message, error.message);
      await context.output?.flush(context, error.location);
      context.output?.discard();
    } catch (_) {
      context.output?.discard();
      rethrow;
    } finally {
      context._depth--;
    }
    return context.removeLinks
        ? removeBdfdLinks(output.toString())
        : output.toString();
  }

  String _replaceError(BdfdContext context, String original) =>
      context._errorEmbed != null ? '' : context._suppressedError ?? original;

  void _appendError(BdfdContext context, String text, String original) {
    final embed = context._errorEmbed;
    if (embed != null) {
      final sink = context.output;
      if (sink is! BdfdErrorOutput) {
        throw BdfdNativeError(
          'Embed error responses require a message output.',
          BdfdLocation('', 0),
        );
      }
      final payload = Map<String, dynamic>.from(embed);
      if (!payload.containsKey('description') && original.isNotEmpty) {
        payload['description'] = original;
      }
      (sink as BdfdErrorOutput).replaceErrorEmbed(payload);
    } else {
      context.output?.append(text);
    }
  }

  Future<void> _statements(
    List<BdfdStatement> statements,
    BdfdProgram program,
    BdfdContext context,
    StringBuffer output,
  ) async {
    // `$skipActions` / `$jumpToAction` count function-call statements of this
    // list: skipping drops the next N, jumping continues at the Nth (1-based).
    var actionNumber = 0, skipping = 0, jumpTarget = 0;
    for (final statement in statements) {
      context._check(_location(program, statement.node));
      if (statement.node is BdfdFunctionCallAst &&
          statement is! BdfdFunctionDefinition) {
        actionNumber++;
        if (skipping > 0) {
          skipping--;
          continue;
        }
        if (jumpTarget > actionNumber) continue;
        jumpTarget = 0;
      }
      switch (statement) {
        case BdfdExpression():
          final text = await _evaluate([statement.node], program, context);
          output.write(text);
          if (context._captureDepth == 0) context.output?.append(text);
        case BdfdFunctionDefinition():
          context._userFunctions[statement.name] = _UserFunction(
            statement,
            program,
          );
        case BdfdConditional():
          var selected = false;
          for (var index = 0; index < statement.branches.length; index++) {
            final branch = statement.branches[index];
            final condition = branch.condition == null
                ? null
                : await _evaluate(branch.condition!, program, context);
            final matches =
                condition == null ||
                _condition(condition, _location(program, statement.node));
            context._trace(
              'condition',
              matches ? 'true' : 'false',
              _location(program, statement.node),
              value: condition,
              branch: index,
            );
            if (matches) {
              selected = true;
              context._trace(
                'branch',
                'selected',
                _location(program, statement.node),
                branch: index,
              );
              await _statements(branch.body, program, context, output);
              break;
            }
          }
          if (!selected) {
            context._trace(
              'branch',
              'none',
              _location(program, statement.node),
            );
          }
        case BdfdLoop():
          await _loop(statement, program, context, output);
        case BdfdJsonForEach():
          await _jsonForEach(statement, program, context, output);
        case BdfdTry():
          if (statement.enter != null) {
            await _evaluate([statement.enter!], program, context);
          }
          try {
            await _statements(statement.body, program, context, output);
          } on BdfdNativeError catch (error) {
            context._trace(
              'catch',
              'handled',
              _location(program, statement.node),
              value: error.toString(),
            );
            context.results['error.message'] = error.toString();
            _recordErrorDetails(context, error);
            if (statement.onCatch != null) {
              await _evaluate([statement.onCatch!], program, context);
            }
            await _statements(statement.catchBody, program, context, output);
          }
          if (statement.exit != null) {
            await _evaluate([statement.exit!], program, context);
          }
          // A request issued with `outer` from the catch body lands here.
          context._pendingSkip = context._outerSkip ?? context._pendingSkip;
          context._pendingJump = context._outerJump ?? context._pendingJump;
          context._outerSkip = context._outerJump = null;
      }
      final skip = context._pendingSkip, jump = context._pendingJump;
      context._pendingSkip = context._pendingJump = null;
      if (skip != null) skipping = skip;
      if (jump != null) {
        if (jump <= actionNumber) {
          throw BdfdNativeError(
            r'$jumpToAction can only jump to a later action.',
            _location(program, statement.node),
          );
        }
        jumpTarget = jump;
      }
    }
  }

  /// Details for `$error[Type]`: command, message, source, row and column.
  void _recordErrorDetails(BdfdContext context, BdfdNativeError error) {
    final location = error.location;
    final lines = location.source.split('\n');
    context.results['error.command'] = location.functionName ?? '';
    context.results['error.rawMessage'] = error.message;
    context.results['error.source'] = location.line <= lines.length
        ? lines[location.line - 1].trim()
        : '';
    context.results['error.row'] = '${location.line}';
    context.results['error.column'] = '${location.column}';
  }

  Future<void> _jsonForEach(
    BdfdJsonForEach loop,
    BdfdProgram program,
    BdfdContext context,
    StringBuffer output,
  ) async {
    final node = loop.node as BdfdFunctionCallAst;
    final location = _location(program, node);
    final path = <String>[];
    for (final argument in node.arguments) {
      final segment = (await _evaluate(argument, program, context)).trim();
      if (segment.isNotEmpty) path.add(segment);
    }
    final entries = context.json.iterationSnapshot(path);
    final bindings = <String, String>{};
    context._loops.add(0);
    context._loopVariables.add(bindings);
    try {
      for (var index = 0; index < entries.length; index++) {
        context._check(location);
        if (index % 32 == 0) await Future<void>.delayed(Duration.zero);
        context.budget.check();
        bindings['jsonkey'] = entries[index].key;
        bindings['jsonvalue'] = entries[index].value;
        bindings['jsonindex'] = '$index';
        bindings['i'] = '$index';
        context._loops[context._loops.length - 1] = index;
        context._trace('jsonLoop', 'iteration', location, iteration: index);
        try {
          await _statements(loop.body, program, context, output);
        } on _Continue {
          context._trace('jsonLoop', 'continue', location, iteration: index);
        } on _Break {
          context._trace('jsonLoop', 'break', location, iteration: index);
          break;
        }
      }
    } finally {
      context._loopVariables.removeLast();
      context._loops.removeLast();
    }
  }

  Future<void> _loop(
    BdfdLoop loop,
    BdfdProgram program,
    BdfdContext context,
    StringBuffer output,
  ) async {
    final node = loop.node as BdfdFunctionCallAst;
    final location = _location(program, node);
    final kind = loop.syntax.kind;
    int? count;
    List<String>? values;
    final bindings = <String, String>{};
    context._loops.add(0);
    context._loopVariables.add(bindings);
    try {
      if (kind == BdfdLoopKind.counted) {
        count = int.tryParse(
          await _evaluate(node.arguments.single, program, context),
        );
        if (count == null || count < 0) {
          throw BdfdNativeError(
            'Expected a nonnegative integer loop count.',
            location,
          );
        }
      } else if (kind == BdfdLoopKind.list) {
        values = [];
        for (final argument in node.arguments.skip(1)) {
          values.add(await _evaluate(argument, program, context));
        }
      } else if (kind == BdfdLoopKind.cStyle) {
        for (final assignment in loop.syntax.initializers) {
          final initial = await _loopNumber(
            assignment.value,
            program,
            context,
            location,
          );
          bindings[assignment.name] = '${initial.toInt()}';
        }
      }
      for (var index = 0; ; index++) {
        context._check(location);
        if (index % 32 == 0) await Future<void>.delayed(Duration.zero);
        context.budget.check();
        if (kind == BdfdLoopKind.counted && index >= count!) break;
        if (kind == BdfdLoopKind.list && index >= values!.length) break;
        if (kind == BdfdLoopKind.cStyle || kind == BdfdLoopKind.whileLoop) {
          final condition = await _evaluate(
            node.arguments[kind == BdfdLoopKind.cStyle ? 1 : 0],
            program,
            context,
            replaceLoopIdentifiers: kind == BdfdLoopKind.cStyle,
          );
          if (kind == BdfdLoopKind.cStyle &&
              !RegExp(
                r'^\s*-?\d+\s*(==|!=|>=|<=|>|<)\s*-?\d+\s*$',
              ).hasMatch(condition)) {
            throw BdfdNativeError(
              'Invalid integer loop condition: $condition.',
              location,
            );
          }
          final matches = _condition(condition, location);
          context._trace(
            'loopCondition',
            matches ? 'true' : 'false',
            location,
            value: condition,
            iteration: index,
          );
          if (!matches) break;
        }
        context._trace('loop', 'iteration', location, iteration: index);
        context._loops[context._loops.length - 1] = index;
        if (kind == BdfdLoopKind.list) {
          bindings[loop.syntax.iterator!] = values![index];
        }
        if (kind == BdfdLoopKind.counted || kind == BdfdLoopKind.whileLoop) {
          bindings['i'] = '$index';
        }
        try {
          await _statements(loop.body, program, context, output);
        } on _Continue {
          context._trace('loop', 'continue', location, iteration: index);
          // A C-style continue still executes the update clause.
        } on _Break {
          context._trace('loop', 'break', location, iteration: index);
          break;
        }
        if (kind == BdfdLoopKind.cStyle) {
          for (final assignment in loop.syntax.updates) {
            final current = int.parse(bindings[assignment.name]!);
            final number = ['++', '--'].contains(assignment.operator)
                ? 1
                : await _loopNumber(
                    assignment.value,
                    program,
                    context,
                    location,
                  );
            if (assignment.operator == '/=' && number == 0) {
              throw BdfdNativeError(
                'Loop update cannot divide by zero.',
                location,
              );
            }
            bindings[assignment.name] =
                '${switch (assignment.operator) {
                  '++' || '+=' => current + number.toInt(),
                  '--' || '-=' => current - number.toInt(),
                  '*=' => (current * number).toInt(),
                  '/=' => (current / number).toInt(),
                  _ => number.toInt(),
                }}';
          }
        }
      }
    } finally {
      context._loops.removeLast();
      context._loopVariables.removeLast();
    }
  }

  Future<num> _loopNumber(
    List<BdfdAstNode> nodes,
    BdfdProgram program,
    BdfdContext context,
    BdfdLocation location,
  ) async {
    final expression = await _evaluate(
      nodes,
      program,
      context,
      replaceLoopIdentifiers: true,
    );
    final value = MathExpressionParser.evaluate(
      expression,
      strictArithmetic: true,
      checkBudget: context.budget.check,
      maxDepth: context.maxDepth,
    );
    if (value == null || !value.isFinite) {
      throw BdfdNativeError('Invalid loop arithmetic: $expression.', location);
    }
    return value;
  }

  String? _loopVariable(String name, BdfdContext context) =>
      context.loopVariable(name);

  String _replaceLoopIdentifiers(String text, BdfdContext context) =>
      text.replaceAllMapped(
        RegExp(r'\b[a-zA-Z_]\w*\b'),
        (match) => _loopVariable(match[0]!.toLowerCase(), context) ?? match[0]!,
      );

  static final _dynamicPlaceholder = RegExp(r'\(\(([^()]+)\)\)');

  /// Literal script text with its `((name))` dynamic variables (the same ones
  /// visual blocks use: `opts.*`, `user.*`, `guild.*`...) substituted from the
  /// context. Substitution happens while evaluating, on each text node, so the
  /// values are data exactly like `$message`: they are never parsed as BDFD.
  /// A `((...))` that names no known variable stays literal text.
  String _expandText(
    String text,
    BdfdProgram program,
    BdfdContext context,
    bool replaceLoopIdentifiers,
  ) {
    String literal(String value) => replaceLoopIdentifiers
        ? _replaceLoopIdentifiers(value, context)
        : value;
    if (!program.expandDynamicVariables || !text.contains('((')) {
      return literal(text);
    }
    final output = StringBuffer();
    var last = 0;
    for (final match in _dynamicPlaceholder.allMatches(text)) {
      final expression = match[1]!.trim();
      if (resolveTemplateExpressionValue(expression, context.variables) ==
          null) {
        continue;
      }
      output
        ..write(literal(text.substring(last, match.start)))
        ..write(
          resolveTemplateExpressionToString(expression, context.variables),
        );
      last = match.end;
    }
    output.write(literal(text.substring(last)));
    return output.toString();
  }

  Future<String> _evaluate(
    List<BdfdAstNode> nodes,
    BdfdProgram program,
    BdfdContext context, {
    bool replaceLoopIdentifiers = false,
  }) async {
    final output = StringBuffer();
    for (final node in nodes) {
      final location = _location(program, node);
      context._check(location);
      if (node is BdfdTextAst) {
        output.write(
          _expandText(node.value, program, context, replaceLoopIdentifiers),
        );
      } else if (node is BdfdFunctionCallAst) {
        final variable = node.arguments.isEmpty
            ? _loopVariable(node.normalizedName, context)
            : null;
        if (variable != null) {
          output.write(variable);
          continue;
        }
        final function = _functions[node.normalizedName];
        if (function == null) {
          // An unknown function is opaque text, including its arguments.
          final literal = program.source.substring(node.start!, node.end!);
          context._trace('function', 'literal', location, value: literal);
          output.write(literal);
          continue;
        }
        if (context._calls.length >= context.maxDepth) {
          throw BdfdNativeError('Function nesting limit exceeded.', location);
        }
        context._calls.add(location);
        final timer = context.onTrace == null ? null : (Stopwatch()..start());
        context._trace('function', 'start', location);
        try {
          final value = await function.handler(
            BdfdInvocation._(this, program, node, context),
          );
          context.budget.check();
          context._trace(
            'function',
            'returned',
            location,
            value: value,
            durationMicroseconds: timer?.elapsedMicroseconds,
          );
          output.write(value);
        } on BdfdNativeError catch (error) {
          context._trace(
            'function',
            'error',
            location,
            value: error.toString(),
            durationMicroseconds: timer?.elapsedMicroseconds,
          );
          if (error.callStack.isNotEmpty) rethrow;
          throw BdfdNativeError(
            error.message,
            error.location,
            cause: error.cause,
            callStack: context.callStack,
          );
        } on CommandExecutionTimeout catch (error) {
          context._trace(
            'function',
            'timeout',
            location,
            value: error.toString(),
            durationMicroseconds: timer?.elapsedMicroseconds,
          );
          rethrow;
        } on _Control catch (control) {
          context._trace(
            'function',
            switch (control) {
              _Stop() => 'stop',
              _Break() => 'break',
              _Continue() => 'continue',
            },
            location,
            durationMicroseconds: timer?.elapsedMicroseconds,
          );
          rethrow;
        } catch (error) {
          context._trace(
            'function',
            'error',
            location,
            value: error.toString(),
            durationMicroseconds: timer?.elapsedMicroseconds,
          );
          throw BdfdNativeError(
            error.toString(),
            location,
            cause: error,
            callStack: context.callStack,
          );
        } finally {
          context._calls.removeLast();
        }
      }
    }
    return output.toString();
  }

  bool _condition(String expression, BdfdLocation location) {
    final value = expression.trim();
    if (value == 'true') return true;
    if (value == 'false') return false;
    final comparison = RegExp(
      r'^(.*?)(==|!=|>=|<=|>|<)(.*)$',
      dotAll: true,
    ).firstMatch(value);
    if (comparison == null) {
      throw BdfdNativeError('Invalid condition: $expression.', location);
    }
    final left = comparison[1]!.trim();
    final right = comparison[3]!.trim();
    final a = num.tryParse(left);
    final b = num.tryParse(right);
    final order = a != null && b != null
        ? a.compareTo(b)
        : left.compareTo(right);
    return switch (comparison[2]) {
      '==' => order == 0,
      '!=' => order != 0,
      '>' => order > 0,
      '<' => order < 0,
      '>=' => order >= 0,
      '<=' => order <= 0,
      _ => false,
    };
  }

  Map<String, BdfdNativeFunction> _coreFunctions() {
    final functions = <String, BdfdNativeFunction>{};
    void add(String name, int min, int max, BdfdFunctionHandler handler) {
      functions[name] = BdfdNativeFunction(
        handler: handler,
        minArguments: min,
        maxArguments: max,
      );
    }

    add('var', 1, 2, (call) async {
      final name = await call.argument(0);
      if (call.argumentCount == 2) {
        call.context.temporaryVariables[name] = await call.argument(1);
        return '';
      }
      return call.context.temporaryVariables[name] ?? '';
    });
    add('funccall', 1, 101, (call) async {
      final name = (await call.argument(0)).trim().toLowerCase();
      if (name.isEmpty) {
        throw BdfdNativeError('A function name is required.', call.location);
      }
      final function = call.context._userFunctions[name];
      if (function == null || call.context._functionFrames.length >= 10) {
        call.context._trace(
          'customFunction',
          'warning',
          call.location,
          value: function == null
              ? 'Undefined function $name.'
              : 'Custom function call depth exceeded.',
        );
        return '';
      }
      final arguments = <String, String>{};
      for (var i = 0; i < function.definition.parameters.length; i++) {
        arguments[function.definition.parameters[i]] =
            i + 1 < call.argumentCount ? await call.argument(i + 1) : '';
      }
      final frame = _FunctionFrame(arguments);
      final previousFunctions = Map<String, _UserFunction>.from(
        call.context._userFunctions,
      );
      call.context._functionFrames.add(frame);
      call.context._captureDepth++;
      final body = StringBuffer();
      try {
        await _statements(
          function.definition.body,
          function.program,
          call.context,
          body,
        );
        return frame.returnValue ?? body.toString();
      } finally {
        call.context._captureDepth--;
        call.context._functionFrames.removeLast();
        call.context._userFunctions
          ..clear()
          ..addAll(previousFunctions);
      }
    });
    add('funcarg', 1, 1, (call) async {
      final name = (await call.argument(0)).trim().toLowerCase();
      return call.context._functionFrames.isEmpty
          ? ''
          : call.context._functionFrames.last.arguments[name] ?? '';
    });
    add('funcreturn', 1, 1, (call) async {
      if (call.context._functionFrames.isNotEmpty) {
        call.context._functionFrames.last.returnValue = await call.argument(0);
      }
      return '';
    });
    add('suppresserrors', 0, 1, (call) async {
      call.context._suppressedError = call.argumentCount == 0
          ? ''
          : await call.argument(0);
      call.context._errorEmbed = null;
      return '';
    });
    add('suppresserrorlogging', 0, 0, (call) {
      call.context.suppressErrorLogging = true;
      return '';
    });
    add('embedsuppresserrors', 2, 6, (call) async {
      final values = <String>[];
      for (var i = 0; i < call.argumentCount; i++) {
        values.add(await call.argument(i));
      }
      if (values.every((value) => value.isEmpty)) {
        throw BdfdNativeError(
          'At least one error embed field is required.',
          call.location,
        );
      }
      final embed = <String, dynamic>{
        if (values[0].isNotEmpty) 'title': values[0],
        if (values[1].isNotEmpty) 'description': values[1],
        if (values.length > 3 && values[3].isNotEmpty)
          'author': {'name': values[3]},
        if (values.length > 4 && values[4].isNotEmpty)
          'footer': {
            'text': values[4],
            if (values.length > 5 && values[5].isNotEmpty)
              'icon_url': values[5],
          },
      };
      if (values.length > 2 && values[2].isNotEmpty) {
        final raw = values[2].trim();
        final color = raw.startsWith('#')
            ? int.tryParse(raw.substring(1), radix: 16)
            : int.tryParse(raw);
        if (color == null || color < 0 || color > 0xffffff) {
          throw BdfdNativeError('Invalid embed color.', call.location);
        }
        embed['color'] = color;
      }
      if (values.length > 5 && values[5].isNotEmpty) {
        final uri = Uri.tryParse(values[5]);
        if (uri == null ||
            !['http', 'https'].contains(uri.scheme) ||
            uri.host.isEmpty) {
          throw BdfdNativeError('Invalid footer icon URL.', call.location);
        }
      }
      call.context._errorEmbed = embed;
      call.context._suppressedError = null;
      return '';
    });
    add('removelinks', 0, 0, (call) {
      call.context.removeLinks = true;
      return '';
    });
    add('unescape', 1, 1, (call) => call.argument(0));
    add('c', 1, 1, (_) => ''); // Comment body is never evaluated.
    add('eval', 1, 1, (call) async => call.eval(await call.argument(0)));
    add('if', 2, 3, (call) async {
      if (call.condition(await call.argument(0))) return call.argument(1);
      return call.argumentCount == 3 ? call.argument(2) : '';
    });
    add('onlyif', 1, 2, (call) async {
      if (!call.condition(await call.argument(0))) {
        throw _Stop(call.argumentCount == 2 ? await call.argument(1) : null);
      }
      return '';
    });
    add('stop', 0, 0, (_) => throw _Stop());
    add('break', 0, 0, (call) {
      if (call.context._loops.isEmpty) {
        throw BdfdNativeError('Break outside a loop.', call.location);
      }
      throw _Break();
    });
    add('skipactions', 1, 1, (call) async {
      final count = int.tryParse((await call.argument(0)).trim());
      if (count == null || count < 0) {
        throw BdfdNativeError(
          'Expected a non-negative action count.',
          call.location,
        );
      }
      call.context._pendingSkip = count;
      return '';
    });
    add('jumptoaction', 1, 1, (call) async {
      final target = int.tryParse((await call.argument(0)).trim());
      if (target == null || target < 1) {
        throw BdfdNativeError(
          'Expected a positive action number.',
          call.location,
        );
      }
      call.context._pendingJump = target;
      return '';
    });
    add('continue', 0, 0, (call) {
      if (call.context._loops.isEmpty) {
        throw BdfdNativeError('Continue outside a loop.', call.location);
      }
      throw _Continue();
    });
    for (final name in ['i', 'loopindex', 'loopiteration', 'loopcount']) {
      add(name, 0, 0, (call) {
        if (call.context._loops.isEmpty) {
          throw BdfdNativeError('Loop index outside a loop.', call.location);
        }
        return '${call.context._loops.last + (name == 'loopcount' ? 1 : 0)}';
      });
    }
    for (final name in ['and', 'or']) {
      add(name, 1, 100, (call) async {
        for (var i = 0; i < call.argumentCount; i++) {
          final result = call.condition(await call.argument(i));
          if (name == 'and' && !result) return 'false';
          if (name == 'or' && result) return 'true';
        }
        return name == 'and' ? 'true' : 'false';
      });
    }
    add(
      'checkcondition',
      1,
      1,
      (call) async => '${call.condition(await call.argument(0))}',
    );
    add(
      'touppercase',
      1,
      1,
      (call) async => (await call.argument(0)).toUpperCase(),
    );
    add(
      'tolowercase',
      1,
      1,
      (call) async => (await call.argument(0)).toLowerCase(),
    );
    add('trimspace', 1, 1, (call) async => (await call.argument(0)).trim());
    add(
      'charcount',
      1,
      1,
      (call) async => '${(await call.argument(0)).length}',
    );
    add(
      'isinteger',
      1,
      1,
      (call) async => '${int.tryParse(await call.argument(0)) != null}',
    );
    add('calculate', 1, 1, (call) async {
      final value = MathExpressionParser.evaluate(
        await call.argument(0),
        strictArithmetic: true,
        checkBudget: call.context.budget.check,
        maxDepth: call.context.maxDepth,
      );
      if (value == null || !value.isFinite) {
        throw BdfdNativeError('Invalid arithmetic expression.', call.location);
      }
      return _mathNumber(call, value);
    });
    add('enabledecimals', 1, 1, (call) async {
      final raw = (await call.argument(0)).trim().toLowerCase();
      switch (raw) {
        case 'yes':
        case 'true':
        case 'on':
        case 'enable':
          call.context.decimalsEnabled = true;
        case 'no':
        case 'false':
        case 'off':
        case 'disable':
          call.context.decimalsEnabled = false;
        default:
          throw BdfdNativeError(
            'Expected an enable-decimals boolean.',
            call.location,
          );
      }
      return '';
    });
    for (final name in ['sum', 'sub', 'multi', 'divide']) {
      add(name, 2, 1 << 30, (call) async {
        Object value = await _arithmeticValue(call, 0);
        for (var i = 1; i < call.argumentCount; i++) {
          call.context.budget.check();
          final next = await _arithmeticValue(call, i);
          if (name == 'divide' &&
              (next is BigInt ? next == BigInt.zero : next == 0)) {
            throw BdfdNativeError('Cannot divide by zero.', call.location);
          }
          if (name != 'divide' && value is BigInt && next is BigInt) {
            final left = value;
            final right = next;
            value = switch (name) {
              'sum' => left + right,
              'sub' => left - right,
              _ => left * right,
            };
          } else {
            final left = value is BigInt ? value.toDouble() : value as num;
            final right = next is BigInt ? next.toDouble() : next as num;
            value = switch (name) {
              'sum' => left + right,
              'sub' => left - right,
              'multi' => left * right,
              _ => left / right,
            };
          }
        }
        if (value is BigInt) return '$value';
        final numeric = value as num;
        if (!numeric.isFinite) {
          throw BdfdNativeError('Non-finite arithmetic result.', call.location);
        }
        return _mathNumber(call, numeric);
      });
    }
    for (final name in ['min', 'max']) {
      add(name, 2, 1 << 30, (call) async {
        var value = await _integer(call, 0);
        for (var i = 1; i < call.argumentCount; i++) {
          call.context.budget.check();
          final next = await _integer(call, i);
          if (name == 'min' ? next < value : next > value) value = next;
        }
        return '$value';
      });
    }
    add('modulo', 2, 2, (call) async {
      final dividend = await _integer(call, 0);
      final divisor = await _integer(call, 1);
      if (divisor == BigInt.zero) {
        throw BdfdNativeError('Cannot take remainder by zero.', call.location);
      }
      return '${dividend.remainder(divisor)}';
    });
    add('sqrt', 1, 1, (call) async {
      final value = await _numeric(call, 0);
      if (value < 0) {
        throw BdfdNativeError(
          'Square root requires a non-negative number.',
          call.location,
        );
      }
      return _mathNumber(call, math.sqrt(value));
    });
    add('round', 1, 2, (call) async {
      final raw = await call.argument(0);
      if (bdfdFiniteDecimal(raw) == null) {
        throw BdfdNativeError('Round requires a finite number.', call.location);
      }
      final placesText = call.argumentCount == 2
          ? (await call.argument(1)).trim()
          : '';
      final places = placesText.isEmpty
          ? BigInt.zero
          : bdfdDecimalInteger(placesText);
      if (places == null) {
        throw BdfdNativeError(
          'Decimal places must be an integer.',
          call.location,
        );
      }
      return bdfdRoundDecimal(
        raw,
        places,
        checkBudget: call.context.budget.check,
      );
    });
    for (final name in ['ceil', 'floor']) {
      add(name, 1, 1, (call) async {
        final value = await _numeric(call, 0);
        if (value is int) return '$value';
        return _number(
          name == 'ceil' ? value.ceilToDouble() : value.floorToDouble(),
        );
      });
    }
    return functions;
  }

  Future<num> _numeric(BdfdInvocation call, int index) async {
    final value = bdfdFiniteDecimal(await call.argument(index));
    if (value == null || !value.isFinite) {
      throw BdfdNativeError(
        'Expected a finite number in argument ${index + 1}.',
        call.location,
      );
    }
    return value;
  }

  Future<Object> _arithmeticValue(BdfdInvocation call, int index) async {
    final raw = await call.argument(index);
    final integer = bdfdDecimalInteger(raw);
    if (integer != null) return integer;
    final value = bdfdFiniteDecimal(raw);
    if (value == null) {
      throw BdfdNativeError(
        'Expected a finite number in argument ${index + 1}.',
        call.location,
      );
    }
    return value;
  }

  Future<BigInt> _integer(BdfdInvocation call, int index) async {
    final value = bdfdDecimalInteger(await call.argument(index));
    if (value == null) {
      throw BdfdNativeError(
        'Expected an integer in argument ${index + 1}.',
        call.location,
      );
    }
    return value;
  }

  String _mathNumber(BdfdInvocation call, num value) =>
      _number(call.context.decimalsEnabled ? value : bdfdNearestInteger(value));
  String _number(num value) => bdfdNumberText(value);
}

sealed class _Control implements Exception {}

class _Stop extends _Control {
  _Stop([this.message]);
  final String? message;
}

class _Break extends _Control {}

class _Continue extends _Control {}

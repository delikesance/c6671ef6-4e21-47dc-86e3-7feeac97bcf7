part of '../bdfd_ast_transpiler.dart';

extension _BdfdAstTranspilationScopeInlineHelpers
    on _BdfdAstTranspilationScope {
  Object _componentBoolean(String raw) =>
      _containsRuntimePlaceholder(raw) ? raw : _parseBooleanLike(raw);

  Object? _componentInteger(String raw, [int? fallback]) =>
      _containsRuntimePlaceholder(raw) ? raw : (int.tryParse(raw) ?? fallback);

  String _componentEnum(String raw) =>
      _containsRuntimePlaceholder(raw) ? raw.trim() : raw.trim().toLowerCase();

  String _inlineReplaceText(BdfdFunctionCallAst node) {
    final text = _stringifyArgument(node, 0);
    final sample = _stringifyArgument(node, 1);
    final replacement = _stringifyArgument(node, 2);
    final amountRaw = _stringifyArgument(node, 3).trim();
    if ([
      text,
      sample,
      replacement,
      amountRaw,
    ].any(_containsRuntimePlaceholder)) {
      return _buildRuntimeBracketExpression('replacetext', [
        text,
        sample,
        replacement,
        amountRaw,
      ]);
    }
    final amount = int.tryParse(amountRaw) ?? 1;

    if (sample.isEmpty) {
      return text;
    }

    if (amount == -1) {
      return text.replaceAll(sample, replacement);
    }

    var result = text;
    var count = 0;
    while (count < amount) {
      final index = result.indexOf(sample);
      if (index < 0) {
        break;
      }
      result =
          result.substring(0, index) +
          replacement +
          result.substring(index + sample.length);
      count++;
    }
    return result;
  }

  String _inlineTitleCase(String text) {
    if (text.isEmpty) {
      return '';
    }
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _inlineCropText(BdfdFunctionCallAst node) {
    final text = _stringifyArgument(node, 0);
    final lengthRaw = _stringifyArgument(node, 1).trim();
    final suffix = _stringifyArgument(node, 2);
    final length = int.tryParse(lengthRaw) ?? text.length;
    if (length >= text.length) {
      return text;
    }
    return text.substring(0, length) + suffix;
  }

  String _inlineRepeatMessage(BdfdFunctionCallAst node) {
    final text = _stringifyArgument(node, 0);
    final countRaw = _stringifyArgument(node, 1).trim();
    if ([text, countRaw].any(_containsRuntimePlaceholder)) {
      return _buildRuntimeBracketExpression('repeatmessage', [text, countRaw]);
    }
    final count = int.tryParse(countRaw) ?? 1;
    if (count <= 0) {
      return '';
    }
    if (count > 100) {
      _diagnostics.add(
        BdfdTranspileDiagnostic(
          message: '${node.name} repeat count capped at 100.',
          severity: BdfdTranspileDiagnosticSeverity.warning,
          start: node.start,
          end: node.end,
          functionName: node.name,
        ),
      );
      return text * 100;
    }
    return text * count;
  }

  String _inlineRemoveContains(BdfdFunctionCallAst node) {
    final args = List.generate(
      node.arguments.length,
      (i) => _stringifyArgument(node, i),
    );
    if (args.any(_containsRuntimePlaceholder)) {
      return _buildRuntimeBracketExpression('removecontains', args);
    }
    var text = args.isEmpty ? '' : args.first;
    for (final target in args.skip(1)) {
      if (target.isNotEmpty) text = text.replaceAll(target, '');
    }
    return text;
  }

  String _inlineNumberSeparator(BdfdFunctionCallAst node) {
    final numberRaw = _stringifyArgument(node, 0).trim();
    final separator = _stringifyArgument(node, 1);
    final sep = separator.isEmpty ? ',' : separator;
    if ([numberRaw, separator].any(_containsRuntimePlaceholder)) {
      return _buildRuntimeBracketExpression('numberseparator', [
        numberRaw,
        separator,
      ]);
    }
    final parts = numberRaw.split('.');
    final intPart = parts[0];

    final buffer = StringBuffer();
    var count = 0;
    for (var i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0 && intPart[i] != '-') {
        buffer.write(sep);
      }
      buffer.write(intPart[i]);
      count++;
    }

    final result = buffer.toString().split('').reversed.join();
    if (parts.length > 1) {
      return '$result.${parts[1]}';
    }
    return result;
  }

  // State belongs to the running command. Capture every read at its action
  // position so a later edit cannot retroactively change an earlier output.
  Action _buildTextSplitStateAction(
    BdfdFunctionCallAst node,
    String operation, {
    bool read = false,
  }) {
    final args = List.generate(
      node.arguments.length,
      (i) => _stringifyArgument(node, i),
    );
    final key = '_bdfd_split_${_textSplitActionCounter++}';
    return Action(
      type: BotCreatorActionType.setTemporaryVariable,
      key: key,
      payload: {
        'key': read ? key : '_bdfd_textsplit',
        'valueType': 'string',
        'value': _buildRuntimeBracketExpression(
          'bdfdtextsplit$operation',
          args,
        ),
      },
    );
  }

  String _inlineTextSplitRead(BdfdFunctionCallAst node, String operation) {
    final action = _buildTextSplitStateAction(node, operation, read: true);
    _deferredInlineActions.add(action);
    return '((${action.key}.value))';
  }

  String _inlineSplitText(BdfdFunctionCallAst node) =>
      _inlineTextSplitRead(node, 'get');

  String _inlineEditSplitText(BdfdFunctionCallAst node) {
    _deferredInlineActions.add(_buildTextSplitStateAction(node, 'edit'));
    return '';
  }

  String _inlineGetTextSplitIndex(BdfdFunctionCallAst node) =>
      _inlineTextSplitRead(node, 'index');

  String _inlineJoinSplitText(BdfdFunctionCallAst node) =>
      _inlineTextSplitRead(node, 'join');

  String _inlineRemoveSplitTextElement(BdfdFunctionCallAst node) {
    _deferredInlineActions.add(_buildTextSplitStateAction(node, 'remove'));
    return '';
  }

  // ── Math inline helpers ──────────────────────────────────────

  String _inlineCalculate(BdfdFunctionCallAst node) {
    final expression = _stringifyArgument(node, 0).trim();
    if (expression.isEmpty) {
      return '0';
    }
    final result = _evaluateSimpleMathExpression(expression);
    if (result == null) {
      return '((calculate[$expression]))';
    }
    if (_enableDecimals) return result.toString();
    if (result == result.roundToDouble() && result.abs() < 1e15) {
      return result.toInt().toString();
    }
    return result.toString();
  }

  /// Recursive-descent math expression parser.
  /// Supports +, -, *, /, %, ^, **, parentheses, and unary minus.
  double? _evaluateSimpleMathExpression(String expression) =>
      MathExpressionParser.evaluate(expression);

  String _inlineMathUnary(
    BdfdFunctionCallAst node,
    int Function(double) operation,
  ) {
    final raw = _stringifyArgument(node, 0).trim();
    final value = double.tryParse(raw);
    if (value == null) {
      return '((${node.normalizedName}[$raw]))';
    }
    return operation(value).toString();
  }

  String _inlineMathUnaryDouble(
    BdfdFunctionCallAst node,
    double Function(double) operation,
  ) {
    final raw = _stringifyArgument(node, 0).trim();
    final value = double.tryParse(raw);
    if (value == null) {
      return '((${node.normalizedName}[$raw]))';
    }
    final result = operation(value);
    if (_enableDecimals) return result.toString();
    if (result == result.roundToDouble() && result.abs() < 1e15) {
      return result.toInt().toString();
    }
    return result.toString();
  }

  String _inlineMathBinary(
    BdfdFunctionCallAst node,
    num Function(num, num) operation,
  ) {
    final aRaw = _stringifyArgument(node, 0).trim();
    final bRaw = _stringifyArgument(node, 1).trim();
    final a = num.tryParse(aRaw);
    final b = num.tryParse(bRaw);
    if (a == null || b == null) {
      return '((${node.normalizedName}[$aRaw;$bRaw]))';
    }
    final result = operation(a, b);
    if (_enableDecimals) return result.toString();
    if (result is double &&
        result == result.roundToDouble() &&
        result.abs() < 1e15) {
      return result.toInt().toString();
    }
    return result.toString();
  }

  String _inlineMathBinaryOp(
    BdfdFunctionCallAst node,
    num Function(num, num) operation,
  ) {
    final aRaw = _stringifyArgument(node, 0).trim();
    final bRaw = _stringifyArgument(node, 1).trim();
    final a = num.tryParse(aRaw);
    final b = num.tryParse(bRaw);
    if (a == null || b == null) {
      return '((${node.normalizedName}[$aRaw;$bRaw]))';
    }
    final result = operation(a, b);
    if (_enableDecimals) return result.toString();
    if (result is double &&
        result == result.roundToDouble() &&
        result.abs() < 1e15) {
      return result.toInt().toString();
    }
    return result.toString();
  }

  String _inlineSum(BdfdFunctionCallAst node) {
    num total = 0;
    for (var i = 0; i < node.arguments.length; i++) {
      final raw = _stringifyArgument(node, i).trim();
      final value = num.tryParse(raw);
      if (value == null) {
        final args = List.generate(
          node.arguments.length,
          (j) => _stringifyArgument(node, j).trim(),
        ).join(';');
        return '((sum[$args]))';
      }
      total += value;
    }
    if (_enableDecimals) return total.toString();
    if (total is double &&
        total == total.roundToDouble() &&
        total.abs() < 1e15) {
      return total.toInt().toString();
    }
    return total.toString();
  }

  String _inlineSort(BdfdFunctionCallAst node) {
    final values = <String>[];
    for (var i = 0; i < node.arguments.length; i++) {
      final raw = _stringifyArgument(node, i).trim();
      if (raw.isNotEmpty) {
        values.add(raw);
      }
    }
    if (values.any(_containsRuntimePlaceholder)) {
      return _buildRuntimeBracketExpression('sort', values);
    }
    final allNumeric = values.every((v) => num.tryParse(v) != null);
    if (allNumeric) {
      values.sort((a, b) => num.parse(a).compareTo(num.parse(b)));
    } else {
      values.sort();
    }
    return values.join(';');
  }

  // ── Boolean check helpers ──────────────────────────────────────

  String _inlineIsBoolean(BdfdFunctionCallAst node) {
    final raw = _stringifyArgument(node, 0).trim();
    if (raw.contains('((')) {
      return '((isBoolean[$raw]))';
    }
    const booleans = {'true', 'false', 'yes', 'no', '1', '0', 'on', 'off'};
    return booleans.contains(raw.toLowerCase()) ? 'true' : 'false';
  }

  String _inlineIsInteger(BdfdFunctionCallAst node) {
    final raw = _stringifyArgument(node, 0).trim();
    if (raw.contains('((')) {
      return '((isInteger[$raw]))';
    }
    return int.tryParse(raw) != null ? 'true' : 'false';
  }

  String _inlineIsNumber(BdfdFunctionCallAst node) {
    final raw = _stringifyArgument(node, 0).trim();
    if (raw.contains('((')) {
      return '((isNumber[$raw]))';
    }
    return num.tryParse(raw) != null ? 'true' : 'false';
  }

  String _inlineIsValidHex(BdfdFunctionCallAst node) {
    final raw = _stringifyArgument(node, 0).trim();
    if (raw.contains('((')) {
      return '((isValidHex[$raw]))';
    }
    final cleaned = raw.startsWith('#') ? raw.substring(1) : raw;
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned) ? 'true' : 'false';
  }

  String _inlineCheckCondition(BdfdFunctionCallAst node) {
    final expression = _stringifyArgument(node, 0).trim();
    if (expression.isEmpty) {
      return 'false';
    }
    // If the expression references a runtime-resolved placeholder (a deferred
    // math result like ((sub[...])), a timestamp ((getTimestamp)), or a
    // variable read), it cannot be evaluated at compile time. The numeric
    // comparators in _evaluateConditionStatically would see a non-numeric
    // operand and always return false. Defer to the runtime checkCondition
    // handler, which resolves the operands first and then compares.
    if (expression.contains('((')) {
      return '((checkCondition[$expression]))';
    }
    final condition = _parseSimpleCondition(expression);
    return _evaluateConditionStatically(condition) ? 'true' : 'false';
  }

  bool _evaluateConditionStatically(_ParsedCondition condition) {
    switch (condition.operator) {
      case 'equals':
        return condition.left == condition.right;
      case 'notEquals':
        return condition.left != condition.right;
      case 'contains':
        return condition.left.contains(condition.right);
      case 'notContains':
        return !condition.left.contains(condition.right);
      case 'startsWith':
        return condition.left.startsWith(condition.right);
      case 'endsWith':
        return condition.left.endsWith(condition.right);
      case 'isNotEmpty':
        return condition.left.isNotEmpty;
      default:
        final leftNum = num.tryParse(condition.left);
        final rightNum = num.tryParse(condition.right);
        if (leftNum != null && rightNum != null) {
          switch (condition.operator) {
            case 'greaterThan':
              return leftNum > rightNum;
            case 'lessThan':
              return leftNum < rightNum;
            case 'greaterOrEqual':
              return leftNum >= rightNum;
            case 'lessOrEqual':
              return leftNum <= rightNum;
          }
        }
        return false;
    }
  }

  String _inlineCheckContains(BdfdFunctionCallAst node) {
    final args = List.generate(
      node.arguments.length,
      (i) => _stringifyArgument(node, i),
    );
    if (args.any(_containsRuntimePlaceholder)) {
      return _buildRuntimeBracketExpression('checkcontains', args);
    }
    final text = args.isEmpty ? '' : args.first;
    return args.skip(1).any(text.contains) ? 'true' : 'false';
  }

  // ── Random helpers ──────────────────────────────────────────

  String _inlineRandom(BdfdFunctionCallAst node) {
    final args = List.generate(
      node.arguments.length,
      (i) => _stringifyArgument(node, i),
    ).join(';');
    return '((random[$args]))';
  }

  String _inlineRandomString(BdfdFunctionCallAst node) {
    final lengthRaw = _stringifyArgument(node, 0).trim();
    final chars = _stringifyArgument(node, 1);
    return _buildRuntimeBracketExpression('randomstring', [lengthRaw, chars]);
  }

  String _inlineRandomText(BdfdFunctionCallAst node) {
    final args = List.generate(
      node.arguments.length,
      (i) => _stringifyArgument(node, i).trim(),
    ).join(';');
    return '((randomtext[$args]))';
  }

  // ── getMessage helper ──────────────────────────────────────

  String _inlineGetMessage(BdfdFunctionCallAst node) {
    final channelId = _stringifyArgument(node, 0).trim();
    final messageId = _stringifyArgument(node, 1).trim();
    final property = _stringifyArgument(node, 2).trim();
    if (channelId.isEmpty || messageId.isEmpty) {
      return '((message.content))';
    }
    if (property.isNotEmpty) {
      return '((getMessage[$channelId;$messageId].$property))';
    }
    return '((getMessage[$channelId;$messageId].content))';
  }
}

import '../utils/runtime_access_checks.dart';
import '../utils/runtime_cooldowns.dart';

// Condition evaluation shared by the historical `ifBlock`/`stopUnless`
// executors and the native visual `bc_cond` function. Extracted verbatim from
// actions/executors/control_flow_executor.dart: behaviour is unchanged.

/// Applies one of the visual condition operators (`equals`, `contains`,
/// `matches`, ...). An unknown operator is `false`, as historically.
bool evaluateActionOperator({
  required String leftValue,
  required String operator,
  required String rightValue,
}) {
  final op = operator.toLowerCase().trim();
  switch (op) {
    case 'equals':
    case '==':
      return leftValue == rightValue;
    case 'notequals':
    case '!=':
      return leftValue != rightValue;
    case 'contains':
      return leftValue.contains(rightValue);
    case 'containsignorecase':
      return leftValue.toLowerCase().contains(rightValue.toLowerCase());
    case 'equalsignorecase':
      return leftValue.toLowerCase() == rightValue.toLowerCase();
    case 'containsitem':
      return runtimeContainsItem(leftValue, rightValue);
    case 'haspermission':
      return runtimeHasPermission(leftValue, rightValue);
    case 'notcontains':
      return !leftValue.contains(rightValue);
    case 'startswith':
      return leftValue.startsWith(rightValue);
    case 'endswith':
      return leftValue.endsWith(rightValue);
    case 'greaterthan':
    case '>':
      return (num.tryParse(leftValue) ?? 0) > (num.tryParse(rightValue) ?? 0);
    case 'lessthan':
    case '<':
      return (num.tryParse(leftValue) ?? 0) < (num.tryParse(rightValue) ?? 0);
    case 'greaterorequal':
    case '>=':
      return (num.tryParse(leftValue) ?? 0) >= (num.tryParse(rightValue) ?? 0);
    case 'lessorequal':
    case '<=':
      return (num.tryParse(leftValue) ?? 0) <= (num.tryParse(rightValue) ?? 0);
    case 'isempty':
      return leftValue.trim().isEmpty;
    case 'isnotempty':
      return leftValue.trim().isNotEmpty;
    case 'matches':
      try {
        return RegExp(rightValue, caseSensitive: false).hasMatch(leftValue);
      } catch (_) {
        return false;
      }
    default:
      return false;
  }
}

bool parseActionBooleanFlag(dynamic value) {
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'yes' ||
      normalized == 'on';
}

Future<bool> evaluateActionCondition({
  required Map<String, dynamic> payload,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
  required Future<int?> Function(String scope, String key)?
  getScopedVariableTtl,
}) async {
  final rawGroup = (payload['condition.group'] ?? payload['group'] ?? '')
      .toString()
      .trim();
  if (rawGroup.isNotEmpty) {
    final group = rawGroup.toLowerCase();
    final rawConditions =
        payload['condition.conditions'] ?? payload['conditions'];
    final conditionList = <Map<String, dynamic>>[];
    if (rawConditions is List) {
      for (final item in rawConditions) {
        if (item is Map) {
          conditionList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    var groupResult = group == 'and';
    for (final condition in conditionList) {
      final passed = await evaluateActionCondition(
        payload: condition,
        variables: variables,
        resolveValue: resolveValue,
        getScopedVariableTtl: getScopedVariableTtl,
      );
      if (group == 'and') {
        groupResult = groupResult && passed;
      } else {
        groupResult = groupResult || passed;
      }
    }

    final negate = parseActionBooleanFlag(
      payload['condition.negate'] ?? payload['negate'],
    );
    return negate ? !groupResult : groupResult;
  }

  final rawConditionVariable =
      (payload['condition.variable'] ?? payload['variable'] ?? '').toString();
  final conditionOperator = resolveValue(
    (payload['condition.operator'] ?? payload['operator'] ?? 'equals')
        .toString(),
  ).trim();
  final conditionValue = resolveValue(
    (payload['condition.value'] ?? payload['value'] ?? '').toString(),
  );
  final leftValue = resolveActionConditionLeft(
    rawConditionVariable,
    variables,
    resolveValue,
  );

  final passed = evaluateActionOperator(
    leftValue: leftValue,
    operator: conditionOperator,
    rightValue: conditionValue,
  );

  // Special handling for cooldown placeholders like %time%
  if (!passed &&
      conditionOperator.toLowerCase() == 'isempty' &&
      rawConditionVariable.contains('.bc_cooldown_')) {
    final trimmed = rawConditionVariable.trim();
    final contentMatch = RegExp(r'^\(\((.+)\)\)$').firstMatch(trimmed);
    if (contentMatch != null) {
      final content = contentMatch.group(1)!;
      final firstExpression = content.split('|').first.trim();
      final scopeMatch = RegExp(r'^([^.]+)\.(.+)$').firstMatch(firstExpression);
      if (scopeMatch != null) {
        final scope = scopeMatch.group(1)!;
        final key = scopeMatch.group(2)!;
        final botId = variables['bot.id'] ?? '';

        final storageKey = key.startsWith('bc_') ? key.substring(3) : key;
        final mapKey = RuntimeCooldowns.key(
          botId,
          scope,
          storageKey,
          variables,
        );
        final expiresAt = RuntimeCooldowns.expirations[mapKey];

        if (expiresAt != null) {
          final remaining = expiresAt - DateTime.now().millisecondsSinceEpoch;
          if (remaining > 0) {
            final unixTimestampSeconds = (expiresAt / 1000).floor();
            final discordTimestamp = '<t:$unixTimestampSeconds:R>';
            variables['cooldown.time'] = discordTimestamp;
          } else {
            // Expired, clean up
            RuntimeCooldowns.expirations.remove(mapKey);
          }
        }
      }
    }
  }

  return passed;
}

String resolveActionConditionLeft(
  String rawConditionVariable,
  Map<String, String> variables,
  String Function(String input) resolveValue,
) {
  final raw = rawConditionVariable.trim();
  if (raw.isEmpty) {
    return '';
  }

  if (variables.containsKey(raw)) {
    return variables[raw] ?? '';
  }

  final wrappedMatch = RegExp(r'^\(\((.+)\)\)$').firstMatch(raw);
  if (wrappedMatch != null) {
    final wrappedKey = (wrappedMatch.group(1) ?? '').trim();
    final expressions = wrappedKey.split('|').map((e) => e.trim()).toList();

    for (final expr in expressions) {
      if (expr.contains('.bc_cooldown_')) {
        final scopeMatch = RegExp(r'^([^.]+)\.(.+)$').firstMatch(expr);
        if (scopeMatch != null) {
          final scope = scopeMatch.group(1)!;
          final key = scopeMatch.group(2)!;
          final botId = variables['bot.id'] ?? '';
          final storageKey = key.startsWith('bc_') ? key.substring(3) : key;

          final mapKey = RuntimeCooldowns.key(
            botId,
            scope,
            storageKey,
            variables,
          );
          final expiresAt = RuntimeCooldowns.expirations[mapKey];
          if (expiresAt != null) {
            final remaining = expiresAt - DateTime.now().millisecondsSinceEpoch;
            if (remaining > 0) {
              return 'cooldown_active';
            } else {
              RuntimeCooldowns.expirations.remove(mapKey);
            }
          }
          // Cooldown is NOT active in RAM, so return empty even if it exists in 'variables'
          return '';
        }
      }

      final value = variables[expr];
      if (value != null) {
        return value;
      }
    }
  }

  return resolveValue(rawConditionVariable);
}

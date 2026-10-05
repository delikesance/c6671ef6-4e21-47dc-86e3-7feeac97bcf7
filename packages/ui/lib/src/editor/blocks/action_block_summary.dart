import '../catalog/action_types.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;

/// Résumé monospace sur une ligne d'un bloc d'action (ex. `score.a ← GET /scores/a`).
///
/// N'emploie que des valeurs (variable, méthode, URL, texte) — jamais de phrase
/// localisée — et renvoie `null` quand rien de significatif n'est configuré.
String? summarizeActionBlock(ActionItem action) {
  final p = action.parameters;
  String v(dynamic raw) => (raw ?? '').toString().replaceAll('\n', ' ').trim();
  String cut(String s, [int max = 64]) =>
      s.length <= max ? s : '${s.substring(0, max - 1)}…';
  final key = action.actionKey.trim();

  switch (action.type) {
    case BotCreatorActionType.httpRequest:
      final url = v(p['url']);
      if (url.isEmpty) return null;
      final method = v(p['method']).isEmpty
          ? 'GET'
          : v(p['method']).toUpperCase();
      final call = '$method ${cut(url)}';
      return key.isEmpty ? call : '$key ← $call';
    case BotCreatorActionType.setGlobalVariable:
    case BotCreatorActionType.setScopedVariable:
      final name = v(p['name'] ?? p['key']);
      if (name.isEmpty) return null;
      final value = v(p['value']);
      return value.isEmpty ? name : '$name ← ${cut(value, 40)}';
    case BotCreatorActionType.ifBlock:
      final left = v(p['condition.variable'] ?? p['left']);
      if (left.isEmpty) return null;
      final op = v(p['condition.operator'] ?? p['operator']);
      final right = v(p['condition.value'] ?? p['right']);
      return cut('$left ${op.isEmpty ? '==' : op} $right'.trim());
    default:
      final text = v(p['content'] ?? p['text'] ?? p['message']);
      if (text.isNotEmpty) return cut(text);
      for (final entry in p.entries) {
        if (entry.key == 'key') continue;
        final value = v(entry.value);
        if (value.isNotEmpty && entry.value is! Map && entry.value is! List) {
          return cut('${entry.key}: $value');
        }
      }
      return key.isEmpty ? null : key;
  }
}

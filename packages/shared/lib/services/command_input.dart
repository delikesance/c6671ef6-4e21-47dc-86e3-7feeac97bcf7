/// Reads the argument variables supplied by entry-point adapters. Prefix
/// adapters must supply arguments without the command trigger, using
/// buildCommandArgumentRuntimeVariables. Named options use the existing opts.*
/// keys. Values are data and are never interpreted as BDFD or placeholders.
class CommandInput {
  CommandInput(this.variables);
  final Map<String, String> variables;
  List<String> get userMentions {
    final encoded = variables['message.mentions'];
    if (encoded != null) {
      return encoded.split(',').where((id) => id.isNotEmpty).toList();
    }
    final result = <String>[];
    for (var i = 0; i < variables.length; i++) {
      final id = variables['message.mentions[$i]'];
      if (id == null) break;
      result.add(id);
    }
    return result;
  }

  bool get isSlash => variables['interaction.isSlash'] == 'true';
  String get text => variables['message.content'] ?? '';
  List<String> get words => text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  int get count => int.tryParse(variables['args.count'] ?? '') ?? words.length;

  String at(String selector) {
    if (selector == '<') return at('1');
    if (selector == '>') {
      return variables['message.args.last'] ??
          (words.isEmpty ? '' : words.last);
    }
    final index = int.tryParse(selector);
    if (index == null || index < 1) return '';
    return variables['args.$index'] ??
        variables['message.content[${index - 1}]'] ??
        (index <= words.length ? words[index - 1] : '');
  }

  String message(String? first, {String? second}) {
    if (first == null ||
        (first.isEmpty && (second == null || second.isEmpty))) {
      return text;
    }
    if (isSlash) {
      return variables['opts.${second != null && second.isNotEmpty ? second : first}'] ??
          '';
    }
    if (first.startsWith('>') && first.length > 1) {
      final skip = int.tryParse(first.substring(1));
      return skip != null && skip >= 0 ? words.skip(skip).join(' ') : '';
    }
    final start = int.tryParse(first);
    if (start != null && start > 0 && second != null) {
      final end = int.tryParse(second);
      if (end != null) {
        return words
            .skip(start - 1)
            .take((end - start + 1).clamp(0, words.length))
            .join(' ');
      }
      if (second.isEmpty) return words.skip(start - 1).join(' ');
    }
    return at(first);
  }
}

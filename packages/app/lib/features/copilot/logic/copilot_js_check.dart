/// Pre-flight checks for a JavaScript command script proposed by the assistant. There is no JavaScript
/// sandbox, so these catch the mistakes that otherwise only surface on Discord: a script that does not
/// parse (unterminated string or template literal, unbalanced brackets), the non-existent
/// `interaction.client.db`, and options read by the script but never declared on the command.
///
/// Every rule is high-confidence: a finding means the script is broken, never a style preference.
List<String> checkCopilotJavascript(
  String script, {
  Set<String>? declaredOptions,
}) {
  final problems = <String>[];
  final structure = _structureProblem(script);
  if (structure != null) problems.add(structure);
  if (RegExp(
    r'interaction\s*\.\s*client\s*\.\s*db\b|\bclient\s*\.\s*db\s*\.',
  ).hasMatch(script)) {
    problems.add(
      '`db` is a global (db.user.get / db.user.set / db.global.get...); there is no client.db',
    );
  }
  if (RegExp(
    r'^\s*(?:export\s|import\s+[\w{*]|module\s*\.\s*exports|exports\s*\.)',
    multiLine: true,
  ).hasMatch(script)) {
    problems.add(
      'the script is the BODY of an async function: no import/export/module.exports (use require(name) for whitelisted modules, and return or await directly)',
    );
  }
  if (declaredOptions != null) {
    final read = RegExp(
      r'''options\s*\.\s*get(?:String|Integer|Number|Boolean|User|Member|Channel|Role|Attachment|Mentionable)\s*\(\s*(['"`])([^'"`]+)\1''',
    );
    final missing = <String>{
      for (final m in read.allMatches(script))
        if (!declaredOptions.contains(m.group(2))) m.group(2)!,
    };
    if (missing.isNotEmpty) {
      problems.add(
        'the script reads option(s) ${missing.map((n) => '"$n"').join(', ')} that are not declared in `options`; declare them in the same call (declared: ${declaredOptions.isEmpty ? 'none' : declaredOptions.map((n) => '"$n"').join(', ')})',
      );
    }
  }
  return problems;
}

/// Names of every option declared by a `local_create_command` options list, including nested ones.
Set<String> copilotDeclaredOptionNames(Object? options) {
  final names = <String>{};
  void walk(Object? list) {
    if (list is! List) return;
    for (final item in list) {
      if (item is! Map) continue;
      final name = item['name'];
      if (name is String) names.add(name);
      walk(item['options']);
    }
  }

  walk(options);
  return names;
}

const _regexPrefixChars = '(,=:[!&|?{};+-*%<>~^';

String? _structureProblem(String s) {
  final stack = <String>[]; // bracket stack; '`' frames mark template literals
  var i = 0;
  var line = 1;
  String? lastSignificant;
  String? lastWord;
  const pairs = {')': '(', ']': '[', '}': '{'};

  String? scanString(String quote) {
    final startLine = line;
    i++;
    while (i < s.length) {
      final c = s[i];
      if (c == r'\') {
        i += 2;
        continue;
      }
      if (c == '\n') {
        return 'unterminated string started on line $startLine (use a template literal or \\n for multi-line text)';
      }
      if (c == quote) {
        i++;
        return null;
      }
      i++;
    }
    return 'unterminated string started on line $startLine';
  }

  // Scans template text until the closing backtick or a `${`, which pushes a frame.
  String? scanTemplateText() {
    final startLine = line;
    while (i < s.length) {
      final c = s[i];
      if (c == r'\') {
        i += 2;
        continue;
      }
      if (c == '\n') line++;
      if (c == '`') {
        i++;
        return null;
      }
      if (c == r'$' && i + 1 < s.length && s[i + 1] == '{') {
        i += 2;
        stack.add('`{');
        return null;
      }
      i++;
    }
    return 'unterminated template literal started on line $startLine (an unescaped backtick inside a template literal ends it early: escape it as \\`)';
  }

  while (i < s.length) {
    final c = s[i];
    if (c == '\n') {
      line++;
      i++;
      continue;
    }
    if (c == ' ' || c == '\t' || c == '\r') {
      i++;
      continue;
    }
    if (c == '/' && i + 1 < s.length && s[i + 1] == '/') {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '/' && i + 1 < s.length && s[i + 1] == '*') {
      final end = s.indexOf('*/', i + 2);
      if (end < 0) return 'unterminated /* comment';
      line += '\n'.allMatches(s.substring(i, end)).length;
      i = end + 2;
      continue;
    }
    if (c == '"' || c == "'") {
      final err = scanString(c);
      if (err != null) return err;
      lastSignificant = c;
      lastWord = null;
      continue;
    }
    if (c == '`') {
      i++;
      final err = scanTemplateText();
      if (err != null) return err;
      lastSignificant = '`';
      lastWord = null;
      continue;
    }
    if (c == '/') {
      final regexAllowed =
          lastSignificant == null ||
          _regexPrefixChars.contains(lastSignificant) ||
          lastWord == 'return' ||
          lastWord == 'typeof';
      if (!regexAllowed &&
          lastSignificant == '`' &&
          RegExp(r'/[A-Za-z_][\w-]*`').matchAsPrefix(s, i) != null) {
        return 'a backtick inside a template literal ends it early (line $line); escape inner backticks as \\` or use quotes';
      }
      if (regexAllowed) {
        i++;
        var inClass = false;
        var closed = false;
        while (i < s.length && s[i] != '\n') {
          final r = s[i];
          if (r == r'\') {
            i += 2;
            continue;
          }
          if (r == '[') {
            inClass = true;
          } else if (r == ']') {
            inClass = false;
          }
          if (r == '/' && !inClass) {
            closed = true;
            i++;
            break;
          }
          i++;
        }
        if (!closed) return 'unterminated regular expression on line $line';
        lastSignificant = '/';
        lastWord = null;
        continue;
      }
    }
    if ('([{'.contains(c)) {
      stack.add(c);
    } else if (')]}'.contains(c)) {
      if (c == '}' && stack.isNotEmpty && stack.last == '`{') {
        stack.removeLast();
        i++;
        final err = scanTemplateText();
        if (err != null) return err;
        lastSignificant = '`';
        lastWord = null;
        continue;
      }
      if (stack.isEmpty || stack.last != pairs[c]) {
        return 'unexpected "$c" on line $line';
      }
      stack.removeLast();
    }
    if (RegExp(r'[A-Za-z_$]').hasMatch(c)) {
      final m = RegExp(r'[A-Za-z0-9_$]+').matchAsPrefix(s, i)!;
      lastWord = m.group(0);
      lastSignificant = 'a';
      i = m.end;
      continue;
    }
    lastWord = null;
    lastSignificant = c;
    i++;
  }
  if (stack.isNotEmpty) {
    final open = stack.last == '`{' ? r'${' : stack.last;
    return 'unclosed "$open"';
  }
  return null;
}

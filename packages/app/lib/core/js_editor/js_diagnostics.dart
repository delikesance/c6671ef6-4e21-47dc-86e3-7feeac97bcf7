import 'package:bot_creator/core/code_editor/script_editor_language.dart';

/// Analyse statique « honnête » du JavaScript édité dans l'application.
///
/// Ce n'est **pas** un parseur : c'est un scanner à état qui suit exactement ce
/// qu'un éditeur doit suivre pour rester fiable :
/// - chaînes `'…'` / `"…"` (antislash d'échappement pris en compte, saut de
///   ligne brut interdit dans une chaîne) ;
/// - templates `` `…` `` **avec l'imbrication `${ … }`** et, dans une
///   substitution, les mêmes règles que dans le code (chaînes, templates,
///   commentaires) ;
/// - commentaires `// …` (jusqu'au saut de ligne) et `/* … */` ;
/// - équilibre des couples `()` `[]` `{}`.
///
/// Le scanner ne devine jamais : il n'émet que les diagnostics qu'il peut
/// prouver depuis cet état (voir [ScriptDiagnosticCode]). Deux limitations
/// assumées : une expression régulière littérale n'est pas reconnue (aucune
/// heuristique de désambiguïsation du `/`, donc un motif contenant `(`, `)` ou
/// `{` peut fausser l'équilibre), et aucune autre erreur n'est inventée.
List<ScriptDiagnostic> analyzeJavaScript(String source) {
  final diagnostics = <ScriptDiagnostic>[];
  final openers = <_Opener>[];
  final length = source.length;
  var i = 0;

  while (i < length) {
    // Texte d'un template : le sommet de la pile est un backtick.
    if (openers.isNotEmpty && openers.last.char == '`') {
      final char = source[i];
      if (char == r'\') {
        i += 2;
        continue;
      }
      if (char == '`') {
        openers.removeLast();
        i += 1;
        continue;
      }
      if (char == r'$' && i + 1 < length && source[i + 1] == '{') {
        openers.add(_Opener('{', i + 1));
        i += 2;
        continue;
      }
      i += 1;
      continue;
    }

    final char = source[i];

    if (char == "'" || char == '"') {
      final end = _stringEnd(source, i);
      if (end == null) {
        diagnostics.add(
          _diagnostic(ScriptDiagnosticCode.unterminatedString, source, i),
        );
        break;
      }
      i = end;
      continue;
    }

    if (char == r'/') {
      final next = i + 1 < length ? source[i + 1] : '';
      if (next == '/') {
        final newline = source.indexOf('\n', i);
        i = newline < 0 ? length : newline + 1;
        continue;
      }
      if (next == '*') {
        final close = source.indexOf('*/', i + 2);
        if (close < 0) {
          diagnostics.add(
            _diagnostic(ScriptDiagnosticCode.unterminatedComment, source, i),
          );
          break;
        }
        i = close + 2;
        continue;
      }
    }

    if (char == '`') {
      openers.add(_Opener('`', i));
      i += 1;
      continue;
    }

    if (char == '(' || char == '[' || char == '{') {
      openers.add(_Opener(char, i));
      i += 1;
      continue;
    }

    final expected = _matchingOpener[char];
    if (expected != null) {
      if (openers.isNotEmpty && openers.last.char == expected) {
        openers.removeLast();
      } else {
        // Fermante orpheline (pile vide) ou mal appariée : le scanner ne
        // devine pas l'ouvrante voulue, il ne dépile donc rien.
        diagnostics.add(
          _diagnostic(
            ScriptDiagnosticCode.unexpectedClosing,
            source,
            i,
            detail: char,
          ),
        );
      }
      i += 1;
      continue;
    }

    i += 1;
  }

  if (openers.isEmpty) {
    return diagnostics;
  }

  // Un backtick jamais fermé n'est signalé que si le scan s'est arrêté *dans*
  // le texte du template. Si c'est un `${` qui n'est jamais fermé, le coupable
  // est l'accolade : signaler en plus le template serait un faux positif, son
  // backtick pouvant simplement être resté dans une substitution ouverte.
  if (openers.last.char == '`') {
    final template = openers.removeLast();
    diagnostics.add(
      _diagnostic(
        ScriptDiagnosticCode.unterminatedTemplate,
        source,
        template.offset,
      ),
    );
  }

  for (final opener in openers) {
    if (opener.char == '`') {
      continue;
    }
    diagnostics.add(
      _diagnostic(
        ScriptDiagnosticCode.unclosedOpening,
        source,
        opener.offset,
        detail: opener.char,
      ),
    );
  }

  return diagnostics;
}

/// Un ouvrant rencontré et encore ouvert à la fin du scan.
class _Opener {
  _Opener(this.char, this.offset);

  /// Caractère ouvrant (`(`, `[`, `{`) ou backtick d'un template.
  final String char;

  /// Offset de l'ouvrant dans la source.
  final int offset;
}

/// Ouvrante attendue pour chaque fermante.
const _matchingOpener = <String, String>{')': '(', ']': '[', '}': '{'};

/// Index juste après la guillemet fermante de la chaîne ouverte en [start], ou
/// `null` si elle n'est pas fermée avant la fin de ligne / fin du document.
int? _stringEnd(String source, int start) {
  final quote = source.codeUnitAt(start);
  var i = start + 1;
  while (i < source.length) {
    final unit = source.codeUnitAt(i);
    if (unit == 0x5C) {
      // Antislash : le caractère suivant est littéral.
      i += 2;
      continue;
    }
    if (unit == quote) {
      return i + 1;
    }
    if (unit == 0x0A) {
      return null;
    }
    i += 1;
  }
  return null;
}

/// Diagnostic positionné sur [offset] ; l'UI traduit le [ScriptDiagnosticCode].
ScriptDiagnostic _diagnostic(
  ScriptDiagnosticCode code,
  String source,
  int offset, {
  String detail = '',
}) {
  final at = scriptLineColumnAt(source, offset);
  return ScriptDiagnostic(
    code: code,
    severity: _severityOf(code),
    line: at.line,
    column: at.column,
    detail: detail,
    // Le message d'une ouvrante non fermée rappelle la ligne où elle a été vue.
    detailLine: code == ScriptDiagnosticCode.unclosedOpening ? at.line : null,
  );
}

/// Sévérité associée à un code : une ouvrante non fermée se voit aussi en cours
/// de frappe (warning), les autres codes sont des erreurs certaines.
ScriptDiagnosticSeverity _severityOf(ScriptDiagnosticCode code) {
  return code == ScriptDiagnosticCode.unclosedOpening
      ? ScriptDiagnosticSeverity.warning
      : ScriptDiagnosticSeverity.error;
}

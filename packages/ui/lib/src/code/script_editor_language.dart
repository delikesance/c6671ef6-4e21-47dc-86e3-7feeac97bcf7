import 'package:flutter/widgets.dart';

/// Kind of an autocomplete entry; drives the icon shown in the panel.
enum ScriptCompletionKind { symbol, callable, snippet, emoji }

/// One autocomplete entry offered by a [ScriptEditorLanguage].
class ScriptCompletionEntry {
  const ScriptCompletionEntry({
    required this.label,
    required this.insert,
    this.cursorOffset,
    this.kind = ScriptCompletionKind.symbol,
  });

  /// Text displayed in the completion panel.
  final String label;

  /// Text actually written into the document.
  final String insert;

  /// Caret offset inside [insert] once inserted; defaults to its end.
  final int? cursorOffset;

  final ScriptCompletionKind kind;
}

/// Result of an autocomplete query.
///
/// [replaceStart] is the offset the insertion replaces up to the caret, so the
/// scaffold can rewrite the document without knowing the language grammar
/// (`$` prefix for BDFD, word prefix for JavaScript, `<:` for emojis).
class ScriptCompletionResult {
  const ScriptCompletionResult({
    required this.replaceStart,
    required this.entries,
  });

  /// Offset of the first character of the token being completed.
  final int replaceStart;

  /// Candidates to display; empty means "no panel".
  final List<ScriptCompletionEntry> entries;

  bool get isEmpty => entries.isEmpty;
}

/// Signature hint of the call the caret sits in.
class ScriptSignatureHint {
  const ScriptSignatureHint({
    required this.name,
    required this.parameters,
    this.activeIndex = -1,
  });

  /// Callable name, displayed as typed (`interaction.reply`, `$reply`).
  final String name;

  /// Argument labels, in declaration order.
  final List<String> parameters;

  /// Index of the argument the caret currently sits in; `-1` when unknown.
  final int activeIndex;
}

enum ScriptDiagnosticSeverity { error, warning }

/// Stable diagnostic identifiers.
///
/// Diagnostics carry **no user-facing text**: the editor maps a code to a
/// localized message, which keeps this layer free of i18n and lets the same
/// analyzer feed logs, tests and the diagnostics bar.
enum ScriptDiagnosticCode {
  /// A `'` or `"` string literal never got its closing quote.
  unterminatedString,

  /// A `` ` `` template literal never got its closing backtick.
  unterminatedTemplate,

  /// A `/*` block comment never got its `*/`.
  unterminatedComment,

  /// A closing bracket with no matching opener.
  unexpectedClosing,

  /// An opener that is still open at end of input.
  unclosedOpening,
}

/// A single static problem reported for a script.
class ScriptDiagnostic {
  const ScriptDiagnostic({
    required this.code,
    required this.severity,
    this.line,
    this.column,
    this.detail = '',
    this.detailLine,
    this.message,
  });

  final ScriptDiagnosticCode code;
  final ScriptDiagnosticSeverity severity;

  /// 1-based ligne du problème, quand elle est connue.
  final int? line;

  /// 1-based colonne du problème, quand elle est connue.
  final int? column;

  /// Valeur technique substituée dans le message localisé (token fautif, …).
  /// Jamais traduite elle-même.
  final String detail;

  /// Ligne secondaire substituée dans le message localisé (ex. la ligne où un
  /// ouvrant non fermé a été vu).
  final int? detailLine;

  /// Message **déjà rédigé** par un analyseur existant (le compilateur BDFD,
  /// dont les diagnostics sont affichés tels quels depuis toujours).
  ///
  /// Les diagnostics construits autour d'un [code] laissent ce champ vide : la
  /// page les traduit via `messageBuilder`. Quand il est renseigné, il prime.
  final String? message;

  @override
  String toString() =>
      'ScriptDiagnostic(${code.name}, ${severity.name}, '
      'line: $line, column: $column, detail: $detail)';
}

/// Language layer consumed by the shared script editor chrome.
///
/// The chrome (line numbers, indent guides, overlays, diagnostics bar, quick
/// chars) is identical for every language; only the three queries below differ.
/// Implementations run on every keystroke, so they must be synchronous, cheap
/// and side-effect free (no I/O, no `setState`).
abstract class ScriptEditorLanguage {
  /// Autocomplete query at [caretOffset], or `null` when the caret is not in a
  /// completable position.
  ScriptCompletionResult? completionAt(String text, int caretOffset);

  /// Signature hint for the call the caret sits in, or `null`.
  ScriptSignatureHint? signatureAt(String text, int caretOffset);

  /// Static diagnostics for [text]; an empty list means "nothing detected".
  List<ScriptDiagnostic> diagnosticsFor(String text);

  /// Keys of the mobile quick-char bar.
  List<String> get quickChars;

  /// Extra indentation added after pressing Enter at the end of [previousLine].
  ///
  /// `0` (the default) copies the previous line indentation verbatim; a
  /// language whose blocks are delimited by brackets can return its tab size
  /// when [previousLine] ends with an opener.
  int indentIncreaseFor(String previousLine) => 0;

  /// Indentation unit used by the auto-indent formatter.
  String indentUnit() => '  ';
}

/// Helper shared by the language implementations: 1-based line/column of
/// [offset] inside [text], tolerating out-of-range offsets.
({int line, int column}) scriptLineColumnAt(String text, int offset) {
  final safe = offset.clamp(0, text.length);
  var line = 1;
  var lineStart = 0;
  for (var i = 0; i < safe; i++) {
    if (text.codeUnitAt(i) == 0x0A) {
      line += 1;
      lineStart = i + 1;
    }
  }
  return (line: line, column: safe - lineStart + 1);
}

/// The Flutter offset of the caret once [entry] replaced the token starting at
/// [replaceStart].
int scriptCaretOffsetAfterInsert(
  ScriptCompletionEntry entry,
  int replaceStart,
) {
  final insert = entry.insert;
  final explicit = entry.cursorOffset;
  if (explicit != null) {
    return replaceStart + explicit.clamp(0, insert.length);
  }
  final opener = insert.indexOf('[');
  final paren = insert.indexOf('(');
  final candidate = opener >= 0 ? opener : paren;
  if (candidate >= 0) {
    // Just after the opener: `$description[|]`, `getString(|"")`.
    return replaceStart + candidate + 1;
  }
  return replaceStart + insert.length;
}

/// Convenience for language implementations: the offset of the caret, clamped
/// to the document, from a possibly invalid [selection].
int scriptClampedCaret(String text, TextSelection selection) {
  if (!selection.isValid || selection.baseOffset < 0) {
    return text.length;
  }
  return selection.baseOffset.clamp(0, text.length);
}

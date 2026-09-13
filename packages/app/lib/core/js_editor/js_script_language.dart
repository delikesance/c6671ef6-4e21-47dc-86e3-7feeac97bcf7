import 'package:bot_creator/core/code_editor/script_editor_language.dart';
import 'package:bot_creator/core/js_editor/js_completion_index.dart';
import 'package:bot_creator/core/js_editor/js_diagnostics.dart';
import 'package:bot_creator/core/js_editor/js_signature_hints.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';

/// Adaptateur JavaScript du chrome d'éditeur partagé.
///
/// Tout est synchrone et sans I/O : l'index de complétion est chargé par
/// l'appelant (`JsCompletionIndex.load()`) puis injecté ici.
class JsScriptLanguage implements ScriptEditorLanguage {
  JsScriptLanguage({
    this.index,
    this.appEmojis = const <AppEmoji>[],
    int tabSize = 2,
  }) : _tabSize = tabSize < 1 ? 1 : tabSize;

  /// Index de complétion injecté par l'appelant (`JsCompletionIndex.load()`),
  /// `null` tant qu'il n'est pas chargé.
  final JsCompletionIndex? index;

  /// Emojis du serveur courant, pour le déclencheur `<:` / `<a:`.
  final List<AppEmoji> appEmojis;

  /// Taille d'indentation, alignée sur `CodeEditorSettings.tabSize` (2 par
  /// défaut) : l'unité retournée par [indentUnit] en dérive.
  final int _tabSize;

  /// Nombre maximum d'emojis proposés, comme dans l'éditeur BDFD.
  static const int _maxEmojiSuggestions = 6;

  /// Déclencheur d'emoji : `<:`, `<a:` puis un éventuel début de nom.
  static final RegExp _emojiTrigger = RegExp(r'<(a?):([A-Za-z0-9_-]*)$');

  /// Dernier mot du document avant le curseur (à remplacer par la complétion).
  static final RegExp _wordPrefix = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*$');

  /// Label d'un membre appelable : segment final en minuscules (`deferReply`),
  /// par opposition aux classes/types (`Client`, `GatewayIntentBits`).
  static final RegExp _callableLabel = RegExp(r'^[a-z_$][A-Za-z0-9_$]*$');

  @override
  List<String> get quickChars => const <String>[
    '{',
    '}',
    '(',
    ')',
    '[',
    ']',
    ';',
    '"',
    "'",
    '`',
    '=',
    '.',
    '>',
  ];

  @override
  ScriptCompletionResult? completionAt(String text, int caretOffset) {
    final caret = caretOffset.clamp(0, text.length);
    final before = text.substring(0, caret);

    final emoji = _emojiCompletion(before, caret);
    if (emoji != null) {
      return emoji;
    }

    final completionIndex = index;
    if (completionIndex == null) {
      return null;
    }

    // L'index travaille sur des lignes/colonnes 0-based.
    final at = scriptLineColumnAt(text, caret);
    final candidates = completionIndex.completionsAt(
      documentText: text,
      line: at.line - 1,
      character: at.column - 1,
    );
    if (candidates.isEmpty) {
      return null;
    }

    final prefix = _wordPrefix.firstMatch(before)?.group(0) ?? '';
    return ScriptCompletionResult(
      replaceStart: caret - prefix.length,
      entries: <ScriptCompletionEntry>[
        for (final candidate in candidates)
          ScriptCompletionEntry(
            label: candidate.label,
            insert: candidate.insertText ?? candidate.label,
            kind: _callableLabel.hasMatch(candidate.label.split('.').last)
                ? ScriptCompletionKind.callable
                : ScriptCompletionKind.symbol,
          ),
      ],
    );
  }

  @override
  ScriptSignatureHint? signatureAt(String text, int caretOffset) =>
      jsSignatureHintAt(text, caretOffset);

  @override
  List<ScriptDiagnostic> diagnosticsFor(String text) => analyzeJavaScript(text);

  @override
  String indentUnit() => ' ' * _tabSize;

  @override
  int indentIncreaseFor(String previousLine) {
    final trimmed = previousLine.trimRight();
    if (trimmed.isEmpty) {
      return 0;
    }
    final last = trimmed[trimmed.length - 1];
    return last == '{' || last == '(' || last == '[' ? indentUnit().length : 0;
  }

  /// Emojis du serveur quand le texte avant le curseur se termine par `<:` ou
  /// `<a:` (avec un éventuel début de nom), sinon `null`.
  ScriptCompletionResult? _emojiCompletion(String before, int caret) {
    if (appEmojis.isEmpty) {
      return null;
    }
    final match = _emojiTrigger.firstMatch(before);
    if (match == null) {
      return null;
    }

    final prefix = (match.group(2) ?? '').toLowerCase();
    final entries = <ScriptCompletionEntry>[];
    for (final emoji in appEmojis) {
      if (prefix.isNotEmpty && !emoji.name.toLowerCase().startsWith(prefix)) {
        continue;
      }
      entries.add(
        ScriptCompletionEntry(
          label: emoji.name,
          insert: emoji.mention,
          kind: ScriptCompletionKind.emoji,
        ),
      );
      if (entries.length >= _maxEmojiSuggestions) {
        break;
      }
    }
    if (entries.isEmpty) {
      return null;
    }

    // `replaceStart` pointe sur le `<` du déclencheur.
    return ScriptCompletionResult(
      replaceStart: caret - match.group(0)!.length,
      entries: entries,
    );
  }
}

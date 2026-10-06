import './script_editor_language.dart';
import '../editor/host/editor_host.dart' show EditorDiagnostic;
import '../editor/models/app_emoji.dart';
import 'package:bot_creator_shared/utils/bdfd_autocomplete.dart';
import 'package:bot_creator_shared/utils/bdfd_lexer.dart';
import 'package:bot_creator_shared/utils/bdfd_parser.dart';
import 'package:bot_creator_shared/utils/bdfd_signature_hints.dart';

/// Caractères de la barre de touches rapides BDFD (mobile).
const List<String> _quickChars = <String>[
  r'$', '[', ']', ';', '{', '}', '(', ')', '"', '=', '<:', '>', '/', //
];

/// Mode de complétion déduit de la position du curseur.
enum _AutocompleteMode { function, emoji }

/// Début du jeton à remplacer (`$` ou `<`) et mode de complétion associé.
typedef _Trigger = ({int start, _AutocompleteMode mode});

/// Adaptateur BDFD du chrome d'éditeur partagé : complétions (`$fonction`,
/// emojis `<:nom` / `<a:nom`), signature de l'appel sous le curseur et
/// diagnostics du compilateur BDFD. Tout est synchrone et sans effet de bord,
/// puisque le chrome interroge ces méthodes à chaque frappe.
class BdfdScriptLanguage implements ScriptEditorLanguage {
  BdfdScriptLanguage({
    this.appEmojis = const <AppEmoji>[],
    this.backend = 'native-v1',
  });

  /// Emojis du serveur courant, proposés sur le déclencheur `<:` / `<a:`.
  final List<AppEmoji> appEmojis;
  final String backend;

  final BdfdLexer _lexer = BdfdLexer();

  /// Caractères d'un nom de fonction BDFD (`addbutton`, `setvar2`…).
  static final RegExp _identifierChar = RegExp(r'[A-Za-z0-9_]');

  /// Préfixe minimal avant de proposer des fonctions, et nombre maximal
  /// d'entrées proposées, fonctions comme emojis.
  static const int _minPrefixLength = 2;
  static const int _maxItems = 6;

  @override
  List<String> get quickChars => _quickChars;

  /// Indentation BDFD : deux espaces.
  @override
  String indentUnit() => '  ';

  /// Aucun cran d'indentation en plus : BDFD n'a pas de bloc délimité par des
  /// accolades, donc après Entrée la ligne suivante recopie l'indentation de la
  /// précédente. Le `0` est écrit explicitement car `implements` ne reprend pas
  /// les corps par défaut de l'interface.
  @override
  int indentIncreaseFor(String previousLine) => 0;

  @override
  ScriptCompletionResult? completionAt(String text, int caretOffset) {
    final caret = caretOffset.clamp(0, text.length);
    final trigger = _triggerAt(text, caret);
    if (trigger == null) {
      return null;
    }
    return switch (trigger.mode) {
      _AutocompleteMode.emoji => _emojiCompletion(text, caret, trigger.start),
      _AutocompleteMode.function => _funcCompletion(text, caret, trigger.start),
    };
  }

  @override
  ScriptSignatureHint? signatureAt(String text, int caretOffset) {
    if (text.isEmpty) {
      return null;
    }
    final caret = caretOffset.clamp(0, text.length);
    final context = bdfdSignatureContextAt(text, caret, _lexer.tokenize(text));
    if (context == null) {
      return null;
    }
    return ScriptSignatureHint(
      name: context.functionName,
      parameters: context.parameters,
      activeIndex: context.activeIndex,
    );
  }

  @override
  List<ScriptDiagnostic> diagnosticsFor(String text) => <ScriptDiagnostic>[
    for (final diagnostic in BdfdEditorHooks.diagnostics(text, backend))
      ScriptDiagnostic(
        // Le compilateur BDFD rédige lui-même le texte affiché : le code n'est
        // lu par l'UI que faute de [ScriptDiagnostic.message].
        code: ScriptDiagnosticCode.unexpectedClosing,
        severity: diagnostic.isError
            ? ScriptDiagnosticSeverity.error
            : ScriptDiagnosticSeverity.warning,
        line: diagnostic.line,
        column: diagnostic.column,
        message: diagnostic.message,
      ),
  ];

  /// Message de la barre de diagnostics : le compilateur BDFD produit déjà la
  /// phrase affichée depuis toujours, elle prime sur tout mapping par code.
  String describe(ScriptDiagnostic diagnostic) => diagnostic.message ?? '';

  // ── Complétion ──────────────────────────────────────────────────────────

  /// Début du jeton à remplacer et mode détecté, ou `null` quand le curseur
  /// n'est pas dans une position complétable.
  _Trigger? _triggerAt(String text, int caret) {
    if (caret <= 0 || caret > text.length) {
      return null;
    }

    // Emoji : le curseur suit immédiatement le déclencheur `<:`.
    if (caret >= 2 && text[caret - 2] == '<' && text[caret - 1] == ':') {
      return (start: caret - 2, mode: _AutocompleteMode.emoji);
    }

    // Emoji avec un début de nom déjà saisi : `<:par` ou `<a:par`.
    var i = caret - 1;
    while (i >= 0) {
      final c = text[i];
      if (c == ':') {
        if (i >= 2 && text[i - 1] == 'a' && text[i - 2] == '<') {
          return (start: i - 2, mode: _AutocompleteMode.emoji);
        }
        if (i >= 1 && text[i - 1] == '<') {
          return (start: i - 1, mode: _AutocompleteMode.emoji);
        }
      }
      if (_identifierChar.hasMatch(c)) {
        i -= 1;
        continue;
      }
      break;
    }

    // Fonction : le `$` ouvre le nom en cours de frappe.
    i = caret - 1;
    while (i >= 0) {
      final c = text[i];
      if (_identifierChar.hasMatch(c)) {
        i -= 1;
        continue;
      }
      if (c == r'$') {
        return (start: i, mode: _AutocompleteMode.function);
      }
      break;
    }

    return null;
  }

  /// Complétion `$fonction` : préfixe d'au moins deux caractères, six résultats
  /// au plus triés par nom, et silence quand le nom saisi est déjà complet.
  ScriptCompletionResult? _funcCompletion(String text, int caret, int start) {
    final prefix = text.substring(start + 1, caret).toLowerCase();
    if (prefix.length < _minPrefixLength) {
      return null;
    }

    final matches =
        bdfdAutocompleteTemplates.entries
            .where((entry) => entry.key.startsWith(prefix))
            .toList(growable: false)
          ..sort((a, b) => a.key.compareTo(b.key));
    if (matches.length == 1 && matches.first.key == prefix) {
      return null;
    }

    return ScriptCompletionResult(
      replaceStart: start,
      entries: <ScriptCompletionEntry>[
        for (final match in matches.take(_maxItems))
          _functionEntry(match.key, match.value),
      ],
    );
  }

  /// Entrée de complétion d'une fonction : le nom pour libellé, le gabarit
  /// résolu (arguments obligatoires injectés) pour texte inséré.
  ScriptCompletionEntry _functionEntry(String key, String template) {
    final resolved = _templateWithDefaultArguments(key, template);
    final bracketIndex = resolved.indexOf('[');
    return ScriptCompletionEntry(
      label: key,
      insert: resolved,
      // Curseur juste après le `[` du gabarit, comme avant la migration.
      cursorOffset: bracketIndex >= 0 ? bracketIndex + 1 : resolved.length,
      kind: ScriptCompletionKind.symbol,
    );
  }

  /// Complétion d'emoji : le nom pour libellé, la mention Discord pour texte
  /// inséré. Le silence remplace toute proposition inutile (nom déjà complet).
  ScriptCompletionResult? _emojiCompletion(String text, int caret, int start) {
    if (appEmojis.isEmpty) {
      return null;
    }

    // Nom déjà saisi, entre `<:` / `<a:` et le curseur.
    final afterPrefix = text.substring(start, caret);
    final String namePrefix;
    if (afterPrefix.startsWith('<a:')) {
      namePrefix = afterPrefix.substring(3).toLowerCase();
    } else if (afterPrefix.startsWith('<:')) {
      namePrefix = afterPrefix.substring(2).toLowerCase();
    } else {
      return null;
    }

    final entries = <ScriptCompletionEntry>[];
    for (final emoji in appEmojis) {
      final matchesPrefix =
          namePrefix.isEmpty || emoji.name.toLowerCase().startsWith(namePrefix);
      if (!matchesPrefix) {
        continue;
      }
      entries.add(
        ScriptCompletionEntry(
          label: emoji.name,
          insert: emoji.mention,
          kind: ScriptCompletionKind.emoji,
        ),
      );
      if (entries.length >= _maxItems) {
        break;
      }
    }

    // Rien à proposer : liste vide, ou unique emoji dont le nom est déjà écrit.
    if (entries.isEmpty ||
        (namePrefix.isNotEmpty &&
            entries.length == 1 &&
            entries.first.label.toLowerCase() == namePrefix)) {
      return null;
    }

    // `replaceStart` pointe sur le `<` du déclencheur.
    return ScriptCompletionResult(replaceStart: start, entries: entries);
  }

  // ── Arguments par défaut du gabarit ─────────────────────────────────────

  /// Clé de signature de [template] : celle du nom de fonction quand elle
  /// existe, sinon celle du nom lu dans le gabarit `$nom[`.
  String _signatureLookupKeyForTemplate(String key, String template) {
    if (bdfdSignatureHints.containsKey(key)) {
      return key;
    }
    final match = RegExp(r'\$([A-Za-z0-9_]+)\[').firstMatch(template);
    final parsed = (match?.group(1) ?? '').toLowerCase();
    return bdfdSignatureHints.containsKey(parsed) ? parsed : key;
  }

  /// `Name (optional)` → `Name` ; `...` ne nomme rien.
  String _normalizeSignatureParameter(String raw) {
    final withoutMeta = raw.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    return withoutMeta == '...' ? '' : withoutMeta;
  }

  /// `true` quand l'argument est marqué optionnel entre parenthèses.
  bool _isOptionalSignatureParameter(String raw) {
    final lower = raw.toLowerCase();
    if (!lower.contains('(') || !lower.contains(')')) {
      return false;
    }
    return RegExp(r'\((?:[^)]*\bopt(?:ional)?\b[^)]*)\)').hasMatch(lower);
  }

  /// Gabarit dont le `[]` est rempli avec les arguments obligatoires de la
  /// signature, séparés par ` ; ` ; inchangé quand aucun ne s'applique.
  String _templateWithDefaultArguments(String key, String template) {
    if (!template.contains('[]')) {
      return template;
    }
    final parameters =
        bdfdSignatureHints[_signatureLookupKeyForTemplate(key, template)];
    if (parameters == null || parameters.isEmpty) {
      return template;
    }

    final defaults = parameters
        .where((parameter) => !_isOptionalSignatureParameter(parameter))
        .map(_normalizeSignatureParameter)
        .where((parameter) => parameter.isNotEmpty)
        .toList(growable: false);
    if (defaults.isEmpty) {
      return template;
    }

    return template.replaceFirst('[]', '[${defaults.join(' ; ')}]');
  }
}

/// Diagnostics BDFD. Par défaut : l'analyse lexicale et syntaxique du moteur,
/// qui ne dépend que de Dart pur (donc disponible sur le web) — parenthèses et
/// crochets non fermés, fonctions mal formées. L'app y substitue la validation
/// complète du moteur natif (arguments attendus de chaque fonction), qui ne se
/// compile pas pour le web.
abstract final class BdfdEditorHooks {
  static List<EditorDiagnostic> Function(String source, String backend)
  diagnostics = syntaxDiagnostics;

  static List<EditorDiagnostic> syntaxDiagnostics(
    String source,
    String backend,
  ) {
    if (source.trim().isEmpty) return const [];
    final lexer = BdfdLexer().tokenize(source);
    final parser = BdfdParser().parseTokens(lexer.tokens);
    return [
      for (final d in lexer.diagnostics)
        EditorDiagnostic(message: d.message, line: d.line, column: d.column),
      for (final d in parser.diagnostics)
        EditorDiagnostic(message: d.message, line: d.line, column: d.column),
    ];
  }
}

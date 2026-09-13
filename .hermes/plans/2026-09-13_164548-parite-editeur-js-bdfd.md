# Parité éditeur JavaScript ↔ BDFD — bot-creator (app Flutter)

> Cible : `/home/jeremy/Code/bc/bot-creator` (branche `dev`) · `packages/app`.
> Date : 2026-09-13 · Objectif utilisateur : « une vraie compat éditeur entre le JS et BDFD, car
> actuellement BDFD possède des features absentes de l'éditeur JavaScript ».

## 1. État actuel (vérifié, chiffré)

| Fonction | `bdfd_editor_page.dart` (1682 l.) | `js_editor_page.dart` (511 l.) |
|---|---|---|
| Coloration syntaxique | lexer BDFD (`BdfdLexer`) | `re_highlight` (highlight.js) |
| Numéros de ligne + sync du scroll | ✅ | ❌ |
| Guides d'indentation + ligne active | ✅ (`BdfdIndentGuidesPainter`) | ❌ |
| Auto-indent sur Entrée | ✅ (`_BdfdAutoIndentFormatter`) | ❌ |
| Autocomplete | ✅ `bdfdAutocompleteTemplates` + arguments par défaut | ⚠️ index statique (`discord_js_completions.json`), sans args |
| Autocomplete emojis `<:name:` / `<a:name:` | ✅ (via `AppEmoji.mention`) | ❌ |
| Signature hints (paramètre actif souligné) | ✅ `bdfdSignatureHints` | ❌ |
| Diagnostics temps réel + barre (erreur / warning / sain) | ✅ `BdfdCompiler` | ❌ |
| Toggles wrap / guides / diagnostics + menu « ⋮ » < 700 px | ✅ | ❌ |
| Barre de caractères rapides mobile | ✅ | ❌ |
| Réglages palette + docs | ✅ | ✅ |
| Barre de snippets | ❌ | ✅ (à conserver) |

**Verrou de non-régression existant** : `test/bdfd_editor_layout_theme_test.dart` (5 tests —
palette sombre/clair sur toute la page, zone de code pleine largeur **et** hauteur en desktop,
menu « ⋮ » sous 700 px, 360 dp sans débordement). Aucun test de l'éditeur JS.

**Call sites** : `command.create.javascript.dart:85`, `workflow_block_editor.dart:1801`,
`option_widget.dart:1058` (les 3 poussent `JsEditorPage`) ; `BdfdEditorPage` depuis
`command.create.bdfd.dart:136`, `command.create.block_editor.dart:868` et `action_card.dart:5317`.

## 2. Objectif d'architecture

Un **chrome d'éditeur unique** dans `packages/app/lib/core/code_editor/`, consommé par les deux
pages. La parité devient **structurelle** : toute feature du chrome existe pour les deux langages,
il n'y a plus deux implémentations à maintenir.

## 3. Contrat d'interface (figé, ne pas dévier)

### 3.1 `core/code_editor/script_editor_language.dart` — ✅ déjà écrit
Modèle (`ScriptCompletionEntry/Kind/Result`, `ScriptSignatureHint`, `ScriptDiagnostic`,
`ScriptDiagnosticSeverity`, `ScriptDiagnosticCode`) + `abstract class ScriptEditorLanguage` :

```dart
ScriptCompletionResult? completionAt(String text, int caretOffset);
ScriptSignatureHint? signatureAt(String text, int caretOffset);
List<ScriptDiagnostic> diagnosticsFor(String text);   // codes, AUCUN texte UI
List<String> get quickChars;
int indentIncreaseFor(String previousLine) => 0;      // JS: +tabSize après { ( [
String indentUnit() => '  ';
```
Helpers : `scriptLineColumnAt`, `scriptCaretOffsetAfterInsert`, `scriptClampedCaret`.

**Règle i18n** : la couche langage ne contient **aucune chaîne utilisateur** — les diagnostics
portent un `ScriptDiagnosticCode` que l'UI traduit.

### 3.2 `core/code_editor/script_editor_scaffold.dart` — API publique imposée

```dart
class ScriptEditorScaffold extends StatefulWidget {
  const ScriptEditorScaffold({
    super.key,
    required this.title,                 // déjà localisé par la page
    required this.initialCode,
    required this.language,              // ScriptEditorLanguage
    required this.hintText,              // déjà localisé
    required this.uxSheetTitle,          // déjà localisé
    required this.uxSheetBullets,        // déjà localisés
    required this.onOpenDocs,            // VoidCallback (section de doc propre au langage)
    this.snippets = const <ScriptEditorSnippet>[],   // barre de chips (JS), vide pour BDFD
    this.enableAutocomplete = true,
    this.prefersWordWrap = false,
  });
}
```
- Le scaffold **possède** le `Scaffold`, l'`AppBar` (titre, docs, palette, toggles, « Terminé »),
  le corps d'édition, la barre de diagnostics, la barre de caractères rapides et la feuille « UX ».
- « Terminé » ⇒ `Navigator.pop(context, controller.text)` (comportement actuel des 2 pages).
- Layout imposé (verrouillé par les tests BDFD) : fond de page `CodeEditorThemeColors.background` ;
  en desktop la zone de code occupe **toute** la largeur et la hauteur ; barre d'outils en icônes
  ≥ 700 px, menu « ⋮ » en dessous ; aucun débordement à 360 dp.
- Réutilise les clés existantes : `code_editor_settings_title`, `bdfd_editor_docs`,
  `bdfd_editor_wrap_toggle`, `bdfd_editor_diagnostics_toggle`, `bdfd_editor_toggle_indent`,
  `more_options_title`, `done`, `close`, et les clés `*_ux_title/includes/auto_indent/indent_guides/
  quick_keys/empty/diagnostics_clean` passées ou résolues par langue.

### 3.3 Autres modules du chrome (mêmes règles : ≤ 300 l./fichier, zéro TODO, zéro code mort)
- `script_editor_editor_body.dart` — corps : gouttière de numéros + sync, deux modes (wrap /
  défilement horizontal), overlays.
- `script_editor_indent_guides.dart` — `ScriptIndentGuidesPainter` (générique, `source` +
  `activeLine`) + `ScriptAutoIndentFormatter` (s'appuie sur `indentIncreaseFor`).
- `script_editor_overlays.dart` — panneau d'autocomplete + bulle de signature (positions calculées
  comme aujourd'hui : `lineHeight 20`, `charWidth 7.8`, padding haut 12 / gauche 8, clamp aux bords).
- `script_editor_diagnostics_bar.dart` — barre saine/erreur/warning, `maxHeight 140`,
  `String Function(ScriptDiagnostic)` fourni par la page pour la traduction.

### 3.4 Couche JavaScript (`core/js_editor/`)
- `js_diagnostics.dart` — `List<ScriptDiagnostic> analyzeJavaScript(String source)` : scanner
  honnête (pas un parseur complet) qui suit les chaînes `'`/`"`, les templates `` ` `` **avec
  imbrication `${}`**, les commentaires `//` et `/* */`, et vérifie l'équilibre `()[]{}` ⇒ codes
  `unterminated*`, `unexpectedClosing`, `unclosedOpening`. Aucun faux « c'est propre » : si le
  scanner ne peut pas conclure (par ex. regex littérale), il ne signale rien.
- `js_signature_hints.dart` — catalogue `Map<String, List<String>>` (globals `client/guild/channel/
  member/interaction/message/db/config/variables/webhook`, `interaction.*`, `db.*.*`) +
  `ScriptSignatureHint? jsSignatureHintAt(String text, int caretOffset)` (repère la parenthèse
  ouverte la plus proche et compte les virgules de premier niveau).
- `js_script_language.dart` — `class JsScriptLanguage implements ScriptEditorLanguage` :
  autocomplete = index statique (`JsCompletionIndex`, injecté) **+ emojis** (`<:` / `<a:` ⇒
  `AppEmoji.mention`) ; signature = `jsSignatureHintAt` ; diagnostics = `analyzeJavaScript` ;
  `quickChars` = `{ } ( ) [ ] ; " ' \` = . >` ; `indentIncreaseFor` ⇒ `indentUnit()` si la ligne se
  termine par `{`, `(` ou `[`.

### 3.5 Pages
- `features/bot_editor/presentation/screens/bdfd_editor_page.dart` — devient une coquille mince :
  `BdfdEditorPage(initialCode, title, appEmojis)` → `ScriptEditorScaffold(language: BdfdScriptLanguage(appEmojis: …))`.
  Le contrôleur (coloration lexer) et l'adaptateur (autocomplete + défauts d'args + signatures +
  diagnostics via `BdfdCompiler`) partent dans `bdfd_syntax_controller.dart` / `bdfd_script_language.dart`.
  **Le chemin d'import `…/screens/bdfd_editor_page.dart` et le constructeur doivent rester compatibles**
  (3 call sites + le test existant).
- `features/bot_editor/presentation/screens/js_editor_page.dart` — idem vers
  `ScriptEditorScaffold(language: JsScriptLanguage(…), snippets: jsEditorSnippets, prefersWordWrap: false)`.
  Nouveau paramètre `appEmojis` (`List<AppEmoji>`, défaut `const []`) ; l'index d'autocomplete continue
  de se charger en asynchrone (pas de blocage d'affichage).
- Plumbing emojis : `command.create.javascript.dart` (`_appEmojis`), `workflow_block_editor.dart`
  (`widget.appEmojis`). `option_widget.dart` reste sans emojis (défaut vide).

## 4. Nouvelles clés i18n (6 locales : en/fr/de/ja/pt/tr, parité stricte + blocs `@`)

| Clé | en |
|---|---|
| `js_editor_ux_title` | Editor UX |
| `js_editor_includes` | Includes: |
| `js_editor_auto_indent` | • Smart auto indentation on Enter |
| `js_editor_indent_guides` | • Live indentation guides |
| `js_editor_quick_keys` | • Mobile quick-keys for JavaScript symbols |
| `js_editor_empty` | Empty script — start typing to see diagnostics. |
| `js_editor_diagnostics_clean` | No syntax problem detected. |
| `js_diag_unterminated_string` | Unterminated string literal. |
| `js_diag_unterminated_template` | Unterminated template literal. |
| `js_diag_unterminated_comment` | Unterminated block comment. |
| `js_diag_unexpected_closing` | Unexpected closing “{0}”. |
| `js_diag_unclosed_opening` | Unclosed “{0}” opened on line {1}. |

## 5. Vagues d'exécution

- **Vague 1** (3 agents, périmètres disjoints)
  1. **Chrome générique** : `core/code_editor/script_editor_{scaffold,editor_body,indent_guides,
     overlays,diagnostics_bar}.dart` (nouveaux fichiers uniquement, aucune migration de page).
  2. **Couche JS** : `core/js_editor/js_{diagnostics,signature_hints,script_language}.dart` + tests unitaires.
  3. **i18n** : 12 clés × 6 ARB + `flutter gen-l10n` + contrôle de parité.
- **Vague 2** (2 agents, périmètres disjoints)
  4. **Page JS** : `js_editor_page.dart` sur le chrome + plumbing `appEmojis` aux 2 call sites + tests.
  5. **Migration BDFD** : `bdfd_editor_page.dart` + `bdfd_syntax_controller.dart` +
     `bdfd_script_language.dart` sur le chrome, **les 5 tests existants doivent rester verts**.
- **Vague 3** (moi) : review gate, `flutter analyze`, suite complète, garde-fous i18n, `git status`,
  commit atomique sélectif (les clés WIP `workflows_create_*` de l'utilisateur ne doivent **pas**
  entrer dans le commit), push.

## 6. Commandes de vérification

```bash
export PATH="/home/jeremy/development/flutter/bin:$PATH"
cd /home/jeremy/Code/bc/bot-creator/packages/app
flutter analyze
flutter test test/bdfd_editor_layout_theme_test.dart test/js_editor_parity_test.dart
flutter test            # suite complète, en fin de vague 2
cd /home/jeremy/Code/bc/bot-creator && git status --short
```

# JS Editor Complete Overhaul

## Problèmes

1. **Pas d'autocomplete** — `_JsScriptEditor` est un `TextField` basique
2. **Éditeur très incomplet** — pas de syntax highlighting, pas d'indent guides, pas de validation réelle
3. **Pas de page séparée** — reste inline dans le ScratchBlock, contrairement au BDFD
4. **`ctx.channelId` cassé** — le preamble JS définit `ctx = {}` une fois à l'init mais `_bc_ctx` n'existe pas encore

## Plan d'action

### Phase 1 — Fix du bug `ctx` (runner)
**Fichier:** `packages/runner/lib/js_engine/js_preamble.dart`
- Retirer l'assignation conditionnelle de `ctx` du preamble (elle est inutile et cassée)
- Dans `js_runtime_bridge.dart::execute()`, ajouter `ctx = _bc_ctx;` AVANT d'exécuter le user script
- Ça garantit que `ctx.channelId`, `ctx.authorId`, etc. fonctionnent

### Phase 2 — Créer un `JsEditorPage` (comme `BdfdEditorPage`)
**Nouveau fichier:** `packages/app/lib/features/bot_editor/presentation/screens/js_editor_page.dart`

Fonctionnalités calquées sur `BdfdEditorPage`:
- `JsSyntaxController` (extends `TextEditingController`, override `buildTextSpan` — keywords JS, strings, comments)
- `_JsAutoIndentFormatter` (comme `_BdfdAutoIndentFormatter`)
- `_JsIndentGuidesPainter` (identique à `_BdfdIndentGuidesPainter`)
- Autocomplete basé sur la liste des fonctions BDFD disponibles (import `allBdfdFunctions`)
- Ligne numbers, word wrap toggle
- Validation JavaScript réelle (via `_runtime.evaluate` si dispo, sinon fallback brace matching)

### Phase 3 — Autocomplete JS
- Lister toutes les fonctions BDFD (`allBdfdFunctions`) comme suggestions
- Ajouter `ctx.*` properties (channelId, authorId, guildId, memberId, messageId, etc.)
- Ajouter les fonctions globales: `sendMessage`, `reply`, `getMessage`, `addRole`, `banUser`, `getGlobalVariable`, `setGlobalVariable`, etc.
- Trigger: taper 2+ caractères après `$` ou juste taper du texte (identifiants JS)

### Phase 4 — Remplacer l'éditeur inline par une page séparée
**Fichier:** `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.block_editor.dart`
- Dans `_buildJsBlock()`, remplacer `_JsScriptEditor` inline par un `GestureDetector` avec preview + `Navigator.push` vers `JsEditorPage`
- Exactement le même pattern que `_buildBdfdBlock()` (lignes 409-507)

### Phase 5 — Nettoyer `command.create.js.dart`
- Supprimer l'ancien `_JsScriptEditor` widget (ou le garder comme fallback minimal si pas desktop)

## Fichiers impactés
| Fichier | Action |
|---|---|
| `packages/runner/lib/js_engine/js_preamble.dart` | Fix `ctx` init |
| `packages/runner/lib/js_engine/js_runtime_bridge.dart` | Inject `ctx = _bc_ctx` |
| `packages/app/lib/features/bot_editor/presentation/screens/js_editor_page.dart` | **NOUVEAU** |
| `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.block_editor.dart` | Remplacer JS inline par page |
| `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.js.dart` | Supprimer ou réduire |

## Ordre d'exécution
1. Phase 1 (bug critique — le code JS ne fonctionne pas)
2. Phase 2 + 3 (nouvelle page éditeur avec autocomplete)
3. Phase 4 (intégration dans le block editor)
4. Phase 5 (nettoyage)

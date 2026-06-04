# Attach Image — Documentation

Action qui attache une image au message de réponse Discord. Supporte les URLs HTTP(S), les data URLs (base64), et les chaînes base64 brutes.

---

## Utilisation

L'action `Attach Image` se trouve dans la catégorie **Messages** du palette de blocs. Elle prend 3 paramètres :

| Paramètre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| `imageName` | string | Oui | Nom du fichier pièce jointe (ex: `photo` → `photo.png`) |
| `imageSource` | url | Oui | URL HTTP(S), data URL, ou chaîne base64 brute |
| `altText` | string | Non | Texte alternatif pour l'image (ignoré à l'exécution) |

### Formats de source supportés

1. **URL HTTP/HTTPS** — `https://example.com/image.png`
2. **Data URL** — `data:image/png;base64,iVBORw0KGgo=...`
3. **Base64 brut** — `iVBORw0KGgo=...` (sans préfixe `data:`)

### Injection de variables

Tous les paramètres supportent l'injection dynamique via `((variableName))`. Exemple :

```
imageName: ((userAvatarName))
imageSource: ((member.avatar_url))
```

---

## Fonctionnement interne

### Chaîne d'exécution

1. `executeAttachImage()` — résout `imageSource` via `resolveImageSource()`, stocke en base64 dans `temp._canvasAttachment_<imageName>`
2. `respondWithMessage` / `sendMessage` — collecte les variables `temp._canvasAttachment_*` via `_collectCanvasAttachments()`
3. Les pièces jointes sont envoyées en fichiers Discord avec le nom `<imageName>.png`

### Fichiers clés

| Fichier | Rôle |
|---------|------|
| `packages/shared/lib/actions/executors/image_executor.dart` | Fonctions `executeAttachImage()` et `resolveImageSource()` |
| `packages/shared/lib/actions/respond_with_message.dart` | Collecte `_collectCanvasAttachments()` |
| `packages/shared/lib/actions/executors/variables_executor.dart` | Dispatch `BotCreatorActionType.attachImage` → `executeAttachImage()` |
| `packages/shared/lib/types/action.dart` | Enum `BotCreatorActionType.attachImage` |
| `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_type_extension.dart` | Définition des paramètres UI (ligne 3262) |

### Variable de sortie

- Résultat JSON: `"attached"` (en cas de succès)
- Variable stockée: `temp._canvasAttachment_<imageName>` (base64 PNG)

### Gestion des erreurs

- `imageName` vide → `Exception: attachImage: imageName is required`
- `imageSource` vide → `Exception: attachImage: imageSource is required`
- Source invalide → `Exception: attachImage: failed to load image from source`

---

## Tests

### Tests unitaires (shared)

**Fichier:** `packages/shared/test/attach_image_executor_test.dart` (13 tests)

- Validation du stockage dans `temp._canvasAttachment_<name>`
- Résolution data URL et base64 brut
- Gestion des erreurs (paramètres vides, source invalide)
- Résolution de placeholders template `((variable))`
- Tests de `resolveImageSource()` avec cache

### Tests d'intégration (shared)

**Fichier:** `packages/shared/test/attach_image_integration_test.dart` (5 tests)

- Flux complet `executeAttachImage` → collecte canvas attachments
- Multiples appels avec noms distincts
- Filtrage des variables vides / invalides
- Roundtrip vers le format attendu par respondWithMessage

### Tests de sérialisation (app)

**Fichier:** `packages/app/test/attach_image_action_test.dart` (12 tests)

- `ActionItem.toJson()` et `ActionItem.fromJson()` pour `attachImage`
- Round-trip JSON (encodage → décodage)
- `purgeActionPayloadStrict()` préservation des paramètres
- Désérialisation dans un workflow complet

### Tests UI (app)

**Fichier:** `packages/app/test/scratch_block_palette_test.dart` (+5 tests)

- Catégorisation dans le groupe `Messages`
- Vérification de l'icône `Icons.image_outlined`
- Définition des 3 paramètres avec leurs types
- Support de l'injection dynamique sur tous les champs

**Exécution des tests:**
```bash
# Shared (exécuteur + intégration) — 18 tests
cd packages/shared && dart test test/attach_image_executor_test.dart test/attach_image_integration_test.dart

# App (sérialisation + UI) — 18 tests
cd packages/app && flutter test test/attach_image_action_test.dart test/scratch_block_palette_test.dart
```

---

## Exemple BDFD

```bdfd
$nomention
$attachImage[thumbnail](https://cdn.example.com/thumb.png)
$description[Voici votre image !]
```

---

*Dernière mise à jour: 2026-06-04*

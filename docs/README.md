# Documentation — Bot Creator

Vue d'ensemble de la documentation technique interne du projet.

---

## Index

| Document | Contenu |
|----------|---------|
| [command-format.md](./command-format.md) | Format JSON complet d'une commande (stockage, normalisation, cycle de vie) |
| [runtime-variables.md](./runtime-variables.md) | Toutes les variables `((…))` disponibles à l'exécution |
| [template-syntax.md](./template-syntax.md) | Syntaxe du moteur de templates (fallback, JSONPath, URLs) |
| [bdfd-supported-functions.md](./bdfd-supported-functions.md) | Etat de support des fonctions BDFD dans Bot Creator |
| [runner-docker.md](./runner-docker.md) | Exécution du Runner Docker en mode API only (sync/start/stop bots) |
| [attach-image.md](./attach-image.md) | Action "Attach Image" — attacher une image à la réponse Discord |
| [native-documentation.md](./native-documentation.md) | API publique, lecteur natif des guides/fonctions et cache hors ligne |

---

## Architecture rapide

```
packages/
├── app/           Application Flutter (éditeur de commandes)
│   ├── lib/routes/app/command.create.dart   Éditeur de commandes (UI + sauvegarde)
│   ├── lib/utils/bot.dart                   createCommand() / updateCommand()
│   └── lib/utils/database.dart              normalizeCommandData() + persistance JSON
│
├── shared/        Code partagé App + Runner
│   ├── lib/utils/global.dart                generateKeyValues() → variables runtime
│   ├── lib/utils/template_resolver.dart     resolveTemplatePlaceholders()
│   ├── lib/actions/interaction_response.dart Résolution + envoi de la réponse Discord
│   └── lib/types/action.dart               BotCreatorActionType + classe Action
│
└── runner/        Runner autonome (exécution des commandes)
    └── lib/discord_runner.dart              Point d'entrée exécution commandes
```

---

## Principe clé : où lire `editorMode` ?

```
Fichier sur disque : { name, id, data: { editorMode, response, actions, … } }
                                  ^^^^
normalizeCommandData lit : command['data']['editorMode']   ← toujours dans 'data'
```

`editorMode` est dans `command['data']`, **jamais** à la racine du command record.

---

## Embedded JS runner (desktop dev)

Sur Linux, Windows et macOS, l'app peut lancer un runner JavaScript embarqué. En développement, le binaire n'est pas toujours présent dans les assets Flutter — configurez-le de l'une des façons suivantes.

### Option A — Télécharger la release GitHub

```bash
cd bot-creator
RUNNER_JS_RELEASE_TAG=runner-js-v0.4.0 ./scripts/fetch-embedded-runner-js.sh
```

Le script place le binaire dans `packages/app/assets/embedded-runner-js/`. Relancez ensuite `flutter run`.

### Option B — Build local (monorepo)

Si `runner-js` est un checkout sibling (ex. `bc/runner-js` à côté de `bc/bot-creator`) :

```bash
cd ../runner-js
npm ci && npm run build && npm run pkg:linux-x64   # ou pkg:win / pkg:macos-arm64
```

`flutter run` résout automatiquement le binaire via `runner-js/build/bot-creator-runner-js-*`.

### Option C — Chemin explicite

```bash
export BOT_CREATOR_EMBEDDED_RUNNER_JS_PATH=/chemin/vers/bot-creator-runner-js-linux-x64
flutter run
```

Le fichier doit faire au moins 1 MiB (binaire PKG valide).

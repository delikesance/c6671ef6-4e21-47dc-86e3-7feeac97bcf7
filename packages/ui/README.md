# bot_creator_ui

Design system et composants visuels **partagés entre l'app Bot Creator et le Studio web**. Un seul code pour
que les deux interfaces se ressemblent et se comportent pareil.

## Ce que contient le paquet

| Dossier | Contenu |
|---|---|
| `lib/src/theme` | `AppTheme`, apparences (`AppAppearanceConfig`), échelle de texte, `BlockFamily`, `UiFonts` |
| `lib/src/widgets` | `AppIcon` (Reicon), `PageContent`, `ResponsiveHelper` |
| `lib/src/l10n` | les traductions (ARB) de l'app **et** du Studio, `context.tr` |
| `lib/src/editor/catalog` | `ActionItem`, paramètres et libellés des types d'actions |
| `lib/src/editor/blocks` | blocs, canevas de blocs, palette d'actions, point d'entrée |
| `lib/src/editor/blueprint` | canvas Blueprint, mini-carte, inspecteur, mise en page |
| `lib/src/editor/forms` | `ActionCard` (formulaires d'actions), champs avec variables, embeds, permissions |
| `lib/src/editor/components_v2` | éditeurs Components V2 et modales |
| `lib/src/editor/pages` | `ActionSequenceEditor` (palette + blocs/Blueprint), `ActionsBuilderPage` |
| `lib/src/editor/lists` | widgets de listes et de pages d'éditeur (modules, groupes de réglages, barre de page) |
| `lib/src/editor/widgets` | `EditorSidebar` / `EditorRail` (navigation d'un bot) |
| `lib/src/code` | thème et réglages des éditeurs de code, coloration BDFD / JavaScript |
| `lib/src/docs` | documentation intégrée : hub, articles Markdown natifs, dépôt de contenu |
| `lib/src/editor/host` | `EditorHost` : ce que le paquet demande à l'application |

## Ajouter ou modifier un composant

1. Le composant ne doit pas connaître l'application : pas de `dart:io`, pas de base locale, pas de client réseau.
   Il doit compiler pour le web (`flutter build web --wasm` dans `packages/studio` le vérifie).
2. Ce dont il a besoin (workflows, variables, éditeurs plein écran) passe par l'[`EditorHost`] :
   `EditorHostScope.of(context)` dans un `build`, `EditorHostScope.read(context)` dans `initState` ou un callback.
3. Les textes passent par `context.tr` ; les ARB sont ici, dans `lib/src/l10n/`, puis `flutter gen-l10n` (dans ce
   dossier). Les outils de l'app (`packages/app/tools`) et le Studio (`tool/l10n_sync.dart`) lisent ces fichiers.
4. Les icônes passent par `AppIcon.fromMaterial(Icons.xxx)`, avec l'icône déclarée dans `reicon_material_map.dart`
   (le test `app_icon_test.dart` de l'app contrôle l'app, le Studio et ce paquet).

## Branchements propres à l'hôte

Quelques composants délèguent à l'hôte par un point d'accroche statique, posé au démarrage : `AvatarImageSource`
(cache d'images), `ExternalLinkOpener` (ouvrir un lien), `DocumentationWebViewHost` (page web de la doc),
`UiDiagnostics` (traces). L'app les règle dans `main()` ; le Studio garde les valeurs par défaut.

## Les deux hôtes

- **App** : `AppEditorHost` (`packages/app/lib/features/bot_editor/presentation/app_editor_host.dart`), monté dans
  `MaterialApp.builder`. Données locales ou runtime distant, éditeurs BDFD et image.
- **Studio** : `StudioEditorHost` (`packages/studio/lib/src/editor/studio_editor_host.dart`), tout via l'API du
  Manager. Pas encore d'éditeur BDFD ni d'image.

L'app garde, à ses anciens chemins, des fichiers qui réexportent le paquet : ses imports n'ont pas changé.

## Tests

`flutter analyze` ici, puis les tests de l'app (`packages/app/test` : blocs, Blueprint, éditeur de commandes) et du
Studio, qui couvrent ces composants.

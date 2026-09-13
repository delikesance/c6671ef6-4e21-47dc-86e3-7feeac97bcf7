# Marges desktop uniformisées + simplification de la page Réglages — bot-creator (app Flutter)

> Cible : `/home/jeremy/Code/bc/bot-creator` · `packages/app` · branche `dev`.
> Demandes utilisateur : « Uniformise moi les margin sur desktop DE TOUTE LES PAGES », « dégage moi
> le back button dans la Page sachant qu'il est déjà en haut », « retire le switch Light/Dark car on
> l'a plus bas », « retire l'icône settings (on a compris que c'était les settings) ».

## 1. Constat (mesuré, page par page)

Aucune convention partagée : **chaque page code sa propre respiration**.
`ResponsiveHelper.getContentMaxWidth` (500/600/800) et `getHorizontalPaddingValue` existent mais ne
sont utilisés que par `create_page.dart`.

| Surface | Largeur actuelle | Marges actuelles |
|---|---|---|
| `bot_sub_pages/home.ui.part.dart` (Accueil bot) | `maxContentWidth = 1200` | `fromLTRB(24, 16, 24, 32)` |
| `bot_sub_pages/commands.list.dart` | `>= 900 ? 760 : 640` | liste `fromLTRB(12, …)` |
| `bot_sub_pages/settings.dart` (Réglages bot) | `>= 900 ? 760 : 640` | onglets internes |
| `bot_sub_pages/export_import.page.dart` | `>= 900 ? 760 : 640` | — |
| `bot_sub_pages/command_dashboard.dart` | `1000` | — |
| `bot_sub_pages/bot_stats.dart` | `1200` | — |
| `bot_sub_pages/builder.response.dart` | `maxContentWidth: 980` (passé à l'éditeur d'actions) | — |
| `home/presentation/home_page.dart` (liste des bots) | `isWide ? 1000 : 640` + `sidePad 28/16` | calculé |
| `settings/presentation/settings_page.dart` (Réglages app) | **600** | `isMobile ? 16 : 24` |
| `bot_management/presentation/create_page.dart` | `ResponsiveHelper` → 800 | `24/32` |
| `command.create.dart` (éditeur de commande) | `>= 1200 ? 980 : (>= 900 ? 860 : 680)` | — |
| `emojis`, `scheduler`, `workflows`, `global.variables`, `guilds`, `bot_logs`, `inbound_webhooks`, `debug_replay` | **full-bleed** (100 % de la largeur) | `12` ou `16` |
| `documentation/documentation_hub_page.dart` | full-bleed | — |

Conséquence visible : sur une même fenêtre, une page a 12 px de marge et la suivante 660 px.

## 2. Contrat figé — `packages/app/lib/core/widgets/page_layout.dart` (✅ déjà écrit)

```dart
abstract final class AppPageLayout {
  static const double maxContentWidth = 1200;         // aligné sur l'Accueil bot (page la plus récente validée)
  static const double compactMaxContentWidth = 640;
  static const double horizontalPadding = AppTheme.spacingXxl;          // 24
  static const double compactHorizontalPadding = AppTheme.spacingLg;    // 16
  static bool isWide(double availableWidth);           // seuil = AppTheme.desktopBreakpoint (720)
  static double contentMaxWidthFor(double availableWidth);
  static double horizontalPaddingFor(double availableWidth);
  static EdgeInsets paddingFor(double availableWidth);
}

/// Enveloppe standard : centre + largeur max + marges communes.
/// Se base sur la largeur RÉELLEMENT disponible (LayoutBuilder), pas celle de
/// la fenêtre (le shell de l'éditeur retire déjà la barre latérale).
/// Le défilement reste à la charge de l'enfant.
class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.child, this.maxWidth, this.padding, this.alignment});
}

/// Vrai sur desktop : la barre de titre du shell porte DÉJÀ la flèche de retour.
bool windowChromeOwnsBackButton();
```

**Règle unique de marge** : toute page enveloppe son contenu dans `PageContent`, et
**supprime** ses bornes locales (`contentMaxWidth`, `sidePad`, `maxWidth: 600/760/1000/1200`,
paddings horizontaux 12/16/28). Aucune page ne doit plus contenir de `maxWidth:` de mise en page
horizontal (les `maxWidth` de composants internes — badges, boutons, largeurs de champ — restent).

**Règle unique de retour** : `windowChromeOwnsBackButton()` ⇒ la page ne rend **aucun** bouton de
retour (`automaticallyImplyLeading: false`, `leading: null`). Le motif de référence est déjà en place
dans `command.create.dart:2117` (`automaticallyImplyLeading: !ResponsiveHelper.isDesktopPlatform()`).

## 3. Simplifications de la page Réglages app (`settings/presentation/settings_page.dart`, classe `SettingPage`)

1. **Retirer la flèche de retour de l'AppBar** (l.2138) : `automaticallyImplyLeading: !widget.embedded`
   ⇒ `!widget.embedded && !windowChromeOwnsBackButton()`. La barre de titre desktop est au-dessus.
2. **Retirer le switch Light/Dark de l'AppBar** (l.2140-2146, `Icons.light_mode` / `Icons.dark_mode`
   + `themeProvider.toggleTheme()`) : redondant avec le sélecteur **Mode** (Dark / Light / System) de
   `AppearanceSettingsSection`. L'`actions:` de l'AppBar devient vide ⇒ le retirer entièrement.
   ⚠️ Ne toucher ni à `ThemeProvider` ni au sélecteur de mode (c'est désormais la seule commande).
3. **Retirer l'icône héro `Icons.settings`** (l.2167-2175) et son `SizedBox(height: 24)` : le titre
   « Backup and Restore » et son sous-titre restent, remontés en tête de page.
   ⚠️ `iconSize` devient inutilisé ⇒ le supprimer aussi (zéro code mort).
4. **Marges** : remplacer `Center` + `SingleChildScrollView(padding: horizontalPadding/24)` +
   `ConstrainedBox(maxWidth: 600)` par `PageContent` (largeur commune 1200, marges 24/16).
   Le `SafeArea(bottom: !widget.embedded)` (double comptage de l'inset avec la barre flottante) ne
   doit **pas** être cassé : il est verrouillé par `test/settings_embedded_bottom_inset_test.dart`.

## 4. Autres pages concernées par la règle de retour

| Fichier | Ligne | Situation |
|---|---|---|
| `features/documentation/documentation_hub_page.dart` | 77 | `automaticallyImplyLeading: !widget.embedded` (embarquée dans le shell ⇒ pas de retour) |
| `bot_sub_pages/editor_sub_page_ui.dart` | 46-55 | `editorSubPageLeading` : cas `standalone` ⇒ `BackButton` alors que la barre de titre desktop le fournit |
| `bot_sub_pages/command.create.dart` | 2117 | ✅ déjà conforme (motif de référence) |

## 5. Vagues d'exécution (périmètres disjoints, aucune ARB touchée)

- **Vague M1 — pages applicatives** : `settings/presentation/settings_page.dart` (§3, priorité),
  `documentation/documentation_hub_page.dart`, `home/presentation/home_page.dart`,
  `bot_management/presentation/create_page.dart` (+ suppression des méthodes `ResponsiveHelper`
  devenues orphelines si plus personne ne les utilise).
- **Vague M2 — sous-pages de l'éditeur (cœur)** : `bot_sub_pages/home.ui.part.dart`,
  `commands.list.dart`, `settings.dart`, `export_import.page.dart`, `command_dashboard.dart`,
  `bot_stats.dart`, `builder.response.dart`, `app_editor_page.dart`.
- **Vague M3 — sous-pages de l'éditeur (suite)** : `workflows.page.dart`, `emojis.page.dart`,
  `scheduler.page.dart`, `global.variables.dart`, `guilds.page.dart`, `bot_logs.dart`,
  `inbound_webhooks.page.dart`, `debug_replay_page.dart`, `editor_sub_page_ui.dart` (§4).

**Hors périmètre assumé** (éditeurs plein-cadre, largeur volontairement propre) :
`js_editor_page.dart`, `bdfd_editor_page.dart`, `command.create.dart` (canvas de blocs),
`image_editor_page.dart`. Ces surfaces sont des éditeurs, pas des pages de contenu — elles gardent
leur largeur. À signaler dans le rapport final si l'utilisateur veut aussi les aligner.

## 6. Vérifications

```bash
export PATH="/home/jeremy/development/flutter/bin:$PATH"
cd /home/jeremy/Code/bc/bot-creator/packages/app
flutter analyze
flutter test test/settings_embedded_bottom_inset_test.dart test/main_shell_test.dart \
             test/bot_home_layout_test.dart test/floating_nav_inline_test.dart
flutter test   # suite complète en fin de vague M3
```

Test de non-régression à ajouter : `test/page_layout_test.dart` — (a) `AppPageLayout` : seuil, largeur
et marges pour une zone large / compacte ; (b) `PageContent` : en 1600 px le contenu fait 1200 px
centré avec 24 px de marge, en 500 px il occupe la largeur avec 16 px ; (c) `windowChromeOwnsBackButton`
et (d) un widget test de la page Réglages : plus aucun bouton de retour en desktop, plus d'icône
`Icons.settings` héro, plus d'`IconButton` de bascule de thème dans l'AppBar, et le contenu suit la
largeur commune.

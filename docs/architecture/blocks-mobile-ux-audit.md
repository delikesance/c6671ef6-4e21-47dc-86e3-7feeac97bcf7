# Audit UX mobile des blocs (éditeur Scratch, cartes d'action, composants V2)

Statut : audit en lecture seule, aucun code modifié, aucun test exécuté (les constats viennent de la lecture du code ; les tailles sont des estimations à 360 dp à confirmer par les tests de la section 4).
Périmètre : `packages/app/lib/features/bot_editor/presentation/` (widgets/scratch_blocks, screens/bot_sub_pages/builder, workflow_block_editor, command.create.*), `features/components_v2/presentation/component_v2_builder/`, `core/widgets/variable_text_field.dart`.

## 1. Comment l'éditeur s'adapte (ou non) aux écrans étroits

### Ce qui existe déjà
- Layout 2 modes : desktop (>= 800 dp, 1000 en test) = palette latérale fixe 320/340 px + canvas ; sinon canvas seul avec bouton « Ajouter un bloc » (`workflow_block_editor.dart:553-558`, `:585`, `:884`; `command.create.block_editor.dart:12-33`, `:683`).
- Palette mobile = bottom sheet à 85 % de hauteur avec recherche, puces d'actions rapides et liste par catégories (`scratch_block_palette.dart:560-690`, `:780-800`). Le drag est désactivé sur mobile (`_resolveEnableDrag`, `scratch_block_palette.dart:685-693`) : on ajoute par tap. C'est le bon modèle.
- Réordonnancement mobile : `ReorderableListView` avec poignée `drag_indicator` (`scratch_block_canvas.dart:397-408`, `command.create.block_editor.dart:190-205`, `:432`) + « Monter/Descendre » dans le menu `more_vert` (`action_block.dart:513-600`).
- Bloc imbriqué (if / else-if / boucles / listenAndExecute) : pas d'indentation, mais une tuile-résumé (3 puces d'aperçu + bouton) qui ouvre une page plein écran `ActionsBuilderPage` avec fil d'Ariane (`action_card.dart:1814-2090`, `workflow_block_editor.dart:2428-2443`). Aucun problème d'indentation profonde ; en revanche on perd le contexte à chaque niveau.
- Embeds, composants (V1/V2), modal, requête HTTP : ouverts dans une page plein écran (`action_card.dart:3924-3960`, `:4180`, `:4229`, `http_request_editor_page.dart`).
- Adaptations ponctuelles par `LayoutBuilder` : SegmentedButton sans libellé < 420/460 px (`metadata_block.dart:329-345`, `entry_point_block.dart:381-400`), else-if en colonne < 760 (`action_card.dart:1700-1790`), `_buildResponsiveTwoFieldRow` < 520 (`component_node_editor.dart:339-360`), menu d'en-tête compact < 420 (`action_card.dart:126`, `:169-250`).
- Clavier : `MobileKeyboardAccessoryBar` (chips de syntaxe + feuille de variables 60 %) en `bottomNavigationBar` quand `viewInsets.bottom > 0` (`command.create.dart:2516-2523`, `mobile_keyboard_accessory_bar.dart:73-140`).
- Résumé collapsible par bloc (`scratch_block.dart:219-224`, état `_collapsed` dans `action_block.dart:504`).

### Ce qui n'est pas adapté
| Sujet | Constat | Réf. |
|---|---|---|
| Cibles tactiles | Boutons d'en-tête 28x28 (`_HeaderIconButton`), menu `more_vert` avec `constraints: BoxConstraints()` donc ~20 px, bouton « + » d'insertion entre blocs 20x20, boutons monter/descendre/supprimer des composants V2 28x28 (icônes 14-16 px). Minimum Material/Apple : 44-48 px. | `scratch_block.dart:244-247`; `action_block.dart:513-520`; `scratch_block_connector.dart:61-62`; `component_node_editor.dart:191-225` |
| Suppression | La croix du bloc est collée au menu et au chevron, sans confirmation ni annulation (la `ActionCard` avait un dialogue de confirmation, masqué car `showManagementControls: false`). Aucun undo dans l'éditeur de blocs (le mot « undo » n'existe que dans bdfd_editor_page et image_editor_page). | `scratch_block.dart:201-206`; `action_block.dart:668`; `action_card.dart:289` |
| En-tête de bloc | Largeur fixe cumulée à 360 dp : liseré 12 + poignée ~32 + icône 28 + menu 20 + croix 28 + chevron 20 + paddings 24, soit ~165 px, plus 32 px de marge canvas. Il reste ~150 px pour titre + badge de catégorie (non flexible). Titres longs tronqués, badge peut pousser le titre à quelques lettres. | `scratch_block.dart:137-216`; `scratch_block_canvas.dart:300` |
| Formulaires longs | Toutes les `parameterDefinitions` sont rendues à plat dans une `Column` dans la carte, sans groupes « avancé » (seul `ExpansionTile` pour clé/état/erreur et HTTP « stocker les résultats »). `ParameterDefinition` n'a pas de champ `advanced`/`group` ; `visibleWhen` existe. Les actions les plus lourdes ont 9 à 14 paramètres (createAutoModRule, sendMessage, queryArray, appendArrayElement, updateGuild, sendWebhook, editMessage). | `action_card.dart:259-283`; `action_types.dart:35-59`; `action_type_extension.dart:627`, `:2877` |
| Ligne « Activé / Sur erreur » | `SwitchListTile` et `DropdownButtonFormField` en `Expanded` côte à côte : ~150 px chacun à 360 dp, libellé « Sur erreur » et options tronqués. | `action_card.dart:360-408` |
| Éditeurs de liste/map/headers | `AlertDialog` à hauteur fixe 55-70 % de l'écran. À 360 dp, le contenu utile fait ~230 px (inset dialogue 40 + padding 24). Ligne clé (flex 4) / valeur (flex 6) / corbeille donne ~80 / ~110 / 48 px. Avec le clavier ouvert, la hauteur fixe de 70 % déborde ou laisse une zone de saisie minuscule. Pas de sélecteur de variable dans ces champs (`TextField` brut). Le champ en-tête utilise `Autocomplete` dont l'overlay se superpose au clavier. | `action_card.dart:2678-2693`, `:3032-3135`, `:3181-3260` |
| Éditeur JSON de map | Dialogue 70 %, saisie JSON brute sur mobile (guillemets, accolades au clavier mobile). | `action_card.dart:2781-2920` |
| Sélecteur de variable | Dialogue (`SizedBox(width: 420)`, borné par le dialogue, pas de crash) contenant un `VariableTextField` avec liste de suggestions inline : sur petit écran + clavier la liste est quasi invisible. Le bouton `data_object` est un `IconButton` compact (~32-40 px) placé à côté du libellé. L'insertion se fait toujours en fin de texte (`_mergeVariableExpression` ignore le curseur). | `action_card.dart:931-960`, `:979-996`, `:970-977`; `variable_text_field.dart:206-260` |
| Clavier | `MobileKeyboardAccessoryBar` n'est branchée que dans `command.create.dart`, pas dans `workflow_block_editor.dart`, ni dans l'éditeur d'embed, de composants, de modal ni dans les dialogues (qui n'ont pas de `viewInsets` explicites). Pas de `scrollPadding`, ni `keyboardDismissBehavior`. | `command.create.dart:2516`; grep `viewInsets` : seulement workflows.page.dart, image_editor_page.dart |
| Débordement horizontal | Les aperçus de puces (nested/embeds/composants) sont des `SingleChildScrollView` horizontaux imbriqués dans un `InkWell` qui ouvre l'éditeur (geste de défilement vs tap ambigu, contenu masqué hors écran). Les dialogues d'args de workflow imposent `width: 480/520` (borné par le dialogue mais sans scroll vertical sur le JSON). Titre du composant V2 non `Flexible` (`Text` + `Spacer`). | `action_card.dart:1930-2020`, `:3770-3860`, `:4060-4140`; `component_node_editor.dart:149-165`, `:2166`, `:2251` |
| Indentation composants V2 | `depth * 8` + liseré 3 + padding carte 8 par niveau (ActionRow > Section > Container...) : ~19 px perdus par niveau, 4 niveaux = ~75 px sur 360. Pas de repli par niveau. | `component_node_editor.dart:119-148` |
| Options de select (V2) | Chaque option = carte avec 2 lignes de 2 champs + emoji + suppression : très haute, répétée jusqu'à 25 fois. | `component_node_editor.dart:860-935` |
| Drag depuis la palette | Désactivé sur mobile : OK. Mais « insérer ici » passe par le « + » 20 px, ou par le bouton global qui ajoute en fin de liste. | `scratch_block_palette.dart:685`; `command.create.block_editor.dart:1112` |
| Sélection du type de commande | Segmented 4 entrées sans libellé < 460 px : icônes seules, découvrabilité faible (tooltip uniquement au long press). | `entry_point_block.dart:381-420` |
| Test | `Platform.environment` lu dans le build du canvas (désactive le scrollbar/controller) : comportement différent entre test et prod. | `scratch_block_canvas.dart:387-395`; `workflow_block_editor.dart:555` |

## 2. Les 15 blocs/écrans les plus pénibles (360-400 px), classés

Critères : fréquence d'usage x gravité x effort de saisie. Largeur de référence 360 dp.

| # | Bloc / écran | Problème concret | Correctif proposé |
|---|---|---|---|
| 1 | En-tête de `ScratchBlock` (tous les blocs) | Cibles 20-28 px serrées (menu, croix, chevron) ; suppression sans confirmation ni undo ; titre tronqué. | En-tête = titre + résumé sur 2 lignes + une seule action « ⋮ » 48 px ; suppression via menu/swipe avec SnackBar « Annuler » (undo) ; poignée de drag 48 px ou mode « réorganiser ». |
| 2 | Formulaire `sendMessage` / `editMessage` / `sendWebhook` (9-11 paramètres + embeds + composants) | Colonne de 9-11 champs, scroll vertical interminable dans le canvas, perte de repère. | Bloc réduit à un résumé (« Envoyer dans #canal : texte… ») ; tap ouvre un bottom sheet plein écran avec sections « Essentiel » / « Embeds » / « Composants » / « Avancé » repliées. Champs essentiels = ceux marqués `required`. |
| 3 | Éditeur de map / headers / paires clé-valeur (`action_card.dart:3032`, `:3181`) | Dialogue à hauteur fixe, 3 colonnes ~80/110/48 px, clavier, pas de variable, `Autocomplete` sous clavier. | Page/bottom sheet `DraggableScrollableSheet` avec cartes verticales (clé au-dessus de la valeur), bouton `((` variable, ajout en bas collant (FAB), `resizeToAvoidBottomInset`. |
| 4 | Sélecteur de variable / placeholder (`((`) | Dialogue + clavier = liste invisible ; insertion en fin de texte ; non branché hors command.create. | Bottom sheet unique et réutilisable avec recherche, groupes, favoris récents ; insertion à la position du curseur ; barre d'accessoire clavier partout (workflow, embeds, composants, dialogues). |
| 5 | Embeds (`ResponseEmbedsEditor`, 945 lignes) | Mini-blocs imbriqués (champs, auteur, footer, images) dans un `SingleChildScrollView` plein écran ; chaque mini-bloc a ses boutons ~28 px ; aperçu limité. | Liste de sections repliées avec résumé (« Titre · 3 champs ») ; une section = un écran/sheet ; stepper « Embed 1/10 » ; aperçu Discord optionnel en bas. |
| 6 | Composants V2 : `ComponentNodeEditor` (2526 lignes) | Imbrication ActionRow > Section > Button/Select, indentation cumulée, boutons 28 px, champs en 2 colonnes en dessous de 520 px donc re-empilés (page très longue). | Navigation « drill-down » (tap sur un nœud = écran enfant avec fil d'Ariane), pas d'indentation ; boutons d'en-tête 48 px ; réorganisation via `ReorderableListView` plutôt que flèches. |
| 7 | Options de select (`StringSelect`, jusqu'à 25) | 4 champs + 2 boutons par option, carte de ~230 px de haut x N. | Liste compacte (label + valeur sur 1 ligne) ; tap = sheet d'édition d'une option (label, valeur, description, emoji) ; import en masse « une option par ligne ». |
| 8 | `createAutoModRule` (14 paramètres) / `updateGuild` / `queryArray` / `appendArrayElement` | Formulaires les plus longs, dépendances `visibleWhen` qui font sauter la mise en page. | Sections avancées repliées, groupes `visibleWhen` en sous-cartes animées ; ajout d'un champ `group`/`advanced` dans `ParameterDefinition`. |
| 9 | Dropdowns / listes de paramètres (`DropdownButtonFormField` salons, rôles, permissions) | Menu déroulant natif court, pas de recherche ; `PermissionFlagsField` est une longue liste de lignes. | Sélecteur « tap ouvre une feuille avec recherche » (`SearchableSelectSheet`) ; permissions en `FilterChip`/liste groupée par catégorie avec résumé « 4 permissions ». |
| 10 | Tuile d'imbrication (if / else-if / boucle / listenAndExecute) | Ouvre une nouvelle page complète à chaque niveau ; l'aperçu horizontal masque des puces ; perte du contexte parent ; else-if multiples = beaucoup de champs répétés. | Garder le drill-down mais ajouter un fil d'Ariane cliquable persistant et une barre de bas « Retour à X » ; résumé vertical (max 3 lignes + « +N ») au lieu de scroll horizontal ; else-if en accordéon avec résumé de condition. |
| 11 | Ligne « Activé / Sur erreur » + clé d'action (`action_card.dart:360`) | Champs côte à côte trop étroits ; paramètre technique visible pour chaque bloc. | Déplacer dans la feuille « Réglages du bloc » (icône engrenage) ; badge d'état dans l'en-tête (désactivé / sur erreur : ignorer). |
| 12 | Connecteur « + » entre blocs (`scratch_block_connector.dart`) | Cible 20x20, difficile à toucher entre deux blocs ; insertion à une position précise est la seule vraie opération « mobile ». | Zone tactile 48 px (hit test élargi, trait visuel inchangé) ou bouton « + » en bas de chaque bloc ; appui long sur un bloc = « Insérer en dessous ». |
| 13 | Palette mobile (`scratch_block_palette.dart`) | Bonne base (recherche, puces), mais liste de ~380 types répartie par catégories dépliées, `ListTile` dense 13 px, sheet 85 % sans poignée de recherche collante. | Search-first : champ au focus par défaut, « Récents » et « Favoris » en haut, catégories repliées par défaut, tuiles 56 px avec une phrase d'aide. |
| 14 | Bloc d'entrée (`WorkflowEntryPointBlock`, 955 lignes) et métadonnées (`MetadataBlock`, 724 lignes) | Beaucoup de champs (type de commande, options de commande, arguments, déclencheur d'événement) en tête de page ; segmented sans libellé ; le tout reste ouvert avant les actions. | Replier par défaut avec résumé (« /ping · 2 options ») ; édition dans un sheet ; segmented remplacé par une liste/menu avec libellés en dessous de 420 px. |
| 15 | Éditeurs de liste (`_showListEditor`), JSON (`bodyJson`, args de workflow `width: 480/520`), BDFD (`maxLines: 6`) | Saisie de texte structuré au clavier mobile ; dialogues en hauteur fixe ; JSON difficile à corriger. | Liste = sheet avec lignes réordonnables ; JSON = éditeur plein écran avec barre `{ } [ ] " :` (réutiliser `MobileKeyboardAccessoryBar`) et validation en ligne ; éviter la hauteur fixe (`minHeight` + scroll). |

## 3. Composants partagés et plan par phases

### Composants à créer (dans `core/widgets/` ou `bot_editor/presentation/widgets/mobile/`)
1. `ResponsiveEditorSheet` : bottom sheet `DraggableScrollableSheet` sur < 600 dp, dialogue sur grand écran ; gère `viewInsets`, bouton Annuler/OK collant, titre, option « plein écran ». Remplace les `AlertDialog` de hauteur fixe.
2. `BlockSummaryTile` : tuile résumé uniforme (icône, titre, 1-2 lignes de résumé, badges d'état, chevron) utilisée par blocs, embeds, composants, imbriqués, options.
3. `ParameterSectionGroup` + champ `group`/`advanced` dans `ParameterDefinition` (`action_types.dart:35`) : sections « Essentiel / Avancé », repliées par défaut ; rendu dans `action_card.dart:259`.
4. `KeyValueListEditor` : éditeur unique pour map, headers, options (carte verticale, variable, ajout collant, réorder).
5. `VariablePickerSheet` + `VariableInsertButton` : sheet avec recherche, insertion au curseur, récents ; barre d'accessoire clavier intégrée à `VariableTextField`.
6. `SearchableSelectSheet` : remplace les dropdowns longs (salons, rôles, workflows, variables, options).
7. `TouchIconButton` : `IconButton` avec cible >= 48 px (visuel 20-24 px) ; remplace `_HeaderIconButton` et les `SizedBox(28)`.
8. `UndoStack` (ou snapshot léger) dans le contrôleur d'état de l'éditeur (command.create et workflow) + SnackBar « Annuler » pour suppression/déplacement/collage.

### Phasage et effort (1 dev, jours de travail)
| Phase | Contenu | Effort |
|---|---|---|
| 0 | Tests de base à 360x800 et 400x860 sur les écrans actuels (voir §4) pour figer l'existant et détecter les overflow | 1-1,5 j |
| 1 (gains rapides) | `TouchIconButton` partout, connecteur « + » 48 px, en-tête de bloc simplifié, confirmation/undo de suppression, accessoire clavier dans workflow_block_editor | 3-4 j |
| 2 | `ResponsiveEditorSheet` + `KeyValueListEditor` (map/headers/liste), `VariablePickerSheet` avec insertion au curseur | 4-6 j |
| 3 | Sections `group/advanced` dans `ParameterDefinition` + renseigner les ~15 actions les plus lourdes ; `BlockSummaryTile` ; résumé pliable par défaut ; ligne « Activé / Sur erreur » déplacée dans un sheet | 5-7 j |
| 4 | Embeds et composants V2 en drill-down + options de select compactes + réorganisation par liste | 6-9 j |
| 5 | Palette search-first (récents/favoris), `SearchableSelectSheet`, entry-point/metadata repliés avec résumé, `PermissionFlagsField` en chips | 4-5 j |
| Total | | ~23-33 j |

Dépendances : phase 3 avant 4 ; 2 avant 3 (réutilise les sheets). Les phases 1 et 2 peuvent être livrées sans toucher au modèle de données.

## 4. Comment vérifier

Patterns existants à réutiliser (`packages/app/test`) :
- `workflow_block_editor_desktop_test.dart` : monte `WorkflowBlockEditor` avec `tester.view.physicalSize` + `devicePixelRatio = 1.0` + `addTearDown(tester.view.reset)`, thème `AppTheme.darkTheme()`, localisation `fr`, `SharedPreferences.setMockInitialValues({})`. Dupliquer en `workflow_block_editor_mobile_layout_test.dart` avec `Size(360, 800)` puis `Size(400, 860)`.
- `mobile_editor_ux_test.dart` : déjà là pour connecteur, canvas réordonnable, palette et accessoire clavier ; y ajouter les assertions de taille.
- Suites voisines : `command_create_page_editor_test.dart`, `command_create_page_desktop_layout_test.dart`, `actions_builder_page_test.dart`, `send_component_v2_test.dart`, `scratch_block_palette_test.dart`.

Tests à écrire :
1. Smoke « sans overflow » : pour chaque taille (320, 360, 400, scale texte 1.0 et 1.5 via `MediaQuery(textScaler: TextScaler.linear(1.5))`), monter `WorkflowBlockEditor`, `CommandCreatePage`, `ActionsBuilderPage` avec une action de chaque type lourd (sendMessage, createAutoModRule, queryArray, httpRequest, embeds, composants) et vérifier `expect(tester.takeException(), isNull)`.
2. Cibles tactiles : pour chaque `IconButton`/`InkWell` d'en-tête, `tester.getSize(find...)` >= 44x44 (ou utiliser `meetsGuideline(androidTapTargetGuideline)` + `labeledTapTargetGuideline` via `tester.ensureSemantics()`). Ce test échouera aujourd'hui (28 px / 20 px) : c'est l'objectif.
3. Dialogues/sheets avec clavier : `tester.view.viewInsets = FakeViewPadding(bottom: 300)` ; vérifier que le champ focalisé reste visible (`tester.getRect(find.byType(TextField)).bottom <= hauteur - 300`) pour map/headers/liste/variable.
4. Interaction : tap-pour-insérer depuis la palette (déjà testé), suppression + « Annuler » restaure le bloc, déplacement par menu, ouverture/fermeture du drill-down avec fil d'Ariane.
5. Goldens (si l'équipe accepte des goldens ; vérifier la présence de `matchesGoldenFile` dans le dépôt avant de les introduire, et figer la police `Roboto`/`loadAppFonts`) : en-tête de bloc, tuile imbriquée, ligne clé/valeur, carte d'option de select à 360 px, thème clair/sombre. Sinon se limiter aux assertions de géométrie ci-dessus, plus stables.
6. Nettoyer `Platform.environment.containsKey('FLUTTER_TEST')` dans le code de production (`scratch_block_canvas.dart:387`, `workflow_block_editor.dart:555`) en injectant un paramètre/`ScrollController` pour que les tests exercent le même chemin que la prod.
7. Vérification manuelle : un appareil 360x640 (Android) et un petit iPhone SE, avec police agrandie à 130 % et mode paysage, sur les 15 blocs de la liste du §2.

## 5. Questions pour le propriétaire (modèle d'interaction)

1. Cible principale : édition complète sur téléphone, ou mobile = retouches rapides (texte, activer/désactiver, réordonner) et desktop = construction ?
2. Modèle d'édition d'un bloc : bloc replié avec résumé + feuille d'édition (recommandé), ou formulaire en ligne comme aujourd'hui ?
3. Réorganisation : poignée de drag, flèches monter/descendre, ou mode « réorganiser » dédié ? Faut-il aussi déplacer entre niveaux imbriqués ?
4. Insertion : préférez-vous « + » entre blocs, « + » en bas de chaque bloc, ou barre flottante unique ?
5. Imbrication : garder la navigation page par page (fil d'Ariane) ou afficher les corps imbriqués en ligne, avec indentation limitée à 2 niveaux ?
6. Paramètres avancés : qui décide ce qui est « avancé » ? (champ explicite dans `ParameterDefinition`, ou liste restreinte des champs `required` visibles ?)
7. Suppression : confirmation, undo (SnackBar), ou les deux ? Faut-il un undo/redo complet (historique de session) ?
8. Variables : l'insertion `((` au clavier suffit-elle, ou voulez-vous toujours un sélecteur visuel (sheet) avec recherche, favoris, aperçu de valeur ?
9. Souhaitez-vous que le plus petit écran supporté soit 320 dp, et quelle échelle de texte maximale (1,3 ? 2,0) ?
10. Accepte-t-on des goldens dans la CI (maintenance des images) ou seulement des tests de géométrie ?
11. Les composants V2 / embeds : un aperçu type Discord est-il utile sur mobile, ou trop coûteux en place ?
12. Priorité : réduire l'effort de saisie (variables, sélecteurs) ou la lisibilité d'ensemble (résumés, sections) en premier ?

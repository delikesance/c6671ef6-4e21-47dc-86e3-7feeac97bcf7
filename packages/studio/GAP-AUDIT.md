# Studio : ce qui manque face à l'app (audit du 2026-10-05)

## Mise à jour — ce qui est maintenant fait

- **Commandes** : création (dialogue nom / description / déclencheur), enregistrement par la route granulaire v2.
- **Éditeur de blocs** (commandes et workflows) : palette d'ajout avec recherche, paramètres modifiables
  (champs ou JSON, structures imbriquées conservées), ordre, activation, suppression.
- **Workflows** : liste, création (général / événement), édition des blocs visuels, suppression. Le Manager expose
  désormais `GET /api/v2/bots/{id}/workflows[/{name}]` (lecture qui manquait).
- **Copilote IA** : discussions par bot, historique, solde de crédits, outils lus automatiquement, écritures soumises
  à approbation. Outils exécutés par le Studio : commandes et workflows visuels, variables, démarrage / arrêt du
  bot hébergé, documentation officielle (si le navigateur l'autorise). La réponse s'affiche une fois générée
  (pas de défilement mot à mot dans le navigateur).
- **Variables à portée** : création, modification et suppression des définitions.

- **Options (arguments)** de commande (texte, nombre, utilisateur, salon, rôle…) et **historique avec retour arrière**.

## Mise à jour 2 — le Studio réutilise le design et les composants de l'app (`packages/ui`)

Le Studio n'a plus de palette ni d'éditeur « équivalent » : il importe `bot_creator_ui`, le paquet que l'app utilise aussi.

- **Design** : `AppTheme` (thème, apparences), `AppIcon` / Reicon, `BlockFamily`, `PageContent`, polices Inter et
  JetBrains Mono, et le jeu de traductions de l'app (une seule série d'ARB).
- **Éditeur de blocs** : `ActionSequenceEditor`, assemblé comme l'éditeur de commandes de l'app : palette d'actions par
  catégorie (recherche, glisser-déposer), blocs `ActionBlock` avec les formulaires d'action de l'app (`ActionCard`,
  ≈60 types), point d'entrée `EntryPointBlock` / `WorkflowEntryPointBlock`, suggestions de variables du moteur.
- **Blueprint** : le canvas de l'app (zoom, mini-carte, câblage des broches, menu contextuel), avec la bascule
  Blocs / Blueprint.
- **Components V2 et modales** : les éditeurs de l'app (via `ActionCard`).
- **Navigation et accueil** : `EditorRail`, `FlatNavRail` / `FlatNavBar`, `StatusPill`, boutons et avatars de la home.
- **Liste des commandes et variables à portée** : la carte de commande de l'app (compteurs, dossier, alias) et la liste
  groupée par portée des variables.
- **Documentation** : le hub et les articles natifs de l'app (onglet Docs). Les pages sont lues sur bot-creator.fr :
  le site doit autoriser l'origine du Studio (CORS), sinon la page propose de l'ouvrir dans le navigateur.

- **Métadonnées et options de commande** : le bloc Métadonnées de l'app (nom, description, dossier, paramètres avancés,
  éditeur d'options complet).

- **Éditeur JavaScript** : l'éditeur de script de l'app (coloration, autocomplétion discord.js, signatures, diagnostics,
  réglages de la palette) pour les commandes en JavaScript et l'autocomplétion des options.

- **Éditeur BDFD** : l'éditeur de l'app (coloration, autocomplétion, signatures). Les diagnostics du compilateur BDFD
  viennent de l'hôte (`BdfdEditorHooks`) : le moteur ne se compile pas pour le web, donc le Studio n'en affiche pas
  pour l'instant.

- **Planificateur** : l'écran de l'app (déclencheurs, activation, limite du forfait), via les routes
  `scheduled-triggers` du Manager.

- **Webhooks entrants** : l'écran de l'app, via les routes `inbound-webhooks` du Manager. Le secret y est en écriture
  seule : jamais relu ; laissé vide il est conservé, ou généré par le serveur à la création et montré une seule fois
  (donc pas de « copier le secret » ni d'URL complète dans le Studio).

- **Accueil et variables globales** : la carte de bot de l'app (`HomeBotCard`, sans la ligne des serveurs que le Studio
  ne connaît pas) et les lignes de variables globales.

Reste à faire : éditeur d'image,
versions de configuration du bot, planificateur, webhooks entrants, émojis, serveurs, marketplace, conteneurs,
documentation intégrée. Le détail ci-dessous est l'audit initial.


Périmètre : `packages/studio/lib/src` (≈46 fichiers) comparé à `packages/app/lib/features/*` et aux routes du Manager.
Limites : lecture de la coque, du modèle de brouillon et des fichiers de routes ; les écrans du Studio et le canvas
Blueprint / la page Copilot de l'app n'ont pas été lus en entier.

## État du Studio

- Rail d'accueil : Accueil (liste des bots), Docs (placeholder), Réglages.
- Rail d'un bot : seuls `commands`, `overview`, `dash`, `vars`, `team` sont réels. `copilot`, `flows`, `emojis`,
  `guilds`, `docs` tombent sur `ComingSoon` ; `sched` et `hooks` sont des stubs premium.

## 1. IA / Copilot : absent

- Rien côté Studio hormis des libellés et l'entrée de rail (`studio_shell.dart:161`). Aucun appel `/gateway/ai/*`.
- App : `features/copilot` (≈6 100 lignes) : conversations en flux, approbation des appels d'outils, aperçu et
  application de commandes, bac à sable, bibliothèque communautaire, configuration MCP, crédits (portefeuille,
  registre, roulette, récompenses).
- Manager : toutes les routes existent déjà (`routes_gateway.go`) avec la même authentification Bearer : portefeuille,
  catalogue d'outils, registre, conversations (créer, lire, modifier, supprimer, `turns`, `summarize`, `continue`,
  flux d'événements `requests/{key}/events`, `actions/{call_id}`), bibliothèque, contributions.
- Les achats, la roulette et les pubs restent côté mobile (règle du Studio : aucun achat).

## 2. Blueprint (workflows et variables) : très partiel

Modèle de l'app : un Blueprint est une vue graphe de la liste `actions[]` d'une commande ; il n'a pas de modèle propre
(positions des nœuds = état d'interface). Un workflow est une liste d'actions nommée et réutilisable (général ou
événement, avec arguments). Variables : globales, à portée (guilde / membre / utilisateur), temporaires, tableaux.

Studio : éditeur de commande en liste (cartes d'actions, champs scalaires modifiables, charges imbriquées en lecture
seule), variables globales complètes, variables à portée en lecture seule.

Manque :
- Créer une commande, ajouter une action depuis une palette (aucun contrôle trouvé).
- Éditeurs typés par action (≈60 types), validation, suggestions de variables, imbriqués (embeds, conditions).
- Onglet Workflows : aucun appel `workflows/sync` ni lecture ; workflows d'événement et arguments.
- Canvas Blueprint (≈1 000 lignes + peintre, mise en page, mini-carte dans l'app).
- Éditeurs BDFD et JavaScript, bac à sable ; Components V2 et modales.
- Valeurs de variables à portée, variables temporaires et tableaux, création et suppression des définitions.
- Versions de configuration, historique de commande et retour arrière, export / import, rejeu de débogage.

Routes déjà là : `commands/sync`, `workflows/sync` et `delete` (pas de GET : lecture via `GET /gateway/bots/{id}/config`),
`versions*`, historique de commande v2, variables à portée (`set`, `remove`, valeurs).

## 3. Autres écarts

| Fonction de l'app | Studio |
|---|---|
| Éditeur de commandes | partiel |
| Workflows, Blueprint, BDFD, JS, Components V2 | absent |
| Variables globales | présent ; à portée : partiel |
| Journaux, statistiques | présent / partiel |
| Planificateur, webhooks entrants | stub premium (routes de gestion non repérées) |
| Émojis, serveurs (guilds), Docs | stub |
| Versions de config, export / import, rejeu | absent |
| Musique (Lavalink), historique pubs | absent |
| Conteneurs (bots hébergés), marketplace | absent (routes existantes) |
| Bots (liste, création, démarrage, arrêt), équipe, connexion Discord | présent |
| Abonnements | lecture seule du plan, par choix |

## 4. Priorités proposées

1. **Workflows + palette d'ajout d'actions + création de commande** (M) : sans cela, le Studio ne sait que retoucher.
2. **Éditeurs d'actions typés et validation**, pilotés par un schéma de données (L).
3. **Variables à portée complètes** (S).
4. **Versions de config, historique, rollback, rechargement** (S/M).
5. **Copilot minimal** (L) : phase 1 portefeuille + liste de conversations (S/M) ; phase 2 chat en flux + approbation des
   outils (L). Pas besoin de porter la page de 2 900 lignes ni le MCP : l'état des conversations est côté serveur.
6. **Canvas Blueprint** (L), après 1 et 2 : seconde vue de `actions[]`, positions côté client.
7. **BDFD / JS / bac à sable** (L) ; en attendant, vue code en lecture seule (S).
8. **Marketplace, import / export, conteneurs, docs, émojis, guilds** (M chacun).
9. **Planificateur et webhooks entrants** (M) : confirmer d'abord le stockage dans la config du bot.
10. **Components V2 / modales** (L), avec le point 2.

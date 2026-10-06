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
- **Apparence** : la carte « Apparence » des réglages (`AppearanceSettingsSection`, `TextScaleSettingsSection`, galerie
  de thèmes, couleurs personnalisées, taille du texte) est celle de l'app, pilotée par le même `ThemeProvider` ; le
  Studio reste sombre (ses jetons de couleur le sont), donc sans choix clair / sombre. Les réglages du site sont
  volontairement réduits : compte, langue, apparence.
- **Historique d'une commande** : la modale de l'app (`CommandHistorySheet` : 5 versions, aperçu, restauration confirmée,
  conflit 409 traité comme tel, suppression) remplace la boîte de dialogue maison ; le Studio fournit seulement
  `StudioCommandHistoryHost` (routes v2 du Manager). Même chose pour la carte « Éditeur de code » des réglages
  (`CodeEditorSettingsCard`).
- **Versions de la configuration d'un bot** : l'écran « Historique des versions » de l'app (`BotConfigVersionsPage` :
  liste, aperçu, suppression, restauration confirmée avec les commandes concernées, restauration forcée proposée quand
  le serveur répond `409 bot_config_version_too_small`) est partagé. Le Studio fournit `StudioBotConfigVersionsHost`
  (`/gateway/bots/{id}/versions`, `…/content`, `…/restore`, DELETE avec `?key=` ; `checkpointBotConfig` est dans
  `StudioApi` mais l'écran de l'app n'a pas de bouton « checkpoint », donc le Studio non plus). Pas de copie locale :
  `applyRestoredLocally` ne fait rien, le serveur est la source de vérité. Entrée : bouton « Historique des versions »
  sur l'accueil du bot (comme la tuile « Outils » de l'accueil de l'app). Pas de formule requise, comme dans l'app.
- **Équipe et tchat** : l'onglet « Équipe » du Studio est l'écran de l'app (`TeamChatPage` : tchat d'équipe persisté,
  messages en cours d'envoi avec réessai automatique puis bouton « Réessayer », collaborateurs et droits, ajout par
  identifiant Discord avec les cinq droits, retrait confirmé, pseudonymes). Le Studio fournit `StudioTeamChatHost`
  (`GET/POST /gateway/bots/{id}/team/collaborators`, `DELETE …/{user_id}`, `GET/POST …/team/chat`). Les droits viennent
  de `my_permissions` : sans `can_invite` aucun contrôle de gestion, sans `can_view_chat` (refus explicite) le fil n'est
  pas affiché et le champ de saisie disparaît. Temps réel : le WebSocket du Manager (`EventSocket`, jeton dans le
  sous-protocole) pousse `team.chat.message` / `team.members.updated` ; tant qu'il n'est pas établi (ou hors navigateur)
  l'écran relit la conversation toutes les 12 s, et après une coupure il rattrape les messages manqués. Carte « équipe du
  portail développeur Discord » (lecture seule) et pseudonymes/avatars Discord des auteurs inconnus : ces deux lectures
  exigent le jeton du bot, que le Studio n'a jamais ; elles passent donc par le Manager, qui lit Discord avec le jeton
  chiffré qu'il garde (`GET /gateway/bots/{id}/team/portal` et `GET …/team/users/{user_id}`, scope `read:bots`, même
  garde d'accès au bot que les relais runner — un bot étranger répond 404 — plus le droit `can_view_chat`) et ne rend que
  les champs publics (identifiants, noms, hash d'avatar), jamais le jeton ; l'identifiant d'utilisateur doit être un
  flocon Discord (sinon 400, rien n'est envoyé à Discord). Mêmes règles que l'app : portail sans identifiant exploitable
  = pas de carte, panne du portail = aucune mise en garde, utilisateur non résolu = l'identifiant reste affiché.
  L'ancienne page maison et ses clés de traduction `team*` sont
  supprimées. Le Manager ne renvoie ni `display_name` ni `is_owner` dans la liste des collaborateurs (seulement `role`) :
  l'app a le même comportement, non corrigé ici.
- **Rejeu du débogueur** : nouvel onglet « Replay Débogueur » d'un bot (rail large, page « Modules » du téléphone, groupe
  Outils ; masqué en mode débutant). C'est `DebugReplayPage` de l'app (liste des exécutions, capture on/off, effacement
  confirmé, détail avec chronologie, lecture pas à pas, comparaison des variables avant/après, trace BDFD natif), montée
  sur `StudioDebugReplayHost`, qui relaie vers le runner du bot par le Manager : `GET /gateway/bots/{id}/debug-replays
  ?limit=30` (`{capturing, replays}`), `POST …/debug-replays/capture` (`{enabled}` → `{capturing}`), `POST …/clear`.
  Fonction **premium** : `StudioFeature.debugReplay` (le Manager applique aussi la règle, `RequirePremiumEntitlement`).
  Sur un compte gratuit l'écran affiche la même carte d'offre que l'app (`debug_replay_premium_*`) avec, à la place du
  bouton d'achat, la mention « l'abonnement s'active depuis l'app » ; aucune requête n'est faite, la capture et le détail
  sont fermés. Le Studio n'a aucune mémoire locale de rejeux : si le bot n'est pas lancé (le Manager répond 409/503),
  l'écran le dit (`debug_replay_unavailable`) et continue d'interroger, à cadence adaptative (`PollCadence`, maintenant
  dans `bot_creator_ui`), jusqu'à ce que le bot réponde. Les modèles (`DebugReplayRecord`, `DebugActionFrame`) sont dans
  le paquet ; l'app les ré-exporte depuis `bot.dart`. Les textes qui étaient en dur dans l'écran (« action(s) », « il y a
  … », statuts BDFD en français/anglais seulement) sont maintenant des clés `debug_replay_*` en 6 langues.
- **Applications hébergées (« bots clé en main »)** : nouvelle entrée « Bots Clé en main » de l'accueil (rail large et
  barre du bas du téléphone, libellé `container_list_title` de l'app). Ce sont les écrans de l'app, déplacés dans
  `bot_creator_ui` (`lib/src/containers`) derrière `HostedContainersHost` : liste (`ContainerListPage`), détail avec
  console de logs, arrêt / démarrage / suppression confirmés, invitation du bot et ajout de temps
  (`ContainerDetailPage`), déploiement (`ContainerDeployPage` : modèles, token Discord validé, variables du schéma du
  modèle, blocages quota / minutes / formule / hébergement coupé) et identifiants de registre privé
  (`RegistryCredentialsPage`, atteignable depuis la liste dans le Studio ; l'app ne l'expose pas). Les modèles
  (`ContainerInfo`, `HostedAppEligibility`, `RegistryCredential`…), le schéma d'environnement et le parcours
  d'invitation (`TurnkeyBotInviteService`) sont dans le paquet ; l'app les ré-exporte et garde ses anciennes signatures
  (`ContainerDetailPage(client:)`, `HomeContainerLogsPage(client:)`…). Le Studio fournit `StudioHostedContainersHost`
  (`GET /containers`, `/containers/eligibility`, `/containers/{id}/status|logs`, `POST …/start|stop|discord-identity`,
  `DELETE /containers/{id}`, `PATCH …/ttl`, `POST /containers/deploy`, `POST /gateway/turnkey/validate-token`,
  `GET /gateway/turnkey/templates?locale=`, `/registry-credentials` CRUD).
  - **Portées du jeton** : aucune modification du Manager. La connexion Discord est la même pour l'app et le Studio
    (`/auth/discord/exchange`) et `discordUserSelfServiceScopes` porte déjà `containers:read|write|deploy` ; un test Go
    (`TestDiscordUserSelfServiceScopesCoverHostedContainers`) fige ce contrat.
  - **Publicités** : `claim-ad` suit une publicité AdMob, uniquement mobile. L'hôte annonce `canWatchAds` faux : ni bouton
    « Pub +N min » ni appel, exactement comme sur le poste de travail de l'app ; le temps d'hébergement vient du solde
    serveur (`hosting_minutes_balance`, minutes déjà gagnées sur mobile) et la carte le montre. L'appel `claim-ad` n'est
    donc pas implémenté dans `StudioApi`.
  - **Achat et formules** : pas de boutique dans le navigateur, mais les FORMULES sont consultables : l'hôte annonce
    `upsellMode` = `plans` (comme le poste de travail de l'app) et les cartes d'offre, le bouton « Voir les offres » du
    déploiement bloqué et le blocage par la formule ouvrent le hub des abonnements (voir plus bas) ; l'achat natif
    (`purchase`) reste absent. Atteindre la limite gratuite affiche le message `container_list_free_limit_reached`.
    `premium_cloud_enabled: false` (lu une fois dans `GET /gateway/runtime`) donne l'explication « hébergement cloud
    coupé » comme dans l'app.
  - **Console** : comme dans l'app, la console de la page de détail lit `GET /containers/{id}/logs?tail=200` à cadence
    adaptative (`PollCadence`) ; l'app n'utilise pas le WebSocket `…/console` (shell interactif). Le Studio ne le
    pourrait d'ailleurs pas aujourd'hui : l'authentification par sous-protocole `bc.bearer` n'est acceptée que pour les
    chemins statiques de `webSocketBearerPaths` (le chemin porte un `{id}`) et `consoleUpgrader` ne répond pas le
    sous-protocole. Statut en temps réel : `container.updated` du canal `/gateway/bots/events` (`EventSocket`), le
    sondage de 30 s restant le filet de sécurité.
  - **Stockage** : les identifiants de registre ne vivent que côté serveur (liste + CRUD, mot de passe jamais relu ni
    affiché) ; rien dans `localStorage`. Pas de bot local dans le Studio : le sélecteur « utiliser un de mes bots » est
    omis (le token se colle, il n'est envoyé qu'au Manager). L'assistant IA sur un conteneur (`container:<id>`) n'est
    pas proposé (l'hôte n'annonce pas `canOpenCopilot`).
  - **Non partagé** : `HostedAppSubscriptionPage` (achat natif de la formule d'hébergement, boutique de l'app) et le
    catalogue de formules ; la carte d'accueil `HomeTurnkeyContainerCard` est dans le paquet mais l'accueil du Studio
    liste les conteneurs dans leur propre entrée.
- **Abonnements, facturation et crédits IA (lecture seule)** : le hub (`SubscriptionsHubPage`), l'écran des offres
  (`SubscriptionPage`), la carte « Abonnements et facturation » des réglages (`SubscriptionsSettingsCard`), les crédits
  IA (`AICreditsPage` : solde, répartition, historique paginé par 50) et la boîte de refus de formule
  (`PlanLimitDialog`) sont les écrans de l'app, déplacés dans `bot_creator_ui` (`lib/src/subscriptions`) derrière
  `SubscriptionsHost` / `AiCreditsHost`. L'app garde ses anciennes signatures (`SubscriptionsHubPage.open(context)`,
  `SubscriptionPage.show(context)`, `AICreditsPage(api:)`, `showPlanLimitDialog`) et ses gardes « disponible sur mobile
  seulement » ; ses services statiques de facturation sont lus par `AppSubscriptionsHost` / `AppAiCreditsHost`. Les
  modèles du catalogue commercial (`CommerceCatalog`), `PlanLimitBlock` et la liste des avantages Premium
  (`premiumFeatureDefinitions`) sont dans le paquet.
  - **Décision achat web : AUCUN paiement dans le navigateur, preuve côté Manager.** Les routes de facturation de
    `internal/api/routes_billing.go` sont les webhooks des boutiques (`/billing/webhook/{kofi,admob,playstore,apple}`) et
    la vérification de reçus (`POST /billing/verify`, `/billing/consumable/verify`, scope `billing:verify`) : elles
    valident un achat DÉJÀ fait dans App Store / Google Play, aucune ne crée de session de paiement ni de portail. Les
    seules intégrations de paiement par carte (`CmsCreateCheckout`, `CmsCreatePublishCheckout`) servent le CMS des
    créateurs (produits et publication de modèles), pas les formules du compte. `/gateway/plans` ne liste que les
    formules ayant un produit de boutique mappé. Aucune route n'a été ajoutée au Manager ; **écart signalé** : un
    paiement web des formules (Stripe Checkout + portail client + webhook) devrait être conçu côté Manager d'abord.
    `canPurchase`, la restauration et la gestion de l'abonnement sont donc faux : l'écran masque « S'abonner », « Gérer »,
    « Restaurer » et les prix, et dit, avec la phrase de l'app pour les plateformes sans boutique
    (`subscription_not_available_on_platform`), que les abonnements sont disponibles sur mobile.
  - **Ce que le Studio lit** (`StudioSubscriptionsHost`, jeton Discord, mêmes portées que le reste) : formule, nom,
    plafond de bots et échéance (`GET /gateway/runtime`), couverture d'hébergement (`GET /containers/eligibility` :
    `premium`, `allow_turnkey`, `max_containers`, `hosting_expires_at` / `hosting_permanent`, même règle que l'app pour
    allumer la carte), offres publiées (`GET /gateway/commerce/catalog`, ignoré tant qu'il n'est pas publié) ; crédits :
    `GET /gateway/ai/wallet` et `GET /gateway/ai/ledger?offset=`. Un Manager injoignable laisse l'état précédent : le
    Studio n'affirme jamais « gratuit » sur une lecture qui a échoué. Un abonnement de boutique n'y est pas dit « géré par
    le serveur » (seul un octroi l'est) ; faute de reçu local, la cadence mensuelle / annuelle n'est pas connue.
  - **Placement** : carte « Abonnements et facturation » dans les réglages (comme l'app) → hub → « Voir les offres » ;
    bouton « Voir les offres » sous les verrous Premium (`PremiumLockedCard`, tableau de bord, rejeu du débogueur) ;
    cartes d'offre des applications hébergées ; bouton « crédits » du Copilote → crédits IA ; refus de démarrage
    (`bot_quota_reached`, `own_bots_not_allowed`, `turnkey_*`) → `PlanLimitDialog` de l'app avec « Voir les offres »,
    jamais « continuer financé par pub » (pas de publicité dans le navigateur). Le refus « plus de temps gratuit »
    garde son texte Studio. Correction au passage : le message d'erreur du dialogue de création de bot imprimait la
    fonction `title` au lieu du texte.
  - **Non partagé et pourquoi** : `HostedAppSubscriptionPage` (feuille d'achat natif de la formule d'hébergement : que des
    prix de boutique et des boutons d'achat, rien à lire — le hub n'y mène que si `canPurchase`) ; roulette, publicités
    récompensées et packs de crédits (boutique / AdMob : `rewardsPlatform` nul, `loadPacks` vide) ; le lien « ouvrir la
    conversation » d'une ligne de l'historique (le Copilote du Studio n'ouvre pas une discussion par son identifiant) ;
    l'entrée « Crédits IA » du hub n'apparaît, comme dans l'app, que si une offre `rewarded_ai` est publiée (le Studio y
    accède aussi par le Copilote).
- **Bac à sable de commande et laboratoire de fonctions — PARTAGÉS, exécutés sur le runner** (`CommandSandboxPage`,
  `SandboxFunctionsPage`, dans `bot_creator_ui` avec un `SandboxHost`). Le moteur de simulation
  (`testCommandInSandbox`, BDFD natif et actions) reste du Dart natif (nyxx, `dart:io`, isolats) : il ne compile pas
  pour le web. L'app l'exécute donc toujours **sur l'appareil** (`AppSandboxHost`), et le Studio l'exécute **sur le
  runner du bot** (`StudioSandboxHost`) par le Manager, sur le modèle du rejeu du débogueur :
  - Manager : `POST /gateway/bots/{id}/sandbox/command` (scope `write:bots`, corps = la demande que prend
    `testCommandInSandbox` : `script` OU `actions`, `bdfdBackend`, `options`, `variables`, `definitions` + fixtures ;
    réponse = le résultat du moteur tel quel) et `GET /gateway/bots/{id}/sandbox/functions` (scope `read:bots`,
    `{count, cases[]}` : un cas = `function`, `label`, `script`, `scenario`, `options`, `expected`, `expectedValues`).
    **Pas premium** (l'app l'offre à tous). Contrairement aux relais voisins, l'appelant doit avoir un droit sur le bot
    (propriétaire ou équipe) : sinon 404 `bot_not_found`, le runner d'un autre compte n'est jamais atteint.
  - Runner : mêmes routes sous `/bots/:id/sandbox/*` (jeton Bearer du runner). Corps ≤ 256 Kio (compté sur les octets
    reçus), délai 5 s (isolat tué), 2 simulations en parallèle au plus. Refus : 400 `invalid_request`, 413
    `payload_too_large`, 429 `sandbox_busy` (+ `Retry-After`), 504 `sandbox_timeout`, 500 `sandbox_failed`. Un échec du
    moteur lui-même (script invalide, fixture manquante) reste un 200 `{success:false, error}`, comme sur l'appareil.
  - Sécurité : aucune connexion Discord (passerelle de fixtures), aucune donnée du bot (rien n'est lu du magasin du
    runner), HTTP simulé par un client factice qui ne répond qu'aux fixtures de la demande, et l'isolat tourne sous un
    `HttpOverrides` qui refuse de créer un vrai `HttpClient` : pas d'accès réseau ni aux adresses internes. Testé côté
    runner par un serveur local de contrôle qui ne doit recevoir aucune requête.
  - Placement : bouton « Tester dans le sandbox » sous l'en-tête de l'éditeur de commande (blocs et script BDFD ; pas
    pour les commandes JavaScript), puis le laboratoire de fonctions par l'icône de la barre de l'écran, comme dans
    l'app. Bot arrêté / sans runner (404 `runner_*`, 409, 502, 503) : phrase localisée `sandbox_unavailable`.
  - Écarts connus avec l'app : le bac à sable n'a pas de simulation hors ligne (il faut que le bot tourne) ; le
    catalogue de fonctions pèse ≈ 700 Kio (807 cas), chargé à l'ouverture du laboratoire ; les libellés de ces deux
    écrans sont en français/anglais seulement (comme dans l'app : seuls les messages d'erreur et le bouton sont en 6
    langues).
- **Traductions** : les écrans du Studio n'ont plus de texte français codé en dur. Ils réutilisent les clés de l'app
  (`context.tr`, 6 langues) quand le sens est identique, sinon des clés Studio (`context.l10n`, 6 langues) ; les
  validations, erreurs de connexion et refus de démarrage sont des types (`ValidationProblem`, `AuthIssue`,
  `StartRefusal`) traduits à l'affichage. Les retours d'outils envoyés au modèle du Copilote restent en français.
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

- **Éditeur BDFD** : le Studio utilise l'éditeur partagé (coloration, autocomplétion, signatures) et les **mêmes
  diagnostics que l'app**, y compris la validation native des arguments de chaque fonction (fonction inconnue ou non
  prise en charge, mauvais nombre d'arguments, branches non prises comprises). Le moteur complet dépend de nyxx
  (`dart:ffi`) et ne se compile pas pour le web : la validation passe par `bot_creator_shared/bdfd_validation.dart`
  (`bdfdNativeDiagnostics`), qui s'appuie sur une table des signatures générée depuis le registre réel
  (`dart run tool/gen_bdfd_signatures.dart` dans `packages/shared`). Un test de `shared` échoue si la table dérive du
  moteur ; le branchement du Studio est `lib/src/editor/bdfd_hooks.dart`.

- **Planificateur** : l'écran de l'app (déclencheurs, activation, limite du forfait), via les routes
  `scheduled-triggers` du Manager.

- **Webhooks entrants** : l'écran de l'app, via les routes `inbound-webhooks` du Manager. Le secret y est en écriture
  seule : jamais relu ; laissé vide il est conservé, ou généré par le serveur à la création et montré une seule fois
  (donc pas de « copier le secret » ni d'URL complète dans le Studio).

- **Accueil et variables globales** : la carte de bot de l'app (`HomeBotCard`, sans la ligne des serveurs que le Studio
  ne connaît pas) et les lignes de variables globales.

- **Serveurs et émojis** : les pages de l'app (liste alphabétique, quitter un serveur ; émojis d'application : liste,
  téléversement, renommage, suppression), via les routes `discord/guilds` et `discord/emojis` du Manager. Le jeton du
  bot reste sur le serveur.

- **Marketplace** : le catalogue et la fiche d'un modèle de l'app (recherche, catégories, note, variables, aperçu des
  commandes). Le Studio applique un modèle par ses routes de commandes, de workflows et de variables (avec la même
  fenêtre de conflits). La publication (assistant en trois étapes) est aussi celle de l'app : le Studio lit les commandes et workflows
  complets du bot, une lecture par entrée (intents compris, lus au Manager).

- **Éditeur d'image** : l'éditeur de canevas de l'app (opérations, aperçu), le sélecteur de fichiers rendant les octets
  de l'image (utilisable sur le web). **Carte de bot** : la ligne « actif sur N serveurs » et ses pastilles d'avatars (`GuildAvatarStack`, la même présentation que
  l'app) sont lues au Manager.

Reste à faire :
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
- Éditeurs BDFD et JavaScript ; Components V2 et modales. (Le bac à sable est partagé : voir plus haut.)
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
| Abonnements, facturation, crédits IA | partagé (hub, offres, crédits, refus de formule), lecture seule : aucun paiement web côté Manager |

## 4. Priorités proposées

1. **Workflows + palette d'ajout d'actions + création de commande** (M) : sans cela, le Studio ne sait que retoucher.
2. **Éditeurs d'actions typés et validation**, pilotés par un schéma de données (L).
3. **Variables à portée complètes** (S).
4. **Versions de config, historique, rollback, rechargement** (S/M).
5. **Copilot minimal** (L) : phase 1 portefeuille + liste de conversations (S/M) ; phase 2 chat en flux + approbation des
   outils (L). Pas besoin de porter la page de 2 900 lignes ni le MCP : l'état des conversations est côté serveur.
6. **Canvas Blueprint** (L), après 1 et 2 : seconde vue de `actions[]`, positions côté client.
7. **BDFD / JS** (L) ; en attendant, vue code en lecture seule (S). Le bac à sable est fait.
8. **Marketplace, import / export, conteneurs, docs, émojis, guilds** (M chacun).
9. **Planificateur et webhooks entrants** (M) : confirmer d'abord le stockage dans la config du bot.
10. **Components V2 / modales** (L), avec le point 2.

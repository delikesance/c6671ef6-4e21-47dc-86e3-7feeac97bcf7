# Copilote IA, historique et crédits

## Parcours

Le copilote est disponible depuis l’accueil, les cartes de bots, la fiche du bot et la navigation de l’éditeur. L’accueil permet les discussions globales et le filtrage par bot. Une discussion de bot conserve son identifiant et son emplacement (appareil ou Manager). Les réponses affichent du Markdown, y compris tableaux et code copiable, pendant le streaming.

Les conversations appartiennent au compte qui les crée. Elles sont enregistrées sur le Manager, synchronisées entre appareils, et conservées jusqu’à suppression. Les collaborateurs et administrateurs ne peuvent pas lire les conversations personnelles d’un autre compte. L’historique permet recherche par titre, pagination, renommage, archivage, export Markdown et suppression. Les anciennes discussions déjà fermées avant cette version ne peuvent pas être récupérées.

Chaque outil a une carte indiquant consultation, validation, exécution, réussite, refus ou état non confirmé. La validation concerne une action précise. Les outils d’une discussion de bot ne peuvent pas cibler un autre bot. Les bots clé en main ont aussi leur entrée Copilote ; leur contexte utilise `container:<id>` et leurs contrôles réutilisent les règles normales de couverture, TTL et temps d’hébergement. Les outils distants sont exécutés par le Manager après contrôle d’accès ; les outils locaux passent par la passerelle de l’application et vérifient aussi le bot du contexte.

Une action revendiquée ne sera pas exécutée une seconde fois. Si l’application ou le Manager s’arrête pendant une action, son résultat peut rester non confirmé ; inspecter le bot avant de clore cette étape, sans autoriser de rejeu. La réouverture d’une discussion ne relance jamais automatiquement une mutation. Huit générations maximum sont autorisées par instruction utilisateur pour éviter une boucle d’outils sans fin.

Une conversation trop longue propose un résumé dans la discussion actuelle, après confirmation du débit potentiel. L’historique visible et le brouillon sont conservés ; les prochains appels utilisent le résumé et les échanges récents. Un résumé échoué ne remplace pas le contexte existant.

## Comptabilité

**1 Crédit IA affiché dans l’application = 100 000 tokens traités**, y compris les tokens d’entrée servis depuis le cache. Le Manager conserve ses unités internes en tokens : la conversion est effectuée par l’application. Le coût dépend de l’usage réel ; aucun coût fixe par commande n’est annoncé. Le solde n’est pas affiché pendant le traitement. Le Manager réserve un budget prudent avant de contacter le fournisseur et libère l’excédent après validation de son usage. `balance` inclut les réservations ; `available = balance - reserved`.

## Outils de configuration

Les catalogues mobile et Manager déclarent les mêmes schémas. Les deux validateurs contrôlent les objets et listes imbriqués, les champs requis, les champs inconnus, les types, les énumérations et les bornes. La profondeur maximale de validation est de douze niveaux.

- `local_create_command` accepte les options dès la création.
- `local_update_command_options` ajoute, modifie ou retire un argument, y compris dans une sous-commande. L’outil exige la révision de `local_get_command`, conserve le code et les permissions, et met à jour le même identifiant Discord. Un argument utilisé dans l’exécution ne peut pas être supprimé ou renommé sans traiter ses références.
- `local_update_command_settings` modifie description, permissions par défaut et contextes Discord.
- `local_list_workflows`, `local_get_workflow`, `local_create_workflow` et `local_update_workflow` gèrent les automatisations autonomes. JavaScript exige le moteur JavaScript ; les blocs et le BDFD compilé exigent le moteur Dart. `local_list_events` expose les déclencheurs disponibles.
- `local_get_bot_configuration` expose configuration et révisions par section, sans secrets. `local_get_bot_presence` et `local_update_bot_presence` gèrent statut et activités ; `local_update_bot_profile` modifie le nom global Discord.
- `local_set_variable`, `local_update_scheduled_trigger` et `local_update_inbound_webhook` gèrent variables, planifications et déclencheurs externes. Les identifiants secrets des webhooks sont générés dans l’application et restent dans les paramètres du bot.

Chaque mutation nécessite une validation. Le résultat distingue sauvegarde locale, modification Discord et synchronisation du bot hébergé. Une réponse HTTP réussie sans confirmation du runtime actif ne confirme pas une mise à jour de commande ou de workflow. Un rechargement échoué retourne également une synchronisation non confirmée. La carte propose une nouvelle tentative lorsque l’application a sauvegardé la modification mais que son activation reste en attente.

Le débit, la réponse définitive et l’événement de fin sont enregistrés dans la même transaction. Une coupure de l’interface n’annule pas le travail serveur et ne déclenche aucun second appel fournisseur. Une requête interrompue sans réponse complète et usage valide est marquée en échec, libère sa réservation et n’expose aucune action exécutable. Les réservations expirent après deux minutes ; les requêtes abandonnées sont réconciliées à la consultation de l’espace IA.

Le journal distingue achats confirmés (`kofi`, et sources stores lorsqu’elles seront intégrées), roulette, attribution administrative, correction et consommation. Une attribution administrative ne compte jamais comme achat. Les tours de roulette sont distincts des crédits. Les paiements en attente et publicités non confirmées ne créditent pas le solde. Les achats consommables des stores restent un chantier commercial distinct.

La suppression d’une discussion efface messages, propositions, résultats et événements de streaming. Les mouvements comptables et les identifiants/fingerprints nécessaires à l’idempotence sont conservés.

## Manager

La rubrique **IA** contient vue d’ensemble, portefeuilles/mouvements et laboratoire. Chaque fiche utilisateur présente aussi son portefeuille et un lien de gestion. Les indicateurs séparent stock actuel, distribution et performances ; les nombres sont formatés selon la langue. Le laboratoire place l’historique dans une colonne latérale, replie la configuration des nouveaux tests et garde le message, les actions et le budget visibles dans leur contexte. Le mobile propose des suggestions de départ, distingue les messages de l’utilisateur et du copilote et conserve un composeur accessible en bas de l’écran.

Les stocks sont calculés à l’instant de la lecture ; les flux et usages suivent la période UTC sélectionnée. Les données peuvent être filtrées par compte, origine et référence. L’export CSV parcourt tout le journal filtré. Les crédits en circulation sont la somme des soldes utilisateurs, réservations comprises. Les achats et gains indiquent la provenance des mouvements historiques, pas une répartition inventée du solde restant.

Les ajustements exigent un montant signé, un motif et une clé d’idempotence. Un retrait ne peut pas dépasser le disponible. Réservations, règlements et ajustements utilisent le même verrou transactionnel de compte. Le blocage refuse les nouvelles dépenses sans empêcher le règlement des appels déjà réservés. Toutes ces actions sont inscrites dans le journal administratif existant.

Les lectures exigent `admin:read`. Ajustements, sessions de laboratoire et générations facturables exigent `admin:write`. Le laboratoire appartient à l’identité administrative (`admin:<id>`), distincte des tenants utilisateurs. Son budget cumulé et ses réservations sont séparés du portefeuille utilisateur et du KPI de circulation. Les générations et outils de laboratoire ont un audit technique dédié. Les actions ne peuvent viser que les bots de test explicitement autorisés ; aucune clé fournisseur n’est transmise au navigateur.

Le laboratoire permet modèles autorisés, instructions expérimentales, sessions persistantes, streaming et Markdown assaini. Il expose les outils documentaires officiels et les outils distants, jamais les outils locaux de l’application. Chaque session conserve usage, cache, latence et estimation de coût. Les tarifs sont des instantanés par appel ; une estimation n’est pas un paiement fournisseur confirmé.

## Activation

Appliquer les migrations jusqu’à **000081_ai_workspace** avant de démarrer le nouveau serveur. Mettre à jour l’application avec le serveur : l’ancienne route `/gateway/ai/copilot/reply` est supprimée.

Configuration uniquement côté serveur :

```dotenv
AI_PROVIDER_URL=https://api.deepseek.com/chat/completions
AI_PROVIDER_KEY=<secret>
AI_PROVIDER_MODEL=<modèle disponible>
AI_LAB_MODELS=<liste de modèles autorisés séparés par des virgules>
AI_LAB_BOTS=<identifiants de bots de test séparés par des virgules>
AI_LAB_TOKEN_LIMIT=1000000
AI_INPUT_USD_PER_MILLION=<tarif entrée hors cache>
AI_CACHE_USD_PER_MILLION=<tarif entrée avec cache>
AI_OUTPUT_USD_PER_MILLION=<tarif sortie>
```

Les modèles du laboratoire utilisent `AI_PROVIDER_MODEL` par défaut. Sans bots autorisés, le laboratoire reste utilisable pour les prompts et la documentation. Le plafond administratif est cumulé par administrateur ; augmenter la configuration permet d’augmenter le budget, sans remettre la consommation à zéro. Sans tarifs, l’interface indique qu’ils ne sont pas configurés ; les appels historiques sans tarif sont signalés dans les estimations. La rubrique IA du Manager propose un choix français/anglais.

L’adaptateur utilise Chat Completions avec `stream: true`, `stream_options.include_usage: true`, thinking désactivé, 4 096 tokens de sortie par défaut et un délai fournisseur de 70 secondes. Le contrat fournisseur est décrit dans la [documentation DeepSeek Chat Completions](https://api-docs.deepseek.com/api/create-chat-completion/). Il conserve `prompt_cache_hit_tokens` et `prompt_cache_miss_tokens`. Le préfixe des instructions et l’ordre du catalogue sont stables. Le cache fournisseur est temporaire et n’est pas garanti ; l’historique applicatif reste la source de vérité.

## Contrats API

- `GET/POST /gateway/ai/conversations` : liste privée (bot, titre, archives, offset) et création.
- `GET/PATCH/DELETE /gateway/ai/conversations/{id}` : lecture, titre/archivage et suppression ; `?export=markdown` pour l’export.
- `POST .../{id}/turns` : `{idempotency_key, revision, prompt, tools}`. Aucun historique arbitraire n’est accepté ; le serveur reconstruit celui enregistré.
- `GET .../{id}/requests/{key}/events` : SSE authentifié, événements `delta`, `completed`, `error`, avec identifiants de reprise (`Last-Event-ID` ou `after`).
- `POST .../{id}/actions/{call_id}` : validation/refus, ou enregistrement du résultat d’une action locale déjà revendiquée. Les effets distants sont exécutés côté serveur. Les contrôles démarrer/arrêter exigent aussi `execute:runners` pour les bots classiques et `containers:deploy` / `containers:write` pour les conteneurs. Une action au résultat incertain peut être close explicitement après inspection, sans réexécution.
- `POST .../{id}/continue` : création explicite d’une suite avec résumé, clé d’idempotence obligatoire.
- `GET /gateway/ai/ledger` : journal paginé du compte authentifié.
- Les routes de laboratoire équivalentes vivent sous `/admin/ai/conversations` et vérifient l’identité administrative.
- `/admin/ai/data` fournit statistiques, journal, budget laboratoire et export CSV ; `/admin/actions/ai/wallet` applique les ajustements et blocages.

## MCP externe sur desktop

Le bouton MCP ouvre un serveur Streamable HTTP sur `127.0.0.1`, port disponible et bearer aléatoire. Il conserve les contrôles de catalogue, validation des arguments et confirmation explicite de chaque mutation. Il est disponible tant que la page reste ouverte. Il ne donne aucun accès général au terminal ou au filesystem. La documentation officielle est consultée sur `https://bot-creator.fr/api/mcp`, sans identifiants Manager ni clé fournisseur.

## Vérification et déploiement

Tests Go : parsing des flux, usage, coupure sans débit, scoping des outils, confidentialité, révisions, Markdown assaini et routes administratives. Les tests PostgreSQL (`BCM_TEST_POSTGRES_DSN`, base jetable uniquement) couvrent transactions, concurrence, blocage, provenance, budget administratif sans tenant, suppression et conservation des écritures comptables. Les tests Flutter couvrent validation/refus et rendu Markdown sur écran étroit.

Déployer d’abord la migration, puis le serveur et l’application. Vérifier initialement avec les seuls bots de test configurés. Suivre réservations expirées, échecs, latence, usage/cache et écarts entre mouvements et soldes avant activation générale. La configuration d’une clé fournisseur et le déploiement en production ne sont pas effectués par les tests.

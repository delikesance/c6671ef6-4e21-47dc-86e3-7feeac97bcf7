# Copilote IA et passerelle MCP

## Parcours

Le bouton étoile sur l'accueil ouvre le copilote sur mobile et desktop. Le compte
Manager fournit le portefeuille commun : 1 crédit IA = 1 token. Les générations
s'exécutent sur le Manager ; aucune clé du fournisseur n'est distribuée à l'application.
Le contexte envoyé au modèle inclut les instructions, l'historique et les résultats
des outils demandés. Les tokens d'entrée et de sortie sont débités au total déclaré
par le fournisseur. Chaque étape IA est facturée, y compris une proposition que
l'utilisateur annule ensuite ; une action sur un bot ne consomme pas de tokens par
elle-même. L'exécution habituelle des commandes reste indépendante de ce portefeuille.

Le Manager réserve un budget prudent (borne en octets UTF-8 du contexte, marge et
plafond de sortie), puis libère l'excédent à la réponse. La réservation peut donc
être supérieure au coût final. Le portefeuille distingue `balance`, `reserved` et
`available`. Les réservations empêchent les dépenses concurrentes ; un échec libère
le budget et une réservation abandonnée cesse de bloquer le solde après deux minutes.
Une requête achevée et son débit sont enregistrés dans la même transaction ; le rejeu
de sa clé rend le résultat enregistré. Un contenu différent sous cette clé est refusé.

La roulette et les entrées vers l'acquisition de tokens sont réservées à iOS/Android.
Le desktop utilise le même solde à distance. Les packs consommables dans les stores
restent un chantier commercial distinct ; leur interface d'achat n'est pas ajoutée
par cette fonctionnalité. La roulette n'est pas un outil proposé au modèle.

## Outils et validation

La passerelle expose un catalogue fermé : documentation officielle (`docs_search`,
`docs_get`), liste/état/démarrage/arrêt des bots sur le Manager et sur l'appareil,
lecture des commandes locales, registre des fonctions/blocs, création d'une commande
et modification de son exécution. Les outils distants utilisent les routes existantes
du Manager et leurs contrôles de compte, de bot et de scopes. Un token de lecture
ne suffit pas pour les appels IA facturés : `/gateway/ai/copilot/reply` exige `write:bots`.
Il ne suffit pas non plus pour démarrer/arrêter un bot, qui exige `execute:runners`.

La documentation vient du MCP public `https://bot-creator.fr/api/mcp`, via son
initialisation et `tools/call`. Les identifiants d'authentification du Manager ne
sont pas envoyés à ce service public. Les sorties locales retirent les clés sensibles
et les secrets reconnaissables avant leur retour au modèle ; un utilisateur doit
éviter de placer lui-même des identifiants dans son message.

Chaque mutation déclenche une validation dans l'application, avec l'emplacement,
le bot et la modification proposée. Annuler empêche l'exécution. Un résultat d'outil
ne constitue jamais une autorisation de nouvelle mutation. Le modèle ne peut pas
déclarer une validation à la place de l'utilisateur.

Pour les commandes, les arguments JSON sont vérifiés contre le schéma de l'outil.
Le BDFD proposé est vérifié contre le registre fermé puis compilé par le compilateur
de l'éditeur, qui construit les types et les payloads des blocs ; le modèle ne
fabrique pas ces payloads. Les fonctions inconnues et les erreurs de compilation
sont refusées avant enregistrement. Les bots Dart acceptent ce parcours ; les bots
JavaScript restent contrôlables mais ne reçoivent pas de blocs Dart.

Une création refuse les noms déjà présents localement ou sur Discord et suit le
parcours existant de création. Une modification d'exécution exige la révision SHA-256
de la commande lue et conserve son ID local, son ID Discord, son nom, ses options
et ses permissions. Une commande avec sous-commandes exige une route explicite.
L'enregistrement déclenche la synchronisation habituelle de l'application ; sa
réussite locale ne prouve pas que tous les runners ont déjà appliqué les changements.

Le registre est embarqué dans le Manager (`internal/services/copilot_tools.json`)
et dans l'application (`assets/copilot/tools.json`). Modifier les deux copies ensemble.
Le client n'utilise un outil que si son nom, son schéma et son caractère mutatif
correspondent au contrat exposé par le Manager.

## Activation du Manager

Appliquer les migrations commerciales 000077 à 000079 et la migration
`000080_ai_copilot_usage`. Configurer uniquement sur le serveur :

```dotenv
AI_PROVIDER_URL=https://api.deepseek.com/chat/completions
AI_PROVIDER_KEY=<secret du fournisseur>
AI_PROVIDER_MODEL=<identifiant de modèle disponible sur votre compte>
```

Sans clé ou modèle, les appels IA répondent `ai_copilot_disabled`. L'adaptateur
utilise les appels d'outils de l'API Chat Completions DeepSeek, sans streaming et
avec le mode thinking désactivé. Le délai fournisseur est de 70 secondes ; le client
attend 80 secondes et garde la clé pour récupérer une réponse après une coupure.
Cette récupération reste disponible dans la page ouverte ; fermer la page efface
la conversation et la clé de reprise côté client.
Un échec définitif nécessite une nouvelle clé, produite par le bouton Réessayer.
Le budget de sortie est de 2 048 tokens dans le branchement actuel.
Contrat fournisseur : [documentation officielle](https://api-docs.deepseek.com/api/create-chat-completion/).

## Connexion d'un client MCP externe sur desktop

Sur la page Copilote, le bouton MCP lance un serveur Streamable HTTP sur
`127.0.0.1`, avec un port disponible et un bearer aléatoire. Le dialogue affiche
l'URL `/mcp` et l'en-tête `Authorization: Bearer …` à renseigner dans le client.
Il expose les mêmes outils et les mêmes validations dans l'application.

Ce serveur reste disponible tant que la page est ouverte. Fermer la page ferme
le serveur ; une nouvelle ouverture fournit de nouveaux paramètres. Il n'écoute
pas sur le réseau local et refuse les requêtes munies d'un Origin de navigateur.
Il ne propose ni terminal, ni commandes système, ni accès libre au filesystem.

## Vérifications locales

Les tests couvrent le décompte fournisseur, les réservations concurrentes et leur
libération, l'idempotence, les scopes et l'identité du compte, le refus d'outils et
fonctions inconnus, les révisions périmées et la préservation de l'identité Discord.
Les tests d'interface vérifient qu'annuler n'appelle pas le Manager et que valider
appelle le contrôle du bot une seule fois. La lecture du MCP public a également
été vérifiée depuis le client réel de la passerelle, sans action sur un bot réel.
Une clé fournisseur de production et un rollout sont nécessaires pour l'activation
en service ; ils ne sont pas effectués par les tests locaux.

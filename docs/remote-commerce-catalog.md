# Catalogue commercial distant — proposition

## État constaté le 29 septembre 2026

Versions déployées déclarées : application mobile et runner Dart 2.5.1,
Manager 0.21.2, runner JS 0.6.11, Dashboard et Creator Console 0.1.10.
Ces versions ne prouvent pas à elles seules quels contrats commerciaux sont activés.

Le Manager possède déjà un catalogue configurable : `account_tiers`,
`billing_tier_mappings`, `PlanCatalogService` et `/gateway/plans`.
La réponse décrit les quotas et les produits rattachés aux formules.

Dans l'application, `SubscriptionsHubPage._registerPurchasableProducts` utilise
ce catalogue pour reconnaître les produits, sans générer les cartes commerciales.
`SubscriptionPage` conserve ses offres mensuelle et annuelle et leurs textes dans
l'application. Les produits d'hébergement disposent aussi de correspondances locales.
Il manque un contrat pour publier de nouvelles offres et leurs avantages traduits.

## Offres actuelles et lecture des droits

Selon les précisions fournies, le fonctionnement actuel est le suivant :

| Offre actuelle | Bots personnalisés hébergés | Bots clé en main (Turnkey) | Financement du temps |
| --- | --- | --- | --- |
| Gratuite | Nombre illimité | 1 bot | Publicités, pour les deux types |
| Abonnement mensuel ou annuel | Nombre illimité | Pas de droit Turnkey supplémentaire déduit de cet achat | Abonnement pour les bots personnalisés |
| Abonnement Turnkey | Pas de droit supplémentaire aux bots personnalisés déduit de cet achat | 1 ou 2 bots selon le produit | Abonnement Turnkey |

Le mensuel et l'annuel sont deux périodicités de la même couverture. La couverture
Turnkey est distincte ; le serveur doit rendre explicitement les droits effectifs
lorsque plusieurs couvertures coexistent. Ne pas additionner automatiquement le bot
Turnkey gratuit aux 1 ou 2 bots d'un abonnement : la règle de cumul doit être fixée.

Rendre séparément dans l'API et l'admin : les achats actifs et leur origine, la
couverture de chaque catégorie, son quota, l'utilisation actuelle, son échéance et
le temps publicitaire restant. « Nombre illimité » ne signifie pas « temps gratuit
illimité ». Représenter le quota par un mode explicite (`limited` / `unlimited`) et
une limite quand applicable, plutôt que demander au client d'interpréter `0`.

L'admin présente les libellés « Bots personnalisés » et « Bots clé en main », la
source des droits et les périodes mensuelle/annuelle. L'API expose ces mêmes
dimensions sous forme structurée ; les textes traduits restent dans le catalogue.
Conserver les champs historiques pour les anciens clients et ajouter cette lecture
explicite. Tester la combinaison gratuite, personnalisée, Turnkey et leurs expirations.

## Responsabilités

- **Manager** : catalogue publié, traductions commerciales, disponibilité,
  correspondances de paiement, droits et quotas réellement appliqués.
- **Application** : composants de boutique, interactions d'achat et fonctions
  qu'elle sait exécuter. Un catalogue ne peut pas ajouter du code à un ancien client.
- **Adaptateur de paiement** : résolution du produit et du prix effectivement
  disponibles avant de proposer l'achat. Un identifiant déclaré dans le catalogue
  ne suffit pas à rendre un produit achetable.

Les nouveaux avantages affichés ne doivent pas accorder de droits par eux-mêmes.
Les droits proviennent exclusivement des achats, récompenses publicitaires et
octrois validés côté serveur.

## Contrat proposé

Conserver `/gateway/plans` pour les clients existants. Ajouter un contrat commercial
versionné, distinct de la façade `/api/v2` consacrée aux commandes.
La route additive est `/gateway/commerce/catalog` ; l'administration se trouve
dans `/admin/commerce`.

Chaque offre contient :

- un identifiant stable et une version du schéma ;
- un type pris en charge : abonnement hébergement, pack de crédits IA,
  récompense publicitaire IA ou contact agence ;
- une référence à la formule ou au pack serveur ;
- des titres, descriptions et avantages par locale ;
- une liste ordonnée d'avantages avec identifiants stables ;
- des bindings de paiement par fournisseur et plateforme, incluant les paramètres nécessaires
  à la sélection du produit ou de l'offre ;
- un ordre d'affichage, une disponibilité et une période de publication ;
- les capacités client requises pour afficher et acheter l'offre.

Publier un document avec révision et ETag. La localisation suit une règle explicite :
locale exacte, langue, puis langue par défaut du catalogue. Le contenu reste du texte
structuré ; pas de HTML ou de code distant à exécuter.

Un ancien client ignore les types inconnus. Un produit indisponible conserve une
explication lisible sans bouton d'achat actif. Le prix d'achat affiché vient du produit
résolu par l'adaptateur, plutôt que d'un texte de prix indépendant.

## Administration et publication

Prévoir création et édition d'offres, avantages traduits, bindings par plateforme,
prévisualisation et publication explicite. Une validation vérifie les traductions
de secours, les références aux formules et les bindings attendus.

La modification d'un texte commercial et la modification d'un quota sont deux
opérations distinctes. Les changements de quotas nécessitent une politique explicite
pour les abonnements déjà actifs. Conserver un journal et permettre de restaurer
une révision publiée du catalogue.

## Paiements extensibles : Ko-fi, puis Stripe et PayPal

Prévoir des adaptateurs de paiement interchangeables : achats intégrés existants,
Ko-fi en premier ajout, puis Stripe et PayPal. Tous alimentent le même journal
d'événements et le même service d'attribution des droits ou crédits. Les offres
possèdent des bindings propres à chaque fournisseur ; leur contenu commercial et
leurs droits ne dépendent pas du moyen de paiement.

Pour Ko-fi, le contrat fourni décrit un POST HTTPS `application/x-www-form-urlencoded`
dont le champ `data` contient le JSON. Vérifier le `verification_token` côté serveur
avec une comparaison en temps constant et un secret configuré hors du catalogue.
Ne jamais exposer ce secret au client ni le recopier dans les journaux.

Enregistrer durablement un événement valide avant l'accusé HTTP 200, puis traiter
l'attribution avec reprise en cas d'échec. Ko-fi rejoue le même `message_id` lorsqu'il
ne reçoit pas 200 : imposer son unicité par fournisseur. Vérifier aussi l'identité
de la transaction pour éviter un second octroi via un autre message du même paiement.
Un doublon valide déjà enregistré reçoit 200 sans nouveau droit.

Normaliser les types : abonnement (`Subscription`), achat boutique (`Shop Order`),
commission et don. Le texte fourni annonce `Tip`, alors que son exemple emploie
`Donation` : prendre en charge les deux pour les dons. Un don ou une commission
n'accorde aucun droit commercial sans mapping explicite.

Associer les abonnements via un mapping contrôlé de `tier_name`, et les packs via
`shop_items[].direct_link_code` et la quantité. Contrôler le montant et la devise
attendus en arithmétique décimale. Utiliser les indicateurs de premier paiement et
de renouvellement et la date de l'événement pour appliquer une période de couverture
explicite, sans prolongation multiple lors d'un rejeu. Un paiement mensuel ne prouve
pas que les mois suivants seront payés.

Rattacher le paiement à un compte lié et vérifié, par exemple via `discord_userid`
et une liaison Discord existante. Ne pas attribuer automatiquement des droits à
partir d'un pseudonyme ou d'un email. Un paiement non rattaché ou non mappé reste
en attente de résolution dans l'admin, avec une reprise qui ne duplique pas l'octroi.

Le contrat fourni décrit les paiements terminés ; il ne fournit pas d'événements
de résiliation ou de remboursement. Prévoir l'expiration des périodes payées et
une procédure de réconciliation/compensation pour ces cas. Respecter `is_public`
si un paiement est affiché publiquement et ne pas exposer les coordonnées privées.

Pour les futurs adaptateurs Stripe et PayPal, prévoir validation propre au
fournisseur, correspondances de produits, événements de renouvellement,
remboursement et résiliation, et la même idempotence. La disponibilité d'un parcours
d'achat externe se configure par plateforme et capacités du client ; la publication
d'un binding seule n'active pas ce parcours.

## Transition vers les offres 2 / 4 / 6 bots

La cible commerciale déclarée est Starter, Pro, Master et Agence, avec un quota
unifié de bots hébergés. L'exécution sur « Ce poste » reste gratuite et illimitée.

Ces formules sont configurées par l'administrateur dans le Manager. Les valeurs
2 / 4 / 6 ne sont pas codées dans le client et aucune migration automatique des
abonnements existants n'est déclenchée par la publication du catalogue. Le Manager
reste responsable des quotas et des droits effectifs ; l'interface doit en faciliter
la lecture et la modification.

Ne pas déduire ce quota unifié de la seule suppression d'une carte : le Manager
expose actuellement aussi `max_turnkey_bots`, `allow_turnkey` et `allow_own_bots`.
Aligner les contrôles de déploiement, les droits et les écrans avant la publication.
Décider du traitement des achats existants avant de retirer les anciens produits.
La migration part des couvertures distinctes décrites plus haut. Documenter la
conversion, le maintien éventuel des droits historiques et le cumul avant de publier
les nouvelles formules ; aucun abonnement existant ne doit être réinterprété
silencieusement comme une nouvelle offre à quota réduit.

## IA

Le catalogue décrit les packs ; un service séparé tient les crédits et leur consommation.
Les packs 3 € / 6 M et 10 € / 20 M sont des objectifs commerciaux fournis, pas une
évaluation de rentabilité. L'unité est confirmée : **1 crédit IA = 1 token utilisable**.
Un pack de 6 M crédits correspond donc à 6 M tokens, et un pack de 20 M à 20 M tokens.
La consommation prévue additionne les tokens d'entrée et de sortie indiqués par
le fournisseur, y compris le contexte envoyé, sans décompte approximatif par caractères.
Le parcours de génération et cette consommation sont ajoutés dans le copilote,
décrit dans [ai-copilot-mcp.md](ai-copilot-mcp.md), à activer après configuration serveur.

Le serveur valide les achats de manière idempotente, journalise les crédits accordés,
réserve un budget avant une génération, puis régularise la consommation ou libère
la réservation en cas d'échec. Les remboursements ont une écriture de compensation.
Le client ne détient ni la clé du fournisseur ni l'autorité sur le solde.

Le fournisseur et le modèle sont configurables côté serveur. La génération utilise
le registre fermé de blocs et une validation du JSON retourné avant importation.
Publier une offre IA seulement pour les clients possédant le parcours IA requis.

### Roulette publicitaire de crédits IA

Ajouter un parcours avec **au maximum 3 publicités par jour UTC et par compte**.
Chaque publicité validée donne **1 tour**. Les gains envisagés sont 1 000, 5 000,
10 000, 20 000, 50 000 ou 100 000 crédits (autant de tokens), ou **+1, +2, +5 tours**.
Les tours bonus ne nécessitent pas de nouvelle publicité et tous les tours inutilisés
sont conservés sans expiration. La limite concerne les publicités, pas les tirages.
Le serveur vérifie la preuve publicitaire ; le callback local de l'application
ne suffit jamais à créditer le compte.

Le serveur émet un ticket lié au compte et à une tentative, vérifie le callback
serveur du fournisseur publicitaire et sa transaction unique, puis accorde un tour.
Une demande de tirage séparée consomme un tour et décide du gain par un tirage sûr.
Les paliers et leurs probabilités sont configurables
et versionnés côté serveur ; leur distribution reste à définir. L'animation de
roulette révèle le résultat enregistré, sans choisir ni retenter le gain localement.

Réserver une place quotidienne avant de lancer la publicité pour empêcher deux
appareils de dépasser le plafond. L'attribution atomique consomme la place et écrit
le tour dans un journal distinct des crédits. Un doublon de preuve ne donne pas
un second tour. Les tickets expirent après 15 minutes ou à minuit UTC au plus tôt ;
les preuves reçues après expiration sont refusées. Chaque tirage possède une clé
d'idempotence : un rejeu rend le même résultat sans consommer un autre tour.

Calendrier confirmé : jour UTC, limite attachée au compte et commune à tous
ses appareils. L'API rend les utilisations restantes et la prochaine remise à zéro.
Les échecs sans récompense validée libèrent leur réservation à expiration du ticket.

Séparer dans le journal les crédits achetés et publicitaires, tout en explicitant
leur consommation dans le solde utilisable. L'unité commune aux packs et aux gains
est le token. Définir l'ordre de consommation et l'éventuelle expiration des crédits publicitaires avant
publication ; l'expiration des minutes d'hébergement ne s'applique pas implicitement
aux crédits IA. Le catalogue fournit les textes traduits et les règles affichées.

## Ordre de réalisation proposé

1. Clarifier les couvertures actuelles dans l'API et l'admin, avec tests de cumul
   et d'expiration ; définir la conversion vers le quota unifié.
2. Contrat commercial, stockage et administration, avec tests de publication
   et bindings pour plusieurs fournisseurs.
3. Adaptateur Ko-fi, journal durable des paiements, rattachement des comptes et
   attribution idempotente. Préparer les interfaces pour Stripe et PayPal.
4. Boutique mobile dynamique, prix résolus, cache du dernier catalogue valide,
   états d'indisponibilité et compatibilité des anciens clients.
5. Configuration des formules et publication des nouvelles offres depuis le Manager,
   avec une règle explicite pour les abonnements historiques si leurs quotas changent.
6. Crédits IA, comptage serveur et parcours client, puis publication des packs.
7. Roulette publicitaire IA : validation serveur, quota quotidien et animation
   client ; activation après définition des probabilités et des règles de crédits.

Vérifications attendues : ajout d'une offre sans nouvelle compilation du client
compatible ; traduction avec repli ; produit absent ; type inconnu ; catalogue hors
ligne ; prix et produit sélectionnés cohérents ; quota imposé côté serveur ; achat
rejoué sans double crédit ; échec IA sans réservation bloquée ; webhook Ko-fi invalide,
dupliqué ou reçu hors ordre ; paiement non rattaché ; quantité boutique ; couverture
expirée ; message privé masqué ; roulette entre 1 000 et 100 000 tokens ou tours bonus ; quatrième
publicité refusée ; tours conservés et tirages rejoués ; deux appareils concurrents ; preuve publicitaire rejouée ou
tardive ; changement de jour et réservation abandonnée.

## État de l'implémentation locale

Le catalogue brouillon/publié, ses traductions, les bindings, la lecture explicite
des couvertures, le webhook Ko-fi avec journal idempotent et la roulette vérifiée
côté serveur sont ajoutés. Le client mobile compatible affiche les abonnements
natifs du catalogue et le parcours de roulette. Le portefeuille API explicite
`unit: "token"` et `tokens_per_credit: 1` ; les champs historiques `credits` restent
les nombres de tokens accordés. Les migrations Manager requises sont 000077 à 000080.
`KOFI_WEBHOOK_SECRET` active la vérification Ko-fi ; les unités publicitaires iOS/
Android et les poids de roulette se configurent dans l'admin. La roulette est
désactivée tant que ces réglages ne sont pas fournis.

Le copilote ajoute la génération avec compilation contre le registre fermé,
la réservation et la consommation des tokens, ainsi qu'une passerelle MCP réunissant
la documentation, les contrôles distants et les actions locales soumises à validation.
Son utilisation est disponible sur desktop ; roulette et acquisition restent mobiles.
À réaliser avant la commercialisation des packs : achats intégrés de consommables et
parcours de paiement externe du client. Stripe et PayPal restent des adaptateurs
futurs. Le journal des publications existe ; sa restauration depuis l'interface
reste à ajouter. Ces changements locaux ne sont pas encore déployés.

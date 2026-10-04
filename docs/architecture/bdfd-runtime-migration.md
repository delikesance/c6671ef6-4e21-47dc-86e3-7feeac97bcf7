# Décisions BDFD et branches conditionnelles

Date : 3 octobre 2026. Direction retenue après inspection du code et comparaison
des alternatives avec Jev. Un premier noyau natif est implémenté ; la migration
des bibliothèques métier et des points d’entrée reste à terminer.

## Moteur dédié unique

Le backend historique `BdfdCompiler` transforme le code en `List<Action>` avec
`BdfdAstTranspiler`, puis utilise les exécuteurs de blocs. Il reste le défaut
pendant la migration. Les commandes slash, commandes préfixées et événements
peuvent maintenant sélectionner explicitement `native-v1`. Les blocs
`runBdfdScript` et la sandbox peuvent également sélectionner le backend natif. Renommer ce compilateur ou ajouter un
wrapper seul ne rendrait pas le BDFD indépendant.

La cible est un interpréteur AST BDFD, avec une seule API d'exécution utilisée par
ces points d'entrée. L'AST, les valeurs et le contrôle de flux ne doivent pas
dépendre de `Action` ou du format JSON de l'éditeur visuel. Le moteur appelle des
services partagés pour Discord, le stockage, HTTP, les images et les permissions.
Les blocs visuels pourront appeler les mêmes services.

Le contexte d'exécution doit porter les variables temporaires, les résultats,
la cible Discord, l'état de réponse, le budget de temps et la pile d'appels.
Les appels imbriqués partagent le budget et l'état de réponse. Les diagnostics
doivent conserver la fonction, la ligne et la colonne. Les arguments sont
évalués au moment de l'exécution : ne pas substituer tout le script avant de le
parser, sauf pour l'évaluation dynamique explicitement demandée par `$eval`.

`runBdfdScript` devient un adaptateur vers cette API, avec le même moteur et les
mêmes erreurs que les commandes BDFD. Conserver son nom sérialisé pour les
workflows existants. Distinguer source BDFD et code produit dynamiquement par
`$eval`, plutôt que d'appliquer implicitement la même substitution aux deux.

## Migration et critères de bascule

1. Extraire les services et établir un corpus de scénarios exécutables :
   modération, variables, conditions, boucles, réponses, interactions, HTTP,
   JSON, images, appels imbriqués et gestion des erreurs.
2. Implémenter le moteur AST et des services simulés enregistrant les effets
   demandés. Comparer variables finales, réponses, cibles et ordre des effets
   avec le moteur existant. Une compilation réussie ne prouve pas cette parité.
3. Ajouter une sélection explicite et versionnée du backend. Basculer seulement
   les commandes entièrement couvertes. Ne jamais reprendre avec l'ancien
   moteur après un effet Discord déjà exécuté : cela pourrait le répéter.
4. Migrer tous les points d'entrée, y compris les handlers de l'application et
   la sandbox, puis retirer le backend Action une fois les scénarios couverts.

Le corpus et les tests précèdent la bascule du runner hébergé.

Règle précisée par l’utilisateur : une fonction inexistante est autorisée et
conservée telle quelle, arguments inclus, sans les évaluer. Une fonction connue
du catalogue mais pas encore migrée dans le backend natif reste diagnostiquée
avant les effets ; elle ne doit pas être considérée comme migrée.

## État de l’implémentation native

Le noyau se trouve dans `packages/shared/lib/engine/bdfd/` :

- `program.dart` réutilise le lexer/parser et construit des branches, boucles et
  blocs try/catch natifs avec leurs positions source.
- `runtime.dart` exécute cet AST directement, sans transpiler ni `Action`.
  Il couvre les variables temporaires, conditions bloc et inline, boucles à
  compteur, C-style, sur listes et while, alias loop, break/continue/stop,
  gardes onlyIf, commentaires, opérateurs
  booléens paresseux, mathématiques de base et eval explicite.
- `loop_syntax.dart` lit les déclarations et mises à jour C-style avant
  l’évaluation des valeurs. Les valeurs interpolées ne peuvent pas déclarer de
  nouveaux itérateurs. Les boucles imbriquées restaurent les variables externes
  et continue applique bien la mise à jour C-style.
- `engine.dart` compose ces bibliothèques dans l’API `BdfdEngine` (identifiant
  `native-v1`), avec préparation sans effets et exécution d’un programme préparé.
- `execution.dart` fournit l’adaptateur partagé `BdfdScriptExecution` et les
  versions `legacy-v1` et `native-v1`. `data.bdfdBackend` sélectionne explicitement
  le backend d’une commande slash, préfixée ou d’un workflow événementiel.
  Une route slash peut hériter du backend parent ou le préciser localement.
  Une valeur absente conserve le backend historique ; une version inconnue
  échoue avant les effets. Aucun fallback après un échec natif n’est possible.
  La préparation native précède la déférence slash. L’adaptateur partage le
  budget avec l’acquittement et retire seulement sa propre réponse différée
  lorsque le script a produit uniquement des messages de salon ou des followups.
  Il conserve une réponse originale terminée ou préexistante. Un acquittement
  tardif est également nettoyé sans démarrer les effets du script.
  Ce raccordement est opt-in dans le code local, pas une bascule du runner
  hébergé. Le sélecteur de l’éditeur et les autres points d’entrée restent à faire.
- `context_functions.dart` lit les valeurs de contexte au moment de l’appel.
  Les valeurs produites par un getter restent du texte, jamais du code implicite.
  `$message` prend les arguments préfixés fournis par les adapters (sans trigger),
  les sélecteurs positionnels et les options slash nommées, via
  `services/command_input.dart`. Mentions utilisateur/salon/rôle, isMentioned,
  argCount et argsCheck sont natifs. Les fonctions de mention refusent le
  contexte slash, où `$message[option]` doit être utilisé. `$mentioned[1]`
  reprend le défaut BDFD qui retourne l’auteur si aucune mention n’existe.
- `text_functions.dart` gère replaceText, textSplit, splitText, ses lectures et
  mutations, joinSplitText, checkContains, repeatMessage, trimContent et titleCase.
  `services/text_operations.dart` est partagé avec les expressions et le
  compilateur historique pour les remplacements et opérations de split.
  Un remplacement borné parcourt les occurrences du texte original, sans
  réinterpréter le texte inséré. L’état du split est commun aux branches et eval,
  mais propre à l’invocation. Le moteur natif suit les signatures officielles
  de [repeatMessage](https://wiki.botdesignerdiscord.com/bdscript/repeatMessage.html)
  (nombre puis texte, maximum 10) et de
  [argsCheck](https://wiki.botdesignerdiscord.com/bdscript/argsCheck.html)
  (condition compacte et message), avec compatibilité de la signature séparée.
- `variable_functions.dart` lie les getters/setters persistants au service
  `services/variable_service.dart`, également utilisé par les blocs pour la
  lecture scoped, la normalisation des clés et les définitions. Les modes
  historiques et actuels des variables user restent distincts.
- `json_functions.dart` utilise `services/json_document.dart`, également
  appelé par les blocs runtime JSON : lectures, chemins, mutations, tableaux,
  coercition, pretty et stringify partagent la même implémentation. Le contexte
  JSON persiste entre les branches et eval, sans conversion en runtimeJsonBlock.
- `http_functions.dart` utilise `services/http_service.dart`, partagé avec
  l’exécuteur HTTP visuel : méthodes, corps, transport, extraction des chemins
  JSON et cycle de vie du client. Les en-têtes en attente et la dernière réponse
  appartiennent au contexte de commande, partagé avec eval. Le handler transmet
  aussi le budget aux requêtes des blocs pour refuser leurs résultats tardifs.
- `message_functions.dart` construit la réponse principale (texte, embeds,
  champs, mentions, ephemeral, tts et reply) et propose les envois explicites.
  Le service `services/bot_message_service.dart` reçoit des messages évalués
  immuables. Le transport Discord `send_message.dart` et `respond_with_message.dart`
  a été extrait dans `services/`, avec les anciennes entrées conservées pour les
  blocs. Aucun `Action` n’est produit par les fonctions natives.
  `$sendMessage[texte;yes/no]` crée un nouveau message dans le salon courant,
  même depuis une interaction déjà acquittée ; `yes` renvoie son ID comme valeur
  utilisable par `$var` ou dans la réponse principale. Il ne consomme pas l’embed
  de cette réponse. Les paramètres invalides sont refusés avant cet envoi.
  Cette sémantique suit la [documentation BDFD officielle](https://wiki.botdesignerdiscord.com/bdscript/sendMessage.html)
  et la consigne utilisateur, plutôt que la conversion historique en réponse
  d’interaction. Le traitement particulier des images reste à raccorder.
  Eval partage le service et l’état d’acquittement ; les arguments ne sont pas
  envoyés implicitement. Un envoi échoué ne peut pas être rejoué par catch.
- Le bloc sérialisé `runBdfdScript` sélectionne `payload.bdfdBackend`, puis
  appelle directement `BdfdScriptExecution` pour `native-v1`. Il transmet la
  source intacte : aucun remplacement de placeholders avant le parser. Le
  handler partage le contexte natif et le budget avec les branches imbriquées,
  et `services/runtime_temporary_variables.dart` fournit une vue commune des
  variables `temp.*` et de `$var`. JSON, split et HTTP restent dans cette session.
  Les résultats et l’arrêt d’un script natif sont propagés au workflow visuel.
  `runWorkflow` détecte les workflows contenant du BDFD et utilise cette même
  route avec leur version de backend. Le prétraitement visuel conserve la source
  native, y compris dans les actions imbriquées. Les policies de sandbox doivent
  fournir des adaptateurs de messages et HTTP natifs ; le handler refuse de contourner une
  policy sans cet adaptateur.
- `workflow_functions.dart` implémente `$callWorkflow` et `$workflowResponse`.
  Les workflows BDFD appelés sélectionnent explicitement `native-v1`, puis
  s’exécutent avec le même runtime et contexte, sans conversion en Action. Les
  workflows visuels passent par un adaptateur qui exécute leurs blocs existants.
  Les noms d’arguments sont lus depuis la syntaxe littérale avant interpolation ;
  des valeurs contenant `=` ou `$` restent des données. Les arguments requis et
  les valeurs par défaut utilisent le résolveur partagé des workflows. Le budget
  inclut la lecture du workflow, les appels imbriqués et leurs effets ; les piles
  de workflows et de fonctions détectent la récursion et portent les diagnostics.
  Les arrêts d’un enfant interrompent le script appelant. Les réponses visuelles
  originales terminées sont signalées au contexte natif, pour que le nettoyage
  d’une déférence slash ne les supprime pas.
- La sandbox sélectionne `bdfdBackend: native-v1` pour les scripts et appelle
  le même `BdfdScriptExecution` que les commandes. Son adaptateur de messages
  capture directement les requêtes neutres, avec destination et ID simulé ;
  il ne construit pas de blocs. Le client HTTP de fixtures est partagé avec les
  blocs, consomme chaque réponse une seule fois et refuse les requêtes sans
  simulation explicite. Les workflows BDFD et visuels imbriqués héritent de ces
  adaptateurs, de la session et du budget. Les modes de variables user 1 et 2
  restent explicites. Les diagnostics natifs conservent ligne, colonne et
  fonction. Le contexte expose un observateur de traces natif : appels et retours
  de fonctions, valeurs littérales inconnues, conditions et branches choisies,
  itérations, break/continue, arrêts et erreurs prises en charge par catch. Les
  sources et profondeurs restent propres aux appels eval imbriqués. La sandbox
  conserve 1 000 événements au maximum, tronque leurs valeurs à 500 caractères
  et indique le nombre omis ; sa trace de programme conserve les variables
  modifiées. Une erreur de l’observateur ne peut pas rejouer ou interrompre les
  effets. Le replay de l’éditeur lit les métadonnées natives (position, état, branche,
  profondeur et troncature), préserve les noms exacts des fonctions et place
  les événements dans leur ordre, sans additionner les durées imbriquées.
  Le défaut reste legacy-v1 ; aucun réseau ou client Discord réel n’est ouvert.
- `replay.dart` convertit les observations natives en frames du transport de
  replay existant, sans produire de blocs. Les commandes, événements et blocs
  natifs transmettent ces frames lorsque la capture est activée. Les branches
  visuelles imbriquées gardent l’observateur de leur parent ; les observateurs
  précédents sont restaurés à la fin de chaque capture. Les échecs de préparation
  produisent une frame d’erreur, et les scripts constitués uniquement de texte
  produisent une frame terminée. Une erreur du destinataire du replay ne peut
  pas échouer ou rejouer un script exécuté. Les captures sont bornées et signalent
  les événements omis. Les tests shared et Flutter vérifient cette livraison,
  la sérialisation, le rendu des noms/positions et une timeline dense.
- La page de commande et son éditeur de code sélectionnent explicitement
  `legacy-v1` ou `native-v1`. La validation native appelle le registre réel
  via `BdfdEngine.validation()`, dont les services refusent toute exécution ;
  elle ne compile pas d’actions. Le notifier efface son ancien résultat de
  compilation en passant au natif. Les diagnostics ont les positions natives,
  y compris les fonctions connues non encore prises en charge dans une branche
  ignorée ; les fonctions inconnues restent opaques et autorisées. Sauvegarde,
  normalisation, rechargement et import conservent le champ de backend. Une
  version inconnue est conservée et signalée, jamais convertie silencieusement
  en legacy. La sandbox reçoit le même backend, que les fixtures ne peuvent pas
  remplacer. Les tests Flutter couvrent une sauvegarde réelle du brouillon.
  Le champ runBdfdScript et l’éditeur de workflows utilisent également cette
  validation et transmettent le backend à leur éditeur de code.
- Le bloc runBdfdScript déclare `bdfdBackend` dans son schéma sérialisé et
  propose un sélecteur fixe de moteur. Ses diagnostics sont recalculés lors
  d’un changement de moteur même si la source est inchangée. Les fonctions
  inconnues restent opaques, y compris dans le champ de script du bloc.
  L’éditeur de workflows propose le mode bdfd_script, un moteur et la source,
  puis valide les erreurs avant sauvegarde. La normalisation conserve ce mode
  et les anciennes clés de source sont ramenées à bdfdScriptContent. Le stockage
  garde moteur et source lors d’une mise à jour partielle ; l’import les
  transmet explicitement. Le passage au visuel efface la source BDFD active à
  la sauvegarde. La vue Blueprint est désactivée pour les scripts. Les tests
  Flutter couvrent le sélecteur réel du bloc, sa sérialisation, les diagnostics,
  l’ouverture d’un workflow natif et les mises à jour de stockage.
- L’extension de projet `$jsonForEach/$endJsonForEach` possède désormais sa
  propre structure d’AST et un parcours natif. `$jsonKey`, `$jsonValue` et
  `$jsonIndex` lisent la portée d’itération ; jsonValue conserve également la
  lecture par chemin hors boucle. Les indices, break/continue, les gardes,
  erreurs et budgets utilisent le contexte commun. Les boucles JSON imbriquées
  et mixtes restaurent leurs portées après sortie ou erreur. Le service
  JsonDocument fournit aux deux moteurs un instantané immuable des clés et
  valeurs textuelles : une mutation du JSON ne prolonge pas le parcours actif,
  et ses valeurs ne sont pas reparsées comme du BDFD. Les fonctions inconnues
  englobantes restent opaques, même avec des délimiteurs JSON dans leurs
  arguments. Les tests comparent notamment le contenu des envois simples au
  moteur historique ; cela ne prouve pas leur parité générale sur Discord.
  Cette extension migre le comportement existant du projet ; la documentation
  officielle JSON consultée ne permet pas de confirmer une fonction BDFD
  officielle jsonForEach.
- Le budget d’exécution commun vit dans `engine/execution_budget.dart` ;
  l’ancien chemin `actions/execution_budget.dart` le réexporte. Les appels eval
  partagent ce budget, les variables et l’état de réponse. Les diagnostics
  conservent aussi la pile des fonctions appelantes.

Les suites `bdfd_native_runtime_test.dart`, `bdfd_native_variables_test.dart`,
`bdfd_native_json_test.dart`, `bdfd_native_http_test.dart`,
`bdfd_native_loops_test.dart`, `bdfd_native_engine_test.dart` et
`bdfd_native_messages_test.dart`, `bdfd_native_text_test.dart` et
`bdfd_backend_selection_test.dart`, `bdfd_native_action_bridge_test.dart` et
`bdfd_native_workflows_test.dart`, `bdfd_native_sandbox_test.dart` et
`bdfd_native_trace_test.dart` et `bdfd_native_replay_test.dart` et `bdfd_native_validation_test.dart` et `bdfd_native_json_foreach_test.dart` couvrent les effets simulés, l’ordre des branches, l’absence de réinterprétation
implicite, les fonctions inconnues conservées intégralement, les gardes, les
limites et erreurs, ainsi que des comparaisons avec le véritable handler de
blocs pour les variables finales, les données persistées et les définitions,
ainsi que les requêtes HTTP (méthode, URL, en-têtes, corps) et leurs résultats.
Un scénario préparé combine HTTP, JSON, boucle C-style et stockage guildMember.
Ces comparaisons ne constituent pas une parité complète du langage.
Les messages sont vérifiés par des captures de service et des objets Nyxx
simulés, incluant les replies préfixés, les nouveaux messages de salon depuis
une commande slash, les retours d’ID et les budgets. La parité des simples
textes/embeds est comparée au handler de blocs ; le `$sendMessage` natif corrige
volontairement sa sémantique historique. Les frontières des réponses autour
des branches, boucles et gardes nécessitent encore un corpus BDFD plus large.

À terminer avant bascule : signatures de contexte avec
arguments et autres fonctions du catalogue encore absentes du registre natif,
complément des réponses/embeds et construction des composants, autres services Discord et permissions,
images, complément de la modération et autres fonctions du catalogue. Étendre le corpus de parité à ces
bibliothèques puis compléter la sélection versionnée dans l’éditeur, les
bibliothèques natives encore manquantes et les scénarios de parité sur Discord.
Les blocs `runBdfdScript` et les appels visuels de workflows BDFD sont raccordés
sur sélection explicite, avec tests utilisant le handler réel. La sélection explicite
des commandes slash/préfixées et événements est raccordée dans le code local ;
le défaut et le runner hébergé ne sont pas basculés. Aucun repli automatique
après un effet n’est introduit. Les tests du sélecteur et de son cycle de réponse
ne constituent pas encore un essai complet sur Discord de ces handlers.

Vérifications du 3 octobre : analyse ciblée sans diagnostic et suite complète du
package shared (2 356 tests) passée après extraction JSON/HTTP/messages/texte,
ajout des bibliothèques et raccordement versionné des premiers points d’entrée, de la sandbox, des traces natives et du replay. Quatre tests Flutter du replay
natif passent également ; 74 tests ciblés de validation, éditeur, sauvegarde et
normalisation passent après le raccordement de l’éditeur de commande. Une
sélection de 40 tests Flutter passe après raccordement des blocs et workflows ;
le test supplémentaire des anciens noms de source est également validé.
Les scénarios de parité ont une portée
limitée ; ce résultat ne valide pas encore l’ensemble du catalogue, les
interactions Discord réelles ou la bascule du runner.

## Service commun de modération

Les blocs `kickUser`, `banUser`, `unbanUser`, `muteUser` et `unmuteUser` délèguent à
`services/bot_moderation_service.dart`. La résolution des placeholders reste
à la frontière des blocs ; le service reçoit une requête immuable déjà évaluée
et ne réinterprète ni BDFD ni templates. Les permissions et la hiérarchie de
rôles sont extraites dans `services/permission_checks.dart`, avec réexport de
compatibilité pour les imports historiques.

L'adaptateur `DiscordBotModerationService` accepte le budget partagé, le vérifie
après les lectures asynchrones et immédiatement avant la mutation Discord.
Une vérification qui termine après expiration ne peut pas déclencher une
expulsion, bannissement ou débannissement. Les ID explicites invalides sont
rejetés avant accès Discord. Les contrôles du propriétaire, des rôles et
des permissions sont conservés. Les blocs conservent leur contrat de résultat,
les raisons par défaut et la limite de suppression des messages entre 0 et 7 jours.

Le registre natif prend maintenant en charge `$kick`, `$ban`, `$banID`,
`$unban`, `$unbanID`, `$timeout`, `$untimeout` et `$kickMention` via ce service, sans créer d'Actions. Les commandes slash, commandes préfixées,
événements, blocs `runBdfdScript`, workflows imbriqués et sandbox disposent
d'un adaptateur. Une politique d'exécution doit fournir explicitement son
adaptateur de modération ; son absence laisse ces fonctions non prises en
charge au préflight, sans possibilité d'accéder au transport Discord réel.

Les signatures suivent les pages officielles :
[`$kick[ID;raison]`](https://wiki.botdesignerdiscord.com/bdscript/kickComplex.html),
[`$kick` sans arguments](https://wiki.botdesignerdiscord.com/bdscript/kick.html),
[`$ban[raison]`](https://wiki.botdesignerdiscord.com/bdscript/banComplex.html) et
[`$banID[raison;ID]`](https://wiki.botdesignerdiscord.com/bdscript/banIDComplex.html).
`$ban` cible la première mention, sans repli vers l'auteur ; `$banID` prend
l'ID explicite ou le dernier argument du message si l'ID est vacant. Les raisons
sont limitées à 512 caractères. Une raison BDFD vide n'ajoute pas la raison
automatique des blocs historiques. Les arguments évalués restent des données.

Un bannissement d'utilisateur extérieur est permis seulement après les
contrôles de permission et du propriétaire, si la recherche de membre retourne
une absence certaine (erreur Discord 10007/404 ou absence de fixture typée).
Les erreurs de permission, réseau ou utilisateur inconnu restent bloquantes.
La sandbox utilise les mêmes contrôles de permission avec un gateway de lecture
sur fixtures, puis simule explicitement les effets sans construire d'Actions.
Elle exige les fixtures de propriétaire, rôles, membres, bans et l'ID du bot.

Les débannissements suivent les signatures officielles
[`$unban`](https://wiki.botdesignerdiscord.com/bdscript/unban.html),
[`$unbanID` sans arguments](https://wiki.botdesignerdiscord.com/bdscript/unbanID.html)
et [`$unbanID[ID]`](https://wiki.botdesignerdiscord.com/bdscript/unbanIDComplex.html).
`$unban` prend le nom d'utilisateur dans le message et cherche les bans par
pages de 1 000, avec comparaison insensible à la casse et arrêt si un curseur
se répète. `$unbanID` sans arguments prend le dernier argument du message ; un
ID explicitement vide est refusé. L'accès exige la permission Ban Members,
mais pas de contrôle de hiérarchie ni de propriétaire sur un utilisateur banni.
Un utilisateur banni n'a pas besoin d'être membre actuel du serveur.

Le budget est vérifié après chaque page et avant `deleteBan`. Les blocs visuels
d'expulsion, bannissement et débannissement reçoivent également le budget du
handler jusque dans le transport commun ; trois tests avec le handler réel
vérifient qu'une lecture tardive ne peut pas muter après expiration. La sandbox
simule aussi les débannissements avec les contrôles de permission communs,
préserve les données de membre et met à jour les variables de ban. La recherche
par nom exige une fixture `ban_users`, associant ID et nom d'utilisateur.

Cent huit tests couvrent le service et sa frontière avec les blocs ; trente-trois
tests vérifient les signatures natives, arguments opaques, préflight, branches,
boucles, gardes, workflows, erreurs et budget partagé. Quarante-six tests de sandbox
couvrent les effets, permissions, rôles, propriétaire, utilisateur extérieur,
débannissements et propagation vers un bloc natif imbriqué. Le script préfixé de
l'incident est également exécuté nativement avec SDK simulé. La suite complète
shared passe avec 2 277 tests. Les neuf tests Flutter ciblés de validation native
passent après ajout des débannissements ; quinze tests d'éditeur/validation
étaient passés après ajout de kick/ban. Ces résultats ne constituent pas un
essai réel sur Discord. D'autres fonctions de modération restent à migrer.

Les timeouts suivent les signatures
[`$timeout[durée;ID]`](https://wiki.botdesignerdiscord.com/bdscript/timeout.html)
et [`$untimeout[ID]`](https://wiki.botdesignerdiscord.com/bdscript/untimeout.html).
Un ID omis ou vacant vise toutes les mentions, sans repli vers l'auteur ; les
IDs sont validés ensemble avant le premier effet et les doublons sont retirés.
Le natif utilise le parseur de durées BDFD (dont durées composées et fractions)
et refuse les durées nulles, négatives, invalides ou supérieures à 28 jours.
Il ne reprend pas le défaut historique de dix minutes des blocs visuels.

Le service commun pose `communication_disabled_until` et le retire avec un
`null` explicite. Les blocs gardent leurs champs de durée, la date `until`, les
bornes historiques et les raisons par défaut ; le natif ne fournit pas de
raison automatique. Les deux opérations contrôlent la permission Moderate
Members, le propriétaire, la hiérarchie et les administrateurs ciblés, suivant
la [documentation Discord](https://github.com/discord/discord-api-docs/blob/main/developers/resources/guild.mdx).
Le budget du handler est transmis aux blocs de timeout/retrait jusque dans le
transport. Deux tests supplémentaires de handler vérifient le refus de mutation
après une lecture tardive. La sandbox simule les mêmes contrôles et les états de
timeout, conserve les membres et propage son adaptateur aux blocs natifs dans
les workflows visuels. Les neuf tests Flutter de validation native passent
avec ces signatures ajoutées au registre de production.

[`$kickMention[raison]`](https://wiki.botdesignerdiscord.com/bdscript/kickMention.html)
est également natif. Il cible la première mention sans repli vers l'auteur.
Sa raison est obligatoire mais peut être vide. Contrairement à `$kick[ID]`,
il exige la permission Kick Members de l'auteur de la commande ; Administrator
ou le statut de propriétaire du serveur satisfont aussi ce contrôle. Une identité
d'auteur absente est refusée avant le service. Les contrôles du bot, du
propriétaire ciblé et de hiérarchie restent ensuite applicables.

La requête typée porte le marqueur d'auteur `kickPermissionActorId` ; le service
commun lit ses permissions réelles via les rôles du serveur et vérifie le budget
après la lecture. La compilation historique de `$kickMention` transmet aussi ce
marqueur au bloc `kickUser`, qui le résout une fois. Les deux modes de sandbox
contrôlent cette permission via le même service. La fixture de corpus historique,
qui ne donnait pas de permission à l'auteur, est corrigée et exécutée aussi avec
le moteur natif. Six tests de service, trois tests natifs et quatre tests de
sandbox supplémentaires couvrent permissions, propriétaire, identité manquante,
arguments opaques, budget et parité de cette fixture. Les neuf tests Flutter de
validation passent avec `$kickMention` inclus dans le registre de production.

## Branches conditionnelles

Le runtime possède déjà `ifBlock`, `thenActions`, `elseIfConditions` et
`elseActions`. L'éditeur Blueprint représente ces branches. Améliorer ce
système existant est préférable à introduire un deuxième format de graphe.

Priorités :

- Choix explicite d'une seule branche, évaluée dans l'ordre, avec un chemin
  « sinon » facultatif et une continuation commune après la condition.
- Validation avant sauvegarde : opérateur valide, types compatibles, actions
  de branche bien formées et limites de profondeur.
- Trace montrant la valeur évaluée, la branche retenue et les blocs ignorés.
- Tests avec branches imbriquées, variables modifiées, arrêt anticipé et erreur.

Dans le BDFD natif, `$if/$elseif/$else/$endif` devient une structure de l'AST,
sans conversion en `ifBlock`. Reporter un graphe arbitraire avec sauts et cycles
libres jusqu'à disposer d'un besoin concret et de règles de validation.

## Documentation et reproductibilité

`packages/shared/tool/audit_bdfd_docs.dart` compile les blocs `bdfd` de `_docs`
et `_posts` de vitrine et signale aussi les fonctions absentes du catalogue.
Il produit un rapport JSON et un code de sortie non nul si des blocs sont
signalés. Depuis `packages/shared` :

```bash
dart run tool/audit_bdfd_docs.dart /chemin/vers/vitrine > audit.json
```

Le premier passage a vérifié 1 522 blocs et en a signalé 300. Ce résultat
comprend des signatures et fragments contextuels, à distinguer des exemples
complets. Il ne prouve ni les permissions Discord, ni l'ordre des effets, ni
la pertinence des arguments. Les pages de modération sont corrigées en premier.

Prochaine étape : identifier explicitement les blocs « syntaxe », « fragment »
et « exemple exécutable » ; fournir des fixtures de contexte pour les derniers.
Les scénarios partagés doivent alimenter la documentation et les tests du
moteur. L'audit global ne peut pas encore être un contrôle CI bloquant sans
traiter les signalements existants et les signatures indicatives.

## Incident kick

Le script préfixé fourni par l'utilisateur est couvert par
`bdfd_prefix_kick_test.dart`, avec services Discord simulés et deux cibles
différentes alors que l'auteur est propriétaire du serveur. La cible, la raison,
l'absence de mention et le refus de s'expulser sont vérifiés via le handler réel.
L'hydratation réseau est désactivée dans ce test ; un essai Discord reste requis.

L'utilisateur indique que le runner hébergé n'a pas encore été mis à jour.
La même erreur n'est pas reproduite sur le code actuel avec ces fixtures.
Ne pas annoncer sa résolution sur le runner avant mise à jour et essai réel.
Le correctif complémentaire empêche `$kick[]` et `$kick[;raison]` de sélectionner
implicitement l'auteur. La forme sans arguments `$kick` conserve sa sémantique.
Le même script est maintenant testé avec le moteur natif. En l'absence de
mention, `$mentioned[1]` natif utilise le repli officiel vers l'auteur ; le
garde-fou contre l'auto-expulsion arrête toujours le script. La variante
`$mentioned[1;no]` est également testée pour préserver une cible vide et afficher
le message d'utilisation. Cette différence du helper ne doit pas être masquée
par un repli de la fonction `$kick[ID]` elle-même.


### Attribution et retrait de rôles

Le registre natif inclut désormais
[`$giveRole`](https://wiki.botdesignerdiscord.com/bdscript/giveRole.html),
[`$takeRole`](https://wiki.botdesignerdiscord.com/bdscript/takeRole.html) et
[`$roleGrant`](https://wiki.botdesignerdiscord.com/bdscript/roleGrant.html).
Les deux premières fonctions acceptent un rôle seul (tous les utilisateurs
mentionnés, sans repli sur l'auteur) ou un utilisateur et un rôle.
`$roleGrant` exige les préfixes `+` ou `-` et applique les changements dans
l'ordre. Tous les identifiants sont validés avant le premier appel du service.
Une fonction inconnue contenant ces appels reste intégralement opaque.

Ces fonctions transmettent des requêtes typées au service commun de modération,
sans compilation en blocs. Les blocs ordinaires `addRole` et `removeRole`
délèguent au même transport, conservent leurs motifs d'audit par défaut et le
repli historique de `userId` invalide vers `memberId`, et reçoivent le budget
du handler. Les branches de définition des rôles délèguent également au service typé
commun, comme le remplacement `setRoles` des blocs.

Le contrôle commun exige Manage Roles (ou Administrator), un rôle existant
strictement inférieur au rôle maximal du bot, et refuse `@everyone`. Les tags
exposés par Nyxx permettent aussi de refuser les rôles de bot, d'intégration
et de booster. Nyxx ne conserve pas le champ Discord `managed` : Discord reste
l'autorité pour les autres rôles gérés que ces tags ne représentent pas.
La comparaison porte sur le rôle modifié, pas sur le rang du destinataire ;
un propriétaire ou un membre de rang supérieur peut recevoir un rôle inférieur.
Le budget est vérifié après les lectures et immédiatement avant la mutation SDK.

La sandbox partage ce contrôle, exige les fixtures de rôles, membres et bot,
refuse les membres absents, et capture les listes de rôles avant/après sans
appeler Discord. Une fixture `managed: true` est représentée comme un rôle
d'intégration. Les tests couvrent l'ordre des changements, les mentions
dédupliquées, les identifiants invalides, les permissions, les rôles gérés,
la hiérarchie, les destinataires élevés et l'expiration du budget, y compris
au travers du handler de blocs. Le préflight de l'éditeur accepte ces signatures
avec le registre de production. La suite shared passe avec 2 277 tests et les
neuf tests Flutter ciblés de validation native passent ; aucun essai Discord
réel n'a été réalisé pour ces fonctions.


### Création, modification et suppression des rôles

Les signatures ont été vérifiées sur le wiki officiel :
[`$createRole`](https://wiki.botdesignerdiscord.com/bdscript/createRole.html)
prend un nom, une couleur et deux booléens optionnels ;
[`$deleteRole`](https://wiki.botdesignerdiscord.com/bdscript/deleteRole.html)
prend l'ID du rôle ;
[`$modifyRole`](https://wiki.botdesignerdiscord.com/bdscript/modifyRole.html)
prend l'ID puis le nom, la couleur, l'affichage séparé et la mentionnabilité
optionnels, avec `!unchanged` pour préserver un champ ;
[`$modifyRolePerms`](https://wiki.botdesignerdiscord.com/bdscript/modifyRolePerms.html)
bascule chaque permission demandée, y compris sur `@everyone` ;
[`$colorRole`](https://wiki.botdesignerdiscord.com/bdscript/colorRole.html)
modifie la couleur du premier rôle mentionné, sans cible implicite si la liste
explicite est vide. Les fonctions renvoient une chaîne vide ; la création ne
place pas directement l'ID du rôle dans la sortie du script.

Le sixième argument de `$modifyRole`, la position, est une extension historique
du projet, absente de la signature officielle. Il reste accepté explicitement
par le moteur natif. Sa validation précède toute modification et exige une
position non négative inférieure au rôle maximal du bot. La modification de
permissions et des champs de `@everyone` est permise, mais sa suppression et
son déplacement restent refusés. Les booléens natifs acceptent `yes`/`no` ; les
champs vacants restent inchangés en modification et valent `no` à la création.
Les couleurs préfixées de `#` ou contenant des lettres hexadécimales sont
interprétées en hexadécimal ; les couleurs entièrement numériques sans `#`
sont des entiers décimaux, y compris les valeurs à six chiffres.

`RoleDefinition` contient uniquement des champs évalués et une copie immuable
des permissions à basculer. Le moteur, les blocs de définition et la sandbox
partagent ce contrat et les contrôles de rôle. Le transport Discord vérifie le
budget après les lectures de permissions et du rôle, ainsi qu'avant les
mutations ; il ne réessaie pas les appels refusés. Les adaptateurs de blocs
restent responsables de la conversion de leurs anciens payloads, sans
interpréter à nouveau les chaînes résolues. Leur contrat de résultat conserve
`roleId` et `status`.

La sandbox simule les nouvelles définitions dans ses fixtures de rôles, capture
l'état avant/après et retire les attributions de membre lors d'une suppression.
Les identifiants créés sont synthétiques et ne représentent pas des rôles
Discord réels. Le préflight de production et les éditeurs valident les nouvelles
signatures sans exécution ; leurs exemples de fonction encore non migrée ont
été remplacés par `$createChannel`. La suite complète shared passe avec
2 277 tests ; treize tests Flutter de validation native et de blocs passent.
L'analyse ciblée ne signale aucun problème. La migration globale reste active :
D'autres fonctions du catalogue et le retrait du compilateur
historique restent à réaliser, avec vérification finale de tous les points
d'entrée. Aucun essai Discord réel n'a été réalisé pour ces fonctions.


### Remplacement des rôles d'un membre

Le nom officiel est
[`$setUserRoles[User ID;Role ID;...]`](https://wiki.botdesignerdiscord.com/bdscript/setUserRoles.html),
et non `$setRoles` : `setRoles` est uniquement le champ interne du bloc visuel.
Le wiki exige un utilisateur explicite et au moins un rôle. Le registre natif
reprend cette arité, refuse tout ID vide/invalide avant soumission au service,
déduplique les rôles en conservant leur ordre et renvoie une chaîne vide.
Les arguments d'une fonction inconnue contenant cet appel restent opaques.

La requête typée utilise `RoleReplacement`, qui fige une copie de la liste
évaluée. Les blocs `addRole` ayant un payload `setRoles` délèguent désormais au
même transport, avec résolution unique et motif d'audit historique. Ils
conservent leur possibilité de remplacer par une liste vide ; cette possibilité
n'est pas annoncée comme une signature BDFD officielle.

Le contrôle commun exige Manage Roles, un membre existant et des rôles connus.
Il vérifie chaque rôle ajouté ou retiré avant toute mutation : le remplacement
ne peut pas retirer un rôle trop élevé ou géré sous prétexte qu'il ne figure
pas dans la nouvelle liste. `@everyone` ne peut pas être explicitement attribué.
Le rang du destinataire n'est pas assimilé au rang des rôles modifiés. Un rôle
inchangé n'est pas traité comme une nouvelle attribution. Discord reste
l'autorité finale pour les contraintes non exposées par Nyxx, notamment les
rôles gérés non représentés par leurs tags.

Le transport conserve `userId`, les `roleId` séparés par une virgule et
`status: set`. Le budget du handler est transmis et vérifié après les lectures
et avant l'unique mise à jour du membre. La sandbox applique le même contrôle,
capture la liste avant/après et met à jour la variable des rôles du membre,
sans appel SDK d'écriture. Les tests couvrent la signature officielle, les
listes figées/dédupliquées, le remplacement complet, l'effacement par bloc,
les permissions, les IDs et rôles absents, `@everyone`, l'ajout ou retrait d'un
rôle trop élevé/géré et l'expiration au travers du handler réel.

La suite shared passe avec 2 277 tests et les treize tests Flutter ciblés de
validation native et de blocs passent. L'analyse des fichiers modifiés et
`git diff --check` ne signalent aucun problème. La migration globale reste
active : d'autres fonctions du catalogue, la vérification de tous les points
d'entrée et le retrait du compilateur historique restent à réaliser.


### Lecture des rôles

Sept fonctions de lecture utilisent désormais le service typé
`BotRoleQueryService`, indépendant des requêtes de mutation :
[`$roleID`](https://wiki.botdesignerdiscord.com/bdscript/roleID.html),
[`$roleName`](https://wiki.botdesignerdiscord.com/bdscript/roleName.html),
[`$getRoleColor`](https://wiki.botdesignerdiscord.com/bdscript/getRoleColor.html),
[`$isHoisted`](https://wiki.botdesignerdiscord.com/bdscript/isHoisted.html),
[`$isMentionable`](https://wiki.botdesignerdiscord.com/bdscript/isMentionable.html),
[`$roleExists`](https://wiki.botdesignerdiscord.com/bdscript/roleExists.html) et
[`$userRoles`](https://wiki.botdesignerdiscord.com/bdscript/userRoles.html).
Les signatures sont vérifiées sur le wiki officiel : chacune prend un argument ;
`$roleExists` accepte une chaîne vide. Les propriétés booléennes renvoient
`true`/`false`, la couleur renvoie six chiffres hexadécimaux majuscules sans `#`,
et les noms de rôles du membre sont séparés par des retours à la ligne.
L'utilisateur de `$userRoles` est explicite, sans repli sur l'auteur.

Le wiki ne précise pas le comportement de `$roleID` avec un nom absent ou
ambigu. Le projet conserve la règle de son hydratation historique : comparaison
exacte du nom et chaîne vide en l'absence d'un résultat unique. Cette règle de
compatibilité n'est pas présentée comme une garantie documentée du wiki.
`$roleExists` vide, non numérique ou non positif renvoie `false` sans lecture
Discord. Les autres lectures par ID invalide ou absent produisent une erreur
native localisée ; les erreurs de lecture restent récupérables par `$try`.

L'adaptateur SDK crée des snapshots immuables de champs primitifs à partir de
lectures fraîches, avec le budget de commande. L'agrégat Discord déjà transmis
aux commandes, événements et workflows expose ce service de lecture ; le moteur
peut aussi recevoir explicitement `roleQueries` pour un service autonome. La
validation de production enregistre les signatures avec un faux service qui
refuse toute exécution. L'hydratation des blocs par nom partage le même transport
de liste des rôles. Aucun rôle n'est compilé en Action pour les lectures natives.

La sandbox utilise le même adaptateur SDK sur son gateway de fixtures en lecture
seule. Elle n'exige ni permission de modération ni ID de bot pour ces lectures.
Une lecture après création, modification ou remplacement consulte l'état courant
des fixtures. Les noms contenant du BDFD restent des données et ne sont jamais
réinterprétés ; une fonction inconnue englobant une lecture reste opaque.

Dix-sept nouveaux tests couvrent les formats officiels, les erreurs, les valeurs
vides, les ambiguïtés, les budgets, les snapshots immuables, le transport commun
aux blocs, les lectures fraîches après mutation et l'absence de permission
nécessaire. La suite shared passe avec 2 277 tests et les treize tests Flutter
ciblés d'éditeur/validation passent. L'analyse ciblée est sans problème. D'autres requêtes de rôles et le retrait du compilateur historique restent
à réaliser. Aucun essai Discord réel n'a été effectué.


### Appartenance et limites de hiérarchie des rôles

Le registre de lecture inclut également
[`$hasRole[User ID;Role ID]`](https://wiki.botdesignerdiscord.com/bdscript/hasRole.html),
[`$highestRole`](https://wiki.botdesignerdiscord.com/bdscript/highestRole.html),
[`$highestRole[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/highestRoleComplex.html),
[`$lowestRole`](https://wiki.botdesignerdiscord.com/bdscript/lowestRole.html),
[`$lowestRole[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/lowestRoleComplex.html)
et [`$rolePosition[Role ID]`](https://wiki.botdesignerdiscord.com/nightly/bdscript/rolePosition.html).
La page stable de position n'était pas accessible au moment de la vérification ;
la page nightly officielle confirme la convention `1` pour le rôle le plus élevé.
Il s'agit donc d'un rang calculé sur les rôles du serveur, pas de la position
brute renvoyée par Discord.

Sans argument, les limites concernent le serveur. Avec un argument, elles
concernent un membre explicite ; une valeur vide/invalide est refusée et ne
bascule ni vers l'auteur ni vers le serveur. Le rôle implicite `@everyone` est
inclus dans la hiérarchie d'un membre même si la liste SDK de ses rôles ne le
contient pas. `$hasRole` valide l'utilisateur explicite, accepte le rôle vide
comme `false` sans lecture, et renvoie aussi `true` pour le rôle implicite d'un
membre réellement existant.

Les snapshots `BotRole` portent la position brute et l'identité du rôle par
défaut. Le classement commun place `@everyone` en dernier, puis compare les
positions Discord décroissantes et les IDs croissants en cas d'égalité. La règle
est cohérente avec la structure des rôles documentée par
[Discord](https://github.com/discord/discord-api-docs/blob/main/developers/topics/permissions.mdx)
et le comparateur de
[discord.py](https://github.com/Rapptz/discord.py/blob/master/discord/role.py).
Le tri copie la liste au lieu de modifier un snapshot fourni par le service.
L'hydratation historique des limites de serveur utilise le même classement et
le même transport de lecture ; les appels natifs ne créent aucune Action.

Douze tests supplémentaires couvrent les formes serveur/membre, les rangs,
les positions égales, les snapshots préservés, `@everyone`, les arguments vides,
les IDs invalides et la lecture après remplacement dans la sandbox. Le test
Flutter de registre de production inclut ces signatures. Les vingt-neuf tests
de lecture de rôles passent ; la suite shared passe avec 2 277 tests et les
treize tests Flutter ciblés de validation/éditeur passent. L'analyse ciblée et
`git diff --check` ne signalent aucun problème.

La migration globale n'est pas achevée : les autres fonctions du catalogue,
les contrôles et essais de tous les points d'entrée et le retrait du compilateur
historique restent à vérifier/réaliser. Aucun essai Discord réel n'a été effectué.


### Hiérarchie commune des contrôles de modération

Les contrôles de modération et de mutation des rôles utilisent maintenant le
même classement que les lectures : `@everyone` est inférieur aux autres rôles,
la position Discord décide en premier et l'ID départage les positions égales.
Le rôle le plus ancien (ID inférieur) est supérieur en cas d'égalité numérique.
Cette règle est documentée par la
[structure des rôles Discord](https://github.com/discord/discord-api-docs/blob/main/developers/topics/permissions.mdx)
et visible dans le
[comparateur de discord.py](https://github.com/Rapptz/discord.py/blob/master/discord/role.py).

Le contrôle précédent comparait uniquement les positions numériques et
refusait donc certains rôles réellement inférieurs au bot. `checkBotCanModerate`
compare désormais les rangs du rôle maximal du bot et du membre, y compris le
rôle implicite de base. `checkBotCanManageRole` applique le même ordre au rôle
modifié ; `checkBotCanReplaceRoles` l'utilise pour tous les ajouts et retraits.
Un membre partageant exactement le rôle maximal du bot reste interdit ; un
rôle plus ancien à position égale est également interdit. Les contrôles de
permission, propriétaire, administrateur ciblé, rôle géré et budget restent
applicables.

Dix-huit tests supplémentaires du transport SDK couvrent l'acceptation et le
refus aux positions égales pour expulsion, bannissement, timeout/retrait de
timeout, attribution/retrait, édition/suppression et remplacement de rôles.
Deux tests natifs de sandbox couvrent aussi les mutations permises et refusées.
Les anciens cas nommés « rôle égal » ciblent désormais réellement le même rôle
que le bot, plutôt qu'un rôle inférieur partageant sa position numérique.
La fixture canonique de `$kickMention` inclut désormais `@everyone`, pour que
son membre sans rôle explicite représente un état de serveur complet.

La suite shared passe avec 2 277 tests ; l'analyse ciblée et `git diff --check`
ne signalent aucun problème. Aucun appel Discord réel n'a été réalisé. La
migration globale et le retrait du compilateur historique restent à terminer.


### Inventaire et limites de rôles filtrées par permissions

Quatre lectures supplémentaires passent par le service natif commun, sans
compilation en Actions. Les signatures ont été vérifiées sur le wiki officiel :

- [`$roleCount`](https://wiki.botdesignerdiscord.com/bdscript/roleCount.html), sans argument, compte les rôles du serveur courant.
- [`$roleNames`](https://wiki.botdesignerdiscord.com/bdscript/roleNames.html), sans argument, renvoie leurs noms.
- [`$highestRoleWithPerms[Permissions]`](https://wiki.botdesignerdiscord.com/bdscript/highestRoleWithPerms.html), renvoie le rôle supérieur satisfaisant les permissions demandées.
- [`$lowestRoleWithPerms[Permissions;...]`](https://wiki.botdesignerdiscord.com/bdscript/lowestRoleWithPerms.html), accepte plusieurs permissions séparées par des points-virgules et renvoie le rôle inférieur les satisfaisant toutes.

Le moteur accepte également plusieurs arguments pour la limite supérieure,
comme le projet historique : cette forme est une extension du projet, car la
page officielle consultée ne présente qu'un argument. Pour `$roleNames`, les
virgules et l'ordre de lecture du service conservent le comportement du projet ;
le wiki ne précise ni séparateur ni ordre. Ces détails ne constituent donc pas
une garantie de conformité BDFD issue de cette page.

Les snapshots transportent les permissions du rôle. Le filtrage exige tous
les flags demandés, avec la convention Discord selon laquelle administrateur
satisfait toutes les permissions. Les limites utilisent le classement commun,
y compris `@everyone` et les positions égales. Les permissions invalides sont
refusées avant toute lecture. Une liste sans résultat produit une chaîne vide.
Les lectures reflètent les mutations précédentes ; les fonctions inconnues
restent opaques, même lorsqu'elles contiennent ces nouvelles fonctions.

Dix tests supplémentaires couvrent ces comportements, dont la lecture après
modification des permissions et le classement du chemin historique. Les
trente-neuf tests de lectures de rôles passent. La suite shared complète passe
avec 2 287 tests, les treize tests Flutter ciblés de validation/éditeur passent,
et l'analyse ciblée ainsi que `git diff --check` ne signalent aucun problème.
La migration globale reste en cours ; aucun essai Discord réel n'a été réalisé.


### Permissions d'un rôle dans un serveur explicite

Le moteur natif prend désormais en charge
[`$rolePerms[Guild ID;Role ID;(Separator)]`](https://wiki.botdesignerdiscord.com/bdscript/rolePerms.html).
Le serveur et le rôle sont obligatoires ; le séparateur par défaut est une
virgule. La sortie reproduit l'exemple officiel
`CreateInvite# KickMembers# BanMembers# ManageChannels` et `No Permissions`
pour un rôle sans permissions.

Le service de lecture accepte maintenant un serveur explicite, sans remplacer
le contexte courant. L'adaptateur SDK, l'agrégat de modération, la validation
sans effets et la sandbox propagent ce choix. La lecture peut ainsi fonctionner
sans serveur courant, et un ID de rôle identique dans deux fixtures ne provoque
pas une lecture du mauvais serveur. Les deux IDs sont validés avant la lecture,
le budget parent reste partagé et un rôle absent provoque une erreur native.
Le résultat reste du texte ; un séparateur contenant une fonction inconnue
n'entraîne aucune évaluation de ses arguments ni réinterprétation du résultat.

Le formateur affiche les flags stockés, sans expansion d'Administrator ni
héritage d'@everyone. Il couvre les flags du SDK installé, par ordre de bit.
Les libellés extérieurs à l'exemple officiel suivent les noms du SDK et ne sont
pas vérifiés contre BDFD : le wiki ne fournit pas leur tableau exhaustif.
La non-expansion d'Administrator et l'ordre des autres flags restent également
à confirmer contre le comportement BDFD réel. Cette étape ne prétend donc pas
prouver une conformité exhaustive des noms de sortie.

Les indications de signature de l'éditeur correspondent maintenant aux trois
arguments officiels. Le chemin historique conserve encore sa forme à un seul
argument et son masque numérique ; son remplacement fait partie du travail
restant avant le retrait du compilateur historique.

Sept tests supplémentaires couvrent l'exemple officiel, le séparateur par
défaut, les arguments invalides, les rôles absents, les sorties opaques, les
lectures SDK/sandbox d'un autre serveur, les flags récents et la lecture après
mutation. Les quarante-six tests ciblés de lectures de rôles passent, ainsi que
les 2 294 tests shared et les treize tests Flutter ciblés de validation/éditeur.
L'analyse ciblée et `git diff --check` ne signalent aucun problème. Aucun essai
Discord réel n'a été effectué ; la migration globale reste en cours.


### Lectures natives de salons

Six fonctions utilisent maintenant un service de lecture de salons indépendant
des Actions et du parseur. Les signatures ont été vérifiées sur le wiki officiel :

- [`$channelName[Channel ID]`](https://wiki.botdesignerdiscord.com/bdscript/channelName.html) : ID obligatoire, nom du salon.
- [`$channelType[Channel ID]`](https://wiki.botdesignerdiscord.com/bdscript/channelType.html) : ID obligatoire, libellés BDFD dont `announcement` et `thread`.
- [`$channelExists[Channel ID]`](https://wiki.botdesignerdiscord.com/bdscript/channelExists.html) : argument emptiable, recherche dans tous les serveurs accessibles au bot.
- [`$channelNames[Separator;(Guild ID)]`](https://wiki.botdesignerdiscord.com/bdscript/channelNames.html) : séparateur obligatoire mais emptiable, serveur courant par défaut.
- [`$isNSFW[Channel ID]`](https://wiki.botdesignerdiscord.com/bdscript/isNSFW.html) : ID obligatoire, booléen en minuscules.
- [`$channelTopic`](https://wiki.botdesignerdiscord.com/bdscript/channelTopic.html) : sans argument, sujet du salon courant.

L'ancien raccourci natif `$channelName` sans argument n'est plus enregistré :
il ne correspondait pas à la signature officielle. Les indications de l'éditeur
reflètent les signatures officielles ; le chemin historique conserve encore
ses formes optionnelles jusqu'à sa migration/retraite.

`BotChannelQueryService` renvoie des snapshots primitives immuables. Le SDK
lit un salon directement par ID, et une liste par serveur explicite ou courant.
L'agrégat Discord déjà injecté aux points d'entrée, la validation sans effets et
la sandbox exposent le service ; une injection autonome `channelQueries` est
également possible dans `BdfdEngine`. Les lectures de listes de l'hydratation
visuelle partagent le transport `readDiscordChannels`. Le moteur natif ne passe
jamais par des Actions ni par la substitution des templates.

Les valeurs non numériques, vides ou non positives de `$channelExists` donnent
`false` sans lecture. Seul un salon réellement absent (fixture typée ou Discord
404/10003) donne `false` après une lecture ; les refus d'accès, autres 404 et
pannes réseau restent des erreurs. Les fonctions de champ refusent les IDs
invalides et les salons absents. Le sujet lit l'ID courant, sans repli vers un
autre salon. Les lectures partagent le budget parent et les résultats restent
opaques, y compris les noms et séparateurs contenant des fonctions inconnues.

Les types Discord sont interprétés selon la
[structure officielle](https://github.com/discord/discord-api-docs/blob/main/developers/resources/channel.mdx)
et les libellés BDFD du wiki. Les salons d'annonce donnent `announcement`,
les trois types de thread donnent `thread` ; le type media donne `media`,
extension dont le wiki BDFD consulté ne décrit pas le libellé. Les DMs donnent
`dm` ; le nom synthétique `DM` conserve une convention locale qui reste à
confirmer contre BDFD. Le wiki ne précise pas l'ordre de `$channelNames` :
l'ordre de la réponse SDK est préservé.

Vingt et un tests couvrent signatures, budgets, sorties opaques, séparateurs
vides, autres serveurs, erreurs réseau/permission, types SDK, snapshots et
sandbox sans permissions de modération. Les fixtures actuelles de salons de
la sandbox représentent les salons textuels et catégories ; les autres types
sont vérifiés dans les tests du transport avec doubles SDK. La suite shared
passe avec 2 315 tests et les treize tests Flutter ciblés de validation/éditeur
passent. L'analyse ciblée et `git diff --check` ne signalent aucun problème.

Le comptage des salons et des posts de forum actifs est décrit dans la
section suivante ; il utilise une lecture distincte des threads actifs.
La migration globale, les autres types de fixtures et le retrait du compilateur
historique restent en cours. Aucun essai Discord réel n'a été effectué.


### Comptage des salons et catégories

[`$channelCount`](https://wiki.botdesignerdiscord.com/bdscript/channelCount.html)
est enregistré sans argument dans le moteur natif. Il utilise le serveur du
service de lecture courant et compte les salons et catégories, puis les posts
actifs rattachés aux forums. Le wiki indique explicitement les posts de forum ;
l'exclusion des threads ordinaires suit cette lecture littérale et reste à
confirmer contre BDFD réel. Le comptage déduplique les IDs et ignore les threads
archivés et ceux dont le parent n'est pas un forum de la liste lue.

La page stable de `$categoryCount` n'était pas accessible lors de la vérification.
Les deux pages officielles nightly confirment
[`$categoryCount`](https://wiki.botdesignerdiscord.com/nightly/bdscript/categoryCount.html)
pour le serveur courant et
[`$categoryCount[Guild ID]`](https://wiki.botdesignerdiscord.com/nightly/bdscript/categoryCountComplex.html)
pour un serveur explicite. Le moteur compte les catégories de la liste fraîche ;
un argument vide/invalide n'est pas remplacé par le serveur courant.

Le service commun `BotChannelQueryService.countChannels` applique le budget
parent autour des deux lectures SDK. La
[documentation Discord](https://github.com/discord/discord-api-docs/blob/main/developers/resources/guild.mdx)
confirme que la liste des salons exclut les threads et que la route des threads
actifs les fournit séparément. Un serveur sans forum ne nécessite pas cette
seconde lecture. Une erreur de lecture des threads ne produit aucun compte
partiel. Après expiration du budget, la seconde lecture reste interdite même
si la première requête se termine plus tard.

La sandbox construit désormais de vrais `ForumChannel` SDK depuis les fixtures,
y compris leurs sujets et leur état NSFW. Les fixtures `guilds.<ID>.threads`
fournissent la liste des threads avec ID, parent et état archived ; leur lecture
est isolée de toute écriture ou réseau. Pour un serveur avec forum, une fixture
threads manquante est une erreur explicite. Les autres opérations de ces doubles
restent interdites. La validation et les agrégats de production propagent la
nouvelle capacité sans compilation en Actions.

Huit tests supplémentaires couvrent signatures, catégories entre serveurs,
posts actifs/archivés, doublons, lectures fraîches, données manquantes, absence
de forum, sujet de forum dans la sandbox et expiration entre les deux lectures.
Les vingt-neuf tests ciblés de lectures de salons passent, ainsi que les 2 323
tests shared et les treize tests Flutter ciblés de validation/éditeur. L'analyse
ciblée et `git diff --check` ne signalent aucun problème. Les anciens chemins
historiques de comptage restent à remplacer avant le retrait du compilateur.
La migration globale reste en cours ; aucun essai Discord réel n'a été effectué.


### Recherche de salons, catégories et relations parentales

Les lectures natives prennent désormais en charge les formes officielles de
[`$channelID`](https://wiki.botdesignerdiscord.com/bdscript/channelID.html),
[`$channelID[Channel name]`](https://wiki.botdesignerdiscord.com/bdscript/channelIDComplex.html),
[`$findChannel[Channel]`](https://wiki.botdesignerdiscord.com/bdscript/findChannel.html),
[`$categoryID[Category name]`](https://wiki.botdesignerdiscord.com/bdscript/categoryID.html),
[`$parentID`](https://wiki.botdesignerdiscord.com/bdscript/parentID.html) et
[`$parentID[Channel ID]`](https://wiki.botdesignerdiscord.com/bdscript/parentIDComplex.html).
Toutes ces pages du wiki officiel ont été consultées avant l'ajout.

Sans argument, `$channelID` lit l'ID courant et renvoie `none` en DM, comme indiqué
par le wiki. Les points d'entrée identifient les DMs par le type du salon ou par
un ID de serveur explicitement vide. Un contexte de test incomplet sans
métadonnées de serveur conserve l'ID de salon fourni. Le même comportement
s'applique avec ou sans adaptateur de lecture de salons.

La forme par nom de `$channelID` accepte également les catégories. `$categoryID`
filtre exclusivement les catégories. Un nom vide est refusé et ne replie pas
sur le salon courant. Les comparaisons exactes et le premier résultat dans
l'ordre du SDK conservent une convention locale ; le wiki ne précise pas la
casse, les doublons ni le résultat en absence de correspondance. Le moteur
renvoie une chaîne vide lorsqu'aucun nom ne correspond.

`$findChannel` accepte les noms, IDs et mentions `<#ID>`, en limitant la recherche
à l'inventaire du serveur courant. Il ne consulte pas directement un ID dans
un autre serveur. Une requête vide ne lit rien et renvoie une chaîne vide, comme
le chemin historique. Les noms sont comparés sans distinction de casse, avec
priorité à l'égalité ; une recherche partielle suit ensuite, pour conserver le
comportement historique. Le wiki ne documente pas cette recherche partielle ni
la casse : ces détails sont des conventions du projet à confirmer contre BDFD.

Les snapshots `BotChannel` portent maintenant les IDs du serveur et du parent.
`$parentID` lit le salon courant ou un ID explicite, et renvoie une chaîne vide
si aucun parent n'est défini, comme documenté. Un argument vide/invalide n'est
pas remplacé par le salon courant. Pour les threads, le parent SDK est le salon
porteur ; ce cas conserve la relation Discord et reste à confirmer contre la
formulation BDFD en termes de catégorie.

Les recherches par nom/ID/mention lisent aussi les threads actifs via l'option
`includeActiveThreads` du service commun. Les listes de noms classiques et les
lectures de catégories conservent leur inventaire de salons REST. Les deux
lectures de recherche partagent le budget parent, dédupliquent les IDs et
ignorent les threads archivés. Les agrégats et la validation transmettent
l'option ; la sandbox fournit des snapshots de threads nommés et permet leur
lecture par ID, sans opération d'écriture ni réseau.

Huit tests supplémentaires couvrent DM, formes par nom, distinctions de
catégorie, mentions, limitation au serveur courant, priorités de recherche,
parents vides/explicites, threads actifs/archivés, sorties opaques et sandbox.
Les trente-sept tests ciblés de salons passent, ainsi que les 2 331 tests shared
et les treize tests Flutter ciblés de validation/éditeur. L'analyse ciblée et
`git diff --check` ne signalent aucun problème. Les autres fonctions du
catalogue et les chemins historiques restent à migrer.
La migration globale reste en cours ; aucun essai Discord réel n'a été effectué.


### Listes des salons d'une catégorie et positions

[`$categoryChannels[Category ID;Separator;(Option)]`](https://wiki.botdesignerdiscord.com/bdscript/categoryChannels.html)
utilise désormais le service natif de lecture. Les deux premiers arguments sont
obligatoires, avec séparateur emptiable. L'option par défaut est `name` ; les
quatre options officielles `name`, `id`, `mention` et `count` sont prises en charge.
Le compte renvoie un nombre unique, sans utiliser le séparateur.

Les IDs et options invalides sont refusés avant toute lecture. Un salon absent
ou qui n'est pas une catégorie ne déclenche pas de lecture de liste. Le serveur
propriétaire de la catégorie est lu dans son snapshot ; la liste est ensuite
lue dans ce serveur, même si le contexte courant désigne un autre serveur.
Le wiki ne restreint pas explicitement la fonction au serveur courant ; cette
lecture par serveur propriétaire est une interprétation du contrat à confirmer
contre BDFD réel. Les lectures suivent le budget parent, et les refus d'accès
restent des erreurs.

Les enfants directs sont filtrés par ID de parent, sans inclure les catégories
ni les posts de forum sous-jacents. Leur ordre est celui du service. Une catégorie
vide produit une chaîne vide pour les listes et `0` pour le compte. Les noms et
séparateurs contenant des appels inconnus restent du texte opaque.

Les deux formes de position ont aussi été vérifiées sur le wiki officiel :
[`$channelPosition`](https://wiki.botdesignerdiscord.com/bdscript/channelPosition.html)
concerne le salon courant et
[`$channelPosition[Channel ID]`](https://wiki.botdesignerdiscord.com/bdscript/channelPositionComplex.html)
un salon explicite. Le DTO porte désormais la position SDK ; elle est renvoyée
sans recalcul de rang ni décalage, en cohérence avec le chemin historique.
Le wiki ne détaille pas cette convention numérique ; sa fidélité à BDFD réel
reste à confirmer. Un snapshot sans position produit une chaîne vide, et un
argument ID vide/invalide ne se replie pas sur le salon courant.

Huit tests supplémentaires couvrent options, listes et comptes vides, IDs
invalides, mauvais types de salons, texte opaque, budgets partagés, positions,
lecture d'une catégorie d'un autre serveur par le SDK et la sandbox, ainsi que
la validation sans effets. Les quarante-cinq tests ciblés de salons passent,
ainsi que les 2 339 tests shared et les treize tests Flutter ciblés de validation
et d'éditeur. L'analyse ciblée et `git diff --check` ne signalent aucun problème.
La migration globale et le retrait des chemins historiques restent en cours ;
aucun essai Discord réel n'a été effectué.


### Slowmode et existence d'un salon du serveur courant

La page stable de `$getSlowmode` n'était pas accessible lors de la vérification.
La page officielle
[nightly](https://wiki.botdesignerdiscord.com/nightly/bdscript/getSlowmode.html)
confirme `$getSlowmode[(Channel ID)]` et une sortie en secondes. Le moteur natif
lit le salon courant sans argument ou un salon explicite avec un argument.
Un ID explicitement vide/invalide ne se replie pas sur le salon courant.

`BotChannel.slowmodeSeconds` est alimenté depuis `rateLimitPerUser` pour les
salons textuels, forums et threads ; une valeur absente donne `0`. Les fixtures
de forum et de thread portent aussi cette valeur et restent en lecture seule.
La lecture SDK produit de nouveaux snapshots et reflète un changement de
fixture au prochain appel, sans remplacer l'ID du salon courant.

[`$serverChannelExists[Channel]`](https://wiki.botdesignerdiscord.com/bdscript/serverChannelExists.html)
utilise un seul argument, nom ou ID, dans l'inventaire du serveur courant,
y compris ses threads actifs. Un argument vide renvoie `false` sans lecture.
Les refus d'accès ou pannes restent des erreurs, sans réessai automatique.
Les noms sont comparés exactement et sans interprétation de jokers ; le wiki
ne documente pas la casse des noms ni les jokers. Les mentions ne sont pas
interprétées par cette fonction ; `$findChannel` les prend en charge.
Les jokers et le second argument de serveur présents dans le chemin historique
ne sont pas repris comme des signatures officielles natives.

Six tests supplémentaires couvrent secondes, salon courant/explicite, IDs
invalides, noms et IDs limités au serveur, absence de jokers et d'argument de
serveur supplémentaire, SDK/forums/threads, lecture fraîche, sandbox et sorties
opaques. Les cinquante et un tests ciblés de salons passent, ainsi que les
2 345 tests shared et les treize tests Flutter ciblés de validation/éditeur.
L'analyse ciblée et `git diff --check` ne signalent aucun problème.

### Audit reproductible du registre natif

`packages/shared/tool/audit_bdfd_native_registry.dart` compare le registre de
validation de production avec `allBdfdFunctions`, sans appeler les services.
Depuis `packages/shared`, le rapport peut être régénéré avec :

```sh
dart run tool/audit_bdfd_native_registry.dart > ../../docs/architecture/bdfd-native-registry-audit.json
```

Le snapshot courant est enregistré dans
[`bdfd-native-registry-audit.json`](bdfd-native-registry-audit.json).
Le catalogue du projet contient 554 noms : 270 sont enregistrés dans le moteur
natif et 284 ne le sont pas encore. Le registre contient aussi cinq noms absents
du catalogue (`break`, `continue`, `endwhile`, `httphead`, `while`), soit 275 noms
au total. Les constructions structurelles sont incluses dans ces nombres.

Ce rapport vérifie exclusivement l'enregistrement. Il ne prouve pas les
signatures, la conformité comportementale à BDFD ni l'exécution sur chacun des
points d'entrée. Il donne une liste concrète du travail restant et doit être
régénéré après les ajouts au registre. La migration globale, les chemins
historiques et leur retrait restent en cours. Aucun essai Discord réel n'a été
effectué.


### Première mutation native de salon : slowmode

[`$slowmode[Channel ID;Slowmode time]`](https://wiki.botdesignerdiscord.com/bdscript/slowmode.html)
est enregistré avec ses deux arguments obligatoires, dans l'ordre officiel.
Le wiki confirme les secondes sans unité, les durées avec unité, `0`/`0s` pour
désactiver, le maximum de six heures et la permission `managechannels`.
Le moteur évalue les arguments une fois, refuse les IDs vides/invalides et les
durées invalides ou supérieures à six heures, puis envoie une requête typée
`SlowmodeChange` au service commun. Il ne produit ni Action ni réponse textuelle.
Le parseur de durée commun conserve les extensions de durée du projet ; la
conversion SDK s'effectue en secondes entières, comme dans le bloc historique.

`BotChannelMutationService` est indépendant des lectures et peut être injecté
seul dans `BdfdEngine`. L'agrégat Discord et la validation de production
l'implémentent ; la validation interdit les appels effectifs. La bibliothèque
native n'est pas enregistrée lorsqu'aucun adaptateur de mutation n'est fourni.
Les fonctions inconnues encapsulant `$slowmode` restent entièrement opaques.

Le transport Discord lit le salon ciblé et vérifie les permissions dans son
serveur propriétaire, plutôt que dans le serveur du contexte courant. Il
accepte salons textuels, salons d'annonce, forums et threads, et refuse les
autres types. Les builders SDK transmettent uniquement le nouveau slowmode.
Le builder d'annonce du SDK installé ne possède pas ce champ ; le builder
textuel est utilisé pour ce PATCH, sans envoyer de changement de type.
Un test vérifie exactement le payload de ce cas.

Le garde commun calcule maintenant les permissions effectives du salon :
permissions de serveur, overwrite `@everyone`, overwrites combinés des rôles,
puis overwrite du membre. Une autorisation de rôle prime un refus d'un autre
rôle, quelle que soit leur position ; le membre reste prioritaire. Propriétaire
et administrateur contournent les overwrites. `View Channel` est aussi exigé.
Les threads utilisent les overwrites de leur parent ; les catégories ne sont
pas consultées pour les enfants désynchronisés. Ce calcul suit la
[documentation Discord officielle](https://github.com/discord/discord-api-docs/blob/main/developers/topics/permissions.mdx).
Il couvre les besoins de cette mutation, pas toutes les permissions implicites
possibles des futures opérations de messages ou de salons vocaux.

Pour les threads, `Manage Threads` est exigé en plus du `managechannels` indiqué
par le wiki BDFD. Un thread archivé est refusé sans tentative de désarchivage :
le PATCH envoyé ne modifie que le slowmode. Ces contraintes viennent de la
[documentation du PATCH Discord](https://github.com/discord/discord-api-docs/blob/main/developers/resources/channel.mdx#json-params-thread).
Leur fidélité exacte à BDFD sur les threads reste à confirmer sur un bot réel.

Le budget parent est vérifié entre les lectures de salon/serveur/membre et juste
avant la mutation. `checkBotGuildPermission` accepte désormais un budget
facultatif et vérifie celui-ci avant/après ses lectures. Une expiration après
une lecture tardive empêche toute écriture ultérieure ; une erreur SDK n'est
jamais réessayée automatiquement.

Le bloc visuel `slowmodeAction` ne contient plus de mutations SDK : il résout
son payload une fois et délègue au même service. Son exécuteur transmet le budget
de `handleActions`. La raison d'audit auparavant résolue puis ignorée est
transmise au SDK. Les résultats historiques channelId/duration sont conservés.
La sandbox native simule la mutation après le même garde de salon et met à
jour la fixture pour que `$getSlowmode` voie immédiatement la nouvelle valeur.
Le chemin de simulation historique par interception d'Action reste à réconcilier.

Onze tests supplémentaires couvrent ordre des arguments, unités, bornes,
désactivation, arguments invalides, wrappers opaques, injection de capacités,
SDK/types/builders, mauvais serveur de permission, expiration avant écriture,
absence de réessai, payload visuel résolu une fois, audit et sandbox avec refus
de permission et lectures fraîches. Les 2 356 tests shared et les treize tests
Flutter ciblés de validation/éditeur passent. L'analyse ciblée et
`git diff --check` ne signalent aucun problème. L'audit régénéré compte 185 noms
du catalogue enregistrés et 369 non enregistrés. La migration globale reste en
cours ; aucun appel Discord réel n'a été effectué.


### Dérogations de permission des salons

Les fixtures de salons textuels, catégories et forums acceptent désormais
`permission_overwrites`, avec ID, type rôle/membre et masques `allow`/`deny`.
Les types ou masques invalides échouent avant toute mutation. Le gateway de
permission de la sandbox expose les lectures de salons nécessaires aux parents
des threads ; ses écritures restent interdites.

Quinze tests supplémentaires couvrent les grants uniquement locaux, les refus
`@everyone`, les priorités entre rôles et membre, les overwrites non concernés,
le refus de visibilité, les contournements administrateur/propriétaire,
l'héritage des threads, `Manage Threads`, les threads archivés, les enfants
désynchronisés et les fixtures invalides. Les cas de permission et les refus
de thread comparent le transport SDK simulé et la sandbox native, et vérifient
l'absence d'écriture ou d'effet en cas de refus.

Validation de cette étape : les 26 tests ciblés de mutation de salon, les
2 371 tests shared et les treize tests Flutter de validation/éditeur passent.
L'analyse ciblée ne signale aucun problème et `git diff --check` est propre.
Le registre reste à 185 noms du catalogue implémentés et 369 non enregistrés ;
la migration globale reste en cours. Aucun appel Discord réel n'a été effectué.


### Suppressions natives de salons

Les signatures ont été vérifiées sur le wiki BDFD officiel :
[`$deleteChannels[Channel IDs;...]`](https://wiki.botdesignerdiscord.com/bdscript/deleteChannels.html)
et [`$deleteChannelsByName[Channel name;...]`](https://wiki.botdesignerdiscord.com/bdscript/deleteChannelsByName.html).
Au moins un argument non vide est requis. Les IDs sont validés avant la première
suppression ; les arguments sont évalués une fois et les cibles dédupliquées.
La recherche par nom passe par le service de lecture du serveur courant et
supprime tous les doublons exacts. Le wiki ne précise ni la casse, ni le serveur
recherché, ni le cas sans correspondance : comparaison exacte, inventaire REST
sans threads, et erreur si aucun nom ne correspond conservent les conventions
historiques du projet, sans prétendre être confirmés par BDFD réel.

Chaque cible produit une requête typée `ChannelDeletion` au service commun.
Le transport lit le salon, calcule les permissions dans son serveur propriétaire
et transmet un unique DELETE au SDK. Les DMs sont refusés. Les threads exigent
également `Manage Threads` ; ils peuvent être supprimés lorsqu'ils sont archivés.
Le budget parent est vérifié entre les lectures et avant chaque écriture. Les
erreurs restent bloquantes et ne déclenchent ni réessai ni repli vers les blocs.
Les suppressions d'un lot sont séquentielles : un refus tardif laisse les effets
précédents réalisés et visibles dans la trace, sans rollback fictif.

L'agrégat Discord, le moteur de validation et la sandbox exposent cette capacité.
`deleteChannelsByName` exige aussi un service de lecture lors du preflight.
Une fonction inconnue englobant ces appels reste entièrement opaque.
Le wrapper visuel `removeChannel` délègue au même service, conserve son résultat
et propage l'expiration. L'exécuteur transmet le budget et ne bloque plus sur
les permissions du serveur courant avant le contrôle du salon effectivement ciblé.

La sandbox native retire les lignes des fixtures et conserve les effets déjà
réalisés en cas d'erreur. Une catégorie supprimée laisse ses enfants sans parent ;
une suppression de salon retire ses threads de la fixture. Les lectures natives
suivantes reflètent la suppression. Les restrictions particulières de serveurs
Community ne sont pas simulées ; le transport propage le refus de Discord.
L'interception historique d'Actions de la sandbox reste distincte et à réconcilier.
Aucune suppression Discord réelle n'a été effectuée.

Douze tests supplémentaires vérifient validation avant lecture/écriture,
déduplication, injection des capacités, noms exacts et doublons, permission du
serveur ciblé, threads archivés, expiration, absence de réessai, délégation
visuelle, refus sans effets, suppression de catégorie et lectures fraîches.
Les 38 tests ciblés de mutation de salon, les 2 383 tests shared et les treize
tests Flutter de validation/éditeur passent. L'analyse ciblée et
`git diff --check` sont propres. L'audit régénéré compte 187 noms du catalogue
enregistrés, 367 non enregistrés et cinq extensions hors catalogue, soit 192
noms au registre. La migration globale et le retrait du backend historique
restent en cours.


### Modification native de salons

[`$modifyChannel[Channel ID;(Channel Name;Topic;Make NSFW?;Position;Category ID)]`](https://wiki.botdesignerdiscord.com/bdscript/modifyChannel.html)
a été vérifié sur le wiki officiel, ainsi que le sens de
[`Vacantable`](https://wiki.botdesignerdiscord.com/nightly/guides/other/arguments.html).
L'ID est obligatoire ; les cinq autres arguments peuvent être omis ou vides.
`!unchanged` conserve un champ. L'évaluation des arguments est unique et le
moteur transmet un `ChannelModification` au service commun, sans Action.
Les booléens acceptent `yes/no` et `true/false`. La position BDFD positive est
convertie en position SDK à partir de zéro, puisque le wiki indique `1 = top`.
La fidélité du classement final dans les catégories/types de salons reste à
confirmer contre Discord/BDFD réel.

Un sujet explicitement vide est transmis comme une chaîne vide pour le vider ;
un sujet omis ou `!unchanged` reste intact. Les autres champs vides restent
inchangés. Le wiki n'explicite pas les valeurs par défaut de chaque argument
vide : cette interprétation du sujet est signalée comme non confirmée par BDFD
réel. Le wrapper des blocs conserve sa convention historique selon laquelle
un sujet vide n'est pas une demande de suppression. Une modification sans champ
valide le salon et ses permissions puis ne produit aucun PATCH ni effet simulé.

`prepareChannelUpdate` partage les validations, les permissions effectives,
la lecture de la catégorie et le builder entre le transport et la sandbox.
La catégorie doit appartenir au serveur du salon ciblé. Les noms, positions,
slowmodes et durées d'archive sont validés ; les sujets ont la limite Discord
appropriée au salon texte ou forum. Les champs incompatibles avec le type sont
refusés avant écriture. Ces limites suivent la
[documentation du PATCH Discord](https://github.com/discord/discord-api-docs/blob/main/developers/resources/channel.mdx#modify-channel).
Les threads utilisent `Manage Threads` en plus du garde BDFD `Manage Channels` ;
un thread archivé ne peut être modifié sans demande explicite de désarchivage.
Les modifications des salons vocaux/stage exigent aussi `Connect`.

Les builders du SDK installé expriment certains champs absents comme `null`,
ce qui signifierait les effacer. Le builder final omet ces valeurs et conserve
les chaînes vides, `false` et zéro explicitement demandés. Le SDK n'expose pas
le slowmode des salons vocaux/stage dans leurs builders : ce champ API est
ajouté au payload final sans changer le type de salon. Les modifications de
salons d'annonce utilisent le builder textuel sans champ `type`. Aucun sujet de
stage ni slowmode d'annonce n'est accepté dans ce service de modification,
conformément aux types indiqués dans le PATCH consulté.

`updateChannelAction` résout son payload une fois et délègue ; il conserve ses
résultats historiques, la conversion des durées et l'arrondi des durées d'archive
vers les valeurs admises. Le budget parent est transmis et une expiration est
propagée, sans écriture après une lecture tardive. La raison d'audit est aussi
transmise. L'exécuteur ne contrôle plus le serveur courant avant le vrai salon.
Les erreurs de champs autrefois ignorés deviennent des refus explicites.

La sandbox native applique le même payload validé aux fixtures et les lectures
suivantes voient immédiatement le nouveau nom, sujet, NSFW, parent ou slowmode.
Ses fixtures n'exposent pas encore les modèles voice/stage/announcement ; ces
cas restent refusés localement et sont testés au niveau du transport SDK simulé.
L'interception historique d'Actions de modification reste à réconcilier.
Treize nouveaux tests couvrent signature et sentinelles, champs absents/vides,
positions, catégories étrangères, limites, types, thread archivé, champs SDK
manquants, permissions, budget, absence de réessai, wrapper et lectures fraîches.
Aucune modification Discord réelle n'a été effectuée.

Validation de cette étape : les 51 tests ciblés de mutation de salon, les
2 396 tests shared et les treize tests Flutter de validation/éditeur passent.
L'analyse ciblée et `git diff --check` sont propres. Le registre régénéré compte
188 noms du catalogue enregistrés et 366 non enregistrés, soit 193 noms avec
les cinq extensions. La migration globale reste en cours.


### Création native de salons

[`$createChannel[Name;Type;(Category ID)]`](https://wiki.botdesignerdiscord.com/bdscript/createChannel.html)
a été vérifié sur le wiki officiel. Nom et type sont obligatoires ; la catégorie
est facultative mais ne peut être vide lorsqu'elle est présente. Les types
natifs sont `category`, `text`, `voice`, `stage` et `forum`, avec comparaison
insensible à la casse. Le nom est limité à 100 caractères. La création requiert
un serveur dans le contexte. Le moteur ne produit pas de texte ; un ID peut être
relu avec `$channelID[nom]`, comme dans l'exemple du wiki. Le wiki ne décrit pas
explicitement un retour de la fonction : ce choix de sortie n'est pas une
preuve d'exécution contre BDFD réel. Le compilateur historique conserve son
extension de retour d'ID, notamment utilisée par ses tickets.

`ChannelCreation` porte le serveur, le nom, le type et les options métier.
`prepareChannelCreation` est partagé entre production et sandbox : validation
avant lecture/écriture, permission `Manage Channels` au niveau du serveur et
vérification que le parent est une catégorie du même serveur. Un overwrite de
catégorie ne remplace pas la permission de création du serveur. Le garde de
serveur reconnaît désormais aussi le propriétaire, comme le garde de salon.
Les services de validation refusent l'exécution, et les fonctions inconnues
contenant une création restent entièrement opaques.

Le transport réalise un unique POST via `GuildManager.createGuildChannel`,
avec le budget parent vérifié avant et après les lectures, puis avant/après la
création. Une expiration avant écriture la bloque ; un refus SDK n'est jamais
réessayé. Les options parent, sujet, NSFW et slowmode sont intégrées au POST :
le wrapper visuel ne crée plus un salon partiellement configuré avant un PATCH
séparé. La raison d'audit est transmise. Les résultats historiques des wrappers
restent des IDs ; les tickets conservent leur pipeline et leurs actions annexes.

Les wrappers conservent les types supplémentaires historiques (`announcement`)
et la sélection de `text` pour un type visuel inconnu. Les champs incompatibles
avec un type sont omis par ce wrapper, comme auparavant ; une requête typée
incorrecte est refusée. Le service utilise la limite de sujet forum de 4096
indiquée par les modèles SDK et le PATCH Discord ; le tableau du POST consulté
indique 1024 sans exception forum. Cette différence reste à confirmer sur une
création Discord réelle. Les autres contraintes suivent la
[documentation de création Discord](https://github.com/discord/discord-api-docs/blob/main/developers/resources/guild.mdx#create-guild-channel).

La sandbox native attribue des IDs déterministes sans collision avec les
salons/threads des fixtures, applique la limite de 500 salons du wiki et ajoute
les options à la fixture. Les overwrites du parent sont copiés pour simuler la
synchronisation initiale ; ce comportement de création n'est pas confirmé par
un essai BDFD réel. Les fixtures exposent désormais les modèles SDK voice,
stage et announcement, ce qui résout la limite de types de la précédente étape.
Les lectures natives voient immédiatement le salon créé. Les contraintes des
serveurs Community et les normalisations de noms effectuées par Discord ne
sont pas simulées. L'interception historique d'Actions reste à réconcilier.

Quatorze nouveaux tests couvrent signature, types officiels, arguments invalides,
absence de contexte serveur, opacité, injection de capacités, limite du nom,
catégorie invalide/étrangère, permission de serveur et propriétaire, POST unique,
délai, absence de réessai, payload visuel, agrégat natif avec lecture fraîche et limite de salons.
Les tests de preflight utilisent maintenant une fonction encore non migrée pour
conserver leur invariant de refus avant effet ; l'éditeur vérifie aussi que la
création fait partie du registre de production. Aucun salon Discord réel n'a
été créé.

Validation de cette étape : les 65 tests ciblés de mutation de salon, les
2 410 tests shared et les treize tests Flutter de validation/éditeur passent.
L'analyse ciblée et `git diff --check` sont propres. Le registre régénéré compte
189 noms du catalogue enregistrés, 365 non enregistrés et cinq extensions, soit
194 noms au total. La migration globale reste en cours.

## Permissions de salon natives : editChannelPerms et modifyChannelPerms

Les pages officielles ont été vérifiées, puis relues le 4 octobre 2026 :
[`$editChannelPerms[Channel ID;User/Role ID;Permission;...]`](https://wiki.botdesignerdiscord.com/bdscript/editChannelPerms.html)
et [`$modifyChannelPerms[Channel ID;Permissions;User/Role ID]`](https://wiki.botdesignerdiscord.com/bdscript/modifyChannelPerms.html).
La première accepte une cible emptiable et les préfixes `+`/`-`. La seconde est
dépréciée, exige une cible et accepte aussi `/` pour une permission neutre.
L'ID du serveur désigne le rôle `@everyone`. Les noms et alias utilisent le
[dictionnaire officiel](https://wiki.botdesignerdiscord.com/resources/permissions.html).

La cible vide de `editChannelPerms` est actuellement interprétée comme
`@everyone`. **C'est une convention provisoire : le wiki ne décrit pas ce
défaut et aucun essai sur BDFD réel ne l'a confirmé.** La séparation de la liste
de `modifyChannelPerms` par espaces ou virgules est également une extension
locale. Les états répétés appliquent le dernier token ; le wiki ne précise pas
ce cas. Ces choix ne constituent pas des preuves de conformité complète.

`BotChannelPermissionService` porte une requête typée commune au moteur, au SDK,
au bloc visuel et à la sandbox. Les appels natifs préservent les flags non
concernés d'un overwrite existant ; la neutralisation enlève le flag des deux
masques. Le bloc visuel conserve sa sémantique de snapshot complet. La cible
est résolue dans le serveur du salon, avec validation du rôle ou du membre.
Les threads sont refusés : leurs overwrites appartiennent au salon parent.
La garde utilise les permissions effectives du bot, puis le budget est vérifié
avant l'écriture. Une lecture qui finit après le délai ne déclenche pas
d'écriture et une erreur SDK n'entraîne aucune relance automatique.

La sandbox emploie la même préparation et modifie ses fixtures, ce qui permet
à la garde suivante de lire les nouvelles permissions. Les types d'overwrite
numériques et leurs alias `role`/`member` désignent la même entrée lors du
remplacement. Les effets simulés sont enregistrés après validation seulement.
Le contrôle Discord des flags que le bot est autorisé à accorder reste celui
de l'API : la sandbox ne simule pas toutes ces restrictions. Nyxx 6.9 n'expose
pas de motif d'audit sur `updatePermissionOverwrite` ; aucun motif n'est envoyé.
La suppression d'overwrites par le bloc visuel reste sur le chemin historique.

Validation : 15 tests dédiés couvrent signatures, ordre des arguments, alias,
neutralisation, fusion et remplacement, cibles, gardes, délais, erreurs sans
relance et overwrites successifs dans la sandbox. La suite partagée passe
2 425 tests et les tests d'éditeur ciblés passent 13 tests. Tous les accès
Discord de ces tests sont simulés. L'audit du registre compte 191 noms du
catalogue enregistrés, 363 non enregistrés et cinq extensions, soit 196 noms.
Cet audit mesure l'enregistrement, pas la conformité BDFD des comportements.

## Lectures et gardes de permissions natives

Quatre signatures ont été vérifiées sur le wiki officiel le 4 octobre 2026 :

- [`$checkUserPerms[User ID;Permissions]`](https://wiki.botdesignerdiscord.com/bdscript/checkUserPerms.html) : au moins une permission, plusieurs permissions séparées par `;`, résultat `true` si toutes sont présentes, sinon `false`.
- [`$onlyPerms[Permissions;...;Error message]`](https://wiki.botdesignerdiscord.com/bdscript/onlyPerms.html) : permissions de l'auteur, arguments permissions et erreur emptiable.
- [`$onlyBotPerms[Permissions;...;Error message]`](https://wiki.botdesignerdiscord.com/bdscript/onlyBotPerms.html) : permissions du bot, permissions et erreur emptiable.
- [`$onlyBotChannelPerms[Channel ID;Permissions;...;Error message]`](https://wiki.botdesignerdiscord.com/bdscript/onlyBotChannelPerms.html) : permissions du bot dans le salon indiqué, cible et erreur emptiable, permissions requises.

Les trois formes sans salon lisent les permissions du serveur courant.
`onlyBotChannelPerms` utilise le serveur du salon demandé, même si le contexte
porte un autre serveur. Un salon vide sélectionne actuellement le salon du
contexte : **le wiki autorise cette valeur sans préciser le défaut ; ce choix
reste une convention locale à confirmer contre BDFD**. Les alias historiques
`hasPerms` et `checkUsersPerms` restent non migrés : les recherches n'ont pas
trouvé leurs pages officielles et ils ne sont pas ajoutés comme synonymes
silencieux. `userPerms`, qui retourne une liste textuelle, a été migré dans
l'étape suivante décrite ci-dessous.

`BotPermissionQueryService` fournit une lecture indépendante des blocs au
moteur, à l'agrégat Discord et à la sandbox. L'adaptateur relit le serveur,
le membre et ses rôles. Il combine `@everyone` et les rôles du membre, puis
applique les overwrites via le calcul partagé. Le propriétaire et
Administrator passent les vérifications. Les threads utilisent les overwrites
de leur parent ; un parent invalide échoue. Le timeout réduit les permissions
aux flags de lecture autorisés par Discord. Les contrôles de salon prennent
en compte View Channel, les dépendances d'envoi et certaines dépendances de
Connect, conformément à la
[documentation Discord](https://raw.githubusercontent.com/discord/discord-api-docs/main/developers/topics/permissions.mdx).
Cela ne simule pas l'accès aux threads privés, les contraintes de connexion
en cours ou toutes les restrictions implicites de Discord ; la conformité
complète de ces cas reste à vérifier.

Les gardes empruntent le contrôle d'arrêt natif. Une erreur de permissions
interrompt les instructions suivantes, y compris dans un try/catch. Le dernier
argument n'est évalué que si la garde refuse l'exécution et remplace alors la
sortie courante, comme la garde native `onlyIf`. Une liste de permissions vide
pour les deux gardes de serveur laisse continuer sans lecture. Ce détail et
l'évaluation paresseuse suivent les conventions natives existantes ; les pages
du wiki ne décrivent pas ces modalités d'évaluation. Des permissions inconnues
ou des signatures incorrectes restent des erreurs ; les fonctions inconnues
restent opaques, arguments compris.

Les indications de signature de l'éditeur ont été corrigées pour ces fonctions,
ainsi que pour `modifyChannel`, `editChannelPerms` et `modifyChannelPerms` : elles
ne suggèrent plus un ordre d'arguments incompatible avec le wiki.

Les 17 tests dédiés vérifient les résultats booléens, l'arrêt et la paresse des
gardes, les rôles et overwrites, propriétaire/Administrator, timeout, lectures
fraîches, threads, budgets et changements de permissions successifs en sandbox.
La suite partagée passe 2 442 tests, les tests d'éditeur ciblés passent 13 tests,
et l'analyse ciblée et `git diff --check` sont propres.
Tous les accès Discord sont simulés. L'audit mesure maintenant 195 noms du
catalogue enregistrés et 359 non enregistrés, avec cinq extensions, soit 200
noms au total. Les autres fonctions et le retrait du backend historique restent
à terminer.

## Liste des permissions utilisateur : userPerms

La page officielle de
[`$userPerms[User ID;Return amount;Separator]`](https://wiki.botdesignerdiscord.com/bdscript/userPerms.html)
a été relue le 4 octobre 2026. Les trois arguments sont obligatoires et `-1`
sélectionne toutes les permissions. L'exemple montre des libellés Discord en
majuscules avec underscores, un séparateur conservé tel quel et une liste
contenant Administrator sans toutes les permissions possibles.

Le handler natif utilise `storedMemberPermissions` dans le service de lecture
existant. Cette méthode relit le membre et les rôles du serveur courant, puis
combine leurs flags et ceux d'`@everyone`. Le calcul de base est partagé avec
la lecture effective utilisée par les gardes. La liste n'élargit pas les flags
pour le propriétaire ou Administrator, n'applique pas les overwrites de salon
et conserve les flags des rôles pendant un timeout. L'interprétation des flags
stockés est déduite de l'exemple ; la page ne spécifie pas explicitement les
cas du propriétaire et du timeout. Aucun essai sur BDFD réel ne les confirme.

Le formateur est propre à `userPerms`, car `rolePerms` emploie d'autres libellés
et une autre convention de séparateur. Il conserve les espaces du séparateur
et n'en ajoute pas. Il retourne au plus le nombre demandé dans l'ordre des
bits Discord. Zéro et une liste sans flags donnent une chaîne vide ; les
valeurs inférieures à `-1` et les valeurs non entières échouent avant toute
lecture. La page ne détaille pas ces cas limites. Les libellés montrés par le
wiki, dont `USE_VAD`, sont repris ; les flags plus récents suivent les noms
Discord, dont la sortie exacte dans BDFD reste à vérifier. Un bit sans libellé
connu est omis. Les alias historiques `authorPerms` et `memberPerms` restent
non migrés, faute de page officielle retrouvée.

L'agrégat SDK, la validation de production, la sandbox et l'éditeur prennent
en charge la fonction. Il n'existe aucun passage par `Action` ou le resolver
de templates historique. Sept nouveaux tests vérifient format, limite,
séparateur, argumentation, conservation opaque, lecture SDK et sandbox ; la
suite dédiée aux permissions contient maintenant 24 tests. Tous les accès
Discord sont simulés. La suite partagée passe 2 449 tests et les tests d'éditeur
ciblés passent 13 tests. L'analyse ciblée et `git diff --check` sont propres.
Le registre contient 196 noms du catalogue, 358 restent
non enregistrés, et cinq extensions portent le total à 201. La migration
globale demeure en cours.

## Recherche et choix aléatoires de rôles et salons

Les signatures ont été vérifiées sur le wiki officiel le 4 octobre 2026 :

- [`$findRole[Role]`](https://wiki.botdesignerdiscord.com/bdscript/findRole.html) : recherche par nom, ID ou mention, seulement dans le serveur courant ; l'argument peut être vide.
- [`$randomRoleID[(Guild ID)]`](https://wiki.botdesignerdiscord.com/bdscript/randomRoleID.html) : serveur courant par défaut ou serveur indiqué ; `@everyone` fait explicitement partie des résultats possibles. L'exemple officiel utilise `[]` pour le défaut.
- [`$randomChannelID`](https://wiki.botdesignerdiscord.com/bdscript/randomChannelID.html) : aucun argument, choix dans le serveur courant.

Les handlers natifs appellent les services de lecture de rôles et de salons
existants, avec le budget commun. `findRole` vérifie l'appartenance au serveur
courant, y compris pour un ID ou une mention `<@&ID>`. La recherche par nom est
exacte et sensible à la casse ; le premier doublon dans la liste SDK est
sélectionné. Une recherche vide ou sans résultat donne une chaîne vide.
Le wiki ne précise pas ces conventions de casse, doublons ou absence de résultat,
ni une recherche partielle : elles restent à confirmer contre BDFD réel.

`randomRoleID` valide un serveur explicite avant la lecture et ne filtre pas
`@everyone`. `randomChannelID` utilise les salons du serveur, catégories comprises,
sans charger les threads actifs. Le wiki ne détaille pas le filtrage des types
de salons ; cette population suit le service de liste existant et reste à
confirmer. Une population vide donne une chaîne vide, autre cas non documenté.
Les erreurs SDK sont propagées et ne déclenchent pas de nouvelle tentative.

Le contexte natif conserve un générateur `Random`, injectable dans les tests.
Les appels d'une même invocation et les évaluations imbriquées partagent le même
générateur. Le tirage utilise uniformément un index de la population lue ; le
wiki ne spécifie ni algorithme ni distribution. La validation de production et
l'éditeur enregistrent les fonctions sans faire de lecture. La sandbox passe
par les mêmes services, sans effet de bloc.

Neuf nouveaux tests portent les suites de rôles et de salons à 106 tests. Ils
vérifient les trois formes de recherche, les conventions de nom, la portée de
serveur, `@everyone`, la population des salons, les signatures, la conservation
opaque et la continuité du générateur à travers un eval. Les accès Discord sont
simulés. La suite partagée passe 2 458 tests et les tests d'éditeur ciblés passent
13 tests ; l'analyse ciblée et `git diff --check` sont propres.
Le registre atteint 199 noms du catalogue, 355 non enregistrés et cinq
extensions, soit 204 noms au total. Les autres fonctions et le retrait des
chemins historiques restent à terminer.

## Fonctions aléatoires générales natives

Les quatre pages officielles ont été vérifiées le 4 octobre 2026 :
[`$random`](https://wiki.botdesignerdiscord.com/bdscript/random.html),
[`$random[Min;Max]`](https://wiki.botdesignerdiscord.com/bdscript/randomComplex.html),
[`$randomText[Text;...]`](https://wiki.botdesignerdiscord.com/bdscript/randomText.html)
et [`$randomString[Length]`](https://wiki.botdesignerdiscord.com/bdscript/randomString.html).
Sans argument, `random` retourne un chiffre de zéro à neuf. La forme à deux
arguments admet entiers et flottants et exclut la borne supérieure ; `Max` doit
dépasser `Min`, conformément aux inégalités et à l'avertissement de la page.
Une phrase de cette page inverse les noms, mais ses exemples sont cohérents
avec cette règle. `randomText` accepte des options vides. `randomString` exige
une longueur entière, avec un maximum de dix. Le
[playground officiel](https://wiki.botdesignerdiscord.com/theme/playground.js),
lu directement sur le site, confirme le minimum de un et l'alphabet de lettres
majuscules/minuscules et de chiffres.

`random_functions.dart` est enregistré sans service Discord et utilise le
générateur du contexte, partagé avec les recherches aléatoires précédentes et
les appels imbriqués. Les helpers numériques sont indépendants des scripts.
Les plages entières larges utilisent BigInt et un tirage par rejet pour éviter
le débordement du calcul de leur largeur. Les rejets vérifient le budget.
L'interpolation décimale traite les largeurs dépassant la capacité d'un double
et corrige l'arrondi qui pourrait produire la borne supérieure exclue. Le wiki
ne spécifie ni précision décimale, ni distribution, ni séquence de tirages :
ces modalités restent propres au moteur natif.

`BdfdNativeFunction` peut maintenant déclarer un ensemble de nombres d'arguments
autorisés. `random` autorise zéro ou deux arguments, ce qui rejette une forme
à un argument dès la préparation, avant tout effet précédent. Les bornes non
finies ou non croissantes et les longueurs invalides échouent avant le tirage.
Le générateur de chaînes ne reprend pas l'extension historique permettant un
alphabet personnalisé ou une longueur supérieure à dix.

`randomText` conserve le texte de l'option choisie, espaces compris, et n'évalue
que cet argument, une fois. Cette paresse conserve la convention du resolver
historique ; le wiki ne spécifie pas les effets des arguments non sélectionnés,
donc ce détail reste à confirmer contre BDFD. Le résultat est traité comme une
valeur, sans interprétation de son contenu comme du code. Les fonctions
inconnues gardent leurs arguments aléatoires opaques et ne consomment aucun
tirage. Le resolver historique reste en place pour le backend legacy ; le
moteur natif ne l'appelle pas.

Les 17 tests dédiés couvrent bornes incluses/exclues, plages entières larges,
rejets et budget, interpolation décimale, options vides et paresse, alphabet et
limite, préflight, conservation opaque, eval et sandbox. L'éditeur enregistre
les signatures et la sandbox exécute ces fonctions sans effet Discord. Le
package partagé passe 2 475 tests et les tests d'éditeur ciblés passent 13 tests.
L'analyse ciblée et `git diff --check` sont propres. Le
registre compte 202 noms du catalogue enregistrés et 352 non enregistrés,
avec cinq extensions, soit 207 noms au total. La migration globale reste active.

## Catégorie aléatoire et salons configurés du serveur

Quatre pages officielles ont été vérifiées le 4 octobre 2026 :

- [`$randomCategoryID[(Guild ID)]`](https://wiki.botdesignerdiscord.com/bdscript/randomCategoryID.html) : catégorie du serveur courant ou du serveur indiqué ; l'exemple utilise `[]` pour le serveur courant.
- [`$afkChannelID`](https://wiki.botdesignerdiscord.com/bdscript/afkChannelID.html) : ID du salon AFK du serveur courant, sans argument.
- [`$rulesChannelID[(Guild ID)]`](https://wiki.botdesignerdiscord.com/bdscript/rulesChannelID.html) : ID du salon de règles, avec un serveur optionnel.
- [`$systemChannelID`](https://wiki.botdesignerdiscord.com/bdscript/systemChannelID.html) : ID du salon système du serveur courant, sans argument.

Les trois fonctions de configuration produisent une erreur quand le salon
n'est pas configuré, comme demandé explicitement par ces pages. Les erreurs
empruntent la gestion native et peuvent être traitées par try/catch. Pour
`rulesChannelID`, l'omission ou un argument vide sélectionne actuellement le
serveur courant ; le wiki indique que l'argument est optionnel sans détailler
explicitement la signification d'un argument vide. Cette convention reste à
confirmer contre BDFD réel.

`BotChannelQueryService` fournit maintenant un snapshot typé
`BotGuildChannelSettings` avec les trois IDs optionnels. L'adaptateur SDK relit
le serveur avec `guilds.fetch` à chaque demande, vérifie le budget après la
lecture, puis extrait ces IDs. Il ne charge pas les salons configurés : ces
fonctions lisent leur référence dans la configuration du serveur. Les erreurs
SDK ne deviennent pas une configuration absente et ne sont pas relancées.
L'agrégat de production et la sandbox délèguent au même service, sans `Action`.
La validation enregistre les handlers avec un adaptateur qui interdit les
lectures ; l'éditeur connaît les signatures.

Les fixtures de serveur exposent `afk_channel_id`, `rules_channel_id` et
`system_channel_id`. Les champs absents ou null valent absence de configuration.
Un ID malformé ou non positif provoque une erreur locale. Les getters relisent
les données de la fixture ; un changement entre deux lectures est visible,
tandis qu'un snapshot déjà retourné reste inchangé.

`randomCategoryID` valide un serveur explicite avant toute lecture, utilise la
liste de salons sans threads, conserve seulement les catégories et choisit
avec le générateur du contexte partagé. Sans catégorie, la chaîne retournée
est vide : la page officielle ne précise pas ce cas limite. Aucun filtrage
historique par nom et aucune requête de blocs n'intervient.

Neuf nouveaux tests portent la suite des lectures de salons à 63 tests. Ils
vérifient signature et portée, absence configurée et try/catch, choix de
catégorie, lectures fraîches, snapshot, fixtures malformées, budget, conservation
opaque, agrégat SDK et sandbox sans effets. Tous les accès Discord sont simulés.
La suite partagée passe 2 484 tests et les tests d'éditeur ciblés passent 13 tests.
L'analyse ciblée et `git diff --check` sont propres.
Le registre atteint 206 noms du catalogue et 348 noms non enregistrés, avec
cinq extensions, soit 211 noms au total. La migration globale reste à terminer.

## Calendrier, fuseaux et timestamps natifs

Les pages officielles ont été vérifiées le 4 octobre 2026 :
[`date`](https://wiki.botdesignerdiscord.com/bdscript/date.html),
[`day`](https://wiki.botdesignerdiscord.com/bdscript/day.html),
[`hour`](https://wiki.botdesignerdiscord.com/bdscript/hour.html),
[`minute`](https://wiki.botdesignerdiscord.com/bdscript/minute.html),
[`second`](https://wiki.botdesignerdiscord.com/bdscript/second.html),
[`month`](https://wiki.botdesignerdiscord.com/bdscript/month.html),
[`year`](https://wiki.botdesignerdiscord.com/bdscript/year.html),
[`time`](https://wiki.botdesignerdiscord.com/bdscript/time.html),
[`getTimestamp`](https://wiki.botdesignerdiscord.com/bdscript/getTimestamp.html)
et sa [forme avec unité](https://wiki.botdesignerdiscord.com/bdscript/getTimestampComplex.html).
La page de `second` a été lue directement depuis le site après l'échec de
l'outil web. Les sept champs de calendrier sont sans argument ; `hour` utilise
24 heures. `time[Timezone]` sélectionne un nom de la base TZ. `getTimestamp`
donne des secondes par défaut ; sa forme à un argument accepte `s`, `ms`, `ns`.

Le [script des exemples officiels](https://wiki.botdesignerdiscord.com/theme/livetime.js)
a aussi été lu directement sur le site. Il affiche la date en `YYYY-MM-DD`, le
mois en anglais avec son nom complet et les champs numériques sans padding.
Le moteur natif suit ces formats. Son défaut UTC concorde avec ce script, mais
les pages ne spécifient pas explicitement le fuseau par défaut du moteur BDFD.
Les exemples du wiki ne constituent pas une exécution comparative contre BDFD.

`BdfdTimeState` appartient au contexte d'invocation. L'horloge est injectable ;
les fonctions la lisent au moment de l'appel, sans utiliser les snapshots de
variables de l'événement ni le resolver historique. Les appels imbriqués et
eval partagent le fuseau et l'horloge. Un contexte séparé repart avec UTC.
`time` n'émet pas de texte et ne remplace le fuseau qu'après résolution réussie ;
un nom invalide traité par try/catch laisse le fuseau précédent intact.

Le package partagé déclare maintenant sa dépendance directe à
[`timezone`](https://pub.dev/packages/timezone), déjà présent dans le workspace
en version 0.11.0. Sa base complète embarquée IANA 2025c assure les transitions
d'été/hiver et les aliases historiques. Le chargement constitue une copie
privée des locations et restaure immédiatement la base et le fuseau ambiants
du package, pour conserver les autres consommateurs de l'application.
Il fonctionne aussi dans un nouvel isolate de sandbox, sans accès réseau.

Les timestamps restent indépendants du fuseau. Le calcul est entier, avec un
arrondi vers le bas pour les instants négatifs, et BigInt évite le débordement
de la représentation en nanosecondes. L'horloge DateTime ne fournit toutefois
que des microsecondes : les trois derniers chiffres en nanosecondes sont nuls.
La page officielle ne spécifie pas la précision effective du backend BDFD.
L'ancien alias `getTimestampMS` reste non migré : aucune page officielle dédiée
n'a été retrouvée, la forme officielle étant `getTimestamp[ms]`.

Les 21 tests dédiés couvrent formats, défaut UTC, fuseaux fractionnaires,
changements d'heure, changement d'année, année bissextile, horloge vivante,
isolation des contextes et du package TZ, eval, erreurs, trois unités, instants
négatifs, absence de débordement et conservation opaque. La validation de
production et l'éditeur connaissent les fonctions ; la sandbox les exécute
sans effet Discord. La suite partagée passe 2 505 tests et les tests d'éditeur
ciblés passent 13 tests. L'analyse ciblée et `git diff --check` sont propres.
Le registre compte 215 noms du catalogue enregistrés,
339 non enregistrés et cinq extensions, soit 220 noms au total. La migration
globale reste active.


### Dates de création des snowflakes et alias historique

Les signatures de [`$creationDate[ID;(Format)]`](https://wiki.botdesignerdiscord.com/bdscript/creationDate.html)
et [`$userJoinedDiscord[ID;(Format)]`](https://wiki.botdesignerdiscord.com/bdscript/userJoinedDiscord.html)
ont été lues sur le wiki officiel. Les deux exigent un ID et acceptent un
format Go optionnel. La seconde est dépréciée depuis novembre 2022 au profit
de la première ; sa page indique explicitement qu'elle accepte aussi les IDs
de salons, rôles, serveurs et messages. Elles partagent le même handler natif.
L'aide de l'éditeur ne présente plus l'ID de userJoinedDiscord comme optionnel.

Le format par défaut `2006-01-02` suit les exemples officiels. Le formateur
partagé couvre les valeurs du [tableau BDFD](https://wiki.botdesignerdiscord.com/resources/timeFormat.html),
y compris padding, heures sur 12 et 24 heures, noms anglais, jours de l'année,
offsets avec secondes et variantes ISO Z. La reconnaissance est insensible
à la casse conformément au tableau ; `PM` et `pm` conservent leurs sorties
respectives. Les casses mixtes de ce dernier donnent des majuscules, convention
non explicitée par le wiki. Les fractions à zéros fixes ou neuf supprimables
suivent la [documentation Go](https://pkg.go.dev/time#pkg-constants) ; elles ne
figurent pas dans le tableau BDFD et ne sont donc pas une garantie BDFD vérifiée.
Un format explicitement vide produit du texte vide, suivant Go ; ce cas reste
également non spécifié par les pages BDFD.

Le décodage suit la [structure officielle des snowflakes Discord](https://docs.discord.com/developers/reference#snowflakes).
BigInt accepte la plage positive non signée de 64 bits sans débordement ; les
bits bas ne changent pas la date. Les valeurs non décimales, nulles ou hors
plage sont rejetées avec une erreur native. Aucun chargement d'entité ni accès
Discord n'est nécessaire ; un ID numérique admissible est décodé même si son
entité n'existe pas. Il n'y a pas de restriction aux dates passées.

Le formateur utilise le fuseau du contexte, sans lire l'horloge actuelle.
L'effet de `$time` sur ces fonctions est une convention de cohérence du moteur
natif : les pages de création ne le garantissent pas explicitement. Les jours
de l'année sont calculés à partir des champs calendaires, évitant un décalage
aux transitions d'heure d'été. Les formats et valeurs interpolés ne sont pas
réinterprétés comme du BDFD ; les appels inconnus restent entièrement opaques.
Le parcours du format vérifie régulièrement le budget d'exécution.

Les 49 tests dédiés couvrent les exemples officiels, les valeurs de format du tableau,
les limites 64 bits, les erreurs, offsets fractionnaires, transitions d'heure,
formats vides et littéraux, absence de réexécution des valeurs et sandbox sans
requête d'entité. Ce sont des vérifications locales, sans exécution comparative
sur BDFD et sans action Discord réelle. La suite partagée passe 2 554 tests ;
l'éditeur passe 13 tests. L'analyse ciblée ne signale aucun problème.
Le registre contient désormais
217 noms du catalogue et cinq extensions, soit 222 noms ; 337 noms du catalogue
restent à enregistrer. Le retrait du moteur historique reste à réaliser.


### Migration parallèle : textes, filtres, variables et embeds

À la demande de l'utilisateur, trois agents ont traité des familles distinctes,
avec vérification individuelle des sources officielles, fichiers séparés et
intégration centrale du registre et de l'éditeur. Le moteur de production inclut
maintenant les nouvelles bibliothèques dans tous ses points d'entrée natifs.

- [Texte](bdfd-text-utilities-migration.md) : huit fonctions, dont byteCount,
  cropText, sort et les prédicats number/boolean/hex. Le tri compare les décimaux
  exactement. Les sources et cas non spécifiés sont détaillés dans ce document.
- [Filtres de contexte](bdfd-context-guards-migration.md) : neuf fonctions,
  listes d'identités/salons/serveurs et onlyIfMessageContains. L'erreur reste
  lazy et l'arrêt utilise le contrôle natif partagé. La casse ignorée reprend
  une convention historique explicitement non garantie par le wiki.
- [Variables](bdfd-variable-operations-migration.md) : varExists et trois resets
  officiels restaurent les défauts déclarés. La population à réinitialiser est
  photographiée avant les writes pour éviter les sauts de pagination. Les resets
  sont séquentiels, sans transaction ni retry automatique ; leur portée
  inter-serveurs user reste une interprétation documentée.
- [Embeds](bdfd-embed-properties-migration.md) : cinq nouvelles fonctions et
  correction des signatures author/footer, des indices 1 à 10 et du quatrième
  argument addField. Les limites de texte et de champs sont vérifiées avant
  l'envoi du brouillon principal.

Les hints de l'éditeur suivent les signatures consultées, et sa validation
prépare un script couvrant toutes les nouvelles fonctions sans les exécuter.
Les bibliothèques ne passent pas par le compilateur de blocs ou le resolver
historique. Les fonctions inconnues et leurs arguments restent opaques.

Après intégration, la suite partagée passe 2 632 tests et les tests d'éditeur
ciblés passent 13 tests. Deux tests supplémentaires d'intégration passent aussi :
ils combinent filtres et textes à travers un workflow dans la sandbox de
production, puis vérifient les resets sur son stockage réel en mémoire.
L'analyse ciblée de toutes les bibliothèques natives,
des services modifiés et des nouveaux tests ne signale aucun problème.
Le registre compte 243 noms du catalogue et cinq extensions (248 au total),
avec 311 noms du catalogue non enregistrés. Ce nombre mesure l'enregistrement,
pas la conformité complète. Les fonctions removeContains/removeLinks/unescape
restent non migrées car leurs contrats exigent des capacités supplémentaires,
pas des substituts de manipulation de chaînes. Le retrait du moteur historique
et la migration globale restent en cours, sans action Discord réelle.


### Services d'utilisateurs, de serveurs et de threads

Le lot parallèle suivant ajoute trois bibliothèques natives et trois services
SDK indépendants du compilateur de blocs :

- [Utilisateurs](bdfd-user-queries-migration.md) : dix noms supplémentaires et
  extension de username à la forme avec ID explicite. Le bare username continue
  à utiliser les données du contexte lorsqu'elles sont fournies. Les lectures
  explicites passent par les endpoints user/member frais. Seules les réponses
  404 confirmant l'absence de cette entité deviennent null. userJoined partage
  le formateur Go ; avatars et bannières utilisent les assets SDK sans download.
- [Serveurs](bdfd-guild-queries-migration.md) : onze fonctions, metadata fraîche
  et pagination complète des serveurs accessibles au compte. serverNames expose
  dix noms selon le wiki. Les aliases sans source officielle ne sont pas ajoutés
  comme garanties de compatibilité. La variante REST pour large bot sharding
  reste une limite de l'API Nyxx installée, détaillée dans le document.
- [Threads](bdfd-threads-migration.md) : six fonctions, créations publiques avec
  ou sans message source, éditions, membership et compteurs. Le service commun
  prépare les requêtes avec des lectures et des permissions fraîches avant les
  writes. Les compteurs sont ceux de Discord, avec leurs limites d'approximation.

Les adaptateurs de production, de validation et de sandbox implémentent les
mêmes interfaces. Le registre commun les sélectionne via l'agrégat SDK déjà
fourni aux commandes, événements et workflows natifs ; il accepte également des
services explicitement injectés. La validation interdit toute lecture/écriture.
L'éditeur connaît les nouvelles signatures, y compris les positions obligatoires
mais emptiable du startThread et les indices/flags d'editThread. Les tests de
capacité non migrée utilisent désormais wait, puisque startThread est disponible.

La sandbox étend ses fixtures avec joined_at, guild avatars, banner/accent color,
metadata de guildes, pagination REST et metadata de threads. Le client de fixtures
expose seulement la configuration nécessaire à fabriquer les URLs CDN ; le HTTP
et les writes SDK restent interdits. Pour les writes threads, la sandbox réutilise
les mêmes helpers de préparation que Discord puis modifie uniquement ses propres
fixtures, avec snapshots avant/après et effets simulated. Les additions de membres
requièrent une liste de membres explicite et une cible présente dans la guilde.
La création depuis un message requiert une fixture de ce message dans le parent ;
l'identité du thread reprend celle du message et les doublons sont rejetés.
Les permissions de visibilité des threads privés restent incomplètement simulées,
comme décrit dans le document du lot.

Les 61 tests dédiés des agents passent, ainsi que dix tests d'intégration de la
sandbox de production couvrant URLs SDK, dates de membres, entités absentes,
fixtures manquantes, pagination au-delà de 200 guildes, lifecycle thread, permissions,
identité du message source, doublons et refus de writes directs au gateway.
La suite partagée passe 2 705 tests ; les tests d'éditeur passent 13 tests.
L'analyse ciblée des bibliothèques natives, services, adapters, hints et nouveaux
tests est propre ; les dix tests d'intégration repassent après la revue finale
de la simulation. Les signatures, sources et conventions non
confirmées par le wiki sont conservées dans les trois documents spécifiques.
Le registre contient 270 noms du catalogue et cinq extensions (275 au total) ;
284 noms du catalogue restent non enregistrés. Les tests ne constituent ni une
comparaison contre le backend BDFD ni un essai Discord réel. Le moteur historique
reste actif par défaut et son retrait fait toujours partie de la migration.

### Migration parallèle : membres, messages et réactions

Trois lots ont été migrés en parallèle, chacun possédant son service typé, ses
bindings natifs, ses tests et ses sources officielles :

- [Membres](bdfd-member-queries-migration.md) : huit fonctions, pagination
  complète des membres et guildes, recherche, tirage aléatoire, boosts et timeouts.
  La forme membersCount[Presence] reste à migrer : une réponse exacte nécessite
  une source complète de présence et les intents correspondants.
- [Messages](bdfd-message-queries-migration.md) : huit fonctions de lecture et
  mutation. Les propriétés et bases d'indices suivent les contrats documentés ;
  les contradictions et représentations non vérifiées restent explicites.
- [Réactions](bdfd-reactions-migration.md) : six fonctions, normalisation des
  aliases officiels, réactions Unicode/custom et pagination des utilisateurs.

L'intégration conserve un registre et des services communs aux commandes,
événements, workflows, validation et sandbox. pinMessage et addReactions attendent
la réponse principale réellement envoyée et utilisent ses IDs de canal/message.
Les envois indépendants de sendMessage ne consomment pas cette queue. Le brouillon
et les opérations différées sont détachés avant l'attente réseau ; une erreur
partielle ne rejoue ni l'envoi ni les opérations. Les réponses vides et les gardes
effacent les opérations en attente. Les fixtures des réponses simulées permettent
ensuite aux mêmes helpers de vérifier les permissions des mutations.

Le registre de production compte désormais 292 noms du catalogue et cinq
extensions, soit 297 au total ; 262 noms restent non enregistrés. Cette mesure
compte des inscriptions et ne garantit pas la parité de chaque variante. Le
moteur historique reste actif par défaut jusqu'à la fin de la migration.

Validation finale de ce lot : les 2 787 tests partagés et les 13 tests d'éditeur
passent. Les 14 tests d'intégration des services natifs vérifient notamment le
ciblage de la réponse principale après un sendMessage indépendant, les lectures
de messages, le refus d'une mutation sans permission et les comptes de membres.
L'analyse ciblée des bindings, services, transports, adaptateurs et signatures
ne signale aucun problème. Ces checks n'exécutent pas de requête Discord réelle.

### Maths, emojis, métadonnées de messages et entrées d'interaction

Ce lot poursuit la migration parallèle des bibliothèques métier :

- [Maths](bdfd-math-migration.md) : trois noms supplémentaires (enableDecimals,
  sqrt, modulo), état de décimales partagé par le contexte, correction du round
  avec précision optionnelle, validation entière des min/max et random soumis
  au flag. Les variantes arithmétiques natives utilisent des validations et
  limites distinctes du parser historique ; les conventions absentes du wiki
  sont documentées, sans prétendre une comparaison avec le backend BDFD.
- [Emojis](bdfd-emojis-migration.md) : huit fonctions, recherches fraîches et
  mutations typées. La préparation des permissions précède le téléchargement
  borné et l'écriture. La sandbox emploie les mêmes helpers, des octets HTTP
  explicites en fixture et des mutations locales ; aucun write SDK n'y est permis.
- [Messages](bdfd-message-queries-migration.md) : six noms supplémentaires pour
  le dernier message/pin, les éditions, les références de réponse et editMessage.
  Le service impose la propriété du message pour l'édition, même pour un admin.
  Les métadonnées sont lues depuis les objets SDK frais. Les cas d'embed absent,
  remplacement et représentation de dates non précisés restent documentés.
- [Interactions](bdfd-interaction-inputs-migration.md) : isSlash et input. Les
  champs modal restent des données littérales. Les tests font passer les valeurs
  réellement extraites des anciens composants et des labels actuels au runtime.
  L'adaptateur générique distingue chat-input, context-menu et modal dans son flag.

La simulation des messages utilise des managers de fixtures pour les salons
textuels, d'annonces, vocaux, stages et threads. Les nouveaux getters de métadonnées
et de références n'ouvrent pas une voie vers les writes SDK. Les changements de
contenu/embed, dernier message et dernier pin sont reflétés dans les mêmes fixtures
lues par les queries suivantes. Les dix-huit tests d'intégration vérifient ces
lectures, les éditions autorisées et refusées et les cibles réelles des hooks.

Le registre compte 311 noms du catalogue et cinq extensions, soit 316 au total ;
243 noms restent non enregistrés. Les inscriptions ne garantissent pas toutes
les formes optionnelles ni les cas non documentés. La bascule du moteur par défaut
et le retrait historique restent à réaliser après couverture des capacités.

Validation finale du lot : 2 842 tests partagés et 13 tests d'éditeur passent.
Le lot math compte 18 nouveaux tests dédiés (90 avec runtime/random/parser), le
lot emoji 20 et les queries de messages 29 (dont huit supplémentaires). Les quatre
tests d'input/isSlash et les tests des composants modals et des sous-types de
commandes valident les vrais champs transmis au contexte. L'analyse ciblée des
services, bindings, parser, adaptateurs, fixtures, signatures et nouveaux tests
est propre ; les cas non précisés par le wiki restent explicitement signalés.
Aucune comparaison contre le backend BDFD ni aucun write Discord réel n'est
inféré de ces checks. La migration globale reste en cours.

### Finalisation du lot en pause : accès, commandes et catalogue des variables

Le 4 octobre 2026, trois sous-agents ont repris les périmètres du lot non validé :
gardes de rôles/permissions, métadonnées de commandes/customID et catalogue des
variables. L'intégration centrale raccorde les requêtes de commandes au registre
de production, à la validation, aux commandes slash/préfixées, aux événements
et aux blocs natifs de workflows. La sandbox fournit un adaptateur explicite
sans accès Discord réel, partagé par les workflows imbriqués.

Les gardes de permissions refusent les IDs invalides avant lecture et contrôlent
le budget après retour des services. varExists et varExistError transmettent
également ce budget au stockage et aux parcours du catalogue. Les métadonnées
de commandes distinguent nom enregistré, déclencheur utilisé, dossier et ID
Discord ; isSlash exclut les menus contextuels. customID conserve les valeurs
des callbacks composants/modals comme données opaques.

Les tests d'intégration vérifient les fixtures de commandes, les métadonnées
contenant du BDFD littéral, les fixtures absentes, le départ de serveur sans
réexécution d'un effet, et l'adaptateur de commandes partagé par un bloc natif
appelé depuis un workflow visuel. Les cas du catalogue et des gardes couvrent
aussi les budgets expirés et les services tardifs.

Le registre contient maintenant 332 noms sur les 554 du catalogue, plus cinq
extensions (337 noms au total) ; 222 noms du catalogue restent non enregistrés.
L'audit JSON est régénéré depuis le registre de validation de production.
La suite partagée passe 2 900 tests ; les tests d'éditeur, de replay et de blocs
natifs passent 17 tests. L'analyse ciblée des bindings natifs, services,
adaptateurs et tests du lot ne signale aucun problème. Les quatre tests
d'intégration de commandes repassent avec une assertion sur la réponse réelle
du bloc imbriqué.

Ces chiffres décrivent les inscriptions et les checks locaux ; ils ne prouvent
pas toutes les variantes BDFD et n'incluent aucun write Discord réel.
La bascule native par défaut et le retrait du moteur historique restent à faire
après migration des familles restantes. Le présent lot est finalisé.

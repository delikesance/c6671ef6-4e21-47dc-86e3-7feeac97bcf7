# Blocs visuels vers moteur natif BDFD : inventaire et plan de migration

Branche `claude/visual-blocks-native` (base `dev`). Document de recherche en lecture seule : aucun code modifié.
Décision de départ : chaque `Action` est traduite en appel(s) de fonction native (même registre, mêmes services,
même budget, mêmes erreurs) ; `handler.dart` et les exécuteurs disparaissent type par type, avec un test de parité par type.

Chemins relatifs à `packages/shared/lib/` sauf mention contraire. Références `fichier:ligne` relevées sur l'état actuel du dépôt.

## 0. Constats clés (à lire d'abord)

1. Les blocs et le moteur natif **partagent déjà beaucoup de services** : `BotModerationService` (ban/kick/roles/clear),
   `BotMessageService` (transport `send_message.dart`/`respond_with_message.dart`), `JsonDocument`, `HttpService`,
   `VariableService`, `BotChannelMutationService`, `BotThreadService`, `BotReactionService`, `image_executor.dart` (canvas).
   Le travail n'est donc pas de réécrire les effets Discord mais de les rendre appelables depuis le moteur avec la **charge utile complète du bloc**.
2. **Les signatures BDFD sont plus étroites que les payloads des blocs.** Exemples : `$createChannel[nom;type;catégorie]` n'a ni topic, ni nsfw, ni slowmode,
   ni raison, et ne renvoie pas l'ID (`channel_mutation_functions.dart:11-40`) ; `$banID[raison;user]` n'a pas `deleteMessageDays` ;
   `$sendMessage[texte;yes/no]` n'accepte que du texte (`message_functions.dart:541`). Mapper un bloc sur la fonction BDFD « la plus proche » **perd des champs**.
   Il faut des fonctions d'extension BotCreator (précédent : `music_functions.dart:6-8`, « BotCreator extension (not in the BDFD wiki) »).
3. **Sortie bufferisée vs envoi immédiat.** Un bloc `sendMessage`/`respondWithMessage` envoie tout de suite. Le natif accumule la réponse dans `BdfdMessageOutput`
   et ne l'envoie qu'au `flush` (fin de script, `$eval`, `$callWorkflow`, `$usechannel`, `message_functions.dart:~105-286`). Seuls `$sendMessage`,
   `$channelSendMessage`, `$sendEmbedMessage` envoient immédiatement.
4. **Deux langages de template.** Les blocs utilisent `((expr))` (JSONPath, fonctions, fallback `|`, `utils/template_resolver.dart:2254`), le natif utilise `$fn[args]`.
   Le runtime natif n'appelle jamais `resolveTemplatePlaceholders` (aucune occurrence dans `engine/bdfd/`).
5. **Deux canaux de résultats.** Les blocs écrivent à la fois `results[clé]` (local à chaque `handleActions`) et `variables['clé.champ']` (map partagée). Le natif a
   `context.results` (une seule map) et `context.variables` (partagée avec les blocs : `handler.dart:201-208` lui passe la même map).
6. `Action.dependOn` est sérialisé (`types/action.dart:152,170,191`) mais **jamais lu** à l'exécution (grep : seulement `command_migration.dart` et l'éditeur qui écrivent `[]`).
7. `packages/app/lib/features/actions/bot_actions/handler.dart` (1735 lignes, 118 `case`) est une **seconde copie** du handler qui délègue partiellement à `shared`
   (`:1679`). Aucun import hors de lui-même (grep `bot_actions/handler`) : code probablement mort, à confirmer puis supprimer en vague 10.
8. Le wiki BDFD (423 pages au sommaire `toc.html`) ne contient **aucune fonction absente du registre natif** hormis des variantes « Complex » (arités alternatives).
   Donc pour tout type « MANQUANT » ci-dessous il n'existe pas de fonction BDFD officielle à implémenter, sauf mention explicite
   (`$pinMessage[canal;message]`, `$dm[id;...]` multi-destinataires).
9. `$debug` natif est un no-op (`advanced_language_functions.dart:27-31`) ; la trace `debugProfile` des blocs n'a pas d'équivalent natif.

## 1. Exécution actuelle d'une `Action` de bout en bout

Points d'entrée : `WorkflowExecutor.executeActions` (`engine/workflow_executor.dart:36`), appelé par `command_executor.dart:274,473,594`, `event_dispatcher.dart:990,1064`,
`handle_component_interaction.dart:215,299` (via `handleListenerWorkflowActions`, `handler.dart:1823`), la sandbox (`sandbox/command_sandbox.dart:436`) et
`$callWorkflow` (`runVisualWorkflow`, `workflow_functions.dart:9-12`).

| Aspect | Fonctionnement actuel | Référence |
|---|---|---|
| Modèle | `Action{type,key,enabled,dependOn,error{mode,jumpToActionId,skipCount},payload}`. JSON : `type,key,enabled,depend_on,error,payload`. 118 valeurs d'enum. | `types/action.dart:1-232` |
| Budget | `handleActions` enveloppe tout dans `CommandExecutionBudget.run` (limite 15 min, un seul chronomètre partagé par tous les niveaux imbriqués). `executionBudget.check()` avant chaque action. | `handler.dart:111-113,316-317` ; `engine/execution_budget.dart:11-39` |
| Résultat par action | Clé = `action.key ?? 'action_$i'`. | `handler.dart:308` |
| `results` | Map **locale** à chaque appel de `_handleActions` (nouvelle map pour chaque liste imbriquée). Le parent recopie `results['<clé>.<sous-clé>']` (if), `results['<clé>.iter<N>.<sous-clé>']` (boucles). Une action imbriquée **ne voit pas** `results` du parent, seulement `variables`. | `handler.dart:193,221-251` ; `control_flow_executor.dart:482-488,583,639,725` |
| Templating des payloads | `resolveValue(s)` : (1) regex `\(\(([^)]+)\)\)` cherche la clé exacte puis la clé sans préfixe `action.` dans `results` ; (2) sinon `resolveTemplate` = `resolveTemplatePlaceholders(s, variables)`. Chaque exécuteur appelle `resolveValue` champ par champ. Les composants/modals sont résolus récursivement avant dispatch. | `handler.dart:253-277,343-361` ; `workflow_executor.dart:~85-95` |
| Hydratation | Avant chaque action (sauf `deferInteraction`), `hydrateActionPlaceholders` pré-charge les entités `user[...]`, `member[...]`, `guild[...]`... utilisées dans le payload, via store puis `DiscordEntityFetcher` (désactivable par la policy). | `handler.dart:324-342` ; `utils/runtime_variables.dart:432` |
| Variables de résultat | En plus de `results`, de nombreux exécuteurs écrivent `variables['<clé>.<champ>']` et `variables['action.<clé>.<champ>']` (http, getMessage, calculate, polls, invites, threads...). `recordTrace` copie un résultat numérique dans `lastSentMessageId`/`lastMessageId`. En fin de workflow visuel : `variables['action.<clé>'] = results`. | `http_executor.dart:~125-135` ; `handler.dart:378-385` ; `workflow_executor.dart:264-267` |
| `enabled` | `if (!action.enabled) continue;` (l'action reste dans la liste : les index de `jump`/`skip` la comptent). | `handler.dart:318-320` |
| `dependOn` | Ignoré à l'exécution (voir constat 6). | `types/action.dart:152` |
| Erreurs / branches d'erreur | Exception d'un exécuteur : `variables['error.message/command/source/row/column']`, `results[clé]='Error: ...'`, puis selon `error.mode` : `stop` (rethrow, défaut), `continue`, `jump` (vers `jumpToActionId`, **en avant seulement**, sinon rethrow), `skip` (`skipCount`). `CommandExecutionTimeout` et `throwOnError` rethrow toujours. | `handler.dart:1647-1684` ; `types/action.dart:217-231` |
| Flux non local | Signaux dans `results` : `__stopped__` (propagé jusqu'à la racine, `handler.dart:432,732,858`), `__skipCount__` (`:861`), `__jumpToTargetKey__` (clé, `_actionId` ou position 1-indexée, en avant seulement, `:868-886`). | `control_flow_executor.dart:821-840` |
| Blocs imbriqués | `ifBlock` (`thenActions`, `elseActions`, `elseIfConditions[{...,actions}]`, conditions simples ou groupes `condition.group` and/or + `negate`, 20 opérateurs dont `matches`, `containsItem`, `hasPermission`), `ifBlock.tryCatch`, `ifBlock.suppressErrors(+Message/Embed)`, `forLoop` (modes simple/list/cstyle, `bodyActions`), `jsonForEachLoop`, `listenAndExecute.actions`, `respondWithModal.actions`. Chaque corps = `executeNestedActions` = nouvel appel `handleActions` (`handler.dart:221`) qui **partage** `variables`, contexte natif, budget, cache d'entités. Variables de boucle : `_loop.index`, `_loop.count`, `_loop.var.<nom>`. | `control_flow_executor.dart:462-650,846-996` |
| Replay | `onReplayCaptured` : une frame par action (`actionType`, durée, `result`, `loopDepth/Iteration`, `variablesBefore/After` tronquées à 800 entrées/500 car.), fusionnée avec les frames natives (`BdfdReplayCapture`, max 1000). Embed `$debug` séparé (`debugProfile`). | `handler.dart:210-219,289-295,378-420,1693-1753,1784-1815` ; `bdfd/replay.dart` |
| Policy / sandbox | `ActionExecutionPolicy` (`checkBudget`, `intercept`, `record`, `allowDiscordHydration`). `intercept` court-circuite **chaque** action (la sandbox simule les effets par type : ~1800 lignes dans `command_sandbox.dart:2783+`). Sans adaptateurs natifs message/HTTP, le handler refuse `runBdfdScript` sous policy. | `actions/execution_policy.dart:1-16` ; `handler.dart:423-435,766-771` |
| Interaction : ack/deferral | Auto-defer avant les actions si pas de `deferInteraction` ni de modal ; éphémère déduit de `visibility` ou d'un `respondWithMessage.ephemeral:true` ; `deferInteraction` acquitte tout de suite (`isEphemeral`) ; les réponses lisent `isInteractionAcknowledged` pour choisir edit-original/followup ; la réponse du workflow (`sendWorkflowResponse`) part après les actions. | `workflow_executor.dart:188-215,270` ; `messaging_executor.dart:506-541` ; `respond_with_message.dart:240-321` |
| Pont natif existant | `runBdfdScript` appelle `BdfdScriptExecution` (même contexte, même budget, `results` préfixés `<clé>.<k>`, `__stopped__`) ; `$callWorkflow` rappelle les blocs via `runVisualWorkflow`. | `handler.dart:765-850` ; `workflow_functions.dart:78-110` |
| Côté natif (rappel) | AST (`BdfdExpression/Conditional/Loop/JsonForEach/Try/FunctionDefinition`), arguments **paresseux et texte**, un seul `;`-split, résultats et erreurs dans `context.results`, `try` n'attrape que `BdfdNativeError`, `maxSteps=100000`, `maxDepth=128`, `skipActions/jumpToAction` comptent les statements de la liste courante. | `bdfd/program.dart:34-86` ; `bdfd/runtime.dart:81-190,486-640,1150-1170` |

Autres écarts de comportement à connaître :
- Conditions : natif `_condition` n'accepte que `true|false` ou `a OP b` et **lève** sinon (`runtime.dart:966-993`) ; les blocs renvoient `false` pour un opérateur inconnu.
- Cooldown : blocs = RAM process (`RuntimeCooldowns.expirations`, `control_flow_executor.dart:740-807`) ; natif = `StoredBotCooldownService` persistant, exige `command.id` (`cooldown_functions.dart:23-34`).
- `$error[...]` lit `context.results` (`context_functions.dart:36-55`) alors que les blocs écrivent `variables['error.*']`.

## 2. Inventaire par type (118)

Légende statut : **OK** = fonction native existante, même effet (écarts mineurs en note) ; **PART** = fonction native de même effet mais signature BDFD plus étroite
ou sémantique différente (extension nécessaire pour la parité) ; **MANQ** = aucune fonction native. « Wiki » = existence d'une page `wiki.botdesignerdiscord.com/bdscript/<nom>.html`
(vérifié contre le sommaire `toc.html`, 423 pages, et par curl sur `pinMessage`/`pinMessageComplex`, `banComplex`, `dmComplex`, etc.).

Exécuteurs (préfixe `actions/`) : `MSG`=executors/messaging_executor.dart, `REA`=executors/reactions_executor.dart, `MOD`=executors/moderation_roles_executor.dart,
`CHA`=executors/channels_executor.dart, `WEB`=executors/webhooks_executor.dart, `CMP`=executors/components_interactions_executor.dart,
`VAR`=executors/variables_executor.dart, `CTL`=executors/control_flow_executor.dart, `HTT`=executors/http_executor.dart, `LAV`=executors/lavalink_executor.dart,
`IMG`=executors/image_executor.dart, `H`=handler.dart (switch résiduel `:921-1646`). Natif : fichiers sous `engine/bdfd/`.

### 2.1 Messages

| Type | Exécuteur | Payload | Natif (mapping) | Statut | Risques |
|---|---|---|---|---|---|
| sendMessage | MSG:229 ; `services/send_message.dart` | `targetType`(channel/user/reply/crosspost), `channelId`, `userId`, `messageId`, `content`, `embeds`, `components`, `componentV2`, mentions | `$channelSendMessage[canal;texte;replyId]`, `$sendEmbedMessage[...]` (1 embed), `$dm`, `$reply[canal;msg]`, `$publishMessage[canal;msg]` | PART | Pas d'embeds multiples/composants/pièces jointes dans les fonctions BDFD. Besoin d'une extension qui appelle `BdfdMessageOutput.send(BotMessageRequest)` (déjà le même transport). Résultat : `results[k]=messageId`, `variables[k.messageId]`, `last.response.id`. Les pièces `temp._canvasAttachment_*` sont consommées à l'envoi (`:290-308`). Erreur « needs at least » avalée si contenu vide (`:325-335`). |
| editMessage | MSG:346 ; `actions/edit_message.dart` | `channelId`,`messageId`,`content`,`embeds`,`components`,`componentV2`,`clearEmbeds`,`clearComponents`,`componentMutation`,`customId`,`bdfdDelayedEdit`,`delay` | `$editMessage[canal;id;texte;titre;desc;couleur;footer]`, `$editIn`, `$editEmbedIn`, `$removeButtons[id]`, `$removeComponent` | PART | `MessageEdit` natif = content/title/description/color/footer (`message_query_functions.dart:93-135`) : pas d'embeds libres ni composants. `bdfdDelayedEdit` = `Timer` en mémoire (`:370-395`) ; natif passe par `BotTimingService`. |
| getMessage | MSG:415 ; `actions/get_message.dart` | `channelId`,`messageId` | `$getMessage[canal;id;content/authorID/username/avatar]`, `$getEmbedData`, `$getAttachments` | PART | Le bloc écrit **tous** les champs en `variables['<k>.<champ>']` ; natif = une propriété par appel. |
| deleteMessages | MSG:43 ; `actions/delete_message.dart` | `channelId`,`messageId`,`messageCount/count`,`delay`,`onlyUserId`,`reason`,`filterBots`,`filterUsers`,`removePinned`,`beforeMessageId`,`deleteItself`,`bdfdClear` | `$clear[n;userId;removePinned]` (canal courant, 1..100), `$deleteMessage[canal;id]`, `$deleteIn[durée]` | PART | `$clear` natif sans `filterBots/filterUsers/before/deleteItself/channelId` ni `reason`. Résultats `variables[k.count/mode/deleteItself]`. Délai = Timer silencieux (`:97-130`). |
| pinMessage | H:1011 ; `actions/pin_message.dart` | `channelId`,`messageId`,`reason` | `$pinMessage` (0 argument, épingle **la réponse du bot**, différé : `message_query_functions.dart:137-150`) | MANQ | Wiki : `$pinMessage[Channel ID;Message ID]` existe (page `pinMessageComplex`), mais le registre n'a que la forme 0-arg. Service existant : `MessageMutationKind.pin` (`bot_message_query_service.dart:101`). |
| unpinMessage | H:1138 | `channelId`,`messageId`,`reason` | `$unpinMessage[canal;id]` (`message_query_functions.dart:241`) | OK | Résultat bloc `'unpinned'` vs `''`. |
| deleteTrigger | MSG:438 | (aucun) lit `message.id`,`channel.id` | `$deleteCommand` (`timing_functions.dart:142`) | OK | Le bloc avale les erreurs (`'ERROR'`, `'NOT_FOUND'`) ; natif lève. |
| sendDm | MSG:471 | `userId`/`userIds`,`content`,... | `$dm[id]` + brouillon, ou `$sendMessage` après `$dm` | PART | Wiki `$dm[User ID;...]` accepte plusieurs IDs ; registre `dm` max 1 argument (`message_functions.dart:502`). Résultat = dernier `messageId`. |
| addReaction | REA:53 ; `actions/add_reaction.dart` | `channelId`,`messageId`,`emoji`/`emojis[]` | `$addMessageReactions[canal;msg;emojis...]` (`reaction_functions.dart:72`), `$addReactions[...]` (réponse) | OK | Nettoyage des échappements `<;:` côté bloc (`:30-37`) ; erreurs agrégées. |
| removeReaction | REA:105 | `channelId`,`messageId`,`emoji`,`userId`,`removeOwn` | `$removeReaction[canal;msg;user;emoji]` (`:89`) | PART | `removeOwn` sans équivalent explicite. |
| clearAllReactions | REA:117 | `channelId`,`messageId`,`emoji` | `$clearReactions[canal;msg;emoji]` (`:73`) | OK | Émoji optionnel côté bloc, obligatoire (3 args) côté natif. |

### 2.2 Interactions, composants, modals, écouteurs

| Type | Exécuteur | Payload | Natif | Statut | Risques |
|---|---|---|---|---|---|
| respondWithMessage | CMP:125 ; `services/respond_with_message.dart` | `content`,`embeds`/`embed`,`components`,`ephemeral`,`deleteAfter/deleteIn`,`messageId`,`channelId`,`replyToMessage` | Brouillon de réponse (`$title`,`$description`,`$addField`,`$ephemeral`,`$addButton`,... + sortie du script), flush = `BotMessageDestination.response` → **même** `respondWithMessage()` (`bot_message_service.dart:102`) | PART | Envoi immédiat vs bufferisé (constat 3) ; `last.response.id`, `originalResponseCompleted` (`CMP:138-143`) vs `context.response`. |
| respondWithComponentV2 | CMP:108 ; `actions/send_component_v2.dart` | `components`/`componentV2` | `$addContainer`,`$addSection`,`$addTextDisplay`,`$addMediaGallery`,... (`component_functions.dart`) ; flush route vers `respondWithComponentV2Action` (`bot_message_service.dart:90-100`) | PART | Définition JSON complète vs constructeur incrémental ; besoin d'injecter `componentState.rows` depuis le JSON. |
| sendComponentV2 | CMP:76 | idem + `channelId` | idem avec destination canal | PART | Déprécié (`types/action.dart:23`) ; l'éditeur le remappe déjà vers `respondWithComponentV2` (`builder/action_types.dart:125-126`). |
| editComponentV2 | CMP:93 ; `actions/edit_component_v2.dart` | `channelId`,`messageId`,`components`,`componentV2` | `$editSelectMenu`/`$editButton`/`$removeComponent` (partiel) | PART | Pas d'édition complète d'un message V2 en natif. |
| respondWithModal | CMP:150 ; `actions/respond_modal.dart` | `modal` (+`actions`, `onSubmitWorkflow/EntryPoint/Arguments`) | `$newModal[...]`+`$addTextInput`... (`component_functions.dart`) | PART | Natif ouvre le modal mais n'enregistre **pas** le listener de soumission (`InteractionListenerRegistry`, 1 h, one-shot, `CMP:176-208`). Le modal doit précéder tout ack (`execution.dart:133`). |
| editInteractionMessage | CMP:216 ; `actions/edit_interaction_response.dart` | `content`,`embeds`,`components`,`componentV2`,`clearEmbeds`,`clearComponents` | aucune | MANQ | Wiki : aucune fonction dédiée. Service : transport `edit_interaction_response.dart` (à extraire en `BotMessageDestination.editResponse`). |
| respondWithAutocomplete | VAR:1781 | `items`,`path`,`labelTemplate`,`valueTemplate` | aucune | MANQ | Pas de page wiki. Pose `__stopped__='AUTOCOMPLETE'`. Contexte d'interaction autocomplete spécifique. |
| deferInteraction | MSG:506 | `ephemeral` | `$defer[ephemeral]` (`timing_functions.dart:169`) | PART | Natif = simple drapeau ; l'ack réel est fait par `BdfdScriptExecution` avant le script (`execution.dart:133-150`) et nettoyé si seulement des messages canal. Le bloc acquitte immédiatement avec `isEphemeral`. |
| listenForButtonClick | CMP:234 | `customId`,`workflowName`,`entryPoint`,`arguments`,`ttlMinutes`(1..60),`messageId` | aucune | MANQ | Wiki : aucune (BDFD route les composants par commandes d'interaction). État = `InteractionListenerRegistry` en mémoire. Relance immédiate du workflow si le clic courant correspond (`:292-310`). |
| listenForSelectMenu | CMP:235 | idem | aucune | MANQ | idem |
| listenForModalSubmit | CMP:236 | idem (one-shot) | aucune | MANQ | idem |
| listenAndExecute | CMP:324 | `customId`,`actions[]`,`workflowName`,`ttlMinutes` | aucune | MANQ | Actions inline stockées dans le listener, exécutées plus tard hors du script courant (hors budget d'origine). |

### 2.3 Modération, rôles, serveur

| Type | Exécuteur | Payload | Natif | Statut | Risques |
|---|---|---|---|---|---|
| banUser | MOD:25 ; `actions/ban_user.dart` | `userId`,`reason`,`deleteMessageDays` | `$banID[raison;user]` (`moderation_functions.dart:298`) | PART | `deleteMessageDays` absent ; bloc `useDefaultReason:true`, natif `false`. Wiki : pas de `deleteMessageDays`. |
| unbanUser | MOD:26 | `userId`,`username`,`reason` | `$unbanID[user]`, `$unban` (nom) | OK | `reason` ignorée en natif. |
| kickUser | MOD:27 | `userId`,`reason`,`deleteMessageDays`,`kickPermissionActorId` | `$kick[user;raison]` | OK | `deleteMessageDays` inutile côté kick. |
| muteUser | MOD:28 ; `actions/mute_user.dart` | `userId`/`memberId`,`until`,`reason` | `$timeout[durée;user]` | PART | Bloc : date `until` ; natif : durée, `clampTimeout:false`, max 28 j. |
| unmuteUser | MOD:29 | `userId`/`memberId`,`reason` | `$untimeout[user]` | OK | |
| addRole | MOD:30 ; `actions/add_role.dart`, `role_definition_actions.dart` | `userId`/`memberId`,`roleId`,`reason`,`setRoles[]`, ou définition de rôle | `$giveRole[user;rôle]`, `$setUserRoles[user;rôles...]`, `$createRole`/`$modifyRole`/`$deleteRole` | OK | Le bloc multiplexe 3 usages (grant/setRoles/définition) : traduire par variante. `reason` ignorée en natif. |
| removeRole | MOD:31 | idem | `$takeRole[user;rôle]` | OK | |
| setNickname | MOD:32 | `userId`,`nickname`,`reason` | `$setNickname[nick;user]` (`moderation_functions.dart:393`) | OK | |
| leaveGuild | H:1074 | `guildId` | `$botLeave[guildId]` (`command_query_functions.dart:98`) | OK | |
| updateGuild | H:1062 ; `actions/update_guild.dart` | `name`,`description`,`afkChannelId`,`afkTimeoutSeconds`,niveaux de vérif/notifications,`systemChannelId`,`rulesChannelId`,`preferredLocale`,... | aucune | MANQ | Wiki : aucune. Pas de service (appel nyxx direct). |
| listMembers | H:1089 | `limit`,`after`,`query` | `$membersCount`, `$findUser`... (lectures) | MANQ | Service : `BotMemberQueryService.guildMembers`. Pas de sérialisation JSON de la liste. Wiki : aucune. |
| getMember | H:1116 | `userId`/`memberId` | getters `$memberNick`, `$memberPerms`, `$userInfo`... | PART | Le bloc renvoie un objet membre JSON ; natif = propriétés une à une. Service : `guildMember`. |
| updateAutoMod | H:1045 | `ruleId`,`enabled`,`filterWords`,`allowedRoles`,`maxMentions`,`reason` | aucune | MANQ | Wiki : aucune. Pas de service. |
| createAutoModRule | H:1404 | `name`,`triggerType`,`keywords`,`regexPatterns`,`allowedWords`,`actionType`,`timeoutDuration`,`alertChannelId`,exemptions,... | aucune | MANQ | Idem. Résultats `variables[k.ruleId/name]`. |
| deleteAutoModRule | H:1419 | `ruleId` | aucune | MANQ | |
| listAutoModRules | H:1432 | (aucun) | aucune | MANQ | Résultats `rulesJson`,`count`. |
| getGuildOnboarding | H:1446 | (aucun) | aucune | MANQ | |
| updateGuildOnboarding | H:1460 | `enabled`,... | aucune | MANQ | |
| updateSelfUser | H:1474 | `username`,`avatarUrl`/`avatarBase64`,`targetUserId` | `$changeUsername[nom]` (`bot_query_functions.dart`) | PART | Avatar absent ; garde `targetUserId != bot.id` (`H:1475-1483`). |
| registerGuildCommands | H:1498 | `guildId`,`commandNames`/définitions | `$registerGuildCommands[guildId]` (`moderation_functions.dart:383`) | PART | Natif ne transmet que le guild ; payload du bloc plus riche (à vérifier côté `register_guild_commands.dart`). |
| unregisterGuildCommands | H:1515 | `guildId`,`commandNames` | `$unregisterGuildCommands[guildId]` | PART | idem |
| createInvite | H:1236 ; `actions/invite_management.dart` | `channelId`,`maxAge`,`maxUses`,`temporary`,`unique`,`reason` | aucune | MANQ | Wiki : seulement lectures `$getInviteInfo`, `$getServerInvite`, `$getBotInvite`. Pas de service. |
| deleteInvite | H:1262 | `inviteCode`,`reason` | aucune | MANQ | |
| getInvite | H:1284 | `inviteCode` | `$getInviteInfo[...]` (`bot_query_functions.dart`) | PART | Bloc : tous les champs en variables. |
| createPoll | H:1174 ; `actions/poll_management.dart` | `channelId`,`question`,`answers[]`,`durationHours`,`allowMultiselect` | aucune | MANQ | Wiki : aucune. Résultats `messageId`,`pollId`. |
| endPoll | H:1199 | `channelId`,`messageId` | aucune | MANQ | |
| moveToVoiceChannel | H:1300 ; `actions/voice_management.dart` | `userId`,`targetChannelId` | aucune | MANQ | Wiki : aucune. Pas de service. |
| disconnectFromVoice | H:1313 | `userId`,`reason` | aucune | MANQ | |
| serverMuteMember | H:1326 | `userId`,`mute`,`reason` | aucune | MANQ | |
| serverDeafenMember | H:1339 | `userId`,`deaf`,`reason` | aucune | MANQ | |

### 2.4 Salons, fils, permissions, tickets, emojis, webhooks

| Type | Exécuteur | Payload | Natif | Statut | Risques |
|---|---|---|---|---|---|
| createChannel | CHA:33 (+ ticket H:497-538) ; `actions/create_channel.dart` | `name`,`type`,`categoryId`,`topic`,`nsfw`,`slowmode`,`reason`,`isTicket`,`welcomeMessage` | `$createChannel[nom;type;cat]` (`channel_mutation_functions.dart:11`) | PART | Natif : pas de topic/nsfw/slowmode/raison, pas d'ID renvoyé, type `announcement` refusé. `ChannelCreation` du service est plus riche. |
| updateChannel | CHA:59 ; `actions/update_channel.dart` | `channelId`,`name`,`topic`,`nsfw`,`position`,`categoryId`,`slowmode`,`archived`,`locked`,`autoArchiveDuration`,`reason` | `$modifyChannel[id;nom;topic;nsfw;pos;cat]` (`:42`) | PART | Natif : `position-1`, pas de slowmode/archived/locked/raison. Sentinelle `!unchanged` commune. |
| removeChannel | CHA:79 (+ ticketClose H:540-617) | `channelId`/`channelIds[]`/`channelNames[]`,`ticketClose`,`errorMessage` | `$deleteChannels[ids...]`, `$deleteChannelsByName[noms...]` | OK | `ticketClose` : marqueur `__ticket` en store + vérif propriétaire (bloc) vs détection par nom `ticket-*` (natif `closeticket`). |
| slowmode | CHA:126 ; `actions/slowmode.dart` | `channelId`,`duration`,`reason` | `$slowmode[canal;durée]` (`channel_mutation_functions.dart:145`) | OK | |
| editChannelPermissions | H:1610 ; `actions/channel_permissions.dart` | `channelId`,`targetId`,`targetType`,`allow`,`deny`,`permissions` | `$editChannelPerms[canal;cible;+perm...]`, `$modifyChannelPerms` | PART | Allow/deny bitfield vs syntaxe `+/-perm` : conversion nécessaire. Service `BotChannelPermissionService.editPermissions`. |
| deleteChannelPermission | H:1624 | `channelId`,`targetId` | aucune | MANQ | Le service n'expose que `editPermissions`. Wiki : aucune. |
| createThread | H:1533 ; `actions/thread_management.dart` | `name`,`channelId`,`messageId`,`type`,`autoArchiveDuration`,`slowmode`,`reason` | `$startThread[nom;canal;msg;archive;retourId]` (`thread_functions.dart:~35`) | PART | Natif sans `type`/`slowmode`/raison ; le bloc écrit `thread.lastId/lastName` (`H:1557-1558`). |
| addThreadMember | H:1561 | `threadId`,`userId` | `$threadAddMember[fil;user]` | OK | Résultat bloc `'ADDED'`. |
| removeThreadMember | H:1585 | `threadId`,`userId` | `$threadRemoveMember[fil;user]` | OK | Résultat `'REMOVED'`. |
| createEmoji | H:1353 ; `actions/emoji_management.dart` | `name`,`imageUrl`/`imageBase64`,`roles`,`reason` | `$addEmoji[nom;url;yes/no]` (`emoji_functions.dart:113`) | PART | Natif : URL seule, renvoie la mention ; le bloc renvoie un JSON + `<k>.emojiId...`. |
| updateEmoji | H:1371 | `emojiId`,`name`,`roles` | aucune | MANQ | `BotEmojiService` n'a pas `update`. Wiki : aucune. |
| deleteEmoji | H:1387 | `emojiId`,`reason` | `$removeEmoji[id]` | OK | |
| sendWebhook | WEB:23 ; `actions/send_webhook.dart` | `webhookId`/`token`/`webhookUrl`,`content`,`embeds`,`components`,`componentV2`,`username`,`avatarUrl`,`threadId`,`wait`,`createWebhook` | `$webhookCreate`,`$webhookContent`,`$webhookTitle`...,`$webhookSend` (brouillon, flush en fin : `webhook_functions.dart:15-30`) | PART | Natif : pas de username/avatar/threadId/wait/composants. `BotWebhookService.send` existe. Résultat bloc = `url` ou `webhookId`. |
| editWebhook | WEB:24 | `webhookUrl`/`webhookId`+`token`,`channelId`,... | aucune (service `update` existe) | MANQ | Wiki : aucune. |
| deleteWebhook | WEB:25 | `webhookUrl`... | `$webhookDelete[url]` | OK | |
| listWebhooks | WEB:50 | `channelId`,`guildId` | aucune | MANQ | Service sans `list`. |
| getWebhook | WEB:76 | `webhookId`,`token`/`webhookUrl` | aucune | MANQ | Service sans `get`. |

### 2.5 Variables, JSON, HTTP, calcul

| Type | Exécuteur | Payload | Natif | Statut | Risques |
|---|---|---|---|---|---|
| setTemporaryVariable | VAR:925 | `key`,`value`/`valueType`,`internal` | `$var[nom;valeur]` (`runtime.dart:1005`) | OK | Bloc écrit `temp.<k>`, `__variables.tempNames`, `<k>.value/.sourceRaw/.resolved...` (`:947-964`). `RuntimeTemporaryVariables(variables)` mappe déjà `$var` sur `temp.*`. |
| setScopedVariable | VAR:977 | `scope`,`key`,`contextId`,`value/valueType/jsonValue/numberValue/boolValue`,`ttl` | `$setUserVar/$setServerVar/$setChannelVar/$setMemberVar/$setMessageVar` (`variable_functions.dart:~150`) | PART | `VariableService.writeScoped` sans `ttl`, sans typage, **sans miroir** `variables['<scope>.<clé>']`/`<scope>[<id>].<clé>` que les templates relisent ensuite (`VAR:1097-1131`). |
| getScopedVariable | VAR:1134 | `scope`,`key`,`contextId`,`storeAs` | `$getUserVar/...` | PART | `storeAs` + miroir runtime ; `readScoped` renvoie `defaulted`. |
| removeScopedVariable | VAR:1207 | `scope`,`key`,`resetAllContexts`,`resetToDefault`,`resetUserId/GuildId` | `$resetUserVar/$resetServerVar/$resetChannelVar/$resetMemberVar` (`variable_functions.dart:68-119`) | PART | `resetAllContexts` et suppression vs remise au défaut ; cooldown spécial (`VAR:~1218`). |
| renameScopedVariable | VAR:1373 | `scope`,`oldKey`,`newKey` | aucune | MANQ | Wiki : aucune. Opération store à extraire dans `VariableService`. |
| listScopedVariableIndex | VAR:1449 | `scope`,`key`,`offset`,`limit`,`order`,`storeAs` | aucune (`$leaderboard` voisin : `leaderboard_functions.dart`) | MANQ | Wiki : aucune. |
| appendArrayElement | VAR:1506 | `target`,`scope`,`key`,`path`,`value`... | `$jsonArrayAppend` (sur le JSON en mémoire seulement) | MANQ | Natif ne persiste pas ; le bloc lit/écrit la variable stockée. |
| removeArrayElement | VAR:1578 | `path`,`index`,... | `$jsonArrayPop/Shift` (mémoire) | MANQ | idem |
| queryArray | VAR:1661 | `input`,`path`,`filterTemplate/Operator/Value`,`sortTemplate`,`order`,`offset`,`limit`,`storeAs` | `$jsonArraySort`, `$jsonArrayIndex` (partiel) | MANQ | Filtre par templates `{value}` (`resolveItemTemplate`) : pas de pendant natif. |
| setGlobalVariable | VAR:1849 | `key`,`value`/`element`,`ttl` | `$setVar[clé;valeur]` | PART | `ttl`, typage, miroir `global.<k>`. |
| getGlobalVariable | VAR:1921 | `key`,`storeAs` | `$getVar[clé]` | PART | idem |
| removeGlobalVariable | VAR:1943 | `key` | aucune (pas de `resetGlobalVar`) | MANQ | `store.removeGlobalVariable` existe ; ajouter à `VariableService`. |
| runtimeJsonBlock | VAR:1953 ; `services/json_document.dart` | `source`,`operations[{op,path,value,separator,order,indent,readIndex,forceString}]` | `$jsonParse`,`$jsonSet`,`$jsonArrayAppend`,...,`$jsonStringify` (`json_functions.dart`) | OK | Même `JsonDocument`. Écart : sous-résultats `<k>.json_<n>` (`VAR:2112-2118`) et résolution de `$jsonStringify` « dernier JSON » (`:2000-2010`). Le bloc est l'ancienne sortie du transpileur (obsolète côté natif). |
| httpRequest | HTT (tout) ; `services/http_service.dart` | `url`,`method`,`headers{}`,`bodyMode`(json/text),`bodyJson`,`bodyText`,`extractJsonPath`,`saveBodyToGlobalVar`,`saveStatusToGlobalVar` | `$httpAddHeader`+`$httpGet/Post/Put/Patch/Delete`+`$httpResult[path]`+`$httpStatus` (`http_functions.dart`) | PART | Natif : corps texte seul (pas de `bodyJson` structuré/`Content-Type` auto), pas de sauvegarde en global. Résultats : `results[k]`=corps ou valeur extraite, `variables[k.status/.body/.jsonPath]`, `http.status`, `http.body` ; natif : `context.results['http.*']`. |
| calculate | `executors/calculate_executor.dart` ; `actions/calculate.dart` | `operation`(add/sub/mul/div/mod/sqrt/abs/floor/ceil/round/negate/random/randomfloat),`operandA/B`,`expression` | `$calculate[expr]`, `$sum/$sub/$multi/$divide/$modulo/$sqrt/$floor/$ceil/$round/$random` (`runtime.dart:1227-1300`) | PART | `abs`, `negate`, `randomfloat` sans fonction ; natif strict (« Invalid arithmetic expression »). Résultat `variables[k.result]`. |
| randomChoice | VAR:1734 | `choices`(`;` ou JSON),`variableName` | `$randomText[a;b;...]` (`random_functions.dart:71`) | PART | Bloc : index `ms % n` (pas aléatoire), écrit `variables[variableName]` ; natif : `context.random`. |
| log | VAR:1987 | `message` | `$log[msg]` (`advanced_language_functions.dart:63`) | OK | |
| debugProfile | handler `:437-444,1693-1753` | `compilationMs`,`sourceLength`,`actionCount` | `$debug` = no-op | MANQ | La trace `$debug` est construite dans le handler (embed). À réimplémenter sur les événements `onTrace`. |

### 2.6 Flux de contrôle, workflows, cooldown

| Type | Exécuteur | Payload | Natif | Statut | Risques |
|---|---|---|---|---|---|
| ifBlock | CTL:462-588 | `condition.*`/`variable,operator,value`,`group`,`conditions`,`negate`,`thenActions`,`elseActions`,`elseIfConditions`,`tryCatch`,`suppressErrors(+Message/Embed)` | `BdfdConditional` / `BdfdTry` (`program.dart:49-69`) | OK | Grammaire de condition différente (constat §1) : prévoir `bc_cond`. Résultats `IF_TRUE/IF_FALSE/ELSE_IF_n/TRY_OK/TRY_CAUGHT` + `<k>.<sous>`. `tryCatch` masque/restaure `error.*` (`:464-499`). |
| forLoop | CTL:590-648,846-996 | `mode`(simple/list/cstyle),`iterations`,`init/condition/update/varNames`,`varName/values`,`bodyActions` | `BdfdLoop` (`$for[n]`, `$for[i=0;i<n;i++]`, `$loop[...]`, `runtime.dart:704+`) | OK | Variables de boucle `_loop.*` vs `$i` ; plafond `maxSteps=100000` natif absent des blocs ; résultats `LOOP_n`, `<k>.iter<i>.*`. |
| jsonForEachLoop | CTL:651-738 | `path[]`,`source`,`bodyActions` | `BdfdJsonForEach` (`runtime.dart:~660`) | OK | Le bloc lit le « dernier JSON » dans variables/résultats ; natif : `context.json`. Variables `_loop.var.jsonkey/jsonvalue/jsonindex` vs `$jsonKey`... |
| stopUnless | CTL:449 | condition | `$onlyIf[cond;msg]` (`runtime.dart:1137`) | PART | Grammaire de condition ; résultat `PASSED/STOPPED`. |
| stop | CTL:821 | (aucun) | `$stop` | OK | |
| skipActions | CTL:825 | `count` | `$skipActions[n]` | OK | Même sémantique « N suivants » ; natif compte les statements. |
| jumpToAction | CTL:833 | `targetKey` (clé, `_actionId` ou position) | `$jumpToAction[n]` (ordinal, avant seulement) | PART | Clé → ordinal à résoudre à la traduction ; clé templatée = dynamique. |
| wait | CTL:808 | `duration` | `$wait[durée]` (`timing_functions.dart:185`) | OK | `BotDelayService` injectable (utile en test). |
| cooldown | CTL:740-807 | `scope`,`key`,`duration`,`operation`(set/change),`errorMessage`(`%time%`) | `$cooldown/$globalCooldown/$serverCooldown/$changeCooldownTime` (`cooldown_functions.dart`) | PART | RAM vs store persistant, exige `command.id`, format `%time%` différent (Discord `<t:..:R>` vs libellés), clé personnalisée absente. |
| runWorkflow | CTL:348-447 | `workflowName`,`entryPoint`,`arguments` | `$callWorkflow[nom;arg=val;...]` (`workflow_functions.dart`) | OK | Les workflows visuels rappellent encore les blocs via `runVisualWorkflow` : le pont se referme quand les blocs sont natifs. Résultats `<k>.<sous>`, `workflow.response.*`. |
| runBdfdScript | CTL:322-346 | `scriptContent`,`bdfdBackend` | exécution directe (`handler.dart:765-850`) | OK | Déjà natif. Source passée telle quelle ; résultats préfixés `<k>.`. |

### 2.7 Images et musique

| Type | Exécuteur | Payload | Natif | Statut | Risques |
|---|---|---|---|---|---|
| runtimeImageBlock | VAR:1963 → IMG:96 | `operations[]`,`imageName`,... | `$canvasCreate`,`$canvasLoadImage`,`$canvasDrawText/Circle/Rect/Line`,`$canvasCompositeImage`,`$canvasProgressBar`,`$canvasSetPixel`,`$canvasInvert/Grayscale/Rotate`,`$canvasContainer` (`canvas_functions.dart`) | OK | Même `image_executor` ; rendu différé via `context.beforeFlush`. Opérations enrichies `condition`/`forEach`/`composition` (`operations_expander.dart`) sans pendant. Pièce jointe : `temp._canvasAttachment_<nom>` (bloc) vs état canvas natif. |
| canvasCreateBlock | VAR:1973 | (sous-blocs, jamais exécutés seuls) | `$canvasCreate` | OK | Types « visuels uniquement », repliés dans `runtimeImageBlock` (`VAR:1973-1985` lève sinon). |
| canvasLoadImageBlock | VAR:1974 | idem | `$canvasLoadImage` | OK | idem |
| canvasDrawTextBlock | VAR:1975 | idem | `$canvasDrawText` | OK | idem |
| canvasDrawCircleBlock | VAR:1976 | idem | `$canvasDrawCircle` | OK | idem |
| canvasDrawRectBlock | VAR:1977 | idem | `$canvasDrawRect` | OK | idem |
| canvasDrawLineBlock | VAR:1978 | idem | `$canvasDrawLine` | OK | idem |
| attachImage | VAR:967 → IMG:265 | `imageName`,`imageSource` | `$attachImage[nom]` (`canvas_functions.dart`) | PART | Le bloc charge une image (URL/data) ; le natif rend un canvas nommé. |
| playMusic | LAV:25 ; `actions/lavalink_music.dart` | `query`,`channelId`,`userId` | `$playMusic[requête;canal;user]` (`music_functions.dart:58`) | PART | Bloc : auto-injection `userId` (`H:635-662`), résultat JSON `{title,author,duration,...}` + sous-clés ; natif renvoie `''`. `BotMusicService.perform` retourne `void`. |
| pauseMusic | LAV:32 | | `$pauseMusic` | OK | Erreurs : le bloc **n'échoue pas** (`results[k]='Error: ...'`, `LAV:111-114`), natif lève. |
| resumeMusic | LAV:39 | | `$resumeMusic` | OK | idem |
| skipMusic | LAV:46 | | `$skipMusic` | OK | idem |
| stopMusic | LAV:53 | | `$stopMusic` | OK | idem |
| setMusicVolume | LAV:60 | `volume` | `$setMusicVolume[0..200]` | OK | idem |
| setMusicLoop | LAV:67 | `loop` | `$setMusicLoop[off/track/queue]` | OK | idem |
| seekMusic | LAV:74 | `position`,`positionUnit` | `$seekMusic[secondes]` | PART | Unité (ms/s) à normaliser. |
| getMusicInfo | LAV:81 | (aucun) | getters `$lavalinkPlaying/Author/Duration/Position/QueueSize/Volume/IsPaused/IsLooping` (lisent `lavalink.*` dans `variables`) | PART | Le bloc renvoie un JSON complet ; natif = lectures de variables peuplées par `_populateLavalinkVariables` (`workflow_executor.dart:65`). |
| joinVoice | LAV:88 | `channelId`,`userId` | `$joinVoice[canal]` | OK | idem |
| leaveVoice | LAV:95 | | `$leaveVoice` | OK | idem |

Total types : 118 (tous présents ci-dessus ; décompte en §2.8).

### 2.8 Bilan chiffré

| Statut | Nombre | Signification pour la migration |
|---|---|---|
| OK | 43 | Traduction mécanique vers une fonction existante (écarts de résultat/erreur à couvrir par le test de parité). |
| PART | 40 | Fonction de même effet mais signature BDFD plus étroite ou sémantique différente : fonction d'extension `bc_*` appelant le même service, ou extension de la fonction native. |
| MANQ | 35 | Aucune fonction native : pinMessage, editInteractionMessage, respondWithAutocomplete, listenForButtonClick, listenForSelectMenu, listenForModalSubmit, listenAndExecute, updateGuild, listMembers, updateAutoMod, createAutoModRule, deleteAutoModRule, listAutoModRules, getGuildOnboarding, updateGuildOnboarding, createInvite, deleteInvite, createPoll, endPoll, moveToVoiceChannel, disconnectFromVoice, serverMuteMember, serverDeafenMember, deleteChannelPermission, updateEmoji, editWebhook, listWebhooks, getWebhook, renameScopedVariable, listScopedVariableIndex, appendArrayElement, removeArrayElement, queryArray, removeGlobalVariable, debugProfile. |
| Total | 118 | |

Parmi les 35 MANQ, seuls `pinMessage` (forme `$pinMessage[canal;message]`) et, côté `PART`, `sendDm` (`$dm[id;...]`) ont un équivalent dans le wiki BDFD ; tous les autres
sont des capacités propres à BotCreator (aucune page dans le sommaire du wiki). Services déjà existants pour une partie d'entre eux : `BotMemberQueryService`
(listMembers/getMember), `BotWebhookService.update` (editWebhook), `store.removeGlobalVariable`, `MessageMutationKind.pin` ; les autres exigent un nouveau service.

## 3. Vagues de migration

Ordre = dépendances d'abord (le socle et le flux de contrôle conditionnent tout le reste), puis valeur/risque. Taille = ordre de grandeur en jours-développeur
(ingénieur connaissant le dépôt), tests de parité inclus.

| Vague | Types | Dépend de | Taille | Pourquoi / risque |
|---|---|---|---|---|
| 0. Socle | (aucun type) : traducteur, `bc_tpl`, `ResultSink`, garde d'erreurs, harnais de parité, `BdfdProgram.fromStatements` | - | L, 8-12 j | Tout le reste en dépend. Risque : design des résultats/erreurs (§4). |
| 1. Flux de contrôle | ifBlock, forLoop, jsonForEachLoop, stopUnless, stop, skipActions, jumpToAction, wait, runWorkflow, runBdfdScript, log | 0 | M, 6-8 j | Prérequis des corps imbriqués. Risque moyen : grammaire de condition, index `skip/jump`, variables `_loop.*`, plafond de pas. |
| 2. Variables, JSON, HTTP, calcul | setTemporaryVariable, runtimeJsonBlock, setScoped/getScoped/removeScopedVariable, set/get/removeGlobalVariable, httpRequest, calculate, randomChoice | 0,1 | M-L, 8-10 j | Forte valeur. Risque : miroir `variables['<scope>.<clé>']`, `ttl`, typage, extraction JSONPath, `bodyJson`. Extensions `VariableService` (remove global, rename). |
| 3. Messagerie et interactions | sendMessage, editMessage, getMessage, deleteMessages, deleteTrigger, sendDm, pinMessage, unpinMessage, deferInteraction, respondWithMessage, editInteractionMessage, addReaction, removeReaction, clearAllReactions | 0,1 | L, 10-14 j | **Valeur maximale, risque maximal** (envoi immédiat vs brouillon, ack/deferral, éphémère, `last.response.id`, pièces canvas). À faire par sous-lots : réactions/épingle d'abord, puis envoi, puis respond*. |
| 4. Rôles, modération, fils | banUser, unbanUser, kickUser, muteUser, unmuteUser, addRole, removeRole, setNickname, createThread, addThreadMember, removeThreadMember, leaveGuild, updateSelfUser, register/unregisterGuildCommands | 0 | S-M, 4-6 j | Services déjà partagés (`BotModerationRequest` est le sur-ensemble). Risque faible ; attention `useDefaultReason`, `deleteMessageDays`, `until`. |
| 5. Salons et tickets | createChannel, updateChannel, removeChannel, slowmode, editChannelPermissions, deleteChannelPermission | 0,2 | M, 5-7 j | Extension de `ChannelCreation`/`Modification` (champs déjà dans le service). Tickets : choisir marqueur store vs nom (question ouverte). |
| 6. Composants, modals, écouteurs | respondWithComponentV2, sendComponentV2, editComponentV2, respondWithModal, listenForButtonClick, listenForSelectMenu, listenForModalSubmit, listenAndExecute, respondWithAutocomplete | 0,1,3 | L, 10-15 j | Les écouteurs exigent un modèle de déclenchement différé (registre en mémoire, TTL, one-shot) : décision de conception avant code. |
| 7. Images | runtimeImageBlock, canvas*Block (6), attachImage | 0,3 | S, 2-3 j | Même `image_executor` ; risque limité au rendu différé et à la pièce jointe. |
| 8. Musique | playMusic, pauseMusic, resumeMusic, skipMusic, stopMusic, setMusicVolume, setMusicLoop, seekMusic, getMusicInfo, joinVoice, leaveVoice | 0 | S-M, 3-4 j | `BotMusicService.perform` doit renvoyer des données (titre, durée...) ; alignement des erreurs (bloc silencieux vs natif qui lève). |
| 9. Hors catalogue BDFD (services à extraire) | sendWebhook, editWebhook, deleteWebhook, listWebhooks, getWebhook, createEmoji, updateEmoji, deleteEmoji, listMembers, getMember, getInvite, createInvite, deleteInvite, createPoll, endPoll, moveToVoiceChannel, disconnectFromVoice, serverMuteMember, serverDeafenMember, updateGuild, updateAutoMod, createAutoModRule, deleteAutoModRule, listAutoModRules, get/updateGuildOnboarding, appendArrayElement, removeArrayElement, queryArray, renameScopedVariable, listScopedVariableIndex, debugProfile | 0,2 | XL, 15-22 j | Aucune fonction BDFD : définir des fonctions d'extension `bc_*` + services (`BotInviteService`, `BotPollService`, `BotVoiceService`, `BotAutoModService`, `BotGuildAdminService`). Faible risque sémantique, large volume. Peut être différée ou laissée en « blocs visuels natifs » via `bc_*`. |
| 10. Retrait | `handler.dart`, `executors/*`, `intercept` sandbox, copie `app/.../bot_actions/handler.dart` | toutes | M, 4-6 j | Suppression + migration des tests (13 fichiers `shared/test` utilisent `handleActions/executeActions`). |

Total indicatif : 75-110 j-dev, dont ~25 % de tests de parité. Les vagues 3 et 6 portent l'essentiel de l'incertitude.

Gabarit de test de parité par type (réutilise la sandbox et les doubles existants) : même `Action` exécutée (a) par l'ancien chemin `handleActions` et (b) par le nouveau chemin,
avec la même `ActionExecutionPolicy`/services simulés (`command_sandbox.dart`), puis comparaison de : effets enregistrés (ordre, cibles, payload), `results`,
variables finales, erreurs (message normalisé), nombre d'appels au budget. Précédent : `test/bdfd_native_action_bridge_test.dart` (policy `_Policy`, `_Messages`, `_Store`).

## 4. Architecture de traduction proposée

### 4.1 Emplacement

Nouveau dossier `engine/bdfd/visual/` (le runtime et l'AST restent indépendants de `Action`, comme l'exige `docs/architecture/bdfd-runtime-migration.md:21-22` ;
la dépendance va de l'adaptateur vers le moteur, jamais l'inverse) :

| Fichier | Rôle |
|---|---|
| `action_translator.dart` | `BdfdActionProgram translate(List<Action>)` : fonction pure, sans effet. Produit un `BdfdProgram` + table `statement → Action` (clé, index) pour diagnostics/replay. |
| `action_functions.dart` | Registre `bdfdVisualFunctions(...)` : fonctions internes `bc_<type>` (une par type quand la fonction BDFD est trop étroite), `bc_tpl`, `bc_cond`, `bc_loopvars`, `bc_result`. Enregistré dans `BdfdEngine(functions: ...)` (paramètre existant `engine.dart:97`). |
| `action_results.dart` | `ResultSink` : écrit `results[clé]`, `results['clé.sous']`, miroir `variables[...]` (mêmes clés que les exécuteurs actuels). |
| `action_runner.dart` | `BdfdActionExecution` : équivalent de `BdfdScriptExecution` pour une liste d'actions (ack/defer, budget, replay, policy). Remplace `handleActions` ; `handleActions` devient un shim pendant la migration. |

Prérequis moteur (petits) : (a) un constructeur public `BdfdProgram.fromStatements(source, statements)` (`program.dart:104`, constructeur privé `BdfdProgram._`) ;
(b) une `source` synthétique (une ligne par action, ex. `#3 sendMessage key=welcome`) pour que `BdfdLocation`/`_location` (`runtime.dart:353`, `substring(node.start,node.end)`)
et les frames de replay restent valides ; (c) option `maxSteps` configurable (`BdfdContext(maxSteps)` existe déjà, `runtime.dart:92`).

### 4.2 AST direct, pas de source BDFD générée

Construire directement `BdfdFunctionCallAst(name, arguments)` avec des `BdfdTextAst` littéraux. Générer du texte BDFD puis le parser exposerait aux problèmes d'échappement
(`;`, `]`, `$` dans les données) et contredirait la règle « les arguments évalués sont des données » (`runtime.dart:226`). Les valeurs de payload passent en **un argument JSON
littéral** (`$bc_sendMessage[{"content":"((user.name))","embeds":[...]}]`) ; la fonction décode puis résout chaque chaîne avec le même résolveur que `resolveValue`
(équivalent de `_resolveJsonLike`, `http_executor.dart:27-39`).

### 4.3 Templates `((...))`

- Aucune modification du lexer/runtime : `bc_tpl[brut]` = fonction interne qui exécute `resolveTemplatePlaceholders(brut, vue)`. `vue` = `variables` surchargée par les résultats courants, avec
  la **même priorité que `resolveValue`** (clé exacte puis préfixe `action.` dans les résultats, puis template ; `handler.dart:257-274`). Elle doit rester `async`-safe : les valeurs lues sont déjà du texte.
- Placement : tout argument/chaîne de payload contenant `((` est emballé dans un nœud `bc_tpl` (ou résolu dans le JSON de la fonction `bc_*`). Les chaînes sans `((` restent littérales (pas de coût).
- Hydratation d'entités : `hydrateActionPlaceholders` doit être appelé avant chaque statement visuel (hook `beforeStatement` dans `bc_tpl`/`bc_*` ou prélude `bc_hydrate`), pour ne pas déplacer les fetch avant un `deferInteraction` (`handler.dart:321-324`).
- Variables de boucle : `bc_loopvars` en tête de corps recopie `$i`/`loopvariable` vers `variables['_loop.index'|'_loop.count'|'_loop.var.<nom>']` (comportement actuel) ; il faut décaler d'un cran les ordinaux de `jump/skip` dans ce corps.

### 4.4 Flux de contrôle

| Bloc | Traduction native |
|---|---|
| Liste d'actions | Une `BdfdStatement` **par action, y compris désactivée** (no-op `$c[]`) pour conserver les ordinaux utilisés par `skip/jump` (`handler.dart:318`, `runtime.dart:551-562`). |
| `ifBlock` | `BdfdConditional(branches)` ; chaque condition = `bc_cond[json]` renvoyant `true`/`false` (la grammaire native refuse le reste, `runtime.dart:966`) ; `bc_cond` réutilise `_evaluateCondition` extrait vers `services/` (20 opérateurs, groupes, négation). |
| `ifBlock.tryCatch` | `BdfdTry(body, catchBody)` ; `catch` copie `error.*` vers `variables` et `results` (les deux lecteurs : `((error.message))` et `$error`). |
| `suppressErrors` | `BdfdTry` + `catch` qui envoie le message/embed via `bc_respondWithMessage` (pas `$suppressErrors`, qui est global au script). |
| `forLoop` | `BdfdLoop` : `simple` → `$for[n]`, `cstyle` → `$for[init;cond;update]`, `list` → `$loop[var;a;b;...]` ; le nœud d'ouverture est fabriqué pour `BdfdLoopSyntax.parse`. |
| `jsonForEachLoop` | `BdfdJsonForEach` (chemin en arguments littéraux/`bc_tpl`). |
| `stop`/`stopUnless` | `$stop` / `$onlyIf[bc_cond;]`. |
| `skipActions` | `$skipActions[n]`. `jumpToAction` : clé résolue en ordinal à la traduction ; clé templatée : `bc_jump[json{table clé→ordinal}]` qui positionne `_pendingJump` via la même voie que `$jumpToAction`. |
| Mode d'erreur d'une action | `stop` = rien (l'erreur remonte) ; `continue` = `BdfdTry` à `catch` vide ; `jump`/`skip` = `BdfdTry` dont le `catch` appelle `$jumpToAction[n]`/`$skipActions[n]` (un seul statement par action : ordinaux préservés). `CommandExecutionTimeout` n'est pas attrapé par `BdfdTry` (`runtime.dart:617`), comme aujourd'hui (`handler.dart:1655`). |
| Erreurs non natives | Chaque `bc_*` enveloppe en `BdfdNativeError(message, location, cause)` (patron `guarded` de `thread_functions.dart:5-14`) afin que `BdfdTry` et `$catch` les voient. Le texte `Error: ...` dans `results[clé]` est conservé via `ResultSink`. |

### 4.5 Résultats et erreurs exposés aux actions suivantes

- Un `ResultSink` unique par exécution écrit exactement ce qu'écrivent les exécuteurs aujourd'hui : `results[clé]`, `results['clé.sous']` ET `variables['clé.sous']` / `variables['action.clé.sous']`
  (liste par type en §2). Il vit dans `context.results` (déjà lu par `$error`, `$callWorkflow`, la sandbox : `command_sandbox.dart:~500`).
- Portée : par défaut **imbriquée comme aujourd'hui** (une action de corps ne lit pas `results` du parent ; le parent reçoit `clé.sous` / `clé.iterN.sous`). Implémentation : pile de portées dans `ResultSink`.
- `__stopped__` est remplacé par `context.stopped` (déjà propagé par le runtime) ; `__skipCount__`/`__jumpToTargetKey__` disparaissent.
- `error.*` : écrit dans `variables` (templates) **et** `context.results` (`$error`) ; restauré après un `tryCatch` (`control_flow_executor.dart:464-499`).
- Sandbox : les policies n'interceptent plus les `Action` ; elles fournissent des services simulés (déjà le cas pour messages/modération/HTTP, `command_sandbox.dart:430-436`). Cela supprime `intercept` (~1800 lignes) en vague 10.

### 4.6 Budget, replay, sandbox

- Budget : même instance `CommandExecutionBudget` (`BdfdContext.budget`) ; `executeProgram` l'enveloppe déjà (`runtime.dart:332`). Attention au plafond `maxSteps=100000` (absent aujourd'hui côté blocs).
- Replay : les `bc_*` portent le nom du type (`actionType` = `location.functionName`, `replay.dart:19`) ; ajouter à `BdfdReplayCapture` les snapshots `variablesBefore/After` et un champ `actionKey`, sinon régression de l'UI de replay (frames natives sans variables, plafond 1000).
- Ack/deferral : `BdfdActionExecution` reprend la logique de `executeVisualWorkflow` (`workflow_executor.dart:188-215`: défer auto, éphémère déduit, pas de défer si `deferInteraction`/modal) et celle de `BdfdScriptExecution` (nettoyage du placeholder, `execution.dart:133-175`). `translate()` expose `hasModal`, `hasDefer`, `ephemeralHint`.
- Migration incrémentale : routage **par type** dans `_handleActions` (`translator.supports(type)` → programme natif d'une action partageant le contexte ; sinon exécuteur historique). Un `ifBlock` natif dont un enfant n'est pas encore supporté délègue cet enfant via `bc_legacy[actionJson]` (choix statique à la traduction, jamais un repli après erreur : règle de `bdfd-runtime-migration.md:~30-32`).

### 4.7 Compatibilité du format JSON de l'éditeur

- Le format persisté ne change pas : `{type,key,enabled,depend_on,error,payload}` (`types/action.dart:168-193`). Le traducteur est en lecture seule sur `Action`.
- `depend_on` reste écrit (toujours `[]`) et ignoré. Les clés héritées du transpileur (`bdfdClear`, `bdfdDelayedEdit`, `bdfdBackend`, `_actionId`, `_debugLoop*`) continuent d'être lues ; une passe de normalisation optionnelle pourra les convertir.
- `CommandMigration` (`utils/command_migration.dart`, injection de `deferInteraction`) et l'éditeur (`builder/action_type_extension.dart`, 3500 lignes) restent inchangés.
- Bonus : `translate()` + `BdfdEngine.validation().prepare()` donnent à l'éditeur des diagnostics d'arité/capacité sur les blocs sans effet (`engine.dart:282`).

## 5. Questions ouvertes pour le propriétaire

1. **Fidélité visée par type** : parité avec le bloc actuel (fonctions d'extension `bc_*`) ou adoption de la sémantique BDFD stricte (ex. `useDefaultReason:false`, `$kick` défaut auteur, tickets par nom `ticket-*`, cooldown persistant, brouillon bufferisé) ? Recommandé : parité des blocs, BDFD intact pour les scripts.
2. **Visibilité des fonctions `bc_*`** : cachées du catalogue/autocomplétion (`bdfd_functions.dart`, audit `bdfd-native-registry-audit.json` les classerait « registeredOutsideCatalogue ») ou exposées comme extensions documentées (précédent : musique) ?
3. **AST synthétique vs source** : accepter `BdfdProgram.fromStatements` + source synthétique (recommandé) ou générer du BDFD échappé ?
4. **Portée des résultats** : conserver l'isolation parent/enfant (recommandé pour la parité) ou rendre les résultats globaux (additif, mais change la résolution de `((action_0))` dans les boucles) ?
5. **Plafond de pas** (`maxSteps=100000`, `maxDepth=128`) pour des blocs qui n'avaient que le budget temps de 15 min : relever, ou imposer comme nouvelle limite ?
6. **Envoi immédiat** : les extensions d'envoi doivent-elles flusher le brouillon avant chaque envoi (comme `$channelSendMessage`) ou ignorer le brouillon ?
7. **Écouteurs, autocomplete, modals inline** (`listen*`, `respondWithAutocomplete`, `respondWithModal.actions`) : porter `InteractionListenerRegistry` tel quel derrière des fonctions `bc_listen*`, concevoir un vrai `$awaitComponent`, ou laisser ces types sur l'exécuteur historique plus longtemps ?
8. **Types sans fonction BDFD** (35 `MANQ`, dont ~30 en vague 9) : créer services + fonctions d'extension (polls, invites, voice, automod, onboarding, guild admin, listes de webhooks, tableaux persistés) maintenant, ou les garder comme exceptions documentées du retrait de `handler.dart` ?
9. **Routage mixte pendant la migration** (par type, `bc_legacy`) vs bascule par workflow « tout natif ou rien ».
10. **Replay** : acceptable de réduire/faire évoluer le format de frames (variables avant/après, plafond 1000) ou doit-il rester identique ?
11. **Erreurs Lavalink** : les blocs avalent l'erreur (`'Error: ...'` en résultat) ; aligner sur le natif (lève) change le comportement des workflows existants.
12. **Copie `app/.../bot_actions/handler.dart`** : confirmer qu'elle est morte et la supprimer dès la vague 0.
13. **`debugProfile`/embed trace** : le réimplémenter sur `onTrace` ou le retirer ?
14. **Variables `((...))` d'un workflow appelé** : `$callWorkflow` expose `workflow.response.*` ; garder ce contrat pour les blocs `runWorkflow` (oui par défaut).

## 6. Décisions du propriétaire (4 octobre 2026)

- Fidélité : **parité des blocs** (fonctions d'extension `bc_*`), les scripts BDFD gardent la sémantique du wiki.
- Visibilité : fonctions `bc_*` **cachées** (hors catalogue et autocomplétion, listées comme `registeredOutsideCatalogue` par l'audit).
- Types sans fonction BDFD (vague 9) : **migrés aussi** (services + fonctions d'extension), pour supprimer entièrement `handler.dart`.
- Transition : **routage par type** (types migrés sur le natif, les autres sur l'exécuteur historique dans le même workflow, choix statique à la traduction, jamais de repli après erreur).
- Par défaut (recommandations de l'inventaire) : AST synthétique (`BdfdProgram.fromStatements`), portée des résultats imbriquée comme aujourd'hui, workflows appelés gardent `workflow.response.*`, copie `app/.../bot_actions/handler.dart` supprimée en vague 0 si confirmée morte.

## 7. Vague 1 : flux de contrôle (réalisée)

Fichiers : `engine/bdfd/visual/control_flow_actions.dart` (handlers `bc_<type>` + fonctions cachées `bc_loopnext`, `bc_tryenter`, `bc_trycatch`, `bc_tryexit`, `bc_suppress`), `control_flow_state.dart` (état d'exécution des boucles/try, marqueurs d'itération), tests `visual_control_flow_parity_test.dart` et `visual_control_flow_runtime_test.dart`.

- **Boucles** : `forLoop` (simple/list/cstyle) et `jsonForEachLoop` sont un `$while` natif dont la condition `bc_loopnext` avance l'état (variables `_loop.*`, résultat `LOOP_n` / `JSONFE_n`, nettoyage). Aucun statement n'est ajouté dans les corps : **les ordinaux de `skipActions`/`jumpToAction` ne sont pas décalés** (écart volontaire par rapport au §4.3 qui prévoyait un prologue `bc_loopvars`). Les résultats d'une itération vivent sous `<clé>.iter<N>` grâce à un marqueur de chemin résolu à l'exécution.
- **Limite du runtime levée** (additif) : `BdfdTry` accepte des appels de cycle de vie (`enter`/`onCatch`/`exit`) et `BdfdContext.requestSkip/requestJump(outer: true)` fait remonter la demande faite depuis un corps `catch` à la liste qui contient le `try` : c'est ainsi qu'un mode d'erreur `skip`/`jump` sur un bloc est appliqué. `tryCatch` et `suppressErrors` sont natifs.
- **`runWorkflow` / `runBdfdScript`** : même code que l'exécuteur historique (`executeControlFlowAction`) via les fermetures du handler (`VisualControlAdapter`), donc `workflow.response.*` et les résultats `<clé>.<sous>` sont inchangés. Un script lancé depuis un programme visuel repart d'un état vierge (`BdfdContext.startScript`) comme avant.
- **Plafond de pas** : `defaultVisualMaxSteps = 1 000 000` par programme visuel (`handleActions(visualMaxSteps:)`). Les blocs n'avaient que le budget de 15 min ; 1 M de pas ≈ 100 000 itérations d'un corps à une action (un tour de boucle coûte une dizaine de pas), assez pour tout usage réel (chaque action est en pratique un appel Discord) tout en stoppant une boucle C-style infinie en quelques secondes. Le plafond de l'hôte (100 000 pour un script) l'emporte s'il est plus proche.
- **Replay** : `BdfdReplayCapture` ajoute `actionKey`, `visualActionType` et, sur la trame de fin d'appel, `variablesBefore`/`variablesAfter` aux appels `bc_*` ; le format existant est inchangé. `execution.time` est rafraîchi avant chaque action native imbriquée.
- **Écarts connus** : un `jumpToAction` numérique vers l'arrière, imbriqué dans un bloc natif, échoue (« can only jump to a later action ») au lieu de boucler ; au niveau racine le comportement historique est conservé. Un `timeout` du budget dans un corps `tryCatch` n'exécute pas la liste `catch`.

## 8. Vague 6 : composants, modals, écouteurs (note de conception)

Types : `respondWithComponentV2`, `sendComponentV2`, `editComponentV2`, `respondWithModal` (y compris `actions` en ligne et `onSubmit*`), `listenForButtonClick`, `listenForSelectMenu`, `listenForModalSubmit`, `listenAndExecute`, `respondWithAutocomplete`. Fichiers : `engine/bdfd/visual/component_actions.dart` (composants V2, modal, autocomplete) et `engine/bdfd/visual/listener_actions.dart` (écouteurs).

**Modèle de déclencheur différé (décision du propriétaire : parité avec les blocs actuels).**

- Aucun `$awaitComponent` n'est créé. Un écouteur n'est pas une attente dans le script : c'est un enregistrement dans `InteractionListenerRegistry` (mémoire du processus, TTL 1..60 min pour `listen*`, 1 h pour le modal, `oneShot` pour modal, répété pour bouton/select, `listenAndExecute` inscrit trois entrées bouton+select+modal). Le programme natif se termine ; plus tard `handleComponentInteraction` retrouve l'entrée et exécute le workflow nommé (`runListenerWorkflow`) ou les actions en ligne (`runListenerInlineActions`) dans une **nouvelle** exécution, hors budget et hors variables du script d'origine (seul `initialContext` est transmis). Cette exécution différée passe elle-même par `handleActions` et donc par le routage natif par type.
- Le registre, `ListenerEntry`, les règles de correspondance (`messageId`, garde « workflow d'événement sans messageId explicite »), le plafonnement TTL, l'exécution immédiate quand le clic courant porte le même `customId` (`unawaited`) et les résultats (`listening:<customId>`, `customId` du modal, `RESPONDED` + `__stopped__ = AUTOCOMPLETE` pour l'autocomplete) restent **strictement inchangés**.
- Les fonctions sont les `bc_<type>` cachées habituelles (`bc_listenforbuttonclick`, `bc_listenforselectmenu`, `bc_listenformodalsubmit`, `bc_listenandexecute`, `bc_respondwithmodal`, ...) : hors catalogue/autocomplétion, listées `registeredOutsideCatalogue` par l'audit, absentes du registre de production.
- Stratégie de parité identique à la vague 2 : les handlers appellent le **même code** que la boucle historique (`executeComponentsInteractionsAction`, `executeVariablesAction` pour l'autocomplete) avec l'état du moteur natif (`ResultSink`, variables partagées, `client`, `lavalinkService` ajoutés à `ActionRunEnvironment`). Effets, clés de résultats, variables, textes d'erreur et modes d'erreur sont donc identiques par construction ; le test de parité le vérifie.
- Règles d'acquittement conservées : le modal doit être la première réponse (`BdfdActionProgram.hasModal` supprime l'auto-defer), `respondWithModal` marque l'interaction acquittée, aucune réponse après un modal n'est ajoutée par le moteur. `respondWithAutocomplete` stoppe la liste : `__stopped__` vaut `AUTOCOMPLETE` au niveau de l'action et `true` aux niveaux englobants, comme aujourd'hui.
- Le futur envoi/réponse de message (vague 3, `message_actions.dart`) n'est pas utilisé : les V2 passent déjà par `respondWithComponentV2Action` / `sendComponentV2Action` / `editComponentV2Action`, services partagés avec le transport du natif.

## 9. Vague 3 : messagerie et interactions (réalisée)

Fichiers : `actions/message_block_actions.dart` (corps partagés `pinMessageBlock`, `unpinMessageBlock`, `respondWithMessageBlock`, `editInteractionMessageBlock`, extraits de la boucle et de l'exécuteur composants), `engine/bdfd/visual/message_actions.dart` (handlers `bc_<type>` + helpers stables), tests `visual_message_actions_parity_test.dart` (réactions, épingle, deleteMessages/deleteTrigger/getMessage), `visual_message_send_parity_test.dart` (sendMessage, sendDm, editMessage), `visual_interaction_actions_parity_test.dart` (deferInteraction, respondWithMessage, editInteractionMessage, brouillon, métadonnées d'ack), doubles dans `test/helpers/visual_message_gateway.dart`.

- **Même code, deux chemins** : un `bc_<type>` appelle les mêmes fonctions d'effet que l'exécuteur historique (`executeMessagingAction`, `executeReactionsAction`, `*Block`), nourries des mêmes valeurs résolues (`call.resolve`, `sink.scope(path)`, `variables`). Effets Discord, `results[clé]`, miroirs (`<clé>.messageId`, `last.response.id`, `<clé>.count/mode`, `action.<clé>.status`), pièces canvas (`temp._canvasAttachment_*` consommées), embeds/composants, mentions autorisées et textes d'erreur sont donc identiques. Les types ne passent pas par une fonction BDFD plus étroite (`$channelSendMessage`, `$clear`...) : ce choix évite toute perte de champ (§0.2).
- **Envoi immédiat, jamais le brouillon** : le runner met `context.output` de côté pendant un programme visuel et le restitue ensuite. Un bloc n'ajoute, ne consomme ni ne flush le brouillon d'un script hôte (test avec un `BdfdOutput` espion). Décision 6 de §5 : « ignorer le brouillon ».
- **Ack/éphémère** : `deferInteraction` acquitte tout de suite ; `respondWithMessage` choisit réponse initiale / edit-original / followup selon `isInteractionAcknowledged` et positionne `context.response` (`acknowledged`, `originalResponseCompleted`) comme avant ; le défer automatique avant les actions reste dans `executeVisualWorkflow`, alimenté par `hasDefer`/`hasModal`/`ephemeralHint` du traducteur (testés). Une action `deferInteraction` imbriquée dans un bloc natif n'hydrate plus ses entités avant d'acquitter (la boucle historique ne le faisait pas non plus).
- **Salon de repli** : comme avant, `respondWithMessage` et `pinMessage` reçoivent le salon de repli brut dans la liste racine et le salon résolu (repli ou salon de l'interaction) dans les listes imbriquées ; `unpinMessage` et les autres reçoivent toujours le salon résolu (`visualComponentFallbackChannel`, `visualResolvedFallbackChannel`).
- **Trace** : `pinMessage`/`unpinMessage` (traités dans le `switch` historique) n'enregistrent leur trace (et le « dernier message » numérique) que sous profilage (`messageProfilingOnlyTraceTypes`) ; les autres types la gardent toujours.
- **suppressErrors** : le message/embed d'erreur passe par `visualRespondWithMessage` (immédiat, même hydratation, mêmes variables d'erreur et `lastSentMessageId`, liste de résultats jetée), sans liste historique imbriquée. Plus aucune dépendance de `bc_suppress` envers l'adaptateur de workflow pour ce message.
- **Tout-ou-rien levé** : `ifBlock` (y compris `tryCatch`/`suppressErrors`), `forLoop` et `jsonForEachLoop` dont les enfants sont ces types sont natifs ; un bloc ne reste historique que s'il contient encore un type non migré.
- **API stable pour la vague 6** : `visualClient(call)`, `visualResolvedFallbackChannel(env)`, `visualComponentFallbackChannel(call)`, `visualFallbackMessageId(variables)`, `visualMessagePayload(call)` (résolution des champs runtime de composants pour une action imbriquée) et `visualRespondWithMessage(env, context, path:, payload:)`.
- **Écarts connus** : les `Timer` des suppressions/éditions différées (`delay`, `bdfdDelayedEdit`, `deleteAfter`) restent des minuteries mémoire silencieuses (comme avant, hors budget). `env.client` (ajouté par la vague 6) porte le client Discord.

## 10. Vague 9b : sondages, vocal, AutoMod, serveur, onboarding (réalisée)

Types : `createPoll`, `endPoll`, `moveToVoiceChannel`, `disconnectFromVoice`, `serverMuteMember`, `serverDeafenMember`, `updateGuild`, `updateAutoMod`, `createAutoModRule`, `deleteAutoModRule`, `listAutoModRules`, `getGuildOnboarding`, `updateGuildOnboarding`. Fichiers : `engine/bdfd/visual/admin_actions.dart` (handlers `bc_<type>`), nouveaux services `services/bot_poll_service.dart`, `bot_voice_service.dart`, `bot_automod_service.dart`, `bot_guild_admin_service.dart`, test `visual_admin_actions_parity_test.dart` + double `test/helpers/visual_admin_gateway.dart`.

- **Logique déplacée dans les services** : les corps de `actions/poll_management.dart`, `voice_management.dart`, `update_automod.dart`, `automod_management.dart`, `update_guild.dart` et `guild_onboarding.dart` vivent maintenant dans `BotPollService`, `BotVoiceService`, `BotAutoModService` et `BotGuildAdminService` (interface + adaptateur `DiscordBot*Service`). Les fonctions historiques (`createPollAction`...) ne sont plus que des délégateurs de même signature, donc le chemin historique et le chemin natif exécutent le même code ; la vague 10 supprimera les délégateurs. `BotBlockActionService.leaveGuild` continue d'appeler `updateGuildAction` (`leave: true`).
- **Branchements de la boucle reproduits** : pré-vérification de permission du bot pour les sondages (cache d'exécution partagé, `create polls` / `end polls`, avant toute validation), résolution champ par champ identique (`updateAutoMod` ne résout que `ruleId`, `endPoll` résout ses deux identifiants puis le payload entier, `updateGuildOnboarding` n'a aucun effet : l'erreur « not supported by the current nyxx runtime yet » est conservée), `results[clé]`, miroirs `<clé>.messageId/pollId/ruleId/name/rulesJson/count/onboardingJson/enabled`, textes d'erreur `Exception: ...`. Trace uniquement sous profilage (`adminProfilingOnlyTraceTypes`, types du `switch`).
- **Services injectables** : `ActionRunEnvironment` gagne `pollService`, `voiceService`, `autoModService`, `guildAdminService` (facultatifs) ; absents, l'adaptateur Discord est construit sur `env.client`, donc `handler.dart` n'a pas changé.
- **`debugProfile` reste historique (écart assumé)** : ce n'est pas un effet, c'est un état local à chaque appel de `handleActions` (chronomètre, liste de trace, métadonnées de compilation) qui enregistre une entrée par action **de sa propre liste** (profondeur/itération de boucle lues dans `_debugLoop*`, entrées d'erreur, aucune sortie si `__stopped__`) puis envoie l'embed en fin de liste. Les hooks natifs `onTrace`/replay observent chaque appel `bc_*` (y compris dans les corps imbriqués), sans notion de « liste courante » ni des types encore historiques : un embed identique n'est donc pas reproductible tant que la boucle de `handleActions` reste le pilote (vague 10). Le type n'est pas supporté par le traducteur (test de routage) et son état/embed sont inchangés ; à refaire sur le runner natif quand `handler.dart` disparaît.

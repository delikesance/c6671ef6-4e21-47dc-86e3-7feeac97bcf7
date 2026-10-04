# Métadonnées et requêtes de commandes BDFD natives

Date : 4 octobre 2026.

Le module `command_query_functions.dart` fournit `$botCommands`,
`$commandsCount`, `$commandName`, `$commandTrigger`, `$commandFolder`,
`$slashCommandsCount`, `$slashID`, `$getBotInvite` et `$botLeave`.

Les définitions viennent du stockage de l'application, relu avec
`forceRefresh: true`. Les noms préfixés utilisent le préfixe configuré et le
déclencheur effectif ; les alias ne créent pas de définitions supplémentaires.
La liste des commandes slash vient d'une lecture REST des commandes globales
Discord, filtrée sur `chatInput`. Les menus contextuels en sont exclus.

Les adaptateurs de commandes renseignent le nom enregistré, le dossier et le
déclencheur réellement utilisé. Un alias préfixé conserve le token saisi et le
préfixe configuré. Une commande slash inclut sa route de sous-commande dans le
déclencheur. `$slashID` sans argument lit l'identifiant de la commande Discord,
distinct de celui de l'interaction. Les métadonnées absentes produisent une
erreur localisée ; un dossier non défini reste une chaîne vide.

Les lectures, départs de serveur et consultations REST partagent le budget
d'exécution. Les fonctions appliquent la validation des arités avant les effets.
Les valeurs renvoyées restent des données, même lorsqu'elles contiennent du
BDFD. L'invitation utilise l'identifiant de l'application et les permissions
configurées par le produit. `$botLeave` utilise le serveur courant ou un
identifiant explicite validé.

Les tests ciblés couvrent les sources distinctes, les mises à jour du stockage,
les identifiants, les métadonnées, les effets ordonnés, les budgets expirés,
les erreurs et les arguments inconnus opaques. Les tests de `$customID`
vérifient aussi les boutons, sélecteurs et modals à partir de l'adaptateur
d'interaction ; cette fonction reste limitée aux callbacks composants/modals.

La sandbox utilise des listes explicites dans les fixtures d'entités :
`commands` contient les noms affichés (préfixe inclus) et
`global_slash_commands` les objets `id`/`name`. Une liste absente est une
erreur, une liste vide représente un résultat vide. Le départ modifie seulement
la fixture du serveur et enregistre un effet simulé. Les blocs BDFD natifs d'un
workflow visuel reçoivent le même adaptateur ; ils ne peuvent pas ouvrir une
connexion Discord réelle.

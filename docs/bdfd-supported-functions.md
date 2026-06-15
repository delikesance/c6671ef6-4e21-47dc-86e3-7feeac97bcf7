# Fonctions BDFD supportees dans Bot Creator

Etat de reference: 30/03/2026.

Ce document decrit ce qui est pris en charge par le transpiler BDFD de Bot Creator.

## Niveaux de support

- Support complet: transpilation dediee vers action(s) runtime attendues.
- Support transpilation placeholder: la fonction est resolue en placeholder texte `((...))`.
- Support partiel: accepte syntaxe/fonction, mais comportement simplifie ou differant de BDFD.
- Non supporte: diagnostic `Unsupported BDFD function for action transpilation`.

## Fonctions supportees (actions)

### Controle de flux

- if
- onlyIf
- onlyForUsers
- onlyForIDs
- onlyForChannels
- onlyForRoles
- onlyForRoleIDs
- onlyForServers
- onlyForCategories
- ignoreChannels
- onlyNSFW
- onlyAdmin
- onlyPerms
- onlyBotPerms
- onlyBotChannelPerms
- checkUserPerms
- checkUsersPerms
- onlyIfMessageContains
- stop

### Bloc conditionnel

- if ... elseif ... else ... endif

### Boucles bloc

- for[n] ... endfor
- loop[n] ... endloop
- for[init; condition; update] ... endfor (C-style)

Note: les boucles avec des valeurs statiques sont deroulees au compile-time (limite de securite: 100 iterations).
Les boucles avec des valeurs dynamiques (ex: `$for[$args[2]]`, `$for[i=0;i<$args[2];i++]`) sont emises en tant qu'action `forLoop` et executees au runtime avec la meme limite de 100 iterations.

### Messagerie

- reply
- sendMessage
- channelSendMessage

### Composants / Interactions

- addButton
- addSelectMenuOption
- addSeparator
- addTextDisplay
- addTextInput
- editButton
- editSelectMenu
- editSelectMenuOption
- newModal
- newSelectMenu
- removeAllComponents / removeAllComponents[]
- removeButtons / removeButtons[]
- removeComponent
- defer
- input

### Embeds

- title
- description
- color
- footer (avec footerIcon optionnel en arg 2)
- footerIcon (standalone)
- thumbnail
- image
- author (avec authorIcon en arg 2, authorURL en arg 3)
- authorIcon (standalone)
- authorURL (standalone)
- addField
- addTimestamp / addTimestamp[]
- embeddedURL
- addContainer
- addSection
- addThumbnail

### Canvas / Image

- canvasCreate[name;width;height;color]
- canvasContainer[name;x;y;width;height;color?]
- canvasLoadImage[url;x?;y?;width?;height?;container?]
- canvasDrawText[text;x;y;fontSize;color;textAlign?;maxWidth?;container?]
- canvasDrawCircle[x;y;radius;color;fill;blend?;container?]
- canvasDrawRect[x;y;width;height;color;fill;blend?;container?]
- canvasDrawLine[x1;y1;x2;y2;color;thickness;blend?;container?]
- canvasCompositeImage[url;x;y;width;height;shape?;blend?;container?]
- canvasProgressBar[x;y;width;height;percentage;barColor;trackColor;textColor;borderWidth?;orientation?;fontSize?;container?]
- canvasSetPixel[x;y;color;container?]
- canvasInvert[]
- canvasGrayscale[]
- canvasRotate[degrees]
- attachImage[name]

Note: les fonctions canvas sont collectees dans un bloc image runtime differe.
Le premier $canvasCreate demarre le bloc; toute fonction non-canvas suivante
provoque le flush du bloc. La couleur de bordure de canvasProgressBar utilise
barColor par defaut (BDFD n'expose pas d'argument de couleur de bordure dedie).

### Threads

- startThread
- editThread
- threadAddMember
- threadRemoveMember

### HTTP

- httpAddHeader
- httpGet
- httpPost
- httpPut
- httpDelete
- httpPatch
- url (encode/decode)

### Variables scopees

- setUserVar
- setServerVar
- setGuildVar
- setChannelVar
- setMemberVar
- setGuildMemberVar
- setMessageVar
- getUserVar (inline)
- getServerVar (inline)
- getGuildVar (inline)
- getChannelVar (inline)
- getMemberVar (inline)
- getGuildMemberVar (inline)
- getMessageVar (inline)

### JSON helpers

- jsonParse
- jsonSet
- jsonSetString
- jsonUnset
- jsonClear
- jsonArray
- jsonArrayAppend
- jsonArrayUnshift
- jsonArraySort
- jsonArrayReverse
- json (inline)
- jsonExists (inline)
- jsonStringify (inline)
- jsonPretty (inline)
- jsonArrayCount (inline)
- jsonArrayIndex (inline)
- jsonJoinArray (inline)
- jsonKeys (inline)
- jsonForEach / endJsonForEach (block loop)
- jsonArrayPop (inline)
- jsonArrayShift (inline)

### Mathematiques et conditions (inline)

- sum, sub, multi, divide, modulo, calculate
- ceil, floor, round, sqrt, max, min
- checkCondition (inline, booleen) — supporte les operateurs ==, !=, >, <, >=, <=,
  contains, notContains, startsWith, endsWith. Les comparaisons avec des operandes
  dynamiques (timestamps, variables, $sub[...] etc.) sont deferrees au runtime et
  evaluees apres resolution des placeholders.

### Await

- awaitFunc

### Profil bot

- changeUsername
- changeUsernameWithID

## Fonctions supportees (placeholder inline)

### Message/mentions

- message
- message[]
- mentions (comma-separated list of mentioned user IDs)
- mentionedChannels

### Runtime placeholders alias

- userID
- username / username[userID]
- userTag
- userAvatar
- userBanner
- authorID
- authorOfMessage
- authorAvatar
- authorUsername
- authorTag
- authorBanner
- creationDate
- discriminator
- displayName / displayName[userID]
- getUserStatus
- getCustomStatus
- isAdmin
- isBooster
- isBot
- isUserDMEnabled
- nickname / nickname[userID]
- userBadges
- userBannerColor
- userExists
- userInfo
- userJoined
- userJoinedDiscord
- userPerms
- userServerAvatar
- findUser
- guildID
- guildName
- guildIcon
- guildCount
- memberCount
- serverID
- serverName
- serverIcon
- channelID
- channelName
- channelType
- commandName
- commandType

## Fonctions non supportees

Toute fonction absente des listes ci-dessus est non supportee pour le moment et genere un diagnostic de transpilation.

## Notes importantes vs BDFD

- Certaines fonctions de type "placeholder" sont mappees vers des variables runtime Bot Creator. Le rendu depend donc de la disponibilite effective des variables dans le contexte d execution.
- Certaines variantes BDFD avec arguments optionnels (par exemple displayName[userID], nickname[userID], username[userID]) sont resolues vers des placeholders cibles: `((user[id].username))`, `((member[id].nick))`, `((member[id].nick|user[id].username))`.
- checkUserPerms est supportee en mode guard et en mode inline (booleen via variable message temporaire).

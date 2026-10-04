# Native guild reads

`bdfdGuildQueryFunctions(BotGuildQueryService)` provides eleven native functions.
`DiscordBotGuildQueryService(client: ..., guildId: ...)` reads Discord directly,
without actions or block compilation. Individual reads use `guilds.fetch` each
time. List reads use the current user's guild-list endpoint and paginate at 200
entries, checking the shared deadline before/after requests and per list item.
No CDN image is fetched; media functions return URL text only.

## Wiki signatures verified

| Function | Native arity and result | Official page |
| --- | --- | --- |
| `$guildExists[Guild ID]` | One argument; true if the bot can access the guild, otherwise false | [guildExists](https://wiki.botdesignerdiscord.com/bdscript/guildExists.html) |
| `$serverCount` | Zero arguments; total guild count | [serverCount](https://wiki.botdesignerdiscord.com/bdscript/serverCount.html) |
| `$serverNames` | Zero arguments; ten guild names, comma-space separated as illustrated | [serverNames](https://wiki.botdesignerdiscord.com/bdscript/serverNames.html) |
| `$serverOwner` | Zero arguments; current guild owner's ID | [serverOwner](https://wiki.botdesignerdiscord.com/bdscript/serverOwner.html) |
| `$serverDescription` | Zero arguments; description, empty if absent | [serverDescription](https://wiki.botdesignerdiscord.com/nightly/bdscript/serverDescription.html) |
| `$serverVerificationLvl` | Zero arguments; None, Low, Medium, High, Very High | [serverVerificationLvl](https://wiki.botdesignerdiscord.com/bdscript/serverVerificationLvl.html) |
| `$serverIcon` | Zero arguments; current guild icon URL | [serverIcon](https://wiki.botdesignerdiscord.com/bdscript/serverIcon.html) |
| `$guildBanner[Guild ID]` | One argument; specified guild banner URL | [guildBanner](https://wiki.botdesignerdiscord.com/bdscript/guildBanner.html) |
| `$boostCount` | Zero arguments; current guild boost count | [boostCount](https://wiki.botdesignerdiscord.com/bdscript/boostCount.html) |
| `$boostLevel` | Zero arguments; current guild boost tier | [boostLevel](https://wiki.botdesignerdiscord.com/bdscript/boostLevel.html) |
| `$afkTimeout[(Guild ID)]` | Zero or one argument; AFK timeout in seconds | [afkTimeout](https://wiki.botdesignerdiscord.com/bdscript/afkTimeout.html) |

The stable `serverDescription` web page could not be retrieved, so its official
nightly page and the official wiki checkout's `src/bdscript/serverDescription.md`
were checked; both give the same zero-argument signature and empty-description
behavior.

No official page or markdown source was found for the proposed names
`serverExists`, `guildCount`, `serverVerificationLevel`, `serverFeatures`,
`guildIcon`, `serverBanner`, `serverSplash`, `serverVanityURL`, or
`serverBoostCount`. They remain known catalogue entries without native support,
rather than being invented as aliases. Truly unknown names retain their literal
source together with unevaluated arguments.

## Choices not confirmed by the BDFD wiki

- The `guildBanner` page puts parentheses around its syntax's guild ID but labels
  that parameter Required. This implementation follows Required and rejects
  omitted/empty IDs. The contradictory syntax is not treated as a conformance
  proof for an optional form.
- `afkTimeout` defaults to the current guild when omitted. An explicitly empty
  argument also selects the current guild; the page says Optional but does not
  specify empty-argument handling.
- Invalid/nonpositive IDs passed to `guildExists` return false without I/O;
  required-ID field reads report an error. Whitespace is trimmed and numeric
  IDs use the project's existing positive signed-integer validation.
- Missing icon/banner return empty text. Their pages do not specify absence.
  CDN hashes use PNG for static images and GIF for `a_` animated hashes, matching
  the installed SDK's default format. The wiki does not promise exact URL format
  or image size (its banner example uses a JPG URL).
- `serverNames` takes the first ten entries in REST response order. The wiki
  specifies ten names and shows a comma-space delimiter, but does not specify
  selection/order. Guild-list IDs are deduplicated, preserving first insertion
  order; updated duplicates replace their name.
- Missing numeric metadata reports an error rather than fabricating zero. The
  SDK can represent a missing boost count as null. Unknown future verification
  levels also report an error instead of being silently named None.

Missing guild reads return null only for the local `DiscordEntityNotFound`
exception, Discord Unknown Guild (404/10004), or Missing Access (403/50001).
Permission failures, HTTP server errors and invalid fixture data propagate;
the runtime wraps ordinary failures with function/source location and `$try`
can catch them. Timeouts retain the shared execution deadline.

[Discord's current-user guild documentation](https://docs.discord.com/developers/resources/user#get-current-user-guilds)
sets a 200-entry page maximum and supports an `after` cursor. The service rejects
a full page with no cursor advancement. The same documentation now requires a
`shard` argument for apps using large bot sharding; the installed Nyxx method
does not expose it. This adapter therefore does not implement the large bot
sharding variant, and must not claim full guild enumeration for such apps.

## Integration and fixtures

The root migration task registers/exports `guild_query_functions.dart` and
`bot_guild_query_service.dart`, attaches this interface to the aggregate service,
and supplies a rejecting production-validation adapter. No central integration
file is changed by this isolated lot.

`BotGuildQueryService.guild({String? guildId, required budget})` returns a nullable
`BotGuild` with `id`, `name`, `ownerId`, `description`, `verificationLevel`,
`iconUrl`, `bannerUrl`, `boostCount`, `boostLevel`, `afkTimeoutSeconds`.
`guilds({required budget})` returns identity/name snapshots only; metadata is not
invented for partial list objects.

The fixture gateway must expose Guild `id`, `name`, `ownerId`, `description`,
`verificationLevel`, `iconHash`, `bannerHash`, `premiumSubscriptionCount`,
`premiumTier`, `afkTimeout`; and UserManager
`listCurrentUserGuilds({after, before, limit, withCounts})` returning UserGuild
objects with `id` and `name`. Existing mutation stubs must still fail locally.

## Verification

The dedicated `bdfd_native_guild_queries_test.dart` suite injects native bindings
with a fake service and separately tests the SDK adapter with manager mocks.
It covers documented fields and all verification labels, fresh reads, arity,
explicit/current IDs, empty metadata, unavailable values, literal returned
text, opaque unknown functions, unsupported aliases, catchable failures,
200-entry pagination/deduplication/stagnation, selective not-found handling,
and shared deadlines. No real Discord connection or mutation is used.

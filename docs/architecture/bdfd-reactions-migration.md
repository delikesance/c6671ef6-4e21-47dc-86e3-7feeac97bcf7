# Native reactions

Six functions are implemented in `bdfdReactionFunctions(BotReactionService)`.
Every available official page was read before implementation:

| Function | Official signature and target | Source |
| --- | --- | --- |
| `$addReactions` | `[Emojis;...]`: bot's future response | [addReactions](https://wiki.botdesignerdiscord.com/bdscript/addReactions.html) |
| `$addCmdReactions` | `[Emojis;...]`: invoking message | [addCmdReactions](https://wiki.botdesignerdiscord.com/bdscript/addCmdReactions.html) |
| `$addMessageReactions` | `[Channel ID;Message ID;Emojis;...]`: specified message | [addMessageReactions](https://wiki.botdesignerdiscord.com/bdscript/addMessageReactions.html) |
| `$clearReactions` | `[Channel ID;Message ID;Emoji]`: clear the emoji for every user, or `!all` for all reactions | [clearReactions](https://wiki.botdesignerdiscord.com/bdscript/clearReactions.html) |
| `$getReactions` | `[Channel ID;Message ID;Separator;Emoji]`: reacting users | [getReactions](https://wiki.botdesignerdiscord.com/bdscript/getReactions.html) |
| `$userReacted` | `[Channel ID;Message ID;User ID;Emoji]`: true/false | [userReacted](https://wiki.botdesignerdiscord.com/bdscript/userReacted.html) |

The three add functions require at least one emoji slot. Both queries require
exactly four arguments; `clearReactions` requires three. No legacy abbreviated
query signatures or implicit author substitution are added. IDs must be positive
decimal strings within the project's signed integer representation.

`removeReaction` has no page in the official wiki checkout and the attempted
stable/nightly page URLs did not resolve. It remains a known unsupported
catalogue function; no removal signature is invented from the legacy compiler.

The `getReactions` prose does not identify a return representation. Its
[official screenshot](https://user-images.githubusercontent.com/69215413/123293801-488f9980-d4e2-11eb-9a1b-241c4b51f845.png)
was inspected: it displays `Spen#0999, Wiki Bot#6295`. The native function
therefore returns user tags, rather than IDs or counts. Modern users with
discriminator `0` return their username only; that modern convention is not
explicitly confirmed by the old wiki screenshot. The supplied separator remains
literal, including spaces and dollar signs. Empty reaction populations return
empty text; this edge case is not specified by the wiki.

## Shared preparation and Discord transport

The immutable add request holds a target and copied emoji strings. Clear/query
requests and user DTOs have final fields. `prepareBotReactionAdd` and
`prepareBotReactionClear` perform only validation and reads; SDK transport and
Sandbox use the same preparation before any writes.

Preparation fetches the target channel and message freshly and requires a
message-capable `TextChannel`. Guild permissions are read with the shared fresh
permission service, including effective channel overwrites. Adding requires
Read Message History and additionally Add Reactions when an emoji is absent
from the fetched message. Clearing requires Manage Messages. DMs rely on the
Discord endpoint's access checks. Emoji existence can change between preparation
and writing; Discord remains authoritative at the endpoint.

These requirements and query pagination follow the primary
[Discord message API documentation](https://docs.discord.com/developers/resources/message).
User queries paginate at 100, deduplicate IDs and reject a full page that fails
to advance the user-ID cursor. The installed Nyxx `fetchReactions` method does
not expose Discord's `type` query argument, so these queries cover normal
reactions rather than the separate burst/super-reaction list. BDFD's wiki does
not specify burst behavior. Missing/inaccessible message errors propagate instead
of silently becoming an empty population or false.

All emoji values resolve before the first add write. Each write checks the
shared deadline immediately before and after its await. Adds execute in argument
order, without retry or rollback: a later failure preserves earlier completed
writes. Clear uses `deleteAllReactions` or `deleteReaction` for all users of one
emoji; it does not accidentally select the delete-own-reaction endpoint.

Unicode strings, custom emoji mentions (including animated ones), bare custom
IDs and aliases are accepted. Unicode validity and custom-emoji access remain
subject to Discord. Bare IDs use a name found in the message's reaction metadata
or freshly enumerated guild emoji lists. Origin-guild enumeration shares the
guild service's documented large-bot-sharding limitation; HTTP errors are not
swallowed as if an emoji did not exist.

The official [supported alias table](https://botdesignerdiscord.com/public/emoji_alias_list)
was retrieved as factual mapping data: 1,881 emoji rows and 2,776 aliases are
stored in `bdfd_reaction_emoji_aliases.dart`. There are no runtime network calls
to download that table. Alias casing/whitespace behavior is not specified by the
wiki; aliases use exact keys and outer whitespace is trimmed. Unknown aliases
fail before mutation. Updates to the official table need a future snapshot
refresh rather than a claim that this snapshot never changes.

## Deferred response reactions

`BotDeferredReactionOutput.deferReactions(List<String>)` is the typed integration
point used by `$addReactions`. The function evaluates/normalizes an immutable
emoji list and queues it; it neither sends a message nor invents its ID. The
response output owns the queue, attaches it to the actual successful flush
result's message/channel IDs, detaches it before awaiting sends or reaction
writes, and discards it when the draft is discarded. Standalone `$sendMessage`
sends do not consume the main response queue. A missing reaction-capable output
reports an error instead of reacting to the invoking message.

The main integration task implements this output lifecycle and registers the
service in the engine, aggregate Discord adapter and validation registry. Values
returned by queries remain literal data; unknown calls preserve their entire
source and never execute nested reaction arguments.

## Sandbox and verification

The native Sandbox adapter implements `BotReactionService`, prepares with the
same read-only helpers, and records simulated changes explicitly. It does not
invoke SDK write methods. Canonical message fixtures are
`entities.messages[channelId][messageId]`; `reactions` is a list of objects with
`emoji`, optional custom `id`, `count`, and `users` as user-ID strings. Reaction
queries read those users' metadata from `entities.users`. A count-only reaction
cannot fabricate user IDs; querying one without its users list fails locally.
The fixture gateway's `fetchReactions` sorts/paginates IDs, while every unsupported
SDK mutation remains denied locally.

The dedicated suite has 27 passing tests: native signatures and examples, user
tags, literal separators/values, immutable requests/deferred queues, unknown
calls, unsupported removal, shared budgets, SDK order and partial failures,
permission distinctions, normal-reaction pagination, and four Sandbox scenarios.
Those scenarios cover invoking/explicit targets, numeric custom-ID lookup,
actual response IDs for deferred reactions, shared mutation/query fixtures,
clearing, invalid aliases, and opaque unknown functions. Targeted analysis is
clean. All checks use mocks/fixtures; no real Discord message is sent or changed.

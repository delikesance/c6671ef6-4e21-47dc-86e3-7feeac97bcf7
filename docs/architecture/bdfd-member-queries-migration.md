# Native BDFD guild-member queries

`bdfdMemberQueryFunctions(BotMemberQueryService)` adds eight native bindings.
`DiscordBotMemberQueryService(client, guildId)` supplies guild member DTOs from
fresh SDK reads. The service is independent of templates and visual actions.

## Official contracts checked

| Binding | Official contract |
| --- | --- |
| [`$findUser[User;(Return author ID?)]`](https://wiki.botdesignerdiscord.com/bdscript/findUser.html) | Current-server lookup by username, ID or mention. The query is emptiable; the optional return-author flag defaults to yes. |
| [`$randomUserID`](https://wiki.botdesignerdiscord.com/bdscript/randomUserID.html) | Zero arguments; random current-server member ID. |
| [`$randomUser`](https://wiki.botdesignerdiscord.com/bdscript/randomUser.html) | Zero arguments; random current-server username. |
| [`$randomMention`](https://wiki.botdesignerdiscord.com/bdscript/randomMention.html) | Zero arguments; mention of a random current-server member. |
| [`$membersCount`](https://wiki.botdesignerdiscord.com/bdscript/membersCount.html) | Zero arguments; current-guild member count. |
| [`$allMembersCount`](https://wiki.botdesignerdiscord.com/bdscript/allMembersCount.html) | Zero arguments; total membership across all guilds the bot belongs to. |
| [`$isBooster[(User ID;Guild ID)]`](https://wiki.botdesignerdiscord.com/bdscript/isBooster.html) | Optional user and guild; boolean booster status. The page explicitly documents `[]` for author. |
| [`$isTimedOut[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/isTimedOut.html) | Required user ID; boolean timeout status. |

Only these verified names are registered. No matching official pages were found
for `memberCount`, `getMembersCount`, `botCount`, `usersWithRole` or `onlineMembers`
in the official wiki or its source catalogue. They are not treated as proven
aliases of other functions. Existing unsupported catalogue names still fail
preflight; genuinely unknown functions remain raw literals.

## Service and SDK reads

`BotGuildMember` contains ID, username, optional nickname, bot flag, role IDs,
optional `premiumSince` and optional `communicationDisabledUntil`. SDK DTO
collections and role-ID lists are unmodifiable.

- `guildMember(userId, guildId?, budget)` uses `members.fetch`, in the current
  guild unless a guild is supplied. Only HTTP 404 with Discord error `10007`
  becomes null. Permission, network, guild-not-found and other failures propagate.
- `guildMembers(guildId?, budget)` reads `members.list(limit: 1000, after: ...)`
  until exhaustion. It advances using the maximum returned ID, deduplicates
  overlapping member IDs and rejects nonadvancing pages rather than returning a
  partial population or looping forever.
- `allGuildMembersCount(budget)` enumerates
  `users.listCurrentUserGuilds(limit: 200, after: ...)`, deduplicates guild IDs,
  and sums the complete enumerated population of each guild. It does not rely on
  a gateway cache or approximate counts.
- Embedded member users supply usernames and bot flags. If the embedded user is
  absent, a fresh `users.fetch(member.id)` supplies it.

These are the official
[list-guild-members](https://docs.discord.com/developers/resources/guild#list-guild-members)
and [current-user-guilds](https://docs.discord.com/developers/resources/user#get-current-user-guilds)
endpoints through Nyxx. Member enumeration requires Discord's privileged guild
members intent. An unavailable or unauthorized population remains an error;
no cached subset is silently described as the complete guild.

All reads and page/mapping loops use the same invocation budget. Expired budgets
block dispatch and slow reads time out. Listing all guild memberships may require
many API calls on large bots, and membership changes during pagination mean the
result is not an atomic cross-server snapshot. No pagination request is retried
and no Discord write is performed.

## Binding behavior and explicit conventions

`findUser` tries ID/mention through a current-guild member fetch. Non-mention
queries then use exact username matching on complete member enumeration. A
numeric username can therefore match if the corresponding ID is absent. It does
not treat server nicknames, display names or partial/fuzzy strings as usernames.
The wiki does not specify case sensitivity or duplicate-name selection; this
implementation chooses a case-sensitive first match. If nothing matches and the
return-author flag is false, it returns empty text; that exact failure value is
not explicit on the page. Author fallback uses `author.id`, then `user.id`.

The three random functions select uniformly from the fully enumerated current
guild using `context.random`. Bot accounts are included as ordinary guild
members; the wiki does not specify bot exclusion. Their empty-population result
is empty text without a random-index call, an undocumented boundary convention.
`randomMention` renders `<@id>` and `randomUser` returns username rather than
nickname or global display name.

Bare `membersCount` uses complete enumeration. The wiki also describes special
use in bot status; that separate status entry point is not implemented by this
command binding. `allMembersCount` sums memberships, so a user in two guilds
contributes twice. Deduplication across separate guilds is not specified by the
wiki; this conventional sum is documented rather than claimed as measured
hosted-BDFD behavior.

`isBooster` reads `premium_since`, whose meaning is defined by the
[Discord member object](https://docs.discord.com/developers/resources/guild#guild-member-object).
Absent or empty user arguments select author; absent or empty guild arguments
select current guild. Bare zero-argument use and the individual empty guild
boundary are interpreted from the optional syntax; only `[]` author use is
explicitly demonstrated. A missing member reports an error rather than a false
booster result; the wiki does not specify that failure case.

`isTimedOut` compares `communication_disabled_until` to the live invocation
clock. Null, elapsed, or exactly-current deadlines return false; a future deadline
returns true. A missing member reports an error. The Discord object defines past
or null values as absence of timeout, but hosted BDFD was not executed for
boundary verification.

The service validates positive decimal IDs representable by Nyxx's signed
integer Snowflake. Literal mentions are accepted only by `findUser`.

## Presence form deliberately deferred

The official [`$membersCount[Presence]`](https://wiki.botdesignerdiscord.com/bdscript/membersCountComplex.html)
accepts `online`, `offline`, `idle`, `dnd` or `invisible`, and requires the
privileged presences intent. REST member lists contain no complete presence
state. An approximate non-offline count cannot implement these five values, and
a partial gateway cache cannot establish complete counts.

This registry therefore accepts only the bare zero-argument `membersCount` form;
presence arguments fail preflight before any effects. Supporting the bracket
form requires a separately maintained, authoritative gateway presence snapshot
with intent and completeness tracking. No fake zero, online total or offline
inference is registered here.

## Fixture and integration requirements

The engine accepts `BotMemberQueryService` explicitly or through its aggregate
moderation adapter. The sandbox delegates to the same SDK service through its
read-only fixture gateway. Its method names avoid collision with
`BotUserQueryService.member`.

SDK fixtures need:

- `MemberManager.list({int? limit, Snowflake? after})`, with numeric ID pagination,
  and `MemberManager.fetch(id)` for current or explicit guilds.
- `UserManager.listCurrentUserGuilds({after, before, limit, withCounts})`; only
  `UserGuild.id` is read by this service.
- Member `id`, `user` (username and bot flag), `nick`, `roleIds`, `premiumSince`
  and `communicationDisabledUntil`; `users.fetch` if embedded `user` is absent.
- Confirmed fixture absence maps to null for single-member queries. Missing
  fixture collections remain configuration errors rather than empty populations.

## Verification

`bdfd_native_member_queries_test.dart` has 22 tests covering wiki lookup/random
contracts, author fallback, timeout expiration, booster scope, malformed IDs,
preflight before effects, opaque unknown functions and code-shaped returned data.
SDK mocks verify multi-page member and guild enumeration, deduplication,
nonadvancing cursor rejection, fresh member/user fetches, precise 404 handling,
immutable DTO lists, shared budgets and deadline failure without partial results.
Production sandbox tests also check current/all-guild counts, lookup, boosting
and timeout through fixtures, no writes, and explicit errors for incomplete or
malformed populations. Fixtures accept canonical `communication_disabled_until`
and preserve the historical `timeout_until` alias. No live Discord requests or
comparisons against hosted BDFD were performed.

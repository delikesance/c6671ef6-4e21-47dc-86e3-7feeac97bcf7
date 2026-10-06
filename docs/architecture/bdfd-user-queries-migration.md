# Native BDFD user queries

`bdfdUserQueryFunctions(BotUserQueryService)` implements eleven user query names.
The native interpreter calls a shared service, without converting scripts into
visual blocks. `DiscordBotUserQueryService` fetches users and current-guild
members through Nyxx. The interface returns immutable `BotUser` and
`BotUserMember` values, or null for confirmed absence.

## Official wiki contracts

All signatures below were checked against their official pages, including
separate pages for bare and bracket forms:

| Function | Verified contract |
| --- | --- |
| [`$userExists[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/userExists.html) | Required ID; Discord-wide existence, returning `true` or `false`. |
| [`$userJoined[User ID;(Format)]`](https://wiki.botdesignerdiscord.com/bdscript/userJoined.html) | Required ID, optional Go date layout, current-server joining date; default example `2022-08-16`. |
| [`$userAvatar[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/userAvatar.html) | Required ID; global avatar URL. |
| [`$authorAvatar`](https://wiki.botdesignerdiscord.com/bdscript/authorAvatar.html) | No arguments; author's global avatar URL. |
| [`$username`](https://wiki.botdesignerdiscord.com/bdscript/username.html), [`$username[User ID]`](https://raw.githubusercontent.com/NilPointer-Software/bdfd-wiki/master/src/bdscript/usernameComplex.md) | Bare form selects author; bracket form requires an ID. |
| [`$displayName`](https://wiki.botdesignerdiscord.com/bdscript/displayName.html), [`$displayName[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/displayNameComplex.html) | Bare form selects author; bracket form requires an ID; reads global display name. |
| [`$nickname`](https://wiki.botdesignerdiscord.com/bdscript/nickname.html), [`$nickname[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/nicknameComplex.html) | Bare form selects author; bracket form requires an ID; guild nickname falls back to display name. |
| [`$discriminator[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/discriminator.html) | Exactly one emptiable argument; `[]` selects author. Human users return `0000`, bots return their four-digit discriminator. |
| [`$userBanner[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/userBanner.html) | Required ID; global banner only, not guild-specific banner. |
| [`$userBannerColor[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/userBannerColor.html) | Required ID; hexadecimal banner color without a leading `#`; unset color returns empty string. |
| [`$userServerAvatar[User ID]`](https://wiki.botdesignerdiscord.com/bdscript/userServerAvatar.html) | Required ID; guild avatar, with fallback to the user's global avatar. |

The bare `username` continues using entry-point-hydrated `user.username` or
`author.username` when supplied. This preserves commands without entity fixtures
and avoids an unnecessary user fetch. An explicit ID always queries the service.
Other bare user fields select `author.id`, falling back to `user.id` when needed.
Empty explicit IDs are rejected except the documented `$discriminator[]` form.

## Shared service and SDK behavior

`user(id, budget)` calls `client.users.fetch(id)`. `member(id, budget)` calls
`client.guilds[currentGuild].members.fetch(id)` and requires a guild. Cached
`get` methods and current-guild member lists are not used for global existence.
The [Discord user object](https://docs.discord.com/developers/resources/user#user-object)
supplies username, global name, discriminator, bot status, avatar, banner and
accent color. The
[guild member object](https://docs.discord.com/developers/resources/guild#guild-member-object)
supplies guild nickname, joining timestamp and guild avatar.

Only HTTP 404 with Discord `Unknown User` code `10013` or `Unknown Member`
code `10007`, respectively, becomes null. Permission failures, transport errors,
other 404 responses and server errors remain errors; they must not report that
an account does not exist. See the
[official error codes](https://docs.discord.com/developers/topics/opcodes-and-status-codes#json-json-error-codes).

CDN URLs are read from Nyxx assets, without fetching image contents. Nyxx handles
animated GIF/static PNG selection and the built-in default avatar when the user
has no custom avatar. No size query is appended, so the wiki's `?size=...` usage
remains possible. A supplied banner color is rendered as six uppercase hex digits.

The same invocation budget is passed into each service read. Reads check the
budget before dispatch and after completion, and time out using its remaining
deadline. A timed-out HTTP read is not retried. Network cancellation itself is
not provided by this adapter.

## Explicit conventions and remaining uncertainty

- The wiki does not specify every missing-entity failure. Global/member field
  queries report an error on absent entities. `$userExists` alone returns false
  for confirmed missing accounts.
- Discord global names fall back to username when absent. This follows the
  Discord model; the BDFD wiki does not explicitly document that second fallback.
- The phrase “default user avatar” for `$userServerAvatar` is implemented as the
  global user avatar, which itself may be a built-in default. This interpretation
  has not been compared with hosted BDFD.
- A missing global banner returns empty text. The wiki says it returns a banner
  if present but does not explicitly specify the missing-banner result.
- Banner color casing and six-digit padding follow the example and ordinary RGB
  formatting; all color boundary cases are not described by the wiki.
- `$userJoined` uses the existing shared Go formatter and the invocation's
  selected `$time` zone. Whether hosted BDFD applies `$time` to this function is
  not stated explicitly on its page. An omitted format uses `2006-01-02`; an
  explicitly empty format returns empty text, following Go formatting.
- Nyxx 6.9.0+1 represents missing guest `joined_at` with a pre-Discord-epoch
  timestamp. The DTO converts that sentinel to null, and the native date function
  reports the unavailable date rather than inventing a joining date.
- ID validation accepts positive decimal IDs representable by Nyxx's signed
  integer Snowflake. It rejects mentions, hexadecimal inputs, zero and overflow.
  This is a current SDK representation limitation; full unsigned 64-bit decoding
  remains available for the separate pure `$creationDate` function.

No official `userTag`/`authorTag` pages were found. `bannerColor` and `serverAvatar`
are not aliases registered here: the verified names are `userBannerColor` and
`userServerAvatar`. Unsupported known catalogue functions continue failing
preflight; unknown names retain their complete literal syntax and their arguments
are never evaluated.

## Integration and fixtures

Include `bdfdUserQueryFunctions()` after context functions, because it extends
the existing bare `username` binding with its official bracket form. Production
adapters should delegate to `DiscordBotUserQueryService(client, guildId)`;
validation adapters must reject I/O.

Sandbox fixtures need user `username`, `global_name`, `discriminator`, `bot`,
`avatar`, `banner` and `accent_color`, and guild member `nick`, `joined_at` and
`avatar`. Nyxx asset construction needs fixture manager/client CDN options or
explicit local assets exposing their URL. Confirmed fixture absence should map
to null, while missing fixture collections must remain configuration errors.
No reply effects or fixture writes are introduced.

## Verification

`bdfd_native_user_queries_test.dart` covers official default/custom date examples,
author selection, hydrated username preservation, nickname/avatar fallbacks,
discriminators, missing entities, required IDs, preflight before effects,
unknown-function opacity, and returned code-shaped data. SDK mocks verify fresh
`fetch` calls and current-guild selection, precise not-found handling, guest date
sentinels, shared budgets, expired budgets and slow-read deadlines. These tests
perform no live Discord reads or writes and do not constitute execution against
the hosted BDFD backend.

# Native context guards

The native runtime now has a separate `bdfdContextGuardFunctions()` library. It
uses invocation context only, without compiling blocks or calling Discord.
The engine must register this map alongside its other native libraries.

## Official signatures checked

Each of the following stable official wiki pages was read before implementation:

| Function | Official signature | Checked subject |
| --- | --- | --- |
| [$onlyForIDs](https://wiki.botdesignerdiscord.com/bdscript/onlyForIDs.html) | `[User IDs;...;Error message]` | Author ID |
| [$onlyForUsers](https://wiki.botdesignerdiscord.com/bdscript/onlyForUsers.html) | `[Usernames;...;Error message]` | Author username |
| [$onlyForChannels](https://wiki.botdesignerdiscord.com/bdscript/onlyForChannels.html) | `[Channel IDs;...;Error message]` | Current channel ID |
| [$onlyForServers](https://wiki.botdesignerdiscord.com/bdscript/onlyForServers.html) | `[Server IDs;...;Error message]` | Current guild ID |
| [$ignoreChannels](https://wiki.botdesignerdiscord.com/bdscript/ignoreChannels.html) | `[Channel IDs;...;Error message]` | Current channel ID |
| [$blackListIDs](https://wiki.botdesignerdiscord.com/bdscript/blackListIDs.html) | `[User IDs;...;Error message]` | Author ID |
| [$blackListUsers](https://wiki.botdesignerdiscord.com/bdscript/blackListUsers.html) | `[Usernames;...;Error message]` | Author username |
| [$blackListServers](https://wiki.botdesignerdiscord.com/bdscript/blackListServers.html) | `[Guild IDs;...;Error message]` | Current guild ID |
| [$onlyIfMessageContains](https://wiki.botdesignerdiscord.com/bdscript/onlyIfMessageContains.html) | `[Message;Word;...;Error message]` | Explicit first argument |

List guards require at least one list slot and the final error slot, including
when either slot is empty. Whitelists require any matching list entry;
blacklists reject any matching list entry. The message guard requires a message,
at least one word slot, and the final error slot. Every word must occur, as
demonstrated by the official `Hello` / `Hi` example. There is no implicit
`$message` argument, no optional-error shorthand, and no undocumented alias.

Arguments execute once, in list order. The error argument executes only when
the guard rejects. Rejection uses the runtime's existing `call.stop(message)`
control path: it discards the pending draft, emits the error text, and stops
subsequent statements without entering `$catch`. An empty error stops silently.
Previously completed external effects are not retried or rolled back.
Returned argument text remains data, without an implicit second evaluation.

## Explicit implementation choices and limits

The wiki does not establish case sensitivity, trimming, evaluation order,
empty-list behavior, or invalid Snowflake diagnostics. These remain unverified
against an actual BDFD interpreter:

- Username comparisons and message substrings ignore case, preserving the
  repository's existing legacy convention. This is not a wiki guarantee.
- ID list entries trim surrounding whitespace; username entries and message
  words retain whitespace. IDs are compared as strings, without fetching their
  existence or enforcing a numeric-ID validation rule absent from these pages.
- Empty list slots never identify an entity. Missing or empty invoking identity
  cannot satisfy a whitelist; it does not match a blacklist. Empty message words
  match any string, including an empty message, using substring semantics.
- All candidates execute even after a match or missing word. Only the error
  argument is lazy. The loop checks the shared execution deadline per candidate.
- Author fields take precedence over user fields; fallback happens only when
  an author field is absent, not when it is explicitly empty. Context adapters
  must supply the actual invoking identity. No member is fetched to substitute
  for missing context.
- Channel guards compare `channel.id`, including DM channel IDs. They do not
  inherit `$channelID`'s special `none` result in DMs. Server guards use
  `guild.id`; an absent server cannot match an empty server slot.

Truly unknown function calls remain opaque together with their unevaluated
arguments. Known catalogue functions without native support continue to fail
preflight before any effects, including when nested inside a guard argument.

## Verification

`bdfd_native_context_guards_test.dart` injects the library directly into
`BdfdRuntime`. Its 38 tests exercise all nine functions, official word examples,
both list outcomes, lazy errors, one-time argument evaluation, missing context,
DMs, empty slots, runtime stop versus `$catch`, literal unknown calls, unsupported
catalogue names, signature preflight, and shared timeout handling. Targeted Dart
analysis is also run. No real Discord message or mutation is performed.

Engine registration, production editor validation and the registry audit are
handled by the main migration integration task.

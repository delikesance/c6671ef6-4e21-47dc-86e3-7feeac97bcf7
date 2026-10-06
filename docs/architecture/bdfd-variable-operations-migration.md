# Native variable existence and reset operations

Official sources read before implementing on 2026-10-04:

- [$varExists](https://wiki.botdesignerdiscord.com/bdscript/varExists.html); the HTML endpoint was unavailable through the browser tool, so its [official repository source](https://raw.githubusercontent.com/NilPointer-Software/bdfd-wiki/master/src/bdscript/varExists.md) was read instead.
- [$resetUserVar](https://wiki.botdesignerdiscord.com/bdscript/resetUserVar.html).
- [$resetServerVar](https://wiki.botdesignerdiscord.com/bdscript/resetServerVar.html).
- [$resetChannelVar](https://wiki.botdesignerdiscord.com/bdscript/resetChannelVar.html).
- [Variables guide](https://wiki.botdesignerdiscord.com/guides/introduction/variables.html) for declaration/default and per-server user scope.

The four functions register through the existing `bdfdVariableFunctions` service adapter. No official pages were found for resetGlobalUserVar, resetGuildVar, resetGuildMemberVar or resetMemberVar in the official wiki repository; they have not been added as assumed aliases.

`$varExists[name]` returns a lowercase boolean and checks variable definitions across scopes plus the local global-variable map. It does not read a scoped value or create a missing value. Global values are also the declaration catalogue for local global variables because the existing store has no separate global-default definition API.

`$resetServerVar[name]` restores the guild definition default across all indexed server contexts. `$resetChannelVar[name]` does the same across every indexed channel context. `$resetUserVar[name]` restores every indexed member context; an optional user ID restricts this to that user's contexts. Unlike ordinary get/set user functions, omitting the reset user ID never defaults to the invoking author. In the explicitly selected legacy user-variable mode, reset uses the global-user `user` scope, consistent with that mode's get/set functions.

Reset requires an existing matching scoped definition with `defaultValue` or `default_value`; missing definitions fail before writes instead of inventing an empty default. Structured defaults stay structured. Empty defaults are persisted as empty values; null defaults use the existing native string representation, an empty string. Definitions, unrelated scopes, unrelated users and other variable keys stay intact.

The service first snapshots all matching context IDs through the existing paginated index API, then restores defaults. Indexes sort by stored values, so changing values while advancing pagination would skip or repeat contexts. Both the canonical key and existing `bc_` reference aliases are indexed and restored; canonical defaults are also written for contexts found only through an old alias, avoiding resurrection of old values through read-time legacy migration. Budget checks surround each page read and each write. Storage errors propagate, and sequential writes are not a transaction: a failed write can leave a partially reset population. No reset is retried automatically.

## Explicit interpretation and limits

The resetUserVar page specifies everyone or a supplied user but does not explicitly discuss multiple servers. The implementation interprets this as all indexed `guildMember` contexts, filtered by user ID when supplied, because the function has no guild parameter and the guide says ordinary user variables differ by server. This cross-server behavior has not been executed against the BDFD backend.

The wiki does not specify case sensitivity, whitespace, local `bc_` aliases, explicit empty optional user IDs, missing-variable errors or return text for reset. The implementation follows the shared variable service's case-insensitive definition matching, trims names, preserves its local alias convention, rejects an explicitly empty or invalid snowflake instead of expanding it to everyone, rejects undeclared defaults and returns an empty string after a successful reset. It accepts positive unsigned 64-bit decimal user IDs without performing a Discord lookup. These are local decisions, not wiki-confirmed edge behavior.

Variable definitions are scope-specific in this application; BDFD's app declarations describe one name/default usable in several scopes. This change does not unify the application's definition model. Already expired values excluded by store indexes are not rewritten. The catalogue audit therefore proves registration only, not complete BDFD storage parity.

## Validation

`dart test test/bdfd_native_variable_operations_test.dart test/bdfd_native_variables_test.dart`: 20 tests pass, including 14 added operation tests. Covered: read-only existence, typed/empty defaults, all-context resets, targeted user isolation, legacy mode, 600-context pagination, old aliases, missing declarations, invalid IDs, arity preflight before earlier effects, unknown opaque arguments and budget cancellation before writes. The test index adapter extends MemoryBotDataStore because that helper's ordinary index method deliberately throws UnsupportedError.

Targeted `dart analyze` on the service, native bindings and added tests passes with no issues. These tests use memory storage; no real Discord requests or production resets occur.

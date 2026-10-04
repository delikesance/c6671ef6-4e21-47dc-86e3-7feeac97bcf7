# Native access guards

`bdfdAccessGuardFunctions({permissions, roles, channels})` receives existing
`BotPermissionQueryService`, `BotRoleQueryService` and `BotChannelQueryService`.
It creates no new SDK adapter and does not execute visual blocks.

All eight official pages and examples were read before implementation:

| Function | Signature | Source |
| --- | --- | --- |
| onlyForRoles | `[Role names;...;Error message]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/onlyForRoles.html) |
| onlyForRoleIDs | `[Role IDs;...;Error message]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/onlyForRoleIDs.html) |
| blackListRoles | `[Role names;...;Error message]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/blackListRoles.html) |
| blackListRolesIDs | `[Role IDs;...;Error message]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/blackListRolesIDs.html) |
| onlyAdmin | `[Error message]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/onlyAdmin.html) |
| isAdmin | `[User ID]` (required) | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/isAdmin.html) |
| onlyNSFW | `[Error message]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/onlyNSFW.html) |
| onlyForCategories | `[Category IDs;...;Error message]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/onlyForCategories.html) |

List entries and error messages are explicitly emptiable. Lists require at least
one entry slot and a final error slot. `onlyAdmin` and `onlyNSFW` each require one
slot, which may be empty. The final slot is always the message, without legacy
heuristics that guess whether the text resembles an error. There are no extra
sentinels or aliases documented. `blackListRoleIDs` without the plural `Roles`
has no official page and is not registered by this module.

Role guards test whether the invoking member has **any** supplied role. All
candidate expressions are evaluated before the read; errors in later arguments
are not hidden by an earlier match. Blank entries do not name a role or category.
An all-blank whitelist rejects; an all-blank blacklist passes without fetching
membership. Role names preserve the legacy exact-case, trimmed-candidate
convention; the wiki does not specify case behavior. ID arguments are positive
decimal strings, normalized within the project's signed integer range. The
implicit guild `@everyone` role is included although member role arrays omit it.
Name guards resolve names from the fresh guild-role list and never treat a
supplied role ID as a name alias.

Admin checks use effective guild permissions for the supplied user (`isAdmin`)
or invoking author (`onlyAdmin`), including the shared service's owner/admin
privilege handling. They do not check the bot or rely on hydrated permission text.
`author.id` takes precedence over `user.id`. Channel checks fetch the current
channel rather than trusting hydrated NSFW/category variables. Missing channels
fail these guards. Threads fetch their parent channel afresh and inspect its
NSFW/category values; absent, nested-thread or cross-guild parents fail. Thread
inheritance and owner privilege are local Discord-aware conventions, not edge
cases explicitly specified by the BDFD pages. Invalid/missing context IDs and
service errors remain native errors, not invented permission answers.

A refusal evaluates its message once and calls `call.stop(message)` to stop the
script, discard the pending response and replace it with the supplied text,
including an empty message. A passing guard does not evaluate that message.
Already performed effects are not rolled back or retried. Budgets wrap every
read and bound candidate/member/role loops. Timeouts propagate without becoming
a guard failure branch. Returned values and error text are never reparsed.
Unknown calls preserve unevaluated arguments; catalogue-known unsupported aliases
retain the engine's unsupported behavior.

`packages/shared/test/bdfd_native_access_guards_test.dart`: 23 tests cover all
eight bindings, lazy failure, stop/discard, empty slots, exact arity, identity
precedence, role-name and @everyone matching, admin privilege, fresh channels,
thread parents, ID validation, unknown-call opacity and deadlines. Shared SDK
adapters remain covered by their role, permission and channel tests.

# Native BDFD emoji functions

The module `packages/shared/lib/engine/bdfd/emoji_functions.dart` uses the typed
`BotEmojiService` independently of block execution. Eight official wiki pages
were read, including their examples, before implementation:

| Function | Required signature | Official source |
| --- | --- | --- |
| customEmoji | `[Emoji name]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/customEmoji.html) |
| emojiExists | `[Emoji ID]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/emojiExists.html) |
| emojiName | `[Emoji ID]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/emojiName.html) |
| isEmojiAnimated | `[Emoji ID]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/isEmojiAnimated.html) |
| emoteCount | no arguments | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/emoteCount.html) |
| serverEmojis | `[Guild ID;Separator]` (separator may be empty) | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/serverEmojis.html) |
| addEmoji | `[Name;Image URL;Return emoji?]` (yes/no required) | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/addEmoji.html) |
| removeEmoji | `[Emoji ID]` | [Wiki](https://wiki.botdesignerdiscord.com/bdscript/removeEmoji.html) |

No official page or source markdown was found for `emojiCount` or `stickerCount`;
neither is invented as an alias. The documented count function is `emoteCount`.
`customEmoji` accepts a name, not an undocumented ID alias. `removeEmoji` accepts
an ID, not a legacy block name alias. Invalid nondecimal, zero or overflowing
IDs produce false in `emojiExists`, consistent with its invalid-text examples;
other ID functions fail before mutation.

Read queries fetch fresh guild emoji lists. ID/name searches prefer the current
guild, then the bot's fresh guild list, without stale-cache answers. Snapshots
and list/image values are immutable. Names use exact case matching, the missing
`customEmoji` name returns an empty string, and missing required ID reads fail;
the wiki does not specify these edge cases or cross-guild search precedence.
Lists and returned creation values use Discord emoji mention syntax. Large
sharded bot accounts retain the installed Nyxx guild-list endpoint limitation
already documented for the guild query migration. Every loop and endpoint uses
the invocation budget; returned text is never reparsed as executable code.
Unknown functions preserve their arguments verbatim without evaluating them.

Creation performs fresh guild permission checks before fetching the image.
The [Discord create endpoint](https://docs.discord.com/developers/resources/emoji#create-guild-emoji)
requires Create Guild Expressions. The
[delete endpoint](https://docs.discord.com/developers/resources/emoji#delete-guild-emoji)
allows that permission for an emoji created by the bot; other emojis require
Manage Guild Expressions. Deletion fetches fresh creator metadata. Public
`prepareBotEmojiCreate` and `prepareBotEmojiDelete` validate and authorize only;
they never download an image or mutate Discord. Uploads use `EmojiBuilder` with
empty restricted-role lists. No implicit retry or rollback is attempted.

The image loader streams one HTTP(S) GET with the shared deadline and a hard
256 KiB limit checked against declared length and every chunk. It rejects HTTP
failures and recognizes PNG, JPEG, GIF, WebP and AVIF signatures. Discord performs
full image/dimension validation; the loader does not resize, decode or reencode.
Injected clients remain caller-owned; created clients close on completion or
failure. Default HTTP client redirect behavior and project HTTP(S) URL policy
are retained, without introducing a separate hostname/IP policy.

The Sandbox implements the same service using read-only preparation and explicit
fixtures, never a real network fallback. Binary HTTP responses use the optional
`bodyBase64` fixture field; malformed base64 fails normally. Emoji fixtures accept
`creator_id`, and fresh `guild.emojis.fetch` reads expose it. Creation allocates
fixture-only IDs, updates the guild emoji list, and records the downloaded byte
count and request URL without storing image bytes in the effect. Deletion records
its previous row. For simulated creation, GIF format is treated as animated and
other formats as static; existing fixture `animated` fields remain authoritative.
This is a simulation convention, not a claimed BDFD animation detection rule.

`packages/shared/test/bdfd_native_emojis_test.dart` covers native bindings,
opaque unknown calls, literal returned values, validation before effects,
immutable values, HTTP limits/deadline/client ownership, SDK fresh reads and
transport writes, permission distinctions, no retries, and Sandbox fixture effects.

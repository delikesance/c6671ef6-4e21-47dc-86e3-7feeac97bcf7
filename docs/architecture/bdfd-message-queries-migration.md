# Native message lookup and mutation functions

Official BDFD sources read before coding on 2026-10-04:

- [$getMessage](https://wiki.botdesignerdiscord.com/bdscript/getMessage.html)
- [$getAttachments](https://wiki.botdesignerdiscord.com/bdscript/getAttachments.html)
- [$getEmbedData](https://wiki.botdesignerdiscord.com/bdscript/getEmbedData.html)
- [$authorOfMessage](https://wiki.botdesignerdiscord.com/bdscript/authorOfMessage.html)
- [$deleteMessage](https://wiki.botdesignerdiscord.com/bdscript/deleteMessage.html)
- [$pinMessage](https://wiki.botdesignerdiscord.com/bdscript/pinMessage.html)
- [$unpinMessage](https://wiki.botdesignerdiscord.com/bdscript/unpinMessage.html)
- [$publishMessage](https://wiki.botdesignerdiscord.com/bdscript/publishMessage.html)

SDK behavior was checked in the installed nyxx 6.9.0+1 MessageManager, TextChannel, MessageAuthor and embed models, and the current [Discord message resource](https://docs.discord.com/developers/resources/message).

getMessage takes channel and message IDs, followed by an optional property defaulting to content. The documented properties content/authorID/username/avatar are individually selected; unsupported properties reject before fetching. authorOfMessage takes the same explicit ID pair. getAttachments uses the triggering channel/message context and a zero-based attachment index, following the official example. getEmbedData takes an explicit channel/message pair, a one-based embed index and one of six documented properties. Fetched values remain data and are not reparsed as script.

BotMessageQueryService returns typed BotMessageSnapshot and BotMessageEmbed objects, rather than a generic map with assumed field names. Its Discord adapter fetches the channel and message fresh, converts author data, attachment URLs and supported embed fields, and checks the shared budget after reads. Message-content intents and channel access remain Discord's responsibility; absent/redacted data is not fabricated. Null author avatars yield an empty string; normal User avatars use the SDK's default-avatar behavior, while webhook authors can expose a null avatar.

deleteMessage/unpinMessage/publishMessage require the documented two explicit IDs and emit no text. They use a typed MessageMutation kind and request. The concrete read-only prepareMessageMutation helper returns the fetched TextChannel and Message after validation and fresh effective permission calculation, so Sandbox can reuse it without calling a write gateway. Every mutation checks the shared budget immediately before its write and after completion. No retries or fictional rollback are introduced.

Deletion of someone else's guild message requires Manage Messages; own messages do not, following Discord. In DMs the bot cannot delete another author. Publishing requires an announcement channel plus Send Messages and additionally Manage Messages for another author. Pin/unpin use the modern Pin Messages flag: BDFD's unpin wiki still documents the older Manage Messages permission. The SDK's pin endpoint is deprecated upstream; this adapter uses the installed SDK method instead of building an unsupported HTTP route manually.

pinMessage is deliberately a zero-argument native function: the wiki says it pins the bot's response, not the triggering message. Its binding only calls BotDeferredMessageOutput.deferPin; the main output adapter must apply the typed pin request after sending and obtaining the actual response ID. An output lacking this capability raises a native error. BdfdMessageOutput now implements this interface and the deferred reaction interface. Its flush detaches draft and hooks before awaiting transport, then pins/reacts only to the actual returned channel/message IDs. Standalone sendMessage does not consume these hooks. Empty flush and guard discard clear pending hooks. Missing response IDs fail explicitly after send rather than guessing the triggering message. Post-send failures are partial and do not replay the sent response or detached hooks.

## Unspecified edges and remaining scope

The getAttachments syntax marks Index as optional but its parameter flag says Required. This implementation requires one argument, matching the flag and example index 0. Exact bare-function behavior is unverified. It returns the attachment URL at the given position without inventing an image-only filter; the wiki's image wording does not specify treatment of non-image files. Out-of-range attachments/embeds raise explicit errors. Missing optional embed fields return empty text.

The wiki does not specify enum case matching, color formatting, timestamp serialization or explicit empty optional properties. Properties match the documented case, empty explicit properties reject, colors use six lowercase hexadecimal digits without a # prefix, and timestamps serialize as UTC ISO 8601. Those representation choices have not been compared with the BDFD backend. IDs use the local SDK's positive signed integer representation. Read access guards rely on Discord's fetch endpoint; fixture reads do not emulate all access or privileged-intent redaction.

Other requested message functions, clear and removeContains are outside this coherent batch and remain for subsequent official-contract migration; no placeholder handlers are registered for them.

## Validation

21 dedicated tests pass, including the four getMessage properties, both index bases, six embed properties, actual SDK-to-DTO attachment/embed conversion, nullable avatar, mutation requests, deferred pinning, invalid input before reads/writes, arity preflight before earlier mutation, unknown opaque arguments, SDK dispatch, own-message deletion, denied permissions, no retry and expired budget. Targeted analysis reports no issues. No real Discord requests or writes were made.

Central integration validation adds 8 deferred-effect tests covering actual destinations, independent sends, send/post-send failures, missing IDs, empty flush, guard discard and production validation registration. The existing message suite remains green. BotMessageResult carries the actual transport channel ID; channel sends return the resolved destination (including created DM channels), and interaction responses return their interaction channel. Engine/aggregate/validation now also wire the reaction and member-query services.

## Subsequent metadata and edit migration

Additional official pages read before implementation: [$lastMessageID](https://wiki.botdesignerdiscord.com/bdscript/lastMessageID.html), [$lastPinTimestamp](https://wiki.botdesignerdiscord.com/bdscript/lastPinTimestamp.html), [$isMessageEdited](https://wiki.botdesignerdiscord.com/bdscript/isMessageEdited.html), [$messageEditedTimestamp](https://wiki.botdesignerdiscord.com/bdscript/messageEditedTimestamp.html), [$repliedMessageID](https://wiki.botdesignerdiscord.com/bdscript/repliedMessageID.html), [$editMessage](https://wiki.botdesignerdiscord.com/bdscript/editMessage.html), plus the official [argument flag guide](https://wiki.botdesignerdiscord.com/nightly/guides/other/arguments.html). The guide defines Vacantable as both omitted and explicitly empty being allowed. No official pages or repository sources were found for messageTimestamp/messageType/messageURL; no presumed aliases were registered for those names.

lastMessageID and lastPinTimestamp take zero arguments and fetch the current channel metadata, rather than returning a cached context message ID. lastPinTimestamp serializes Unix seconds, as the wiki example specifies. isMessageEdited and messageEditedTimestamp require explicit channel/message IDs and derive their values from the fetched edited timestamp. Unix-second conversion reuses the shared integer timestamp formatter. repliedMessageID takes no arguments and reads the triggering message fresh; only reply-type messages expose a reference ID. Other reference-bearing types such as pin notices and crossposts do not masquerade as replies, and an ordinary message yields empty text as explicitly documented.

The service now adds messageChannel, returning BotMessageChannelSnapshot(lastMessageId,lastPinTimestamp), and BotMessageSnapshot adds editedTimestamp/repliedMessageId. Missing last-message IDs, missing pin timestamps and unedited timestamps return empty text. The wiki does not specify the first three missing cases; this is a local choice. Channel last-message metadata can refer to a deleted/unavailable message, as Discord documents, and no fabricated history traversal replaces it.

editMessage has 3–7 arguments with an included but emptiable content position. Its optional title/description/color/footer fields accept omission and empty values. Color accepts integer RGB or six-digit hexadecimal input, with optional # for hexadecimal, and validates the 24-bit range. Length and total embed text constraints are enforced before the mutation. The mutation request extends the typed enum with edit plus MessageEdit data and SDK toBuilder conversion. Read-only preparation rejects other authors even if the bot has Administrator or Manage Messages; only the bot's own original messages can be edited. The prepared message manager sends one update after the budget check, preserving the no-retry policy.

The wiki does not say whether omitted embed arguments preserve prior embeds or whether supplied embed values merge with prior fields. This implementation omits embeds entirely on a three-argument edit, preserving existing embeds. If any optional embed position is supplied, it replaces the embed list with one embed constructed from the supplied fields; an entirely empty optional embed group clears embeds. That replacement behavior is a documented local interpretation, not verified BDFD backend parity. Attachments/components are left out of the update and preserved by Discord. Discord remains authoritative about updates that would leave a completely empty message.

Eight additional tests cover fresh channel metadata, edited status/seconds with missing values, current-message reply IDs, edit payloads and empty fields, integer color limits, preflight/unknown opacity, SDK edited/reply metadata and rejection of edits to another author even with privileged access. The dedicated suite now has 29 tests; targeted analysis remains clean. SDK metadata getters are real fetched fields, and writes remain mocks.

# Native embed properties and corrected indexes

Official pages checked on 2026-10-04: [embed indexes](https://wiki.botdesignerdiscord.com/resources/embedIndexes.html),
[author](https://wiki.botdesignerdiscord.com/bdscript/author.html),
[footer](https://wiki.botdesignerdiscord.com/bdscript/footer.html),
[authorIcon](https://wiki.botdesignerdiscord.com/bdscript/authorIcon.html),
[authorURL](https://wiki.botdesignerdiscord.com/bdscript/authorURL.html),
[footerIcon](https://wiki.botdesignerdiscord.com/bdscript/footerIcon.html),
[embeddedURL](https://wiki.botdesignerdiscord.com/bdscript/embeddedURL.html),
[addTimestamp](https://wiki.botdesignerdiscord.com/bdscript/addTimestamp.html),
[indexed addTimestamp](https://wiki.botdesignerdiscord.com/bdscript/addTimestampComplex.html),
[addField](https://wiki.botdesignerdiscord.com/bdscript/addField.html),
[title](https://wiki.botdesignerdiscord.com/bdscript/title.html),
[description](https://wiki.botdesignerdiscord.com/bdscript/description.html),
and [color](https://wiki.botdesignerdiscord.com/bdscript/color.html).

Native embed functions now select the officially documented indexes 1 through
10, defaulting to 1. `$author[Text;Index]` and `$footer[Text;Index]` no longer
interpret the second argument as an icon. Their previous local overloads with
extra icon/URL arguments are rejected in preflight, before earlier sends.
The fourth argument of `$addField` chooses the embed; it no longer inserts a
field at that position in the first embed. Fields append in evaluation order.

Five new registered functions expose separate author/footer icons, author/title
links and timestamps. Separate setters preserve each other and can execute
before or after the corresponding text, including the wiki author-icon example.
`$addTimestamp` reads the invocation's live clock, serializes an ISO UTC instant
and does not depend on `$time` or the response transport's real clock. It works
without footer text, as documented, and accepts an optional embed index.

At finalization, isolated icon/link sections without corresponding text are
excluded, following the wiki's warning that those properties need author,
footer or title text. The wiki does not specify whether these cases should
raise an error; silently omitting invisible properties is a local interpretation.
An empty URL remains empty and clears its property without deleting text.
URL syntactic validity, remote image contents and network reachability are not
validated by these handlers; the existing Discord transport/API remains
responsible for invalid URL rejections. No images are fetched by the engine.

Title/author text limits are 256, description 4096, footer 2048; field name/value
limits are 256/1024, with at most 25 fields per embed. The total text across
embeds is capped at 6000 before final response sending. Local counting uses
Dart UTF-16 code units; the wiki does not specify Unicode counting semantics.
Explicitly blank indexes select the default, a convention not specified for
every optional index page. Malformed, zero, fractional and out-of-range indexes
fail instead of silently selecting the first embed. Main-draft errors discard
that draft; already completed external sends remain completed.

`$sendMessage` continues to create an independent channel message, preserving
the main embed draft and returning the message ID only when requested. The new
properties do not introduce a legacy compiler/resolver path or implicit reparse.
Unknown wrappers preserve their entire raw text and never mutate embeds.

Twelve dedicated tests cover official indexes, setters in both orders, missing
text, clearing properties, live/injected timestamp clock, size limits,
preflight, invalid indexes, field counts, independent sends, unknown wrappers
and native sandbox. Existing message tests also pass. No real Discord action
was performed and no hosted BDFD comparison was executed.

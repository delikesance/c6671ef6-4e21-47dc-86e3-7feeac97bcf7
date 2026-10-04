# Native interaction inputs

Official contracts checked:

- [$isSlash](https://wiki.botdesignerdiscord.com/bdscript/isSlash.html): bare call,
  true when invoked as a slash command, false otherwise.
- [$input](https://wiki.botdesignerdiscord.com/bdscript/input.html): one required
  text input ID; retrieves the submitted modal value.

Both functions belong to the shared context registry and perform no I/O.
The slash command adapters already provide interaction.isSlash. input reads the
modal.<ID> values provided by buildInteractionRuntimeVariables, including the
legacy modal rows and modern labels. It does not read opts.<ID>, since a slash
option is a different input source. Returned values preserve whitespace, empty
text, dollar signs and brackets; they are never parsed as script.

Missing fields and empty IDs raise an explicit native diagnostic. The official
wiki does not specify those error cases; this is a local convention, not a
claim of exact BDFD error text. Missing slash flags default false. The generic interactionCreate event adapter derives the flag from both the
interaction type and the chat-input application command subtype. Modal, component
and context-menu interactions receive false. These functions do not migrate modal construction or response functions.

Four dedicated tests verify flags, literal/empty inputs, source isolation,
unknown opaque calls and preflight arities. The existing interaction event tests
also execute input against values extracted from both actual supported modal
component layouts. No Discord request is made.

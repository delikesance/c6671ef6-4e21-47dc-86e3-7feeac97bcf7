# Native BDFD text utility functions

The `bdfdTextUtilityFunctions()` registry adds eight pure functions. It requires
no Discord adapter and is usable by command, workflow, editor validation and
sandbox runtimes when included in their production registry.

## Official contracts checked

Each function was checked against its official wiki page:

| Function | Contract and source |
| --- | --- |
| `$byteCount[Text]` | Emptiable text; UTF-8 byte length. [Wiki](https://wiki.botdesignerdiscord.com/bdscript/byteCount.html) |
| `$linesCount[Text]` | Required text; line count. [Wiki](https://wiki.botdesignerdiscord.com/bdscript/linesCount.html) |
| `$cropText[Text;Max characters;Ending]` | Emptiable text and ending; integer limit; ending is appended only when truncation occurs. The emoji example counts the emoji as one scalar value. [Wiki](https://wiki.botdesignerdiscord.com/bdscript/cropText.html) |
| `$sort[Numbers;...;Direction;Return amount;Separator]` | At least one finite number, `asc` or `desc`, integer return limit (`-1` means all), required separator. [Wiki](https://wiki.botdesignerdiscord.com/bdscript/sort.html) |
| `$numberSeparator[Number;(Separator)]` | Integer number, vacantable separator, default comma. [Wiki](https://wiki.botdesignerdiscord.com/bdscript/numberSeparator.html) |
| `$isNumber[Value]` | Emptiable value, lowercase `true`/`false` result. [Wiki](https://wiki.botdesignerdiscord.com/bdscript/isNumber.html) |
| `$isBoolean[Text]` | Emptiable text; recognizes the eight documented boolean words. [Wiki](https://wiki.botdesignerdiscord.com/bdscript/isBoolean.html) |
| `$isValidHex[Color hex]` | Emptiable text; optional leading `#`. [Wiki](https://wiki.botdesignerdiscord.com/bdscript/isValidHex.html) |

The [official playground source](https://raw.githubusercontent.com/NilPointer-Software/bdfd-wiki/master/src/theme/playground.js)
provides UTF-8 counting through `TextEncoder`, case-sensitive lowercase boolean
membership, hex validation with one or more hex digits (no six-digit restriction),
and `parseFloat` combined with finite JavaScript-number validation. The native
number predicate therefore accepts finite decimal/exponent values and unsigned
hexadecimal, binary and octal number literals. Empty, whitespace-only, malformed
or infinite values return false. These playground details are evidence about
the wiki demonstration; actual hosted BDFD backend behavior was not executed.

## Explicit implementation conventions

The wiki does not resolve every boundary case. These choices remain documented
conventions rather than claims of measured BDFD parity:

- Lines are LF-delimited. CRLF works; lone CR is ordinary text. Trailing LF adds
  an empty line. Empty input is rejected because the argument is marked Required.
- Cropping accepts zero, rejects negative limits, and counts Unicode scalar
  values rather than grapheme clusters. Combining marks remain separate values.
  Arbitrarily large limits preserve text without integer overflow.
- Integer formatting uses exact `BigInt` values, accepts a decimal sign,
  normalizes leading zeros, and preserves separators exactly. Explicitly empty
  separators use the documented vacantable default comma.
- Sorting accepts decimal/exponent notation, trims numeric inputs, preserves
  their textual representation, and keeps original order for equal numeric
  values. Zero returns an empty string; an oversized limit returns all values;
  amounts below `-1` and empty separators are rejected. Comparison uses exact
  decimal digits and exponent, avoiding rounded large integers or fractions;
  accepted inputs still require a finite Dart numeric parse. These representation,
  exact-decimal comparison and tie-breaking choices are not specified by the wiki.

## Intentionally deferred functions

The official [`$removeContains`](https://wiki.botdesignerdiscord.com/bdscript/removeContains.html)
deletes Discord messages, with a final amount capped at 100. It is not a pure text
operation; registering a string-removal implementation would change its meaning.
It needs the message deletion service and sandbox effects.

The official [`$removeLinks`](https://wiki.botdesignerdiscord.com/bdscript/removeLinks.html)
has zero arguments and filters links from the complete bot reply. It needs reply
finalization, rather than a handler applied to a single argument.

The official [`$unescape`](https://wiki.botdesignerdiscord.com/bdscript/unescape.html)
allows escaped semicolons to become argument separators: its example combines it
with `$randomText[$unescape[$message]]`. Returning unchanged text from a fixed AST
argument would fail that example. It needs an explicit structural value or
argument-expansion primitive, without reparsing ordinary data as executable code.

These three known catalogue names remain unsupported and preflight-error before
effects; they are not silently registered with unrelated behavior. Truly unknown
functions remain opaque, including their arguments.

## Verification

`test/bdfd_native_text_utilities_test.dart` checks official examples, multibyte
and unpaired-surrogate UTF-8, scalar-safe truncation, boolean/hex playground
rules, finite number syntax, numeric sorting, large integer formatting, malformed
inputs and arity checks before variable effects. It also checks unknown-function
opacity, code-shaped returned data, and budget cancellation during long scans.
No real Discord reads or writes occur.

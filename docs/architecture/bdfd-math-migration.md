# Native BDFD math and decimal mode

The native context now owns `decimalsEnabled`, defaulting to false. The new core
bindings are `enableDecimals`, `sqrt` and `modulo`. Existing math and random
bindings use the same context state; no block action or legacy fallback is used.

## Official contracts checked

| Function | Verified source and contract |
| --- | --- |
| [`$enableDecimals[Enable?]`](https://wiki.botdesignerdiscord.com/bdscript/enableDecimals.html) | Required boolean; decimals in math and random functions are disabled by default. |
| [`$sqrt[Number]`](https://wiki.botdesignerdiscord.com/bdscript/sqrt.html) | Required finite non-negative number; decimals need `enableDecimals`. The official playground rounds default roots to nearest integer (`24` returns `5`). |
| [`$modulo[A;B]`](https://wiki.botdesignerdiscord.com/bdscript/modulo.html) | Exactly two required integers; remainder. |
| [`$round[Number;(Decimal place)]`](https://wiki.botdesignerdiscord.com/bdscript/round.html) | Finite number and optional vacantable integer decimal-place count, default zero. The example `100.123;1` returns `100.1`. |
| [`$min[A;B;...]`](https://wiki.botdesignerdiscord.com/bdscript/min.html), [`$max[A;B;...]`](https://wiki.botdesignerdiscord.com/bdscript/max.html) | Required integer arguments, with at least two values. |
| [`$random`](https://wiki.botdesignerdiscord.com/bdscript/random.html), [`$random[Min;Max]`](https://wiki.botdesignerdiscord.com/bdscript/randomComplex.html) | Bare default digits `0` through `9`; bracket form accepts increasing integer/float bounds and excludes the upper endpoint. |
| [`$calculate[Expression]`](https://wiki.botdesignerdiscord.com/bdscript/calculate.html) | Required expression; documented signs `+`, `-`, `*`, `/`, `%`, `**` and parentheses. |
| [`$sum`](https://wiki.botdesignerdiscord.com/bdscript/sum.html), [`$sub`](https://wiki.botdesignerdiscord.com/bdscript/sub.html), [`$multi`](https://wiki.botdesignerdiscord.com/bdscript/multi.html), [`$divide`](https://raw.githubusercontent.com/NilPointer-Software/bdfd-wiki/master/src/bdscript/divide.md) | Variadic arithmetic on integer/float operands. |
| [`$ceil`](https://wiki.botdesignerdiscord.com/bdscript/ceil.html), [`$floor`](https://wiki.botdesignerdiscord.com/bdscript/floor.html) | Required finite number; respectively smallest integer above or largest integer below the value. |

The [official playground source](https://raw.githubusercontent.com/NilPointer-Software/bdfd-wiki/master/src/theme/playground.js)
uses `Math.round(Math.sqrt(value))` for roots and `Math.round` for its single
argument rounding demo. Midpoint ties toward positive infinity are therefore
used by the native rounding helpers. The playground is documentation evidence;
the hosted BDFD backend was not executed.

## Behavior and numerical representation

The decimal switch emits no output, changes state only when its handler runs,
and is shared by explicitly nested scripts such as `eval`. Distinct invocation
contexts start with decimals disabled. Skipped branches and opaque unknown
functions cannot change the switch. Invalid arity fails preflight before earlier
effects or state changes.

`sum`, `sub`, `multi`, `divide`, `calculate` and `sqrt` preserve fractional results
when enabled. Disabled mode renders the final result as a nearest integer.
The general nearest-integer rule is a documented implementation convention:
`enableDecimals` specifies suppression of decimals, but does not explicitly
describe truncation versus rounding for every arithmetic function. Roots and
single-argument rounding have direct playground evidence for nearest rounding.

Integer-only addition, subtraction and multiplication use `BigInt`, avoiding
signed overflow. Mixed fractional arithmetic, division, expression evaluation
and roots use finite Dart floating-point values, with their precision limits.
`min`, `max` and `modulo` validate decimal integer syntax and operate on exact
`BigInt` values; enabling decimals does not relax their integer contract.
The remainder has the dividend's sign, following ordinary remainder semantics;
the wiki examples use only positive numbers and do not resolve negative cases.

`round` accepts one or two arguments, with omitted/empty decimal places selecting
zero. It works independently of decimal mode, as suggested by the wiki's advice
to use explicit rounding functions for decimals. Rounding uses the provided
decimal text, rather than multiplying binary floats by a large power of ten.
This avoids intermediate overflow and preserves large integer input. It removes
unnecessary trailing zeros. Negative place counts round tens/hundreds; very large
positive counts preserve the value and very negative counts produce zero, without
allocating billions of zeros. Very small or large results use scientific text.
These negative-place, extreme-place, exact-decimal and output-format conventions
are not specified completely by BDFD's page. Binary floating-point and hosted
BDFD midpoint behavior at multiple decimal places may differ.

## Random mode

With decimals disabled, integer sampling remains exact, unbiased and upper
exclusive, including ranges wider than signed 64-bit subtraction. Fractional
endpoints select the integer population `ceil(min)` through `ceil(max) - 1`.
An interval containing no integer errors without consuming entropy. This choice
preserves both integer output and the documented bounds; the wiki does not
describe the exact algorithm for fractional bounds with decimals disabled.

With decimals enabled, integer as well as fractional endpoints use decimal
sampling. This reproduces the `enableDecimals` example with integer endpoints
and a fractional result. Bare random uses the continuous range `[0,10)` when
enabled, an inference from the documented default digit population and mode.
Decimal sampling uses finite double interpolation with a correction if rounding
would hit the excluded upper bound. If distinct integer endpoints become equal
at double precision, it errors before consuming entropy rather than returning a
value outside the range. Fractional precision/distribution and that precision
failure boundary are not specified by the wiki.

## Strict native expression parsing

`MathExpressionParser` now accepts optional `strictArithmetic`, `checkBudget`
and `maxDepth` parameters. Native `calculate` and native loop arithmetic opt in.
Zero division/remainder is rejected rather than replaced by zero, parser loops
observe the shared deadline, and nested unary/parenthesis/power expressions obey
the context depth limit. Native parsing also accepts ordinary whitespace.

Strict parsing uses right-associative powers (`2**3**2` is `512`), with power
precedence above unary signs (`-2**2` is `-4`, `(-2)**2` is `4`), and supports
signed exponents. The wiki lists power syntax but provides no associativity or
negative-power example and has no calculate playground. These choices are
standard mathematical conventions, not verified hosted BDFD behavior. The
historical `^` power extension remains accepted and is not claimed as an
official BDFD operator.

The parser's default mode is unchanged for visual Calculate blocks and legacy
callers: existing zero-divisor and left-associated-power behavior remains there.
The parser change therefore does not silently alter block math semantics.

The existing two-operand minimum for `sum`, `sub`, `multi` and `divide` is retained;
unlike `min`/`max`, their wiki pages do not explicitly state the minimum count.
Variadic maxima no longer impose an undocumented local 100-value cap.

## Verification

`bdfd_native_math_test.dart` covers decimal defaults and toggling, nested-state
sharing and context isolation, official root/round/min/max/remainder examples,
negative midpoint conventions, arbitrary decimal places, overflow-safe integers,
strict integer contracts, random modes, excluded endpoints, precision failures,
zero-divisor rejection, strict precedence/depth/budgets, unknown opacity and
preflight before effects. The production sandbox runs math without entity
fixtures, Discord reads or writes.

Existing native runtime/random tests explicitly enable decimals when expecting
fractions. `math_parser_test.dart` verifies that default parser behavior still
passes. No claims of complete numerical parity beyond the checked wiki contracts
are made.

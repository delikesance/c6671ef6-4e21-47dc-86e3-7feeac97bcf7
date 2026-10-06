import 'function_suite.dart';

/// End-to-end contracts for JSON data and runtime control flow.
final sandboxDataFlowFunctionCases = [
  SandboxFunctionCase(
    'jsonforeach',
    r'$var[total;0]$jsonParse[$message[data]]$jsonForEach[]$var[total;$sum[$var[total];1]]$endJsonForEach$var[total]',
    0,
    '250',
    label: '250 JSON elements',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '[${List.generate(250, (i) => '$i').join(',')}]'},
    },
  ),
  SandboxFunctionCase(
    'for',
    r'$var[total;0]$for[item;' +
        List.generate(250, (i) => '$i').join(';') +
        r']$var[total;$sum[$var[total];1]]$endfor$var[total]',
    0,
    '250',
    label: '250 list elements',
  ),
  for (final loop in [
    r"$for[250]",
    r"$for[$message[count]]",
    r"$for[i=0;i<250;i++]",
    r"$for[i=0;i<250;i=i+1]",
    r"$for[i=0;i<250;i+=$message[step]]",
  ])
    SandboxFunctionCase(
      "for",
      r"$var[total;0]" +
          loop +
          r"$var[total;$sum[$var[total];1]]$endfor$var[total]",
      0,
      "250",
      label: "beyond 100: $loop",
      scenario: {
        "variables": {"interaction.isSlash": "true"},
        "options": {"count": 250, "step": 1},
      },
    ),
  SandboxFunctionCase(
    'jsonarray',
    r'$jsonParse[{"values":"one|two"}]$jsonArray[values;$message[separator]]$jsonJoinArray[values;,]',
    0,
    'one,two',
    label: 'literal document and runtime separator',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'separator': '|'},
    },
  ),
  SandboxFunctionCase(
    'jsonarraysort',
    r'$jsonParse[{"values":[2,10,3]}]$jsonArraySort[values;$message[order]]$jsonJoinArray[values;,]',
    0,
    '10,3,2',
    label: 'literal document and runtime direction',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'order': 'DESC'},
    },
  ),
  SandboxFunctionCase(
    'jsonkeys',
    r'$jsonParse[{"nested":{"one":1,"two":2}}]$jsonKeys[$message[path];$message[separator]]',
    0,
    'one|two',
    label: 'literal document and runtime path',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'path': 'nested', 'separator': '|'},
    },
  ),
  SandboxFunctionCase(
    'jsonset',
    r'$jsonParse[{"old":1}]$jsonSet[$message[path];$message[value]]$jsonStringify',
    7,
    '{"old":1,"new":7}',
    label: 'literal document and runtime write',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'path': 'new', 'value': 7},
    },
  ),
  SandboxFunctionCase(
    'sort',
    r'$sort[$message[a];$message[b];$message[c];$message[order];$message[amount];$message[separator]]',
    0,
    '10 - 3',
    label: 'runtime direction, amount and separator',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {
        'a': 10,
        'b': 2,
        'c': 3,
        'order': 'desc',
        'amount': 2,
        'separator': ' - ',
      },
    },
  ),
  SandboxFunctionCase(
    'sort',
    r'$sort[$message[a];$message[b];asc;-1;,]',
    0,
    '',
    label: 'runtime text is not sortable (wiki: numbers only)',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'a': 'zebra', 'b': 'pear'},
    },
    expectedValues: {
      '/success': false,
      '/error': r'BDFD L1:1 $sort: Sort requires finite numbers.',
    },
  ),
  SandboxFunctionCase(
    'jsonarray',
    r'$jsonParse[$message[data]]$jsonArray[new]$jsonStringify',
    0,
    '{"old":1,"new":[]}',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"old":1}'},
    },
  ),
  SandboxFunctionCase(
    'jsonarrayindex',
    r'$jsonParse[$message[data]]$jsonArrayIndex[values;$message[target]]',
    0,
    '1',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"values":[2,10,3]}', 'target': 10},
    },
  ),
  SandboxFunctionCase(
    'jsonarrayindex',
    r'$jsonParse[$message[data]]$jsonArrayIndex[values;missing]',
    0,
    '-1',
    label: 'absent value',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"values":[2,10,3]}'},
    },
  ),
  SandboxFunctionCase(
    'jsonarraysort',
    r'$jsonParse[$message[data]]$jsonArraySort[values;desc]$jsonJoinArray[values;,]',
    0,
    '10,3,2',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"values":[2,10,3]}'},
    },
  ),
  SandboxFunctionCase(
    'jsonarraysort',
    r'$jsonParse[$message[data]]$jsonArraySort[values;$message[order]]$jsonJoinArray[values;,]',
    0,
    '10,3,2',
    label: 'runtime direction',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"values":[2,10,3]}', 'order': 'desc'},
    },
  ),
  SandboxFunctionCase(
    'jsonjoinarray',
    r'$jsonParse[$message[data]]$jsonJoinArray[values;$message[separator]]',
    0,
    'one|two',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"values":["one","two"]}', 'separator': '|'},
    },
  ),
  SandboxFunctionCase(
    'jsonkeys',
    r'$jsonParse[$message[data]]$jsonKeys[nested;$message[separator]]',
    0,
    'one|two',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"nested":{"one":1,"two":2}}', 'separator': '|'},
    },
  ),
  SandboxFunctionCase(
    'jsonpretty',
    r'$jsonParse[$message[data]]$jsonPretty[2]',
    0,
    '{\n  "name": "two  spaces"\n}',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"name":"two  spaces"}'},
    },
  ),
  SandboxFunctionCase(
    'jsonforeach',
    r'$jsonParse[$message[data]]$jsonForEach[]$jsonKey=$jsonValue$endJsonForEach',
    0,
    'a=1b=2',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"a":1,"b":2}'},
    },
  ),
  SandboxFunctionCase(
    'jsonkey',
    r'$jsonParse[$message[data]]$jsonForEach[]$jsonKey$endJsonForEach',
    0,
    'ab',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"a":1,"b":2}'},
    },
  ),
  SandboxFunctionCase(
    'jsonindex',
    r'$jsonParse[$message[data]]$jsonForEach[]$jsonIndex$endJsonForEach',
    0,
    '01',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '{"a":1,"b":2}'},
    },
  ),
  SandboxFunctionCase(
    'endjsonforeach',
    r'$jsonParse[$message[data]]$jsonForEach[]$jsonValue$endJsonForEach$setVar[after;yes]done',
    0,
    '12done',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'data': '[1,2]'},
    },
    expectedValues: {'/storage_after/global/after': 'yes'},
  ),
  SandboxFunctionCase('sort', r'$sort[10;2;3;asc;-1;,]', 0, '2,3,10'),
  SandboxFunctionCase(
    'sort',
    r'$sort[$message[a];$message[b];$message[c];asc;-1;,]',
    0,
    '2,3,10',
    label: 'runtime numbers',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'a': 10, 'b': 2, 'c': 3},
    },
  ),
  SandboxFunctionCase(
    'unescape',
    r'$unescape[$message[text]]',
    0,
    'a;b',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'text': 'a;b'},
    },
  ),
  SandboxFunctionCase(
    'eval',
    r'$eval[$message[source]]',
    0,
    '5',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'source': r'$sum[2;3]'},
    },
  ),
  SandboxFunctionCase(
    'func',
    r'$func[double;x]$funcReturn[$sum[$funcArg[x];$funcArg[x]]]$funcEnd$funcCall[double;$message[value]]',
    3,
    '6',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'funcarg',
    r'$func[tag;x]$funcReturn[<$funcArg[x]>]$funcEnd$funcCall[tag;$message[value]]',
    'value',
    '<value>',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'funcreturn',
    r'$func[tag;x]$funcReturn[$funcArg[x]]$funcEnd$funcCall[tag;one]|$funcCall[tag;two]',
    0,
    'one|two',
  ),
  SandboxFunctionCase(
    'funcend',
    r'$func[tag;x]$funcReturn[$funcArg[x]]$funcEnd$funcCall[tag;value]',
    0,
    'value',
  ),
  SandboxFunctionCase(
    'funccall',
    r'$func[tag;x]$funcReturn[<$funcArg[x]>]$funcEnd$func[wrap;x]$funcReturn[$funcCall[tag;$funcArg[x]]]$funcEnd$funcCall[wrap;$message[value]]',
    'nested',
    '<nested>',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'i',
    r'$for[$message[count]]$i$endfor',
    0,
    '01',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'loopindex',
    r'$for[$message[count]]$loopIndex$endfor',
    0,
    '01',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'loopiteration',
    r'$for[$message[count]]$loopIteration$endfor',
    0,
    '01',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'loopcount',
    r'$for[$message[count]]$loopCount$endfor',
    0,
    '12',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'endfor',
    r'$for[$message[count]]$setVar[touched;$i]$endfor$setVar[after;yes]done',
    0,
    'done',
    expectedValues: {
      '/storage_after/global/touched': '1',
      '/storage_after/global/after': 'yes',
    },
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'endloop',
    r'$loop[$message[count]]$setVar[touched;$i]$endloop$setVar[after;yes]done',
    0,
    'done',
    expectedValues: {
      '/storage_after/global/touched': '1',
      '/storage_after/global/after': 'yes',
    },
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'else',
    r'$if[$message[value]==yes]wrong$else correct$endif',
    'no',
    ' correct',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'endif',
    r'$if[$message[value]==yes]wrong$endif after',
    'no',
    ' after',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
];

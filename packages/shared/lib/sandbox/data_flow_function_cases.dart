import 'function_suite.dart';

/// End-to-end contracts for JSON data and runtime control flow.
final sandboxDataFlowFunctionCases = [
  SandboxFunctionCase(
    'jsonforeach',
    r'$var[total;0]$jsonParse[((opts.data))]$jsonForEach[]$var[total;$sum[$var[total];1]]$endJsonForEach$var[total]',
    0,
    '250',
    label: '250 JSON elements',
    scenario: {
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
    r"$for[((opts.count))]",
    r"$for[i=0;i<250;i++]",
    r"$for[i=0;i<250;i=i+1]",
    r"$for[i=0;i<250;i+=((opts.step))]",
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
        "options": {"count": 250, "step": 1},
      },
    ),
  SandboxFunctionCase(
    'jsonarray',
    r'$jsonParse[{"values":"one|two"}]$jsonArray[values;((opts.separator))]$jsonJoinArray[values;,]',
    0,
    'one,two',
    label: 'literal document and runtime separator',
    scenario: {
      'options': {'separator': '|'},
    },
  ),
  SandboxFunctionCase(
    'jsonarraysort',
    r'$jsonParse[{"values":[2,10,3]}]$jsonArraySort[values;((opts.order))]$jsonJoinArray[values;,]',
    0,
    '10,3,2',
    label: 'literal document and runtime direction',
    scenario: {
      'options': {'order': 'DESC'},
    },
  ),
  SandboxFunctionCase(
    'jsonkeys',
    r'$jsonParse[{"nested":{"one":1,"two":2}}]$jsonKeys[((opts.path));((opts.separator))]',
    0,
    'one|two',
    label: 'literal document and runtime path',
    scenario: {
      'options': {'path': 'nested', 'separator': '|'},
    },
  ),
  SandboxFunctionCase(
    'jsonset',
    r'$jsonParse[{"old":1}]$jsonSet[((opts.path));((opts.value))]$jsonStringify',
    7,
    '{"old":1,"new":7}',
    label: 'literal document and runtime write',
    scenario: {
      'options': {'path': 'new', 'value': 7},
    },
  ),
  SandboxFunctionCase(
    'sort',
    r'$sort[((opts.a));((opts.b));((opts.c))]',
    0,
    'apple;pear;zebra',
    label: 'runtime text',
    scenario: {
      'options': {'a': 'zebra', 'b': 'pear', 'c': 'apple'},
    },
  ),
  SandboxFunctionCase(
    'jsonarray',
    r'$jsonParse[((opts.data))]$jsonArray[new]$jsonStringify',
    0,
    '{"old":1,"new":[]}',
    scenario: {
      'options': {'data': '{"old":1}'},
    },
  ),
  SandboxFunctionCase(
    'jsonarrayindex',
    r'$jsonParse[((opts.data))]$jsonArrayIndex[values;((opts.target))]',
    0,
    '1',
    scenario: {
      'options': {'data': '{"values":[2,10,3]}', 'target': 10},
    },
  ),
  SandboxFunctionCase(
    'jsonarrayindex',
    r'$jsonParse[((opts.data))]$jsonArrayIndex[values;missing]',
    0,
    '-1',
    label: 'absent value',
    scenario: {
      'options': {'data': '{"values":[2,10,3]}'},
    },
  ),
  SandboxFunctionCase(
    'jsonarraysort',
    r'$jsonParse[((opts.data))]$jsonArraySort[values;desc]$jsonJoinArray[values;,]',
    0,
    '10,3,2',
    scenario: {
      'options': {'data': '{"values":[2,10,3]}'},
    },
  ),
  SandboxFunctionCase(
    'jsonarraysort',
    r'$jsonParse[((opts.data))]$jsonArraySort[values;((opts.order))]$jsonJoinArray[values;,]',
    0,
    '10,3,2',
    label: 'runtime direction',
    scenario: {
      'options': {'data': '{"values":[2,10,3]}', 'order': 'desc'},
    },
  ),
  SandboxFunctionCase(
    'jsonjoinarray',
    r'$jsonParse[((opts.data))]$jsonJoinArray[values;((opts.separator))]',
    0,
    'one|two',
    scenario: {
      'options': {'data': '{"values":["one","two"]}', 'separator': '|'},
    },
  ),
  SandboxFunctionCase(
    'jsonkeys',
    r'$jsonParse[((opts.data))]$jsonKeys[nested;((opts.separator))]',
    0,
    'one|two',
    scenario: {
      'options': {'data': '{"nested":{"one":1,"two":2}}', 'separator': '|'},
    },
  ),
  SandboxFunctionCase(
    'jsonpretty',
    r'$jsonParse[((opts.data))]$jsonPretty[2]',
    0,
    '{\n  "name": "two  spaces"\n}',
    scenario: {
      'options': {'data': '{"name":"two  spaces"}'},
    },
  ),
  SandboxFunctionCase(
    'jsonforeach',
    r'$jsonParse[((opts.data))]$jsonForEach[]$jsonKey=$jsonValue$endJsonForEach',
    0,
    'a=1\nb=2',
    scenario: {
      'options': {'data': '{"a":1,"b":2}'},
    },
  ),
  SandboxFunctionCase(
    'jsonkey',
    r'$jsonParse[((opts.data))]$jsonForEach[]$jsonKey$endJsonForEach',
    0,
    'a\nb',
    scenario: {
      'options': {'data': '{"a":1,"b":2}'},
    },
  ),
  SandboxFunctionCase(
    'jsonindex',
    r'$jsonParse[((opts.data))]$jsonForEach[]$jsonIndex$endJsonForEach',
    0,
    '0\n1',
    scenario: {
      'options': {'data': '{"a":1,"b":2}'},
    },
  ),
  SandboxFunctionCase(
    'endjsonforeach',
    r'$jsonParse[((opts.data))]$jsonForEach[]$jsonValue$endJsonForEach$setVar[after;yes]done',
    0,
    '1\n2\ndone',
    scenario: {
      'options': {'data': '[1,2]'},
    },
    expectedValues: {'/storage_after/global/after': 'yes'},
  ),
  SandboxFunctionCase('sort', r'$sort[10;2;3]', 0, '2;3;10'),
  SandboxFunctionCase(
    'sort',
    r'$sort[((opts.a));((opts.b));((opts.c))]',
    0,
    '2;3;10',
    label: 'runtime numbers',
    scenario: {
      'options': {'a': 10, 'b': 2, 'c': 3},
    },
  ),
  SandboxFunctionCase(
    'unescape',
    r'$unescape[((opts.text))]',
    0,
    'a;b',
    scenario: {
      'options': {'text': 'a;b'},
    },
  ),
  SandboxFunctionCase(
    'eval',
    r'$eval[((opts.source))]',
    0,
    '5',
    scenario: {
      'options': {'source': r'$sum[2;3]'},
    },
  ),
  SandboxFunctionCase(
    'func',
    r'$func[double;x]$funcReturn[$sum[$funcArg[x];$funcArg[x]]]$funcEnd$funcCall[double;((opts.value))]',
    3,
    '6',
  ),
  SandboxFunctionCase(
    'funcarg',
    r'$func[tag;x]$funcReturn[<$funcArg[x]>]$funcEnd$funcCall[tag;((opts.value))]',
    'value',
    '<value>',
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
    r'$func[tag;x]$funcReturn[<$funcArg[x]>]$funcEnd$func[wrap;x]$funcReturn[$funcCall[tag;$funcArg[x]]]$funcEnd$funcCall[wrap;((opts.value))]',
    'nested',
    '<nested>',
  ),
  SandboxFunctionCase('i', r'$for[((opts.count))]$i$endfor', 0, '0\n1'),
  SandboxFunctionCase(
    'loopindex',
    r'$for[((opts.count))]$loopIndex$endfor',
    0,
    '0\n1',
  ),
  SandboxFunctionCase(
    'loopiteration',
    r'$for[((opts.count))]$loopIteration$endfor',
    0,
    '0\n1',
  ),
  SandboxFunctionCase(
    'loopcount',
    r'$for[((opts.count))]$loopCount$endfor',
    0,
    '1\n2',
  ),
  SandboxFunctionCase(
    'endfor',
    r'$for[((opts.count))]$setVar[touched;$i]$endfor$setVar[after;yes]done',
    0,
    'done',
    expectedValues: {
      '/storage_after/global/touched': '1',
      '/storage_after/global/after': 'yes',
    },
  ),
  SandboxFunctionCase(
    'endloop',
    r'$loop[((opts.count))]$setVar[touched;$i]$endloop$setVar[after;yes]done',
    0,
    'done',
    expectedValues: {
      '/storage_after/global/touched': '1',
      '/storage_after/global/after': 'yes',
    },
  ),
  SandboxFunctionCase(
    'else',
    r'$if[((opts.value))==yes]wrong$else correct$endif',
    'no',
    ' correct',
  ),
  SandboxFunctionCase(
    'endif',
    r'$if[((opts.value))==yes]wrong$endif after',
    'no',
    ' after',
  ),
];

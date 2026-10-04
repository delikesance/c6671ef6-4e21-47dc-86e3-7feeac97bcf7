import '../utils/bdfd_functions.dart';
import 'command_sandbox.dart';
import 'canvas_function_cases.dart';
import 'music_function_cases.dart';
import 'misc_function_cases.dart';
import 'thread_function_cases.dart';
import 'workflow_function_cases.dart';
import 'ticket_function_cases.dart';
import 'webhook_function_cases.dart';
import 'guard_function_cases.dart';
import 'context_function_cases.dart';
import 'component_function_cases.dart';
import 'data_flow_function_cases.dart';
import 'message_function_cases.dart';
import 'message_lookup_function_cases.dart';
import 'interaction_function_cases.dart';
import 'error_function_cases.dart';
import 'role_function_cases.dart';
import 'channel_function_cases.dart';
import 'random_entity_function_cases.dart';
import 'guild_lookup_function_cases.dart';
import 'emoji_function_cases.dart';
import 'member_role_function_cases.dart';
import 'user_function_cases.dart';
import 'role_action_function_cases.dart';
import 'moderation_function_cases.dart';
import 'message_mutation_function_cases.dart';
import 'flow_function_cases.dart';
import 'time_function_cases.dart';
import 'variable_function_cases.dart';

/// Explicit runtime contracts. A registered name without a case is reported as
/// uncovered, never as passing. Cases run in the same sandbox as mobile/Copilot.
class SandboxFunctionCase {
  const SandboxFunctionCase(
    this.function,
    this.script,
    this.input,
    this.expected, {
    this.scenario = const {},
    this.expectedValues = const {},
    this.label = '',
  });
  final String function;
  final String script;
  final dynamic input;
  final String expected;
  final Map<String, dynamic> scenario;
  final String label;

  /// JSON pointers into the sandbox result, for embeds, components and storage.
  final Map<String, dynamic> expectedValues;
  Map<String, dynamic> get request => {
    'options': {'value': input, 'count': 2},
    ...scenario,
    // Slash options are only read through $message[...] when the interaction
    // is a slash command, so cases feeding `value`/`count` that way opt in.
    if (script.contains(r'$message[value]') ||
        script.contains(r'$message[count]'))
      'variables': {
        'interaction.isSlash': 'true',
        ...(scenario['variables'] as Map? ?? const {}),
      },
    'script': script,
  };
  Future<Map<String, dynamic>> run() async {
    final result = await testCommandInSandbox(request);
    final contract = evaluateSandboxContract(
      result,
      expectedContent: expected,
      expectedValues: expectedValues,
    );
    return {
      ...result,
      'function': function,
      'expected': expected,
      'actual': contract['actual'],
      'checks': contract['checks'],
      'passed': contract['passed'],
    };
  }
}

/// Shared by the audit, mobile laboratory and Copilot's catalog contracts.
Map<String, dynamic> evaluateSandboxContract(
  Map<String, dynamic> result, {
  String? expectedContent,
  Map<String, dynamic> expectedValues = const {},
}) {
  final actual = (result['responses'] as List? ?? [])
      .map((response) => response['payload']['content'] ?? '')
      .join('\n');
  final checks = <Map<String, dynamic>>[];
  if (expectedContent != null) {
    checks.add({
      'path': 'response content',
      'expected': expectedContent,
      'actual': actual,
      'passed': actual == expectedContent,
    });
  }
  for (final entry in expectedValues.entries) {
    dynamic value = result;
    var found = entry.key.startsWith('/');
    for (final token in entry.key.split('/').skip(1)) {
      final key = token.replaceAll('~1', '/').replaceAll('~0', '~');
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else if (value is List) {
        final index = int.tryParse(key);
        if (index == null || index < 0 || index >= value.length) {
          found = false;
          break;
        }
        value = value[index];
      } else {
        found = false;
        break;
      }
    }
    checks.add({
      'path': entry.key,
      'expected': entry.value,
      'actual': found ? value : null,
      'found': found,
      'passed': found && _sameJsonValue(value, entry.value),
    });
  }
  return {
    'actual': actual,
    'checks': checks,
    'passed':
        (result['success'] == true ||
            (expectedValues['/success'] == false &&
                expectedValues.containsKey('/error'))) &&
        checks.isNotEmpty &&
        checks.every((check) => check['passed'] == true),
  };
}

bool _sameJsonValue(dynamic left, dynamic right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.keys.every(
          (key) =>
              right.containsKey(key) && _sameJsonValue(left[key], right[key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        List.generate(
          left.length,
          (index) => index,
        ).every((index) => _sameJsonValue(left[index], right[index]));
  }
  if (right == sandboxIsoTimestampMatcher && left is String) {
    return DateTime.tryParse(left)?.isUtc == true;
  }
  return left == right;
}

/// Expected value matching any UTC ISO-8601 timestamp, for clock-dependent
/// output the sandbox cannot pin to a fixed instant.
const sandboxIsoTimestampMatcher = '<utc iso-8601 timestamp>';

final sandboxFunctionCases = [
  ...sandboxCanvasFunctionCases,
  ...sandboxMusicFunctionCases,
  ...sandboxMiscFunctionCases,
  ...sandboxThreadFunctionCases,
  ...sandboxWorkflowFunctionCases,
  ...sandboxTicketFunctionCases,
  ...sandboxWebhookFunctionCases,
  ...sandboxGuardFunctionCases,
  ...sandboxContextFunctionCases,
  ...sandboxComponentFunctionCases,
  ...sandboxDataFlowFunctionCases,
  ...sandboxMessageFunctionCases,
  ...sandboxMessageLookupFunctionCases,
  ...sandboxInteractionFunctionCases,
  ...sandboxErrorFunctionCases,
  ...sandboxRoleFunctionCases,
  ...sandboxChannelFunctionCases,
  ...sandboxRandomEntityFunctionCases,
  ...sandboxGuildLookupFunctionCases,
  ...sandboxEmojiFunctionCases,
  ...sandboxMemberRoleFunctionCases,
  ...sandboxUserFunctionCases,
  ...sandboxRoleActionFunctionCases,
  ...sandboxModerationFunctionCases,
  ...sandboxMessageMutationFunctionCases,
  ...sandboxFlowFunctionCases,
  ...sandboxTimeFunctionCases,
  ...sandboxVariableFunctionCases,
  SandboxFunctionCase(
    'title',
    r'$title[$message[value]]',
    'Score',
    '',
    expectedValues: {'/responses/0/payload/embeds/0/title': 'Score'},
  ),
  SandboxFunctionCase(
    'description',
    r'$description[$message[value]]',
    'Earned 10 XP',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/description': 'Earned 10 XP',
    },
  ),
  SandboxFunctionCase(
    'color',
    r'$color[$message[value]]',
    '#00ff00',
    '',
    expectedValues: {'/responses/0/payload/embeds/0/color': '#00ff00'},
  ),
  SandboxFunctionCase(
    'footer',
    r'$footer[$message[value]]$footerIcon[https://example.com/footer.png]',
    'Bot Creator',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/footer': {
        'text': 'Bot Creator',
        'icon_url': 'https://example.com/footer.png',
      },
    },
  ),
  SandboxFunctionCase(
    'thumbnail',
    r'$thumbnail[$message[value]]',
    'https://example.com/thumb.png',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/thumbnail/url':
          'https://example.com/thumb.png',
    },
  ),
  SandboxFunctionCase(
    'image',
    r'$image[$message[value]]',
    'https://example.com/image.png',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/image/url':
          'https://example.com/image.png',
    },
  ),
  SandboxFunctionCase(
    'author',
    r'$author[$message[value]]$authorIcon[https://example.com/avatar.png]$authorURL[https://example.com/profile]',
    'Alice',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/author': {
        'name': 'Alice',
        'icon_url': 'https://example.com/avatar.png',
        'url': 'https://example.com/profile',
      },
    },
  ),
  SandboxFunctionCase(
    'authoricon',
    r'$author[Alice]$authorIcon[$message[value]]',
    'https://example.com/avatar.png',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/author/icon_url':
          'https://example.com/avatar.png',
    },
  ),
  SandboxFunctionCase(
    'authorurl',
    r'$author[Alice]$authorURL[$message[value]]',
    'https://example.com/profile',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/author/url': 'https://example.com/profile',
    },
  ),
  SandboxFunctionCase(
    'footericon',
    r'$footer[Credits]$footerIcon[$message[value]]',
    'https://example.com/icon.png',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/footer/icon_url':
          'https://example.com/icon.png',
    },
  ),
  SandboxFunctionCase(
    'embeddedurl',
    r'$title[Link]$embeddedURL[$message[value]]',
    'https://example.com',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/url': 'https://example.com',
    },
  ),
  SandboxFunctionCase(
    'addtimestamp',
    r'$addTimestamp',
    '2026-10-01T12:00:00Z',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/timestamp': sandboxIsoTimestampMatcher,
    },
  ),
  SandboxFunctionCase(
    'addfield',
    r'$addField[Level;$message[value];yes]',
    '4',
    '',
    expectedValues: {
      '/responses/0/payload/embeds/0/fields/0': {
        'name': 'Level',
        'value': '4',
        'inline': true,
      },
    },
  ),
  SandboxFunctionCase('sum', r'$sum[$message[value];2]', 4, '6'),
  SandboxFunctionCase('sub', r'$sub[$message[value];2]', 4, '2'),
  SandboxFunctionCase('multi', r'$multi[$message[value];2]', 4, '8'),
  SandboxFunctionCase('divide', r'$divide[$message[value];2]', 4, '2'),
  SandboxFunctionCase('modulo', r'$modulo[$message[value];3]', 4, '1'),
  SandboxFunctionCase('min', r'$min[$message[value];2]', 4, '2'),
  SandboxFunctionCase('max', r'$max[$message[value];2]', 4, '4'),
  SandboxFunctionCase('ceil', r'$ceil[$message[value]]', 4.2, '5'),
  SandboxFunctionCase('floor', r'$floor[$message[value]]', 4.2, '4'),
  SandboxFunctionCase('round', r'$round[$message[value]]', 4.6, '5'),
  SandboxFunctionCase('sqrt', r'$sqrt[$message[value]]', 4, '2'),
  SandboxFunctionCase('random', r'$random[$message[value];8]', 7, '7'),
  SandboxFunctionCase(
    'randomtext',
    r'$randomText[$message[value]]',
    'choice',
    'choice',
  ),
  SandboxFunctionCase(
    'randomstring',
    r'$charCount[$randomString[$message[value]]]',
    8,
    '8',
  ),
  SandboxFunctionCase('calculate', r'$calculate[$message[value]^2]', 4, '16'),
  SandboxFunctionCase('isnumber', r'$isNumber[$message[value]]', 100, 'true'),
  SandboxFunctionCase(
    'isinteger',
    r'$isInteger[$message[value]]',
    1.5,
    'false',
  ),
  SandboxFunctionCase(
    'isboolean',
    r'$isBoolean[$message[value]]',
    true,
    'true',
  ),
  SandboxFunctionCase(
    'isvalidhex',
    r'$isValidHex[$message[value]]',
    '#aabb00',
    'true',
  ),
  SandboxFunctionCase(
    'checkcondition',
    r'$checkCondition[$message[value]>=4]',
    4,
    'true',
  ),
  SandboxFunctionCase(
    'tolowercase',
    r'$toLowerCase[$message[value]]',
    'ABC',
    'abc',
  ),
  SandboxFunctionCase(
    'touppercase',
    r'$toUpperCase[$message[value]]',
    'abc',
    'ABC',
  ),
  SandboxFunctionCase(
    'totitlecase',
    r'$toTitleCase[$message[value]]',
    'hello world',
    'Hello World',
  ),
  SandboxFunctionCase(
    'trimspace',
    r'$trimSpace[$message[value]]',
    '  hello  ',
    'hello',
  ),
  SandboxFunctionCase(
    'trimcontent',
    r'$trimContent[$message[value]]',
    '  hello  ',
    'hello',
  ),
  SandboxFunctionCase(
    'charcount',
    r'$charCount[$message[value]]',
    'hello',
    '5',
  ),
  SandboxFunctionCase(
    'checkcontains',
    r'$checkContains[$message[value];World]|$checkContains[$message[value];world]|$checkContains[Hello;]|$checkContains[Hello World;missing;World]',
    'Hello World',
    'true|false|true|true',
  ),
  SandboxFunctionCase('bytecount', r'$byteCount[$message[value]]', 'é', '2'),
  SandboxFunctionCase(
    'linescount',
    r'$linesCount[$message[value]]',
    'one\ntwo',
    '2',
  ),
  SandboxFunctionCase(
    'croptext',
    r'$cropText[$message[value];3;...]',
    'abcdef',
    'abc...',
  ),
  SandboxFunctionCase(
    'replacetext',
    r'$replaceText[$message[value];a;x;-1]',
    'aba',
    'xbx',
  ),
  SandboxFunctionCase(
    'repeatmessage',
    r'$repeatMessage[$message[count];$message[value]]',
    'ab',
    'abab',
  ),
  SandboxFunctionCase(
    'removecontains',
    r'$removeContains[$message[value];a]',
    'aba',
    'b',
  ),
  SandboxFunctionCase(
    'numberseparator',
    r'$numberSeparator[$message[value];,]',
    123456,
    '123,456',
  ),
  SandboxFunctionCase(
    'args',
    r'$args[1]',
    100,
    '100',
    scenario: {
      'variables': {'message.content': '!cmd 100'},
    },
  ),
  SandboxFunctionCase(
    'var',
    r'$var[value;$message[value]]$var[value]',
    'hello',
    'hello',
  ),
  SandboxFunctionCase('authorid', r'$authorID', 0, '20'),
  SandboxFunctionCase('userid', r'$userID', 0, '20'),
  SandboxFunctionCase('guildid', r'$guildID', 0, '10'),
  SandboxFunctionCase('serverid', r'$serverID', 0, '10'),
  SandboxFunctionCase('channelid', r'$channelID', 0, '30'),
  SandboxFunctionCase('botid', r'$botID', 0, 'sandbox'),
  SandboxFunctionCase('authorusername', r'$authorUsername', 0, 'Test user'),
  SandboxFunctionCase('isbot', r'$isBot', 0, 'false'),
  SandboxFunctionCase(
    'and',
    r'$and[$message[value]>0;$message[value]<10]',
    4,
    'true',
  ),
  SandboxFunctionCase(
    'or',
    r'$or[$message[value]<0;$message[value]==4]',
    4,
    'true',
  ),
  SandboxFunctionCase(
    'if',
    r'$if[$message[value]==4]yes$else no$endif',
    4,
    'yes',
  ),
  SandboxFunctionCase(
    'elseif',
    r'$if[$message[value]==0]zero$elseif[$message[value]==4]four$else other$endif',
    4,
    'four',
  ),
  SandboxFunctionCase(
    'for',
    r'$var[n;0]$for[3]$var[n;$sum[$var[n];1]]$endfor$var[n]',
    0,
    '3',
  ),
  SandboxFunctionCase(
    'loop',
    r'$var[n;0]$loop[3]$var[n;$sum[$var[n];1]]$endloop$var[n]',
    0,
    '3',
  ),
  SandboxFunctionCase(
    'stop',
    r'$if[$message[value]==4]$stop$endif unreachable',
    4,
    '',
  ),
  SandboxFunctionCase(
    'jsonparse',
    r'$jsonParse[$message[value]]$json[a]',
    '{"a":4}',
    '4',
  ),
  SandboxFunctionCase(
    'json',
    r'$jsonParse[$message[value]]$json[a]',
    '{"a":4}',
    '4',
  ),
  SandboxFunctionCase(
    'jsonvalue',
    r'$jsonParse[$message[value]]$jsonValue[a]',
    '{"a":4}',
    '4',
  ),
  SandboxFunctionCase(
    'jsonset',
    r'$jsonParse[{"a":1}]$jsonSet[a;$message[value]]$json[a]',
    4,
    '4',
  ),
  SandboxFunctionCase(
    'jsonsetstring',
    r'$jsonParse[{}]$jsonSetString[a;$message[value]]$jsonStringify',
    4,
    '{"a":"4"}',
  ),
  SandboxFunctionCase(
    'jsonexists',
    r'$jsonParse[$message[value]]$jsonExists[a]',
    '{"a":4}',
    'true',
  ),
  SandboxFunctionCase(
    'jsonunset',
    r'$jsonParse[$message[value]]$jsonUnset[a]$jsonExists[a]',
    '{"a":4}',
    'false',
  ),
  SandboxFunctionCase(
    'jsonclear',
    r'$jsonParse[$message[value]]$jsonClear$jsonStringify',
    '{"a":4}',
    '{}',
  ),
  SandboxFunctionCase(
    'jsonstringify',
    r'$jsonParse[$message[value]]$jsonStringify',
    '{"a":4}',
    '{"a":4}',
  ),
  SandboxFunctionCase(
    'jsonarraycount',
    r'$jsonParse[$message[value]]$jsonArrayCount[items]',
    '{"items":[1,2]}',
    '2',
  ),
  SandboxFunctionCase(
    'jsonarrayappend',
    r'$jsonParse[$message[value]]$jsonArrayAppend[items;3]$json[items]',
    '{"items":[1,2]}',
    '[1,2,3]',
  ),
  SandboxFunctionCase(
    'jsonarrayunshift',
    r'$jsonParse[$message[value]]$jsonArrayUnshift[items;3]$json[items]',
    '{"items":[1,2]}',
    '[3,1,2]',
  ),
  SandboxFunctionCase(
    'jsonarraypop',
    r'$jsonParse[$message[value]]$jsonArrayPop[items]',
    '{"items":[1,2]}',
    '2',
  ),
  SandboxFunctionCase(
    'jsonarrayshift',
    r'$jsonParse[$message[value]]$jsonArrayShift[items]',
    '{"items":[1,2]}',
    '1',
  ),
  SandboxFunctionCase(
    'jsonarrayreverse',
    r'$jsonParse[$message[value]]$jsonArrayReverse[items]$json[items]',
    '{"items":[1,2]}',
    '[2,1]',
  ),
  SandboxFunctionCase(
    'textsplit',
    r'$textSplit[$message[value];,]$splitText[$message[count]]',
    'a,b,c',
    'b',
  ),
  SandboxFunctionCase(
    'splittext',
    r'$textSplit[$message[value];,]$splitText[$message[count]]',
    'a,b,c',
    'b',
  ),
  SandboxFunctionCase(
    'gettextsplitlength',
    r'$textSplit[$message[value];,]$getTextSplitLength',
    'a,b,c',
    '3',
  ),
  SandboxFunctionCase(
    'gettextsplitindex',
    r'$textSplit[$message[value];,]$getTextSplitIndex[b]',
    'a,b,c',
    '2',
  ),
  SandboxFunctionCase(
    'joinsplittext',
    r'$textSplit[$message[value];,]$joinSplitText[-]',
    'a,b,c',
    'a-b-c',
  ),
  SandboxFunctionCase(
    'editsplittext',
    r'$textSplit[$message[value];,]$editSplitText[2;x]$splitText[2]',
    'a,b,c',
    'x',
  ),
  SandboxFunctionCase(
    'removesplittextelement',
    r'$textSplit[$message[value];,]$removeSplitTextElement[2]$joinSplitText[-]',
    'a,b,c',
    'a-c',
  ),
  SandboxFunctionCase(
    'getuservar',
    r'$setUserVar[value;$message[value]]$getUserVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'setuservar',
    r'$setUserVar[value;$message[value]]$getUserVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'getguildvar',
    r'$setGuildVar[value;$message[value]]$getGuildVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'setguildvar',
    r'$setGuildVar[value;$message[value]]$getGuildVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'getservervar',
    r'$setServerVar[value;$message[value]]$getServerVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'setservervar',
    r'$setServerVar[value;$message[value]]$getServerVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'getchannelvar',
    r'$setChannelVar[value;$message[value]]$getChannelVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'setchannelvar',
    r'$setChannelVar[value;$message[value]]$getChannelVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'getguildmembervar',
    r'$setGuildMemberVar[value;$message[value]]$getGuildMemberVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'setguildmembervar',
    r'$setGuildMemberVar[value;$message[value]]$getGuildMemberVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'getmembervar',
    r'$setMemberVar[value;$message[value]]$getMemberVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'setmembervar',
    r'$setMemberVar[value;$message[value]]$getMemberVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'getvar',
    r'$setVar[value;$message[value]]$getVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'setvar',
    r'$setVar[value;$message[value]]$getVar[value]',
    42,
    '42',
  ),
  SandboxFunctionCase(
    'httpget',
    r'$httpGet[https://sandbox.invalid/test]$httpStatus',
    'payload',
    '201',
    scenario: {
      'http': [
        {
          'method': 'GET',
          'url': 'https://sandbox.invalid/test',
          'status': 201,
          'body': 'ok',
          'expectedRequest': {'body': ''},
        },
      ],
    },
  ),
  SandboxFunctionCase(
    'httppost',
    r'$httpPost[https://sandbox.invalid/test;$message[value]]$httpStatus',
    'payload',
    '201',
    scenario: {
      'http': [
        {
          'method': 'POST',
          'url': 'https://sandbox.invalid/test',
          'status': 201,
          'body': 'ok',
          'expectedRequest': {'body': 'payload'},
        },
      ],
    },
  ),
  SandboxFunctionCase(
    'httpput',
    r'$httpPut[https://sandbox.invalid/test;$message[value]]$httpStatus',
    'payload',
    '201',
    scenario: {
      'http': [
        {
          'method': 'PUT',
          'url': 'https://sandbox.invalid/test',
          'status': 201,
          'body': 'ok',
          'expectedRequest': {'body': 'payload'},
        },
      ],
    },
  ),
  SandboxFunctionCase(
    'httppatch',
    r'$httpPatch[https://sandbox.invalid/test;$message[value]]$httpStatus',
    'payload',
    '201',
    scenario: {
      'http': [
        {
          'method': 'PATCH',
          'url': 'https://sandbox.invalid/test',
          'status': 201,
          'body': 'ok',
          'expectedRequest': {'body': 'payload'},
        },
      ],
    },
  ),
  SandboxFunctionCase(
    'httpdelete',
    r'$httpDelete[https://sandbox.invalid/test;$message[value]]$httpStatus',
    'payload',
    '201',
    scenario: {
      'http': [
        {
          'method': 'DELETE',
          'url': 'https://sandbox.invalid/test',
          'status': 201,
          'body': 'ok',
          'expectedRequest': {'body': 'payload'},
        },
      ],
    },
  ),

  SandboxFunctionCase(
    'httpresult',
    r'$httpGet[https://sandbox.invalid/test]$httpResult[user;id]',
    0,
    '42',
    scenario: {
      'http': [
        {
          'url': 'https://sandbox.invalid/test',
          'body': {
            'user': {'id': 42},
          },
        },
      ],
    },
  ),
  SandboxFunctionCase(
    'httpstatus',
    r'$httpGet[https://sandbox.invalid/test]$httpStatus',
    0,
    '404',
    scenario: {
      'http': [
        {'url': 'https://sandbox.invalid/test', 'status': 404},
      ],
    },
  ),
  SandboxFunctionCase(
    'httpaddheader',
    r'$httpAddHeader[X-Test;$message[value]]$httpGet[https://sandbox.invalid/test]$httpResult',
    'value',
    'ok',
    scenario: {
      'http': [
        {
          'url': 'https://sandbox.invalid/test',
          'body': 'ok',
          'expectedRequest': {
            'headers': {'x-test': 'value'},
          },
        },
      ],
    },
  ),
];

List<Map<String, dynamic>> sandboxFunctionCatalog() => [
  for (final name in allBdfdFunctions.toList()..sort())
    {
      'function': name,
      'cases': sandboxFunctionCases
          .where((c) => c.function == name)
          .map(
            (c) => {
              'script': c.script,
              'label': c.label,
              'options': c.request['options'],
              'scenario': c.scenario,
              'expected': c.expected,
              'expected_values': c.expectedValues,
            },
          )
          .toList(),
      'covered': sandboxFunctionCases.any((c) => c.function == name),
    },
];

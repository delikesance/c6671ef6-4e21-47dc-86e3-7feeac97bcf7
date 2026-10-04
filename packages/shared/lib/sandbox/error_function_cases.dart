import 'function_suite.dart';

const _failure = {
  'http': [
    {'url': 'https://example.com/data', 'error': 'offline'},
  ],
};
final sandboxErrorFunctionCases = [
  SandboxFunctionCase(
    'log',
    r'$log[$message[message]]done',
    0,
    'done',
    label: 'captures the resolved log without Discord',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'message': 'Sandbox diagnostic'},
    },
    expectedValues: {
      '/logs': ['Sandbox diagnostic'],
    },
  ),
  for (final name in ['try', 'catch', 'endtry'])
    SandboxFunctionCase(
      name,
      r'$try$httpGet[https://example.com/data]$setVar[unreachable;yes]$catch$setVar[caught;yes]recovered$endtry$sendMessage[after]',
      0,
      'after\nrecovered',
      label: 'failure is caught',
      scenario: _failure,
      expectedValues: {
        '/storage_after/global': {'caught': 'yes'},
      },
    ),
  SandboxFunctionCase(
    'try',
    r'$try$setVar[ok;yes]success$catch wrong$endtry$sendMessage[after]',
    0,
    'after\nsuccess',
    label: 'successful body',
    expectedValues: {
      '/storage_after/global': {'ok': 'yes'},
    },
  ),
  SandboxFunctionCase(
    'try',
    r'$try$httpGet[https://example.com/data]$setVar[unreachable;yes]$endtry$sendMessage[after]',
    0,
    'after',
    label: 'no catch',
    scenario: _failure,
    expectedValues: {'/storage_after/global': {}},
  ),
  SandboxFunctionCase(
    'error',
    r'$try$httpGet[https://example.com/data]$catch$error[message]$endtry',
    0,
    'Bad state: offline',
    scenario: _failure,
  ),
  SandboxFunctionCase(
    'error',
    r'$try$httpGet[https://example.com/data]$catch$error[command]|$error[row]|$error[source]$endtry',
    0,
    r'$httpGet|1|$try$httpGet[https://example.com/data]$catch$error[command]|$error[row]|$error[source]$endtry',
    label: 'command, row and source of the failing function',
    scenario: _failure,
  ),
  SandboxFunctionCase(
    'error',
    r'$try$httpGet[https://example.com/data]$catch$error[other]$endtry',
    0,
    '',
    label: 'unknown error type',
    scenario: _failure,
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:45 $error: Error type must be command, message, source, row or column.',
    },
  ),
  SandboxFunctionCase(
    'suppresserrors',
    r'$suppressErrors[custom error]$httpGet[https://example.com/data]$setVar[unreachable;yes]',
    0,
    'custom error',
    scenario: _failure,
    expectedValues: {'/storage_after/global': {}},
  ),
  SandboxFunctionCase(
    'suppresserrors',
    r'$suppressErrors$httpGet[https://example.com/data]$setVar[unreachable;yes]',
    0,
    '',
    label: 'silent',
    scenario: _failure,
    expectedValues: {'/storage_after/global': {}},
  ),
  SandboxFunctionCase(
    'embedsuppresserrors',
    r'$embedSuppressErrors[Error;Failed;#FF0000;Author;Footer;https://example.com/icon.png]$httpGet[https://example.com/data]',
    0,
    '',
    scenario: _failure,
    expectedValues: {
      '/responses/0/payload/embeds/0/title': 'Error',
      '/responses/0/payload/embeds/0/description': 'Failed',
    },
  ),
];

import 'function_suite.dart';

const _failure = {
  'http': [
    {'url': 'https://example.com/data', 'error': 'offline'},
  ],
};
final sandboxErrorFunctionCases = [
  SandboxFunctionCase(
    'log',
    r'$log[((opts.message));info]done',
    0,
    'done',
    label: 'captures the resolved log without Discord',
    scenario: {
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
      'recovered\nafter',
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
    'success\nafter',
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
    r'$embedSuppressErrors[Error;Failed;FF0000;Author;Footer;https://example.com/icon.png]$httpGet[https://example.com/data]',
    0,
    '',
    scenario: _failure,
    expectedValues: {
      '/responses/0/payload/embeds/0/title': 'Error',
      '/responses/0/payload/embeds/0/description': 'Failed',
    },
  ),
];

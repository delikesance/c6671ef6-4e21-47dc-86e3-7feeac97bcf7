import 'function_suite.dart';

const _workflows = [
  {
    'name': 'Greeting',
    'entryPoint': 'main',
    'arguments': [
      {'name': 'name', 'required': true},
    ],
    'actions': [
      {
        'type': 'setGlobalVariable',
        'key': 'save',
        'payload': {
          'key': 'greeting',
          'value': '((arg.name))',
          'valueType': 'string',
        },
      },
    ],
  },
];

const sandboxWorkflowFunctionCases = [
  SandboxFunctionCase(
    'callworkflow',
    r'$callWorkflow[Greeting;name=Alice]$workflowResponse',
    0,
    'WORKFLOW_OK:main',
    scenario: {'workflows': _workflows},
    expectedValues: {
      '/storage_after/global/greeting': 'Alice',
      '/variables/workflow.name': 'Greeting',
    },
    label: 'runs supplied workflow actions with a named argument',
  ),
  SandboxFunctionCase(
    'workflowresponse',
    r'$callWorkflow[Greeting;name=Bob]$workflowResponse[save]',
    0,
    'OK',
    scenario: {'workflows': _workflows},
    expectedValues: {'/storage_after/global/greeting': 'Bob'},
    label: 'reads the result of a named action in the workflow',
  ),
  SandboxFunctionCase(
    'awaitfunc',
    r'$awaitFunc[Follow Up;21;30]ready',
    0,
    'ready',
    expectedValues: {
      '/storage_after/scoped/user/21/await_follow_up/name': 'follow_up',
      '/storage_after/scoped/user/21/await_follow_up/userId': '21',
      '/storage_after/scoped/user/21/await_follow_up/channelId': '30',
    },
    label: 'stores the pending function for the requested user',
  ),
  SandboxFunctionCase(
    'setmessagevar',
    r'$setMessageVar[note;ok]$getMessageVar[note]',
    0,
    'ok',
    scenario: {
      'variables': {'message.id': '50'},
    },
    expectedValues: {'/storage_after/scoped/message/50/note': 'ok'},
    label: 'writes a variable scoped to the triggering message',
  ),
];

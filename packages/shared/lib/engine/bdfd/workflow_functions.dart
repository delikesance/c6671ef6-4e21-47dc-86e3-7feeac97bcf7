import '../../bot/bot_data_store.dart';
import '../../utils/bdfd_ast.dart';
import '../../utils/workflow_call.dart';
import 'program.dart';
import 'runtime.dart';

/// The adapter executes an existing visual workflow. Native BDFD itself never
/// builds or dispatches Action objects. Arguments are already evaluated data.
typedef BdfdVisualWorkflowRunner =
    Future<Map<String, String>> Function(
      Map<String, dynamic> workflow,
      BdfdContext context,
    );

Map<String, BdfdNativeFunction> bdfdWorkflowFunctions(
  BotDataStore store,
  String botId, {
  BdfdVisualWorkflowRunner? runVisualWorkflow,
}) => {
  'callworkflow': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 100,
    handler: (call) async {
      final name = (await call.argument(0)).trim();
      if (name.isEmpty) {
        throw BdfdNativeError('Workflow name is required.', call.location);
      }
      final arguments = <String, String>{};
      for (var i = 1; i < call.argumentCount; i++) {
        final nodes = call.node.arguments[i];
        final prefix = nodes.isNotEmpty && nodes.first is BdfdTextAst
            ? (nodes.first as BdfdTextAst).value
            : '';
        final equals = prefix.indexOf('=');
        final key = equals > 0 ? prefix.substring(0, equals).trim() : '$i';
        final value = await call.argument(i);
        // Only literal syntax before interpolation can declare an argument
        // name. A data value containing '=' remains a positional argument.
        arguments[key] = equals > 0 ? value.substring(equals + 1) : value;
      }
      final workflow = await call.context.budget.run(
        () => store.getWorkflowByName(botId, name),
      );
      if (workflow == null) {
        throw BdfdNativeError('Workflow not found: $name.', call.location);
      }
      final data = Map<String, dynamic>.from(
        (workflow['data'] as Map?) ?? workflow,
      );
      final entryPoint = normalizeWorkflowEntryPoint(
        data['entryPoint'] ?? workflow['entryPoint'],
      );
      final key = '${name.toLowerCase()}::${entryPoint.toLowerCase()}';
      if (call.context.activeWorkflows.contains(key)) {
        throw BdfdNativeError(
          'Workflow recursion detected: $name ($entryPoint).',
          call.location,
        );
      }
      if (call.context.activeWorkflows.length >= call.context.maxDepth) {
        throw BdfdNativeError(
          'Workflow nesting limit exceeded.',
          call.location,
        );
      }
      final definitions = parseWorkflowArgumentDefinitions(
        data['arguments'] ?? workflow['arguments'],
      );
      final resolved = resolveWorkflowInvocationArguments(
        definitions: definitions,
        providedArguments: arguments,
        enforceRequired: true,
      );
      final source =
          (data['bdfdScriptContent'] ??
                  data['scriptContent'] ??
                  data['bdfdScript'] ??
                  '')
              .toString();
      final isScript =
          data['executionMode'] == 'bdfd_script' || source.trim().isNotEmpty;
      BdfdProgram? program;
      if (isScript) {
        if (data['bdfdBackend'] != 'native-v1') {
          throw BdfdNativeError(
            'Called BDFD workflow must select native-v1: $name.',
            call.location,
          );
        }
        program = call.prepare(source);
      } else if (runVisualWorkflow == null) {
        throw BdfdNativeError(
          'Visual workflow adapter is not configured: $name.',
          call.location,
        );
      }
      applyWorkflowInvocationContext(
        variables: call.context.variables,
        workflowName: name,
        entryPoint: entryPoint,
        definitions: definitions,
        providedArguments: resolved,
      );
      call.context.activeWorkflows.add(key);
      late final Map<String, String> results;
      try {
        if (program != null) {
          final output = await call.executeScript(program);
          results = {
            ...call.context.results,
            'output': output,
            'script': 'BDFD_OK',
          };
        } else {
          await call.context.output?.flush(call.context, call.location);
          results = await call.context.budget.run(
            () => runVisualWorkflow!(data, call.context),
          );
        }
        call.context.variables.removeWhere(
          (key, _) => key.startsWith('workflow.response.'),
        );
        for (final entry in results.entries) {
          call.context.variables['workflow.response.${entry.key}'] =
              entry.value;
        }
        call.context.variables['workflow.response'] = 'WORKFLOW_OK:$entryPoint';
        if (call.context.stopped || results.containsKey('__stopped__')) {
          call.stop();
        }
      } finally {
        call.context.activeWorkflows.remove(key);
      }
      return '';
    },
  ),
  'workflowresponse': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async {
      final property = call.argumentCount > 0
          ? (await call.argument(0)).trim()
          : '';
      return call.context.variables[property.isEmpty
              ? 'workflow.response'
              : 'workflow.response.$property'] ??
          '';
    },
  ),
};

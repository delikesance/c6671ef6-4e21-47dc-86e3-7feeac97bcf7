import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_shared/bot/json_variable_store.dart';
import 'package:bot_creator_shared/bot/variable_database.dart';
import 'package:bot_creator_runner/runner_runtime_controller.dart';
import 'package:bot_creator_runner/stores/sqlite_cli_variable_store.dart';
import 'package:bot_creator_runner/web_log_store.dart';
import 'package:bot_creator_runner/web_runtime_config.dart';
import 'package:bot_creator_runner/web_api_spec.dart';
import 'package:openapi_spec/openapi_spec.dart';

class _CpuSample {
  const _CpuSample({required this.jiffies, required this.timestampMs});

  final int jiffies;
  final int timestampMs;
}

/// The semantic version of the Bot Creator Runner.
final String runnerVersion = _resolveVersion();

String _resolveVersion() {
  const compiled = String.fromEnvironment('VERSION');
  if (compiled.isNotEmpty) return compiled;

  final candidates = <String>{
    'pubspec.yaml',
    File(
      Platform.resolvedExecutable,
    ).parent.parent.uri.resolve('pubspec.yaml').toFilePath(),
  };

  for (final path in candidates) {
    try {
      final pubspec = File(path).readAsStringSync();
      final match = RegExp(r'version:\s*(\S+)').firstMatch(pubspec);
      if (match != null) return match.group(1)!;
    } catch (_) {}
  }

  return 'unknown';
}

/// HTTP API server for the Bot Creator Runner using Alfred.
class RunnerWebBootstrapServer {
  RunnerWebBootstrapServer({
    required this.host,
    required this.port,
    String? apiToken,
    required this.logStore,
    VariableDatabase? variableStore,
    String? dataDir,
  }) : _apiToken = normalizeRunnerApiToken(apiToken),
       _runtimeController = RunnerRuntimeController(dataDir: dataDir),
       _injectedVariableStore = variableStore,
       _dataDir = dataDir {
    if (_injectedVariableStore != null) {
      _variableStore = _injectedVariableStore;
    } else {
      _sqliteVariableStore = SqliteCliVariableStore(
        _resolveRunnerVariablesDir(_dataDir),
      );
      _variableStore = _sqliteVariableStore!;
    }

    _apiSpec = RunnerApiSpec(version: runnerVersion);
    _setupRoutes();
  }

  final String host;
  final int port;
  final String _apiToken;
  final RunnerLogStore logStore;
  final VariableDatabase? _injectedVariableStore;
  final String? _dataDir;

  final RunnerRuntimeController _runtimeController;
  _CpuSample? _lastCpuSample;
  late VariableDatabase _variableStore;
  SqliteCliVariableStore? _sqliteVariableStore;
  final JsonVariableStore _jsonFallbackVariableStore = JsonVariableStore();
  Future<void>? _variableStoreInitFuture;

  late final Alfred _app;
  late final RunnerApiSpec _apiSpec;
  final Completer<void> _lifecycleCompleter = Completer<void>();

  String get listenUrl => 'http://$host:$port';

  void _setupRoutes() {
    _app = Alfred();

    // CORS and Security Headers
    _app.all('*', (req, res) {
      res.headers.set('access-control-allow-origin', '*');
      res.headers.set('access-control-allow-methods', 'GET, POST, OPTIONS');
      res.headers.set(
        'access-control-allow-headers',
        'content-type, authorization, x-bot-webhook-secret, x-webhook-secret',
      );
      res.headers.set('cache-control', 'no-store');

      if (req.method == 'OPTIONS') {
        res.statusCode = HttpStatus.noContent;
        return res.close();
      }
    });

    // Authentication Middleware
    _app.all('*', (req, res) {
      if (!_requiresAuthentication(req.uri.path, req.method)) return;

      if (!_isAuthorized(req)) {
        res.headers.set(
          HttpHeaders.wwwAuthenticateHeader,
          'Bearer realm="bot-creator-runner"',
        );
        throw AlfredException(HttpStatus.unauthorized, {
          'error': 'Missing or invalid bearer token.',
        });
      }
    });

    // Documentation
    _get(
      '/swagger.json',
      (req, res) => _apiSpec.generateJson(),
      summary: 'OpenAPI Specification',
      requiresAuth: false,
    );
    _get('/swagger', (req, res) {
      res.headers.contentType = ContentType.html;
      return _apiSpec.generateHtml();
    }, summary: 'Swagger UI', requiresAuth: false);

    // Public Routes
    _get(
      '/',
      (req, res) => {'name': 'Bot Creator Runner', 'version': runnerVersion},
      summary: 'Runner Information',
      requiresAuth: false,
      responses: {
        '200': RunnerApiSpec.jsonResponse('Runner Information', {
          'name': Schema.string(),
          'version': Schema.string(),
        }),
      },
    );
    _get(
      '/health',
      (req, res) => {'ok': true},
      summary: 'Health Check',
      requiresAuth: false,
      responses: {
        '200': RunnerApiSpec.jsonResponse('Health Status', {
          'ok': Schema.boolean(),
        }),
      },
    );

    // System Status & Logs
    _get(
      '/status',
      (req, res) => _buildStatusPayload(),
      summary: 'System Status',
      responses: {
        '200': RunnerApiSpec.jsonResponse('System Status Payload', {
          'apiVersion': Schema.integer(),
          'running': Schema.boolean(),
          'runningCount': Schema.integer(),
          'bots': Schema.array(items: Schema.object(properties: {
            'botId': Schema.string(),
            'botName': Schema.string(),
            'state': Schema.string(),
          })),
        }),
      },
    );
    _get('/metrics', (req, res) => _handleMetrics(), summary: 'System Metrics');
    _get('/logs', _handleLogs, summary: 'Runner Logs');

    _get('/bots', (req, res) async {
      final entries = await _runtimeController.botStore.listAll();
      return {
        'bots':
            entries
                .map(
                  (e) => {
                    'id': e.id,
                    'name': e.name,
                    'syncedAt': e.syncedAt.toUtc().toIso8601String(),
                  },
                )
                .toList(),
      };
    }, summary: 'List All Bots');

    _post(
      '/bots/sync',
      _handleBotsSync,
      summary: 'Sync Bot Configuration',
      requestBody: RunnerApiSpec.jsonRequest({
        'botId': Schema.string(),
        'botName': Schema.string(),
        'config': Schema.object(properties: {
          'name': Schema.string(),
          'description': Schema.string(),
        }, description: 'Full BotConfig JSON object'),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Sync Result', {
          'ok': Schema.boolean(),
        }),
      },
    );

    // Scoped Bot Actions
    _get('/bots/:id/status', (HttpRequest req, HttpResponse res) {
      final botId = req.params['id'];
      return {'apiVersion': 2, 'bot': _buildBotStatePayload(botId)};
    }, summary: 'Get Bot Status', responses: {
      '200': RunnerApiSpec.jsonResponse('Bot Status', {
        'apiVersion': Schema.integer(),
        'bot': Schema.object(properties: {
          'botId': Schema.string(),
          'state': Schema.string(),
        }),
      }),
    });

    _get(
      '/bots/:id/metrics',
      (HttpRequest req, HttpResponse res) => _handleMetrics(botId: req.params['id']),
      summary: 'Get Bot Metrics',
      responses: {
        '200': RunnerApiSpec.jsonResponse('Bot Metrics', {
          'apiVersion': Schema.integer(),
          'running': Schema.boolean(),
          'rssBytes': Schema.integer(),
          'cpuPercent': Schema.number(),
        }),
      },
    );
    _get('/bots/:id/command-stats', _handleCommandStats, summary: 'Get Bot Command Statistics', responses: {
      '200': RunnerApiSpec.jsonResponse('Command Statistics', {
        'botId': Schema.string(),
        'totalAllTime': Schema.integer(),
        'commands': Schema.array(items: Schema.object(properties: {})),
      }),
    });
    _get('/bots/:id/logs', _handleBotLogs, summary: 'Get Bot Logs', responses: {
      '200': RunnerApiSpec.jsonResponse('Bot Logs', {
        'lines': Schema.array(items: Schema.string()),
      }),
    });

    _post(
      '/bots/:id/start',
      _handleRunnerStart,
      summary: 'Start Bot',
      requestBody: RunnerApiSpec.jsonRequest({
        'botName': Schema.string(),
      }, required: false),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Bot Status', {
          'apiVersion': Schema.integer(),
          'running': Schema.boolean(),
          'bots': Schema.array(items: Schema.object(properties: {
            'botId': Schema.string(),
            'state': Schema.string(),
          })),
        }),
      },
    );
    _post(
      '/bots/:id/stop',
      _handleRunnerStop,
      summary: 'Stop Bot',
      responses: {
        '200': RunnerApiSpec.jsonResponse('Bot Status', {
          'apiVersion': Schema.integer(),
          'running': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/reload',
      _handleBotsReload,
      summary: 'Reload Bot Configuration',
      requestBody: RunnerApiSpec.jsonRequest({
        'config': Schema.object(properties: {}, description: 'Full BotConfig JSON object'),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Reload Result', {
          'ok': Schema.boolean(),
          'reloaded': Schema.boolean(),
        }),
      },
    );

    // Workflows & Commands
    _post(
      '/bots/:id/workflows/sync',
      _handleWorkflowSync,
      summary: 'Sync Workflow',
      requestBody: RunnerApiSpec.jsonRequest({
        'workflowName': Schema.string(),
        'workflow': Schema.object(properties: {}, description: 'Workflow definition Map'),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Sync Result', {
          'ok': Schema.boolean(),
          'workflowName': Schema.string(),
          'running': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/workflows/delete',
      _handleWorkflowDelete,
      summary: 'Delete Workflow',
      requestBody: RunnerApiSpec.jsonRequest({
        'workflowName': Schema.string(),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Delete Result', {
          'ok': Schema.boolean(),
          'workflowName': Schema.string(),
        }),
      },
    );
    _post(
      '/bots/:id/commands/sync',
      _handleCommandSync,
      summary: 'Sync Command',
      requestBody: RunnerApiSpec.jsonRequest({
        'commandId': Schema.string(),
        'command': Schema.object(properties: {}, description: 'Command definition Map'),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Sync Result', {
          'ok': Schema.boolean(),
          'commandId': Schema.string(),
          'running': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/commands/delete',
      _handleCommandDelete,
      summary: 'Delete Command',
      requestBody: RunnerApiSpec.jsonRequest({
        'commandId': Schema.string(),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Delete Result', {
          'ok': Schema.boolean(),
          'commandId': Schema.string(),
        }),
      },
    );
    _post(
      '/bots/:id/scheduled-triggers/sync',
      _handleScheduledTriggerSync,
      summary: 'Sync Scheduled Trigger',
      requestBody: RunnerApiSpec.jsonRequest({
        'triggerId': Schema.string(),
        'trigger': Schema.object(properties: {}, description: 'Trigger definition Map'),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Sync Result', {
          'ok': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/scheduled-triggers/delete',
      _handleScheduledTriggerDelete,
      summary: 'Delete Scheduled Trigger',
      requestBody: RunnerApiSpec.jsonRequest({
        'triggerId': Schema.string(),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Delete Result', {
          'ok': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/inbound-webhooks/sync',
      _handleInboundWebhookSync,
      summary: 'Sync Inbound Webhook',
      requestBody: RunnerApiSpec.jsonRequest({
        'webhookId': Schema.string(),
        'webhook': Schema.object(properties: {}, description: 'Webhook definition Map'),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Sync Result', {
          'ok': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/inbound-webhooks/delete',
      _handleInboundWebhookDelete,
      summary: 'Delete Inbound Webhook',
      requestBody: RunnerApiSpec.jsonRequest({
        'webhookId': Schema.string(),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Delete Result', {
          'ok': Schema.boolean(),
        }),
      },
    );

    // Variables
    _get(
      '/bots/:id/variables/global',
      _handleGetGlobalVariables,
      summary: 'Get Global Variables',
      responses: {
        '200': RunnerApiSpec.jsonResponse('Global Variables', {
          'botId': Schema.string(),
          'variables': Schema.object(properties: {}, description: 'Key-value map of global variables'),
        }),
      },
    );
    _post(
      '/bots/:id/variables/global/set',
      _handleSetGlobalVariable,
      summary: 'Set Global Variable',
      requestBody: RunnerApiSpec.jsonRequest({
        'key': Schema.string(),
        'value': Schema.object(properties: {}, description: 'Any JSON value'),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Set Result', {
          'ok': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/variables/global/rename',
      _handleRenameGlobalVariable,
      summary: 'Rename Global Variable',
      requestBody: RunnerApiSpec.jsonRequest({
        'oldKey': Schema.string(),
        'newKey': Schema.string(),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Rename Result', {
          'ok': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/variables/global/remove',
      _handleRemoveGlobalVariable,
      summary: 'Remove Global Variable',
      requestBody: RunnerApiSpec.jsonRequest({
        'key': Schema.string(),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Remove Result', {
          'ok': Schema.boolean(),
        }),
      },
    );

    _get(
      '/bots/:id/variables/scoped-definitions',
      _handleGetScopedDefinitions,
      summary: 'Get Scoped Variable Definitions',
      responses: {
        '200': RunnerApiSpec.jsonResponse('Scoped Definitions', {
          'botId': Schema.string(),
          'definitions': Schema.array(items: Schema.object(properties: {
            'key': Schema.string(),
            'scope': Schema.string(),
            'defaultValue': Schema.object(properties: {}),
            'valueType': Schema.string(),
          })),
        }),
      },
    );
    _post(
      '/bots/:id/variables/scoped-definitions/set',
      _handleSetScopedDefinition,
      summary: 'Set Scoped Variable Definition',
      requestBody: RunnerApiSpec.jsonRequest({
        'scope': Schema.string(),
        'key': Schema.string(),
        'defaultValue': Schema.object(properties: {}),
        'valueType': Schema.string(),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Set Result', {
          'ok': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/variables/scoped-definitions/remove',
      _handleRemoveScopedDefinition,
      summary: 'Remove Scoped Variable Definition',
      requestBody: RunnerApiSpec.jsonRequest({
        'key': Schema.string(),
        'scope': Schema.string(),
        'purgeStoredValues': Schema.boolean(),
      }),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Remove Result', {
          'ok': Schema.boolean(),
        }),
      },
    );

    _get(
      '/bots/:id/variables/scoped-values',
      _handleGetScopedValues,
      summary: 'Get Scoped Variable Values',
      responses: {
        '200': RunnerApiSpec.jsonResponse('Scoped Values', {
          'botId': Schema.string(),
          'scope': Schema.string(),
          'key': Schema.string(),
          'values': Schema.object(properties: {}, description: 'Map of contextId to value'),
        }),
      },
    );

    // Debug Replays
    _get(
      '/bots/:id/debug-replays',
      _handleDebugReplays,
      summary: 'Get Debug Replays',
      responses: {
        '200': RunnerApiSpec.jsonResponse('Debug Replays', {
          'botId': Schema.string(),
          'capturing': Schema.boolean(),
          'replays': Schema.array(items: Schema.object(properties: {})),
        }),
      },
    );
    _post(
      '/bots/:id/debug-replays/clear',
      _handleClearDebugReplays,
      summary: 'Clear Debug Replays',
      responses: {
        '200': RunnerApiSpec.jsonResponse('Clear Result', {
          'ok': Schema.boolean(),
        }),
      },
    );
    _post(
      '/bots/:id/debug-replays/capture',
      _handleSetDebugReplayCapture,
      summary: 'Set Debug Replay Capture State',
      requestBody: RunnerApiSpec.jsonRequest({
        'enabled': Schema.boolean(),
      }),
    );

    // Inbound Webhooks (Dynamic Path)
    _post(
      '/bots/:id/inbound/:pathKey',
      _handleInboundWebhook,
      summary: 'Trigger Inbound Webhook',
      requiresAuth: false,
      requestBody: RunnerApiSpec.jsonRequest({}, description: 'Any JSON payload'),
      responses: {
        '200': RunnerApiSpec.jsonResponse('Trigger Result', {
          'ok': Schema.boolean(),
          'botId': Schema.string(),
          'path': Schema.string(),
          'workflow': Schema.string(),
        }),
      },
    );
  }

  void _get(
    String path,
    dynamic handler, {
    String? summary,
    String? description,
    bool requiresAuth = true,
    Map<String, Response>? responses,
  }) {
    _app.get(path, handler);
    _apiSpec.addRoute(
      path: path,
      method: 'get',
      summary: summary,
      description: description,
      requiresAuth: requiresAuth,
      responses: responses,
    );
  }

  void _post(
    String path,
    dynamic handler, {
    String? summary,
    String? description,
    bool requiresAuth = true,
    RequestBody? requestBody,
    Map<String, Response>? responses,
  }) {
    _app.post(path, handler);
    _apiSpec.addRoute(
      path: path,
      method: 'post',
      summary: summary,
      description: description,
      requiresAuth: requiresAuth,
      requestBody: requestBody,
      responses: responses,
    );
  }

  Future<void> start() async {
    await _app.listen(port, host);
  }

  Future<void> waitForShutdown() => _lifecycleCompleter.future;

  Future<void> selfHeal() => _runtimeController.selfHeal();

  Future<void> stop() async {
    await _runtimeController.dispose();
    _sqliteVariableStore?.dispose();
    final activeStore = _variableStore;
    if (activeStore is SqliteCliVariableStore &&
        !identical(activeStore, _sqliteVariableStore)) {
      activeStore.dispose();
    }
    await _app.close();
    if (!_lifecycleCompleter.isCompleted) {
      _lifecycleCompleter.complete();
    }
  }

  // --- Handlers ---

  Future<void> _handleBotsSync(HttpRequest req, HttpResponse res) async {
    final payload = await req.bodyAsJsonMap;
    final botId = (payload['botId'] ?? '').toString().trim();
    final botName = (payload['botName'] ?? '').toString().trim();

    if (botId.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {'error': 'Missing botId.'});
    }

    final rawConfig = payload['config'];
    if (rawConfig == null || rawConfig is! Map) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing or invalid config payload.',
      });
    }

    try {
      final config = BotConfig.fromJson(Map<String, dynamic>.from(rawConfig));
      config.validate();
      await _runtimeController.botStore.save(
        botId,
        botName.isEmpty ? botId : botName,
        config,
      );
      return res.json({'ok': true});
    } catch (e) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Invalid config: $e',
      });
    }
  }

  Future<void> _handleRunnerStart(HttpRequest req, HttpResponse res) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final botName = (payload['botName'] ?? '').toString().trim();

    try {
      await _runtimeController.startBot(
        botId: botId,
        botName: botName.isEmpty ? null : botName,
      );
      return res.json(_buildStatusPayload());
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.conflict, {'error': e.message});
    }
  }

  Future<void> _handleRunnerStop(HttpRequest req, HttpResponse res) async {
    final botId = req.params['id'];
    await _runtimeController.stopBot(botId);
    return res.json(_buildStatusPayload());
  }

  Future<void> _handleBotsReload(HttpRequest req, HttpResponse res) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final rawConfig = payload['config'];

    if (rawConfig == null || rawConfig is! Map) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing or invalid config payload.',
      });
    }

    try {
      final config = BotConfig.fromJson(Map<String, dynamic>.from(rawConfig));
      config.validate();
      await _runtimeController.reloadBot(botId, config);
      return res.json({
        'ok': true,
        'reloaded': _runtimeController.isBotRunning(botId),
      });
    } catch (e) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Invalid config: $e',
      });
    }
  }

  Future<void> _handleCommandSync(HttpRequest req, HttpResponse res) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final commandId = (payload['commandId'] ?? '').toString().trim();
    final rawCommand = payload['command'];

    if (commandId.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing commandId.',
      });
    }
    if (rawCommand == null || rawCommand is! Map) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing or invalid command payload.',
      });
    }

    final command = Map<String, dynamic>.from(rawCommand)..['id'] = commandId;

    try {
      await _runtimeController.upsertCommand(botId, command);
      return res.json({
        'ok': true,
        'botId': botId,
        'commandId': commandId,
        'running': _runtimeController.isBotRunning(botId),
      });
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.notFound, {'error': e.message});
    }
  }

  Future<void> _handleCommandDelete(HttpRequest req, HttpResponse res) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final commandId = (payload['commandId'] ?? '').toString().trim();

    if (commandId.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing commandId.',
      });
    }

    try {
      await _runtimeController.deleteCommand(botId, commandId);
      return res.json({
        'ok': true,
        'botId': botId,
        'commandId': commandId,
        'running': _runtimeController.isBotRunning(botId),
      });
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.notFound, {'error': e.message});
    }
  }

  Future<void> _handleWorkflowSync(HttpRequest req, HttpResponse res) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final workflowName = (payload['workflowName'] ?? '').toString().trim();
    final rawWorkflow = payload['workflow'];

    if (workflowName.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing workflowName.',
      });
    }
    if (rawWorkflow == null || rawWorkflow is! Map) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing or invalid workflow payload.',
      });
    }

    final workflow = Map<String, dynamic>.from(rawWorkflow)
      ..['name'] = workflowName;

    try {
      await _runtimeController.upsertWorkflow(botId, workflow);
      return res.json({
        'ok': true,
        'botId': botId,
        'workflowName': workflowName,
        'running': _runtimeController.isBotRunning(botId),
      });
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.notFound, {'error': e.message});
    }
  }

  Future<void> _handleWorkflowDelete(HttpRequest req, HttpResponse res) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final workflowName = (payload['workflowName'] ?? '').toString().trim();

    if (workflowName.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing workflowName.',
      });
    }

    try {
      await _runtimeController.deleteWorkflow(botId, workflowName);
      return res.json({
        'ok': true,
        'botId': botId,
        'workflowName': workflowName,
        'running': _runtimeController.isBotRunning(botId),
      });
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.notFound, {'error': e.message});
    }
  }

  Future<void> _handleScheduledTriggerSync(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final triggerId = (payload['triggerId'] ?? '').toString().trim();
    final trigger = payload['trigger'];

    if (triggerId.isEmpty || trigger == null || trigger is! Map) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing triggerId or trigger payload.',
      });
    }

    try {
      await _runtimeController.upsertScheduledTrigger(
        botId,
        triggerId,
        Map<String, dynamic>.from(trigger),
      );
      return res.json({'ok': true});
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.notFound, {'error': e.message});
    }
  }

  Future<void> _handleScheduledTriggerDelete(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final triggerId = (payload['triggerId'] ?? '').toString().trim();

    if (triggerId.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing triggerId.',
      });
    }

    try {
      await _runtimeController.deleteScheduledTrigger(botId, triggerId);
      return res.json({'ok': true});
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.notFound, {'error': e.message});
    }
  }

  Future<void> _handleInboundWebhookSync(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final webhookId = (payload['webhookId'] ?? '').toString().trim();
    final webhook = payload['webhook'];

    if (webhookId.isEmpty || webhook == null || webhook is! Map) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing webhookId or webhook payload.',
      });
    }

    try {
      await _runtimeController.upsertInboundWebhook(
        botId,
        webhookId,
        Map<String, dynamic>.from(webhook),
      );
      return res.json({'ok': true});
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.notFound, {'error': e.message});
    }
  }

  Future<void> _handleInboundWebhookDelete(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final webhookId = (payload['webhookId'] ?? '').toString().trim();

    if (webhookId.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing webhookId.',
      });
    }

    try {
      await _runtimeController.deleteInboundWebhook(botId, webhookId);
      return res.json({'ok': true});
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.notFound, {'error': e.message});
    }
  }

  Future<Map<String, dynamic>> _handleGetGlobalVariables(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final entry = await _runtimeController.botStore.loadEntry(botId);
    if (entry == null) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Bot "$botId" not found.',
      });
    }

    await _ensureVariableStoreInitialized();
    final runtime = await _variableStore.getGlobalVariables(botId);
    return {
      'botId': botId,
      'variables': {...entry.config.globalVariables, ...runtime},
    };
  }

  Future<void> _handleSetGlobalVariable(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final key = (payload['key'] ?? '').toString().trim();
    if (key.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {'error': 'Missing key.'});
    }

    final entry = await _runtimeController.botStore.loadEntry(botId);
    if (entry == null) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Bot "$botId" not found.',
      });
    }

    await _runtimeController.upsertGlobalVariable(botId, key, payload['value']);
    await _ensureVariableStoreInitialized();
    await _variableStore.setGlobalVariable(botId, key, payload['value']);

    return res.json({'ok': true});
  }

  Future<void> _handleRenameGlobalVariable(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final oldKey = (payload['oldKey'] ?? '').toString().trim();
    final newKey = (payload['newKey'] ?? '').toString().trim();
    if (oldKey.isEmpty || newKey.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing oldKey or newKey.',
      });
    }

    final entry = await _runtimeController.botStore.loadEntry(botId);
    if (entry == null) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Bot "$botId" not found.',
      });
    }

    await _runtimeController.renameGlobalVariable(botId, oldKey, newKey);
    await _ensureVariableStoreInitialized();
    final current = await _variableStore.getGlobalVariables(botId);
    if (current.containsKey(oldKey)) {
      final value = current[oldKey];
      await _variableStore.removeGlobalVariable(botId, oldKey);
      await _variableStore.setGlobalVariable(botId, newKey, value);
    }
    return res.json({'ok': true});
  }

  Future<void> _handleRemoveGlobalVariable(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final key = (payload['key'] ?? '').toString().trim();
    if (key.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {'error': 'Missing key.'});
    }

    final entry = await _runtimeController.botStore.loadEntry(botId);
    if (entry == null) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Bot "$botId" not found.',
      });
    }

    await _runtimeController.removeGlobalVariable(botId, key);
    await _ensureVariableStoreInitialized();
    await _variableStore.removeGlobalVariable(botId, key);
    return res.json({'ok': true});
  }

  Future<Map<String, dynamic>> _handleGetScopedDefinitions(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final entry = await _runtimeController.botStore.loadEntry(botId);
    if (entry == null) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Bot "$botId" not found.',
      });
    }

    return {
      'botId': botId,
      'definitions': entry.config.scopedVariableDefinitions,
    };
  }

  Future<void> _handleSetScopedDefinition(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final scope = (payload['scope'] ?? '').toString().trim();
    final key = _normalizeScopedStorageKey((payload['key'] ?? '').toString());
    if (scope.isEmpty || key.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing scope or key.',
      });
    }

    final entry = await _runtimeController.botStore.loadEntry(botId);
    if (entry == null) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Bot "$botId" not found.',
      });
    }

    await _runtimeController.upsertScopedVariableDefinition(
      botId,
      key,
      scope,
      payload['defaultValue'],
      valueType: (payload['valueType'] ?? 'string').toString(),
    );
    return res.json({'ok': true});
  }

  Future<void> _handleRemoveScopedDefinition(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final key = _normalizeScopedStorageKey((payload['key'] ?? '').toString());
    final scope = (payload['scope'] ?? '').toString().trim();
    final purgeStoredValues = payload['purgeStoredValues'] == true;
    if (key.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {'error': 'Missing key.'});
    }

    final entry = await _runtimeController.botStore.loadEntry(botId);
    if (entry == null) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Bot "$botId" not found.',
      });
    }

    final scopesToPurge =
        purgeStoredValues
            ? <String>{
              if (scope.isNotEmpty) scope,
              if (scope.isEmpty)
                ...entry.config.scopedVariableDefinitions
                    .where(
                      (d) =>
                          _normalizeScopedStorageKey(
                            (d['key'] ?? '').toString(),
                          ) ==
                          key,
                    )
                    .map((d) => (d['scope'] ?? '').toString().trim())
                    .where((v) => v.isNotEmpty),
            }
            : const <String>{};

    await _runtimeController.deleteScopedVariableDefinition(
      botId,
      key,
      scope: scope.isEmpty ? null : scope,
      purgeStoredValues: purgeStoredValues,
    );
    for (final scopeName in scopesToPurge) {
      await _removeAllScopedValuesForKey(botId, scopeName, key);
    }
    return res.json({'ok': true});
  }

  Future<Map<String, dynamic>> _handleGetScopedValues(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final entry = await _runtimeController.botStore.loadEntry(botId);
    if (entry == null) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Bot "$botId" not found.',
      });
    }

    final scope = (req.uri.queryParameters['scope'] ?? '').trim();
    final keyRaw = (req.uri.queryParameters['key'] ?? '').trim();
    if (scope.isEmpty || keyRaw.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Missing scope or key query parameter.',
      });
    }

    final storageKey = _normalizeScopedStorageKey(keyRaw);
    final legacyKey = _toScopedReferenceKey(storageKey);

    await _ensureVariableStoreInitialized();
    final contextIds = List<String>.from(
      await _variableStore.listContextIds(botId, scope, searchKey: storageKey),
      growable: true,
    );
    if (legacyKey != storageKey) {
      contextIds.addAll(
        await _variableStore.listContextIds(botId, scope, searchKey: legacyKey),
      );
    }
    final uniqueContextIds = contextIds.toSet().toList()..sort();

    final values = <String, dynamic>{};
    for (final contextId in uniqueContextIds) {
      var value = await _variableStore.getScopedVariable(
        botId,
        scope,
        contextId,
        storageKey,
      );
      if (value == null && legacyKey != storageKey) {
        value = await _variableStore.getScopedVariable(
          botId,
          scope,
          contextId,
          legacyKey,
        );
      }
      if (value != null) values[contextId] = value;
    }

    return {
      'botId': botId,
      'scope': scope,
      'key': storageKey,
      'values': values,
    };
  }

  Future<Map<String, dynamic>> _handleDebugReplays(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final limit = int.tryParse(req.uri.queryParameters['limit'] ?? '30') ?? 30;
    try {
      final replays = _runtimeController.listDebugReplays(botId, limit: limit);
      return {
        'botId': botId,
        'capturing': _runtimeController.isDebugReplayCapturing(botId),
        'replays': replays,
      };
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.conflict, {'error': e.message});
    }
  }

  Future<Map<String, bool>> _handleClearDebugReplays(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    try {
      _runtimeController.clearDebugReplays(botId);
      return {'ok': true};
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.conflict, {'error': e.message});
    }
  }

  Future<Map<String, bool>> _handleSetDebugReplayCapture(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final payload = await req.bodyAsJsonMap;
    final enabled = payload['enabled'] == true;
    try {
      _runtimeController.setDebugReplayCapturing(botId, enabled);
      return {
        'ok': true,
        'capturing': _runtimeController.isDebugReplayCapturing(botId),
      };
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.conflict, {'error': e.message});
    }
  }

  Future<Map<String, dynamic>> _handleInboundWebhook(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final pathKey = req.params['pathKey'];
    final payload = await req.bodyAsJsonMap;

    final entry = await _runtimeController.botStore.loadEntry(botId);
    if (entry == null) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Bot "$botId" not found.',
      });
    }
    if (!entry.config.inboundWebhooks) {
      throw AlfredException(HttpStatus.forbidden, {
        'error': 'Inbound webhooks are disabled for bot "$botId".',
      });
    }

    final endpoint = entry.config.inboundWebhookEndpoints
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .firstWhere((candidate) {
          final configuredPath =
              (candidate['path'] ?? '').toString().trim().toLowerCase();
          return configuredPath == pathKey.trim().toLowerCase() &&
              candidate['enabled'] != false;
        }, orElse: () => const <String, dynamic>{});

    if (endpoint.isEmpty) {
      throw AlfredException(HttpStatus.notFound, {
        'error': 'Inbound webhook path not found.',
      });
    }

    final expectedSecret = (endpoint['secret'] ?? '').toString().trim();
    final providedSecret =
        (req.headers.value('x-bot-webhook-secret') ??
                req.headers.value('x-webhook-secret') ??
                req.uri.queryParameters['secret'] ??
                '')
            .trim();

    if (expectedSecret.isNotEmpty && providedSecret != expectedSecret) {
      throw AlfredException(HttpStatus.unauthorized, {
        'error': 'Invalid webhook secret.',
      });
    }

    final workflowName = (endpoint['workflowName'] ?? '').toString().trim();
    if (workflowName.isEmpty) {
      throw AlfredException(HttpStatus.badRequest, {
        'error': 'Inbound webhook misconfigured.',
      });
    }

    final headers = <String, String>{};
    req.headers.forEach((name, values) {
      if (values.isNotEmpty) headers[name.toLowerCase()] = values.join(',');
    });

    try {
      await _runtimeController.triggerInboundWebhook(
        botId,
        workflowName: workflowName,
        payload: payload,
        headers: headers,
        requestId: req.headers.value('x-request-id'),
        sourceIp: req.connectionInfo?.remoteAddress.address ?? 'unknown',
      );
      return {
        'ok': true,
        'botId': botId,
        'path': pathKey,
        'workflow': workflowName,
      };
    } on StateError catch (e) {
      throw AlfredException(HttpStatus.conflict, {'error': e.message});
    }
  }

  Future<Map<String, dynamic>> _handleCommandStats(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final hours = int.tryParse(req.uri.queryParameters['hours'] ?? '24') ?? 24;
    final sinceMs = hours * 3600000;

    final store = _runtimeController.commandStatsStore;
    return {
      'botId': botId,
      'hours': hours,
      'totalAllTime': store.totalCount(botId),
      'commands': store.querySummary(botId, sinceMs: sinceMs),
      'timeline': store.queryTimeline(botId, hours: hours),
      'locales': store.queryLocales(botId, sinceMs: sinceMs),
      'health': store.queryHealthMetrics(botId, sinceMs: sinceMs),
    };
  }

  Future<Map<String, dynamic>> _handleMetrics({String? botId}) async {
    final running = _runtimeController.isRunning;
    return {
      'apiVersion': 2,
      'running': running,
      'runningCount': _runtimeController.runningCount,
      'rssBytes': running ? ProcessInfo.currentRss : null,
      'cpuPercent': running ? _readCurrentProcessCpuPercent() : null,
      'bots':
          botId == null
              ? _runtimeController
                  .listRuntimeStates()
                  .map(_runtimeStateToPayload)
                  .toList()
              : [_buildBotStatePayload(botId)],
    };
  }

  Future<Map<String, dynamic>> _handleLogs(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final limit =
        int.tryParse(req.uri.queryParameters['limit'] ?? '200') ?? 200;
    return {'lines': logStore.tail(limit: limit)};
  }

  Future<Map<String, dynamic>> _handleBotLogs(
    HttpRequest req,
    HttpResponse res,
  ) async {
    final botId = req.params['id'];
    final limit =
        int.tryParse(req.uri.queryParameters['limit'] ?? '200') ?? 200;
    return {'lines': logStore.tail(botId: botId, limit: limit)};
  }

  // --- Helpers ---

  Future<void> _ensureVariableStoreInitialized() {
    if (_sqliteVariableStore == null) return Future.value();
    _variableStoreInitFuture ??= _initializeSqliteStoreWithFallback(
      _sqliteVariableStore!,
    );
    return _variableStoreInitFuture!;
  }

  Future<void> _initializeSqliteStoreWithFallback(
    SqliteCliVariableStore sqlite,
  ) async {
    try {
      await sqlite.init();
    } catch (_) {
      sqlite.dispose();
      _sqliteVariableStore = null;
      _variableStore = _jsonFallbackVariableStore;
    }
  }

  Map<String, dynamic> _buildStatusPayload() {
    return {
      'apiVersion': 2,
      'running': _runtimeController.isRunning,
      'runningCount': _runtimeController.runningCount,
      'bots':
          _runtimeController
              .listRuntimeStates()
              .map(_runtimeStateToPayload)
              .toList(),
    };
  }

  Map<String, dynamic> _buildBotStatePayload(String botId) {
    return _runtimeStateToPayload(_runtimeController.runtimeStateForBot(botId));
  }

  Map<String, dynamic> _runtimeStateToPayload(RunnerBotRuntimeState state) {
    return {
      'botId': state.botId,
      'botName': state.botName,
      'state': state.state,
      'lastSeenAt': state.lastSeenAt?.toIso8601String(),
      'lastError': state.lastError,
      'baselineRssBytes': state.baselineRssBytes,
    };
  }

  bool _requiresAuthentication(String path, String method) {
    if (_apiToken.isEmpty) return false;
    if (path.contains('/inbound/') && method == 'POST') return false;
    if (path == '/swagger' || path == '/swagger.json') return false;
    return !(method == 'GET' && (path == '/health' || path == '/'));
  }

  bool _isAuthorized(HttpRequest req) {
    final header = req.headers.value(HttpHeaders.authorizationHeader);
    if (header == null || !header.startsWith('Bearer ')) return false;
    return normalizeRunnerApiToken(header.substring(7)) == _apiToken;
  }

  String _normalizeScopedStorageKey(String key) {
    final trimmed = key.trim();
    return (trimmed.startsWith('bc_') && trimmed.length > 3)
        ? trimmed.substring(3)
        : trimmed;
  }

  String _toScopedReferenceKey(String key) {
    final trimmed = key.trim();
    return (trimmed.isEmpty || trimmed.startsWith('bc_'))
        ? trimmed
        : 'bc_$trimmed';
  }

  static String _resolveRunnerVariablesDir(String? dataDir) {
    if (dataDir != null && dataDir.isNotEmpty) {
      return '$dataDir/variables';
    }
    final configured =
        (Platform.environment['BOT_CREATOR_DATA_DIR'] ?? '').trim();
    return configured.isNotEmpty ? '$configured/variables' : './data/variables';
  }

  Future<void> _removeAllScopedValuesForKey(
    String botId,
    String scope,
    String key,
  ) async {
    final storageKey = _normalizeScopedStorageKey(key);
    final legacyKey = _toScopedReferenceKey(storageKey);
    await _ensureVariableStoreInitialized();
    final contextIds =
        (await _variableStore.listContextIds(
          botId,
          scope,
          searchKey: storageKey,
        )).toSet();
    if (legacyKey != storageKey) {
      contextIds.addAll(
        await _variableStore.listContextIds(botId, scope, searchKey: legacyKey),
      );
    }
    for (final cid in contextIds) {
      await _variableStore.removeScopedVariable(botId, scope, cid, storageKey);
      if (legacyKey != storageKey) {
        await _variableStore.removeScopedVariable(botId, scope, cid, legacyKey);
      }
    }
  }

  double? _readCurrentProcessCpuPercent() {
    // Reuse existing CPU logic from original file
    final jiffies = _readCurrentProcessCpuJiffies();
    if (jiffies == null) return null;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final prev = _lastCpuSample;
    _lastCpuSample = _CpuSample(jiffies: jiffies, timestampMs: nowMs);
    if (prev == null) return 0.0;
    final deltaJiffies = jiffies - prev.jiffies;
    final deltaMs = nowMs - prev.timestampMs;
    if (deltaJiffies <= 0 || deltaMs <= 0) return 0.0;
    final percent =
        (deltaJiffies / 100.0) /
        (deltaMs / 1000.0) *
        100.0 /
        Platform.numberOfProcessors.clamp(1, 64);
    return percent.clamp(0.0, 100.0);
  }

  int? _readCurrentProcessCpuJiffies() {
    if (!(Platform.isAndroid || Platform.isLinux)) return null;
    try {
      final stat = File('/proc/self/stat').readAsStringSync();
      final lastParen = stat.lastIndexOf(')');
      final fields = stat.substring(lastParen + 2).trim().split(RegExp(r'\s+'));
      return int.parse(fields[10]) + int.parse(fields[11]);
    } catch (_) {
      return null;
    }
  }
}

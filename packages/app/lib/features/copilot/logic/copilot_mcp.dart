import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'copilot_schema.dart';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/copilot/logic/copilot_command.dart';
import 'package:bot_creator/features/copilot/logic/copilot_configuration.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:uuid/uuid.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/function_suite.dart';
import 'package:bot_creator_shared/utils/bdfd_runtime_reference.dart';
import 'package:bot_creator_shared/utils/event_catalog.dart';

part 'copilot_mcp_configuration.dart';

typedef CopilotApproval =
    Future<bool> Function(String tool, Map<String, dynamic> arguments);

/// One MCP catalogue over official documentation, account API and this device.
/// The local HTTP transport is opt-in, loopback-only and authenticated.
class CopilotMcp {
  CopilotMcp(
    this.api, {
    required this.approve,
    this.botId,
    http.Client? documentationClient,
    this.discordConnect,
  }) : _docsClient = documentationClient ?? http.Client();
  final String? botId;
  final MainApiClient api;
  final CopilotApproval approve;
  final Future<NyxxRest> Function(String token)? discordConnect;
  Future<NyxxRest> _connectDiscord(String token) =>
      discordConnect?.call(token) ?? Nyxx.connectRest(token);
  final http.Client _docsClient;
  List<Map<String, dynamic>> tools = [];
  HttpServer? _server;
  String? _bearer;
  String? _docsSession;
  bool _docsInitialized = false;
  int _rpcID = 0;
  final Map<String, Future<Map<String, dynamic>>> _calls = {};
  final Map<String, String> _callFingerprints = {};

  bool get desktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  String? get endpoint =>
      _server == null ? null : 'http://127.0.0.1:${_server!.port}/mcp';
  String? get bearer => _bearer;
  Future<void> initialize() async {
    final raw =
        jsonDecode(await rootBundle.loadString('assets/copilot/tools.json'))
            as List;
    tools = raw.map((t) => Map<String, dynamic>.from(t as Map)).toList();
  }

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> arguments, {
    required String callID,
    bool alreadyApproved = false,
  }) {
    final fingerprint = jsonEncode({'name': name, 'arguments': arguments});
    if (_callFingerprints.containsKey(callID)) {
      if (_callFingerprints[callID] != fingerprint) {
        return Future.error(StateError('Tool call ID conflict'));
      }
      return _calls[callID]!;
    }
    _callFingerprints[callID] = fingerprint;
    return _calls[callID] = _call(
      name,
      Map<String, dynamic>.from(arguments),
      alreadyApproved,
    );
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> args,
    bool alreadyApproved,
  ) async {
    final candidates = tools.where((t) => t['name'] == name);
    if (candidates.isEmpty) throw StateError('Unknown MCP tool');
    final tool = candidates.single;
    validateArguments(
      Map<String, dynamic>.from(tool['inputSchema'] as Map),
      args,
    );
    if (botId != null && args['bot_id'] != null && args['bot_id'] != botId) {
      throw StateError('Tool targets another bot');
    }
    final botID = args['bot_id'] as String?;
    if (botID != null && !RegExp(r'^\d{15,22}$').hasMatch(botID)) {
      throw StateError('Invalid bot ID');
    }
    final script = args['script'] as String?;
    final commandMutation =
        name == 'local_create_command' ||
        name == 'local_update_command_execution';
    final semanticTarget = botID ?? botId;
    final versionSensitive =
        commandMutation ||
        const {
          'local_validate_bdfd',
          'local_test_command',
          'local_runtime_reference',
        }.contains(name);
    final semantics = versionSensitive && semanticTarget != null
        ? ((await _localBot(semanticTarget))['bdfdUserVariableSemantics'] == 2
              ? 2
              : 1)
        : 2;
    final javascriptRuntime =
        commandMutation &&
        botID != null &&
        await getBotRuntimeEngine(botID) == runtimeEngineJavascript;
    String? existingMode;
    if (name == 'local_update_command_execution' &&
        args['execution_mode'] == null &&
        botID != null) {
      final existing = await AppManager().getAppCommand(
        botID,
        _commandID(args),
      );
      final data = existing['data'];
      if (data is Map) existingMode = data['executionMode'] as String?;
    }
    final executionMode =
        (args['execution_mode'] as String?) ??
        existingMode ??
        (javascriptRuntime ? 'javascript' : 'bdfd_script');
    if (commandMutation) {
      if (javascriptRuntime != (executionMode == 'javascript')) {
        throw StateError('Execution mode does not match the bot runtime');
      }
      copilotExecutionDataForMode(
        executionMode,
        script: script,
        actionsJson: args['actions_json'] as String?,
        legacyUserVariables: semantics == 1,
      );
    }
    if (tool['mutating'] == true &&
        !alreadyApproved &&
        !await approve(name, Map<String, dynamic>.unmodifiable(args))) {
      return {
        'content': [
          {
            'type': 'text',
            'text': 'Action cancelled by the user; nothing was executed.',
          },
        ],
        'isError': true,
      };
    }
    Object? value;
    switch (name) {
      case 'docs_search':
        return _documentation('search_docs', args);
      case 'docs_get':
        return _documentation('get_doc', args);
      case 'remote_list_bots':
        value = (await api.listBots())
            .where((b) => botId == null || b['bot_id'] == botId)
            .toList();
      case 'remote_bot_status':
        final status = await api.getStatus(botId: botID!);
        value = {
          'running': status.isBotRunning(botID),
          'bots': status.bots
              .where((b) => botId == null || b.botId == botId)
              .map(
                (bot) => {
                  'bot_id': bot.botId,
                  'name': bot.botName,
                  'state': bot.state,
                },
              )
              .toList(),
        };
      case 'remote_start_bot':
        await api.startBot(botID!);
        value = {'started': true, 'bot_id': botID};
      case 'remote_stop_bot':
        value = await api.stopBot(botID!);
      case 'local_list_bots':
        value = (await AppManager().getAllApps())
            .whereType<Map>()
            .where((a) => botId == null || a['id'].toString() == botId)
            .map(
              (a) => {
                'id': a['id'],
                'name': a['username'] ?? a['name'],
                'runtime_engine': a['runtimeEngine'] ?? 'dart',
              },
            )
            .toList();
      case 'local_bot_status':
        await _localBot(botID!);
        value = await _localStatus(botID);
      case 'local_list_commands':
        await _localBot(botID!);
        final commands = await AppManager().listAppCommands(botID);
        value = commands
            .where((c) => args['name'] == null || c['name'] == args['name'])
            .map(
              (c) => {
                ...copilotCommandSettings(c),
                if (args['include_execution'] == true) 'data': c['data'],
                'revision': HashUtil.calculateHash(c),
              },
            )
            .toList();
      case 'local_block_registry':
        final requested = (args['functions'] as List?)
            ?.map(
              (f) =>
                  f.toString().replaceFirst(RegExp(r'^\$'), '').toLowerCase(),
            )
            .toSet();
        if (args['include_examples'] == true &&
            (requested == null || requested.isEmpty)) {
          throw const FormatException(
            'Select up to 8 functions before requesting sandbox examples.',
          );
        }
        final functions =
            allBdfdFunctions
                .where((f) => requested == null || requested.contains(f))
                .toList()
              ..sort();
        final covered = sandboxFunctionCases.map((c) => c.function).toSet();
        value = {
          'functions': functions,
          'sandbox_functions': args['include_examples'] == true
              ? sandboxFunctionCatalog()
                    .where((entry) => requested!.contains(entry['function']))
                    .toList()
              : [
                  for (final f in functions)
                    {'function': f, 'covered': covered.contains(f)},
                ],
          if (requested != null)
            'unknown_functions': requested.difference(allBdfdFunctions).toList()
              ..sort(),
          'action_types': BotCreatorActionType.values
              .map((t) => t.name)
              .toList(),
          'action_format': {
            'type': 'respondWithMessage',
            'payload': {'content': 'Hello'},
          },
        };
      case 'local_runtime_reference':
        final runtime = await getBotRuntimeEngine(botID!);
        value = {
          'runtime_engine': runtime,
          'bdfdUserVariableSemantics': semantics,
          if (runtime != runtimeEngineJavascript)
            'reference': bdfdRuntimeReference(
              legacyUserVariables: semantics == 1,
              includeExamples:
                  args['include_examples'] == true ||
                  !(tool['inputSchema']['properties'] as Map).containsKey(
                    'include_examples',
                  ),
            )
          else
            'message':
                'This bundled reference describes the BDFD runtime only. Use JavaScript documentation for this bot.',
        };
      case 'local_test_command':
        final result = await testCommandInSandbox({
          ...Map<String, dynamic>.from(args['scenario'] as Map? ?? {}),
          if (args['script'] != null) 'script': args['script'],
          if (args['actions'] != null) 'actions': args['actions'],
          'bdfdUserVariableSemantics': semantics,
        });
        result['bot_id'] = semanticTarget;
        result['configuration_source'] = semanticTarget == null
            ? 'standalone_official'
            : 'saved_bot_configuration';
        if (args['expected_content'] != null ||
            args['expected_values'] != null) {
          final contract = evaluateSandboxContract(
            result,
            expectedContent: args['expected_content'] as String?,
            expectedValues: Map<String, dynamic>.from(
              args['expected_values'] as Map? ?? {},
            ),
          );
          result['contract_passed'] = contract['passed'];
          result['contract_checks'] = contract['checks'];
        }
        final trace = result['trace'];
        final traceLimit = args['trace_limit'] as int? ?? 40;
        if (trace is List && trace.length > traceLimit) {
          result['trace_total'] = trace.length;
          result['trace_truncated'] = true;
          result['trace'] = trace.take(traceLimit).toList();
        }
        return {
          'content': [
            {'type': 'text', 'text': jsonEncode(result)},
          ],
          'isError':
              result['success'] != true || result['contract_passed'] == false,
        };
      case 'local_validate_bdfd':
        final validation = validateCopilotBdfd(
          script!,
          legacyUserVariables: semantics == 1,
        );
        validation['bot_id'] = semanticTarget;
        validation['configuration_source'] = semanticTarget == null
            ? 'standalone_official'
            : 'saved_bot_configuration';
        return {
          'content': [
            {'type': 'text', 'text': jsonEncode(validation)},
          ],
          'isError': validation['valid'] != true,
        };
      case 'local_get_command':
        await _localBot(botID!);
        final commandID = _commandID(args);
        final command = await AppManager().getAppCommand(botID, commandID);
        if (command.isEmpty) throw StateError('Command not found');
        value = {
          'command': args['view'] == 'settings'
              ? copilotCommandSettings(command)
              : command,
          'revision': HashUtil.calculateHash(command),
        };
      case 'local_update_command_options':
      case 'local_update_command_settings':
      case 'local_list_workflows':
      case 'local_get_workflow':
      case 'local_create_workflow':
      case 'local_update_workflow':
      case 'local_list_events':
      case 'local_get_bot_configuration':
      case 'local_get_bot_presence':
      case 'local_update_bot_presence':
      case 'local_update_bot_profile':
      case 'local_set_variable':
      case 'local_update_scheduled_trigger':
      case 'local_update_inbound_webhook':
        value = await _configurationTool(name, args);
      case 'local_update_command_execution':
        await _localBot(botID!);
        final commandID = _commandID(args);
        final command = await AppManager().getAppCommand(botID, commandID);
        final updated = replaceCopilotExecution(
          command,
          args['expected_revision'] as String,
          script ?? '',
          route: args['route'] as String?,
          executionMode: executionMode,
          actionsJson: args['actions_json'] as String?,
          legacyUserVariables: semantics == 1,
        );
        await AppManager().saveAppCommand(botID, commandID, updated);
        final synced = await syncCloudCommand(botID, commandID);
        value = {
          'saved': true,
          'command_id': commandID,
          'bot_id': botID,
          'runner_synced': synced,
          'message': synced
              ? 'Commande active sur le bot cloud'
              : 'Enregistrée, pas encore active sur le bot cloud',
          'revision': HashUtil.calculateHash(
            await AppManager().getAppCommand(botID, commandID),
          ),
        };
      case 'local_create_command':
        final app = await _localBot(botID!);
        final name = args['name'] as String;
        if (!RegExp(r'^[a-z0-9_-]{1,32}$').hasMatch(name)) {
          throw const FormatException('Invalid slash command name');
        }
        if ((await AppManager().listAppCommands(
          botID,
        )).any((c) => c['name'] == name)) {
          throw StateError('Command already exists; edit it instead');
        }
        final token = (app['token'] ?? '').toString();
        if (token.isEmpty) {
          throw StateError('Configure the bot token in the application');
        }
        final options = validateCopilotOptions(args['options'] as List? ?? []);
        final rest = await _connectDiscord(token);
        try {
          if (rest.user.id.toString() != botID) {
            throw StateError('Bot identity does not match its token');
          }
          if ((await rest.commands.list()).any((c) => c.name == name)) {
            throw StateError(
              'Discord command already exists; import and edit it instead',
            );
          }
          final storageId = const Uuid().v4();
          final created = await createCommand(
            rest,
            ApplicationCommandBuilder(
              type: ApplicationCommandType.chatInput,
              name: name,
              description: args['description'] as String,
              options: deserializeCommandOptions(options),
            ),
            storageId: storageId,
            data:
                withCopilotOptions({
                      'data': copilotExecutionDataForMode(
                        executionMode,
                        script: script,
                        actionsJson: args['actions_json'] as String?,
                        legacyUserVariables: semantics == 1,
                      ),
                    }, options)['data']
                    as Map<String, dynamic>,
          );
          final synced = await syncCloudCommand(botID, storageId);
          value = {
            'created': true,
            'discord_id': created.id.toString(),
            'name': name,
            'command_id': storageId,
            'bot_id': botID,
            'runner_synced': synced,
            'message': synced
                ? 'Commande active sur le bot cloud'
                : 'Créée sur Discord, pas encore active sur le bot',
          };
        } finally {
          rest.close();
        }
      case 'local_start_bot':
        final app = await _localBot(botID!);
        if (await getBotRuntimeEngine(botID) == runtimeEngineJavascript) {
          if (!desktop) {
            throw StateError('The JavaScript runner requires desktop');
          }
          final config = await RunnerSettings.prepareEmbeddedJsRunner();
          if (config == null ||
              !RunnerSettings.isInternalEmbeddedRunner(config)) {
            throw StateError('Local JavaScript runner unavailable');
          }
          final client = config.createClient();
          await client.syncBot(
            botID,
            (app['username'] ?? app['name'] ?? botID).toString(),
            await buildRemotePayload(botID),
          );
          await client.startBot(botID);
          RunnerSettings.associateBotWithRunner(botID, config.id);
        } else {
          final token = (app['token'] ?? '').toString();
          if (token.isEmpty) {
            throw StateError(
              'Bot token is missing; configure it in the application',
            );
          }
          if (desktop) {
            await startDesktopBot(token, expectedBotId: botID);
          } else {
            final rest = await Nyxx.connectRest(token);
            try {
              if (rest.user.id.toString() != botID) {
                throw StateError('Bot identity does not match its token');
              }
            } finally {
              rest.close();
            }
            var permission =
                await FlutterForegroundTask.checkNotificationPermission();
            if (permission != NotificationPermission.granted) {
              await FlutterForegroundTask.requestNotificationPermission();
              permission =
                  await FlutterForegroundTask.checkNotificationPermission();
            }
            if (permission != NotificationPermission.granted) {
              throw StateError('Notification permission is required');
            }
            await initForegroundService();
            await startMobileBotSession(botId: botID, token: token);
            if (!await FlutterForegroundTask.isRunningService) {
              throw StateError('Foreground service did not start');
            }
          }
        }
        setBotRuntimeActive(true);
        value = {'start_requested': true, 'bot_id': botID};
      case 'local_stop_bot':
        await _localBot(botID!);
        if (await getBotRuntimeEngine(botID) == runtimeEngineJavascript) {
          final localConfigs = (await RunnerSettings.getRunners()).where(
            RunnerSettings.isInternalEmbeddedRunner,
          );
          final config = localConfigs.isEmpty ? null : localConfigs.first;
          if (config == null ||
              !RunnerSettings.isInternalEmbeddedRunner(config)) {
            throw StateError('Local JavaScript runner unavailable');
          }
          value = await config.createClient().stopBot(botID);
        } else {
          if (desktop) {
            await stopDesktopBot(botId: botID);
          } else {
            await stopMobileBotSession(botId: botID);
          }
          value = {'stopped': true, 'bot_id': botID};
        }
      default:
        throw StateError('Unsupported MCP tool');
    }
    return {
      'content': [
        {'type': 'text', 'text': jsonEncode(redact(value))},
      ],
    };
  }

  Future<Map<String, dynamic>> _localBot(String id) async {
    final app = await AppManager().getApp(id);
    if (app.isEmpty) {
      throw StateError('Bot is not present on this device');
    }
    return app;
  }

  String _commandID(Map<String, dynamic> args) {
    final id = args['command_id'] as String;
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id)) {
      throw const FormatException('Invalid command ID');
    }
    return id;
  }

  /// Wait for the manager acknowledgement. A persisted command is not treated
  /// as active until its runner confirms the update.
  Future<bool> syncCloudCommand(String botID, String commandID) async {
    try {
      var command = await AppManager().getAppCommand(botID, commandID);
      if (command.isEmpty) return false;
      if (await getBotRuntimeEngine(botID) == runtimeEngineJavascript) {
        final payload = await buildRemotePayload(botID);
        final matches = (payload['commands'] as List? ?? const [])
            .whereType<Map>()
            .where((c) => c['id'] == commandID);
        if (matches.isEmpty) return false;
        command = Map<String, dynamic>.from(matches.single);
      }
      final app = await AppManager().getApp(botID);
      final botName = (app['username'] ?? app['name'] ?? botID).toString();
      Future<bool> delta() =>
          api.syncCommandWithStatus(botID, botName, commandID, command);
      try {
        if (await delta()) return true;
      } catch (_) {
        // The full sync below can recover a stale or missing cloud config.
      }
      try {
        await api.syncBot(
          botID,
          botName,
          await buildRemotePayload(botID),
          force: true,
        );
        return await delta();
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _localStatus(String id) async {
    if (await getBotRuntimeEngine(id) == runtimeEngineJavascript) {
      final localConfigs = (await RunnerSettings.getRunners()).where(
        RunnerSettings.isInternalEmbeddedRunner,
      );
      final config = localConfigs.isEmpty ? null : localConfigs.first;
      if (config == null || !RunnerSettings.isInternalEmbeddedRunner(config)) {
        return {'running': false, 'available': false};
      }
      return {
        'running': (await config.createClient().getStatus(
          botId: id,
        )).isBotRunning(id),
      };
    }
    return {'running': isDesktopBotRunningId(id) || isMobileBotRunning(id)};
  }

  static Object? redact(Object? value) {
    if (value is Map) {
      return {
        for (final e in value.entries)
          if (!RegExp(
            r'token|secret|password|authorization|api.?key',
            caseSensitive: false,
          ).hasMatch(e.key.toString()))
            e.key.toString(): redact(e.value),
      };
    }
    if (value is List) return value.map(redact).toList();
    if (value is String) {
      if (value.trimLeft().startsWith('{') ||
          value.trimLeft().startsWith('[')) {
        try {
          return jsonEncode(redact(jsonDecode(value)));
        } catch (_) {
          /* Plain text follows. */
        }
      }
      return value
          .replaceAll(
            RegExp(
              r'(?:mfa\.[A-Za-z0-9_-]{20,}|[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{20,})',
            ),
            '[REDACTED]',
          )
          .replaceAllMapped(
            RegExp(
              r'authorization\s*[:=]\s*(?:bearer\s+)?[^\s;,\]}]+',
              caseSensitive: false,
            ),
            (_) => 'Authorization: [REDACTED]',
          );
    }
    return value;
  }

  static void validateArguments(
    Map<String, dynamic> schema,
    Map<String, dynamic> args,
  ) {
    validateCopilotSchema(schema, args);
  }

  Future<Map<String, dynamic>> _docsRPC(
    String method,
    Map<String, dynamic> params,
  ) async {
    final id = ++_rpcID;
    final response = await _docsClient
        .post(
          Uri.parse('https://bot-creator.fr/api/mcp'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json, text/event-stream',
            'MCP-Protocol-Version': '2025-11-25',
            'Mcp-Session-Id': ?_docsSession,
          },
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'method': method,
            'params': params,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 ||
        response.bodyBytes.length > 2 * 1024 * 1024) {
      throw StateError('Documentation MCP unavailable');
    }
    _docsSession = response.headers['mcp-session-id'] ?? _docsSession;
    String body = response.body;
    if ((response.headers['content-type'] ?? '').contains(
      'text/event-stream',
    )) {
      final events = body.replaceAll('\r\n', '\n').split('\n\n');
      body = events
          .map(
            (event) => event
                .split('\n')
                .where((line) => line.startsWith('data:'))
                .map((line) => line.substring(5).trimLeft())
                .join('\n'),
          )
          .where((data) => data.trim().isNotEmpty)
          .firstWhere((data) {
            try {
              return (jsonDecode(data) as Map)['id'] == id;
            } catch (_) {
              return false;
            }
          }, orElse: () => throw StateError('Invalid MCP response'));
    }
    final envelope = jsonDecode(body) as Map;
    if (envelope['id'] != id ||
        envelope['error'] != null ||
        envelope['result'] is! Map) {
      throw StateError('Documentation MCP request failed');
    }
    return Map<String, dynamic>.from(envelope['result'] as Map);
  }

  Future<Map<String, dynamic>> _documentation(
    String name,
    Map<String, dynamic> args,
  ) async {
    if (!_docsInitialized) {
      await _docsRPC('initialize', {
        'protocolVersion': '2025-11-25',
        'capabilities': {},
        'clientInfo': {'name': 'bot-creator-studio', 'version': '1.0'},
      });
      await _docsClient
          .post(
            Uri.parse('https://bot-creator.fr/api/mcp'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json, text/event-stream',
              'Mcp-Session-Id': ?_docsSession,
            },
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'notifications/initialized',
            }),
          )
          .timeout(const Duration(seconds: 20));
      _docsInitialized = true;
    }
    return _docsRPC('tools/call', {'name': name, 'arguments': args});
  }

  Future<Map<String, dynamic>?> dispatch(Map<String, dynamic> request) async {
    final id = request['id'];
    if (request['jsonrpc'] != '2.0' || request['method'] is! String) {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': -32600, 'message': 'Invalid Request'},
      };
    }
    final method = request['method'];
    if (method == 'notifications/initialized' && id == null) return null;
    Object? result;
    switch (method) {
      case 'initialize':
        result = {
          'protocolVersion': '2025-11-25',
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': 'bot-creator-studio-bridge', 'version': '1.0'},
          'instructions':
              'Use focused reads and reuse facts already obtained. For command '
              'description/permissions edits, use local_list_commands filtered by '
              'name or local_get_command with view=settings, then '
              'local_update_command_settings with the returned revision. '
              'Execution tests and function docs are needed for execution changes. '
              'local_block_registry omits fixtures by default; request up to 8 '
              'functions with include_examples=true for their sandbox contracts. '
              'After confirmed success, report the result without redundant reads.',
        };
      case 'ping':
        result = {};
      case 'tools/list':
        result = {
          'tools': tools
              .map(
                (t) => {
                  'name': t['name'],
                  'description': t['description'],
                  'inputSchema': t['inputSchema'],
                  'annotations': {
                    'readOnlyHint': t['mutating'] != true,
                    'destructiveHint': t['mutating'] == true,
                  },
                },
              )
              .toList(),
        };
      case 'tools/call':
        final params = Map<String, dynamic>.from(
          request['params'] as Map? ?? {},
        );
        try {
          result = await call(
            params['name'] as String,
            Map<String, dynamic>.from(params['arguments'] as Map? ?? {}),
            callID: 'mcp:${++_rpcID}:${jsonEncode(id)}',
          );
        } catch (error) {
          result = {
            'isError': true,
            'content': [
              {
                'type': 'text',
                'text': redact(
                  error is FormatException
                      ? error.message.toString()
                      : error is StateError
                      ? error.message.toString()
                      : 'Tool failed. Check the target, permissions and runtime in the application.',
                ),
              },
            ],
          };
        }
      default:
        return {
          'jsonrpc': '2.0',
          'id': id,
          'error': {'code': -32601, 'message': 'Method not found'},
        };
    }
    return {'jsonrpc': '2.0', 'id': id, 'result': result};
  }

  Future<void> startServer() async {
    if (!desktop || _server != null) return;
    _bearer = base64UrlEncode(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen((request) async {
      final response = request.response;
      try {
        if (request.headers.value('origin') != null) {
          response.statusCode = 403;
          return;
        }
        if (request.headers.value('authorization') != 'Bearer $_bearer') {
          response.statusCode = 401;
          return;
        }
        if (request.uri.path != '/mcp') {
          response.statusCode = 404;
          return;
        }
        if (request.method != 'POST') {
          response.statusCode = 405;
          response.headers.set('Allow', 'POST');
          return;
        }
        final data = <int>[];
        await for (final chunk in request) {
          data.addAll(chunk);
          if (data.length > 128 * 1024) {
            response.statusCode = 413;
            return;
          }
        }
        final message = Map<String, dynamic>.from(
          jsonDecode(utf8.decode(data)) as Map,
        );
        final reply = await dispatch(message);
        if (reply == null) {
          response.statusCode = 202;
        } else {
          response.headers.contentType = ContentType.json;
          response.write(jsonEncode(reply));
        }
      } catch (_) {
        response.statusCode = 400;
      } finally {
        await response.close();
      }
    });
  }

  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
    _bearer = null;
    _docsClient.close();
  }
}

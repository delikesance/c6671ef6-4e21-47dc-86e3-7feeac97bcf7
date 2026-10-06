import '../services/bot_component_service.dart';
import '../services/bot_cooldown_service.dart';
import '../services/bot_timing_service.dart';
import '../services/bot_webhook_service.dart';
import '../services/bot_command_query_service.dart';
import '../services/bot_channel_permission_service.dart';
import '../services/bot_permission_query_service.dart';
import '../services/bot_user_query_service.dart';
import '../services/bot_member_query_service.dart';
import '../services/bot_guild_query_service.dart';
import '../services/bot_thread_service.dart';
import '../services/bot_message_query_service.dart';
import '../services/bot_reaction_service.dart';
import '../services/bot_emoji_service.dart';
import '../services/bot_channel_mutation_service.dart';
import '../services/bot_channel_query_service.dart';
import 'dart:async';
import '../services/bot_moderation_service.dart';
import '../services/bot_music_service.dart';
import '../services/bot_role_query_service.dart';
import '../services/permission_checks.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import '../engine/bdfd/visual/http_logic.dart';
import '../engine/bdfd/execution.dart';
import '../engine/bdfd/program.dart';
import '../engine/bdfd/runtime.dart';
import '../engine/execution_budget.dart';
import '../engine/discord_entity_fetcher.dart' show DiscordEntityNotFound;
import '../services/bot_message_service.dart';
import '../services/http_service.dart';
import '../services/runtime_temporary_variables.dart';
import '../actions/send_component_v2.dart';
import '../actions/respond_modal.dart';
import '../services/bot_webhook_block_service.dart' show buildWebhookMessage;
import '../types/component.dart';
import '../actions/execution_policy.dart';
import '../services/bot_moderation_blocks.dart'
    show isRoleDefinitionPayload, parseBdfdRoleColor;
import '../actions/handler.dart';
import '../types/action.dart';
import '../utils/bdfd_duration_parser.dart';
import '../utils/runtime_variables.dart';
import '../utils/message_runtime.dart';
import '../utils/global.dart';
import '../utils/template_resolver.dart';
import 'sandbox_store.dart';
import 'entity_fixture_gateway.dart';
import 'action_simulations.dart';
import 'music_fixture.dart';

/// Runs only caller-provided fixtures; never reads the application's real store
/// or connects a Discord client. Killing the isolate also stops busy loops.
Future<Map<String, dynamic>> testCommandInSandbox(
  Map<String, dynamic> request, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final encoded = jsonEncode(request);
  if (encoded.length > 512000) {
    return {'success': false, 'error': 'Sandbox fixture size limit exceeded'};
  }
  final input = jsonDecode(encoded) as Map<String, dynamic>;
  final port = ReceivePort();
  Isolate? worker;
  try {
    worker = await Isolate.spawn(_sandboxWorker, [port.sendPort, input]);
    return Map<String, dynamic>.from(await port.first.timeout(timeout) as Map);
  } on TimeoutException {
    return {
      'success': false,
      'error': 'Sandbox execution time limit exceeded',
      'terminated': true,
    };
  } finally {
    worker?.kill(priority: Isolate.immediate);
    port.close();
  }
}

void _sandboxWorker(List<dynamic> arguments) async {
  final port = arguments[0] as SendPort;
  final input = arguments[1] as Map<String, dynamic>;
  await HttpOverrides.runZoned(
    () async {
      try {
        port.send(await _run(input));
      } catch (error) {
        port.send({'success': false, 'error': error.toString()});
      }
    },
    createHttpClient: (_) => throw StateError('Sandbox network access denied'),
  );
}

Snowflake? _snowflake(String? value) {
  final number = int.tryParse(value ?? '');
  return number == null ? null : Snowflake(number);
}

class _NoDiscord implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Sandbox Discord access denied: ${invocation.memberName}',
  );
}

Future<Map<String, dynamic>> _run(Map<String, dynamic> input) async {
  if ((input['script'] == null) == (input['actions'] == null)) {
    throw ArgumentError('Provide exactly one of script or actions');
  }
  final script = (input['script'] ?? '').toString();
  if (script.length > 100000) throw StateError('Script size limit exceeded');
  final backend = BdfdBackend.parse(input['bdfdBackend']);
  final nativeScript = input['script'] != null;
  final diagnostics = <Map<String, dynamic>>[];
  final semantics = input['bdfdUserVariableSemantics'] ?? 2;
  if (semantics != 1 && semantics != 2) {
    throw ArgumentError('Unsupported BDFD user variable semantics');
  }
  final List<Action> actions;
  if (nativeScript) {
    actions = const [];
  } else {
    actions = (input['actions'] as List)
        .map((a) => Action.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();
  }
  final scopedDefinitions = <Map<String, dynamic>>[];
  final rawDefinitions = input['definitions'];
  if (rawDefinitions is List) {
    for (final d in rawDefinitions.whereType<Map>()) {
      scopedDefinitions.add({
        'key': (d['key'] ?? d['name'] ?? '').toString(),
        'scope': (d['scope'] ?? 'guildMember').toString(),
        'defaultValue': d['defaultValue'] ?? d['default'] ?? d['value'] ?? '',
        if (d['value_type'] != null) 'value_type': d['value_type'],
      });
    }
  } else if (rawDefinitions is Map) {
    for (final entry in rawDefinitions.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val is Map) {
        scopedDefinitions.add({
          'key': (val['key'] ?? val['name'] ?? key).toString(),
          'scope': (val['scope'] ?? 'guildMember').toString(),
          'defaultValue':
              val['defaultValue'] ?? val['default'] ?? val['value'] ?? '',
          if (val['value_type'] != null) 'value_type': val['value_type'],
        });
      } else {
        scopedDefinitions.add({
          'key': key,
          'scope': 'guildMember',
          'defaultValue': val?.toString() ?? '',
        });
      }
    }
  }

  final scopedVariables = <String, Map<String, Map<String, dynamic>>>{};
  final rawScoped = input['scoped'];
  if (rawScoped is Map) {
    for (final scopeEntry in rawScoped.entries) {
      final scope = scopeEntry.key.toString();
      final scopeMap = scopedVariables.putIfAbsent(scope, () => {});
      if (scopeEntry.value is Map) {
        for (final contextEntry in (scopeEntry.value as Map).entries) {
          final ctxId = contextEntry.key.toString();
          if (contextEntry.value is Map) {
            scopeMap[ctxId] = Map<String, dynamic>.from(
              contextEntry.value as Map,
            );
          } else {
            scopeMap.putIfAbsent('10:20', () => {})[ctxId] = contextEntry.value;
          }
        }
      }
    }
  } else if (rawScoped is List) {
    for (final item in rawScoped.whereType<Map>()) {
      final scope = (item['scope'] ?? 'guildMember').toString();
      final context =
          (item['context'] ?? item['id'] ?? item['contextId'] ?? '10:20')
              .toString();
      final key = (item['key'] ?? item['name'] ?? '').toString();
      final value = item['value'] ?? item['defaultValue'] ?? '';
      if (key.isNotEmpty) {
        scopedVariables
                .putIfAbsent(scope, () => {})
                .putIfAbsent(context, () => {})[key] =
            value;
      }
    }
  }

  final store = SandboxStore(
    bdfdUserVariableSemantics: semantics as int,
    globalVariables: Map<String, dynamic>.from(input['global'] as Map? ?? {}),
    scopedDefinitions: scopedDefinitions,
    scopedVariables: scopedVariables,
    workflows: (input['workflows'] as List? ?? [])
        .map((workflow) => Map<String, dynamic>.from(workflow as Map))
        .toList(),
  );
  final variables = <String, String>{
    'bot.id': 'sandbox',
    'guild.id': '10',
    'channel.id': '30',
    'author.id': '20',
    'user.id': '20',
    'author.username': 'Test user',
    'user.username': 'Test user',
    'author.tag': '0',
    'user.tag': '0',
    'member.id': '20',
    'author.isBot': 'false',
    'user.isBot': 'false',
    'member.isAdmin': 'false',
    'interaction.isSlash': 'false',
    'guild.ownerId': '99',
    'member.permissions': '',
    ...buildCommandArgumentRuntimeVariables(
      ((input['variables'] as Map? ?? {})['message.content'] ?? '')
          .toString()
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList(),
    ),
  };

  void applyContext(Map ctx) {
    for (final entry in ctx.entries) {
      final k = entry.key.toString();
      final v = entry.value;
      if (v is Map) {
        for (final sub in v.entries) {
          variables['$k.${sub.key}'] = sub.value?.toString() ?? '';
        }
        if (v['id'] != null) {
          variables['$k.id'] = v['id'].toString();
        }
        // `context.author` must mean the same as `context.userId`: the invoking user, whatever
        // the script reads ($authorID, $userID or the member).
        if (k == 'author') {
          if (v['id'] != null) {
            variables['user.id'] = v['id'].toString();
            variables['member.id'] = v['id'].toString();
          }
          if (v['username'] != null) {
            variables['user.username'] = v['username'].toString();
          }
        }
      } else if (v is List) {
        if (k == 'permissions' || k == 'member.permissions') {
          variables['member.permissions'] = v
              .map((p) => p.toString().toLowerCase())
              .join(',');
        } else {
          variables[k] = jsonEncode(v);
        }
      } else {
        variables[k] = v?.toString() ?? '';
        if (k == 'guild_id' || k == 'guildId') {
          variables['guild.id'] = v.toString();
        }
        if (k == 'channel_id' || k == 'channelId') {
          variables['channel.id'] = v.toString();
        }
        if (k == 'user_id' ||
            k == 'userId' ||
            k == 'author_id' ||
            k == 'authorId') {
          final idStr = v.toString();
          variables['author.id'] = idStr;
          variables['user.id'] = idStr;
          variables['member.id'] = idStr;
        }
        if (k == 'username' || k == 'author_username') {
          variables['author.username'] = v.toString();
          variables['user.username'] = v.toString();
        }
        if (k == 'permissions' || k == 'permission') {
          variables['member.permissions'] = v.toString().toLowerCase();
        }
        if (k == 'isAdmin' || k == 'admin') {
          variables['member.isAdmin'] = (v == true || v == 'true').toString();
        }
        if (k == 'isSlash' || k == 'slash') {
          variables['interaction.isSlash'] = (v == true || v == 'true')
              .toString();
        }
      }
    }
  }

  if (input['context'] is Map) {
    applyContext(input['context'] as Map);
  }
  if (input['permissions'] != null) {
    final p = input['permissions'];
    variables['member.permissions'] = p is List
        ? p.map((e) => e.toString().toLowerCase()).join(',')
        : p.toString().toLowerCase();
  }
  if (variables['member.isAdmin'] == 'true') {
    final cur = variables['member.permissions'] ?? '';
    if (!cur.contains('administrator')) {
      variables['member.permissions'] = cur.isEmpty
          ? 'administrator'
          : '$cur,administrator';
    }
    variables['isAdmin.byId.${variables['author.id']}'] = 'true';
  }
  if ((variables['member.permissions'] ?? '').isNotEmpty) {
    variables['permissions.byId.${variables['author.id']}'] =
        variables['member.permissions']!;
  }

  if (input['temp'] is Map) {
    for (final entry in (input['temp'] as Map).entries) {
      variables['temp.${entry.key}'] = entry.value?.toString() ?? '';
    }
  }

  for (final entry in (input['variables'] as Map? ?? {}).entries) {
    final k = entry.key.toString();
    final v = entry.value?.toString() ?? '';
    variables[k] = v;
    if (!k.contains('.')) {
      variables['temp.$k'] = v;
    }
  }

  // Options use the same flattened namespace as production interaction events.
  void option(String key, dynamic value) {
    variables[key] = value is Map || value is List
        ? jsonEncode(value)
        : '$value';
    if (value is Map) {
      for (final entry in value.entries) {
        option('$key.${entry.key}', entry.value);
      }
      if (value['id'] != null) {
        variables[key] = value['id'].toString();
      }
    } else if (value is String || value is num) {
      final valStr = value.toString();
      final optName = key.startsWith('opts.') ? key.substring(5) : key;
      if ([
        'user',
        'membre',
        'member',
        'target',
        'channel',
        'role',
      ].contains(optName)) {
        variables.putIfAbsent('$key.id', () => valStr);
      }
    }
  }

  for (final entry in (input['options'] as Map? ?? {}).entries) {
    option('opts.${entry.key}', entry.value);
  }
  final musicFixture = input['music'] is Map
      ? MusicFixture(Map<String, dynamic>.from(input['music'] as Map))
      : null;
  musicFixture?.populate(variables);
  await hydrateRuntimeVariables(
    store: store,
    botId: 'sandbox',
    runtimeVariables: variables,
    guildContextId: variables['guild.id'],
    userContextId: variables['author.id'],
    channelContextId: variables['channel.id'],
    messageContextId: variables['message.id'],
  );
  final before = jsonDecode(jsonEncode(store.snapshot()));
  final entityGateway = input['entities'] is Map
      ? EntityFixtureGateway(
          Map<String, dynamic>.from(input['entities'] as Map),
        )
      : null;
  final policy = _SandboxPolicy(
    store,
    (input['http'] as List? ?? [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList(),
    imageSources: Map<String, dynamic>.from(
      input['imageSources'] as Map? ?? {},
    ),
    allowEntityFixtures: entityGateway != null,
    entityGateway: entityGateway,
    musicFixture: musicFixture,
  );
  variables['bdfd.userVariableSemantics'] = semantics.toString();
  String? error;
  Map<String, String> results = {};
  final logs = <String>[];
  try {
    final budget = CommandExecutionBudget(limit: const Duration(seconds: 2));
    final context = BdfdContext(
      variables: variables,
      temporaryVariables: RuntimeTemporaryVariables(variables),
      budget: budget,
      maxSteps: 10000,
      onTrace: policy.recordNative,
    );
    context.onLog = logs.add;
    context.imageSourceResolver = (source) async {
      final uri = Uri.tryParse(source);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final fixture = policy.imageSources[source]?.toString();
        if (fixture == null || fixture.length > 128000) {
          throw StateError(
            'Sandbox image source must have an explicit local fixture',
          );
        }
        final fixtureUri = Uri.tryParse(fixture);
        if (fixtureUri != null &&
            fixtureUri.hasScheme &&
            fixtureUri.scheme != 'data') {
          throw StateError(
            'Sandbox image fixture must be a data URL or base64',
          );
        }
        return fixture;
      }
      if (uri != null && uri.hasScheme && uri.scheme != 'data') {
        throw StateError('Sandbox image source must be a data URL or base64');
      }
      return source;
    };
    final messages = _SandboxMessages(policy);
    final moderation = _SandboxModeration(policy, variables);
    final commandQueries = _SandboxCommandQueries(policy, variables);
    final components = _SandboxComponents(policy, variables);
    final timing = SandboxBotTimingService(moderation);
    final delays = _SandboxDelays(policy);
    final httpService = HttpService(clientFactory: policy.httpClient);
    Future<Map<String, String>> runActions(List<Action> nested) =>
        handleActions(
          entityGateway ?? _NoDiscord(),
          null,
          actions: nested,
          store: store,
          botId: 'sandbox',
          variables: variables,
          fallbackGuildId: _snowflake(variables['guild.id']),
          fallbackChannelId: _snowflake(variables['channel.id']),
          resolveTemplate: (text) =>
              resolveTemplatePlaceholders(text, variables),
          executionPolicy: policy,
          bdfdContext: context,
          bdfdMessages: messages,
          bdfdModeration: moderation,
          bdfdCommandQueries: commandQueries,
          bdfdComponents: components,
          bdfdTiming: timing,
          bdfdDelays: delays,
          bdfdHttp: httpService,
          executionBudget: budget,
          workflowStack: context.activeWorkflows,
          throwOnError: nativeScript,
          onLog: logs.add,
        );
    if (nativeScript) {
      final execution = BdfdScriptExecution(
        store: store,
        botId: 'sandbox',
        variables: variables,
        context: context,
        messages: messages,
        moderation: moderation,
        commandQueries: commandQueries,
        components: components,
        timing: timing,
        delays: delays,
        http: httpService,
        music: _SandboxMusic(policy, variables),
        runVisualWorkflow: (workflow, _) => runActions(
          ((workflow['actions'] as List?) ?? [])
              .whereType<Map>()
              .map((json) => Action.fromJson(Map<String, dynamic>.from(json)))
              .toList(),
        ),
      );
      final started = Stopwatch()..start();
      final variablesBefore = Map<String, String>.from(variables);
      try {
        final output = await execution.execute(script, backend: backend.id);
        results = {
          ...context.results,
          'output': output ?? '',
          if (context.stopped) '__stopped__': 'true',
        };
      } finally {
        // This frame covers the native program; visual workflow frames remain
        // separate. It is not a simulated list of compiled block actions.
        policy.record({
          'type': 'bdfdProgram',
          'backend': backend.id,
          'durationMs': started.elapsedMilliseconds,
          'variablesBefore': variablesBefore,
          'variablesAfter': Map<String, String>.from(variables),
        });
      }
    } else {
      results = await runActions(actions);
    }
    await timing.drain();
    if (context.response.deferred) {
      policy.effects.add({
        'type': 'deferInteraction',
        'ephemeral': context.response.ephemeral,
        'simulated': true,
      });
    }
    error = variables['error.message'];
    if (error == null &&
        entityGateway != null &&
        entityGateway.errors.isNotEmpty) {
      error = entityGateway.errors.join('; ');
    }
  } catch (e) {
    error = e.toString();
    if (e is BdfdNativeError) {
      diagnostics.add({
        'message': e.message,
        'severity': 'error',
        'line': e.location.line,
        'column': e.location.column,
        'function': e.location.functionName,
      });
    }
  }
  final images = <String, dynamic>{};
  final probes = (input['pixelProbes'] as List? ?? const [])
      .whereType<List>()
      .where((point) => point.length == 2)
      .take(64)
      .toList();
  for (final entry in variables.entries) {
    if (!entry.key.startsWith('temp._canvasAttachment_')) continue;
    try {
      final canvas = img.decodePng(base64Decode(entry.value));
      if (canvas == null) continue;
      final selected = probes.isNotEmpty
          ? probes
          : <List<int>>[
              [0, 0],
              [canvas.width ~/ 2, canvas.height ~/ 2],
              [canvas.width - 1, canvas.height - 1],
            ];
      final pixels = <String, String>{};
      var nonUniform = false;
      if (canvas.width * canvas.height <= 65536) {
        final first = canvas.getPixel(0, 0);
        for (final pixel in canvas) {
          if (pixel.r != first.r ||
              pixel.g != first.g ||
              pixel.b != first.b ||
              pixel.a != first.a) {
            nonUniform = true;
            break;
          }
        }
      }
      for (final point in selected) {
        final x = int.tryParse(point[0].toString());
        final y = int.tryParse(point[1].toString());
        if (x == null ||
            y == null ||
            x < 0 ||
            y < 0 ||
            x >= canvas.width ||
            y >= canvas.height) {
          continue;
        }
        final pixel = canvas.getPixel(x, y);
        final rgba = [pixel.r, pixel.g, pixel.b, pixel.a]
            .map((channel) => channel.toInt().toRadixString(16).padLeft(2, '0'))
            .join();
        pixels['$x,$y'] = '#$rgba';
      }
      images[entry.key.substring('temp._canvasAttachment_'.length)] = {
        'width': canvas.width,
        'height': canvas.height,
        'pixels': pixels,
        'nonUniform': nonUniform,
      };
    } catch (_) {
      // A malformed attachment is reported by the executor, not the preview.
    }
  }
  return {
    'success': error == null,
    'bdfdUserVariableSemantics': semantics,
    'bdfdBackend': backend.id,
    'error': error,
    'diagnostics': diagnostics,
    'responses': policy.responses,
    'trace': policy.frames,
    'native_trace_dropped': policy.nativeTraceDropped,
    'effects': policy.effects,
    'unused_http_fixtures': policy.httpFixtures.length,
    'entity_requests': entityGateway?.requests ?? [],
    'variables': variables,
    'storage_before': before,
    'storage_after': store.snapshot(),
    'results': results,
    'logs': logs,
    'images': images,
    'stopped': results.containsKey('__stopped__'),
    'execution': 'sandbox',
    'discord_verified': false,
  };
}

Map? _sandboxMessageChannelRow(EntityFixtureGateway gateway, String id) {
  final guilds = gateway.fixtures['guilds'];
  if (guilds is! Map) return null;
  for (final guild in guilds.values.whereType<Map>()) {
    final channels = guild['channels'];
    final threads = guild['threads'];
    final rows = [
      if (channels is List) ...channels,
      if (threads is List) ...threads,
    ];
    for (final row in rows.whereType<Map>()) {
      if (row['id'].toString() == id) return row;
    }
  }
  return null;
}

/// Serialises staged components exactly as the production send path does.
List<Map<String, Object?>> _apiComponents(Object? json) {
  if (json is! Map) return const [];
  final definition = ComponentV2Definition.fromJson(
    Map<String, dynamic>.from(json),
  );
  if (definition.components.isEmpty) return const [];
  return buildComponentNodes(
    definition: definition,
    resolve: (value) => value,
  ).map((builder) => builder.build()).toList();
}

class _SandboxMessages implements BotMessageService {
  _SandboxMessages(this.policy);
  final _SandboxPolicy policy;

  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    budget.check();
    policy.actions++;
    policy.checkBudget();
    if (request.payload['targetType'] == 'typing') {
      policy.effects.add({
        'type': 'typing',
        'backend': 'native-v1',
        'channel_id':
            request.payload['channelId']?.toString() ?? variables['channel.id'],
        'simulated': true,
      });
      return const BotMessageResult();
    }
    final id = '${100000 + policy.responses.length}';
    final channelId =
        request.payload['channelId']?.toString() ??
        (request.destination == BotMessageDestination.user
            ? null
            : variables['channel.id']);
    final gateway = policy.entityGateway;
    if (gateway != null && channelId != null) {
      final messages =
          gateway.fixtures.putIfAbsent('messages', () => <String, dynamic>{})
              as Map;
      final channelMessages =
          messages.putIfAbsent(channelId, () => <String, dynamic>{}) as Map;
      if (channelMessages.containsKey(id)) {
        throw StateError('Sandbox response ID already exists.');
      }
      channelMessages[id] = {
        'author_id': variables['bot.id'] ?? '0',
        'author_name': 'Sandbox bot',
        'channel_id': channelId,
        'content': request.payload['content'] ?? '',
        'embeds': request.payload['embeds'] ?? [],
        'components': _apiComponents(request.payload['components']),
        'reactions': <dynamic>[],
      };
      _sandboxMessageChannelRow(gateway, channelId)?['last_message_id'] = id;
    }
    final componentJson = request.payload['components'];
    final componentDefinition = componentJson is Map
        ? ComponentV2Definition.fromJson(
            Map<String, dynamic>.from(componentJson),
          )
        : null;
    final richComponents = componentDefinition?.isRichV2 ?? false;
    policy.responses.add({
      'type': richComponents
          ? (request.destination == BotMessageDestination.response
                ? 'respondWithComponentV2'
                : 'sendComponentV2')
          : request.destination == BotMessageDestination.response
          ? 'respondWithMessage'
          : 'sendMessage',
      'destination': request.destination.name,
      'backend': 'native-v1',
      'payload': request.payload,
      if (componentDefinition != null &&
          componentDefinition.components.isNotEmpty)
        'api_components': _apiComponents(componentJson),
      'simulated': true,
      'id': id,
    });
    return BotMessageResult(
      messageId: id,
      channelId: channelId,
      acknowledged: request.destination == BotMessageDestination.response,
      originalResponseCompleted:
          request.destination == BotMessageDestination.response,
    );
  }
}

/// Uses the production permission checks with a read-only fixture gateway.
/// Mutation is simulated explicitly after authorization, never through Actions.
class _SandboxModeration
    implements
        BotModerationService,
        BotRoleQueryService,
        BotChannelQueryService,
        BotChannelMutationService,
        BotChannelPermissionService,
        BotPermissionQueryService,
        BotUserQueryService,
        BotMemberQueryService,
        BotGuildQueryService,
        BotMessageQueryService,
        BotReactionService,
        BotEmojiService,
        BotWebhookService,
        BotThreadService {
  _SandboxModeration(this.policy, this.variables);
  final _SandboxPolicy policy;
  final Map<String, String> variables;

  Map get _webhookFixtures {
    final fixtures = policy.entityGateway?.fixtures;
    if (fixtures == null) {
      throw StateError('Native webhooks require entity fixtures.');
    }
    return fixtures.putIfAbsent('webhooks', () => <String, dynamic>{}) as Map;
  }

  Map _webhook(BotWebhookReference ref) {
    final row = _webhookFixtures[ref.id];
    if (row is! Map || row['token'] != ref.token) {
      throw StateError('Webhook fixture is absent or token does not match.');
    }
    return row;
  }

  Future<void> _avatar(String url, CommandExecutionBudget budget) async {
    if (url.isNotEmpty) {
      await DiscordBotWebhookService(
        client: _queries.client,
        httpClientFactory: policy.httpClient,
      ).loadAvatar(url, budget);
    }
  }

  @override
  Future<String> create(
    String channelId,
    String name,
    String avatarUrl, {
    required CommandExecutionBudget budget,
  }) async {
    final gateway = policy.entityGateway;
    final bot = _snowflake(variables['bot.id']);
    if (gateway == null || bot == null) {
      throw StateError('Webhook creation requires entity fixtures and bot ID.');
    }
    await prepareBotWebhookCreate(
      _SandboxPermissionGateway(gateway, bot),
      channelId,
      name,
      budget: budget,
    );
    final webhooks = _webhookFixtures;
    if (webhooks.values
            .whereType<Map>()
            .where((row) => row['channel_id'] == channelId)
            .length >=
        10) {
      throw StateError('Channel webhook fixture limit reached.');
    }
    await _avatar(avatarUrl, budget);
    budget.check();
    var counter = 9000 + policy.effects.length + 1;
    while (webhooks.containsKey('$counter')) {
      counter++;
    }
    final id = '$counter';
    final ref = BotWebhookReference(id, 'sandbox-token-$id');
    webhooks[id] = {
      'channel_id': channelId,
      'name': name,
      'avatar_url': avatarUrl,
      'token': ref.token,
    };
    policy.effects.add({
      'type': 'createWebhook',
      'webhook_id': id,
      'channel_id': channelId,
      'name': name,
      'simulated': true,
    });
    return ref.url;
  }

  @override
  Future<void> update(
    BotWebhookReference webhook, {
    String? name,
    String? avatarUrl,
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    final row = _webhook(webhook);
    if (name != null) validateWebhookName(name);
    if (avatarUrl != null) await _avatar(avatarUrl, budget);
    budget.check();
    if (name != null) row['name'] = name;
    if (avatarUrl != null) row['avatar_url'] = avatarUrl;
    policy.effects.add({
      'type': 'editWebhook',
      'webhook_id': webhook.id,
      'name': ?name,
      'avatar_url': ?avatarUrl,
      'simulated': true,
    });
  }

  @override
  Future<void> delete(
    BotWebhookReference webhook, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    _webhook(webhook);
    _webhookFixtures.remove(webhook.id);
    policy.effects.add({
      'type': 'deleteWebhook',
      'webhook_id': webhook.id,
      'simulated': true,
    });
  }

  @override
  Future<void> send(
    BotWebhookReference webhook,
    Map<String, dynamic> payload, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    _webhook(webhook);
    final built = buildBotWebhookMessage(payload).build();
    policy.effects.add({
      'type': 'sendWebhook',
      'webhook_id': webhook.id,
      'payload': built,
      'simulated': true,
    });
  }

  DiscordBotEmojiService get _emojiQueries => DiscordBotEmojiService(
    client: _queries.client,
    guildId: _queries.guildId,
  );
  @override
  Future<BotEmoji?> emoji(
    String id, {
    required CommandExecutionBudget budget,
  }) => _emojiQueries.emoji(id, budget: budget);
  @override
  Future<BotEmoji?> emojiByName(
    String name, {
    required CommandExecutionBudget budget,
  }) => _emojiQueries.emojiByName(name, budget: budget);
  @override
  Future<List<BotEmoji>> emojis({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => _emojiQueries.emojis(guildId: guildId, budget: budget);
  @override
  Future<BotEmoji> createEmoji(
    BotEmojiCreateRequest request, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final guildId = _queries.guildId;
    final prepared = await prepareBotEmojiCreate(
      _messageGateway,
      guildId,
      request,
      budget: budget,
    );
    final image = await HttpBotEmojiImageLoader(
      clientFactory: policy.httpClient,
    ).load(request.imageUrl, budget: budget);
    final guilds = policy.entityGateway!.fixtures['guilds'] as Map;
    final guild = guilds['$guildId'] as Map;
    final rows = guild['emojis'];
    if (rows is! List) throw StateError('Emoji list fixture is required.');
    var nextId = BigInt.from(300000);
    for (final guild in guilds.values.whereType<Map>()) {
      for (final row in (guild['emojis'] as List? ?? []).whereType<Map>()) {
        budget.check();
        final id = BigInt.parse(row['id'].toString());
        if (id >= nextId) nextId = id + BigInt.one;
      }
    }
    if (nextId > BigInt.from(9223372036854775807)) {
      throw StateError('No available fixture emoji ID.');
    }
    final row = <String, dynamic>{
      'id': '$nextId',
      'name': prepared.name,
      'animated': image.format == 'gif',
      'creator_id': variables['bot.id'],
    };
    budget.check();
    policy.checkBudget();
    rows.add(row);
    policy.effects.add({
      'type': 'createEmoji',
      'guild_id': '$guildId',
      'emoji_id': '$nextId',
      'image_url': request.imageUrl,
      'image_bytes': image.bytes.length,
      'after': Map<String, dynamic>.from(row),
      'simulated': true,
    });
    return BotEmoji(
      id: '$nextId',
      name: prepared.name,
      guildId: '$guildId',
      animated: row['animated'] == true,
      creatorId: variables['bot.id'],
    );
  });
  @override
  Future<void> deleteEmoji(
    String id, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final guildId = _queries.guildId;
    final prepared = await prepareBotEmojiDelete(
      _messageGateway,
      guildId,
      id,
      budget: budget,
    );
    final guild =
        (policy.entityGateway!.fixtures['guilds'] as Map)['$guildId'] as Map;
    final rows = guild['emojis'] as List;
    final index = rows.indexWhere(
      (row) => row is Map && row['id'].toString() == '${prepared.emojiId}',
    );
    if (index < 0) throw StateError('Emoji fixture is required.');
    final before = Map<String, dynamic>.from(rows[index] as Map);
    budget.check();
    policy.checkBudget();
    rows.removeAt(index);
    policy.effects.add({
      'type': 'deleteEmoji',
      'guild_id': '$guildId',
      'emoji_id': '${prepared.emojiId}',
      'before': before,
      'simulated': true,
    });
  });

  Map _reactionMessageRow(BotReactionTarget target) {
    final messages = policy.entityGateway?.fixtures['messages'];
    final channel = messages is Map
        ? messages['${int.parse(target.channelId.trim())}']
        : null;
    final row = channel is Map
        ? channel['${int.parse(target.messageId.trim())}']
        : null;
    if (row is! Map) throw StateError('Reaction message fixture is required.');
    return row;
  }

  List<Map> _reactionRows(Map message) {
    final rows = message['reactions'];
    if (rows == null) return <Map>[];
    if (rows is! List || rows.any((row) => row is! Map)) {
      throw StateError('Reaction list fixture is required.');
    }
    return rows.cast<Map>();
  }

  bool _reactionMatches(Map row, ReactionBuilder emoji) => emoji.id != null
      ? row['id']?.toString() == '${emoji.id}'
      : (row['id'] == null || row['id'].toString() == '0') &&
            row['emoji']?.toString() == emoji.name;

  @override
  Future<void> addReactions(
    BotReactionAddRequest request, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    policy.checkBudget();
    final prepared = await prepareBotReactionAdd(
      _messageGateway,
      request,
      budget: budget,
    );
    final message = _reactionMessageRow(request.target);
    final rows = _reactionRows(message);
    final botId = variables['bot.id'];
    if (botId == null || botId.isEmpty) {
      throw StateError('Reaction mutation requires a bot ID.');
    }
    for (final emoji in prepared.emojis) {
      budget.check();
      final existing = rows
          .where((row) => _reactionMatches(row, emoji))
          .firstOrNull;
      if (existing != null && existing['users'] is! List) {
        throw StateError('Reaction users fixture is required.');
      }
    }
    final mutableRows = [...rows];
    message['reactions'] = mutableRows;
    for (final emoji in prepared.emojis) {
      policy.checkBudget();
      budget.check();
      final before = jsonDecode(jsonEncode(mutableRows));
      var row = mutableRows
          .where((item) => _reactionMatches(item, emoji))
          .firstOrNull;
      if (row == null) {
        row = <String, dynamic>{
          'emoji': emoji.name,
          if (emoji.id != null) 'id': '${emoji.id}',
          'users': <String>[],
          'count': 0,
        };
        mutableRows.add(row);
      }
      final users = List<dynamic>.from(row['users'] as List);
      if (!users.any((value) => value.toString() == botId)) users.add(botId);
      row['users'] = users;
      row['count'] = users.length;
      policy.effects.add({
        'type': 'addReaction',
        'backend': 'native-v1',
        'channel_id': '${prepared.manager.channelId}',
        'message_id': '${prepared.messageId}',
        'emoji': emoji.build(),
        'before': before,
        'after': jsonDecode(jsonEncode(mutableRows)),
        'simulated': true,
      });
    }
  });

  @override
  Future<void> clearReactions(
    BotReactionClearRequest request, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    policy.checkBudget();
    final prepared = await prepareBotReactionClear(
      _messageGateway,
      request,
      budget: budget,
    );
    final message = _reactionMessageRow(request.target);
    final rows = _reactionRows(message);
    final before = jsonDecode(jsonEncode(rows));
    final after = <Map>[];
    for (final row in rows) {
      budget.check();
      if (prepared.emoji != null && !_reactionMatches(row, prepared.emoji!)) {
        after.add(row);
      }
    }
    policy.checkBudget();
    budget.check();
    message['reactions'] = after;
    policy.effects.add({
      'type': 'clearReactions',
      'backend': 'native-v1',
      'channel_id': '${prepared.manager.channelId}',
      'message_id': '${prepared.messageId}',
      'emoji': prepared.emoji?.build() ?? '!all',
      'before': before,
      'after': jsonDecode(jsonEncode(after)),
      'simulated': true,
    });
  });

  @override
  Future<List<BotReactionUser>> reactionUsers(
    BotReactionQuery query, {
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return DiscordBotReactionService(
      client: _queries.client,
    ).reactionUsers(query, budget: budget);
  }

  NyxxGateway get _messageGateway {
    final gateway = policy.entityGateway;
    final bot = _snowflake(variables['bot.id']);
    if (gateway == null || bot == null) {
      throw StateError('Message mutations require fixtures and a bot ID.');
    }
    return _SandboxPermissionGateway(gateway, bot);
  }

  @override
  Future<BotMessageChannelSnapshot> messageChannel(
    String channelId, {
    required CommandExecutionBudget budget,
  }) => DiscordBotMessageQueryService(
    client: _queries.client,
  ).messageChannel(channelId, budget: budget);
  @override
  Future<BotMessageSnapshot> message({
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  }) => DiscordBotMessageQueryService(
    client: _queries.client,
  ).message(channelId: channelId, messageId: messageId, budget: budget);

  @override
  Future<void> mutateMessage(
    MessageMutation change, {
    required CommandExecutionBudget budget,
  }) async {
    final prepared = await DiscordBotMessageQueryService(
      client: _messageGateway,
    ).prepareMessageMutation(change, budget: budget);
    budget.check();
    policy.checkBudget();
    final messages = policy.entityGateway!.fixtures['messages'] as Map;
    final channelId = prepared.channel.id.toString();
    final messageId = prepared.message.id.toString();
    final rows = messages[channelId] as Map;
    final row = rows[messageId] as Map;
    switch (change.kind) {
      case MessageMutationKind.delete:
        rows.remove(messageId);
      case MessageMutationKind.pin:
        row['pinned'] = true;
        _sandboxMessageChannelRow(
          policy.entityGateway!,
          channelId,
        )?['last_pin_timestamp'] = DateTime.now()
            .toUtc()
            .millisecondsSinceEpoch;
      case MessageMutationKind.unpin:
        row['pinned'] = false;
        _sandboxMessageChannelRow(
          policy.entityGateway!,
          channelId,
        )?['last_pin_timestamp'] = DateTime.now()
            .toUtc()
            .millisecondsSinceEpoch;
      case MessageMutationKind.publish:
        row['published'] = true;
      case MessageMutationKind.edit:
        final edit = change.edit!;
        row['content'] = edit.content;
        row['edited_timestamp'] = DateTime.now().toUtc().toIso8601String();
        if (edit.replaceEmbed) {
          row['embeds'] =
              edit.toBuilder().embeds?.map((e) => e.build()).toList() ?? [];
        }
    }
    policy.effects.add({
      'type': '${change.kind.name}Message',
      'channel_id': channelId,
      'message_id': messageId,
      'simulated': true,
    });
  }

  DiscordBotThreadService get _threadQueries => DiscordBotThreadService(
    client: _queries.client,
    guildId: _queries.guildId,
    channelId: _snowflake(variables['channel.id']),
  );
  DiscordBotThreadService get _threadMutations {
    final gateway = policy.entityGateway;
    final bot = _snowflake(variables['bot.id']);
    if (gateway == null || bot == null) {
      throw StateError(
        'Thread mutations require entity fixtures and a bot ID.',
      );
    }
    return DiscordBotThreadService(
      client: _SandboxPermissionGateway(gateway, bot),
      guildId: _snowflake(variables['guild.id']),
      channelId: _snowflake(variables['channel.id']),
    );
  }

  Map _threadRow(Thread thread) {
    final guild =
        (policy.entityGateway!.fixtures['guilds'] as Map)['${thread.guildId}']
            as Map;
    return (guild['threads'] as List).whereType<Map>().firstWhere(
      (row) => row['id'].toString() == '${thread.id}',
    );
  }

  @override
  Future<BotThreadInfo> threadInfo({
    String? threadId,
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return _threadQueries.threadInfo(threadId: threadId, budget: budget);
  }

  @override
  Future<String> startThread(
    ThreadCreation change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    policy.checkBudget();
    final parent = await _threadMutations.prepareThreadCreation(
      change,
      budget: budget,
    );
    final gateway = policy.entityGateway!;
    final guilds = gateway.fixtures['guilds'] as Map;
    final guild = guilds['${parent.guildId}'] as Map;
    final rows = guild['threads'] == null
        ? <dynamic>[]
        : guild['threads'] as List;
    final existing = <String>{};
    var nextId = BigInt.from(200000);
    for (final guild in guilds.values.whereType<Map>()) {
      for (final row in [
        ...(guild['channels'] as List? ?? []),
        ...(guild['threads'] as List? ?? []),
      ].whereType<Map>()) {
        budget.check();
        final id = row['id'].toString();
        existing.add(id);
        final parsed = BigInt.parse(id);
        if (parsed >= nextId) nextId = parsed + BigInt.one;
      }
    }
    final String id;
    if (change.messageId != null) {
      final messageId = threadSnowflake(change.messageId!);
      await (gateway.channels[parent.id] as PartialTextChannel).messages.fetch(
        messageId,
      );
      budget.check();
      final source =
          ((gateway.fixtures['messages'] as Map)['${parent.id}']
                  as Map)['$messageId']
              as Map;
      if (source['channel_id'] != null &&
          source['channel_id'].toString() != '${parent.id}') {
        throw StateError('Source message belongs to another channel.');
      }
      id = '$messageId';
    } else {
      if (nextId > (BigInt.one << 64) - BigInt.one) {
        throw StateError('No available fixture thread ID.');
      }
      id = '$nextId';
    }
    if (existing.contains(id)) {
      throw StateError('A thread with this ID already exists.');
    }
    final bot = variables['bot.id']!;
    final row = <String, dynamic>{
      'id': id,
      'name': change.name,
      'parent_id': '${parent.id}',
      'owner_id': bot,
      'type': parent is GuildAnnouncementChannel
          ? 'announcement_thread'
          : 'public_thread',
      'archived': false,
      'locked': false,
      'auto_archive_duration': change.archiveMinutes,
      'slowmode': 0,
      'message_count': 0,
      'member_count': 1,
      'members': <String>[bot],
    };
    budget.check();
    policy.checkBudget();
    guild['threads'] = rows;
    rows.add(row);
    policy.effects.add({
      'type': 'startThread',
      'guild_id': '${parent.guildId}',
      'channel_id': '${parent.id}',
      'thread_id': id,
      'after': jsonDecode(jsonEncode(row)),
      'simulated': true,
    });
    return id;
  });
  @override
  Future<void> editThread(
    ThreadModification change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    policy.checkBudget();
    final thread = await _threadMutations.prepareThreadModification(
      change,
      budget: budget,
    );
    final payload = change.toBuilder().build();
    if (payload.isEmpty) return;
    final row = _threadRow(thread);
    final before = jsonDecode(jsonEncode(row));
    budget.check();
    policy.checkBudget();
    for (final entry in payload.entries) {
      row[entry.key == 'rate_limit_per_user' ? 'slowmode' : entry.key] =
          entry.value;
    }
    policy.effects.add({
      'type': 'editThread',
      'guild_id': '${thread.guildId}',
      'thread_id': '${thread.id}',
      'before': before,
      'after': jsonDecode(jsonEncode(row)),
      'simulated': true,
    });
  });
  Future<void> _changeThreadMember(
    ThreadMemberChange change,
    bool remove,
    CommandExecutionBudget budget,
  ) => budget.run(() async {
    policy.checkBudget();
    final thread = await _threadMutations.prepareThreadMemberChange(
      change,
      remove: remove,
      budget: budget,
    );
    final row = _threadRow(thread);
    final rawMembers = row['members'];
    if (rawMembers is! List) {
      throw StateError(
        'Thread member simulation requires a members list fixture.',
      );
    }
    if (!remove) {
      await policy.entityGateway!.guilds[thread.guildId].members.fetch(
        threadSnowflake(change.userId),
      );
      budget.check();
    }
    final members = rawMembers.map((value) => value.toString()).toSet();
    final before = jsonDecode(jsonEncode(row));
    final target = '${threadSnowflake(change.userId)}';
    if (remove) {
      members.remove(target);
    } else {
      members.add(target);
    }
    budget.check();
    policy.checkBudget();
    row['members'] = members.toList();
    row['member_count'] = members.length > 50 ? 50 : members.length;
    policy.effects.add({
      'type': remove ? 'threadRemoveMember' : 'threadAddMember',
      'guild_id': '${thread.guildId}',
      'thread_id': '${thread.id}',
      'user_id': target,
      'before': before,
      'after': jsonDecode(jsonEncode(row)),
      'simulated': true,
    });
  });
  @override
  Future<void> addThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) => _changeThreadMember(change, false, budget);
  @override
  Future<void> removeThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) => _changeThreadMember(change, true, budget);
  DiscordBotUserQueryService get _userQueries => DiscordBotUserQueryService(
    client: _queries.client,
    guildId: _queries.guildId,
  );
  DiscordBotMemberQueryService get _memberQueries =>
      DiscordBotMemberQueryService(
        client: _queries.client,
        guildId: _queries.guildId,
      );
  @override
  Future<List<BotGuildMember>> guildMembers({
    String? guildId,
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return _memberQueries.guildMembers(guildId: guildId, budget: budget);
  }

  @override
  Future<BotGuildMember?> guildMember(
    String userId, {
    String? guildId,
    required CommandExecutionBudget budget,
  }) async {
    policy.checkBudget();
    try {
      return await _memberQueries.guildMember(
        userId,
        guildId: guildId,
        budget: budget,
      );
    } on DiscordEntityNotFound {
      budget.check();
      // An absent member is a normal lookup miss; a present member with missing
      // user data is an incomplete fixture and must not become false absence.
      final selectedGuild = guildId ?? '${_queries.guildId}';
      final guild =
          (policy.entityGateway!.fixtures['guilds'] as Map?)?[selectedGuild];
      final members = guild is Map ? guild['members'] : null;
      if (members is Map && members.containsKey(userId)) rethrow;
      return null;
    }
  }

  @override
  Future<int> allGuildMembersCount({required CommandExecutionBudget budget}) {
    policy.checkBudget();
    return _memberQueries.allGuildMembersCount(budget: budget);
  }

  @override
  Future<BotUser?> user(
    String userId, {
    required CommandExecutionBudget budget,
  }) async {
    policy.checkBudget();
    try {
      return await _userQueries.user(userId, budget: budget);
    } on DiscordEntityNotFound {
      budget.check();
      return null;
    }
  }

  @override
  Future<BotUserMember?> member(
    String userId, {
    required CommandExecutionBudget budget,
  }) async {
    policy.checkBudget();
    try {
      return await _userQueries.member(userId, budget: budget);
    } on DiscordEntityNotFound {
      budget.check();
      return null;
    }
  }

  @override
  Future<BotGuild?> guild({
    String? guildId,
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return DiscordBotGuildQueryService(
      client: _queries.client,
      guildId: _queries.guildId,
    ).guild(guildId: guildId, budget: budget);
  }

  @override
  Future<List<BotGuild>> guilds({required CommandExecutionBudget budget}) {
    policy.checkBudget();
    return DiscordBotGuildQueryService(
      client: _queries.client,
      guildId: _queries.guildId,
    ).guilds(budget: budget);
  }

  @override
  Future<BotGuildChannelSettings> guildChannelSettings({
    String? guildId,
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return _channelQueries.guildChannelSettings(
      guildId: guildId,
      budget: budget,
    );
  }

  @override
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return DiscordBotPermissionQueryService(
      client: _queries.client,
      guildId: _queries.guildId,
    ).storedMemberPermissions(userId, budget: budget);
  }

  @override
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    final gateway = policy.entityGateway;
    final bot = _snowflake(variables['bot.id']);
    if (gateway == null || bot == null) {
      throw StateError(
        'Permission queries require entity fixtures and a bot ID.',
      );
    }
    return DiscordBotPermissionQueryService(
      client: _SandboxPermissionGateway(gateway, bot),
      guildId: _snowflake(variables['guild.id']),
    ).memberPermissions(userId: userId, channelId: channelId, budget: budget);
  }

  DiscordBotRoleQueryService get _queries {
    final gateway = policy.entityGateway;
    if (gateway == null) {
      throw StateError('Role queries require entity fixtures');
    }
    return DiscordBotRoleQueryService(
      client: gateway,
      guildId: _snowflake(variables['guild.id']),
    );
  }

  DiscordBotChannelQueryService get _channelQueries =>
      DiscordBotChannelQueryService(
        client: _queries.client,
        guildId: _queries.guildId,
      );
  @override
  Future<ChannelPermissionResult> editPermissions(
    ChannelPermissionChange change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    policy.checkBudget();
    change.validate();
    final gateway = policy.entityGateway;
    final bot = _snowflake(variables['bot.id']);
    if (gateway == null || bot == null) {
      throw StateError(
        'Permission edits require entity fixtures and a bot ID.',
      );
    }
    final prepared = await prepareChannelPermissions(
      _SandboxPermissionGateway(gateway, bot),
      change,
      budget: budget,
    );
    final guild =
        (gateway.fixtures['guilds'] as Map)[prepared.channel.guildId.toString()]
            as Map;
    final rows = guild['channels'] as List;
    final row = rows.whereType<Map>().firstWhere(
      (r) => r['id'].toString() == '${prepared.channel.id}',
    );
    final existing = row['permission_overwrites'];
    final overwrites = existing == null
        ? <Map<String, dynamic>>[]
        : [
            for (final value in existing as List)
              Map<String, dynamic>.from(value as Map),
          ];
    final overwrite = prepared.builder.build();
    overwrites.removeWhere(
      (o) =>
          o['id'].toString() == '${prepared.builder.id}' &&
          (o['type'].toString() == prepared.builder.type.value.toString() ||
              o['type'].toString() ==
                  (prepared.builder.type == PermissionOverwriteType.role
                      ? 'role'
                      : 'member')),
    );
    overwrites.add(Map<String, dynamic>.from(overwrite));
    budget.check();
    policy.checkBudget();
    row['permission_overwrites'] = overwrites;
    policy.effects.add({
      'type': 'editChannelPermissions',
      'guild_id': '${prepared.channel.guildId}',
      'channel_id': '${prepared.channel.id}',
      'target_id': '${prepared.builder.id}',
      'overwrite': overwrite,
      'simulated': true,
    });
    return ChannelPermissionResult(
      '${prepared.channel.id}',
      '${prepared.builder.id}',
    );
  });
  @override
  Future<String> createChannel(
    ChannelCreation change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    policy.checkBudget();
    change.validate();
    final gateway = policy.entityGateway;
    final bot = _snowflake(variables['bot.id']);
    if (gateway == null || bot == null) {
      throw StateError('Creation requires entity fixtures and a bot ID.');
    }
    final builder = await prepareChannelCreation(
      _SandboxPermissionGateway(gateway, bot),
      change,
      budget: budget,
    );
    final guilds = gateway.fixtures['guilds'] as Map;
    final guildId = '${Snowflake.parse(change.guildId.trim())}';
    final guild = guilds[guildId] as Map;
    final channels = guild['channels'];
    if (channels is! List) {
      throw StateError('Channel creation requires guild channel fixtures.');
    }
    if (channels
            .whereType<Map>()
            .where((row) => row['type'] != 'thread')
            .length >=
        500) {
      throw StateError('Guild channel limit reached.');
    }
    final used = <String>{
      for (final value in guilds.values.whereType<Map>())
        for (final row in [
          ...(value['channels'] as List? ?? []),
          ...(value['threads'] as List? ?? []),
        ].whereType<Map>())
          row['id'].toString(),
    };
    var next = 60;
    while (used.contains('$next')) {
      next++;
    }
    final id = '$next';
    final payload = builder.build();
    final row = <String, dynamic>{
      'id': id,
      'name': payload['name'],
      'type': change.type,
      if (payload.containsKey('parent_id')) 'parent_id': payload['parent_id'],
      if (payload.containsKey('topic')) 'topic': payload['topic'],
      if (payload.containsKey('nsfw')) 'nsfw': payload['nsfw'],
      if (payload.containsKey('rate_limit_per_user'))
        'slowmode': payload['rate_limit_per_user'],
      if (payload.containsKey('permission_overwrites'))
        'permission_overwrites': payload['permission_overwrites'],
    };
    if (change.categoryId != null && row['permission_overwrites'] == null) {
      final category = channels.whereType<Map>().firstWhere(
        (r) =>
            r['id'].toString() ==
            '${Snowflake.parse(change.categoryId!.trim())}',
      );
      if (category['permission_overwrites'] != null) {
        row['permission_overwrites'] = [
          for (final value in category['permission_overwrites'] as List)
            Map<String, dynamic>.from(value as Map),
        ];
      }
    }
    budget.check();
    policy.checkBudget();
    channels.add(row);
    policy.effects.add({
      'type': 'createChannel',
      'guild_id': guildId,
      'channel_id': id,
      'after': Map<String, dynamic>.from(row),
      'simulated': true,
      if (change.reason != null) 'reason': change.reason,
    });
    return id;
  });
  @override
  Future<void> modifyChannel(
    ChannelModification change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    policy.checkBudget();
    change.validate();
    final gateway = policy.entityGateway;
    final bot = _snowflake(variables['bot.id']);
    if (gateway == null || bot == null) {
      throw StateError('Modification requires entity fixtures and a bot ID.');
    }
    final prepared = await prepareChannelUpdate(
      _SandboxPermissionGateway(gateway, bot),
      change,
      budget: budget,
    );
    final payload = prepared.builder.build();
    if (payload.isEmpty) return;
    final guild =
        (gateway.fixtures['guilds'] as Map)[prepared.channel.guildId.toString()]
            as Map;
    final rows = [
      ...(guild['channels'] as List? ?? []),
      ...(guild['threads'] as List? ?? []),
    ];
    final row = rows.whereType<Map>().firstWhere(
      (r) => r['id'].toString() == '${prepared.channel.id}',
    );
    final before = Map<String, dynamic>.from(row);
    budget.check();
    policy.checkBudget();
    const mapping = {
      'name': 'name',
      'topic': 'topic',
      'nsfw': 'nsfw',
      'position': 'position',
      'parent_id': 'parent_id',
      'rate_limit_per_user': 'slowmode',
      'archived': 'archived',
      'locked': 'locked',
      'auto_archive_duration': 'auto_archive_duration',
    };
    for (final entry in payload.entries) {
      final key = mapping[entry.key];
      if (key == null) {
        throw StateError('Unsupported simulated channel field: ${entry.key}');
      }
      row[key] = entry.value;
    }
    policy.effects.add({
      'type': 'updateChannel',
      'guild_id': '${prepared.channel.guildId}',
      'channel_id': '${prepared.channel.id}',
      'before': before,
      'after': Map<String, dynamic>.from(row),
      'simulated': true,
      if (change.reason != null) 'reason': change.reason,
    });
  });
  @override
  Future<void> deleteChannel(
    ChannelDeletion change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    policy.checkBudget();
    change.validate();
    final gateway = policy.entityGateway;
    final bot = _snowflake(variables['bot.id']);
    if (gateway == null || bot == null) {
      throw StateError(
        'Channel deletion requires entity fixtures and a bot ID.',
      );
    }
    final id = Snowflake.parse(change.channelId.trim());
    final target = await gateway.channels.fetch(id);
    budget.check();
    if (target is! GuildChannel) {
      throw StateError('Channel deletion requires a guild channel.');
    }
    final error = await checkBotChannelPermission(
      _SandboxPermissionGateway(gateway, bot),
      channel: target,
      requiredPermissions: [
        Permissions.manageChannels,
        if (target is Thread) Permissions.manageThreads,
      ],
      actionLabel: 'delete channels',
      budget: budget,
    );
    if (error != null) throw StateError(error);
    final guild =
        (gateway.fixtures['guilds'] as Map)[target.guildId.toString()] as Map;
    final channels = guild['channels'] as List? ?? [];
    final threads = guild['threads'] as List? ?? [];
    budget.check();
    policy.checkBudget();
    channels.removeWhere((row) => row is Map && row['id'].toString() == '$id');
    threads.removeWhere((row) => row is Map && row['id'].toString() == '$id');
    if (target is GuildCategory) {
      for (final row in channels.whereType<Map>()) {
        if (row['parent_id']?.toString() == '$id') row.remove('parent_id');
      }
    } else if (target is! Thread) {
      threads.removeWhere(
        (row) => row is Map && row['parent_id']?.toString() == '$id',
      );
    }
    policy.effects.add({
      'type': 'removeChannel',
      'guild_id': '${target.guildId}',
      'channel_id': '$id',
      'simulated': true,
      if (change.reason != null) 'reason': change.reason,
    });
  });
  @override
  Future<void> setSlowmode(
    SlowmodeChange change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    policy.checkBudget();
    change.validate();
    final gateway = policy.entityGateway;
    final bot = _snowflake(variables['bot.id']);
    if (gateway == null || bot == null) {
      throw StateError('Slowmode requires entity fixtures and a bot ID.');
    }
    final target = await _channelQueries.channel(
      change.channelId,
      budget: budget,
    );
    if (target == null ||
        target.guildId == null ||
        !const [
          'text',
          'announcement',
          'forum',
          'thread',
        ].contains(target.type)) {
      throw StateError('Slowmode requires a supported guild channel.');
    }
    final permissionChannel = await gateway.channels.fetch(
      Snowflake.parse(target.id),
    );
    budget.check();
    if (permissionChannel is! GuildChannel) {
      throw StateError('Slowmode requires a guild channel.');
    }
    if (permissionChannel is Thread && permissionChannel.isArchived) {
      throw StateError('Cannot change slowmode on an archived thread.');
    }
    final error = await checkBotChannelPermission(
      _SandboxPermissionGateway(gateway, bot),
      channel: permissionChannel,
      requiredPermissions: [
        Permissions.manageChannels,
        if (permissionChannel is Thread) Permissions.manageThreads,
      ],
      actionLabel: 'set slowmode',
      budget: budget,
    );
    if (error != null) throw StateError(error);
    final guild = (gateway.fixtures['guilds'] as Map)[target.guildId] as Map;
    final rows = [
      ...(guild['channels'] as List? ?? []),
      ...(guild['threads'] as List? ?? []),
    ];
    final row = rows
        .whereType<Map>()
        .where((r) => r['id'].toString() == target.id)
        .firstOrNull;
    if (row == null) throw StateError('Missing slowmode channel fixture.');
    budget.check();
    policy.checkBudget();
    final before = row['slowmode'] ?? 0;
    row['slowmode'] = change.seconds;
    variables['channel[${target.id}].rateLimitPerUser'] = '${change.seconds}';
    if (variables['channel.id'] == target.id) {
      variables['channel.rateLimitPerUser'] = '${change.seconds}';
    }
    policy.effects.add({
      'type': 'slowmode',
      'guild_id': target.guildId,
      'channel_id': target.id,
      'before': before,
      'after': change.seconds,
      'simulated': true,
    });
  });
  @override
  Future<int> countChannels({required CommandExecutionBudget budget}) {
    policy.checkBudget();
    return _channelQueries.countChannels(budget: budget);
  }

  @override
  Future<BotChannel?> channel(
    String id, {
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return _channelQueries.channel(id, budget: budget);
  }

  @override
  Future<List<BotChannel>> channels({
    String? guildId,
    bool includeActiveThreads = false,
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return _channelQueries.channels(
      guildId: guildId,
      includeActiveThreads: includeActiveThreads,
      budget: budget,
    );
  }

  @override
  Future<List<BotRole>> roles({
    String? guildId,
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return _queries.roles(guildId: guildId, budget: budget);
  }

  @override
  Future<List<String>> memberRoleIds(
    String userId, {
    required CommandExecutionBudget budget,
  }) {
    policy.checkBudget();
    return _queries.memberRoleIds(userId, budget: budget);
  }

  @override
  Future<String> moderate(
    BotModerationRequest request, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    budget.check();
    policy.actions++;
    policy.checkBudget();
    final gateway = policy.entityGateway;
    final guildId = _snowflake(variables['guild.id']);
    final botId = _snowflake(variables['bot.id']);
    final userId = _snowflake(request.userId);
    final guild = (gateway?.fixtures['guilds'] as Map?)?[guildId?.toString()];
    switch (request.operation) {
      case BotModerationOperation.clearMessages:
        return _simulateClear(request, guildId, guild);
      case BotModerationOperation.setNickname:
        return _simulateNickname(request, guildId, guild);
      case BotModerationOperation.registerGuildCommands:
      case BotModerationOperation.unregisterGuildCommands:
        final raw = request.targetGuildId.trim().isEmpty
            ? guildId?.toString() ?? ''
            : request.targetGuildId.trim();
        if (int.tryParse(raw) == null) {
          throw StateError('Guild command simulation requires a guild ID');
        }
        policy.effects.add({
          'type': request.operation.name,
          'backend': 'native-v1',
          'guild_id': raw,
          'simulated': true,
        });
        return '';
      case BotModerationOperation.isBanned:
      case BotModerationOperation.banReason:
        if (gateway == null) {
          throw StateError('Ban lookups require entity fixtures');
        }
        final scope =
            _snowflake(
              request.targetGuildId.trim().isEmpty
                  ? null
                  : request.targetGuildId,
            ) ??
            guildId;
        if (scope == null || userId == null) {
          throw StateError('Ban lookups require guild and user IDs');
        }
        String? reason;
        var banned = true;
        try {
          reason = (await gateway.guilds.fetchBan(scope, userId)).reason;
        } on DiscordEntityNotFound {
          banned = false;
        }
        budget.check();
        variables['member[$userId].isBanned'] = '$banned';
        final value = banned ? reason ?? '' : '';
        variables['ban.reason[$userId]'] = value;
        if (request.targetGuildId.trim().isNotEmpty) {
          variables['ban.reason[$userId;${request.targetGuildId.trim()}]'] =
              value;
        }
        return request.operation == BotModerationOperation.isBanned
            ? '$banned'
            : value;
      default:
        break;
    }
    if (request.operation == BotModerationOperation.setUserRoles) {
      return _simulateRoleReplacement(
        request,
        budget,
        gateway,
        guildId,
        botId,
        guild,
      );
    }
    if (request.operation == BotModerationOperation.createRole ||
        request.operation == BotModerationOperation.updateRole ||
        request.operation == BotModerationOperation.deleteRole) {
      return _simulateRoleDefinition(
        request,
        budget,
        gateway,
        guildId,
        botId,
        guild,
      );
    }
    if (request.operation == BotModerationOperation.addRole ||
        request.operation == BotModerationOperation.removeRole) {
      return _simulateRole(request, budget, gateway, guildId, botId, guild);
    }
    if (request.operation == BotModerationOperation.timeout ||
        request.operation == BotModerationOperation.untimeout) {
      return _simulateTimeout(request, budget, gateway, guildId, botId, guild);
    }
    if (request.operation == BotModerationOperation.unban) {
      return _simulateUnban(request, budget, gateway, guildId, botId, guild);
    }
    if (gateway == null ||
        guildId == null ||
        botId == null ||
        userId == null ||
        guild is! Map ||
        guild['members'] is! Map ||
        guild['bans'] is! Map ||
        guild['owner_id'] == null ||
        guild['roles'] is! List) {
      throw StateError(
        'Native moderation requires bot ID, guild owner, roles, members and bans fixtures',
      );
    }
    await checkModerationActorPermission(
      _SandboxPermissionGateway(gateway, botId),
      guildId,
      request,
      budget,
    );
    final error = await checkBotCanModerate(
      _SandboxPermissionGateway(gateway, botId),
      guildId: guildId,
      targetUserId: userId,
      requiredPermission: request.operation == BotModerationOperation.kick
          ? Permissions.kickMembers
          : Permissions.banMembers,
      actionLabel: request.operation.name,
      allowNonMember: request.operation == BotModerationOperation.ban,
    );
    budget.check();
    if (error != null) throw StateError(error);
    final members = guild['members'] as Map;
    final bans = guild['bans'] as Map;
    final target = userId.toString();
    final member = members[target];
    final before = {
      'member': member is Map ? Map<String, dynamic>.from(member) : null,
      'ban_reason': bans[target],
    };
    final auditReason = request.auditLogReason ?? '';
    if (request.operation == BotModerationOperation.ban) {
      bans[target] = auditReason;
      variables['member[$target].isBanned'] = 'true';
      variables['ban.reason[$target]'] = bans[target].toString();
      variables['ban.reason[$target;$guildId]'] = bans[target].toString();
    }
    members.remove(target);
    policy.effects.add({
      'type': request.operation == BotModerationOperation.kick
          ? 'kickUser'
          : 'banUser',
      'backend': 'native-v1',
      'guild_id': guildId.toString(),
      'user_id': target,
      'reason': auditReason,
      'before': before,
      'after': {'member': null, 'ban_reason': bans[target]},
      'simulated': true,
    });
    return target;
  });
  Future<String> _simulateRoleReplacement(
    BotModerationRequest request,
    CommandExecutionBudget budget,
    EntityFixtureGateway? gateway,
    Snowflake? guildId,
    Snowflake? botId,
    dynamic guild,
  ) async {
    if (gateway == null ||
        guildId == null ||
        botId == null ||
        guild is! Map ||
        guild['roles'] is! List ||
        guild['members'] is! Map) {
      throw StateError(
        'Native role replacements require bot ID, roles and members fixtures',
      );
    }
    final userId = _snowflake(request.userId);
    if (userId == null || userId.value <= 0) {
      throw StateError('Invalid user ID');
    }
    final rawRoles = request.roleReplacement?.roleIds;
    if (rawRoles == null) throw StateError('Missing role replacement');
    final ids = <Snowflake>{};
    for (final raw in rawRoles) {
      final id = _snowflake(raw);
      if (id == null || id.value <= 0) throw StateError('Invalid role ID');
      ids.add(id);
    }
    final error = await checkBotCanReplaceRoles(
      _SandboxPermissionGateway(gateway, botId),
      guildId: guildId,
      userId: userId,
      roleIds: ids.toList(),
      budget: budget,
    );
    budget.check();
    if (error != null) throw StateError(error);
    final member = guild['members'][userId.toString()] as Map;
    final before = Map<String, dynamic>.from(member);
    member['roles'] = ids.map((id) => id.toString()).toList();
    variables['member[$userId].roles'] = ids.join(',');
    policy.effects.add({
      'type': 'setUserRoles',
      'backend': 'native-v1',
      'guild_id': '$guildId',
      'user_id': '$userId',
      'role_ids': ids.map((id) => id.toString()).toList(),
      'reason': request.auditLogReason ?? '',
      'before': {'member': before},
      'after': {'member': Map<String, dynamic>.from(member)},
      'simulated': true,
    });
    return userId.toString();
  }

  Future<String> _simulateRoleDefinition(
    BotModerationRequest request,
    CommandExecutionBudget budget,
    EntityFixtureGateway? gateway,
    Snowflake? guildId,
    Snowflake? botId,
    dynamic guild,
  ) async {
    if (gateway == null ||
        guildId == null ||
        botId == null ||
        guild is! Map ||
        guild['roles'] is! List ||
        guild['members'] is! Map) {
      throw StateError(
        'Native role definitions require bot ID, roles and members fixtures',
      );
    }
    final create = request.operation == BotModerationOperation.createRole;
    final delete = request.operation == BotModerationOperation.deleteRole;
    final fields = request.roleDefinition;
    if (!delete) {
      if (fields == null) throw StateError('Missing role definition');
      final invalid = fields.validate(create: create);
      if (invalid != null) throw StateError(invalid);
    }
    final permissions = _SandboxPermissionGateway(gateway, botId);
    final roleId = _snowflake(request.roleId);
    if (!create && (roleId == null || roleId.value <= 0)) {
      throw StateError('Invalid role ID');
    }
    final error = create
        ? await checkBotGuildPermission(
            permissions,
            guildId: guildId,
            requiredPermissions: [Permissions.manageRoles],
            actionLabel: 'create roles',
          )
        : await checkBotCanManageRole(
            permissions,
            guildId: guildId,
            roleId: roleId!,
            allowEveryone: !delete,
          );
    budget.check();
    if (error != null) throw StateError(error);
    final roles = guild['roles'] as List;
    final Map role;
    final String target;
    if (create) {
      // Fixture-only IDs; never claim these synthetic IDs exist on Discord.
      var next =
          roles
              .map((r) => int.tryParse(r['id'].toString()) ?? 0)
              .fold<int>(0, (a, b) => a > b ? a : b) +
          1;
      while (roles.any((r) => r['id'].toString() == next.toString())) {
        next++;
      }
      target = next.toString();
      role = {
        'id': target,
        'name': fields!.name,
        'color': fields.color,
        'hoist': fields.hoist ?? false,
        'mentionable': fields.mentionable ?? false,
        'position': 1,
        'permissions': '0',
      };
    } else {
      target = roleId.toString();
      role = roles.firstWhere((r) => r['id'].toString() == target) as Map;
    }
    final before = create ? null : Map<String, dynamic>.from(role);
    if (!create && !delete && fields!.position != null) {
      final bot = guild['members'][botId.toString()];
      final botRoles = (bot['roles'] as List)
          .map((id) => id.toString())
          .toSet();
      final highest = roles
          .where((r) => botRoles.contains(r['id'].toString()))
          .map((r) => (r['position'] as num? ?? 0).toInt())
          .fold<int>(0, (a, b) => a > b ? a : b);
      if (roleId == guildId || fields.position! >= highest) {
        throw StateError('Invalid role position: must be below the bot');
      }
    }
    budget.check();
    if (delete) {
      roles.remove(role);
      for (final member in (guild['members'] as Map).values) {
        if (member is Map && member['roles'] is List) {
          member['roles'] = (member['roles'] as List)
              .where((id) => id.toString() != target)
              .toList();
        }
      }
    } else {
      if (fields!.name != null) role['name'] = fields.name;
      if (fields.color != null) role['color'] = fields.color;
      if (fields.hoist != null) role['hoist'] = fields.hoist;
      if (fields.mentionable != null) role['mentionable'] = fields.mentionable;
      if (fields.position != null) role['position'] = fields.position;
      if (fields.togglePermissions != null) {
        var mask = int.parse((role['permissions'] ?? '0').toString());
        for (final flag in fields.togglePermissions!) {
          mask ^= flag;
        }
        role['permissions'] = mask.toString();
      }
      if (create) roles.add(role);
    }
    policy.effects.add({
      'type': request.operation.name,
      'backend': 'native-v1',
      'guild_id': guildId.toString(),
      'role_id': target,
      'reason': request.auditLogReason ?? '',
      'before': before,
      'after': delete ? null : Map<String, dynamic>.from(role),
      'simulated': true,
    });
    return target;
  }

  Future<String> _simulateRole(
    BotModerationRequest request,
    CommandExecutionBudget budget,
    EntityFixtureGateway? gateway,
    Snowflake? guildId,
    Snowflake? botId,
    dynamic guild,
  ) async {
    if (gateway == null ||
        guildId == null ||
        botId == null ||
        guild is! Map ||
        guild['roles'] is! List ||
        guild['members'] is! Map) {
      throw StateError(
        'Native role grants require bot ID, roles and members fixtures',
      );
    }
    final userId = _snowflake(request.userId);
    final roleId = _snowflake(request.roleId);
    if (userId == null ||
        userId.value <= 0 ||
        roleId == null ||
        roleId.value <= 0) {
      throw StateError('Missing or invalid user ID/role ID');
    }
    final error = await checkBotCanManageRole(
      _SandboxPermissionGateway(gateway, botId),
      guildId: guildId,
      roleId: roleId,
    );
    budget.check();
    if (error != null) throw StateError(error);
    // Require a real fixture member, just as Discord requires guild membership.
    await gateway.guilds.get(guildId).then((g) => g.members.get(userId));
    budget.check();
    final member = guild['members'][userId.toString()] as Map;
    final before = Map<String, dynamic>.from(member);
    final roles = (member['roles'] as List? ?? [])
        .map((id) => id.toString())
        .toSet();
    if (request.operation == BotModerationOperation.addRole) {
      roles.add(roleId.toString());
    } else {
      roles.remove(roleId.toString());
    }
    member['roles'] = roles.toList();
    variables['member[$userId].roles'] = roles.join(',');
    policy.effects.add({
      'type': request.operation.name,
      'backend': 'native-v1',
      'guild_id': guildId.toString(),
      'user_id': userId.toString(),
      'role_id': roleId.toString(),
      'reason': request.auditLogReason ?? '',
      'before': {'member': before},
      'after': {'member': Map<String, dynamic>.from(member)},
      'simulated': true,
    });
    return userId.toString();
  }

  Future<String> _simulateTimeout(
    BotModerationRequest request,
    CommandExecutionBudget budget,
    EntityFixtureGateway? gateway,
    Snowflake? guildId,
    Snowflake? botId,
    dynamic guild,
  ) async {
    if (gateway == null ||
        guildId == null ||
        botId == null ||
        guild is! Map ||
        guild['members'] is! Map ||
        guild['roles'] is! List ||
        guild['owner_id'] == null) {
      throw StateError(
        'Native timeout requires bot ID, owner, roles and members fixtures',
      );
    }
    final userId = _snowflake(request.userId);
    if (userId == null || userId.value <= 0) {
      throw StateError('Missing or invalid user ID');
    }
    final error = await checkBotCanModerate(
      _SandboxPermissionGateway(gateway, botId),
      guildId: guildId,
      targetUserId: userId,
      requiredPermission: Permissions.moderateMembers,
      actionLabel: request.operation.name,
      disallowAdministrator: true,
    );
    budget.check();
    if (error != null) throw StateError(error);
    final target = userId.toString();
    final member = guild['members'][target] as Map;
    final before = Map<String, dynamic>.from(member);
    if (request.operation == BotModerationOperation.timeout) {
      final now = DateTime.now().toUtc();
      final until = request.timeoutDeadline(now);
      member['timeout_until'] = until.toIso8601String();
      member['timeout_seconds'] = until.difference(now).inSeconds;
      variables['member[$target].isTimedOut'] = 'true';
    } else {
      member.remove('timeout_until');
      member.remove('timeout_seconds');
      variables['member[$target].isTimedOut'] = 'false';
    }
    policy.effects.add({
      'type': request.operation == BotModerationOperation.timeout
          ? 'muteUser'
          : 'unmuteUser',
      'backend': 'native-v1',
      'guild_id': guildId.toString(),
      'user_id': target,
      'reason': request.auditLogReason ?? '',
      'before': {'member': before},
      'after': {'member': Map<String, dynamic>.from(member)},
      'simulated': true,
    });
    return target;
  }

  String _simulateClear(
    BotModerationRequest request,
    Snowflake? guildId,
    dynamic guild,
  ) {
    final channelId = request.channelId;
    final channels = guild is Map ? guild['messages'] : null;
    final rows = channels is Map ? channels[channelId] : null;
    if (rows is! List) {
      throw StateError(
        'Message deletion simulation requires channel messages fixtures',
      );
    }
    if (request.count < 1 || request.count > 100) {
      throw StateError(r'$clear amount must be between 1 and 100');
    }
    final selected = rows
        .where((raw) {
          if (raw is! Map) return false;
          if (request.onlyUserId.isNotEmpty &&
              raw['author_id']?.toString() != request.onlyUserId) {
            return false;
          }
          return request.removePinned || raw['pinned'] != true;
        })
        .take(request.count)
        .map((raw) => (raw as Map)['id'].toString())
        .toList();
    final selectedIds = selected.toSet();
    rows.removeWhere(
      (raw) => raw is Map && selectedIds.contains(raw['id'].toString()),
    );
    policy.effects.add({
      'type': 'deleteMessages',
      'backend': 'native-v1',
      'guild_id': guildId?.toString() ?? '',
      'channel_id': channelId,
      'only_user_id': request.onlyUserId,
      'remove_pinned': request.removePinned,
      'deleted_ids': selected,
      'deleted_count': selected.length,
      'remaining_ids': [
        for (final raw in rows)
          if (raw is Map) raw['id'].toString(),
      ],
      'simulated': true,
    });
    return '';
  }

  String _simulateNickname(
    BotModerationRequest request,
    Snowflake? guildId,
    dynamic guild,
  ) {
    final members = guild is Map ? guild['members'] : null;
    if (members is! Map) {
      throw StateError('Nickname simulation requires guild members fixtures');
    }
    final userId = request.userId.trim();
    final member = members[userId];
    if (int.tryParse(userId) == null || member is! Map) {
      throw StateError('Nickname simulation requires an existing member ID');
    }
    if (request.nickname.length > 32) {
      throw StateError('Nickname exceeds Discord length limit');
    }
    final before = member['nick']?.toString();
    member['nick'] = request.nickname;
    variables['member[$userId].nick'] = request.nickname;
    variables['member[$userId].displayName'] = request.nickname;
    if (variables['author.id'] == userId) {
      variables['member.nick'] = request.nickname;
      variables['member.displayName'] = request.nickname;
    }
    policy.effects.add({
      'type': 'setNickname',
      'backend': 'native-v1',
      'guild_id': guildId?.toString() ?? '',
      'user_id': userId,
      'before': before,
      'after': request.nickname,
      'simulated': true,
    });
    return userId;
  }

  Future<String> _simulateUnban(
    BotModerationRequest request,
    CommandExecutionBudget budget,
    EntityFixtureGateway? gateway,
    Snowflake? guildId,
    Snowflake? botId,
    dynamic guild,
  ) async {
    if (gateway == null ||
        guildId == null ||
        botId == null ||
        guild is! Map ||
        guild['roles'] is! List ||
        guild['members'] is! Map ||
        guild['bans'] is! Map) {
      throw StateError(
        'Native unban requires bot ID, roles, members and bans fixtures',
      );
    }
    final error = await checkBotGuildPermission(
      _SandboxPermissionGateway(gateway, botId),
      guildId: guildId,
      requiredPermissions: [Permissions.banMembers],
      actionLabel: 'unban this user',
    );
    budget.check();
    if (error != null) throw StateError(error);
    final bans = guild['bans'] as Map;
    final members = guild['members'] as Map;
    var target = request.userId.trim();
    if (target.isEmpty) {
      final usernames = guild['ban_users'];
      if (usernames is! Map) {
        throw StateError('Username unban requires ban_users fixtures');
      }
      final username = request.username.trim().toLowerCase();
      for (final id in bans.keys) {
        if (usernames[id]?.toString().toLowerCase() == username) {
          target = id.toString();
          break;
        }
      }
    } else {
      target = _snowflake(target)?.toString() ?? '';
    }
    final targetNumber = int.tryParse(target);
    if (targetNumber == null || targetNumber <= 0) {
      throw StateError('Banned user not found');
    }
    target = Snowflake(targetNumber).toString();
    if (target.isEmpty || !bans.containsKey(target)) {
      throw StateError('Banned user not found');
    }
    final member = members[target];
    final before = {
      'member': member is Map ? Map<String, dynamic>.from(member) : null,
      'ban_reason': bans[target],
    };
    budget.check();
    bans.remove(target);
    variables['member[$target].isBanned'] = 'false';
    variables['ban.reason[$target]'] = '';
    variables['ban.reason[$target;$guildId]'] = '';
    policy.effects.add({
      'type': 'unbanUser',
      'backend': 'native-v1',
      'guild_id': guildId.toString(),
      'user_id': target,
      'reason': request.auditLogReason ?? '',
      'before': before,
      'after': {
        'member': member is Map ? Map<String, dynamic>.from(member) : null,
        'ban_reason': null,
      },
      'simulated': true,
    });
    return target;
  }
}

class _SandboxPermissionGateway implements NyxxGateway {
  _SandboxPermissionGateway(this.fixtureGateway, this.botId);
  final EntityFixtureGateway fixtureGateway;
  final Snowflake botId;
  @override
  UserManager get users => fixtureGateway.users;
  @override
  GuildManager get guilds => fixtureGateway.guilds;
  @override
  ChannelManager get channels => fixtureGateway.channels;
  @override
  PartialUser get user => _SandboxBotUser(botId);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox permission access denied');
}

class _SandboxBotUser implements PartialUser {
  _SandboxBotUser(this.id);
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox bot user access denied');
}

class _SandboxPolicy implements ActionExecutionPolicy {
  _SandboxPolicy(
    this.store,
    this.httpFixtures, {
    this.imageSources = const {},
    this.allowEntityFixtures = false,
    this.entityGateway,
    this.musicFixture,
  });
  final bool allowEntityFixtures;
  final EntityFixtureGateway? entityGateway;
  final MusicFixture? musicFixture;
  final SandboxStore store;
  final List<Map<String, dynamic>> httpFixtures;
  final Map<String, dynamic> imageSources;
  final effects = <Map<String, dynamic>>[];
  final responses = <Map<String, dynamic>>[];
  final frames = <Map<String, dynamic>>[];
  int actions = 0;
  final timer = Stopwatch()..start();
  http.Client httpClient() => MockClient((request) async {
    checkBudget();
    final index = httpFixtures.indexWhere(
      (fixture) =>
          (fixture['method'] ?? 'GET').toString().toUpperCase() ==
              request.method &&
          fixture['url'] == request.url.toString(),
    );
    if (index < 0) {
      throw StateError(
        'HTTP ${request.method} ${request.url} requires an explicit simulation fixture',
      );
    }
    final fixture = httpFixtures.removeAt(index);
    effects.add({
      'type': 'httpRequest',
      'method': request.method,
      'url': request.url.toString(),
      'headers': request.headers,
      'body': request.body,
      'simulated': true,
    });
    final expected = fixture['expectedRequest'] as Map?;
    if (expected != null) {
      if (expected.containsKey('body') && expected['body'] != request.body) {
        throw StateError(
          'Simulated HTTP request body did not match fixture expectation',
        );
      }
      for (final entry in (expected['headers'] as Map? ?? {}).entries) {
        if (request.headers[entry.key.toString()] != entry.value.toString()) {
          throw StateError(
            'Simulated HTTP request header ${entry.key} did not match fixture expectation',
          );
        }
      }
    }
    if (fixture['error'] != null) {
      throw StateError(fixture['error'].toString());
    }
    final status = fixture['status'] as int? ?? 200;
    if (status < 100 || status > 599) {
      throw ArgumentError('Invalid simulated HTTP status');
    }
    if (fixture['bodyBase64'] != null) {
      return http.Response.bytes(
        base64Decode(fixture['bodyBase64'].toString()),
        status,
        headers: (fixture['headers'] as Map? ?? {}).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      );
    }
    final body = fixture['body'] ?? '';
    return http.Response(
      body is String ? body : jsonEncode(body),
      status,
      headers: (fixture['headers'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  });

  int nativeTraceCount = 0;
  int nativeTraceDropped = 0;
  void recordNative(BdfdTraceEvent event) {
    if (++nativeTraceCount > 1000) {
      nativeTraceDropped++;
      return;
    }
    final value = event.value;
    frames.add({
      'type': 'bdfd${event.kind[0].toUpperCase()}${event.kind.substring(1)}',
      'backend': 'native-v1',
      'status': event.status,
      'line': event.location.line,
      'column': event.location.column,
      'function': event.location.functionName,
      'scriptDepth': event.scriptDepth,
      'functionDepth': event.functionDepth,
      if (event.branch != null) 'branch': event.branch,
      if (event.iteration != null) 'iteration': event.iteration,
      if (event.durationMicroseconds != null)
        'durationMicroseconds': event.durationMicroseconds,
      if (value != null)
        'value': value.length > 500 ? value.substring(0, 500) : value,
      if (value != null && value.length > 500) 'valueTruncated': true,
    });
  }

  @override
  bool get allowDiscordHydration => allowEntityFixtures;
  @override
  void checkBudget() {
    if (actions > 1000 || timer.elapsedMilliseconds > 2000) {
      throw StateError('Sandbox execution budget exceeded');
    }
  }

  @override
  void record(Map<String, dynamic> frame) {
    final before = Map<String, String>.from(
      frame['variablesBefore'] as Map? ?? {},
    );
    final after = Map<String, String>.from(
      frame['variablesAfter'] as Map? ?? {},
    );
    final changed = {
      ...before.keys,
      ...after.keys,
    }.where((k) => before[k] != after[k]);
    frames.add({
      ...frame,
      'variablesBefore': {for (final key in changed) key: before[key]},
      'variablesAfter': {for (final key in changed) key: after[key]},
    });
  }

  static const pure = {
    BotCreatorActionType.setGlobalVariable,
    BotCreatorActionType.getGlobalVariable,
    BotCreatorActionType.removeGlobalVariable,
    BotCreatorActionType.setScopedVariable,
    BotCreatorActionType.setTemporaryVariable,
    BotCreatorActionType.getScopedVariable,
    BotCreatorActionType.removeScopedVariable,
    BotCreatorActionType.renameScopedVariable,
    BotCreatorActionType.appendArrayElement,
    BotCreatorActionType.removeArrayElement,
    BotCreatorActionType.runBdfdScript,
    BotCreatorActionType.runWorkflow,
    BotCreatorActionType.stopUnless,
    BotCreatorActionType.ifBlock,
    BotCreatorActionType.forLoop,
    BotCreatorActionType.jsonForEachLoop,
    BotCreatorActionType.calculate,
    BotCreatorActionType.log,
    BotCreatorActionType.runtimeJsonBlock,
    BotCreatorActionType.cooldown,
    BotCreatorActionType.wait,
    BotCreatorActionType.stop,
    BotCreatorActionType.randomChoice,
    BotCreatorActionType.skipActions,
    BotCreatorActionType.jumpToAction,
    // Variable reads and in-memory listeners/images: no Discord access, run as in production.
    BotCreatorActionType.queryArray,
    BotCreatorActionType.listScopedVariableIndex,
    BotCreatorActionType.listenForButtonClick,
    BotCreatorActionType.listenForSelectMenu,
    BotCreatorActionType.listenForModalSubmit,
    BotCreatorActionType.listenAndExecute,
    BotCreatorActionType.attachImage,
  };
  static const messages = {
    BotCreatorActionType.respondWithMessage,
    BotCreatorActionType.sendMessage,
    BotCreatorActionType.respondWithComponentV2,
    BotCreatorActionType.sendComponentV2,
    BotCreatorActionType.respondWithModal,
    BotCreatorActionType.respondWithAutocomplete,
    BotCreatorActionType.deferInteraction,
  };
  @override
  Future<bool> intercept({
    required Action action,
    required String resultKey,
    required Map<String, String> results,
    required Map<String, String> variables,
    required String Function(String) resolveValue,
  }) async {
    actions++;
    checkBudget();
    if (variables.values.fold<int>(0, (size, value) => size + value.length) >
        128000) {
      throw StateError('Sandbox variable size limit exceeded');
    }
    dynamic resolve(dynamic data) {
      if (data is String) return resolveValue(data);
      if (data is Map) {
        final resolved = data.map((k, v) => MapEntry(k, resolve(v)));
        final fields = resolved['fields'];
        if (fields is List) {
          resolved['fields'] = fields
              .where(
                (field) =>
                    field is! Map ||
                    !field.containsKey('includeIf') ||
                    field['includeIf'].toString() == 'true',
              )
              .toList();
        }
        return resolved;
      }
      if (data is List) return data.map(resolve).toList();
      return data;
    }

    if (musicFixture != null) {
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final musicResult = musicFixture!.apply(
        action.type,
        payload,
        variables,
        effects,
      );
      if (musicResult != null) {
        results[resultKey] = musicResult;
        return true;
      }
    }

    if ({
      BotCreatorActionType.createEmoji,
      BotCreatorActionType.deleteEmoji,
    }.contains(action.type)) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      final emojis = guild is Map ? guild['emojis'] : null;
      if (emojis is! List) {
        throw StateError('Emoji simulation requires guild emojis fixtures');
      }
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      if (action.type == BotCreatorActionType.createEmoji) {
        final name = (payload['name'] ?? '').toString().trim();
        final source = (payload['imageUrl'] ?? '').toString().trim();
        final raw = (payload['imageBase64'] ?? imageSources[source] ?? '')
            .toString();
        final encoded = raw.startsWith('data:') ? raw.split(',').last : raw;
        img.Image? decoded;
        try {
          decoded = img.decodeImage(base64Decode(encoded));
        } catch (_) {}
        if (!RegExp(r'^[A-Za-z0-9_]{2,32}$').hasMatch(name) ||
            (source.isNotEmpty && !imageSources.containsKey(source)) ||
            decoded == null) {
          throw StateError(
            'Emoji creation requires a valid name and explicit image fixture',
          );
        }
        if (emojis.any((item) => item is Map && item['name'] == name)) {
          throw StateError('Emoji $name already exists');
        }
        final id = '${8000 + emojis.length}';
        final emoji = {'id': id, 'name': name, 'animated': false};
        emojis.add(emoji);
        final tag = '<:$name:$id>';
        results[resultKey] = jsonEncode({
          'emojiId': id,
          'name': name,
          'animated': 'false',
          'status': 'created',
          'tag': tag,
        });
        results['$resultKey.tag'] = tag;
        results['$resultKey.emojiId'] = id;
        effects.add({
          'type': 'createEmoji',
          'guild_id': guildId,
          'emoji': emoji,
          'image_width': decoded.width,
          'image_height': decoded.height,
          'simulated': true,
        });
        return true;
      }
      final identifier = (payload['emojiId'] ?? '').toString().trim();
      final index = emojis.indexWhere(
        (item) =>
            item is Map &&
            (item['id'].toString() == identifier || item['name'] == identifier),
      );
      if (index < 0) throw StateError('Emoji $identifier not found');
      final removed = Map<String, dynamic>.from(emojis.removeAt(index) as Map);
      results[resultKey] = jsonEncode({
        'emojiId': removed['id'].toString(),
        'status': 'deleted',
      });
      results['$resultKey.emojiId'] = removed['id'].toString();
      effects.add({
        'type': 'deleteEmoji',
        'guild_id': guildId,
        'emoji': removed,
        'simulated': true,
      });
      return true;
    }

    if (action.type == BotCreatorActionType.updateSelfUser) {
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final targetId = (payload['targetUserId'] ?? '').toString();
      final botId = variables['bot.id'] ?? '';
      if (targetId.isNotEmpty && targetId != botId) {
        throw StateError(
          'A bot token cannot change another user’s global username',
        );
      }
      final username = (payload['username'] ?? '').toString().trim();
      if (username.length < 2 || username.length > 32) {
        throw StateError('Bot username must contain 2–32 characters');
      }
      final before = variables['bot.username'] ?? '';
      variables['bot.username'] = username;
      variables['$resultKey.username'] = username;
      variables['$resultKey.userId'] = botId;
      results[resultKey] = 'updated';
      effects.add({
        'type': 'updateSelfUser',
        'user_id': botId,
        'before': before,
        'after': username,
        'simulated': true,
      });
      return true;
    }

    if (action.type == BotCreatorActionType.leaveGuild) {
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final guildId = (payload['guildId'] ?? variables['guild.id'] ?? '')
          .toString();
      final guilds = entityGateway?.fixtures['guilds'];
      if (guilds is! Map ||
          int.tryParse(guildId) == null ||
          !guilds.containsKey(guildId)) {
        throw StateError('Bot leave requires an existing guild fixture');
      }
      guilds.remove(guildId);
      results[resultKey] = guildId;
      effects.add({
        'type': 'leaveGuild',
        'guild_id': guildId,
        'simulated': true,
      });
      return true;
    }

    if (action.type == BotCreatorActionType.sendWebhook &&
        action.payload['createWebhook'] == true) {
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final channelId = (payload['channelId'] ?? '').toString();
      final name = (payload['name'] ?? '').toString().trim();
      final guild =
          (entityGateway?.fixtures['guilds'] as Map?)?[variables['guild.id']];
      final channels = guild is Map ? guild['channels'] : null;
      if (int.tryParse(channelId) == null ||
          name.length < 2 ||
          name.length > 80 ||
          channels is! List ||
          !channels.any(
            (channel) =>
                channel is Map && channel['id'].toString() == channelId,
          )) {
        throw StateError(
          'Sandbox webhook creation requires an existing channel fixture and valid name',
        );
      }
      final webhookId = (9000 + effects.length + 1).toString();
      final url =
          'https://discord.com/api/webhooks/'
          '$webhookId/sandbox-token-$webhookId';
      effects.add({
        'type': 'createWebhook',
        'channel_id': channelId,
        'name': name,
        'avatar_url': payload['avatarUrl'] ?? '',
        'webhook_id': webhookId,
        'simulated': true,
      });
      results[resultKey] = url;
      return true;
    }
    if (action.type == BotCreatorActionType.sendWebhook) {
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final url = (payload['webhookUrl'] ?? '').toString();
      final uri = Uri.tryParse(url);
      final parts = uri?.pathSegments ?? const <String>[];
      final index = parts.indexOf('webhooks');
      if (index < 0 ||
          index + 2 >= parts.length ||
          int.tryParse(parts[index + 1]) == null ||
          parts[index + 2].isEmpty) {
        throw StateError('Sandbox webhook send requires an ID and token URL');
      }
      final builder = buildWebhookMessage(payload, resolveValue);
      effects.add({
        'type': 'sendWebhook',
        'webhook_id': parts[index + 1],
        'payload': builder.build(),
        'username': payload['username'] ?? '',
        'avatar_url': payload['avatarUrl'] ?? '',
        'simulated': true,
      });
      results[resultKey] = parts[index + 1];
      return true;
    }
    if (action.type == BotCreatorActionType.deleteWebhook) {
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      var id = (payload['webhookId'] ?? '').toString();
      var token = (payload['token'] ?? '').toString();
      final uri = Uri.tryParse((payload['webhookUrl'] ?? '').toString());
      final parts = uri?.pathSegments ?? const <String>[];
      final index = parts.indexOf('webhooks');
      if (index >= 0 && index + 2 < parts.length) {
        id = parts[index + 1];
        token = parts[index + 2];
      }
      if (int.tryParse(id) == null || token.isEmpty) {
        throw StateError('Sandbox webhook deletion requires an ID and token');
      }
      effects.add({
        'type': 'deleteWebhook',
        'webhook_id': id,
        'simulated': true,
      });
      results[resultKey] = id;
      return true;
    }

    if (action.type == BotCreatorActionType.runtimeImageBlock) {
      for (final raw in action.payload['operations'] as List? ?? const []) {
        if (raw is! Map) continue;
        if (raw['op'] != 'loadImage' && raw['op'] != 'compositeImage') continue;
        final source = resolveValue(
          (raw['url'] ?? raw['dataUrl'] ?? '').toString(),
        );
        final uri = Uri.tryParse(source);
        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
          final fixture = imageSources[source]?.toString();
          if (fixture == null || fixture.length > 128000) {
            throw StateError(
              'Sandbox image source must have an explicit local fixture',
            );
          }
          final fixtureUri = Uri.tryParse(fixture);
          if (fixtureUri != null &&
              fixtureUri.hasScheme &&
              fixtureUri.scheme != 'data') {
            throw StateError(
              'Sandbox image fixture must be a data URL or base64',
            );
          }
          raw['url'] = fixture;
        } else if (uri != null && uri.hasScheme && uri.scheme != 'data') {
          throw StateError('Sandbox image source must be a data URL or base64');
        }
      }
      return false;
    }

    if (action.type == BotCreatorActionType.addRole ||
        action.type == BotCreatorActionType.removeRole) {
      final fixtures = entityGateway?.fixtures;
      final guildId = variables['guild.id'] ?? '';
      final guild = (fixtures?['guilds'] as Map?)?[guildId];
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      if (isRoleDefinitionPayload(payload)) {
        if (guild is! Map || guild['roles'] is! List) {
          throw StateError('Role simulation requires guild roles fixtures');
        }
        results[resultKey] = _simulateRoleDefinition(
          guild,
          guildId,
          payload,
          variables,
        );
        return true;
      }
      if (guild is! Map ||
          guild['roles'] is! List ||
          guild['members'] is! Map) {
        throw StateError(
          'Role simulation requires guild roles and members fixtures',
        );
      }
      final userId = (payload['userId'] ?? payload['memberId'] ?? '')
          .toString();
      final members = guild['members'] as Map;
      final member = members[userId];
      if (int.tryParse(userId) == null || member is! Map) {
        throw StateError('Role simulation requires an existing member ID');
      }
      final knownRoles = <String, Map>{
        for (final raw in guild['roles'] as List)
          (raw as Map)['id'].toString(): raw,
      };
      final before = (member['roles'] as List? ?? const [])
          .map((role) => role.toString())
          .toList();
      final setRoles = payload['setRoles'];
      final selected = setRoles is List
          ? setRoles.map((role) => role.toString()).toList()
          : [
              payload['roleId']?.toString() ??
                  knownRoles.entries
                      .where(
                        (entry) =>
                            entry.value['name']?.toString() ==
                            payload['roleName']?.toString(),
                      )
                      .map((entry) => entry.key)
                      .firstOrNull ??
                  '',
            ];
      for (final roleId in selected) {
        if (int.tryParse(roleId) == null || !knownRoles.containsKey(roleId)) {
          throw StateError('Role $roleId is absent from sandbox fixture');
        }
      }
      final after = [...before];
      final type = setRoles is List
          ? 'setUserRoles'
          : action.type == BotCreatorActionType.addRole
          ? 'addRole'
          : 'removeRole';
      if (setRoles is List) {
        after
          ..clear()
          ..addAll(selected.toSet());
      } else if (action.type == BotCreatorActionType.addRole) {
        if (!after.contains(selected.single)) after.add(selected.single);
      } else {
        after.remove(selected.single);
      }
      member['roles'] = after;
      final scopedPrefix = 'member[$userId]';
      variables['$scopedPrefix.roles'] = after.join(',');
      final names = <String>[
        for (final role in guild['roles'] as List)
          if (after.contains((role as Map)['id'].toString()))
            role['name'].toString(),
      ];
      variables['$scopedPrefix.roleNamesJson'] = jsonEncode(names);
      var permissions = 0;
      for (final roleId in after) {
        permissions |=
            int.tryParse(
              knownRoles[roleId]?['permissions']?.toString() ?? '',
            ) ??
            0;
      }
      final isAdmin =
          guild['owner_id']?.toString() == userId ||
          Permissions(permissions).isAdministrator;
      variables['$scopedPrefix.isAdmin'] = isAdmin.toString();
      final permissionTokens = permissionTokensFromPermissions(
        Permissions(
          isAdmin ? permissions | Permissions.administrator.value : permissions,
        ),
      ).join(',');
      variables['$scopedPrefix.permissions'] = permissionTokens;
      variables['permissions.byId.$userId'] = permissionTokens;
      if (userId == variables['author.id']) {
        variables['member.roles'] = after.join(',');
        variables['member.isAdmin'] = isAdmin.toString();
        variables['member.permissions'] = permissionTokens;
      }
      effects.add({
        'type': type,
        'guild_id': guildId,
        'user_id': userId,
        'role_ids': selected,
        'before': before,
        'after': after,
        'simulated': true,
      });
      results[resultKey] = userId;
      return true;
    }

    if (action.type == BotCreatorActionType.setNickname) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      final members = guild is Map ? guild['members'] : null;
      if (members is! Map) {
        throw StateError('Nickname simulation requires guild members fixtures');
      }
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final userId = payload['userId']?.toString() ?? '';
      final member = members[userId];
      if (int.tryParse(userId) == null || member is! Map) {
        throw StateError('Nickname simulation requires an existing member ID');
      }
      final nickname = payload['nickname']?.toString() ?? '';
      if (nickname.length > 32) {
        throw StateError('Nickname exceeds Discord length limit');
      }
      final before = member['nick']?.toString();
      member['nick'] = nickname;
      variables['member[$userId].nick'] = nickname;
      variables['member[$userId].displayName'] = nickname;
      if (variables['author.id'] == userId) {
        variables['member.nick'] = nickname;
        variables['member.displayName'] = nickname;
      }
      effects.add({
        'type': 'setNickname',
        'guild_id': guildId,
        'user_id': userId,
        'before': before,
        'after': nickname,
        'simulated': true,
      });
      results[resultKey] = userId;
      return true;
    }

    if (action.type == BotCreatorActionType.slowmode) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      final channels = guild is Map ? guild['channels'] : null;
      if (channels is! List) {
        throw StateError(
          'Slowmode simulation requires guild channels fixtures',
        );
      }
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final channelId = payload['channelId']?.toString() ?? '';
      final matches = channels.where(
        (raw) => raw is Map && raw['id'].toString() == channelId,
      );
      if (int.tryParse(channelId) == null || matches.isEmpty) {
        throw StateError('Slowmode simulation requires an existing channel ID');
      }
      final channel = matches.first as Map;
      if (!{'text', 'forum', 'thread'}.contains(channel['type'] ?? 'text')) {
        throw StateError('Slowmode is unsupported for this channel type');
      }
      final duration = parseBdfdDuration(payload['duration']?.toString() ?? '');
      if (duration == null || duration > const Duration(hours: 6)) {
        throw StateError('Slowmode duration must be between 0 and 6 hours');
      }
      final before = channel['slowmode'] ?? 0;
      channel['slowmode'] = duration.inSeconds;
      variables['channel[$channelId].slowmode'] = '${duration.inSeconds}';
      if (variables['channel.id'] == channelId) {
        variables['channel.slowmode'] = '${duration.inSeconds}';
      }
      effects.add({
        'type': 'slowmode',
        'guild_id': guildId,
        'channel_id': channelId,
        'before': before,
        'after': duration.inSeconds,
        'simulated': true,
      });
      results[resultKey] = channelId;
      return true;
    }

    if ({
      BotCreatorActionType.createThread,
      BotCreatorActionType.addThreadMember,
      BotCreatorActionType.removeThreadMember,
    }.contains(action.type)) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      final channels = guild is Map ? guild['channels'] : null;
      if (channels is! List) {
        throw StateError('Thread simulation requires guild channels fixtures');
      }
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      if (action.type == BotCreatorActionType.createThread) {
        final parentId =
            (payload['channelId']?.toString().isNotEmpty == true
                    ? payload['channelId']
                    : variables['channel.id'])
                .toString();
        final parent = channels
            .whereType<Map>()
            .where((channel) => channel['id'].toString() == parentId)
            .firstOrNull;
        final name = (payload['name'] ?? '').toString().trim();
        if (parent == null || parent['type'] != 'text' || name.isEmpty) {
          throw StateError('Thread creation requires a text parent and name');
        }
        final messageId = (payload['messageId'] ?? '').toString();
        if (messageId.isNotEmpty) {
          final messages = (guild['messages'] as Map?)?[parentId];
          if (messages is! List ||
              !messages.any(
                (row) => row is Map && row['id'].toString() == messageId,
              )) {
            throw StateError('Thread source message is absent from fixture');
          }
        }
        final id = '${9000 + channels.length}';
        final thread = <String, dynamic>{
          'id': id,
          'name': name,
          'type': 'thread',
          'parent_id': parentId,
          'message_count': 0,
          'members': <String>[],
          'archived': false,
          'locked': false,
          'auto_archive_duration':
              int.tryParse(
                (payload['autoArchiveDuration'] ?? '60').toString(),
              ) ??
              60,
          if (messageId.isNotEmpty) 'source_message_id': messageId,
        };
        channels.add(thread);
        variables['thread.lastId'] = id;
        variables['thread.lastName'] = name;
        variables['$resultKey.threadId'] = id;
        variables['$resultKey.name'] = name;
        variables['$resultKey.parentId'] = parentId;
        results[resultKey] = id;
        effects.add({
          'type': 'createThread',
          'guild_id': guildId,
          'thread': Map<String, dynamic>.from(thread),
          'simulated': true,
        });
        return true;
      }
      final threadId = (payload['threadId'] ?? '').toString();
      final userId = (payload['userId'] ?? '').toString();
      final thread = channels
          .whereType<Map>()
          .where(
            (channel) =>
                channel['id'].toString() == threadId &&
                channel['type'] == 'thread',
          )
          .firstOrNull;
      if (thread == null || int.tryParse(userId) == null) {
        throw StateError(
          'Thread member simulation requires a thread and user ID',
        );
      }
      final members = thread['members'];
      if (members is! List) {
        throw StateError('Thread members fixture is missing');
      }
      final before = members.map((value) => value.toString()).toList();
      if (action.type == BotCreatorActionType.addThreadMember) {
        if (!members.contains(userId)) members.add(userId);
      } else {
        members.remove(userId);
      }
      final after = members.map((value) => value.toString()).toList();
      variables['thread.memberCount'] = after.length.toString();
      variables['$resultKey.threadId'] = threadId;
      variables['$resultKey.userId'] = userId;
      results[resultKey] = action.type == BotCreatorActionType.addThreadMember
          ? 'ADDED'
          : 'REMOVED';
      effects.add({
        'type': action.type.name,
        'thread_id': threadId,
        'user_id': userId,
        'before': before,
        'after': after,
        'simulated': true,
      });
      return true;
    }

    if ({
      BotCreatorActionType.createChannel,
      BotCreatorActionType.updateChannel,
      BotCreatorActionType.removeChannel,
    }.contains(action.type)) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      final channels = guild is Map ? guild['channels'] : null;
      if (channels is! List) {
        throw StateError('Channel simulation requires guild channels fixtures');
      }
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final type = action.type;
      if (type == BotCreatorActionType.createChannel) {
        final name = payload['name']?.toString().trim() ?? '';
        final channelType = payload['type']?.toString() ?? 'text';
        final categoryId = payload['categoryId']?.toString() ?? '';
        final isTicket = payload['isTicket'] == true;
        final ownerId = payload['ownerId']?.toString() ?? '';
        if (name.isEmpty ||
            name.length > 100 ||
            !{
              'text',
              'voice',
              'stage',
              'forum',
              'category',
              'announcement',
            }.contains(channelType)) {
          throw StateError('Invalid channel name or type');
        }
        if (categoryId.isNotEmpty &&
            !channels.any(
              (c) =>
                  c is Map &&
                  c['id'].toString() == categoryId &&
                  c['type'] == 'category',
            )) {
          throw StateError('Channel category is absent from sandbox fixture');
        }
        if (isTicket &&
            (categoryId.isEmpty ||
                int.tryParse(ownerId) == null ||
                channelType != 'text')) {
          throw StateError('Ticket requires a category and creator ID');
        }
        final id = (60 + channels.length).toString();
        final channel = <String, dynamic>{
          'id': id,
          'name': name,
          'type': channelType,
          if (categoryId.isNotEmpty) 'parent_id': categoryId,
          if (isTicket) 'is_ticket': true,
          if (isTicket) 'owner_id': ownerId,
          if (isTicket)
            'permission_overwrites': {
              variables['guild.id'] ?? '': {'viewChannel': 'deny'},
              ownerId: {
                'viewChannel': 'allow',
                'sendMessages': 'allow',
                'readMessageHistory': 'allow',
              },
            },
        };
        channels.add(channel);
        if (isTicket) {
          await store.setScopedVariable(
            'sandbox',
            'channel',
            id,
            '__ticket',
            true,
          );
          await store.setScopedVariable(
            'sandbox',
            'channel',
            id,
            '__ticket_owner',
            ownerId,
          );
          final welcome = (payload['welcomeMessage'] ?? '').toString();
          if (welcome.isNotEmpty) {
            responses.add({
              'type': 'sendMessage',
              'payload': {'channelId': id, 'content': welcome},
              'simulated': true,
              'id': '${100000 + responses.length}',
            });
          }
        }
        effects.add({
          'type': isTicket ? 'createTicket' : 'createChannel',
          'channel_id': id,
          'after': channel,
          'simulated': true,
        });
        results[resultKey] = id;
        return true;
      }
      final rawIds = payload['channelIds'];
      final rawNames = payload['channelNames'];
      final ids = type == BotCreatorActionType.updateChannel
          ? [payload['channelId']?.toString() ?? '']
          : rawNames is List
          ? [
              for (final name in rawNames)
                for (final channel in channels)
                  if (channel is Map && channel['name'] == name)
                    channel['id'].toString(),
            ]
          : [
              for (final id in rawIds is List ? rawIds : [payload['channelId']])
                id.toString(),
            ];
      if (ids.isEmpty ||
          ids.any(
            (id) =>
                int.tryParse(id) == null ||
                !channels.any((c) => c is Map && c['id'].toString() == id),
          )) {
        throw StateError('Channel is absent from sandbox fixture');
      }
      if (type == BotCreatorActionType.removeChannel) {
        for (final id in ids.toSet()) {
          if (payload['ticketClose'] == true) {
            final marker = await store.getScopedVariable(
              'sandbox',
              'channel',
              id,
              '__ticket',
            );
            if (marker != true && marker?.toString() != 'true') {
              final message = (payload['errorMessage'] ?? '').toString();
              if (message.isNotEmpty) {
                responses.add({
                  'type': 'respondWithMessage',
                  'payload': {'content': message},
                  'simulated': true,
                  'id': '${100000 + responses.length}',
                });
                results[resultKey] = '';
                return true;
              }
              throw StateError('This channel is not a ticket');
            }
            final owner = await store.getScopedVariable(
              'sandbox',
              'channel',
              id,
              '__ticket_owner',
            );
            final actorId =
                variables['author.id'] ?? variables['user.id'] ?? '';
            final perms = (variables['member.permissions'] ?? '').toLowerCase();
            if (actorId != owner?.toString() &&
                actorId != variables['guild.ownerId'] &&
                variables['member.isAdmin'] != 'true' &&
                !perms.contains('managechannels') &&
                !perms.contains('administrator')) {
              throw StateError('Only the ticket creator or staff can close it');
            }
            await store.removeScopedVariable(
              'sandbox',
              'channel',
              id,
              '__ticket',
            );
            await store.removeScopedVariable(
              'sandbox',
              'channel',
              id,
              '__ticket_owner',
            );
            variables['channel.isTicket'] = 'false';
          }
          channels.removeWhere((c) => c is Map && c['id'].toString() == id);
          effects.add({
            'type': payload['ticketClose'] == true
                ? 'closeTicket'
                : 'removeChannel',
            'channel_id': id,
            'simulated': true,
          });
        }
      } else {
        final id = ids.single;
        final channel =
            channels.firstWhere((c) => c is Map && c['id'].toString() == id)
                as Map;
        final categoryId = payload['categoryId']?.toString();
        if (categoryId != null &&
            !channels.any(
              (c) =>
                  c is Map &&
                  c['id'].toString() == categoryId &&
                  c['type'] == 'category',
            )) {
          throw StateError('Channel category is absent from sandbox fixture');
        }
        final before = Map<String, dynamic>.from(channel);
        if (channel['type'] == 'thread') {
          for (final entry in {
            'archived': 'archived',
            'locked': 'locked',
            'autoArchiveDuration': 'auto_archive_duration',
            'slowmode': 'slowmode',
          }.entries) {
            final value = payload[entry.key];
            if (value != null) channel[entry.value] = value;
          }
        }
        for (final key in ['name', 'topic', 'nsfw', 'position']) {
          if (payload.containsKey(key) && payload[key] != null) {
            channel[key] = payload[key];
          }
        }
        if (categoryId != null) channel['parent_id'] = categoryId;
        effects.add({
          'type': 'updateChannel',
          'channel_id': id,
          'before': before,
          'after': Map<String, dynamic>.from(channel),
          'simulated': true,
        });
      }
      results[resultKey] = ids.last;
      return true;
    }

    if (action.type == BotCreatorActionType.editChannelPermissions) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      final channels = guild is Map ? guild['channels'] : null;
      if (channels is! List) {
        throw StateError('Channel permissions require guild channels fixtures');
      }
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final channelId = payload['channelId']?.toString() ?? '';
      final targetId = payload['targetId']?.toString() ?? '';
      if (!channels.any((c) => c is Map && c['id'].toString() == channelId) ||
          int.tryParse(targetId) == null) {
        throw StateError('Channel or permission target is absent');
      }
      final roles = guild['roles'] as List? ?? [];
      final members = guild['members'] as Map? ?? {};
      final targetType =
          roles.any((r) => r is Map && r['id'].toString() == targetId)
          ? 'role'
          : members.containsKey(targetId)
          ? 'member'
          : null;
      if (targetType == null) {
        throw StateError('Permission target is absent from sandbox fixture');
      }
      final permissions = Map<String, dynamic>.from(
        payload['permissions'] as Map? ?? {},
      );
      if (permissions.isEmpty ||
          permissions.values.any((v) => v != 'allow' && v != 'deny')) {
        throw StateError('Channel permission states must be allow or deny');
      }
      effects.add({
        'type': 'editChannelPermissions',
        'channel_id': channelId,
        'target_id': targetId,
        'target_type': targetType,
        'permissions': permissions,
        'simulated': true,
      });
      results[resultKey] = 'updated';
      return true;
    }

    if ({
      BotCreatorActionType.banUser,
      BotCreatorActionType.unbanUser,
      BotCreatorActionType.kickUser,
      BotCreatorActionType.muteUser,
      BotCreatorActionType.unmuteUser,
    }.contains(action.type)) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      if (guild is! Map || guild['members'] is! Map || guild['bans'] is! Map) {
        throw StateError(
          'Moderation simulation requires guild members and bans fixtures',
        );
      }
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      var userId = (payload['userId'] ?? payload['memberId'] ?? '').toString();
      if (action.type == BotCreatorActionType.unbanUser && userId.isEmpty) {
        final username =
            payload['username']?.toString().trim().toLowerCase() ?? '';
        final knownUsers = guild['ban_users'];
        if (username.isEmpty || knownUsers is! Map) {
          throw StateError('Username unban requires ban_users fixtures');
        }
        for (final entry in knownUsers.entries) {
          if (entry.value.toString().toLowerCase() == username) {
            userId = entry.key.toString();
            break;
          }
        }
      }
      if (int.tryParse(userId) == null) {
        throw StateError('Moderation simulation requires a valid user ID');
      }
      if (action.type == BotCreatorActionType.kickUser &&
          payload['kickPermissionActorId'] != null) {
        await checkModerationActorPermission(
          entityGateway!,
          Snowflake.parse(guildId),
          BotModerationRequest(
            operation: BotModerationOperation.kick,
            userId: userId,
            kickPermissionActorId: payload['kickPermissionActorId'].toString(),
          ),
          null,
        );
        checkBudget();
      }
      final members = guild['members'] as Map;
      final bans = guild['bans'] as Map;
      final member = members[userId];
      final before = <String, dynamic>{
        'member': member is Map ? Map<String, dynamic>.from(member) : null,
        'ban_reason': bans[userId],
      };
      final type = action.type.name;
      switch (action.type) {
        case BotCreatorActionType.banUser:
          bans[userId] = payload['reason']?.toString() ?? '';
          members.remove(userId);
          variables['member[$userId].isBanned'] = 'true';
          variables['ban.reason[$userId]'] = bans[userId].toString();
          variables['ban.reason[$userId;$guildId]'] = bans[userId].toString();
        case BotCreatorActionType.unbanUser:
          if (!bans.containsKey(userId)) {
            throw StateError('User $userId is absent from sandbox bans');
          }
          bans.remove(userId);
          variables['member[$userId].isBanned'] = 'false';
          variables['ban.reason[$userId]'] = '';
          variables['ban.reason[$userId;$guildId]'] = '';
        case BotCreatorActionType.kickUser:
          if (member is! Map) {
            throw StateError('User $userId is absent from sandbox members');
          }
          members.remove(userId);
        case BotCreatorActionType.muteUser:
          if (member is! Map) {
            throw StateError('User $userId is absent from sandbox members');
          }
          final raw = payload['duration']?.toString().trim() ?? '';
          final match = RegExp(
            r'^(\d+)\s*([smhd])?$',
            caseSensitive: false,
          ).firstMatch(raw);
          if (match == null) {
            throw StateError('Invalid simulated timeout duration');
          }
          final amount = int.parse(match.group(1)!);
          final unit = (match.group(2) ?? 's').toLowerCase();
          final seconds =
              amount *
              switch (unit) {
                'm' => 60,
                'h' => 3600,
                'd' => 86400,
                _ => 1,
              };
          member['timeout_seconds'] = seconds.clamp(1, 28 * 86400);
          member['timeout_until'] = DateTime.now()
              .toUtc()
              .add(Duration(seconds: member['timeout_seconds'] as int))
              .toIso8601String();
          variables['member[$userId].isTimedOut'] = 'true';
        case BotCreatorActionType.unmuteUser:
          if (member is! Map) {
            throw StateError('User $userId is absent from sandbox members');
          }
          member.remove('timeout_seconds');
          member.remove('timeout_until');
          variables['member[$userId].isTimedOut'] = 'false';
        default:
          throw StateError('Unsupported moderation action');
      }
      effects.add({
        'type': type,
        'guild_id': guildId,
        'user_id': userId,
        'reason': payload['reason']?.toString() ?? '',
        'before': before,
        'after': {
          'member': members[userId] is Map
              ? Map<String, dynamic>.from(members[userId] as Map)
              : null,
          'ban_reason': bans[userId],
        },
        'simulated': true,
      });
      results[resultKey] = userId;
      return true;
    }

    if (action.type == BotCreatorActionType.deleteMessages ||
        action.type == BotCreatorActionType.deleteTrigger) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final channelId = (payload['channelId'] ?? variables['channel.id'] ?? '')
          .toString();
      final channels = guild is Map ? guild['messages'] : null;
      final rows = channels is Map ? channels[channelId] : null;
      if (rows is! List) {
        throw StateError(
          'Message deletion simulation requires channel messages fixtures',
        );
      }
      final messageId = action.type == BotCreatorActionType.deleteTrigger
          ? variables['message.id'] ?? ''
          : payload['messageId']?.toString() ?? '';
      if (messageId.isNotEmpty) {
        final index = rows.indexWhere(
          (raw) => raw is Map && raw['id'].toString() == messageId,
        );
        if (index < 0) {
          throw StateError('Message $messageId is absent from sandbox fixture');
        }
        rows.removeAt(index);
        effects.add({
          'type': action.type.name,
          'guild_id': guildId,
          'channel_id': channelId,
          'deleted_ids': [messageId],
          'remaining_ids': [
            for (final raw in rows)
              if (raw is Map) raw['id'].toString(),
          ],
          'simulated': true,
        });
        results[resultKey] = action.type == BotCreatorActionType.deleteTrigger
            ? messageId
            : '1';
        return true;
      }
      if (action.type == BotCreatorActionType.deleteTrigger) {
        results[resultKey] = 'NOT_FOUND';
        return true;
      }
      final count = int.tryParse(
        (payload['count'] ?? payload['messageCount'] ?? '').toString(),
      );
      if (count == null ||
          count < 1 ||
          (payload['bdfdClear'] == true && count > 100)) {
        throw StateError('Invalid simulated message deletion count');
      }
      final onlyUserId = payload['onlyUserId']?.toString() ?? '';
      final pinnedRaw = payload['removePinned']?.toString().toLowerCase() ?? '';
      final removePinned = !{'no', 'false', '0', 'n'}.contains(pinnedRaw);
      final selected = rows
          .where((raw) {
            if (raw is! Map) return false;
            if (onlyUserId.isNotEmpty &&
                raw['author_id']?.toString() != onlyUserId) {
              return false;
            }
            return removePinned || raw['pinned'] != true;
          })
          .take(count)
          .map((raw) => (raw as Map)['id'].toString())
          .toList();
      final selectedIds = selected.toSet();
      rows.removeWhere(
        (raw) => raw is Map && selectedIds.contains(raw['id'].toString()),
      );
      effects.add({
        'type': 'deleteMessages',
        'guild_id': guildId,
        'channel_id': channelId,
        'only_user_id': onlyUserId,
        'remove_pinned': removePinned,
        'deleted_ids': selected,
        'deleted_count': selected.length,
        'remaining_ids': [
          for (final raw in rows)
            if (raw is Map) raw['id'].toString(),
        ],
        'simulated': true,
      });
      results[resultKey] = '${selected.length}';
      variables['action.$resultKey.count'] = '${selected.length}';
      variables['$resultKey.count'] = '${selected.length}';
      return true;
    }

    final isCrosspost =
        action.type == BotCreatorActionType.sendMessage &&
        action.payload['targetType'] == 'crosspost';
    if (action.type == BotCreatorActionType.pinMessage ||
        action.type == BotCreatorActionType.unpinMessage ||
        action.type == BotCreatorActionType.editMessage ||
        isCrosspost) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final channelId = (payload['channelId'] ?? variables['channel.id'] ?? '')
          .toString();
      final messagesByChannel = guild is Map ? guild['messages'] : null;
      final rows = messagesByChannel is Map
          ? messagesByChannel[channelId]
          : null;
      if (rows is! List) {
        throw StateError('Message mutation requires channel messages fixtures');
      }
      final messageId = payload['messageId']?.toString() ?? '';
      final index = rows.indexWhere(
        (raw) => raw is Map && raw['id'].toString() == messageId,
      );
      if (int.tryParse(messageId) == null || index < 0) {
        throw StateError('Message $messageId is absent from sandbox fixture');
      }
      final row = rows[index] as Map;
      final before = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(row)) as Map,
      );
      if (action.type == BotCreatorActionType.editMessage &&
          payload['bdfdDelayedEdit'] == true) {
        final duration = parseBdfdDuration(payload['delay']?.toString() ?? '');
        if (duration == null ||
            duration <= Duration.zero ||
            duration > const Duration(minutes: 120)) {
          throw StateError('Invalid simulated delayed edit duration');
        }
        if (row['author_id']?.toString() != variables['bot.id']) {
          throw StateError('Only the bot’s message can be edited');
        }
        effects.add({
          'type': 'scheduleEditMessage',
          'guild_id': guildId,
          'channel_id': channelId,
          'message_id': messageId,
          'delay_ms': duration.inMilliseconds,
          'before': before,
          'scheduled': {
            if (payload.containsKey('content')) 'content': payload['content'],
            if (payload.containsKey('embeds')) 'embeds': payload['embeds'],
          },
          'simulated': true,
        });
        results[resultKey] = 'scheduled';
        variables['action.$resultKey.status'] = 'scheduled';
        return true;
      }
      if (action.type == BotCreatorActionType.pinMessage) {
        row['pinned'] = true;
      } else if (action.type == BotCreatorActionType.unpinMessage) {
        row['pinned'] = false;
      } else if (action.type == BotCreatorActionType.editMessage) {
        if (row['author_id']?.toString() != variables['bot.id']) {
          throw StateError('Only the bot’s message can be edited');
        }
        if (payload.containsKey('content')) row['content'] = payload['content'];
        if (payload.containsKey('embeds')) row['embeds'] = payload['embeds'];
        if (payload['clearComponents'] == true) {
          row['components'] = <dynamic>[];
        } else if (payload['componentMutation'] != null) {
          final mutation = payload['componentMutation']?.toString();
          final customId = payload['customId']?.toString() ?? '';
          final components = row['components'];
          if (components is! List) {
            throw StateError(
              'Component mutation requires message components fixture',
            );
          }
          final remaining = <dynamic>[];
          for (final raw in components) {
            if (raw is! Map ||
                raw['type'] != 'actionRow' ||
                raw['components'] is! List) {
              throw StateError(
                'Selective component removal requires action rows',
              );
            }
            final children = (raw['components'] as List).where((child) {
              if (child is! Map) return true;
              if (mutation == 'removeButtons') return child['type'] != 'button';
              return child['customId'] != customId && child['url'] != customId;
            }).toList();
            if (children.isNotEmpty) {
              remaining.add({...raw, 'components': children});
            }
          }
          row['components'] = remaining;
        }
      } else {
        final channels = guild['channels'];
        final isAnnouncement =
            channels is List &&
            channels.any(
              (raw) =>
                  raw is Map &&
                  raw['id'].toString() == channelId &&
                  raw['type'] == 'announcement',
            );
        if (!isAnnouncement) {
          throw StateError(
            'Crosspost requires an announcement channel fixture',
          );
        }
        row['published'] = true;
      }
      effects.add({
        'type': isCrosspost ? 'publishMessage' : action.type.name,
        'guild_id': guildId,
        'channel_id': channelId,
        'message_id': messageId,
        'before': before,
        'after': Map<String, dynamic>.from(jsonDecode(jsonEncode(row)) as Map),
        'simulated': true,
      });
      results[resultKey] = messageId;
      return true;
    }

    if (action.type == BotCreatorActionType.httpRequest) {
      final client = httpClient();
      try {
        return await executeHttp(
          type: action.type,
          payload: action.payload,
          resultKey: resultKey,
          results: results,
          variables: variables,
          resolveValue: resolveValue,
          onLog: null,
          httpClient: client,
          setGlobalVariable: (key, value) =>
              store.setGlobalVariable('sandbox', key, value),
        );
      } finally {
        client.close();
      }
    }
    if ({
      BotCreatorActionType.addReaction,
      BotCreatorActionType.removeReaction,
      BotCreatorActionType.clearAllReactions,
    }.contains(action.type)) {
      final guildId = variables['guild.id'] ?? '';
      final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final channelId = (payload['channelId'] ?? variables['channel.id'] ?? '')
          .toString();
      final messageId = payload['messageId']?.toString() ?? '';
      final rows = guild is Map && guild['messages'] is Map
          ? (guild['messages'] as Map)[channelId]
          : null;
      if (rows is! List || int.tryParse(messageId) == null) {
        throw StateError('Reaction requires channel messages fixtures');
      }
      final index = rows.indexWhere(
        (r) => r is Map && r['id'].toString() == messageId,
      );
      if (index < 0) {
        throw StateError('Reaction message is absent from sandbox fixture');
      }
      final row = rows[index] as Map;
      final rawReactions = row.putIfAbsent(
        'reactions',
        () => <String, dynamic>{},
      );
      if (rawReactions is! Map) throw StateError('Invalid reactions fixture');
      final reactions = rawReactions;
      final before = jsonDecode(jsonEncode(reactions));
      final type = action.type;
      if (type == BotCreatorActionType.addReaction) {
        final rawEmojis = payload['emojis'];
        final emojis = rawEmojis is List
            ? rawEmojis.map((e) => e.toString()).toList()
            : [payload['emoji']?.toString() ?? ''];
        if (emojis.isEmpty || emojis.any((e) => e.isEmpty)) {
          throw StateError('At least one reaction emoji is required');
        }
        for (final emoji in emojis) {
          final users = reactions.putIfAbsent(emoji, () => <String>[]);
          if (users is! List) {
            throw StateError('Invalid reaction users fixture');
          }
          if (!users.contains(variables['bot.id'])) {
            users.add(variables['bot.id']);
          }
        }
      } else if (type == BotCreatorActionType.removeReaction) {
        final emoji = payload['emoji']?.toString() ?? '';
        if (emoji.isEmpty) throw StateError('Reaction emoji is required');
        final users = reactions[emoji];
        if (users is List) {
          users.remove(payload['userId']?.toString() ?? variables['bot.id']);
          if (users.isEmpty) reactions.remove(emoji);
        }
      } else {
        final emoji = payload['emoji']?.toString() ?? '!all';
        if (emoji == '!all') {
          reactions.clear();
        } else {
          reactions.remove(emoji);
        }
      }
      effects.add({
        'type': type.name,
        'channel_id': channelId,
        'message_id': messageId,
        'before': before,
        'after': jsonDecode(jsonEncode(reactions)),
        'simulated': true,
      });
      results[resultKey] = 'OK';
      return true;
    }
    if (action.type == BotCreatorActionType.sendDm) {
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final rawIds = payload['userIds'];
      final userIds = rawIds is List ? rawIds : [payload['userId']];
      if (userIds.isEmpty) throw StateError('DM requires a recipient');
      for (final rawId in userIds) {
        final userId = rawId?.toString() ?? '';
        if (int.tryParse(userId) == null) {
          throw StateError('DM requires valid recipient IDs');
        }
        final id = '${100000 + responses.length}';
        responses.add({
          'type': 'sendDm',
          'payload': {...payload, 'userId': userId},
          'id': id,
          'simulated': true,
        });
        effects.add({
          'type': 'sendDm',
          'user_id': userId,
          'message_id': id,
          'simulated': true,
        });
        variables['last.response.id'] = id;
        results[resultKey] = id;
      }
      return true;
    }
    if (messages.contains(action.type)) {
      if (action.type == BotCreatorActionType.sendMessage &&
          action.payload['targetType'] == 'typing') {
        final payload = Map<String, dynamic>.from(
          resolve(action.payload) as Map,
        );
        final channelId =
            (payload['channelId'] ?? variables['channel.id'] ?? '').toString();
        if (int.tryParse(channelId) == null) {
          throw StateError('Typing simulation requires a valid channel ID');
        }
        effects.add({
          'type': 'typing',
          'channel_id': channelId,
          'simulated': true,
        });
        results[resultKey] = '';
        return true;
      }
      final id = '${100000 + responses.length}';
      final response = <String, dynamic>{
        'type': action.type.name,
        'payload': resolve(action.payload),
        'simulated': true,
        'id': id,
      };
      if (action.type == BotCreatorActionType.respondWithModal) {
        final definition = ModalDefinition.fromJson(
          Map<String, dynamic>.from(
            action.payload['modal'] as Map? ?? action.payload,
          ),
        );
        response['api_modal'] = buildModalResponse(
          definition,
          resolveValue,
        ).build();
      } else {
        final components =
            action.payload['components'] ?? action.payload['componentV2'];
        if (components is Map && components.isNotEmpty) {
          final definition = ComponentV2Definition.fromJson(
            Map<String, dynamic>.from(components),
          );
          response['api_components'] = buildComponentNodes(
            definition: definition,
            resolve: resolveValue,
          ).map((builder) => builder.build()).toList();
        }
      }
      responses.add(response);
      results[resultKey] = id;
      if (action.type == BotCreatorActionType.respondWithMessage ||
          action.type == BotCreatorActionType.sendMessage) {
        variables['last.response.id'] = id;
        final guildId = variables['guild.id'] ?? '';
        final guild = (entityGateway?.fixtures['guilds'] as Map?)?[guildId];
        final messagesByChannel = guild is Map ? guild['messages'] : null;
        final channelId = response['payload'] is Map
            ? ((response['payload'] as Map)['channelId'] ??
                      variables['channel.id'])
                  .toString()
            : (variables['channel.id'] ?? '');
        final rows = messagesByChannel is Map
            ? messagesByChannel[channelId]
            : null;
        if (rows is List) {
          rows.insert(0, {
            'id': id,
            'author_id': variables['bot.id'],
            'content': (response['payload'] as Map)['content'] ?? '',
            'pinned': false,
          });
        }
      }
      return true;
    }
    if (action.type == BotCreatorActionType.registerGuildCommands ||
        action.type == BotCreatorActionType.unregisterGuildCommands) {
      final payload = Map<String, dynamic>.from(resolve(action.payload) as Map);
      final rawGuildId = payload['guildId'] ?? variables['guild.id'];
      final guildId = rawGuildId?.toString().trim() ?? '';
      if (guildId.isEmpty || int.tryParse(guildId) == null) {
        throw StateError(
          'Sandbox action ${action.type.name} requires a valid guild ID',
        );
      }
      effects.add({
        'type': action.type.name,
        'guild_id': guildId,
        'simulated': true,
      });
      results[resultKey] = 'OK';
      return true;
    }
    if (action.type == BotCreatorActionType.debugProfile) {
      results[resultKey] = 'Sandbox trace enabled';
      return true;
    }
    if (sandboxSimulatedAdditionalActions.contains(action.type)) {
      final guild =
          (entityGateway?.fixtures['guilds'] as Map?)?[variables['guild.id'] ??
              ''];
      return simulateAdditionalAction(
        type: action.type,
        payload: Map<String, dynamic>.from(resolve(action.payload) as Map),
        resultKey: resultKey,
        results: results,
        variables: variables,
        effects: effects,
        responses: responses,
        guild: guild is Map ? guild : null,
      );
    }
    if (pure.contains(action.type)) return false;
    throw StateError(sandboxMissingFixtureMessage(action.type));
  }

  String _simulateRoleDefinition(
    Map guild,
    String guildId,
    Map<String, dynamic> payload,
    Map<String, String> variables,
  ) {
    final roles = guild['roles'] as List;
    if (payload['createNew'] == true) {
      final name = payload['name']?.toString().trim() ?? '';
      final color = parseBdfdRoleColor(payload['color']);
      if (name.isEmpty || name.length > 100 || color == null) {
        throw StateError('Invalid role name or color');
      }
      final nextId =
          roles
              .map((role) => int.tryParse((role as Map)['id'].toString()) ?? 0)
              .fold<int>(int.tryParse(guildId) ?? 0, (a, b) => a > b ? a : b) +
          1;
      final role = <String, dynamic>{
        'id': '$nextId',
        'name': name,
        'color': color,
        'position': roles.length,
        'permissions': '0',
        'hoist': payload['hoist'] == true,
        'mentionable': payload['mentionable'] == true,
      };
      roles.add(role);
      variables['role[$name].id'] = '$nextId';
      variables['role[$nextId].name'] = name;
      variables['role[$nextId].exists'] = 'true';
      effects.add({
        'type': 'createRole',
        'guild_id': guildId,
        'role_id': '$nextId',
        'before': null,
        'after': Map<String, dynamic>.from(role),
        'simulated': true,
      });
      return '$nextId';
    }

    final roleId = payload['roleId']?.toString() ?? '';
    final index = roles.indexWhere(
      (raw) => (raw as Map)['id'].toString() == roleId,
    );
    if (index < 0) {
      throw StateError('Role $roleId is absent from sandbox fixture');
    }
    final role = roles[index] as Map;
    final before = Map<String, dynamic>.from(role);
    String type;
    if (payload['deleteRole'] == true) {
      roles.removeAt(index);
      final members = guild['members'];
      if (members is Map) {
        for (final member in members.values) {
          if (member is Map && member['roles'] is List) {
            (member['roles'] as List).removeWhere(
              (value) => value.toString() == roleId,
            );
          }
        }
      }
      variables['role[$roleId].exists'] = 'false';
      variables['role[$roleId].name'] = '';
      variables['role[${before['name']}].id'] = '';
      type = 'deleteRole';
    } else if (payload.containsKey('updateColor')) {
      final color = parseBdfdRoleColor(payload['updateColor']);
      if (color == null) throw StateError('Invalid role color');
      role['color'] = color;
      type = 'colorRole';
    } else if (payload.containsKey('modifyPermissions')) {
      final raw = payload['modifyPermissions'];
      if (raw is! List) throw StateError('Invalid role permissions');
      final flags = bdfdPermissionFlags(raw.map((value) => value.toString()));
      if (flags == null) throw StateError('Invalid role permissions');
      var mask = int.tryParse(role['permissions']?.toString() ?? '') ?? 0;
      for (final flag in flags) {
        mask ^= flag.value;
      }
      role['permissions'] = '$mask';
      type = 'modifyRolePerms';
    } else if (payload['modify'] == true) {
      if (payload.containsKey('color')) {
        final color = parseBdfdRoleColor(payload['color']);
        if (color == null) throw StateError('Invalid role color');
        role['color'] = color;
      }
      for (final field in ['name', 'hoist', 'mentionable', 'position']) {
        if (payload.containsKey(field)) role[field] = payload[field];
      }
      if (payload.containsKey('name')) {
        variables['role[${before['name']}].id'] = '';
        variables['role[${role['name']}].id'] = roleId;
        variables['role[$roleId].name'] = role['name'].toString();
      }
      type = 'modifyRole';
    } else {
      throw StateError('Unsupported role definition action');
    }
    effects.add({
      'type': type,
      'guild_id': guildId,
      'role_id': roleId,
      'before': before,
      'after': type == 'deleteRole' ? null : Map<String, dynamic>.from(role),
      'simulated': true,
    });
    return roleId;
  }
}

/// Command fixtures are explicit, so missing data never looks like an empty bot.
class _SandboxCommandQueries implements BotCommandQueryService {
  _SandboxCommandQueries(this.policy, this.variables);
  final _SandboxPolicy policy;
  final Map<String, String> variables;

  List<dynamic> _rows(String key, CommandExecutionBudget budget) {
    budget.check();
    final rows = policy.entityGateway?.fixtures[key];
    if (rows is! List) {
      throw StateError('Native command queries require $key fixtures');
    }
    return rows;
  }

  @override
  Future<List<BotCommandDefinition>> commands({
    required CommandExecutionBudget budget,
  }) async => _rows('commands', budget).map((row) {
    budget.check();
    if (row is! Map ||
        row['name'] is! String ||
        (row['name'] as String).isEmpty) {
      throw StateError('Command fixture requires a name');
    }
    return BotCommandDefinition(row['name'] as String);
  }).toList();

  @override
  Future<List<BotGlobalSlashCommand>> globalSlashCommands({
    required CommandExecutionBudget budget,
  }) async => _rows('global_slash_commands', budget).map((row) {
    budget.check();
    if (row is! Map ||
        row['name'] is! String ||
        (row['name'] as String).isEmpty ||
        !RegExp(r'^[1-9][0-9]*$').hasMatch('${row['id']}')) {
      throw StateError('Global slash fixture requires an ID and name');
    }
    return BotGlobalSlashCommand(
      id: '${row['id']}',
      name: row['name'] as String,
    );
  }).toList();

  @override
  Future<String> invite({required CommandExecutionBudget budget}) async {
    budget.check();
    final id = variables['bot.id'] ?? '';
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(id)) {
      throw StateError('Bot invite requires a numeric bot ID');
    }
    return Uri.https('discord.com', '/oauth2/authorize', {
      'client_id': id,
      'permissions': '8',
      'scope': 'bot applications.commands',
    }).toString();
  }

  @override
  Future<void> leaveGuild(
    String? guildId, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    final id = guildId ?? variables['guild.id'] ?? '';
    final guilds = policy.entityGateway?.fixtures['guilds'];
    if (guilds is! Map ||
        !RegExp(r'^[1-9][0-9]*$').hasMatch(id) ||
        !guilds.containsKey(id)) {
      throw StateError('Bot leave requires an existing guild fixture');
    }
    guilds.remove(id);
    policy.effects.add({
      'type': 'leaveGuild',
      'guild_id': id,
      'simulated': true,
    });
  }
}

class _SandboxMusic implements BotMusicService {
  _SandboxMusic(this.policy, this.variables);
  final _SandboxPolicy policy;
  final Map<String, String> variables;
  @override
  Future<void> perform(
    BotMusicRequest request, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    final fixture = policy.musicFixture;
    if (fixture == null) {
      throw StateError('Music simulation requires a music fixture');
    }
    final type = switch (request.operation) {
      BotMusicOperation.join => BotCreatorActionType.joinVoice,
      BotMusicOperation.leave => BotCreatorActionType.leaveVoice,
      BotMusicOperation.play => BotCreatorActionType.playMusic,
      BotMusicOperation.pause => BotCreatorActionType.pauseMusic,
      BotMusicOperation.resume => BotCreatorActionType.resumeMusic,
      BotMusicOperation.skip => BotCreatorActionType.skipMusic,
      BotMusicOperation.stop => BotCreatorActionType.stopMusic,
      BotMusicOperation.volume => BotCreatorActionType.setMusicVolume,
      BotMusicOperation.loop => BotCreatorActionType.setMusicLoop,
      BotMusicOperation.seek => BotCreatorActionType.seekMusic,
    };
    policy.actions++;
    policy.checkBudget();
    fixture.apply(
      type,
      {
        if (request.query.isNotEmpty) 'query': request.query,
        if (request.channelId.isNotEmpty) 'channelId': request.channelId,
        if (request.userId.isNotEmpty) 'userId': request.userId,
        if (request.volume != null) 'volume': request.volume,
        if (request.loop.isNotEmpty) 'loop': request.loop,
        if (request.positionSeconds != null) ...{
          'position': request.positionSeconds,
          'positionUnit': 'seconds',
        },
      },
      variables,
      policy.effects,
    );
  }
}

class _SandboxDelays implements BotDelayService {
  _SandboxDelays(this.policy);
  final _SandboxPolicy policy;
  @override
  Future<void> delay(
    Duration duration, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    policy.effects.add({
      'type': 'replyIn',
      'delay_ms': duration.inMilliseconds,
      'simulated': true,
    });
  }
}

class _SandboxComponents implements BotComponentService {
  _SandboxComponents(this.policy, this.variables);
  final _SandboxPolicy policy;
  final Map<String, String> variables;
  Map _message(String id) {
    final row =
        ((policy.entityGateway?.fixtures['messages']
                as Map?)?[variables['channel.id']]
            as Map?)?[id];
    if (row is! Map || row['author_id'].toString() != variables['bot.id']) {
      throw StateError(
        'Component edits require an existing bot-authored message fixture.',
      );
    }
    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> readComponents(
    String messageId, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    _message(messageId);
    final gateway = policy.entityGateway;
    if (gateway == null) {
      throw StateError('Component edits require entity fixtures.');
    }
    final bot = _snowflake(variables['bot.id']);
    if (bot == null) {
      throw StateError('Component edits require a numeric bot ID.');
    }
    return DiscordBotComponentService(
      client: _SandboxPermissionGateway(gateway, bot),
      channelId: _snowflake(variables['channel.id']),
    ).readComponents(messageId, budget: budget);
  }

  @override
  Future<void> editComponents(
    String messageId,
    List<Map<String, dynamic>> rows, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    final row = _message(messageId);
    final raw = rows.map((row) => nativeComponentBuilder(row).build()).toList();
    row['components'] = raw;
    policy.effects.add({
      'type': 'editComponents',
      'message_id': messageId,
      'components': raw,
      'simulated': true,
    });
  }

  @override
  Future<void> sendModal(
    Map<String, dynamic> definition, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    if (!{'2', '3'}.contains(variables['interaction.type'])) {
      throw StateError(
        'A modal requires a command or component interaction fixture.',
      );
    }
    final raw = nativeModalBuilder(definition).build();
    policy.responses.add({
      'type': 'respondWithModal',
      'payload': raw,
      'api_modal': raw,
      'simulated': true,
    });
  }
}

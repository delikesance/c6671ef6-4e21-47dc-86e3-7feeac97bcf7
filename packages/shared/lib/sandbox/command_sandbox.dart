import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import '../actions/executors/http_executor.dart';
import '../actions/send_component_v2.dart';
import '../actions/respond_modal.dart';
import '../actions/send_webhook.dart';
import '../types/component.dart';
import '../actions/execution_policy.dart';
import '../actions/role_definition_actions.dart';
import '../actions/handler.dart';
import '../types/action.dart';
import '../utils/bdfd_compiler.dart';
import '../utils/bdfd_duration_parser.dart';
import '../utils/runtime_variables.dart';
import '../utils/message_runtime.dart';
import '../utils/global.dart';
import '../utils/template_resolver.dart';
import 'sandbox_store.dart';
import 'entity_fixture_gateway.dart';
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
  final diagnostics = <Map<String, dynamic>>[];
  final List<Action> actions;
  if (input['actions'] is List) {
    actions = (input['actions'] as List)
        .map((a) => Action.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();
  } else {
    final compiled = BdfdCompiler().compile(script);
    diagnostics.addAll(
      compiled.diagnostics.map(
        (d) => {
          'message': d.message,
          'severity': d.severity.name,
          'line': d.line,
          'column': d.column,
        },
      ),
    );
    if (compiled.hasErrors) {
      return {
        'success': false,
        'diagnostics': diagnostics,
        'error': 'Compilation failed',
      };
    }
    actions = compiled.actions;
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
  String? error;
  Map<String, String> results = {};
  final logs = <String>[];
  try {
    results = await handleActions(
      entityGateway ?? _NoDiscord(),
      null,
      actions: actions,
      store: store,
      botId: 'sandbox',
      variables: variables,
      fallbackGuildId: _snowflake(variables['guild.id']),
      fallbackChannelId: _snowflake(variables['channel.id']),
      resolveTemplate: (text) => resolveTemplatePlaceholders(text, variables),
      executionPolicy: policy,
      onLog: logs.add,
    );
    error = variables['error.message'];
    if (error == null &&
        entityGateway != null &&
        entityGateway.errors.isNotEmpty) {
      error = entityGateway.errors.join('; ');
    }
  } catch (e) {
    error = e.toString();
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
    'error': error,
    'diagnostics': diagnostics,
    'responses': policy.responses,
    'trace': policy.frames,
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
      if (data is Map) return data.map((k, v) => MapEntry(k, resolve(v)));
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
      final client = MockClient((request) async {
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
          if (expected.containsKey('body') &&
              expected['body'] != request.body) {
            throw StateError(
              'Simulated HTTP request body did not match fixture expectation',
            );
          }
          for (final entry in (expected['headers'] as Map? ?? {}).entries) {
            if (request.headers[entry.key.toString()] !=
                entry.value.toString()) {
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
        final body = fixture['body'] ?? '';
        return http.Response(
          body is String ? body : jsonEncode(body),
          status,
          headers: (fixture['headers'] as Map? ?? {}).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        );
      });
      try {
        return await executeHttpAction(
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
    if (pure.contains(action.type)) return false;
    throw StateError(
      'Sandbox action ${action.type.name} requires an explicit simulation fixture',
    );
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

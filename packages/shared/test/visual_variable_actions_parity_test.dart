import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/fake_role_gateway.dart';
import 'helpers/variables_test_helpers.dart';

/// Parity of the variable / JSON / HTTP / calculation blocks between the
/// historical executors (`ActionTranslator.none()`) and the native engine
/// (`bc_<type>`): the same actions run through both paths over equal stores
/// and the same local HTTP server; effects (store contents, ttl, requests),
/// `results`, final variables and error text are compared.

class _Spy extends ActionTranslator {
  _Spy() : super();
  int native = 0;
  @override
  BdfdActionProgram translate(
    List<Action> actions, {
    int firstIndex = 0,
    bool topLevelErrorModes = true,
  }) {
    native++;
    return super.translate(
      actions,
      firstIndex: firstIndex,
      topLevelErrorModes: topLevelErrorModes,
    );
  }
}

/// In-memory store that also records ttl writes and serves the value index.
class _Store extends MemoryBotDataStore {
  _Store({super.scopedDefinitions});
  final ttls = <String, String?>{};
  final log = <String>[];

  @override
  Future<void> setGlobalVariable(
    String botId,
    String key,
    dynamic value, {
    String? ttl,
  }) async {
    ttls['global/$key'] = ttl;
    log.add('setGlobal $key');
    await super.setGlobalVariable(botId, key, value, ttl: ttl);
  }

  @override
  Future<void> setScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
    dynamic value, {
    String? ttl,
  }) async {
    ttls['$scope/$contextId/$key'] = ttl;
    log.add('setScoped $scope/$contextId/$key');
    await super.setScopedVariable(
      botId,
      scope,
      contextId,
      key,
      value,
      ttl: ttl,
    );
  }

  @override
  Future<int?> getScopedVariableTtl(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async => null;

  @override
  Future<Map<String, dynamic>> queryScopedVariableIndex(
    String botId,
    String scope,
    String key, {
    int offset = 0,
    int limit = 25,
    bool descending = true,
  }) async {
    final entries =
        [
          for (final context in (scopedVariables[scope] ?? {}).entries)
            if (context.value.containsKey(key))
              {'contextId': context.key, 'value': context.value[key]},
        ]..sort(
          (a, b) =>
              a['contextId'].toString().compareTo(b['contextId'].toString()),
        );
    final ordered = descending ? entries.reversed.toList() : entries;
    final end = (offset + limit).clamp(0, ordered.length);
    return {
      'total': ordered.length,
      'items': ordered.sublist(offset.clamp(0, end), end),
    };
  }

  Map<String, Object?> get state => {
    'global': jsonDecode(jsonEncode(globalVariables)),
    'scoped': jsonDecode(jsonEncode(scopedVariables)),
    'definitions': jsonDecode(jsonEncode(scopedDefinitions)),
    'ttls': ttls,
    'log': log,
  };
}

class _Outcome {
  _Outcome(this.store, this.results, this.variables, this.error, this.native);
  final _Store store;
  final Map<String, String>? results;
  final Map<String, String> variables;
  final Object? error;
  final int native;
  Object? get errorText => error == null
      ? null
      : '${error.runtimeType}: ${error is CommandExecutionTimeout ? 'timeout' : error}';
}

late HttpServer _server;
final _requests = <Map<String, Object?>>[];
String get _base => 'http://127.0.0.1:${_server.port}';

Future<void> _startServer() async {
  _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  _server.listen((request) async {
    final body = await utf8.decoder.bind(request).join();
    _requests.add({
      'method': request.method,
      'path': request.uri.toString(),
      'contentType': request.headers.contentType?.mimeType,
      'x': request.headers.value('x-test'),
      'body': body,
    });
    if (request.uri.path == '/slow') {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    request.response.statusCode = request.uri.path == '/missing' ? 404 : 200;
    if (request.uri.path == '/text') {
      request.response.write('plain text');
    } else {
      request.response.write(
        jsonEncode({
          'name': 'sword',
          'items': [
            {'id': 1, 'tag': 'a'},
            {'id': 2, 'tag': 'b'},
          ],
          'method': request.method,
        }),
      );
    }
    await request.response.close();
  });
}

Action _a(
  BotCreatorActionType type,
  Map<String, dynamic> payload, {
  String? key,
  Map<String, String> error = const {},
  bool enabled = true,
}) =>
    Action(type: type, key: key, enabled: enabled, payload: payload)
      ..error.addAll(error);

Future<_Outcome> _execute(
  List<Action> actions, {
  required bool native,
  Map<String, String>? variables,
  void Function(_Store store)? setup,
  List<Map<String, dynamic>>? definitions,
  bool guild = true,
  bool throwOnError = false,
  Duration? limit,
  ActionExecutionPolicy? policy,
}) async {
  final store = _Store(scopedDefinitions: definitions);
  setup?.call(store);
  final values = <String, String>{
    'guild.id': '10',
    'user.id': '222',
    'channel.id': '30',
    'bot.id': 'bot',
    ...?variables,
  };
  final spy = _Spy();
  Map<String, String>? results;
  Object? error;
  try {
    results = await handleActions(
      FakeGateway(),
      null,
      actions: actions,
      store: store,
      botId: 'bot',
      variables: values,
      fallbackGuildId: guild ? Snowflake(10) : null,
      fallbackChannelId: Snowflake(30),
      resolveTemplate: (value) => resolveTemplatePlaceholders(value, values),
      throwOnError: throwOnError,
      executionPolicy: policy,
      executionBudget: limit == null
          ? null
          : CommandExecutionBudget(limit: limit),
      actionTranslator: native ? spy : const ActionTranslator.none(),
    );
  } catch (e) {
    error = e;
  }
  values.remove('execution.time');
  return _Outcome(store, results, values, error, spy.native);
}

/// Strips values that legitimately differ per run.
Object? _stable(Object? value) => value is Map
    ? {for (final e in value.entries) e.key: _stable(e.value)}
    : value;

Future<_Outcome> _parity(
  List<Action> actions, {
  Map<String, String>? variables,
  void Function(_Store store)? setup,
  List<Map<String, dynamic>>? definitions,
  bool guild = true,
  bool throwOnError = false,
  Duration? limit,
  ActionExecutionPolicy? policy,
  bool expectNative = true,
}) async {
  Future<_Outcome> run(bool native) async {
    _requests.clear();
    final outcome = await _execute(
      actions.map((a) => Action.fromJson(a.toJson())).toList(),
      native: native,
      variables: variables == null ? null : {...variables},
      setup: setup,
      definitions: definitions
          ?.map((d) => Map<String, dynamic>.from(d))
          .toList(),
      guild: guild,
      throwOnError: throwOnError,
      limit: limit,
      policy: policy,
    );
    outcome.requests = List.of(_requests);
    return outcome;
  }

  final historical = await run(false);
  final native = await run(true);
  // A timeout may be raised by the outer deadline before the failing action
  // records its bookkeeping: let both runs settle.
  if (limit != null) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  expect(historical.native, 0);
  if (expectNative) {
    expect(native.native, greaterThan(0), reason: 'must run natively');
  } else {
    expect(native.native, 0, reason: 'must stay historical');
  }
  expect(
    _stable(native.store.state),
    _stable(historical.store.state),
    reason: 'store effects',
  );
  expect(native.requests, historical.requests, reason: 'http requests');
  Map<String, String>? ports(Map<String, String>? m) => m?.map(
    (k, v) => MapEntry(k, v.replaceAll(RegExp(r'port = \d+'), 'port = N')),
  );
  expect(ports(native.results), ports(historical.results), reason: 'results');
  expect(
    ports(native.variables),
    ports(historical.variables),
    reason: 'variables',
  );
  expect(native.errorText, historical.errorText, reason: 'error');
  return native;
}

extension on _Outcome {
  static final _requestsOf = Expando<List<Map<String, Object?>>>();
  List<Map<String, Object?>> get requests => _requestsOf[this] ?? const [];
  set requests(List<Map<String, Object?>> value) => _requestsOf[this] = value;
}

const _t = BotCreatorActionType.setTemporaryVariable;
const _setScoped = BotCreatorActionType.setScopedVariable;
const _getScoped = BotCreatorActionType.getScopedVariable;
const _rmScoped = BotCreatorActionType.removeScopedVariable;
const _setGlobal = BotCreatorActionType.setGlobalVariable;
const _getGlobal = BotCreatorActionType.getGlobalVariable;
const _rmGlobal = BotCreatorActionType.removeGlobalVariable;

void main() {
  setUpAll(_startServer);
  tearDownAll(() => _server.close(force: true));

  group('routing', () {
    test('every migrated type is supported and has a hidden function', () {
      const translator = ActionTranslator();
      for (final type in [
        _t,
        _setScoped,
        _getScoped,
        _rmScoped,
        _setGlobal,
        _getGlobal,
        _rmGlobal,
        BotCreatorActionType.runtimeJsonBlock,
        BotCreatorActionType.httpRequest,
        BotCreatorActionType.calculate,
        BotCreatorActionType.randomChoice,
        BotCreatorActionType.appendArrayElement,
        BotCreatorActionType.removeArrayElement,
        BotCreatorActionType.queryArray,
        BotCreatorActionType.renameScopedVariable,
        BotCreatorActionType.listScopedVariableIndex,
      ]) {
        expect(
          translator.supports(Action(type: type, payload: const {})),
          isTrue,
          reason: '$type',
        );
        expect(bdfdVisualActionHandlers.containsKey(type), isTrue);
        expect(
          const ActionTranslator.none().supports(
            Action(type: type, payload: const {}),
          ),
          isFalse,
        );
      }
    });
  });

  group('setTemporaryVariable parity', () {
    test('stores text and exposes the result sub-fields', () async {
      final o = await _parity([
        _a(_t, {'key': 'name', 'value': 'Ada'}, key: 'tmp'),
      ]);
      expect(o.results, {'tmp': 'OK'});
      expect(o.variables['temp.name'], 'Ada');
      expect(o.variables['tmp.scope'], 'temp');
      expect(o.variables['__variables.tempNames'], '["name"]');
    });

    test('bc_ prefix, internal flag and raw key alias', () async {
      final o = await _parity([
        _a(_t, {'key': 'bc_hidden', 'value': '1', 'internal': true}),
        _a(_t, {'key': 'bc_shown', 'value': '2'}),
      ]);
      expect(o.variables['temp.hidden'], '1');
      expect(o.variables['temp.bc_shown'], '2');
    });

    test('typed values', () async {
      final o = await _parity([
        _a(_t, {'key': 'n', 'valueType': 'number', 'numberValue': '4.5'}),
        _a(_t, {'key': 'b', 'valueType': 'boolean', 'boolValue': 'TRUE'}),
        _a(_t, {'key': 'j', 'valueType': 'json', 'jsonValue': '{"a":[1]}'}),
        _a(_t, {'key': 'i', 'value': 7}),
      ]);
      expect(o.variables['temp.n'], '4.5');
      expect(o.variables['temp.b'], 'true');
      expect(o.variables['temp.j'], '{"a":[1]}');
      expect(o.variables['temp.i'], '7');
    });

    for (final entry in {
      'bad number': {'valueType': 'number', 'numberValue': 'x'},
      'bad bool': {'valueType': 'boolean', 'boolValue': 'maybe'},
      'empty json': {'valueType': 'json', 'jsonValue': ''},
      'invalid json': {'valueType': 'json', 'jsonValue': '{'},
      'empty key': {'key': '', 'value': 'x'},
    }.entries) {
      test('reports ${entry.key} identically', () async {
        final o = await _parity([
          _a(_t, {'key': 'k', ...entry.value}, key: 'bad'),
        ]);
        expect(o.error, isA<Exception>());
        expect(o.variables['error.command'], 'setTemporaryVariable');
        expect(o.results, isNull);
      });
    }

    test('resolves results of earlier actions and placeholders', () async {
      final o = await _parity(
        [
          _a(_t, {'key': 'a', 'value': '((who))'}, key: 'one'),
          _a(_t, {'key': 'b', 'value': '((one.value))-((action.one))'}),
        ],
        variables: {'who': 'Ada'},
      );
      expect(o.variables['temp.b'], 'Ada-OK');
    });

    test('continue / skip / jump modes', () async {
      final o = await _parity([
        _a(
          _t,
          {'key': 'k', 'valueType': 'number', 'numberValue': 'x'},
          key: 'bad',
          error: {'mode': 'continue'},
        ),
        _a(
          _t,
          {'key': 'k', 'valueType': 'number', 'numberValue': 'x'},
          key: 'bad2',
          error: {'mode': 'jump', 'jumpToActionId': 'end'},
        ),
        _a(_t, {'key': 'x', 'value': '1'}, key: 'skipped'),
        _a(_t, {'key': 'y', 'value': '1'}, key: 'end'),
      ]);
      expect(o.results!.keys, ['bad', 'bad2', 'end']);
      expect(o.results!['bad'], startsWith('Error: Exception: '));
    });
  });

  group('scoped variables parity', () {
    test(
      'set mirrors the value and records definition, ttl, results',
      () async {
        final o = await _parity([
          _a(_setScoped, {
            'scope': 'user',
            'key': 'coins',
            'value': '5',
            'ttl': '1h',
          }, key: 's'),
          _a(_getScoped, {'scope': 'user', 'key': 'coins'}, key: 'g'),
        ]);
        expect(o.results, {'s': 'OK', 'g': '5'});
        expect(o.variables['user.bc_coins'], '5');
        expect(o.variables['user[222].bc_coins'], '5');
        expect(o.variables['user.coins'], '5');
        expect(o.variables['s.persisted'], '5');
        expect(o.store.ttls['user/222/coins'], '1h');
      },
    );

    test('typed json / number / bool and explicit contextId', () async {
      final o = await _parity([
        _a(_setScoped, {
          'scope': 'guild',
          'key': 'cfg',
          'valueType': 'json',
          'jsonValue': '{"a":1}',
          'contextId': '99',
        }, key: 'a'),
        _a(_setScoped, {
          'scope': 'channel',
          'key': 'n',
          'valueType': 'number',
          'numberValue': '3',
        }, key: 'b'),
        _a(_setScoped, {
          'scope': 'message',
          'key': 'f',
          'valueType': 'bool',
          'boolValue': 'false',
          'contextId': '5',
        }, key: 'c'),
      ]);
      expect(o.variables['guild[99].bc_cfg'], '{"a":1}');
      expect(o.variables.containsKey('guild.bc_cfg'), isFalse);
      expect(o.variables['channel.bc_n'], '3');
    });

    test('guildMember context and its validation', () async {
      await _parity([
        _a(_setScoped, {'scope': 'guildMember', 'key': 'xp', 'value': '9'}),
        _a(_getScoped, {'scope': 'guildMember', 'key': 'xp'}, key: 'g'),
      ]);
      final o = await _parity([
        _a(_setScoped, {
          'scope': 'guildMember',
          'key': 'xp',
          'value': '9',
          'contextId': 'a:dm',
        }),
      ]);
      expect(
        o.error.toString(),
        'Exception: A server and user are required for guildMember variables',
      );
    });

    test('cooldown keys only touch the runtime cooldown', () async {
      await _parity([
        _a(_setScoped, {
          'scope': 'user',
          'key': 'cooldown_daily',
          'value': 'x',
          'ttl': '1m',
        }),
        _a(_rmScoped, {'scope': 'user', 'key': 'cooldown_daily'}, key: 'r'),
      ]);
    });

    test('get applies a configured default and storeAs', () async {
      final o = await _parity(
        [
          _a(_getScoped, {
            'scope': 'user',
            'key': 'lang',
            'storeAs': 'my.lang',
          }, key: 'g'),
        ],
        definitions: [
          {
            'scope': 'user',
            'key': 'lang',
            'defaultValue': 'fr',
            'valueType': 'string',
          },
        ],
      );
      expect(o.results, {'g': 'fr'});
      expect(o.variables['my.lang'], 'fr');
    });

    test('get of a missing value initialises it to empty', () async {
      final o = await _parity([
        _a(_getScoped, {'scope': 'channel', 'key': 'none'}, key: 'g'),
      ]);
      expect(o.results, {'g': ''});
    });

    test('remove deletes, or resets to the default', () async {
      final o = await _parity(
        [
          _a(_setScoped, {'scope': 'user', 'key': 'a', 'value': '1'}),
          _a(_rmScoped, {'scope': 'user', 'key': 'a'}, key: 'r1'),
          _a(_setScoped, {'scope': 'user', 'key': 'lang', 'value': 'en'}),
          _a(_rmScoped, {
            'scope': 'user',
            'key': 'lang',
            'resetToDefault': true,
          }, key: 'r2'),
        ],
        definitions: [
          {
            'scope': 'user',
            'key': 'lang',
            'defaultValue': 'fr',
            'valueType': 'string',
          },
        ],
      );
      expect(o.results!['r1'], 'REMOVED');
      expect(o.variables['user.bc_lang'], 'fr');
      expect(o.variables.containsKey('user.bc_a'), isFalse);
    });

    test('resetAllContexts walks the value index', () async {
      final o = await _parity(
        [
          _a(_rmScoped, {
            'scope': 'guildMember',
            'key': 'xp',
            'resetAllContexts': true,
            'resetToDefault': true,
            'resetGuildId': '10',
          }, key: 'r'),
        ],
        setup: (s) {
          s.scopedVariables['guildMember'] = {
            '10:1': {'xp': '5'},
            '10:2': {'xp': '6'},
            '11:3': {'xp': '7'},
          };
        },
        definitions: [
          {
            'scope': 'guildMember',
            'key': 'xp',
            'defaultValue': '0',
            'valueType': 'string',
          },
        ],
      );
      expect(o.results!['r'], 'RESET');
      expect(o.store.scopedVariables['guildMember']!['11:3']!['xp'], '7');
      expect(o.store.scopedVariables['guildMember']!['10:1']!['xp'], '0');
    });

    test('invalid reset and invalid scope fail identically', () async {
      final a = await _parity([
        _a(_rmScoped, {'scope': 'user', 'key': 'x', 'resetAllContexts': true}),
      ]);
      expect(a.error.toString(), 'Exception: Invalid user variable reset');
      for (final type in [_setScoped, _getScoped, _rmScoped]) {
        final b = await _parity([
          _a(type, {'scope': 'nope', 'key': 'x', 'value': '1'}),
        ]);
        expect(b.error.toString(), contains('must be one of'));
      }
    });

    test('an unresolvable context fails identically', () async {
      final o = await _parity(
        [
          _a(_getScoped, {'scope': 'user', 'key': 'x'}),
        ],
        variables: {'user.id': ''},
      );
      expect(
        o.error.toString(),
        'Exception: Unable to resolve context ID for scope "user"',
      );
    });

    test('rename moves the value and the runtime mirror', () async {
      final o = await _parity([
        _a(_setScoped, {'scope': 'user', 'key': 'old', 'value': '1'}),
        _a(BotCreatorActionType.renameScopedVariable, {
          'scope': 'user',
          'oldKey': 'old',
          'newKey': 'fresh',
        }, key: 'r'),
      ]);
      expect(o.results!['r'], 'RENAMED');
    });

    test('list index pages the values', () async {
      final o = await _parity(
        [
          _a(BotCreatorActionType.listScopedVariableIndex, {
            'scope': 'user',
            'key': 'coins',
            'limit': '2',
            'order': 'asc',
            'storeAs': 'board',
          }, key: 'l'),
        ],
        setup: (s) {
          s.scopedVariables['user'] = {
            '1': {'coins': '1'},
            '2': {'coins': '2'},
            '3': {'coins': '3'},
          };
        },
      );
      expect(o.variables['l.total'], '3');
      expect(o.variables['l.count'], '2');
      expect(o.variables['board'], isNotEmpty);
    });
  });

  group('global variables parity', () {
    test('set / get / remove with ttl, typing and mirrors', () async {
      final o = await _parity([
        _a(_setGlobal, {'key': 'motd', 'value': 'hi', 'ttl': '30s'}, key: 's'),
        _a(_getGlobal, {'key': 'motd', 'storeAs': 'copy'}, key: 'g'),
        _a(_setGlobal, {
          'key': 'n',
          'valueType': 'number',
          'numberValue': '12',
        }, key: 's2'),
        _a(_getGlobal, {'key': 'missing'}, key: 'g2'),
        _a(_rmGlobal, {'key': 'motd'}, key: 'r'),
      ]);
      expect(o.results, {
        's': 'OK',
        'g': 'hi',
        's2': 'OK',
        'g2': '',
        'r': 'REMOVED',
      });
      expect(o.variables['copy'], 'hi');
      expect(o.variables.containsKey('global.motd'), isFalse);
      expect(o.variables['global.n'], '12');
      expect(o.store.ttls['global/motd'], '30s');
      expect(o.store.globalVariables['n'], 12);
    });

    test('empty keys and invalid typed values fail identically', () async {
      for (final type in [_setGlobal, _getGlobal, _rmGlobal]) {
        final o = await _parity([
          _a(type, {'key': ' ', 'value': 'x'}),
        ]);
        expect(
          o.error.toString(),
          'Exception: key is required for ${type.name}',
        );
      }
      final o = await _parity([
        _a(_setGlobal, {
          'key': 'k',
          'valueType': 'number',
          'numberValue': 'abc',
        }),
      ]);
      expect(o.error.toString(), contains('numberValue is required'));
    });

    test('values come from earlier results through placeholders', () async {
      final o = await _parity([
        _a(_getGlobal, {'key': 'src'}, key: 'first'),
        _a(_setGlobal, {'key': 'dst', 'value': '((first))!'}),
      ], setup: (s) => s.globalVariables['src'] = 'v');
      expect(o.store.globalVariables['dst'], 'v!');
    });
  });

  group('array and query blocks parity', () {
    test('append and remove on a scoped variable', () async {
      final o = await _parity([
        _a(BotCreatorActionType.appendArrayElement, {
          'scope': 'user',
          'key': 'inv',
          'value': 'sword',
        }, key: 'a1'),
        _a(BotCreatorActionType.appendArrayElement, {
          'scope': 'user',
          'key': 'inv',
          'value': 'shield',
        }, key: 'a2'),
        _a(BotCreatorActionType.removeArrayElement, {
          'scope': 'user',
          'key': 'inv',
          'index': '0',
        }, key: 'r'),
      ]);
      expect(o.results!['r'], '["shield"]');
      expect(o.variables['r.removed'], 'sword');
      expect(o.variables['r.length'], '1');
    });

    test('append at a JSON path on a global variable', () async {
      final o = await _parity([
        _a(BotCreatorActionType.appendArrayElement, {
          'target': 'global',
          'key': 'doc',
          'path': r'$.list',
          'value': 'x',
        }, key: 'a'),
        _a(BotCreatorActionType.removeArrayElement, {
          'target': 'global',
          'key': 'doc',
          'path': r'$.list',
          'index': 'zz',
        }, key: 'bad'),
      ]);
      expect(
        o.error.toString(),
        'Exception: index is required for removeArrayElement',
      );
    });

    test('queryArray filters, sorts and pages', () async {
      final o = await _parity([
        _a(BotCreatorActionType.queryArray, {
          'input': '[{"n":"b","v":2},{"n":"a","v":1},{"n":"c","v":3}]',
          'filterTemplate': '{v}',
          'filterOperator': 'gt',
          'filterValue': '1',
          'sortTemplate': '{n}',
          'order': 'desc',
          'limit': '5',
          'storeAs': 'out',
        }, key: 'q'),
      ]);
      expect(o.variables['q.total'], '2');
      expect(o.variables['out'], contains('"c"'));
    });
  });

  group('randomChoice parity', () {
    test('a single choice is deterministic', () async {
      final o = await _parity([
        _a(BotCreatorActionType.randomChoice, {
          'choices': 'only',
          'variableName': 'pick',
        }, key: 'r'),
        _a(BotCreatorActionType.randomChoice, {
          'choices': '["solo"]',
        }, key: 'j'),
        _a(BotCreatorActionType.randomChoice, {'choices': ' ; '}, key: 'e'),
      ]);
      expect(o.results, {'r': 'only', 'j': 'solo', 'e': ''});
      expect(o.variables['pick'], 'only');
      expect(o.variables['random_choice'], '');
    });

    test('native pick is one of the choices', () async {
      final o = await _execute([
        _a(BotCreatorActionType.randomChoice, {'choices': 'a;b;c'}, key: 'r'),
      ], native: true);
      expect(['a', 'b', 'c'], contains(o.results!['r']));
      expect(o.native, greaterThan(0));
    });
  });

  group('runtimeJsonBlock parity', () {
    test('operations, read results and sub-results', () async {
      final o = await _parity(
        [
          _a(BotCreatorActionType.runtimeJsonBlock, {
            'source': '{"a":{"b":[1,2]}}',
            'operations': [
              {
                'op': 'set',
                'path': ['a', 'c'],
                'value': '((who))',
              },
              {
                'op': 'arrayAppend',
                'path': ['a', 'b'],
                'value': '3',
              },
              {
                'op': 'get',
                'path': ['a', 'b', '2'],
                'readIndex': 0,
              },
              {'op': 'bogus', 'path': []},
            ],
          }, key: 'j'),
          _a(BotCreatorActionType.runtimeJsonBlock, {
            'source': '((j))',
            'operations': [
              {'op': 'pretty', 'path': [], 'indent': '2', 'readIndex': 1},
            ],
          }, key: 'k'),
        ],
        variables: {'who': 'Ada'},
      );
      expect(o.variables['j'], contains('"c":"Ada"'));
      expect(o.results!.containsKey('j.json_0'), isTrue);
    });

    test('invalid source and missing operations', () async {
      await _parity([
        _a(BotCreatorActionType.runtimeJsonBlock, {
          'source': '{"a":1}',
        }, key: 'j'),
      ]);
      await _parity([
        _a(BotCreatorActionType.runtimeJsonBlock, {'source': '{bad'}, key: 'j'),
      ]);
    });
  });

  group('calculate parity', () {
    test('expressions and operations', () async {
      final o = await _parity(
        [
          _a(BotCreatorActionType.calculate, {'expression': '2+3*4'}, key: 'e'),
          _a(BotCreatorActionType.calculate, {
            'operation': 'divide',
            'operandA': '9',
            'operandB': '4',
          }, key: 'd'),
          _a(BotCreatorActionType.calculate, {
            'operation': 'abs',
            'operandA': '-3.5',
          }, key: 'abs'),
          _a(BotCreatorActionType.calculate, {
            'operation': 'negate',
            'operandA': '3',
          }, key: 'neg'),
          _a(BotCreatorActionType.calculate, {
            'operation': 'round',
            'operandA': '2.5',
          }, key: 'rnd'),
          _a(BotCreatorActionType.calculate, {
            'operation': 'pow',
            'operandA': '2',
            'operandB': '10',
          }, key: 'p'),
          _a(BotCreatorActionType.calculate, {
            'operation': 'add',
            'operandA': '((x))',
            'operandB': '1',
          }, key: 'x'),
        ],
        variables: {'x': '41'},
      );
      expect(o.results!['e'], '14');
      expect(o.error, isNull);
      expect(o.variables['e.result'], '14');
      expect(o.results!['x'], '42');
    });

    for (final entry in {
      'division by zero': {
        'operation': 'div',
        'operandA': '1',
        'operandB': '0',
      },
      'unknown operation': {
        'operation': 'zap',
        'operandA': '1',
        'operandB': '1',
      },
      'bad operand': {'operation': 'add', 'operandA': 'q', 'operandB': '1'},
      'bad expression': {'expression': '2+*'},
      'random range': {'operation': 'random', 'operandA': '5', 'operandB': '1'},
    }.entries) {
      test('${entry.key} fails with the same message', () async {
        final o = await _parity([
          _a(BotCreatorActionType.calculate, entry.value, key: 'c'),
        ]);
        expect(o.error, isA<Exception>());
        expect(o.variables['error.command'], 'calculate');
      });
    }

    test('random stays in range', () async {
      _requests.clear();
      final o = await _execute([
        _a(BotCreatorActionType.calculate, {
          'operation': 'random',
          'operandA': '3',
          'operandB': '5',
        }, key: 'r'),
        _a(BotCreatorActionType.calculate, {
          'operation': 'randomFloat',
          'operandA': '1',
          'operandB': '2',
        }, key: 'f'),
      ], native: true);
      expect(o.error, isNull);
      final r = int.parse(o.results!['r']!);
      expect(r, inInclusiveRange(3, 5));
      expect(double.parse(o.results!['f']!), inInclusiveRange(1, 2));
      expect(o.native, greaterThan(0));
    });
  });

  group('httpRequest parity', () {
    test('GET with headers and json extraction', () async {
      final o = await _parity(
        [
          _a(BotCreatorActionType.httpRequest, {
            'url': '$_base/item?q=((q))',
            'headers': {'X-Test': '((token))', ' ': 'ignored'},
            'extractJsonPath': r'$.items[1].tag',
            'saveBodyToGlobalVar': 'last_body',
            'saveStatusToGlobalVar': 'last_status',
          }, key: 'h'),
        ],
        variables: {'q': 'sword', 'token': 'abc'},
      );
      expect(o.results, {'h': 'b'});
      expect(o.variables['h.status'], '200');
      expect(o.variables['h.jsonPath'], 'b');
      expect(o.variables['http.jsonPath'], 'b');
      expect(o.variables['h.body'], contains('"sword"'));
      expect(o.store.globalVariables['last_status'], '200');
      expect(o.requests.single['x'], 'abc');
    });

    test('POST with a structured json body sets the content type', () async {
      final o = await _parity(
        [
          _a(BotCreatorActionType.httpRequest, {
            'url': '$_base/post',
            'method': 'post',
            'bodyJson': {
              'name': '((who))',
              'nested': {
                'list': ['((who))', 1, true],
              },
            },
          }, key: 'h'),
        ],
        variables: {'who': 'Ada'},
      );
      expect(o.requests.single['contentType'], 'application/json');
      expect(jsonDecode(o.requests.single['body'] as String), {
        'name': 'Ada',
        'nested': {
          'list': ['Ada', 1, true],
        },
      });
    });

    test('text body, other methods and non-json responses', () async {
      final o = await _parity(
        [
          _a(BotCreatorActionType.httpRequest, {
            'url': '$_base/text',
            'method': 'PUT',
            'bodyMode': 'text',
            'bodyText': 'hello ((who))',
            'extractJsonPath': r'$.x',
          }, key: 'h'),
          _a(BotCreatorActionType.httpRequest, {
            'url': '$_base/missing',
            'method': 'HEAD',
          }, key: 'm'),
          _a(BotCreatorActionType.httpRequest, {
            'url': '$_base/x',
            'method': 'bogus',
          }, key: 'u'),
        ],
        variables: {'who': 'Ada'},
      );
      expect(o.results!['h'], 'plain text');
      expect(o.variables['m.status'], '404');
    });

    test('missing url and invalid scheme fail identically', () async {
      final a = await _parity([
        _a(BotCreatorActionType.httpRequest, {'url': ' '}, key: 'h'),
      ]);
      expect(a.error.toString(), 'Exception: url is required for httpRequest');
      await _parity([
        _a(BotCreatorActionType.httpRequest, {'url': 'ftp://x/y'}, key: 'h'),
      ]);
    });

    test('an unreachable host is an action failure with error mode', () async {
      final o = await _parity([
        _a(
          BotCreatorActionType.httpRequest,
          {'url': 'http://127.0.0.1:1/'},
          key: 'h',
          error: {'mode': 'continue'},
        ),
        _a(_t, {'key': 'after', 'value': '1'}, key: 'ok'),
      ]);
      expect(o.results!['h'], startsWith('Error: '));
      expect(o.results!['ok'], 'OK');
    });

    test('the shared budget stops a slow request', () async {
      final o = await _parity([
        _a(BotCreatorActionType.httpRequest, {'url': '$_base/slow'}, key: 'h'),
      ], limit: const Duration(milliseconds: 40));
      expect(o.error, isA<CommandExecutionTimeout>());
    });
  });

  group('mixed lists and blocks', () {
    test(
      'natively routed actions share results with historical ones',
      () async {
        final o = await _parity([
          _a(_setGlobal, {'key': 'g', 'value': '3'}, key: 'a'),
          _a(BotCreatorActionType.calculate, {
            'expression': '((global.g))*2',
          }, key: 'b'),
          _a(BotCreatorActionType.log, {'message': 'x ((b))'}, key: 'l'),
          _a(_t, {'key': 'out', 'value': '((b))'}, key: 'c'),
        ]);
        expect(o.variables['temp.out'], '6');
        expect(o.results!['l'], 'LOGGED');
      },
    );

    test('inside an ifBlock the children keep their own result list', () async {
      final o = await _parity(
        [
          _a(BotCreatorActionType.ifBlock, {
            'variable': 'flag',
            'operator': 'equals',
            'value': 'yes',
            'thenActions': [
              _a(_setGlobal, {'key': 'g', 'value': '3'}, key: 'a').toJson(),
              _a(BotCreatorActionType.calculate, {
                'expression': '1+1',
              }, key: 'b').toJson(),
              _a(_t, {'key': 'out', 'value': '((b))'}, key: 'c').toJson(),
            ],
            'elseActions': [],
          }, key: 'gate'),
        ],
        variables: {'flag': 'yes'},
      );
      expect(o.results!['gate.a'], 'OK');
      expect(o.results!['gate.b'], '2');
      expect(o.variables['temp.out'], '2');
    });

    test('a failing child follows its nested error mode', () async {
      await _parity(
        [
          _a(BotCreatorActionType.ifBlock, {
            'variable': 'flag',
            'operator': 'equals',
            'value': 'yes',
            'thenActions': [
              _a(
                BotCreatorActionType.calculate,
                {'expression': '1+'},
                key: 'bad',
                error: {'mode': 'continue'},
              ).toJson(),
              _a(_setGlobal, {'key': 'g', 'value': '1'}, key: 'good').toJson(),
            ],
            'elseActions': [],
          }, key: 'gate'),
        ],
        variables: {'flag': 'yes'},
      );
    });

    test('protected executions ignore the error mode', () async {
      final o = await _parity([
        _a(_getGlobal, {'key': ''}, error: {'mode': 'continue'}),
      ], throwOnError: true);
      expect(o.error, isA<Exception>());
    });

    test('disabled actions are skipped', () async {
      final o = await _parity([
        _a(_setGlobal, {'key': 'off', 'value': '1'}, key: 'x', enabled: false),
        _a(_setGlobal, {'key': 'on', 'value': '1'}, key: 'y'),
      ]);
      expect(o.results, {'y': 'OK'});
    });

    test('numeric results become the last message like today', () async {
      final o = await _parity([
        _a(_getGlobal, {'key': 'n'}, key: 'g'),
      ], setup: (s) => s.globalVariables['n'] = '123456');
      expect(o.variables['lastSentMessageId'], '123456');
    });
  });
}

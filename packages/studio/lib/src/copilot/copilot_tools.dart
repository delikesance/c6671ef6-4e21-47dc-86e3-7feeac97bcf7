import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/studio_api.dart';
import '../commands/command_draft.dart';

/// Résultat d'un outil, au format que le serveur rejoue au modèle.
typedef ToolResult = Map<String, dynamic>;

ToolResult _ok(Object? value) => {
  'content': [
    {'type': 'text', 'text': jsonEncode(value)},
  ],
};

ToolResult _fail(String message) => {
  'isError': true,
  'content': [
    {'type': 'text', 'text': message},
  ],
};

/// Les outils du Copilot que le Studio exécute lui-même, par l'API du Manager.
///
/// Le serveur décide de l'offre d'outils à partir de la liste que le client
/// annonce (`tools`) : le Studio n'annonce que ce qu'il sait faire — commandes
/// et workflows VISUELS (blocs), variables, démarrage / arrêt du bot hébergé et
/// documentation. Pas de BDFD, de JavaScript ni de bac à sable local : le modèle
/// ne les propose donc jamais.
class CopilotTools {
  CopilotTools(this.api, {http.Client? docsClient})
    : _docs = docsClient ?? http.Client();

  final StudioApi api;
  final http.Client _docs;

  /// Outils exécutés par le SERVEUR après approbation (le client ne fait rien).
  static const serverSide = {
    'remote_list_bots',
    'remote_bot_status',
    'remote_start_bot',
    'remote_stop_bot',
  };

  static const _readTools = {
    'local_list_commands',
    'local_get_command',
    'local_list_workflows',
    'local_get_workflow',
    'docs_search',
    'docs_get',
    'docs_plan',
    'docs_manifest',
    'docs_actions',
    'docs_validate_actions',
    ...serverSide,
  };

  static const _mutatingTools = {
    'local_create_command',
    'local_update_command_execution',
    'local_create_workflow',
    'local_update_workflow',
    'local_set_variable',
    'remote_start_bot',
    'remote_stop_bot',
  };

  static const _docsNames = {
    'docs_search': 'search_docs',
    'docs_get': 'get_doc',
    'docs_plan': 'plan_solution',
    'docs_manifest': 'get_schema_manifest',
    'docs_actions': 'list_actions',
    'docs_validate_actions': 'validate_actions',
  };

  /// Noms annoncés au serveur.
  static List<String> get names =>
      ({..._readTools, ..._mutatingTools}.toList()..sort());

  static bool isMutating(String name) => _mutatingTools.contains(name);

  /// Exécute [name] avec [args] et rend un résultat, jamais une exception : une
  /// erreur devient un résultat `isError` que le modèle lit et corrige.
  Future<ToolResult> run(String name, Map<String, dynamic> args) async {
    try {
      if (_docsNames.containsKey(name)) return await _documentation(name, args);
      final botId = '${args['bot_id'] ?? ''}'.trim();
      switch (name) {
        case 'local_list_commands':
          return _ok(await _listCommands(botId, args));
        case 'local_get_command':
          return _ok(await _getCommand(botId, args));
        case 'local_create_command':
          return _ok(await _createCommand(botId, args));
        case 'local_update_command_execution':
          return _ok(await _updateCommandExecution(botId, args));
        case 'local_list_workflows':
          return _ok(await _listWorkflows(botId));
        case 'local_get_workflow':
          return _ok(await _getWorkflow(botId, '${args['name']}'));
        case 'local_create_workflow':
          return _ok(await _saveWorkflow(botId, args, create: true));
        case 'local_update_workflow':
          return _ok(await _saveWorkflow(botId, args, create: false));
        case 'local_set_variable':
          return _ok(await _setVariable(botId, args));
      }
      return _fail('Outil non disponible dans le Studio : $name.');
    } on StudioApiException catch (e) {
      return _fail(
        e.statusCode == 409
            ? 'Révision périmée : relisez la ressource et réessayez avec sa révision actuelle.'
            : e.message,
      );
    } on FormatException catch (e) {
      return _fail(e.message);
    } catch (e) {
      return _fail('$e');
    }
  }

  // ── Commandes ─────────────────────────────────────────────────────────────

  Future<Object?> _listCommands(String botId, Map<String, dynamic> args) async {
    final wanted = '${args['name'] ?? ''}'.trim().toLowerCase();
    final commands = await api.listCommands(botId);
    return {
      'commands': [
        for (final c in commands)
          if (wanted.isEmpty || c.name.toLowerCase() == wanted)
            {'id': c.id, 'name': c.name, 'trigger': c.trigger},
      ],
    };
  }

  Future<Object?> _getCommand(String botId, Map<String, dynamic> args) async {
    final detail = await api.getCommand(botId, '${args['command_id']}');
    final raw = Map<String, dynamic>.from(detail.raw);
    if (args['view'] == 'settings' && raw['data'] is Map) {
      final data = Map<String, dynamic>.from(raw['data'] as Map)
        ..remove('actions')
        ..remove('script');
      raw['data'] = data;
    }
    return {'command': raw, 'revision': detail.revision};
  }

  List<Map<String, dynamic>> _actions(Object? json) {
    final decoded = json is String ? jsonDecode(json) : json;
    if (decoded is! List) {
      throw const FormatException('actions_json doit être un tableau JSON.');
    }
    final out = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is! Map || '${item['type'] ?? ''}'.isEmpty) {
        throw const FormatException(
          'Chaque bloc doit avoir un "type" et un "payload".',
        );
      }
      out.add({
        'enabled': true,
        ...Map<String, dynamic>.from(item),
        'payload': item['payload'] is Map
            ? item['payload']
            : <String, dynamic>{},
      });
    }
    if (out.length > 80) throw const FormatException('80 blocs au maximum.');
    return out;
  }

  void _requireVisual(Map<String, dynamic> args) {
    final mode = '${args['execution_mode'] ?? 'workflow'}';
    if (mode != 'workflow') {
      throw const FormatException(
        'Le Studio ne crée que des commandes et workflows visuels (execution_mode workflow).',
      );
    }
  }

  Future<Object?> _createCommand(
    String botId,
    Map<String, dynamic> args,
  ) async {
    _requireVisual(args);
    final draft = CommandDraft.blank(
      name: '${args['name'] ?? ''}'.trim(),
      description: '${args['description'] ?? ''}'.trim(),
    );
    final problem = draft.validate();
    // Retour destiné au modèle : toujours en français, comme les autres outils.
    if (problem != null) throw FormatException(problem.inLanguage('fr'));
    final raw = draft.toRaw();
    final data = Map<String, dynamic>.from(raw['data'] as Map);
    data['actions'] = _actions(args['actions_json'] ?? '[]');
    if (args['options'] is List) data['options'] = args['options'];
    raw['data'] = data;
    final revision = await api.saveCommand(botId, '${raw['id']}', raw);
    return {'command_id': raw['id'], 'revision': revision, 'saved': true};
  }

  Future<Object?> _updateCommandExecution(
    String botId,
    Map<String, dynamic> args,
  ) async {
    _requireVisual(args);
    final id = '${args['command_id']}';
    final detail = await api.getCommand(botId, id);
    final raw = Map<String, dynamic>.from(detail.raw);
    final data = Map<String, dynamic>.from((raw['data'] as Map?) ?? {});
    data['actions'] = _actions(args['actions_json'] ?? '[]');
    data['executionMode'] = 'workflow';
    raw['data'] = data;
    final revision = await api.saveCommand(
      botId,
      id,
      raw,
      revision: '${args['expected_revision'] ?? ''}',
    );
    return {'command_id': id, 'revision': revision, 'saved': true};
  }

  // ── Workflows ─────────────────────────────────────────────────────────────

  Future<Object?> _listWorkflows(String botId) async {
    final items = await api.listWorkflows(botId);
    return {
      'workflows': [
        for (final w in items)
          {
            'name': w.name,
            'workflow_type': w.type,
            'execution_mode': w.executionMode,
            'action_count': w.actionCount,
          },
      ],
    };
  }

  Future<Object?> _getWorkflow(String botId, String name) async {
    final detail = await api.getWorkflow(botId, name);
    return {'workflow': detail.raw, 'revision': detail.revision};
  }

  Future<Object?> _saveWorkflow(
    String botId,
    Map<String, dynamic> args, {
    required bool create,
  }) async {
    _requireVisual(args);
    final name = '${args['name'] ?? ''}'.trim();
    if (name.isEmpty) throw const FormatException('Le nom est requis.');
    Map<String, dynamic> raw;
    if (create) {
      raw = {
        'name': name,
        'workflowType': args['workflow_type'] ?? 'general',
        'executionMode': 'workflow',
        'entryPoint': args['entry_point'] ?? 'main',
        'arguments': <dynamic>[],
        'actions': <dynamic>[],
      };
    } else {
      raw = Map<String, dynamic>.from((await api.getWorkflow(botId, name)).raw);
      if (args['workflow_type'] != null) {
        raw['workflowType'] = args['workflow_type'];
      }
      if (args['entry_point'] != null) raw['entryPoint'] = args['entry_point'];
    }
    if (args['actions'] != null) raw['actions'] = _actions(args['actions']);
    if (raw['workflowType'] == 'event' && args['event_trigger'] is Map) {
      raw['eventTrigger'] = args['event_trigger'];
    }
    raw['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    final bot = (await api.listBots()).where((b) => b.id == botId).firstOrNull;
    await api.saveWorkflow(botId, bot?.name ?? '', raw);
    return {'workflow': name, 'saved': true};
  }

  // ── Variables ─────────────────────────────────────────────────────────────

  Future<Object?> _setVariable(String botId, Map<String, dynamic> args) async {
    final key = '${args['key'] ?? ''}'.trim();
    if (key.isEmpty) throw const FormatException('La clé est requise.');
    final scope = '${args['scope'] ?? 'global'}';
    if (scope == 'global') {
      await api.setGlobalVariable(botId, key, args['value']);
    } else {
      await api.setScopedDefinition(
        botId,
        key: key,
        scope: scope,
        defaultValue: args['value'],
      );
    }
    return {'key': key, 'scope': scope, 'saved': true};
  }

  // ── Documentation (serveur MCP public) ────────────────────────────────────

  static final _docsUrl = Uri.parse('https://bot-creator.fr/api/mcp');
  String? _docsSession;
  bool _docsReady = false;
  int _rpcId = 0;

  Future<Map<String, dynamic>> _rpc(
    String method,
    Map<String, dynamic>? params, {
    bool notify = false,
  }) async {
    final id = notify ? null : ++_rpcId;
    final response = await _docs
        .post(
          _docsUrl,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json, text/event-stream',
            'mcp-session-id': ?_docsSession,
          },
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': ?id,
            'method': method,
            'params': ?params,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 400) {
      throw StateError('Documentation indisponible (${response.statusCode}).');
    }
    _docsSession = response.headers['mcp-session-id'] ?? _docsSession;
    if (notify) return const {};
    var body = response.body;
    if ((response.headers['content-type'] ?? '').contains('event-stream')) {
      final data = body
          .split('\n')
          .where((l) => l.startsWith('data:'))
          .map((l) => l.substring(5).trim())
          .where((l) => l.isNotEmpty)
          .join('\n');
      body = data;
    }
    final envelope = jsonDecode(body);
    if (envelope is! Map || envelope['error'] != null) {
      throw StateError('Réponse de documentation invalide.');
    }
    return Map<String, dynamic>.from((envelope['result'] as Map?) ?? {});
  }

  Future<ToolResult> _documentation(
    String name,
    Map<String, dynamic> args,
  ) async {
    try {
      if (!_docsReady) {
        await _rpc('initialize', {
          'protocolVersion': '2025-11-25',
          'capabilities': {},
          'clientInfo': {'name': 'bot-creator-studio', 'version': '1.0'},
        });
        await _rpc('notifications/initialized', null, notify: true);
        _docsReady = true;
      }
      return await _rpc('tools/call', {
        'name': _docsNames[name],
        'arguments': args,
      });
    } catch (e) {
      // Le navigateur peut refuser l'appel (CORS) : le modèle continue sans.
      return _fail(
        'La documentation officielle est indisponible depuis le Studio ($e). '
        'Poursuivez avec vos connaissances des blocs et dites-le à l\'utilisateur.',
      );
    }
  }
}

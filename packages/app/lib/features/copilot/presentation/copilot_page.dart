import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/copilot/logic/copilot_mcp.dart';
import 'package:bot_creator/features/subscriptions/presentation/ai_credits_page.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CopilotPage extends StatefulWidget {
  const CopilotPage({super.key, this.api});
  final MainApiClient? api;
  @override
  State<CopilotPage> createState() => _CopilotPageState();
}

class _CopilotPageState extends State<CopilotPage> {
  final _prompt = TextEditingController();
  final _messages = <Map<String, dynamic>>[];
  MainApiClient? _api;
  CopilotMcp? _mcp;
  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _pending;
  String? _error;
  bool _busy = false;
  bool _ready = false;
  Future<void> _approvalQueue = Future.value();
  String _text(String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _prompt.dispose();
    unawaited(_mcp?.close() ?? Future.value());
    super.dispose();
  }

  Future<void> _initialize() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _mcp?.close();
      _api = widget.api;
      if (_api == null) {
        final settings = await MainApiSettingsStore.loadConfig();
        final session = await MainApiSettingsStore.loadSession();
        if (!settings.isConfigured || session == null || session.isExpired) {
          throw StateError('Sign in to use the copilot');
        }
        _api = MainApiClient(
          baseUrl: settings.baseUrl,
          accessToken: session.accessToken,
        );
      }
      final bridge = CopilotMcp(_api!, approve: _approve);
      _mcp = bridge;
      await bridge.initialize();
      final server = await _api!.getCopilotTools();
      final supported = {
        for (final t in (server['tools'] as List).whereType<Map>())
          t['name']: t,
      };
      bridge.tools.removeWhere(
        (t) =>
            supported[t['name']] == null ||
            supported[t['name']]!['mutating'] != t['mutating'] ||
            HashUtil.calculateHash(supported[t['name']]!['inputSchema']) !=
                HashUtil.calculateHash(t['inputSchema']),
      );
      _wallet = await _api!.getAIWallet();
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = _describe(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(Object error) {
    if (error is MainApiClientException) {
      if (error.statusCode == 402) {
        return _text(
          'Solde insuffisant pour réserver les tokens de cette demande et de son contexte.',
          'Insufficient tokens for this request and its context.',
        );
      }
      if (error.statusCode == 503) {
        return _text(
          'Le copilote n’est pas encore activé sur le Manager.',
          'The copilot is not enabled on the Manager yet.',
        );
      }
      if (error.statusCode == 409) {
        return _text(
          'Demande déjà en cours. Réessayez pour récupérer son résultat.',
          'Request already in progress. Retry to recover its result.',
        );
      }
      if (error.statusCode == 401) {
        return _text(
          'Connectez-vous pour utiliser vos tokens IA.',
          'Sign in to use your AI tokens.',
        );
      }
    }
    return _text(
      'Copilote indisponible. Réessayez ou vérifiez votre connexion et votre compte.',
      'Copilot unavailable. Retry or check your connection and account.',
    );
  }

  Future<bool> _approve(String name, Map<String, dynamic> args) async {
    final answer = Completer<bool>();
    _approvalQueue = _approvalQueue.then((_) async {
      if (!mounted) {
        answer.complete(false);
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            _text('Valider l’action du copilote', 'Approve copilot action'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.startsWith('local_')
                      ? _text(
                          'Cette action concerne ce poste.',
                          'This action affects this device.',
                        )
                      : _text(
                          'Cette action concerne le bot distant sur le Manager.',
                          'This action affects the remote bot on the Manager.',
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  _actionLabel(name),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Bot : ${args['bot_id'] ?? ''}'),
                if (args['name'] != null) Text('/${args['name']}'),
                if (args['script'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _text('Nouvelle exécution proposée', 'Proposed execution'),
                  ),
                  SelectableText(args['script'] as String),
                ],
                if (name == 'local_update_command_execution')
                  Text(
                    _text(
                      'L’enregistrement déclenche la synchronisation habituelle du runner associé.',
                      'Saving triggers the usual sync of the associated runner.',
                    ),
                  ),
                ExpansionTile(
                  title: Text(_text('Détails de l’action', 'Action details')),
                  children: [
                    SelectableText(
                      '$name\n${const JsonEncoder.withIndent('  ').convert(args)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_text('Annuler', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_text('Exécuter', 'Execute')),
            ),
          ],
        ),
      );
      answer.complete(confirmed == true);
    });
    return answer.future;
  }

  String _actionLabel(String name) => switch (name) {
    'remote_start_bot' => _text(
      'Démarrer le bot sur le Manager',
      'Start the bot on the Manager',
    ),
    'remote_stop_bot' => _text(
      'Arrêter le bot sur le Manager',
      'Stop the bot on the Manager',
    ),
    'local_start_bot' => _text(
      'Démarrer le bot sur cet appareil',
      'Start the bot on this device',
    ),
    'local_stop_bot' => _text(
      'Arrêter le bot sur cet appareil',
      'Stop the bot on this device',
    ),
    'local_create_command' => _text(
      'Créer une commande Discord et ses blocs',
      'Create a Discord command and its blocks',
    ),
    'local_update_command_execution' => _text(
      'Remplacer les blocs d’exécution de la commande',
      'Replace the command’s execution blocks',
    ),
    _ => name,
  };

  Future<void> _send() async {
    if (_busy || !_ready || _prompt.text.trim().isEmpty || _pending != null) {
      return;
    }
    setState(() {
      _messages.add({'role': 'user', 'content': _prompt.text.trim()});
      _prompt.clear();
    });
    await _run();
  }

  Future<void> _run() async {
    if (_busy || _api == null || _mcp == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      for (var round = 0; round < 8; round++) {
        if (!mounted) return;
        _pending ??= {
          'idempotency_key': const Uuid().v4(),
          'messages': jsonDecode(jsonEncode(_messages)),
          'tools': _mcp!.tools.map((t) => t['name']).toList(),
        };
        final reply = await _api!.copilotReply(_pending!);
        final responseKey = _pending!['idempotency_key'] as String;
        final message = Map<String, dynamic>.from(reply['message'] as Map);
        _pending = null;
        if (!mounted) return;
        setState(() => _messages.add(message));
        try {
          _wallet = await _api!.getAIWallet();
        } catch (_) {
          /* A wallet refresh must not abandon pending tool calls. */
        }
        final calls = message['tool_calls'] as List? ?? [];
        if (calls.isEmpty) return;
        for (final raw in calls) {
          final call = Map<String, dynamic>.from(raw as Map);
          final function = Map<String, dynamic>.from(call['function'] as Map);
          Map<String, dynamic> result;
          try {
            result = await _mcp!.call(
              function['name'] as String,
              Map<String, dynamic>.from(
                jsonDecode(function['arguments'] as String) as Map,
              ),
              callID: '$responseKey:${call['id']}',
            );
          } catch (_) {
            result = {
              'isError': true,
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Action failed; no success is confirmed. Check runtime and permissions in the application.',
                },
              ],
            };
          }
          if (!mounted) return;
          // Bound the next prompt; full MCP results remain available via the bridge.
          final encoded = jsonEncode(result);
          final encodedBytes = utf8.encode(encoded);
          setState(
            () => _messages.add({
              'role': 'tool',
              'tool_call_id': call['id'],
              'content': encodedBytes.length <= 24000
                  ? encoded
                  : '${utf8.decode(encodedBytes.sublist(0, 24000), allowMalformed: true)}\n[truncated]',
            }),
          );
        }
      }
      if (mounted) {
        setState(
          () => _error = _text(
            'La limite de 8 étapes est atteinte. Envoyez une nouvelle demande pour continuer.',
            'The 8-step limit was reached. Send another request to continue.',
          ),
        );
      }
    } catch (error) {
      if (error is MainApiClientException && error.statusCode != 409) {
        _pending = null;
      }
      if (mounted) setState(() => _error = _describe(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connection() async {
    await _mcp!.startServer();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_text('Connexion MCP locale', 'Local MCP connection')),
        content: SingleChildScrollView(
          child: SelectableText(
            '${_mcp!.endpoint}\n\nAuthorization: Bearer ${_mcp!.bearer}\n\n${_text('Disponible tant que cet écran reste ouvert. Les actions demandent toujours une validation ici.', 'Available while this screen stays open. Actions always require approval here.')}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_text('Fermer', 'Close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_text('Copilote IA', 'AI copilot')),
      actions: [
        IconButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _messages.clear();
                  _pending = null;
                  _error = null;
                }),
          tooltip: _text('Nouvelle conversation', 'New conversation'),
          icon: const Icon(Icons.add_comment_outlined),
        ),
        if (_ready &&
            (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
          IconButton(
            onPressed: _connection,
            tooltip: 'MCP',
            icon: const Icon(Icons.hub_outlined),
          ),
        if (Platform.isAndroid || Platform.isIOS)
          IconButton(
            onPressed: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AICreditsPage(),
                  ),
                ).then((_) async {
                  if (_api != null) {
                    final wallet = await _api!.getAIWallet();
                    if (mounted) setState(() => _wallet = wallet);
                  }
                }),
            tooltip: _text('Tokens et roulette', 'Tokens and roulette'),
            icon: const Icon(Icons.token),
          ),
      ],
    ),
    body: Column(
      children: [
        if (_wallet != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${_wallet!['available'] ?? _wallet!['balance']} ${_text('tokens disponibles · entrée et sortie facturées · actions soumises à validation', 'tokens available · input and output are billed · actions require approval')}',
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_messages.isEmpty)
                Text(
                  _text(
                    'Demandez de l’aide sur vos commandes ou demandez de démarrer/arrêter un bot. Précisez « sur ce poste » ou « sur le Manager ».',
                    'Ask for help with commands or to start/stop a bot. Specify “on this device” or “on the Manager”.',
                  ),
                ),
              for (final m in _messages)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['role'] as String,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        SelectableText((m['content'] ?? '').toString()),
                        if (m['tool_calls'] is List)
                          for (final call in m['tool_calls'] as List)
                            Text('→ ${(call as Map)['function']['name']}'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
        if (_busy) const LinearProgressIndicator(),
        if (_pending != null && !_busy)
          TextButton(
            onPressed: _run,
            child: Text(_text('Récupérer la demande', 'Recover request')),
          ),
        if (_error != null && _ready && _pending == null && !_busy)
          TextButton(
            onPressed: _run,
            child: Text(_text('Réessayer la demande', 'Retry request')),
          ),
        if (!_ready && !_busy)
          TextButton(
            onPressed: _initialize,
            child: Text(_text('Se connecter / réessayer', 'Sign in / retry')),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prompt,
                    enabled: _ready && !_busy && _pending == null,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _text('Votre demande…', 'Your request…'),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  onPressed: _ready && !_busy && _pending == null
                      ? _send
                      : null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

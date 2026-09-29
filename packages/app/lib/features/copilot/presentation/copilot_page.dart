import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/copilot/logic/copilot_mcp.dart';
import 'package:bot_creator/features/subscriptions/presentation/ai_credits_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class CopilotPage extends StatefulWidget {
  const CopilotPage({
    super.key,
    this.api,
    this.initialConversationId,
    this.botId,
    this.botName,
    this.location = 'local',
  });
  final MainApiClient? api;
  final String? botId, botName, initialConversationId;
  final String location;
  @override
  State<CopilotPage> createState() => _CopilotPageState();
}

class _CopilotPageState extends State<CopilotPage> {
  final _prompt = TextEditingController(),
      _search = TextEditingController(),
      _botFilter = TextEditingController();
  final _scroll = ScrollController();
  MainApiClient? _api;
  CopilotMcp? _mcp;
  Map<String, dynamic>? _chat, _wallet, _pending;
  List<Map<String, dynamic>> _history = [];
  final Map<String, String> _botNames = {};
  Future<void> _draftQueue = Future.value();
  bool _busy = false, _ready = false, _archives = false, _loading = true;
  bool _historyMore = false, _hasPrompt = false;
  String? _error;
  String _partial = '';
  int _cursor = 0, _viewEpoch = 0;
  String? _requestKey;
  bool _streamDone = false;
  String _t(String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  String get _id => _chat!['id'] as String;
  List<Map<String, dynamic>> get _actions => (_chat?['actions'] as List? ?? [])
      .map((a) => Map<String, dynamic>.from(a as Map))
      .toList();
  List<Map<String, dynamic>> get _messages =>
      (_chat?['messages'] as List? ?? [])
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList();
  String get _draftKey =>
      'ai-draft:${_api?.baseUrl}:${_api?.draftIdentity}:${_chat?['id'] ?? widget.botId ?? 'global'}';
  @override
  void initState() {
    super.initState();
    _prompt.addListener(_promptChanged);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _viewEpoch++;
    _prompt.removeListener(_promptChanged);
    _prompt.dispose();
    _scroll.dispose();
    _search.dispose();
    _botFilter.dispose();
    unawaited(_mcp?.close() ?? Future.value());
    super.dispose();
  }

  void _scrollTail({bool force = false}) {
    if (!force && _scroll.hasClients && _scroll.position.extentAfter > 180) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _promptChanged() {
    unawaited(_saveDraft());
    final hasText = _prompt.text.trim().isNotEmpty;
    if (mounted && hasText != _hasPrompt) setState(() => _hasPrompt = hasText);
  }

  Future<void> _saveDraft() {
    final key = _draftKey, value = _prompt.text;
    return _draftQueue = _draftQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (value.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    });
  }

  Future<void> _restoreDraft() async {
    final key = _draftKey;
    final prefs = await SharedPreferences.getInstance();
    if (mounted && key == _draftKey) {
      _prompt.text = prefs.getString(key) ?? '';
    }
  }

  Future<void> _initialize() async {
    try {
      _api = widget.api;
      if (_api == null) {
        final config = await MainApiSettingsStore.loadConfig(),
            session = await MainApiSettingsStore.loadSession();
        if (!config.isConfigured || session == null || session.isExpired) {
          throw const MainApiClientException('Sign in', statusCode: 401);
        }
        _api = MainApiClient(
          baseUrl: config.baseUrl,
          accessToken: session.accessToken,
        );
      }
      await _bridge(widget.botId);
      _wallet = await _api!.getAIWallet();
      await _loadHistory();
      if (widget.botId == null) {
        try {
          for (final b in await _api!.listBots()) {
            final id = (b['bot_id'] ?? '').toString();
            if (id.isNotEmpty) {
              _botNames[id] = (b['bot_name'] ?? id).toString();
            }
          }
        } catch (_) {}
      }
      await _restoreDraft();
      if (mounted) {
        setState(() {
          _ready = true;
          _loading = false;
        });
      }
      if (widget.initialConversationId != null) {
        await _open(widget.initialConversationId!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = _describe(e));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _bridge(String? bot) async {
    await _mcp?.close();
    final bridge = CopilotMcp(
      _api!,
      botId: bot,
      approve: (name, args) async {
        if (!mounted || _busy) return false;
        return _approve({
          'call': {
            'function': {'name': name, 'arguments': jsonEncode(args)},
          },
        });
      },
    );
    await bridge.initialize();
    if (bot?.startsWith('container:') == true) {
      bridge.tools.removeWhere(
        (t) => (t['name'] as String).startsWith('local_'),
      );
    }
    final server = await _api!.getCopilotTools();
    final supported = {
      for (final t in (server['tools'] as List).whereType<Map>()) t['name']: t,
    };
    bridge.tools.removeWhere(
      (t) =>
          supported[t['name']] == null ||
          supported[t['name']]!['mutating'] != t['mutating'] ||
          HashUtil.calculateHash(supported[t['name']]!['inputSchema']) !=
              HashUtil.calculateHash(t['inputSchema']),
    );
    _mcp = bridge;
  }

  String _describe(Object e) {
    if (e is MainApiClientException) {
      switch (e.code) {
        case 'ai_tool_round_limit':
          return _t(
            'La limite de huit étapes IA est atteinte. Envoyez une nouvelle instruction pour continuer.',
            'The eight-step AI limit was reached. Send a new instruction to continue.',
          );
        case 'ai_context_limit':
          return _t(
            'Contexte trop long. Continuez dans une nouvelle discussion avec un résumé.',
            'Context too long. Continue in a new conversation with a summary.',
          );
        case 'ai_spending_blocked':
          return _t(
            'Les dépenses IA sont bloquées sur ce compte.',
            'AI spending is blocked for this account.',
          );
        case 'ai_revision_conflict':
          return _t(
            'La discussion a changé sur un autre appareil. Actualisez-la.',
            'The conversation changed on another device. Refresh it.',
          );
        case 'ai_action_already_claimed':
          return _t(
            'Une action attend une validation ou sa résolution.',
            'An action needs approval or resolution.',
          );
      }
      if (e.statusCode == 402) {
        return _t(
          'Solde insuffisant pour réserver la demande et son contexte.',
          'Insufficient balance to reserve this request and its context.',
        );
      }
      if (e.statusCode == 401) {
        return _t(
          'Connectez-vous pour utiliser le copilote.',
          'Sign in to use copilot.',
        );
      }
      if (e.statusCode == 404) {
        return _t(
          'Discussion ou bot inaccessible.',
          'Conversation or bot is inaccessible.',
        );
      }
      if (e.statusCode == 503) {
        return _t(
          'Le copilote est indisponible sur le Manager.',
          'Copilot is unavailable on the Manager.',
        );
      }
    }
    return _t(
      'La demande n’a pas abouti. Actualisez pour récupérer son état.',
      'The request did not complete. Refresh to recover its status.',
    );
  }

  Future<void> _loadHistory({bool more = false}) async {
    final d = await _api!.listAIConversations(
      botId:
          widget.botId ??
          (_botFilter.text.trim().isEmpty ? null : _botFilter.text.trim()),
      query: _search.text,
      archived: _archives,
      offset: more ? _history.length : 0,
    );
    if (mounted) {
      setState(() {
        final rows = (d['conversations'] as List)
            .map((c) => Map<String, dynamic>.from(c as Map))
            .toList();
        _history = more ? [..._history, ...rows] : rows;
        _historyMore = d['has_more'] == true;
      });
    }
  }

  Future<void> _open(String id) async {
    if (_busy) {
      return;
    }
    await _saveDraft();
    final c = await _api!.getAIConversation(id);
    if (!mounted) {
      return;
    }
    _viewEpoch++;
    setState(() {
      _chat = c;
      _partial = '';
      _error = c['last_request_status'] == 'failed'
          ? _describe(
              MainApiClientException(
                'Generation failed',
                code: c['last_error_code'] as String?,
              ),
            )
          : null;
      _pending = null;
      _cursor = 0;
      _requestKey = (c['active_key'] as String?)?.isEmpty == false
          ? c['active_key'] as String
          : null;
    });
    await _bridge(
      (c['bot_id'] as String?)?.isEmpty == false ? c['bot_id'] as String : null,
    );
    await _restoreDraft();
    _scrollTail(force: true);
    if (_requestKey != null) {
      await _follow();
    }
  }

  Future<void> _new() async {
    if (_busy) {
      return;
    }
    await _saveDraft();
    _viewEpoch++;
    setState(() {
      _chat = null;
      _pending = null;
      _requestKey = null;
      _partial = '';
      _error = null;
    });
    await _bridge(widget.botId);
    await _restoreDraft();
  }

  Future<void> _refresh() async {
    if (!_ready) {
      await _initialize();
      return;
    }
    try {
      if (_chat != null) {
        final c = await _api!.getAIConversation(_id);
        if (!mounted) {
          return;
        }
        setState(() => _chat = c);
        final key = c['active_key'] as String?;
        if (!_busy && key != null && key.isNotEmpty) {
          _requestKey = key;
          _cursor = 0;
          _partial = '';
          await _follow();
        }
      }
      _wallet = await _api!.getAIWallet();
      await _loadHistory();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = _describe(e));
      }
    }
  }

  Future<void> _send([String? toolContinuation]) async {
    if (_busy || !_ready) {
      return;
    }
    final prompt = toolContinuation ?? _prompt.text.trim();
    if (prompt.isEmpty && toolContinuation == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_chat == null) {
        final oldKey = _draftKey;
        _chat = await _api!.createAIConversation(
          botId: widget.botId,
          location: widget.botId == null ? 'global' : widget.location,
          title: prompt.length > 60 ? prompt.substring(0, 60) : prompt,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(oldKey);
      }
      _pending ??= {
        'idempotency_key': const Uuid().v4(),
        'revision': _chat!['revision'],
        'prompt': prompt,
        'tools': _mcp!.tools.map((t) => t['name']).toList(),
      };
      _requestKey = _pending!['idempotency_key'] as String;
      await _api!.startAITurn(_id, _pending!);
      _pending = null;
      _prompt.clear();
      _partial = '';
      _cursor = 0;
      _chat = await _api!.getAIConversation(_id);
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      await _follow();
      await _loadHistory();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _describe(e);
        });
      }
    }
  }

  Future<void> _follow() async {
    if (_requestKey == null || _chat == null || _busy) {
      return;
    }
    final epoch = _viewEpoch;
    setState(() => _busy = true);
    _streamDone = false;
    try {
      await for (final event in _api!.aiEvents(
        _id,
        _requestKey!,
        after: _cursor,
      )) {
        if (!mounted || epoch != _viewEpoch) {
          return;
        }
        _cursor = event['id'] as int;
        final payload = event['payload'] as Map;
        switch (event['kind']) {
          case 'delta':
            _scrollTail();
            setState(() => _partial += payload['text'] as String);
          case 'error':
            throw MainApiClientException(
              'Generation failed',
              code: payload['code'] as String?,
            );
          case 'completed':
            _streamDone = true;
        }
      }
      final c = await _api!.getAIConversation(_id);
      if (!mounted) {
        return;
      }
      setState(() {
        _chat = c;
        _busy = false;
      });
      if (!_streamDone && c['active_key'] != '') {
        throw const MainApiClientException('Stream interrupted');
      }
      if (_streamDone) {
        _partial = '';
        _requestKey = null;
        _wallet = await _api!.getAIWallet();
        if (mounted) {
          setState(() {});
        }
        await _readActions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _describe(e);
        });
      }
    }
  }

  bool _mutating(Map<String, dynamic> a) {
    final name = (a['call'] as Map)['function']['name'];
    return _mcp!.tools.any((t) => t['name'] == name && t['mutating'] == true);
  }

  Future<void> _readActions() async {
    for (final a in _actions) {
      if (a['state'] == 'pending' && !_mutating(a)) {
        await _action(a, true, continueAfter: false);
        if (_error != null) {
          return;
        }
      }
    }
    if (_actions.isNotEmpty &&
        _actions.every(
          (a) => ['succeeded', 'failed', 'declined'].contains(a['state']),
        ) &&
        _messages.last['role'] == 'tool') {
      await _send('');
    }
  }

  Future<bool> _approve(Map<String, dynamic> a) async {
    final fn = (a['call'] as Map)['function'] as Map;
    final args = jsonDecode(fn['arguments'] as String) as Map;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              _t('Valider l’action du copilote', 'Approve copilot action'),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_t('Bot', 'Bot')} : ${args['bot_id'] ?? _chat?['bot_id'] ?? '—'}',
                  ),
                  Text(_label(fn['name'] as String)),
                  Text(
                    (fn['name'] as String).startsWith('remote_')
                        ? _t('Manager distant', 'Remote Manager')
                        : _t('Cet appareil', 'This device'),
                  ),
                  if (args['name'] != null) Text('/${args['name']}'),
                  if (args['script'] != null)
                    SelectableText(args['script'] as String),
                  ExpansionTile(
                    title: Text(_t('Détails de l’action', 'Action details')),
                    children: [
                      SelectableText(
                        const JsonEncoder.withIndent('  ').convert(args),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t('Annuler', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_t('Exécuter', 'Execute')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _action(
    Map<String, dynamic> a,
    bool approve, {
    bool continueAfter = true,
  }) async {
    if (_busy) {
      return;
    }
    final fn = (a['call'] as Map)['function'] as Map;
    final name = fn['name'] as String;
    final call = a['call_id'] as String;
    if (approve && _mutating(a)) {
      approve = await _approve(a);
      if (!mounted) {
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api!.aiAction(_id, call, {'approve': approve});
      if (approve && !name.startsWith('remote_')) {
        Map<String, dynamic> result;
        String state;
        try {
          result = await _mcp!.call(
            name,
            Map<String, dynamic>.from(
              jsonDecode(fn['arguments'] as String) as Map,
            ),
            callID: '${a['request_key']}:$call',
            alreadyApproved: true,
          );
          state = result['isError'] == true ? 'failed' : 'succeeded';
        } catch (_) {
          result = {
            'isError': true,
            'message': 'Action failed; success not confirmed.',
          };
          state = 'failed';
        }
        if (utf8.encode(jsonEncode(result)).length > 24000) {
          result = {'message': 'Result too large. Inspect bot details.'};
        }
        await _api!.aiAction(_id, call, {'state': state, 'result': result});
      }
      _chat = await _api!.getAIConversation(_id);
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      if (continueAfter) {
        await _readActions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _describe(e);
        });
      }
    }
  }

  String _label(String name) => switch (name) {
    'remote_start_bot' ||
    'local_start_bot' => _t('Démarrer le bot', 'Start bot'),
    'remote_stop_bot' || 'local_stop_bot' => _t('Arrêter le bot', 'Stop bot'),
    'local_create_command' => _t('Créer une commande', 'Create command'),
    'local_update_command_execution' => _t(
      'Modifier une commande',
      'Update command',
    ),
    'docs_search' ||
    'docs_get' => _t('Consulter la documentation', 'Read documentation'),
    _ => _t('Consulter le bot', 'Inspect bot'),
  };
  Future<void> _menu(String action) async {
    if (_chat == null) {
      return;
    }
    try {
      switch (action) {
        case 'rename':
          final controller = TextEditingController(
            text: _chat!['title'] as String,
          );
          final title = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(_t('Renommer', 'Rename')),
              content: TextField(controller: controller, maxLength: 200),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_t('Annuler', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: Text(_t('Enregistrer', 'Save')),
                ),
              ],
            ),
          );
          controller.dispose();
          if (title != null && title.isNotEmpty) {
            await _api!.updateAIConversation(
              _id,
              title,
              _chat!['archived'] == true,
            );
          }
        case 'archive':
          await _api!.updateAIConversation(
            _id,
            _chat!['title'] as String,
            _chat!['archived'] != true,
          );
        case 'export':
          final content = StringBuffer('# ${_chat!['title']}\n\n');
          for (final m in _messages) {
            if (m['role'] == 'user' || m['role'] == 'assistant') {
              content.write('## ${m['role']}\n\n${m['content']}\n\n');
            }
          }
          final path = await FilePicker.saveFile(
            dialogTitle: _t('Exporter la discussion', 'Export conversation'),
            fileName: 'conversation.md',
            bytes: Uint8List.fromList(utf8.encode(content.toString())),
          );
          if (path != null &&
              (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
            await File(path).writeAsString(content.toString());
          }
        case 'delete':
          final yes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                _t('Supprimer la discussion ?', 'Delete conversation?'),
              ),
              content: Text(
                _t(
                  'Le contenu sera supprimé. Les mouvements de crédits seront conservés.',
                  'Content will be deleted. Credit movements will remain.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(_t('Annuler', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(_t('Supprimer', 'Delete')),
                ),
              ],
            ),
          );
          if (yes == true) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_draftKey);
            await _api!.deleteAIConversation(_id);
            _chat = null;
            _prompt.clear();
          }
        case 'continue':
          final yes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                _t('Continuer avec un résumé', 'Continue with a summary'),
              ),
              content: Text(
                _t(
                  'Le résumé consomme des crédits IA (entrée + sortie). Les échanges les plus récents seront résumés, dans la limite du contexte. La discussion originale sera conservée.',
                  'The summary uses AI credits (input + output). Recent exchanges will be summarized within the context limit. The original conversation will remain.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(_t('Annuler', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(_t('Créer la suite', 'Create continuation')),
                ),
              ],
            ),
          );
          if (yes == true) {
            final c = await _api!.continueAIConversation(
              _id,
              const Uuid().v4(),
            );
            await _open(c['id'] as String);
          }
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() => _error = _describe(e));
      }
    }
  }

  Future<void> _connection() async {
    try {
      await _mcp!.startServer();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_t('Connexion MCP locale', 'Local MCP connection')),
          content: SelectableText(
            '${_mcp!.endpoint}\n\nAuthorization: Bearer ${_mcp!.bearer}\n\n${_t('Les mutations nécessitent une validation ici.', 'Mutations require approval here.')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t('Fermer', 'Close')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = _describe(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot = _chat?['bot_id'] ?? widget.botId;
    final location =
        _chat?['location'] ??
        (widget.botId == null ? 'global' : widget.location);
    final canSend =
        (_hasPrompt || _pending != null) &&
        _ready &&
        !_busy &&
        _chat?['archived'] != true &&
        !_actions.any(
          (a) => ['pending', 'executing', 'uncertain'].contains(a['state']),
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Copilote IA', 'AI copilot')),
        actions: [
          IconButton(
            tooltip: _t('Historique', 'History'),
            icon: const Icon(Icons.history_rounded),
            onPressed: _busy ? null : _historySheet,
          ),
          IconButton(
            tooltip: _t('Nouvelle discussion', 'New conversation'),
            icon: const Icon(Icons.edit_square),
            onPressed: _busy ? null : _new,
          ),
          PopupMenuButton<String>(
            tooltip: _t('Options', 'Options'),
            enabled: !_busy,
            onSelected: _handleMenu,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'refresh',
                child: Text(_t('Actualiser', 'Refresh')),
              ),
              PopupMenuItem(
                value: 'wallet',
                child: Text(_t('Crédits IA', 'AI credits')),
              ),
              if (_mcp?.desktop == true)
                PopupMenuItem(
                  value: 'mcp',
                  child: Text(_t('Connexion MCP', 'MCP connection')),
                ),
              if (_chat != null) ...[
                const PopupMenuDivider(),
                for (final item in [
                  ('rename', _t('Renommer', 'Rename')),
                  ('archive', _t('Archiver / restaurer', 'Archive / restore')),
                  ('export', _t('Exporter Markdown', 'Export Markdown')),
                  (
                    'continue',
                    _t('Continuer avec résumé', 'Continue with summary'),
                  ),
                  ('delete', _t('Supprimer', 'Delete')),
                ])
                  PopupMenuItem(value: item.$1, child: Text(item.$2)),
              ],
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              children: [
                _contextHeader(bot, location),
                if (_wallet != null) _walletStrip(),
                if (_loading || _busy) const LinearProgressIndicator(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: _busy ? null : _refresh,
                              child: Text(_t('Actualiser', 'Refresh')),
                            ),
                            if (_requestKey != null)
                              TextButton(
                                onPressed: _busy ? null : _follow,
                                child: Text(
                                  _t(
                                    'Récupérer la réponse',
                                    'Recover response',
                                  ),
                                ),
                              ),
                            if (_pending != null)
                              TextButton(
                                onPressed: _busy ? null : _send,
                                child: Text(
                                  _t('Réessayer la demande', 'Retry request'),
                                ),
                              ),
                            if (_chat != null)
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _menu('continue'),
                                child: Text(
                                  _t(
                                    'Continuer avec résumé',
                                    'Continue with summary',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_chat == null) _welcome(),
                      for (final m in _messages)
                        if (m['role'] == 'user' || m['role'] == 'assistant')
                          _messageBubble(m),
                      if (_partial.isNotEmpty)
                        _messageBubble({
                          'role': 'assistant',
                          'content': _partial,
                        }, streaming: true),
                      for (final a in _actions) _actionCard(a),
                    ],
                  ),
                ),
                _composer(canSend),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenu(String choice) async {
    switch (choice) {
      case 'refresh':
        await _refresh();
      case 'wallet':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AICreditsPage(api: _api)),
        );
      case 'mcp':
        await _connection();
      default:
        await _menu(choice);
    }
  }

  String _number(Object? value) {
    final raw = (value ?? 0).toString();
    return raw.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}\u202f',
    );
  }

  Widget _contextHeader(String? bot, String location) {
    final colors = Theme.of(context).colorScheme;
    final name = bot == null || bot.isEmpty
        ? _t('Discussion globale', 'Global conversation')
        : widget.botName ?? _botNames[bot] ?? bot;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              bot == null || bot.isEmpty
                  ? Icons.auto_awesome_rounded
                  : Icons.smart_toy_outlined,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _chat?['title'] as String? ??
                      _t('Nouvelle discussion', 'New conversation'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (bot != null && bot.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    location == 'local'
                        ? Icons.devices_rounded
                        : Icons.cloud_outlined,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    location == 'local'
                        ? _t('Local', 'Local')
                        : _t('Distant', 'Remote'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _walletStrip() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: .55),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (final metric in [
              (_t('Disponible', 'Available'), _wallet!['available']),
              (_t('Réservé', 'Reserved'), _wallet!['reserved'] ?? 0),
              (_t('Total', 'Total'), _wallet!['balance']),
            ])
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.$1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _number(metric.$2),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _t('Crédits IA', 'AI credits'),
              onPressed: () => _handleMenu('wallet'),
              icon: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Un coup de main pour votre bot ?', 'A hand with your bot?'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              'Explorez une idée, vérifiez une commande ou préparez une modification. Vous gardez le contrôle des actions.',
              'Explore an idea, check a command or prepare a change. You stay in control of every action.',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          for (final suggestion in [
            (
              Icons.search_rounded,
              _t('Vérifier mon bot', 'Check my bot'),
              _t(
                'Vérifie l’état de mon bot et propose les prochaines étapes.',
                'Inspect my bot and suggest next steps.',
              ),
            ),
            (
              Icons.code_rounded,
              _t('Créer une commande', 'Create a command'),
              _t(
                'Aide-moi à préparer une nouvelle commande pour mon bot.',
                'Help me prepare a new command for my bot.',
              ),
            ),
            (
              Icons.lightbulb_outline_rounded,
              _t('Comprendre une fonctionnalité', 'Understand a feature'),
              _t(
                'Explique-moi comment utiliser les fonctionnalités de Bot Creator.',
                'Explain how to use Bot Creator features.',
              ),
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: !_ready
                      ? null
                      : () {
                          _prompt.text = suggestion.$3;
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(suggestion.$1, size: 19, color: colors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion.$2,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Icon(
                          Icons.north_west_rounded,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              _t('Reprendre une discussion', 'Continue a conversation'),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (final c in _history.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
                title: Text(
                  c['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => _open(c['id'] as String),
              ),
          ],
        ],
      ),
    );
  }

  Widget _messageBubble(
    Map<String, dynamic> message, {
    bool streaming = false,
  }) {
    final colors = Theme.of(context).colorScheme,
        user = message['role'] == 'user',
        content = (message['content'] ?? '').toString();
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: user ? MediaQuery.sizeOf(context).width * .82 : 850,
        ),
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: user
              ? colors.primaryContainer.withValues(alpha: .32)
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(user ? 18 : 5),
            bottomRight: Radius.circular(user ? 5 : 18),
          ),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: .4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!user) ...[
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 7),
                ],
                Expanded(
                  child: Text(
                    user ? _t('Vous', 'You') : _t('Copilote', 'Copilot'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: user ? colors.onSurfaceVariant : colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (streaming)
                  Text(
                    _t('En cours…', 'Generating…'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: _t('Copier le message', 'Copy message'),
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: content)),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            CopilotMarkdown(content: content),
          ],
        ),
      ),
    );
  }

  Widget _composer(bool canSend) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: .4)),
        ),
      ),
      child: Column(
        children: [
          if (_chat != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Icon(
                    Icons.toll_outlined,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_number(_chat?['consumed_tokens'])} ${_t('tokens dans cette discussion', 'tokens in this conversation')}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 3, 5, 3),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _prompt,
                    minLines: 1,
                    maxLines: 5,
                    enabled: _ready,
                    decoration: InputDecoration(
                      hintText: _t('Votre message', 'Your message'),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: IconButton.filled(
                    tooltip: _t('Envoyer', 'Send'),
                    onPressed: canSend ? () => _send() : null,
                    icon: const Icon(Icons.send, size: 19),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(Map<String, dynamic> a) {
    final fn = (a['call'] as Map)['function'] as Map;
    final state = a['state'];
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: state == 'pending'
              ? colors.primary.withValues(alpha: .35)
              : colors.outlineVariant.withValues(alpha: .5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _mutating(a) ? Icons.tune_rounded : Icons.search_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _label(fn['name'] as String),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(switch (state) {
              'pending' =>
                _mutating(a)
                    ? _t('Validation requise', 'Approval required')
                    : _t('Consultation disponible', 'Ready to inspect'),
              'executing' => _t('Exécution en cours', 'Executing'),
              'succeeded' => _t('Réussite', 'Succeeded'),
              'declined' => _t('Refusée', 'Declined'),
              'uncertain' => _t(
                'Exécution non confirmée — vérifiez le bot',
                'Execution unconfirmed — inspect the bot',
              ),
              _ => _t('Échec', 'Failed'),
            }),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                _t('Détails techniques', 'Technical details'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              children: [
                SelectableText(
                  '${fn['name']}\n${fn['arguments']}\n${a['result'] ?? ''}',
                ),
              ],
            ),
            if (state == 'pending')
              Wrap(
                children: [
                  FilledButton(
                    onPressed: _busy || _chat?['archived'] == true
                        ? null
                        : () => _action(a, true),
                    child: Text(
                      _mutating(a)
                          ? _t('Valider', 'Approve')
                          : _t('Consulter', 'Inspect'),
                    ),
                  ),
                  if (_mutating(a))
                    TextButton(
                      onPressed: _busy || _chat?['archived'] == true
                          ? null
                          : () => _action(a, false),
                      child: Text(_t('Refuser', 'Decline')),
                    ),
                ],
              ),
            if (state == 'uncertain')
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              _t(
                                'Clore sans réexécuter',
                                'Close without replay',
                              ),
                            ),
                            content: Text(
                              _t(
                                'Vérifiez le bot avant de clore cette action au résultat inconnu.',
                                'Check the bot before closing this action with an unknown outcome.',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(_t('Annuler', 'Cancel')),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(_t('Clore', 'Close')),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) {
                          return;
                        }
                        try {
                          await _api!.aiAction(_id, a['call_id'] as String, {
                            'state': 'failed',
                            'result': {
                              'isError': true,
                              'message':
                                  'Execution outcome unconfirmed; user acknowledged after inspection. No replay authorized.',
                            },
                          });
                          await _refresh();
                        } catch (e) {
                          if (mounted) {
                            setState(() => _error = _describe(e));
                          }
                        }
                      },
                child: Text(
                  _t('Clore sans réexécuter', 'Close without replay'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _historySheet() async {
    if (_api == null || _busy) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .8,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _t('Historique des discussions', 'Conversation history'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: _t('Rechercher un titre', 'Search title'),
                  ),
                  onSubmitted: (_) async {
                    await _loadHistory();
                    update(() {});
                  },
                ),
                if (widget.botId == null)
                  DropdownButtonFormField<String>(
                    initialValue: _botFilter.text.isEmpty
                        ? ''
                        : _botFilter.text,
                    decoration: InputDecoration(
                      labelText: _t('Filtrer par bot', 'Filter by bot'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(_t('Tous les bots', 'All bots')),
                      ),
                      for (final id in {
                        ..._botNames.keys,
                        ..._history
                            .map((c) => (c['bot_id'] ?? '').toString())
                            .where((id) => id.isNotEmpty),
                        if (_botFilter.text.isNotEmpty) _botFilter.text,
                      })
                        DropdownMenuItem(
                          value: id,
                          child: Text(_botNames[id] ?? id),
                        ),
                    ],
                    onChanged: (id) async {
                      _botFilter.text = id ?? '';
                      try {
                        await _loadHistory();
                        if (ctx.mounted) {
                          update(() {});
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _error = _describe(e));
                        }
                      }
                    },
                  ),
                SwitchListTile(
                  title: Text(_t('Archives', 'Archives')),
                  value: _archives,
                  onChanged: (v) async {
                    _archives = v;
                    await _loadHistory();
                    update(() {});
                  },
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (_history.isEmpty)
                        Text(_t('Aucune discussion.', 'No conversations.')),
                      for (final c in _history)
                        ListTile(
                          title: Text(c['title'] as String),
                          subtitle: Text(
                            '${c['bot_id'] == '' ? _t('Globale', 'Global') : c['bot_id']} · ${c['updated_at'] ?? ''}',
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            unawaited(_open(c['id'] as String));
                          },
                        ),
                      if (_historyMore)
                        TextButton(
                          onPressed: () async {
                            try {
                              await _loadHistory(more: true);
                              if (ctx.mounted) {
                                update(() {});
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => _error = _describe(e));
                              }
                            }
                          },
                          child: Text(_t('Charger la suite', 'Load more')),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CopilotMarkdown extends StatelessWidget {
  const CopilotMarkdown({super.key, required this.content});
  final String content;
  @override
  Widget build(BuildContext context) => SelectionArea(
    child: MarkdownBody(
      data: content,
      selectable: false,
      onTapLink: (text, href, title) {
        final uri = Uri.tryParse(href ?? '');
        if (uri != null && ['https', 'http'].contains(uri.scheme)) {
          unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
        }
      },
      builders: {
        'pre': _CodeBuilder(
          Localizations.localeOf(context).languageCode == 'fr'
              ? 'Copier le code'
              : 'Copy code',
        ),
      },
    ),
  );
}

class _CodeBuilder extends MarkdownElementBuilder {
  _CodeBuilder(this.copyTooltip);
  final String copyTooltip;

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final code = element.textContent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            code,
            style: preferredStyle?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        IconButton(
          tooltip: copyTooltip,
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () => Clipboard.setData(ClipboardData(text: code)),
        ),
      ],
    );
  }
}

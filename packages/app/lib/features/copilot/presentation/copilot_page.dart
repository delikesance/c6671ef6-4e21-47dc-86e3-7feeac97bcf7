import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/copilot/logic/copilot_mcp.dart';
import 'package:bot_creator/features/copilot/logic/copilot_catalog.dart';
import 'package:bot_creator/features/subscriptions/presentation/ai_credits_page.dart';
import 'package:bot_creator/features/subscriptions/logic/ai_credit_format.dart';
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
  bool _pendingRejected = false;
  List<Map<String, dynamic>> _history = [];
  final Map<String, String> _botNames = {};
  final Map<String, bool> _toolMutations = {};
  Future<void> _draftQueue = Future.value();
  bool _busy = false, _ready = false, _archives = false, _loading = true;
  bool _historyMore = false, _hasPrompt = false;
  bool? _cloudRunning;
  bool _cloudManaged = false;
  final Set<String> _cloudRetried = {};
  String? _error;
  bool _catalogMismatch = false;
  String _partial = '';
  int _cursor = 0, _viewEpoch = 0;
  String? _requestKey;
  String? _summaryKey;
  bool _streamDone = false;
  bool _summarizing = false;
  int _historyEpoch = 0;
  String get _id => _chat!['id'] as String;
  String _copy(String french, String english) =>
      Localizations.localeOf(context).languageCode == 'fr' ? french : english;
  List<Map<String, dynamic>> get _actions => (_chat?['actions'] as List? ?? [])
      .map((a) => Map<String, dynamic>.from(a as Map))
      .toList();
  List<Map<String, dynamic>> get _messages =>
      (_chat?['messages'] as List? ?? [])
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList();
  List<Widget> _conversationItems() {
    final actions = _actions;
    final placed = <String>{};
    final items = <Widget>[];
    final messages = _messages;
    for (var messageIndex = 0; messageIndex < messages.length; messageIndex++) {
      final message = messages[messageIndex];
      if (message['role'] != 'user' && message['role'] != 'assistant') continue;
      if (message['role'] == 'user' ||
          (message['content'] ?? '').toString().trim().isNotEmpty) {
        items.add(
          KeyedSubtree(
            key: ValueKey('message-$messageIndex'),
            child: _messageBubble(message),
          ),
        );
      }
      if (message['role'] != 'assistant') continue;
      final calls = (message['tool_calls'] as List? ?? const []);
      for (final call in calls) {
        if (call is! Map) continue;
        final id = call['id']?.toString();
        for (final action in actions) {
          if (id != null && action['call_id'] == id && placed.add(id)) {
            if (!_mutating(action)) continue;
            items.add(
              KeyedSubtree(
                key: ValueKey('action-$id'),
                child: _actionCard(action),
              ),
            );
          }
        }
      }
    }
    if (_partial.isNotEmpty) {
      items.add(
        _messageBubble({
          'role': 'assistant',
          'content': _partial,
        }, streaming: true),
      );
    }
    final orphans = actions
        .where((a) => !placed.contains(a['call_id']) && _mutating(a))
        .toList();
    if (orphans.isNotEmpty) {
      items.addAll(orphans.map(_actionCard));
    }
    return items;
  }

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
    final text = _prompt.text;
    await _draftQueue;
    final prefs = await SharedPreferences.getInstance();
    if (mounted && key == _draftKey && _prompt.text == text) {
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
      } else {
        await _refreshCloudStatus();
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
    final epoch = _viewEpoch;
    final previous = _mcp;
    _mcp = null;
    await previous?.close();
    if (!mounted || epoch != _viewEpoch) return;
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
    if (!mounted || epoch != _viewEpoch) {
      await bridge.close();
      return;
    }
    for (final tool in bridge.tools) {
      _toolMutations[tool['name'] as String] = tool['mutating'] != false;
    }
    if (bot?.startsWith('container:') == true) {
      bridge.tools.removeWhere(
        (t) => (t['name'] as String).startsWith('local_'),
      );
    }
    final server = await _api!.getCopilotTools();
    if (!mounted || epoch != _viewEpoch) {
      await bridge.close();
      return;
    }
    final negotiated = negotiateCopilotTools(
      bridge.tools,
      server['tools'] as List,
    );
    _catalogMismatch =
        negotiated.length != bridge.tools.length ||
        negotiated.any(
          (t) =>
              HashUtil.calculateHash(t['inputSchema']) !=
              HashUtil.calculateHash(
                bridge.tools.singleWhere(
                  (original) => original['name'] == t['name'],
                )['inputSchema'],
              ),
        );
    bridge.tools = negotiated;
    _mcp = bridge;
  }

  String _describe(Object e) {
    if (e is MainApiClientException) {
      switch (e.code) {
        case 'ai_tool_round_limit':
          return context.tr.copilot_err_tool_round_limit;
        case 'ai_context_limit':
          return _copy(
            'Contexte trop long. Un résumé dans cette discussion est nécessaire.',
            'Context too long. A summary in this conversation is needed.',
          );
        case 'ai_spending_blocked':
          return context.tr.copilot_err_spending_blocked;
        case 'ai_revision_conflict':
          return context.tr.copilot_err_revision_conflict;
        case 'ai_action_already_claimed':
          return context.tr.copilot_err_action_claimed;
        case 'ai_copilot_disabled':
          return '${context.tr.copilot_err_unavailable} (ai_copilot_disabled)';
        case 'ai_provider_failure':
          return '${context.tr.copilot_err_request_failed} (ai_provider_failure)';
      }
      if (e.statusCode == 402) {
        return context.tr.copilot_err_insufficient_balance;
      }
      if (e.statusCode == 401) {
        return context.tr.copilot_err_unauthorized;
      }
      if (e.statusCode == 404) {
        return context.tr.copilot_err_not_found;
      }
      if (e.statusCode == 503) {
        return context.tr.copilot_err_unavailable;
      }
      if (e.code != null && e.code!.isNotEmpty) {
        return '${context.tr.copilot_err_request_failed} (${e.code})';
      }
    }
    return context.tr.copilot_err_request_failed;
  }

  Future<void> _loadHistory({bool more = false}) async {
    final epoch = ++_historyEpoch;
    final d = await _api!.listAIConversations(
      botId:
          widget.botId ??
          (_botFilter.text.trim().isEmpty ? null : _botFilter.text.trim()),
      query: _search.text,
      archived: _archives,
      offset: more ? _history.length : 0,
    );
    if (mounted && epoch == _historyEpoch) {
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
    if (_busy || !mounted) {
      return;
    }
    final epoch = ++_viewEpoch;
    try {
      await _saveDraft();
      if (!mounted || epoch != _viewEpoch) return;
      final c = await _api!.getAIConversation(id);
      if (!mounted || epoch != _viewEpoch) {
        return;
      }
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
        _summaryKey = null;
        _summarizing = false;
        _cursor = 0;
        _requestKey = (c['active_key'] as String?)?.isEmpty == false
            ? c['active_key'] as String
            : null;
      });
      await _bridge(
        (c['bot_id'] as String?)?.isEmpty == false
            ? c['bot_id'] as String
            : null,
      );
      if (!mounted || epoch != _viewEpoch) return;
      await _refreshCloudStatus();
      if (!mounted || epoch != _viewEpoch) return;
      await _restoreDraft();
      _scrollTail(force: true);
      if (_requestKey != null) {
        await _follow();
      } else if (c['archived'] != true &&
          _actions.any((a) => a['state'] == 'pending' && !_mutating(a))) {
        await _readActions();
      }
    } catch (e) {
      if (mounted && epoch == _viewEpoch) {
        setState(() => _error = _describe(e));
      }
    }
  }

  Future<void> _new() async {
    if (_busy) {
      return;
    }
    final epoch = ++_viewEpoch;
    try {
      await _saveDraft();
      if (!mounted || epoch != _viewEpoch) return;
      setState(() {
        _chat = null;
        _pending = null;
        _requestKey = null;
        _summaryKey = null;
        _summarizing = false;
        _cloudManaged = false;
        _cloudRunning = null;
        _partial = '';
        _error = null;
      });
      await _bridge(widget.botId);
      if (!mounted || epoch != _viewEpoch) return;
      await _refreshCloudStatus();
      await _restoreDraft();
    } catch (e) {
      if (mounted && epoch == _viewEpoch) {
        setState(() => _error = _describe(e));
      }
    }
  }

  Future<void> _refresh() async {
    if (!_ready) {
      await _initialize();
      return;
    }
    try {
      if (_mcp == null) {
        await _bridge((_chat?['bot_id'] ?? widget.botId)?.toString());
        if (!mounted) return;
      }
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
        if (_summaryKey != null &&
            _pending != null &&
            _chat?['active_key'] == '' &&
            _chat?['last_request_key'] == _summaryKey) {
          if (_chat?['last_request_status'] == 'completed') {
            _summaryKey = null;
            _pending!['idempotency_key'] = const Uuid().v4();
            _pending!['revision'] = _chat!['revision'];
            await _send(null, false, true);
          } else if (_chat?['last_request_status'] == 'failed') {
            _summaryKey = null;
            _pending!['idempotency_key'] = const Uuid().v4();
            _pending!['revision'] = _chat!['revision'];
          }
        }
      }
      _wallet = await _api!.getAIWallet();
      await _refreshCloudStatus();
      await _loadHistory();
      if (mounted &&
          !_busy &&
          _chat?['archived'] != true &&
          _actions.any((a) => a['state'] == 'pending' && !_mutating(a))) {
        await _readActions();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = _describe(e));
      }
    }
  }

  Future<void> _refreshCloudStatus() async {
    final epoch = _viewEpoch;
    final bot = (_chat?['bot_id'] ?? widget.botId)?.toString();
    if (mounted) {
      setState(() {
        _cloudManaged = false;
        _cloudRunning = null;
      });
    }
    if (bot == null || bot.isEmpty) return;
    try {
      final managed = (await _api!.listBots()).any(
        (b) => (b['bot_id'] ?? b['id']).toString() == bot,
      );
      final status = await _api!.getStatus(botId: bot);
      if (mounted && epoch == _viewEpoch) {
        setState(() {
          _cloudManaged = managed;
          _cloudRunning = status.isBotRunning(bot);
        });
      }
    } catch (_) {
      if (mounted && epoch == _viewEpoch) {
        setState(() => _cloudRunning = null);
      }
    }
  }

  Future<void> _send([
    String? toolContinuation,
    bool allowSummary = true,
    bool replayPending = false,
  ]) async {
    if (!mounted || _busy || !_ready || _mcp == null) {
      return;
    }
    // A retry reuses its key, but an edited draft is a new request.
    if (!replayPending &&
        toolContinuation == null &&
        _pendingRejected &&
        _pending != null &&
        (_pending!['prompt'] as String).isNotEmpty &&
        _pending!['prompt'] != _prompt.text.trim()) {
      _pending = null;
    }
    final prompt =
        (_pending?['prompt'] as String?) ??
        toolContinuation ??
        _prompt.text.trim();
    if (prompt.isEmpty && toolContinuation == null && _pending == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _draftQueue;
      if (!mounted) return;
      if (_chat == null) {
        final oldKey = _draftKey;
        _chat = await _api!.createAIConversation(
          botId: widget.botId,
          location: widget.botId == null ? 'global' : widget.location,
          title: prompt.length > 60 ? prompt.substring(0, 60) : prompt,
        );
        if (!mounted) return;
        // Move the draft before removing its old global/bot key. An unknown
        // acceptance or closing the page must not discard unsent text.
        await _saveDraft();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(oldKey);
        if (!mounted) return;
      }
      _pending ??= {
        'idempotency_key': const Uuid().v4(),
        'revision': _chat!['revision'],
        'prompt': prompt,
        'tools': _mcp!.tools.map((t) => t['name']).toList(),
      };
      _requestKey = _pending!['idempotency_key'] as String;
      _pendingRejected = false;
      await _api!.startAITurn(_id, _pending!);
      if (!mounted) return;
      _pending = null;
      if (prompt.isNotEmpty && _prompt.text.trim() == prompt) _prompt.clear();
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
      // A timeout can hide an accepted turn. Keep its key and body for an
      // idempotent retry even when the composer holds the next draft.
      if (e is MainApiClientException &&
          (e.statusCode ?? 0) >= 400 &&
          (e.statusCode ?? 0) < 500) {
        _pendingRejected = true;
      }
      if (e is MainApiClientException &&
          e.code == 'ai_revision_conflict' &&
          _chat != null &&
          _pending != null) {
        try {
          final latest = await _api!.getAIConversation(_id);
          if (!mounted) return;
          _chat = latest;
          _pending!['idempotency_key'] = const Uuid().v4();
          _pending!['revision'] = latest['revision'];
          _requestKey = (latest['active_key'] as String?)?.isNotEmpty == true
              ? latest['active_key'] as String
              : null;
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _describe(e);
        });
      }
      if (mounted &&
          allowSummary &&
          e is MainApiClientException &&
          e.code == 'ai_context_limit') {
        await _summarizeAndRetry();
      }
    }
  }

  Future<void> _summarizeAndRetry() async {
    if (!mounted || _chat == null || _pending == null) return;
    setState(() {
      _busy = true;
      _summarizing = true;
      _error = null;
    });
    try {
      _summaryKey ??= const Uuid().v4();
      _requestKey = _summaryKey;
      _cursor = 0;
      await _api!.summarizeAIConversation(
        _id,
        _summaryKey!,
        _chat!['revision'] as int,
      );
      if (!mounted) return;
      var completed = false;
      await for (final event in _api!.aiEvents(_id, _summaryKey!)) {
        if (event['kind'] == 'error') {
          final payload = event['payload'] as Map;
          throw MainApiClientException(
            'Résumé échoué',
            code: payload['code'] as String?,
          );
        }
        if (event['kind'] == 'completed') completed = true;
      }
      if (!completed) throw const MainApiClientException('Résumé interrompu');
      _chat = await _api!.getAIConversation(_id);
      _summaryKey = null;
      _pending!['idempotency_key'] = const Uuid().v4();
      _pending!['revision'] = _chat!['revision'];
      if (!mounted) return;
      setState(() {
        _busy = false;
        _summarizing = false;
      });
      await _send(null, false, true);
    } catch (e) {
      if (!mounted) return;
      try {
        _chat = await _api!.getAIConversation(_id);
        if (_chat?['last_request_status'] == 'failed') {
          _summaryKey = null;
          _pending!['idempotency_key'] = const Uuid().v4();
          _pending!['revision'] = _chat!['revision'];
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _busy = false;
        _summarizing = false;
        _error = _describe(e);
      });
    }
  }

  Future<void> _follow() async {
    if (_requestKey == null || _chat == null || _busy) {
      return;
    }
    final epoch = _viewEpoch;
    final id = _id;
    final requestKey = _requestKey!;
    setState(() => _busy = true);
    _streamDone = false;
    try {
      await for (final event in _api!.aiEvents(
        id,
        requestKey,
        after: _cursor,
      )) {
        if (!mounted || epoch != _viewEpoch) {
          return;
        }
        _cursor = event['id'] as int;
        final payload = event['payload'] as Map;
        switch (event['kind']) {
          case 'summarizing':
            setState(() => _summarizing = payload['phase'] == 'started');
          case 'delta':
            if (_requestKey != _summaryKey) {
              _scrollTail();
              setState(() => _partial += payload['text'] as String);
            }
          case 'error':
            throw MainApiClientException(
              'Generation failed',
              code: payload['code'] as String?,
            );
          case 'completed':
            _streamDone = true;
        }
      }
      final c = await _api!.getAIConversation(id);
      if (!mounted || epoch != _viewEpoch) {
        return;
      }
      // Recovery may start after the completed SSE event was already consumed.
      // The durable request status is the authority in that case.
      final settled = c['last_request_key'] == requestKey;
      final completed =
          _streamDone || (settled && c['last_request_status'] == 'completed');
      if (settled && c['last_request_status'] == 'failed') {
        throw MainApiClientException(
          'Generation failed',
          code: c['last_error_code'] as String?,
        );
      }
      setState(() {
        _chat = c;
        _busy = false;
        _summarizing = false;
        if (completed) {
          _partial = '';
          _requestKey = null;
          _error = null;
        }
      });
      if (!completed && (c['active_key'] as String? ?? '').isNotEmpty) {
        throw const MainApiClientException('Stream interrupted');
      }
      if (completed) {
        if (requestKey == _summaryKey && _pending != null) {
          _summaryKey = null;
          _pending!['idempotency_key'] = const Uuid().v4();
          _pending!['revision'] = _chat!['revision'];
          await _send(null, false, true);
          return;
        }
        _wallet = await _api!.getAIWallet();
        if (mounted) {
          setState(() {});
        }
        await _readActions();
      }
    } catch (e) {
      // Keep persisted messages/context in sync even when the SSE stream fails.
      Map<String, dynamic>? latest;
      try {
        latest = await _api!.getAIConversation(id);
      } catch (_) {}
      if (mounted && epoch == _viewEpoch) {
        setState(() {
          if (latest != null) _chat = latest;
          _busy = false;
          _summarizing = false;
          _error = _describe(e);
        });
      }
    }
  }

  bool _mutating(Map<String, dynamic> a) {
    final name = (a['call'] as Map)['function']['name'];
    for (final tool in _mcp?.tools ?? const <Map<String, dynamic>>[]) {
      if (tool['name'] == name) return tool['mutating'] != false;
    }
    return _toolMutations[name] != false;
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
        _messages.isNotEmpty &&
        _messages.last['role'] == 'tool') {
      await _send('');
    }
  }

  Future<bool> _approve(Map<String, dynamic> a) async {
    final fn = (a['call'] as Map)['function'] as Map;
    final args = jsonDecode(fn['arguments'] as String) as Map;
    Map<String, dynamic>? preview;
    try {
      preview = await _mcp?.previewConfiguration(
        fn['name'] as String,
        Map<String, dynamic>.from(args),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _describe(error));
      return false;
    }
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.tr.copilot_approve_dialog_title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${context.tr.copilot_bot_label} : ${args['bot_id'] ?? _chat?['bot_id'] ?? '—'}',
                  ),
                  Text(_label(fn['name'] as String)),
                  if (preview != null &&
                      fn['name'] == 'local_update_command_options') ...[
                    Text(
                      '${_copy('Avant', 'Before')} : ${(preview['before'] as List).map((o) => (o as Map)['name']).join(', ')}',
                    ),
                    Text(
                      '${_copy('Après', 'After')} : ${(preview['after'] as List).map((o) => (o as Map)['name']).join(', ')}',
                    ),
                  ],
                  Text(
                    (fn['name'] as String).startsWith('remote_')
                        ? context.tr.copilot_remote_manager
                        : context.tr.copilot_this_device,
                  ),
                  if (args['name'] != null) Text('/${args['name']}'),
                  if (args['option_name'] != null)
                    Text(
                      '${_copy('Argument', 'Argument')} : ${args['option_name']}',
                    ),
                  if (args['operation'] != null)
                    Text(switch (args['operation']) {
                      'add' => _copy(
                        'Ajouter cet argument',
                        'Add this argument',
                      ),
                      'update' => _copy(
                        'Modifier cet argument',
                        'Edit this argument',
                      ),
                      'remove' => _copy(
                        'Supprimer cet argument',
                        'Remove this argument',
                      ),
                      _ => '',
                    }),
                  if (args['option'] is Map) ...[
                    if ((args['option'] as Map)['description'] != null)
                      Text((args['option'] as Map)['description'] as String),
                    if ((args['option'] as Map)['required'] != null)
                      Text(
                        (args['option'] as Map)['required'] == true
                            ? _copy('Argument obligatoire', 'Required argument')
                            : _copy('Argument facultatif', 'Optional argument'),
                      ),
                  ],
                  if (args['username'] != null)
                    Text(
                      '${_copy('Nouveau nom', 'New name')} : ${args['username']}',
                    ),
                  if (args['workflow_name'] != null)
                    Text(
                      '${_copy('Automatisation', 'Automation')} : ${args['workflow_name']}',
                    ),
                  if (args['every_minutes'] != null)
                    Text(
                      _copy(
                        'Toutes les ${args['every_minutes']} minutes',
                        'Every ${args['every_minutes']} minutes',
                      ),
                    ),
                  if (args['activities'] is List)
                    for (final activity in args['activities'] as List)
                      Text((activity as Map)['name'] as String),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.tr.copilot_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.tr.copilot_execute),
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
    'local_start_bot' => context.tr.copilot_tool_start_bot,
    'remote_stop_bot' || 'local_stop_bot' => context.tr.copilot_tool_stop_bot,
    'local_create_command' => context.tr.copilot_tool_create_command,
    'local_update_command_execution' => context.tr.copilot_tool_update_command,
    'local_update_command_options' => context.tr.copilot_tool_options,
    'local_update_command_settings' => context.tr.copilot_tool_settings,
    'local_create_workflow' => context.tr.copilot_tool_create_workflow,
    'local_update_workflow' => context.tr.copilot_tool_update_workflow,
    'local_update_bot_presence' => context.tr.copilot_tool_presence,
    'local_update_bot_profile' => context.tr.copilot_tool_profile,
    'local_set_variable' => context.tr.copilot_tool_variable,
    'local_update_scheduled_trigger' => context.tr.copilot_tool_schedule,
    'local_update_inbound_webhook' => context.tr.copilot_tool_webhook,
    'docs_search' || 'docs_get' => context.tr.copilot_tool_read_docs,
    _ => context.tr.copilot_tool_inspect_bot,
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
              title: Text(context.tr.copilot_rename_title),
              content: TextField(controller: controller, maxLength: 200),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.tr.copilot_cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: Text(context.tr.copilot_save),
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
            dialogTitle: context.tr.copilot_export_dialog_title,
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
              title: Text(context.tr.copilot_delete_confirm_title),
              content: Text(context.tr.copilot_delete_confirm_body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.tr.copilot_cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.tr.copilot_delete),
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
              title: Text(context.tr.copilot_continue_summary_title),
              content: Text(context.tr.copilot_continue_summary_body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.tr.copilot_cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.tr.copilot_create_continuation),
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
          title: Text(context.tr.copilot_mcp_local_title),
          content: SelectableText(
            '${_mcp!.endpoint}\n\nAuthorization: Bearer ${_mcp!.bearer}\n\n${context.tr.copilot_mcp_approval_note}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr.copilot_close),
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
    final location = _cloudManaged
        ? 'remote'
        : _chat?['location'] ??
              (widget.botId == null ? 'global' : widget.location);
    final canSend =
        (_hasPrompt || _pending != null) &&
        _ready &&
        _mcp != null &&
        !_busy &&
        _chat?['archived'] != true &&
        !_actions.any(
          (a) => ['pending', 'executing', 'uncertain'].contains(a['state']),
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.copilot_title),
        actions: [
          IconButton(
            tooltip: context.tr.copilot_history_tooltip,
            icon: const Icon(Icons.history_rounded),
            onPressed: _busy ? null : _historySheet,
          ),
          IconButton(
            tooltip: context.tr.copilot_new_discussion,
            icon: const Icon(Icons.edit_square),
            onPressed: _busy ? null : _new,
          ),
          PopupMenuButton<String>(
            tooltip: context.tr.copilot_options_tooltip,
            enabled: !_busy,
            onSelected: _handleMenu,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'refresh',
                child: Text(context.tr.copilot_action_refresh),
              ),
              PopupMenuItem(
                value: 'wallet',
                child: Text(context.tr.copilot_action_credits),
              ),
              if (_mcp?.desktop == true)
                PopupMenuItem(
                  value: 'mcp',
                  child: Text(context.tr.copilot_action_mcp_connection),
                ),
              if (_chat != null) ...[
                const PopupMenuDivider(),
                for (final item in [
                  ('rename', context.tr.copilot_rename_title),
                  ('archive', context.tr.copilot_action_archive),
                  ('export', context.tr.copilot_action_export),
                  ('continue', context.tr.copilot_action_continue),
                  ('delete', context.tr.copilot_delete),
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
                if (_loading || _busy) const LinearProgressIndicator(),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_catalogMismatch)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _copy(
                              'Certaines fonctions IA sont indisponibles : les versions de l’application et du serveur diffèrent. Mettez-les à jour pour accéder à tous les outils.',
                              'Some AI features are unavailable because the app and server versions differ. Update them to access all tools.',
                            ),
                          ),
                        ),
                      if (_wallet != null && !_busy) _walletStrip(),
                      if (_summarizing)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _copy(
                              'Résumé automatique du contexte… Les messages restent disponibles.',
                              'Automatically summarizing context… Messages stay available.',
                            ),
                          ),
                        ),
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
                                    child: Text(
                                      context.tr.copilot_action_refresh,
                                    ),
                                  ),
                                  if (_requestKey != null)
                                    TextButton(
                                      onPressed: _busy ? null : _follow,
                                      child: Text(
                                        context
                                            .tr
                                            .copilot_action_recover_response,
                                      ),
                                    ),
                                  if (_pending != null)
                                    TextButton(
                                      onPressed: _busy ? null : _send,
                                      child: Text(
                                        context.tr.copilot_action_retry,
                                      ),
                                    ),
                                  if (_chat != null)
                                    TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _menu('continue'),
                                      child: Text(
                                        context.tr.copilot_action_continue,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (_chat == null) _welcome(),
                      if ((_chat?['context_summary'] as String? ?? '')
                          .isNotEmpty)
                        ExpansionTile(
                          title: Text(
                            _copy('Contexte résumé', 'Summarized context'),
                          ),
                          children: [
                            SelectableText(_chat!['context_summary'] as String),
                          ],
                        ),
                      ..._conversationItems(),
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

  String _credits(Object? value) => formatAiCredits(
    value,
    locale: Localizations.localeOf(context).toString(),
  );

  Widget _contextHeader(String? bot, String location) {
    final colors = Theme.of(context).colorScheme;
    final name = bot == null || bot.isEmpty
        ? context.tr.copilot_global_discussion
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
                      context.tr.copilot_new_discussion,
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
                        ? context.tr.copilot_location_local
                        : _cloudRunning == false
                        ? '${context.tr.copilot_location_remote} · ${_copy('arrêté', 'stopped')}'
                        : _cloudRunning == true
                        ? '${context.tr.copilot_location_remote} · ${_copy('actif', 'running')}'
                        : context.tr.copilot_location_remote,
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
        child: Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final metric in [
              (context.tr.copilot_available, _wallet!['available']),
              (context.tr.copilot_reserved, _wallet!['reserved'] ?? 0),
              (context.tr.copilot_total, _wallet!['balance']),
            ])
              Column(
                mainAxisSize: MainAxisSize.min,
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
                    _credits(metric.$2),
                    softWrap: false,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: context.tr.copilot_action_credits,
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
            context.tr.copilot_welcome_title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr.copilot_welcome_subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          for (final suggestion in [
            (
              Icons.search_rounded,
              context.tr.copilot_suggestion_check_title,
              context.tr.copilot_suggestion_check_prompt,
            ),
            (
              Icons.code_rounded,
              context.tr.copilot_suggestion_command_title,
              context.tr.copilot_suggestion_command_prompt,
            ),
            (
              Icons.lightbulb_outline_rounded,
              context.tr.copilot_suggestion_feature_title,
              context.tr.copilot_suggestion_feature_prompt,
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
              context.tr.copilot_history_section_title,
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
                    user
                        ? context.tr.copilot_role_you
                        : context.tr.copilot_role_assistant,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: user ? colors.onSurfaceVariant : colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (streaming)
                  Text(
                    context.tr.copilot_generating,
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
                    tooltip: context.tr.copilot_copy_message,
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
    final retryPending =
        _pending != null && !_pendingRejected && _error != null;
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
                  Flexible(
                    child: Text(
                      context.tr.copilot_credits_in_discussion(
                        _credits(_chat?['consumed_tokens']),
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
                      hintText: context.tr.copilot_input_hint,
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
                    tooltip: retryPending
                        ? _copy(
                            'Réessayer la demande en attente',
                            'Retry pending request',
                          )
                        : context.tr.copilot_send,
                    onPressed: canSend
                        ? () => _send(null, true, retryPending)
                        : null,
                    icon: Icon(
                      retryPending ? Icons.replay_rounded : Icons.send,
                      size: 19,
                    ),
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
    final cloudPending = _pendingCloudCommand(a);
    final failed = state == 'failed' || state == 'uncertain';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (state == 'executing')
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: colors.onSurfaceVariant,
                  ),
                )
              else
                Icon(
                  state == 'succeeded'
                      ? Icons.check_rounded
                      : failed
                      ? Icons.error_outline_rounded
                      : Icons.tune_rounded,
                  size: 14,
                  color: failed ? colors.error : colors.onSurfaceVariant,
                ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _label(fn['name'] as String),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (state != 'succeeded')
            Padding(
              padding: const EdgeInsets.only(left: 21, top: 2),
              child: Text(
                switch (state) {
                  'pending' =>
                    _mutating(a)
                        ? context.tr.copilot_status_approval_required
                        : context.tr.copilot_status_ready_to_inspect,
                  'executing' => context.tr.copilot_status_executing,
                  'succeeded' => context.tr.copilot_status_succeeded,
                  'declined' => context.tr.copilot_status_declined,
                  'uncertain' => context.tr.copilot_status_unconfirmed,
                  _ => context.tr.copilot_status_failed,
                },
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: failed ? colors.error : colors.onSurfaceVariant,
                ),
              ),
            ),
          if (cloudPending != null &&
              !_cloudRetried.contains(a['call_id'])) ...[
            Text(
              cloudPending['created'] == true
                  ? _copy(
                      'Créée sur Discord, pas encore active sur le bot',
                      'Created on Discord, not yet active on the bot',
                    )
                  : _copy(
                      'Enregistrée, pas encore active sur le bot cloud',
                      'Saved, not yet active on the cloud bot',
                    ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final synced = cloudPending['command_id'] is String
                          ? await _mcp!.syncCloudCommand(
                              cloudPending['bot_id'] as String,
                              cloudPending['command_id'] as String,
                            )
                          : await _mcp!.retryCloudConfiguration(
                              cloudPending['bot_id'] as String,
                            );
                      if (!mounted) return;
                      setState(() {
                        _busy = false;
                        if (synced) {
                          _cloudRetried.add(a['call_id'] as String);
                        } else {
                          _error = _copy(
                            'Commande toujours inactive sur le bot cloud',
                            'Command is still inactive on the cloud bot',
                          );
                        }
                      });
                    },
              child: Text(
                _copy('Réessayer la synchronisation', 'Retry synchronization'),
              ),
            ),
          ],
          if (state == 'pending')
            Wrap(
              children: [
                FilledButton(
                  onPressed: _busy || _chat?['archived'] == true
                      ? null
                      : () => _action(a, true),
                  child: Text(context.tr.copilot_approve),
                ),
                if (_mutating(a))
                  TextButton(
                    onPressed: _busy || _chat?['archived'] == true
                        ? null
                        : () => _action(a, false),
                    child: Text(context.tr.copilot_decline),
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
                          title: Text(context.tr.copilot_close_without_replay),
                          content: Text(
                            context.tr.copilot_close_unconfirmed_warning,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(context.tr.copilot_cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(context.tr.copilot_close_action),
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
              child: Text(context.tr.copilot_close_without_replay),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _pendingCloudCommand(Map<String, dynamic> action) {
    final result = action['result'];
    if (result is! Map) return null;
    final content = result['content'];
    if (content is! List || content.isEmpty || content.first is! Map) {
      return null;
    }
    try {
      final value = jsonDecode((content.first as Map)['text'] as String);
      if (value is Map &&
          value['runner_synced'] == false &&
          value['activation_requires_trigger'] != true &&
          value['bot_id'] is String) {
        return Map<String, dynamic>.from(value);
      }
    } catch (_) {}
    return null;
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
                  context.tr.copilot_history_sheet_title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: context.tr.copilot_search_title_hint,
                  ),
                  onSubmitted: (_) async {
                    try {
                      await _loadHistory();
                      if (ctx.mounted) update(() {});
                    } catch (e) {
                      if (mounted) setState(() => _error = _describe(e));
                    }
                  },
                ),
                if (widget.botId == null)
                  DropdownButtonFormField<String>(
                    initialValue: _botFilter.text.isEmpty
                        ? ''
                        : _botFilter.text,
                    decoration: InputDecoration(
                      labelText: context.tr.copilot_filter_by_bot,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(context.tr.copilot_all_bots),
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
                  title: Text(context.tr.copilot_archives),
                  value: _archives,
                  onChanged: (v) async {
                    _archives = v;
                    try {
                      await _loadHistory();
                      if (ctx.mounted) update(() {});
                    } catch (e) {
                      if (mounted) setState(() => _error = _describe(e));
                    }
                  },
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (_history.isEmpty)
                        Text(context.tr.copilot_no_conversations),
                      for (final c in _history)
                        ListTile(
                          title: Text(c['title'] as String),
                          subtitle: Text(
                            '${c['bot_id'] == '' ? context.tr.copilot_badge_global : c['bot_id']} · ${c['updated_at'] ?? ''}',
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
                          child: Text(context.tr.copilot_load_more),
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
      builders: {'pre': _CodeBuilder(context.tr.copilot_copy_code)},
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

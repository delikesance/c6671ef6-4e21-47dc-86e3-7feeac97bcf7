import 'dart:async';
import 'package:bot_creator_ui/bot_creator_ui.dart'
    show
        CopilotChatSummary,
        copilotToolLabel,
        CopilotComposer,
        CopilotContextHeader,
        CopilotDiscussionsPane,
        CopilotMessageBubble,
        CopilotSidePanel,
        CopilotWalletStrip,
        CopilotWelcome;
import 'dart:convert';
import 'dart:io';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart';
import 'package:bot_creator/features/copilot/presentation/copilot_activity.dart';
import 'package:bot_creator/features/copilot/presentation/copilot_code_preview.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/copilot/logic/copilot_mcp.dart';
import 'package:bot_creator/features/copilot/logic/copilot_catalog.dart';
import 'package:bot_creator/features/copilot/logic/copilot_tool_result.dart';
import 'package:bot_creator/features/subscriptions/presentation/ai_credits_page.dart';
import 'package:bot_creator/features/subscriptions/logic/ai_credit_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

export 'package:bot_creator_ui/bot_creator_ui.dart' show CopilotMarkdown;

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
  final _promptFocus = FocusNode(skipTraversal: true);
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
  // Script d'origine des commandes modifiées (aperçu diff), par call_id.
  final Map<String, String?> _beforeScripts = {};
  final Set<String> _beforeLoading = {};
  Future<void> _draftQueue = Future.value();
  bool _busy = false, _ready = false, _archives = false, _loading = true;
  bool _historyMore = false, _hasPrompt = false;
  bool? _cloudRunning;
  bool _cloudManaged = false;
  final Set<String> _cloudRetried = {};
  String? _error;
  bool _catalogMismatch = false;
  String _partial = '';
  String _lastSentPrompt = '';
  int _cursor = 0, _viewEpoch = 0;
  String? _requestKey;
  String? _summaryKey;
  bool _streamDone = false;
  bool _summarizing = false;
  int _historyEpoch = 0;
  // Disposition desktop (discussions | conversation | panneau latéral).
  static const _wideBreakpoint = 1100.0;
  bool _wide = false;
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

  /// Tokens billed for the response ending at [index]: cache misses + output
  /// (cache hits excluded), summed over the tool loop since the last user turn.
  int _responseTokens(int index) {
    final perMessage = (_chat?['message_tokens'] as List? ?? const []);
    final messages = _messages;
    var total = 0;
    for (var i = index; i >= 0 && i < messages.length; i--) {
      if (messages[i]['role'] == 'user') break;
      if (i < perMessage.length) total += (perMessage[i] as num? ?? 0).toInt();
    }
    return total;
  }

  bool get _hasPendingReads => _actions.any(
    (a) =>
        ['pending', 'executing', 'uncertain'].contains(a['state']) &&
        !_mutating(a),
  );
  CopilotActivityStep _activityStep(Map<String, dynamic> action) {
    final fn = (action['call'] as Map)['function'] as Map;
    final name = fn['name'] as String;
    final state = action['state'];
    final failed = state == 'failed' || state == 'uncertain';
    return CopilotActivityStep(
      label: switch (name) {
        'docs_search' => _copy(
          'Recherche dans la documentation',
          'Searching documentation',
        ),
        'docs_get' => _copy(
          'Lecture de la documentation',
          'Reading documentation',
        ),
        'local_test_command' => _copy(
          'Test dans le sandbox',
          'Testing in the sandbox',
        ),
        _ => _label(name),
      },
      icon: switch (name) {
        'docs_search' => Reicon.outline.search,
        'docs_get' => Reicon.outline.bookOpen,
        'local_test_command' => Reicon.outline.code,
        'local_validate_bdfd' => Reicon.outline.taskSquare,
        'local_runtime_reference' ||
        'local_block_registry' => Reicon.outline.documentCode,
        _ when name.contains('command') || name.contains('workflow') =>
          Reicon.outline.code,
        _ when name.contains('bot') => Reicon.outline.cpu,
        _ => Reicon.outline.search,
      },
      running: state == 'pending' || state == 'executing',
      failed: failed,
      detail: failed
          ? (state == 'failed'
                ? context.tr.copilot_status_failed
                : context.tr.copilot_status_unconfirmed)
          : null,
    );
  }

  List<Widget> _conversationItems() {
    final actions = _actions;
    final placed = <String>{};
    final items = <Widget>[];
    final messages = _messages;
    var steps = <CopilotActivityStep>[];
    String? activityKey;
    void flushActivity() {
      if (steps.isEmpty) return;
      final running = steps.any((step) => step.running);
      items.add(
        CopilotActivity(
          key: ValueKey('activity-${_chat?['id']}-$activityKey'),
          title: running
              ? _copy(
                  'Recherche et vérifications en cours',
                  'Research and checks in progress',
                )
              : _copy('Recherche et vérifications', 'Research and checks'),
          steps: List.of(steps),
        ),
      );
      steps = [];
      activityKey = null;
    }

    for (var messageIndex = 0; messageIndex < messages.length; messageIndex++) {
      final message = messages[messageIndex];
      final role = message['role'];
      if (role != 'user' && role != 'assistant') continue;
      final content = (message['content'] ?? '').toString().trim();
      // The summary request that opens a continuation is an instruction to the
      // model, not something the user wrote.
      if (role == 'user' && content.startsWith('[continuation-summary]')) {
        continue;
      }
      final calls = (message['tool_calls'] as List? ?? const []);
      if (role == 'user' || calls.isEmpty) {
        flushActivity();
        if (role == 'user' || content.isNotEmpty) {
          items.add(
            KeyedSubtree(
              key: ValueKey('message-$messageIndex'),
              child: _messageBubble(
                message,
                tokens: role == 'assistant' ? _responseTokens(messageIndex) : 0,
              ),
            ),
          );
        }
      } else if (content.isNotEmpty) {
        activityKey ??= '$messageIndex';
        steps.add(
          CopilotActivityStep(
            label: _copy('Analyse', 'Analysis'),
            detail: content,
            icon: Reicon.outline.magicStar,
          ),
        );
      }
      if (role != 'assistant') continue;
      for (final call in calls) {
        if (call is! Map) continue;
        final id = call['id']?.toString();
        for (final action in actions) {
          if (id == null || action['call_id'] != id || !placed.add(id)) {
            continue;
          }
          if (_mutating(action)) {
            flushActivity();
            items.add(
              KeyedSubtree(
                key: ValueKey('action-$id'),
                child: _actionCard(action),
              ),
            );
          } else {
            activityKey ??= '$messageIndex';
            steps.add(_activityStep(action));
          }
        }
      }
    }
    for (final action in actions.where((a) => !placed.contains(a['call_id']))) {
      if (_mutating(action)) {
        flushActivity();
        items.add(_actionCard(action));
      } else {
        activityKey ??= 'orphan-${action['call_id']}';
        steps.add(_activityStep(action));
      }
    }
    flushActivity();
    if (_partial.isNotEmpty) {
      items.add(
        _messageBubble({
          'role': 'assistant',
          'content': _partial,
        }, streaming: true),
      );
    } else if (_busy && !_summarizing && !_hasPendingReads) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              AppIcon(
                Reicon.outline.magicStar,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _copy(
                    'Préparation de la réponse…',
                    'Preparing the response…',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
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
    _promptFocus.dispose();
    _prompt.removeListener(_promptChanged);
    _prompt.dispose();
    _scroll.dispose();
    _search.dispose();
    _botFilter.dispose();
    unawaited(_mcp?.close() ?? Future.value());
    super.dispose();
  }

  void _scrollTail({bool force = false}) {
    if (!_scroll.hasClients) return;
    final atBottom = force || _scroll.position.extentAfter <= 48;
    if (!atBottom) return;
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
              HashUtil.calculateHash(
                stripSchemaDescriptions(t['inputSchema']),
              ) !=
              HashUtil.calculateHash(
                stripSchemaDescriptions(
                  bridge.tools.singleWhere(
                    (original) => original['name'] == t['name'],
                  )['inputSchema'],
                ),
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
        case 'ai_insufficient_tokens':
          // Running out mid-turn arrives as a stream error (no HTTP status),
          // so it never reached the 402 branch below.
          return context.tr.copilot_err_insufficient_balance;
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
      } else if (c['archived'] != true && _hasPendingReads) {
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
      if (mounted && !_busy && _chat?['archived'] != true && _hasPendingReads) {
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
    _promptFocus.unfocus();
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
      final bot = (_chat?['bot_id'] ?? widget.botId)?.toString();
      _pending ??= {
        'idempotency_key': const Uuid().v4(),
        'revision': _chat!['revision'],
        'prompt': prompt,
        'tools': _mcp!.tools.map((t) => t['name']).toList(),
        // The server picks its prompt guidance from the bot's engine, so the
        // model neither probes for it nor writes another language.
        if (bot != null && bot.isNotEmpty)
          'runtime_engine': await getBotRuntimeEngine(bot),
      };
      _requestKey = _pending!['idempotency_key'] as String;
      _pendingRejected = false;
      if (prompt.isNotEmpty) _lastSentPrompt = prompt;
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
          // A half-streamed bubble would otherwise stay on screen as if it were the answer.
          _partial = '';
          // Give the text back: the turn failed, and retyping it would also duplicate the user message.
          if (_prompt.text.trim().isEmpty && _lastSentPrompt.isNotEmpty) {
            _prompt.text = _lastSentPrompt;
          }
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
    if (_actions.any((a) => a['state'] == 'executing' && !_mutating(a))) {
      await _waitForReads();
      if (!mounted || _busy || _error != null) return;
    }
    for (final a in _actions) {
      if (['pending', 'uncertain'].contains(a['state']) && !_mutating(a)) {
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

  Future<void> _waitForReads() async {
    if (!mounted || _busy || _chat == null) return;
    final id = _id;
    final epoch = _viewEpoch;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Allow the original read to finish, or the server's two-minute recovery
      // to mark it interrupted. Never replay an in-flight action blindly.
      for (var attempt = 0; attempt < 65; attempt++) {
        if (!mounted || epoch != _viewEpoch) return;
        final latest = await _api!.getAIConversation(id);
        if (!mounted || epoch != _viewEpoch) return;
        setState(() => _chat = latest);
        if (!_actions.any((a) => a['state'] == 'executing' && !_mutating(a))) {
          return;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (mounted && epoch == _viewEpoch) {
        setState(
          () => _error = _copy(
            'La réponse n’est pas encore disponible. Réessayez l’actualisation.',
            'The response is not available yet. Try refreshing again.',
          ),
        );
      }
    } catch (error) {
      if (mounted && epoch == _viewEpoch) {
        setState(() => _error = _describe(error));
      }
    } finally {
      if (mounted && epoch == _viewEpoch) setState(() => _busy = false);
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
                  if (fn['name'] == 'local_create_command_from_library') ...[
                    Text(
                      _copy(
                        'Basée sur la commande « ${args['library_id']} » de la bibliothèque',
                        'Based on library command "${args['library_id']}"',
                      ),
                    ),
                    for (final value
                        in (args['values'] as Map? ?? const {}).entries)
                      Text('${value.key} → ${value.value}'),
                    ..._editLines(args['replacements']),
                  ],
                  if (fn['name'] == 'local_patch_command_execution')
                    ..._editLines(args['edits']),
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
    FocusManager.instance.primaryFocus?.unfocus();
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
      final interruptedRead = a['state'] == 'uncertain' && !_mutating(a);
      if (interruptedRead) {
        // A hidden read must not leave the conversation waiting for manual
        // resolution. Record its interruption before the assistant continues.
        await _api!.aiAction(_id, call, {
          'state': 'failed',
          'result': {'isError': true, 'message': 'Read interrupted.'},
        });
      } else {
        await _api!.aiAction(_id, call, {'approve': approve});
      }
      if (approve && !interruptedRead && !name.startsWith('remote_')) {
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
        } catch (error) {
          result = copilotToolFailure(error);
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

  /// The exact substitutions a patch or a derivation will apply, shown as a small diff.
  List<Widget> _editLines(Object? edits) {
    String clip(Object? value) {
      final text = (value ?? '').toString();
      return text.length > 200 ? '${text.substring(0, 200)}…' : text;
    }

    return [
      if (edits is List)
        for (final edit in edits.whereType<Map>())
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '− ${clip(edit['find'])}\n+ ${clip(edit['replace'])}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
    ];
  }

  String _label(String name) => copilotToolLabel(context, name);
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
            await _api!.deleteAIConversation(_id);
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_draftKey);
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
          if (MediaQuery.sizeOf(context).width < _wideBreakpoint)
            IconButton(
              tooltip: context.tr.copilot_history_tooltip,
              icon: AppIcon.fromMaterial(Icons.history_rounded, size: 21),
              onPressed: _busy ? null : _historySheet,
            ),
          IconButton(
            tooltip: context.tr.copilot_new_discussion,
            icon: AppIcon.fromMaterial(Icons.edit_square, size: 21),
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
              PopupMenuItem(
                value: 'library',
                child: Text(context.tr.copilot_action_library),
              ),
              if (_mcp?.desktop == true &&
                  MediaQuery.sizeOf(context).width < _wideBreakpoint)
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
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= _wideBreakpoint;
            _wide = wide;
            final conversation = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 860 : 980),
                child: Column(
                  children: [
                    _contextHeader(bot, location),
                    SizedBox(
                      height: 4,
                      child: (_loading || _busy)
                          ? const LinearProgressIndicator()
                          : const SizedBox.shrink(),
                    ),
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
                          if (_wallet != null && !_wide) _walletStrip(),
                          if (_summarizing)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                _copy(
                                  'Optimisation du contexte…',
                                  'Optimizing context…',
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
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
                          ..._conversationItems(),
                        ],
                      ),
                    ),
                    _composer(canSend),
                  ],
                ),
              ),
            );
            if (!wide) return conversation;
            return Row(
              children: [
                SizedBox(width: 272, child: _discussionsPane()),
                const VerticalDivider(width: 1, color: AppTheme.homeCardBorder),
                Expanded(child: conversation),
                const VerticalDivider(width: 1, color: AppTheme.homeCardBorder),
                SizedBox(width: 304, child: _sidePanel()),
              ],
            );
          },
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
      case 'library':
        await _libraryDialog();
      default:
        await _menu(choice);
    }
  }

  /// Opt-out of the shared command library: tested commands this account's assistant creates may
  /// be added to it (scrubbed of IDs and secrets) unless the account turns this off.
  Future<void> _libraryDialog() async {
    final api = _api;
    if (api == null) return;
    bool enabled;
    try {
      enabled = await api.getAILibraryContribution();
    } catch (error) {
      if (mounted) setState(() => _error = _describe(error));
      return;
    }
    if (!mounted) return;
    var value = enabled;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(context.tr.copilot_library_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr.copilot_library_hint),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr.copilot_library_contribute),
                value: value,
                onChanged: (next) async {
                  try {
                    final saved = await api.setAILibraryContribution(next);
                    setLocal(() => value = saved);
                  } catch (error) {
                    if (mounted) setState(() => _error = _describe(error));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr.copilot_close),
            ),
          ],
        ),
      ),
    );
  }

  String _credits(Object? value) => formatAiCredits(
    value,
    locale: Localizations.localeOf(context).toString(),
  );

  Widget _contextHeader(String? bot, String location) => CopilotContextHeader(
    isBot: bot != null && bot.isNotEmpty,
    botName: bot == null || bot.isEmpty
        ? ''
        : widget.botName ?? _botNames[bot] ?? bot,
    title: _chat?['title'] as String?,
    local: location == 'local',
    cloudRunning: _cloudRunning,
  );

  Widget _walletStrip() {
    final reserved = (_wallet!['reserved'] as num? ?? 0);
    return CopilotWalletStrip(
      available: _credits(_wallet!['available']),
      reserved: reserved > 0 ? _credits(reserved) : null,
      onOpenCredits: () => _handleMenu('wallet'),
    );
  }

  /// Colonne des discussions (desktop).
  Widget _discussionsPane() => CopilotDiscussionsPane(
    search: _search,
    history: [
      for (final c in _history)
        CopilotChatSummary(id: c['id'] as String, title: c['title'] as String),
    ],
    selectedId: _chat?['id'] as String?,
    busy: _busy,
    hasMore: _historyMore,
    onOpen: (id) => unawaited(_open(id)),
    onSearch: () async {
      try {
        await _loadHistory();
      } catch (e) {
        if (mounted) setState(() => _error = _describe(e));
      }
    },
    onLoadMore: () async {
      try {
        await _loadHistory(more: true);
      } catch (e) {
        if (mounted) setState(() => _error = _describe(e));
      }
    },
  );

  /// Panneau latéral desktop : crédits et capacités, sections repliables.
  Widget _sidePanel() {
    final tools = <String>{
      for (final t in _mcp?.tools ?? const <Map<String, dynamic>>[])
        _label(t['name'] as String),
    };
    final bot = _chat?['bot_id'] ?? widget.botId;
    return CopilotSidePanel(
      available: _wallet == null ? null : _credits(_wallet!['available']),
      consumedInDiscussion: _chat == null
          ? null
          : _credits(_chat?['consumed_tokens']),
      onOpenCredits: () => _handleMenu('wallet'),
      botLabel: bot == null || (bot as String).isEmpty
          ? context.tr.copilot_global_discussion
          : widget.botName ?? _botNames[bot] ?? bot,
      tools: tools,
      onConnection: _mcp?.desktop == true && !_busy ? _connection : null,
    );
  }

  Widget _welcome() => CopilotWelcome(
    ready: _ready,
    history: [
      for (final c in _history)
        CopilotChatSummary(id: c['id'] as String, title: c['title'] as String),
    ],
    onSuggestion: (prompt) => _prompt.text = prompt,
    onOpen: _open,
  );

  Widget _messageBubble(
    Map<String, dynamic> message, {
    bool streaming = false,
    int tokens = 0,
  }) => CopilotMessageBubble(
    content: (message['content'] ?? '').toString(),
    user: message['role'] == 'user',
    streaming: streaming,
    credits: tokens > 0 ? _credits(tokens) : null,
  );

  Widget _composer(bool canSend) {
    final retryPending =
        _pending != null && !_pendingRejected && _error != null;
    return CopilotComposer(
      controller: _prompt,
      focusNode: _promptFocus,
      enabled: _ready,
      canSend: canSend,
      availableCredits: _wallet == null
          ? null
          : _credits(_wallet!['available']),
      retryPending: retryPending,
      onSend: () => _send(null, true, retryPending),
    );
  }

  Map<String, dynamic>? _callArgs(Map<String, dynamic> a) {
    try {
      final fn = (a['call'] as Map)['function'] as Map;
      final decoded = jsonDecode(fn['arguments'] as String);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  /// Script d'origine de la commande, pour le diff de l'aperçu. Lu une seule
  /// fois par action et seulement tant qu'elle attend la validation : après
  /// exécution le stockage contient déjà le nouveau script.
  void _loadBefore(Map<String, dynamic> a, Map<String, dynamic> args) {
    final id = a['call_id'] as String?;
    final bot = args['bot_id'], command = args['command_id'];
    if (id == null ||
        a['state'] != 'pending' ||
        _beforeScripts.containsKey(id) ||
        !_beforeLoading.add(id) ||
        bot is! String ||
        command is! String) {
      return;
    }
    unawaited(() async {
      String? before;
      try {
        final stored = await AppManager().getAppCommand(bot, command);
        var data = Map<String, dynamic>.from(stored['data'] as Map? ?? {});
        final route = args['route'];
        if (route is String && data['subcommandWorkflows'] is Map) {
          final flow = (data['subcommandWorkflows'] as Map)[route];
          if (flow is Map) data = Map<String, dynamic>.from(flow);
        }
        final mode = args['execution_mode'] as String? ?? data['executionMode'];
        final value = mode == 'javascript'
            ? data['jsScriptContent']
            : data['bdfdScriptContent'];
        if (value is String) before = value;
      } catch (_) {}
      _beforeLoading.remove(id);
      if (mounted) setState(() => _beforeScripts[id] = before);
    }());
  }

  Future<void> _openInEditor(Map<String, dynamic> args) async {
    final bot = args['bot_id'], command = args['command_id'];
    if (bot is! String || command is! String) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommandCreatePage(botId: bot, localCommandId: command),
      ),
    );
  }

  Widget _statusLabel(Map<String, dynamic> a, Object? state, bool failed) {
    final text = switch (state) {
      'pending' =>
        _mutating(a)
            ? context.tr.copilot_status_approval_required
            : context.tr.copilot_status_ready_to_inspect,
      'executing' => context.tr.copilot_status_executing,
      'succeeded' => context.tr.copilot_status_succeeded,
      'declined' => context.tr.copilot_status_declined,
      'uncertain' => context.tr.copilot_status_unconfirmed,
      _ => context.tr.copilot_status_failed,
    };
    final waiting = state == 'pending' && _mutating(a);
    final color = waiting
        ? AppTheme.statusWarning
        : failed
        ? AppTheme.statusErrorText
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (waiting) ...[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.statusWarning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: waiting ? FontWeight.w700 : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(Map<String, dynamic> a) {
    final fn = (a['call'] as Map)['function'] as Map;
    final name = fn['name'] as String;
    final state = a['state'];
    final colors = Theme.of(context).colorScheme;
    final cloudPending = _pendingCloudCommand(a);
    final failed = state == 'failed' || state == 'uncertain';
    final args = _callArgs(a);
    final mode = args?['execution_mode'] as String? ?? 'bdfd_script';
    final script = args?['script'];
    final hasCode = copilotActionHasCode(name, script, mode);
    if (hasCode) _loadBefore(a, args!);
    final commandName = args?['name'] ?? args?['command_name'];
    final waiting = state == 'pending' && _mutating(a);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        // Carte discrète : bordure fine, aucun fond relevé.
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.homeCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F222C),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFF272B36)),
                    ),
                    child: Center(
                      child: state == 'executing'
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: colors.onSurfaceVariant,
                              ),
                            )
                          : AppIcon(
                              state == 'succeeded'
                                  ? Reicon.outline.tickCircle
                                  : failed
                                  ? Reicon.outline.infoCircle
                                  : hasCode
                                  ? Reicon.outline.code
                                  : Reicon.outline.setting4,
                              size: 14,
                              color: failed
                                  ? AppTheme.statusErrorText
                                  : const Color(0xFFC9CDD8),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label(name),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          children: [
                            if (commandName is String)
                              Text(
                                '/$commandName',
                                style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 12,
                                  color: Color(0xFFC9CDD8),
                                ),
                              ),
                            if (state != 'succeeded')
                              _statusLabel(a, state, failed),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasCode)
              CopilotCodePreview(
                fileName: commandName is String
                    ? '$commandName.${mode == 'javascript' ? 'js' : 'bdfd'}'
                    : (mode == 'javascript' ? 'script.js' : 'script.bdfd'),
                script: script,
                before: _beforeScripts[a['call_id']],
                bdfd: mode != 'javascript',
                onOpen:
                    args!['bot_id'] is String && args['command_id'] is String
                    ? () => _openInEditor(args)
                    : null,
                openTooltip: _copy('Ouvrir dans l\'éditeur', 'Open in editor'),
                regionLabel: _copy(
                  'Aperçu du code modifié',
                  'Preview of the changed code',
                ),
                validLabel: _copy('Syntaxe valide', 'Valid syntax'),
                errorLabel: _copy('Erreur de syntaxe', 'Syntax error'),
              ),
            if (waiting || failed || cloudPending != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                final synced =
                                    cloudPending['command_id'] is String
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
                          _copy(
                            'Réessayer la synchronisation',
                            'Retry synchronization',
                          ),
                        ),
                      ),
                    ],
                    if (state == 'pending')
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                            ),
                            onPressed:
                                _busy ||
                                    _mcp == null ||
                                    _chat?['archived'] == true
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    _action(a, true);
                                  },
                            child: Text(context.tr.copilot_approve),
                          ),
                          if (_mutating(a))
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                foregroundColor: const Color(0xFFC9CDD8),
                              ),
                              onPressed: _busy || _chat?['archived'] == true
                                  ? null
                                  : () {
                                      FocusScope.of(context).unfocus();
                                      _action(a, false);
                                    },
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
                                    title: Text(
                                      context.tr.copilot_close_without_replay,
                                    ),
                                    content: Text(
                                      context
                                          .tr
                                          .copilot_close_unconfirmed_warning,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(context.tr.copilot_cancel),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                          context.tr.copilot_close_action,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) {
                                  return;
                                }
                                try {
                                  await _api!.aiAction(
                                    _id,
                                    a['call_id'] as String,
                                    {
                                      'state': 'failed',
                                      'result': {
                                        'isError': true,
                                        'message':
                                            'Execution outcome unconfirmed; user acknowledged after inspection. No replay authorized.',
                                      },
                                    },
                                  );
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
              ),
          ],
        ),
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

import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../copilot/copilot_tools.dart';
import '../l10n_ext.dart';
import '../layout.dart';
import '../theme.dart';

/// Onglet « Copilote IA » d'un bot : discussion avec l'assistant qui lit et
/// modifie les commandes, workflows et variables du bot.
///
/// Même protocole que l'app : le serveur propose des appels d'outils, les lectures
/// s'exécutent seules, toute écriture attend l'approbation de l'utilisateur. Le
/// navigateur reçoit la réponse une fois générée (pas de défilement mot à mot).
class CopilotPage extends StatefulWidget {
  const CopilotPage({super.key, required this.api, required this.bot});

  final StudioApi api;
  final StudioBot bot;

  @override
  State<CopilotPage> createState() => _CopilotPageState();
}

class _CopilotPageState extends State<CopilotPage> {
  late final CopilotTools _tools = CopilotTools(widget.api);
  final _prompt = TextEditingController();
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _rng = Random();

  Map<String, dynamic>? _chat;
  List<Map<String, dynamic>> _history = const [];
  Map<String, dynamic>? _wallet;
  bool _busy = false;
  String? _error;
  String? _requestKey;
  Map<String, dynamic>? _pending; // tour en cours d'envoi (rejouable)

  String get _id => '${_chat?['id'] ?? ''}';

  @override
  void initState() {
    super.initState();
    _loadSide();
  }

  @override
  void dispose() {
    _prompt.dispose();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _newKey() => List.generate(
    16,
    (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  Future<void> _loadSide() async {
    try {
      final results = await Future.wait([
        widget.api.aiWallet(),
        widget.api.aiConversations(botId: widget.bot.id),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Map<String, dynamic>;
        _history = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _describe(e));
    }
  }

  String _describe(Object e) {
    if (e is StudioApiException) {
      final code = (e.code ?? '').toLowerCase();
      if (e.statusCode == 402 || code.contains('insufficient')) {
        return context.l10n.copilotNoCredits;
      }
      if (code == 'ai_context_limit') {
        return context.l10n.copilotChatTooLong;
      }
      if (code == 'ai_disabled' || e.statusCode == 503) {
        return context.l10n.copilotUnavailable;
      }
      return e.message;
    }
    return '$e';
  }

  Future<void> _open(String id) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final chat = await widget.api.aiConversation(id);
      if (!mounted) return;
      setState(() {
        _chat = chat;
        _busy = false;
      });
      await _readActions();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _describe(e);
        });
      }
    }
  }

  void _newChat() => setState(() {
    _chat = null;
    _pending = null;
    _requestKey = null;
    _error = null;
  });

  Future<void> _delete(String id) async {
    try {
      await widget.api.deleteAiConversation(id);
      if (_id == id) _newChat();
      await _loadSide();
    } catch (e) {
      if (mounted) setState(() => _error = _describe(e));
    }
  }

  // ── Envoi d'un tour ───────────────────────────────────────────────────────

  Future<void> _send([String? continuation]) async {
    if (_busy) return;
    final text = continuation ?? _prompt.text.trim();
    if (text.isEmpty && continuation == null && _pending == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _chat ??= await widget.api.createAiConversation(
        botId: widget.bot.id,
        title: text.isEmpty
            ? context.tr.copilot_new_discussion
            : (text.length > 60 ? text.substring(0, 60) : text),
      );
      _pending ??= {
        'idempotency_key': _newKey(),
        'revision': _chat!['revision'],
        'prompt': text,
        'tools': CopilotTools.names,
      };
      _requestKey = _pending!['idempotency_key'] as String;
      await widget.api.startAiTurn(_id, _pending!);
      _pending = null;
      if (continuation == null) _prompt.clear();
      if (mounted) setState(() {}); // montre le message tout de suite
      await _follow();
    } catch (e) {
      if (e is StudioApiException &&
          e.code == 'ai_revision_conflict' &&
          _chat != null &&
          _pending != null) {
        try {
          final latest = await widget.api.aiConversation(_id);
          _chat = latest;
          _pending!['idempotency_key'] = _newKey();
          _pending!['revision'] = latest['revision'];
        } catch (_) {}
      } else if (e is StudioApiException && (e.statusCode ?? 0) >= 400) {
        _pending = null;
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _describe(e);
        });
      }
    }
  }

  /// Attend la fin de la génération, relit la conversation puis enchaîne sur les
  /// outils proposés.
  Future<void> _follow() async {
    final key = _requestKey;
    if (key == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    try {
      var failedCode = '';
      final events = await widget.api.aiEvents(_id, key);
      for (final event in events) {
        if (event.kind == 'error') {
          failedCode = '${event.payload['code'] ?? 'generation_failed'}';
        }
      }
      final chat = await widget.api.aiConversation(_id);
      if (!mounted) return;
      if (failedCode.isNotEmpty || chat['last_request_status'] == 'failed') {
        throw StudioApiException(
          context.l10n.copilotGenerationFailed,
          code: failedCode.isEmpty ? '${chat['last_error_code']}' : failedCode,
        );
      }
      setState(() {
        _chat = chat;
        _busy = false;
        _requestKey = null;
      });
      _scrollToEnd();
      unawaited(_refreshWallet());
      await _readActions();
      unawaited(_loadSide());
    } catch (e) {
      Map<String, dynamic>? latest;
      try {
        latest = await widget.api.aiConversation(_id);
      } catch (_) {}
      if (mounted) {
        setState(() {
          if (latest != null) _chat = latest;
          _busy = false;
          _error = _describe(e);
        });
      }
    }
  }

  Future<void> _refreshWallet() async {
    try {
      final w = await widget.api.aiWallet();
      if (mounted) setState(() => _wallet = w);
    } catch (_) {}
  }

  // ── Outils ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _actions => [
    for (final a in ((_chat?['actions'] as List?) ?? const []).whereType<Map>())
      Map<String, dynamic>.from(a),
  ];

  String _toolName(Map<String, dynamic> a) =>
      '${((a['call'] as Map?)?['function'] as Map?)?['name'] ?? ''}';

  bool _needsApproval(Map<String, dynamic> a) =>
      const {'pending', 'uncertain'}.contains(a['state']) &&
      CopilotTools.isMutating(_toolName(a));

  /// Exécute seules les lectures, puis relance le modèle quand tout est réglé.
  Future<void> _readActions() async {
    for (final a in _actions) {
      if (const {'pending', 'uncertain'}.contains(a['state']) &&
          !CopilotTools.isMutating(_toolName(a))) {
        await _action(a, true, continueAfter: false);
        if (_error != null) return;
      }
    }
    final actions = _actions;
    final messages = ((_chat?['messages'] as List?) ?? const []);
    if (actions.isNotEmpty &&
        actions.every(
          (a) => const {'succeeded', 'failed', 'declined'}.contains(a['state']),
        ) &&
        messages.isNotEmpty &&
        (messages.last as Map)['role'] == 'tool') {
      await _send('');
    }
  }

  Future<void> _action(
    Map<String, dynamic> a,
    bool approve, {
    bool continueAfter = true,
  }) async {
    final fn = ((a['call'] as Map)['function'] as Map);
    final name = '${fn['name']}';
    final callId = '${a['call_id']}';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.aiAction(_id, callId, {'approve': approve});
      if (approve && !CopilotTools.serverSide.contains(name)) {
        ToolResult result;
        try {
          final args = Map<String, dynamic>.from(
            jsonDecode('${fn['arguments']}') as Map,
          );
          result = await _tools.run(name, args);
        } catch (e) {
          result = {
            'isError': true,
            'content': [
              {'type': 'text', 'text': '$e'},
            ],
          };
        }
        if (utf8.encode(jsonEncode(result)).length > 24000) {
          result = {
            'message': 'Résultat trop volumineux : relisez plus précisément.',
          };
        }
        await widget.api.aiAction(_id, callId, {
          'state': result['isError'] == true ? 'failed' : 'succeeded',
          'result': result,
        });
      }
      final chat = await widget.api.aiConversation(_id);
      if (!mounted) return;
      setState(() {
        _chat = chat;
        _busy = false;
      });
      if (continueAfter) await _readActions();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _describe(e);
        });
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Affichage ─────────────────────────────────────────────────────────────

  String? get _credits {
    final raw = _wallet?['available'] ?? _wallet?['balance'];
    return raw == null
        ? null
        : formatAiCredits(
            raw,
            locale: Localizations.localeOf(context).toString(),
          );
  }

  List<CopilotChatSummary> get _summaries => [
    for (final c in _history)
      CopilotChatSummary(
        id: '${c['id']}',
        title: '${c['title'] ?? context.tr.copilot_new_discussion}',
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final chat = _chatColumn();
    if (!wide) return chat;
    final scheme = Theme.of(context).colorScheme;
    BoxDecoration side(bool left) => BoxDecoration(
      border: Border(
        left: left ? BorderSide(color: scheme.outlineVariant) : BorderSide.none,
        right: left
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
      ),
    );
    return Row(
      children: [
        Container(
          width: 280,
          decoration: side(false),
          child: CopilotDiscussionsPane(
            search: _search,
            history: _summaries,
            selectedId: _chat == null ? null : _id,
            busy: _busy,
            hasMore: false,
            onOpen: (id) => unawaited(_open(id)),
            onSearch: _loadSide,
            onLoadMore: () {},
          ),
        ),
        Expanded(child: chat),
        Container(
          width: 300,
          decoration: side(true),
          child: CopilotSidePanel(
            available: _credits,
            consumedInDiscussion: _chat == null
                ? null
                : formatAiCredits(
                    _chat?['consumed_tokens'],
                    locale: Localizations.localeOf(context).toString(),
                  ),
            onOpenCredits: () {},
            botLabel: widget.bot.name,
            tools: {for (final t in CopilotTools.names) _toolLabel(t)},
          ),
        ),
      ],
    );
  }

  Widget _chatColumn() {
    final messages = [
      for (final m
          in ((_chat?['messages'] as List?) ?? const []).whereType<Map>())
        Map<String, dynamic>.from(m),
    ];
    final visible = [
      for (final m in messages)
        if ((m['role'] == 'user' || m['role'] == 'assistant') &&
            '${m['content'] ?? ''}'.trim().isNotEmpty)
          m,
    ];
    final approvals = _actions.where(_needsApproval).toList();
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return Column(
      children: [
        CopilotContextHeader(
          botName: widget.bot.name,
          title: _chat?['title'] as String?,
          cloudRunning: widget.bot.stateKnown ? widget.bot.running : null,
        ),
        if (wide && _chat != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _busy ? null : () => _delete(_id),
                icon: const AppIcon.fromMaterial(
                  Icons.delete_outline,
                  size: 16,
                ),
                label: Text(context.l10n.copilotDeleteChat),
              ),
            ),
          ),
        if (!wide)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                if (_credits != null)
                  Expanded(
                    child: CopilotWalletStrip(
                      available: _credits!,
                      onOpenCredits: () {},
                    ),
                  )
                else
                  const Spacer(),
                PopupMenuButton<String>(
                  tooltip: context.tr.copilot_history_section_title,
                  icon: const AppIcon.fromMaterial(Icons.history_rounded),
                  onSelected: (id) => switch (id) {
                    '__new__' => _newChat(),
                    '__delete__' => _delete(_id),
                    _ => _open(id),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: '__new__',
                      child: Text(context.tr.copilot_new_discussion),
                    ),
                    if (_chat != null)
                      PopupMenuItem(
                        value: '__delete__',
                        child: Text(context.l10n.copilotDeleteChat),
                      ),
                    if (_history.isNotEmpty) const PopupMenuDivider(),
                    for (final c in _summaries.take(20))
                      PopupMenuItem(value: c.id, child: Text(c.title)),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              pagePadding(context),
              8,
              pagePadding(context),
              16,
            ),
            children: [
              PageContent(
                maxWidth: 820,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (visible.isEmpty && approvals.isEmpty)
                      CopilotWelcome(
                        ready: !_busy,
                        history: _summaries,
                        onSuggestion: (prompt) => _prompt.text = prompt,
                        onOpen: _open,
                      ),
                    for (final m in visible)
                      CopilotMessageBubble(
                        content: '${m['content']}',
                        user: m['role'] == 'user',
                      ),
                    for (final a in approvals) _approvalCard(a),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: StudioColors.errorText,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        CopilotComposer(
          controller: _prompt,
          enabled: !_busy,
          canSend: !_busy,
          availableCredits: _credits,
          onSend: _send,
        ),
      ],
    );
  }

  Widget _approvalCard(Map<String, dynamic> a) {
    final name = _toolName(a);
    String args;
    try {
      args = const JsonEncoder.withIndent('  ').convert(
        jsonDecode('${((a['call'] as Map)['function'] as Map)['arguments']}'),
      );
    } catch (_) {
      args = '${((a['call'] as Map)['function'] as Map)['arguments']}';
    }
    if (args.length > 1800) args = '${args.substring(0, 1800)}…';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudioColors.card,
        border: Border.all(
          color: StudioColors.premiumGold.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon.fromMaterial(
                Icons.shield_outlined,
                size: 18,
                color: StudioColors.premiumGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.copilotWants(_toolLabel(name)),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: StudioColors.containerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              args,
              style: const TextStyle(
                fontFamily: StudioTheme.monoFamily,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busy ? null : () => _action(a, false),
                child: Text(context.tr.copilot_decline),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : () => _action(a, true),
                child: Text(context.tr.copilot_approve),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _toolLabel(String name) => copilotToolLabel(context, name);
}

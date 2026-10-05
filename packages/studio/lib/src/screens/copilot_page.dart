import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../copilot/copilot_tools.dart';
import '../layout.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
        return 'Crédits IA insuffisants. Rechargez-les depuis l\'app mobile.';
      }
      if (code == 'ai_context_limit') {
        return 'Cette discussion est trop longue : démarrez-en une nouvelle.';
      }
      if (code == 'ai_disabled' || e.statusCode == 503) {
        return 'Le Copilote est indisponible pour le moment.';
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
        title: text.length > 60 ? text.substring(0, 60) : text,
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
          'La génération a échoué.',
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

  String get _balance {
    final raw = _wallet?['available'] ?? _wallet?['balance'];
    if (raw is! num) return '';
    final value = raw.toDouble();
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)} M crédits';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(0)} k crédits';
    return '${value.toStringAsFixed(0)} crédits';
  }

  @override
  Widget build(BuildContext context) {
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
    return Column(
      children: [
        _header(),
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
                    if (visible.isEmpty && approvals.isEmpty) _welcome(),
                    for (final m in visible) _bubble(m),
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
        _composer(),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pagePadding(context),
        12,
        pagePadding(context),
        4,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: StudioColors.actionSoft,
          ),
          const SizedBox(width: 8),
          const Text(
            'Copilote IA',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          if (_balance.isNotEmpty)
            Flexible(
              child: Text(
                _balance,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: StudioColors.muted,
                ),
              ),
            ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Discussions',
            icon: const Icon(Icons.history_rounded),
            onSelected: (id) => id == '__new__' ? _newChat() : _open(id),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '__new__',
                child: Text('Nouvelle discussion'),
              ),
              if (_history.isNotEmpty) const PopupMenuDivider(),
              for (final c in _history.take(20))
                PopupMenuItem(
                  value: '${c['id']}',
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${c['title'] ?? 'Discussion'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        iconSize: 16,
                        onPressed: () {
                          Navigator.of(context).pop();
                          _delete('${c['id']}');
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Nouvelle discussion',
            onPressed: _busy ? null : _newChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
    );
  }

  Widget _welcome() => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Column(
      children: [
        const Icon(
          Icons.auto_awesome_outlined,
          size: 40,
          color: StudioColors.actionSoft,
        ),
        const SizedBox(height: 12),
        Text(
          'Que voulez-vous construire pour ${widget.bot.name} ?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Décrivez une commande, un workflow ou une variable. Le Copilote lit votre bot, propose les changements et ne modifie rien sans votre accord.',
          textAlign: TextAlign.center,
          style: TextStyle(color: StudioColors.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final s in const [
              'Crée une commande /ping qui répond « pong ».',
              'Ajoute un message de bienvenue quand un membre arrive.',
              'Quelles commandes a mon bot ?',
            ])
              ActionChip(
                label: Text(s),
                onPressed: _busy
                    ? null
                    : () {
                        _prompt.text = s;
                        _send();
                      },
              ),
          ],
        ),
      ],
    ),
  );

  Widget _bubble(Map<String, dynamic> m) {
    final user = m['role'] == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 680),
        decoration: BoxDecoration(
          color: user
              ? StudioColors.action.withValues(alpha: 0.18)
              : StudioColors.card,
          border: Border.all(
            color: user
                ? StudioColors.action.withValues(alpha: 0.4)
                : StudioColors.clusterBorder,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          '${m['content']}',
          style: const TextStyle(height: 1.5),
        ),
      ),
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
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: StudioColors.premiumGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le Copilote veut : ${_toolLabel(name)}',
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
                child: const Text('Refuser'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : () => _action(a, true),
                child: const Text('Approuver'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _toolLabel(String name) => switch (name) {
    'local_create_command' => 'créer une commande',
    'local_update_command_execution' => 'modifier les actions d\'une commande',
    'local_create_workflow' => 'créer un workflow',
    'local_update_workflow' => 'modifier un workflow',
    'local_set_variable' => 'définir une variable',
    'remote_start_bot' => 'démarrer le bot',
    'remote_stop_bot' => 'arrêter le bot',
    _ => name,
  };

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          pagePadding(context),
          8,
          pagePadding(context),
          12,
        ),
        child: PageContent(
          maxWidth: 820,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _prompt,
                  minLines: 1,
                  maxLines: 5,
                  enabled: !_busy,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Décrivez ce que vous voulez…',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Envoyer',
                onPressed: _busy ? null : () => _send(),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

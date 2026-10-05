import 'dart:async';

import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _permissionLabels = {
  'can_edit_commands': 'Modifier les commandes',
  'can_start_stop': 'Lancer / arrêter',
  'can_claim_ads': 'Gagner du temps (pubs)',
  'can_invite': 'Inviter',
};

/// Onglet « Équipe » : collaborateurs, droits et tchat d'équipe.
class TeamPage extends StatefulWidget {
  const TeamPage({super.key, required this.api, required this.bot});

  final StudioApi api;
  final StudioBot bot;

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  StudioTeam? _team;
  List<StudioChatMessage> _messages = const [];
  Object? _error;
  Timer? _poll;
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    // Les événements temps réel exigent un en-tête qu'un navigateur ne peut
    // pas envoyer : le tchat est relu à intervalle.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _loadChat());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final team = await widget.api.team(widget.bot.id);
      if (!mounted) return;
      setState(() {
        _team = team;
        _error = null;
      });
      await _loadChat();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadChat() async {
    if (_team?.mine['can_view_chat'] == false) return;
    try {
      final messages = await widget.api.teamChat(widget.bot.id);
      if (mounted) setState(() => _messages = messages);
    } catch (_) {
      // Un échec de relecture ne casse pas la page : on réessaie au prochain tour.
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.sendTeamChat(widget.bot.id, text);
      _input.clear();
      await _loadChat();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is StudioApiException ? e.message : '$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _remove(StudioCollaborator c) async {
    try {
      await widget.api.removeCollaborator(widget.bot.id, c.userId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is StudioApiException ? e.message : '$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _team == null) {
      return ErrorNotice(message: '$_error', onRetry: _load);
    }
    final team = _team;
    if (team == null) return const Center(child: CircularProgressIndicator());
    final canChat = team.mine['can_view_chat'] != false;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: PageContent(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Équipe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Collaborateurs et tchat d\'équipe.',
              style: TextStyle(color: StudioColors.muted),
            ),
            const SizedBox(height: 16),
            for (final c in team.collaborators)
              _CollaboratorRow(
                collaborator: c,
                onRemove: c.isOwner || team.mine['can_invite'] != true
                    ? null
                    : () => _remove(c),
              ),
            const SizedBox(height: 24),
            const Overline('Tchat d\'équipe'),
            const SizedBox(height: 12),
            if (!canChat)
              const Text(
                'Le propriétaire ne vous a pas donné accès au tchat.',
                style: TextStyle(color: StudioColors.muted),
              )
            else ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 360),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: StudioColors.card,
                  border: Border.all(color: StudioColors.clusterBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _messages.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Aucun message.',
                          style: TextStyle(color: StudioColors.muted),
                        ),
                      )
                    : ListView(
                        reverse: true,
                        shrinkWrap: true,
                        children: [
                          for (final m in _messages)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.author,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: StudioColors.actionSoft,
                                    ),
                                  ),
                                  SelectableText(m.content),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Envoyer',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollaboratorRow extends StatelessWidget {
  const _CollaboratorRow({required this.collaborator, this.onRemove});

  final StudioCollaborator collaborator;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = collaborator;
    final granted = [
      for (final e in _permissionLabels.entries)
        if (c.permissions[e.key] == true) e.value,
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: StudioColors.card,
        border: Border.all(color: StudioColors.clusterBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: StudioColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.displayName.isEmpty ? c.userId : c.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  c.isOwner
                      ? 'Propriétaire'
                      : granted.isEmpty
                      ? 'Aucun droit particulier'
                      : granted.join(' · '),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: StudioColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Retirer de l\'équipe',
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_outlined, size: 18),
            ),
        ],
      ),
    );
  }
}

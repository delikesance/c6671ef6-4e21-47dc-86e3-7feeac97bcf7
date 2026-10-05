import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/start_refusal.dart';
import '../l10n_ext.dart';
import '../api/studio_api.dart';
import '../bots/new_bot.dart';
import '../theme.dart';

/// Création d'un bot depuis son jeton Discord.
///
/// Le jeton n'est JAMAIS stocké (ni navigateur, ni journal) : il vit dans le
/// champ de saisie, part en HTTPS vers l'API et est effacé aussitôt.
/// Se ferme sur `true` quand le bot est créé.
class CreateBotDialog extends StatefulWidget {
  const CreateBotDialog({super.key, required this.api});

  final StudioApi api;

  @override
  State<CreateBotDialog> createState() => _CreateBotDialogState();
}

class _CreateBotDialogState extends State<CreateBotDialog> {
  final _token = TextEditingController();
  StudioBotIdentity? _identity;
  bool _busy = false;
  bool _samplePing = true;
  String? _error;

  @override
  void dispose() {
    _token.clear();
    _token.dispose();
    super.dispose();
  }

  String _message(Object e) {
    final refusal = StartRefusal.fromError(e);
    if (refusal != null) return '${refusal.title}. ${refusal.body}';
    if (e is StudioApiException) {
      if (e.code == 'bot_sync_in_progress') {
        return context.l10n.createBotSyncBusy;
      }
      return e.message;
    }
    return '$e';
  }

  Future<void> _verify() async {
    final token = _token.text.trim();
    if (token.isEmpty) return;
    final l =
        context.l10n; // lu avant les `await` : le contexte peut changer ensuite
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final found = await widget.api.validateBotToken(token);
      final id = found.id.isNotEmpty ? found.id : botIdFromToken(token) ?? '';
      if (id.isEmpty) {
        throw StudioApiException(l.createBotNoId);
      }
      if (!mounted) return;
      setState(() => _identity = StudioBotIdentity(id: id, name: found.name));
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final identity = _identity!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.createBot(
        botId: identity.id,
        botToken: _token.text.trim(),
        config: newBotConfig(
          username: identity.name,
          withSamplePing: _samplePing,
        ),
      );
      _token.clear();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _message(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = _identity;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(context.l10n.botsCreate),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _token,
              enabled: !_busy && identity == null,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: context.l10n.createBotToken,
                helperText: context.l10n.createBotTokenHint,
                helperMaxLines: 2,
              ),
              onSubmitted: (_) => _verify(),
            ),
            if (identity != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const AppIcon.fromMaterial(
                    Icons.check_circle_rounded,
                    color: StudioColors.online,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      identity.name.isEmpty
                          ? context.l10n.createBotValidId(identity.id)
                          : context.l10n.createBotValidNamed(identity.name),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _samplePing,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _samplePing = v ?? true),
                title: Text(context.l10n.createBotSamplePing),
              ),
            ],
            if (_busy && identity != null) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                context.l10n.createBotBusy,
                style: TextStyle(fontSize: 12.5, color: StudioColors.muted),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: const TextStyle(color: StudioColors.errorText),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy && identity != null
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(context.l10n.commonCancel),
        ),
        if (identity == null)
          FilledButton(
            onPressed: _busy ? null : _verify,
            child: Text(context.l10n.createBotVerify),
          )
        else
          FilledButton(
            onPressed: _busy ? null : _create,
            child: Text(context.l10n.createBotSubmit),
          ),
      ],
    );
  }
}

import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/start_refusal.dart';
import '../api/studio_api.dart';
import '../bots/new_bot.dart';
import '../l10n_ext.dart';
import '../layout.dart';

/// « Créer un bot » : la même page que l'app (formulaire partagé
/// `BotCreateSetup` : moteur, jeton, sécurité, ressources), branchée sur l'API
/// du Manager. Se ferme sur `true` quand le bot est créé.
///
/// Le jeton n'est JAMAIS stocké (ni navigateur, ni journal) : il vit dans le
/// champ de saisie, part en HTTPS vers l'API et est effacé aussitôt.
class CreateBotPage extends StatefulWidget {
  const CreateBotPage({super.key, required this.api});

  final StudioApi api;

  @override
  State<CreateBotPage> createState() => _CreateBotPageState();
}

class _CreateBotPageState extends State<CreateBotPage> {
  final _token = TextEditingController();
  bool _obscure = true;
  bool _javascript = false;
  bool _saving = false;

  @override
  void dispose() {
    _token.clear();
    _token.dispose();
    super.dispose();
  }

  String _message(Object e) {
    final refusal = StartRefusal.fromError(e);
    if (refusal != null) {
      return '${refusal.title(context.l10n, context.tr)}. '
          '${refusal.body(context.l10n, context.tr)}';
    }
    if (e is StudioApiException) {
      if (e.code == 'bot_sync_in_progress') {
        return context.l10n.createBotSyncBusy;
      }
      return e.message;
    }
    return '$e';
  }

  Future<void> _error(String message) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.tr.error),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.tr.ok),
        ),
      ],
    ),
  );

  /// Comme l'app : une fois le jeton reconnu, on propose la commande `/ping`.
  Future<bool> _askSample(String botName) async {
    final tr = context.tr;
    final answer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.smart_toy_rounded,
              color: Theme.of(ctx).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(tr.app_create_sample_title)),
          ],
        ),
        content: Text(tr.app_create_sample_desc(botName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.app_create_sample_skip),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(tr.app_create_sample_confirm),
          ),
        ],
      ),
    );
    return answer == true;
  }

  Future<void> _save() async {
    final token = _token.text.trim();
    if (_saving || token.isEmpty) return;
    FocusScope.of(context).unfocus();
    final l = context.l10n; // lu avant les `await`
    setState(() => _saving = true);
    try {
      final found = await widget.api.validateBotToken(token);
      final id = found.id.isNotEmpty ? found.id : botIdFromToken(token) ?? '';
      if (id.isEmpty) throw StudioApiException(l.createBotNoId);
      if (!mounted) return;
      final withPing = await _askSample(found.name.isEmpty ? id : found.name);
      if (!mounted) return;
      await widget.api.createBot(
        botId: id,
        botToken: token,
        config: newBotConfig(
          username: found.name,
          withSamplePing: withPing,
          javascript: _javascript,
        ),
      );
      _token.clear();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) await _error(_message(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: pageInsets(context, top: 24),
        child: PageContent(
          maxWidth: 1080,
          child: BotCreateSetup(
            javascript: _javascript,
            onEngineChanged: (value) => setState(() => _javascript = value),
            tokenController: _token,
            obscureToken: _obscure,
            onToggleToken: () => setState(() => _obscure = !_obscure),
            onTokenChanged: (_) => setState(() {}),
            saving: _saving,
            onSave: _token.text.trim().isEmpty || _saving ? null : _save,
            onBack: () => Navigator.of(context).maybePop(),
            showBack: true,
            onPortal: () => openExternalUrl(
              Uri.parse('https://discord.com/developers/applications'),
            ),
            onGuide: () => openExternalUrl(Uri.parse(botTokenTutorialUrl)),
          ),
        ),
      ),
    ),
  );
}

// Page Lavalink = un INTERRUPTEUR « Musique (Lavalink) » + les serveurs de
// repli personnels. Le bot essaie lui-même la liste publique ; l'app ne
// propose donc plus aucun choix de serveur public ni bouton « tester la
// connexion » à la main.
//
// Règle de la maison (NE PAS LA CHANGER) : pour un compte non premium les
// contrôles restent VISIBLES mais GRISÉS, avec un cadenas et la mention
// « 🔒 Disponible avec Bot Creator PREMIUM » — un levier d'abonnement ne se
// masque jamais.
//
// Nuance ajoutée par la règle produit : quand le bot tourne sur CET appareil, la
// musique n'est plus une ressource du serveur — le bot interroge lui-même ses
// serveurs. Le cadrage suit donc l'endroit d'exécution (voir `premium_feature_gate`),
// pas la plateforme : c'est la même page qui se dégrise sur un poste de travail et
// qui reste grisée pour un bot hébergé.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/logic/lavalink_config.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_feature_gate.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:flutter/material.dart';

class LavalinkSettingsSection extends StatefulWidget {
  const LavalinkSettingsSection({
    super.key,
    required this.initialConfig,
    required this.onSave,
    required this.botId,
  });

  /// Contenu persisté de `lavalinkConfig` (schéma figé, ou ancienne forme relue
  /// pour la rétrocompatibilité). `null` = jamais configuré.
  final Map<String, dynamic>? initialConfig;

  /// Persiste la charge utile conforme au schéma figé.
  final Future<void> Function(Map<String, dynamic> config) onSave;

  /// Bot édité : indispensable pour savoir OÙ il s'exécute, et donc si la musique
  /// reste cadrée par la formule (bot sur Bot Creator Server) ou non (bot sur ce
  /// poste — la règle produit ne réserve au serveur que le Running côté serveur).
  final String botId;

  @override
  State<LavalinkSettingsSection> createState() =>
      _LavalinkSettingsSectionState();
}

class _LavalinkSettingsSectionState extends State<LavalinkSettingsSection> {
  final List<_FallbackServerDraft> _servers = <_FallbackServerDraft>[];
  bool _enabled = false;
  bool _saving = false;
  bool _invalidServer = false;
  String _loadedSignature = '';

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.initialConfig);
  }

  @override
  void didUpdateWidget(LavalinkSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final signature = lavalinkConfigSignature(widget.initialConfig);
    if (signature != _loadedSignature) {
      _loadFrom(widget.initialConfig);
    }
  }

  @override
  void dispose() {
    for (final server in _servers) {
      server.dispose();
    }
    super.dispose();
  }

  void _loadFrom(Map<String, dynamic>? raw) {
    _loadedSignature = lavalinkConfigSignature(raw);
    _enabled = lavalinkEnabledFromConfig(raw);
    for (final server in _servers) {
      server.dispose();
    }
    _servers
      ..clear()
      ..addAll(
        lavalinkCustomServersFromConfig(raw).map(
          _FallbackServerDraft.fromConfig,
        ),
      );
  }

  void _addServer() {
    setState(() {
      _servers.add(_FallbackServerDraft.empty());
      _invalidServer = false;
    });
  }

  void _removeServer(int index) {
    setState(() {
      _servers.removeAt(index).dispose();
      _invalidServer = false;
    });
  }

  Future<void> _save() async {
    final servers = <Map<String, dynamic>>[];
    for (final server in _servers) {
      if (server.isEmpty) continue;
      if (!server.isValid) {
        setState(() => _invalidServer = true);
        return;
      }
      servers.add(server.toConfig());
    }

    setState(() {
      _invalidServer = false;
      _saving = true;
    });
    try {
      await widget.onSave(
        buildLavalinkConfigPayload(enabled: _enabled, customServers: servers),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _inputDecoration(ColorScheme scheme) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final scheme = Theme.of(context).colorScheme;
    final inputDecoration = _inputDecoration(scheme);
    // La musique s'exécute ICI (le bot interroge lui-même les serveurs publics) : sur
    // un poste de travail elle n'est donc plus cadrée par la formule tant que le bot
    // tourne sur cet appareil. Règle produit : seul le Running côté serveur l'est.
    final isPremium = premiumCapabilityAvailableForBot(
      PremiumCapability.lavalinkAudio,
      botId: widget.botId,
    );
    final canPurchase = PremiumCapabilities.canShowPurchaseUI;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bandeau premium : le levier d'abonnement reste visible pour un compte
        // non premium, jamais masqué.
        if (!isPremium) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.discord.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.discord.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: AppTheme.discord),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.bot_settings_lavalink_premium_banner_title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.discord,
                        ),
                      ),
                      if (canPurchase)
                        Text(
                          tr.bot_settings_lavalink_premium_banner_desc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (canPurchase) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => SubscriptionPage.show(context),
                    child: Text(tr.bot_settings_lavalink_view_offers),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Volet 1 — l'interrupteur : la seule chose que l'utilisateur pilote.
        Card(
          child: SwitchListTile(
            key: const Key('lavalink_enabled_switch'),
            secondary: Icon(
              isPremium ? Icons.music_note : Icons.lock,
              color: isPremium ? AppTheme.discord : AppTheme.grey,
            ),
            title: Text(
              tr.bot_settings_lavalink_enable_title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              tr.bot_settings_lavalink_enable_subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            value: _enabled,
            onChanged: isPremium
                ? (value) {
                    setState(() {
                      _enabled = value;
                    });
                  }
                : null,
          ),
        ),
        const SizedBox(height: 20),

        // Volet 2 — les serveurs de repli personnels.
        Row(
          children: [
            Icon(
              isPremium ? Icons.dns : Icons.lock,
              size: 18,
              color: isPremium ? AppTheme.discord : AppTheme.grey,
            ),
            const SizedBox(width: 8),
            Text(
              tr.bot_settings_lavalink_fallback_title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          tr.bot_settings_lavalink_fallback_desc,
          style: const TextStyle(fontSize: 12, color: AppTheme.grey),
        ),
        const SizedBox(height: 12),

        if (_servers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              tr.bot_settings_lavalink_no_fallback,
              style: const TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
          ),

        for (var index = 0; index < _servers.length; index++)
          _buildServerCard(
            index: index,
            server: _servers[index],
            isPremium: isPremium,
            inputDecoration: inputDecoration,
          ),

        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('lavalink_add_server_button'),
            onPressed: isPremium ? _addServer : null,
            icon: const Icon(Icons.add),
            label: Text(tr.bot_settings_lavalink_add_fallback),
          ),
        ),

        if (_invalidServer) ...[
          const SizedBox(height: 8),
          Text(
            tr.bot_settings_lavalink_invalid_server,
            style: const TextStyle(fontSize: 12, color: AppTheme.error),
          ),
        ],

        const SizedBox(height: 16),
        Text(
          tr.bot_settings_lavalink_save_caption,
          style: const TextStyle(fontSize: 12, color: AppTheme.grey),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('lavalink_save_button'),
            onPressed: (_saving || !isPremium) ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(tr.bot_settings_lavalink_save_btn),
          ),
        ),
      ],
    );
  }

  Widget _buildServerCard({
    required int index,
    required _FallbackServerDraft server,
    required bool isPremium,
    required InputDecoration inputDecoration,
  }) {
    final tr = context.tr;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (!isPremium)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.lock, size: 16, color: AppTheme.grey),
                  ),
                Expanded(
                  child: Text(
                    tr.bot_settings_lavalink_server_number(index + 1),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  key: Key('lavalink_remove_server_$index'),
                  onPressed: isPremium ? () => _removeServer(index) : null,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: tr.bot_settings_lavalink_remove_fallback,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(tr.bot_settings_lavalink_host),
            const SizedBox(height: 6),
            TextField(
              key: Key('lavalink_server_host_$index'),
              controller: server.hostController,
              enabled: isPremium,
              decoration: inputDecoration.copyWith(
                hintText: tr.bot_settings_lavalink_host_hint,
              ),
            ),
            const SizedBox(height: 12),
            Text(tr.bot_settings_lavalink_port),
            const SizedBox(height: 6),
            TextField(
              key: Key('lavalink_server_port_$index'),
              controller: server.portController,
              enabled: isPremium,
              keyboardType: TextInputType.number,
              decoration: inputDecoration.copyWith(
                hintText: tr.bot_settings_lavalink_port_hint,
              ),
            ),
            const SizedBox(height: 12),
            Text(tr.bot_settings_lavalink_password),
            const SizedBox(height: 6),
            TextField(
              key: Key('lavalink_server_password_$index'),
              controller: server.passwordController,
              enabled: isPremium,
              obscureText: !server.passwordVisible,
              decoration: inputDecoration.copyWith(
                hintText: tr.bot_settings_lavalink_password_hint,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      server.passwordVisible = !server.passwordVisible;
                    });
                  },
                  icon: Icon(
                    server.passwordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),
            ),
            SwitchListTile(
              key: Key('lavalink_server_secure_$index'),
              contentPadding: EdgeInsets.zero,
              title: Text(tr.bot_settings_lavalink_ssl),
              subtitle: Text(
                tr.bot_settings_lavalink_ssl_subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
              value: server.secure,
              onChanged: isPremium
                  ? (value) {
                      setState(() {
                        server.secure = value;
                      });
                    }
                  : null,
              controlAffinity: ListTileControlAffinity.trailing,
            ),
          ],
        ),
      ),
    );
  }
}

/// Brouillon d'un serveur de repli (un par carte de l'UI).
class _FallbackServerDraft {
  _FallbackServerDraft({
    String host = '',
    String port = '',
    String password = '',
    this.secure = false,
  }) : hostController = TextEditingController(text: host),
       portController = TextEditingController(text: port),
       passwordController = TextEditingController(text: password);

  factory _FallbackServerDraft.fromConfig(Map<String, dynamic> config) {
    return _FallbackServerDraft(
      host: (config['host'] ?? '').toString(),
      port: (config['port'] ?? kLavalinkDefaultPort).toString(),
      password: (config['password'] ?? '').toString(),
      secure: config['secure'] == true,
    );
  }

  /// Nouveau serveur : port et mot de passe par défaut, hôte à saisir.
  factory _FallbackServerDraft.empty() => _FallbackServerDraft(
    port: '$kLavalinkDefaultPort',
    password: kLavalinkDefaultPassword,
  );

  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController passwordController;
  bool secure;
  bool passwordVisible = false;

  /// Carte vierge : rien de saisi, elle n'est pas envoyée.
  bool get isEmpty =>
      hostController.text.trim().isEmpty &&
      passwordController.text.trim().isEmpty;

  bool get isValid =>
      isLavalinkServerInputValid(hostController.text, portController.text);

  Map<String, dynamic> toConfig() => <String, dynamic>{
    'host': hostController.text.trim(),
    'port': int.tryParse(portController.text.trim()) ?? kLavalinkDefaultPort,
    'password': passwordController.text,
    'secure': secure,
  };

  void dispose() {
    hostController.dispose();
    portController.dispose();
    passwordController.dispose();
  }
}

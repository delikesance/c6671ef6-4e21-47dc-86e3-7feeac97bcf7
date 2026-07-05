import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:flutter/material.dart';

import 'package:bot_creator/main.dart' show appManager;

class BotConfigVersionsPage extends StatefulWidget {
  final String botId;
  final String botToken;
  final Future<MainApiClient?> Function(String botId, String token) resolveClient;

  const BotConfigVersionsPage({
    super.key,
    required this.botId,
    required this.botToken,
    required this.resolveClient,
  });

  @override
  State<BotConfigVersionsPage> createState() => _BotConfigVersionsPageState();
}

class _BotConfigVersionsPageState extends State<BotConfigVersionsPage> {
  late Future<List<Map<String, dynamic>>> _versionsFuture;
  bool _isRestoring = false;
  bool _isLoadingDiff = false;

  @override
  void initState() {
    super.initState();
    _versionsFuture = _loadVersions();
  }

  void _retry() {
    setState(() {
      _versionsFuture = _loadVersions();
    });
  }

  Future<List<Map<String, dynamic>>> _loadVersions() async {
    final client = await widget.resolveClient(widget.botId, widget.botToken);
    if (client == null) {
      throw Exception('Failed to resolve API client');
    }
    return client.getBotConfigVersions(widget.botId);
  }

  String _formatVersionDate(String key) {
    final filename = key.split('/').last.replaceAll('.json', '');
    final cleaned = filename.replaceAll('T', ' ').replaceAll('h', ':');
    return cleaned;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  List<Map<String, dynamic>> _extractCommandList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (raw is Map) {
      return raw.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  Future<void> _restoreVersion(String versionKey) async {
    setState(() => _isLoadingDiff = true);

    // Fetch version config to show what's inside
    int versionCommandCount = 0;
    List<String> versionCommandNames = const <String>[];
    try {
      final client = await widget.resolveClient(widget.botId, widget.botToken);
      if (client != null) {
        final versionConfig = await client.getBotConfigVersion(
          widget.botId,
          versionKey,
        );
        final commands = _extractCommandList(versionConfig['commands']);
        versionCommandCount = commands.length;
        versionCommandNames = commands
            .map((c) => (c['name'] ?? '?').toString())
            .toList(growable: false);
      }
    } catch (_) {
      // If we can't fetch the version content, still allow restore
    }

    setState(() => _isLoadingDiff = false);

    if (!mounted) return;

    // Get current local command count
    int currentCommandCount = 0;
    try {
      final localCommands = await appManager.listAppCommands(widget.botId);
      currentCommandCount = localCommands.length;
    } catch (_) {}

    final willReplace = versionCommandCount != currentCommandCount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: AppTheme.dialogShape,
        title: Text(context.tr.bot_config_versions_restore),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.discordDarkerBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.discordBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatVersionDate(versionKey),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.code, size: 14, color: AppTheme.grey),
                        const SizedBox(width: 6),
                        Text(
                          '$versionCommandCount commands',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    if (willReplace) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz, size: 14, color: AppTheme.warning),
                          const SizedBox(width: 6),
                          Text(
                            'Will replace $currentCommandCount current commands',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Command list preview (max 8)
              if (versionCommandNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Commands in this version:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.discordText.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                ...versionCommandNames.take(8).map(
                      (name) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          '• $name',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                if (versionCommandNames.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      '… and ${versionCommandNames.length - 8} more',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.discordText.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 12),
              Text(
                context.tr.bot_config_versions_restore_confirm,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.discordText.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr.bot_config_versions_restore),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    try {
      final client = await widget.resolveClient(widget.botId, widget.botToken);
      if (client == null) {
        throw Exception('Failed to resolve API client');
      }
      final success = await client.restoreBotConfigVersion(
        widget.botId,
        versionKey,
      );
      if (!mounted) return;
      if (success) {
        final remoteConfig = await client.getBotConfig(widget.botId);
        if (remoteConfig['inboundWebhooks'] is bool) {
          remoteConfig.remove('inboundWebhooks');
        }
        final localApp = await appManager.getApp(widget.botId);
        if (localApp['avatar'] != null && remoteConfig['avatar'] == null) {
          remoteConfig['avatar'] = localApp['avatar'];
        }
        if (localApp['name'] != null && remoteConfig['name'] == null) {
          remoteConfig['name'] = localApp['name'];
        }
        final token = (localApp['token'] ?? widget.botToken).toString().trim();
        if (token.isNotEmpty) {
          remoteConfig['token'] = token;
        }
        await applyManagerConfigToLocal(
          appManager: appManager,
          botId: widget.botId,
          remoteConfig: remoteConfig,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.bot_config_versions_restored),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.bot_config_versions_restore_error),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.bot_config_versions_restore_error),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.discordDarkBg,
      appBar: AppBar(
        title: Text(context.tr.bot_config_versions_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _versionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.grey,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    context.tr.bot_config_versions_error,
                    style: const TextStyle(
                      color: AppTheme.discordText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  OutlinedButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final versions = snapshot.data ?? [];

          if (versions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history,
                    size: 48,
                    color: AppTheme.grey,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    context.tr.bot_config_versions_empty,
                    style: const TextStyle(
                      color: AppTheme.discordText,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            itemCount: versions.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTheme.spacingSm),
            itemBuilder: (context, index) {
              final version = versions[index];
              final key = (version['key'] ?? '').toString();
              final sizeRaw = version['size'];
              final size = sizeRaw is int
                  ? sizeRaw
                  : int.tryParse(sizeRaw?.toString() ?? '') ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.discordDarkerBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.discordBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatVersionDate(key),
                            style: const TextStyle(
                              color: AppTheme.discordText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatSize(size),
                            style: TextStyle(
                              color: AppTheme.discordText.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isRestoring || _isLoadingDiff)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => _restoreVersion(key),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.discordText,
                          side: const BorderSide(color: AppTheme.discordBorder),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: AppTheme.spacingSm,
                          ),
                        ),
                        child: Text(
                          context.tr.bot_config_versions_restore,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

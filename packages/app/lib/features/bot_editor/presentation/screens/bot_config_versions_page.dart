import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
    // Extract filename from key: configs/{botID}/versions/YYYY-MM-DDTHHhMM.json
    final filename = key.split('/').last.replaceAll('.json', '');
    // Replace the format: YYYY-MM-DDTHHhMM → YYYY-MM-DD HH:MM
    final cleaned = filename.replaceAll('T', ' ').replaceAll('h', ':');
    return cleaned;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  Future<void> _restoreVersion(String versionKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: AppTheme.dialogShape,
        title: Text(context.tr.bot_config_versions_restore),
        content: Text(context.tr.bot_config_versions_restore_confirm),
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
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
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

          // Empty state
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

          // Data state
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
                    if (_isRestoring)
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

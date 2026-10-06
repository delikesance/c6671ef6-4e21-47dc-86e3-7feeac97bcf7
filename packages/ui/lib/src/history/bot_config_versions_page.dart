// L'ÉCRAN DES VERSIONS DE LA CONFIGURATION D'UN BOT : liste, aperçu,
// suppression et restauration (y compris FORCÉE quand le serveur juge la
// version « trop petite »). Partagé entre l'app et le Studio ; tout ce qui
// parle au serveur ou à une copie locale passe par [BotConfigVersionsHost].
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import 'bot_config_versions_host.dart';
import 'history_version_actions.dart';
import 'history_version_preview.dart';

class BotConfigVersionsPage extends StatefulWidget {
  final String botId;
  final BotConfigVersionsHost host;

  const BotConfigVersionsPage({
    super.key,
    required this.botId,
    required this.host,
  });

  @override
  State<BotConfigVersionsPage> createState() => _BotConfigVersionsPageState();
}

class _BotConfigVersionsPageState extends State<BotConfigVersionsPage> {
  late Future<List<BotConfigVersionEntry>> _versionsFuture;
  final Set<String> _deletedVersionKeys = {};
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

  Future<List<BotConfigVersionEntry>> _loadVersions() =>
      widget.host.list(widget.botId);

  String _formatVersionDate(String key, [dynamic timestamp]) {
    final filename = key.split('/').last.replaceAll('.json', '');
    final match = RegExp(
      r'^(\d{4}-\d{2}-\d{2})T(\d{2})h(\d{2})(?:m|h)(\d{2})(?:s)?',
    ).firstMatch(filename);
    final date =
        DateTime.tryParse(timestamp?.toString() ?? '') ??
        (match == null
            ? null
            : DateTime.tryParse(
                '${match[1]}T${match[2]}:${match[3]}:${match[4]}Z',
              ));
    if (date == null) return filename;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_Hms().format(date.toLocal());
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  /// [confirmOvershrink] : restauration FORCÉE, demandée après que le manager a
  /// refusé la version pour cause de plancher de plausibilité. Le drapeau n'est
  /// posé qu'APRÈS un accord explicite (voir [_offerForcedRestore]).
  Future<void> _restoreVersion(
    String versionKey, {
    bool confirmOvershrink = false,
  }) async {
    setState(() => _isLoadingDiff = true);

    // Fetch version config to show what's inside
    int versionCommandCount = 0;
    List<String> versionCommandNames = const <String>[];
    try {
      versionCommandNames = await widget.host.commandNames(
        widget.botId,
        versionKey,
      );
      versionCommandCount = versionCommandNames.length;
    } catch (_) {
      // If we can't fetch the version content, still allow restore
    }

    // The version fetch above is awaited, so this State may already be
    // unmounted. Calling setState on a disposed State throws
    // "Null check operator used on a null value" (issue efce54f8).
    if (!mounted) return;
    setState(() => _isLoadingDiff = false);

    // Get the current command count (what the restore will replace)
    int currentCommandCount = 0;
    try {
      currentCommandCount =
          await widget.host.currentCommandCount(widget.botId) ?? 0;
    } catch (_) {}

    if (!mounted) return;
    final willReplace = versionCommandCount != currentCommandCount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: AppTheme.dialogShape,
        title: Text(context.tr.bot_config_versions_restore),
        scrollable: true,
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
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
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
                        AppIcon.fromMaterial(
                          Icons.code,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.tr.bot_config_version_commands(
                              versionCommandCount,
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    if (willReplace) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AppIcon.fromMaterial(
                            Icons.swap_horiz,
                            size: 14,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              context.tr.bot_config_version_replace_warning(
                                currentCommandCount,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.warning,
                              ),
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
                  context.tr.bot_config_version_commands_title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                ...versionCommandNames
                    .take(8)
                    .map(
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
                      context.tr.bot_config_version_more_count(
                        versionCommandNames.length - 8,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 12),
              Text(
                context.tr.bot_config_versions_restore_confirm,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
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
      // Phase 1 — la décision du serveur. C'est SA raison qu'on veut afficher :
      // jusqu'ici elle était jetée (un `catch (_)` nu), d'où un « échec de la
      // restauration » impossible à expliquer, même en switchant de moteur.
      final result = await widget.host.restore(
        widget.botId,
        versionKey,
        confirmOvershrink: confirmOvershrink,
      );
      if (!mounted) return;
      switch (result.status) {
        case BotConfigRestoreStatus.restored:
          break;
        case BotConfigRestoreStatus.floorRefused:
          // Le plancher protège une POUSSÉE (suppression massive peut-être
          // involontaire). Une restauration, elle, est un retour en arrière
          // DEMANDÉ : on ne reste pas bloqué dessus, on propose de la forcer.
          if (confirmOvershrink) {
            // Même forcée, elle est refusée : le manager n'accepte pas encore la
            // restauration forcée pour cette version. Le dire tel quel plutôt
            // que de laisser croire à une panne de l'application.
            _showRestoreFailure(
              context.tr.bot_config_versions_restore_too_small_unforced,
            );
            return;
          }
          await _offerForcedRestore(versionKey);
          return;
        case BotConfigRestoreStatus.notConfirmed:
          _showRestoreFailure(context.tr.bot_config_versions_restore_refused);
          return;
        case BotConfigRestoreStatus.failed:
          _showRestoreFailure(
            context.tr.bot_config_versions_restore_error_detail(
              result.reason ?? '',
            ),
          );
          return;
      }

      // Phase 2 — application locale. Le serveur A restauré : le dire autrement
      // serait mentir sur l'état réel du bot (et rendre le diagnostic suivant
      // incompréhensible).
      try {
        await widget.host.applyRestoredLocally(widget.botId);
      } catch (error) {
        if (!mounted) return;
        _showRestoreFailure(
          context.tr.bot_config_versions_restore_local_failed(
            _describeFailure(error),
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.bot_config_versions_restored),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _showRestoreFailure(
        context.tr.bot_config_versions_restore_error_detail(
          _describeFailure(error),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  /// Propose de FORCER la restauration que le manager a refusée.
  ///
  /// POURQUOI une question plutôt qu'un refus sec : le plancher de plausibilité
  /// protège une POUSSÉE — une suppression massive possiblement accidentelle.
  /// Une restauration est l'inverse : un retour en arrière explicitement
  /// demandé, dont la version a déjà tourné pour ce bot. Poser la question
  /// laisse la décision à l'utilisateur au lieu de la lui interdire.
  Future<void> _offerForcedRestore(String versionKey) async {
    final agreed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.bot_config_versions_force_restore_title,
      content: context.tr.bot_config_versions_force_restore_body,
      confirmLabel: context.tr.bot_config_versions_force_restore_confirm,
      cancelLabel: context.tr.bot_config_versions_force_restore_keep,
      isDestructive: true,
    );
    if (!agreed || !mounted) return;
    await _restoreVersion(versionKey, confirmOvershrink: true);
  }

  /// Affiche la raison RÉELLE d'un échec de restauration.
  ///
  /// POURQUOI : l'écran n'affichait qu'un « échec de la restauration » muet,
  /// sans rien du serveur — impossible de distinguer une version disparue, un
  /// refus d'API ou un moteur dépareillé. La raison part aussi au journal de
  /// diagnostic, consultable après coup.
  void _showRestoreFailure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  /// Réduit une exception à une raison lisible : statut, code d'API, message.
  ///
  /// Le code est la partie stable du contrat (cf. `MainApiClientException`) :
  /// c'est lui qui permet de nommer la cause, pas la phrase du serveur.
  String _describeFailure(Object error) => widget.host.describeError(error);

  Future<void> _previewVersion(String key) async {
    if (_isLoadingDiff || _isRestoring) return;
    setState(() => _isLoadingDiff = true);
    try {
      await showHistoryVersionPreview(
        context,
        load: () => widget.host.preview(widget.botId, key),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDiff = false);
    }
  }

  Future<void> _deleteVersion(String key) async {
    if (_isLoadingDiff || _isRestoring) return;
    setState(() => _isLoadingDiff = true);
    try {
      final confirmed = await AppTheme.showConfirmDialog(
        context,
        title: context.tr.common_delete,
        content: context.tr.history_delete_confirm,
        confirmLabel: context.tr.common_delete,
        cancelLabel: context.tr.common_cancel,
        isDestructive: true,
      );
      if (!confirmed || !mounted) return;
      await widget.host.delete(widget.botId, key);
      if (mounted) {
        setState(() => _deletedVersionKeys.add(key));
      }
    } catch (_) {
      if (mounted) _showRestoreFailure(context.tr.history_action_failed);
    } finally {
      if (mounted) setState(() => _isLoadingDiff = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr.bot_config_versions_title),
        actions: [
          IconButton(
            icon: AppIcon.fromMaterial(Icons.refresh_rounded),
            tooltip: context.tr.common_retry,
            onPressed: _isRestoring || _isLoadingDiff ? null : _retry,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<BotConfigVersionEntry>>(
          future: _versionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon.fromMaterial(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        context.tr.bot_config_versions_error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      OutlinedButton(
                        onPressed: _retry,
                        child: Text(context.tr.common_retry),
                      ),
                    ],
                  ),
                ),
              );
            }

            final versions = (snapshot.data ?? [])
                .where((version) => !_deletedVersionKeys.contains(version.key))
                .toList(growable: false);

            if (versions.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon.fromMaterial(
                        Icons.history,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        context.tr.bot_config_versions_empty,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXxl,
                        ),
                        child: Text(
                          context.tr.bot_config_versions_checkpoint_hint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final colors = Theme.of(context).colorScheme;
            final busy = _isRestoring || _isLoadingDiff;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  itemCount: versions.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTheme.spacingSm),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppIcon.fromMaterial(
                                  Icons.cloud_done_rounded,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                Expanded(
                                  child: Text(
                                    context
                                        .tr
                                        .bot_config_versions_cloud_checkpoints,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Text(
                              context.tr.bot_config_versions_checkpoint_hint,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }
                    final version = versions[index - 1];
                    final key = version.key;
                    return Card(
                      key: ValueKey(key),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatVersionDate(key, version.time),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingXs,
                                      ),
                                      Text(
                                        _formatSize(version.size),
                                        style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                HistoryVersionDeleteButton(
                                  onDelete: busy
                                      ? null
                                      : () => _deleteVersion(key),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            HistoryVersionActions(
                              onPreview: busy
                                  ? null
                                  : () => _previewVersion(key),
                              onRestore: busy
                                  ? null
                                  : () => _restoreVersion(key),
                              restoreLabel:
                                  context.tr.bot_config_versions_restore,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

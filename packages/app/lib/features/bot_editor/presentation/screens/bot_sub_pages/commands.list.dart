import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/storage/app_storage_directory.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';
import 'package:bot_creator/features/marketplace/presentation/marketplace_page.dart';
import 'package:bot_creator/features/marketplace/presentation/publish_template_page.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/ads/logic/ads_placement_policy.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/features/ads/presentation/native_ad_slot.dart';
import 'package:bot_creator/core/widgets/notion_filter_bar.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_refresh.dart';
import 'package:bot_creator/features/bot_editor/logic/command_folder_tree.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/folder_picker_dialog.dart';
import 'package:bot_creator_shared/utils/legacy_command_triggers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/core/theme/app_theme.dart';

import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

class AppCommandsPage extends StatefulWidget {
  final NyxxRest? client;
  final String botId;
  const AppCommandsPage({super.key, required this.botId, this.client});

  @override
  State<AppCommandsPage> createState() => _AppCommandsPageState();
}

class _AppCommandsPageState extends State<AppCommandsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _commands = <Map<String, dynamic>>[];
  bool _loading = true;
  final Set<String> _emptyFolders = {};
  bool _isReorderMode = false;
  final Set<String> _expandedFolders = {};
  // commandId -> folder name (empty string = no folder)
  Map<String, String> _reorderFolderMap = {};
  String _searchQuery = '';
  String _typeFilter = 'all';
  String _folderFilter = '';
  bool _showTemplateOnly = false;
  bool _showLegacyOnly = false;
  bool _isSelectMode = false;
  final Set<String> _selectedCommandIds = {};

  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView(
      screenName: "AppCommandsPage",
      screenClass: "AppCommandsPage",
      parameters: {"app_id": widget.botId},
    );
    BotConfigRefreshNotifier.instance.addListener(_onConfigReplaced);
    _load();
  }

  @override
  void dispose() {
    BotConfigRefreshNotifier.instance.removeListener(_onConfigReplaced);
    super.dispose();
  }

  /// La configuration de CE bot vient d'être remplacée depuis le serveur
  /// (restauration de version, synchro entrante). [_commands] est une copie
  /// locale : sans relecture, la page continue d'afficher l'ancien état — c'est
  /// ce qui faisait qu'une restauration ne se voyait pas ici.
  void _onConfigReplaced() {
    if (!mounted || BotConfigRefreshNotifier.instance.botId != widget.botId) {
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final commands = await appManager.listAppCommands(widget.botId);
    await _loadEmptyFolders();
    if (!mounted) return;
    setState(() {
      _commands = commands;
      _loading = false;
    });
  }

  Future<String> _getEmptyFoldersPath() async {
    final storagePath = await getAppStoragePath();
    return '$storagePath/apps/${widget.botId}/_empty_folders.json';
  }

  Future<void> _loadEmptyFolders() async {
    try {
      final path = await _getEmptyFoldersPath();
      final file = File(path);
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final list = (jsonDecode(content) as List).cast<String>();
      _emptyFolders.addAll(list);
    } catch (_) {
      // Ignore errors loading empty folders
    }
  }

  Future<void> _saveEmptyFolders() async {
    try {
      final path = await _getEmptyFoldersPath();
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(_emptyFolders.toList()));
    } catch (_) {
      // Ignore errors saving empty folders
    }
  }

  /// Resolves a [MainApiClient] with a valid Manager session.
  Future<MainApiClient?> _resolveApiClient() async {
    final config = await MainApiSettingsStore.loadConfig();
    if (!config.isConfigured) return null;
    final session = await MainApiSettingsStore.loadSession();
    if (session != null && !session.isExpired) {
      return MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
    }
    return null;
  }

  /// Returns the current user's display name.
  Future<String> _resolveAuthorName() async {
    final session = await MainApiSettingsStore.loadSession();
    return session?.username ?? session?.userId ?? 'Unknown';
  }

  Snowflake? _toSnowflake(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      return null;
    }
    return Snowflake(parsed);
  }

  Widget _buildCommandCard(Map<String, dynamic> command) {
    final commandId = (command['id'] ?? '').toString();
    final snowflake = _toSnowflake(
      (command['discordId'] ?? commandId).toString(),
    );
    final templateOrigin = command['templateOrigin'] as Map<String, dynamic>?;
    final templateId = (templateOrigin?['templateId'] ?? '').toString();
    final name = (command['name'] ?? 'unknown').toString();

    final cardWidget = Card(
      child: ListTile(
        leading: _isSelectMode
            ? Checkbox(
                value: _selectedCommandIds.contains(commandId),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedCommandIds.add(commandId);
                    } else {
                      _selectedCommandIds.remove(commandId);
                    }
                  });
                },
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isSelectMode) ...[
              IconButton(
                icon: const AppIcon.fromMaterial(
                  Icons.drive_file_move_outlined,
                  size: 20,
                ),
                tooltip: context.tr.commands_move_to_folder,
                onPressed: () => _showMoveCommandDialog(command),
              ),
              IconButton(
                icon: AppIcon.fromMaterial(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: context.tr.delete,
                onPressed: () => _deleteCommand(commandId, name),
              ),
            ],
            const AppIcon.fromMaterial(Icons.arrow_forward_ios_outlined),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                (command['name'] ?? 'unknown').toString(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (templateId.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon.fromMaterial(
                      Icons.auto_awesome,
                      size: 12,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      templateId,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: _buildCommandSubtitle(command),
        isThreeLine: false,
        minVerticalPadding: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        onLongPress: () {
          if (!_isReorderMode) _enterReorderMode();
        },
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommandCreatePage(
                client: widget.client,
                botId: widget.botId,
                id: snowflake ?? Snowflake.zero,
                localCommandId: commandId,
              ),
            ),
          );
          if (!mounted) {
            return;
          }
          _load();
        },
      ),
    );

    if (_isSelectMode || _isReorderMode) {
      return cardWidget;
    }

    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final feedbackWidget = Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.terminal_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Draggable<Map<String, dynamic>>(
        data: command,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedbackWidget,
        childWhenDragging: Opacity(opacity: 0.35, child: cardWidget),
        child: cardWidget,
      );
    }

    return LongPressDraggable<Map<String, dynamic>>(
      data: command,
      hapticFeedbackOnStart: true,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: feedbackWidget,
      childWhenDragging: Opacity(opacity: 0.35, child: cardWidget),
      child: cardWidget,
    );
  }

  List<Widget> _buildCommandMetaChips(Map<String, dynamic> command) {
    final data = Map<String, dynamic>.from(
      (command['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    (command['type'] ?? data['commandType'] ?? 'chatInput').toString();
    final optionsCount = (data['options'] as List?)?.length ?? 0;
    final actionsCount = (data['actions'] as List?)?.length ?? 0;
    final subcommandCount = (data['subcommandWorkflows'] as Map?)?.length ?? 0;
    final legacyMode = data['legacyModeEnabled'] == true;
    final legacyLocal = data['legacyLocalOnly'] == true;

    final chips = <Widget>[
      _CommandMetaChip(
        icon: legacyLocal ? Icons.history_toggle_off : Icons.bolt_outlined,
      ),
      _CommandMetaChip(label: '$optionsCount', icon: Icons.tune),
      _CommandMetaChip(
        label: '$actionsCount',
        icon: Icons.account_tree_outlined,
      ),
    ];
    if (subcommandCount > 0) {
      chips.add(
        _CommandMetaChip(label: '$subcommandCount', icon: Icons.route_outlined),
      );
    }
    if (legacyMode && !legacyLocal) {
      chips.add(const _CommandMetaChip(icon: Icons.history_toggle_off));
    }
    if (legacyLocal) {
      chips.add(const _CommandMetaChip(icon: Icons.offline_bolt));
    }
    return chips;
  }

  /// Sous-titre d'une carte de commande : badges existants, puis chips d'alias
  /// pour les commandes Message Texte qui en ont. Sans alias, la rangée de
  /// badges est identique à avant.
  Widget _buildCommandSubtitle(Map<String, dynamic> command) {
    final aliasChips = _buildCommandAliasChips(command);
    final folder = normalizeFolderPath((command['folder'] ?? '').toString());
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (folder.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon.fromMaterial(
                  Icons.folder_outlined,
                  size: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Text(
                  folder,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
        ..._buildCommandMetaChips(command),
        if (aliasChips.isNotEmpty)
          Flexible(
            child: Wrap(spacing: 4, runSpacing: 4, children: aliasChips),
          ),
      ],
    );
  }

  /// Chips discrètes des alias (`!alias`) d'une commande Message Texte.
  ///
  /// Renvoie une liste vide pour les commandes sans alias, afin de ne pas
  /// changer leur rendu.
  List<Widget> _buildCommandAliasChips(Map<String, dynamic> command) {
    final data = Map<String, dynamic>.from(
      (command['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    if (data['legacyModeEnabled'] != true) {
      return const <Widget>[];
    }
    final aliases = normalizeLegacyCommandAliases(data['legacyAliases']);
    final colorScheme = Theme.of(context).colorScheme;
    return [
      for (final alias in aliases)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            _aliasChipLabel(alias),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
    ];
  }

  /// Étiquette affichée sur une chip d'alias : `!mot`.
  String _aliasChipLabel(String alias) => '!$alias';

  Future<void> _deleteCommand(String commandId, String name) async {
    final confirmed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.delete,
      content: context.tr.cmd_delete_confirm(name),
      confirmLabel: context.tr.confirm,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await appManager.deleteAppCommand(widget.botId, commandId);
    unawaited(refreshBotRuntime(widget.botId));
    await _load();

    // Fallback: old buggy commands may have a different filename than internal id.
    // If the command still appears, scan the directory for files with matching name.
    if (mounted && _commands.any((c) => (c['id'] ?? '') == commandId)) {
      await _forceDeleteCommandByScan(name);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.cmd_delete_success(name))),
    );
    await _load();
  }

  /// Fallback for buggy commands whose filename doesn't match their internal id.
  /// Scans all command files in the bot directory and deletes the one whose
  /// decoded `name` field matches [name].
  Future<void> _forceDeleteCommandByScan(String name) async {
    final storagePath = await getAppStoragePath();
    final dir = Directory('$storagePath/apps/${widget.botId}');
    if (!await dir.exists()) return;
    final entities = await dir.list().toList();
    for (final entity in entities) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final content = await entity.readAsString();
        if (content.trim().isEmpty) continue;
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final decodedName = (decoded['name'] ?? '').toString();
        if (decodedName.toLowerCase() == name.toLowerCase()) {
          await entity.delete();
          return;
        }
      } catch (_) {}
    }
  }

  List<Map<String, dynamic>> _visibleCommands() {
    final query = _searchQuery.trim().toLowerCase();
    return _commands
        .where((command) {
          final data = Map<String, dynamic>.from(
            (command['data'] as Map?)?.cast<String, dynamic>() ?? const {},
          );
          final type = (command['type'] ?? data['commandType'] ?? 'chatInput')
              .toString();
          final folder = (command['folder'] ?? '').toString().trim();
          final templateId =
              ((command['templateOrigin']
                          as Map<String, dynamic>?)?['templateId'] ??
                      '')
                  .toString()
                  .trim();
          final legacyMode = data['legacyModeEnabled'] == true;
          final legacyLocal = data['legacyLocalOnly'] == true;
          final name = (command['name'] ?? '').toString().toLowerCase();
          final description = (command['description'] ?? '')
              .toString()
              .toLowerCase();
          // Les alias des commandes Message Texte comptent comme des
          // correspondances : taper `p` ou `!p` retrouve la commande.
          final aliasQuery = query.startsWith('!') ? query.substring(1) : query;
          final aliases = normalizeLegacyCommandAliases(data['legacyAliases']);
          if (_typeFilter == 'legacy') {
            if (!legacyMode) return false;
          } else if (_typeFilter != 'all' && type != _typeFilter) {
            return false;
          }
          if (_folderFilter.isNotEmpty &&
              folder != _folderFilter &&
              !folder.startsWith('$_folderFilter/')) {
            return false;
          }
          if (_showTemplateOnly && templateId.isEmpty) {
            return false;
          }
          if (_showLegacyOnly && !legacyLocal) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          final matchesAlias =
              aliasQuery.isNotEmpty &&
              aliases.any((alias) => alias.contains(aliasQuery));
          return name.contains(query) ||
              description.contains(query) ||
              folder.toLowerCase().contains(query) ||
              templateId.toLowerCase().contains(query) ||
              matchesAlias;
        })
        .toList(growable: false);
  }

  Future<void> _handleCreateMenuSelection(String selection) async {
    if (selection == 'command') {
      await _navigateToCreateCommand();
      return;
    }

    if (selection == 'template') {
      final client = await _resolveApiClient();
      if (!mounted) return;
      if (client != null) {
        final applied = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MarketplacePage(botId: widget.botId, apiClient: client),
          ),
        );
        if (applied == true && mounted) {
          _load();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.marketplace_connect_manager)),
        );
      }
      return;
    }

    if (selection == 'folder') {
      await _showCreateFolderDialog();
    }
  }

  Widget _buildFiltersBar() {
    final query = _searchQuery.trim();
    return NotionFilterBar(
      searchQuery: _searchQuery,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      searchHint: context.tr.commands_search_hint,
      addFilterLabel: context.tr.notion_filter_add,
      filters: [
        NotionFilter(
          id: 'type',
          label: context.tr.commands_filter_type_label,
          icon: Icons.category_outlined,
          options: {
            '': context.tr.common_all,
            'chatInput': context.tr.command_type_slash,
            'user': context.tr.command_type_user,
            'message': context.tr.command_type_message,
            'legacy': context.tr.command_type_legacy,
          },
          selectedValue: _typeFilter == 'all' ? '' : _typeFilter,
        ),
        if (_existingFolders.isNotEmpty)
          NotionFilter(
            id: 'folder',
            label: context.tr.commands_folder_label,
            icon: Icons.folder_outlined,
            options: {
              '': context.tr.commands_all_folders,
              for (final item in buildCommandFolderTree(
                commands: _commands,
                emptyFolders: _emptyFolders,
              ).flatten())
                item.fullPath: item.indentedLabel,
            },
            selectedValue: _folderFilter,
          ),
      ],
      toggleFilters: [
        NotionToggleFilter(
          id: 'template',
          label: context.tr.commands_filter_template,
          icon: Icons.auto_awesome,
          enabled: _showTemplateOnly,
        ),
        NotionToggleFilter(
          id: 'legacy_local',
          label: context.tr.commands_filter_legacy_local,
          icon: Icons.storage_outlined,
          enabled: _showLegacyOnly,
        ),
      ],
      onFilterChanged: (filterId, value) {
        setState(() {
          if (filterId == 'type') {
            _typeFilter = value.isEmpty ? 'all' : value;
          } else if (filterId == 'folder') {
            _folderFilter = value;
          }
        });
      },
      onToggleFilterChanged: (filterId, enabled) {
        setState(() {
          if (filterId == 'template') {
            _showTemplateOnly = enabled;
          } else if (filterId == 'legacy_local') {
            _showLegacyOnly = enabled;
          }
        });
      },
      showCreateSuggestion: query.isNotEmpty,
      createFromQueryLabel: context.tr.commands_create_from_query(query),
      onCreateFromQuery: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommandCreatePage(
              client: widget.client,
              botId: widget.botId,
              prefillName: query,
            ),
          ),
        );
        if (!mounted) return;
        _load();
      },
      trailingAction: _isReorderMode
          ? null
          : PopupMenuButton<String>(
              tooltip: context.tr.commands_create_button,
              offset: const Offset(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              onSelected: _handleCreateMenuSelection,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'command',
                  child: Row(
                    children: [
                      const AppIcon.fromMaterial(
                        Icons.add_circle_outline,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(context.tr.commands_create_button),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'template',
                  child: Row(
                    children: [
                      const AppIcon.fromMaterial(Icons.auto_awesome, size: 20),
                      const SizedBox(width: 12),
                      Text(context.tr.marketplace_title),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'folder',
                  child: Row(
                    children: [
                      const AppIcon.fromMaterial(
                        Icons.create_new_folder_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(context.tr.commands_create_folder),
                    ],
                  ),
                ),
              ],
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandPrimary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon.fromMaterial(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr.create,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Set<String> get _existingFolders {
    final folders = <String>{};
    for (final c in _commands) {
      final f = normalizeFolderPath((c['folder'] ?? '').toString());
      if (f.isNotEmpty) {
        var cur = f;
        while (cur.isNotEmpty) {
          folders.add(cur);
          cur = folderParentPath(cur);
        }
      }
    }
    for (final e in _emptyFolders) {
      final f = normalizeFolderPath(e);
      if (f.isNotEmpty) {
        var cur = f;
        while (cur.isNotEmpty) {
          folders.add(cur);
          cur = folderParentPath(cur);
        }
      }
    }
    return folders;
  }

  Future<void> _navigateToCreateCommand({String? prefillFolder}) async {
    final countBefore = _commands.length;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommandCreatePage(
          client: widget.client,
          botId: widget.botId,
          prefillFolder: prefillFolder,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    // S6: Post-save guidance — only when a brand-new command was actually added.
    if (_commands.length > countBefore) {
      await _showPostSaveGuidance();
    }
  }

  /// F12: Creates a sample /ping command directly from the empty state.
  /// This gives users a one-click recovery if they missed the initial
  /// sample dialog during bot creation.
  Future<void> _addSamplePingCommand() async {
    final now = DateTime.now().toIso8601String();
    final commandId = 'sample_ping_${DateTime.now().millisecondsSinceEpoch}';
    final sampleCommand = <String, dynamic>{
      'name': 'ping',
      'description': 'Check if the bot is responsive',
      'type': 'chatInput',
      'id': commandId,
      'createdAt': now,
      'updatedAt': now,
      'data': <String, dynamic>{
        'version': 1,
        'commandType': 'chatInput',
        'editorMode': 'advanced',
        'executionMode': 'workflow',
        'bdfdScriptContent': '',
        'legacyModeEnabled': false,
        'legacyLocalOnly': false,
        'legacyPrefixOverride': '',
        'legacyResponseTarget': 'reply',
        'simpleConfig': <String, dynamic>{},
        'defaultMemberPermissions': '',
        'actions': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'respondWithMessage',
            'key': 'sample_ping_response',
            'enabled': true,
            'payload': <String, dynamic>{
              'content': 'Pong!',
              'embeds': <Map<String, dynamic>>[],
              'components': <String, dynamic>{},
            },
          },
        ],
        'options': <Map<String, dynamic>>[],
        'integrationTypes': <int>[1],
        'contexts': <int>[0],
      },
    };

    try {
      await appManager.saveAppCommand(widget.botId, commandId, sampleCommand);
      AppAnalytics.logEvent(
        name: 'add_sample_ping_from_empty',
        parameters: {'bot_id': widget.botId},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.command_created_sample_success),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.success,
          ),
        );
        await _load();
        if (mounted) await _showPostSaveGuidance();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.tr.error}: $e')));
      }
    }
  }

  /// S6 helper: best-effort check of whether [widget.botId] is currently
  /// running on any resolved remote runtime. Defaults to [false] on any error
  /// or timeout so the "Start my bot" CTA remains available and the post-save
  /// sheet is not delayed.
  Future<bool> _isBotCurrentlyRunning() async {
    try {
      final resolved = await resolveRemoteRuntime(
        supportsManagerRuntime: true,
        botId: widget.botId,
      ).timeout(const Duration(seconds: 4));
      final client = resolved.client;
      if (client == null) return false;
      final status = await client
          .getStatus(botId: widget.botId)
          .timeout(const Duration(seconds: 4));
      return status.isBotRunning(widget.botId);
    } catch (_) {
      return false;
    }
  }

  /// Shared helper that opens the Marketplace flow (resolved Manager client
  /// required). Used by both the guided empty state and the create menu.
  Future<void> _openMarketplace() async {
    final client = await _resolveApiClient();
    if (!mounted) return;
    if (client != null) {
      final applied = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MarketplacePage(botId: widget.botId, apiClient: client),
        ),
      );
      if (applied == true && mounted) {
        _load();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.marketplace_connect_manager)),
      );
    }
  }

  Future<void> _openPublishTemplate() async {
    final client = await _resolveApiClient();
    final authorName = await _resolveAuthorName();
    final session = await MainApiSettingsStore.loadSession();
    final authorId = session?.userId ?? 'unknown';
    if (!mounted) return;
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.marketplace_connect_publish)),
      );
      return;
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PublishTemplatePage(
          botId: widget.botId,
          apiClient: client,
          authorId: authorId,
          authorName: authorName,
        ),
      ),
    );
    if (result == true && mounted) {
      _load();
    }
  }

  /// S6: Post-save guidance sheet shown after a brand-new command is created.
  /// Offers the user clear next steps (start bot / invite / create another).
  Future<void> _showPostSaveGuidance() async {
    final isRunning = await _isBotCurrentlyRunning();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingXl,
              AppTheme.spacingSm,
              AppTheme.spacingXl,
              AppTheme.spacingLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingSm,
                    bottom: AppTheme.spacingMd,
                  ),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.successLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon.fromMaterial(
                      Icons.check_circle_rounded,
                      size: 48,
                      color: AppTheme.success,
                    ),
                  ),
                ),
                Text(
                  context.tr.command_created_success_title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  context.tr.command_created_success_subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXxl),
                if (!isRunning) ...[
                  _GuidanceActionTile(
                    icon: Icons.play_arrow_rounded,
                    iconColor: AppTheme.success,
                    iconBg: AppTheme.successLight.withValues(alpha: 0.15),
                    label: context.tr.command_created_start_bot,
                    onTap: () {
                      final messenger = ScaffoldMessenger.of(this.context);
                      final hint = context.tr.command_created_start_bot_hint;
                      Navigator.of(context).pop();
                      messenger.showSnackBar(SnackBar(content: Text(hint)));
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                ],
                _GuidanceActionTile(
                  icon: Icons.person_add_rounded,
                  iconColor: AppTheme.info,
                  iconBg: AppTheme.info.withValues(alpha: 0.15),
                  label: context.tr.command_created_invite,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(this.context);
                    final errorMsg = context.tr.command_created_invite_error;
                    final inviteUrl = Uri.parse(
                      'https://discord.com/oauth2/authorize'
                      '?client_id=${widget.botId}'
                      '&permissions=8'
                      '&scope=bot%20applications.commands',
                    );
                    final opened = await openExternalUrl(inviteUrl);
                    if (!opened) {
                      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _GuidanceActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  iconBg: Theme.of(context).colorScheme.surfaceContainerHighest,
                  label: context.tr.command_created_create_another,
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToCreateCommand();
                  },
                ),
                const SizedBox(height: AppTheme.spacingLg),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr.command_created_close),
                ),
                const SizedBox(height: AppTheme.spacingSm),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _moveCommandToFolder(
    String commandId,
    String targetFolder,
  ) async {
    final cleanFolder = normalizeFolderPath(targetFolder);
    final full = await appManager.getAppCommand(widget.botId, commandId);
    if (full.isEmpty || !mounted) return;
    final updated = Map<String, dynamic>.from(full);
    if (cleanFolder.isEmpty) {
      updated.remove('folder');
    } else {
      updated['folder'] = cleanFolder;
      // Auto-expand folder so moved command is immediately visible
      var cur = cleanFolder;
      while (cur.isNotEmpty) {
        _expandedFolders.add(cur);
        cur = folderParentPath(cur);
      }
    }
    await appManager.saveAppCommand(widget.botId, commandId, updated);
    unawaited(refreshBotRuntime(widget.botId));
    await _load();
  }

  Future<void> _showMoveCommandDialog(Map<String, dynamic> command) async {
    final commandId = (command['id'] ?? '').toString();
    final name = (command['name'] ?? 'unknown').toString();
    final currentFolder = normalizeFolderPath(
      (command['folder'] ?? '').toString(),
    );

    final tree = buildCommandFolderTree(
      commands: _commands,
      emptyFolders: _emptyFolders,
    );
    final selected = await FolderPickerDialog.show(
      context: context,
      title: '${context.tr.commands_move_to_folder}: $name',
      currentFolder: currentFolder,
      tree: tree,
    );

    if (selected == null || !mounted) return;
    if (selected != currentFolder) {
      await _moveCommandToFolder(commandId, selected);
    }
  }

  Future<void> _showCreateFolderDialog({String? parentPath}) async {
    final controller = TextEditingController();
    final cleanParent = normalizeFolderPath(parentPath);
    final title = cleanParent.isEmpty
        ? context.tr.commands_create_folder
        : '${context.tr.commands_create_folder} ($cleanParent)';

    final folderName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.tr.commands_new_folder_hint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              final t = v.trim();
              if (t.isNotEmpty) Navigator.pop(context, t);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr.cancel),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isNotEmpty) Navigator.pop(context, t);
              },
              child: Text(context.tr.create),
            ),
          ],
        );
      },
    );
    if (folderName == null || folderName.isEmpty || !mounted) return;
    final fullPath = cleanParent.isEmpty
        ? normalizeFolderPath(folderName)
        : normalizeFolderPath('$cleanParent/$folderName');
    if (fullPath.isEmpty) return;

    setState(() {
      _emptyFolders.add(fullPath);
      // Auto-expand parent path and the new folder so it's clearly visible
      var cur = fullPath;
      while (cur.isNotEmpty) {
        _expandedFolders.add(cur);
        cur = folderParentPath(cur);
      }
    });
    await _saveEmptyFolders();
  }

  Future<void> _renameFolderDialog(String oldPath) async {
    final cleanOld = normalizeFolderPath(oldPath);
    final displayName = folderDisplayName(cleanOld);
    final parent = folderParentPath(cleanOld);
    final controller = TextEditingController(text: displayName);

    final newDisplayName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr.commands_rename_folder),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.tr.commands_new_folder_hint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              final t = v.trim();
              if (t.isNotEmpty) Navigator.pop(context, t);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr.cancel),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isNotEmpty) Navigator.pop(context, t);
              },
              child: Text(context.tr.save),
            ),
          ],
        );
      },
    );
    if (newDisplayName == null ||
        newDisplayName.isEmpty ||
        newDisplayName == displayName ||
        !mounted) {
      return;
    }

    final newPath = parent.isEmpty
        ? normalizeFolderPath(newDisplayName)
        : normalizeFolderPath('$parent/$newDisplayName');
    if (newPath.isEmpty || newPath == cleanOld) return;

    final updatedCommands = <Map<String, dynamic>>[];
    cascadeRenameFolder(
      oldPath: cleanOld,
      newPath: newPath,
      commands: _commands,
      emptyFolders: _emptyFolders,
      onUpdateCommand: (cmd) => updatedCommands.add(cmd),
    );

    for (final cmd in updatedCommands) {
      final id = (cmd['id'] ?? '').toString();
      final full = await appManager.getAppCommand(widget.botId, id);
      if (full.isEmpty) continue;
      final updated = Map<String, dynamic>.from(full);
      updated['folder'] = cmd['folder'];
      await appManager.saveAppCommand(widget.botId, id, updated);
    }

    unawaited(refreshBotRuntime(widget.botId));
    // Update expanded folders set
    final oldPrefix = '$cleanOld/';
    final toRemove = <String>[];
    final toAdd = <String>[];
    for (final exp in _expandedFolders) {
      if (exp == cleanOld) {
        toRemove.add(exp);
        toAdd.add(newPath);
      } else if (exp.startsWith(oldPrefix)) {
        toRemove.add(exp);
        toAdd.add('$newPath/${exp.substring(oldPrefix.length)}');
      }
    }
    _expandedFolders.removeAll(toRemove);
    _expandedFolders.addAll(toAdd);

    await _saveEmptyFolders();
    await _load();
  }

  Future<void> _moveFolderDialog(String sourcePath) async {
    final cleanSource = normalizeFolderPath(sourcePath);
    if (cleanSource.isEmpty) return;

    final tree = buildCommandFolderTree(
      commands: _commands,
      emptyFolders: _emptyFolders,
    );

    final destParent = await FolderPickerDialog.show(
      context: context,
      title: context.tr.commands_move_to_folder,
      currentFolder: folderParentPath(cleanSource),
      tree: tree,
      excludePrefix: cleanSource,
    );

    if (destParent == null || !mounted) return;

    final updatedCommands = <Map<String, dynamic>>[];
    final success = cascadeMoveFolder(
      sourcePath: cleanSource,
      destinationParentPath: destParent,
      commands: _commands,
      emptyFolders: _emptyFolders,
      onUpdateCommand: (cmd) => updatedCommands.add(cmd),
    );

    if (!success) return;

    for (final cmd in updatedCommands) {
      final id = (cmd['id'] ?? '').toString();
      final full = await appManager.getAppCommand(widget.botId, id);
      if (full.isEmpty) continue;
      final updated = Map<String, dynamic>.from(full);
      final newFolder = (cmd['folder'] ?? '').toString().trim();
      if (newFolder.isEmpty) {
        updated.remove('folder');
      } else {
        updated['folder'] = newFolder;
      }
      await appManager.saveAppCommand(widget.botId, id, updated);
    }

    unawaited(refreshBotRuntime(widget.botId));
    await _saveEmptyFolders();
    await _load();
  }

  Future<void> _deleteFolderDialog(String targetPath) async {
    final cleanTarget = normalizeFolderPath(targetPath);
    if (cleanTarget.isEmpty) return;

    final targetPrefix = '$cleanTarget/';
    final cmdsInFolder = _commands.where((c) {
      final f = normalizeFolderPath((c['folder'] ?? '').toString());
      return f == cleanTarget || f.startsWith(targetPrefix);
    }).toList();

    if (cmdsInFolder.isEmpty) {
      final confirmed = await AppTheme.showConfirmDialog(
        context,
        title: context.tr.commands_delete_folder,
        content: context.tr.commands_delete_folder_desc,
        confirmLabel: context.tr.confirm,
        isDestructive: true,
      );
      if (!confirmed || !mounted) return;

      final updatedCommands = <Map<String, dynamic>>[];
      cascadeDeleteFolder(
        targetPath: cleanTarget,
        commands: _commands,
        emptyFolders: _emptyFolders,
        onUpdateCommand: (cmd) => updatedCommands.add(cmd),
      );
      _expandedFolders.removeWhere(
        (f) => f == cleanTarget || f.startsWith(targetPrefix),
      );
      await _saveEmptyFolders();
      await _load();
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.commands_delete_folder),
        content: Text(
          '${context.tr.commands_delete_folder_desc}\n\n(${cmdsInFolder.length} command(s))',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop('keep'),
            child: Text(context.tr.commands_delete_folder),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop('delete_all'),
            child: Text('${context.tr.delete} (${cmdsInFolder.length})'),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'keep') {
      final updatedCommands = <Map<String, dynamic>>[];
      cascadeDeleteFolder(
        targetPath: cleanTarget,
        commands: _commands,
        emptyFolders: _emptyFolders,
        onUpdateCommand: (cmd) => updatedCommands.add(cmd),
      );

      for (final cmd in updatedCommands) {
        final id = (cmd['id'] ?? '').toString();
        final full = await appManager.getAppCommand(widget.botId, id);
        if (full.isEmpty) continue;
        final updated = Map<String, dynamic>.from(full)..remove('folder');
        await appManager.saveAppCommand(widget.botId, id, updated);
      }
    } else if (choice == 'delete_all') {
      final idsToDelete = <String>[];
      cascadeDeleteFolderAndCommands(
        targetPath: cleanTarget,
        commands: _commands,
        emptyFolders: _emptyFolders,
        onDeleteCommand: (id) => idsToDelete.add(id),
      );

      for (final id in idsToDelete) {
        await appManager.deleteAppCommand(widget.botId, id);
      }
    }

    unawaited(refreshBotRuntime(widget.botId));
    _expandedFolders.removeWhere(
      (f) => f == cleanTarget || f.startsWith(targetPrefix),
    );
    await _saveEmptyFolders();
    await _load();
  }

  void _enterReorderMode() {
    final map = <String, String>{};
    for (final cmd in _commands) {
      final id = (cmd['id'] ?? '').toString();
      final folder = (cmd['folder'] ?? '').toString().trim();
      map[id] = folder;
    }
    setState(() {
      _isReorderMode = true;
      _reorderFolderMap = map;
    });
  }

  void _cancelReorderMode() {
    setState(() {
      _isReorderMode = false;
      _reorderFolderMap = {};
    });
  }

  void _enterSelectMode() {
    setState(() {
      _isSelectMode = true;
      _selectedCommandIds.clear();
    });
  }

  void _cancelSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedCommandIds.clear();
    });
  }

  Future<void> _batchDeleteSelected() async {
    final count = _selectedCommandIds.length;
    if (count == 0) return;
    final confirmed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.delete,
      content: context.tr.cmd_batch_delete_confirm(count),
      confirmLabel: context.tr.confirm,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    for (final id in _selectedCommandIds.toList()) {
      await appManager.deleteAppCommand(widget.botId, id);
    }
    unawaited(refreshBotRuntime(widget.botId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.cmd_batch_delete_success(count))),
    );
    setState(() {
      _isSelectMode = false;
      _selectedCommandIds.clear();
    });
    await _load();
  }

  Future<void> _batchMoveSelected() async {
    final count = _selectedCommandIds.length;
    if (count == 0) return;

    final tree = buildCommandFolderTree(
      commands: _commands,
      emptyFolders: _emptyFolders,
    );

    final destFolder = await FolderPickerDialog.show(
      context: context,
      title: context.tr.commands_move_to_folder,
      currentFolder: '',
      tree: tree,
    );

    if (destFolder == null || !mounted) return;

    for (final id in _selectedCommandIds) {
      final full = await appManager.getAppCommand(widget.botId, id);
      if (full.isEmpty) continue;
      final updated = Map<String, dynamic>.from(full);
      if (destFolder.isEmpty) {
        updated.remove('folder');
      } else {
        updated['folder'] = destFolder;
      }
      await appManager.saveAppCommand(widget.botId, id, updated);
    }

    unawaited(refreshBotRuntime(widget.botId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.tr.commands_move_to_folder}: $count')),
    );
    setState(() {
      _isSelectMode = false;
      _selectedCommandIds.clear();
    });
    await _load();
  }

  Future<void> _saveReorderMode() async {
    for (final entry in _reorderFolderMap.entries) {
      final commandId = entry.key;
      final newFolder = entry.value;
      final original = _commands.firstWhere(
        (c) => (c['id'] ?? '').toString() == commandId,
        orElse: () => <String, dynamic>{},
      );
      final oldFolder = (original['folder'] ?? '').toString().trim();
      if (newFolder == oldFolder) continue;

      final full = await appManager.getAppCommand(widget.botId, commandId);
      if (full.isEmpty) continue;
      final updated = Map<String, dynamic>.from(full);
      if (newFolder.isEmpty) {
        updated.remove('folder');
      } else {
        updated['folder'] = newFolder;
      }
      await appManager.saveAppCommand(widget.botId, commandId, updated);
    }
    unawaited(refreshBotRuntime(widget.botId));
    setState(() {
      _isReorderMode = false;
      _reorderFolderMap = {};
    });
    await _load();
  }

  Set<String> get _reorderAvailableFolders {
    final folders = <String>{};
    folders.addAll(_existingFolders);
    folders.addAll(_emptyFolders);
    for (final f in _reorderFolderMap.values) {
      if (f.isNotEmpty) folders.add(f);
    }
    return folders;
  }

  Widget _buildReorderCommandTile(Map<String, dynamic> command) {
    final commandId = (command['id'] ?? '').toString();
    final name = (command['name'] ?? 'unknown').toString();
    final currentFolder = _reorderFolderMap[commandId] ?? '';
    final tree = buildCommandFolderTree(
      commands: _commands,
      emptyFolders: _reorderAvailableFolders,
    );
    final flattened = tree.flatten();

    return Card(
      child: ListTile(
        leading: const AppIcon.fromMaterial(Icons.drag_handle),
        title: Text(
          name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: DropdownButton<String>(
          value: currentFolder,
          underline: const SizedBox.shrink(),
          isDense: true,
          icon: const AppIcon.fromMaterial(Icons.folder_outlined, size: 18),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(
                context.tr.commands_no_folder,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final item in flattened)
              DropdownMenuItem<String>(
                value: item.fullPath,
                child: Text(
                  item.indentedLabel,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _reorderFolderMap[commandId] = value;
            });
          },
        ),
      ),
    );
  }

  List<Widget> _buildReorderList() {
    // Group by current reorder folder assignments
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final command in _commands) {
      final id = (command['id'] ?? '').toString();
      final folder = _reorderFolderMap[id] ?? '';
      grouped.putIfAbsent(folder, () => []).add(command);
    }
    for (final folder in _emptyFolders) {
      grouped.putIfAbsent(folder, () => []);
    }
    // Also include folders only present in reorderFolderMap
    for (final f in _reorderFolderMap.values) {
      if (f.isNotEmpty) grouped.putIfAbsent(f, () => []);
    }

    final tree = buildCommandFolderTree(
      commands: _commands.map((cmd) {
        final id = (cmd['id'] ?? '').toString();
        final c = Map<String, dynamic>.from(cmd);
        c['folder'] = _reorderFolderMap[id] ?? '';
        return c;
      }).toList(),
      emptyFolders: _reorderAvailableFolders,
    );
    final flattened = tree.flatten();

    final children = <Widget>[];

    // Un-foldered commands first
    final rootCmds = grouped[''] ?? [];
    if (rootCmds.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Row(
            children: [
              AppIcon.fromMaterial(
                Icons.folder_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr.commands_no_folder,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${rootCmds.length})',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
      for (final command in rootCmds) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildReorderCommandTile(command),
          ),
        );
      }
    }

    // Folders in hierarchical order
    for (final item in flattened) {
      final folderCommands = grouped[item.fullPath] ?? [];
      final indentPadding = (item.depth * 16.0);
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(4 + indentPadding, 16, 4, 6),
          child: Row(
            children: [
              if (item.depth > 0) ...[
                Text(
                  '↳ ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              AppIcon.fromMaterial(
                Icons.folder,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${folderCommands.length})',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
      for (final command in folderCommands) {
        children.add(
          Padding(
            padding: EdgeInsets.only(left: indentPadding, bottom: 6),
            child: _buildReorderCommandTile(command),
          ),
        );
      }
    }
    return children;
  }

  List<Widget> _buildGroupedCommandList() {
    final visible = _visibleCommands();
    final tree = buildCommandFolderTree(
      commands: visible,
      emptyFolders: _emptyFolders,
    );

    final children = <Widget>[];
    final adsEnabled = AdsPlacementPolicy.isPlacementEnabled(
      NativeAdPlacement.commandsList,
    );
    var displayedCount = 0;

    void addCommandCard(Map<String, dynamic> command, {double indent = 0}) {
      children.add(
        Padding(
          padding: EdgeInsets.only(left: indent, bottom: 6),
          child: _buildCommandCard(command),
        ),
      );
      displayedCount += 1;
      if (adsEnabled &&
          AdsPlacementPolicy.shouldInsertAfterContentCount(displayedCount)) {
        children.add(
          const NativeAdSlot(
            placement: NativeAdPlacement.commandsList,
            height: 110,
          ),
        );
      }
    }

    // 1. Root un-foldered commands (if any)
    if (tree.rootCommands.isNotEmpty || tree.rootFolders.isNotEmpty) {
      if (tree.rootFolders.isNotEmpty) {
        children.add(
          DragTarget<Map<String, dynamic>>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              final cmdId = (details.data['id'] ?? '').toString();
              if (cmdId.isNotEmpty) {
                _moveCommandToFolder(cmdId, '');
              }
            },
            builder: (context, candidateData, _) {
              final isHovered = candidateData.isNotEmpty;
              return Container(
                decoration: isHovered
                    ? BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      )
                    : null,
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                child: Row(
                  children: [
                    AppIcon.fromMaterial(
                      Icons.folder_off_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr.commands_no_folder,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${tree.rootCommands.length})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
      for (final command in tree.rootCommands) {
        addCommandCard(command);
      }
    }

    // 2. Recursive folder node rendering
    void renderNode(CommandFolderNode node) {
      final isExpanded = _expandedFolders.contains(node.fullPath);
      final indent = node.depth * 16.0;

      children.add(
        CommandFolderHeader(
          title: node.name,
          count: node.totalCommandCount,
          directCount: node.commands.length,
          depth: node.depth,
          isExpanded: isExpanded,
          onToggle: () {
            setState(() {
              if (isExpanded) {
                _expandedFolders.remove(node.fullPath);
              } else {
                _expandedFolders.add(node.fullPath);
              }
            });
          },
          onRename: () => _renameFolderDialog(node.fullPath),
          onMove: () => _moveFolderDialog(node.fullPath),
          onDelete: () => _deleteFolderDialog(node.fullPath),
          onAddSubfolder: () =>
              _showCreateFolderDialog(parentPath: node.fullPath),
          onNewCommand: () =>
              _navigateToCreateCommand(prefillFolder: node.fullPath),
          onAcceptDrop: (cmd) {
            final cmdId = (cmd['id'] ?? '').toString();
            if (cmdId.isNotEmpty) {
              _moveCommandToFolder(cmdId, node.fullPath);
            }
          },
        ),
      );

      if (!isExpanded) return;

      // Render direct commands in this folder
      for (final cmd in node.commands) {
        addCommandCard(cmd, indent: indent);
      }

      // Render subfolders recursively
      for (final subfolder in node.subfolders) {
        renderNode(subfolder);
      }
    }

    for (final rootFolder in tree.rootFolders) {
      renderNode(rootFolder);
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: _isSelectMode
            ? Text(
                context.tr.commands_selected_count(_selectedCommandIds.length),
              )
            : _isReorderMode
            ? Text(context.tr.commands_reorder_title)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr.commands_title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_commands.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                      ),
                      child: Text(
                        '${_commands.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        leading: _isSelectMode
            ? IconButton(
                icon: const AppIcon.fromMaterial(Icons.close),
                tooltip: context.tr.cancel,
                onPressed: _cancelSelectMode,
              )
            : _isReorderMode
            ? IconButton(
                icon: const AppIcon.fromMaterial(Icons.close),
                tooltip: context.tr.cancel,
                onPressed: _cancelReorderMode,
              )
            : editorSubPageLeading(context),
        actions: _isSelectMode
            ? [
                IconButton(
                  icon: AppIcon.fromMaterial(
                    _selectedCommandIds.length == _commands.length &&
                            _commands.isNotEmpty
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                  ),
                  tooltip:
                      _selectedCommandIds.length == _commands.length &&
                          _commands.isNotEmpty
                      ? context.tr.marketplace_publish_deselect_all
                      : context.tr.marketplace_publish_select_all,
                  onPressed: () {
                    setState(() {
                      if (_selectedCommandIds.length == _commands.length) {
                        _selectedCommandIds.clear();
                      } else {
                        _selectedCommandIds.clear();
                        for (final c in _commands) {
                          final id = (c['id'] ?? '').toString();
                          if (id.isNotEmpty) _selectedCommandIds.add(id);
                        }
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const AppIcon.fromMaterial(
                    Icons.drive_file_move_outlined,
                  ),
                  tooltip: context.tr.commands_move_to_folder,
                  onPressed: _selectedCommandIds.isNotEmpty
                      ? _batchMoveSelected
                      : null,
                ),
                IconButton(
                  icon: const AppIcon.fromMaterial(
                    Icons.delete_outline_rounded,
                  ),
                  tooltip: context.tr.delete,
                  onPressed: _selectedCommandIds.isNotEmpty
                      ? _batchDeleteSelected
                      : null,
                ),
              ]
            : _isReorderMode
            ? [
                IconButton(
                  icon: const AppIcon.fromMaterial(Icons.check_rounded),
                  tooltip: context.tr.save,
                  onPressed: _saveReorderMode,
                ),
              ]
            : [
                IconButton(
                  icon: const AppIcon.fromMaterial(Icons.auto_awesome_rounded),
                  tooltip: context.tr.marketplace_title,
                  color: AppTheme.brandSecondary,
                  onPressed: _openMarketplace,
                ),
                PopupMenuButton<String>(
                  icon: const AppIcon.fromMaterial(Icons.more_vert_rounded),
                  tooltip: context.tr.more_options_title,
                  onSelected: (value) async {
                    switch (value) {
                      case 'select':
                        if (_commands.isNotEmpty) _enterSelectMode();
                      case 'reorder':
                        if (_commands.isNotEmpty) _enterReorderMode();
                      case 'publish':
                        await _openPublishTemplate();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'select',
                      enabled: _commands.isNotEmpty,
                      child: Row(
                        children: [
                          const AppIcon.fromMaterial(
                            Icons.checklist_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(context.tr.commands_batch_select),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reorder',
                      enabled: _commands.isNotEmpty,
                      child: Row(
                        children: [
                          const AppIcon.fromMaterial(
                            Icons.swap_vert_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(context.tr.commands_reorder_title),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'publish',
                      child: Row(
                        children: [
                          const AppIcon.fromMaterial(
                            Icons.cloud_upload_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(context.tr.marketplace_publish_title),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: SafeArea(
        top: false,
        // Contraintes ignorées : la largeur maximale et les marges viennent
        // désormais de `PageContent` (`AppPageLayout`).
        child: LayoutBuilder(
          builder: (context, _) {
            final visibleCommands = _visibleCommands();
            if (_loading) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeAlign: 0.5,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.info),
                ),
              );
            }

            if (_commands.isEmpty) {
              // S2: Guided empty state — single obvious primary action with a
              // calm secondary path. Avoids the bottom-sheet dead end.
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingXxl,
                    AppTheme.spacingXxl,
                    AppTheme.spacingXxl,
                    AppTheme.spacingXxl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: AppIcon.fromMaterial(
                            Icons.smart_toy_rounded,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXxl),
                        Text(
                          context.tr.commands_empty_title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: AppTheme.fontWeightBold),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          context.tr.commands_empty_description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingXxl),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _navigateToCreateCommand,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingLg,
                                vertical: AppTheme.spacingMd,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                              ),
                            ),
                            icon: const AppIcon.fromMaterial(Icons.add_rounded),
                            label: Text(
                              context.tr.commands_empty_create_button,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: AppTheme.fontWeightSemiBold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextButton.icon(
                          onPressed: _openMarketplace,
                          icon: AppIcon.fromMaterial(
                            Icons.auto_awesome,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            context.tr.commands_empty_marketplace_link,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: AppTheme.fontWeightSemiBold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        TextButton.icon(
                          onPressed: () async {
                            await _addSamplePingCommand();
                          },
                          icon: AppIcon.fromMaterial(
                            Icons.bolt_rounded,
                            size: 18,
                            color: AppTheme.warning,
                          ),
                          label: Text(
                            context.tr.commands_empty_sample_ping,
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontWeight: AppTheme.fontWeightSemiBold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: PageContent(
                child: _isReorderMode
                    ? ListView(
                        padding: EdgeInsets.fromLTRB(
                          0,
                          16,
                          0,
                          FloatingGlassNavBar.contentClearanceOf(context) + 16,
                        ),
                        children: _buildReorderList(),
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          0,
                          8,
                          0,
                          FloatingGlassNavBar.contentClearanceOf(context) + 16,
                        ),
                        children: [
                          _buildFiltersBar(),
                          if (visibleCommands.isEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 48),
                              child: Center(
                                child: Text(
                                  context.tr.commands_no_match_filters,
                                ),
                              ),
                            )
                          else
                            ..._buildGroupedCommandList(),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CommandFolderHeader extends StatelessWidget {
  final String title;
  final int count;
  final int directCount;
  final int depth;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback? onMove;
  final VoidCallback onDelete;
  final VoidCallback? onAddSubfolder;
  final VoidCallback? onNewCommand;
  final ValueChanged<Map<String, dynamic>>? onAcceptDrop;

  const CommandFolderHeader({
    super.key,
    required this.title,
    required this.count,
    this.directCount = 0,
    this.depth = 0,
    required this.isExpanded,
    required this.onToggle,
    required this.onRename,
    this.onMove,
    required this.onDelete,
    this.onAddSubfolder,
    this.onNewCommand,
    this.onAcceptDrop,
  });

  @override
  Widget build(BuildContext context) {
    final indentPadding = depth * 16.0;
    final headerChild = InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4 + indentPadding, 12, 4, 6),
        child: Row(
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: AppIcon.fromMaterial(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            if (depth > 0) ...[
              Text(
                '↳ ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            AppIcon.fromMaterial(
              isExpanded ? Icons.folder_open : Icons.folder,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: AppIcon.fromMaterial(
                Icons.more_vert,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                if (onNewCommand != null)
                  PopupMenuItem(
                    value: 'add_command',
                    child: Row(
                      children: [
                        const AppIcon.fromMaterial(
                          Icons.add_circle_outline,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(context.tr.commands_create_button),
                      ],
                    ),
                  ),
                if (onAddSubfolder != null)
                  PopupMenuItem(
                    value: 'add_subfolder',
                    child: Row(
                      children: [
                        const AppIcon.fromMaterial(
                          Icons.create_new_folder_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(context.tr.commands_create_folder),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      const AppIcon.fromMaterial(Icons.edit, size: 18),
                      const SizedBox(width: 8),
                      Text(context.tr.commands_rename_folder),
                    ],
                  ),
                ),
                if (onMove != null)
                  PopupMenuItem(
                    value: 'move',
                    child: Row(
                      children: [
                        const AppIcon.fromMaterial(
                          Icons.drive_file_move_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(context.tr.commands_move_to_folder),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const AppIcon.fromMaterial(
                        Icons.delete_outline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(context.tr.commands_delete_folder),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'add_command') {
                  onNewCommand?.call();
                } else if (value == 'add_subfolder') {
                  onAddSubfolder?.call();
                } else if (value == 'rename') {
                  onRename();
                } else if (value == 'move') {
                  onMove?.call();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ],
        ),
      ),
    );

    if (onAcceptDrop == null) return headerChild;

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAcceptDrop!(details.data),
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        if (!isHovered) return headerChild;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: headerChild,
        );
      },
    );
  }
}

class _CommandMetaChip extends StatelessWidget {
  const _CommandMetaChip({this.label, required this.icon});

  final String? label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.fromMaterial(
            icon,
            size: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          if (label != null) ...[
            const SizedBox(width: 3),
            Text(
              label!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SpeedDialItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SpeedDialItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'speed_dial_$label',
          onPressed: onTap,
          child: AppIcon.fromMaterial(icon),
        ),
      ],
    );
  }
}

/// S6: A single tappable action row used inside the post-save guidance sheet.
class _GuidanceActionTile extends StatelessWidget {
  const _GuidanceActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon.fromMaterial(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontWeightSemiBold,
                  ),
                ),
              ),
              AppIcon.fromMaterial(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

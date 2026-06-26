import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/storage/app_storage_directory.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart';
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
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';

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
    final snowflake = _toSnowflake(commandId);
    final templateOrigin = command['templateOrigin'] as Map<String, dynamic>?;
    final templateId = (templateOrigin?['templateId'] ?? '').toString();
    final name = (command['name'] ?? 'unknown').toString();

    return Card(
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
            if (!_isSelectMode)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: context.tr.delete,
                onPressed: () => _deleteCommand(commandId, name),
              ),
            const Icon(Icons.arrow_forward_ios_outlined),
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
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      templateId,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Row(children: _buildCommandMetaChips(command)),
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
              builder:
                  (context) => CommandCreatePage(
                    client: widget.client,
                    botId: widget.botId,
                    id: snowflake ?? Snowflake.zero,
                    localCommandId: snowflake == null ? commandId : null,
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
          final type =
              (command['type'] ?? data['commandType'] ?? 'chatInput')
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
          final description =
              (command['description'] ?? '').toString().toLowerCase();
          if (_typeFilter == 'legacy') {
            if (!legacyMode) return false;
          } else if (_typeFilter != 'all' && type != _typeFilter) {
            return false;
          }
          if (_folderFilter.isNotEmpty && folder != _folderFilter) {
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
          return name.contains(query) ||
              description.contains(query) ||
              folder.toLowerCase().contains(query) ||
              templateId.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _showCreateMenu() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(context.tr.commands_create_button),
                onTap: () => Navigator.pop(context, 'command'),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: Text(context.tr.marketplace_title),
                onTap: () => Navigator.pop(context, 'template'),
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: Text(context.tr.commands_create_folder),
                onTap: () => Navigator.pop(context, 'folder'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selection == null) {
      return;
    }

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
            builder: (_) => MarketplacePage(
              botId: widget.botId,
              apiClient: client,
            ),
          ),
        );
        if (applied == true && mounted) {
          _load();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.marketplace_connect_manager),
          ),
        );
      }
      return;
    }

    if (selection == 'folder') {
      await _showCreateFolderDialog();
    }
  }

  Widget _buildFiltersBar() {
    final folders = _existingFolders.toList()..sort();
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
        if (folders.isNotEmpty)
          NotionFilter(
            id: 'folder',
            label: context.tr.commands_folder_label,
            icon: Icons.folder_outlined,
            options: {
              '': context.tr.commands_all_folders,
              for (final f in folders) f: f,
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
            builder:
                (_) => CommandCreatePage(
                  client: widget.client,
                  botId: widget.botId,
                  prefillName: query,
                ),
          ),
        );
        if (!mounted) return;
        _load();
      },
    );
  }

  Set<String> get _existingFolders {
    return _commands
        .map((c) => (c['folder'] ?? '').toString().trim())
        .where((f) => f.isNotEmpty)
        .toSet();
  }

  Future<void> _navigateToCreateCommand() async {
    final countBefore = _commands.length;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CommandCreatePage(client: widget.client, botId: widget.botId),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
          builder: (_) => MarketplacePage(
            botId: widget.botId,
            apiClient: client,
          ),
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
                    child: const Icon(
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
                      messenger.showSnackBar(
                        SnackBar(content: Text(hint)),
                      );
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
                      messenger.showSnackBar(
                        SnackBar(content: Text(errorMsg)),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _GuidanceActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: AppTheme.brandPrimary,
                  iconBg: AppTheme.brandPrimary.withValues(alpha: 0.12),
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

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr.commands_create_folder),
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
    // Nothing to do beyond recording the name — the folder appears once a
    // command is moved into it. But we can store an empty folder list so the
    // header appears immediately.
    setState(() {
      _emptyFolders.add(folderName);
    });
    await _saveEmptyFolders();
  }

  Future<void> _renameFolderDialog(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
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
    if (newName == null || newName.isEmpty || newName == oldName || !mounted) {
      return;
    }
    // Rename folder on all commands that belong to it
    for (final cmd in _commands) {
      final f = (cmd['folder'] ?? '').toString().trim();
      if (f != oldName) continue;
      final id = (cmd['id'] ?? '').toString();
      final full = await appManager.getAppCommand(widget.botId, id);
      if (full.isEmpty) continue;
      final updated = Map<String, dynamic>.from(full);
      updated['folder'] = newName;
      await appManager.saveAppCommand(widget.botId, id, updated);
    }
    unawaited(refreshBotRuntime(widget.botId));
    _emptyFolders.remove(oldName);
    await _saveEmptyFolders();
    await _load();
  }

  Future<void> _deleteFolderDialog(String folderName) async {
    final confirmed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.commands_delete_folder,
      content: context.tr.commands_delete_folder_desc,
      confirmLabel: context.tr.confirm,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    // Remove folder from all commands (commands stay, just become un-foldered)
    for (final cmd in _commands) {
      final f = (cmd['folder'] ?? '').toString().trim();
      if (f != folderName) continue;
      final id = (cmd['id'] ?? '').toString();
      final full = await appManager.getAppCommand(widget.botId, id);
      if (full.isEmpty) continue;
      final updated = Map<String, dynamic>.from(full)..remove('folder');
      await appManager.saveAppCommand(widget.botId, id, updated);
    }
    unawaited(refreshBotRuntime(widget.botId));
    _emptyFolders.remove(folderName);
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
    final folders = _reorderAvailableFolders.toList()..sort();

    return Card(
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(
          name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: DropdownButton<String>(
          value: currentFolder,
          underline: const SizedBox.shrink(),
          isDense: true,
          icon: const Icon(Icons.folder_outlined, size: 18),
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
            for (final folder in folders)
              DropdownMenuItem<String>(
                value: folder,
                child: Text(folder, style: const TextStyle(fontSize: 13)),
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

    final sortedFolders =
        grouped.keys.toList()..sort((a, b) {
          if (a.isEmpty) return -1;
          if (b.isEmpty) return 1;
          return a.compareTo(b);
        });

    final children = <Widget>[];
    for (final folder in sortedFolders) {
      final commands = grouped[folder]!;
      if (folder.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  folder,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${commands.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      for (final command in commands) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildReorderCommandTile(command),
          ),
        );
      }
    }
    return children;
  }

  List<Widget> _buildGroupedCommandList() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final command in _visibleCommands()) {
      final folder = (command['folder'] ?? '').toString().trim();
      grouped.putIfAbsent(folder, () => []).add(command);
    }
    // Include empty folders that the user created but hasn't moved commands into yet
    for (final folder in _emptyFolders) {
      grouped.putIfAbsent(folder, () => []);
    }

    final sortedFolders =
        grouped.keys.toList()..sort((a, b) {
          if (a.isEmpty) return -1;
          if (b.isEmpty) return 1;
          return a.compareTo(b);
        });

    final children = <Widget>[];
    final adsEnabled = AdsPlacementPolicy.isPlacementEnabled(
      NativeAdPlacement.commandsList,
    );
    var displayedCount = 0;

    for (final folder in sortedFolders) {
      final commands = grouped[folder]!;
      if (folder.isNotEmpty) {
        final isExpanded = _expandedFolders.contains(folder);
        children.add(
          _CommandFolderHeader(
            title: folder,
            count: commands.length,
            isExpanded: isExpanded,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedFolders.remove(folder);
                } else {
                  _expandedFolders.add(folder);
                }
              });
            },
            onRename: () => _renameFolderDialog(folder),
            onDelete: () => _deleteFolderDialog(folder),
          ),
        );
        if (!isExpanded) continue;
      } else if (commands.isNotEmpty) {
        // "No folder" header for uncategorized commands
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
            child: Row(
              children: [
                Icon(
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
                  '(${commands.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      for (final command in commands) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
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
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromRGBO(106, 15, 162, 1),
        title: Text(
          _isSelectMode
              ? '${_selectedCommandIds.length} selected'
              : _isReorderMode
                  ? context.tr.commands_reorder_title
                  : context.tr.commands_title,
        ),
        centerTitle: true,
        leading: _isSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.tr.cancel,
                onPressed: _cancelSelectMode,
              )
            : _isReorderMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: context.tr.cancel,
                    onPressed: _cancelReorderMode,
                  )
                : (!ResponsiveHelper.isDesktopPlatform()
                    ? IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => context.openParentDrawer(),
                      )
                    : null),
        actions: _isSelectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: context.tr.delete,
                  onPressed: _selectedCommandIds.isNotEmpty
                      ? _batchDeleteSelected
                      : null,
                ),
              ]
            : _isReorderMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: context.tr.save,
                      onPressed: _saveReorderMode,
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.checklist),
                      tooltip: 'Select',
                      onPressed:
                          _commands.isNotEmpty ? _enterSelectMode : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_vert),
                      tooltip: context.tr.commands_reorder_title,
                      onPressed:
                          _commands.isNotEmpty ? _enterReorderMode : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      tooltip: context.tr.marketplace_title,
                      onPressed: () async {
                      final client = await _resolveApiClient();
                      if (!mounted) return;
                      if (client == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr.marketplace_connect_manager),
                          ),
                        );
                        return;
                      }
                      final applied = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MarketplacePage(
                            botId: widget.botId,
                            apiClient: client,
                          ),
                        ),
                      );
                      if (applied == true && mounted) {
                        _load();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cloud_upload_outlined),
                    tooltip: context.tr.marketplace_publish_title,
                    onPressed: () async {
                      final client = await _resolveApiClient();
                      final authorName = await _resolveAuthorName();
                      final session = await MainApiSettingsStore.loadSession();
                      final authorId = session?.userId ?? 'unknown';
                      if (!mounted) return;
                      if (client == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr.marketplace_connect_publish),
                          ),
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
                    },
                  ),
                ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentMaxWidth = constraints.maxWidth >= 900 ? 760.0 : 640.0;
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
                            color: AppTheme.brandPrimary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            size: 80,
                            color: AppTheme.brandPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXxl),
                        Text(
                          context.tr.commands_empty_title,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: AppTheme.fontWeightBold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          context.tr.commands_empty_description,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXxl),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _navigateToCreateCommand,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.brandPrimary,
                              foregroundColor: Colors.white,
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
                            icon: const Icon(Icons.add_rounded),
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
                          icon: Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: AppTheme.brandSecondary,
                          ),
                          label: Text(
                            context.tr.commands_empty_marketplace_link,
                            style: TextStyle(
                              color: AppTheme.brandSecondary,
                              fontWeight: AppTheme.fontWeightSemiBold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        TextButton.icon(
                          onPressed: () async {
                            await _addSamplePingCommand();
                          },
                          icon: Icon(
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
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child:
                    _isReorderMode
                        ? ListView(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
                          children: _buildReorderList(),
                        )
                        : ListView(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
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
      floatingActionButton:
          _isReorderMode
              ? null
              : FloatingActionButton.extended(
                onPressed: _showCreateMenu,
                tooltip: context.tr.commands_create_button,
                icon: const Icon(Icons.add),
                label: Text(context.tr.create),
              ),
    );
  }
}

class _CommandFolderHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  const _CommandFolderHeader({
    required this.title,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
        child: Row(
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
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
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(context.tr.commands_rename_folder),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(context.tr.commands_delete_folder),
                        ],
                      ),
                    ),
                  ],
              onSelected: (value) {
                if (value == 'rename') {
                  onRename();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ],
        ),
      ),
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
          Icon(
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
          child: Icon(icon),
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
                child: Icon(icon, size: 22, color: iconColor),
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
              Icon(
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

import 'package:bot_creator/routes/app/command.create.dart';
import 'package:bot_creator/routes/app/template_gallery.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/utils/analytics.dart';
import 'package:bot_creator/utils/ads_placement_policy.dart';
import 'package:bot_creator/utils/i18n.dart';
import 'package:bot_creator/widgets/native_ad_slot.dart';
import 'package:bot_creator/widgets/notion_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/utils/app_theme.dart';

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
    if (!mounted) return;
    setState(() {
      _commands = commands;
      _loading = false;
    });
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

    return Card(
      child: ListTile(
        trailing: const Icon(Icons.arrow_forward_ios_outlined),
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
                title: Text(context.tr.template_gallery_title),
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
      final applied = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder:
              (_) => TemplateGalleryPage(
                botId: widget.botId,
                client: widget.client,
              ),
        ),
      );
      if (applied == true && mounted) {
        _load();
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
    );
  }

  Set<String> get _existingFolders {
    return _commands
        .map((c) => (c['folder'] ?? '').toString().trim())
        .where((f) => f.isNotEmpty)
        .toSet();
  }

  Future<void> _navigateToCreateCommand() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CommandCreatePage(client: widget.client, botId: widget.botId),
      ),
    );
    if (!mounted) return;
    _load();
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
    _emptyFolders.remove(oldName);
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
    _emptyFolders.remove(folderName);
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
        backgroundColor: const Color.fromRGBO(106, 15, 162, 1),
        title: Text(
          _isReorderMode
              ? context.tr.commands_reorder_title
              : context.tr.commands_title,
        ),
        centerTitle: true,
        leading:
            _isReorderMode
                ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.tr.cancel,
                  onPressed: _cancelReorderMode,
                )
                : null,
        actions:
            _isReorderMode
                ? [
                  IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: context.tr.save,
                    onPressed: _saveReorderMode,
                  ),
                ]
                : [
                  IconButton(
                    icon: const Icon(Icons.swap_vert),
                    tooltip: context.tr.commands_reorder_title,
                    onPressed: _commands.isNotEmpty ? _enterReorderMode : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    tooltip: context.tr.template_gallery_title,
                    onPressed: () async {
                      final applied = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => TemplateGalleryPage(
                                botId: widget.botId,
                                client: widget.client,
                              ),
                        ),
                      );
                      if (applied == true && mounted) {
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
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.tr.commands_empty),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        final applied = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => TemplateGalleryPage(
                                  botId: widget.botId,
                                  client: widget.client,
                                ),
                          ),
                        );
                        if (applied == true && mounted) {
                          _load();
                        }
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(context.tr.template_gallery_title),
                    ),
                  ],
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

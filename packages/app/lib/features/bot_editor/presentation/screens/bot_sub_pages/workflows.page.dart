import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/storage/app_storage_directory.dart';
import 'package:bot_creator/features/bot_editor/logic/command_folder_tree.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/folder_picker_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflow_block_editor.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/entry_point_block.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator_shared/utils/variable_catalog.dart'
    show inferCategory;
import 'package:bot_creator/features/bot_editor/logic/app_emoji_api.dart';
import 'package:bot_creator/features/ads/logic/ads_placement_policy.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator/features/ads/presentation/native_ad_slot.dart';
import 'package:bot_creator/core/widgets/notion_filter_bar.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator_shared/bot_creator_shared.dart'
    show VariableCatalog, WorkflowEventDefinition, EventCatalog;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';

class WorkflowsPage extends StatefulWidget {
  const WorkflowsPage({
    super.key,
    required this.botId,
    this.eventsOnly = false,
  });

  final String botId;

  /// When true (JS bots), only event workflows are listed/created.
  final bool eventsOnly;

  @override
  State<WorkflowsPage> createState() => _WorkflowsPageState();
}

class _WorkflowsPageState extends State<WorkflowsPage> {
  List<Map<String, dynamic>> _workflows = <Map<String, dynamic>>[];
  bool _loading = true;
  List<AppEmoji> _appEmojis = [];
  String _searchQuery = '';
  late String _workflowFilter;
  String _folderFilter = '';
  final Set<String> _expandedWorkflowFolders = <String>{};
  final Set<String> _emptyWorkflowFolders = <String>{};

  Future<String> _getEmptyWorkflowFoldersFilePath() async {
    final storagePath = await getAppStoragePath();
    return '$storagePath/apps/${widget.botId}/_empty_workflow_folders.json';
  }

  Future<void> _loadEmptyWorkflowFolders() async {
    try {
      final path = await _getEmptyWorkflowFoldersFilePath();
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List?;
        if (list != null) {
          _emptyWorkflowFolders.clear();
          for (final item in list) {
            final normalized = normalizeFolderPath(item.toString());
            if (normalized.isNotEmpty) _emptyWorkflowFolders.add(normalized);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveEmptyWorkflowFolders() async {
    try {
      final path = await _getEmptyWorkflowFoldersFilePath();
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode(_emptyWorkflowFolders.toList()..sort()),
      );
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _workflowFilter = widget.eventsOnly ? workflowTypeEvent : 'all';
    _load();
  }

  String _toScopedReferenceName(String rawKey) {
    final key = rawKey.trim();
    if (key.isEmpty) {
      return key;
    }
    if (key.startsWith('bc_') && key.length > 3) {
      return key.substring(3);
    }
    return key;
  }

  Future<void> _load() async {
    await _loadEmptyWorkflowFolders();
    final workflows = await appManager.getWorkflows(widget.botId);
    if (!mounted) {
      return;
    }

    final tree = buildCommandFolderTree(
      commands: workflows,
      emptyFolders: _emptyWorkflowFolders,
    );
    for (final p in tree.allFolderPaths) {
      _expandedWorkflowFolders.add(p);
    }

    // Load application emojis silently for autocomplete
    List<AppEmoji> emojis = [];
    try {
      final token = (await appManager.getApp(widget.botId))['token'] as String?;
      if (token != null && token.isNotEmpty) {
        emojis = await AppEmojiApi.listEmojis(token, widget.botId);
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _workflows = workflows;
      _appEmojis = emojis;
      _loading = false;
    });
  }

  List<WorkflowEventDefinition> get _workflowEventCatalog =>
      EventCatalog.getEvents();

  List<String> get _workflowEventCategories {
    final categories = <String>[];
    for (final event in _workflowEventCatalog) {
      if (!categories.contains(event.category)) {
        categories.add(event.category);
      }
    }
    return categories;
  }

  List<WorkflowEventDefinition> _eventsForCategory(String category) {
    return _workflowEventCatalog
        .where((event) => event.category == category)
        .toList(growable: false);
  }

  WorkflowEventDefinition? _findEventDefinition(String eventName) {
    for (final event in _workflowEventCatalog) {
      if (event.event == eventName) {
        return event;
      }
    }
    return null;
  }

  String _eventCategoryLabel(String category) {
    switch (category) {
      case 'core':
        return 'Core';
      case 'commands':
        return 'Commands';
      case 'automod':
        return 'Auto Moderation';
      case 'channels':
        return 'Channels';
      case 'threads':
        return 'Threads';
      case 'entitlements':
        return 'Entitlements';
      case 'guilds':
        return 'Guilds';
      case 'members':
        return 'Members';
      case 'roles':
        return 'Roles';
      case 'scheduled':
        return 'Scheduled Events';
      case 'integrations':
        return 'Integrations';
      case 'invites':
        return 'Invites';
      case 'messages':
        return 'Messages';
      case 'reactions':
        return 'Reactions';
      case 'presence':
        return 'Presence';
      case 'stages':
        return 'Stage Instances';
      case 'voice':
        return 'Voice';
      case 'webhooks':
        return 'Webhooks';
      case 'soundboard':
        return 'Soundboard';
      default:
        return category;
    }
  }

  String _eventLabel(String eventName) {
    final definition = _findEventDefinition(eventName);
    if (definition == null) {
      return eventName;
    }
    return definition.label;
  }

  String _workflowTypeBadgeLabel(String workflowType) {
    return workflowType == workflowTypeEvent
        ? context.tr.workflows_type_badge_event
        : context.tr.workflows_type_badge_general;
  }

  Future<List<VariableSuggestion>> _buildWorkflowVariableSuggestions({
    required String workflowType,
    required List<WorkflowArgumentDefinition> argumentDefinitions,
    required Map<String, dynamic> eventTrigger,
  }) async {
    final suggestions = <VariableSuggestion>[
      ...VariableCatalog.getAlwaysAvailableSuggestions(
        argumentNames: argumentDefinitions.map((arg) => arg.name).toList(),
      ),
    ];

    if (workflowType == workflowTypeEvent) {
      suggestions.addAll(VariableCatalog.getBaseHydratedSuggestions());

      final eventName = (eventTrigger['event'] ?? '').toString();
      suggestions.addAll(VariableCatalog.getSuggestionsForEvent(eventName));
    }

    try {
      final globals = await appManager.getGlobalVariables(widget.botId);
      for (final entry in globals.entries) {
        final key = entry.key.toString().trim();
        if (key.isEmpty) {
          continue;
        }
        suggestions.add(
          VariableSuggestion(
            name: 'global.$key',
            kind: entry.value is num
                ? VariableSuggestionKind.numeric
                : VariableSuggestionKind.unknown,
            category: inferCategory('global.$key'),
          ),
        );
      }

      final scopedDefinitions = await appManager.getScopedVariableDefinitions(
        widget.botId,
      );
      for (final definition in scopedDefinitions) {
        final scope = (definition['scope'] ?? '').toString().trim();
        final storageKey = (definition['key'] ?? '').toString().trim();
        if (scope.isEmpty || storageKey.isEmpty) {
          continue;
        }
        final name = '$scope.${_toScopedReferenceName(storageKey)}';
        suggestions.add(
          VariableSuggestion(
            name: name,
            kind:
                (definition['valueType']?.toString() == 'number' ||
                    definition['defaultValue'] is num)
                ? VariableSuggestionKind.numeric
                : VariableSuggestionKind.unknown,
            category: inferCategory(name),
          ),
        );
      }
    } catch (_) {
      // Keep editor resilient when local persistence is temporarily unavailable.
    }

    final uniqueByName = <String, VariableSuggestion>{};
    for (final suggestion in suggestions) {
      uniqueByName[suggestion.name] = suggestion;
    }
    return uniqueByName.values.toList(growable: false);
  }

  Future<void> _createOrEditWorkflow({
    Map<String, dynamic>? initial,
    String? initialWorkflowType,
    String? prefillFolder,
  }) async {
    final effectiveInitial =
        initial ??
        (prefillFolder != null && prefillFolder.isNotEmpty
            ? <String, dynamic>{'folder': prefillFolder}
            : null);
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkflowBlockEditor(
          botId: widget.botId,
          initial: effectiveInitial,
          initialWorkflowType: initialWorkflowType,
          eventsOnly: widget.eventsOnly,
          appEmojis: _appEmojis,
          eventCatalog: _workflowEventCatalog
              .map(
                (e) => WorkflowEventItem(
                  event: e.event,
                  label: e.label,
                  description: e.description,
                ),
              )
              .toList(growable: false),
          eventCategories: _workflowEventCategories,
          eventsForCategory: (category) => _eventsForCategory(category)
              .map(
                (e) => WorkflowEventItem(
                  event: e.event,
                  label: e.label,
                  description: e.description,
                ),
              )
              .toList(growable: false),
          eventCategoryLabel: _eventCategoryLabel,
          buildVariableSuggestions:
              ({
                required workflowType,
                required argumentDefinitions,
                required eventTrigger,
              }) => _buildWorkflowVariableSuggestions(
                workflowType: workflowType,
                argumentDefinitions: argumentDefinitions,
                eventTrigger: eventTrigger,
              ),
        ),
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _deleteWorkflow(String name) async {
    final workflow = _workflows.firstWhere(
      (w) => w['name'] == name,
      orElse: () => <String, dynamic>{},
    );
    final actionCount = (workflow['actions'] as List?)?.length ?? 0;
    final extra = actionCount > 0
        ? '\n\nThis will remove $actionCount action(s).'
        : '';

    final isCompactScreen = MediaQuery.of(context).size.width < 600;
    final shouldDelete = isCompactScreen
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (sheetContext) {
              final colorScheme = Theme.of(sheetContext).colorScheme;
              final bottomSafePadding = MediaQuery.of(
                sheetContext,
              ).viewPadding.bottom;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + bottomSafePadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr.workflows_delete_title,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('${context.tr.workflows_delete_confirm(name)}$extra'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext, false),
                            child: Text(context.tr.cancel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.error,
                              foregroundColor: colorScheme.onError,
                            ),
                            onPressed: () => Navigator.pop(sheetContext, true),
                            child: Text(context.tr.delete),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          )
        : await AppTheme.showConfirmDialog(
            context,
            title: context.tr.workflows_delete_title,
            content: '${context.tr.workflows_delete_confirm(name)}$extra',
            confirmLabel: context.tr.delete,
            isDestructive: true,
          );

    if (shouldDelete != true) {
      return;
    }

    await appManager.deleteWorkflow(widget.botId, name);
    await _load();
  }

  Map<String, dynamic> _buildWorkflowSharePayload() {
    final normalized = _workflows
        .map((workflow) {
          return normalizeStoredWorkflowDefinition(
            Map<String, dynamic>.from(workflow),
          );
        })
        .toList(growable: false);
    return <String, dynamic>{
      'version': 1,
      'type': 'bot_creator_workflows',
      'workflows': normalized,
    };
  }

  Future<void> _copyWorkflowPayload({required bool asBase64}) async {
    if (_workflows.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.workflows_copy_none)));
      return;
    }

    final payload = _buildWorkflowSharePayload();
    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    final text = asBase64 ? base64Encode(utf8.encode(jsonText)) : jsonText;
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          asBase64
              ? context.tr.workflows_copy_done_base64
              : context.tr.workflows_copy_done_json,
        ),
      ),
    );
  }

  Future<void> _showWorkflowExportOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.data_object_outlined),
                title: Text(context.tr.workflows_export_json),
                subtitle: Text(context.tr.workflows_export_json_desc),
                onTap: () async {
                  Navigator.pop(context);
                  await _copyWorkflowPayload(asBase64: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.key_outlined),
                title: Text(context.tr.workflows_export_base64),
                subtitle: Text(context.tr.workflows_export_base64_desc),
                onTap: () async {
                  Navigator.pop(context);
                  await _copyWorkflowPayload(asBase64: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportSingleWorkflow(Map<String, dynamic> workflow) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  context.tr.workflows_export_tooltip,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.data_object_outlined),
                title: Text(context.tr.workflows_export_json),
                subtitle: Text(context.tr.workflows_export_json_desc),
                onTap: () => Navigator.pop(ctx, 'json'),
              ),
              ListTile(
                leading: const Icon(Icons.key_outlined),
                title: Text(context.tr.workflows_export_base64),
                subtitle: Text(context.tr.workflows_export_base64_desc),
                onTap: () => Navigator.pop(ctx, 'base64'),
              ),
            ],
          ),
        );
      },
    );

    if (format == null || !mounted) return;

    final normalized = normalizeStoredWorkflowDefinition(
      Map<String, dynamic>.from(workflow),
    );
    final jsonText = const JsonEncoder.withIndent('  ').convert(normalized);
    final text = format == 'base64'
        ? base64Encode(utf8.encode(jsonText))
        : jsonText;
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          format == 'base64'
              ? context.tr.workflows_copy_done_base64
              : context.tr.workflows_copy_done_json,
        ),
      ),
    );
  }

  Future<void> _importWorkflows() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final initialText = (clipboard?.text ?? '').trim();
    final controller = TextEditingController(text: initialText);
    var overwrite = true;

    Widget importForm(StateSetter setDialogState, {bool compact = false}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr.workflows_import_desc),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: compact ? 8 : 6,
            maxLines: compact ? 14 : 12,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: context.tr.workflows_import_input_hint,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr.workflows_import_overwrite),
            value: overwrite,
            onChanged: (value) {
              setDialogState(() {
                overwrite = value;
              });
            },
          ),
        ],
      );
    }

    final compactImport = MediaQuery.of(context).size.width < 600;

    final shouldImport = compactImport
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.tr.workflows_import_title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: SingleChildScrollView(
                            child: importForm(setDialogState, compact: true),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(context.tr.cancel),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(context.tr.workflows_import_action),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          )
        : await showDialog<bool>(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    title: Text(context.tr.workflows_import_title),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: importForm(setDialogState),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(context.tr.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(context.tr.workflows_import_action),
                      ),
                    ],
                  );
                },
              );
            },
          );

    if (shouldImport != true) {
      return;
    }

    final rawInput = controller.text.trim();
    if (rawInput.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.workflows_import_empty)),
      );
      return;
    }

    dynamic decoded;
    try {
      if (rawInput.startsWith('{') || rawInput.startsWith('[')) {
        decoded = jsonDecode(rawInput);
      } else {
        final jsonText = utf8.decode(base64Decode(rawInput));
        decoded = jsonDecode(jsonText);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.workflows_import_invalid_format)),
      );
      return;
    }

    List<Map<String, dynamic>> imported = <Map<String, dynamic>>[];
    if (decoded is Map && decoded['workflows'] is List) {
      imported = (decoded['workflows'] as List)
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    } else if (decoded is List) {
      imported = decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    } else if (decoded is Map) {
      imported = <Map<String, dynamic>>[Map<String, dynamic>.from(decoded)];
    }

    if (imported.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.workflows_import_no_valid)),
      );
      return;
    }

    // Build preview entries
    final previewEntries = <Map<String, dynamic>>[];
    for (final raw in imported) {
      final wf = normalizeStoredWorkflowDefinition(raw);
      final wfName = (wf['name'] ?? '').toString().trim();
      if (wfName.isEmpty) continue;
      final wfType = normalizeWorkflowType(wf['workflowType']);
      final actionCount = (wf['actions'] as List?)?.length ?? 0;
      previewEntries.add(<String, dynamic>{
        'name': wfName,
        'type': wfType,
        'actionCount': actionCount,
        'workflow': wf,
      });
    }

    if (previewEntries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.workflows_import_no_valid)),
      );
      return;
    }

    // Show preview with folder selection
    String? importFolder;
    final usedNames = _workflows
        .map((workflow) => (workflow['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    final confirmImport = await _showImportPreviewDialog(
      previewEntries: previewEntries,
      overwrite: overwrite,
      usedNames: usedNames,
    );

    if (confirmImport == null || !mounted) return;
    importFolder = confirmImport['folder'] as String?;
    final confirmedOverwrite = confirmImport['overwrite'] as bool;

    String uniqueName(String base, Set<String> used) {
      var candidate = base;
      var index = 2;
      while (used.contains(candidate)) {
        candidate = '$base ($index)';
        index++;
      }
      used.add(candidate);
      return candidate;
    }

    var importedCount = 0;
    for (final entry in previewEntries) {
      final workflow = entry['workflow'] as Map<String, dynamic>;
      final rawName = (workflow['name'] ?? '').toString().trim();
      if (rawName.isEmpty) continue;

      final workflowType = normalizeWorkflowType(workflow['workflowType']);
      final targetName = confirmedOverwrite
          ? rawName
          : uniqueName(rawName, Set<String>.from(usedNames));
      usedNames.add(targetName);

      final actions = List<Map<String, dynamic>>.from(
        (workflow['actions'] as List?)?.whereType<Map>().map(
              (entry) => Map<String, dynamic>.from(entry),
            ) ??
            const <Map<String, dynamic>>[],
      );

      await appManager.saveWorkflow(
        widget.botId,
        name: targetName,
        actions: actions,
        entryPoint: normalizeWorkflowEntryPoint(workflow['entryPoint']),
        arguments: serializeWorkflowArgumentDefinitions(
          parseWorkflowArgumentDefinitions(workflow['arguments']),
        ),
        workflowType: workflowType,
        eventTrigger: workflowType == workflowTypeEvent
            ? normalizeWorkflowEventTrigger(workflow['eventTrigger'])
            : null,
        folder: importFolder ?? (workflow['folder'] ?? '').toString().trim(),
      );
      importedCount++;
    }

    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.workflows_import_done(importedCount))),
    );
  }

  Future<Map<String, dynamic>?> _showImportPreviewDialog({
    required List<Map<String, dynamic>> previewEntries,
    required bool overwrite,
    required Set<String> usedNames,
  }) async {
    final folders = _existingWorkflowFolders.toList()..sort();
    String selectedFolder = '';
    var localOverwrite = overwrite;

    final compact = MediaQuery.of(context).size.width < 600;

    Widget buildPreview(StateSetter setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr.workflow_import_review_count(previewEntries.length),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: compact ? 180 : 250),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: previewEntries.length,
              itemBuilder: (context, index) {
                final entry = previewEntries[index];
                final wfName = entry['name'] as String;
                final wfType = entry['type'] as String;
                final actionCount = entry['actionCount'] as int;
                final typeLabel = wfType == workflowTypeEvent
                    ? 'Event'
                    : 'General';
                final exists = usedNames.contains(wfName);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(
                          wfType == workflowTypeEvent
                              ? Icons.notifications_active_outlined
                              : Icons.account_tree_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wfName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(context.tr.workflows_preview_summary(typeLabel, actionCount),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (exists)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(context.tr.common_exists,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr.workflows_import_overwrite),
            value: localOverwrite,
            onChanged: (v) {
              setState(() => localOverwrite = v);
            },
            dense: true,
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: selectedFolder.isEmpty ? null : selectedFolder,
            decoration: InputDecoration(
              labelText: context.tr.workflows_folder_destination_optional,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(context.tr.commands_no_folder),
              ),
              ...folders.map(
                (f) => DropdownMenuItem<String>(value: f, child: Text(f)),
              ),
            ],
            onChanged: (v) {
              setState(() => selectedFolder = v ?? '');
            },
          ),
        ],
      );
    }

    final confirmed = compact
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (ctx) {
              return StatefulBuilder(
                builder: (ctx, setState) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + MediaQuery.of(ctx).viewPadding.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(context.tr.workflows_import_preview_title,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: SingleChildScrollView(
                            child: buildPreview(setState),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(context.tr.cancel),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(context.tr.common_import),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          )
        : await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return StatefulBuilder(
                builder: (ctx, setState) {
                  return AlertDialog(
                    title: Text(context.tr.workflows_import_preview_title),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: buildPreview(setState),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.tr.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(context.tr.common_import),
                      ),
                    ],
                  );
                },
              );
            },
          );

    if (confirmed != true) return null;

    return <String, dynamic>{
      'folder': selectedFolder.isEmpty ? null : selectedFolder,
      'overwrite': localOverwrite,
    };
  }

  Set<String> get _existingWorkflowFolders {
    final folders = <String>{};
    for (final w in _workflows) {
      final f = normalizeFolderPath((w['folder'] ?? '').toString());
      if (f.isNotEmpty) {
        var cur = f;
        while (cur.isNotEmpty) {
          folders.add(cur);
          cur = folderParentPath(cur);
        }
      }
    }
    for (final empty in _emptyWorkflowFolders) {
      final f = normalizeFolderPath(empty);
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

  Future<void> _moveWorkflowToFolder(
    Map<String, dynamic> workflow,
    String targetFolder,
  ) async {
    final cleanFolder = normalizeFolderPath(targetFolder);
    final name = (workflow['name'] ?? '').toString();
    if (name.isEmpty) return;

    if (cleanFolder.isNotEmpty) {
      var cur = cleanFolder;
      while (cur.isNotEmpty) {
        _expandedWorkflowFolders.add(cur);
        cur = folderParentPath(cur);
      }
    }

    await appManager.saveWorkflow(
      widget.botId,
      name: name,
      actions: List<Map<String, dynamic>>.from(
        (workflow['actions'] as List?)?.whereType<Map>().map(
              (e) => Map<String, dynamic>.from(e),
            ) ??
            const <Map<String, dynamic>>[],
      ),
      entryPoint: normalizeWorkflowEntryPoint(workflow['entryPoint']),
      arguments: serializeWorkflowArgumentDefinitions(
        parseWorkflowArgumentDefinitions(workflow['arguments']),
      ),
      workflowType: normalizeWorkflowType(workflow['workflowType']),
      eventTrigger:
          normalizeWorkflowType(workflow['workflowType']) == workflowTypeEvent
          ? normalizeWorkflowEventTrigger(workflow['eventTrigger'])
          : null,
      folder: cleanFolder,
    );
    await _load();
  }

  Future<void> _showWorkflowMoveToFolderDialog(
    Map<String, dynamic> workflow,
  ) async {
    final name = (workflow['name'] ?? '').toString();
    final currentFolder = normalizeFolderPath(
      (workflow['folder'] ?? '').toString(),
    );

    final tree = buildCommandFolderTree(
      commands: _workflows,
      emptyFolders: _emptyWorkflowFolders,
    );

    final chosen = await FolderPickerDialog.show(
      context: context,
      title: '${context.tr.workflows_move_to_folder}: $name',
      currentFolder: currentFolder,
      tree: tree,
    );

    if (chosen == null || !mounted || chosen == currentFolder) return;
    await _moveWorkflowToFolder(workflow, chosen);
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
              child: Text(context.tr.save),
            ),
          ],
        );
      },
    );

    if (folderName == null || folderName.isEmpty || !mounted) return;
    final finalPath = cleanParent.isEmpty
        ? normalizeFolderPath(folderName)
        : normalizeFolderPath('$cleanParent/$folderName');
    if (finalPath.isEmpty) return;

    setState(() {
      _emptyWorkflowFolders.add(finalPath);
      var cur = finalPath;
      while (cur.isNotEmpty) {
        _expandedWorkflowFolders.add(cur);
        cur = folderParentPath(cur);
      }
    });
    await _saveEmptyWorkflowFolders();
  }

  Future<void> _renameFolderDialog(String oldPath) async {
    final cleanOld = normalizeFolderPath(oldPath);
    if (cleanOld.isEmpty) return;
    final controller = TextEditingController(text: folderDisplayName(cleanOld));

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

    if (newName == null || newName.isEmpty || !mounted) return;
    final parent = folderParentPath(cleanOld);
    final newPath = parent.isEmpty
        ? normalizeFolderPath(newName)
        : normalizeFolderPath('$parent/$newName');
    if (newPath == cleanOld) return;

    cascadeRenameFolder(
      oldPath: cleanOld,
      newPath: newPath,
      commands: _workflows,
      emptyFolders: _emptyWorkflowFolders,
      onUpdateCommand: (updated) async {
        await appManager.saveWorkflow(
          widget.botId,
          name: (updated['name'] ?? '').toString(),
          actions: List<Map<String, dynamic>>.from(
            (updated['actions'] as List?)?.whereType<Map>().map(
                  (e) => Map<String, dynamic>.from(e),
                ) ??
                const <Map<String, dynamic>>[],
          ),
          entryPoint: normalizeWorkflowEntryPoint(updated['entryPoint']),
          arguments: serializeWorkflowArgumentDefinitions(
            parseWorkflowArgumentDefinitions(updated['arguments']),
          ),
          workflowType: normalizeWorkflowType(updated['workflowType']),
          eventTrigger:
              normalizeWorkflowType(updated['workflowType']) ==
                  workflowTypeEvent
              ? normalizeWorkflowEventTrigger(updated['eventTrigger'])
              : null,
          folder: (updated['folder'] ?? '').toString(),
        );
      },
    );

    if (_expandedWorkflowFolders.remove(cleanOld)) {
      _expandedWorkflowFolders.add(newPath);
    }
    await _saveEmptyWorkflowFolders();
    await _load();
  }

  Future<void> _deleteFolderDialog(String folderPath) async {
    final cleanPath = normalizeFolderPath(folderPath);
    if (cleanPath.isEmpty) return;

    final confirmed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.commands_delete_folder,
      content: context.tr.commands_delete_folder_desc,
      confirmLabel: context.tr.confirm,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    cascadeDeleteFolder(
      targetPath: cleanPath,
      commands: _workflows,
      emptyFolders: _emptyWorkflowFolders,
      onUpdateCommand: (updated) async {
        await appManager.saveWorkflow(
          widget.botId,
          name: (updated['name'] ?? '').toString(),
          actions: List<Map<String, dynamic>>.from(
            (updated['actions'] as List?)?.whereType<Map>().map(
                  (e) => Map<String, dynamic>.from(e),
                ) ??
                const <Map<String, dynamic>>[],
          ),
          entryPoint: normalizeWorkflowEntryPoint(updated['entryPoint']),
          arguments: serializeWorkflowArgumentDefinitions(
            parseWorkflowArgumentDefinitions(updated['arguments']),
          ),
          workflowType: normalizeWorkflowType(updated['workflowType']),
          eventTrigger:
              normalizeWorkflowType(updated['workflowType']) ==
                  workflowTypeEvent
              ? normalizeWorkflowEventTrigger(updated['eventTrigger'])
              : null,
          folder: (updated['folder'] ?? '').toString(),
        );
      },
    );

    _expandedWorkflowFolders.remove(cleanPath);
    await _saveEmptyWorkflowFolders();
    await _load();
  }

  List<Map<String, dynamic>> _visibleWorkflows() {
    final query = _searchQuery.trim().toLowerCase();
    return _workflows
        .where((workflow) {
          final workflowType = normalizeWorkflowType(workflow['workflowType']);
          if (widget.eventsOnly && workflowType != workflowTypeEvent) {
            return false;
          }
          if (_workflowFilter != 'all' && workflowType != _workflowFilter) {
            return false;
          }

          final folder = normalizeFolderPath(
            (workflow['folder'] ?? '').toString(),
          );
          if (_folderFilter.isNotEmpty &&
              folder != _folderFilter &&
              !folder.startsWith('$_folderFilter/')) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          final name = (workflow['name'] ?? '').toString().toLowerCase();
          final entryPoint = normalizeWorkflowEntryPoint(
            workflow['entryPoint'],
          ).toLowerCase();
          final eventTrigger = normalizeWorkflowEventTrigger(
            workflow['eventTrigger'],
          );
          final eventName = _eventLabel(
            (eventTrigger['event'] ?? '').toString(),
          ).toLowerCase();
          return name.contains(query) ||
              folder.toLowerCase().contains(query) ||
              entryPoint.contains(query) ||
              eventName.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _showCreateWorkflowMenu({String? prefillFolder}) async {
    if (widget.eventsOnly) {
      await _createOrEditWorkflow(
        initialWorkflowType: workflowTypeEvent,
        prefillFolder: prefillFolder,
      );
      return;
    }

    final selection = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr.workflows_create,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: context.tr.cancel,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(context.tr.workflows_type_general),
                  subtitle: Text(context.tr.workflows_type_general_desc),
                  onTap: () => Navigator.pop(context, workflowTypeGeneral),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(context.tr.workflows_type_event),
                  subtitle: Text(context.tr.workflows_type_event_desc),
                  onTap: () => Navigator.pop(context, workflowTypeEvent),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (selection == null || !mounted) {
      return;
    }

    await _createOrEditWorkflow(
      initialWorkflowType: selection,
      prefillFolder: prefillFolder,
    );
  }

  Widget _buildFilters() {
    final visible = _visibleWorkflows();
    final query = _searchQuery.trim();
    final showCreate = query.isNotEmpty && visible.isEmpty;

    return NotionFilterBar(
      searchQuery: _searchQuery,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      searchHint: context.tr.workflows_search_hint,
      addFilterLabel: context.tr.notion_filter_add,
      filters: [
        if (!widget.eventsOnly)
          NotionFilter(
            id: 'type',
            label: context.tr.notion_filter_type,
            icon: Icons.category_outlined,
            options: {
              '': context.tr.common_all,
              workflowTypeGeneral: context.tr.workflows_type_badge_general,
              workflowTypeEvent: context.tr.workflows_type_badge_event,
            },
            selectedValue: _workflowFilter == 'all' ? '' : _workflowFilter,
          ),
        if (_existingWorkflowFolders.isNotEmpty)
          NotionFilter(
            id: 'folder',
            label: context.tr.commands_folder_label,
            icon: Icons.folder_outlined,
            options: {
              '': context.tr.commands_all_folders,
              for (final folder in _existingWorkflowFolders) folder: folder,
            },
            selectedValue: _folderFilter,
          ),
      ],
      onFilterChanged: (filterId, value) {
        setState(() {
          if (filterId == 'type') {
            _workflowFilter = value.isEmpty ? 'all' : value;
          } else if (filterId == 'folder') {
            _folderFilter = value;
          }
        });
      },
      showCreateSuggestion: showCreate,
      createFromQueryLabel: context.tr.notion_create_workflow_from_query(query),
      onCreateFromQuery: showCreate
          ? () => _createOrEditWorkflow(
              initialWorkflowType: widget.eventsOnly
                  ? workflowTypeEvent
                  : workflowTypeGeneral,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleWorkflows = _visibleWorkflows();
    final generalWorkflows = visibleWorkflows
        .where(
          (workflow) =>
              normalizeWorkflowType(workflow['workflowType']) ==
              workflowTypeGeneral,
        )
        .toList(growable: false);
    final eventWorkflows = visibleWorkflows
        .where(
          (workflow) =>
              normalizeWorkflowType(workflow['workflowType']) ==
              workflowTypeEvent,
        )
        .toList(growable: false);
    final adsEnabled = AdsPlacementPolicy.isPlacementEnabled(
      NativeAdPlacement.workflowsList,
    );
    final workflowChildren = <Widget>[];
    var displayedWorkflowsCount = 0;

    final showSectionHeaders =
        !widget.eventsOnly &&
        generalWorkflows.isNotEmpty &&
        eventWorkflows.isNotEmpty;

    void appendSection(String title, List<Map<String, dynamic>> workflows) {
      if (workflows.isEmpty) {
        return;
      }

      if (showSectionHeaders) {
        workflowChildren.add(_WorkflowSectionHeader(title: title));
      }

      void addWorkflowCard(
        Map<String, dynamic> workflow, {
        double indent = 0.0,
      }) {
        workflowChildren.add(
          Padding(
            padding: EdgeInsets.only(left: indent, bottom: 6),
            child: _buildWorkflowTile(workflow),
          ),
        );
        displayedWorkflowsCount += 1;
        if (adsEnabled &&
            AdsPlacementPolicy.shouldInsertAfterContentCount(
              displayedWorkflowsCount,
            )) {
          workflowChildren.add(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: NativeAdSlot(
                placement: NativeAdPlacement.workflowsList,
                height: 110,
                margin: EdgeInsets.zero,
              ),
            ),
          );
        }
      }

      if (title == context.tr.workflows_event_section ||
          (widget.eventsOnly && title == context.tr.workflows_type_event)) {
        final Map<String, List<Map<String, dynamic>>> byEvent = {};
        for (final workflow in workflows) {
          final trigger = normalizeWorkflowEventTrigger(
            workflow['eventTrigger'],
          );
          final eventKey = (trigger['event'] ?? '').toString();
          byEvent.putIfAbsent(eventKey, () => []).add(workflow);
        }
        final sortedEvents = byEvent.keys.toList(growable: false)..sort();
        final showEventHeader =
            sortedEvents.length > 1 ||
            (sortedEvents.isNotEmpty && sortedEvents.first.isNotEmpty);

        for (final event in sortedEvents) {
          if (showEventHeader) {
            workflowChildren.add(
              _WorkflowFolderHeader(
                title: _eventLabel(event),
                count: byEvent[event]!.length,
                icon: Icons.notifications_active_outlined,
              ),
            );
          }
          for (final workflow in byEvent[event]!) {
            addWorkflowCard(workflow);
          }
        }
        return;
      }

      final tree = buildCommandFolderTree(
        commands: workflows,
        emptyFolders: _emptyWorkflowFolders,
      );

      // 1. Root workflows (no folder)
      if (tree.rootCommands.isNotEmpty) {
        if (tree.rootFolders.isNotEmpty) {
          workflowChildren.add(
            DragTarget<Map<String, dynamic>>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) {
                _moveWorkflowToFolder(details.data, '');
              },
              builder: (context, candidateData, _) {
                final isHovered = candidateData.isNotEmpty;
                return Container(
                  decoration: isHovered
                      ? BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
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
                            '${tree.rootCommands.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
              },
            ),
          );
        }
        for (final workflow in tree.rootCommands) {
          addWorkflowCard(workflow);
        }
      }

      // 2. Recursive folder node rendering
      void renderNode(CommandFolderNode node) {
        final isExpanded = _expandedWorkflowFolders.contains(node.fullPath);
        final indent = node.depth * 16.0;

        workflowChildren.add(
          _WorkflowFolderHeader(
            title: node.name,
            count: node.totalCommandCount,
            directCount: node.commands.length,
            depth: node.depth,
            isExpanded: isExpanded,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedWorkflowFolders.remove(node.fullPath);
                } else {
                  _expandedWorkflowFolders.add(node.fullPath);
                }
              });
            },
            onRename: () => _renameFolderDialog(node.fullPath),
            onDelete: () => _deleteFolderDialog(node.fullPath),
            onAddSubfolder: () =>
                _showCreateFolderDialog(parentPath: node.fullPath),
            onNewWorkflow: () =>
                _showCreateWorkflowMenu(prefillFolder: node.fullPath),
            onAcceptDrop: (wf) {
              _moveWorkflowToFolder(wf, node.fullPath);
            },
          ),
        );

        if (!isExpanded) return;

        // Render direct workflows in this folder
        for (final wf in node.commands) {
          addWorkflowCard(wf, indent: indent);
        }

        // Render subfolders recursively
        for (final subfolder in node.subfolders) {
          renderNode(subfolder);
        }
      }

      for (final rootFolder in tree.rootFolders) {
        renderNode(rootFolder);
      }
    }

    if (!widget.eventsOnly) {
      appendSection(context.tr.workflows_general_section, generalWorkflows);
    }
    appendSection(
      widget.eventsOnly
          ? context.tr.workflows_type_event
          : context.tr.workflows_event_section,
      eventWorkflows,
    );

    return Scaffold(
      appBar: AppBar(
        leading: editorSubPageLeading(context),
        title: Text(
          widget.eventsOnly
              ? context.tr.workflows_type_event
              : context.tr.workflows_title,
        ),
        actions: [
          if (widget.eventsOnly)
            IconButton(
              tooltip: context.tr.workflows_create_event,
              onPressed: () =>
                  _createOrEditWorkflow(initialWorkflowType: workflowTypeEvent),
              icon: const Icon(Icons.add_rounded),
            )
          else
            PopupMenuButton<String>(
              tooltip: context.tr.workflows_create,
              icon: const Icon(Icons.add_rounded),
              onSelected: (type) =>
                  _createOrEditWorkflow(initialWorkflowType: type),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: workflowTypeGeneral,
                  child: Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text(context.tr.workflows_type_general),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: workflowTypeEvent,
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text(context.tr.workflows_type_event),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            tooltip: context.tr.workflows_import_tooltip,
            onPressed: _importWorkflows,
            icon: const Icon(Icons.content_paste_go_outlined),
          ),
          IconButton(
            tooltip: context.tr.workflows_export_tooltip,
            onPressed: _showWorkflowExportOptions,
            icon: const Icon(Icons.copy_all_outlined),
          ),
          IconButton(
            tooltip: context.tr.workflows_docs_tooltip,
            onPressed: () {
              openDocumentationHubForBot(context, botId: widget.botId);
            },
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      // Largeur et marges communes à toutes les pages (contrat AppPageLayout) :
      // la liste n'est plus en plein-cadre.
      body: PageContent(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _workflows.isEmpty
            ? EditorEmptyState(
                icon: widget.eventsOnly
                    ? Icons.notifications_active_outlined
                    : Icons.account_tree_outlined,
                title: context.tr.workflows_empty,
                actionLabel: widget.eventsOnly
                    ? context.tr.workflows_create_event
                    : context.tr.workflows_create,
                onAction: _showCreateWorkflowMenu,
              )
            : ListView(
                // Réserve de bas de liste conservée telle quelle.
                padding: EdgeInsets.only(
                  bottom: FloatingGlassNavBar.contentClearanceOf(context) + 24,
                ),
                children: [
                  _buildFilters(),
                  const SizedBox(height: 8),
                  if (visibleWorkflows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(context.tr.workflows_no_matches),
                      ),
                    )
                  else
                    ...workflowChildren,
                ],
              ),
      ),
    );
  }

  Widget _buildWorkflowTile(Map<String, dynamic> workflow) {
    final name = (workflow['name'] ?? '').toString();
    final actions = (workflow['actions'] is List)
        ? (workflow['actions'] as List).length
        : 0;
    final workflowType = normalizeWorkflowType(workflow['workflowType']);
    final entryPoint = normalizeWorkflowEntryPoint(workflow['entryPoint']);
    final argsCount = parseWorkflowArgumentDefinitions(
      workflow['arguments'],
    ).length;
    final folder = (workflow['folder'] ?? '').toString().trim();
    final eventTrigger = normalizeWorkflowEventTrigger(
      workflow['eventTrigger'],
    );
    final executionMode = normalizeWorkflowExecutionMode(
      workflow['executionMode'],
      supportsJavascript: true,
    );
    final isJsEventScript =
        widget.eventsOnly &&
        workflowType == workflowTypeEvent &&
        executionMode == workflowExecutionModeJavascript;
    final subtitle = workflowType == workflowTypeEvent
        ? isJsEventScript
              ? '${context.tr.cmd_execution_mode_javascript} • ${_eventLabel((eventTrigger['event'] ?? '').toString())}'
              : context.tr.workflows_event_subtitle(
                  actions,
                  _eventLabel((eventTrigger['event'] ?? '').toString()),
                )
        : context.tr.workflows_subtitle(
            actions,
            entryPoint,
            argsCount.toString(),
          );
    final templateOrigin = workflow['templateOrigin'] as Map<String, dynamic>?;
    final templateId = (templateOrigin?['templateId'] ?? '').toString();
    final isEvent = workflowType == workflowTypeEvent;
    final compactTile = MediaQuery.of(context).size.width < 420;

    final cardWidget = Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                (isEvent
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.secondaryContainer)
                    .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(
            isEvent
                ? Icons.notifications_active_outlined
                : Icons.account_tree_outlined,
            color: isEvent
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                _workflowTypeBadgeLabel(workflowType),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (folder.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  folder,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (templateId.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  color: Theme.of(context).colorScheme.tertiaryContainer,
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
                        fontWeight: FontWeight.w600,
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: compactTile
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _createOrEditWorkflow(initial: workflow);
                  } else if (value == 'move') {
                    _showWorkflowMoveToFolderDialog(workflow);
                  } else if (value == 'delete') {
                    _deleteWorkflow(name);
                  } else if (value == 'export') {
                    _exportSingleWorkflow(workflow);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    height: 48,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined),
                        const SizedBox(width: 8),
                        Text(context.tr.common_edit),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'move',
                    height: 48,
                    child: Row(
                      children: [
                        const Icon(Icons.drive_file_move_outlined),
                        const SizedBox(width: 8),
                        Text(context.tr.commands_move_to_folder),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'export',
                    height: 48,
                    child: Row(
                      children: [
                        const Icon(Icons.ios_share_outlined),
                        const SizedBox(width: 8),
                        Text(context.tr.common_export),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    height: 48,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(context.tr.common_delete,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showWorkflowMoveToFolderDialog(workflow),
                    tooltip: context.tr.commands_move_to_folder,
                    icon: const Icon(Icons.drive_file_move_outlined, size: 20),
                  ),
                  IconButton(
                    onPressed: () => _exportSingleWorkflow(workflow),
                    tooltip: context.tr.common_export,
                    icon: const Icon(Icons.ios_share_outlined, size: 20),
                  ),
                  IconButton(
                    onPressed: () => _deleteWorkflow(name),
                    tooltip: context.tr.delete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_outlined, size: 16),
                ],
              ),
        onTap: () => _createOrEditWorkflow(initial: workflow),
        onLongPress: () => _showWorkflowMoveToFolderDialog(workflow),
      ),
    );

    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    final feedbackWidget = Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEvent
                  ? Icons.notifications_active_outlined
                  : Icons.account_tree_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Draggable<Map<String, dynamic>>(
        data: workflow,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedbackWidget,
        childWhenDragging: Opacity(opacity: 0.35, child: cardWidget),
        child: cardWidget,
      );
    }

    return LongPressDraggable<Map<String, dynamic>>(
      data: workflow,
      hapticFeedbackOnStart: true,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: feedbackWidget,
      childWhenDragging: Opacity(opacity: 0.35, child: cardWidget),
      child: cardWidget,
    );
  }
}

class _WorkflowSectionHeader extends StatelessWidget {
  const _WorkflowSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _WorkflowFolderHeader extends StatelessWidget {
  final String title;
  final int count;
  final int directCount;
  final int depth;
  final bool isExpanded;
  final IconData? icon;
  final VoidCallback? onToggle;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onAddSubfolder;
  final VoidCallback? onNewWorkflow;
  final ValueChanged<Map<String, dynamic>>? onAcceptDrop;

  const _WorkflowFolderHeader({
    required this.title,
    required this.count,
    this.directCount = 0,
    this.depth = 0,
    this.isExpanded = true,
    this.icon,
    this.onToggle,
    this.onRename,
    this.onDelete,
    this.onAddSubfolder,
    this.onNewWorkflow,
    this.onAcceptDrop,
  });

  @override
  Widget build(BuildContext context) {
    if (onToggle == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Row(
          children: [
            Icon(
              icon ?? Icons.folder_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          ],
        ),
      );
    }

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
              child: Icon(
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
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                if (onNewWorkflow != null)
                  PopupMenuItem(
                    value: 'add_workflow',
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(context.tr.workflows_create),
                      ],
                    ),
                  ),
                if (onAddSubfolder != null)
                  PopupMenuItem(
                    value: 'add_subfolder',
                    child: Row(
                      children: [
                        const Icon(Icons.create_new_folder_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(context.tr.commands_create_folder),
                      ],
                    ),
                  ),
                if (onRename != null)
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
                if (onDelete != null)
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
                if (value == 'add_workflow') {
                  onNewWorkflow?.call();
                } else if (value == 'add_subfolder') {
                  onAddSubfolder?.call();
                } else if (value == 'rename') {
                  onRename?.call();
                } else if (value == 'delete') {
                  onDelete?.call();
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

@visibleForTesting
class CreateWorkflowCard extends StatelessWidget {
  const CreateWorkflowCard({
    super.key,
    required this.eventsOnly,
    required this.onTap,
  });

  final bool eventsOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final tokens = HomeTokens.of(context);
    final fill = isDark
        ? tokens.accent.withValues(alpha: 0.30)
        : scheme.surfaceContainerHighest;
    final border = isDark ? tokens.accent : scheme.primary;
    final avatarFill = tokens.accent;
    final avatarIconColor = isDark ? Colors.white : tokens.onAccent;

    final title = eventsOnly
        ? context.tr.workflows_create_event
        : context.tr.workflows_create;
    final subtitle = eventsOnly
        ? context.tr.workflows_create_event_subtitle
        : context.tr.workflows_create_subtitle;

    return Stack(
      children: [
        Material(
          color: fill,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: avatarFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 26,
                      color: avatarIconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: homeDisplayStyle(16, color: scheme.onSurface),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: homeDisplayStyle(
                            12,
                            weight: FontWeight.w400,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.30)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark
                        ? tokens.muted
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: HomeDashedRoundedRectPainter(
                color: border,
                radius: AppTheme.radiusCard,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

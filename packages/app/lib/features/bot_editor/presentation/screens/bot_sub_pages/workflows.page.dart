import 'dart:convert';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflow_block_editor.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/entry_point_block.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator_shared/utils/variable_catalog.dart' show inferCategory;
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
import 'package:bot_creator/core/utils/responsive.dart';

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
    final workflows = await appManager.getWorkflows(widget.botId);
    if (!mounted) {
      return;
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
            kind: (definition['valueType']?.toString() == 'number' ||
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
  }) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) => WorkflowBlockEditor(
              botId: widget.botId,
              initial: initial,
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
              eventsForCategory:
                  (category) => _eventsForCategory(category)
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
    final extra =
        actionCount > 0 ? '\n\nThis will remove $actionCount action(s).' : '';

    final isCompactScreen = MediaQuery.of(context).size.width < 600;
    final shouldDelete =
        isCompactScreen
            ? await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (sheetContext) {
                final colorScheme = Theme.of(sheetContext).colorScheme;
                final bottomSafePadding =
                    MediaQuery.of(sheetContext).viewPadding.bottom;
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
                      Text(
                        '${context.tr.workflows_delete_confirm(name)}$extra',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  () => Navigator.pop(sheetContext, false),
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
                              onPressed:
                                  () => Navigator.pop(sheetContext, true),
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
    final text = format == 'base64' ? base64Encode(utf8.encode(jsonText)) : jsonText;
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

    final shouldImport =
        compactImport
            ? await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    final bottomInset =
                        MediaQuery.of(context).viewInsets.bottom;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        12 + bottomInset,
                      ),
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
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text(context.tr.cancel),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    context.tr.workflows_import_action,
                                  ),
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
    final usedNames =
        _workflows
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
      final targetName =
          confirmedOverwrite
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
        eventTrigger:
            workflowType == workflowTypeEvent
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
          Text(
            'Review ${previewEntries.length} workflow(s) to import:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: compact ? 180 : 250,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: previewEntries.length,
              itemBuilder: (context, index) {
                final entry = previewEntries[index];
                final wfName = entry['name'] as String;
                final wfType = entry['type'] as String;
                final actionCount = entry['actionCount'] as int;
                final typeLabel = wfType == workflowTypeEvent ? 'Event' : 'General';
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
                              Text(
                                '$typeLabel  •  $actionCount action(s)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              color: Theme.of(context).colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Exists',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
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
              labelText: 'Destination folder (optional)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No folder'),
              ),
              ...folders.map(
                (f) => DropdownMenuItem<String>(
                  value: f,
                  child: Text(f),
                ),
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
                      Text(
                        'Import workflow preview',
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
                              child: const Text('Import'),
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
                  title: const Text('Import workflow preview'),
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
                      child: const Text('Import'),
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
    return _workflows
        .map((w) => (w['folder'] ?? '').toString().trim())
        .where((f) => f.isNotEmpty)
        .toSet();
  }

  Future<void> _showWorkflowMoveToFolderDialog(
    Map<String, dynamic> workflow,
  ) async {
    final name = (workflow['name'] ?? '').toString();
    final currentFolder = (workflow['folder'] ?? '').toString().trim();
    final folders = _existingWorkflowFolders.toList()..sort();
    final controller = TextEditingController();

    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  context.tr.workflows_move_to_folder,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (currentFolder.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: Text(context.tr.workflows_remove_from_folder),
                  onTap: () => Navigator.pop(context, ''),
                ),
              for (final folder in folders)
                ListTile(
                  leading: Icon(
                    Icons.folder,
                    color:
                        folder == currentFolder
                            ? Theme.of(context).colorScheme.primary
                            : null,
                  ),
                  title: Text(folder),
                  selected: folder == currentFolder,
                  onTap: () => Navigator.pop(context, folder),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: context.tr.workflows_new_folder_hint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        final newFolder = controller.text.trim();
                        if (newFolder.isNotEmpty) {
                          Navigator.pop(context, newFolder);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen == null || !mounted) return;

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
      folder: chosen,
    );
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

          if (query.isEmpty) {
            return true;
          }

          final name = (workflow['name'] ?? '').toString().toLowerCase();
          final folder = (workflow['folder'] ?? '').toString().toLowerCase();
          final entryPoint =
              normalizeWorkflowEntryPoint(workflow['entryPoint']).toLowerCase();
          final eventTrigger = normalizeWorkflowEventTrigger(
            workflow['eventTrigger'],
          );
          final eventName =
              _eventLabel(
                (eventTrigger['event'] ?? '').toString(),
              ).toLowerCase();
          return name.contains(query) ||
              folder.contains(query) ||
              entryPoint.contains(query) ||
              eventName.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _showCreateWorkflowMenu() async {
    if (widget.eventsOnly) {
      await _createOrEditWorkflow(initialWorkflowType: workflowTypeEvent);
      return;
    }

    final selection = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
        );
      },
    );

    if (selection == null) {
      return;
    }

    await _createOrEditWorkflow(initialWorkflowType: selection);
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
      ],
      onFilterChanged: (filterId, value) {
        setState(() {
          if (filterId == 'type') {
            _workflowFilter = value.isEmpty ? 'all' : value;
          }
        });
      },
      showCreateSuggestion: showCreate,
      createFromQueryLabel: context.tr.notion_create_workflow_from_query(query),
      onCreateFromQuery:
          showCreate
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

    void appendSection(String title, List<Map<String, dynamic>> workflows) {
      if (workflows.isEmpty) {
        return;
      }

      workflowChildren.add(_WorkflowSectionHeader(title: title));
      if (title == context.tr.workflows_event_section) {
        final Map<String, List<Map<String, dynamic>>> byEvent = {};
        for (final workflow in workflows) {
          final trigger = normalizeWorkflowEventTrigger(
            workflow['eventTrigger'],
          );
          final eventKey = (trigger['event'] ?? '').toString();
          byEvent.putIfAbsent(eventKey, () => []).add(workflow);
        }
        final sortedEvents = byEvent.keys.toList(growable: false)..sort();
        for (final event in sortedEvents) {
          workflowChildren.add(
            _WorkflowFolderHeader(
              title: _eventLabel(event),
              count: byEvent[event]!.length,
              icon: Icons.notifications_active_outlined,
            ),
          );
          for (final workflow in byEvent[event]!) {
            workflowChildren.add(_buildWorkflowTile(workflow));
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
        }
        return;
      }

      final Map<String, List<Map<String, dynamic>>> byFolder = {};
      for (final workflow in workflows) {
        final folder = (workflow['folder'] ?? '').toString().trim();
        byFolder.putIfAbsent(folder, () => []).add(workflow);
      }
      final sortedFolders =
          byFolder.keys.toList()..sort((a, b) {
            if (a.isEmpty) return -1;
            if (b.isEmpty) return 1;
            return a.compareTo(b);
          });

      for (final folder in sortedFolders) {
        if (folder.isNotEmpty) {
          workflowChildren.add(
            _WorkflowFolderHeader(
              title: folder,
              count: byFolder[folder]!.length,
            ),
          );
        }
        for (final workflow in byFolder[folder]!) {
          workflowChildren.add(_buildWorkflowTile(workflow));
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
        leading: !ResponsiveHelper.isDesktopPlatform()
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.openParentDrawer(),
              )
            : null,
        title: Text(
          widget.eventsOnly
              ? context.tr.workflows_type_event
              : context.tr.workflows_title,
        ),
        actions: [
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
              openDocumentationHubForBot(
                context,
                botId: widget.botId,
              );
            },
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateWorkflowMenu,
        child: const Icon(Icons.add),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _workflows.isEmpty
              ? Center(child: Text(context.tr.workflows_empty))
              : ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  _buildFilters(),
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
    );
  }

  Widget _buildWorkflowTile(Map<String, dynamic> workflow) {
    final name = (workflow['name'] ?? '').toString();
    final actions =
        (workflow['actions'] is List)
            ? (workflow['actions'] as List).length
            : 0;
    final workflowType = normalizeWorkflowType(workflow['workflowType']);
    final entryPoint = normalizeWorkflowEntryPoint(workflow['entryPoint']);
    final argsCount =
        parseWorkflowArgumentDefinitions(workflow['arguments']).length;
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
    final subtitle =
        workflowType == workflowTypeEvent
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

    final compactTile = MediaQuery.of(context).size.width < 420;

    return Column(
      children: [
        ListTile(
          onLongPress: () => _showWorkflowMoveToFolderDialog(workflow),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: Icon(
            workflowType == workflowTypeEvent
                ? Icons.notifications_active_outlined
                : Icons.account_tree_outlined,
          ),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      _workflowTypeBadgeLabel(workflowType),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (folder.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      ),
                      child: Text(
                        folder,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (((workflow['templateOrigin']
                              as Map<String, dynamic>?)?['templateId'] ??
                          '')
                      .toString()
                      .isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (workflow['templateOrigin']
                                    as Map<String, dynamic>)['templateId']
                                .toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          trailing:
              compactTile
                  ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _createOrEditWorkflow(initial: workflow);
                      } else if (value == 'delete') {
                        _deleteWorkflow(name);
                      } else if (value == 'export') {
                        _exportSingleWorkflow(workflow);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            height: 48,
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 8),
                                Text(context.tr.common_edit),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'export',
                            height: 48,
                            child: Row(
                              children: [
                                Icon(Icons.ios_share_outlined),
                                SizedBox(width: 8),
                                Text('Export'),
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
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                  )
                  : Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed:
                            () => _exportSingleWorkflow(workflow),
                        tooltip: 'Export',
                        icon: const Icon(Icons.ios_share_outlined),
                      ),
                      IconButton(
                        onPressed:
                            () => _createOrEditWorkflow(initial: workflow),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _deleteWorkflow(name),
                        tooltip: context.tr.delete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _WorkflowSectionHeader extends StatelessWidget {
  const _WorkflowSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
  const _WorkflowFolderHeader({
    required this.title,
    required this.count,
    this.icon = Icons.folder,
  });

  final String title;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}


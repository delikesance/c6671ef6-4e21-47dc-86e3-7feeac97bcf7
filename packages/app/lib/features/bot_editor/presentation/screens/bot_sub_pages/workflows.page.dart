import 'dart:convert';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflow_block_editor.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflow_docs.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/entry_point_block.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/features/bot_editor/logic/app_emoji_api.dart';
import 'package:bot_creator/features/ads/logic/ads_placement_policy.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator/features/ads/presentation/native_ad_slot.dart';
import 'package:bot_creator/core/widgets/notion_filter_bar.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator_shared/bot_creator_shared.dart' show VariableCatalog;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkflowsPage extends StatefulWidget {
  const WorkflowsPage({super.key, required this.botId});

  final String botId;

  @override
  State<WorkflowsPage> createState() => _WorkflowsPageState();
}

class _WorkflowsPageState extends State<WorkflowsPage> {
  List<Map<String, dynamic>> _workflows = <Map<String, dynamic>>[];
  bool _loading = true;
  List<AppEmoji> _appEmojis = [];
  String _searchQuery = '';
  String _workflowFilter = 'all';

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

  @override
  void initState() {
    super.initState();
    _load();
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

  List<_WorkflowEventDefinition>
  get _workflowEventCatalog => const <_WorkflowEventDefinition>[
    _WorkflowEventDefinition(
      category: 'core',
      event: 'ready',
      label: 'Ready',
      description: 'Contains the initial state information.',
    ),
    _WorkflowEventDefinition(
      category: 'core',
      event: 'resumed',
      label: 'Resumed',
      description: 'Response to Resume.',
    ),
    _WorkflowEventDefinition(
      category: 'core',
      event: 'interactionCreate',
      label: 'Interaction Create',
      description: 'User used an interaction, such as an application command.',
    ),
    _WorkflowEventDefinition(
      category: 'commands',
      event: 'applicationCommandPermissionsUpdate',
      label: 'Application Command Permissions Update',
      description: 'Application command permission was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'automod',
      event: 'autoModerationRuleCreate',
      label: 'Auto Moderation Rule Create',
      description: 'Auto Moderation rule was created.',
    ),
    _WorkflowEventDefinition(
      category: 'automod',
      event: 'autoModerationRuleUpdate',
      label: 'Auto Moderation Rule Update',
      description: 'Auto Moderation rule was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'automod',
      event: 'autoModerationRuleDelete',
      label: 'Auto Moderation Rule Delete',
      description: 'Auto Moderation rule was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'automod',
      event: 'autoModerationActionExecution',
      label: 'Auto Moderation Action Execution',
      description:
          'Auto Moderation rule was triggered and an action was executed.',
    ),
    _WorkflowEventDefinition(
      category: 'channels',
      event: 'channelCreate',
      label: 'Channel Create',
      description: 'New guild channel created.',
    ),
    _WorkflowEventDefinition(
      category: 'channels',
      event: 'channelUpdate',
      label: 'Channel Update',
      description: 'Channel was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'channels',
      event: 'channelDelete',
      label: 'Channel Delete',
      description: 'Channel was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'channels',
      event: 'channelPinsUpdate',
      label: 'Channel Pins Update',
      description: 'Message was pinned or unpinned.',
    ),
    _WorkflowEventDefinition(
      category: 'threads',
      event: 'threadCreate',
      label: 'Thread Create',
      description:
          'Thread created, also sent when being added to a private thread.',
    ),
    _WorkflowEventDefinition(
      category: 'threads',
      event: 'threadUpdate',
      label: 'Thread Update',
      description: 'Thread was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'threads',
      event: 'threadDelete',
      label: 'Thread Delete',
      description: 'Thread was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'threads',
      event: 'threadListSync',
      label: 'Thread List Sync',
      description:
          'Sent when gaining access to a channel, contains all active threads in that channel.',
    ),
    _WorkflowEventDefinition(
      category: 'threads',
      event: 'threadMemberUpdate',
      label: 'Thread Member Update',
      description: 'Thread member for the current user was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'threads',
      event: 'threadMembersUpdate',
      label: 'Thread Members Update',
      description: 'Some users were added to or removed from a thread.',
    ),
    _WorkflowEventDefinition(
      category: 'entitlements',
      event: 'entitlementCreate',
      label: 'Entitlement Create',
      description: 'Entitlement was created.',
    ),
    _WorkflowEventDefinition(
      category: 'entitlements',
      event: 'entitlementUpdate',
      label: 'Entitlement Update',
      description: 'Entitlement was updated or renewed.',
    ),
    _WorkflowEventDefinition(
      category: 'entitlements',
      event: 'entitlementDelete',
      label: 'Entitlement Delete',
      description: 'Entitlement was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'guilds',
      event: 'guildCreate',
      label: 'Guild Create',
      description: 'Guild became available, or the bot joined a guild.',
    ),
    _WorkflowEventDefinition(
      category: 'guilds',
      event: 'guildUpdate',
      label: 'Guild Update',
      description: 'Guild was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'guilds',
      event: 'guildDelete',
      label: 'Guild Delete',
      description: 'Guild became unavailable, or the bot left a guild.',
    ),
    _WorkflowEventDefinition(
      category: 'guilds',
      event: 'guildAuditLogCreate',
      label: 'Guild Audit Log Entry Create',
      description: 'A guild audit log entry was created.',
    ),
    _WorkflowEventDefinition(
      category: 'guilds',
      event: 'guildEmojisUpdate',
      label: 'Guild Emojis Update',
      description: 'Guild emojis were updated.',
    ),
    _WorkflowEventDefinition(
      category: 'guilds',
      event: 'guildStickersUpdate',
      label: 'Guild Stickers Update',
      description: 'Guild stickers were updated.',
    ),
    _WorkflowEventDefinition(
      category: 'guilds',
      event: 'guildIntegrationsUpdate',
      label: 'Guild Integrations Update',
      description: 'Guild integration was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'guilds',
      event: 'guildMembersChunk',
      label: 'Guild Members Chunk',
      description: 'Response to Request Guild Members.',
    ),
    _WorkflowEventDefinition(
      category: 'members',
      event: 'guildBanAdd',
      label: 'Guild Ban Add',
      description: 'User was banned from a guild.',
    ),
    _WorkflowEventDefinition(
      category: 'members',
      event: 'guildBanRemove',
      label: 'Guild Ban Remove',
      description: 'User was unbanned from a guild.',
    ),
    _WorkflowEventDefinition(
      category: 'members',
      event: 'guildMemberAdd',
      label: 'Guild Member Add',
      description: 'New user joined a guild.',
    ),
    _WorkflowEventDefinition(
      category: 'members',
      event: 'guildMemberRemove',
      label: 'Guild Member Remove',
      description: 'User was removed from a guild.',
    ),
    _WorkflowEventDefinition(
      category: 'members',
      event: 'guildMemberUpdate',
      label: 'Guild Member Update',
      description: 'Guild member was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'roles',
      event: 'guildRoleCreate',
      label: 'Guild Role Create',
      description: 'Guild role was created.',
    ),
    _WorkflowEventDefinition(
      category: 'roles',
      event: 'guildRoleUpdate',
      label: 'Guild Role Update',
      description: 'Guild role was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'roles',
      event: 'guildRoleDelete',
      label: 'Guild Role Delete',
      description: 'Guild role was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'scheduled',
      event: 'guildScheduledEventCreate',
      label: 'Guild Scheduled Event Create',
      description: 'Guild scheduled event was created.',
    ),
    _WorkflowEventDefinition(
      category: 'scheduled',
      event: 'guildScheduledEventUpdate',
      label: 'Guild Scheduled Event Update',
      description: 'Guild scheduled event was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'scheduled',
      event: 'guildScheduledEventDelete',
      label: 'Guild Scheduled Event Delete',
      description: 'Guild scheduled event was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'scheduled',
      event: 'guildScheduledEventUserAdd',
      label: 'Guild Scheduled Event User Add',
      description: 'User subscribed to a guild scheduled event.',
    ),
    _WorkflowEventDefinition(
      category: 'scheduled',
      event: 'guildScheduledEventUserRemove',
      label: 'Guild Scheduled Event User Remove',
      description: 'User unsubscribed from a guild scheduled event.',
    ),
    _WorkflowEventDefinition(
      category: 'integrations',
      event: 'integrationCreate',
      label: 'Integration Create',
      description: 'Guild integration was created.',
    ),
    _WorkflowEventDefinition(
      category: 'integrations',
      event: 'integrationUpdate',
      label: 'Integration Update',
      description: 'Guild integration was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'integrations',
      event: 'integrationDelete',
      label: 'Integration Delete',
      description: 'Guild integration was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'invites',
      event: 'inviteCreate',
      label: 'Invite Create',
      description: 'Invite to a channel was created.',
    ),
    _WorkflowEventDefinition(
      category: 'invites',
      event: 'inviteDelete',
      label: 'Invite Delete',
      description: 'Invite to a channel was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'messages',
      event: 'messageCreate',
      label: 'Message Create',
      description: 'Message was created.',
    ),
    _WorkflowEventDefinition(
      category: 'messages',
      event: 'messageUpdate',
      label: 'Message Update',
      description: 'Message was edited.',
    ),
    _WorkflowEventDefinition(
      category: 'messages',
      event: 'messageDelete',
      label: 'Message Delete',
      description: 'Message was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'messages',
      event: 'messageBulkDelete',
      label: 'Message Delete Bulk',
      description: 'Multiple messages were deleted at once.',
    ),
    _WorkflowEventDefinition(
      category: 'reactions',
      event: 'messageReactionAdd',
      label: 'Message Reaction Add',
      description: 'User reacted to a message.',
    ),
    _WorkflowEventDefinition(
      category: 'reactions',
      event: 'messageReactionRemove',
      label: 'Message Reaction Remove',
      description: 'User removed a reaction from a message.',
    ),
    _WorkflowEventDefinition(
      category: 'reactions',
      event: 'messageReactionRemoveAll',
      label: 'Message Reaction Remove All',
      description: 'All reactions were explicitly removed from a message.',
    ),
    _WorkflowEventDefinition(
      category: 'reactions',
      event: 'messageReactionRemoveEmoji',
      label: 'Message Reaction Remove Emoji',
      description:
          'All reactions for a given emoji were explicitly removed from a message.',
    ),
    _WorkflowEventDefinition(
      category: 'reactions',
      event: 'messagePollVoteAdd',
      label: 'Message Poll Vote Add',
      description: 'User voted on a poll.',
    ),
    _WorkflowEventDefinition(
      category: 'reactions',
      event: 'messagePollVoteRemove',
      label: 'Message Poll Vote Remove',
      description: 'User removed a vote on a poll.',
    ),
    _WorkflowEventDefinition(
      category: 'presence',
      event: 'presenceUpdate',
      label: 'Presence Update',
      description: 'User presence was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'presence',
      event: 'typingStart',
      label: 'Typing Start',
      description: 'User started typing in a channel.',
    ),
    _WorkflowEventDefinition(
      category: 'presence',
      event: 'userUpdate',
      label: 'User Update',
      description: 'Properties about the user changed.',
    ),
    _WorkflowEventDefinition(
      category: 'stages',
      event: 'stageInstanceCreate',
      label: 'Stage Instance Create',
      description: 'Stage instance was created.',
    ),
    _WorkflowEventDefinition(
      category: 'stages',
      event: 'stageInstanceUpdate',
      label: 'Stage Instance Update',
      description: 'Stage instance was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'stages',
      event: 'stageInstanceDelete',
      label: 'Stage Instance Delete',
      description: 'Stage instance was deleted or closed.',
    ),
    _WorkflowEventDefinition(
      category: 'voice',
      event: 'voiceStateUpdate',
      label: 'Voice State Update',
      description: 'Someone joined, left, or moved a voice channel.',
    ),
    _WorkflowEventDefinition(
      category: 'voice',
      event: 'voiceServerUpdate',
      label: 'Voice Server Update',
      description: 'Guild voice server was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'voice',
      event: 'voiceChannelEffectSend',
      label: 'Voice Channel Effect Send',
      description: 'Someone sent an effect in a connected voice channel.',
    ),
    _WorkflowEventDefinition(
      category: 'webhooks',
      event: 'webhooksUpdate',
      label: 'Webhooks Update',
      description: 'Guild channel webhook was created, updated, or deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'soundboard',
      event: 'soundboardSoundCreate',
      label: 'Guild Soundboard Sound Create',
      description: 'Guild soundboard sound was created.',
    ),
    _WorkflowEventDefinition(
      category: 'soundboard',
      event: 'soundboardSoundUpdate',
      label: 'Guild Soundboard Sound Update',
      description: 'Guild soundboard sound was updated.',
    ),
    _WorkflowEventDefinition(
      category: 'soundboard',
      event: 'soundboardSoundDelete',
      label: 'Guild Soundboard Sound Delete',
      description: 'Guild soundboard sound was deleted.',
    ),
    _WorkflowEventDefinition(
      category: 'soundboard',
      event: 'soundboardSoundsUpdate',
      label: 'Guild Soundboard Sounds Update',
      description: 'Guild soundboard sounds were updated.',
    ),
  ];

  List<String> get _workflowEventCategories {
    final categories = <String>[];
    for (final event in _workflowEventCatalog) {
      if (!categories.contains(event.category)) {
        categories.add(event.category);
      }
    }
    return categories;
  }

  List<_WorkflowEventDefinition> _eventsForCategory(String category) {
    return _workflowEventCatalog
        .where((event) => event.category == category)
        .toList(growable: false);
  }

  _WorkflowEventDefinition? _findEventDefinition(String eventName) {
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
        suggestions.add(
          VariableSuggestion(
            name: '$scope.${_toScopedReferenceName(storageKey)}',
            kind: (definition['valueType']?.toString() == 'number' ||
                    definition['defaultValue'] is num)
                ? VariableSuggestionKind.numeric
                : VariableSuggestionKind.unknown,
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

    final usedNames =
        _workflows
            .map((workflow) => (workflow['name'] ?? '').toString().trim())
            .where((name) => name.isNotEmpty)
            .toSet();

    var importedCount = 0;
    for (final raw in imported) {
      final workflow = normalizeStoredWorkflowDefinition(raw);
      final rawName = (workflow['name'] ?? '').toString().trim();
      if (rawName.isEmpty) {
        continue;
      }

      final workflowType = normalizeWorkflowType(workflow['workflowType']);
      final targetName =
          overwrite
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
        folder: (workflow['folder'] ?? '').toString().trim(),
      );
      importedCount++;
    }

    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.workflows_import_done(importedCount))),
    );
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
                initialWorkflowType: workflowTypeGeneral,
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

    appendSection(context.tr.workflows_general_section, generalWorkflows);
    appendSection(context.tr.workflows_event_section, eventWorkflows);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.workflows_title),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WorkflowDocumentationPage(),
                ),
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
    final subtitle =
        workflowType == workflowTypeEvent
            ? context.tr.workflows_event_subtitle(
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

class _WorkflowEventDefinition {
  const _WorkflowEventDefinition({
    required this.category,
    required this.event,
    required this.label,
    required this.description,
  });

  final String category;
  final String event;
  final String label;
  final String description;
}

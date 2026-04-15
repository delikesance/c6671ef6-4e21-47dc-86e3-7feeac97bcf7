import 'package:bot_creator/routes/app/doc_kind.dart';
import 'package:bot_creator/utils/command_variable_catalog.dart';
import 'package:bot_creator/utils/i18n.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/utils/app_theme.dart';

class _DocSection {
  const _DocSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

class _DocEntry {
  const _DocEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.sections,
    this.variables = const <String>[],
    this.example,
    this.requiresIntent = const <String>[],
  });

  final String id;
  final DocKind kind;
  final String title;
  final String subtitle;
  final String summary;
  final List<_DocSection> sections;
  final List<String> variables;
  final String? example;
  final List<String> requiresIntent;
}

class WorkflowDocumentationPage extends StatefulWidget {
  const WorkflowDocumentationPage({
    super.key,
    this.initialSearch = '',
    this.initialKind,
  });

  final String initialSearch;
  final DocKind? initialKind;

  @override
  State<WorkflowDocumentationPage> createState() =>
      _WorkflowDocumentationPageState();
}

class _WorkflowDocumentationPageState extends State<WorkflowDocumentationPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  DocKind? _kindFilter;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialSearch;
    _kindFilter = widget.initialKind;
  }

  _DocEntry _buildTemplateVariablesDoc() {
    return _DocEntry(
      id: 'template.variables',
      kind: DocKind.template,
      title: context.tr.doc_template_variables_title,
      subtitle: context.tr.doc_template_variables_subtitle,
      summary: context.tr.doc_template_variables_summary,
      variables: commandTemplateReferenceVariables,
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_template_variables_section_sources_title,
          lines: <String>[
            context.tr.doc_template_variables_section_sources_l1,
            context.tr.doc_template_variables_section_sources_l2,
            context.tr.doc_template_variables_section_sources_l3,
            context.tr.doc_template_variables_section_sources_l4,
            context.tr.doc_template_variables_section_sources_l5,
          ],
        ),
        _DocSection(
          title: context.tr.doc_template_variables_section_builtin_title,
          lines: commandBuiltinVariableDocumentationLines,
        ),
        _DocSection(
          title: context.tr.doc_template_variables_section_types_title,
          lines: <String>[
            context.tr.doc_template_variables_section_types_l1,
            context.tr.doc_template_variables_section_types_l2,
            context.tr.doc_template_variables_section_types_l3,
            context.tr.doc_template_variables_section_types_l4,
          ],
        ),
        _DocSection(
          title: context.tr.doc_template_variables_section_fallbacks_title,
          lines: <String>[
            context.tr.doc_template_variables_section_fallbacks_l1,
            context.tr.doc_template_variables_section_fallbacks_l2,
            context.tr.doc_template_variables_section_fallbacks_l3,
          ],
        ),
      ],
      example: context.tr.doc_template_variables_example('{name}', '{score}'),
    );
  }

  _DocEntry _buildTemplateFunctionsDoc() {
    return _DocEntry(
      id: 'template.functions',
      kind: DocKind.template,
      title: context.tr.doc_template_functions_title,
      subtitle: context.tr.doc_template_functions_subtitle,
      summary: context.tr.doc_template_functions_summary,
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_template_functions_section_string_title,
          lines: <String>[
            context.tr.doc_template_functions_section_string_l1,
            context.tr.doc_template_functions_section_string_l2,
            context.tr.doc_template_functions_section_string_l3,
            context.tr.doc_template_functions_section_string_l4,
          ],
        ),
        _DocSection(
          title: context.tr.doc_template_functions_section_array_title,
          lines: <String>[
            context.tr.doc_template_functions_section_array_l1,
            context.tr.doc_template_functions_section_array_l2,
            context.tr.doc_template_functions_section_array_l3,
            context.tr.doc_template_functions_section_array_l4,
          ],
        ),
        _DocSection(
          title: context.tr.doc_template_functions_section_random_title,
          lines: <String>[
            context.tr.doc_template_functions_section_random_l1,
            context.tr.doc_template_functions_section_random_l2,
          ],
        ),
        _DocSection(
          title: context.tr.doc_template_functions_section_notes_title,
          lines: <String>[
            context.tr.doc_template_functions_section_notes_l1,
            context.tr.doc_template_functions_section_notes_l2,
            context.tr.doc_template_functions_section_notes_l3,
            context.tr.doc_template_functions_section_notes_l4,
          ],
        ),
      ],
      example: context.tr.doc_template_functions_example,
    );
  }

  _DocEntry _buildTemplateAdvancedVariablesDoc() {
    return _DocEntry(
      id: 'template.advancedVariables',
      kind: DocKind.template,
      title: context.tr.doc_template_advanced_variables_title,
      subtitle: context.tr.doc_template_advanced_variables_subtitle,
      summary: context.tr.doc_template_advanced_variables_summary,
      variables: const <String>[
        'interaction.kind',
        'interaction.values',
        'interaction.values.count',
        'interaction.command.name',
        'interaction.command.id',
        'interaction.guildId',
        'interaction.channelId',
        'interaction.userId',
        'interaction.messageId',
        'channel.kind',
        'channel.position',
        'channel.bitrate',
        'channel.userLimit',
        'channel.categoryId',
        'channel.thread.archived',
        'channel.thread.locked',
        'channel.thread.ownerId',
        'channel.thread.autoArchiveDuration',
        'guild.kind',
        'user.id',
        'user.username',
        'user.tag',
        'user.avatar',
        'user.banner',
        'member.id',
      ],
      sections: <_DocSection>[
        _DocSection(
          title:
              context
                  .tr
                  .doc_template_advanced_variables_section_interaction_title,
          lines: <String>[
            context.tr.doc_template_advanced_variables_section_interaction_l1,
            context.tr.doc_template_advanced_variables_section_interaction_l2,
            context.tr.doc_template_advanced_variables_section_interaction_l3,
          ],
        ),
        _DocSection(
          title:
              context
                  .tr
                  .doc_template_advanced_variables_section_channel_guild_title,
          lines: <String>[
            context.tr.doc_template_advanced_variables_section_channel_guild_l1,
            context.tr.doc_template_advanced_variables_section_channel_guild_l2,
            context.tr.doc_template_advanced_variables_section_channel_guild_l3,
          ],
        ),
        _DocSection(
          title:
              context.tr.doc_template_advanced_variables_section_aliases_title,
          lines: <String>[
            context.tr.doc_template_advanced_variables_section_aliases_l1,
            context.tr.doc_template_advanced_variables_section_aliases_l2,
          ],
        ),
      ],
      example: context.tr.doc_template_advanced_variables_example,
    );
  }

  _DocEntry _buildRuntimeActionOutputsDoc() {
    return _DocEntry(
      id: 'runtime.actionOutputs',
      kind: DocKind.runtime,
      title: context.tr.doc_runtime_action_outputs_title,
      subtitle: context.tr.doc_runtime_action_outputs_subtitle,
      summary: context.tr.doc_runtime_action_outputs_summary,
      variables: const <String>[
        'action.<resultKey>',
        'action.<resultKey>.status',
        'action.<resultKey>.body',
        'action.<resultKey>.jsonPath',
        'action.<resultKey>.count',
        'action.<resultKey>.mode',
        'action.<resultKey>.deleteItself',
        'action.<resultKey>.deleteResponse',
        'action.<resultKey>.items',
        'action.<resultKey>.length',
        'action.<resultKey>.removed',
        'action.<resultKey>.total',
        '<resultKey>',
        '<resultKey>.status',
        '<resultKey>.body',
        '<resultKey>.jsonPath',
        '<resultKey>.count',
        '<resultKey>.items',
        '<resultKey>.length',
        '<resultKey>.removed',
        '<resultKey>.total',
        '<resultKey>.result',
        '<resultKey>.messageId',
      ],
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_runtime_action_outputs_section_patterns_title,
          lines: <String>[
            context.tr.doc_runtime_action_outputs_section_patterns_l1,
            context.tr.doc_runtime_action_outputs_section_patterns_l2,
            context.tr.doc_runtime_action_outputs_section_patterns_l3,
          ],
        ),
        _DocSection(
          title:
              context.tr.doc_runtime_action_outputs_section_common_fields_title,
          lines: <String>[
            context.tr.doc_runtime_action_outputs_section_common_fields_l1,
            context.tr.doc_runtime_action_outputs_section_common_fields_l2,
            context.tr.doc_runtime_action_outputs_section_common_fields_l3,
            context.tr.doc_runtime_action_outputs_section_common_fields_l4,
          ],
        ),
        _DocSection(
          title: context.tr.doc_runtime_action_outputs_section_caveats_title,
          lines: <String>[
            context.tr.doc_runtime_action_outputs_section_caveats_l1,
            context.tr.doc_runtime_action_outputs_section_caveats_l2,
            context.tr.doc_runtime_action_outputs_section_caveats_l3,
          ],
        ),
      ],
      example: context.tr.doc_runtime_action_outputs_example,
    );
  }

  _DocEntry _buildInteractionCommandsDoc() {
    return _DocEntry(
      id: 'runtime.interactionCommands',
      kind: DocKind.runtime,
      title: context.tr.doc_interaction_commands_title,
      subtitle: context.tr.doc_interaction_commands_subtitle,
      summary: context.tr.doc_interaction_commands_summary,
      variables: interactionCommandReferenceVariables,
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_interaction_commands_section_execution_title,
          lines: <String>[
            context.tr.doc_interaction_commands_section_execution_l1,
            context.tr.doc_interaction_commands_section_execution_l2,
            context.tr.doc_interaction_commands_section_execution_l3,
          ],
        ),
        _DocSection(
          title: context.tr.doc_interaction_commands_section_per_type_title,
          lines: <String>[
            context.tr.doc_interaction_commands_section_per_type_l1,
            context.tr.doc_interaction_commands_section_per_type_l2,
            context.tr.doc_interaction_commands_section_per_type_l3,
          ],
        ),
        _DocSection(
          title: context.tr.doc_interaction_commands_section_builtin_title,
          lines: commandBuiltinVariableDocumentationLines,
        ),
        _DocSection(
          title: context.tr.doc_interaction_commands_section_guidance_title,
          lines: <String>[
            context.tr.doc_interaction_commands_section_guidance_l1,
            context.tr.doc_interaction_commands_section_guidance_l2,
            context.tr.doc_interaction_commands_section_guidance_l3,
          ],
        ),
      ],
      example: context.tr.doc_interaction_commands_example('{id}', '{name}'),
    );
  }

  _DocEntry _buildMessageCreateDoc() {
    return _DocEntry(
      id: 'event.messageCreate',
      kind: DocKind.event,
      title: context.tr.doc_event_message_create_title,
      subtitle: context.tr.doc_event_message_create_subtitle,
      summary: context.tr.doc_event_message_create_summary,
      requiresIntent: <String>[
        context.tr.doc_event_message_create_intent_1,
        context.tr.doc_event_message_create_intent_2,
      ],
      variables: <String>[
        'event.name',
        'timestamp',
        'actualTime',
        'guildId',
        'channelId',
        'userId',
        'message.id',
        'message.content',
        'message.content[0]',
        'message.word.count',
        'message.isBot',
        'message.type',
        'message.mentions',
        'author.id',
        'author.name',
        'author.username',
        'author.tag',
        'author.avatar',
      ],
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_common_section_best_use_cases,
          lines: <String>[
            context.tr.doc_event_message_create_best_use_l1,
            context.tr.doc_event_message_create_best_use_l2,
            context.tr.doc_event_message_create_best_use_l3,
          ],
        ),
        _DocSection(
          title: context.tr.doc_common_section_important_notes,
          lines: <String>[
            context.tr.doc_event_message_create_notes_l1,
            context.tr.doc_event_message_create_notes_l2,
            context.tr.doc_event_message_create_notes_l3,
          ],
        ),
      ],
      example: context.tr.doc_event_message_create_example,
    );
  }

  _DocEntry _buildRuntimeExecutionFlowDoc() {
    return _DocEntry(
      id: 'runtime.executionFlow',
      kind: DocKind.runtime,
      title: context.tr.doc_runtime_execution_flow_title,
      subtitle: context.tr.doc_runtime_execution_flow_subtitle,
      summary: context.tr.doc_runtime_execution_flow_summary,
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_runtime_execution_flow_section_pipeline_title,
          lines: <String>[
            context.tr.doc_runtime_execution_flow_section_pipeline_l1,
            context.tr.doc_runtime_execution_flow_section_pipeline_l2,
            context.tr.doc_runtime_execution_flow_section_pipeline_l3,
            context.tr.doc_runtime_execution_flow_section_pipeline_l4,
            context.tr.doc_runtime_execution_flow_section_pipeline_l5,
          ],
        ),
        _DocSection(
          title: context.tr.doc_runtime_execution_flow_section_parity_title,
          lines: <String>[
            context.tr.doc_runtime_execution_flow_section_parity_l1,
            context.tr.doc_runtime_execution_flow_section_parity_l2,
          ],
        ),
      ],
    );
  }

  List<_DocEntry> get _docs => <_DocEntry>[
    _buildMessageCreateDoc(),
    _DocEntry(
      id: 'event.messageReactionAdd',
      kind: DocKind.event,
      title: context.tr.doc_event_reaction_add_title,
      subtitle: context.tr.doc_event_reaction_add_subtitle,
      summary: context.tr.doc_event_reaction_add_summary,
      requiresIntent: <String>[context.tr.doc_event_reaction_add_intent],
      variables: <String>[
        'event.name',
        'guildId',
        'channelId',
        'userId',
        'message.id',
        'reaction.emoji.name',
        'reaction.emoji.id',
        'reaction.emoji.animated',
      ],
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_common_section_best_use_cases,
          lines: <String>[
            context.tr.doc_event_reaction_add_best_use_l1,
            context.tr.doc_event_reaction_add_best_use_l2,
            context.tr.doc_event_reaction_add_best_use_l3,
          ],
        ),
        _DocSection(
          title: context.tr.doc_common_section_important_notes,
          lines: <String>[
            context.tr.doc_event_reaction_add_notes_l1,
            context.tr.doc_event_reaction_add_notes_l2,
            context.tr.doc_event_reaction_add_notes_l3,
          ],
        ),
      ],
      example: context.tr.doc_event_reaction_add_example,
    ),
    _DocEntry(
      id: 'event.messagePollVoteAdd',
      kind: DocKind.event,
      title: context.tr.doc_event_poll_vote_add_title,
      subtitle: context.tr.doc_event_poll_vote_add_subtitle,
      summary: context.tr.doc_event_poll_vote_add_summary,
      requiresIntent: <String>[context.tr.doc_event_poll_vote_add_intent],
      variables: <String>[
        'event.name',
        'guildId',
        'channelId',
        'userId',
        'message.id',
        'poll.answer.id',
        'poll.question',
      ],
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_common_section_best_use_cases,
          lines: <String>[
            context.tr.doc_event_poll_vote_add_best_use_l1,
            context.tr.doc_event_poll_vote_add_best_use_l2,
          ],
        ),
        _DocSection(
          title: context.tr.doc_common_section_important_notes,
          lines: <String>[
            context.tr.doc_event_poll_vote_add_notes_l1,
            context.tr.doc_event_poll_vote_add_notes_l2,
          ],
        ),
      ],
    ),
    _DocEntry(
      id: 'event.voiceStateUpdate',
      kind: DocKind.event,
      title: context.tr.doc_event_voice_state_update_title,
      subtitle: context.tr.doc_event_voice_state_update_subtitle,
      summary: context.tr.doc_event_voice_state_update_summary,
      requiresIntent: <String>[context.tr.doc_event_voice_state_update_intent],
      variables: <String>[
        'event.name',
        'guildId',
        'channelId',
        'userId',
        'voice.channel.id',
        'voice.user.id',
        'voice.state.sessionId',
        'voice.selfMute',
        'voice.selfDeafen',
        'voice.mute',
        'voice.deafen',
      ],
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_event_voice_state_update_section_title,
          lines: <String>[
            context.tr.doc_event_voice_state_update_automations_l1,
            context.tr.doc_event_voice_state_update_automations_l2,
            context.tr.doc_event_voice_state_update_automations_l3,
          ],
        ),
      ],
    ),
    _DocEntry(
      id: 'event.userUpdate',
      kind: DocKind.event,
      title: context.tr.doc_event_user_update_title,
      subtitle: context.tr.doc_event_user_update_subtitle,
      summary: context.tr.doc_event_user_update_summary,
      variables: <String>[
        'event.name',
        'user.id',
        'user.username',
        'user.avatar',
        'user.banner',
        'user.accentColor',
      ],
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_common_section_important_notes,
          lines: <String>[
            context.tr.doc_event_user_update_notes_l1,
            context.tr.doc_event_user_update_notes_l2,
          ],
        ),
      ],
    ),
    _DocEntry(
      id: 'event.guildAuditLogCreate',
      kind: DocKind.event,
      title: context.tr.doc_event_audit_log_create_title,
      subtitle: context.tr.doc_event_audit_log_create_subtitle,
      summary: context.tr.doc_event_audit_log_create_summary,
      variables: <String>[
        'event.name',
        'guildId',
        'auditLog.action',
        'auditLog.executorId',
        'auditLog.targetId',
      ],
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_common_section_best_use_cases,
          lines: <String>[
            context.tr.doc_event_audit_log_create_best_use_l1,
            context.tr.doc_event_audit_log_create_best_use_l2,
          ],
        ),
      ],
    ),
    _DocEntry(
      id: 'action.stopUnless',
      kind: DocKind.action,
      title: context.tr.doc_action_stop_unless_title,
      subtitle: context.tr.doc_action_stop_unless_subtitle,
      summary: context.tr.doc_action_stop_unless_summary,
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_action_stop_unless_section_operators,
          lines: <String>[
            context.tr.doc_action_stop_unless_operators_l1,
            context.tr.doc_action_stop_unless_operators_l2,
            context.tr.doc_action_stop_unless_operators_l3,
          ],
        ),
        _DocSection(
          title: context.tr.doc_action_stop_unless_section_format,
          lines: <String>[
            context.tr.doc_action_stop_unless_format_l1,
            context.tr.doc_action_stop_unless_format_l2,
            context.tr.doc_action_stop_unless_format_l3,
          ],
        ),
      ],
      example: context.tr.doc_action_stop_unless_example,
    ),
    _DocEntry(
      id: 'action.ifBlock',
      kind: DocKind.action,
      title: context.tr.doc_action_if_block_title,
      subtitle: context.tr.doc_action_if_block_subtitle,
      summary: context.tr.doc_action_if_block_summary,
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_action_if_block_section_execution,
          lines: <String>[
            context.tr.doc_action_if_block_execution_l1,
            context.tr.doc_action_if_block_execution_l2,
            context.tr.doc_action_if_block_execution_l3,
          ],
        ),
      ],
    ),
    _DocEntry(
      id: 'action.runWorkflow',
      kind: DocKind.action,
      title: context.tr.doc_action_run_workflow_title,
      subtitle: context.tr.doc_action_run_workflow_subtitle,
      summary: context.tr.doc_action_run_workflow_summary,
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_action_run_workflow_section_practices,
          lines: <String>[
            context.tr.doc_action_run_workflow_practices_l1,
            context.tr.doc_action_run_workflow_practices_l2,
            context.tr.doc_action_run_workflow_practices_l3,
          ],
        ),
      ],
    ),
    _DocEntry(
      id: 'action.httpRequest',
      kind: DocKind.action,
      title: context.tr.doc_action_http_request_title,
      subtitle: context.tr.doc_action_http_request_subtitle,
      summary: context.tr.doc_action_http_request_summary,
      sections: <_DocSection>[
        _DocSection(
          title: context.tr.doc_action_http_request_section_checklist,
          lines: <String>[
            context.tr.doc_action_http_request_checklist_l1,
            context.tr.doc_action_http_request_checklist_l2,
            context.tr.doc_action_http_request_checklist_l3,
          ],
        ),
      ],
    ),
    _buildTemplateVariablesDoc(),
    _buildTemplateFunctionsDoc(),
    _buildTemplateAdvancedVariablesDoc(),
    _buildInteractionCommandsDoc(),
    _buildRuntimeActionOutputsDoc(),
    _buildRuntimeExecutionFlowDoc(),
  ];

  List<_DocEntry> get _filtered {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _docs
        .where((doc) {
          if (_kindFilter != null && doc.kind != _kindFilter) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          final haystack =
              <String>[
                doc.title,
                doc.subtitle,
                doc.summary,
                ...doc.variables,
                ...doc.requiresIntent,
                ...doc.sections.expand(
                  (section) => <String>[section.title, ...section.lines],
                ),
              ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  String _kindLabel(DocKind kind) {
    switch (kind) {
      case DocKind.event:
        return context.tr.doc_kind_event;
      case DocKind.action:
        return context.tr.doc_kind_action;
      case DocKind.template:
        return context.tr.doc_kind_template;
      case DocKind.runtime:
        return context.tr.doc_kind_runtime;
    }
  }

  IconData _kindIcon(DocKind kind) {
    switch (kind) {
      case DocKind.event:
        return Icons.notifications_active_outlined;
      case DocKind.action:
        return Icons.build_circle_outlined;
      case DocKind.template:
        return Icons.data_object_outlined;
      case DocKind.runtime:
        return Icons.hub_outlined;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.doc_center_title)),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                            tooltip: context.tr.doc_center_clear_search,
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  hintText: context.tr.doc_center_search_hint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(context.tr.doc_kind_all),
                      selected: _kindFilter == null,
                      onSelected: (_) => setState(() => _kindFilter = null),
                    ),
                  ),
                  for (final kind in DocKind.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(_kindLabel(kind)),
                        selected: _kindFilter == kind,
                        onSelected: (_) => setState(() => _kindFilter = kind),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  docs.isEmpty
                      ? Center(
                        child: Text(
                          context.tr.doc_center_empty,
                          textAlign: TextAlign.center,
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          return Card(
                            child: ListTile(
                              leading: Icon(_kindIcon(doc.kind)),
                              title: Text(doc.title),
                              subtitle: Text(doc.subtitle),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => _WorkflowDocDetailPage(doc: doc),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowDocDetailPage extends StatelessWidget {
  const _WorkflowDocDetailPage({required this.doc});

  final _DocEntry doc;

  Widget _mono(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.grey),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(doc.subtitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(doc.summary),
            if (doc.requiresIntent.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                context.tr.doc_required_intents,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: doc.requiresIntent
                    .map((intent) => Chip(label: Text(intent)))
                    .toList(growable: false),
              ),
            ],
            if (doc.variables.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                context.tr.doc_available_variables,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _mono(doc.variables.join('\n')),
            ],
            for (final section in doc.sections) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                section.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              for (final line in section.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $line'),
                ),
            ],
            if (doc.example != null &&
                doc.example!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                context.tr.doc_example,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              _mono(doc.example!),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

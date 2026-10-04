import 'package:bot_creator/main.dart';

import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_feature_gate.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:bot_creator/features/subscriptions/presentation/widgets/premium_locked_hint.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/core/theme/block_category.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/module_list_widgets.dart';

class SchedulerPage extends StatefulWidget {
  const SchedulerPage({super.key, required this.botId});

  final String botId;

  @override
  State<SchedulerPage> createState() => _SchedulerPageState();
}

class _SchedulerPageState extends State<SchedulerPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _triggers = const <Map<String, dynamic>>[];
  List<String> _workflowNames = const <String>[];

  /// La capacité du planificateur dépend de l'ENDROIT où le bot tourne, pas de
  /// l'OS : sur un poste de travail avec un bot local, les déclencheurs
  /// s'exécutent chez l'utilisateur, donc ils sont ouverts sans abonnement
  /// (`premium_feature_gate.dart`).
  bool get _hasSchedulerCapability => premiumCapabilityAvailableForBot(
    PremiumCapability.schedulerTriggers,
    botId: widget.botId,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final workflows = await appManager.getWorkflows(widget.botId);
    final workflowNames =
        workflows
            .where(
              (entry) =>
                  normalizeWorkflowType(entry['workflowType']) ==
                  workflowTypeGeneral,
            )
            .map((entry) => (entry['name'] ?? '').toString().trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();

    final triggers = await appManager.getScheduledTriggers(widget.botId);

    if (!mounted) {
      return;
    }

    setState(() {
      _workflowNames = workflowNames;
      _triggers = triggers;
      _loading = false;
    });
  }

  Future<void> _showEditor({Map<String, dynamic>? initial}) async {
    if (_workflowNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.scheduler_no_workflows)),
      );
      return;
    }

    final labelCtrl = TextEditingController(
      text: (initial?['label'] ?? '').toString(),
    );
    final minutesCtrl = TextEditingController(
      text: ((initial?['everyMinutes'] ?? 60) as int).toString(),
    );
    var selectedWorkflow =
        ((initial?['workflowName'] ?? '').toString().trim().isNotEmpty)
        ? (initial!['workflowName'] as String)
        : _workflowNames.first;
    var enabled = initial == null ? true : initial['enabled'] != false;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setInnerState) {
            return AlertDialog.adaptive(
              title: Text(
                initial == null
                    ? context.tr.scheduler_add_title
                    : context.tr.scheduler_edit_title,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedWorkflow,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.tr.common_workflow,
                      border: OutlineInputBorder(),
                    ),
                    items: _workflowNames
                        .map(
                          (name) => DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setInnerState(() {
                        selectedWorkflow = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr.scheduler_label_field,
                      hintText: context.tr.scheduler_label_hint,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: minutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr.scheduler_every_minutes,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: enabled,
                    title: Text(context.tr.common_enabled),
                    onChanged: (value) {
                      setInnerState(() {
                        enabled = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.tr.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(context.tr.app_save),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true) {
      return;
    }

    final everyMinutes = int.tryParse(minutesCtrl.text.trim()) ?? 0;
    if (everyMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.scheduler_invalid_minutes)),
      );
      return;
    }

    try {
      await appManager.saveScheduledTrigger(
        widget.botId,
        workflowName: selectedWorkflow,
        everyMinutes: everyMinutes,
        enabled: enabled,
        triggerId: (initial?['id'] ?? '').toString().trim().isEmpty
            ? null
            : (initial?['id'] ?? '').toString(),
        label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
      );
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final text = error.toString();
      if (text.contains('scheduler_trigger_limit_reached')) {
        final limit = PremiumCapabilities.limitFor(
          PremiumCapability.schedulerTriggers,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.scheduler_limit_reached(limit))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.scheduler_save_failed('$error'))),
        );
      }
    }
  }

  Future<void> _deleteTrigger(Map<String, dynamic> trigger) async {
    final label = (trigger['label'] ?? trigger['workflowName'] ?? '')
        .toString()
        .trim();

    final confirm = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.scheduler_delete_title,
      content: context.tr.scheduler_delete_confirm(label),
      confirmLabel: context.tr.delete,
      isDestructive: true,
    );

    if (!confirm) {
      return;
    }

    await appManager.deleteScheduledTrigger(
      widget.botId,
      (trigger['id'] ?? '').toString(),
    );
    if (!mounted) return;
    setState(() {
      _triggers = _triggers
          .where((entry) => entry['id'] != trigger['id'])
          .toList();
    });
  }

  Future<void> _toggleTrigger(Map<String, dynamic> trigger, bool value) async {
    await appManager.saveScheduledTrigger(
      widget.botId,
      workflowName: (trigger['workflowName'] ?? '').toString(),
      everyMinutes:
          int.tryParse((trigger['everyMinutes'] ?? '').toString()) ?? 60,
      enabled: value,
      triggerId: (trigger['id'] ?? '').toString(),
      label: (trigger['label'] ?? '').toString(),
    );
    await _load();
  }

  Widget _buildUpsellCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ModuleUpsellCard(
        title: context.tr.subscription_feature_scheduler_title,
        description: context.tr.subscription_feature_scheduler_desc,
        action: PremiumCapabilities.canShowPurchaseUI
            ? FilledButton.icon(
                onPressed: () async {
                  await SubscriptionPage.show(context);
                  if (!mounted) {
                    return;
                  }
                  await _load();
                },
                icon: const AppIcon.fromMaterial(
                  Icons.workspace_premium_rounded,
                ),
                label: Text(context.tr.premium_card_button),
              )
            // Verrou de FORMULE, pas de plateforme (voir PremiumLockedHint).
            : const PremiumLockedHint(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final limit = PremiumCapabilities.limitFor(
      PremiumCapability.schedulerTriggers,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: editorSubPageLeading(context),
        title: Text(context.tr.scheduler_page_title),
        actions: [
          IconButton(
            tooltip: context.tr.common_refresh,
            onPressed: _load,
            icon: const AppIcon.fromMaterial(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _hasSchedulerCapability
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _showEditor(),
              icon: const AppIcon.fromMaterial(Icons.add),
              label: Text(context.tr.scheduler_add_trigger),
            )
          : null,
      body: SafeArea(
        top: false,
        child: PageContent(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (!_hasSchedulerCapability) _buildUpsellCard(),
                    Padding(
                      // Marges horizontales portées par PageContent.
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingMd,
                        bottom: AppTheme.spacingSm,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ModuleOverline(
                          context.tr.scheduler_triggers_count(
                            _triggers.length,
                            limit > 0 ? ' / $limit' : '',
                          ),
                          family: BlockFamily.logic,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _triggers.isEmpty
                          ? EditorEmptyState(
                              icon: Icons.schedule_rounded,
                              title: context.tr.scheduler_empty,
                              description: _workflowNames.isEmpty
                                  ? context.tr.scheduler_no_workflows
                                  : null,
                              actionLabel: _hasSchedulerCapability
                                  ? context.tr.scheduler_add_trigger
                                  : null,
                              onAction: _hasSchedulerCapability
                                  ? _showEditor
                                  : null,
                            )
                          : ListView.separated(
                              padding: EdgeInsets.only(
                                bottom:
                                    FloatingGlassNavBar.contentClearanceOf(
                                      context,
                                    ) +
                                    24,
                              ),
                              itemCount: _triggers.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final trigger = _triggers[index];
                                final label =
                                    (trigger['label'] ??
                                            trigger['workflowName'] ??
                                            '')
                                        .toString();
                                final workflowName =
                                    (trigger['workflowName'] ?? '').toString();
                                final everyMinutes =
                                    int.tryParse(
                                      (trigger['everyMinutes'] ?? '')
                                          .toString(),
                                    ) ??
                                    60;
                                final enabled = trigger['enabled'] != false;
                                return ModuleRowCard(
                                  key: ValueKey(
                                    'scheduler_trigger_${trigger['id']}',
                                  ),
                                  family: BlockFamily.logic,
                                  icon: Icons.schedule_rounded,
                                  title: label,
                                  summary: context.tr.scheduler_subtitle(
                                    workflowName,
                                    everyMinutes,
                                  ),
                                  dimmed: !enabled,
                                  onTap: _hasSchedulerCapability
                                      ? () => _showEditor(initial: trigger)
                                      : null,
                                  trailing: [
                                    Switch.adaptive(
                                      value: enabled,
                                      onChanged: _hasSchedulerCapability
                                          ? (value) =>
                                                _toggleTrigger(trigger, value)
                                          : null,
                                    ),
                                    if (_hasSchedulerCapability)
                                      moduleMoreButton<String>(
                                        context: context,
                                        tooltip: context.tr.more_options_title,
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showEditor(initial: trigger);
                                          } else if (value == 'delete') {
                                            _deleteTrigger(trigger);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          moduleMenuItem<String>(
                                            context,
                                            value: 'edit',
                                            icon: Icons.edit_outlined,
                                            label: context.tr.common_edit,
                                          ),
                                          const PopupMenuDivider(),
                                          moduleMenuItem<String>(
                                            context,
                                            value: 'delete',
                                            icon: Icons.delete_outline,
                                            label: context.tr.delete,
                                            danger: true,
                                          ),
                                        ],
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

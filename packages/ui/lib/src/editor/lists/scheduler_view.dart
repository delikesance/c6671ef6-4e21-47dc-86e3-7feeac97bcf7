import 'package:flutter/material.dart';

import '../../l10n/tr_extension.dart';
import '../../theme/app_theme.dart';
import '../../theme/block_family.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/floating_glass_nav_bar.dart';
import '../../widgets/page_layout.dart';
import '../logic/workflow_call.dart';
import 'editor_sub_page_ui.dart';
import 'module_list_widgets.dart';

/// Ce que l'écran du planificateur demande à son hôte : les déclencheurs du
/// bot, ses workflows généraux, l'écriture, et ce que le forfait autorise.
abstract class SchedulerController {
  const SchedulerController();

  Future<List<Map<String, dynamic>>> triggers();
  Future<List<Map<String, dynamic>>> workflows();

  Future<void> save({
    required String workflowName,
    required int everyMinutes,
    required bool enabled,
    String? triggerId,
    String? label,
  });

  Future<void> delete(String triggerId);

  /// Le forfait (ou le lieu d'exécution) autorise les déclencheurs planifiés.
  bool get hasCapability => true;

  /// Nombre maximal de déclencheurs (0 : pas de limite connue).
  int get limit => 0;

  /// Carte proposant de passer à une formule supérieure (`null` : rien).
  Widget? upsell(BuildContext context, Future<void> Function() reload) => null;

  /// L'erreur d'enregistrement vient de la limite du forfait.
  bool isLimitError(Object error) =>
      error.toString().contains('scheduler_trigger_limit_reached');
}

class SchedulerView extends StatefulWidget {
  const SchedulerView({super.key, required this.controller});

  final SchedulerController controller;

  @override
  State<SchedulerView> createState() => _SchedulerViewState();
}

class _SchedulerViewState extends State<SchedulerView> {
  bool _loading = true;
  List<Map<String, dynamic>> _triggers = const <Map<String, dynamic>>[];
  List<String> _workflowNames = const <String>[];

  bool get _hasSchedulerCapability => widget.controller.hasCapability;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final workflows = await widget.controller.workflows();
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

    final triggers = await widget.controller.triggers();

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

    if (save != true || !mounted) {
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
      await widget.controller.save(
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
      if (widget.controller.isLimitError(error)) {
        final limit = widget.controller.limit;
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

    await widget.controller.delete((trigger['id'] ?? '').toString());
    if (!mounted) return;
    setState(() {
      _triggers = _triggers
          .where((entry) => entry['id'] != trigger['id'])
          .toList();
    });
  }

  Future<void> _toggleTrigger(Map<String, dynamic> trigger, bool value) async {
    await widget.controller.save(
      workflowName: (trigger['workflowName'] ?? '').toString(),
      everyMinutes:
          int.tryParse((trigger['everyMinutes'] ?? '').toString()) ?? 60,
      enabled: value,
      triggerId: (trigger['id'] ?? '').toString(),
      label: (trigger['label'] ?? '').toString(),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final limit = widget.controller.limit;

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
                    if (!_hasSchedulerCapability)
                      ?widget.controller.upsell(context, _load),
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

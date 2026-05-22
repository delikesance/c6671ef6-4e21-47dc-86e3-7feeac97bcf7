import 'package:flutter/material.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/core/widgets/variable_text_field.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command.response_workflow.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/response_embeds_editor.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/component_v2_editor.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/normal_component_editor.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/modal_builder.dart';
import 'package:bot_creator_shared/types/component.dart';

import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

class ReplyCard extends StatelessWidget {
  final String responseType;
  final ValueChanged<String> onResponseTypeChanged;
  final TextEditingController responseController;
  final Widget variableSuggestionBar;
  final List<Map<String, dynamic>> responseEmbeds;
  final ValueChanged<List<Map<String, dynamic>>> onEmbedsChanged;
  final Map<String, dynamic> responseComponents;
  final ValueChanged<Map<String, dynamic>> onComponentsChanged;
  final Map<String, dynamic> responseModal;
  final ValueChanged<Map<String, dynamic>> onModalChanged;
  final Map<String, dynamic> responseWorkflow;
  final Map<String, dynamic> Function(Map<String, dynamic>) normalizeWorkflow;
  final List<VariableSuggestion> variableSuggestions;
  final List<AppEmoji>? emojiSuggestions;
  final String? botIdForConfig;
  final ValueChanged<Map<String, dynamic>> onWorkflowChanged;
  final String workflowSummary;
  final String? activeRouteLabel;
  final bool activeRouteIsGrouped;
  final bool allowModal;

  const ReplyCard({
    super.key,
    required this.responseType,
    required this.onResponseTypeChanged,
    required this.responseController,
    required this.variableSuggestionBar,
    required this.responseEmbeds,
    required this.onEmbedsChanged,
    required this.responseComponents,
    required this.onComponentsChanged,
    required this.responseModal,
    required this.onModalChanged,
    required this.responseWorkflow,
    required this.normalizeWorkflow,
    required this.variableSuggestions,
    this.emojiSuggestions,
    this.botIdForConfig,
    required this.onWorkflowChanged,
    required this.workflowSummary,
    this.activeRouteLabel,
    this.activeRouteIsGrouped = false,
    this.allowModal = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 420;
    final routeColor =
        activeRouteIsGrouped
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.primary;

    Future<void> openWorkflowEditor() async {
      final nextWorkflow = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder:
              (context) => CommandResponseWorkflowPage(
                initialWorkflow: normalizeWorkflow(responseWorkflow),
                variableSuggestions: variableSuggestions,
                emojiSuggestions: emojiSuggestions,
                botIdForConfig: botIdForConfig,
              ),
        ),
      );

      if (nextWorkflow != null) {
        onWorkflowChanged(normalizeWorkflow(nextWorkflow));
      }
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr.reply_command_reply_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr.reply_choose_type,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            if (activeRouteLabel != null && activeRouteLabel!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: routeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      context.tr.reply_active_route(activeRouteLabel!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: routeColor,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _buildResponseModeSelector(context),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.brandPrimary.withValues(alpha: 0.2),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.brandGradient,
                    ),
                    child: Text(
                      context.tr.reply_response_workflow,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workflowSummary,
                          style: TextStyle(fontSize: 12, color: AppTheme.grey),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: openWorkflowEditor,
                          icon: const Icon(Icons.account_tree_outlined),
                          label: Text(context.tr.reply_configure_workflow),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (responseType == 'message' || responseType == 'normal') ...[
              VariableTextField(
                label: context.tr.reply_response_text_label,
                controller: responseController,
                maxLines: 4,
                suggestions: variableSuggestions,
                emojiSuggestions: emojiSuggestions,
                onChanged: (_) {},
                helperText: context.tr.reply_response_text_helper,
              ),
              // external suggestion bar provided by parent (e.g. command creation page)
              variableSuggestionBar,
              const SizedBox(height: 12),
              ResponseEmbedsEditor(
                embeds: responseEmbeds,
                variableSuggestions: variableSuggestions,
                emojiSuggestions: emojiSuggestions,
                onChanged: onEmbedsChanged,
              ),
              const SizedBox(height: 12),
              NormalComponentEditorWidget(
                definition: ComponentV2Definition.fromJson(responseComponents),
                onChanged: (def) => onComponentsChanged(def.toJson()),
                variableSuggestions: variableSuggestions,
                botIdForConfig: botIdForConfig,
              ),
            ] else if (responseType == 'componentV2') ...[
              ComponentV2EditorWidget(
                definition: ComponentV2Definition.fromJson(responseComponents),
                onChanged: (def) => onComponentsChanged(def.toJson()),
                variableSuggestions: variableSuggestions,
                botIdForConfig: botIdForConfig,
              ),
            ] else if (responseType == 'modal') ...[
              ModalBuilderWidget(
                modal: ModalDefinition.fromJson(responseModal),
                onChanged: (def) => onModalChanged(def.toJson()),
                variableSuggestions: variableSuggestions,
                botIdForConfig: botIdForConfig,
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.error,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mode inconnu: $responseType',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Veuillez sélectionner un mode ci-dessus.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Unified mode selector that displays each response mode with a label,
  /// description, and icon so users understand when to use which mode.
  Widget _buildResponseModeSelector(BuildContext context) {
    final modes = [
      (
        value: 'message',
        label: context.tr.reply_mode_standard,
        description: context.tr.reply_mode_standard_desc,
        icon: Icons.message_outlined,
      ),
      (
        value: 'componentV2',
        label: context.tr.reply_mode_layout,
        description: context.tr.reply_mode_layout_desc,
        icon: Icons.dashboard_customize_outlined,
      ),
    ];

    final visibleModes =
        <({String value, String label, String description, IconData icon})>[
          ...modes,
          if (allowModal)
            (
              value: 'modal',
              label: context.tr.reply_mode_modal,
              description: context.tr.reply_mode_modal_desc,
              icon: Icons.web_asset_outlined,
            ),
        ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 420;
        final chips = [
          for (var i = 0; i < visibleModes.length; i++)
            _buildResponseModeChip(
              context: context,
              value: visibleModes[i].value,
              label: visibleModes[i].label,
              description: visibleModes[i].description,
              icon: visibleModes[i].icon,
              useExpanded: useRow,
            ),
        ];

        if (useRow) {
          return Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                chips[i],
                if (i < chips.length - 1) const SizedBox(width: 8),
              ],
            ],
          );
        }
        return Wrap(spacing: 8, runSpacing: 8, children: chips);
      },
    );
  }

  Widget _buildResponseModeChip({
    required BuildContext context,
    required String value,
    required String label,
    required String description,
    required IconData icon,
    bool useExpanded = true,
  }) {
    final selected = responseType == value;
    final colorScheme = Theme.of(context).colorScheme;

    final chip = GestureDetector(
      onTap: () => onResponseTypeChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.brandGradient : null,
          color: selected ? null : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color:
                selected
                    ? Colors.transparent
                    : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppTheme.grey,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: selected ? Colors.white70 : colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    return useExpanded ? Expanded(child: chip) : chip;
  }
}

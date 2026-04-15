part of 'command.create.dart';

const int _commandCreateStepCount = 5;

extension _CommandCreateStepTitles on _CommandCreatePageState {
  List<String> get _commandCreateStepTitles => <String>[
    context.tr.wizard_step_infos,
    context.tr.wizard_step_trigger_inputs,
    context.tr.wizard_step_reply,
    context.tr.wizard_step_actions,
    context.tr.wizard_step_review,
  ];
}

extension _CommandCreateWizard on _CommandCreatePageState {
  IconData _stepIconFor(int index) {
    switch (index) {
      case 0:
        return Icons.info_outline;
      case 1:
        return Icons.tune;
      case 2:
        return Icons.reply_outlined;
      case 3:
        return Icons.account_tree_outlined;
      case 4:
        return Icons.fact_check_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Future<void> _openReplyEditor() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder:
            (_) => CommandReplyEditorPage(
              initialResponseType: _responseType,
              initialResponseText: _responseController.text,
              initialEmbeds: _responseEmbeds,
              initialComponents: _responseComponents,
              initialModal: _responseModal,
              initialWorkflow: _responseWorkflow,
              normalizeWorkflow: _normalizeWorkflow,
              variableSuggestions: _actionVariableSuggestions,
              emojiSuggestions: _appEmojis,
              botIdForConfig: _botIdForConfig,
              allowModal: _allowModalResponses,
            ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    _applyStateUpdate(() {
      _responseType = (result['responseType'] ?? 'normal').toString();
      _response = (result['responseText'] ?? '').toString();
      _responseController.text = _response;
      _responseEmbeds = List<Map<String, dynamic>>.from(
        (result['responseEmbeds'] as List?)?.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ) ??
            const <Map<String, dynamic>>[],
      );
      _responseComponents = Map<String, dynamic>.from(
        (result['responseComponents'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
      _responseModal = Map<String, dynamic>.from(
        (result['responseModal'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
      _responseWorkflow = _normalizeWorkflow(
        Map<String, dynamic>.from(
          (result['responseWorkflow'] as Map?)?.cast<String, dynamic>() ??
              _CommandCreatePageState._defaultWorkflow(),
        ),
      );
      _persistActiveSubcommandWorkflow();
    });
  }

  void _applyQuickStartPreset() {
    _applyStateUpdate(() {
      _applyQuickStartToDraft();
      _persistActiveSubcommandWorkflow();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.wizard_quick_start_applied)),
    );
  }

  String _responseModeLabel() {
    switch (_responseType) {
      case 'componentV2':
        return context.tr.response_mode_layout;
      case 'modal':
        return context.tr.response_mode_modal;
      default:
        return context.tr.response_mode_standard;
    }
  }

  String _responseSummaryLine() {
    final preview = _responseController.text.trim();
    final embeds = _responseEmbeds.length;
    final hasComponents = _responseComponents.isNotEmpty;
    final visibility =
        _responseWorkflow['visibility'] == 'ephemeral'
            ? context.tr.response_visibility_ephemeral
            : context.tr.response_visibility_public;
    final parts = <String>[
      _responseModeLabel(),
      visibility,
      if (preview.isNotEmpty)
        preview.length > 80 ? '${preview.substring(0, 79)}...' : preview,
      if (embeds > 0) context.tr.response_embeds_count(embeds),
      if (hasComponents) context.tr.response_interactive_components,
    ];
    return parts.join(' | ');
  }

  String _actionsSummaryLine() {
    if (_isBdfdScriptMode) {
      final lines = _bdfdScriptController.text.trim().split('\n');
      final diagnostics = _bdfdDiagnostics.length;
      return context.tr.actions_summary_bdfd(
        lines.where((line) => line.trim().isNotEmpty).length,
        diagnostics,
      );
    }
    final actionCount = _actions.length;
    final subcommands = _subcommandWorkflows.length;
    if (subcommands > 0) {
      return context.tr.actions_summary_routes(actionCount, subcommands);
    }
    return context.tr.actions_summary_configured(actionCount);
  }

  Widget _buildWizardShell({required double contentMaxWidth}) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepNavigation(),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _buildStepBody(_currentEditorStep, contentMaxWidth),
          ),
          const SizedBox(height: 16),
          _buildStepFooter(),
        ],
      ),
    );
  }

  Widget _buildStepNavigation() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List<Widget>.generate(_commandCreateStepCount, (index) {
        final selected = _currentEditorStep == index;
        return ChoiceChip(
          selected: selected,
          showCheckmark: false,
          avatar: Icon(
            _stepIconFor(index),
            size: 16,
            color:
                selected
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.grey,
          ),
          label: Text(_commandCreateStepTitles[index]),
          onSelected: (_) {
            _applyStateUpdate(() {
              _currentEditorStep = index;
            });
          },
        );
      }),
    );
  }

  Widget _buildStepFooter() {
    final isReview = _currentEditorStep == _commandCreateStepCount - 1;
    return Row(
      children: [
        if (_currentEditorStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _applyStateUpdate(() {
                  _currentEditorStep -= 1;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(context.tr.common_back),
            ),
          ),
        if (_currentEditorStep > 0) const SizedBox(width: 12),
        Expanded(
          child:
              isReview
                  ? FilledButton.icon(
                    onPressed: () {
                      if (_validateCommandInputs()) {
                        _updateOrCreate();
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: Text(
                      _isEditingExistingCommand
                          ? context.tr.wizard_save_command
                          : context.tr.wizard_create_command,
                    ),
                  )
                  : FilledButton.icon(
                    onPressed: () {
                      _applyStateUpdate(() {
                        _currentEditorStep += 1;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(context.tr.common_next),
                  ),
        ),
      ],
    );
  }

  Widget _buildStepBody(int stepIndex, double contentMaxWidth) {
    switch (stepIndex) {
      case 0:
        return _buildInfoStep();
      case 1:
        return _buildTriggerAndInputsStep();
      case 2:
        return _buildReplyStep();
      case 3:
        return _buildActionsStep(contentMaxWidth);
      case 4:
      default:
        return _buildReviewStep();
    }
  }

  Widget _buildInfoStep() {
    return Column(
      key: const ValueKey('step-info'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BasicInfoCard(
          commandName: _commandName,
          commandDescription: _commandDescription,
          commandType: _commandType,
          isLegacyCommand:
              _legacyModeEnabled &&
              _commandType == ApplicationCommandType.chatInput,
          canEditCommandType: !_isEditingExistingCommand,
          localOnlyCommand: _localOnlyCommand,
          showDescriptionField: _supportsCommandDescription,
          integrationTypes: _integrationTypes,
          contexts: _contexts,
          onNameChanged: (val) {
            _applyStateUpdate(() {
              _commandName = val;
            });
          },
          onDescriptionChanged: (val) {
            _applyStateUpdate(() {
              _commandDescription = val;
            });
          },
          onCommandTypeChanged: (val) {
            _applyStateUpdate(() {
              _persistActiveSubcommandWorkflow();
              _commandType = val;
              if (!_supportsSimpleMode) {
                _editorMode = _CommandCreatePageState._editorModeAdvanced;
                _legacyModeEnabled = false;
                _localOnlyCommand = false;
              }
              if (_commandType != ApplicationCommandType.chatInput) {
                _subcommandWorkflows = <String, Map<String, dynamic>>{};
                _activeSubcommandRoute =
                    _CommandCreatePageState._rootWorkflowRoute;
              } else {
                _syncSubcommandWorkflowRoutes();
              }
            });
          },
          onLegacyCommandChanged: (enabled) {
            _applyStateUpdate(() {
              _persistActiveSubcommandWorkflow();
              _commandType = ApplicationCommandType.chatInput;
              _legacyModeEnabled = enabled;
              _localOnlyCommand = enabled;
              if (_legacyModeEnabled && _responseType == 'modal') {
                _responseType = 'normal';
              }
              _syncSubcommandWorkflowRoutes();
            });
          },
          onLocalOnlyCommandChanged: (enabled) {
            _applyStateUpdate(() {
              _localOnlyCommand = enabled;
            });
          },
          onIntegrationTypesChanged: (val) {
            _applyStateUpdate(() {
              _integrationTypes = val;
            });
          },
          onContextsChanged: (val) {
            _applyStateUpdate(() {
              _contexts = val;
            });
          },
          onDefaultMemberPermissionsChanged: (value) {
            _applyStateUpdate(() {
              _defaultMemberPermissions = value;
            });
          },
          defaultMemberPermissions: _defaultMemberPermissions,
          nameValidator: _validateName,
          nameMaxLength: _commandNameMaxLength,
        ),
        const SizedBox(height: 12),
        _buildFolderField(),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _openDocumentationCenter,
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(context.tr.cmd_show_variables),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerAndInputsStep() {
    return Column(
      key: const ValueKey('step-trigger'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_subcommandWorkflows.isNotEmpty) ...[
          _buildSubcommandWorkflowSelectorCard(),
          const SizedBox(height: 12),
        ],
        if (_supportsCommandOptions) ...[
          _buildCommandOptionsCard(),
          const SizedBox(height: 12),
        ],
        if (_supportsCommandOptions && !_isBdfdScriptMode)
          ExpansionTile(
            title: Text(context.tr.wizard_advanced_trigger),
            subtitle: Text(
              context.tr.wizard_legacy_options_subtitle,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLegacyModeCard(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReplyStep() {
    final activeRouteLabel =
        _subcommandWorkflows.isNotEmpty
            ? _workflowRouteLabel(_activeSubcommandRoute)
            : null;
    return Column(
      key: const ValueKey('step-reply'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr.wizard_reply_summary,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _responseSummaryLine(),
                  style: TextStyle(color: AppTheme.grey),
                ),
                if (activeRouteLabel != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(activeRouteLabel)),
                      Chip(label: Text(_workflowSummary())),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Chip(label: Text(_workflowSummary())),
                ],
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _openReplyEditor,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(context.tr.wizard_edit_reply),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsStep(double contentMaxWidth) {
    return Column(
      key: const ValueKey('step-actions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_supportsSimpleMode && !_isBdfdScriptMode)
          ExpansionTile(
            initiallyExpanded: _showQuickStartBuilder,
            onExpansionChanged: (expanded) {
              _applyStateUpdate(() {
                _showQuickStartBuilder = expanded;
              });
            },
            title: Text(context.tr.wizard_quick_starts),
            subtitle: Text(
              context.tr.wizard_quick_start_subtitle,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSimpleActionsCard(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FilledButton.tonalIcon(
                  onPressed: _applyQuickStartPreset,
                  icon: const Icon(Icons.bolt_outlined),
                  label: Text(context.tr.wizard_apply_quick_start),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: Text(context.tr.wizard_code_advanced),
          subtitle: Text(
            _isBdfdScriptMode
                ? context.tr.wizard_bdfd_mode_enabled
                : context.tr.wizard_visual_mode_enabled,
            style: TextStyle(fontSize: 12, color: AppTheme.grey),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExecutionModeCard(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_subcommandWorkflows.isNotEmpty) ...[
          _buildSubcommandWorkflowSelectorCard(),
          const SizedBox(height: 12),
        ],
        if (_isBdfdScriptMode)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr.wizard_command_body,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _actionsSummaryLine(),
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 12),
                  _buildBdfdEditorTile(),
                  const SizedBox(height: 12),
                  _buildBdfdDiagnosticsPanel(),
                ],
              ),
            ),
          )
        else
          ActionsCard(
            actions: _actions,
            onActionsChanged: (val) {
              _applyStateUpdate(() {
                _actions = val;
                _persistActiveSubcommandWorkflow();
              });
            },
            actionVariableSuggestions: _actionVariableSuggestions,
            emojiSuggestions: _appEmojis,
            botIdForConfig: _botIdForConfig,
            activeRouteLabel:
                _subcommandWorkflows.isNotEmpty
                    ? _workflowRouteLabel(_activeSubcommandRoute)
                    : null,
            activeRouteIsGrouped:
                _subcommandWorkflows.isNotEmpty &&
                _activeSubcommandRoute.contains('/'),
          ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final subcommandCount = _subcommandWorkflows.length;
    return Column(
      key: const ValueKey('step-review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewCard(
          title: context.tr.review_info_title,
          icon: Icons.info_outline,
          lines: <String>[
            context.tr.review_name_line(
              _commandName.isEmpty
                  ? context.tr.review_name_untitled
                  : _commandName,
            ),
            context.tr.review_type_line(_commandTypeToText(_commandType)),
            if (_commandDescription.trim().isNotEmpty)
              context.tr.review_description_line(_commandDescription.trim()),
            if (_folder.trim().isNotEmpty)
              context.tr.review_folder_line(_folder.trim()),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: context.tr.review_trigger_inputs_title,
          icon: Icons.tune,
          lines: <String>[
            context.tr.review_options_count(_effectiveOptions.length),
            if (subcommandCount > 0)
              context.tr.review_subcommand_routes(subcommandCount),
            if (_legacyModeEnabled) context.tr.review_legacy_mode,
            if (_localOnlyCommand) context.tr.review_local_only,
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: context.tr.review_reply_title,
          icon: Icons.reply_outlined,
          lines: <String>[_responseSummaryLine(), _workflowSummary()],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: context.tr.review_actions_title,
          icon: Icons.account_tree_outlined,
          lines: <String>[_actionsSummaryLine()],
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final line in lines.where(
                    (line) => line.trim().isNotEmpty,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(line),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

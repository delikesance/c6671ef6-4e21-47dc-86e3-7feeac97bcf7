part of 'command.create.dart';

extension _CommandCreateEditShell on _CommandCreatePageState {
  String _editCommandTypeLabel() {
    if (_legacyModeEnabled) {
      return 'Legacy command';
    }
    switch (_commandType) {
      case ApplicationCommandType.user:
        return 'User command';
      case ApplicationCommandType.message:
        return 'Message command';
      case ApplicationCommandType.chatInput:
        return 'Slash command';
      default:
        return 'Command';
    }
  }

  IconData _editCommandTypeIcon() {
    if (_legacyModeEnabled) {
      return Icons.history_toggle_off;
    }
    switch (_commandType) {
      case ApplicationCommandType.user:
        return Icons.person_outline;
      case ApplicationCommandType.message:
        return Icons.chat_bubble_outline;
      case ApplicationCommandType.chatInput:
        return Icons.bolt_outlined;
      default:
        return Icons.bolt_outlined;
    }
  }

  Widget _buildEditShell() {
    final activeRouteLabel =
        _subcommandWorkflows.isNotEmpty
            ? _workflowRouteLabel(_activeSubcommandRoute)
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EditSummaryCard(
          title:
              _commandName.trim().isEmpty ? 'Untitled command' : _commandName,
          subtitle:
              'Reply and behavior are front and center here. Inputs and availability settings stay below when you need them.',
          saveLabel: 'Save changes',
          onSave: () {
            _saveExistingCommand();
          },
          badges: [
            _EditSummaryBadge(
              label: _editCommandTypeLabel(),
              icon: _editCommandTypeIcon(),
            ),
            if (_subcommandWorkflows.isNotEmpty)
              _EditSummaryBadge(
                label: '${_subcommandWorkflows.length} route(s)',
                icon: Icons.route_outlined,
              ),
            if (_localOnlyCommand)
              const _EditSummaryBadge(
                label: 'Local-only',
                icon: Icons.offline_bolt,
              ),
            if (_isLocalOnlyCommand)
              const _EditSummaryBadge(
                label: 'Local draft',
                icon: Icons.cloud_off,
              ),
            if (_isDirty)
              const _EditSummaryBadge(
                label: 'Unsaved changes',
                icon: Icons.circle,
              ),
          ],
        ),
        if (_subcommandWorkflows.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSubcommandWorkflowSelectorCard(),
        ],
        const SizedBox(height: 12),
        _buildReplyStep(),
        const SizedBox(height: 12),
        if (_isBdfdScriptMode)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Command body',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _actionsSummaryLine(),
                    style: TextStyle(color: Colors.grey.shade700),
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
            activeRouteLabel: activeRouteLabel,
            activeRouteIsGrouped:
                _subcommandWorkflows.isNotEmpty &&
                _activeSubcommandRoute.contains('/'),
          ),
        const SizedBox(height: 12),
        _buildEditSectionCard(
          title: 'Trigger & Inputs',
          subtitle:
              'Adjust command options, trigger behavior, and execution mode.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_supportsCommandOptions) _buildCommandOptionsCard(),
              if (_supportsCommandOptions) const SizedBox(height: 12),
              if (_supportsCommandOptions && !_isBdfdScriptMode)
                _buildLegacyModeCard(),
              if (_supportsCommandOptions && !_isBdfdScriptMode)
                const SizedBox(height: 12),
              _buildExecutionModeCard(includeInlineEditor: false),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildEditSectionCard(
          title: 'Command settings',
          subtitle:
              'Metadata, availability, permissions, and folder placement.',
          child: Column(
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey<String>('edit-section-$title'),
          maintainState: true,
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [child],
        ),
      ),
    );
  }
}

class _EditSummaryCard extends StatelessWidget {
  const _EditSummaryCard({
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.saveLabel,
    required this.onSave,
  });

  final String title;
  final String subtitle;
  final List<_EditSummaryBadge> badges;
  final String saveLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: badges),
              ],
            );

            final saveButton = FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: Text(saveLabel),
            );

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: 16),
                  saveButton,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 16), saveButton],
            );
          },
        ),
      ),
    );
  }
}

class _EditSummaryBadge extends StatelessWidget {
  const _EditSummaryBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

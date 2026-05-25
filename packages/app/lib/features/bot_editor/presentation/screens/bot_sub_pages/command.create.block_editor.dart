part of 'command.create.dart';

/// New Scratch-like block editor that replaces the wizard and edit shell.
///
/// Uses [ScratchBlockCanvas] with fixed Metadata and EntryPoint blocks
/// followed by dynamic action blocks.
extension _CommandBlockEditor on _CommandCreatePageState {
  Widget _buildBlockEditor({required double contentMaxWidth}) {
    final entryPointType =
        _legacyModeEnabled
            ? CommandEntryPointType.message
            : CommandEntryPointType.interaction;

    final isBdfdMode =
        _executionMode == _CommandCreatePageState._executionModeBdfdScript;

    // Collect action blocks
    final actionBlocks = <Widget>[];

    if (!isBdfdMode) {
      for (var i = 0; i < _actions.length; i++) {
        final action = ActionItem.fromJson(
          _actions[i],
          fallbackId: 'action_$i',
        );
        actionBlocks.add(
          ActionBlock(
            key: ValueKey('action-block-${action.id}'),
            action: action,
            index: i,
            totalCount: _actions.length,
            variableSuggestions: _actionVariableSuggestions,
            emojiSuggestions: _appEmojis,
            botIdForConfig: _botIdForConfig,
            onRemove: () {
              _applyStateUpdate(() {
                _actions.removeAt(i);
                _persistActiveSubcommandWorkflow();
              });
            },
            onMoveUp:
                i > 0
                    ? () {
                      _applyStateUpdate(() {
                        final item = _actions.removeAt(i);
                        _actions.insert(i - 1, item);
                        _persistActiveSubcommandWorkflow();
                      });
                    }
                    : null,
            onMoveDown:
                i < _actions.length - 1
                    ? () {
                      _applyStateUpdate(() {
                        final item = _actions.removeAt(i);
                        _actions.insert(i + 1, item);
                        _persistActiveSubcommandWorkflow();
                      });
                    }
                    : null,
            onParameterChanged: (key, value) {
              _applyStateUpdate(() {
                if (key == '__enabled__') {
                  _actions[i]['enabled'] = value == true;
                  return;
                }
                if (key == '__onErrorMode__') {
                  final error = Map<String, dynamic>.from(
                    (_actions[i]['error'] as Map?)?.cast<String, dynamic>() ??
                        const {},
                  );
                  error['mode'] = value == 'continue' ? 'continue' : 'stop';
                  _actions[i]['error'] = error;
                  return;
                }
                if (key == '__actionKey__') {
                  _actions[i]['key'] = value.toString();
                  _persistActiveSubcommandWorkflow();
                  return;
                }
                final payload = Map<String, dynamic>.from(
                  (_actions[i]['payload'] as Map?)?.cast<String, dynamic>() ??
                      const {},
                );
                payload[key] = value;
                _actions[i]['payload'] = payload;
                _persistActiveSubcommandWorkflow();
              });
            },
            onSuggestionSelected: (key, value) {
              _applyStateUpdate(() {
                final payload = Map<String, dynamic>.from(
                  (_actions[i]['payload'] as Map?)?.cast<String, dynamic>() ??
                      const {},
                );
                payload[key] = value;
                _actions[i]['payload'] = payload;
              });
            },
            fieldRefreshVersionOf: (_) => 0,
            onEditNestedActions: (current, suggestions, blockName, {onChanged}) async {
              final result = await Navigator.push<List<Map<String, dynamic>>>(
                context,
                MaterialPageRoute<List<Map<String, dynamic>>>(
                  builder:
                      (_) => ActionsBuilderPage(
                        initialActions: current,
                        variableSuggestions: suggestions,
                        emojiSuggestions: _appEmojis,
                        botIdForConfig: _botIdForConfig,
                        editPath: ['Racine', blockName],
                        onChanged: onChanged,
                      ),
                ),
              );
              return result;
            },
          ),
        );
      }
    }

    // Build the canvas blocks
    final canvasChildren = <Widget>[
      // ── Fixed: Metadata Block ──
      MetadataBlock(
        commandName: _commandName,
        commandDescription: _commandDescription,
        commandType: _commandType,
        isLegacyCommand: _legacyModeEnabled,
        localOnlyCommand: _localOnlyCommand,
        canEditCommandType: !_isEditingExistingCommand || _isLocalOnlyCommand,
        showDescriptionField: _supportsCommandDescription,
        integrationTypes: _integrationTypes,
        contexts: _contexts,
        onNameChanged:
            (value) => _applyStateUpdate(() {
              _commandName = value;
            }),
        onDescriptionChanged:
            (value) => _applyStateUpdate(() {
              _commandDescription = value;
            }),
        onCommandTypeChanged:
            (value) => _applyStateUpdate(() {
              _commandType = value;
              if (!_supportsSimpleMode) {
                _editorMode = _CommandCreatePageState._editorModeAdvanced;
              }
            }),
        onLegacyCommandChanged:
            (value) => _applyStateUpdate(() {
              _legacyModeEnabled = value;
              _localOnlyCommand = value;
              if (_legacyModeEnabled && _responseType == 'modal') {
                _responseType = 'normal';
              }
            }),
        onLocalOnlyCommandChanged:
            (value) => _applyStateUpdate(() {
              _localOnlyCommand = value;
            }),
        onIntegrationTypesChanged:
            (value) => _applyStateUpdate(() {
              _integrationTypes = value;
            }),
        onContextsChanged:
            (value) => _applyStateUpdate(() {
              _contexts = value;
            }),
        defaultMemberPermissions: _defaultMemberPermissions,
        onDefaultMemberPermissionsChanged:
            (value) => _applyStateUpdate(() {
              _defaultMemberPermissions = value;
            }),
        nameValidator: _validateName,
        nameMaxLength: _commandNameMaxLength,
        // Options
        showOptions: _supportsCommandOptions,
        options: _options,
        onOptionsChanged: _applyOptionsUpdate,
        botIdForConfig: _botIdForConfig,
        variableSuggestions: _actionVariableSuggestions,
        // Folder
        folderController: _folderController,
        onFolderChanged: (value) {
          _folder = value.trim();
        },
      ),

      // ── Fixed: Entry Point Block ──
      EntryPointBlock(
        entryPointType: entryPointType,
        onEntryPointTypeChanged:
            (value) => _applyStateUpdate(() {
              if (value == CommandEntryPointType.message) {
                _legacyModeEnabled = true;
                _localOnlyCommand = true;
              } else {
                _legacyModeEnabled = false;
                _localOnlyCommand = false;
              }
            }),
        legacyModeEnabled: _legacyModeEnabled,
        onLegacyModeChanged:
            _supportsCommandOptions
                ? (value) => _applyStateUpdate(() {
                  _legacyModeEnabled = value;
                  _localOnlyCommand = value;
                  if (_legacyModeEnabled && _responseType == 'modal') {
                    _responseType = 'normal';
                  }
                })
                : null,
        legacyPrefixOverride: _legacyPrefixOverride,
        onLegacyPrefixOverrideChanged:
            (value) => _applyStateUpdate(() {
              _legacyPrefixOverride = value;
            }),
        legacyResponseTarget: _legacyResponseTarget,
        onLegacyResponseTargetChanged:
            (value) => _applyStateUpdate(() {
              _legacyResponseTarget = value;
            }),
        executionMode: _executionMode,
        onExecutionModeChanged:
            (value) => _applyStateUpdate(() {
              _executionMode = value;
              if (value == _CommandCreatePageState._executionModeBdfdScript) {
                _refreshBdfdCompileResult(notify: false);
              }
            }),
      ),

      // ── Subcommand route selector (if applicable) ──
      if (_subcommandWorkflows.isNotEmpty) _buildBlockSubcommandSelector(),

      // ── BDFD Script editor (if BDFD mode) ──
      if (isBdfdMode) _buildBdfdBlock(),

      // ── Action blocks ──
      ...actionBlocks,

      // ── Add block button ──
      if (!isBdfdMode) _buildAddBlockButton(),
    ];

    // Compute indices of final (cap) blocks so the canvas skips connectors
    // after them.
    final skipConnectorAfter = <int>{};

    if (!isBdfdMode) {
      // Offset: MetadataBlock + EntryPointBlock + optional subcommand + optional bdfd
      var offset = 2;
      if (_subcommandWorkflows.isNotEmpty) offset++;
      if (isBdfdMode) offset++;
      for (var i = 0; i < _actions.length; i++) {
        final type = BotCreatorActionType.values.firstWhere(
          (t) => t.name == _actions[i]['type'],
          orElse: () => BotCreatorActionType.sendMessage,
        );
        if (isFinalAction(type)) {
          skipConnectorAfter.add(offset + i);
        }
      }
    }

    return ScratchBlockCanvas(
      skipConnectorAfterIndices: skipConnectorAfter,
      children: canvasChildren,
    );
  }

  Widget _buildBlockSubcommandSelector() {
    final routes = _subcommandWorkflows.keys.toList(growable: false);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr.actions_active_route(_activeSubcommandRoute),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: routes
                  .map((route) {
                    final isActive = route == _activeSubcommandRoute;
                    return ChoiceChip(
                      label: Text(_workflowRouteLabel(route)),
                      selected: isActive,
                      onSelected:
                          (_) => _applyStateUpdate(() {
                            _switchActiveSubcommandRoute(route);
                          }),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBdfdBlock() {
    final code = _bdfdScriptController.text;
    final isEmpty = code.trim().isEmpty;
    final preview =
        isEmpty
            ? context.tr.bdfd_editor_tap_hint
            : code.length > 300
            ? '${code.substring(0, 300)}…'
            : code;

    return ScratchBlock(
      color: AppTheme.brandPrimary,
      title: context.tr.scratch_bdfd_script,
      icon: Icons.code,
      required: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Preview / tap-to-edit ──
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute<String>(
                  builder:
                      (_) => BdfdEditorPage(
                        initialCode: _bdfdScriptController.text,
                        title: context.tr.workflow_bdfd_editor_title,
                      ),
                ),
              );
              if (result != null && mounted) {
                _applyStateUpdate(() {
                  _bdfdScriptController.text = result;
                  _refreshBdfdCompileResult(notify: false);
                });
              }
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.codeSurfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.grey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: AppTheme.grey),
                      const SizedBox(width: 6),
                      Text(
                        context.tr.bdfd_editor_tap_hint,
                        style: TextStyle(fontSize: 11, color: AppTheme.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    preview,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFFCFD8DC),
                    ),
                    maxLines: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // ── Diagnostics ──
          if (_bdfdDiagnostics.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final diagnostic in _bdfdDiagnostics.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _formatBdfdDiagnostic(diagnostic),
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        diagnostic.severity ==
                                BdfdCompileDiagnosticSeverity.error
                            ? AppTheme.error
                            : AppTheme.warning,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddBlockButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: () {
          showBlockPalette(
            context,
            onActionSelected: (type) {
              _applyStateUpdate(() {
                final newAction = <String, dynamic>{
                  'id': 'action_${_actions.length}',
                  'type': type.name,
                  'enabled': true,
                  'key': 'action_${_actions.length}',
                  'depend_on': <String>[],
                  'error': {'mode': 'stop'},
                  'payload': Map<String, dynamic>.from(type.defaultParameters),
                };
                _actions.add(newAction);
                _persistActiveSubcommandWorkflow();
              });
            },
          );
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr.scratch_add_block),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }
}

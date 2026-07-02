part of 'command.create.dart';

/// New Scratch-like block editor that replaces the wizard and edit shell.
///
/// Uses [ScratchBlockCanvas] with fixed Metadata and EntryPoint blocks
/// followed by dynamic action blocks.
extension _CommandBlockEditor on _CommandCreatePageState {
  Widget _buildBlockEditor({required double contentMaxWidth}) {
    final isDesktop = MediaQuery.of(context).size.width >= 800 &&
        !Platform.environment.containsKey('FLUTTER_TEST');

    final entryPointType =
        _legacyModeEnabled
            ? CommandEntryPointType.message
            : CommandEntryPointType.interaction;

    final isBdfdMode =
        _executionMode == _CommandCreatePageState._executionModeBdfdScript;
    final isJavascriptMode =
        _executionMode == _CommandCreatePageState._executionModeJavascript;
    final isCodeMode = isBdfdMode || isJavascriptMode;

    // Collect action blocks
    final actionBlocks = <Widget>[];

    // Precompute ActionItem list for Jump to action dropdown
    final allActionItems = List<ActionItem>.generate(
      _actions.length,
      (i) => ActionItem.fromJson(_actions[i], fallbackId: 'action_$i'),
    );

    if (!isCodeMode) {
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
            onPasteAbove: (copiedAction) {
              _applyStateUpdate(() {
                final copy = Map<String, dynamic>.from(
                  jsonDecode(jsonEncode(copiedAction)),
                );
                copy['id'] = 'action_${DateTime.now().microsecondsSinceEpoch}';
                _actions.insert(i, copy);
                _persistActiveSubcommandWorkflow();
              });
            },
            onPasteBelow: (copiedAction) {
              _applyStateUpdate(() {
                final copy = Map<String, dynamic>.from(
                  jsonDecode(jsonEncode(copiedAction)),
                );
                copy['id'] = 'action_${DateTime.now().microsecondsSinceEpoch}';
                _actions.insert(i + 1, copy);
                _persistActiveSubcommandWorkflow();
              });
            },
            onDuplicate: () {
              _applyStateUpdate(() {
                final copy = Map<String, dynamic>.from(
                  jsonDecode(jsonEncode(_actions[i])),
                );
                copy['id'] = 'action_${DateTime.now().microsecondsSinceEpoch}';
                _actions.insert(i + 1, copy);
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
                  error['mode'] = value == 'continue' ? 'continue'
                      : (value == 'jump' ? 'jump' : (value == 'skip' ? 'skip' : 'stop'));
                  _actions[i]['error'] = error;
                  return;
                }
                if (key == '__onErrorJumpTarget__') {
                  final error = Map<String, dynamic>.from(
                    (_actions[i]['error'] as Map?)?.cast<String, dynamic>() ??
                        const {},
                  );
                  error['jumpToActionId'] = value?.toString();
                  _actions[i]['error'] = error;
                  return;
                }
                if (key == '__onErrorSkipCount__') {
                  final error = Map<String, dynamic>.from(
                    (_actions[i]['error'] as Map?)?.cast<String, dynamic>() ??
                        const {},
                  );
                  error['skipCount'] = value?.toString();
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
                        isInteraction: !_legacyModeEnabled,
                      ),
                ),
              );
              return result;
            },
            allActions: allActionItems,
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
        onOptionsChanged:
            (value) => _applyStateUpdate(() {
              _applyOptionsUpdate(value);
            }),
        botIdForConfig: _botIdForConfig,
        variableSuggestions: _actionVariableSuggestions,
        // Folder
        folderController: _folderController,
        onFolderChanged: (value) {
          _applyStateUpdate(() {
            _folder = value.trim();
          });
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
        showWorkflowMode: !_isJavascriptOnlyBot,
        showBdfdMode: !_isJavascriptOnlyBot,
        showJavascriptMode: _supportsJavascriptMode,
        onExecutionModeChanged: _isJavascriptOnlyBot
            ? null
            : (value) => _applyStateUpdate(() {
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

      // ── JavaScript editor (if JS mode) ──
      if (isJavascriptMode) _buildJavascriptBlock(),

      // ── Action blocks ──
      ...actionBlocks,

      // ── Add block button ──
      if (!isCodeMode && !isDesktop) _buildAddBlockButton(),
    ];

    // Compute indices of final (cap) blocks so the canvas skips connectors
    // after them.
    final skipConnectorAfter = <int>{};

    if (!isCodeMode) {
      // Offset: MetadataBlock + EntryPointBlock + optional subcommand + optional bdfd
      var offset = 2;
      if (_subcommandWorkflows.isNotEmpty) offset++;
      if (isBdfdMode || isJavascriptMode) offset++;
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

    final canvasWidget = ScratchBlockCanvas(
      padding: EdgeInsets.fromLTRB(16, 12, 16, _showEditShell ? 88 : 12),
      skipConnectorAfterIndices: skipConnectorAfter,
      children: canvasChildren,
    );

    if (isDesktop) {
      if (isCodeMode) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860.0),
            child: canvasWidget,
          ),
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: ScratchBlockPalette(
              onActionSelected: (type) {
                _applyStateUpdate(() {
                  final uniqueId = 'action_${DateTime.now().microsecondsSinceEpoch}';
                  _actions.add(<String, dynamic>{
                    'id': uniqueId,
                    'type': type.name,
                    'enabled': true,
                    'key': uniqueId,
                    'depend_on': <String>[],
                    'error': {'mode': 'stop'},
                    'payload': Map<String, dynamic>.from(type.defaultParameters),
                  });
                  _persistActiveSubcommandWorkflow();
                });
              },
              isInteraction: !_legacyModeEnabled,
              isWorkflow: false,
              popOnSelect: false,
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860.0),
                child: canvasWidget,
              ),
            ),
          ),
        ],
      );
    }

    return canvasWidget;
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

  Widget _buildJavascriptBlock() {
    return ScratchBlock(
      color: Colors.orange,
      title: context.tr.cmd_execution_mode_javascript,
      icon: Icons.code,
      required: true,
      child: _buildJavascriptEditorTile(),
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
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute<String>(
                  builder:
                      (_) => BdfdEditorPage(
                        initialCode: _bdfdScriptController.text,
                        title: context.tr.workflow_bdfd_editor_title,
                        appEmojis: _appEmojis,
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
            isInteraction: !_legacyModeEnabled,
            onActionSelected: (type) {
              _applyStateUpdate(() {
                final uniqueId = 'action_${DateTime.now().microsecondsSinceEpoch}';
                final newAction = <String, dynamic>{
                  'id': uniqueId,
                  'type': type.name,
                  'enabled': true,
                  'key': uniqueId,
                  'depend_on': <String>[],
                  'error': {'mode': 'stop'},
                  'payload': Map<String, dynamic>.from(type.defaultParameters),
                };
                // Defensive: ensure _actions is a growable list. Some code paths
                // (e.g. import, builder round-trip) may produce a fixed-length list
                // via const [] or List.unmodifiable, causing a runtime crash.
                try {
                  _actions.add(newAction);
                } on UnsupportedError {
                  // Fixed-length list — replace with a growable copy and retry.
                  _actions = List<Map<String, dynamic>>.from(_actions);
                  _actions.add(newAction);
                }
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

part of 'command.create.dart';

/// New Scratch-like block editor that replaces the wizard and edit shell.
///
/// Uses [ScratchBlockCanvas] with fixed Metadata and EntryPoint blocks
/// followed by dynamic action blocks.
extension _CommandBlockEditor on _CommandCreatePageState {
  Widget _buildBlockEditor({required double contentMaxWidth}) {
    final isDesktop =
        MediaQuery.of(context).size.width >= 800 &&
        !Platform.environment.containsKey('FLUTTER_TEST');

    final entryPointType = _legacyModeEnabled
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
            onMoveUp: i > 0
                ? () {
                    _applyStateUpdate(() {
                      final item = _actions.removeAt(i);
                      _actions.insert(i - 1, item);
                      _persistActiveSubcommandWorkflow();
                    });
                  }
                : null,
            onMoveDown: i < _actions.length - 1
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
                  error['mode'] = value == 'continue'
                      ? 'continue'
                      : (value == 'jump'
                            ? 'jump'
                            : (value == 'skip' ? 'skip' : 'stop'));
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
            onEditNestedActions:
                (current, suggestions, blockName, {onChanged}) async {
                  final result =
                      await Navigator.push<List<Map<String, dynamic>>>(
                        context,
                        MaterialPageRoute<List<Map<String, dynamic>>>(
                          builder: (_) => ActionsBuilderPage(
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
            onOpenDocs: _openDocumentationCenter,
          ),
        );
      }
    }

    final showMetadataOnCanvas =
        MediaQuery.of(context).size.width >= 900 ||
        Platform.environment.containsKey('FLUTTER_TEST');

    // Build the canvas blocks
    final canvasChildren = <Widget>[
      // ── Fixed: Metadata Block (Desktop or wide screens) ──
      if (showMetadataOnCanvas)
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
          onNameChanged: (value) => _applyStateUpdate(() {
            _commandName = value;
          }),
          onDescriptionChanged: (value) => _applyStateUpdate(() {
            _commandDescription = value;
          }),
          onCommandTypeChanged: (value) => _applyStateUpdate(() {
            _commandType = value;
            if (!_supportsSimpleMode) {
              _editorMode = _CommandCreatePageState._editorModeAdvanced;
            }
          }),
          onLegacyCommandChanged: (value) => _applyStateUpdate(() {
            _legacyModeEnabled = value;
            _localOnlyCommand = value;
          }),
          onLocalOnlyCommandChanged: (value) => _applyStateUpdate(() {
            _localOnlyCommand = value;
          }),
          onIntegrationTypesChanged: (value) => _applyStateUpdate(() {
            _integrationTypes = value;
          }),
          onContextsChanged: (value) => _applyStateUpdate(() {
            _contexts = value;
          }),
          defaultMemberPermissions: _defaultMemberPermissions,
          onDefaultMemberPermissionsChanged: (value) => _applyStateUpdate(() {
            _defaultMemberPermissions = value;
          }),
          nameValidator: _validateName,
          nameMaxLength: _commandNameMaxLength,
          // Options
          showOptions: _supportsCommandOptions,
          options: _options,
          onOptionsChanged: (value) => _applyStateUpdate(() {
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
        commandName: _commandName,
        commandType: _commandType,
        canEditCommandType: !_isEditingExistingCommand || _isLocalOnlyCommand,
        onCommandTypeChanged: (value) => _applyStateUpdate(() {
          _persistActiveSubcommandWorkflow();
          _commandType = value;
          if (!_supportsSimpleMode) {
            _editorMode = _CommandCreatePageState._editorModeAdvanced;
          }
          if (_commandType != ApplicationCommandType.chatInput) {
            _subcommandWorkflows = <String, Map<String, dynamic>>{};
            _activeSubcommandRoute = _CommandCreatePageState._rootWorkflowRoute;
          } else {
            _syncSubcommandWorkflowRoutes();
          }
        }),
        onOpenSettings: _openCommandSettings,
        onEntryPointTypeChanged: (value) => _applyStateUpdate(() {
          if (value == CommandEntryPointType.message) {
            _legacyModeEnabled = true;
            _localOnlyCommand = true;
          } else {
            _legacyModeEnabled = false;
            _localOnlyCommand = false;
          }
        }),
        legacyModeEnabled: _legacyModeEnabled,
        onLegacyModeChanged: (value) => _applyStateUpdate(() {
          _persistActiveSubcommandWorkflow();
          _legacyModeEnabled = value;
          _localOnlyCommand = value;
          if (value) {
            _commandType = ApplicationCommandType.chatInput;
          }
          _syncSubcommandWorkflowRoutes();
        }),
        legacyPrefixOverride: _legacyPrefixOverride,
        onLegacyPrefixOverrideChanged: (value) => _applyStateUpdate(() {
          _legacyPrefixOverride = value;
        }),
        legacyResponseTarget: _legacyResponseTarget,
        onLegacyResponseTargetChanged: (value) => _applyStateUpdate(() {
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

      // ── Empty state ──
      if (!isCodeMode && _actions.isEmpty) _buildActionsEmptyState(),

      // ── Inline action validation ──
      if (!isCodeMode) ..._buildActionValidationBanners(),

      // ── Action blocks ──
      ...actionBlocks,

      // ── Add block button ──
      if (!isCodeMode && !isDesktop) _buildAddBlockButton(),

      // ── Documentation Tip Card ──
      if (!isCodeMode) _buildDocumentationTipCard(),
    ];

    // Compute indices of elements after which the canvas skips connectors
    final skipConnectorAfter = <int>{};

    if (!isCodeMode && canvasChildren.isNotEmpty) {
      // Find the index of the first action block if present
      final firstActionIdx = actionBlocks.isNotEmpty
          ? canvasChildren.indexOf(actionBlocks.first)
          : -1;

      if (firstActionIdx != -1) {
        for (var i = 0; i < _actions.length; i++) {
          final type = BotCreatorActionType.values.firstWhere(
            (t) => t.name == _actions[i]['type'],
            orElse: () => BotCreatorActionType.sendMessage,
          );
          // If it's a stop action and the very last action, suppress arrow
          if (isFinalAction(type) && i == _actions.length - 1) {
            skipConnectorAfter.add(firstActionIdx + i);
          }
        }
      }

      // Omit connectors leading to and from the trailing tip card
      skipConnectorAfter.add(canvasChildren.length - 2);
      skipConnectorAfter.add(canvasChildren.length - 1);
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

      final isBlueprint = _desktopViewMode == 'blueprint';

      final centerCanvas = isBlueprint
          ? BlueprintGraphCanvas(
              commandName: _commandName.isNotEmpty ? _commandName : 'command',
              isInteraction: !_legacyModeEnabled,
              actions: allActionItems,
              customNodePositions: _blueprintNodePositions,
              severedConnectionIds: _blueprintSeveredConnections,
              onNodeMoved: (nodeId, position) {
                _blueprintNodePositions[nodeId] = position;
              },
              onDisconnectConnection:
                  (
                    connectionId, {
                    fromNodeId,
                    fromPinId,
                    toNodeId,
                    toPinId,
                    toNodePosition,
                    allNodePositions,
                  }) {
                    _applyStateUpdate(() {
                      _blueprintSeveredConnections.add(connectionId);
                      if (allNodePositions != null) {
                        _blueprintNodePositions.addAll(allNodePositions);
                      } else if (toNodeId != null && toNodePosition != null) {
                        _blueprintNodePositions.putIfAbsent(
                          toNodeId,
                          () => toNodePosition,
                        );
                      }

                      if (toNodeId != null) {
                        // Check if toNodeId is inside a nested branch of an IF block
                        final loc = _findActionInBranchTrees(
                          _actions,
                          toNodeId,
                        );
                        if (loc != null) {
                          // Extract toNodeId and any downstream chain from this branch
                          final branchList = loc.branchList;
                          final index = loc.indexInBranch;
                          final extracted = branchList.sublist(index);
                          branchList.removeRange(index, branchList.length);

                          loc.updateParentBranch(branchList);

                          // Append extracted actions to root _actions
                          final lastActionBefore = _actions.isNotEmpty
                              ? _actions.last
                              : null;
                          _actions.addAll(extracted);

                          // Sever connection from previous action to avoid unwanted auto-wire
                          if (lastActionBefore != null &&
                              extracted.isNotEmpty) {
                            _blueprintSeveredConnections.add(
                              'conn_${lastActionBefore['id']}_to_${extracted.first['id']}',
                            );
                          }
                          if (loc.parentAction['id'] != null &&
                              extracted.isNotEmpty) {
                            _blueprintSeveredConnections.add(
                              'conn_${loc.parentAction['id']}_to_${extracted.first['id']}',
                            );
                          }
                        }
                      }
                      _persistActiveSubcommandWorkflow();
                    });
                  },
              fieldRefreshVersionOf: (_) => 0,
              variableSuggestions: _actionVariableSuggestions,
              emojiSuggestions: _appEmojis,
              botIdForConfig: _botIdForConfig,
              onEditNestedActions:
                  (current, suggestions, blockName, {onChanged}) async {
                    final result =
                        await Navigator.push<List<Map<String, dynamic>>>(
                          context,
                          MaterialPageRoute<List<Map<String, dynamic>>>(
                            builder: (_) => ActionsBuilderPage(
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
              onParameterChanged: (index, key, value) {
                _applyStateUpdate(() {
                  if (key == '__enabled__') {
                    _actions[index]['enabled'] = value == true;
                    return;
                  }
                  if (key == '__onErrorMode__') {
                    final error = Map<String, dynamic>.from(
                      (_actions[index]['error'] as Map?)
                              ?.cast<String, dynamic>() ??
                          const {},
                    );
                    error['mode'] = value == 'continue'
                        ? 'continue'
                        : (value == 'jump'
                              ? 'jump'
                              : (value == 'skip' ? 'skip' : 'stop'));
                    _actions[index]['error'] = error;
                    return;
                  }
                  if (key == '__actionKey__') {
                    _actions[index]['key'] = value.toString();
                    _persistActiveSubcommandWorkflow();
                    return;
                  }
                  final payload = Map<String, dynamic>.from(
                    (_actions[index]['payload'] as Map?)
                            ?.cast<String, dynamic>() ??
                        const {},
                  );
                  payload[key] = value;
                  _actions[index]['payload'] = payload;
                  _persistActiveSubcommandWorkflow();
                });
              },
              onSuggestionSelected: (index, key, value) {
                _applyStateUpdate(() {
                  final payload = Map<String, dynamic>.from(
                    (_actions[index]['payload'] as Map?)
                            ?.cast<String, dynamic>() ??
                        const {},
                  );
                  payload[key] = value;
                  _actions[index]['payload'] = payload;
                });
              },
              onRemoveAction: (nodeId, index) {
                _applyStateUpdate(() {
                  _removeActionFromTree(_actions, nodeId);
                  _persistActiveSubcommandWorkflow();
                });
              },
              onAddActionAt:
                  (
                    type,
                    canvasPosition, {
                    connectFromNodeId,
                    connectFromPinId,
                    connectFromPinDirection,
                  }) {
                    _applyStateUpdate(() {
                      final uniqueId =
                          'action_${DateTime.now().microsecondsSinceEpoch}';
                      _blueprintNodePositions[uniqueId] = canvasPosition;
                      _actions.add(<String, dynamic>{
                        'id': uniqueId,
                        'type': type.name,
                        'enabled': true,
                        'key': uniqueId,
                        'depend_on': <String>[],
                        'error': {'mode': 'stop'},
                        'payload': Map<String, dynamic>.from(
                          type.defaultParameters,
                        ),
                      });

                      if (connectFromNodeId != null &&
                          connectFromPinId != null) {
                        if (connectFromPinDirection ==
                            BlueprintPinDirection.input) {
                          _connectWorkflowPins(
                            uniqueId,
                            'exec_out',
                            connectFromNodeId,
                            connectFromPinId,
                          );
                        } else {
                          _connectWorkflowPins(
                            connectFromNodeId,
                            connectFromPinId,
                            uniqueId,
                            'exec_in',
                          );
                        }
                      } else {
                        _persistActiveSubcommandWorkflow();
                      }
                    });
                  },
              onConnectPins: (fromNodeId, fromPinId, toNodeId, toPinId) {
                _applyStateUpdate(() {
                  _connectWorkflowPins(
                    fromNodeId,
                    fromPinId,
                    toNodeId,
                    toPinId,
                  );
                });
              },
              onDuplicateAction: (index) {
                _applyStateUpdate(() {
                  final copy = Map<String, dynamic>.from(
                    jsonDecode(jsonEncode(_actions[index])),
                  );
                  copy['id'] =
                      'action_${DateTime.now().microsecondsSinceEpoch}';
                  _actions.insert(index + 1, copy);
                  _persistActiveSubcommandWorkflow();
                });
              },
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860.0),
                child: canvasWidget,
              ),
            );

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
                  final uniqueId =
                      'action_${DateTime.now().microsecondsSinceEpoch}';
                  _actions.add(<String, dynamic>{
                    'id': uniqueId,
                    'type': type.name,
                    'enabled': true,
                    'key': uniqueId,
                    'depend_on': <String>[],
                    'error': {'mode': 'stop'},
                    'payload': Map<String, dynamic>.from(
                      type.defaultParameters,
                    ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Desktop View Switcher Header Bar ──
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Subcommand tabs or title if applicable
                      if (_subcommandWorkflows.isNotEmpty)
                        Expanded(
                          child: Text(
                            context.tr.actions_active_route(
                              _activeSubcommandRoute,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            isBlueprint
                                ? 'Graphe Blueprint 2D (Unreal Engine)'
                                : 'Vue Blocs Linéaires (Scratch)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                      // Segmented Button / Toggle
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'linear',
                            icon: Icon(Icons.view_agenda_outlined, size: 16),
                            label: Text(
                              'Blocs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment<String>(
                            value: 'blueprint',
                            icon: Icon(Icons.hub_outlined, size: 16),
                            label: Text(
                              'Blueprint',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        selected: {_desktopViewMode},
                        onSelectionChanged: (val) {
                          if (val.isNotEmpty) {
                            _applyStateUpdate(() {
                              _desktopViewMode = val.first;
                            });
                          }
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Main Canvas View ──
                Expanded(child: centerCanvas),
              ],
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
                      onSelected: (_) => _applyStateUpdate(() {
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
    final preview = isEmpty
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
                  builder: (_) => BdfdEditorPage(
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

  void _openBlockPalette() {
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
          try {
            _actions.add(newAction);
          } on UnsupportedError {
            _actions = List<Map<String, dynamic>>.from(_actions);
            _actions.add(newAction);
          }
          _persistActiveSubcommandWorkflow();
        });
      },
    );
  }

  List<Widget> _buildActionValidationBanners() {
    final issues = _collectWorkflowActionIssues();
    if (issues.isEmpty) return const <Widget>[];

    return issues
        .map(
          (issue) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue,
                      style: TextStyle(fontSize: 12, color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildActionsEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.grey.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr.cmd_block_editor_empty_title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr.cmd_block_editor_empty_hint,
              style: TextStyle(fontSize: 13, color: AppTheme.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openBlockPalette,
              icon: const Icon(Icons.add),
              label: Text(context.tr.cmd_block_editor_add_action),
            ),
            TextButton(
              onPressed: _openDocumentationCenter,
              child: Text(context.tr.docs_tab_bot_creator),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBlockButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: _openBlockPalette,
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

  Widget _buildDocumentationTipCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFr
                            ? "Besoin d'aide ou d'exemples ?"
                            : "Need help or command examples?",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFr
                            ? "Guides pas-à-pas, catalogue de variables et modèles prêts à l'emploi sur la doc officielle."
                            : "Step-by-step guides, variable catalog, and templates in the official documentation.",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _openDocumentationCenter,
                icon: const Icon(Icons.auto_stories_rounded, size: 16),
                label: const Text(
                  "bot-creator.fr/docs",
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCommandSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AnimatedBuilder(
          animation: _editorNotifier,
          builder: (context, _) => Scaffold(
            appBar: AppBar(
              backgroundColor: AppTheme.brandPrimary,
              title: Text(
                _commandName.trim().isNotEmpty
                    ? '${context.tr.edit_shell_command_settings} (/${_commandName.trim()})'
                    : context.tr.edit_shell_command_settings,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: context.tr.common_save,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
                      canEditCommandType:
                          !_isEditingExistingCommand || _isLocalOnlyCommand,
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
                            _editorMode =
                                _CommandCreatePageState._editorModeAdvanced;
                            _legacyModeEnabled = false;
                            _localOnlyCommand = false;
                          }
                          if (_commandType !=
                              ApplicationCommandType.chatInput) {
                            _subcommandWorkflows =
                                <String, Map<String, dynamic>>{};
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
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildFolderField(),
                      ),
                    ),
                    if (_supportsCommandOptions) ...[
                      const SizedBox(height: 14),
                      _buildCommandOptionsCard(),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _connectWorkflowPins(
    String fromNodeId,
    String fromPinId,
    String toNodeId,
    String toPinId,
  ) {
    // Un-sever any previously severed connections between these nodes
    _blueprintSeveredConnections.removeWhere(
      (id) =>
          (id.contains(fromNodeId) && id.contains(toNodeId)) ||
          (id.contains(toNodeId) && id.contains(fromNodeId)),
    );

    // 0. Handle connecting from Entry Point (__entry_point__)
    if (fromNodeId == '__entry_point__') {
      var toIndex = _actions.indexWhere((a) => a['id'] == toNodeId);
      if (toIndex == -1) {
        final extracted = _removeActionFromTree(_actions, toNodeId);
        if (extracted != null) {
          _actions.insert(0, extracted);
          _persistActiveSubcommandWorkflow();
          return;
        }
      } else {
        final item = _actions.removeAt(toIndex);
        _actions.insert(0, item);
        _persistActiveSubcommandWorkflow();
        return;
      }
    }

    // 1. Check if connecting from then_out, else_out, or elseif_out_k of an IF block
    if (fromPinId == 'then_out' ||
        fromPinId == 'else_out' ||
        fromPinId.startsWith('elseif_out_')) {
      Map<String, dynamic>? fromAction;
      final rootFromIdx = _actions.indexWhere((a) => a['id'] == fromNodeId);
      if (rootFromIdx != -1) {
        fromAction = _actions[rootFromIdx];
      } else {
        final nestedLoc = _findActionInBranchTrees(_actions, fromNodeId);
        if (nestedLoc != null) {
          fromAction = nestedLoc.targetAction;
        }
      }

      if (fromAction != null &&
          fromAction['type'] == BotCreatorActionType.ifBlock.name) {
        final toAction = _removeActionFromTree(_actions, toNodeId);
        if (toAction != null) {
          final payload = Map<String, dynamic>.from(
            (fromAction['payload'] as Map?)?.cast<String, dynamic>() ??
                const {},
          );

          if (fromPinId.startsWith('elseif_out_')) {
            final k =
                int.tryParse(fromPinId.replaceFirst('elseif_out_', '')) ?? 0;
            final elseIfList = List<Map<String, dynamic>>.from(
              (payload['elseIfConditions'] as List?)?.map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ) ??
                  const [],
            );
            if (k < elseIfList.length) {
              final branchActions = List<Map<String, dynamic>>.from(
                (elseIfList[k]['actions'] as List?)?.map(
                      (e) => Map<String, dynamic>.from(e as Map),
                    ) ??
                    const [],
              );
              branchActions.add(toAction);
              elseIfList[k]['actions'] = branchActions;
              payload['elseIfConditions'] = elseIfList;
              fromAction['payload'] = payload;
              _persistActiveSubcommandWorkflow();
              return;
            }
          } else {
            final branchKey = fromPinId == 'then_out'
                ? 'thenActions'
                : 'elseActions';
            final branchList = List<Map<String, dynamic>>.from(
              (payload[branchKey] as List?)?.map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ) ??
                  const [],
            );
            branchList.add(toAction);
            payload[branchKey] = branchList;
            fromAction['payload'] = payload;
            _persistActiveSubcommandWorkflow();
            return;
          }
        }
      }
    }

    // 2. Check if connecting from a node that is inside an IF branch
    final fromBranchLoc = _findActionInBranchTrees(_actions, fromNodeId);
    if (fromBranchLoc != null && fromPinId == 'exec_out') {
      final toAction = _removeActionFromTree(_actions, toNodeId);
      if (toAction != null) {
        final list = fromBranchLoc.branchList;
        list.insert(fromBranchLoc.indexInBranch + 1, toAction);
        fromBranchLoc.updateParentBranch(list);
        _persistActiveSubcommandWorkflow();
        return;
      }
    }

    // 3. Connect between root actions (standard sequential flow)
    final fromIndex = _actions.indexWhere((a) => a['id'] == fromNodeId);
    var toIndex = _actions.indexWhere((a) => a['id'] == toNodeId);
    if (toIndex == -1) {
      final extracted = _removeActionFromTree(_actions, toNodeId);
      if (extracted != null) {
        toIndex = _actions.length;
        _actions.add(extracted);
      }
    }

    if (fromIndex != -1 && toIndex != -1) {
      final item = _actions.removeAt(toIndex);
      final insertIndex = toIndex < fromIndex ? fromIndex : fromIndex + 1;
      _actions.insert(insertIndex.clamp(0, _actions.length), item);
      _persistActiveSubcommandWorkflow();
    }
  }
}

class _BlueprintBranchLocation {
  final Map<String, dynamic> parentAction;
  final String branchKey; // 'thenActions', 'elseActions', or 'elseIfConditions'
  final int? elseIfIndex;
  final List<Map<String, dynamic>> branchList;
  final int indexInBranch;
  final Map<String, dynamic> targetAction;

  _BlueprintBranchLocation({
    required this.parentAction,
    required this.branchKey,
    this.elseIfIndex,
    required this.branchList,
    required this.indexInBranch,
    required this.targetAction,
  });

  void updateParentBranch(List<Map<String, dynamic>> updatedList) {
    final payload = Map<String, dynamic>.from(
      (parentAction['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    if (branchKey == 'elseIfConditions' && elseIfIndex != null) {
      final elseIfList = (payload['elseIfConditions'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (elseIfIndex! >= 0 && elseIfIndex! < elseIfList.length) {
        final condition = Map<String, dynamic>.from(elseIfList[elseIfIndex!]);
        condition['actions'] = updatedList;
        elseIfList[elseIfIndex!] = condition;
        payload['elseIfConditions'] = elseIfList;
      }
    } else {
      payload[branchKey] = updatedList;
    }
    parentAction['payload'] = payload;
  }
}

_BlueprintBranchLocation? _findActionInBranchTrees(
  List<Map<String, dynamic>> actions,
  String targetId,
) {
  for (final action in actions) {
    final payload = (action['payload'] as Map?)?.cast<String, dynamic>();
    if (payload != null) {
      for (final branchKey in const ['thenActions', 'elseActions']) {
        final listRaw = payload[branchKey];
        if (listRaw is List) {
          final branchList = listRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          for (int i = 0; i < branchList.length; i++) {
            final item = branchList[i];
            if (item['id'] == targetId || item['key'] == targetId) {
              return _BlueprintBranchLocation(
                parentAction: action,
                branchKey: branchKey,
                branchList: branchList,
                indexInBranch: i,
                targetAction: item,
              );
            }
          }
          final nested = _findActionInBranchTrees(branchList, targetId);
          if (nested != null) return nested;
        }
      }

      final elseIfRaw = payload['elseIfConditions'];
      if (elseIfRaw is List) {
        final elseIfList = elseIfRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        for (int k = 0; k < elseIfList.length; k++) {
          final cond = elseIfList[k];
          final condActionsRaw = cond['actions'];
          if (condActionsRaw is List) {
            final branchList = condActionsRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            for (int i = 0; i < branchList.length; i++) {
              final item = branchList[i];
              if (item['id'] == targetId || item['key'] == targetId) {
                return _BlueprintBranchLocation(
                  parentAction: action,
                  branchKey: 'elseIfConditions',
                  elseIfIndex: k,
                  branchList: branchList,
                  indexInBranch: i,
                  targetAction: item,
                );
              }
            }
            final nested = _findActionInBranchTrees(branchList, targetId);
            if (nested != null) return nested;
          }
        }
      }
    }
  }
  return null;
}

Map<String, dynamic>? _removeActionFromTree(
  List<Map<String, dynamic>> rootActions,
  String actionId,
) {
  final rootIdx = rootActions.indexWhere(
    (a) => a['id'] == actionId || a['key'] == actionId,
  );
  if (rootIdx != -1) {
    return rootActions.removeAt(rootIdx);
  }

  final loc = _findActionInBranchTrees(rootActions, actionId);
  if (loc != null) {
    final list = loc.branchList;
    final removed = list.removeAt(loc.indexInBranch);
    loc.updateParentBranch(list);
    return removed;
  }

  return null;
}

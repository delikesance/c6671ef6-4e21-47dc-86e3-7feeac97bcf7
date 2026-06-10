import 'dart:convert';

import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bot_creator/features/bot_editor/presentation/screens/bdfd_editor_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/image_editor_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/http_request_editor_page.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator_shared/types/component.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflows.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/global.variables.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/logic/embed_normalization.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/component_v2_editor.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/modal_builder.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/normal_component_editor.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/permission_flags_field.dart';
import 'package:bot_creator_shared/utils/permission_flags.dart' show decomposePermissionBitmasks;
import 'package:bot_creator/core/widgets/variable_text_field.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/response_embeds_editor.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator_shared/utils/variable_catalog.dart' show variableDescription;
import 'package:bot_creator_shared/types/variable_suggestion.dart' as shared;
import 'action_types.dart';
import 'action_type_extension.dart';
import 'package:http/http.dart' as http;

enum _ActionCardMenuAction { moveUp, moveDown, remove }

class ActionCard extends StatelessWidget {
  static const List<String> _conditionOperators = <String>[
    'equals',
    'notEquals',
    'contains',
    'notContains',
    'startsWith',
    'endsWith',
    'greaterThan',
    'lessThan',
    'greaterOrEqual',
    'lessOrEqual',
    'isEmpty',
    'isNotEmpty',
    'matches',
  ];

  final ActionItem action;
  final int index;
  final int totalCount;
  final String actionKey;
  final List<VariableSuggestion> variableSuggestions;
  final List<AppEmoji>? emojiSuggestions;
  final int Function(String paramKey) fieldRefreshVersionOf;
  final Function(String key, dynamic value) onSuggestionSelected;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final Function(String key, dynamic value) onParameterChanged;
  final String? botIdForConfig;

  /// Opens a sub-action builder for nested blocks (IF/ELSE). Provided by the
  /// parent [ActionsBuilderPage]. When null, nested editing is disabled.
  final Future<List<Map<String, dynamic>>?> Function(
    List<Map<String, dynamic>> current,
    List<VariableSuggestion> suggestions,
    String blockName, {
    void Function(List<Map<String, dynamic>>)? onChanged,
  })?
  onEditNestedActions;
  final bool showHeader;
  final bool showPositionLabel;
  final bool showManagementControls;
  final bool collapseActionSettings;

  /// List of all actions in the current command/workflow (for Jump to action dropdown).
  /// Only actions AFTER the current one are shown.
  final List<ActionItem>? allActions;

  const ActionCard({
    super.key,
    required this.action,
    required this.index,
    required this.totalCount,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
    required this.onParameterChanged,
    required this.onSuggestionSelected,
    required this.fieldRefreshVersionOf,
    required this.actionKey,
    required this.variableSuggestions,
    this.emojiSuggestions,
    this.botIdForConfig,
    this.onEditNestedActions,
    this.showHeader = true,
    this.showPositionLabel = true,
    this.showManagementControls = true,
    this.collapseActionSettings = false,
    this.allActions,
  });

  Key _parameterInputKey(String paramKey) {
    final version = fieldRefreshVersionOf(paramKey);
    return ValueKey('param-input-${action.runtimeId}-$paramKey-v$version');
  }

  @override
  Widget build(BuildContext context) {
    final compactHeader = MediaQuery.of(context).size.width < 420;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                children: [
                  Icon(action.type.icon, color: AppTheme.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.type.displayName(context),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (showPositionLabel) ...[
                          const SizedBox(height: 2),
                          Text(
                            context.tr.action_position(index + 1, totalCount),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showManagementControls && compactHeader)
                    PopupMenuButton<_ActionCardMenuAction>(
                      tooltip: context.tr.action_options_tooltip,
                      onSelected: (value) async {
                        if (value == _ActionCardMenuAction.moveUp &&
                            onMoveUp != null) {
                          onMoveUp!();
                        } else if (value == _ActionCardMenuAction.moveDown &&
                            onMoveDown != null) {
                          onMoveDown!();
                        } else if (value == _ActionCardMenuAction.remove) {
                          await _confirmAndRemoveAction(context);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem<_ActionCardMenuAction>(
                              value: _ActionCardMenuAction.moveUp,
                              enabled: onMoveUp != null,
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_upward),
                                  SizedBox(width: 8),
                                  Text(context.tr.common_move_up),
                                ],
                              ),
                            ),
                            PopupMenuItem<_ActionCardMenuAction>(
                              value: _ActionCardMenuAction.moveDown,
                              enabled: onMoveDown != null,
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_downward),
                                  SizedBox(width: 8),
                                  Text(context.tr.common_move_down),
                                ],
                              ),
                            ),
                            PopupMenuItem<_ActionCardMenuAction>(
                              value: _ActionCardMenuAction.remove,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr.action_remove_menu,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    )
                  else if (showManagementControls) ...[
                    IconButton(
                      onPressed: onMoveUp,
                      tooltip: context.tr.common_move_up,
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      onPressed: onMoveDown,
                      tooltip: context.tr.common_move_down,
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      onPressed: () => _confirmAndRemoveAction(context),
                      tooltip: context.tr.action_remove_menu,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (showManagementControls &&
                  (index > 0 || index < totalCount - 1))
                Text(
                  context.tr.action_order_tip,
                  style: TextStyle(fontSize: 11, color: AppTheme.grey),
                ),
              if (showManagementControls &&
                  (index > 0 || index < totalCount - 1))
                const SizedBox(height: 8),
            ],
            if (collapseActionSettings)
              _buildActionSettingsPanel(context, collapsed: true)
            else ...[
              _buildActionKeyField(context),
              const SizedBox(height: 12),
              _buildActionStateRow(context),
              if (action.onErrorMode == 'jump') _buildJumpTargetField(context),
              if (action.onErrorMode == 'skip') _buildSkipCountField(context),
            ],
            const SizedBox(height: 16),
            if (action.type == BotCreatorActionType.httpRequest)
              ..._buildHttpRequestFields(context)
            else
              ...action.type.parameterDefinitions
                  .where(_shouldShowParameter)
                  .map((paramDef) {
                    final currentValue = action.parameters[paramDef.key];
                    return Padding(
                      key: ValueKey('param-padding-${action.runtimeId}-${paramDef.key}'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildParameterField(
                        context,
                        paramDef,
                        currentValue,
                      ),
                    );
                  }),
          ],
        ),
      ),
    );
  }

  Widget _buildJumpTargetField(BuildContext context) {
    if (allActions == null || allActions!.isEmpty) return const SizedBox.shrink();

    // Show only subsequent actions (after current)
    final items = <DropdownMenuItem<String>>[];
    var foundCurrent = false;
    for (final a in allActions!) {
      if (!foundCurrent) {
        if (a.runtimeId == action.runtimeId || a.id == action.id) {
          foundCurrent = true;
        }
        continue;
      }
      final label = a.actionKey.isNotEmpty ? a.actionKey : a.type.name;
      items.add(DropdownMenuItem(
        value: a.actionKey.isNotEmpty ? a.actionKey : a.runtimeId,
        child: Text(label, overflow: TextOverflow.ellipsis),
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: DropdownButtonFormField<String>(
        initialValue: action.jumpToActionId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Jump to',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: items,
        onChanged: (value) {
          if (value != null) onParameterChanged('__onErrorJumpTarget__', value);
        },
      ),
    );
  }

  Widget _buildSkipCountField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: TextFormField(
        initialValue: action.skipCount > 0 ? '${action.skipCount}' : '1',
        decoration: const InputDecoration(
          labelText: 'Skip count',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) => onParameterChanged('__onErrorSkipCount__', value),
      ),
    );
  }

  Widget _buildActionKeyField(BuildContext context) {
    return TextFormField(
      key: ValueKey('action-key-${action.runtimeId}'),
      initialValue: actionKey,
      decoration: InputDecoration(
        labelText: context.tr.action_key_field,
        border: const OutlineInputBorder(),
      ),
      onChanged: (newValue) => onParameterChanged('__actionKey__', newValue),
    );
  }

  Widget _buildActionStateRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr.common_enabled),
            value: action.enabled,
            onChanged: (value) => onParameterChanged('__enabled__', value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: action.onErrorMode,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr.action_on_error,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(
                value: 'stop',
                child: Text(context.tr.action_error_stop),
              ),
              DropdownMenuItem(
                value: 'continue',
                child: Text(context.tr.action_error_continue),
              ),
              DropdownMenuItem(
                value: 'jump',
                child: const Text('Jump to action'),
              ),
              DropdownMenuItem(
                value: 'skip',
                child: const Text('Skip N actions'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                onParameterChanged('__onErrorMode__', value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionSettingsPanel(
    BuildContext context, {
    required bool collapsed,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionKeyField(context),
        const SizedBox(height: 12),
        _buildActionStateRow(context),
      ],
    );
    if (!collapsed) {
      return content;
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(context.tr.action_advanced_settings),
      subtitle: Text(
        action.enabled
            ? context.tr.action_status_enabled
            : context.tr.action_status_disabled,
        style: TextStyle(fontSize: 12, color: AppTheme.grey),
      ),
      children: [const SizedBox(height: 8), content],
    );
  }

  Future<void> _confirmAndRemoveAction(BuildContext context) async {
    final shouldDelete = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.action_remove_title,
      content: context.tr.action_remove_confirm,
      confirmLabel: context.tr.common_remove,
      isDestructive: true,
    );

    if (shouldDelete) {
      onRemove();
    }
  }

  // Parses a JSON response and returns a flat list of JSON Path dot notations.
  // Includes the root path (`$`) so top-level arrays can be selected directly.
  List<String> _extractPaths(dynamic data, [String currentPath = '\$']) {
    List<String> paths =
        currentPath == r'$' ? <String>[currentPath] : <String>[];
    if (data is Map) {
      for (final key in data.keys) {
        final newPath = '$currentPath.$key';
        paths.add(newPath);
        paths.addAll(_extractPaths(data[key], newPath));
      }
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        final newPath = '$currentPath[$i]';
        paths.add(newPath);
        paths.addAll(_extractPaths(data[i], newPath));
      }
    }
    return paths;
  }

  void _showTestRequestModal(BuildContext context) {
    bool isLoading = true;
    int? statusCode;
    String? responseBody;
    String? errorMessage;
    List<String>? newPaths;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.codeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoading) {
              // Fire the request on first build frame using Futures
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  final urlStr = action.parameters['url']?.toString() ?? '';
                  if (urlStr.isEmpty) throw context.tr.action_provide_valid_url;

                  // Fallback for placeholders: the request might just fail, but we'll try to execute it as-is
                  final uri = Uri.parse(urlStr);
                  final method =
                      (action.parameters['method']?.toString() ?? 'GET')
                          .toUpperCase();

                  final rawHeadersMap = action.parameters['headers'];
                  final Map<String, String> requestHeaders = {};
                  if (rawHeadersMap is Map) {
                    for (final entry in rawHeadersMap.entries) {
                      requestHeaders[entry.key.toString()] =
                          entry.value?.toString() ?? '';
                    }
                  }

                  http.Response response;
                  if (method == 'POST') {
                    final dynamic bodyData =
                        action.parameters['bodyMode'] == 'json'
                            ? jsonEncode(action.parameters['bodyJson'])
                            : action.parameters['bodyText'];
                    if (action.parameters['bodyMode'] == 'json' &&
                        !requestHeaders.containsKey('Content-Type')) {
                      requestHeaders['Content-Type'] = 'application/json';
                    }
                    response = await http.post(
                      uri,
                      headers: requestHeaders,
                      body: bodyData,
                    );
                  } else if (method == 'PUT') {
                    final dynamic bodyData =
                        action.parameters['bodyMode'] == 'json'
                            ? jsonEncode(action.parameters['bodyJson'])
                            : action.parameters['bodyText'];
                    if (action.parameters['bodyMode'] == 'json' &&
                        !requestHeaders.containsKey('Content-Type')) {
                      requestHeaders['Content-Type'] = 'application/json';
                    }
                    response = await http.put(
                      uri,
                      headers: requestHeaders,
                      body: bodyData,
                    );
                  } else if (method == 'PATCH') {
                    final dynamic bodyData =
                        action.parameters['bodyMode'] == 'json'
                            ? jsonEncode(action.parameters['bodyJson'])
                            : action.parameters['bodyText'];
                    if (action.parameters['bodyMode'] == 'json' &&
                        !requestHeaders.containsKey('Content-Type')) {
                      requestHeaders['Content-Type'] = 'application/json';
                    }
                    response = await http.patch(
                      uri,
                      headers: requestHeaders,
                      body: bodyData,
                    );
                  } else if (method == 'DELETE') {
                    response = await http.delete(uri, headers: requestHeaders);
                  } else {
                    response = await http.get(uri, headers: requestHeaders);
                  }

                  statusCode = response.statusCode;
                  responseBody = response.body;

                  try {
                    final decodedJson = jsonDecode(responseBody!);
                    newPaths = _extractPaths(decodedJson);
                    // Update parameter so the extractJsonPath combobox actually uses the new paths
                    if (newPaths != null && newPaths!.isNotEmpty) {
                      onParameterChanged('_cachedJsonPaths', newPaths!);
                    }
                  } catch (_) {
                    // Not valid JSON to parse paths from, ignore.
                  }

                  setModalState(() => isLoading = false);
                } catch (e) {
                  setModalState(() {
                    isLoading = false;
                    errorMessage = e.toString();
                  });
                }
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr.action_http_test_title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.grey),
                      if (isLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (errorMessage != null)
                        Expanded(
                          child: SingleChildScrollView(
                            controller: controller,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                                border: Border.all(
                                  color: AppTheme.error.withValues(alpha: 0.5),
                                ),
                              ),
                              child: SelectableText(
                                errorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    statusCode != null &&
                                            statusCode! >= 200 &&
                                            statusCode! < 300
                                        ? AppTheme.success.withValues(
                                          alpha: 0.2,
                                        )
                                        : AppTheme.error.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXs,
                                ),
                                border: Border.all(
                                  color:
                                      statusCode != null &&
                                              statusCode! >= 200 &&
                                              statusCode! < 300
                                          ? AppTheme.success
                                          : AppTheme.error,
                                ),
                              ),
                              child: Text(
                                context.tr.action_http_status(
                                  statusCode ?? 200,
                                ),
                                style: TextStyle(
                                  color:
                                      statusCode != null &&
                                              statusCode! >= 200 &&
                                              statusCode! < 300
                                          ? AppTheme.successAccent
                                          : AppTheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (newPaths != null && newPaths!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXs,
                                  ),
                                  border: Border.all(color: AppTheme.info),
                                ),
                                child: Text(
                                  context.tr.action_http_paths_parsed(
                                    newPaths!.length,
                                  ),
                                  style: const TextStyle(
                                    color: AppTheme.info,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr.action_http_response_body,
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.codeSurfaceDarcula,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXs,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: SingleChildScrollView(
                              controller: controller,
                              child: HighlightView(
                                responseBody ?? '',
                                language: 'json',
                                theme: darculaTheme,
                                textStyle: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Widget> _buildHttpRequestFields(BuildContext context) {
    final defs = action.type.parameterDefinitions;
    ParameterDefinition? defFor(String key) => defs
        .cast<ParameterDefinition?>()
        .firstWhere((d) => d?.key == key, orElse: () => null);

    Widget fieldFor(String key) {
      final pd = defFor(key);
      if (pd == null) return const SizedBox.shrink();
      final currentValue = action.parameters[pd.key];
      return Padding(
        key: ValueKey('param-padding-${action.runtimeId}-${pd.key}'),
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildParameterField(context, pd, currentValue),
      );
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openHttpRequestEditor(context),
            icon: const Icon(Icons.http, size: 20),
            label: const Text('Edit Request'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
          title: Text(context.tr.action_store_results),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 4),
          children: [
            fieldFor('saveBodyToGlobalVar'),
            fieldFor('saveStatusToGlobalVar'),
          ],
        ),
      ),
      fieldFor('extractJsonPath'),
      Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showTestRequestModal(context),
            icon: const Icon(Icons.send_rounded),
            label: Text(context.tr.action_http_test_button),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.info.withValues(alpha: 0.2),
              foregroundColor: AppTheme.info,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    ];
  }

  void _openHttpRequestEditor(BuildContext context) {
    final headers = <String, String>{};
    final rawHeaders = action.parameters['headers'];
    if (rawHeaders is Map) {
      (rawHeaders).forEach((k, v) => headers[k.toString()] = v.toString());
    }

    final bodyJsonRaw = action.parameters['bodyJson'];
    final bodyJson = bodyJsonRaw is Map
        ? Map<String, dynamic>.from(bodyJsonRaw.cast<String, dynamic>())
        : <String, dynamic>{};

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => HttpRequestEditorPage(
          url: (action.parameters['url'] ?? '').toString(),
          method: (action.parameters['method'] ?? 'GET').toString(),
          headers: headers,
          bodyMode: (action.parameters['bodyMode'] ?? 'json').toString(),
          bodyText: (action.parameters['bodyText'] ?? '').toString(),
          bodyJson: bodyJson,
          onSaved: ({required String url, required String method, required Map<String, String> headers, required String bodyMode, required String bodyText, required Map<String, dynamic> bodyJson}) {
            onParameterChanged('url', url);
            onParameterChanged('method', method);
            onParameterChanged('headers', headers);
            onParameterChanged('bodyMode', bodyMode);
            onParameterChanged('bodyText', bodyText);
            onParameterChanged('bodyJson', bodyJson);
          },
        ),
      ),
    );
  }

  /// Whether a parameter should be rendered based on the current action state.
  /// Used to toggle between normal message fields and componentV2 fields.
  bool _shouldShowParameter(ParameterDefinition paramDef) {
    final visibleWhen = paramDef.visibleWhen;
    if (visibleWhen != null && visibleWhen.isNotEmpty) {
      for (final entry in visibleWhen.entries) {
        final current =
            (action.parameters[entry.key] ?? '')
                .toString()
                .trim()
                .toLowerCase();
        final allowed =
            entry.value
                .map((value) => value.trim().toLowerCase())
                .where((value) => value.isNotEmpty)
                .toSet();
        if (allowed.isNotEmpty && !allowed.contains(current)) {
          return false;
        }
      }
    }

    if (action.type == BotCreatorActionType.sendMessage) {
      final mode = (action.parameters['messageMode'] ?? 'normal').toString();
      if (mode == 'componentV2') {
        // In componentV2 mode, hide normal-message fields.
        if (paramDef.key == 'embeds' || paramDef.key == 'components') {
          return false;
        }
      } else {
        // In normal mode, hide componentV2 field.
        if (paramDef.key == 'componentV2') return false;
      }
    }
    return true;
  }

  /// Shows a dialog with a [VariableTextField] pre-populated with `((`
  /// so autocomplete suggestions appear immediately. On accept, inserts
  /// the selected variable into the parameter field.
  void _showVariablePickerDialog(BuildContext context, String paramKey, dynamic currentValue) {
    final vc = TextEditingController(
      text: (currentValue ?? '').toString(),
    );
    // If the current value is empty, pre-populate with (( for autocomplete.
    if (vc.text.isEmpty) {
      vc.text = '((';
      vc.selection = TextSelection.collapsed(offset: 2);
    }

    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Variable'),
        content: SizedBox(
          width: 420,
          child: VariableTextField(
            label: 'Expression',
            hint: 'Type (( to see variable suggestions',
            suggestions: variableSuggestions,
            controller: vc,
            onChanged: (_) {},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, vc.text.trim()),
            child: const Text('Insert'),
          ),
        ],
      ),
    ).then((result) {
      if (result != null && result.isNotEmpty) {
        onParameterChanged(paramKey, result);
      }
    });
  }

  /// Returns a compact [IconButton] for inserting variables via the
  /// [VariableTextField] dialog. Returns null when no suggestions are
  /// available.
  Widget? _buildVariableIcon(BuildContext context, String paramKey, dynamic currentValue) {
    if (variableSuggestions.isEmpty) return null;
    return IconButton(
      icon: const Icon(Icons.data_object, size: 18),
      tooltip: 'Insert variable',
      visualDensity: VisualDensity.compact,
      onPressed: () => _showVariablePickerDialog(context, paramKey, currentValue),
    );
  }

  bool _coerceBoolValue(dynamic value, bool fallback) {
    if (value is bool) {
      return value;
    }
    final normalized = (value ?? '').toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return fallback;
  }

  /// Coerces a value into a `Map<String, String>` for permissionFlags.
  ///
  /// Handles backward compatibility: if the payload has only 'allow'/'deny'
  /// integer bitmasks (old format), decomposes them into the permission
  /// states map. Otherwise returns the existing map or an empty one.
  Map<String, String> _coercePermissionFlagsValue(dynamic value) {
    if (value is Map<String, String>) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k, v.toString()));
    }
    // Backward compat: if action has allow/deny but no permissions map
    final actionParameters = action.parameters;
    final allowStr = (actionParameters['allow'] ?? '0').toString();
    final denyStr = (actionParameters['deny'] ?? '0').toString();
    final allow = int.tryParse(allowStr) ?? 0;
    final deny = int.tryParse(denyStr) ?? 0;
    if (allow != 0 || deny != 0) {
      return decomposePermissionBitmasks(allow, deny);
    }
    return const <String, String>{};
  }

  Widget _buildParameterField(
    BuildContext context,
    ParameterDefinition paramDef,
    dynamic currentValue,
  ) {
    switch (paramDef.type) {
      case ParameterType.boolean:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatParameterName(paramDef.key),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ?_buildVariableIcon(context, paramDef.key, currentValue),
                Switch(
                  value: _coerceBoolValue(
                    currentValue,
                    _coerceBoolValue(paramDef.defaultValue, false),
                  ),
                  onChanged:
                      (newValue) => onParameterChanged(paramDef.key, newValue),
                ),
              ],
            ),
          ],
        );

      case ParameterType.number:
        return _NumberParameterField(
          paramDef: paramDef,
          currentValue: currentValue,
          onParameterChanged: onParameterChanged,
          variableSuggestions: variableSuggestions,
          paramKey: paramDef.key,
          variableIcon: _buildVariableIcon(context, paramDef.key, currentValue),
        );

      case ParameterType.list:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatParameterName(paramDef.key),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed:
                      () => _showListEditor(context, paramDef, currentValue),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey),
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentValue is List && currentValue.isNotEmpty)
                    ...currentValue.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${entry.key + 1}. ${entry.value}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    })
                  else
                    Text(
                      context.tr.action_no_items_tap_edit,
                      style: TextStyle(color: AppTheme.grey, fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        );

      case ParameterType.elseIfBranches:
        return _buildElseIfBranchesField(context, paramDef, currentValue);

      case ParameterType.multiSelect:
        final options = paramDef.options ?? const <String>[];
        final rawValue = (currentValue ?? paramDef.defaultValue).toString();
        final selectedValue =
            options.contains(rawValue)
                ? rawValue
                : (options.isNotEmpty ? options.first : rawValue);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatParameterName(paramDef.key),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ?_buildVariableIcon(context, paramDef.key, currentValue),
              ],
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: selectedValue,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: _localizeHint(paramDef.hint),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items:
                  paramDef.options?.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
              onChanged:
                  (newValue) => onParameterChanged(paramDef.key, newValue),
            ),
            ..._buildVariableSuggestionsForParam(
              paramKey: paramDef.key,
              value: currentValue,
            ),
          ],
        );

      case ParameterType.duration:
        return VariableTextField(
          key: _parameterInputKey(paramDef.key),
          label: _formatParameterName(paramDef.key),
          initialValue: (currentValue ?? paramDef.defaultValue).toString(),
          hint: _localizeHint(paramDef.hint) ?? context.tr.action_hint_duration,
          suggestions: variableSuggestions,
          required: paramDef.required,
          onChanged: (newValue) => onParameterChanged(paramDef.key, newValue),
        );

      case ParameterType.url:
        return VariableTextField(
          key: _parameterInputKey(paramDef.key),
          label: _formatParameterName(paramDef.key),
          initialValue: (currentValue ?? paramDef.defaultValue).toString(),
          hint: _localizeHint(paramDef.hint) ?? 'https://example.com',
          suggestions: variableSuggestions,
          required: paramDef.required,
          onChanged: (newValue) => onParameterChanged(paramDef.key, newValue),
        );

      case ParameterType.userId:
      case ParameterType.channelId:
      case ParameterType.messageId:
      case ParameterType.roleId:
        return VariableTextField(
          key: _parameterInputKey(paramDef.key),
          label: _formatParameterName(paramDef.key),
          initialValue: (currentValue ?? paramDef.defaultValue).toString(),
          hint: _localizeHint(paramDef.hint) ??
              context.tr.action_hint_enter_type(paramDef.type.name),
          suggestions: variableSuggestions,
          required: paramDef.required,
          onChanged: (newValue) => onParameterChanged(paramDef.key, newValue),
        );

      case ParameterType.emoji:
        return VariableTextField(
          key: _parameterInputKey(paramDef.key),
          label: _formatParameterName(paramDef.key),
          initialValue: (currentValue ?? paramDef.defaultValue).toString(),
          hint: _localizeHint(paramDef.hint) ?? context.tr.action_hint_emoji,
          suggestions: variableSuggestions,
          required: paramDef.required,
          onChanged: (newValue) => onParameterChanged(paramDef.key, newValue),
        );

      case ParameterType.color:
        return VariableTextField(
          key: _parameterInputKey(paramDef.key),
          label: _formatParameterName(paramDef.key),
          initialValue: (currentValue ?? paramDef.defaultValue).toString(),
          hint: _localizeHint(paramDef.hint) ?? context.tr.action_hint_color,
          suggestions: variableSuggestions,
          required: paramDef.required,
          onChanged: (newValue) => onParameterChanged(paramDef.key, newValue),
        );

      case ParameterType.map:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatParameterName(paramDef.key),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ?_buildVariableIcon(context, paramDef.key, currentValue),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed:
                      () => _showMapEditor(context, paramDef, currentValue),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey),
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: _buildMapPreview(context, paramDef.key, currentValue),
            ),
          ],
        );

      case ParameterType.embeds:
        final embeds = normalizeResponseEmbedsPayload(currentValue);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatParameterName(paramDef.key),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ResponseEmbedsEditor(
              key: _parameterInputKey(paramDef.key),
              embeds: embeds,
              variableSuggestions: variableSuggestions,
              emojiSuggestions: emojiSuggestions,
              onChanged: (updated) {
                onParameterChanged(paramDef.key, updated);
              },
            ),
          ],
        );

      case ParameterType.nestedActions:
        final nestedList =
            currentValue is List
                ? currentValue
                    .whereType<Map>()
                    .map((m) => Map<String, dynamic>.from(m))
                    .toList()
                : <Map<String, dynamic>>[];
        final blockLabel =
            _localizeHint(paramDef.hint) ?? _formatParameterName(paramDef.key);
        final blockColor =
            paramDef.key == 'thenActions' ? AppTheme.success : AppTheme.warning;

        // ── Image Editor entry point ──────────────────────────────────────
        final isImageBlock =
            action.type == BotCreatorActionType.runtimeImageBlock;

        Future<void> openEditor() async {
          if (isImageBlock) {
            // Open the specialized image editor for canvas operations
            final result = await Navigator.push<List<Map<String, dynamic>>>(
              context,
              MaterialPageRoute<List<Map<String, dynamic>>>(
                builder: (_) => ImageEditorPage(
                  operations: nestedList,
                  variableSuggestions: variableSuggestions
                      .map((s) => shared.VariableSuggestion(
                            name: s.name,
                            kind: shared.VariableSuggestionKind.unknown,
                            category: s.category,
                            description: s.description,
                          ))
                      .toList(),
                ),
              ),
            );
            if (result != null) {
              onParameterChanged(paramDef.key, result);
            }
            return;
          }

          // Generic nested actions editor for all other action types
          if (onEditNestedActions == null) {
            return;
          }

          final result = await onEditNestedActions!(
            nestedList,
            variableSuggestions,
            '${action.type.displayName(context)} > $blockLabel',
            onChanged: (newActions) {
              onParameterChanged(paramDef.key, newActions);
            },
          );
          if (result != null) {
            onParameterChanged(paramDef.key, result);
          }
        }

        // ── Button label for image editor ─────────────────────────────────
        if (isImageBlock) {
          return _buildImageEditorEntry(
            context,
            nestedList: nestedList,
            onEdit: openEditor,
          );
        }

        return _buildNestedActionsEditor(
          nestedList: nestedList,
          blockLabel: blockLabel,
          blockColor: blockColor,
          icon:
              paramDef.key == 'thenActions'
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
          onEdit: openEditor,
        );

      case ParameterType.componentV2:
        final compDef =
            currentValue is Map<String, dynamic>
                ? ComponentV2Definition.fromJson(currentValue)
                : currentValue is Map
                ? ComponentV2Definition.fromJson(
                  Map<String, dynamic>.from(
                    currentValue.map((k, v) => MapEntry(k.toString(), v)),
                  ),
                )
                : ComponentV2Definition();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatParameterName(paramDef.key),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ComponentV2EditorWidget(
              key: _parameterInputKey(paramDef.key),
              definition: compDef,
              variableSuggestions: variableSuggestions,
              botIdForConfig: botIdForConfig,
              onChanged: (updated) {
                onParameterChanged(paramDef.key, updated.toJson());
              },
            ),
          ],
        );

      case ParameterType.normalComponents:
        final compDef =
            currentValue is Map<String, dynamic>
                ? ComponentV2Definition.fromJson(currentValue)
                : currentValue is Map
                ? ComponentV2Definition.fromJson(
                  Map<String, dynamic>.from(
                    currentValue.map((k, v) => MapEntry(k.toString(), v)),
                  ),
                )
                : ComponentV2Definition();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatParameterName(paramDef.key),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            NormalComponentEditorWidget(
              key: _parameterInputKey(paramDef.key),
              definition: compDef,
              variableSuggestions: variableSuggestions,
              botIdForConfig: botIdForConfig,
              onChanged: (updated) {
                onParameterChanged(paramDef.key, updated.toJson());
              },
            ),
          ],
        );

      case ParameterType.modalDefinition:
        final modalDef =
            currentValue is Map<String, dynamic>
                ? ModalDefinition.fromJson(currentValue)
                : currentValue is Map
                ? ModalDefinition.fromJson(
                  Map<String, dynamic>.from(
                    currentValue.map((k, v) => MapEntry(k.toString(), v)),
                  ),
                )
                : ModalDefinition();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatParameterName(paramDef.key),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ModalBuilderWidget(
              key: _parameterInputKey(paramDef.key),
              modal: modalDef,
              variableSuggestions: variableSuggestions,
              botIdForConfig: botIdForConfig,
              onChanged: (updated) {
                onParameterChanged(paramDef.key, updated.toJson());
              },
            ),
          ],
        );

      case ParameterType.bdfdScript:
        return _BdfdScriptParameterField(
          key: _parameterInputKey(paramDef.key),
          currentValue: (currentValue ?? paramDef.defaultValue).toString(),
          hint: _localizeHint(paramDef.hint),
          onChanged: (newValue) => onParameterChanged(paramDef.key, newValue),
        );

      case ParameterType.permissionFlags:
        return PermissionFlagsField(
          label: _formatParameterName(paramDef.key),
          currentValue: _coercePermissionFlagsValue(currentValue),
          hint: _localizeHint(paramDef.hint),
          onChanged: (newValue) =>
              onParameterChanged(paramDef.key, newValue),
        );

      default: // ParameterType.string and ParameterType.url and others
        if (paramDef.type == ParameterType.string &&
            paramDef.key == 'workflowName' &&
            botIdForConfig != null &&
            botIdForConfig!.trim().isNotEmpty) {
          return _WorkflowNameParameterField(
            key: _parameterInputKey(paramDef.key),
            label: _formatParameterName(paramDef.key),
            currentValue:
                (currentValue ?? paramDef.defaultValue).toString().trim(),
            hint:
                _localizeHint(paramDef.hint) ?? context.tr.action_hint_workflow,
            botId: botIdForConfig!,
            onChanged: (value) {
              onParameterChanged(paramDef.key, value);
            },
          );
        }
        if (botIdForConfig != null &&
            botIdForConfig!.trim().isNotEmpty &&
            _isVariableKeyParameter(action.type, paramDef.key)) {
          final currentScope = (action.parameters['scope'] ?? '').toString();
          final usesScopedKeys =
              action.type == BotCreatorActionType.setScopedVariable ||
              action.type == BotCreatorActionType.getScopedVariable ||
              action.type == BotCreatorActionType.removeScopedVariable ||
              action.type == BotCreatorActionType.renameScopedVariable ||
              action.type == BotCreatorActionType.listScopedVariableIndex ||
              action.type == BotCreatorActionType.appendArrayElement ||
              action.type == BotCreatorActionType.removeArrayElement;
 
          return _VariableKeyParameterField(
            key: _parameterInputKey(paramDef.key),
            label: _formatParameterName(paramDef.key),
            currentValue: (currentValue ?? paramDef.defaultValue).toString(),
            hint:
                _localizeHint(paramDef.hint) ??
                context.tr.action_hint_variable_key,
            botId: botIdForConfig!,
            scope: currentScope,
            scoped: usesScopedKeys,
            onChanged: (value) {
              onParameterChanged(paramDef.key, value.trim());
            },
          );
        }

        if (paramDef.key == 'extractJsonPath' &&
            action.type == BotCreatorActionType.httpRequest) {
          final cachedPaths =
              action.parameters['_cachedJsonPaths'] as List<dynamic>? ?? [];
          final stringPaths = cachedPaths.map((e) => e.toString()).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatParameterName(paramDef.key),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return stringPaths;
                  }
                  return stringPaths.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  onParameterChanged(paramDef.key, selection);
                },
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onEditingComplete,
                ) {
                  if (controller.text != (currentValue?.toString() ?? '') &&
                      controller.text.isEmpty) {
                    controller.text = currentValue?.toString() ?? '';
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: () {
                      onParameterChanged(paramDef.key, controller.text);
                      onEditingComplete();
                    },
                    onChanged: (val) {
                      onParameterChanged(paramDef.key, val);
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      hintText: _localizeHint(paramDef.hint),
                      suffixIcon:
                          stringPaths.isNotEmpty
                              ? const Icon(
                                Icons.arrow_drop_down,
                                color: AppTheme.info,
                              )
                              : null,
                    ),
                  );
                },
              ),
            ],
          );
        }

        if (action.type == BotCreatorActionType.respondWithAutocomplete &&
            const <String>{
              'items',
              'labelTemplate',
              'valueTemplate',
            }.contains(paramDef.key)) {
          return VariableTextField(
            key: _parameterInputKey(paramDef.key),
            label: _formatParameterName(paramDef.key),
            initialValue: (currentValue ?? paramDef.defaultValue).toString(),
            hint: _localizeHint(paramDef.hint),
            suggestions: variableSuggestions,
            onChanged: (newValue) => onParameterChanged(paramDef.key, newValue),
          );
        }

        return VariableTextField(
          key: _parameterInputKey(paramDef.key),
          label: _formatParameterName(paramDef.key),
          initialValue: (currentValue ?? paramDef.defaultValue).toString(),
          hint: _localizeHint(paramDef.hint),
          suggestions: variableSuggestions,
          required: paramDef.required,
          maxLines: paramDef.key.toLowerCase().contains('content') ? 3 : 1,
          onChanged: (newValue) => onParameterChanged(paramDef.key, newValue),
        );
    }
  }

  Widget _buildElseIfBranchesField(
    BuildContext context,
    ParameterDefinition paramDef,
    dynamic currentValue,
  ) {
    final branches = _normalizeElseIfBranches(currentValue);
    final label =
        _localizeHint(paramDef.hint) ?? _formatParameterName(paramDef.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                final updated = <Map<String, dynamic>>[
                  ...branches,
                  <String, dynamic>{
                    'condition.variable': '',
                    'condition.operator': 'equals',
                    'condition.value': '',
                    'actions': <Map<String, dynamic>>[],
                  },
                ];
                onParameterChanged(paramDef.key, updated);
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.tr.action_add_else_if),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (branches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withValues(alpha: 0.06),
              border: Border.all(
                color: AppTheme.premiumGold.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              context.tr.action_no_else_if_yet,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
          )
        else
          ...branches.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == branches.length - 1 ? 0 : 12,
              ),
              child: _buildElseIfBranchCard(
                context: context,
                paramKey: paramDef.key,
                branchIndex: entry.key,
                branch: entry.value,
                branches: branches,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildElseIfBranchCard({
    required BuildContext context,
    required String paramKey,
    required int branchIndex,
    required Map<String, dynamic> branch,
    required List<Map<String, dynamic>> branches,
  }) {
    final blockColor = AppTheme.premiumGold;
    final variableValue = (branch['condition.variable'] ?? '').toString();
    final operatorValue = (branch['condition.operator'] ?? 'equals').toString();
    final conditionValue = (branch['condition.value'] ?? '').toString();
    final nestedActions = _normalizeNestedActions(branch['actions']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blockColor.withValues(alpha: 0.05),
        border: Border.all(color: blockColor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route, color: blockColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ELSE IF ${branchIndex + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: blockColor,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.tr.action_remove_else_if,
                onPressed: () {
                  final updated = _cloneElseIfBranches(branches)
                    ..removeAt(branchIndex);
                  onParameterChanged(paramKey, updated);
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 760;
              final variableField = VariableTextField(
                key: ValueKey(
                  'elseif-${action.runtimeId}-$branchIndex-variable',
                ),
                label: context.tr.action_condition_variable,
                initialValue: variableValue,
                hint: context.tr.action_hint_condition_var,
                suggestions: variableSuggestions,
                onChanged: (value) {
                  final updated = _cloneElseIfBranches(branches);
                  updated[branchIndex]['condition.variable'] = value;
                  onParameterChanged(paramKey, updated);
                },
              );
              final operatorField = SizedBox(
                width: isCompact ? double.infinity : 170,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                    'elseif-${action.runtimeId}-$branchIndex-operator',
                  ),
                  initialValue:
                      _conditionOperators.contains(operatorValue)
                          ? operatorValue
                          : 'equals',
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr.common_operator,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _conditionOperators
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    final updated = _cloneElseIfBranches(branches);
                    updated[branchIndex]['condition.operator'] =
                        value ?? 'equals';
                    onParameterChanged(paramKey, updated);
                  },
                ),
              );
              final valueField = VariableTextField(
                key: ValueKey('elseif-${action.runtimeId}-$branchIndex-value'),
                label: context.tr.action_condition_value,
                initialValue: conditionValue,
                hint: context.tr.action_hint_condition_value,
                suggestions: variableSuggestions,
                onChanged: (value) {
                  final updated = _cloneElseIfBranches(branches);
                  updated[branchIndex]['condition.value'] = value;
                  onParameterChanged(paramKey, updated);
                },
              );

              if (isCompact) {
                return Column(
                  children: [
                    variableField,
                    const SizedBox(height: 8),
                    operatorField,
                    const SizedBox(height: 8),
                    valueField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: variableField),
                  const SizedBox(width: 8),
                  operatorField,
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: valueField),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _buildNestedActionsEditor(
            nestedList: nestedActions,
            blockLabel: context.tr.action_else_if_label(branchIndex + 1),
            blockColor: blockColor,
            icon: Icons.subdirectory_arrow_right,
            onEdit: () async {
              if (onEditNestedActions == null) {
                return;
              }

              final result = await onEditNestedActions!(
                nestedActions,
                variableSuggestions,
                '${action.type.displayName(context)} > ${context.tr.action_else_if_label(branchIndex + 1)}',
                onChanged: (newActions) {
                  final updated = _cloneElseIfBranches(branches);
                  updated[branchIndex]['actions'] = newActions;
                  onParameterChanged(paramKey, updated);
                },
              );
              if (result == null) {
                return;
              }

              final updated = _cloneElseIfBranches(branches);
              updated[branchIndex]['actions'] = result;
              onParameterChanged(paramKey, updated);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNestedActionsEditor({
    required List<Map<String, dynamic>> nestedList,
    required String blockLabel,
    required Color blockColor,
    required IconData icon,
    required Future<void> Function() onEdit,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        final editButton = FilledButton.tonalIcon(
          onPressed: onEditNestedActions == null ? null : onEdit,
          icon: const Icon(Icons.edit, size: 15),
          label: Text(
            isCompact
                ? context.tr.action_edit_nested(nestedList.length)
                : context.tr.action_edit_nested_parens(nestedList.length),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: blockColor.withValues(alpha: 0.16),
            foregroundColor: blockColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            onTap: onEditNestedActions == null ? null : onEdit,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Ink(
              decoration: BoxDecoration(
                border: Border.all(color: blockColor.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                color: blockColor.withValues(alpha: 0.05),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCompact) ...[
                      Row(
                        children: [
                          Icon(icon, color: blockColor, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              blockLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: blockColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: editButton),
                    ] else
                      Row(
                        children: [
                          Icon(icon, color: blockColor, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              blockLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: blockColor,
                              ),
                            ),
                          ),
                          editButton,
                        ],
                      ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        color: blockColor.withValues(alpha: 0.08),
                      ),
                      child:
                          nestedList.isEmpty
                              ? Text(
                                context.tr.action_no_actions_yet,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.grey,
                                ),
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...nestedList
                                      .take(3)
                                      .map(
                                        (a) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.arrow_right,
                                                size: 16,
                                                color: AppTheme.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  a['type']?.toString() ?? '?',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  if (nestedList.length > 3)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 20),
                                      child: Text(
                                        context.tr.action_and_more(
                                          nestedList.length - 3,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Renders the image editor entry point for [BotCreatorActionType.runtimeImageBlock].
  ///
  /// Shows a prominent button that opens the specialized [ImageEditorPage]
  /// instead of the generic nested actions editor.
  Widget _buildImageEditorEntry(
    BuildContext context, {
    required List<Map<String, dynamic>> nestedList,
    required Future<void> Function() onEdit,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    final hasOps = nestedList.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            color: color.withValues(alpha: 0.05),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_library_outlined,
                        color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasOps
                            ? context.tr.image_editor_edit_canvas(nestedList.length)
                            : context.tr.image_editor_create_canvas,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onEdit,
                      icon: Icon(
                        hasOps ? Icons.edit : Icons.add,
                        size: 16,
                      ),
                      label: Text(
                        hasOps
                            ? context.tr.image_editor_open
                            : context.tr.image_editor_create,
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: color.withValues(alpha: 0.16),
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
                if (hasOps) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                      color: color.withValues(alpha: 0.08),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...nestedList.take(3).map((a) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_right,
                                      size: 16,
                                      color: AppTheme.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      a['op']?.toString() ?? '?',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.grey),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (nestedList.length > 3)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 20),
                            child: Text(
                              context.tr.action_and_more(
                                  nestedList.length - 3),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _normalizeNestedActions(dynamic raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _normalizeElseIfBranches(dynamic raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map((entry) {
          final branch = Map<String, dynamic>.from(entry);
          return <String, dynamic>{
            'condition.variable':
                (branch['condition.variable'] ?? '').toString(),
            'condition.operator':
                (branch['condition.operator'] ?? 'equals').toString(),
            'condition.value': (branch['condition.value'] ?? '').toString(),
            'actions': _normalizeNestedActions(branch['actions']),
          };
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _cloneElseIfBranches(
    List<Map<String, dynamic>> branches,
  ) {
    return branches
        .map(
          (branch) => <String, dynamic>{
            'condition.variable':
                (branch['condition.variable'] ?? '').toString(),
            'condition.operator':
                (branch['condition.operator'] ?? 'equals').toString(),
            'condition.value': (branch['condition.value'] ?? '').toString(),
            'actions': _normalizeNestedActions(branch['actions']),
          },
        )
        .toList(growable: true);
  }

  List<Widget> _buildVariableSuggestionsForParam({
    required String paramKey,
    required dynamic value,
    bool isNumericField = false,
  }) {
    final rawValue = value?.toString() ?? '';
    final query = _extractPlaceholderQuery(rawValue);
    if (query == null) {
      return const [];
    }

    final normalizedQuery = query.trim().toLowerCase();
    final filteredByKind =
        isNumericField
            ? variableSuggestions.where(
              (item) => item.isNumeric || item.isUnknown,
            )
            : variableSuggestions;

    final dedupedByName = <String, VariableSuggestion>{};
    for (final item in filteredByKind) {
      final normalizedName = item.name.trim();
      if (normalizedName.isEmpty) {
        continue;
      }
      dedupedByName.putIfAbsent(
        normalizedName,
        () => VariableSuggestion(
          name: normalizedName,
          kind: item.kind,
          category: item.category,
        ),
      );
    }

    final suggestions =
        dedupedByName.values
            .where(
              (item) =>
                  normalizedQuery.isEmpty ||
                  item.name.toLowerCase().contains(normalizedQuery),
            )
            .toList();

    if (!isNumericField) {
      suggestions.addAll(
        _buildContextualArraySuggestions(
          normalizedQuery: normalizedQuery,
          baseSuggestions: dedupedByName.values,
        ),
      );
    }

    final uniqueSuggestions = <String, VariableSuggestion>{};
    for (final item in suggestions) {
      uniqueSuggestions[item.name] = item;
    }
    final topSuggestions = uniqueSuggestions.values.toList();

    if (topSuggestions.isEmpty) {
      return const [];
    }

    // Group by category for a mobile-friendly scrollable list with descriptions.
    final grouped = _groupByCategoryStatic(topSuggestions);
    final categoryOrder = _orderedCategoriesStatic(grouped.keys.toList());

    return [
      const SizedBox(height: 8),
      Text(
        isNumericField
            ? 'Dynamic numeric suggestions'
            : 'Available variables',
        style: TextStyle(fontSize: 11, color: AppTheme.grey),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 200,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            for (final cat in categoryOrder)
              if (grouped.containsKey(cat)) ...[
                _buildSuggestionCategoryHeaderStatic(cat, grouped[cat]!.length),
                ...grouped[cat]!.map((item) => _buildSuggestionListTileStatic(
                      item,
                      onTap: () {
                        final nextValue = _insertVariableInOpenPlaceholder(
                          rawValue,
                          item.name,
                        );
                        onSuggestionSelected(paramKey, nextValue);
                      },
                    )),
                const SizedBox(height: 4),
              ],
          ],
        ),
      ),
    ];
  }

  // ── Grouped suggestion helpers (static so they can be shared) ────────────

  static Map<shared.VariableCategory, List<VariableSuggestion>> _groupByCategoryStatic(
    List<VariableSuggestion> items,
  ) {
    final map = <shared.VariableCategory, List<VariableSuggestion>>{};
    for (final item in items) {
      final cat = item.category;
      map.putIfAbsent(cat, () => []).add(item);
    }
    return map;
  }

  static List<shared.VariableCategory> _orderedCategoriesStatic(
    List<shared.VariableCategory> cats,
  ) {
    const order = [
      shared.VariableCategory.context_,
      shared.VariableCategory.interaction,
      shared.VariableCategory.author,
      shared.VariableCategory.member,
      shared.VariableCategory.message,
      shared.VariableCategory.channel,
      shared.VariableCategory.guild,
      shared.VariableCategory.user,
      shared.VariableCategory.bot,
      shared.VariableCategory.temp,
      shared.VariableCategory.function_,
      shared.VariableCategory.other,
    ];
    cats.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return cats;
  }

  static Widget _buildSuggestionCategoryHeaderStatic(shared.VariableCategory cat, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
      child: Row(
        children: [
          Icon(_categoryIconStatic(cat), size: 14, color: AppTheme.grey),
          const SizedBox(width: 4),
          Text(
            _categoryLabel(cat),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text('$count', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
        ],
      ),
    );
  }

  static Widget _buildSuggestionListTileStatic(
    VariableSuggestion item, {
    required VoidCallback onTap,
  }) {
    final desc = variableDescription(item.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isNumeric
                      ? Colors.orange
                      : item.isUnknown
                          ? Colors.purple
                          : Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '((${item.name}))',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (desc != null)
                      Text(
                        desc,
                        style: TextStyle(fontSize: 11, color: AppTheme.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.grey),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _categoryIconStatic(shared.VariableCategory cat) {
    switch (cat) {
      case shared.VariableCategory.context_:
        return Icons.play_circle_outline;
      case shared.VariableCategory.interaction:
        return Icons.alternate_email;
      case shared.VariableCategory.bot:
        return Icons.smart_toy_outlined;
      case shared.VariableCategory.guild:
        return Icons.dns_outlined;
      case shared.VariableCategory.channel:
        return Icons.tag;
      case shared.VariableCategory.member:
        return Icons.person_outline;
      case shared.VariableCategory.message:
        return Icons.message_outlined;
      case shared.VariableCategory.author:
        return Icons.edit_note;
      case shared.VariableCategory.user:
        return Icons.account_circle_outlined;
      case shared.VariableCategory.temp:
        return Icons.schedule;
      case shared.VariableCategory.function_:
        return Icons.functions;
      case shared.VariableCategory.other:
        return Icons.more_horiz;
    }
  }

  static String _categoryLabel(shared.VariableCategory cat) {
    switch (cat) {
      case shared.VariableCategory.context_:
        return 'Context';
      case shared.VariableCategory.interaction:
        return 'Interaction';
      case shared.VariableCategory.bot:
        return 'Bot';
      case shared.VariableCategory.guild:
        return 'Server';
      case shared.VariableCategory.channel:
        return 'Channel';
      case shared.VariableCategory.member:
        return 'Member';
      case shared.VariableCategory.message:
        return 'Message';
      case shared.VariableCategory.author:
        return 'Author';
      case shared.VariableCategory.user:
        return 'User';
      case shared.VariableCategory.temp:
        return 'Temporary';
      case shared.VariableCategory.function_:
        return 'Functions';
      case shared.VariableCategory.other:
        return 'Other';
    }
  }

  List<VariableSuggestion> _buildContextualArraySuggestions({
    required String normalizedQuery,
    required Iterable<VariableSuggestion> baseSuggestions,
  }) {
    final query = normalizedQuery.trim();
    if (query.isEmpty) {
      return const [];
    }

    final baseQuery =
        query.endsWith('.') ? query.substring(0, query.length - 1) : query;
    if (baseQuery.isEmpty) {
      return const [];
    }

    final matchingBases =
        baseSuggestions
            .where((item) => item.name.toLowerCase() == baseQuery)
            .map((item) => item.name)
            .toSet();

    if (matchingBases.isEmpty) {
      return const [];
    }

    final generated = <VariableSuggestion>[];
    for (final base in matchingBases) {
      generated.add(
        VariableSuggestion(
          name: '$base.items',
          kind: VariableSuggestionKind.unknown,
        ),
      );
      generated.add(
        VariableSuggestion(
          name: '$base.display',
          kind: VariableSuggestionKind.nonNumeric,
        ),
      );
      generated.add(
        VariableSuggestion(
          name: '$base.count',
          kind: VariableSuggestionKind.numeric,
        ),
      );
      generated.add(
        VariableSuggestion(
          name: '$base.total',
          kind: VariableSuggestionKind.numeric,
        ),
      );
      for (var index = 0; index < 5; index++) {
        generated.add(
          VariableSuggestion(
            name: '$base.$index',
            kind: VariableSuggestionKind.unknown,
          ),
        );
      }
    }

    return generated;
  }

  String? _extractPlaceholderQuery(String input) {
    final start = input.lastIndexOf('((');
    if (start == -1) {
      return null;
    }

    final afterStart = input.substring(start + 2);
    if (afterStart.contains('))')) {
      return null;
    }

    final parts = afterStart.split('|');
    return parts.last.trimLeft();
  }

  String _insertVariableInOpenPlaceholder(String input, String variableName) {
    final start = input.lastIndexOf('((');
    if (start == -1) {
      return '(($variableName))';
    }

    final beforeStart = input.substring(0, start);
    final afterStart = input.substring(start + 2);

    if (afterStart.contains('))')) {
      return input;
    }

    final parts = afterStart.split('|');
    final prefixParts =
        parts.length > 1 ? parts.sublist(0, parts.length - 1) : <String>[];
    final previous = prefixParts
        .map((entry) => entry.trim())
        .where((e) => e.isNotEmpty);
    final merged = [...previous, variableName];
    final inner = merged.join(' | ');

    return '$beforeStart(($inner))';
  }

  // Méthodes utilitaires
  void _showListEditor(
    BuildContext context,
    ParameterDefinition paramDef,
    dynamic currentValue,
  ) {
    final maxHeight = MediaQuery.of(context).size.height * 0.55;
    final List<String> items = List<String>.from(currentValue ?? []);
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    context.tr.action_edit_param(
                      _formatParameterName(paramDef.key),
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: maxHeight,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  hintText: context.tr.action_add_new_item,
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    setDialogState(() {
                                      items.add(value.trim());
                                      controller.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (controller.text.trim().isNotEmpty) {
                                  setDialogState(() {
                                    items.add(controller.text.trim());
                                    controller.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(items[index]),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: AppTheme.error,
                                  ),
                                  onPressed:
                                      () => setDialogState(
                                        () => items.removeAt(index),
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(context.tr.common_cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onParameterChanged(paramDef.key, items);
                        Navigator.pop(dialogContext);
                      },
                      child: Text(context.tr.common_save),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showMapEditor(
    BuildContext context,
    ParameterDefinition paramDef,
    dynamic currentValue,
  ) {
    if (paramDef.key == 'headers') {
      _showHeadersEditor(context, paramDef, currentValue);
      return;
    }
    if (paramDef.key == 'arguments') {
      _showKeyValueEditor(context, paramDef, currentValue);
      return;
    }
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final rawMap =
        (currentValue is Map)
            ? Map<String, dynamic>.from(currentValue.cast<String, dynamic>())
            : <String, dynamic>{};

    // We start in edit mode but with validation checking
    showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController jsonController = TextEditingController(
          text: const JsonEncoder.withIndent('  ').convert(rawMap),
        );
        String? errorMessage;
        bool isPreviewMode = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void validateJson(String text) {
              if (text.trim().isEmpty) {
                setDialogState(() => errorMessage = null);
                return;
              }
              try {
                final decoded = jsonDecode(text);
                if (decoded is! Map) {
                  setDialogState(
                    () => errorMessage = context.tr.action_root_must_json,
                  );
                } else {
                  setDialogState(() => errorMessage = null);
                }
              } catch (e) {
                setDialogState(() => errorMessage = e.toString());
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr.action_edit_param(
                        _formatParameterName(paramDef.key),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(isPreviewMode ? Icons.code : Icons.visibility),
                    tooltip:
                        isPreviewMode
                            ? context.tr.action_edit_raw_json
                            : context.tr.action_preview_json,
                    onPressed: () {
                      if (!isPreviewMode) {
                        // Before switching to preview, format the JSON to ensure it's pretty
                        try {
                          final decoded = jsonDecode(
                            jsonController.text.trim(),
                          );
                          if (decoded is Map) {
                            jsonController.text = const JsonEncoder.withIndent(
                              '  ',
                            ).convert(decoded);
                          }
                        } catch (_) {}
                      }
                      setDialogState(() => isPreviewMode = !isPreviewMode);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_align_left),
                    tooltip: context.tr.action_format_json,
                    onPressed: () {
                      try {
                        final decoded = jsonDecode(jsonController.text.trim());
                        if (decoded is Map) {
                          setDialogState(() {
                            jsonController.text = const JsonEncoder.withIndent(
                              '  ',
                            ).convert(decoded);
                            errorMessage = null;
                          });
                        }
                      } catch (e) {
                        setDialogState(
                          () =>
                              errorMessage =
                                  context.tr.action_cannot_format_json,
                        );
                      }
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isPreviewMode)
                      Text(
                        context.tr.action_json_editor_hint,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child:
                          isPreviewMode
                              ? Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.grey),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXs,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  child: HighlightView(
                                    jsonController.text.trim().isEmpty
                                        ? '{}'
                                        : jsonController.text,
                                    language: 'json',
                                    theme: darculaTheme,
                                    padding: const EdgeInsets.all(12),
                                    textStyle: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                              : TextField(
                                controller: jsonController,
                                maxLines: null,
                                expands: true,
                                keyboardType: TextInputType.multiline,
                                onChanged: validateJson,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                  errorText: errorMessage,
                                ),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.tr.common_cancel),
                ),
                ElevatedButton(
                  onPressed:
                      errorMessage != null
                          ? null
                          : () {
                            try {
                              final text = jsonController.text.trim();
                              if (text.isEmpty) {
                                onParameterChanged(
                                  paramDef.key,
                                  <String, dynamic>{},
                                );
                                Navigator.pop(dialogContext);
                                return;
                              }
                              final decoded = jsonDecode(text);
                              if (decoded is! Map) {
                                setDialogState(
                                  () =>
                                      errorMessage =
                                          context.tr.action_root_must_json,
                                );
                                return;
                              }

                              onParameterChanged(
                                paramDef.key,
                                Map<String, dynamic>.from(decoded),
                              );
                              Navigator.pop(dialogContext);
                            } catch (error) {
                              setDialogState(
                                () => errorMessage = error.toString(),
                              );
                            }
                          },
                  child: Text(context.tr.common_save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMapPreview(
    BuildContext context,
    String key,
    dynamic currentValue,
  ) {
    if (currentValue is Map && currentValue.isNotEmpty) {
      if (key == 'headers' || key == 'arguments') {
        final entries = currentValue.entries.toList();
        final preview = entries
            .take(6)
            .map((entry) {
              final entryKey = entry.key.toString();
              final entryValue = entry.value?.toString() ?? '';
              return '$entryKey: $entryValue';
            })
            .join('\n');
        final extraCount = entries.length - 6;
        return SelectableText(
          extraCount > 0 ? '$preview\n… ($extraCount more)' : preview,
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
        );
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.codeSurfaceDarcula, // darcula background
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        ),
        padding: const EdgeInsets.all(8),
        child: HighlightView(
          const JsonEncoder.withIndent('  ').convert(currentValue),
          language: 'json',
          theme: darculaTheme,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      );
    }

    return Text(
      key == 'headers'
          ? context.tr.action_no_headers_tap_edit
          : key == 'arguments'
          ? context.tr.action_no_args_tap_edit
          : context.tr.action_no_properties_tap_edit,
      style: TextStyle(color: AppTheme.grey, fontSize: 14),
    );
  }

  void _showKeyValueEditor(
    BuildContext context,
    ParameterDefinition paramDef,
    dynamic currentValue,
  ) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final Map<String, dynamic> rawMap =
        (currentValue is Map)
            ? Map<String, dynamic>.from(currentValue.cast<String, dynamic>())
            : <String, dynamic>{};

    final List<Map<String, TextEditingController>> pairs =
        rawMap.entries
            .map(
              (entry) => {
                'keyController': TextEditingController(text: entry.key),
                'valueController': TextEditingController(
                  text: entry.value?.toString() ?? '',
                ),
              },
            )
            .toList();

    if (pairs.isEmpty) {
      pairs.add({
        'keyController': TextEditingController(),
        'valueController': TextEditingController(),
      });
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    context.tr.action_edit_param(
                      _formatParameterName(paramDef.key),
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.action_key_value_pairs,
                          style: TextStyle(fontSize: 12, color: AppTheme.grey),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: pairs.length,
                            itemBuilder: (context, index) {
                              final keyController =
                                  pairs[index]['keyController']!;
                              final valueController =
                                  pairs[index]['valueController']!;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: TextField(
                                        controller: keyController,
                                        decoration: InputDecoration(
                                          hintText: context.tr.common_key,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 6,
                                      child: TextField(
                                        controller: valueController,
                                        decoration: InputDecoration(
                                          hintText: context.tr.common_value,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        maxLines: null,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: AppTheme.error,
                                      ),
                                      onPressed: () {
                                        setDialogState(() {
                                          if (pairs.length > 1) {
                                            pairs.removeAt(index);
                                          } else {
                                            keyController.clear();
                                            valueController.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              pairs.add({
                                'keyController': TextEditingController(),
                                'valueController': TextEditingController(),
                              });
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: Text(context.tr.common_add_argument),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(context.tr.common_cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final result = <String, dynamic>{};
                        for (final pair in pairs) {
                          final key = pair['keyController']!.text.trim();
                          final value = pair['valueController']!.text.trim();
                          if (key.isNotEmpty) {
                            result[key] = value;
                          }
                        }
                        onParameterChanged(paramDef.key, result);
                        Navigator.pop(dialogContext);
                      },
                      child: Text(context.tr.common_save),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showHeadersEditor(
    BuildContext context,
    ParameterDefinition paramDef,
    dynamic currentValue,
  ) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final Map<String, dynamic> rawMap =
        (currentValue is Map)
            ? Map<String, dynamic>.from(currentValue.cast<String, dynamic>())
            : <String, dynamic>{};

    final List<Map<String, TextEditingController>> headers =
        rawMap.entries
            .map(
              (entry) => {
                'keyController': TextEditingController(text: entry.key),
                'valueController': TextEditingController(
                  text: entry.value?.toString() ?? '',
                ),
              },
            )
            .toList();

    if (headers.isEmpty) {
      headers.add({
        'keyController': TextEditingController(),
        'valueController': TextEditingController(),
      });
    }

    final pasteController = TextEditingController();

    const commonHeaders = [
      'Authorization',
      'Content-Type',
      'Accept',
      'User-Agent',
      'Cache-Control',
      'Host',
      'Connection',
      'Origin',
      'Referer',
      'X-Requested-With',
      'Access-Control-Allow-Origin',
    ];

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    context.tr.action_edit_param(
                      _formatParameterName(paramDef.key),
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.action_http_headers_title,
                          style: TextStyle(fontSize: 12, color: AppTheme.grey),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: headers.length,
                            itemBuilder: (context, index) {
                              final keyController =
                                  headers[index]['keyController']!;
                              final valueController =
                                  headers[index]['valueController']!;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Autocomplete<String>(
                                        optionsBuilder: (
                                          TextEditingValue textEditingValue,
                                        ) {
                                          if (textEditingValue.text == '') {
                                            return commonHeaders;
                                          }
                                          return commonHeaders.where((
                                            String option,
                                          ) {
                                            return option
                                                .toLowerCase()
                                                .contains(
                                                  textEditingValue.text
                                                      .toLowerCase(),
                                                );
                                          });
                                        },
                                        onSelected: (String selection) {
                                          keyController.text = selection;
                                        },
                                        fieldViewBuilder: (
                                          context,
                                          controller,
                                          focusNode,
                                          onEditingComplete,
                                        ) {
                                          // Sync initial value since Autocomplete creates its own controller initially empty
                                          if (controller.text !=
                                                  keyController.text &&
                                              controller.text.isEmpty) {
                                            controller.text =
                                                keyController.text;
                                          }
                                          controller.addListener(() {
                                            keyController.text =
                                                controller.text;
                                          });

                                          return TextField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            onEditingComplete:
                                                onEditingComplete,
                                            decoration: InputDecoration(
                                              hintText: context.tr.common_key,
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 6,
                                      child: TextField(
                                        controller: valueController,
                                        decoration: InputDecoration(
                                          hintText: context.tr.common_value,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        maxLines: null,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: AppTheme.error,
                                      ),
                                      onPressed: () {
                                        setDialogState(() {
                                          if (headers.length > 1) {
                                            headers.removeAt(index);
                                          } else {
                                            keyController.clear();
                                            valueController.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  headers.add({
                                    'keyController': TextEditingController(),
                                    'valueController': TextEditingController(),
                                  });
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: Text(context.tr.action_add_header),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  for (final entry in headers) {
                                    entry['keyController']!.clear();
                                    entry['valueController']!.clear();
                                  }
                                  // Keep at least one empty row
                                  if (headers.length > 1) {
                                    headers.removeRange(1, headers.length);
                                  }
                                });
                              },
                              child: Text(context.tr.action_clear_all),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        Text(
                          context.tr.action_bulk_import_hint,
                          style: TextStyle(fontSize: 12, color: AppTheme.grey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: pasteController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Authorization: Bearer ...\nAccept: application/json',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final raw = pasteController.text.trim();
                                if (raw.isEmpty) {
                                  return;
                                }
                                final lines = raw.split(RegExp(r'\r?\n'));
                                setDialogState(() {
                                  // Remove empty rows if any
                                  headers.removeWhere(
                                    (entry) =>
                                        entry['keyController']!.text
                                            .trim()
                                            .isEmpty &&
                                        entry['valueController']!.text
                                            .trim()
                                            .isEmpty,
                                  );

                                  for (final line in lines) {
                                    final separatorIndex = line.indexOf(':');
                                    if (separatorIndex <= 0) {
                                      continue;
                                    }
                                    final key =
                                        line
                                            .substring(0, separatorIndex)
                                            .trim();
                                    final value =
                                        line
                                            .substring(separatorIndex + 1)
                                            .trim();
                                    if (key.isEmpty) {
                                      continue;
                                    }
                                    headers.add({
                                      'keyController': TextEditingController(
                                        text: key,
                                      ),
                                      'valueController': TextEditingController(
                                        text: value,
                                      ),
                                    });
                                  }
                                  pasteController.clear();

                                  // Add empty row if everything is clear
                                  if (headers.isEmpty) {
                                    headers.add({
                                      'keyController': TextEditingController(),
                                      'valueController':
                                          TextEditingController(),
                                    });
                                  }
                                });
                              },
                              child: Text(context.tr.common_import),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(context.tr.common_cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final Map<String, dynamic> result = {};
                        for (final entry in headers) {
                          final key = entry['keyController']!.text.trim();
                          final value = entry['valueController']!.text.trim();
                          if (key.isNotEmpty) {
                            result[key] = value;
                          }
                        }
                        onParameterChanged(paramDef.key, result);
                        Navigator.pop(dialogContext);
                      },
                      child: Text(context.tr.common_save),
                    ),
                  ],
                ),
          ),
    );
  }

  String _formatParameterName(String key) {
    if (action.type == BotCreatorActionType.calculate) {
      final operation =
          (action.parameters['operation'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
      final isRandom = operation == 'random' || operation == 'randomfloat';
      if (isRandom && key == 'operandA') {
        return 'Minimum';
      }
      if (isRandom && key == 'operandB') {
        return 'Maximum';
      }
    }

    if (action.type == BotCreatorActionType.cooldown) {
      if (key == 'time') return 'Duration';
      if (key == 'error') return 'Error Message';
    }

    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String? _localizeHint(String? hint) {
    final raw = (hint ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }
    if (WidgetsBinding.instance.platformDispatcher.locale.languageCode !=
        'fr') {
      return raw;
    }

    const direct = <String, String>{
      'Math operation to perform': 'Opération mathématique à effectuer',
      'Comparison operator': 'Opérateur de comparaison',
      'Message content': 'Contenu du message',
      'Audit log reason': 'Raison du journal d\'audit',
      'Global variable key': 'Clé de variable globale',
      'Scoped variable key (bc_ optional)':
          'Clé de variable scopée (bc_ optionnel)',
      'Saved workflow name to execute': 'Nom du workflow enregistré à exécuter',
      'Optional entry point override (defaults to workflow entry)':
          'Surcharge optionnelle du point d\'entrée (par défaut: entrée du workflow)',
      'Optional key/value arguments for workflow call':
          'Arguments clé/valeur optionnels pour l\'appel du workflow',
      'Optional key/value arguments injected as ((arg.key))':
          'Arguments clé/valeur optionnels injectés comme ((arg.key))',
      'Only visible to command author':
          'Visible uniquement pour l\'auteur de la commande',
      'Modal dialog definition': 'Définition du modal',
      'Body format': 'Format du body',
      'Custom headers': 'En-têtes personnalisés',
      'Raw text body': 'Body texte brut',
      'JSON body builder map': 'Map du body JSON',
      'Request URL (supports placeholders ((...)))':
          'URL de requête (supporte les placeholders ((...)))',
      'Value type: string or number': 'Type de valeur : string ou number',
      'Numeric value when valueType=number':
          'Valeur numérique quand valueType=number',
      'String value (supports placeholders ((...)))':
          'Valeur texte (supporte les placeholders ((...)))',
      'Runtime variable alias (ex: token)':
          'Alias de variable runtime (ex: token)',
      'Runtime variable alias (ex: guild.score)':
          'Alias de variable runtime (ex: guild.score)',
      'Listener TTL in minutes (max 60)': 'TTL du listener en minutes (max 60)',
      'Remove listener after first click':
          'Supprimer le listener après le premier clic',
      'Button customId to listen for (supports ((variables)))':
          'customId du bouton à écouter (supporte ((variables)))',
      'Modal customId to listen for': 'customId du modal à écouter',
      'Workflow to run when button is clicked':
          'Workflow à exécuter au clic sur le bouton',
      'Workflow to run when modal is submitted':
          'Workflow à exécuter à la soumission du modal',
      'Optional text above the components':
          'Texte optionnel au-dessus des composants',
      'Component V2 layout builder': 'Constructeur de layout Component V2',
      'Enable or disable guild onboarding':
          'Activer ou désactiver l\'onboarding serveur',
      'Duration (e.g. 10s, 1m)': 'Durée (ex: 10s, 1m)',
      'Duration (e.g. 5s, 1m)': 'Durée (ex: 5s, 1m)',
      'Custom error message (supports %time%)':
          'Message d\'erreur personnalisé (supporte %time%)',
      'User to send DM to': 'Utilisateur à qui envoyer le MP',
      'User whose nickname to change':
          'Utilisateur dont le surnom doit changer',
      'New nickname': 'Nouveau surnom',
      'Channel to set slowmode for': 'Salon où activer le mode lent',
      'Slowmode duration (e.g. 5s, 0 to disable)':
          'Durée du mode lent (ex: 5s, 0 pour désactiver)',
      'List of choices (separated by ;)': 'Liste de choix (séparés par ;)',
      'Variable name to store the result':
          'Nom de la variable pour stocker le résultat',
      'Optional: target channel (uses current channel if empty)':
          'Optionnel : salon cible (utilise le salon actuel si vide)',
      'Number of messages to delete': 'Nombre de messages à supprimer',
      'Optional: only delete messages from this user':
          'Optionnel : supprimer uniquement les messages de cet utilisateur',
      'Optional: delete messages posted before the given message ID':
          'Optionnel : supprimer les messages postés avant l\'ID donné',
      'Reason for deletion': 'Raison de la suppression',
      'Only delete bot messages': 'Supprimer uniquement les messages de bots',
      'Only delete user messages':
          'Supprimer uniquement les messages d\'utilisateurs',
      'Channel to remove': 'Salon à supprimer',
      'Channel name': 'Nom du salon',
      'Channel type': 'Type de salon',
      'Parent category': 'Catégorie parente',
      'Channel topic/description': 'Sujet/description du salon',
      'Age-restricted channel': 'Salon réservé aux adultes (NSFW)',
      'Slowmode duration': 'Durée du mode lent',
      'New channel name': 'Nouveau nom du salon',
      'New channel topic/description': 'Nouveau sujet/description du salon',
      'Toggle NSFW status': 'Basculer le statut NSFW',
      'New slowmode duration': 'Nouvelle durée du mode lent',
      'Send to a channel or directly to a user (DM)':
          'Envoyer dans un salon ou directement à un utilisateur (MP)',
      'Target channel (required when targetType=channel; leave empty for current channel)':
          'Salon cible (requis si targetType=channel ; laisser vide pour le salon actuel)',
      'User to DM (required when targetType=user)':
          'Utilisateur à qui envoyer le MP (requis si targetType=user)',
      'Normal message (embeds, buttons/selects) or Component V2':
          'Message normal (embeds, boutons) ou Composant V2',
      'Optional embeds (same format as normal command reply)':
          'Embeds optionnels (même format que la réponse de commande)',
      'Optional message components (buttons/select menus only)':
          'Composants de message optionnels (boutons/menus de sélection)',
      'Component V2 interactive elements': 'Éléments interactifs Composant V2',
      'Users/roles to mention': 'Utilisateurs/rôles à mentionner',
      'Text-to-speech': 'Synthèse vocale (TTS)',
      'Channel containing message': 'Salon contenant le message',
      'Message to edit': 'Message à modifier',
      'Edit standard message or Component V2 layout':
          'Modifier un message standard ou un layout Composant V2',
      'New message content': 'Nouveau contenu du message',
      'Optional embeds to replace the current message embeds':
          'Embeds optionnels pour remplacer les embeds actuels',
      'Remove all embeds from the message':
          'Supprimer tous les embeds du message',
      'Edit Component V2 interactive elements (optional)':
          'Modifier les éléments interactifs Composant V2 (optionnel)',
    };

    final directValue = direct[raw];
    if (directValue != null) {
      return directValue;
    }

    var text = raw;
    const replacements = <MapEntry<String, String>>[
      MapEntry('Optional:', 'Optionnel :'),
      MapEntry('required', 'requis'),
      MapEntry('Channel', 'Salon'),
      MapEntry('channel', 'salon'),
      MapEntry('User', 'Utilisateur'),
      MapEntry('user', 'utilisateur'),
      MapEntry('Role', 'Rôle'),
      MapEntry('role', 'rôle'),
      MapEntry('reason', 'raison'),
      MapEntry('Reason', 'Raison'),
      MapEntry('Delete', 'Supprimer'),
      MapEntry('delete', 'supprimer'),
      MapEntry('Create', 'Créer'),
      MapEntry('create', 'créer'),
      MapEntry('Update', 'Mettre à jour'),
      MapEntry('update', 'mettre à jour'),
      MapEntry('New ', 'Nouveau '),
      MapEntry('new ', 'nouveau '),
      MapEntry('supports placeholders', 'supporte les placeholders'),
      MapEntry('supports ((variables))', 'supporte ((variables))'),
      MapEntry('leave empty', 'laisser vide'),
      MapEntry('current channel', 'salon actuel'),
      MapEntry('Max ', 'Max '),
      MapEntry('max ', 'max '),
      MapEntry('Min ', 'Min '),
      MapEntry('min ', 'min '),
    ];

    for (final replacement in replacements) {
      text = text.replaceAll(replacement.key, replacement.value);
    }
    return text;
  }

  bool _isVariableKeyParameter(BotCreatorActionType type, String paramKey) {
    switch (type) {
      case BotCreatorActionType.setGlobalVariable:
      case BotCreatorActionType.getGlobalVariable:
      case BotCreatorActionType.removeGlobalVariable:
        return paramKey == 'key';
      case BotCreatorActionType.setScopedVariable:
      case BotCreatorActionType.getScopedVariable:
      case BotCreatorActionType.removeScopedVariable:
      case BotCreatorActionType.listScopedVariableIndex:
      case BotCreatorActionType.appendArrayElement:
      case BotCreatorActionType.removeArrayElement:
        return paramKey == 'key';
      case BotCreatorActionType.renameScopedVariable:
        return paramKey == 'oldKey' || paramKey == 'newKey';
      default:
        return false;
    }
  }
}

class _VariableKeyParameterField extends StatefulWidget {
  final String label;
  final String currentValue;
  final String hint;
  final String botId;
  final String scope;
  final bool scoped;
  final ValueChanged<String> onChanged;

  const _VariableKeyParameterField({
    super.key,
    required this.label,
    required this.currentValue,
    required this.hint,
    required this.botId,
    required this.scope,
    required this.scoped,
    required this.onChanged,
  });

  @override
  State<_VariableKeyParameterField> createState() =>
      _VariableKeyParameterFieldState();
}

class _VariableKeyParameterFieldState
    extends State<_VariableKeyParameterField> {
  List<String> _keys = const [];
  bool _loading = false;

  String _toScopedReferenceKey(String rawKey) {
    final key = rawKey.trim();
    if (key.isEmpty) {
      return key;
    }
    if (key.startsWith('bc_') && key.length > 3) {
      return key.substring(3);
    }
    return key;
  }

  String _toLegacyScopedReferenceKey(String rawKey) {
    final key = _toScopedReferenceKey(rawKey);
    if (key.isEmpty) {
      return key;
    }
    return 'bc_$key';
  }

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  @override
  void didUpdateWidget(covariant _VariableKeyParameterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.botId != widget.botId ||
        oldWidget.scoped != widget.scoped ||
        oldWidget.scope != widget.scope) {
      _loadKeys();
    }
  }

  Future<void> _loadKeys() async {
    setState(() {
      _loading = true;
    });

    List<String> keys = const [];
    try {
      final remoteRuntime = await resolveRemoteRuntime(
        supportsManagerRuntime: !kIsWeb,
        botId: widget.botId,
        getTimeout: const Duration(seconds: 4),
      );

      if (widget.scoped) {
        List<Map<String, dynamic>> defs;
        if (remoteRuntime.isManager && remoteRuntime.client is MainApiClient) {
          defs = await (remoteRuntime.client as MainApiClient)
              .getScopedVariableDefinitions(widget.botId);
        } else if (remoteRuntime.isRunner &&
            remoteRuntime.client is RunnerClient) {
          defs = await (remoteRuntime.client as RunnerClient)
              .getScopedVariableDefinitions(widget.botId);
        } else {
          defs = await appManager.getScopedVariableDefinitions(widget.botId);
        }

        final scope = widget.scope.trim();
        keys = defs
            .where(
              (def) =>
                  scope.isEmpty ||
                  (def['scope'] ?? '').toString().trim() == scope,
            )
            .map((def) => (def['key'] ?? '').toString().trim())
            .where((k) => k.isNotEmpty)
            .toSet()
            .toList(growable: false);
      } else {
        Map<String, dynamic> globals;
        if (remoteRuntime.isManager && remoteRuntime.client is MainApiClient) {
          globals = await (remoteRuntime.client as MainApiClient)
              .getGlobalVariables(widget.botId);
        } else if (remoteRuntime.isRunner &&
            remoteRuntime.client is RunnerClient) {
          globals = await (remoteRuntime.client as RunnerClient)
              .getGlobalVariables(widget.botId);
        } else {
          globals = await appManager.getGlobalVariables(widget.botId);
        }

        keys = globals.keys
            .map((k) => k.toString().trim())
            .where((k) => k.isNotEmpty)
            .toSet()
            .toList(growable: false);
      }
    } catch (e) {
      // Fallback to local SQLite if remote loading fails/times out
      if (widget.scoped) {
        final defs = await appManager.getScopedVariableDefinitions(
          widget.botId,
        );
        final scope = widget.scope.trim();
        keys = defs
            .where(
              (def) =>
                  scope.isEmpty ||
                  (def['scope'] ?? '').toString().trim() == scope,
            )
            .map((def) => (def['key'] ?? '').toString().trim())
            .where((k) => k.isNotEmpty)
            .toSet()
            .toList(growable: false);
      } else {
        final globals = await appManager.getGlobalVariables(widget.botId);
        keys = globals.keys
            .map((k) => k.toString().trim())
            .where((k) => k.isNotEmpty)
            .toSet()
            .toList(growable: false);
      }
    }

    keys = keys.toList()..sort();
    if (!mounted) {
      return;
    }
    setState(() {
      _keys = keys;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trimmedCurrent = widget.currentValue.trim();
    final items = <String>{
      ..._keys,
      if (trimmedCurrent.isNotEmpty) trimmedCurrent,
    }.toList(growable: false)..sort();

    final selectedValue =
        trimmedCurrent.isNotEmpty && items.contains(trimmedCurrent)
            ? trimmedCurrent
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            Text(
              context.tr.action_static_badge,
              style: const TextStyle(fontSize: 11, color: AppTheme.warning),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'variableKeyDropdown_${widget.scoped}_${widget.scope}_${widget.currentValue}_${items.length}',
                ),
                initialValue: selectedValue,
                isExpanded: true,
                items: items
                    .map((key) {
                      final canonicalRef = _toScopedReferenceKey(key);
                      final legacyRef = _toLegacyScopedReferenceKey(key);
                      final scopedLabel =
                          canonicalRef == legacyRef
                              ? '$key  (ref: $canonicalRef)'
                              : '$key  (ref: $canonicalRef, legacy: $legacyRef)';
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(
                          widget.scoped ? scopedLabel : key,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    })
                    .toList(growable: false),
                onChanged:
                    _loading
                        ? null
                        : (value) {
                          widget.onChanged((value ?? '').trim());
                        },
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText:
                      _loading
                          ? context.tr.action_loading_keys
                          : (items.isEmpty
                              ? context.tr.action_no_saved_keys
                              : (widget.scoped
                                  ? context.tr.action_select_stored_key
                                  : context.tr.action_select_saved_key)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: context.tr.action_refresh_keys,
              onPressed: _loading ? null : _loadKeys,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GlobalVariablesPage(botId: widget.botId),
              ),
            );
            await _loadKeys();
          },
          icon: const Icon(Icons.storage),
          label: Text(context.tr.action_manage_variable_keys),
        ),
      ],
    );
  }
}

class _WorkflowNameParameterField extends StatefulWidget {
  final String label;
  final String currentValue;
  final String hint;
  final String botId;
  final ValueChanged<String> onChanged;

  const _WorkflowNameParameterField({
    super.key,
    required this.label,
    required this.currentValue,
    required this.hint,
    required this.botId,
    required this.onChanged,
  });

  @override
  State<_WorkflowNameParameterField> createState() =>
      _WorkflowNameParameterFieldState();
}

class _WorkflowNameParameterFieldState
    extends State<_WorkflowNameParameterField> {
  List<String> _workflowNames = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkflows();
  }

  @override
  void didUpdateWidget(covariant _WorkflowNameParameterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.botId != widget.botId) {
      _loadWorkflows();
    }
  }

  Future<void> _loadWorkflows() async {
    setState(() {
      _loading = true;
    });
    final workflows = await appManager.getWorkflows(widget.botId);
    if (!mounted) {
      return;
    }
    final names = workflows
      .map((workflow) => (workflow['name'] ?? '').toString().trim())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false)..sort();
    setState(() {
      _workflowNames = names;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trimmedCurrent = widget.currentValue.trim();
    final items = <String>{
      ..._workflowNames,
      if (trimmedCurrent.isNotEmpty) trimmedCurrent,
    }.toList(growable: false)..sort();

    final dropdownValue =
        trimmedCurrent.isNotEmpty && items.contains(trimmedCurrent)
            ? trimmedCurrent
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'workflowNameDropdown_${widget.currentValue}_${items.length}',
                ),
                initialValue: dropdownValue,
                isExpanded: true,
                items:
                    items
                        .map(
                          (name) => DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          ),
                        )
                        .toList(),
                onChanged:
                    _loading
                        ? null
                        : (value) {
                          widget.onChanged((value ?? '').trim());
                        },
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText:
                      _loading
                          ? context.tr.autocomplete_loading
                          : (_workflowNames.isEmpty
                              ? context.tr.autocomplete_no_workflows
                              : context.tr.autocomplete_select_workflow),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: context.tr.common_refresh_workflows,
              onPressed: _loading ? null : _loadWorkflows,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('workflowNameInput_${widget.currentValue}'),
          initialValue: trimmedCurrent,
          decoration: InputDecoration(
            labelText: context.tr.autocomplete_type_name,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) => widget.onChanged(value.trim()),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkflowsPage(botId: widget.botId),
              ),
            );
            await _loadWorkflows();
          },
          icon: const Icon(Icons.account_tree),
          label: Text(context.tr.common_manage_workflows),
        ),
      ],
    );
  }
}

// Widget stateful pour les champs numériques avec clamping en temps réel
class _NumberParameterField extends StatefulWidget {
  final ParameterDefinition paramDef;
  final dynamic currentValue;
  final Function(String key, dynamic value) onParameterChanged;
  final List<VariableSuggestion> variableSuggestions;
  final String paramKey;
  final Widget? variableIcon;

  const _NumberParameterField({
    required this.paramDef,
    required this.currentValue,
    required this.onParameterChanged,
    required this.variableSuggestions,
    required this.paramKey,
    this.variableIcon,
  });

  @override
  State<_NumberParameterField> createState() => _NumberParameterFieldState();
}

class _NumberParameterFieldState extends State<_NumberParameterField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentValue ?? widget.paramDef.defaultValue).toString(),
    );
  }

  @override
  void didUpdateWidget(_NumberParameterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue) {
      _controller.text =
          (widget.currentValue ?? widget.paramDef.defaultValue).toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _getErrorMessage() {
    final numValue = int.tryParse(_controller.text);
    if (numValue != null) {
      if (widget.paramDef.minValue != null &&
          numValue < widget.paramDef.minValue!) {
        return 'Min: ${widget.paramDef.minValue}';
      } else if (widget.paramDef.maxValue != null &&
          numValue > widget.paramDef.maxValue!) {
        return 'Max: ${widget.paramDef.maxValue}';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _formatParameterName(widget.paramKey),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (widget.paramDef.required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (widget.variableIcon != null) widget.variableIcon!,
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _controller,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: _localizeHint(widget.paramDef.hint),
            border: const OutlineInputBorder(),
            isDense: true,
            errorText: _getErrorMessage(),
            suffixText:
                widget.paramDef.minValue != null &&
                        widget.paramDef.maxValue != null
                    ? '${widget.paramDef.minValue}-${widget.paramDef.maxValue}'
                    : null,
          ),
          onChanged: (newValue) {
            final trimmed = newValue.trim();
            if (trimmed.isEmpty) {
              widget.onParameterChanged(widget.paramKey, '');
              setState(() {});
              return;
            }

            final intValue = int.tryParse(trimmed);
            if (intValue != null) {
              // Clamper aux limites min/max
              int finalValue = intValue;
              if (widget.paramDef.minValue != null &&
                  finalValue < widget.paramDef.minValue!) {
                finalValue = widget.paramDef.minValue!;
                _controller.text = finalValue.toString();
              }
              if (widget.paramDef.maxValue != null &&
                  finalValue > widget.paramDef.maxValue!) {
                finalValue = widget.paramDef.maxValue!;
                _controller.text = finalValue.toString();
              }
              widget.onParameterChanged(widget.paramKey, finalValue);
              setState(() {});
              return;
            }

            // Si allowDynamic est false, rejeter les valeurs non numériques
            if (!widget.paramDef.allowDynamic) {
              _controller.text =
                  (widget.currentValue ?? widget.paramDef.defaultValue)
                      .toString();
              setState(() {});
              return;
            }

            widget.onParameterChanged(widget.paramKey, trimmed);
            setState(() {});
          },
        ),
        if (widget.paramDef.allowDynamic)
          ..._buildVariableSuggestionsForParam(
            paramKey: widget.paramKey,
            value: widget.currentValue,
            isNumericField: true,
          ),
      ],
    );
  }

  String _formatParameterName(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String? _localizeHint(String? hint) {
    if (hint == null) return null;
    try {
      return hint;
    } catch (_) {
      return hint;
    }
  }

  List<Widget> _buildVariableSuggestionsForParam({
    required String paramKey,
    required dynamic value,
    bool isNumericField = false,
  }) {
    final rawValue = value?.toString() ?? '';
    final query = _extractPlaceholderQuery(rawValue);
    if (query == null) {
      return const [];
    }

    final normalizedQuery = query.trim().toLowerCase();
    final filteredByKind =
        isNumericField
            ? widget.variableSuggestions.where(
              (item) => item.isNumeric || item.isUnknown,
            )
            : widget.variableSuggestions;

    final dedupedByName = <String, VariableSuggestion>{};
    for (final item in filteredByKind) {
      final normalizedName2 = item.name.trim();
      if (normalizedName2.isEmpty) continue;
      dedupedByName.putIfAbsent(
        normalizedName2,
        () => VariableSuggestion(
          name: normalizedName2,
          kind: item.kind,
          category: item.category,
        ),
      );
    }

    final suggestions =
        dedupedByName.values
            .where(
              (item) =>
                  normalizedQuery.isEmpty ||
                  item.name.toLowerCase().contains(normalizedQuery),
            )
            .toList();

    if (suggestions.isEmpty) {
      return const [];
    }

    // Group by category for a mobile-friendly scrollable list with descriptions.
    final grouped = ActionCard._groupByCategoryStatic(suggestions);
    final categoryOrder = ActionCard._orderedCategoriesStatic(grouped.keys.toList());

    return [
      const SizedBox(height: 8),
      Text(
        isNumericField
            ? 'Dynamic numeric suggestions'
            : 'Available variables',
        style: TextStyle(fontSize: 11, color: AppTheme.grey),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 200,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            for (final cat in categoryOrder)
              if (grouped.containsKey(cat)) ...[
                ActionCard._buildSuggestionCategoryHeaderStatic(cat, grouped[cat]!.length),
                ...grouped[cat]!.map((item) => ActionCard._buildSuggestionListTileStatic(
                      item,
                      onTap: () {
                        final nextValue = _insertVariableInOpenPlaceholder(
                          rawValue,
                          item.name,
                        );
                        _controller.text = nextValue;
                        widget.onParameterChanged(widget.paramKey, nextValue);
                        setState(() {});
                      },
                    )),
                const SizedBox(height: 4),
              ],
          ],
        ),
      ),
    ];
  }

  String? _extractPlaceholderQuery(String input) {
    final start = input.lastIndexOf('((');
    if (start == -1) {
      return null;
    }

    final afterStart = input.substring(start + 2);
    if (afterStart.contains('))')) {
      return null;
    }

    final parts = afterStart.split('|');
    return parts.last.trimLeft();
  }

  String _insertVariableInOpenPlaceholder(String input, String variableName) {
    final start = input.lastIndexOf('((');
    if (start == -1) {
      return '(($variableName))';
    }

    final beforeStart = input.substring(0, start);
    final afterStart = input.substring(start + 2);

    if (afterStart.contains('))')) {
      return input;
    }

    return '$beforeStart(($variableName))';
  }
}

// Widget stateful pour les champs texte avec support de l'auto-complétion variable
class _TextParameterField extends StatefulWidget {
  final ParameterDefinition paramDef;
  final dynamic currentValue;
  final Function(String key, dynamic value) onParameterChanged;
  final Function(String key, dynamic value) onSuggestionSelected;
  final List<VariableSuggestion> variableSuggestions;
  final String paramKey;
  final Widget Function({
    required String paramKey,
    required dynamic value,
  }) buildVariableSuggestions;

  const _TextParameterField({
    required this.paramDef,
    required this.currentValue,
    required this.onParameterChanged,
    required this.onSuggestionSelected,
    required this.variableSuggestions,
    required this.paramKey,
    required this.buildVariableSuggestions,
  });

  @override
  State<_TextParameterField> createState() => _TextParameterFieldState();
}

class _TextParameterFieldState extends State<_TextParameterField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentValue ?? widget.paramDef.defaultValue).toString(),
    );
  }

  @override
  void didUpdateWidget(_TextParameterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue) {
      final newText = (widget.currentValue ?? widget.paramDef.defaultValue).toString();
      if (_controller.text != newText) {
        _controller.text = newText;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _localizeHint(String? hint) {
    final raw = (hint ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }
    if (WidgetsBinding.instance.platformDispatcher.locale.languageCode !=
        'fr') {
      return raw;
    }

    const direct = <String, String>{
      'Math operation to perform': 'Opération mathématique à effectuer',
      'Comparison operator': 'Opérateur de comparaison',
      'Message content': 'Contenu du message',
      'Audit log reason': 'Raison du journal d\'audit',
      'Global variable key': 'Clé de variable globale',
      'Variable scope': 'Portée de la variable',
      'Channel to slowmode': 'Salon à ralentir',
      'Slowmode duration': 'Durée du mode lent',
      'Stop execution immediately': 'Arrêter l\'exécution immédiatement',
      'Response type': 'Type de réponse',
      'Modal custom ID': 'ID personnalisé de la modale',
      'Modal title': 'Titre de la modale',
      'Text input custom ID': 'ID personnalisé du champ texte',
      'Text input label': 'Libellé du champ texte',
      'Text input style': 'Style du champ texte',
      'Placeholder text': 'Texte d\'espace réservé',
      'Minimum length': 'Longueur minimale',
      'Maximum length': 'Longueur maximale',
      'Is required': 'Est requis',
      'Default value': 'Valeur par défaut',
      'Embed description': 'Description de l\'embed',
      'Embed title': 'Titre de l\'embed',
      'Embed color': 'Couleur de l\'embed',
      'Embed footer': 'Pied de page de l\'embed',
      'Embed image': 'Image de l\'embed',
      'Embed thumbnail': 'Miniature de l\'embed',
      'Embed author': 'Auteur de l\'embed',
      'Field name': 'Nom du champ',
      'Field value': 'Valeur du champ',
      'Field inline': 'Alignement du champ',
      'Webhook URL': 'URL du webhook',
      'Payload data': 'Données utiles',
      'Variable key': 'Clé de la variable',
      'Variable value': 'Valeur de la variable',
      'Array items': 'Éléments du tableau',
      'Interaction custom ID': 'ID personnalisé de l\'interaction',
      'Interaction deferred': 'Interaction différée',
      'Interaction ephemeral': 'Interaction éphémère',
    };

    return direct[raw] ?? raw;
  }

  String _formatParameterName(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _formatParameterName(widget.paramKey),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (widget.paramDef.required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _controller,
          maxLines: widget.paramKey.toLowerCase().contains('content') ? 3 : 1,
          decoration: InputDecoration(
            hintText: _localizeHint(widget.paramDef.hint),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (newValue) {
            widget.onParameterChanged(widget.paramKey, newValue);
          },
        ),
        widget.buildVariableSuggestions(
          paramKey: widget.paramKey,
          value: _controller.text,
        ),
      ],
    );
  }
}

class _BdfdScriptParameterField extends StatefulWidget {
  const _BdfdScriptParameterField({
    super.key,
    required this.currentValue,
    required this.onChanged,
    this.hint,
  });

  final String currentValue;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  State<_BdfdScriptParameterField> createState() =>
      _BdfdScriptParameterFieldState();
}

class _BdfdScriptParameterFieldState extends State<_BdfdScriptParameterField> {
  late final TextEditingController _controller;
  final BdfdCompiler _compiler = BdfdCompiler();
  BdfdCompileResult? _compileResult;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
    _recompile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _recompile() {
    final source = _controller.text;
    if (source.trim().isEmpty) {
      _compileResult = null;
      return;
    }
    _compileResult = _compiler.compile(source);
  }

  List<BdfdCompileDiagnostic> get _diagnostics =>
      _compileResult?.diagnostics ?? const <BdfdCompileDiagnostic>[];

  bool get _hasErrors => _diagnostics.any(
    (d) => d.severity == BdfdCompileDiagnosticSeverity.error,
  );

  String _formatDiagnostic(BdfdCompileDiagnostic d) {
    final loc =
        (d.line != null && d.column != null) ? 'L${d.line}:C${d.column} ' : '';
    return '$loc${d.message}';
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    final isEmpty = code.trim().isEmpty;
    final preview =
        isEmpty
            ? context.tr.bdfd_editor_tap_hint
            : code.length > 150
            ? '${code.substring(0, 150)}…'
            : code;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'BDFD Script',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute<String>(
                builder: (_) => BdfdEditorPage(initialCode: _controller.text),
              ),
            );
            if (result != null && mounted) {
              _controller.text = result;
              setState(_recompile);
              widget.onChanged(result);
            }
          },
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
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
                    const Icon(Icons.code, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      context.tr.bdfd_editor_tap_hint,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.open_in_new, size: 14, color: AppTheme.grey),
                  ],
                ),
                if (!isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    preview,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.grey,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildDiagnosticsPanel(),
      ],
    );
  }

  Widget _buildDiagnosticsPanel() {
    final diagnostics = _diagnostics;

    if (_controller.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (diagnostics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.success,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.success),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: AppTheme.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr.cmd_bdfd_diagnostics_clean,
                style: TextStyle(fontSize: 12, color: AppTheme.success),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _hasErrors ? AppTheme.error : AppTheme.warning,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: _hasErrors ? AppTheme.error : AppTheme.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.cmd_bdfd_diagnostics_title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          ...diagnostics.map((d) {
            final isError = d.severity == BdfdCompileDiagnosticSeverity.error;
            final icon =
                isError ? Icons.error_outline : Icons.warning_amber_rounded;
            final label =
                isError
                    ? 'cmd_bdfd_diagnostics_error'
                    : 'cmd_bdfd_diagnostics_warning';
            final color = isError ? AppTheme.error : AppTheme.warning;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$label: ${_formatDiagnostic(d)}',
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyxx/nyxx.dart' hide Builder;
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';

enum _VariableMode { global, scoped }

enum _VariablesSource { local, runner, manager }

class GlobalVariablesPage extends StatefulWidget {
  const GlobalVariablesPage({super.key, required this.botId});

  final String botId;

  @override
  State<GlobalVariablesPage> createState() => _GlobalVariablesPageState();
}

class _GlobalVariablesPageState extends State<GlobalVariablesPage>
    with WidgetsBindingObserver {
  static const List<String> _scopes = <String>[
    'guild',
    'user',
    'channel',
    'guildMember',
    'message',
  ];

  static const double _wideBreakpoint = 600;

  Map<String, dynamic> _globalVariables = <String, dynamic>{};
  List<Map<String, dynamic>> _scopedDefinitions = <Map<String, dynamic>>[];
  _VariableMode _mode = _VariableMode.global;
  _VariablesSource _source = _VariablesSource.local;
  List<RunnerConnectionConfig> _runners = const [];
  String? _activeRunnerId;
  RunnerClient? _runnerClient;
  MainApiClient? _managerClient;
  String? _managerDetailLabel;
  String? _error;
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_refreshSourcesAndLoad(preserveSelection: true));
    }
  }

  bool get _isScopedMode => _mode == _VariableMode.scoped;
  bool get _isRunnerMode => _source == _VariablesSource.runner;

  bool get _isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _isManagerMode => _source == _VariablesSource.manager;
  bool get _supportsManagerRuntime {
    return !kIsWeb &&
        defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.linux &&
        defaultTargetPlatform != TargetPlatform.macOS;
  }

  Future<void> _init() async {
    await _refreshSourcesAndLoad(preserveSelection: false);
  }

  Future<void> _refreshSourcesAndLoad({required bool preserveSelection}) async {
    final runners = await RunnerSettings.getRunners();
    final active = await RunnerSettings.resolveConfigForBot(widget.botId);
    final remoteRuntime = await resolveRemoteRuntime(
      supportsManagerRuntime: _supportsManagerRuntime,
      botId: widget.botId,
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 30),
    );
    final managerClient = remoteRuntime.client is MainApiClient
        ? remoteRuntime.client as MainApiClient
        : null;

    if (!mounted) return;
    final mergedRunners = List<RunnerConnectionConfig>.from(runners);
    if (active != null &&
        !mergedRunners.any((runner) => runner.id == active.id)) {
      mergedRunners.insert(0, active);
    }
    setState(() {
      _runners = mergedRunners;
      _activeRunnerId = active?.id;
      _runnerClient = active?.createClient();
      _managerClient = managerClient;
      _managerDetailLabel = remoteRuntime.detailLabel;
      _source = _resolvePreferredSource(
        preserveSelection: preserveSelection,
        hasActiveRunner: active != null,
        hasManager: managerClient != null,
      );
    });
    await _load();
  }

  _VariablesSource _resolvePreferredSource({
    required bool preserveSelection,
    required bool hasActiveRunner,
    required bool hasManager,
  }) {
    if (preserveSelection) {
      if (_source == _VariablesSource.manager && hasManager) {
        return _VariablesSource.manager;
      }
      if (_source == _VariablesSource.runner && hasActiveRunner) {
        return _VariablesSource.runner;
      }
      if (_source == _VariablesSource.local) {
        return _VariablesSource.local;
      }
    }

    if (hasManager) {
      return _VariablesSource.manager;
    }
    if (hasActiveRunner) {
      return _VariablesSource.runner;
    }
    return _VariablesSource.local;
  }

  dynamic _parseLooseVariableValue(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final number = num.tryParse(trimmed);
    if (number != null) {
      return number;
    }

    if (trimmed == 'true') {
      return true;
    }
    if (trimmed == 'false') {
      return false;
    }

    if ((trimmed.startsWith('[') && trimmed.endsWith(']')) ||
        (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        trimmed == 'null') {
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return raw;
      }
    }

    return raw;
  }

  String _formatVariableValue(dynamic value) {
    if (value == null) {
      return 'null';
    }
    if (value is List || value is Map) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

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

  static IconData _scopeIcon(String scope) {
    switch (scope) {
      case 'guild':
        return Icons.dns_outlined;
      case 'user':
        return Icons.person_outline;
      case 'channel':
        return Icons.tag;
      case 'guildMember':
        return Icons.people_outline;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.label_outline;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _getSourceGlobalVariables(),
        _getSourceScopedDefinitions(),
      ]);
      if (!mounted) return;
      setState(() {
        _globalVariables = Map<String, dynamic>.from(
          results[0] as Map<String, dynamic>,
        );
        _scopedDefinitions = List<Map<String, dynamic>>.from(
          results[1] as List,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  RunnerClient _requireRunnerClient() {
    final client = _runnerClient;
    if (client == null) {
      throw StateError('Source Runner sélectionnée sans connexion active.');
    }
    return client;
  }

  MainApiClient _requireManagerClient() {
    final client = _managerClient;
    if (client == null) {
      throw StateError(
        'Source Bot Creator sélectionnée sans connexion active.',
      );
    }
    return client;
  }

  Future<Map<String, dynamic>> _getSourceGlobalVariables() async {
    if (_isManagerMode) {
      return _requireManagerClient().getGlobalVariables(widget.botId);
    }
    if (_isRunnerMode) {
      return _requireRunnerClient().getGlobalVariables(widget.botId);
    }
    return appManager.getGlobalVariables(widget.botId);
  }

  Future<List<Map<String, dynamic>>> _getSourceScopedDefinitions() async {
    if (_isManagerMode) {
      return _requireManagerClient().getScopedVariableDefinitions(widget.botId);
    }
    if (_isRunnerMode) {
      return _requireRunnerClient().getScopedVariableDefinitions(widget.botId);
    }
    return appManager.getScopedVariableDefinitions(widget.botId);
  }

  Future<void> _setSourceGlobalVariable(String key, dynamic value) async {
    if (_isManagerMode) {
      await _requireManagerClient().setGlobalVariable(widget.botId, key, value);
      return;
    }
    if (_isRunnerMode) {
      await _requireRunnerClient().setGlobalVariable(widget.botId, key, value);
      return;
    }
    await appManager.setGlobalVariable(widget.botId, key, value);
  }

  Future<void> _removeSourceGlobalVariable(String key) async {
    if (_isManagerMode) {
      await _requireManagerClient().removeGlobalVariable(widget.botId, key);
      return;
    }
    if (_isRunnerMode) {
      await _requireRunnerClient().removeGlobalVariable(widget.botId, key);
      return;
    }
    await appManager.removeGlobalVariable(widget.botId, key);
  }

  Future<void> _setSourceScopedDefinition(
    String key,
    String scope,
    dynamic defaultValue,
  ) async {
    if (_isManagerMode) {
      await _requireManagerClient().setScopedVariableDefinition(
        widget.botId,
        key,
        scope,
        defaultValue,
      );
      return;
    }
    if (_isRunnerMode) {
      await _requireRunnerClient().setScopedVariableDefinition(
        widget.botId,
        key,
        scope,
        defaultValue,
      );
      return;
    }
    await appManager.setScopedVariableDefinition(
      widget.botId,
      key,
      scope,
      defaultValue,
    );
  }

  Future<void> _removeSourceScopedDefinition(
    String key, {
    String? scope,
    bool purgeStoredValues = false,
  }) async {
    if (_isManagerMode) {
      await _requireManagerClient().removeScopedVariableDefinition(
        widget.botId,
        key,
        scope: scope,
        purgeStoredValues: purgeStoredValues,
      );
      return;
    }
    if (_isRunnerMode) {
      await _requireRunnerClient().removeScopedVariableDefinition(
        widget.botId,
        key,
        scope: scope,
        purgeStoredValues: purgeStoredValues,
      );
      return;
    }
    await appManager.removeScopedVariableDefinition(
      widget.botId,
      key,
      scope: scope,
      purgeStoredValues: purgeStoredValues,
    );
  }

  Future<Map<String, dynamic>> _listSourceScopedValuesForKey(
    String scope,
    String key,
  ) async {
    if (_isManagerMode) {
      return _requireManagerClient().listScopedValuesForKey(
        widget.botId,
        scope,
        key,
      );
    }
    if (_isRunnerMode) {
      return _requireRunnerClient().listScopedValuesForKey(
        widget.botId,
        scope,
        key,
      );
    }
    return appManager.listScopedValuesForKey(widget.botId, scope, key);
  }

  Future<void> _switchSource(String sourceId) async {
    if (sourceId == 'local') {
      setState(() {
        _source = _VariablesSource.local;
        _error = null;
      });
      await _load();
      return;
    }

    if (sourceId == 'manager') {
      if (_managerClient == null) {
        return;
      }
      setState(() {
        _source = _VariablesSource.manager;
        _error = null;
      });
      await _load();
      return;
    }

    final runner = _runners.where((r) => r.id == sourceId).firstOrNull;
    if (runner == null) {
      return;
    }

    setState(() {
      _source = _VariablesSource.runner;
      _activeRunnerId = sourceId;
      _runnerClient = runner.createClient();
      _error = null;
    });
    await _load();
  }

  // ─── Global variable add / edit ───────────────────────────────────────────

  Future<void> _editGlobalVariable({String? key}) async {
    final keyCtrl = TextEditingController(text: key ?? '');
    final valueCtrl = TextEditingController(
      text: key != null ? _formatVariableValue(_globalVariables[key]) : '',
    );

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.public,
              size: 22,
              color: Theme.of(ctx).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                key == null
                    ? context.tr.globals_add_global
                    : context.tr.globals_edit_global,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr.globals_dialog_global_desc,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyCtrl,
                enabled: key == null,
                autofocus: key == null,
                decoration: InputDecoration(
                  labelText: context.tr.globals_key,
                  hintText: context.tr.globals_key_hint,
                  prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueCtrl,
                maxLines: 4,
                minLines: 1,
                autofocus: key != null,
                decoration: InputDecoration(
                  labelText: context.tr.globals_value,
                  helperText: context.tr.globals_value_auto_type_hint,
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr.app_save),
          ),
        ],
      ),
    );

    if (save != true) return;
    final nextKey = keyCtrl.text.trim();
    if (nextKey.isEmpty) return;

    final parsed = _parseLooseVariableValue(valueCtrl.text);
    try {
      await _setSourceGlobalVariable(nextKey, parsed);
    } on MainApiClientException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sync variable: ${e.message}')),
      );
      return;
    }
    await _load();
  }

  Future<void> _deleteGlobalVariable(String key) async {
    final shouldDelete = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.globals_delete_title,
      content: context.tr.globals_delete_confirm(key),
      confirmLabel: context.tr.delete,
      isDestructive: true,
    );
    if (!shouldDelete) {
      return;
    }

    await _removeSourceGlobalVariable(key);
    await _load();
  }

  // ─── Scoped variable definition add / edit ────────────────────────────────

  Future<void> _editScopedDefinition({Map<String, dynamic>? existing}) async {
    final oldKey = existing?['key']?.toString();
    final keyCtrl = TextEditingController(text: oldKey ?? '');
    final rawDefault = existing?['defaultValue'];
    final valueCtrl = TextEditingController(
      text: rawDefault != null ? _formatVariableValue(rawDefault) : '',
    );
    String scope =
        (existing?['scope']?.toString().isNotEmpty == true
            ? existing!['scope'].toString()
            : null) ??
        _scopes.first;

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 22,
                color: Theme.of(ctx).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  existing == null
                      ? context.tr.globals_add_scoped
                      : context.tr.globals_edit_scoped,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr.globals_dialog_scoped_desc(scope),
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: scope,
                  decoration: InputDecoration(
                    labelText: context.tr.scoped_scope,
                    helperText: context.tr.scoped_scope_help,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                  items: _scopes
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s,
                          child: Row(
                            children: [
                              Icon(
                                _scopeIcon(s),
                                size: 18,
                                color: Theme.of(
                                  ctx,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Text(s),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (v) {
                    if (v != null) setInner(() => scope = v);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keyCtrl,
                  autofocus: existing == null,
                  decoration: InputDecoration(
                    labelText: context.tr.globals_key,
                    hintText: context.tr.globals_key_hint,
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setInner(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueCtrl,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    labelText: context.tr.scoped_default_value,
                    hintText: context.tr.scoped_default_value_hint,
                    helperText: context.tr.globals_value_auto_type_hint,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (keyCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.globals_dialog_ref_preview(
                            '$scope.${_toScopedReferenceKey(keyCtrl.text)}',
                          ),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                        Text(
                          context.tr.scoped_ref(
                            '$scope.${_toScopedReferenceKey(keyCtrl.text)}',
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.tr.app_save),
            ),
          ],
        ),
      ),
    );

    if (save != true) return;
    final newKey = keyCtrl.text.trim();
    if (newKey.isEmpty) return;

    // If the key was renamed, delete the old entry first.
    if (oldKey != null && oldKey != newKey) {
      await _removeSourceScopedDefinition(
        oldKey,
        scope: existing?['scope']?.toString(),
      );
    }

    final parsed = _parseLooseVariableValue(valueCtrl.text);
    await _setSourceScopedDefinition(newKey, scope, parsed);
    await _load();
  }

  Future<void> _deleteScopedDefinition(String key, String scope) async {
    final shouldDelete = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.scoped_delete_title,
      content: context.tr.scoped_delete_confirm(key),
      confirmLabel: context.tr.delete,
      isDestructive: true,
    );
    if (!shouldDelete) {
      return;
    }

    final existing = _scopedDefinitions
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (entry) =>
              (entry?['key'] ?? '').toString() == key &&
              (entry?['scope'] ?? '').toString() == scope,
          orElse: () => null,
        );
    await _removeSourceScopedDefinition(
      key,
      scope: existing?['scope']?.toString() ?? scope,
      purgeStoredValues: true,
    );
    await _load();
  }

  // ─── Explorer: shows SQLite runtime data for a given scoped key ───────────

  /// Returns a [NyxxRest] client for the current bot.
  ///
  /// Reuses a running desktop gateway when available, otherwise creates a
  /// lightweight REST-only client from the stored token.  Returns `null` when
  /// the token is missing or empty.
  Future<NyxxRest?> _getRestClient() async {
    // Prefer an already-connected gateway (avoids extra REST handshake).
    final gateway = desktopGatewayForBot(widget.botId);
    if (gateway != null) return gateway;

    final appData = await appManager.getApp(widget.botId);
    final token = (appData['token'] ?? '').toString().trim();
    if (token.isEmpty) return null;

    try {
      return await Nyxx.connectRest(token);
    } catch (_) {
      return null;
    }
  }

  /// Try to resolve a Discord snowflake [contextId] to a human-readable label.
  Future<String?> _resolveContextLabel(
    NyxxRest client,
    String scope,
    String contextId,
  ) async {
    try {
      switch (scope) {
        case 'guild':
          final guild = await client.guilds.get(Snowflake.parse(contextId));
          return guild.name;
        case 'user':
          final user = await client.users.get(Snowflake.parse(contextId));
          return user.username;
        case 'channel':
          final channel = await client.channels.get(Snowflake.parse(contextId));
          if (channel is GuildTextChannel) return '#${channel.name}';
          if (channel is GuildVoiceChannel) return channel.name;
          if (channel is ThreadsOnlyChannel) return '#${channel.name}';
          if (channel is GuildStageChannel) return channel.name;
          if (channel is DmChannel) return 'DM';
          return channel.toString();
        case 'guildMember':
          final parts = contextId.split(':');
          if (parts.length == 2) {
            final guildName = await _resolveContextLabel(
              client,
              'guild',
              parts[0],
            );
            final userName = await _resolveContextLabel(
              client,
              'user',
              parts[1],
            );
            if (guildName != null || userName != null) {
              return '${guildName ?? parts[0]} / ${userName ?? parts[1]}';
            }
          }
          return null;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Resolves all context IDs to human-readable labels in parallel.
  Future<Map<String, String>> _resolveAllContextLabels(
    String scope,
    Iterable<String> contextIds,
  ) async {
    final labels = <String, String>{};
    if (contextIds.isEmpty) return labels;

    final client = await _getRestClient();
    if (client == null) return labels;

    final futures = <Future<void>>[];
    for (final contextId in contextIds) {
      futures.add(
        _resolveContextLabel(client, scope, contextId).then((label) {
          if (label != null) labels[contextId] = label;
        }),
      );
    }
    await Future.wait(futures);
    return labels;
  }

  Future<void> _exploreScopedKey(String key, String scope) async {
    final values = await _listSourceScopedValuesForKey(scope, key);

    if (!mounted) return;

    // Resolve Discord IDs to human-readable names.
    final labels = await _resolveAllContextLabels(scope, values.keys);

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) {
          var runtimeSearch = '';
          return StatefulBuilder(
            builder: (ctx, setLocalState) {
              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(context.tr.scoped_runtime_title(key)),
                      subtitle: Text(
                        context.tr.scoped_runtime_subtitle(
                          scope,
                          values.length,
                        ),
                      ),
                      trailing: values.isNotEmpty
                          ? IconButton(
                              tooltip: context.tr.scoped_runtime_copy_all,
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: const JsonEncoder.withIndent(
                                      '  ',
                                    ).convert(values),
                                  ),
                                );
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr.scoped_runtime_copy_all,
                                    ),
                                  ),
                                );
                              },
                            )
                          : null,
                    ),
                    if (values.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: context.tr.scoped_runtime_search,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            setLocalState(() {
                              runtimeSearch = v;
                            });
                          },
                        ),
                      ),
                    const Divider(height: 1),
                    Expanded(
                      child: values.isEmpty
                          ? Center(
                              child: Text(
                                context.tr.scoped_runtime_empty,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Builder(
                              builder: (ctx) {
                                final q = runtimeSearch.toLowerCase();
                                final filtered = values.entries
                                    .where((e) {
                                      if (q.isEmpty) return true;
                                      final label = labels[e.key];
                                      return e.key.toLowerCase().contains(q) ||
                                          (label != null &&
                                              label.toLowerCase().contains(q));
                                    })
                                    .toList(growable: false);
                                if (filtered.isEmpty) {
                                  return Center(
                                    child: Text(
                                      context.tr.scoped_runtime_empty,
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  controller: scrollCtrl,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1),
                                  itemBuilder: (ctx, i) {
                                    final entry = filtered[i];
                                    final label = labels[entry.key];
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        label ?? entry.key,
                                        style: TextStyle(
                                          fontFamily: label != null
                                              ? null
                                              : 'monospace',
                                          fontWeight: FontWeight.w600,
                                          fontSize: label != null ? 14 : 12,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (label != null)
                                            Text(
                                              entry.key,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 11,
                                              ),
                                            ),
                                          Text(entry.value?.toString() ?? ''),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── Filtered data helpers ────────────────────────────────────────────────

  List<MapEntry<String, dynamic>> get _filteredGlobalEntries {
    final entries = _globalVariables.entries.toList();
    if (_searchQuery.isEmpty) return entries;
    final q = _searchQuery.toLowerCase();
    return entries
        .where(
          (e) =>
              e.key.toLowerCase().contains(q) ||
              (e.value?.toString().toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  /// Returns scoped definitions grouped by scope, filtered by search query.
  Map<String, List<Map<String, dynamic>>> get _filteredScopedByScope {
    final q = _searchQuery.toLowerCase();
    final filtered = _searchQuery.isEmpty
        ? _scopedDefinitions
        : _scopedDefinitions
              .where(
                (d) =>
                    (d['key']?.toString().toLowerCase().contains(q) ?? false) ||
                    (d['scope']?.toString().toLowerCase().contains(q) ?? false),
              )
              .toList();

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final def in filtered) {
      final scope = def['scope']?.toString() ?? '';
      (grouped[scope] ??= []).add(def);
    }
    return grouped;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  String get _sourceLabel {
    if (_source == _VariablesSource.local) {
      return context.tr.globals_source_local;
    }
    if (_source == _VariablesSource.manager) {
      final detail = _managerDetailLabel?.trim();
      if (detail == null || detail.isEmpty) {
        return context.tr.app_title;
      }
      return '${context.tr.app_title} • $detail';
    }
    final runner = _runners.where((r) => r.id == _activeRunnerId).firstOrNull;
    return context.tr.globals_source_runner(runner?.name ?? '?');
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: context.tr.globals_search,
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<_VariableMode>(
                  segments: [
                    ButtonSegment<_VariableMode>(
                      value: _VariableMode.global,
                      label: Text(context.tr.globals_mode_global),
                      icon: const Icon(Icons.public, size: 18),
                    ),
                    ButtonSegment<_VariableMode>(
                      value: _VariableMode.scoped,
                      label: Text(context.tr.globals_mode_scoped),
                      icon: const Icon(Icons.account_tree_outlined, size: 18),
                    ),
                  ],
                  selected: <_VariableMode>{_mode},
                  onSelectionChanged: (selection) async {
                    final next = selection.first;
                    if (next == _mode) return;
                    setState(() {
                      _mode = next;
                      _searchQuery = '';
                    });
                    await _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isScopedMode
                      ? context.tr.globals_help_scoped
                      : context.tr.globals_help_global,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _load,
                child: Text(context.tr.globals_retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 320,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: Text(context.tr.globals_add),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalList() {
    final entries = _filteredGlobalEntries;

    if (_globalVariables.isEmpty) {
      return _buildEmptyState(
        icon: Icons.dataset_outlined,
        title: context.tr.globals_empty,
        subtitle: context.tr.globals_empty_subtitle,
        onAdd: () => _editGlobalVariable(),
      );
    }

    if (entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120, child: Center(child: Text('—'))),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: FloatingGlassNavBar.contentClearanceOf(context) + 24,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        return ListTile(
          title: Text(
            entry.key,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            entry.value?.toString() ?? 'null',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          onTap: () => _editGlobalVariable(key: entry.key),
          trailing: PopupMenuButton<String>(
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined, size: 20),
                  title: Text(context.tr.globals_edit),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'copy',
                child: ListTile(
                  leading: const Icon(Icons.copy, size: 20),
                  title: Text(context.tr.globals_copy_value),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                  title: Text(
                    context.tr.delete,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case 'edit':
                  _editGlobalVariable(key: entry.key);
                case 'copy':
                  Clipboard.setData(
                    ClipboardData(text: _formatVariableValue(entry.value)),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr.globals_copy_value)),
                  );
                case 'delete':
                  _deleteGlobalVariable(entry.key);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildScopedList() {
    if (_scopedDefinitions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.account_tree_outlined,
        title: context.tr.scoped_empty,
        subtitle: context.tr.scoped_empty_subtitle,
        onAdd: () => _editScopedDefinition(),
      );
    }

    final grouped = _filteredScopedByScope;

    if (grouped.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120, child: Center(child: Text('—'))),
        ],
      );
    }

    // Build a flat list with section headers.
    final items = <_ScopedListItem>[];
    for (final scope in _scopes) {
      final defs = grouped[scope];
      if (defs == null || defs.isEmpty) continue;
      items.add(_ScopedListItem.header(scope, defs.length));
      for (final def in defs) {
        items.add(_ScopedListItem.entry(def));
      }
    }
    // Catch any scopes not in the predefined list.
    for (final scope in grouped.keys) {
      if (!_scopes.contains(scope)) {
        final defs = grouped[scope]!;
        items.add(_ScopedListItem.header(scope, defs.length));
        for (final def in defs) {
          items.add(_ScopedListItem.entry(def));
        }
      }
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: FloatingGlassNavBar.contentClearanceOf(context) + 24,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        if (item.isHeader) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Text(
                  item.scope!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    '${item.count}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final def = item.def!;
        final key = def['key']?.toString() ?? '';
        final scope = def['scope']?.toString() ?? '';
        final defaultValue = def['defaultValue'];
        final refKey = _toScopedReferenceKey(key);
        final legacyRefKey = _toLegacyScopedReferenceKey(key);
        final hasLegacy = refKey != legacyRefKey;

        return ListTile(
          title: Text(
            key,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                defaultValue != null && defaultValue.toString().isNotEmpty
                    ? '= ${_formatVariableValue(defaultValue)}'
                    : context.tr.globals_no_default,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr.scoped_ref('$scope.$refKey'),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasLegacy)
                Text(
                  context.tr.scoped_ref_legacy('$scope.$legacyRefKey'),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'explore',
                child: ListTile(
                  leading: const Icon(Icons.travel_explore, size: 20),
                  title: Text(context.tr.scoped_explore_runtime),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined, size: 20),
                  title: Text(context.tr.globals_edit),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                  title: Text(
                    context.tr.delete,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case 'explore':
                  _exploreScopedKey(key, scope);
                case 'edit':
                  _editScopedDefinition(existing: def);
                case 'delete':
                  _deleteScopedDefinition(key, scope);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildVariablesContent({required bool isWide}) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildPanel(_VariableMode.global)),
          const VerticalDivider(width: 1),
          Expanded(child: _buildPanel(_VariableMode.scoped)),
        ],
      );
    }

    // Mobile: single panel driven by _mode toggle.
    return Column(
      children: [
        _buildModeToggle(),
        if (_error != null) _buildError(),
        _buildSearchBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _isScopedMode ? _buildScopedList() : _buildGlobalList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(_VariableMode mode) {
    final isGlobal = mode == _VariableMode.global;
    final title = isGlobal
        ? context.tr.globals_mode_global
        : context.tr.globals_mode_scoped;
    final help = isGlobal
        ? context.tr.globals_help_global
        : context.tr.globals_help_scoped;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isGlobal ? Icons.public : Icons.account_tree_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: context.tr.globals_add,
                    onPressed: isGlobal
                        ? () => _editGlobalVariable()
                        : () => _editScopedDefinition(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      help,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null &&
            ((isGlobal && !_isScopedMode) || (!isGlobal && _isScopedMode)))
          _buildError(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: isGlobal ? _buildGlobalList() : _buildScopedList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasManagerSource = _managerClient != null;
    final sourceActions = <Widget>[
      if (hasManagerSource || _runners.isNotEmpty)
        PopupMenuButton<String>(
          tooltip: _sourceLabel,
          icon: Icon(switch (_source) {
            _VariablesSource.local => Icons.storage_outlined,
            _VariablesSource.runner => Icons.cloud_outlined,
            _VariablesSource.manager => Icons.hub_outlined,
          }, size: 22),
          itemBuilder: (ctx) => [
            PopupMenuItem<String>(
              value: 'local',
              child: ListTile(
                leading: const Icon(Icons.storage_outlined, size: 20),
                title: Text(context.tr.globals_source_local),
                dense: true,
                contentPadding: EdgeInsets.zero,
                selected: _source == _VariablesSource.local,
              ),
            ),
            if (hasManagerSource) const PopupMenuDivider(),
            if (hasManagerSource)
              PopupMenuItem<String>(
                value: 'manager',
                child: ListTile(
                  leading: const Icon(Icons.hub_outlined, size: 20),
                  title: Text(context.tr.app_title),
                  subtitle: (_managerDetailLabel?.trim().isNotEmpty ?? false)
                      ? Text(
                          _managerDetailLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  selected: _isManagerMode,
                ),
              ),
            if (hasManagerSource && _runners.isNotEmpty && !_isMobile)
              const PopupMenuDivider(),
            if (!_isMobile)
              ..._runners.map(
                (runner) => PopupMenuItem<String>(
                  value: runner.id,
                  child: ListTile(
                    leading: const Icon(Icons.cloud_outlined, size: 20),
                    title: Text(
                      context.tr.globals_source_runner(runner.name ?? '?'),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    selected: _isRunnerMode && _activeRunnerId == runner.id,
                  ),
                ),
              ),
          ],
          onSelected: (id) => unawaited(_switchSource(id)),
        ),
      IconButton(
        tooltip: context.tr.globals_add,
        onPressed: () =>
            _isScopedMode ? _editScopedDefinition() : _editGlobalVariable(),
        icon: const Icon(Icons.add_rounded),
      ),
      IconButton(
        tooltip: context.tr.globals_refresh,
        onPressed: _load,
        icon: const Icon(Icons.refresh),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: editorSubPageLeading(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr.globals_title),
            if (hasManagerSource || (_runners.isNotEmpty && !_isMobile))
              Text(
                _sourceLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: sourceActions,
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth >= _wideBreakpoint;
                  final content = _buildVariablesContent(isWide: isWide);
                  if (isWide) {
                    return content;
                  }
                  return PageContent(child: content);
                },
              ),
      ),
    );
  }
}

class _ScopedListItem {
  final bool isHeader;
  final String? scope;
  final int? count;
  final Map<String, dynamic>? def;

  const _ScopedListItem._({
    required this.isHeader,
    this.scope,
    this.count,
    this.def,
  });

  factory _ScopedListItem.header(String scope, int count) =>
      _ScopedListItem._(isHeader: true, scope: scope, count: count);

  factory _ScopedListItem.entry(Map<String, dynamic> def) =>
      _ScopedListItem._(isHeader: false, def: def);
}

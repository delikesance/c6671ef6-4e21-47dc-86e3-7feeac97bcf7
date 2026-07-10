import 'dart:io';
import 'dart:async';
import 'dart:convert';


import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/export_import.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflow_docs.page.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/logic/js_runner_capabilities.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:bot_creator/core/discord/portal_intent_feedback.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:bot_creator_shared/services/lavalink_list_service.dart';
import 'package:bot_creator_shared/services/lavalink_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as developer;

class AppSettingsPage extends StatefulWidget {
  final NyxxRest client;
  final VoidCallback? onRuntimeEngineChanged;

  const AppSettingsPage({
    super.key,
    required this.client,
    this.onRuntimeEngineChanged,
  });

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  Application? app;
  DiscordApplicationOwnerMetadata? _ownerMetadata;
  bool _isSavingToken = false;
  bool _isForceSyncing = false;
  bool _isSavingPrefix = false;
  bool _isSavingProfile = false;
  bool _isEditingToken = false;
  String _savedToken = '';
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  String? _selectedAvatarPath;
  bool _builtInLegacyHelpEnabled = true;
  final List<_StatusDraft> _statusDrafts = <_StatusDraft>[];
  String _presenceStatus = 'online';
  String _appVersion = '';
  String? _runnerVersion;
  String _runtimeEngine = runtimeEngineDart;
  bool _isSwitchingRuntimeEngine = false;
  // Lavalink fields
  final TextEditingController _lavalinkHostController = TextEditingController();
  final TextEditingController _lavalinkPortController = TextEditingController();
  final TextEditingController _lavalinkPasswordController = TextEditingController();
  bool _lavalinkSsl = false;
  bool _isSavingLavalink = false;
  bool _lavalinkPasswordVisible = false;
  // Connection test
  bool _isTestingConnection = false;
  String? _connectionTestResult;
  // Public server list
  final LavalinkListService _lavalinkListService = LavalinkListService();
  List<LavalinkServerEntry>? _publicServers;
  bool _isLoadingServers = false;

  static const List<String> _statusTypes = <String>[
    'playing',
    'streaming',
    'listening',
    'watching',
    'competing',
  ];

  bool get _supportsManagerRuntime =>
      !kIsWeb &&
      !Platform.isWindows &&
      !Platform.isLinux &&
      !Platform.isMacOS;

  BotRuntimeCapabilities get _capabilities =>
      capabilitiesForEngine(_runtimeEngine);

  Future<void> _onRuntimeEngineChanged(String? value) async {
    if (value == null || value == _runtimeEngine || _isSwitchingRuntimeEngine) {
      return;
    }

    final confirm = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.settings_runtime_engine_switch_dialog_title,
      content: context.tr.settings_runtime_engine_switch_dialog_desc,
      confirmLabel: context.tr.settings_runtime_engine_switch_dialog_confirm,
      isDestructive: true,
    );
    if (confirm != true || !mounted) {
      return;
    }

    final botId = widget.client.user.id.toString();
    setState(() => _isSwitchingRuntimeEngine = true);

    try {
      await switchBotRuntimeEngine(
        botId,
        value,
        supportsManagerRuntime: _supportsManagerRuntime,
      );
      if (!mounted) return;
      setState(() => _runtimeEngine = value);
      widget.onRuntimeEngineChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.settings_runtime_engine_switch_success)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr.settings_runtime_engine_switch_error(error.toString()),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSwitchingRuntimeEngine = false);
      }
    }
  }

  static const List<String> _presenceStatuses = <String>[
    'online',
    'idle',
    'dnd',
    'invisible',
  ];

  String _statusTypeLabel(String type) {
    switch (type) {
      case 'streaming':
        return context.tr.bot_settings_status_type_streaming;
      case 'listening':
        return context.tr.bot_settings_status_type_listening;
      case 'watching':
        return context.tr.bot_settings_status_type_watching;
      case 'competing':
        return context.tr.bot_settings_status_type_competing;
      case 'playing':
      default:
        return context.tr.bot_settings_status_type_playing;
    }
  }

  String _presenceStatusLabel(String status) {
    switch (status) {
      case 'idle':
        return context.tr.bot_settings_presence_idle;
      case 'dnd':
        return context.tr.bot_settings_presence_dnd;
      case 'invisible':
        return context.tr.bot_settings_presence_invisible;
      case 'online':
      default:
        return context.tr.bot_settings_presence_online;
    }
  }

  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView(
      screenName: "AppSettingsPage",
      screenClass: "AppSettingsPage",
      parameters: {"app_id": widget.client.application.id.toString()},
    );
    _init();
    _loadVersions();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _prefixController.dispose();
    _usernameController.dispose();
    _lavalinkHostController.dispose();
    _lavalinkPortController.dispose();
    _lavalinkPasswordController.dispose();
    for (final status in _statusDrafts) {
      status.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    final fetchedApp =
        await widget.client.applications.fetchCurrentApplication();
    final persistedApp = await appManager.getApp(
      widget.client.user.id.toString(),
    );

    final persistedActivities = List<Map<String, dynamic>>.from(
      ((persistedApp['activities'] ?? persistedApp['statuses']) as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item)) ??
          const <Map<String, dynamic>>[],
    );

    // Charger le statut de présence sauvegardé
    final presenceStatus =
        (persistedApp['presenceStatus'] as String?) ?? 'online';
    if (_presenceStatuses.contains(presenceStatus)) {
      _presenceStatus = presenceStatus;
    }
    _builtInLegacyHelpEnabled =
        persistedApp['builtInLegacyHelpEnabled'] != false;

    for (final status in _statusDrafts) {
      status.dispose();
    }
    _statusDrafts.clear();

    for (final status in persistedActivities) {
      _statusDrafts.add(_StatusDraft.fromMap(status));
    }

    // Fetch Discord Application Owner Metadata if we have a token
    final token = (persistedApp['token'] ?? '').toString().trim();
    DiscordApplicationOwnerMetadata? ownerMetadata;
    if (token.isNotEmpty) {
      try {
        ownerMetadata = await getDiscordApplicationOwnerMetadata(token);
      } catch (e) {
        developer.log('Error fetching owner metadata: $e', name: 'AppSettingsPage');
      }
    }

    if (!mounted) return;
    setState(() {
      app = fetchedApp;
      _ownerMetadata = ownerMetadata;
      _savedToken = (persistedApp['token'] ?? '').toString().trim();
      _tokenController.text = _savedToken;
      _prefixController.text =
          (persistedApp['prefix'] ?? '!').toString().trim().isEmpty
              ? '!'
              : (persistedApp['prefix'] ?? '!').toString();
      _usernameController.text = '';
      _selectedAvatarPath = null;
      _runtimeEngine = isJavascriptRuntimeEngine(
            (persistedApp['runtimeEngine'] ?? '').toString(),
          )
          ? runtimeEngineJavascript
          : runtimeEngineDart;
      // Lavalink config
      final lavalinkConfig =
          (persistedApp['lavalinkConfig'] as Map<String, dynamic>?) ?? {};
      _lavalinkHostController.text =
          (lavalinkConfig['host'] ?? '').toString();
      _lavalinkPortController.text =
          (lavalinkConfig['port'] ?? '2333').toString();
      _lavalinkPasswordController.text =
          (lavalinkConfig['password'] ?? 'youshallnotpass').toString();
      _lavalinkSsl = (lavalinkConfig['useSsl'] == true) || (lavalinkConfig['ssl'] == true);
    });
  }

  Future<void> _loadVersions() async {
    final info = await PackageInfo.fromPlatform();
    final client = await RunnerSettings.createClient();
    final rv = await client?.getRunnerVersion();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
      _runnerVersion = rv;
    });
  }

  Future<void> _saveLavalinkOnly() async {
    setState(() {
      _isSavingLavalink = true;
    });

    try {
      final botId = widget.client.user.id.toString();
      final appData = Map<String, dynamic>.from(await appManager.getApp(botId));
      final token = (appData['token'] ?? _savedToken).toString().trim();
      if (token.isEmpty) {
        throw Exception(context.tr.bot_settings_save_token_first);
      }

      final lavalinkConfig = <String, dynamic>{
        'host': _lavalinkHostController.text.trim(),
        'port': _lavalinkPortController.text.trim(),
        'password': _lavalinkPasswordController.text,
        'useSsl': _lavalinkSsl,
      };

      final latestAppData = Map<String, dynamic>.from(appData);
      latestAppData['token'] = token;
      latestAppData['lavalinkConfig'] = lavalinkConfig;
      latestAppData.remove('username');
      latestAppData.remove('avatarPath');
      await appManager.saveApp(botId, latestAppData);

      applyDesktopRuntimeSettings(botId: botId, appData: latestAppData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.bot_settings_save_success)),
      );
      unawaited(refreshBotRuntime(botId));
    } catch (e) {
      developer.log('Error saving lavalink: $e', name: 'AppSettingsPage');
      if (!mounted) return;
      final dialog = AlertDialog(
        title: Text(context.tr.error),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(context.tr.ok),
          ),
        ],
      );
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingLavalink = false;
        });
      }
    }
  }

  Future<void> _testLavalinkConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    final host = _lavalinkHostController.text.trim();
    final port = int.tryParse(_lavalinkPortController.text.trim()) ?? 2333;
    final password = _lavalinkPasswordController.text.trim();
    final useSsl = _lavalinkSsl;

    final error = await LavalinkService.testConnection(
      host: host,
      port: port,
      password: password,
      useSsl: useSsl,
    );

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _connectionTestResult = error ?? '';
      });
    }
  }

  Future<void> _loadPublicServers() async {
    if (_isLoadingServers) return;
    setState(() => _isLoadingServers = true);
    try {
      final servers = await _lavalinkListService.getServers();
      if (mounted) setState(() => _publicServers = servers);
    } finally {
      if (mounted) setState(() => _isLoadingServers = false);
    }
  }

  Future<void> _showServerPicker(BuildContext context) async {
    // Load servers on first open
    if (_publicServers == null) await _loadPublicServers();
    if (_publicServers == null || _publicServers!.isEmpty) return;

    final server = await showDialog<LavalinkServerEntry>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.bot_settings_lavalink_server_picker_title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _publicServers!.length,
            itemBuilder: (ctx, i) {
              final s = _publicServers![i];
              return ListTile(
                leading: Icon(
                  s.secure ? Icons.lock : Icons.public,
                  size: 20,
                ),
                title: Text(s.host, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  context.tr.bot_settings_lavalink_server_subtitle(s.port.toString(), s.version),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, s),
              );
            },
          ),
        ),
      ),
    );

    if (server != null && mounted) {
      setState(() {
        _lavalinkHostController.text = server.host;
        _lavalinkPortController.text = server.port.toString();
        _lavalinkPasswordController.text = server.password;
        _lavalinkSsl = server.secure;
      });
    }
  }

  Future<void> _savePrefixOnly() async {
    setState(() {
      _isSavingPrefix = true;
    });

    try {
      final botId = widget.client.user.id.toString();
      final appData = Map<String, dynamic>.from(await appManager.getApp(botId));
      final token = (appData['token'] ?? _savedToken).toString().trim();
      if (token.isEmpty) {
        throw Exception(context.tr.bot_settings_save_token_first);
      }

      final latestAppData = Map<String, dynamic>.from(appData);
      latestAppData['token'] = token;
      latestAppData['prefix'] =
          _prefixController.text.trim().isEmpty
              ? '!'
              : _prefixController.text.trim();
      latestAppData['builtInLegacyHelpEnabled'] = _builtInLegacyHelpEnabled;
      latestAppData.remove('username');
      latestAppData.remove('avatarPath');

      await appManager.saveApp(botId, latestAppData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.bot_settings_save_success)),
      );
      unawaited(refreshBotRuntime(botId));
    } catch (e) {
      developer.log('Error saving prefix: $e', name: 'AppSettingsPage');
      if (!mounted) return;
      final dialog = AlertDialog(
        title: Text(context.tr.error),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(context.tr.ok),
          ),
        ],
      );
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPrefix = false;
        });
      }
    }
  }

  Future<void> _saveTokenOnly() async {
    setState(() {
      _isSavingToken = true;
    });

    try {
      final effectiveToken = _tokenController.text.trim();
      if (effectiveToken.isEmpty) {
        throw Exception(context.tr.bot_settings_token_required);
      }

      final discordUser = await getDiscordUser(effectiveToken);

      // ── Bot ID mismatch check ─────────────────────────────────────────────
      final localBotId = widget.client.user.id.toString();
      final newBotId = discordUser.id.toString();
      if (newBotId != localBotId) {
        if (!mounted) return;
        final proceed = await AppTheme.showConfirmDialog(
          context,
          title: context.tr.bot_settings_token_mismatch_title,
          content: context.tr.bot_settings_token_mismatch_content(
            newBotId,
            localBotId,
          ),
          confirmLabel: context.tr.bot_settings_token_mismatch_confirm,
        );
        if (!proceed || !mounted) return;
      }

      final intentOutcome = await fetchPortalIntentsWithOutcome(effectiveToken);
      final computedIntents = intentOutcome.intents;

      await appManager.createOrUpdateApp(
        id: discordUser.id,
        username: discordUser.username,
        avatarHash: discordUser.avatarHash,
        discriminator: discordUser.discriminator.toString(),
        token: effectiveToken,
        intents: computedIntents,
        prefix:
            _prefixController.text.trim().isEmpty
                ? '!'
                : _prefixController.text,
      );

      final appData = Map<String, dynamic>.from(
        await appManager.getApp(discordUser.id.toString()),
      );
      appData['builtInLegacyHelpEnabled'] = _builtInLegacyHelpEnabled;
      appData.remove('username');
      appData.remove('avatarPath');
      await appManager.saveApp(discordUser.id.toString(), appData);

      // Push to cloud if configured
      try {
        final apiConfig = await MainApiSettingsStore.loadConfig();
        if (apiConfig.isConfigured) {
          final client = MainApiClient(baseUrl: apiConfig.baseUrl);
          final session = await client.exchangeDiscordBotToken(botToken: effectiveToken);
          final apiClient = MainApiClient(
            baseUrl: apiConfig.baseUrl,
            accessToken: session.accessToken,
          );
          await apiClient.syncBot(
            discordUser.id.toString(),
            discordUser.username,
            appData,
          );
        }
      } catch (e) {
        developer.log('Failed to sync token to cloud: $e', name: 'AppSettingsPage');
      }

      _savedToken = effectiveToken;
      _isEditingToken = false;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.bot_settings_token_saved)),
      );
      showPortalIntentOutcomeSnackbars(context, intentOutcome);
      unawaited(refreshBotRuntime(discordUser.id.toString()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToken = false;
        });
      }
    }
  }

  Future<void> _saveProfileAndStatuses() async {
    setState(() {
      _isSavingProfile = true;
    });

    try {
      final activities = _collectActivities();
      final appData = Map<String, dynamic>.from(
        await appManager.getApp(widget.client.user.id.toString()),
      );
      final token = (appData['token'] ?? _savedToken).toString().trim();
      if (token.isEmpty) {
        throw Exception(context.tr.bot_settings_save_token_first);
      }

      final trimmedUsername = _usernameController.text.trim();
      final trimmedAvatarPath = (_selectedAvatarPath ?? '').trim();
      if (trimmedAvatarPath.isNotEmpty &&
          !isSupportedDiscordAvatarPath(trimmedAvatarPath)) {
        final ext = avatarFileExtension(trimmedAvatarPath) ?? 'unknown';
        throw Exception(
          context.tr.bot_settings_avatar_unsupported_format(
            ext,
            supportedDiscordAvatarFormatsLabel(),
          ),
        );
      }
      final shouldUpdateProfile =
          trimmedUsername.isNotEmpty || trimmedAvatarPath.isNotEmpty;

      String botId = widget.client.user.id.toString();
      if (shouldUpdateProfile) {
        final discordUser = await updateDiscordBotProfile(
          token,
          username: trimmedUsername.isNotEmpty ? trimmedUsername : null,
          avatarPath: trimmedAvatarPath.isNotEmpty ? trimmedAvatarPath : null,
        );
        botId = discordUser.id.toString();

        final intents = Map<String, bool>.from(
          (appData['intents'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value == true),
              ) ??
              const <String, bool>{},
        );
        await appManager.createOrUpdateApp(
          id: discordUser.id,
          username: discordUser.username,
          avatarHash: discordUser.avatarHash,
          discriminator: discordUser.discriminator.toString(),
          token: token,
          intents: intents,
          prefix:
              _prefixController.text.trim().isEmpty
                  ? '!'
                  : _prefixController.text,
        );
      }

      final latestAppData = Map<String, dynamic>.from(
        await appManager.getApp(botId),
      );
      latestAppData['activities'] = activities;
      latestAppData['statuses'] = activities
          .map(
            (activity) => {
              'type': activity['type'],
              'text': activity['name'],
              'minIntervalSeconds': activity['minIntervalSeconds'],
              'maxIntervalSeconds': activity['maxIntervalSeconds'],
            },
          )
          .toList(growable: false);
      latestAppData['presenceStatus'] = _presenceStatus;
      latestAppData['builtInLegacyHelpEnabled'] = _builtInLegacyHelpEnabled;
      latestAppData.remove('username');
      latestAppData.remove('avatarPath');

      await appManager.saveApp(botId, latestAppData);

      applyDesktopRuntimeSettings(botId: botId, appData: latestAppData);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.bot_settings_profile_saved)),
      );
      unawaited(refreshBotRuntime(botId));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _collectActivities() {
    final normalized = <Map<String, dynamic>>[];

    for (var i = 0; i < _statusDrafts.length; i++) {
      final draft = _statusDrafts[i];
      final name = draft.textController.text.trim();
      final state = draft.stateController.text.trim();
      final url = draft.urlController.text.trim();
      final min = int.tryParse(draft.minController.text.trim()) ?? 60;
      final max = int.tryParse(draft.maxController.text.trim()) ?? min;

      if (name.isEmpty) {
        throw FormatException('Activity #${i + 1}: name is required.');
      }
      if (min <= 0 || max <= 0) {
        throw FormatException(
          'Activity #${i + 1}: min/max interval must be > 0.',
        );
      }
      if (max < min) {
        throw FormatException(
          'Activity #${i + 1}: max interval must be >= min interval.',
        );
      }
      if (draft.type == 'streaming') {
        if (url.isEmpty) {
          throw FormatException(
            'Activity #${i + 1}: stream URL is required for streaming type.',
          );
        }
        final parsed = Uri.tryParse(url);
        final isValid =
            parsed != null &&
            (parsed.scheme == 'http' || parsed.scheme == 'https') &&
            (parsed.host.isNotEmpty);
        if (!isValid) {
          throw FormatException(
            'Activity #${i + 1}: stream URL must be a valid http/https URL.',
          );
        }
      }

      normalized.add({
        'type': draft.type,
        'name': name,
        'text': name,
        'state': state,
        'url': url,
        'minIntervalSeconds': min,
        'maxIntervalSeconds': max,
      });
    }

    return normalized;
  }

  bool _isDeletingBot = false;

  Future<void> _forceSyncDiscordCommands() async {
    final botId = widget.client.user.id.toString();
    final confirm = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.settings_sync_force_dialog_title,
      content: context.tr.settings_sync_force_dialog_desc,
      confirmLabel: context.tr.settings_sync_force_dialog_confirm,
      isDestructive: true,
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isForceSyncing = true;
    });

    try {
      final localCommands = await appManager.listAppCommands(botId);
      final localCommandIds = localCommands
          .map((c) => (c['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      final remoteCommands = await widget.client.commands.list();

      int deletedCount = 0;
      for (final remoteCmd in remoteCommands) {
        final remoteId = remoteCmd.id.toString();
        if (!localCommandIds.contains(remoteId)) {
          await widget.client.commands.delete(remoteCmd.id);
          deletedCount++;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr.settings_sync_force_success(deletedCount),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.settings_sync_force_error(e.toString())),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isForceSyncing = false;
        });
      }
    }
  }

  Future<void> _deleteBot() async {
    final botId = widget.client.user.id.toString();
    final confirm = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.bot_settings_delete_title,
      content: context.tr.bot_settings_delete_desc(botId),
      confirmLabel: context.tr.delete,
      isDestructive: true,
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isDeletingBot = true;
    });

    try {
      // Cloud + local deletion in one call.
      await appManager.deleteBotCompletely(botId);

      if (!mounted) return;

      // 3. Navigate home and sync
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Trigger a sync of all bots to refresh the home page UI.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HomePageState.current?.syncAllBotsFromManager();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${context.tr.error}: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingBot = false;
        });
      }
    }
  }

  Future<void> _pickAvatarFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedDiscordAvatarFormats,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.first.path;
    if (path == null || path.isEmpty) {
      return;
    }

    if (!isSupportedDiscordAvatarPath(path)) {
      if (!mounted) {
        return;
      }
      final ext = avatarFileExtension(path) ?? 'unknown';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr.bot_settings_avatar_unsupported_format(
              ext,
              supportedDiscordAvatarFormatsLabel(),
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedAvatarPath = path;
    });
  }

  Widget _buildGeneralTab(double contentMaxWidth) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfilePreviewCard(),
              _buildTeamOwnershipSection(),
              
              // Token Update Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.tr.bot_settings_token_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_isEditingToken) ...[
                Text(
                  context.tr.bot_settings_token_hidden_desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _tokenController.text = _savedToken;
                        _isEditingToken = true;
                      });
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(context.tr.bot_settings_edit_token_btn),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: context.tr.bot_settings_update_token,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.all(8),
                    hintText: context.tr.bot_settings_token_hint,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isSavingToken
                            ? null
                            : () {
                              setState(() {
                                _tokenController.text = _savedToken;
                                _isEditingToken = false;
                              });
                            },
                    icon: const Icon(Icons.close),
                    label: Text(
                      context.tr.bot_settings_cancel_token_edit_btn,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                context.tr.bot_settings_save_token_caption,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_isSavingToken || !_isEditingToken)
                          ? null
                          : () async {
                            try {
                              await _saveTokenOnly();
                            } catch (e) {
                              developer.log(
                                'Error saving token: $e',
                                name: 'AppSettingsPage',
                              );
                              if (!mounted) return;
                              final dialog = AlertDialog(
                                title: Text(context.tr.error),
                                content: Text(e.toString()),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(context.tr.ok),
                                  ),
                                ],
                              );
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return dialog;
                                },
                              );
                            }
                          },
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: Text(
                    context.tr.bot_settings_save_token_only_btn,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Runtime engine',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _runtimeEngine,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  helperText:
                      'JavaScript bots require a JS runner (embedded or external).',
                ),
                items: const [
                  DropdownMenuItem(
                    value: runtimeEngineDart,
                    child: Text('Bot Creator (Dart / blocks)'),
                  ),
                  DropdownMenuItem(
                    value: runtimeEngineJavascript,
                    child: Text('JavaScript (runner-js)'),
                  ),
                ],
                onChanged: _isSwitchingRuntimeEngine ? null : _onRuntimeEngineChanged,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Prefix Management Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.tr.settings_legacy_prefix,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextField(
                controller: _prefixController,
                decoration: InputDecoration(
                  labelText: context.tr.settings_legacy_prefix,
                  border: const OutlineInputBorder(),
                  hintText: context.tr.settings_legacy_prefix_hint,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.settings_legacy_prefix_helper,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr.settings_builtin_help),
                subtitle: Text(
                  context.tr.settings_builtin_help_subtitle,
                ),
                value: _builtInLegacyHelpEnabled,
                onChanged: (value) {
                  setState(() {
                    _builtInLegacyHelpEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingPrefix ? null : _savePrefixOnly,
                  icon:
                      _isSavingPrefix
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.save_outlined),
                  label: Text(context.tr.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceTab(double contentMaxWidth) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfilePreviewCard(),

              // Profile Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.tr.bot_settings_profile_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: context.tr.bot_settings_username_override,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(8),
                  hintText: context.tr.bot_settings_username_hint,
                ),
                controller: _usernameController,
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              
              Card(
                color: AppTheme.discordDarkerBg,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: AppTheme.discordBorder.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.bot_settings_avatar_preview_label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.discordBorder,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _selectedAvatarPath != null
                                      ? Image.file(
                                          File(_selectedAvatarPath!),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          (widget.client.user as User).avatar.url.toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppTheme.discordBorder,
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (_selectedAvatarPath != null)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.success,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _pickAvatarFile,
                                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      label: Text(context.tr.bot_settings_browse),
                                    ),
                                    if (_selectedAvatarPath != null) ...[
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _selectedAvatarPath = null;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.error,
                                          side: const BorderSide(color: AppTheme.error),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.clear, size: 16),
                                        label: Text(context.tr.bot_settings_avatar_clear_selection),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_selectedAvatarPath != null) ...[
                                  Text(
                                    context.tr.bot_settings_avatar_selected,
                                    style: const TextStyle(
                                      color: AppTheme.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SelectableText(
                                    Uri.file(_selectedAvatarPath!).pathSegments.last,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ] else
                                  Text(
                                    context.tr.bot_settings_avatar_none_selected,
                                    style: const TextStyle(
                                      color: AppTheme.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.discord.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.discord.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.discord,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.tr.bot_settings_avatar_important_note,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.discordText,
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

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Presence Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.tr.bot_settings_presence_status_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _presenceStatus,
                  decoration: InputDecoration(
                    labelText:
                        context.tr.bot_settings_presence_status_label,
                    border: const OutlineInputBorder(),
                  ),
                  items: _presenceStatuses
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(_presenceStatusLabel(status)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _presenceStatus = value;
                    });
                  },
                ),
              ),

              if (_capabilities.supportsStatusRotation) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // Status Rotation Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    context.tr.bot_settings_status_rotation_title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.tr.bot_settings_status_rotation_desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _statusDrafts.add(_StatusDraft.empty());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text(context.tr.bot_settings_add_status),
                ),
              ),
              const SizedBox(height: 8),
              if (_statusDrafts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.grey.withValues(alpha: 0.5),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr.bot_settings_no_activities,
                          style: const TextStyle(color: AppTheme.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ...List.generate(_statusDrafts.length, (index) {
                final draft = _statusDrafts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr
                                    .bot_settings_status_item_title(
                                      index + 1,
                                    ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip:
                                  context.tr.bot_settings_remove_status,
                              onPressed: () async {
                                        final shouldDelete =
                                            await AppTheme.showConfirmDialog(
                                              context,
                                              title:
                                                  context
                                                      .tr
                                                      .bot_settings_remove_status,
                                              content:
                                                  context
                                                      .tr
                                                      .settings_status_remove_confirm,
                                              confirmLabel:
                                                  context.tr.delete,
                                              isDestructive: true,
                                            );
                                        if (!shouldDelete) {
                                          return;
                                        }
                                        setState(() {
                                          final removed = _statusDrafts
                                              .removeAt(index);
                                          removed.dispose();
                                        });
                                      },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: draft.type,
                          decoration: InputDecoration(
                            labelText:
                                context
                                    .tr
                                    .bot_settings_status_type_label,
                            border: const OutlineInputBorder(),
                          ),
                          items: _statusTypes
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(_statusTypeLabel(type)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              draft.type = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: draft.textController,
                          decoration: InputDecoration(
                            labelText:
                                context
                                    .tr
                                    .bot_settings_status_text_label,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: draft.stateController,
                          decoration: InputDecoration(
                            labelText:
                                context
                                    .tr
                                    .bot_settings_activity_state_label,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: draft.urlController,
                          decoration: InputDecoration(
                            labelText:
                                context
                                    .tr
                                    .bot_settings_activity_url_label,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: draft.minController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText:
                                      context
                                          .tr
                                          .bot_settings_status_min_interval,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: draft.maxController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText:
                                      context
                                          .tr
                                          .bot_settings_status_max_interval,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              ],

              const SizedBox(height: 12),
              Text(
                context.tr.bot_settings_save_profile_caption,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _isSavingProfile
                          ? null
                          : () async {
                            try {
                              await _saveProfileAndStatuses();
                            } catch (e) {
                              developer.log(
                                'Error saving profile/statuses: $e',
                                name: 'AppSettingsPage',
                              );
                              if (!mounted) return;
                              final dialog = AlertDialog(
                                title: Text(context.tr.error),
                                content: Text(e.toString()),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(context.tr.ok),
                                  ),
                                ],
                              );
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return dialog;
                                },
                              );
                            }
                          },
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    context.tr.bot_settings_save_profile_status_btn,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLavalinkTab(double contentMaxWidth) {
    final isPremium = PremiumCapabilities.hasCapability(PremiumCapability.lavalinkAudio);
    final canPurchase = PremiumCapabilities.canShowPurchaseUI;

    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.discordBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.discordBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.discord, width: 2),
      ),
      filled: true,
      fillColor: AppTheme.discordDarkBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium banner
              if (!isPremium) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.discord.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          AppTheme.discord.withValues(alpha: 0.3),
                    ),
                  ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: AppTheme.discord),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr.bot_settings_lavalink_premium_banner_title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.discord,
                                ),
                              ),
                              if (canPurchase)
                                Text(
                                  context.tr.bot_settings_lavalink_premium_banner_desc,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (canPurchase) ...[
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              SubscriptionPage.show(context);
                            },
                            child: Text(context.tr.bot_settings_lavalink_view_offers),
                          ),
                        ],
                      ],
                    ),
                ),
                const SizedBox(height: 16),
              ],

              // Section title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.music_note, color: AppTheme.discord),
                    const SizedBox(width: 10),
                    Text(
                      context.tr.bot_settings_lavalink_section_title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Public server list picker
              if (isPremium) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.public, size: 16, color: AppTheme.discord),
                            const SizedBox(width: 8),
                            Text(
                              context.tr.bot_settings_lavalink_public_servers,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (_isLoadingServers)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoadingServers
                                ? null
                                : () => _showServerPicker(context),
                            icon: const Icon(Icons.list),
                            label: Text(
                              _publicServers != null
                                  ? context.tr.bot_settings_lavalink_servers_available(_publicServers!.length)
                                  : context.tr.bot_settings_lavalink_choose_server,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Host field
              Row(
                children: [
                  if (!isPremium)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.lock, size: 16, color: AppTheme.grey),
                    ),
                  Text(context.tr.bot_settings_lavalink_host),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _lavalinkHostController,
                enabled: isPremium,
                decoration: inputDecoration.copyWith(
                  hintText: context.tr.bot_settings_lavalink_host_hint,
                ),
              ),
              const SizedBox(height: 16),

              // Port field
              Row(
                children: [
                  if (!isPremium)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.lock, size: 16, color: AppTheme.grey),
                    ),
                  Text(context.tr.bot_settings_lavalink_port),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _lavalinkPortController,
                enabled: isPremium,
                keyboardType: TextInputType.number,
                decoration: inputDecoration.copyWith(
                  hintText: context.tr.bot_settings_lavalink_port_hint,
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              Row(
                children: [
                  if (!isPremium)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.lock, size: 16, color: AppTheme.grey),
                    ),
                  Text(context.tr.bot_settings_lavalink_password),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _lavalinkPasswordController,
                enabled: isPremium,
                obscureText: !_lavalinkPasswordVisible,
                decoration: inputDecoration.copyWith(
                  hintText: context.tr.bot_settings_lavalink_password_hint,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _lavalinkPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _lavalinkPasswordVisible =
                            !_lavalinkPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SSL toggle
              SwitchListTile(
                title: Row(
                  children: [
                    if (!isPremium)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child:
                            Icon(Icons.lock, size: 16, color: AppTheme.grey),
                      ),
                    Text(context.tr.bot_settings_lavalink_ssl),
                  ],
                ),
                subtitle: Text(
                  context.tr.bot_settings_lavalink_ssl_subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                ),
                value: _lavalinkSsl,
                onChanged: isPremium
                    ? (value) {
                        setState(() {
                          _lavalinkSsl = value;
                        });
                      }
                    : null,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              const SizedBox(height: 12),

              Text(
                context.tr.bot_settings_lavalink_save_caption,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingLavalink ? null : _saveLavalinkOnly,
                  icon: const Icon(Icons.music_note),
                  label: Text(context.tr.bot_settings_lavalink_save_btn),
                ),
              ),
              const SizedBox(height: 8),
              // Test connection button
              if (isPremium) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isTestingConnection ? null : _testLavalinkConnection,
                    icon: _isTestingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(
                      _isTestingConnection
                          ? context.tr.bot_settings_lavalink_testing
                          : context.tr.bot_settings_lavalink_test_btn,
                    ),
                  ),
                ),
                if (_connectionTestResult != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _connectionTestResult!.isEmpty
                            ? Icons.check_circle
                            : Icons.error,
                        size: 16,
                        color: _connectionTestResult!.isEmpty
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _connectionTestResult!.isEmpty
                            ? context.tr.bot_settings_lavalink_success
                            : _connectionTestResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _connectionTestResult!.isEmpty
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedTab(double contentMaxWidth) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Utility Cards
              Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(context.tr.bot_settings_workflow_docs),
                  subtitle: Text(
                    context.tr.bot_settings_workflow_docs_desc,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const WorkflowDocumentationPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.import_export),
                  title: Text(context.tr.bot_settings_export_import),
                  subtitle: Text(
                    context.tr.bot_settings_export_import_desc,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => BotExportImportPage(
                              botId:
                                  widget.client.application.id
                                      .toString(),
                            ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.settings_version_title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_android, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${context.tr.settings_app_version}: $_appVersion',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.dns_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${context.tr.settings_runner_version}: ${_runnerVersion ?? context.tr.settings_runner_not_connected}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Force Sync Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.tr.settings_sync_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: AppTheme.grey.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.settings_sync_force_title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr.settings_sync_force_desc,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isForceSyncing ? null : _forceSyncDiscordCommands,
                          icon: _isForceSyncing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(context.tr.settings_sync_force_button),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Danger Zone
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.tr.bot_settings_danger_zone,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.error,
                  ),
                ),
              ),
              Card(
                color: AppTheme.error.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: AppTheme.error.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.bot_settings_delete_bot,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr.bot_settings_delete_bot_desc,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isDeletingBot ? null : _deleteBot,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(
                              color: AppTheme.error,
                            ),
                          ),
                          icon:
                              _isDeletingBot
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                            AppTheme.error,
                                          ),
                                    ),
                                  )
                                  : const Icon(Icons.delete_forever),
                          label: Text(
                            context.tr.bot_settings_delete_bot_btn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showLavalink = _capabilities.supportsLavalink;
    final tabCount = showLavalink ? 4 : 3;

    return DefaultTabController(
      key: ValueKey('bot-settings-tabs-$tabCount'),
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr.bot_settings_title),
          automaticallyImplyLeading: false,
          leading: !ResponsiveHelper.isDesktopPlatform()
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => context.openParentDrawer(),
                )
              : null,
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                icon: const Icon(Icons.settings),
                text: context.tr.bot_settings_tab_general,
              ),
              Tab(
                icon: const Icon(Icons.emoji_emotions_outlined),
                text: context.tr.bot_settings_tab_presence,
              ),
              if (showLavalink)
                Tab(
                  icon: const Icon(Icons.music_note),
                  text: context.tr.bot_settings_tab_lavalink,
                ),
              Tab(
                icon: const Icon(Icons.build_outlined),
                text: context.tr.bot_settings_tab_advanced,
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentMaxWidth = constraints.maxWidth >= 900 ? 760.0 : 640.0;
              return TabBarView(
                children: [
                  _buildGeneralTab(contentMaxWidth),
                  _buildPresenceTab(contentMaxWidth),
                  if (showLavalink) _buildLavalinkTab(contentMaxWidth),
                  _buildAdvancedTab(contentMaxWidth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePreviewCard() {
    final user = widget.client.user as User;
    final botName =
        _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : user.username;

    // Discord Status Colors
    Color statusColor;
    switch (_presenceStatus) {
      case 'idle':
        statusColor = const Color(0xFFF0B232);
        break;
      case 'dnd':
        statusColor = const Color(0xFFF23F43);
        break;
      case 'invisible':
      case 'offline':
        statusColor = const Color(0xFF80848E);
        break;
      case 'online':
      default:
        statusColor = const Color(0xFF23A55A);
        break;
    }

    // Activity preview
    String? activityTypeLabel;
    String? activityText;
    String? activityState;
    String? activityUrl;
    bool isStreaming = false;

    if (_statusDrafts.isNotEmpty) {
      final first = _statusDrafts.first;
      activityText = first.textController.text.trim();
      activityState = first.stateController.text.trim();
      activityUrl = first.urlController.text.trim();
      isStreaming = first.type == 'streaming';
      activityTypeLabel = _statusTypeLabel(first.type).toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.discordDarkerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.discordBorder.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.discord,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: GestureDetector(
                  onTap: _pickAvatarFile,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.discordDarkerBg,
                            border: Border.all(
                              color: AppTheme.discordDarkerBg,
                              width: 6,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipOval(
                                  child:
                                      _selectedAvatarPath != null
                                          ? Image.file(
                                            File(_selectedAvatarPath!),
                                            fit: BoxFit.cover,
                                          )
                                          : Image.network(
                                            user.avatar.url.toString(),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, _, _) => Container(
                                                  color: AppTheme.discordBorder,
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                                ),
                                          ),
                                ),
                              ),
                              // Edit Overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.discordDarkerBg,
                              border: Border.all(
                                color: AppTheme.discordDarkerBg,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 55),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        botName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.discord,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'APP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "${botName.toLowerCase().replaceAll(' ', '')}#${user.discriminator}",
                  style: const TextStyle(
                    color: AppTheme.discordText,
                    fontSize: 14,
                  ),
                ),
                if (activityText != null && activityText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.discordBorder, height: 1),
                  const SizedBox(height: 16),
                  Text(
                    isStreaming ? "EN DIRECT" : activityTypeLabel ?? "ACTIVITÉ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        isStreaming
                            ? Icons.videocam_outlined
                            : Icons.videogame_asset_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activityTypeLabel ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              activityText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            if (activityState != null &&
                                activityState.isNotEmpty)
                              Text(
                                activityState,
                                style: const TextStyle(
                                  color: AppTheme.discordText,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isStreaming &&
                      activityUrl != null &&
                      activityUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.discordDarkBg,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          context.tr.bot_settings_status_type_streaming,
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamOwnershipSection() {
    if (_ownerMetadata == null) {
      return const SizedBox.shrink();
    }

    final meta = _ownerMetadata!;
    final hasTeam = meta.teamId.isNotEmpty;

    // Pretty-printed raw JSON string
    String prettyJson = '';
    try {
      prettyJson = const JsonEncoder.withIndent('  ').convert(meta.rawJson);
    } catch (_) {
      prettyJson = meta.rawJson.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.discordDarkerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.discordBorder.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.discordDarkBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  hasTeam ? Icons.groups_outlined : Icons.person_outline,
                  color: AppTheme.discord,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasTeam ? context.tr.settings_team_ownership : context.tr.settings_personal_ownership,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (hasTeam ? AppTheme.discord : AppTheme.success).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (hasTeam ? AppTheme.discord : AppTheme.success).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    hasTeam ? context.tr.settings_team_pill : context.tr.settings_solo_pill,
                    style: TextStyle(
                      color: hasTeam ? AppTheme.discord : AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Visual Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasTeam) ...[
                  // Team Name
                  Row(
                    children: [
                      Text(
                        context.tr.settings_team_name_label,
                        style: const TextStyle(color: AppTheme.discordText, fontSize: 13),
                      ),
                      Text(
                        meta.teamName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        context.tr.settings_team_id_label,
                        style: const TextStyle(color: AppTheme.discordText, fontSize: 13),
                      ),
                      SelectableText(
                        meta.teamId,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Team Owner
                  Text(
                    context.tr.settings_team_owner_label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.discordText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.discordDarkBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meta.teamOwnerUsername.isNotEmpty
                                    ? meta.teamOwnerUsername
                                    : context.tr.settings_owner_fallback,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText(
                                meta.teamOwnerUserId,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppTheme.discordText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.tr.settings_owner_badge,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Team Members
                  Text(
                    context.tr.settings_team_members_label(meta.teamMembersInfo.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.discordText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: meta.teamMembersInfo.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final member = meta.teamMembersInfo[idx];
                      final isOwner = member['id'] == meta.teamOwnerUserId;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.discordDarkBg.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppTheme.discord,
                              backgroundImage: member['avatar'] != null && member['avatar'].toString().isNotEmpty
                                  ? NetworkImage(makeAvatarUrl(member['id'].toString(), avatarId: member['avatar'].toString()))
                                  : null,
                              child: member['avatar'] == null || member['avatar'].toString().isEmpty
                                  ? const Icon(Icons.person, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['username']?.toString() ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SelectableText(
                                    member['id']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: AppTheme.discordText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isOwner ? Colors.amber : AppTheme.discord).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isOwner ? context.tr.settings_owner_badge : member['role']?.toString().toUpperCase() ?? context.tr.settings_member_badge,
                                style: TextStyle(
                                  color: isOwner ? Colors.amber : AppTheme.discord,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // Personal Owner info
                  Row(
                    children: [
                      Text(
                        context.tr.settings_personal_owner_label,
                        style: const TextStyle(color: AppTheme.discordText, fontSize: 13),
                      ),
                      Text(
                        meta.ownerUsername.isNotEmpty ? meta.ownerUsername : context.tr.settings_personal_owner_fallback,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        context.tr.settings_personal_owner_id_label,
                        style: const TextStyle(color: AppTheme.discordText, fontSize: 13),
                      ),
                      SelectableText(
                        meta.ownerId,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Collapsible JSON View
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Material(
              color: Colors.transparent,
              child: ExpansionTile(
                title: Text(
                  context.tr.settings_raw_json_tile,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.discordText,
                  ),
                ),
                leading: const Icon(Icons.code, size: 20, color: AppTheme.discordText),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                expandedAlignment: Alignment.topLeft,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.discordDarkBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.discordBorder.withValues(alpha: 0.4),
                      ),
                    ),
                    child: SelectableText(
                      prettyJson,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.lightGreenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDraft {
  String type;
  final TextEditingController textController;
  final TextEditingController stateController;
  final TextEditingController urlController;
  final TextEditingController minController;
  final TextEditingController maxController;

  _StatusDraft({
    required this.type,
    required this.textController,
    required this.stateController,
    required this.urlController,
    required this.minController,
    required this.maxController,
  });

  factory _StatusDraft.empty() {
    return _StatusDraft(
      type: 'playing',
      textController: TextEditingController(),
      stateController: TextEditingController(),
      urlController: TextEditingController(),
      minController: TextEditingController(text: '60'),
      maxController: TextEditingController(text: '60'),
    );
  }

  factory _StatusDraft.fromMap(Map<String, dynamic> map) {
    final min =
        int.tryParse((map['minIntervalSeconds'] ?? '').toString()) ?? 60;
    final maxRaw =
        int.tryParse((map['maxIntervalSeconds'] ?? '').toString()) ?? min;
    final max = maxRaw < min ? min : maxRaw;

    final type = (map['type'] ?? 'playing').toString().trim().toLowerCase();
    return _StatusDraft(
      type:
          _AppSettingsPageState._statusTypes.contains(type) ? type : 'playing',
      textController: TextEditingController(
        text: ((map['name'] ?? map['text']) ?? '').toString(),
      ),
      stateController: TextEditingController(
        text: (map['state'] ?? '').toString(),
      ),
      urlController: TextEditingController(text: (map['url'] ?? '').toString()),
      minController: TextEditingController(text: '$min'),
      maxController: TextEditingController(text: '$max'),
    );
  }

  void dispose() {
    textController.dispose();
    stateController.dispose();
    urlController.dispose();
    minController.dispose();
    maxController.dispose();
  }
}

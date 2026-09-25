import 'dart:io';
import 'dart:async';
import 'package:bot_creator/core/platform/run_platform.dart';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/export_import.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_dashboard.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/logic/js_runner_capabilities.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_application_commands.dart';
import 'package:bot_creator/core/utils/bot_payload_guard.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_identity_sync.dart';

import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/core/network/main_api_client.dart'
    hide DiscordBotIdentity;
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:bot_creator/core/discord/portal_intent_feedback.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/lavalink_settings_section.dart';
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
  String? _selectedBannerPath;
  String? _currentBannerUrl;
  int? _bannerAccentColor;
  bool _removeBanner = false;
  bool _builtInLegacyHelpEnabled = true;
  final List<_StatusDraft> _statusDrafts = <_StatusDraft>[];
  String _presenceStatus = 'online';
  String _runtimeEngine = runtimeEngineDart;
  bool _isSwitchingRuntimeEngine = false;
  // Lavalink : la page ne pilote que l'interrupteur et les serveurs de repli
  // (schéma figé « lavalink » : enabled + custom_servers). La liste publique est
  // sondée par le bot, jamais choisie ni stockée ici.
  Map<String, dynamic>? _lavalinkConfigRaw;
  // External Database fields (JavaScript bots)
  String _databaseType = 'none';
  final TextEditingController _databaseUriController = TextEditingController();
  final TextEditingController _databaseHostController = TextEditingController();
  final TextEditingController _databasePortController = TextEditingController();
  final TextEditingController _databaseNameController = TextEditingController();
  final TextEditingController _databaseUserController = TextEditingController();
  final TextEditingController _databasePasswordController =
      TextEditingController();
  bool _databaseSsl = false;
  bool _showAdvancedDbFields = false;
  bool _isSavingDatabase = false;
  bool _databasePasswordVisible = false;

  static const List<String> _statusTypes = <String>[
    'playing',
    'streaming',
    'listening',
    'watching',
    'competing',
  ];

  // Une seule règle dans toute l'application (voir `run_platform.dart`) : les réglages du
  // bot doivent pouvoir viser le serveur depuis un poste de travail.
  bool get _supportsManagerRuntime => supportsManagerRuntime;

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
        SnackBar(
          content: Text(context.tr.settings_runtime_engine_switch_success),
        ),
      );
    } on DegenerateBotPayloadException {
      // POURQUOI un message dédié : la bascule a été REFUSÉE avant tout
      // effacement. Afficher le diagnostic brut de la garde ferait croire à une
      // panne alors que, précisément, rien n'a été touché.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr.settings_runtime_engine_switch_empty_payload,
          ),
          backgroundColor: AppTheme.error,
        ),
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
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _prefixController.dispose();
    _usernameController.dispose();
    _databaseUriController.dispose();
    _databaseHostController.dispose();
    _databasePortController.dispose();
    _databaseNameController.dispose();
    _databaseUserController.dispose();
    _databasePasswordController.dispose();
    for (final status in _statusDrafts) {
      status.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    final fetchedApp = await widget.client.applications
        .fetchCurrentApplication();
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

    // Fetch Bot Identity if we have a token
    final token = (persistedApp['token'] ?? '').toString().trim();
    DiscordBotIdentity? botIdentity;
    if (token.isNotEmpty) {
      try {
        botIdentity = await fetchDiscordBotIdentity(token: token);
      } catch (e) {
        developer.log(
          'Error fetching bot identity: $e',
          name: 'AppSettingsPage',
        );
      }
    }

    if (!mounted) return;
    setState(() {
      app = fetchedApp;
      _currentBannerUrl = makeBannerUrl(
        widget.client.user.id.toString(),
        bannerHash: botIdentity?.bannerHash,
      );
      _bannerAccentColor = botIdentity?.accentColor;
      _selectedBannerPath = null;
      _removeBanner = false;
      _savedToken = (persistedApp['token'] ?? '').toString().trim();
      _tokenController.text = _savedToken;
      _prefixController.text =
          (persistedApp['prefix'] ?? '!').toString().trim().isEmpty
          ? '!'
          : (persistedApp['prefix'] ?? '!').toString();
      _usernameController.text = '';
      _selectedAvatarPath = null;
      _runtimeEngine =
          isJavascriptRuntimeEngine(
            (persistedApp['runtimeEngine'] ?? '').toString(),
          )
          ? runtimeEngineJavascript
          : runtimeEngineDart;
      // Lavalink config (schéma figé : enabled + custom_servers ; l'ancienne
      // forme est relue par le module, jamais réécrite).
      final lavalinkConfig = persistedApp['lavalinkConfig'];
      _lavalinkConfigRaw = lavalinkConfig is Map
          ? Map<String, dynamic>.from(lavalinkConfig)
          : null;
      // Database config
      final databaseConfig =
          (persistedApp['databaseConfig'] as Map<String, dynamic>?) ?? {};
      _databaseType = (databaseConfig['type'] ?? 'none').toString();
      _databaseUriController.text = (databaseConfig['uri'] ?? '').toString();
      _databaseHostController.text = (databaseConfig['host'] ?? '').toString();
      _databasePortController.text = (databaseConfig['port'] ?? '').toString();
      _databaseNameController.text = (databaseConfig['database'] ?? '')
          .toString();
      _databaseUserController.text = (databaseConfig['user'] ?? '').toString();
      _databasePasswordController.text = (databaseConfig['password'] ?? '')
          .toString();
      _databaseSsl = databaseConfig['ssl'] == true;
    });
  }

  /// Persiste la charge utile Lavalink conforme au schéma figé
  /// (`enabled` + `custom_servers`) — l'ancienne forme n'est plus écrite.
  Future<void> _saveLavalinkConfig(Map<String, dynamic> lavalinkConfig) async {
    try {
      final botId = widget.client.user.id.toString();
      final appData = Map<String, dynamic>.from(await appManager.getApp(botId));
      final token = (appData['token'] ?? _savedToken).toString().trim();
      if (token.isEmpty) {
        throw Exception(context.tr.bot_settings_save_token_first);
      }

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
    }
  }

  Future<void> _saveDatabaseOnly() async {
    setState(() {
      _isSavingDatabase = true;
    });

    try {
      final botId = widget.client.user.id.toString();
      final appData = Map<String, dynamic>.from(await appManager.getApp(botId));
      final token = (appData['token'] ?? _savedToken).toString().trim();
      if (token.isEmpty) {
        throw Exception(context.tr.bot_settings_save_token_first);
      }

      final databaseConfig = <String, dynamic>{
        'type': _databaseType,
        'uri': _databaseUriController.text.trim(),
        'host': _databaseHostController.text.trim(),
        'port': _databasePortController.text.trim(),
        'database': _databaseNameController.text.trim(),
        'user': _databaseUserController.text.trim(),
        'password': _databasePasswordController.text,
        'ssl': _databaseSsl,
      };

      final latestAppData = Map<String, dynamic>.from(appData);
      latestAppData['token'] = token;
      latestAppData['databaseConfig'] = databaseConfig;
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
      developer.log('Error saving database: $e', name: 'AppSettingsPage');
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
          _isSavingDatabase = false;
        });
      }
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
      latestAppData['prefix'] = _prefixController.text.trim().isEmpty
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
        prefix: _prefixController.text.trim().isEmpty
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
          final session = await client.exchangeDiscordBotToken(
            botToken: effectiveToken,
          );
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
        developer.log(
          'Failed to sync token to cloud: $e',
          name: 'AppSettingsPage',
        );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
          prefix: _prefixController.text.trim().isEmpty
              ? '!'
              : _prefixController.text,
        );
      }

      final shouldUpdateBanner = _selectedBannerPath != null || _removeBanner;
      if (shouldUpdateBanner) {
        final updatedUser = await updateDiscordBotBanner(
          token,
          bannerPath: _selectedBannerPath,
          removeBanner: _removeBanner,
        );
        final bannerHash = (updatedUser['banner'] ?? '').toString();
        setState(() {
          _currentBannerUrl = makeBannerUrl(botId, bannerHash: bannerHash);
          _selectedBannerPath = null;
          _removeBanner = false;
        });
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
      // Réconciliation DANS LES DEUX SENS : ce qui manque sur Discord est
      // recréé, ce qui n'existe plus localement est supprimé. Comparer par nom
      // (et non par identifiant) est indispensable : le runner réenregistre ses
      // commandes sans identifiant, donc Discord en attribue de nouveaux à
      // chaque fois — par identifiant, le bouton supprimait tout et ne
      // recréait rien.
      final outcome = await reconcileDiscordCommandsForBot(
        botId,
        api: NyxxApplicationCommandsApi(widget.client),
      );

      if (!mounted) return;

      if (outcome == null) {
        // Rien n'a été touché : dire POURQUOI plutôt qu'afficher un succès.
        _showSyncFeedback(
          context.tr.settings_sync_force_no_local_commands,
          isError: true,
        );
        return;
      }

      _showSyncFeedback(
        context.tr.settings_sync_force_success_counts(
          outcome.created,
          outcome.relinked,
          outcome.deleted,
        ),
        isError: false,
      );

      final failure = outcome.firstFailure;
      if (failure != null) {
        _showSyncFeedback(
          context.tr.settings_sync_force_error(failure),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSyncFeedback(
        context.tr.settings_sync_force_error(e.toString()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isForceSyncing = false;
        });
      }
    }
  }

  void _showSyncFeedback(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : null,
      ),
    );
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

  Future<void> _pickBannerFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.first.path;
    if (path == null || path.isEmpty) {
      return;
    }

    setState(() {
      _selectedBannerPath = path;
      _removeBanner = false;
    });
  }

  EdgeInsets _tabContentPadding(BuildContext context) {
    // Marges horizontales : elles viennent de `PageContent`
    // (`AppPageLayout`), qui porte aussi la largeur maximale commune. Seule la
    // réserve basse de la barre de navigation flottante reste locale.
    return EdgeInsets.only(
      top: 16,
      bottom: FloatingGlassNavBar.contentClearanceOf(context) + 24,
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _tabContentPadding(context),
      child: Center(
        child: PageContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfilePreviewCard(),

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
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
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
                    onPressed: _isSavingToken
                        ? null
                        : () {
                            setState(() {
                              _tokenController.text = _savedToken;
                              _isEditingToken = false;
                            });
                          },
                    icon: const Icon(Icons.close),
                    label: Text(context.tr.bot_settings_cancel_token_edit_btn),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                context.tr.bot_settings_save_token_caption,
                style: const TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isSavingToken || !_isEditingToken)
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
                  label: Text(context.tr.bot_settings_save_token_only_btn),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(context.tr.import_engine_title,
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
                onChanged: _isSwitchingRuntimeEngine
                    ? null
                    : _onRuntimeEngineChanged,
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
                style: const TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr.settings_builtin_help),
                subtitle: Text(context.tr.settings_builtin_help_subtitle),
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
                  icon: _isSavingPrefix
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildPresenceTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _tabContentPadding(context),
      child: Center(
        child: PageContent(
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
                color: Theme.of(context).colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
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
                                          (widget.client.user as User)
                                              .avatar
                                              .url
                                              .toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    color:
                                                        AppTheme.discordBorder,
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
                                      icon: const Icon(
                                        Icons.photo_library_outlined,
                                        size: 16,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      label: Text(
                                        context.tr.bot_settings_browse,
                                      ),
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
                                          side: const BorderSide(
                                            color: AppTheme.error,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        icon: const Icon(Icons.clear, size: 16),
                                        label: Text(
                                          context
                                              .tr
                                              .bot_settings_avatar_clear_selection,
                                        ),
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
                                    Uri.file(
                                      _selectedAvatarPath!,
                                    ).pathSegments.last,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ] else
                                  Text(
                                    context
                                        .tr
                                        .bot_settings_avatar_none_selected,
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
                    labelText: context.tr.bot_settings_presence_status_label,
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
                    style: const TextStyle(fontSize: 12, color: AppTheme.grey),
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
                                  context.tr.bot_settings_status_item_title(
                                    index + 1,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: context.tr.bot_settings_remove_status,
                                onPressed: () async {
                                  final shouldDelete =
                                      await AppTheme.showConfirmDialog(
                                        context,
                                        title: context
                                            .tr
                                            .bot_settings_remove_status,
                                        content: context
                                            .tr
                                            .settings_status_remove_confirm,
                                        confirmLabel: context.tr.delete,
                                        isDestructive: true,
                                      );
                                  if (!shouldDelete) {
                                    return;
                                  }
                                  setState(() {
                                    final removed = _statusDrafts.removeAt(
                                      index,
                                    );
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
                                  context.tr.bot_settings_status_type_label,
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
                                  context.tr.bot_settings_status_text_label,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: draft.stateController,
                            decoration: InputDecoration(
                              labelText:
                                  context.tr.bot_settings_activity_state_label,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: draft.urlController,
                            decoration: InputDecoration(
                              labelText:
                                  context.tr.bot_settings_activity_url_label,
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
                                    labelText: context
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
                                    labelText: context
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
                style: const TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingProfile
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
                  label: Text(context.tr.bot_settings_save_profile_status_btn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLavalinkTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _tabContentPadding(context),
      child: Center(
        child: PageContent(
          child: LavalinkSettingsSection(
            initialConfig: _lavalinkConfigRaw,
            onSave: _saveLavalinkConfig,
            // Le bot édité : la section en a besoin pour savoir s'il s'exécute ici
            // (musique débloquée) ou sur Bot Creator Server (formule exigée).
            botId: widget.client.user.id.toString(),
          ),
        ),
      ),
    );
  }

  Widget _buildDatabaseTab() {
    final scheme = Theme.of(context).colorScheme;
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _tabContentPadding(context),
      child: Center(
        child: PageContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.storage, color: AppTheme.discord),
                    const SizedBox(width: 10),
                    Text(
                      context.tr.bot_settings_database_section_title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Database Type Dropdown / Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.bot_settings_database_type_label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _databaseType,
                        decoration: inputDecoration,
                        dropdownColor: scheme.surfaceContainer,
                        items: [
                          DropdownMenuItem(
                            value: 'none',
                            child: Text(
                              context.tr.bot_settings_database_type_none,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'postgres',
                            child: Text(
                              context.tr.bot_settings_database_type_postgres,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'mysql',
                            child: Text(
                              context.tr.bot_settings_database_type_mysql,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'mongo',
                            child: Text(
                              context.tr.bot_settings_database_type_mongo,
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _databaseType = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_databaseType != 'none') ...[
                // Info banner explaining the keyword
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.discord.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.discord.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.discord,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _databaseType == 'postgres'
                              ? context.tr.bot_settings_database_info_postgres
                              : _databaseType == 'mysql'
                              ? context.tr.bot_settings_database_info_mysql
                              : context.tr.bot_settings_database_info_mongo,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // URI Connection String
                Text(context.tr.bot_settings_database_uri_label),
                const SizedBox(height: 6),
                TextField(
                  controller: _databaseUriController,
                  decoration: inputDecoration.copyWith(
                    hintText: _databaseType == 'postgres'
                        ? 'postgresql://user:password@localhost:5432/dbname'
                        : _databaseType == 'mysql'
                        ? 'mysql://user:password@localhost:3306/dbname'
                        : 'mongodb+srv://user:password@cluster.mongodb.net/dbname',
                  ),
                ),
                const SizedBox(height: 12),

                // Toggle for advanced discrete fields
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAdvancedDbFields = !_showAdvancedDbFields;
                      });
                    },
                    icon: Icon(
                      _showAdvancedDbFields
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                    label: Text(
                      _showAdvancedDbFields
                          ? context
                                .tr
                                .bot_settings_database_hide_discrete_fields
                          : context
                                .tr
                                .bot_settings_database_show_discrete_fields,
                    ),
                  ),
                ),

                if (_showAdvancedDbFields) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr.bot_settings_database_host),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _databaseHostController,
                              decoration: inputDecoration.copyWith(
                                hintText:
                                    context.tr.bot_settings_database_host_hint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr.bot_settings_database_port),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _databasePortController,
                              keyboardType: TextInputType.number,
                              decoration: inputDecoration.copyWith(
                                hintText: _databaseType == 'postgres'
                                    ? '5432'
                                    : _databaseType == 'mysql'
                                    ? '3306'
                                    : '27017',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(context.tr.bot_settings_database_name),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _databaseNameController,
                    decoration: inputDecoration.copyWith(
                      hintText: context.tr.bot_settings_database_name_hint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr.bot_settings_database_user),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _databaseUserController,
                              decoration: inputDecoration.copyWith(
                                hintText:
                                    context.tr.bot_settings_database_user_hint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr.bot_settings_database_password),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _databasePasswordController,
                              obscureText: !_databasePasswordVisible,
                              decoration: inputDecoration.copyWith(
                                hintText: '••••••••',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _databasePasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _databasePasswordVisible =
                                          !_databasePasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: Text(context.tr.bot_settings_database_ssl),
                    value: _databaseSsl,
                    onChanged: (val) {
                      setState(() {
                        _databaseSsl = val == true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ],
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingDatabase ? null : _saveDatabaseOnly,
                  icon: const Icon(Icons.save),
                  label: Text(context.tr.bot_settings_database_save_btn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _tabContentPadding(context),
      child: Center(
        child: PageContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Utility Cards
              Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(context.tr.bot_settings_workflow_docs),
                  subtitle: Text(context.tr.bot_settings_workflow_docs_desc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    openDocumentationHub(
                      context,
                      showDiscordJsTab:
                          _runtimeEngine == runtimeEngineJavascript,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.import_export),
                  title: Text(context.tr.bot_settings_export_import),
                  subtitle: Text(context.tr.bot_settings_export_import_desc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BotExportImportPage(
                          botId: widget.client.application.id.toString(),
                        ),
                      ),
                    );
                  },
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
                  side: BorderSide(color: AppTheme.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.settings_sync_force_title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                          onPressed: _isForceSyncing
                              ? null
                              : _forceSyncDiscordCommands,
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
                            side: const BorderSide(color: AppTheme.error),
                          ),
                          icon: _isDeletingBot
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.error,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.delete_forever),
                          label: Text(context.tr.bot_settings_delete_bot_btn),
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
    final showDatabase = _capabilities.supportsExternalDatabase;
    final tabCount = (showLavalink || showDatabase) ? 4 : 3;

    return DefaultTabController(
      key: ValueKey(
        'bot-settings-tabs-$tabCount-${showDatabase ? "db" : "no-db"}',
      ),
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr.bot_settings_title),
          automaticallyImplyLeading: false,
          // Le garde d'origine testait la *plateforme* (`isDesktopPlatform`) et
          // non la largeur : sur desktop / tablette large, le burger
          // s'affichait alors que le shell ne crée AUCUN tiroir (la sidebar est
          // permanente) — un bouton mort. `editorSubPageLeading` interroge le
          // Scaffold parent : null quand la sidebar est là, bouton tiroir en
          // layout compact, bouton retour pour une route poussée.
          leading: editorSubPageLeading(context),
          actions: [
            if (_capabilities.supportsCommandDashboard)
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: context.tr.dashboard_title,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CommandDashboardPage(
                        botId: widget.client.user.id.toString(),
                      ),
                    ),
                  );
                },
              ),
          ],
          // Les onglets sont rendus par le composant de navigation partagé
          // (variante inline) au lieu d'un `TabBar` Material : même identité
          // visuelle que la nav de la Home et les pastilles de modules.
          bottom: _SettingsTabsNav(
            tabs: [
              (
                icon: Icons.settings,
                selectedIcon: Icons.settings_rounded,
                label: context.tr.bot_settings_tab_general,
              ),
              (
                icon: Icons.emoji_emotions_outlined,
                selectedIcon: Icons.emoji_emotions,
                label: context.tr.bot_settings_tab_presence,
              ),
              if (showLavalink)
                (
                  icon: Icons.music_note,
                  selectedIcon: null,
                  label: context.tr.bot_settings_tab_lavalink,
                ),
              if (showDatabase)
                (
                  icon: Icons.storage,
                  selectedIcon: null,
                  label: context.tr.bot_settings_tab_database,
                ),
              (
                icon: Icons.build_outlined,
                selectedIcon: Icons.build,
                label: context.tr.bot_settings_tab_advanced,
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _buildGeneralTab(),
              _buildPresenceTab(),
              if (showLavalink) _buildLavalinkTab(),
              if (showDatabase) _buildDatabaseTab(),
              _buildAdvancedTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePreviewCard() {
    final user = widget.client.user as User;
    final botName = _usernameController.text.trim().isNotEmpty
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

    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _pickBannerFile,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: _bannerAccentColor != null
                          ? Color(0xFF000000 | _bannerAccentColor!)
                          : AppTheme.discord,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      image: _selectedBannerPath != null
                          ? DecorationImage(
                              image: FileImage(File(_selectedBannerPath!)),
                              fit: BoxFit.cover,
                            )
                          : (_currentBannerUrl != null && !_removeBanner)
                          ? DecorationImage(
                              image: NetworkImage(_currentBannerUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Tooltip(
                            message: context.tr.common_edit,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (_selectedBannerPath != null ||
                            (_currentBannerUrl != null && !_removeBanner))
                          Positioned(
                            top: 8,
                            right: 44,
                            child: Tooltip(
                              message: context.tr.delete,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedBannerPath = null;
                                    _removeBanner = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.white,
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
              Positioned(
                top: 45,
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
                            color: scheme.surfaceContainer,
                            border: Border.all(
                              color: scheme.surfaceContainer,
                              width: 6,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipOval(
                                  child: _selectedAvatarPath != null
                                      ? Image.file(
                                          File(_selectedAvatarPath!),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          user.avatar.url.toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color:
                                                scheme.surfaceContainerHighest,
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
                              color: scheme.surfaceContainer,
                              border: Border.all(
                                color: scheme.surfaceContainer,
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
      type: _AppSettingsPageState._statusTypes.contains(type)
          ? type
          : 'playing',
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

/// Bandeau d'onglets (Général / Présence & Statut / Lavalink / …) de la page
/// Paramètres du bot.
///
/// Il remplace le `TabBar` Material par le composant de navigation partagé
/// [FloatingGlassNavBar] en variante inline, pour n'avoir qu'une seule
/// identité visuelle dans l'app. Il se branche sur le `TabController` du
/// `DefaultTabController` parent : le swipe entre les sections (`TabBarView`),
/// l'index sélectionné et les libellés i18n restent inchangés.
class _SettingsTabsNav extends StatelessWidget implements PreferredSizeWidget {
  const _SettingsTabsNav({required this.tabs});

  final List<({IconData icon, IconData? selectedIcon, String label})> tabs;

  @override
  Size get preferredSize =>
      const Size.fromHeight(FloatingGlassNavBar.inlinePreferredHeight);

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final animation = controller.animation;
    if (animation == null) {
      // Ne peut pas arriver pour un `DefaultTabController` monté (le contrôleur
      // n'est détaché que lorsqu'il est remplacé/disposé).
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FloatingGlassNavBar.inlineHorizontalMargin,
        vertical: FloatingGlassNavBar.inlineVerticalMargin,
      ),
      child: AnimatedBuilder(
        // `animation` (et non le contrôleur) se met à jour à chaque image :
        // l'item sélectionné suit ainsi le swipe au lieu de ne changer qu'à
        // l'arrêt de l'animation.
        animation: animation,
        builder: (context, _) {
          final selectedIndex = animation.value.round().clamp(
            0,
            tabs.length - 1,
          );
          return FloatingGlassNavBar.inline(
            scrollable: true,
            items: [
              for (var i = 0; i < tabs.length; i++)
                FloatingGlassNavItem(
                  icon: tabs[i].icon,
                  selectedIcon: tabs[i].selectedIcon,
                  label: tabs[i].label,
                  selected: selectedIndex == i,
                  onTap: () => controller.animateTo(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

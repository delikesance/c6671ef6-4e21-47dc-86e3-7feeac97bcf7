import 'dart:async';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/core/diagnostics/diagnostics_logs_page.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' show CodeEditorSettingsCard;
import 'package:bot_creator/features/settings/presentation/appearance_settings_section.dart';
import 'package:bot_creator/features/settings/presentation/widgets/app_version_and_updates_card.dart';
import 'package:bot_creator/features/onboarding/presentation/onboarding_page.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/analytics/user_properties.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:bot_creator/features/ads/logic/ad_consent_service.dart';
import 'package:bot_creator/features/ads/logic/ad_mediation_debug.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/features/discord_rpc/logic/discord_rpc_service.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_auth_service.dart';
import 'package:bot_creator/core/network/main_api_credentials_auth_service.dart';
import 'package:bot_creator/core/auth/mobile_account_gate.dart';
import 'package:bot_creator/core/auth/mobile_account_session.dart';
import 'package:bot_creator/core/auth/main_api_account_bootstrap.dart';
import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/core/storage/runtime_preferences.dart';
import 'package:bot_creator/features/notifications/logic/notification_service.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscriptions_hub_page.dart';
import 'package:bot_creator/core/storage/drive.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';

import 'package:bot_creator/features/onboarding/logic/onboarding_manager.dart';
import 'package:bot_creator/core/diagnostics/recovery_manager.dart';
import 'package:bot_creator/core/network/runner_kind.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/runner/embedded_js_runner_service.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key, this.embedded = false});

  /// When true, hide the back button (used inside the compact bottom-nav shell).
  final bool embedded;

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  List<File> files = [];
  DriveApi? driveApi;
  bool _isBusy = false;
  String _busyMessage = '';
  RecoverySettings _recoverySettings = RecoverySettings.defaults();
  bool _loadingRecoverySettings = true;
  bool _loadingSnapshots = false;
  List<BackupSnapshotSummary> _snapshots = const [];

  // Developer mode state
  final TextEditingController _runnerUrlController = TextEditingController();
  final TextEditingController _runnerApiTokenController =
      TextEditingController();
  final TextEditingController _mainApiUrlController = TextEditingController();
  final TextEditingController _discordRpcClientIdController =
      TextEditingController();
  bool _checkingRunner = false;
  bool _checkingMainApi = false;
  bool _connectingMainApi = false;
  bool _disconnectingMainApi = false;
  String? _runnerStatusKey;
  String? _mainApiStatusKey;
  bool _runnerTokenObscured = true;
  bool _runnerTemporarilyDisabled = false;
  RunnerKind _runnerKind = RunnerKind.auto;
  bool _useRemoteRunner = false;
  String? _embeddedRunnerStatusLabel;
  EmbeddedRunnerDiagnostics? _embeddedRunnerDiagnostics;
  String? _runnerEngineLabel;
  String? _runnerVersionLabel;
  bool _mainApiSectionExpanded = false;
  MainApiSession? _mainApiSession;
  StreamSubscription<DiscordRpcSnapshot>? _discordRpcSnapshotSubscription;
  bool _checkingAdPrivacy = false;
  bool _adPrivacyRequired = false;
  bool _developerSectionExpanded = false;
  bool _mobileLocalHostingEnabled = false;
  bool _loadingMobileLocalHosting = true;
  bool _refreshingMainApiOnResume = false;
  final TextEditingController _altLoginEmailController =
      TextEditingController();
  final TextEditingController _altLoginPasswordController =
      TextEditingController();
  final TextEditingController _altLoginConfirmController =
      TextEditingController();
  final TextEditingController _altLoginCurrentPasswordController =
      TextEditingController();
  bool _savingAlternativeLogin = false;
  bool _alternativeLoginExpanded = false;
  bool _userHasPassword = false;
  String? _userEmail;

  void _mainApiDebug(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[MainApi][Settings] $message');
  }

  bool get _isDesktopPlatform {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool get _isManagedMobilePlatform {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _showsRemoteRunnerConfig => !_isDesktopPlatform || _useRemoteRunner;

  Future<void> _runWithLoading(
    String message,
    Future<void> Function() action,
  ) async {
    if (!mounted) return;
    setState(() {
      _isBusy = true;
      _busyMessage = message;
    });

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyMessage = '';
        });
      }
    }
  }

  Future<void> _ensureDriveApiConnected({bool interactive = true}) async {
    if (driveApi != null) {
      return;
    }
    DriveApi drive;
    try {
      drive = await getDriveApi(interactive: interactive);
    } catch (error) {
      if (isDriveAuthCancellation(error)) {
        return;
      }
      rethrow;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      driveApi = drive;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_settingsLifecycleObserver);
    EmbeddedJsRunnerService.instance.downloadProgress.addListener(
      _onEmbeddedRunnerDownloadProgress,
    );
    _loadCachedSnapshotsFromCache();
    _loadRecoverySettings();
    _initializeDriveApi();
    _loadRunnerSettings();
    _loadMainApiSettings();
    _loadRuntimePreferences();
    if (_isDesktopPlatform) {
      _loadDiscordRpcSettings();
      _refreshEmbeddedRunnerDiagnostics();
    } else {}
    _loadAdPrivacyRequirement();
  }

  late final WidgetsBindingObserver _settingsLifecycleObserver =
      _SettingsLifecycleObserver(onResumed: _handleAppResumed);

  Future<void> _handleAppResumed() async {
    if (_refreshingMainApiOnResume) {
      return;
    }
    _mainApiDebug('App resumed on mobile, reloading main API session state');
    _refreshingMainApiOnResume = true;
    try {
      await _loadMainApiSettings();
      if (_isDesktopPlatform) {
        await _refreshEmbeddedRunnerDiagnostics();
      }
    } finally {
      _mainApiDebug('Resume refresh finished');
      _refreshingMainApiOnResume = false;
    }
  }

  Future<void> _loadRuntimePreferences() async {
    final mobileLocalHostingEnabled =
        await RuntimePreferences.isMobileLocalHostingEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _mobileLocalHostingEnabled = mobileLocalHostingEnabled;
      _loadingMobileLocalHosting = false;
    });
  }

  Future<void> _loadCachedSnapshotsFromCache() async {
    final cached = await RecoveryManager.loadCachedSnapshots();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshots = cached;
    });
  }

  Future<void> _loadAdPrivacyRequirement() async {
    if (!mounted) return;
    setState(() {
      _checkingAdPrivacy = true;
    });

    final required = await AdConsentService.isPrivacyOptionsRequired();
    if (!mounted) return;
    setState(() {
      _adPrivacyRequired = required;
      _checkingAdPrivacy = false;
    });
  }

  Future<void> _openAdPrivacyOptions() async {
    final opened = await AdConsentService.showPrivacyOptionsForm();
    await _loadAdPrivacyRequirement();
    if (!mounted) return;
    _showSnack(
      opened
          ? context.tr.settings_ads_privacy_opened
          : context.tr.settings_ads_privacy_open_error,
    );
  }

  Future<void> _runMediationDiagnostics() async {
    await AdMediationDebug.logInitializationStatus();
    final canRequest = await AdConsentService.ensureCanRequestAds();
    _showSnack(
      canRequest
          ? 'Mediation diagnostics launched. Check diagnostics logs.'
          : 'Consent blocked ads request. Open privacy options and retry.',
    );
  }

  Future<void> _openAdInspector() async {
    await AdMediationDebug.openAdInspector();
    _showSnack('Ad Inspector closed. Check diagnostics logs.');
  }

  Future<void> _initializeDriveApi() async {
    String userId = 'unknown';
    // getSignedInAccount() works on both Android and iOS.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      try {
        final account = await getSignedInAccount(interactive: false);
        userId = account.id;
      } catch (_) {}
    }

    await AppAnalytics.logScreenView(
      screenName: "SettingPage",
      screenClass: "SettingPage",
      parameters: {"user_id": userId as Object},
    );
    // La connexion à Google Drive se fait uniquement sur action de l'utilisateur.
  }

  Future<void> _loadRunnerSettings() async {
    final config = await RunnerSettings.getUserStoredConfig();
    final isDisabled = await RunnerSettings.isTemporarilyDisabled();
    if (!mounted) return;
    setState(() {
      _runnerUrlController.text = config?.url ?? '';
      _runnerApiTokenController.text = config?.apiToken ?? '';
      _runnerTemporarilyDisabled = isDisabled;
      _runnerKind = config?.kind ?? RunnerKind.auto;
      _useRemoteRunner = config != null;
      _runnerEngineLabel = null;
      _runnerVersionLabel = null;
      _embeddedRunnerStatusLabel = _embeddedRunnerStatusText();
    });
    if (_showsRemoteRunnerConfig && config != null && !isDisabled) {
      await _checkRunnerConnection();
    }
    await _refreshEmbeddedRunnerDiagnostics();
  }

  Future<void> _refreshEmbeddedRunnerDiagnostics() async {
    if (!_isDesktopPlatform) {
      return;
    }
    final diagnostics = await EmbeddedJsRunnerService.instance.getDiagnostics();
    if (!mounted) {
      return;
    }
    setState(() {
      _embeddedRunnerDiagnostics = diagnostics;
      _embeddedRunnerStatusLabel = _embeddedRunnerStatusText();
    });
  }

  String _embeddedRunnerPrimaryStatusText() {
    final service = EmbeddedJsRunnerService.instance;
    if (service.isDownloading) {
      return context.tr.settings_embedded_runner_status_downloading;
    }
    if (service.isRunning) {
      final baseUrl = service.baseUrl;
      if (baseUrl == null || baseUrl.isEmpty) {
        return context.tr.settings_embedded_runner_status_running;
      }
      return context.tr.settings_embedded_runner_running_at(baseUrl);
    }
    final error = service.lastStartupError;
    if (error != null && error.isNotEmpty) {
      return context.tr.settings_embedded_runner_status_failed;
    }
    return context.tr.settings_embedded_runner_status_stopped;
  }

  String _truncateEmbeddedRunnerPath(String path) {
    if (path.length <= 72) {
      return path;
    }
    return '...${path.substring(path.length - 69)}';
  }

  String _embeddedRunnerExecutionModeHint() {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    if (lang.startsWith('fr')) {
      return 'Les bots JavaScript utilisent toujours ce runner embarque. '
          'Le mode d\'execution local desactive uniquement les runners distants '
          'optionnels et le mode Dart local.';
    }
    return 'JavaScript bots always use this embedded runner. Local execution mode '
        'only disables optional remote runners and Dart local mode.';
  }

  Future<void> _restartEmbeddedRunner() async {
    await _runWithLoading(
      context.tr.settings_embedded_runner_restart,
      () async {
        final config = await RunnerSettings.restartEmbeddedJsRunner();
        await _refreshEmbeddedRunnerDiagnostics();
        if (!mounted) {
          return;
        }
        _showSnack(
          config != null
              ? context.tr.settings_embedded_runner_restart_success
              : context.tr.settings_embedded_runner_restart_failed,
        );
      },
    );
  }

  Future<void> _redownloadEmbeddedRunner() async {
    await _runWithLoading(
      context.tr.settings_embedded_runner_redownload,
      () async {
        final config = await RunnerSettings.redownloadEmbeddedJsRunner();
        await _refreshEmbeddedRunnerDiagnostics();
        if (!mounted) {
          return;
        }
        _showSnack(
          config != null
              ? context.tr.settings_embedded_runner_redownload_success
              : context.tr.settings_embedded_runner_redownload_failed,
        );
      },
    );
  }

  Future<void> _openEmbeddedRunnerLog() async {
    final logPath =
        _embeddedRunnerDiagnostics?.logPath ??
        EmbeddedJsRunnerService.instance.logPath;
    if (logPath == null || logPath.isEmpty) {
      return;
    }
    final opened = await openExternalUrl(Uri.file(logPath));
    if (!opened && mounted) {
      _showSnack(context.tr.app_open_link_error);
    }
  }

  String _embeddedRunnerStatusText() {
    if (!_isDesktopPlatform) {
      return '';
    }

    final service = EmbeddedJsRunnerService.instance;
    final download = service.downloadProgress.value;
    if (download != null) {
      if (download.totalBytes != null) {
        return context.tr.settings_embedded_runner_download_progress(
          _formatEmbeddedRunnerDownloadBytes(download.receivedBytes),
          _formatEmbeddedRunnerDownloadBytes(download.totalBytes!),
        );
      }
      return context.tr.settings_embedded_runner_download_indeterminate(
        _formatEmbeddedRunnerDownloadBytes(download.receivedBytes),
      );
    }

    if (service.isRunning) {
      final baseUrl = service.baseUrl;
      return baseUrl == null
          ? context.tr.settings_embedded_runner_status_running
          : context.tr.settings_embedded_runner_running_at(baseUrl);
    }

    final error = service.lastStartupError;
    if (error != null && error.isNotEmpty) {
      final phase = service.lastStartupPhase;
      final phaseSuffix = phase == null || phase.isEmpty
          ? ''
          : ' (phase: $phase)';
      return '${context.tr.settings_embedded_runner_status_failed}$phaseSuffix: $error';
    }

    return context.tr.settings_embedded_runner_status_stopped;
  }

  Future<void> _toggleUseRemoteRunner(bool enabled) async {
    setState(() {
      _useRemoteRunner = enabled;
      if (!enabled) {
        _runnerUrlController.clear();
        _runnerApiTokenController.clear();
        _runnerStatusKey = null;
        _runnerEngineLabel = null;
        _runnerVersionLabel = null;
      }
    });

    if (!enabled) {
      await RunnerSettings.clearUserConfig();
      if (!mounted) return;
      _showSnack(context.tr.settings_runner_cleared);
    }
  }

  Future<void> _toggleRunnerTemporarilyDisabled(bool disabled) async {
    await RunnerSettings.setTemporarilyDisabled(disabled);
    if (!mounted) return;
    setState(() {
      _runnerTemporarilyDisabled = disabled;
      if (disabled) {
        _runnerStatusKey = 'settings_runner_temporarily_disabled';
      }
    });

    if (!disabled &&
        _showsRemoteRunnerConfig &&
        _runnerUrlController.text.trim().isNotEmpty) {
      await _checkRunnerConnection();
    }

    _showSnack(
      disabled
          ? context.tr.settings_runner_temporarily_disabled_saved
          : context.tr.settings_runner_reenabled,
    );
  }

  Future<void> _saveRunnerSettings() async {
    if (_isDesktopPlatform && !_useRemoteRunner) {
      await RunnerSettings.clearUserConfig();
      if (!mounted) return;
      setState(() {
        _runnerStatusKey = null;
      });
      _showSnack(context.tr.settings_runner_cleared);
      return;
    }

    final url = _runnerUrlController.text.trim();
    final apiToken = _runnerApiTokenController.text.trim();
    await RunnerSettings.save(url: url, apiToken: apiToken, kind: _runnerKind);
    if (!mounted) return;
    setState(() {
      _runnerStatusKey = null;
    });
    final cleared = url.isEmpty && apiToken.isEmpty;
    _showSnack(
      cleared
          ? context.tr.settings_runner_cleared
          : context.tr.settings_runner_saved,
    );
    if (!cleared) {
      await _checkRunnerConnection();
    }
  }

  Future<void> _checkRunnerConnection() async {
    if (!_showsRemoteRunnerConfig) {
      return;
    }

    final url = _runnerUrlController.text.trim();
    if (url.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _checkingRunner = true;
      _runnerStatusKey = null;
    });
    try {
      final client =
          RunnerConnectionConfig(
            id: '_check',
            url: url,
            apiToken: _runnerApiTokenController.text.trim(),
            kind: _runnerKind,
          ).createClient(
            getTimeout: const Duration(seconds: 30),
            postTimeout: const Duration(seconds: 25),
          );
      final root = await client.fetchRootInfo();
      await client.getStatus();
      if (!mounted) return;
      setState(() {
        _runnerStatusKey = 'settings_runner_connected';
        _checkingRunner = false;
        _runnerEngineLabel = (root['engine'] ?? '').toString();
        _runnerVersionLabel = (root['version'] ?? '').toString();
      });
    } on RunnerClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _runnerStatusKey = error.statusCode == 401 || error.statusCode == 403
            ? 'settings_runner_auth_failed'
            : 'settings_runner_unreachable';
        _checkingRunner = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _runnerStatusKey = 'settings_runner_unreachable';
        _checkingRunner = false;
      });
    }
  }

  Future<void> _loadMainApiSettings() async {
    _mainApiDebug('Loading main API config + session from storage');
    final config = await MainApiSettingsStore.loadConfig();
    var session = await MainApiSettingsStore.loadSession();

    if (session != null && session.isExpired && session.refreshToken == null) {
      _mainApiDebug('Stored session expired without refresh token, clearing');
      await MainApiSettingsStore.clearSession();
      session = null;
    }

    if (!mounted) {
      return;
    }

    final resolvedBaseUrl = config.baseUrl.isEmpty
        ? defaultMainApiBaseUrl
        : config.baseUrl;

    _mainApiDebug(
      'Loaded baseUrl=$resolvedBaseUrl sessionPresent=${session != null} sessionExpired=${session?.isExpired ?? false}',
    );

    setState(() {
      _mainApiUrlController.text = resolvedBaseUrl;
      _mainApiSession = session;
      if (session != null) {
        _mainApiStatusKey = session.isExpired
            ? 'settings_main_api_session_expired'
            : 'settings_main_api_session_connected';
      } else {
        _mainApiStatusKey = 'settings_main_api_connected';
      }
    });

    await _checkMainApiConnection();
  }

  Future<void> _checkMainApiConnection() async {
    final config = await MainApiSettingsStore.loadConfig();
    final url = config.baseUrl;
    _mainApiDebug(
      'Checking main API health url=$url sessionPresent=${_mainApiSession != null}',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _checkingMainApi = true;
      _mainApiStatusKey = null;
    });

    try {
      final publicClient = MainApiClient(baseUrl: url);
      final healthy = await publicClient.checkHealth();
      _mainApiDebug('Health check result healthy=$healthy');
      if (!healthy) {
        if (!mounted) return;
        setState(() {
          _mainApiStatusKey = 'settings_main_api_unreachable';
          _checkingMainApi = false;
        });
        return;
      }

      var nextSession = _mainApiSession;
      var statusKey = 'settings_main_api_connected';

      if (nextSession != null) {
        var activeSession = nextSession;
        if (nextSession.expiresSoon()) {
          activeSession = await ensureMainApiSession() ?? nextSession;
        }
        if (activeSession.isExpired) {
          activeSession = nextSession;
        }

        try {
          final profile = await publicClient
              .withAccessToken(activeSession.accessToken)
              .getCurrentUser();

          final refreshedFromStore = await MainApiSettingsStore.loadSession();
          if (refreshedFromStore != null) {
            activeSession = refreshedFromStore;
          }

          final username = (profile['username'] ?? profile['name'] ?? '')
              .toString()
              .trim();
          final profileEmail = (profile['email'] ?? '').toString().trim();
          final hasPassword = profile['has_password'] == true;
          if (username.isNotEmpty && username != activeSession.username) {
            activeSession = activeSession.copyWith(username: username);
            await MainApiSettingsStore.saveSession(activeSession);
            _mainApiDebug('Session username updated to $username');
          }
          nextSession = activeSession;
          statusKey = 'settings_main_api_session_connected';
          if (mounted) {
            setState(() {
              _userHasPassword = hasPassword;
              _userEmail = profileEmail.isEmpty ? null : profileEmail;
            });
          }
          _mainApiDebug('Session validated successfully (connected)');
        } on MainApiClientException catch (error) {
          _mainApiDebug(
            'Session validation failed statusCode=${error.statusCode}',
          );
          if (error.statusCode == 401 || error.statusCode == 403) {
            statusKey = 'settings_main_api_auth_failed';
            nextSession = await MainApiSettingsStore.loadSession();
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _mainApiSession = nextSession;
        _mainApiStatusKey = statusKey;
        _checkingMainApi = false;
      });
      _mainApiDebug('Main API status key set to $statusKey');
    } catch (_) {
      _mainApiDebug('Main API check failed with unexpected error');
      if (!mounted) return;
      setState(() {
        _mainApiStatusKey = 'settings_main_api_unreachable';
        _checkingMainApi = false;
      });
    }
  }

  Future<void> _connectMainApiDiscord() async {
    final config = await MainApiSettingsStore.loadConfig();
    final url = config.baseUrl;
    _mainApiDebug('Starting Discord OAuth flow for url=$url');

    if (!mounted) return;
    setState(() {
      _connectingMainApi = true;
    });

    try {
      final client = MainApiClient(baseUrl: url);
      final session = await MainApiAuthService.connectWithDiscord(
        client: client,
      );
      _mainApiDebug(
        'OAuth completed, saving session expiresAt=${session.expiresAt.toUtc().toIso8601String()} user=${session.username ?? ''}',
      );
      await MainApiSettingsStore.saveSession(
        session.copyWith(authMethod: MainApiAuthMethod.discordOauth),
      );

      // Immediately sync managed bots from the Manager to enrich local
      // entries with tokens and configs.
      try {
        await syncManagedBotsAfterDiscordLogin(
          baseUrl: url,
          accessToken: session.accessToken,
        );
        _mainApiDebug('Managed bots synced locally after connect');
      } catch (e) {
        _mainApiDebug('Failed to sync bots after connect: $e');
      }

      await MobileAccountSession.instance.recheck();

      if (!mounted) return;
      setState(() {
        _mainApiSession = session;
        _mainApiStatusKey = 'settings_main_api_session_connected';
      });

      final username = (session.username ?? '').trim();
      if (username.isNotEmpty) {
        if (mounted) {
          _showSnack(context.tr.settings_main_api_connected_user(username));
        }
      } else {
        if (mounted) {
          _showSnack(context.tr.settings_main_api_connected_discord);
        }
      }

      await _checkMainApiConnection();
    } catch (error) {
      _mainApiDebug('OAuth flow failed: $error');
      _showSnack(_formatErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _connectingMainApi = false;
        });
      }
    }
  }

  Future<void> _disconnectMainApi() async {
    if (!mounted) return;

    setState(() {
      _disconnectingMainApi = true;
    });

    try {
      await MainApiSettingsStore.clearSession();
      await MobileAccountSession.instance.recheck();
      if (!mounted) return;
      setState(() {
        _mainApiSession = null;
        _mainApiStatusKey = 'settings_main_api_session_disconnected';
      });
      _showSnack(context.tr.settings_main_api_session_disconnected);
    } finally {
      if (mounted) {
        setState(() {
          _disconnectingMainApi = false;
        });
      }
    }
  }

  Future<void> _setMobileLocalHostingEnabled(bool enabled) async {
    await RuntimePreferences.setMobileLocalHostingEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _mobileLocalHostingEnabled = enabled;
    });
    _showSnack(
      enabled
          ? context.tr.settings_local_hosting_enabled
          : context.tr.settings_cloud_hosting_enabled,
    );
  }

  Color? _mainApiStatusColor(String? statusKey) {
    switch (statusKey) {
      case 'settings_main_api_connected':
      case 'settings_main_api_session_connected':
        return AppTheme.successLight;
      case 'settings_main_api_unreachable':
      case 'settings_main_api_auth_failed':
        return AppTheme.errorLight;
      case 'settings_main_api_not_configured':
      case 'settings_main_api_session_expired':
      case 'settings_main_api_session_disconnected':
        return AppTheme.warning;
      default:
        return null;
    }
  }

  void _onEmbeddedRunnerDownloadProgress() {
    if (!mounted) {
      return;
    }
    setState(() {
      _embeddedRunnerStatusLabel = _embeddedRunnerStatusText();
    });
    unawaited(_refreshEmbeddedRunnerDiagnostics());
  }

  String _formatEmbeddedRunnerDownloadBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    EmbeddedJsRunnerService.instance.downloadProgress.removeListener(
      _onEmbeddedRunnerDownloadProgress,
    );
    WidgetsBinding.instance.removeObserver(_settingsLifecycleObserver);
    _discordRpcSnapshotSubscription?.cancel();
    _discordRpcClientIdController.dispose();
    _mainApiUrlController.dispose();
    _runnerUrlController.dispose();
    _runnerApiTokenController.dispose();
    _altLoginEmailController.dispose();
    _altLoginPasswordController.dispose();
    _altLoginConfirmController.dispose();
    _altLoginCurrentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadRecoverySettings() async {
    final settings = await RecoveryManager.loadSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _recoverySettings = settings;
      _loadingRecoverySettings = false;
    });
  }

  Future<void> _saveRecoverySettings(RecoverySettings settings) async {
    await RecoveryManager.saveSettings(settings);
    if (!mounted) {
      return;
    }
    setState(() {
      _recoverySettings = settings;
    });
  }

  Future<void> _refreshSnapshots() async {
    if (!mounted) return;
    if (driveApi == null) {
      await _loadCachedSnapshotsFromCache();
      return;
    }
    setState(() {
      _loadingSnapshots = true;
    });
    try {
      final snapshots = await listBackupSnapshots(driveApi!);
      await RecoveryManager.saveCachedSnapshots(snapshots);
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshots = snapshots;
      });
    } catch (_) {
      await _loadCachedSnapshotsFromCache();
    } finally {
      if (mounted) {
        setState(() {
          _loadingSnapshots = false;
        });
      }
    }
  }

  Future<void> _runAutoBackupCheck({
    required bool force,
    required bool showSnack,
  }) async {
    if (driveApi == null) {
      return;
    }
    final result = await RecoveryManager.runAutoBackupIfDue(
      drive: driveApi!,
      appManager: appManager,
      force: force,
    );
    if (!mounted) {
      return;
    }

    if (result.executed) {
      final updated = _recoverySettings.copyWith(
        lastAutoBackupAt: DateTime.now().toUtc(),
      );
      await _saveRecoverySettings(updated);
      await _refreshSnapshots();
    }

    if (showSnack) {
      final suffix = result.snapshot == null
          ? ''
          : ' (${result.snapshot!.snapshotId.substring(0, 19)})';
      _showSnack('${result.message}$suffix');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Le `ScaffoldMessenger` le plus proche, avec repli sur la racine de
  /// navigation.
  ///
  /// Le repli est légitime : `ScaffoldMessenger` est fourni AU-DESSUS du
  /// `Navigator` dans `MaterialApp`, donc le contexte de `navigatorKey` en voit
  /// un — contrairement à `Overlay`, qui vit SOUS le Navigator et qu'on ne
  /// trouve jamais depuis ce contexte-là.
  ///
  /// Si ni l'un ni l'autre n'existe (arbre pas encore monté, écran détaché), on
  /// le JOURNALISE : un message utilisateur qui disparaît sans trace est un
  /// échec impossible à diagnostiquer.
  ScaffoldMessengerState? _currentScaffoldMessenger() {
    if (!mounted) {
      return null;
    }
    final currentMessenger = ScaffoldMessenger.maybeOf(context);
    if (currentMessenger != null) {
      return currentMessenger;
    }
    final navigatorContext = MyApp.navigatorKey.currentContext;
    final fromNavigationRoot = navigatorContext == null
        ? null
        : ScaffoldMessenger.maybeOf(navigatorContext);
    if (fromNavigationRoot == null) {
      unawaited(
        AppDiagnostics.logInfo(
          'Settings: no ScaffoldMessenger found for a snackbar',
        ),
      );
      return null;
    }
    return fromNavigationRoot;
  }

  void _showSnackBar(SnackBar snackBar) {
    final messenger = _currentScaffoldMessenger();
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(snackBar);
  }

  void _showSnack(String message) {
    _showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _dropdownLabel(String text) {
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  String _languagePreferenceLabel(
    AppLocalePreference preference,
    AppLocale detectedLocale,
  ) {
    switch (preference) {
      case AppLocalePreference.system:
        return '${context.tr.settings_language_system} • ${detectedLocale.label}';
      case AppLocalePreference.en:
        return AppLocale.en.label;
      case AppLocalePreference.fr:
        return AppLocale.fr.label;
      case AppLocalePreference.de:
        return AppLocale.de.label;
      case AppLocalePreference.pt:
        return AppLocale.pt.label;
      case AppLocalePreference.tr:
        return AppLocale.tr.label;
      case AppLocalePreference.ja:
        return AppLocale.ja.label;
    }
  }

  static AppLocalePreference _localeToPreference(AppLocale locale) {
    switch (locale) {
      case AppLocale.en:
        return AppLocalePreference.en;
      case AppLocale.fr:
        return AppLocalePreference.fr;
      case AppLocale.de:
        return AppLocalePreference.de;
      case AppLocale.pt:
        return AppLocalePreference.pt;
      case AppLocale.tr:
        return AppLocalePreference.tr;
      case AppLocale.ja:
        return AppLocalePreference.ja;
    }
  }

  String _formatErrorMessage(Object error) {
    final msg = error.toString();
    if (!mounted) return msg;
    try {
      return context.tr.error_with_details(msg);
    } catch (_) {
      return msg;
    }
  }

  Future<void> _loadDiscordRpcSettings() async {
    try {
      final service = DiscordRpcService.instance;
      final snapshot = await service.initialize();
      final subscription = service.snapshots.listen((snapshot) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });

      if (!mounted) {
        await subscription.cancel();
        return;
      }

      _discordRpcSnapshotSubscription = subscription;
      _discordRpcClientIdController.text = snapshot.config.clientId;
      unawaited(
        AppDiagnostics.logInfo(
          'Discord RPC settings loaded in UI',
          data: <String, Object?>{
            'enabled': snapshot.config.enabled,
            'hasClientId': snapshot.config.hasClientId,
            'runtimeState': snapshot.runtimeState.name,
          },
        ),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {});
      _showSnack(_formatErrorMessage(error));
    }
  }

  String _notificationTopicLabel(NotificationTopic topic) {
    switch (topic) {
      case NotificationTopic.broadcast:
        return context.tr.settings_notifications_topic_broadcast;
      case NotificationTopic.updates:
        return context.tr.settings_notifications_topic_updates;
      case NotificationTopic.botAlerts:
        return context.tr.settings_notifications_topic_botAlerts;
      case NotificationTopic.billing:
        return context.tr.settings_notifications_topic_billing;
    }
  }

  String _notificationTopicDescription(NotificationTopic topic) {
    switch (topic) {
      case NotificationTopic.broadcast:
        return context.tr.settings_notifications_topic_broadcast_desc;
      case NotificationTopic.updates:
        return context.tr.settings_notifications_topic_updates_desc;
      case NotificationTopic.botAlerts:
        return context.tr.settings_notifications_topic_botAlerts_desc;
      case NotificationTopic.billing:
        return context.tr.settings_notifications_topic_billing_desc;
    }
  }

  IconData _notificationTopicIcon(NotificationTopic topic) {
    switch (topic) {
      case NotificationTopic.broadcast:
        return Icons.campaign_outlined;
      case NotificationTopic.updates:
        return Icons.system_update_outlined;
      case NotificationTopic.botAlerts:
        return Icons.warning_amber_outlined;
      case NotificationTopic.billing:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _buildNotificationTopicTile(NotificationTopic topic) {
    final service = NotificationService.instance;
    final enabled = service.isTopicEnabled(topic);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: AppIcon.fromMaterial(
        _notificationTopicIcon(topic),
        size: 20,
        color: enabled ? Theme.of(context).colorScheme.primary : AppTheme.grey,
      ),
      title: Text(_notificationTopicLabel(topic)),
      subtitle: Text(
        _notificationTopicDescription(topic),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.grey),
      ),
      value: enabled,
      onChanged: (value) {
        setState(() {}); // trigger rebuild for icon color
        service.setTopicEnabled(topic, value);
      },
    );
  }

  Widget _buildMainApiCard() {
    final statusKey = _mainApiStatusKey;
    final statusColor = _mainApiStatusColor(statusKey);
    final session = _mainApiSession;
    final hasSession = session != null && !session.isExpired;
    final hasDiscordAccount = MobileAccountGate.isDiscordOAuthSession(session);
    final accountConnected = _isManagedMobilePlatform
        ? MobileAccountGate.isManagedAccountSession(session)
        : hasSession;
    final sessionUser = (session?.username ?? '').trim();
    _mainApiUrlController.text.trim();
    final accountTitle = context.tr.settings_main_api_title;
    final accountDescription = context.tr.settings_main_api_desc;
    final accountHint = accountConnected
        ? context.tr.settings_account_connected_hint
        : context.tr.settings_account_disconnected_hint;
    final connectButtonLabel = context.tr.settings_account_connect_label;
    final disconnectButtonLabel = context.tr.settings_account_disconnect_label;
    final mobileStatusText = accountConnected
        ? context.tr.settings_account_status_connected
        : context.tr.settings_account_status_disconnected;
    final mobileStatusColor = accountConnected
        ? AppTheme.successLight
        : AppTheme.warning;

    final isBusy =
        _checkingMainApi ||
        _connectingMainApi ||
        _disconnectingMainApi ||
        _savingAlternativeLogin;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: _mainApiSectionExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _mainApiSectionExpanded = expanded;
          });
        },
        leading: AppIcon.fromMaterial(
          _isManagedMobilePlatform ? Icons.person_outline : Icons.hub_outlined,
          size: 18,
        ),
        title: Text(
          accountTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: statusKey == null
            ? null
            : Text(
                _isManagedMobilePlatform
                    ? mobileStatusText
                    : _translateStatusKey(context, statusKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _isManagedMobilePlatform
                      ? mobileStatusColor
                      : statusColor,
                ),
              ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              accountDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accountConnected
                  ? AppTheme.successLight.withValues(alpha: 0.12)
                  : AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accountConnected
                    ? AppTheme.successLight.withValues(alpha: 0.35)
                    : AppTheme.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon.fromMaterial(
                  accountConnected ? Icons.verified_user : Icons.info_outline,
                  size: 18,
                  color: accountConnected
                      ? AppTheme.successLight
                      : AppTheme.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accountHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          if (accountConnected) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                AppIcon.fromMaterial(
                  Icons.verified_user,
                  size: 18,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sessionUser.isEmpty
                        ? context.tr.settings_main_api_connected_discord
                        : context.tr.settings_main_api_connected_user(
                            sessionUser,
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isBusy ? null : _connectMainApiDiscord,
                icon: _connectingMainApi
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const AppIcon.fromMaterial(Icons.login, size: 18),
                label: Text(connectButtonLabel),
              ),
              OutlinedButton.icon(
                onPressed: isBusy || !accountConnected
                    ? null
                    : _disconnectMainApi,
                icon: _disconnectingMainApi
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const AppIcon.fromMaterial(Icons.logout, size: 18),
                label: Text(disconnectButtonLabel),
              ),
            ],
          ),
          if (_isManagedMobilePlatform && hasDiscordAccount) ...[
            const SizedBox(height: 20),
            _buildAlternativeLoginSection(session),
          ],
        ],
      ),
    );
  }

  Widget _buildAlternativeLoginSection(MainApiSession? session) {
    final tr = context.tr;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: _alternativeLoginExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _alternativeLoginExpanded = expanded);
      },
      title: Text(
        tr.settings_alternative_login_title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: _userHasPassword && (_userEmail?.isNotEmpty ?? false)
          ? Text(_userEmail!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      children: [
        TextField(
          controller: _altLoginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: tr.mobile_login_email,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (_userHasPassword)
          TextField(
            controller: _altLoginCurrentPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: tr.settings_alternative_login_current_password,
              border: const OutlineInputBorder(),
            ),
          ),
        if (_userHasPassword) const SizedBox(height: 12),
        TextField(
          controller: _altLoginPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: tr.mobile_login_password,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _altLoginConfirmController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: tr.settings_alternative_login_confirm_password,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _savingAlternativeLogin
              ? null
              : () => _saveAlternativeLogin(session),
          child: _savingAlternativeLogin
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _userHasPassword
                      ? tr.settings_alternative_login_update
                      : tr.settings_add_credentials,
                ),
        ),
      ],
    );
  }

  Future<void> _saveAlternativeLogin(MainApiSession? session) async {
    if (session == null || session.isExpired) {
      return;
    }

    final email = _altLoginEmailController.text.trim();
    final password = _altLoginPasswordController.text;
    final confirm = _altLoginConfirmController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack(context.tr.settings_alternative_login_missing_fields);
      return;
    }
    if (password != confirm) {
      _showSnack(context.tr.settings_alternative_login_password_mismatch);
      return;
    }

    setState(() => _savingAlternativeLogin = true);
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final client = MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
      final profile = await MainApiCredentialsAuthService.setCredentials(
        client: client,
        email: email,
        password: password,
        currentPassword: _userHasPassword
            ? _altLoginCurrentPasswordController.text
            : null,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _userHasPassword = profile['has_password'] == true;
        _userEmail = (profile['email'] ?? email).toString();
        _altLoginPasswordController.clear();
        _altLoginConfirmController.clear();
        _altLoginCurrentPasswordController.clear();
      });
      _showSnack(context.tr.settings_credentials_saved);
    } on MainApiCredentialsAuthException catch (error) {
      _showSnack(error.message);
    } catch (error) {
      _showSnack(_formatErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _savingAlternativeLogin = false);
      }
    }
  }

  Widget _buildMobileLocalHostingCard() {
    final supportsLocalHosting = RuntimePreferences.supportsMobileLocalHosting;
    final title = context.tr.settings_startup_mode_title;
    final description = context.tr.settings_startup_mode_desc;
    final useBotCreatorServers = !_mobileLocalHostingEnabled;
    final switchTitle = context.tr.settings_startup_mode_use_cloud;
    final switchSubtitle = !supportsLocalHosting
        ? context.tr.settings_startup_mode_ios_warning
        : useBotCreatorServers
        ? context.tr.settings_startup_mode_cloud_desc
        : context.tr.settings_startup_mode_local_desc;
    final warning = !supportsLocalHosting
        ? context.tr.settings_startup_mode_ios_unavailable
        : context.tr.settings_startup_mode_local_warning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon.fromMaterial(Icons.phone_android, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(switchTitle),
              subtitle: Text(switchSubtitle),
              value: useBotCreatorServers,
              onChanged: _loadingMobileLocalHosting || !supportsLocalHosting
                  ? null
                  : (value) => _setMobileLocalHostingEnabled(!value),
            ),
            if (!useBotCreatorServers)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppIcon.fromMaterial(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopRuntimeCard() {
    final title = context.tr.settings_execution_mode_title;
    final description = context.tr.settings_execution_mode_desc;
    final useSelfHostedRunner = !_runnerTemporarilyDisabled;
    final hasStoredRunner = _runnerUrlController.text.trim().isNotEmpty;
    final switchTitle = context.tr.settings_execution_mode_use_runner;
    final switchSubtitle = useSelfHostedRunner
        ? (hasStoredRunner
              ? context.tr.settings_execution_mode_runner_priority
              : context.tr.settings_execution_mode_no_runner)
        : context.tr.settings_execution_mode_local_active;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon.fromMaterial(Icons.developer_mode, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(switchTitle),
              subtitle: Text(switchSubtitle),
              value: useSelfHostedRunner,
              onChanged: _isBusy
                  ? null
                  : (value) => _toggleRunnerTemporarilyDisabled(!value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddedRunnerCard() {
    final service = EmbeddedJsRunnerService.instance;
    final diagnostics = _embeddedRunnerDiagnostics;
    final download = service.downloadProgress.value;
    final logPath = diagnostics?.logPath ?? service.logPath;
    final binaryPath = diagnostics?.binaryPath;
    final binarySize = diagnostics?.binarySizeBytes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon.fromMaterial(
                  service.isDownloading
                      ? Icons.download_outlined
                      : service.isRunning
                      ? Icons.check_circle_outline
                      : Icons.memory_outlined,
                  color: service.isDownloading
                      ? Theme.of(context).colorScheme.primary
                      : service.isRunning
                      ? AppTheme.successLight
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.settings_embedded_runner_title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _embeddedRunnerPrimaryStatusText(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (download != null) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: download.fraction,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              _embeddedRunnerStatusLabel ?? _embeddedRunnerStatusText(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (diagnostics?.version != null &&
                diagnostics!.version!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${context.tr.settings_runner_version}: v${diagnostics.version}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (binaryPath != null && binarySize != null) ...[
              const SizedBox(height: 8),
              Text(
                context.tr.settings_embedded_runner_binary_info(
                  _formatEmbeddedRunnerDownloadBytes(binarySize),
                  _truncateEmbeddedRunnerPath(binaryPath),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (diagnostics?.lastError != null &&
                diagnostics!.lastError!.isNotEmpty &&
                !service.isRunning) ...[
              const SizedBox(height: 8),
              Text(
                diagnostics.lastError!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.errorLight),
              ),
            ],
            if (_runnerTemporarilyDisabled && service.isRunning) ...[
              const SizedBox(height: 8),
              Text(
                _embeddedRunnerExecutionModeHint(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _restartEmbeddedRunner,
                  icon: const AppIcon.fromMaterial(Icons.refresh),
                  label: Text(context.tr.settings_embedded_runner_restart),
                ),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _redownloadEmbeddedRunner,
                  icon: const AppIcon.fromMaterial(Icons.download_outlined),
                  label: Text(context.tr.settings_embedded_runner_redownload),
                ),
                if (logPath != null && logPath.isNotEmpty)
                  TextButton.icon(
                    onPressed: _isBusy ? null : _openEmbeddedRunnerLog,
                    icon: const AppIcon.fromMaterial(
                      Icons.description_outlined,
                    ),
                    label: Text(context.tr.settings_embedded_runner_open_log),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _autoBackupIntervalLabel(int hours) {
    switch (hours) {
      case 6:
        return context.tr.settings_auto_backup_every_6h;
      case 12:
        return context.tr.settings_auto_backup_every_12h;
      case 24:
        return context.tr.settings_auto_backup_every_24h;
      case 72:
        return context.tr.settings_auto_backup_every_72h;
      default:
        return '$hours h';
    }
  }

  String _lastAutoBackupLabel() {
    if (_recoverySettings.lastAutoBackupAt == null) {
      return context.tr.settings_last_auto_backup_never;
    }

    return context.tr.settings_last_auto_backup_at(
      _recoverySettings.lastAutoBackupAt!.toLocal().toString(),
    );
  }

  String _snapshotListEntryLabel(BackupSnapshotSummary snapshot) {
    return context.tr.settings_snapshot_list_entry(
      snapshot.createdAt.toLocal().toString(),
      snapshot.fileCount,
      _formatBytes(snapshot.totalBytes),
    );
  }

  Future<void> _resetLocalPreferences({bool showSnack = true}) async {
    final onboardingManager = context.read<OnboardingManager>();
    final themeProvider = context.read<ThemeProvider>();
    final localeProvider = context.read<LocaleProvider>();

    await _runWithLoading(context.tr.settings_reset_preferences, () async {
      await onboardingManager.reset();
      await themeProvider.resetToDefault();
      await localeProvider.resetToSystem();
      // The `locale` user property follows the language the app is now in.
      unawaited(AppUserProperties.refresh());
    });

    if (!mounted || !showSnack) {
      return;
    }

    _showSnack(context.tr.settings_preferences_reset_done);
  }

  Future<void> _replayOnboarding() async {
    await _resetLocalPreferences(showSnack: false);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (routeContext) => OnboardingPage(
          onComplete: () {
            if (routeContext.mounted) {
              Navigator.of(
                routeContext,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            }
          },
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _deleteSnapshot(BackupSnapshotSummary snapshot) async {
    await _runWithLoading(
      context.tr.settings_snapshot_delete_loading,
      () async {
        try {
          await _ensureDriveApiConnected();
          await deleteBackupSnapshot(
            driveApi!,
            snapshotId: snapshot.snapshotId,
          );
          await _refreshSnapshots();
          if (!mounted) {
            return;
          }
          _showSnack(context.tr.settings_snapshot_deleted);
        } catch (e, st) {
          debugPrint('Delete snapshot failed: $e');
          debugPrintStack(stackTrace: st);
          if (!mounted) {
            return;
          }
          _showSnack(_formatErrorMessage(e));
        }
      },
    );
  }

  Future<void> _restoreSnapshot(BackupSnapshotSummary snapshot) async {
    await _runWithLoading(
      context.tr.settings_snapshot_restore_loading,
      () async {
        try {
          await _ensureDriveApiConnected();
          final message = await restoreBackupSnapshot(
            context,
            driveApi!,
            appManager,
            snapshotId: snapshot.snapshotId,
          );
          await appManager.refreshApps();
          await _refreshSnapshots();
          if (!mounted) {
            return;
          }
          _showSnack(message);
        } catch (e, st) {
          debugPrint('Restore snapshot failed: $e');
          debugPrintStack(stackTrace: st);
          if (!mounted) {
            return;
          }
          _showSnack(_formatErrorMessage(e));
        }
      },
    );
  }

  Widget _buildSnapshotDetailsContent(BackupSnapshotSummary snapshot) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.tr.settings_snapshot_id(snapshot.snapshotId)),
          Text(context.tr.settings_snapshot_label(snapshot.label)),
          Text(
            context.tr.settings_snapshot_created_at(
              snapshot.createdAt.toLocal().toString(),
            ),
          ),
          Text(
            context.tr.settings_snapshot_files_size(
              snapshot.fileCount,
              _formatBytes(snapshot.totalBytes),
            ),
          ),
          Text(context.tr.settings_snapshot_apps_count(snapshot.appCount)),
          const SizedBox(height: 10),
          Text(
            context.tr.settings_snapshot_apps_list,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          if (snapshot.apps.isEmpty)
            Text(context.tr.settings_snapshot_no_metadata)
          else
            ...snapshot.apps.map((entry) {
              final appName = (entry['name'] ?? '').trim();
              final appId = (entry['id'] ?? '').trim();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(appName.isEmpty ? appId : '$appName ($appId)'),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showSnapshotPreview(BackupSnapshotSummary snapshot) async {
    if (!mounted) {
      return;
    }

    final isCompact = MediaQuery.of(context).size.width < 700;

    if (isCompact) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr.settings_snapshot_preview_title,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Flexible(child: _buildSnapshotDetailsContent(snapshot)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _restoreSnapshot(snapshot);
                  },
                  icon: const AppIcon.fromMaterial(Icons.restore),
                  label: Text(context.tr.settings_restore_snapshot),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    final confirmed = await AppTheme.showConfirmDialog(
                      context,
                      title: context.tr.settings_snapshot_delete_loading,
                      content: context.tr.settings_snapshots_delete_one_confirm(
                        snapshot.label,
                      ),
                      confirmLabel: context.tr.delete,
                      isDestructive: true,
                    );
                    if (!confirmed) {
                      return;
                    }
                    await _deleteSnapshot(snapshot);
                  },
                  child: Text(context.tr.delete),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(context.tr.close),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr.settings_snapshot_preview_title),
          content: SizedBox(
            width: 560,
            child: _buildSnapshotDetailsContent(snapshot),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final confirmed = await AppTheme.showConfirmDialog(
                  context,
                  title: context.tr.settings_snapshot_delete_loading,
                  content: context.tr.settings_snapshots_delete_one_confirm(
                    snapshot.label,
                  ),
                  confirmLabel: context.tr.delete,
                  isDestructive: true,
                );
                if (!confirmed) {
                  return;
                }
                await _deleteSnapshot(snapshot);
              },
              child: Text(context.tr.delete),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr.close),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _restoreSnapshot(snapshot);
              },
              icon: const AppIcon.fromMaterial(Icons.restore),
              label: Text(context.tr.settings_restore_snapshot),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllSnapshots() async {
    if (!mounted || _snapshots.isEmpty) {
      return;
    }

    final count = _snapshots.length;
    final confirmed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.settings_snapshots_delete_all_title,
      content: context.tr.settings_snapshots_delete_all_confirm(count),
      confirmLabel: context.tr.delete,
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }

    await _runWithLoading(
      context.tr.settings_snapshots_delete_all_loading,
      () async {
        try {
          await _ensureDriveApiConnected();
          final snapshots = List<BackupSnapshotSummary>.from(_snapshots);
          for (final snapshot in snapshots) {
            await deleteBackupSnapshot(
              driveApi!,
              snapshotId: snapshot.snapshotId,
            );
          }
          await _refreshSnapshots();
          if (!mounted) {
            return;
          }
          _showSnack(
            context.tr.settings_snapshots_delete_all_done(snapshots.length),
          );
        } catch (e, st) {
          debugPrint('Delete all snapshots failed: $e');
          debugPrintStack(stackTrace: st);
          if (!mounted) {
            return;
          }
          _showSnack(_formatErrorMessage(e));
        }
      },
    );
  }

  Future<void> _showSnapshotQuickDeletePicker() async {
    if (!mounted || _snapshots.isEmpty) {
      return;
    }

    final sorted = List<BackupSnapshotSummary>.from(_snapshots)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final selected = await showModalBottomSheet<BackupSnapshotSummary>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr.settings_snapshots_delete_select_title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                context.tr.settings_snapshots_delete_select_desc,
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final snapshot = sorted[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(snapshot.label),
                      subtitle: Text(_snapshotListEntryLabel(snapshot)),
                      trailing: const AppIcon.fromMaterial(
                        Icons.delete_outline,
                      ),
                      onTap: () => Navigator.of(sheetContext).pop(snapshot),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(context.tr.close),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    final confirmed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.settings_snapshot_delete_loading,
      content: context.tr.settings_snapshots_delete_one_confirm(selected.label),
      confirmLabel: context.tr.delete,
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }

    await _deleteSnapshot(selected);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final titleSize = isMobile ? 24.0 : 28.0;

    final localeProvider = context.watch<LocaleProvider>();
    final detectedLocale = detectSystemLocale(
      Localizations.maybeLocaleOf(context),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.settings_tab),
        centerTitle: true,
        // Sur desktop, la barre de titre du shell (DesktopTitleBar) affiche déjà
        // sa propre flèche de retour juste au-dessus de la page : en rendre une
        // seconde ici empile deux flèches. Embarquée dans le shell compact, la
        // page n'est pas une route poussée : pas de flèche non plus.
        automaticallyImplyLeading:
            !widget.embedded && !windowChromeOwnsBackButton(),
      ),
      // Embarquée dans le shell compact, la page vit SOUS la réserve de la
      // barre flottante (`FloatingGlassNavBar.contentClearanceOf`, inset système
      // compris) : réserver l'inset bas une seconde fois laissait un vide de
      // [24 + inset] px entre la dernière carte et la barre. Autonome (route
      // poussée depuis la Home), elle doit au contraire l'éviter.
      body: SafeArea(
        bottom: !widget.embedded,
        // Largeur et marges communes à toutes les pages de l'app : la page
        // n'impose plus ses propres bornes (600 px, padding 16/24).
        child: PageContent(
          child: SingleChildScrollView(
            // Marge verticale propre à la page : l'horizontale est fournie par
            // PageContent.
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  context.tr.settings_backup_restore_title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr.settings_backup_restore_desc,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                const _DocumentationCard(),
                const SizedBox(height: 16),

                // ── Support Discord card ────────────────────────────────────
                _SupportDiscordCard(),
                const SizedBox(height: 16),
                _SubscriptionsSettingsCard(),
                const SizedBox(height: 16),
                _PrivacyPolicyCard(
                  checkingAdPrivacy: _checkingAdPrivacy,
                  adPrivacyRequired: _adPrivacyRequired,
                  onOpenAdPrivacy: _checkingAdPrivacy
                      ? null
                      : (_adPrivacyRequired ? _openAdPrivacyOptions : null),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),

                // ── Carte Apparence : mode, presets, couleurs perso ────────
                const AppearanceSettingsSection(),
                const SizedBox(height: 24),

                // ── Carte Langue : l'ancienne carte « Apparence et langue »
                //    ne porte plus que la langue (l'apparence a sa carte)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.settings_language_title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr.settings_language_desc,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<AppLocalePreference>(
                          initialValue: localeProvider.preference,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: context.tr.settings_language_title,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: AppLocalePreference.system,
                              child: _dropdownLabel(
                                _languagePreferenceLabel(
                                  AppLocalePreference.system,
                                  detectedLocale,
                                ),
                              ),
                            ),
                            ...AppLocale.values.map(
                              (locale) => DropdownMenuItem(
                                value: _localeToPreference(locale),
                                child: _dropdownLabel(locale.label),
                              ),
                            ),
                          ],
                          selectedItemBuilder: (context) => AppLocalePreference
                              .values
                              .map(
                                (preference) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: _dropdownLabel(
                                    _languagePreferenceLabel(
                                      preference,
                                      detectedLocale,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            if (value == null) {
                              return;
                            }

                            await localeProvider.setPreference(value);
                            // The `locale` user property follows the language
                            // the app is now in.
                            unawaited(AppUserProperties.refresh());
                            if (!mounted) {
                              return;
                            }
                            _showSnack(context.tr.settings_language_updated);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // ── Code editor customization card ──────────────────
                const CodeEditorSettingsCard(),
                const SizedBox(height: 24),
                // ── Notifications card ──────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.settings_notifications_title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr.settings_notifications_desc,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: AppTheme.grey),
                        ),
                        const SizedBox(height: 8),
                        ...NotificationTopic.values.map(
                          (topic) => _buildNotificationTopicTile(topic),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (kDebugMode) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.settings_debug_title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr.settings_debug_desc,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr.settings_reset_preferences_desc,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isBusy
                                  ? null
                                  : () => _resetLocalPreferences(),
                              icon: const AppIcon.fromMaterial(
                                Icons.restart_alt,
                              ),
                              label: Text(
                                context.tr.settings_reset_preferences,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr.settings_replay_onboarding_desc,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isBusy
                                  ? null
                                  : () => _replayOnboarding(),
                              icon: const AppIcon.fromMaterial(
                                Icons.rocket_launch_outlined,
                              ),
                              label: Text(
                                context.tr.settings_replay_onboarding,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: const AppIcon.fromMaterial(
                              Icons.workspace_premium_rounded,
                            ),
                            title: Text(
                              context.tr.settings_debug_premium_bypass,
                            ),
                            subtitle: Text(
                              context.tr.settings_debug_premium_bypass_desc,
                            ),
                            value: PremiumCapabilities.debugPremiumBypass,
                            onChanged: (value) {
                              setState(() {
                                PremiumCapabilities.debugPremiumBypass = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.settings_ads_debug_title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr.settings_ads_debug_desc,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.grey),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: _runMediationDiagnostics,
                                icon: const AppIcon.fromMaterial(
                                  Icons.analytics_outlined,
                                ),
                                label: Text(
                                  context.tr.settings_run_diagnostics,
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _openAdInspector,
                                icon: const AppIcon.fromMaterial(
                                  Icons.bug_report_outlined,
                                ),
                                label: Text(
                                  context.tr.settings_open_ad_inspector,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_isBusy)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 12),
                        Flexible(child: Text(_busyMessage)),
                      ],
                    ),
                  ),
                // Connection Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.settings_drive_title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (driveApi == null) ...[
                        Text(
                          context.tr.settings_drive_desc,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isBusy
                                ? null
                                : () async {
                                    await _runWithLoading(
                                      context.tr.settings_drive_connect_loading,
                                      () async {
                                        try {
                                          await _ensureDriveApiConnected();
                                          await _refreshSnapshots();
                                          await _runAutoBackupCheck(
                                            force: false,
                                            showSnack: false,
                                          );
                                          _showSnack(
                                            context.tr.settings_drive_connected,
                                          );
                                        } catch (e, st) {
                                          debugPrint(
                                            'Connect to Google Drive failed: $e',
                                          );
                                          debugPrintStack(stackTrace: st);
                                          _showSnack(_formatErrorMessage(e));
                                        }
                                      },
                                    );
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppIcon.fromMaterial(Icons.g_mobiledata),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    context.tr.settings_drive_connect,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            AppIcon.fromMaterial(
                              Icons.check_circle,
                              color: AppTheme.successLight,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                context.tr.settings_drive_status_connected,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.successLight),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isBusy
                                ? null
                                : () async {
                                    await _runWithLoading(
                                      context
                                          .tr
                                          .settings_drive_disconnect_loading,
                                      () async {
                                        await disconnectDriveAccount();
                                        if (!mounted) {
                                          return;
                                        }
                                        setState(() {
                                          driveApi = null;
                                        });
                                        await _loadCachedSnapshotsFromCache();
                                        _showSnack(
                                          context
                                              .tr
                                              .settings_drive_disconnected,
                                        );
                                      },
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppIcon.fromMaterial(Icons.logout),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    context.tr.settings_drive_disconnect,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (true) ...[
                  // Show Main API card on all platforms (desktop included)
                  const SizedBox(height: 24),
                  _buildMainApiCard(),
                  const SizedBox(height: 16),
                ],
                if (_isManagedMobilePlatform) ...[
                  _buildMobileLocalHostingCard(),
                  const SizedBox(height: 16),
                ],
                if (!_isManagedMobilePlatform) ...[
                  _buildDesktopRuntimeCard(),
                  const SizedBox(height: 16),
                  if (_isDesktopPlatform) ...[
                    _buildEmbeddedRunnerCard(),
                    const SizedBox(height: 16),
                  ],
                ],
                // Version de l'APPLICATION et mises à jour : des informations globales,
                // déplacées ici depuis les réglages d'un bot — elles n'ont rien à voir
                // avec un bot, et le même contenu réapparaissait pour chaque bot.
                const AppVersionAndUpdatesCard(),
                const SizedBox(height: 16),
                if (!_isManagedMobilePlatform && !_runnerTemporarilyDisabled)
                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: _developerSectionExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _developerSectionExpanded = expanded;
                        });
                      },
                      leading: const AppIcon.fromMaterial(
                        Icons.developer_mode,
                        size: 18,
                      ),
                      title: Text(
                        context.tr.settings_runner_title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: _runnerTemporarilyDisabled
                          ? Text(
                              context.tr.settings_runner_temporarily_disabled,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.warning),
                            )
                          : _runnerStatusKey == null
                          ? null
                          : Text(
                              _translateStatusKey(context, _runnerStatusKey!),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color:
                                        _runnerStatusKey ==
                                            'settings_runner_connected'
                                        ? AppTheme.successLight
                                        : AppTheme.errorLight,
                                  ),
                            ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.tr.settings_runner_desc,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isDesktopPlatform) ...[
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(context.tr.settings_runner_use_remote),
                            subtitle: Text(
                              context.tr.settings_runner_use_remote_desc,
                            ),
                            value: _useRemoteRunner,
                            onChanged: _runnerTemporarilyDisabled || _isBusy
                                ? null
                                : _toggleUseRemoteRunner,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_showsRemoteRunnerConfig) ...[
                          Text(
                            context.tr.settings_runner_type_label,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<RunnerKind>(
                            segments: [
                              const ButtonSegment(
                                value: RunnerKind.dart,
                                label: Text('Dart'),
                                icon: AppIcon.fromMaterial(Icons.memory),
                              ),

                              const ButtonSegment(
                                value: RunnerKind.javascript,
                                label: Text('JS'),
                                icon: AppIcon.fromMaterial(Icons.code),
                              ),

                              ButtonSegment(
                                value: RunnerKind.auto,
                                label: Text(context.tr.common_auto),
                                icon: const AppIcon.fromMaterial(
                                  Icons.auto_awesome,
                                ),
                              ),
                            ],
                            selected: {_runnerKind},
                            onSelectionChanged: _runnerTemporarilyDisabled
                                ? null
                                : (selection) {
                                    setState(() {
                                      _runnerKind = selection.first;
                                    });
                                  },
                          ),
                          if (_runnerEngineLabel != null &&
                              _runnerEngineLabel!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${context.tr.settings_detected_engine(_runnerEngineLabel!)}'
                              '${_runnerVersionLabel != null && _runnerVersionLabel!.isNotEmpty ? ' · v$_runnerVersionLabel' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              context.tr.settings_runner_disable_temp,
                            ),
                            subtitle: Text(
                              context.tr.settings_runner_disable_temp_desc,
                            ),
                            value: _runnerTemporarilyDisabled,
                            onChanged: _isBusy
                                ? null
                                : _toggleRunnerTemporarilyDisabled,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _runnerUrlController,
                            decoration: InputDecoration(
                              hintText: context.tr.settings_runner_url_hint,
                              isDense: true,
                              border: const OutlineInputBorder(),
                              suffixIcon:
                                  (_runnerTemporarilyDisabled ||
                                      _checkingRunner)
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : (_runnerStatusKey == null
                                        ? null
                                        : AppIcon.fromMaterial(
                                            _runnerStatusKey ==
                                                    'settings_runner_connected'
                                                ? Icons.check_circle
                                                : Icons.error_outline,
                                            color:
                                                _runnerStatusKey ==
                                                    'settings_runner_connected'
                                                ? AppTheme.successLight
                                                : AppTheme.errorLight,
                                            size: 18,
                                          )),
                            ),
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _runnerApiTokenController,
                            decoration: InputDecoration(
                              labelText: context.tr.settings_runner_token_label,
                              hintText: context.tr.settings_runner_token_hint,
                              isDense: true,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _runnerTokenObscured =
                                        !_runnerTokenObscured;
                                  });
                                },
                                icon: AppIcon.fromMaterial(
                                  _runnerTokenObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18,
                                ),
                              ),
                            ),
                            autocorrect: false,
                            obscureText: _runnerTokenObscured,
                          ),
                          const SizedBox(height: 12),
                          if (isMobile) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isBusy ||
                                        _checkingRunner ||
                                        _runnerTemporarilyDisabled
                                    ? null
                                    : _saveRunnerSettings,
                                icon: const AppIcon.fromMaterial(
                                  Icons.save_outlined,
                                  size: 18,
                                ),
                                label: Text(context.tr.settings_runner_save),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _checkingRunner ||
                                        _runnerTemporarilyDisabled
                                    ? null
                                    : _checkRunnerConnection,
                                icon: _checkingRunner
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const AppIcon.fromMaterial(
                                        Icons.wifi_find,
                                        size: 18,
                                      ),
                                label: Text(context.tr.settings_runner_check),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isBusy
                                    ? null
                                    : () {
                                        _runnerUrlController.clear();
                                        _runnerApiTokenController.clear();
                                        _saveRunnerSettings();
                                      },
                                icon: const AppIcon.fromMaterial(
                                  Icons.clear,
                                  size: 18,
                                ),
                                label: Text(context.tr.settings_runner_clear),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isBusy ||
                                            _checkingRunner ||
                                            _runnerTemporarilyDisabled
                                        ? null
                                        : _saveRunnerSettings,
                                    icon: const AppIcon.fromMaterial(
                                      Icons.save_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      context.tr.settings_runner_save,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed:
                                      _checkingRunner ||
                                          _runnerTemporarilyDisabled
                                      ? null
                                      : _checkRunnerConnection,
                                  icon: _checkingRunner
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const AppIcon.fromMaterial(
                                          Icons.wifi_find,
                                          size: 18,
                                        ),
                                  label: Text(context.tr.settings_runner_check),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _isBusy
                                      ? null
                                      : () {
                                          _runnerUrlController.clear();
                                          _runnerApiTokenController.clear();
                                          _saveRunnerSettings();
                                        },
                                  icon: const AppIcon.fromMaterial(
                                    Icons.clear,
                                    size: 18,
                                  ),
                                  tooltip: context.tr.settings_runner_clear,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                if (!_isManagedMobilePlatform && !_runnerTemporarilyDisabled)
                  const SizedBox(height: 16),
                // Data Operations Section
                Text(
                  context.tr.settings_data_operations_title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (isWideScreen)
                  Row(
                    children: [
                      Expanded(
                        child: _buildDataButton(
                          context,
                          icon: Icons.upload_file,
                          label: context.tr.settings_export,
                          onPressed: _isBusy
                              ? null
                              : () async {
                                  await _runWithLoading(
                                    context.tr.settings_export_loading,
                                    () async {
                                      try {
                                        await _ensureDriveApiConnected();
                                        if (!mounted) return;
                                        final message = await uploadAppData(
                                          context,
                                          driveApi!,
                                          appManager,
                                        );
                                        await _refreshSnapshots();
                                        if (!mounted) return;
                                        _showSnack(message);
                                      } catch (e, st) {
                                        debugPrint(
                                          'Export App Data failed: $e',
                                        );
                                        debugPrintStack(stackTrace: st);
                                        if (mounted) {
                                          _showSnack(_formatErrorMessage(e));
                                        }
                                      }
                                    },
                                  );
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDataButton(
                          context,
                          icon: Icons.file_download_outlined,
                          label: context.tr.settings_import,
                          onPressed: _isBusy
                              ? null
                              : () async {
                                  await _runWithLoading(
                                    context.tr.settings_import_loading,
                                    () async {
                                      try {
                                        await _ensureDriveApiConnected();
                                        final message = await downloadAppData(
                                          context,
                                          driveApi!,
                                          appManager,
                                        );
                                        await appManager.refreshApps();
                                        await _refreshSnapshots();
                                        _showSnack(message);
                                      } catch (e, st) {
                                        debugPrint(
                                          'Import App Data failed: $e',
                                        );
                                        debugPrintStack(stackTrace: st);
                                        if (mounted) {
                                          _showSnack(_formatErrorMessage(e));
                                        }
                                      }
                                    },
                                  );
                                },
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildDataButton(
                        context,
                        icon: Icons.upload_file,
                        label: context.tr.settings_export_app_data,
                        onPressed: _isBusy
                            ? null
                            : () async {
                                await _runWithLoading(
                                  context.tr.settings_export_loading,
                                  () async {
                                    try {
                                      await _ensureDriveApiConnected();
                                      final message = await uploadAppData(
                                        context,
                                        driveApi!,
                                        appManager,
                                      );
                                      await _refreshSnapshots();
                                      _showSnack(message);
                                    } catch (e, st) {
                                      debugPrint('Export App Data failed: $e');
                                      debugPrintStack(stackTrace: st);
                                      _showSnack(_formatErrorMessage(e));
                                    }
                                  },
                                );
                              },
                      ),
                      const SizedBox(height: 12),
                      _buildDataButton(
                        context,
                        icon: Icons.file_download_outlined,
                        label: context.tr.settings_import_app_data,
                        onPressed: _isBusy
                            ? null
                            : () async {
                                await _runWithLoading(
                                  context.tr.settings_import_loading,
                                  () async {
                                    try {
                                      await _ensureDriveApiConnected();
                                      final message = await downloadAppData(
                                        context,
                                        driveApi!,
                                        appManager,
                                      );
                                      await appManager.refreshApps();
                                      await _refreshSnapshots();
                                      _showSnack(message);
                                    } catch (e, st) {
                                      debugPrint('Import App Data failed: $e');
                                      debugPrintStack(stackTrace: st);
                                      _showSnack(_formatErrorMessage(e));
                                    }
                                  },
                                );
                              },
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                Text(
                  context.tr.settings_recovery_title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(context.tr.settings_enable_auto_backup),
                          subtitle: Text(
                            context.tr.settings_enable_auto_backup_desc,
                          ),
                          value:
                              !_loadingRecoverySettings &&
                              _recoverySettings.autoBackupEnabled,
                          onChanged: _loadingRecoverySettings
                              ? null
                              : (enabled) async {
                                  final next = _recoverySettings.copyWith(
                                    autoBackupEnabled: enabled,
                                  );
                                  await _saveRecoverySettings(next);
                                },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          key: ValueKey(
                            'auto_backup_interval_${_recoverySettings.autoBackupIntervalHours}',
                          ),
                          initialValue:
                              _recoverySettings.autoBackupIntervalHours,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: context.tr.settings_auto_backup_interval,
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 6,
                              child: Text(_autoBackupIntervalLabel(6)),
                            ),
                            DropdownMenuItem(
                              value: 12,
                              child: Text(_autoBackupIntervalLabel(12)),
                            ),
                            DropdownMenuItem(
                              value: 24,
                              child: Text(_autoBackupIntervalLabel(24)),
                            ),
                            DropdownMenuItem(
                              value: 72,
                              child: Text(_autoBackupIntervalLabel(72)),
                            ),
                          ],
                          onChanged:
                              (!_recoverySettings.autoBackupEnabled ||
                                  _loadingRecoverySettings)
                              ? null
                              : (value) async {
                                  if (value == null) {
                                    return;
                                  }
                                  final next = _recoverySettings.copyWith(
                                    autoBackupIntervalHours: value,
                                  );
                                  await _saveRecoverySettings(next);
                                },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastAutoBackupLabel(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isBusy
                                  ? null
                                  : () async {
                                      await _runWithLoading(
                                        context
                                            .tr
                                            .settings_snapshot_create_loading,
                                        () async {
                                          try {
                                            await _ensureDriveApiConnected();
                                            final snapshot =
                                                await createBackupSnapshot(
                                                  driveApi!,
                                                  appManager,
                                                  label: context
                                                      .tr
                                                      .settings_manual_snapshot_label,
                                                );
                                            await _refreshSnapshots();
                                            if (!mounted) {
                                              return;
                                            }
                                            _showSnack(
                                              context.tr
                                                  .settings_snapshot_created_message(
                                                    snapshot.snapshotId,
                                                  ),
                                            );
                                          } catch (e, st) {
                                            debugPrint(
                                              'Manual snapshot failed: $e',
                                            );
                                            debugPrintStack(stackTrace: st);
                                            if (!mounted) {
                                              return;
                                            }
                                            _showSnack(_formatErrorMessage(e));
                                          }
                                        },
                                      );
                                    },
                              icon: const AppIcon.fromMaterial(Icons.backup),
                              label: Text(context.tr.settings_backup_now),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  _isBusy ||
                                      !_recoverySettings.autoBackupEnabled
                                  ? null
                                  : () async {
                                      await _runWithLoading(
                                        context
                                            .tr
                                            .settings_auto_backup_check_loading,
                                        () async {
                                          await _ensureDriveApiConnected();
                                          await _runAutoBackupCheck(
                                            force: true,
                                            showSnack: true,
                                          );
                                        },
                                      );
                                    },
                              icon: const AppIcon.fromMaterial(
                                Icons.schedule_send,
                              ),
                              label: Text(
                                context.tr.settings_run_auto_backup_now,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr.settings_snapshots_title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: context
                                  .tr
                                  .settings_snapshots_delete_select_tooltip,
                              onPressed:
                                  _isBusy ||
                                      _loadingSnapshots ||
                                      _snapshots.isEmpty
                                  ? null
                                  : _showSnapshotQuickDeletePicker,
                              icon: const AppIcon.fromMaterial(
                                Icons.remove_circle_outline,
                              ),
                            ),
                            IconButton(
                              tooltip: context.tr.settings_snapshots_delete_all,
                              onPressed:
                                  _isBusy ||
                                      _loadingSnapshots ||
                                      _snapshots.isEmpty
                                  ? null
                                  : _deleteAllSnapshots,
                              icon: const AppIcon.fromMaterial(
                                Icons.delete_sweep_outlined,
                              ),
                            ),
                            IconButton(
                              tooltip: context.tr.settings_snapshots_refresh,
                              onPressed: _isBusy || _loadingSnapshots
                                  ? null
                                  : () async {
                                      await _runWithLoading(
                                        context
                                            .tr
                                            .settings_snapshots_refresh_loading,
                                        () async {
                                          await _ensureDriveApiConnected();
                                          await _refreshSnapshots();
                                        },
                                      );
                                    },
                              icon: const AppIcon.fromMaterial(Icons.refresh),
                            ),
                          ],
                        ),
                        if (_loadingSnapshots)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_snapshots.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              context.tr.settings_snapshots_empty,
                              style: const TextStyle(color: AppTheme.grey),
                            ),
                          )
                        else
                          ..._snapshots.take(8).map((snapshot) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(snapshot.label),
                              subtitle: Text(_snapshotListEntryLabel(snapshot)),
                              trailing: const AppIcon.fromMaterial(
                                Icons.chevron_right,
                              ),
                              onTap: () => _showSnapshotPreview(snapshot),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  context.tr.settings_diagnostics_section_title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (isWideScreen)
                  Row(
                    children: [
                      Expanded(
                        child: _buildDataButton(
                          context,
                          icon: Icons.bug_report_outlined,
                          label: context.tr.settings_view_startup_logs,
                          onPressed: _isBusy
                              ? null
                              : () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const DiagnosticsLogsPage(),
                                    ),
                                  );
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDataButton(
                          context,
                          icon: Icons.delete_outline,
                          label: context.tr.settings_clear_logs,
                          onPressed: _isBusy
                              ? null
                              : () async {
                                  await AppDiagnostics.clearLog();
                                  if (!mounted) {
                                    return;
                                  }
                                  _showSnack(context.tr.settings_logs_cleared);
                                },
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildDataButton(
                        context,
                        icon: Icons.bug_report_outlined,
                        label: context.tr.settings_view_startup_logs,
                        onPressed: _isBusy
                            ? null
                            : () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const DiagnosticsLogsPage(),
                                  ),
                                );
                              },
                      ),
                      const SizedBox(height: 12),
                      _buildDataButton(
                        context,
                        icon: Icons.delete_outline,
                        label: context.tr.settings_clear_logs,
                        onPressed: _isBusy
                            ? null
                            : () async {
                                await AppDiagnostics.clearLog();
                                if (!mounted) {
                                  return;
                                }
                                _showSnack(context.tr.settings_logs_cleared);
                              },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: AppIcon.fromMaterial(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : 12,
          horizontal: isMobile ? 12 : 16,
        ),
      ),
    );
  }
}

class _SettingsLifecycleObserver extends WidgetsBindingObserver {
  _SettingsLifecycleObserver({required this.onResumed});

  final Future<void> Function() onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(onResumed());
    }
  }
}

class _PrivacyPolicyCard extends StatelessWidget {
  const _PrivacyPolicyCard({
    required this.checkingAdPrivacy,
    required this.adPrivacyRequired,
    required this.onOpenAdPrivacy,
  });

  final bool checkingAdPrivacy;
  final bool adPrivacyRequired;
  final VoidCallback? onOpenAdPrivacy;

  static const _privacyPolicyUrl = privacyPolicyUrl;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(_privacyPolicyUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _reportOpenFailure(context);
      }
    } catch (_) {
      _reportOpenFailure(context);
    }
  }

  /// L'échec d'ouverture est dit à l'utilisateur s'il y a un
  /// `ScaffoldMessenger`, et JOURNALISÉ sinon : jamais un no-op muet.
  void _reportOpenFailure(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr.app_open_link_error)),
      );
      return;
    }
    unawaited(
      AppDiagnostics.logInfo(
        'Settings: link failure could not be shown to the user',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.settings_legal_title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr.settings_legal_desc,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _open(context),
                icon: const AppIcon.fromMaterial(Icons.privacy_tip_outlined),
                label: Text(context.tr.settings_privacy_policy),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenAdPrivacy,
                icon: checkingAdPrivacy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const AppIcon.fromMaterial(Icons.shield_outlined),
                label: Text(
                  checkingAdPrivacy
                      ? context.tr.settings_ads_privacy_loading
                      : (adPrivacyRequired
                            ? context.tr.settings_ads_privacy_manage
                            : context.tr.settings_ads_privacy_not_required),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final info = await PackageInfo.fromPlatform();
                  if (context.mounted) {
                    showLicensePage(
                      context: context,
                      applicationName: info.appName,
                      applicationVersion: info.version,
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AppIcon.fromMaterial(
                          Icons.smart_toy_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                },
                icon: const AppIcon.fromMaterial(Icons.description_outlined),
                label: Text(context.tr.settings_oss_licenses),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Documentation Card ─────────────────────────────────────────────────────

class _DocumentationCard extends StatelessWidget {
  const _DocumentationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: AppIcon.fromMaterial(
          Icons.menu_book_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(context.tr.docs_hub_title),
        subtitle: Text(context.tr.bot_settings_workflow_docs_desc),
        trailing: const AppIcon.fromMaterial(Icons.chevron_right),
        onTap: () => openDocumentationHub(context, showDiscordJsTab: true),
      ),
    );
  }
}

// ── Support Discord Card ───────────────────────────────────────────────────

class _SupportDiscordCard extends StatelessWidget {
  const _SupportDiscordCard();

  static const _discordUrl = 'https://discord.gg/gyEGNBUZdA';
  static const _discordColor = AppTheme.discord;

  Future<void> _open() async {
    final uri = Uri.parse(_discordUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        // Surface plate (pas de dégradé) : couleur de marque Discord unie.
        decoration: const BoxDecoration(color: _discordColor),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon.fromMaterial(
                      Icons.verified_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        context.tr.support_discord_badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const AppIcon.fromMaterial(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr.support_card_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.support_card_desc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _open,
                  icon: const AppIcon.fromMaterial(Icons.open_in_new, size: 16),
                  label: Text(context.tr.support_join_discord),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _discordColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subscriptions entry ─────────────────────────────────────────────────────

class _SubscriptionsSettingsCard extends StatefulWidget {
  const _SubscriptionsSettingsCard();

  @override
  State<_SubscriptionsSettingsCard> createState() =>
      _SubscriptionsSettingsCardState();
}

class _SubscriptionsSettingsCardState
    extends State<_SubscriptionsSettingsCard> {
  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      SubscriptionService.resolveEffectivePremiumStatus(forceRefresh: true),
      HostedAppSubscriptionService.resolveEffectiveHostedAppStatus(
        forceRefresh: true,
      ),
    ]);
    if (mounted) setState(() {});
  }

  String _summary(BuildContext context) {
    final tr = context.tr;
    final bot = SubscriptionService.isSubscribed;
    final hosted = HostedAppSubscriptionService.isSubscribed;
    if (bot && hosted) {
      return tr.subscriptions_hub_summary_both;
    }
    if (bot) {
      return tr.subscriptions_hub_summary_bot_only;
    }
    if (hosted) {
      return tr.subscriptions_hub_summary_hosted_only;
    }
    return tr.subscriptions_hub_summary_none;
  }

  @override
  Widget build(BuildContext context) {
    if (!SubscriptionService.supportsNativeBilling) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await SubscriptionsHubPage.open(context);
          if (mounted) {
            await _refresh();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const AppIcon.fromMaterial(
                Icons.subscriptions_outlined,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.subscriptions_hub_open_settings,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _summary(context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const AppIcon.fromMaterial(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

String _translateStatusKey(BuildContext context, String statusKey) {
  switch (statusKey) {
    case 'settings_runner_connected':
      return context.tr.settings_runner_connected;
    case 'settings_runner_disconnected':
      return context.tr.settings_runner_disconnected;
    case 'settings_runner_temporarily_disabled':
      return context.tr.settings_runner_temporarily_disabled;
    case 'settings_main_api_connected':
      return context.tr.settings_main_api_connected;
    case 'settings_main_api_session_connected':
      return context.tr.settings_main_api_session_connected;
    case 'settings_main_api_session_disconnected':
      return context.tr.settings_main_api_session_disconnected;
    case 'settings_main_api_title':
      return context.tr.settings_main_api_title;
    case 'settings_main_api_desc':
      return context.tr.settings_main_api_desc;
    default:
      return statusKey;
  }
}

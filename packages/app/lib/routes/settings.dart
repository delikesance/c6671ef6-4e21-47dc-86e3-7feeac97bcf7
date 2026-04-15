import 'dart:async';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/utils/app_theme.dart';
import 'package:bot_creator/routes/bdfd_compatible_functions.dart';
import 'package:bot_creator/routes/diagnostics_logs_page.dart';
import 'package:bot_creator/routes/onboarding.dart';
import 'package:bot_creator/utils/analytics.dart';
import 'package:bot_creator/utils/ad_consent_service.dart';
import 'package:bot_creator/utils/ad_mediation_debug.dart';
import 'package:bot_creator/utils/app_diagnostics.dart';
import 'package:bot_creator/utils/discord_rpc_service.dart';
import 'package:bot_creator/utils/premium_capabilities.dart';
import 'package:bot_creator/utils/subscription_service.dart';
import 'package:bot_creator/widgets/subscription_page.dart';
import 'package:bot_creator/utils/drive.dart';
import 'package:bot_creator/utils/i18n.dart';
import 'package:bot_creator/utils/onboarding_manager.dart';
import 'package:bot_creator/utils/recovery_manager.dart';
import 'package:bot_creator/utils/runner_client.dart';
import 'package:bot_creator/utils/runner_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

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
  final TextEditingController _discordRpcClientIdController =
      TextEditingController();
  bool _checkingRunner = false;
  String? _runnerStatusKey;
  bool _runnerTokenObscured = true;
  bool _runnerTemporarilyDisabled = false;
  StreamSubscription<DiscordRpcSnapshot>? _discordRpcSnapshotSubscription;
  DiscordRpcSnapshot? _discordRpcSnapshot;
  bool _loadingDiscordRpc = true;
  bool _savingDiscordRpc = false;
  bool _connectingDiscordRpc = false;
  bool _disconnectingDiscordRpc = false;
  bool _discordRpcEnabled = false;
  bool _checkingAdPrivacy = false;
  bool _adPrivacyRequired = false;
  bool _discordSectionExpanded = false;
  bool _developerSectionExpanded = false;

  bool get _isDesktopPlatform {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

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
    _loadCachedSnapshotsFromCache();
    _loadRecoverySettings();
    _initializeDriveApi();
    _loadRunnerSettings();
    if (_isDesktopPlatform) {
      _loadDiscordRpcSettings();
    } else {
      _loadingDiscordRpc = false;
    }
    _loadAdPrivacyRequirement();
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
    final config = await RunnerSettings.getStoredConfig();
    final isDisabled = await RunnerSettings.isTemporarilyDisabled();
    if (!mounted) return;
    setState(() {
      _runnerUrlController.text = config?.url ?? '';
      _runnerApiTokenController.text = config?.apiToken ?? '';
      _runnerTemporarilyDisabled = isDisabled;
    });
    if (config != null && !isDisabled) {
      await _checkRunnerConnection();
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

    if (!disabled && _runnerUrlController.text.trim().isNotEmpty) {
      await _checkRunnerConnection();
    }

    _showSnack(
      AppStrings.t(
        disabled
            ? 'settings_runner_temporarily_disabled_saved'
            : 'settings_runner_reenabled',
      ),
    );
  }

  Future<void> _saveRunnerSettings() async {
    final url = _runnerUrlController.text.trim();
    final apiToken = _runnerApiTokenController.text.trim();
    await RunnerSettings.save(url: url, apiToken: apiToken);
    if (!mounted) return;
    setState(() {
      _runnerStatusKey = null;
    });
    _showSnack(
      url.isEmpty && apiToken.isEmpty
          ? context.tr.settings_runner_cleared
          : context.tr.settings_runner_saved,
    );
    if (url.isNotEmpty) {
      await _checkRunnerConnection();
    }
  }

  Future<void> _checkRunnerConnection() async {
    final url = _runnerUrlController.text.trim();
    if (url.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _checkingRunner = true;
      _runnerStatusKey = null;
    });
    try {
      final client = RunnerConnectionConfig(
        id: '_check',
        url: url,
        apiToken: _runnerApiTokenController.text.trim(),
      ).createClient(
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 90),
      );
      await client.getStatus();
      if (!mounted) return;
      setState(() {
        _runnerStatusKey = 'settings_runner_connected';
        _checkingRunner = false;
      });
    } on RunnerClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _runnerStatusKey =
            error.statusCode == 401 || error.statusCode == 403
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

  @override
  void dispose() {
    _discordRpcSnapshotSubscription?.cancel();
    _discordRpcClientIdController.dispose();
    _runnerUrlController.dispose();
    _runnerApiTokenController.dispose();
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
      final suffix =
          result.snapshot == null
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

  ScaffoldMessengerState? _currentScaffoldMessenger() {
    if (!mounted) {
      return null;
    }
    final currentMessenger = ScaffoldMessenger.maybeOf(context);
    if (currentMessenger != null) {
      return currentMessenger;
    }
    final navigatorContext = MyApp.navigatorKey.currentContext;
    if (navigatorContext == null) {
      return null;
    }
    return ScaffoldMessenger.maybeOf(navigatorContext);
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
    }
  }

  String _formatErrorMessage(Object error) {
    return context.tr.error_with_details(error.toString());
  }

  Future<void> _loadDiscordRpcSettings() async {
    try {
      final service = DiscordRpcService.instance;
      final snapshot = await service.initialize();
      final subscription = service.snapshots.listen((snapshot) {
        if (!mounted) {
          return;
        }
        setState(() {
          _discordRpcSnapshot = snapshot;
        });
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
      setState(() {
        _discordRpcSnapshot = snapshot;
        _discordRpcEnabled = snapshot.config.enabled;
        _loadingDiscordRpc = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingDiscordRpc = false;
      });
      _showSnack(_formatErrorMessage(error));
    }
  }

  Future<DiscordRpcSnapshot?> _saveDiscordRpcSettings({
    bool showSnack = true,
  }) async {
    if (_loadingDiscordRpc) {
      return _discordRpcSnapshot;
    }
    if (!mounted) {
      return _discordRpcSnapshot;
    }

    setState(() {
      _savingDiscordRpc = true;
    });

    try {
      await AppDiagnostics.logInfo(
        'Discord RPC settings save requested from UI',
        data: <String, Object?>{
          'enabled': _discordRpcEnabled,
          'applicationId': _discordRpcClientIdController.text.trim(),
        },
      );
      final snapshot = await DiscordRpcService.instance.updateConfig(
        enabled: _discordRpcEnabled,
        clientId: _discordRpcClientIdController.text,
        clientSecret: '',
        brokerUrl: '',
      );
      if (!mounted) {
        return snapshot;
      }
      setState(() {
        _discordRpcSnapshot = snapshot;
        _discordRpcEnabled = snapshot.config.enabled;
      });
      if (showSnack) {
        _showSnack(context.tr.settings_discord_rpc_saved);
      }
      return snapshot;
    } catch (error) {
      _showSnack(_formatErrorMessage(error));
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _savingDiscordRpc = false;
        });
      }
    }
  }

  Future<void> _connectDiscordRpc() async {
    final savedSnapshot = await _saveDiscordRpcSettings(showSnack: false);
    if (!mounted || savedSnapshot == null) {
      return;
    }
    if (!savedSnapshot.config.enabled) {
      _showSnack(context.tr.settings_discord_rpc_enable_first);
      return;
    }

    await AppDiagnostics.logInfo(
      'Discord RPC refresh requested from UI',
      data: <String, Object?>{
        'applicationId': savedSnapshot.config.clientId,
        'runtimeState': savedSnapshot.runtimeState.name,
      },
    );

    setState(() {
      _connectingDiscordRpc = true;
    });

    try {
      final snapshot = await DiscordRpcService.instance.connectIfPossible();
      if (!mounted) {
        return;
      }
      setState(() {
        _discordRpcSnapshot = snapshot;
      });
      _showSnack(AppStrings.t(_discordRpcStatusKey(snapshot.runtimeState)));
    } catch (error) {
      _showSnack(_formatErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _connectingDiscordRpc = false;
        });
      }
    }
  }

  Future<void> _disconnectDiscordRpc() async {
    if (!mounted) {
      return;
    }

    await AppDiagnostics.logInfo(
      'Discord RPC disconnect requested from UI',
      data: <String, Object?>{
        'hasEndpoint': _discordRpcSnapshot?.connectedEndpoint != null,
      },
    );

    setState(() {
      _disconnectingDiscordRpc = true;
    });

    try {
      final snapshot = await DiscordRpcService.instance.disconnect(
        clearSession: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _discordRpcSnapshot = snapshot;
      });
      _showSnack(context.tr.settings_discord_rpc_disconnected);
    } catch (error) {
      _showSnack(_formatErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _disconnectingDiscordRpc = false;
        });
      }
    }
  }

  String _discordRpcStatusKey(DiscordRpcRuntimeState state) {
    switch (state) {
      case DiscordRpcRuntimeState.disabled:
        return 'settings_discord_rpc_disabled';
      case DiscordRpcRuntimeState.unsupportedPlatform:
        return 'settings_discord_rpc_platform_unsupported';
      case DiscordRpcRuntimeState.transportUnsupported:
        return 'settings_discord_rpc_transport_unsupported';
      case DiscordRpcRuntimeState.notConfigured:
        return 'settings_discord_rpc_not_configured';
      case DiscordRpcRuntimeState.disconnected:
        return 'settings_discord_rpc_disconnected';
      case DiscordRpcRuntimeState.needsAuthorization:
        return 'settings_discord_rpc_needs_authorization';
      case DiscordRpcRuntimeState.authorizationCodePendingExchange:
        return 'settings_discord_rpc_authorization_code_pending_exchange';
      case DiscordRpcRuntimeState.connecting:
        return 'settings_discord_rpc_connecting';
      case DiscordRpcRuntimeState.authorizing:
        return 'settings_discord_rpc_authorizing';
      case DiscordRpcRuntimeState.exchangingCode:
        return 'settings_discord_rpc_exchanging_code';
      case DiscordRpcRuntimeState.authenticating:
        return 'settings_discord_rpc_authenticating';
      case DiscordRpcRuntimeState.connected:
        return 'settings_discord_rpc_connected';
      case DiscordRpcRuntimeState.error:
        return 'settings_discord_rpc_error';
    }
  }

  Color? _discordRpcStatusColor(DiscordRpcRuntimeState state) {
    switch (state) {
      case DiscordRpcRuntimeState.connected:
        return AppTheme.successLight;
      case DiscordRpcRuntimeState.error:
        return AppTheme.errorLight;
      case DiscordRpcRuntimeState.transportUnsupported:
      case DiscordRpcRuntimeState.unsupportedPlatform:
      case DiscordRpcRuntimeState.notConfigured:
      case DiscordRpcRuntimeState.needsAuthorization:
      case DiscordRpcRuntimeState.authorizationCodePendingExchange:
        return AppTheme.warning;
      case DiscordRpcRuntimeState.connecting:
      case DiscordRpcRuntimeState.authorizing:
      case DiscordRpcRuntimeState.exchangingCode:
      case DiscordRpcRuntimeState.authenticating:
        return Theme.of(context).colorScheme.primary;
      case DiscordRpcRuntimeState.disabled:
      case DiscordRpcRuntimeState.disconnected:
        return null;
    }
  }

  String _discordRpcPrimaryActionLabelKey() {
    return 'settings_discord_rpc_connect';
  }

  Widget _buildDiscordRpcCard({required bool isMobile}) {
    final snapshot = _discordRpcSnapshot;
    final runtimeState =
        snapshot?.runtimeState ?? DiscordRpcRuntimeState.disabled;
    final statusColor = _discordRpcStatusColor(runtimeState);
    final isBusy =
        _loadingDiscordRpc ||
        _savingDiscordRpc ||
        _connectingDiscordRpc ||
        _disconnectingDiscordRpc;
    final canDisconnect = snapshot?.connectedEndpoint != null;
    final primaryActionLabelKey = _discordRpcPrimaryActionLabelKey();
    final primaryActionDisabled = isBusy || !_discordRpcEnabled;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: _discordSectionExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _discordSectionExpanded = expanded;
          });
        },
        leading: const Icon(Icons.chat_bubble_outline, size: 18),
        title: Text(
          context.tr.settings_discord_rpc_title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle:
            snapshot == null
                ? null
                : Text(
                  AppStrings.t(_discordRpcStatusKey(runtimeState)),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: statusColor),
                ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr.settings_discord_rpc_desc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingDiscordRpc) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr.settings_discord_rpc_enable),
            value: _discordRpcEnabled,
            onChanged:
                isBusy
                    ? null
                    : (value) {
                      setState(() {
                        _discordRpcEnabled = value;
                      });
                    },
          ),
          if (snapshot?.connectedEndpoint != null) ...[
            const SizedBox(height: 12),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr.settings_discord_rpc_endpoint(
                  snapshot!.connectedEndpoint!,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          if (snapshot?.lastError?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr.settings_discord_rpc_last_error(
                  snapshot!.lastError!,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.errorLight),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isMobile) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : _saveDiscordRpcSettings,
                icon:
                    _savingDiscordRpc
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined, size: 18),
                label: Text(context.tr.settings_discord_rpc_save),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: primaryActionDisabled ? null : _connectDiscordRpc,
                icon:
                    _connectingDiscordRpc
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.link, size: 18),
                label: Text(AppStrings.t(primaryActionLabelKey)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    isBusy || !canDisconnect ? null : _disconnectDiscordRpc,
                icon:
                    _disconnectingDiscordRpc
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.link_off, size: 18),
                label: Text(context.tr.settings_discord_rpc_disconnect),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : _saveDiscordRpcSettings,
                    icon:
                        _savingDiscordRpc
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.save_outlined, size: 18),
                    label: Text(context.tr.settings_discord_rpc_save),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        primaryActionDisabled ? null : _connectDiscordRpc,
                    icon:
                        _connectingDiscordRpc
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.link, size: 18),
                    label: Text(AppStrings.t(primaryActionLabelKey)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed:
                      isBusy || !canDisconnect ? null : _disconnectDiscordRpc,
                  icon:
                      _disconnectingDiscordRpc
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.link_off, size: 18),
                  label: Text(context.tr.settings_discord_rpc_disconnect),
                ),
              ],
            ),
          ],
        ],
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
      snapshot.fileCount.toString(),
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
        builder:
            (routeContext) => OnboardingPage(
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
              snapshot.fileCount.toString(),
              _formatBytes(snapshot.totalBytes),
            ),
          ),
          Text(
            context.tr.settings_snapshot_apps_count(
              snapshot.appCount.toString(),
            ),
          ),
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
                  icon: const Icon(Icons.restore),
                  label: Text(context.tr.settings_restore_snapshot),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    final confirmed =
                        await AppTheme.showConfirmDialog(
                          context,
                          title: context.tr.settings_snapshot_delete_loading,
                          content: context.tr
                              .settings_snapshots_delete_one_confirm(
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
                final confirmed =
                    await AppTheme.showConfirmDialog(
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
              icon: const Icon(Icons.restore),
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
    final confirmed =
        await AppTheme.showConfirmDialog(
          context,
          title: context.tr.settings_snapshots_delete_all_title,
          content: context.tr.settings_snapshots_delete_all_confirm(
            count.toString(),
          ),
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
            context.tr.settings_snapshots_delete_all_done(
              snapshots.length.toString(),
            ),
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
                      trailing: const Icon(Icons.delete_outline),
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

    final confirmed =
        await AppTheme.showConfirmDialog(
          context,
          title: context.tr.settings_snapshot_delete_loading,
          content: context.tr.settings_snapshots_delete_one_confirm(
            selected.label,
          ),
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
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    final iconSize = isMobile ? 60.0 : 80.0;
    final titleSize = isMobile ? 24.0 : 28.0;

    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final detectedLocale = AppStrings.detectSystemLocale(
      Localizations.maybeLocaleOf(context),
    );
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.settings_tab),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip:
                isDark
                    ? context.tr.settings_theme_switch_light
                    : context.tr.settings_theme_switch_dark,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.settings,
                    size: iconSize,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
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

                  // ── Support Discord card ────────────────────────────────────
                  _SupportDiscordCard(),
                  const SizedBox(height: 16),
                  _PremiumCard(),
                  const SizedBox(height: 16),
                  _PrivacyPolicyCard(
                    checkingAdPrivacy: _checkingAdPrivacy,
                    adPrivacyRequired: _adPrivacyRequired,
                    onOpenAdPrivacy:
                        _checkingAdPrivacy
                            ? null
                            : (_adPrivacyRequired
                                ? _openAdPrivacyOptions
                                : null),
                  ),
                  const SizedBox(height: 16),
                  const _BdfdCompatibilityCard(),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.settings_appearance_title,
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
                                  value:
                                      locale == AppLocale.fr
                                          ? AppLocalePreference.fr
                                          : AppLocalePreference.en,
                                  child: _dropdownLabel(locale.label),
                                ),
                              ),
                            ],
                            selectedItemBuilder:
                                (context) =>
                                    AppLocalePreference.values
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
                                onPressed:
                                    _isBusy
                                        ? null
                                        : () => _resetLocalPreferences(),
                                icon: const Icon(Icons.restart_alt),
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
                                onPressed:
                                    _isBusy ? null : () => _replayOnboarding(),
                                icon: const Icon(Icons.rocket_launch_outlined),
                                label: Text(
                                  context.tr.settings_replay_onboarding,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              secondary: const Icon(
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
                                  PremiumCapabilities.debugPremiumBypass =
                                      value;
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
                              'Ads Mediation Debug',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Open Ad Inspector and log adapter status (Unity/Google) to validate mediation.',
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
                                  icon: const Icon(Icons.analytics_outlined),
                                  label: Text(
                                    context.tr.settings_run_diagnostics,
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: _openAdInspector,
                                  icon: const Icon(Icons.bug_report_outlined),
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
                              onPressed:
                                  _isBusy
                                      ? null
                                      : () async {
                                        await _runWithLoading(
                                          context
                                              .tr
                                              .settings_drive_connect_loading,
                                          () async {
                                            try {
                                              await _ensureDriveApiConnected();
                                              await _refreshSnapshots();
                                              await _runAutoBackupCheck(
                                                force: false,
                                                showSnack: false,
                                              );
                                              _showSnack(
                                                context
                                                    .tr
                                                    .settings_drive_connected,
                                              );
                                            } catch (e, st) {
                                              debugPrint(
                                                'Connect to Google Drive failed: $e',
                                              );
                                              debugPrintStack(stackTrace: st);
                                              _showSnack(
                                                _formatErrorMessage(e),
                                              );
                                            }
                                          },
                                        );
                                      },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.g_mobiledata),
                                  const SizedBox(width: 8),
                                  Text(context.tr.settings_drive_connect),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.successLight,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr.settings_drive_status_connected,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.successLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isBusy
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
                                  const Icon(Icons.logout),
                                  const SizedBox(width: 8),
                                  Text(context.tr.settings_drive_disconnect),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Developer Mode Section
                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: _developerSectionExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _developerSectionExpanded = expanded;
                        });
                      },
                      leading: const Icon(Icons.developer_mode, size: 18),
                      title: Text(
                        context.tr.settings_runner_title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          _runnerTemporarilyDisabled
                              ? Text(
                                context.tr.settings_runner_temporarily_disabled,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.warning),
                              )
                              : _runnerStatusKey == null
                              ? null
                              : Text(
                                AppStrings.t(_runnerStatusKey!),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
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
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(context.tr.settings_runner_disable_temp),
                          subtitle: Text(
                            context.tr.settings_runner_disable_temp_desc,
                          ),
                          value: _runnerTemporarilyDisabled,
                          onChanged:
                              _isBusy ? null : _toggleRunnerTemporarilyDisabled,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _runnerUrlController,
                          decoration: InputDecoration(
                            hintText: context.tr.settings_runner_url_hint,
                            isDense: true,
                            border: const OutlineInputBorder(),
                            suffixIcon:
                                (_runnerTemporarilyDisabled || _checkingRunner)
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
                                        : Icon(
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
                                  _runnerTokenObscured = !_runnerTokenObscured;
                                });
                              },
                              icon: Icon(
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
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: Text(context.tr.settings_runner_save),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _checkingRunner || _runnerTemporarilyDisabled
                                      ? null
                                      : _checkRunnerConnection,
                              icon:
                                  _checkingRunner
                                      ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.wifi_find, size: 18),
                              label: Text(context.tr.settings_runner_check),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isBusy
                                      ? null
                                      : () {
                                        _runnerUrlController.clear();
                                        _runnerApiTokenController.clear();
                                        _saveRunnerSettings();
                                      },
                              icon: const Icon(Icons.clear, size: 18),
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
                                  icon: const Icon(
                                    Icons.save_outlined,
                                    size: 18,
                                  ),
                                  label: Text(context.tr.settings_runner_save),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed:
                                    _checkingRunner ||
                                            _runnerTemporarilyDisabled
                                        ? null
                                        : _checkRunnerConnection,
                                icon:
                                    _checkingRunner
                                        ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.wifi_find, size: 18),
                                label: Text(context.tr.settings_runner_check),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed:
                                    _isBusy
                                        ? null
                                        : () {
                                          _runnerUrlController.clear();
                                          _runnerApiTokenController.clear();
                                          _saveRunnerSettings();
                                        },
                                icon: const Icon(Icons.clear, size: 18),
                                tooltip: context.tr.settings_runner_clear,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isDesktopPlatform) ...[
                    _buildDiscordRpcCard(isMobile: isMobile),
                    const SizedBox(height: 16),
                  ],
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
                            onPressed:
                                _isBusy
                                    ? null
                                    : () async {
                                      await _runWithLoading(
                                        context.tr.settings_export_loading,
                                        () async {
                                          try {
                                            await _ensureDriveApiConnected();
                                            final message = await uploadAppData(
                                              driveApi!,
                                              appManager,
                                            );
                                            await _refreshSnapshots();
                                            _showSnack(message);
                                          } catch (e, st) {
                                            debugPrint(
                                              'Export App Data failed: $e',
                                            );
                                            debugPrintStack(stackTrace: st);
                                            _showSnack(_formatErrorMessage(e));
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
                            onPressed:
                                _isBusy
                                    ? null
                                    : () async {
                                      await _runWithLoading(
                                        context.tr.settings_import_loading,
                                        () async {
                                          try {
                                            await _ensureDriveApiConnected();
                                            final message =
                                                await downloadAppData(
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
                                            _showSnack(_formatErrorMessage(e));
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
                          onPressed:
                              _isBusy
                                  ? null
                                  : () async {
                                    await _runWithLoading(
                                      context.tr.settings_export_loading,
                                      () async {
                                        try {
                                          await _ensureDriveApiConnected();
                                          final message = await uploadAppData(
                                            driveApi!,
                                            appManager,
                                          );
                                          await _refreshSnapshots();
                                          _showSnack(message);
                                        } catch (e, st) {
                                          debugPrint(
                                            'Export App Data failed: $e',
                                          );
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
                          onPressed:
                              _isBusy
                                  ? null
                                  : () async {
                                    await _runWithLoading(
                                      context.tr.settings_import_loading,
                                      () async {
                                        try {
                                          await _ensureDriveApiConnected();
                                          final message = await downloadAppData(
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
                            onChanged:
                                _loadingRecoverySettings
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
                              labelText:
                                  context.tr.settings_auto_backup_interval,
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
                                onPressed:
                                    _isBusy
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
                                                      label:
                                                          context
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
                                                _showSnack(
                                                  _formatErrorMessage(e),
                                                );
                                              }
                                            },
                                          );
                                        },
                                icon: const Icon(Icons.backup),
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
                                icon: const Icon(Icons.schedule_send),
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
                                tooltip:
                                    context
                                        .tr
                                        .settings_snapshots_delete_select_tooltip,
                                onPressed:
                                    _isBusy ||
                                            _loadingSnapshots ||
                                            _snapshots.isEmpty
                                        ? null
                                        : _showSnapshotQuickDeletePicker,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              IconButton(
                                tooltip:
                                    context.tr.settings_snapshots_delete_all,
                                onPressed:
                                    _isBusy ||
                                            _loadingSnapshots ||
                                            _snapshots.isEmpty
                                        ? null
                                        : _deleteAllSnapshots,
                                icon: const Icon(Icons.delete_sweep_outlined),
                              ),
                              IconButton(
                                tooltip: context.tr.settings_snapshots_refresh,
                                onPressed:
                                    _isBusy || _loadingSnapshots
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
                                icon: const Icon(Icons.refresh),
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
                                subtitle: Text(
                                  _snapshotListEntryLabel(snapshot),
                                ),
                                trailing: const Icon(Icons.chevron_right),
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
                            onPressed:
                                _isBusy
                                    ? null
                                    : () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder:
                                              (_) =>
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
                            onPressed:
                                _isBusy
                                    ? null
                                    : () async {
                                      await AppDiagnostics.clearLog();
                                      if (!mounted) {
                                        return;
                                      }
                                      _showSnack(
                                        context.tr.settings_logs_cleared,
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
                          icon: Icons.bug_report_outlined,
                          label: context.tr.settings_view_startup_logs,
                          onPressed:
                              _isBusy
                                  ? null
                                  : () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => const DiagnosticsLogsPage(),
                                      ),
                                    );
                                  },
                        ),
                        const SizedBox(height: 12),
                        _buildDataButton(
                          context,
                          icon: Icons.delete_outline,
                          label: context.tr.settings_clear_logs,
                          onPressed:
                              _isBusy
                                  ? null
                                  : () async {
                                    await AppDiagnostics.clearLog();
                                    if (!mounted) {
                                      return;
                                    }
                                    _showSnack(
                                      context.tr.settings_logs_cleared,
                                    );
                                  },
                        ),
                      ],
                    ),
                ],
              ),
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
      icon: Icon(icon),
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

class _PrivacyPolicyCard extends StatelessWidget {
  const _PrivacyPolicyCard({
    required this.checkingAdPrivacy,
    required this.adPrivacyRequired,
    required this.onOpenAdPrivacy,
  });

  final bool checkingAdPrivacy;
  final bool adPrivacyRequired;
  final VoidCallback? onOpenAdPrivacy;

  static const _privacyPolicyUrl = 'https://bot-creator.fr/privacy-policy.html';

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(_privacyPolicyUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(context.tr.app_open_link_error)),
        );
      }
    } catch (_) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(context.tr.app_open_link_error)));
    }
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
                icon: const Icon(Icons.privacy_tip_outlined),
                label: Text(context.tr.settings_privacy_policy),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenAdPrivacy,
                icon:
                    checkingAdPrivacy
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.shield_outlined),
                label: Text(
                  checkingAdPrivacy
                      ? context.tr.settings_ads_privacy_loading
                      : (adPrivacyRequired
                          ? context.tr.settings_ads_privacy_manage
                          : context.tr.settings_ads_privacy_not_required),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CapabilityStatus { supported, partial, missing }

class _CapabilitySnapshot {
  const _CapabilitySnapshot({
    required this.titleKey,
    required this.descriptionKey,
    required this.status,
  });

  final String titleKey;
  final String descriptionKey;
  final _CapabilityStatus status;
}

class _BdfdCompatibilityCard extends StatelessWidget {
  const _BdfdCompatibilityCard();

  static const List<_CapabilitySnapshot> _snapshots = [
    _CapabilitySnapshot(
      titleKey: 'settings_compatibility_item_workflows_title',
      descriptionKey: 'settings_compatibility_item_workflows_desc',
      status: _CapabilityStatus.supported,
    ),
    _CapabilitySnapshot(
      titleKey: 'settings_compatibility_item_variables_title',
      descriptionKey: 'settings_compatibility_item_variables_desc',
      status: _CapabilityStatus.supported,
    ),
    _CapabilitySnapshot(
      titleKey: 'settings_compatibility_item_events_title',
      descriptionKey: 'settings_compatibility_item_events_desc',
      status: _CapabilityStatus.partial,
    ),
    _CapabilitySnapshot(
      titleKey: 'settings_compatibility_item_runner_title',
      descriptionKey: 'settings_compatibility_item_runner_desc',
      status: _CapabilityStatus.partial,
    ),
    _CapabilitySnapshot(
      titleKey: 'settings_compatibility_item_bdscript_title',
      descriptionKey: 'settings_compatibility_item_bdscript_desc',
      status: _CapabilityStatus.supported,
    ),
  ];

  String _statusLabel(_CapabilityStatus status, BuildContext context) {
    switch (status) {
      case _CapabilityStatus.supported:
        return context.tr.settings_compatibility_status_supported;
      case _CapabilityStatus.partial:
        return context.tr.settings_compatibility_status_partial;
      case _CapabilityStatus.missing:
        return context.tr.settings_compatibility_status_missing;
    }
  }

  Color _statusColor(_CapabilityStatus status, BuildContext context) {
    switch (status) {
      case _CapabilityStatus.supported:
        return AppTheme.success;
      case _CapabilityStatus.partial:
        return AppTheme.warning;
      case _CapabilityStatus.missing:
        return Theme.of(context).colorScheme.error;
    }
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
              context.tr.settings_compatibility_title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr.settings_compatibility_desc,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ..._snapshots.map((snapshot) {
              final color = _statusColor(snapshot.status, context);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.t(snapshot.titleKey),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.t(snapshot.descriptionKey),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _statusLabel(snapshot.status, context),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            Text(
              context.tr.settings_compatibility_note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BdfdCompatibleFunctionsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt_outlined),
                label: Text(context.tr.settings_compatibility_open_functions),
              ),
            ),
          ],
        ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_discordColor, AppTheme.discordLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      context.tr.support_discord_badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr.support_card_title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
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
                  icon: const Icon(Icons.open_in_new, size: 16),
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

// ── Premium Subscription Card ──────────────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context) {
    if (!SubscriptionService.supportsNativeBilling) {
      return const SizedBox.shrink();
    }

    final isActive = SubscriptionService.isSubscribed;

    if (isActive) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.premiumGold,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.premium_active_title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr.premium_active_desc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.premiumGold, AppTheme.warning],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr.premium_card_title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.premium_card_desc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => SubscriptionPage.show(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.premiumGold,
                  ),
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: Text(context.tr.premium_card_button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_logs.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_stats.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/debug_replay_page.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_owner_sync.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/ads/logic/ad_consent_service.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:nyxx/nyxx.dart';
import 'dart:developer' as developer;

part 'home.logic.part.dart';
part 'home.sync.part.dart';
part 'home.ads.part.dart';
part 'home.ui.part.dart';

/// Describes a secondary section accessible via quick-actions on mobile.
class QuickAccessSection {
  final int index;
  final IconData icon;
  final String labelKey;

  const QuickAccessSection({
    required this.index,
    required this.icon,
    required this.labelKey,
  });
}

class AppHomePage extends StatefulWidget {
  final NyxxRest client;
  final ValueChanged<int>? onNavigateToSection;
  final List<QuickAccessSection> secondarySections;
  const AppHomePage({
    super.key,
    required this.client,
    this.onNavigateToSection,
    this.secondarySections = const [],
  });

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage>
    with TickerProviderStateMixin {
  String _appName = "";
  NyxxRest? client;
  String avatar = "";
  bool _botLaunched = false;
  bool _botStarting = false;
  int? _freeMinutesBalance;
  bool _isAddingTime = false;
  bool _isSyncingApp = false;
  void _setState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  int _extractFreeMinutes(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  bool _hasFreeRuntimeAvailable(Map<String, dynamic> runtime, int balance) {
    final fundingMode =
        (runtime['funding_mode'] ?? runtime['fundingMode'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    final sessionActiveRaw =
        runtime['session_active'] ?? runtime['sessionActive'];
    final sessionActive =
        sessionActiveRaw == true ||
        sessionActiveRaw?.toString().toLowerCase() == 'true';
    return balance > 0 || fundingMode == 'free' || sessionActive;
  }

  void Function(Object)? _taskDataCallback;

  @override
  void initState() {
    super.initState();
    if (_supportsForegroundTask) {
      _taskDataCallback = (Object data) {
        consumeForegroundTaskDataForBotLogs(data);
        if (mounted) {
          final currentBotId = widget.client.user.id.toString();
          var launched = _botLaunched;
          var starting = _botStarting;

          if (data is Map) {
            final map = Map<String, dynamic>.from(
              data.cast<dynamic, dynamic>(),
            );
            if (map['type'] == 'bot_lifecycle' &&
                map['botId']?.toString() == currentBotId) {
              launched = isMobileBotRunning(currentBotId);
              starting = false;
            }
          }

          setState(() {
            _botLaunched = launched;
            _botStarting = starting;
          });
        }
      };
      try {
        FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);
      } on MissingPluginException {
        debugPrint('Foreground callback registration unavailable on platform');
      } on PlatformException catch (error) {
        if (_isDeadChannelError(error)) {
          debugPrint('Foreground callback channel unavailable; skipping.');
        } else {
          rethrow;
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initService();
    });
    _init();
  }

  @override
  void dispose() {
    final callback = _taskDataCallback;
    if (callback != null) {
      try {
        FlutterForegroundTask.removeTaskDataCallback(callback);
      } on MissingPluginException {
        debugPrint('Foreground callback removal unavailable on platform');
      } on PlatformException catch (error) {
        if (_isDeadChannelError(error)) {
          debugPrint('Foreground callback channel unavailable; skipping.');
        } else {
          rethrow;
        }
      }
    }
    super.dispose();
  }

  Future<List<ApplicationCommand>> getCommands() async {
    if (client == null) {
      throw Exception("Client is not initialized");
    }
    final commands = await client!.commands.list();
    return commands;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        ),
        title: Text(
          _appName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentMaxWidth = constraints.maxWidth >= 900 ? 560.0 : 460.0;
          final showQuickAccess = constraints.maxWidth < 900;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingLg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: AppTheme.spacingLg),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.brandGradient,
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: colorScheme.surface,
                            child:
                                avatar.isNotEmpty
                                    ? ClipOval(
                                      child: Image.network(
                                        avatar,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.smart_toy,
                                                  size: 40,
                                                ),
                                      ),
                                    )
                                    : const Icon(Icons.smart_toy, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        _appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (Platform.isIOS) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                            border: Border.all(
                              color: AppTheme.warning.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.info_outline,
                                  color: AppTheme.warning,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr.bot_home_ios_notice_title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.tr.bot_home_ios_notice_content,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingXl),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              _botLaunched
                                  ? AppTheme.error
                                  : _botStarting
                                  ? AppTheme.warning
                                  : AppTheme.success,
                          minimumSize: const Size.fromHeight(48),
                          shape: AppTheme.buttonShape,
                        ),
                        onPressed:
                            _botStarting
                                ? null
                                : () async {
                                  try {
                                    final app = await appManager.getApp(
                                      widget.client.user.id.toString(),
                                    );
                                    final token = app["token"]?.toString();
                                    if (token == null || token.trim().isEmpty) {
                                      throw Exception("Token not found");
                                    }

                                    final botId =
                                        widget.client.user.id.toString();

                                    var remoteRuntime =
                                        await _resolveRemoteRuntime(
                                          getTimeout: const Duration(
                                            seconds: 30,
                                          ),
                                          postTimeout: const Duration(
                                            seconds: 90,
                                          ),
                                        );

                                    if (!_botLaunched &&
                                        remoteRuntime.blocksLocalFallback) {
                                      final sessionRestored =
                                          await _restoreMainApiSessionWithBotToken(
                                            botId: botId,
                                            botToken: token,
                                          );

                                      if (sessionRestored) {
                                        remoteRuntime =
                                            await _resolveRemoteRuntime(
                                              getTimeout: const Duration(
                                                seconds: 30,
                                              ),
                                              postTimeout: const Duration(
                                                seconds: 90,
                                              ),
                                            );
                                      }

                                      if (remoteRuntime.blocksLocalFallback) {
                                        final message =
                                            remoteRuntime.unavailableReason ??
                                            _uiCopy(
                                              fr:
                                                  'Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                                              en:
                                                  'Sign in to Bot Creator in Settings before starting this bot.',
                                            );

                                        throw Exception(message);
                                      }
                                    }

                                    if (!_botLaunched) {
                                      if (remoteRuntime.client == null) {
                                        try {
                                          await getDiscordUser(token);
                                        } catch (_) {
                                          if (!mounted) return;
                                          final proceed =
                                              await AppTheme.showConfirmDialog(
                                                context,
                                                title:
                                                    context
                                                        .tr
                                                        .bot_home_token_invalid_title,
                                                content:
                                                    context
                                                        .tr
                                                        .bot_home_token_invalid_content,
                                                confirmLabel:
                                                    context.tr.bot_home_start,
                                              );
                                          if (!proceed || !mounted) return;
                                        }
                                      }
                                      if (SubscriptionService.isSubscribed) {
                                        await SubscriptionService.syncStatusWithBackend(
                                          force: true,
                                        );
                                      }

                                      final adUnlocked =
                                          await _maybeOfferRewardedAd(
                                            botId: botId,
                                            botToken: token,
                                          );
                                      if (!adUnlocked) {
                                        return;
                                      }
                                    }

                                    final remoteClient = remoteRuntime.client;

                                    if (remoteClient != null) {
                                      try {
                                        if (_botLaunched) {
                                          appendBotLog(
                                            'Bot stop requested',
                                            botId: botId,
                                            source: remoteRuntime.source,
                                          );
                                          await remoteClient.stopBot(botId);
                                          endBotLogSession(
                                            botId: botId,
                                            source: remoteRuntime.source,
                                          );
                                          setBotRuntimeActive(false);
                                          if (mounted) {
                                            setState(
                                              () => _botLaunched = false,
                                            );
                                          }
                                        } else {
                                          startBotLogSession(
                                            botId: botId,
                                            source: remoteRuntime.source,
                                          );
                                          clearBotBaselineRss();
                                          appendBotLog(
                                            'Bot start requested',
                                            botId: botId,
                                            source: remoteRuntime.source,
                                          );
                                          final payload = await buildBotPayload(
                                            botId,
                                          );
                                          if (remoteClient is MainApiClient) {
                                            final botToken = token.trim();
                                            if (botToken.isNotEmpty) {
                                              try {
                                                await remoteClient
                                                    .saveDiscordBotSnapshot(
                                                      botToken: botToken,
                                                      config: payload,
                                                    );
                                              } catch (_) {}
                                            }
                                          }
                                          await remoteClient.syncBot(
                                            botId,
                                            _appName,
                                            payload,
                                          );
                                          if (remoteClient is MainApiClient) {
                                            await startManagerBotWithCreditRetry(
                                              client: remoteClient,
                                              botId: botId,
                                              botName: _appName,
                                            );
                                            RunnerSettings.associateBotWithRunner(
                                              botId,
                                              'manager',
                                            );
                                          } else {
                                            await remoteClient.startBot(
                                              botId,
                                              botName: _appName,
                                            );
                                            final runnerConfig =
                                                await RunnerSettings.getConfig();
                                            if (runnerConfig != null) {
                                              RunnerSettings.associateBotWithRunner(
                                                botId,
                                                runnerConfig.id,
                                              );
                                            }
                                          }
                                          setBotRuntimeActive(true);
                                          if (mounted) {
                                            setState(() => _botLaunched = true);
                                          }
                                        }
                                      } catch (error) {
                                        if (remoteClient is MainApiClient) {
                                          throw Exception(
                                            await describeManagerRuntimeFailure(
                                              remoteClient,
                                              error,
                                            ),
                                          );
                                        }
                                        rethrow;
                                      }
                                      return;
                                    }

                                    if (!_botLaunched) {
                                      clearBotBaselineRss();
                                      startBotLogSession(botId: botId);
                                      appendBotLog(
                                        'Bot start requested',
                                        botId: botId,
                                      );
                                    }

                                    if (_supportsForegroundTask) {
                                      if (_botLaunched) {
                                        appendBotLog(
                                          'Bot stop requested',
                                          botId: botId,
                                        );
                                        await stopMobileBotSession(
                                          botId: botId,
                                        );
                                        endBotLogSession(botId: botId);
                                        setBotRuntimeActive(
                                          isDesktopBotRunning ||
                                              mobileRunningBotIds.isNotEmpty,
                                        );
                                        if (mounted) {
                                          setState(() {
                                            _botLaunched = false;
                                            _botStarting = false;
                                          });
                                        }
                                        return;
                                      }

                                      final permissionGranted =
                                          await _requestPermissions();
                                      if (!permissionGranted) {
                                        throw Exception(
                                          context.tr.bot_home_notif_required,
                                        );
                                      }
                                      await _initService();

                                      await startMobileBotSession(
                                        botId: botId,
                                        token: token,
                                      );
                                      developer.log(
                                        'Token saved, starting foreground service',
                                        name: 'AppHomePage',
                                      );

                                      final running =
                                          await FlutterForegroundTask
                                              .isRunningService;
                                      if (!running) {
                                        throw Exception(
                                          context
                                              .tr
                                              .bot_home_service_not_started,
                                        );
                                      }

                                      if (mounted) {
                                        setState(() {
                                          _botLaunched = false;
                                          _botStarting = true;
                                        });
                                      }
                                    } else {
                                      if (_botLaunched) {
                                        appendBotLog(
                                          context.tr.bot_home_log_desktop_stop,
                                          botId: botId,
                                        );
                                        await stopDesktopBot(botId: botId);
                                        endBotLogSession(botId: botId);
                                        setBotRuntimeActive(
                                          isDesktopBotRunning ||
                                              mobileRunningBotIds.isNotEmpty,
                                        );
                                        clearBotBaselineRss();
                                        if (mounted) {
                                          setState(() {
                                            _botLaunched = false;
                                            _botStarting = false;
                                          });
                                        }
                                        return;
                                      }

                                      await startDesktopBot(token);
                                    }

                                    if (mounted) {
                                      setState(() {
                                        _botLaunched = !_supportsForegroundTask;
                                        _botStarting = false;
                                      });
                                    }
                                  } on PlatformException catch (error) {
                                    if (!mounted) return;
                                    setState(() {
                                      _botStarting = false;
                                    });
                                    final deadChannel = _isDeadChannelError(
                                      error,
                                    );
                                    final display =
                                        deadChannel
                                            ? 'Foreground service channel unavailable. Please reopen the app and try again.'
                                            : error.toString();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.tr.bot_home_start_error(
                                            display,
                                          ),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() {
                                      _botStarting = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.tr.bot_home_start_error(
                                            e.toString(),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_botStarting)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(
                                _botLaunched ? Icons.stop : Icons.play_arrow,
                                color: Colors.white,
                              ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Text(
                              _botStarting
                                  ? context.tr.bot_home_starting
                                  : _botLaunched
                                  ? context.tr.bot_home_stop
                                  : context.tr.bot_home_start,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_supportsForegroundTask) ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.tr.home_hosting_time_left(
                                    formatDuration(_freeMinutesBalance ?? 0),
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _hostingTimeColor(
                                      _freeMinutesBalance ?? 0,
                                    ).withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed:
                                    _isAddingTime ? null : _addRuntimeTime,
                                icon:
                                    _isAddingTime
                                        ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.add_circle_outline),
                                label: Text(context.tr.home_add_time),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacingXl),
                      if (widget.onNavigateToSection != null)
                        _buildSection(
                          icon: Icons.rocket_launch_outlined,
                          title: context.tr.bot_home_section_getting_started,
                          children: [
                            _buildActionTile(
                              icon: Icons.tune,
                              label: context.tr.bot_home_customize,
                              onTap: () => widget.onNavigateToSection!(8),
                              iconColor: AppTheme.brandPrimary,
                            ),
                            _buildActionTile(
                              icon: Icons.add_circle_outline,
                              label: context.tr.bot_home_create_command,
                              onTap: () => widget.onNavigateToSection!(1),
                              iconColor: AppTheme.success,
                            ),
                          ],
                        ),
                      const SizedBox(height: AppTheme.spacingMd),
                      if (showQuickAccess &&
                          widget.secondarySections.isNotEmpty &&
                          widget.onNavigateToSection != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 10,
                                ),
                                child: Text(
                                  context.tr.quick_access_title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              GridView.count(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.12,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  for (
                                    var i = 0;
                                    i <
                                        widget.secondarySections.length.clamp(
                                          0,
                                          3,
                                        );
                                    i++
                                  )
                                    _QuickAccessChip(
                                      icon: widget.secondarySections[i].icon,
                                      label: _resolveQuickAccessLabel(
                                        context,
                                        widget.secondarySections[i].labelKey,
                                      ),
                                      onTap:
                                          () => widget.onNavigateToSection!(
                                            widget.secondarySections[i].index,
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                      ],
                      _buildSection(
                        icon: Icons.monitor_heart_outlined,
                        title: context.tr.bot_home_section_monitoring,
                        children: [
                          _buildActionTile(
                            icon: Icons.receipt_long,
                            label: context.tr.bot_home_view_logs,
                            onTap: () {
                              final botId = widget.client.user.id.toString();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BotLogsPage(botId: botId),
                                ),
                              );
                            },
                          ),
                          _buildActionTile(
                            icon: Icons.bar_chart,
                            label: context.tr.bot_home_view_stats,
                            onTap: () {
                              final botId = widget.client.user.id.toString();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BotStatsPage(botId: botId),
                                ),
                              );
                            },
                          ),
                          if (PremiumCapabilities.isCapabilityRolledOut(
                            PremiumCapability.visualDebuggerReplay,
                          ))
                            _buildActionTile(
                              icon: Icons.play_circle_outline,
                              label: context.tr.bot_home_view_replay,
                              onTap: () {
                                final botId = widget.client.user.id.toString();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => DebugReplayPage(botId: botId),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildSection(
                        icon: Icons.build_outlined,
                        title: context.tr.bot_home_section_tools,
                        children: [
                          _buildActionTile(
                            icon: Icons.sync,
                            label: context.tr.bot_home_sync,
                            onTap:
                                _isSyncingApp
                                    ? null
                                    : () async {
                                      await _syncAppFromRemote(showSnack: true);
                                      unawaited(
                                        refreshBotRuntime(
                                          widget.client.user.id.toString(),
                                        ),
                                      );
                                    },
                            trailing:
                                _isSyncingApp
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : null,
                          ),
                          _buildActionTile(
                            icon: Icons.person_add,
                            label: context.tr.bot_home_invite,
                            iconColor: AppTheme.info,
                            onTap: () async {
                              final botId = widget.client.user.id.toString();
                              final inviteUrl = Uri.parse(
                                'https://discord.com/api/oauth2/authorize?client_id=$botId&scope=bot&permissions=8',
                              );

                              if (await openExternalUrl(inviteUrl)) {
                                await AppAnalytics.logEvent(
                                  name: "invite_bot",
                                  parameters: {"bot_id": botId},
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr.bot_home_invite_error,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildSection(
                        icon: Icons.warning_amber_rounded,
                        title: context.tr.bot_home_section_danger,
                        children: [
                          _buildActionTile(
                            icon: Icons.delete_outline,
                            label: context.tr.bot_home_delete,
                            iconColor: AppTheme.error,
                            textColor: AppTheme.error,
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppTheme.error,
                            ),
                            onTap: () async {
                              final confirmed =
                                  await AppTheme.showConfirmDialog(
                                    context,
                                    title: context.tr.bot_home_delete,
                                    content: context.tr.bot_home_delete_confirm,
                                    confirmLabel: context.tr.common_delete,
                                    icon: Icons.delete_forever,
                                  );
                              if (!confirmed || !mounted) return;
                              await appManager.deleteApp(
                                widget.client.user.id.toString(),
                              );
                              if (mounted) Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXxl),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickAccessChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

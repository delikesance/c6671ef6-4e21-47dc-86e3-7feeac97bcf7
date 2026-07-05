import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_logs.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_stats.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/debug_replay_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_config_versions_page.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/utils/responsive.dart';
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
  const AppHomePage({
    super.key,
    required this.client,
    this.onNavigateToSection,
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
  bool _isPushingApp = false;
  bool _isPullingApp = false;
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
        automaticallyImplyLeading: false,
        leading: !ResponsiveHelper.isDesktopPlatform()
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.openParentDrawer(),
              )
            : null,
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
                                : _toggleBotLaunchState,
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
                      if (_supportsForegroundTask &&
                          !SubscriptionService.isSubscribed) ...[
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
                                    _isAddingTime ? null : () => _addRuntimeTime(),
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
                              onTap: () => widget.onNavigateToSection!(9),
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
                          if (ResponsiveHelper.isDesktopPlatform())
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
                            icon: Icons.cloud_download,
                            label: context.tr.bot_home_pull,
                            iconColor: AppTheme.info,
                            onTap:
                                _isPullingApp
                                    ? null
                                    : () async {
                                      await _pullFromRemote(showSnack: true);
                                      unawaited(
                                        refreshBotRuntime(
                                          widget.client.user.id.toString(),
                                        ),
                                      );
                                    },
                            trailing:
                                _isPullingApp
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
                            icon: Icons.cloud_upload,
                            label: context.tr.bot_home_push,
                            iconColor: AppTheme.success,
                            onTap:
                                _isPushingApp
                                    ? null
                                    : () async {
                                      await _pushToRemote(showSnack: true);
                                      unawaited(
                                        refreshBotRuntime(
                                          widget.client.user.id.toString(),
                                        ),
                                      );
                                    },
                            trailing:
                                _isPushingApp
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
                            icon: Icons.history,
                            label: context.tr.bot_home_version_history,
                            iconColor: AppTheme.grey,
                            onTap: () async {
                              final botId = widget.client.user.id.toString();
                              final app = await appManager.getApp(botId);
                              final token = (app['token'] ?? '').toString().trim();
                              if (token.isEmpty) return;

                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BotConfigVersionsPage(
                                    botId: botId,
                                    botToken: token,
                                    resolveClient: (id, tok) => _resolveMainApiClientForBot(
                                      botId: id,
                                      botToken: tok,
                                      attemptSessionRestore: true,
                                    ),
                                  ),
                                ),
                              );
                            },
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
                              await appManager.deleteBotCompletely(
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


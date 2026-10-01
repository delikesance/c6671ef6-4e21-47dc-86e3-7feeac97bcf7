import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_status.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_templates.dart';
import 'package:bot_creator/features/containers/presentation/container_deploy_page.dart';
import 'package:bot_creator/features/containers/presentation/container_detail_page.dart';
import 'package:bot_creator/features/containers/presentation/hosted_app_upsell_widgets.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/hosted_app_subscription_page.dart';
import 'package:flutter/material.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

class ContainerListPage extends StatefulWidget {
  const ContainerListPage({super.key});

  @override
  State<ContainerListPage> createState() => _ContainerListPageState();
}

class _ContainerListPageState extends State<ContainerListPage> {
  MainApiClient? _client;
  List<ContainerInfo>? _containers;
  HostedAppEligibility? _eligibility;
  bool _loading = true;
  bool _initError = false;
  String? _error;

  bool get _atFreeContainerLimit {
    final elig = _eligibility;
    if (elig == null || elig.premium) return false;
    return elig.activeContainers >= elig.maxContainers;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (session == null || session.isExpired || !config.isConfigured) {
        if (mounted) {
          setState(() {
            _initError = true;
            _loading = false;
          });
        }
        return;
      }
      _client = MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = true;
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _load() async {
    if (_client == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _client!.listContainers(),
        _client!.getHostedAppEligibility(),
      ]);
      if (mounted) {
        setState(() {
          _containers = results[0] as List<ContainerInfo>;
          _eligibility = results[1] as HostedAppEligibility;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openDeploy() async {
    if (_atFreeContainerLimit) {
      if (SubscriptionService.supportsNativeBilling &&
          _eligibility?.premium != true) {
        await HostedAppSubscriptionPage.show(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.container_list_free_limit_reached)),
        );
      }
      return;
    }
    // Deploying now pushReplaces into ContainerDetailPage on success, so the
    // return value here is unreliable — always refresh to be safe.
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ContainerDeployPage(client: _client)),
    );
    _load();
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'RUNNING':
        return Colors.green;
      case 'PENDING':
      case 'PROVISIONING':
        return Colors.orange;
      case 'STOPPED':
      case 'STOPPING':
        return Colors.grey;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _stateLabel(String state, AppLocalizations tr) {
    switch (state) {
      case 'RUNNING':
        return tr.container_state_running;
      case 'PENDING':
        return tr.container_state_pending;
      case 'PROVISIONING':
        return tr.container_state_provisioning;
      case 'STOPPED':
        return tr.container_state_stopped;
      case 'STOPPING':
        return tr.container_state_stopping;
      case 'FAILED':
        return tr.container_state_failed;
      default:
        return state;
    }
  }

  String _formatMemory(ContainerInfo c) {
    if (c.memoryUsageBytes > 0) {
      final usedMb = (c.memoryUsageBytes / (1024 * 1024)).ceil();
      return '$usedMb / ${c.memoryMb} MB';
    }
    return '${c.memoryMb} MB';
  }

  String? _formatTimeRemaining(ContainerInfo c) {
    if (c.expiresAt.millisecondsSinceEpoch == 0) return null;
    final remaining = c.expiresAt.toUtc().difference(DateTime.now().toUtc());
    if (remaining.isNegative) return 'Expired';
    final totalMinutes = remaining.inMinutes;
    if (totalMinutes < 1) return '<1m left';
    if (totalMinutes < 60) return '${totalMinutes}m left';
    final hours = totalMinutes ~/ 60;
    if (hours < 24) return '${hours}h left';
    return '${hours ~/ 24}d left';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = context.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.container_list_title),
        actions: [
          IconButton(
            icon: const AppIcon.fromMaterial(Icons.refresh),
            onPressed: _load,
          ),
          if (_atFreeContainerLimit &&
              SubscriptionService.supportsNativeBilling &&
              _eligibility?.premium != true)
            IconButton(
              icon: const AppIcon.fromMaterial(
                Icons.storage_rounded,
                color: Colors.teal,
              ),
              tooltip: tr.container_list_premium_host_anytime_tooltip,
              onPressed: () => HostedAppSubscriptionPage.show(context),
            )
          else
            IconButton(
              icon: const AppIcon.fromMaterial(Icons.add),
              onPressed: _openDeploy,
            ),
        ],
      ),
      body: _buildBody(colorScheme),
      floatingActionButton:
          _atFreeContainerLimit &&
              SubscriptionService.supportsNativeBilling &&
              _eligibility?.premium != true
          ? FloatingActionButton.extended(
              onPressed: () => HostedAppSubscriptionPage.show(context),
              icon: const AppIcon.fromMaterial(Icons.storage_rounded),
              label: Text(tr.container_list_premium_host_anytime_fab),
            )
          : null,
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    final tr = context.tr;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_initError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.cloud_off,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              tr.container_list_session_missing,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr.container_list_session_hint,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.cloud_off,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              tr.container_list_error,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _load,
              icon: const AppIcon.fromMaterial(Icons.refresh),
              label: Text(tr.container_list_retry),
            ),
          ],
        ),
      );
    }

    if (_containers == null || _containers!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.fromMaterial(
                Icons.smart_toy_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                tr.container_list_empty,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                tr.container_list_empty_hint,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _openDeploy,
                icon: const AppIcon.fromMaterial(Icons.rocket_launch_rounded),
                label: Text(tr.container_list_deploy_btn),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _containers!.length + (_atFreeContainerLimit ? 1 : 0),
        itemBuilder: (context, index) {
          if (_atFreeContainerLimit && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HostedAppPremiumUpsell(eligibility: _eligibility),
            );
          }
          final c = _containers![index - (_atFreeContainerLimit ? 1 : 0)];
          final template = templateForImage(c.image);
          final title =
              (template?.id == HostedAppTemplateId.easyMusic ||
                  c.image.toLowerCase().contains('beatdock'))
              ? tr.container_deploy_template_easy_music
              : (template?.title ?? c.image);
          final icon =
              template?.icon ??
              (c.image.toLowerCase().contains('beatdock')
                  ? Icons.music_note_rounded
                  : Icons.smart_toy_outlined);
          final isLegacyCustom =
              template == null && !c.image.toLowerCase().contains('beatdock');

          return Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ContainerDetailPage(containerId: c.id, client: _client),
                  ),
                );
                _load();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppIcon.fromMaterial(
                        icon,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLegacyCustom) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tr.container_list_unsupported_badge,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isHostedAppUnhealthy(
                            healthStatus: c.healthStatus,
                            statusCode: c.statusCode,
                          )) ...[
                            const SizedBox(height: 2),
                            Text(
                              describeHostedAppStatus(
                                healthStatus: c.healthStatus,
                                statusCode: c.statusCode,
                                statusMessage: c.statusMessage,
                                state: c.state,
                                tr: tr,
                              ),
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatMemory(c),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          if (_formatTimeRemaining(c) case final timeLeft?) ...[
                            const SizedBox(height: 2),
                            Text(
                              timeLeft,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _stateColor(c.state).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusPill,
                            ),
                          ),
                          child: Text(
                            _stateLabel(c.state, tr),
                            style: TextStyle(
                              color: _stateColor(c.state),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

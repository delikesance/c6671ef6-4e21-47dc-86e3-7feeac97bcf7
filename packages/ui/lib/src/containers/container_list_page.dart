import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import 'container_deploy_page.dart';
import 'container_detail_page.dart';
import 'container_presentation.dart';
import 'hosted_app_status.dart';
import 'hosted_app_templates.dart';
import 'hosted_app_upsell_widgets.dart';
import 'hosted_containers_host.dart';
import 'hosted_models.dart';
import 'registry_credentials_page.dart';

/// Liste des applications hébergées (« conteneurs clé en main ») du compte :
/// l'écran de l'app, tel quel, derrière un [HostedContainersHost].
class ContainerListPage extends StatefulWidget {
  const ContainerListPage({super.key, required this.host});

  final HostedContainersHost host;

  @override
  State<ContainerListPage> createState() => _ContainerListPageState();
}

class _ContainerListPageState extends State<ContainerListPage> {
  HostedContainersHost get _host => widget.host;
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

  /// Faut-il proposer l'achat de la formule d'hébergement (limite gratuite
  /// atteinte, achat natif disponible, pas d'abonnement) ?
  bool get _offersPremiumHost =>
      _atFreeContainerLimit &&
      _host.upsellMode == HostedUpsellMode.purchase &&
      _eligibility?.premium != true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (!await _host.hasSession()) {
        if (mounted) {
          setState(() {
            _initError = true;
            _loading = false;
          });
        }
        return;
      }
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _host.listContainers(),
        _host.eligibility(),
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
      if (_offersPremiumHost) {
        _host.openSubscription(context);
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
      MaterialPageRoute(builder: (_) => ContainerDeployPage(host: _host)),
    );
    _load();
  }

  String _formatMemory(ContainerInfo c) {
    if (c.memoryUsageBytes > 0) {
      final usedMb = (c.memoryUsageBytes / (1024 * 1024)).ceil();
      return '$usedMb / ${c.memoryMb} MB';
    }
    return '${c.memoryMb} MB';
  }

  String? _timeLeft(ContainerInfo c, AppLocalizations tr) {
    if (c.expiresAt.millisecondsSinceEpoch == 0) return null;
    return containerExpiryLabel(c.expiresAt, tr);
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
          if (_host.showsRegistryCredentials)
            IconButton(
              icon: const AppIcon.fromMaterial(Icons.vpn_key_outlined),
              tooltip: tr.registry_credentials_title,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RegistryCredentialsPage(host: _host),
                ),
              ),
            ),
          if (_offersPremiumHost)
            IconButton(
              icon: const AppIcon.fromMaterial(
                Icons.storage_rounded,
                color: Colors.teal,
              ),
              tooltip: tr.container_list_premium_host_anytime_tooltip,
              onPressed: () => _host.openSubscription(context),
            )
          else
            IconButton(
              icon: const AppIcon.fromMaterial(Icons.add),
              onPressed: _openDeploy,
            ),
        ],
      ),
      body: _buildBody(colorScheme),
      floatingActionButton: _offersPremiumHost
          ? FloatingActionButton.extended(
              onPressed: () => _host.openSubscription(context),
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
              child: HostedAppPremiumUpsell(
                host: _host,
                eligibility: _eligibility,
              ),
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
                        ContainerDetailPage(containerId: c.id, host: _host),
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
                          if (_timeLeft(c, tr) case final timeLeft?) ...[
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
                            color: containerStateColor(
                              c.state,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusPill,
                            ),
                          ),
                          child: Text(
                            containerStateLabel(c.state, tr),
                            style: TextStyle(
                              color: containerStateColor(c.state),
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

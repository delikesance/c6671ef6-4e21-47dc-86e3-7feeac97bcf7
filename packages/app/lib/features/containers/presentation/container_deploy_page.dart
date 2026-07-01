import 'dart:async';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_hosting_actions.dart';
import 'package:bot_creator/features/containers/presentation/hosted_app_upsell_widgets.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:flutter/material.dart';

class ContainerDeployPage extends StatefulWidget {
  final MainApiClient? client;

  const ContainerDeployPage({super.key, this.client});

  @override
  State<ContainerDeployPage> createState() => _ContainerDeployPageState();
}

class _ContainerDeployPageState extends State<ContainerDeployPage> {
  final _formKey = GlobalKey<FormState>();
  final _imageCtrl = TextEditingController(text: 'nginx:alpine');
  final _envKeyCtrl = TextEditingController();
  final _envValCtrl = TextEditingController();

  final List<MapEntry<String, String>> _envVars = [];
  bool _deploying = false;
  bool _claimingAd = false;
  bool _loadingEligibility = true;
  MainApiClient? _client;
  HostedAppEligibility? _eligibility;
  String? _ownerId;

  @override
  void initState() {
    super.initState();
    unawaited(_initClient());
  }

  Future<void> _initClient() async {
    if (widget.client != null) {
      _client = widget.client;
      _ownerId = await HostedAppHostingActions.resolveOwnerId();
    } else {
      try {
        final config = await MainApiSettingsStore.loadConfig();
        final session = await MainApiSettingsStore.loadSession();
        if (session != null && !session.isExpired && config.isConfigured) {
          _client = MainApiClient(
            baseUrl: config.baseUrl,
            accessToken: session.accessToken,
          );
          _ownerId = session.userId;
        }
      } catch (_) {}
    }
    await _refreshEligibility();
  }

  Future<void> _refreshEligibility() async {
    if (_client == null) {
      if (mounted) setState(() => _loadingEligibility = false);
      return;
    }
    setState(() => _loadingEligibility = true);
    try {
      final elig = await _client!.getHostedAppEligibility();
      if (mounted) {
        setState(() {
          _eligibility = elig;
          _loadingEligibility = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _eligibility = null;
          _loadingEligibility = false;
        });
      }
    }
  }

  bool get _canDeploy => _eligibility?.canDeploy ?? PremiumCapabilities.isPremiumUser;

  @override
  void dispose() {
    _imageCtrl.dispose();
    _envKeyCtrl.dispose();
    _envValCtrl.dispose();
    super.dispose();
  }

  void _addEnvVar() {
    final key = _envKeyCtrl.text.trim();
    final val = _envValCtrl.text.trim();
    if (key.isEmpty) return;
    setState(() => _envVars.add(MapEntry(key, val)));
    _envKeyCtrl.clear();
    _envValCtrl.clear();
  }

  Future<void> _watchAdForHostingMinutes() async {
    if (_client == null || _claimingAd) return;

    setState(() => _claimingAd = true);
    try {
      final result = await HostedAppHostingActions.watchAdAndClaim(
        client: _client!,
        ownerId: _ownerId,
        placement: 'hosted_app_deploy',
      );
      await _refreshEligibility();

      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.container_deploy_ad_unlock_success(
                result.grantedMinutes,
                result.hostingMinutesBalance,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.container_deploy_ad_unlock_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claimingAd = false);
    }
  }

  Future<void> _deploy() async {
    if (!_formKey.currentState!.validate()) return;
    if (_client == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.container_deploy_not_auth),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (!_canDeploy) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.container_deploy_requires_premium_or_ad),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _deploying = true);
    try {
      final image = _imageCtrl.text.trim();
      final env = {for (final e in _envVars) e.key: e.value};

      final result = await _client!.deployContainer(
        image: image,
        cpuMillis: 250,
        memoryMb: 192,
        storageGb: 1,
        env: env,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.container_deploy_success(result['container_id']),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.container_deploy_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deploying = false);
    }
  }

  Widget _buildEligibilityBanner() {
    if (_loadingEligibility) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      );
    }

    final elig = _eligibility;
    if (elig == null) {
      return const SizedBox.shrink();
    }

    if (elig.premium) {
      return Card(
        color: Colors.amber.withValues(alpha: 0.08),
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const Icon(Icons.workspace_premium, color: Colors.amber),
          title: Text(
            context.tr.container_deploy_premium_account,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            context.tr.container_deploy_premium_containers(
              elig.maxContainers,
              elig.activeContainers,
            ),
          ),
        ),
      );
    }

    final atLimit = elig.activeContainers >= elig.maxContainers;
    if (atLimit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HostedAppPremiumUpsell(),
          HostedAppFreeHostingBanner(
            eligibility: elig,
            claimingAd: false,
            onWatchAd: null,
          ),
        ],
      );
    }

    return HostedAppFreeHostingBanner(
      eligibility: elig,
      claimingAd: _claimingAd,
      onWatchAd: _watchAdForHostingMinutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.container_deploy_title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildEligibilityBanner(),
            Text(
              context.tr.container_deploy_image_label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageCtrl,
              decoration: InputDecoration(
                hintText: 'nginx:alpine',
                helperText: context.tr.container_deploy_image_hint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.tr.container_deploy_image_required
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              context.tr.container_deploy_env_label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._envVars.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${e.key}=${e.value}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => setState(() => _envVars.remove(e)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _envKeyCtrl,
                    decoration: InputDecoration(
                      hintText: context.tr.container_deploy_env_key_hint,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _envValCtrl,
                    decoration: InputDecoration(
                      hintText: context.tr.container_deploy_env_value_hint,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addEnvVar,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Colors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '0.25 CPU · 192 MB RAM',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr.container_deploy_ephemeral_storage,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: (_deploying || !_canDeploy) ? null : _deploy,
              icon: _deploying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.rocket_launch),
              label: Text(
                _deploying
                    ? context.tr.container_deploy_submitting
                    : context.tr.container_deploy_submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

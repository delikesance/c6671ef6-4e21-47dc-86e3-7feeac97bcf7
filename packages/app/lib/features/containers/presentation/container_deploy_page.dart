import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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

  String _copy({required String fr, required String en}) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'fr' ? fr : en;
  }

  Future<void> _watchAdForHostingMinutes() async {
    if (_client == null || _claimingAd) return;

    if (!Platform.isAndroid && !Platform.isIOS && !kIsWeb) {
      return;
    }
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _copy(
                fr: 'Les publicités récompensées ne sont pas disponibles sur le web.',
                en: 'Rewarded ads are not available on web.',
              ),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _claimingAd = true);
    try {
      if (!AdRewardService.hasReadyRewardedAd) {
        final loaded = await AdRewardService.ensureAdLoaded(
          timeout: const Duration(seconds: 6),
        );
        if (!loaded) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _copy(
                    fr: 'Aucune publicité disponible pour le moment.',
                    en: 'No ad available right now.',
                  ),
                ),
              ),
            );
          }
          return;
        }
      }

      if (!await AdRewardService.shouldOfferRewardedAd(
        checkPremiumCapability: false,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _copy(
                  fr: 'Cooldown publicitaire actif. Réessayez dans quelques instants.',
                  en: 'Ad cooldown is active. Try again in a moment.',
                ),
              ),
            ),
          );
        }
        return;
      }

      var rewardEarned = false;
      final rewardId = const Uuid().v4();
      final adShown = await AdRewardService.showRewardedAd(
        ssvContext: AdRewardSsvContext(userId: _ownerId),
        onRewardEarned: () async {
          rewardEarned = true;
        },
      );
      if (!adShown || !rewardEarned) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _copy(
                  fr: 'Publicité non terminée — aucune minute créditée.',
                  en: 'Ad not completed — no minutes granted.',
                ),
              ),
            ),
          );
        }
        return;
      }

      final result = await _client!.claimHostedAppAd(
        placement: 'hosted_app_deploy',
        rewardId: rewardId,
        idempotencyKey: rewardId,
      );
      await _refreshEligibility();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _copy(
                fr: '+${result.grantedMinutes} min d\'hébergement (total : ${result.hostingMinutesBalance} min).',
                en: '+${result.grantedMinutes} hosting minutes (total: ${result.hostingMinutesBalance} min).',
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
            content: Text(
              _copy(
                fr: 'Échec du déblocage : $e',
                en: 'Unlock failed: $e',
              ),
            ),
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
            content: Text(
              _copy(
                fr: 'Abonnement Premium ou publicité requise pour déployer un conteneur.',
                en: 'Premium subscription or rewarded ad required to deploy a container.',
              ),
            ),
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
            _copy(fr: 'Compte Premium', en: 'Premium account'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            _copy(
              fr: 'Jusqu\'à ${elig.maxContainers} conteneurs actifs (${elig.activeContainers}/${elig.maxContainers}).',
              en: 'Up to ${elig.maxContainers} active containers (${elig.activeContainers}/${elig.maxContainers}).',
            ),
          ),
        ),
      );
    }

    final minutes = elig.hostingMinutesBalance;
    final reward = elig.adRewardMinutes;
    final atLimit = elig.activeContainers >= elig.maxContainers;
    final canDeployNow = minutes > 0 && !atLimit;

    return Card(
      color: Colors.teal.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _copy(
                      fr: 'Hébergement gratuit (1 conteneur max)',
                      en: 'Free hosting (1 container max)',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              atLimit
                  ? _copy(
                      fr: 'Conteneur actif — arrêtez-le pour en relancer un (${elig.activeContainers}/${elig.maxContainers}).',
                      en: 'Container active — stop it to deploy again (${elig.activeContainers}/${elig.maxContainers}).',
                    )
                  : minutes > 0
                  ? _copy(
                      fr: '$minutes min d\'hébergement disponibles (cumulables).',
                      en: '$minutes hosting minutes available (stackable).',
                    )
                  : _copy(
                      fr: 'Regardez une pub pour gagner $reward min d\'hébergement.',
                      en: 'Watch an ad to earn $reward hosting minutes.',
                    ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            if (!atLimit) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _claimingAd ? null : _watchAdForHostingMinutes,
                icon: _claimingAd
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(
                  _copy(
                    fr: 'Pub +$reward min',
                    en: 'Ad +$reward min',
                  ),
                ),
              ),
            ],
            if (!canDeployNow && !atLimit) ...[
              const SizedBox(height: 8),
              Text(
                _copy(
                  fr: 'Accumulez des minutes via les pubs, puis déployez.',
                  en: 'Stack minutes from ads, then deploy.',
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
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
                            _copy(
                              fr: 'Stockage éphémère (pas de volume persistant)',
                              en: 'Ephemeral storage (no persistent volume)',
                            ),
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

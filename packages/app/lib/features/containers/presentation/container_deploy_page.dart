import 'dart:async';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_hosting_actions.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_templates.dart';
import 'package:bot_creator/features/containers/presentation/hosted_app_upsell_widgets.dart';
import 'package:bot_creator/features/containers/presentation/registry_credentials_page.dart';
import 'package:flutter/material.dart';

const kDefaultHostedAppImage = kEasyMusicBotImage;

class ContainerDeployPage extends StatefulWidget {
  final MainApiClient? client;

  const ContainerDeployPage({super.key, this.client});

  @override
  State<ContainerDeployPage> createState() => _ContainerDeployPageState();
}

class _ContainerDeployPageState extends State<ContainerDeployPage> {
  final _formKey = GlobalKey<FormState>();
  final _imageCtrl = TextEditingController(text: kDefaultHostedAppImage);
  final _botTokenCtrl = TextEditingController();
  final _envKeyCtrl = TextEditingController();
  final _envValCtrl = TextEditingController();
  final _registryUserCtrl = TextEditingController();
  final _registryPassCtrl = TextEditingController();
  final _saveRegistryLabelCtrl = TextEditingController();

  final List<MapEntry<String, String>> _envVars = [];
  HostedAppTemplateId _templateId = HostedAppTemplateId.easyMusic;
  List<Map<String, dynamic>> _localBots = const [];
  String? _selectedBotId;
  bool _obscureBotToken = true;
  bool _deploying = false;
  bool _claimingAd = false;
  bool _loadingEligibility = true;
  bool _loadingCredentials = false;
  bool _privateImage = false;
  bool _useInlineCredentials = false;
  bool _saveRegistryAuth = false;
  bool _obscureRegistryPassword = true;
  MainApiClient? _client;
  HostedAppEligibility? _eligibility;
  String? _ownerId;
  List<RegistryCredential> _registryCredentials = const [];
  String? _selectedCredentialId;

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
    await _loadRegistryCredentials();
    await _loadLocalBots();
  }

  Future<void> _loadLocalBots() async {
    try {
      final apps = await AppManager().getAllApps();
      final bots = <Map<String, dynamic>>[];
      for (final raw in apps) {
        if (raw is! Map) continue;
        final app = Map<String, dynamic>.from(raw);
        final id = app['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final full = await AppManager().getApp(id);
        final token = full['token']?.toString() ?? '';
        if (token.isEmpty) continue;
        bots.add({
          'id': id,
          'name': app['name']?.toString() ?? id,
          'token': token,
        });
      }
      if (mounted) setState(() => _localBots = bots);
    } catch (_) {}
  }

  bool get _isEasyMusicTemplate =>
      _templateId == HostedAppTemplateId.easyMusic;

  void _applyTemplate(HostedAppTemplateId templateId) {
    final template = templateFor(templateId);
    setState(() {
      _templateId = templateId;
      _privateImage = template.requiresPrivateRegistry;
      if (template.image.isNotEmpty) {
        _imageCtrl.text = template.image;
      }
      if (templateId != HostedAppTemplateId.easyMusic) {
        _botTokenCtrl.clear();
        _selectedBotId = null;
      }
    });
  }

  Future<void> _fillTokenFromBot(String? botId) async {
    if (botId == null || botId.isEmpty) {
      setState(() {
        _selectedBotId = null;
        _botTokenCtrl.clear();
      });
      return;
    }
    final bot = _localBots.firstWhere(
      (b) => b['id'] == botId,
      orElse: () => const {},
    );
    final token = bot['token']?.toString() ?? '';
    setState(() {
      _selectedBotId = botId;
      _botTokenCtrl.text = token;
    });
  }

  Future<void> _loadRegistryCredentials() async {
    if (_client == null) return;
    setState(() => _loadingCredentials = true);
    try {
      final creds = await _client!.listRegistryCredentials();
      if (mounted) {
        setState(() {
          _registryCredentials = creds;
          _loadingCredentials = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCredentials = false);
    }
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

  bool get _canDeploy => _eligibility?.canDeploy ?? false;

  @override
  void dispose() {
    _imageCtrl.dispose();
    _botTokenCtrl.dispose();
    _envKeyCtrl.dispose();
    _envValCtrl.dispose();
    _registryUserCtrl.dispose();
    _registryPassCtrl.dispose();
    _saveRegistryLabelCtrl.dispose();
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

    if (_isEasyMusicTemplate) {
      final token = _botTokenCtrl.text.trim();
      if (token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.container_deploy_bot_token_required),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() => _deploying = true);
    try {
      final image = _imageCtrl.text.trim();
      final env = {for (final e in _envVars) e.key: e.value};
      if (_isEasyMusicTemplate) {
        env['TOKEN'] = _botTokenCtrl.text.trim();
      }

      String? registryCredentialId;
      RegistryAuthInput? registryAuth;
      var saveRegistryAuth = false;
      String? saveRegistryLabel;

      if (_privateImage) {
        if (_useInlineCredentials) {
          final username = _registryUserCtrl.text.trim();
          final password = _registryPassCtrl.text;
          if (username.isEmpty || password.isEmpty) {
            throw Exception(context.tr.container_deploy_registry_auth_required);
          }
          registryAuth = RegistryAuthInput(
            registry: detectRegistryHostFromImage(image),
            username: username,
            password: password,
          );
          saveRegistryAuth = _saveRegistryAuth;
          if (saveRegistryAuth) {
            saveRegistryLabel = _saveRegistryLabelCtrl.text.trim();
          }
        } else {
          if (_selectedCredentialId == null || _selectedCredentialId!.isEmpty) {
            throw Exception(context.tr.container_deploy_registry_profile_required);
          }
          registryCredentialId = _selectedCredentialId;
        }
      }

      final result = await _client!.deployContainer(
        image: image,
        cpuMillis: 250,
        memoryMb: 192,
        storageGb: 1,
        env: env,
        registryCredentialId: registryCredentialId,
        registryAuth: registryAuth,
        saveRegistryAuth: saveRegistryAuth,
        saveRegistryLabel: saveRegistryLabel,
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
          if (_eligibility != null && !_eligibility!.premium)
            HostedAppPremiumUpsell(eligibility: _eligibility),
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
            _buildEligibilityBanner(),
            Text(
              context.tr.container_deploy_template_label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<HostedAppTemplateId>(
              segments: [
                ButtonSegment(
                  value: HostedAppTemplateId.easyMusic,
                  label: Text(context.tr.container_deploy_template_easy_music),
                  icon: const Icon(Icons.music_note_outlined),
                ),
                ButtonSegment(
                  value: HostedAppTemplateId.custom,
                  label: Text(context.tr.container_deploy_template_custom),
                  icon: const Icon(Icons.tune_outlined),
                ),
              ],
              selected: {_templateId},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                _applyTemplate(selection.first);
              },
            ),
            if (_isEasyMusicTemplate) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr.container_deploy_easy_music_hint,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_localBots.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  initialValue: _selectedBotId,
                  decoration: InputDecoration(
                    labelText: context.tr.container_deploy_pick_bot,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(context.tr.container_deploy_pick_bot_manual),
                    ),
                    ..._localBots.map(
                      (bot) => DropdownMenuItem<String?>(
                        value: bot['id']?.toString(),
                        child: Text(bot['name']?.toString() ?? ''),
                      ),
                    ),
                  ],
                  onChanged: _fillTokenFromBot,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _botTokenCtrl,
                obscureText: _obscureBotToken,
                decoration: InputDecoration(
                  labelText: context.tr.app_bot_token,
                  helperText: context.tr.container_deploy_bot_token_hint,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureBotToken
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureBotToken = !_obscureBotToken,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text(
                context.tr.container_deploy_image_label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageCtrl,
                decoration: InputDecoration(
                  hintText: kDefaultHostedAppImage,
                  helperText: context.tr.container_deploy_image_hint,
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.tr.container_deploy_image_required
                    : null,
              ),
              const SizedBox(height: 8),
            ],
            if (!_isEasyMusicTemplate) ...[
              SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr.container_deploy_private_image),
              subtitle: Text(context.tr.container_deploy_private_image_hint),
              value: _privateImage,
              onChanged: (v) => setState(() => _privateImage = v),
            ),
            if (_privateImage) ...[
              if (_loadingCredentials)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr.container_deploy_use_custom_credentials),
                value: _useInlineCredentials,
                onChanged: (v) => setState(() => _useInlineCredentials = v),
              ),
              if (!_useInlineCredentials) ...[
                DropdownButtonFormField<String?>(
                  initialValue: _selectedCredentialId,
                  decoration: InputDecoration(
                    labelText: context.tr.container_deploy_registry_profile,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(context.tr.container_deploy_registry_profile_none),
                    ),
                    ..._registryCredentials.map(
                      (cred) => DropdownMenuItem<String?>(
                        value: cred.id,
                        child: Text('${cred.label} (${cred.registryHost})'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedCredentialId = v),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegistryCredentialsPage(client: _client),
                        ),
                      );
                      await _loadRegistryCredentials();
                    },
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: Text(context.tr.registry_credentials_manage),
                  ),
                ),
              ] else ...[
                Text(
                  context.tr.container_deploy_registry_detected(
                    detectRegistryHostFromImage(_imageCtrl.text),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _registryUserCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr.registry_credentials_username,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _registryPassCtrl,
                  obscureText: _obscureRegistryPassword,
                  decoration: InputDecoration(
                    labelText: context.tr.registry_credentials_password,
                    helperText: context.tr.registry_credentials_ghcr_hint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureRegistryPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _obscureRegistryPassword = !_obscureRegistryPassword,
                      ),
                    ),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr.container_deploy_save_registry_auth),
                  value: _saveRegistryAuth,
                  onChanged: (v) => setState(() => _saveRegistryAuth = v ?? false),
                ),
                if (_saveRegistryAuth)
                  TextFormField(
                    controller: _saveRegistryLabelCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr.registry_credentials_label,
                      hintText: detectRegistryHostFromImage(_imageCtrl.text),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
            ],
            ],
            if (!_isEasyMusicTemplate) ...[
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
            ],
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
    ),
    );
  }
}

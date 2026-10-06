import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/tr_extension.dart';
import '../widgets/app_icon.dart';
import 'container_detail_page.dart';
import 'hosted_app_templates.dart';
import 'hosted_app_upsell_widgets.dart';
import 'hosted_containers_host.dart';
import 'hosted_models.dart';
import 'turnkey_env_fields.dart';
import 'turnkey_env_payload.dart';

/// Reason the Deploy button is currently disabled, derived from the latest
/// [HostedAppEligibility] snapshot. Drives which banner/snackbar copy is shown.
enum _DeployBlockReason {
  /// Nothing is blocking — deploy is allowed.
  none,

  /// Eligibility is still loading.
  loading,

  /// The eligibility check failed to load.
  eligibilityError,

  /// The free/premium container limit has been reached.
  containerLimit,

  /// The account formula does not include turnkey apps at all.
  planLimit,

  /// No hosting minutes remain (free tier only).
  noMinutes,

  /// Le serveur a dit que l'hébergement cloud est coupé sur ce déploiement
  /// (`premium_cloud_enabled: false`). Le blocage vient de lui ; seule
  /// l'explication change, parce qu'aucune publicité ni aucune formule ne le
  /// débloquerait.
  serverCloudDisabled,
}

/// Déploiement d'une application hébergée : choix du modèle, token Discord,
/// variables du schéma, puis `POST /containers/deploy` — l'écran de l'app, tel
/// quel, derrière un [HostedContainersHost].
class ContainerDeployPage extends StatefulWidget {
  final HostedContainersHost host;

  const ContainerDeployPage({super.key, required this.host});

  @override
  State<ContainerDeployPage> createState() => _ContainerDeployPageState();
}

class _ContainerDeployPageState extends State<ContainerDeployPage> {
  final _formKey = GlobalKey<FormState>();
  final _botTokenCtrl = TextEditingController();

  /// Un contrôleur par variable À SAISIR du template sélectionné (le token
  /// Discord a le sien, au-dessus : [_botTokenCtrl]).
  final Map<String, TextEditingController> _envCtrls =
      <String, TextEditingController>{};

  HostedAppTemplate _selectedTemplate = easyMusicBotTemplate;
  List<HostedLocalBot> _localBots = const [];
  String? _selectedBotId;
  bool _obscureBotToken = true;
  bool _deploying = false;
  bool _claimingAd = false;
  bool _loadingEligibility = true;
  HostedAppEligibility? _eligibility;
  HostedContainersHost get _host => widget.host;

  @override
  void initState() {
    super.initState();
    _syncEnvControllers();
    unawaited(_initClient());
    // La langue de l'écran n'est lisible qu'après le premier build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshTemplates());
    });
  }

  @override
  void dispose() {
    _botTokenCtrl.dispose();
    for (final controller in _envCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Variables du template que l'utilisateur doit saisir (le token Discord est
  /// rendu à part, par son champ dédié).
  List<HostedAppEnvField> get _userEnvFields =>
      turnkeyUserEnvFields(_selectedTemplate);

  /// Clés du token Discord DÉCLARÉES par le template : c'est le champ token
  /// dédié qui les alimente, quel que soit le nom exact déclaré.
  List<String> get _tokenEnvKeys => turnkeyTokenEnvFields(
    _selectedTemplate,
  ).map((field) => field.key.trim()).toList(growable: false);

  /// (Re)construit les contrôleurs du formulaire d'environnement quand le modèle
  /// sélectionné change : chaque variable est pré-remplie avec la valeur par
  /// défaut déclarée, et les contrôleurs des variables disparues sont libérés.
  void _syncEnvControllers() {
    final fields = _userEnvFields;
    final wanted = <String>{for (final field in fields) field.key.trim()};
    for (final key in _envCtrls.keys.toList()) {
      if (!wanted.contains(key)) {
        _envCtrls.remove(key)?.dispose();
      }
    }
    for (final field in fields) {
      _envCtrls.putIfAbsent(
        field.key.trim(),
        () => TextEditingController(text: initialTurnkeyEnvValue(field)),
      );
    }
  }

  Future<void> _initClient() async {
    await _refreshEligibility();
    if (!mounted) return;
    await _loadLocalBots();
  }

  /// Le catalogue de modèles servi par le Manager, pour la langue de l'écran.
  /// L'app le tient déjà à jour en tâche de fond (l'hôte rend `null`).
  Future<void> _refreshTemplates() async {
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final raw = await _host.fetchTurnkeyTemplates(locale);
      if (raw == null || raw.isEmpty || !mounted) return;
      final templates = [
        for (final item in raw) HostedAppTemplate.fromJson(item),
      ];
      setCachedTurnkeyTemplates(templates);
      setState(() {
        final current = _selectedTemplate;
        _selectedTemplate = templates.firstWhere(
          (t) => t.image == current.image,
          orElse: () => templates.first,
        );
        _syncEnvControllers();
      });
    } catch (_) {}
  }

  Future<void> _loadLocalBots() async {
    try {
      final bots = await _host.localBots();
      if (mounted) setState(() => _localBots = bots);
    } catch (_) {}
  }

  Future<void> _fillTokenFromBot(String? botId) async {
    if (botId == null || botId.isEmpty) {
      setState(() {
        _selectedBotId = null;
        _botTokenCtrl.clear();
      });
      return;
    }
    final match = _localBots.where((b) => b.id == botId);
    final token = match.isEmpty ? '' : match.first.token;
    setState(() {
      _selectedBotId = botId;
      if (token.isNotEmpty) {
        _botTokenCtrl.text = token;
      }
    });
  }

  Future<void> _refreshEligibility() async {
    if (mounted) setState(() => _loadingEligibility = true);
    try {
      final elig = await _host.eligibility();
      if (mounted) {
        setState(() {
          _eligibility = elig;
          _loadingEligibility = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEligibility = false);
    }
  }

  Future<void> _watchAdForHostingMinutes() async {
    if (!_host.canWatchAds || _claimingAd) return;
    setState(() => _claimingAd = true);
    try {
      final result = await _host.watchAdAndClaim(
        placement: 'turnkey_bot_deploy',
      );
      if (result != null && mounted) {
        await _refreshEligibility();
        if (!mounted) return;
        final tr = context.tr;
        final elig = _eligibility;
        final isSlotFull =
            elig != null &&
            !elig.premium &&
            elig.activeContainers >= elig.maxContainers;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSlotFull
                  ? tr.container_deploy_ad_slot_full(result.grantedMinutes)
                  : tr.container_deploy_ad_unlock_success(
                      result.grantedMinutes,
                      result.hostingMinutesBalance,
                    ),
            ),
            backgroundColor: isSlotFull ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.container_deploy_ad_unlock_failed(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claimingAd = false);
    }
  }

  _DeployBlockReason get _blockReason {
    if (_loadingEligibility) return _DeployBlockReason.loading;
    final elig = _eligibility;
    if (elig == null) return _DeployBlockReason.eligibilityError;
    // La formule du compte est servie par le serveur (elle prime sur
    // l'abonnement store) : si elle n'inclut pas le clé en main, inutile
    // d'aller plus loin, le déploiement sera refusé.
    if (!elig.allowTurnkey) {
      return _explicationHonnete(_DeployBlockReason.planLimit);
    }
    // Le VERDICT DU SERVEUR prime : c'est lui qui applique le quota au démarrage.
    // Les heuristiques ci-dessous ne servent que de repli pour un serveur qui ne
    // renverrait pas ces champs.
    if (!elig.canDeploy) {
      if (elig.isBlockedByNoMinutes) {
        return _explicationHonnete(_DeployBlockReason.noMinutes);
      }
      if (elig.isBlockedByPlan) {
        return _explicationHonnete(_DeployBlockReason.planLimit);
      }
      return _DeployBlockReason.containerLimit;
    }
    // Le quota de conteneurs s'applique à TOUT LE MONDE, premium compris : une
    // formule d'hébergement en cours ne crée pas de place supplémentaire. Un bot
    // clé en main n'ayant aucune configuration à sauvegarder, on le refuse AVANT la
    // saisie du token plutôt que de laisser remplir un formulaire sans issue.
    // (0 = illimité, d'où le garde-fou sur la valeur du plafond.)
    if (elig.maxContainers > 0 && elig.activeContainers >= elig.maxContainers) {
      return _DeployBlockReason.containerLimit;
    }
    // En revanche, l'exigence de minutes ne concerne que l'hébergement ad-financé :
    // un compte couvert par une formule n'a pas de minutes à consommer.
    if (!elig.premium && elig.hostingMinutesBalance <= 0) {
      return _explicationHonnete(_DeployBlockReason.noMinutes);
    }
    return _DeployBlockReason.none;
  }

  /// Le blocage reste celui du SERVEUR — on n'invente aucune interdiction, c'est
  /// lui qui applique le quota. Seule l'EXPLICATION change quand l'hébergement
  /// cloud est coupé sur ce déploiement (`premium_cloud_enabled: false`) : dans ce
  /// cas, ni une publicité récompensée ni une formule premium ne débloqueraient
  /// quoi que ce soit, et envoyer l'utilisateur acheter ou regarder une pub serait
  /// une promesse fausse.
  _DeployBlockReason _explicationHonnete(_DeployBlockReason raison) {
    if (!_host.premiumCloudDisabled) return raison;
    switch (raison) {
      case _DeployBlockReason.noMinutes:
      case _DeployBlockReason.planLimit:
        return _DeployBlockReason.serverCloudDisabled;
      case _DeployBlockReason.none:
      case _DeployBlockReason.loading:
      case _DeployBlockReason.eligibilityError:
      case _DeployBlockReason.containerLimit:
      case _DeployBlockReason.serverCloudDisabled:
        return raison;
    }
  }

  bool get _canDeploy => _blockReason == _DeployBlockReason.none;

  Future<void> _deploy() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _botTokenCtrl.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.container_deploy_bot_token_required),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reason = _blockReason;
    if (reason != _DeployBlockReason.none) {
      final tr = context.tr;
      switch (reason) {
        case _DeployBlockReason.containerLimit:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.container_deploy_blocked_container_limit),
              backgroundColor: Colors.orange,
            ),
          );
        case _DeployBlockReason.planLimit:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.plan_limit_turnkey_desc),
              backgroundColor: Colors.orange,
              action: _host.upsellMode == HostedUpsellMode.none
                  ? null
                  : SnackBarAction(
                      label: tr.plan_limit_view_offers,
                      onPressed: () => _host.openPlans(context),
                    ),
            ),
          );
        case _DeployBlockReason.noMinutes:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.container_deploy_blocked_no_minutes),
              backgroundColor: Colors.orange,
            ),
          );
        case _DeployBlockReason.serverCloudDisabled:
          // Aucune action proposée : ni une publicité ni une formule ne rouvrent
          // un hébergement cloud coupé sur ce déploiement.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.container_deploy_blocked_cloud_disabled),
              backgroundColor: Colors.orange,
            ),
          );
        case _DeployBlockReason.eligibilityError:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.container_deploy_blocked_eligibility_error),
              backgroundColor: Colors.red,
            ),
          );
        case _DeployBlockReason.loading:
        case _DeployBlockReason.none:
          break;
      }
      return;
    }

    setState(() => _deploying = true);
    try {
      // Validation technique du token Discord : le serveur vérifie que le bot
      // existe et que ses droits sont suffisants. L'identité Discord renvoyée
      // n'est PLUS persistée — un bot clé en main est un CONTENEUR, pas un bot
      // local (voir la note après le déploiement).
      try {
        await _host.validateDiscordToken(token);
      } catch (tokenErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.container_deploy_token_invalid(tokenErr.toString()),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // L'env envoyé est celui du SCHÉMA du template : le token Discord alimente
      // les variables token déclarées, chaque autre variable prend la saisie de
      // l'utilisateur ou le défaut déclaré, et les variables imposées par le
      // serveur (fixed / source "node") ne partent jamais avec une valeur
      // inventée côté app.
      final env = buildTurnkeyEnvPayload(
        template: _selectedTemplate,
        botToken: token,
        userValues: <String, String>{
          for (final entry in _envCtrls.entries) entry.key: entry.value.text,
          for (final key in _tokenEnvKeys) key: token,
        },
      );

      final result = await _host.deployContainer(
        image: _selectedTemplate.image,
        cpuMillis: _selectedTemplate.cpuMillis,
        memoryMb: _selectedTemplate.memoryMb,
        storageGb: _selectedTemplate.storageGb,
        env: env,
      );

      final containerId = result['container_id']?.toString() ?? '';

      // AUCUN enregistrement local ici, délibérément. Un bot clé en main est un
      // CONTENEUR piloté par le serveur, sans configuration à éditer : l'accueil
      // le liste via `listContainers()` (carte `HomeTurnkeyContainerCard`).
      // L'ancien `AppManager().saveApp(...)` fabriquait un faux bot local sous
      // l'ID DISCORD du bot, avec une config vide/par défaut, le token Discord en
      // clair (alors qu'il vit déjà dans l'environnement du conteneur) et une
      // ligne de bot fantôme côté manager — avec le risque d'ÉCRASER un vrai bot
      // configuré portant le même ID Discord. Les entrées déjà créées chez les
      // utilisateurs sont nettoyées par `AppManager.purgeTurnkeyAppEntries()`.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.container_deploy_submitted_starting),
            backgroundColor: Colors.green,
          ),
        );
        if (containerId.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ContainerDetailPage(containerId: containerId, host: _host),
            ),
          );
        } else {
          Navigator.pop(context, true);
        }
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
    if (elig == null) return const SizedBox.shrink();

    if (elig.premium) {
      return Card(
        color: Colors.amber.withValues(alpha: 0.08),
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const AppIcon.fromMaterial(
            Icons.workspace_premium,
            color: Colors.amber,
          ),
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

    return HostedAppFreeHostingBanner(
      eligibility: elig,
      claimingAd: _claimingAd,
      canWatchAds: _host.canWatchAds,
      // Desktop : aucune publicité n'y existe (le temps vient du solde serveur,
      // ci-dessus). On ne câble donc même pas l'action — la bannière ne peut pas
      // proposer un parcours qui mènerait à `HostedAppHostingActions`.
      onWatchAd: _host.canWatchAds ? _watchAdForHostingMinutes : null,
    );
  }

  Widget _buildDeployBlockedNotice() {
    final tr = context.tr;
    final reason = _blockReason;

    switch (reason) {
      case _DeployBlockReason.none:
      case _DeployBlockReason.loading:
        return const SizedBox.shrink();
      case _DeployBlockReason.eligibilityError:
        return _DeployNoticeCard(
          icon: Icons.error_outline,
          color: Colors.red,
          message: tr.container_deploy_blocked_eligibility_error,
          actionLabel: tr.container_list_retry,
          onAction: _refreshEligibility,
        );
      case _DeployBlockReason.containerLimit:
        return _DeployNoticeCard(
          icon: Icons.block,
          color: Colors.orange,
          message: tr.container_deploy_blocked_container_limit,
          actionLabel: tr.container_list_title,
          onAction: () => Navigator.pop(context, false),
        );
      case _DeployBlockReason.planLimit:
        return _DeployNoticeCard(
          icon: Icons.lock_outline,
          color: Colors.orange,
          message: tr.plan_limit_turnkey_desc,
          actionLabel: _host.upsellMode == HostedUpsellMode.none
              ? null
              : tr.plan_limit_view_offers,
          onAction: _host.upsellMode == HostedUpsellMode.none
              ? null
              : () => _host.openPlans(context),
        );
      case _DeployBlockReason.noMinutes:
        if (!_host.canWatchAds) {
          // Desktop : pas de publicité, donc pas de porte de sortie par une pub.
          // On montre le SOLDE SERVEUR tel quel (c'est lui qui débloque le
          // déploiement) et on renvoie vers les formules.
          return _DeployNoticeCard(
            icon: Icons.hourglass_empty,
            color: Colors.orange,
            message: tr.container_hosted_minutes_available(
              _eligibility?.hostingMinutesBalance ?? 0,
            ),
            actionLabel: _host.upsellMode == HostedUpsellMode.none
                ? null
                : tr.plan_limit_view_offers,
            onAction: _host.upsellMode == HostedUpsellMode.none
                ? null
                : () => _host.openPlans(context),
          );
        }
        final reward = _eligibility?.adRewardMinutes ?? 0;
        return _DeployNoticeCard(
          icon: Icons.play_circle_outline,
          color: Colors.orange,
          message: tr.container_deploy_blocked_no_minutes,
          actionLabel: tr.container_hosted_ad_button(reward),
          onAction: _claimingAd ? null : _watchAdForHostingMinutes,
        );
      case _DeployBlockReason.serverCloudDisabled:
        // Aucune action, et surtout PAS une publicité : le message dit la vraie
        // porte de sortie (local ou runner perso) au lieu d'en promettre une
        // fausse (regarder une pub ou acheter une formule ne rouvrirait rien).
        return _DeployNoticeCard(
          icon: Icons.cloud_off_rounded,
          color: Colors.orange,
          message: tr.container_deploy_blocked_cloud_disabled,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.container_deploy_title)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildEligibilityBanner(),

              // Modèles de bots prêts à l'emploi
              Text(
                context.tr.container_deploy_template_section,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...kTurnkeyBotTemplates.map((template) {
                final isSelected = _selectedTemplate.id == template.id;
                return Card(
                  elevation: isSelected ? 2 : 0,
                  color: isSelected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedTemplate = template;
                        _syncEnvControllers();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AppIcon.fromMaterial(
                                  template.icon,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template.id ==
                                              HostedAppTemplateId.easyMusic
                                          ? context
                                                .tr
                                                .container_deploy_template_easy_music
                                          : template.title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      context
                                          .tr
                                          .container_deploy_managed_hosting,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                AppIcon.fromMaterial(
                                  Icons.check_circle_rounded,
                                  color: colorScheme.primary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            template.id == HostedAppTemplateId.easyMusic
                                ? context.tr.container_deploy_easy_music_hint
                                : template.description,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Configuration du Token Discord
              Text(
                context.tr.container_deploy_bot_config_section,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (_localBots.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  initialValue: _selectedBotId,
                  decoration: InputDecoration(
                    labelText: context.tr.container_deploy_pick_bot,
                    prefixIcon: const AppIcon.fromMaterial(
                      Icons.smart_toy_outlined,
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(context.tr.container_deploy_pick_bot_manual),
                    ),
                    ..._localBots.map(
                      (bot) => DropdownMenuItem<String?>(
                        value: bot.id,
                        child: Text(bot.name),
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
                  hintText: context.tr.container_deploy_paste_token_hint,
                  prefixIcon: const AppIcon.fromMaterial(Icons.key_outlined),
                  suffixIcon: IconButton(
                    icon: AppIcon.fromMaterial(
                      _obscureBotToken
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureBotToken = !_obscureBotToken),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.tr.container_deploy_bot_token_required;
                  }
                  return null;
                },
              ),

              // Un champ par variable DÉCLARÉE par le modèle sélectionné : rien
              // n'est supposé côté app, le schéma du template fait foi.
              if (_userEnvFields.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  context.tr.container_deploy_env_fields_section,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TurnkeyEnvFieldsSection(
                  template: _selectedTemplate,
                  controllers: _envCtrls,
                ),
              ],

              const SizedBox(height: 16),

              // Guide / Prérequis Discord
              Card(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppIcon.fromMaterial(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr.container_deploy_discord_prereqs,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._selectedTemplate.tips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
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

              const SizedBox(height: 24),
              _buildDeployBlockedNotice(),
              const SizedBox(height: 8),

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
                    : const AppIcon.fromMaterial(Icons.rocket_launch_rounded),
                label: Text(
                  _deploying
                      ? context.tr.container_deploy_submitting
                      : context.tr.container_deploy_launch_btn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small dismissable-looking notice card explaining why deploying is
/// currently blocked, with an optional single action.
class _DeployNoticeCard extends StatelessWidget {
  const _DeployNoticeCard({
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon.fromMaterial(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

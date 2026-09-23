import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';
import 'package:bot_creator/features/team/logic/team_models.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';

/// Onglet « Équipe et tchat » d'un bot : QUI travaille sur ce bot, et ce que
/// l'équipe se dit.
///
/// Trois blocs portent la même question :
///   * le tchat d'équipe, **persisté côté serveur** — un appareil qui rejoint
///     OUVRE la conversation, il ne la recommence pas ;
///   * les collaborateurs et leurs droits : c'est la SEULE liste de membres de
///     l'application (les réglages du bot n'en rendent plus une seconde, qui
///     aurait divergé) ;
///   * l'équipe officielle du portail développeur Discord, en **lecture seule** :
///     elle appartient à Discord, l'app ne fait que la montrer.
///
/// Le temps réel arrive par le canal d'événements du compte
/// ([GatewayBotEventsSession]) : un message ou un changement de droits apparaît
/// sans rechargement et sans sondage.
class TeamChatPage extends StatefulWidget {
  const TeamChatPage({
    super.key,
    required this.botId,
    this.client,
    this.portalLookup,
  });

  final String botId;

  /// Client injectable (tests) : par défaut la page résout le runtime commun
  /// ([resolveRemoteRuntime]), comme les autres onglets.
  final MainApiClient? client;

  /// Lecture de l'équipe du portail Discord, injectable (tests). Par défaut
  /// [getDiscordApplicationOwnerMetadata] — la seule source de vérité du
  /// portail, l'app ne réimplémente aucun appel Discord.
  final Future<DiscordApplicationOwnerMetadata?> Function(String botToken)?
  portalLookup;

  @override
  State<TeamChatPage> createState() => _TeamChatPageState();
}

class _TeamChatPageState extends State<TeamChatPage> {
  MainApiClient? _client;
  StreamSubscription<GatewayBotEvent>? _eventsSub;

  List<BotCollaborator> _collaborators = const <BotCollaborator>[];
  final List<TeamChatMessage> _messages = <TeamChatMessage>[];

  bool _loading = true;
  String? _error;
  bool _sending = false;

  /// Droits EFFECTIFS du lecteur sur CE bot, tels que le serveur les accorde
  /// (`my_permissions` de la route d'équipe, via [fetchMyTeamPermissions]).
  ///
  /// `null` = INCONNUS : le chargement n'a pas encore abouti, le serveur est
  /// plus ancien, ou l'appel a échoué. La page est alors FERMÉE — aucun
  /// contrôle de gestion n'est rendu —, jamais l'inverse : l'interface ne
  /// promet pas une action que le serveur refusera (`bot_permission_denied`).
  BotPermissions? _myPermissions;

  /// Le contrôle d'ajout/retrait de collaborateur est-il accordé au LECTEUR ?
  ///
  /// Le drapeau est `can_invite`, et lui seul : la route renvoie les droits
  /// EFFECTIFS, dont le propriétaire les a tous (règle serveur
  /// `EffectivePermissions`), donc « propriétaire » est couvert par ce même
  /// droit sans qu'il faille le deviner côté client. Le `is_owner` de la même
  /// réponse est rendu à CÔTÉ de `my_permissions`, que
  /// [MainApiClient.fetchMyTeamPermissions] ne remonte pas : le propriétaire y
  /// est reconnu par ses droits, pas par une seconde lecture.
  bool get _canManageTeam => _myPermissions?.canInvite == true;

  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Pseudonymes et avatars Discord résolus (portail, collaborateurs ou Discord API).
  final Map<String, String> _userDisplayNames = <String, String>{};
  final Map<String, String> _userAvatars = <String, String>{};
  final Set<String> _pendingUserLookups = <String>{};

  /// Équipe officielle du portail Discord de CE bot, mise en cache au niveau de
  /// la page : la vérification ne coûte donc jamais un appel réseau par frappe.
  /// `null` = inconnue (jeton absent, portail injoignable) : dans ce cas aucune
  /// mise en garde n'est affichée, une absence ne se suppose pas.
  Set<String>? _portalMemberIds;
  DiscordApplicationOwnerMetadata? _portalMetadata;
  Future<void>? _portalLookup;

  void _cachePortalUserMetadata(DiscordApplicationOwnerMetadata metadata) {
    if (metadata.ownerId.isNotEmpty && metadata.ownerUsername.isNotEmpty) {
      _userDisplayNames[metadata.ownerId] = metadata.ownerUsername;
    }
    if (metadata.ownerId.isNotEmpty && metadata.ownerAvatar.isNotEmpty) {
      _userAvatars[metadata.ownerId] = metadata.ownerAvatar;
    }
    if (metadata.teamOwnerUserId.isNotEmpty &&
        metadata.teamOwnerUsername.isNotEmpty) {
      _userDisplayNames[metadata.teamOwnerUserId] = metadata.teamOwnerUsername;
    }
    for (final member in metadata.teamMembersInfo) {
      final id = member['id']?.toString() ?? '';
      final username = member['username']?.toString() ?? '';
      final avatar = member['avatar']?.toString() ?? '';
      if (id.isNotEmpty && username.isNotEmpty) {
        _userDisplayNames[id] = username;
      }
      if (id.isNotEmpty && avatar.isNotEmpty) {
        _userAvatars[id] = avatar;
      }
    }
  }

  void _cacheCollaboratorUserMetadata(List<BotCollaborator> collaborators) {
    for (final c in collaborators) {
      if (c.displayName.isNotEmpty) {
        _userDisplayNames[c.userId] = c.displayName;
      }
    }
  }

  void _resolveDiscordUserIfNeeded(String userId) {
    if (userId.isEmpty ||
        _userDisplayNames.containsKey(userId) ||
        _pendingUserLookups.contains(userId)) {
      return;
    }
    _pendingUserLookups.add(userId);
    unawaited(_lookupDiscordUser(userId));
  }

  Future<void> _lookupDiscordUser(String userId) async {
    final token = await _botToken();
    if (token.isEmpty) return;
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://discord.com/api/v10/users/$userId'),
      );
      request.headers.set(HttpHeaders.authorizationHeader, 'Bot $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final payload = await utf8.decodeStream(response);
        final data = jsonDecode(payload);
        if (data is Map) {
          final username = (data['global_name'] ?? data['username'] ?? '')
              .toString()
              .trim();
          final avatar = (data['avatar'] ?? '').toString().trim();
          if (!mounted) return;
          if (username.isNotEmpty || avatar.isNotEmpty) {
            setState(() {
              if (username.isNotEmpty) _userDisplayNames[userId] = username;
              if (avatar.isNotEmpty) _userAvatars[userId] = avatar;
            });
          }
        }
      }
    } catch (_) {
      // Ignoré si réseau indisponible
    }
  }

  String _resolveAuthorName(TeamChatMessage message) {
    if (message.authorDisplayName.isNotEmpty &&
        message.authorDisplayName != message.authorUserId) {
      return message.authorDisplayName;
    }
    final cached = _userDisplayNames[message.authorUserId];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    _resolveDiscordUserIfNeeded(message.authorUserId);
    return message.authorUserId;
  }

  String? _resolveAuthorAvatarUrl(String userId) {
    final avatarId = _userAvatars[userId];
    if (avatarId != null && avatarId.isNotEmpty) {
      return makeAvatarUrl(userId, avatarId: avatarId);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  void dispose() {
    unawaited(_eventsSub?.cancel());
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final client = await _resolveClient();
    if (!mounted) return;
    setState(() => _client = client);
    if (client == null) {
      setState(() {
        _loading = false;
        _error = context.tr.team_unavailable;
      });
      return;
    }
    _subscribeToEvents(client);
    await _load();
    // Lancée en tâche de fond : l'équipe du portail sert la modale d'ajout et
    // l'encart en lecture seule, mais ne doit pas retarder le tchat.
    unawaited(_ensurePortalTeam());
  }

  /// Client du runtime courant : le tchat d'équipe est une donnée du COMPTE
  /// (partagée entre appareils), donc il n'a de sens que côté manager.
  Future<MainApiClient?> _resolveClient() async {
    if (widget.client != null) return widget.client;
    final remoteRuntime = await resolveRemoteRuntime(
      supportsManagerRuntime: supportsManagerRuntime,
      botId: widget.botId,
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 30),
    );
    final client = remoteRuntime.client;
    return client is MainApiClient ? client : null;
  }

  /// Abonnement au canal d'événements du compte. Le désabonnement vit en
  /// [dispose] : une page fermée ne doit plus rien rafraîchir.
  void _subscribeToEvents(MainApiClient client) {
    _eventsSub = client.connectGatewayBotEvents().events.listen(
      _onGatewayEvent,
    );
  }

  void _onGatewayEvent(GatewayBotEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case GatewayBotEventType.teamChatMessage:
        final message = event.teamMessage;
        if (message == null) return;
        // Le fil NOMME désormais le bot concerné : c'est la seule autorité, et
        // elle ne dépend plus de qui est déjà dans l'équipe. L'heuristique
        // « l'auteur est-il un membre connu ? » perdait les premiers messages
        // d'un collaborateur tout juste ajouté, et laissait entrer le message
        // d'un autre bot dont l'auteur est membre des deux équipes.
        final botId = message.botId;
        if (botId != null) {
          if (botId != widget.botId) return;
        } else if (!_isKnownTeamMember(message.authorUserId)) {
          // Repli pour un serveur plus ancien (ou un message venu du REST, qui
          // ne porte pas `bot_id`) : sans le nom du bot, l'auteur est le seul
          // indice disponible.
          return;
        }
        _appendMessage(message);
        break;
      case GatewayBotEventType.teamMembersUpdated:
        final botId = event.teamMembersBotId;
        if (botId != null && botId.isNotEmpty && botId != widget.botId) return;
        unawaited(_reloadCollaborators());
        break;
      default:
        break;
    }
  }

  bool _isKnownTeamMember(String userId) {
    if (userId.isEmpty) return false;
    return _collaborators.any((collaborator) => collaborator.userId == userId);
  }

  /// Charge collaborateurs et messages ; [showSpinner] réserve l'écran au
  /// premier chargement, un rafraîchissement garde le contenu à l'écran.
  Future<void> _load({bool showSpinner = true}) async {
    final client = _client;
    if (client == null) return;
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    // Lancés avec le reste : les droits du lecteur décident de l'affichage des
    // contrôles de gestion, mais leur échec ne doit rien fermer d'autre.
    unawaited(_loadMyPermissions());
    try {
      final results = await Future.wait(<Future<List<Map<String, dynamic>>>>[
        client.listTeamCollaborators(widget.botId),
        client.listTeamChatMessages(widget.botId),
      ]);
      if (!mounted) return;
      final messages =
          results[1].map(TeamChatMessage.fromJson).toList(growable: false)
            // Du plus ancien au plus récent : le serveur pagine du plus récent au
            // plus ancien, l'affichage se lit dans l'autre sens.
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      setState(() {
        _collaborators = results[0]
            .map(BotCollaborator.fromJson)
            .toList(growable: false);
        _messages
          ..clear()
          ..addAll(messages);
        _loading = false;
        _error = null;
      });
      _cacheCollaboratorUserMetadata(_collaborators);
      _scrollToLatest();
    } catch (_) {
      if (!mounted) return;
      final hasContent = _messages.isNotEmpty || _collaborators.isNotEmpty;
      if (!hasContent) {
        setState(() {
          _loading = false;
          _error = context.tr.team_chat_load_error;
        });
        return;
      }
      _showError(context.tr.team_chat_load_error);
    }
  }

  /// Charge les droits EFFECTIFS du lecteur sur ce bot (`my_permissions`).
  ///
  /// Échec ou bloc absent = droits INCONNUS, donc contrôles de gestion masqués :
  /// le refus par défaut, jamais l'ouverture. Rejouer un rafraîchissement
  /// (bouton, tirer-pour-rafraîchir) retente l'appel.
  Future<void> _loadMyPermissions() async {
    final client = _client;
    if (client == null) return;
    Map<String, dynamic>? raw;
    try {
      raw = await client.fetchMyTeamPermissions(widget.botId);
    } catch (_) {
      // Droits indisponibles : rien à dire à l'utilisateur, l'écran reste
      // utilisable — seuls les contrôles de gestion s'effacent.
      raw = null;
    }
    if (!mounted) return;
    setState(() {
      _myPermissions = raw == null ? null : BotPermissions.fromJson(raw);
    });
  }

  /// Recharge la seule liste des collaborateurs (changement de droits poussé par
  /// le serveur) : l'échec est silencieux, la conversation reste utilisable.
  Future<void> _reloadCollaborators() async {
    final client = _client;
    if (client == null) return;
    try {
      final raw = await client.listTeamCollaborators(widget.botId);
      if (!mounted) return;
      setState(() {
        _collaborators = raw
            .map(BotCollaborator.fromJson)
            .toList(growable: false);
      });
      _cacheCollaboratorUserMetadata(_collaborators);
    } catch (_) {
      // Rien à dire à l'utilisateur : l'écran affiche encore l'état précédent.
    }
  }

  /// Ajoute un message localement, sans doublon : le serveur renvoie l'événement
  /// d'un message à TOUS les appareils, y compris celui qui l'a envoyé.
  void _appendMessage(TeamChatMessage message) {
    if (_containsMessage(message)) return;
    setState(() => _messages.add(message));
    _scrollToLatest();
  }

  bool _containsMessage(TeamChatMessage message) {
    return _messages.any((existing) {
      if (message.id != 0 && existing.id != 0) {
        return existing.id == message.id;
      }
      return existing.authorUserId == message.authorUserId &&
          existing.content == message.content &&
          existing.createdAt == message.createdAt;
    });
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  /// Équipe du portail Discord, lue une seule fois par page.
  Future<void> _ensurePortalTeam() {
    final pending = _portalLookup;
    if (pending != null) return pending;
    final lookup = _loadPortalTeam();
    _portalLookup = lookup;
    return lookup;
  }

  Future<void> _loadPortalTeam() async {
    final token = await _botToken();
    if (token.isEmpty) return;
    final lookup = widget.portalLookup ?? getDiscordApplicationOwnerMetadata;
    try {
      final metadata = await lookup(token);
      if (!mounted || metadata == null) return;
      setState(() {
        _portalMetadata = metadata;
        _portalMemberIds = metadata.ownerCandidateIds.toSet();
      });
      _cachePortalUserMetadata(metadata);
    } catch (_) {
      // Portail injoignable : on ne dit RIEN sur l'appartenance d'un ID. Mieux
      // vaut aucune mise en garde qu'une accusation fondée sur une panne.
    }
  }

  /// Jeton du bot, lu exactement comme les autres écrans (stockage local du bot,
  /// jamais journalisé).
  Future<String> _botToken() async {
    try {
      final app = await appManager.getApp(widget.botId);
      return (app['token'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  /// Vrai seulement quand on SAIT que l'ID est absent de l'équipe du portail.
  bool _isOutsidePortalTeam(String userId) {
    final portalMemberIds = _portalMemberIds;
    if (portalMemberIds == null || userId.isEmpty) return false;
    return !portalMemberIds.contains(userId);
  }

  Future<void> _showAddCollaboratorDialog() async {
    final idController = TextEditingController();
    // Moindre privilège par défaut, aligné sur le défaut serveur : seule la
    // lecture du tchat est accordée tant que le propriétaire ne coche rien
    // d'autre.
    var permissions = const BotPermissions();

    final draft = await showDialog<_CollaboratorDraft>(
      context: context,
      // `dialogContext` est celui de la MODALE (son `Navigator`/overlay), et
      // `builderContext` celui de l'arbre qu'elle bâtit : tous deux viennent du
      // dialogue. Bâtir les widgets de la modale depuis le `context` de la PAGE
      // ferait, si la page est démontée pendant que la modale est ouverte,
      // chercher l'ancêtre d'un widget désactivé — Flutter jette alors
      // « Looking up a deactivated widget's ancestor ».
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            final userId = idController.text.trim();
            return AlertDialog(
              title: Text(builderContext.tr.team_add_by_discord_id),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: idController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: builderContext.tr.team_add_discord_id_label,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      builderContext.tr.team_permissions_title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _PermissionTile(
                      label: builderContext.tr.team_permission_edit_commands,
                      value: permissions.canEditCommands,
                      onChanged: (checked) => setDialogState(
                        () => permissions = permissions.copyWith(
                          canEditCommands: checked,
                        ),
                      ),
                    ),
                    _PermissionTile(
                      label: builderContext.tr.team_permission_start_stop,
                      value: permissions.canStartStop,
                      onChanged: (checked) => setDialogState(
                        () => permissions = permissions.copyWith(
                          canStartStop: checked,
                        ),
                      ),
                    ),
                    _PermissionTile(
                      label: builderContext.tr.team_permission_claim_ads,
                      value: permissions.canClaimAds,
                      onChanged: (checked) => setDialogState(
                        () => permissions = permissions.copyWith(
                          canClaimAds: checked,
                        ),
                      ),
                    ),
                    _PermissionTile(
                      label: builderContext.tr.team_permission_invite,
                      value: permissions.canInvite,
                      onChanged: (checked) => setDialogState(
                        () => permissions = permissions.copyWith(
                          canInvite: checked,
                        ),
                      ),
                    ),
                    _PermissionTile(
                      label: builderContext.tr.team_permission_view_chat,
                      value: permissions.canViewChat,
                      onChanged: (checked) => setDialogState(
                        () => permissions = permissions.copyWith(
                          canViewChat: checked,
                        ),
                      ),
                    ),
                    // Bandeau INFORMATIF, jamais bloquant : appartenir à
                    // l'équipe du portail et avoir accès au bot sont deux choses
                    // distinctes. Le bouton de validation reste donc actif même
                    // quand l'ID est absent du portail.
                    if (_isOutsidePortalTeam(userId))
                      const Padding(
                        padding: EdgeInsets.only(top: AppTheme.spacingMd),
                        child: _PortalTeamWarningBanner(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(builderContext.tr.cancel),
                ),
                FilledButton(
                  onPressed: userId.isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(
                          _CollaboratorDraft(
                            userId: userId,
                            permissions: permissions,
                          ),
                        ),
                  child: Text(builderContext.tr.common_save),
                ),
              ],
            );
          },
        );
      },
    );

    if (draft == null || !mounted) return;
    await _addCollaborator(draft);
  }

  Future<void> _addCollaborator(_CollaboratorDraft draft) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.upsertTeamCollaborator(
        widget.botId,
        draft.userId,
        draft.permissions.toJson(),
      );
      if (!mounted) return;
      await _load(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      _showError(context.tr.team_add_error);
    }
  }

  Future<void> _confirmRemove(BotCollaborator collaborator) async {
    final label = collaborator.displayName.isNotEmpty
        ? collaborator.displayName
        : collaborator.userId;
    final confirmed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.team_remove,
      content: context.tr.team_remove_confirm(label),
      confirmLabel: context.tr.team_remove,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final client = _client;
    if (client == null) return;
    try {
      await client.removeTeamCollaborator(widget.botId, collaborator.userId);
      if (!mounted) return;
      await _load(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      _showError(context.tr.team_remove_error);
    }
  }

  Future<void> _sendMessage() async {
    final content = _composerController.text.trim();
    final client = _client;
    if (content.isEmpty || client == null || _sending) return;
    setState(() => _sending = true);
    try {
      final response = await client.sendTeamChatMessage(widget.botId, content);
      if (!mounted) return;
      _composerController.clear();
      // Réponse exploitable : le message apparaît sans attendre l'aller-retour
      // de l'événement. Sinon le serveur le pousse à tous les appareils, dont
      // celui-ci : rien ne manque.
      final created = _createdMessage(response);
      if (created != null) {
        _appendMessage(created);
      }
    } catch (_) {
      if (!mounted) return;
      _showError(context.tr.team_chat_send_error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  TeamChatMessage? _createdMessage(Map<String, dynamic> response) {
    final raw = response['message'] ?? response['data'];
    final map = raw is Map
        ? Map<String, dynamic>.from(raw.cast<dynamic, dynamic>())
        : response;
    final message = TeamChatMessage.fromJson(map);
    return message.content.isEmpty ? null : message;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  /// Heure du message, datée quand il n'est pas d'aujourd'hui : dans un tchat
  /// d'équipe, un « 14:32 » seul pour un message de la veille serait trompeur.
  String _timestampLabel(BuildContext context, DateTime timestamp) {
    final local = timestamp.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local));
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return isToday ? time : '${localizations.formatShortDate(local)} $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: editorSubPageLeading(context),
        title: Text(context.tr.team_chat_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.tr.common_refresh,
            onPressed: _client == null ? null : () => _load(),
          ),
        ],
      ),
      body: SafeArea(top: false, child: PageContent(child: _buildBody())),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: AppTheme.spacingMd),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingMd),
            FilledButton(
              onPressed: () => _load(),
              child: Text(context.tr.common_retry),
            ),
          ],
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(showSpinner: false),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: AppTheme.spacingLg,
                bottom: AppTheme.spacingLg,
              ),
              children: [
                _buildCollaboratorsCard(),
                if (_portalMetadata != null) _buildPortalTeamSection(),
                const SizedBox(height: AppTheme.spacingLg),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: AppTheme.discord,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr.team_chat_title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_messages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingXl,
                      horizontal: AppTheme.spacingLg,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 44,
                          color: scheme.outline.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr.team_chat_empty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final message in _messages)
                    _ChatMessageTile(
                      message: message,
                      authorName: _resolveAuthorName(message),
                      authorAvatarUrl: _resolveAuthorAvatarUrl(
                        message.authorUserId,
                      ),
                      timeLabel: _timestampLabel(context, message.createdAt),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildComposer(),
      ],
    );
  }

  Widget _buildCollaboratorsCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 460;
                final titleRow = Row(
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      color: AppTheme.discord,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.tr.team_collaborators_title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.discord.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_collaborators.length}',
                        style: const TextStyle(
                          color: AppTheme.discord,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isCompact) ...[
                      const Spacer(),
                      if (_canManageTeam)
                        TextButton.icon(
                          onPressed: _client == null
                              ? null
                              : _showAddCollaboratorDialog,
                          icon: const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 18,
                          ),
                          label: Text(context.tr.team_add_by_discord_id),
                        ),
                    ],
                  ],
                );

                if (!isCompact) return titleRow;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    if (_canManageTeam) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _client == null
                            ? null
                            : _showAddCollaboratorDialog,
                        icon: const Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 18,
                        ),
                        label: Text(context.tr.team_add_by_discord_id),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          if (_collaborators.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 36,
                    color: AppTheme.discord.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.team_collaborators_empty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < _collaborators.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              _CollaboratorTile(
                collaborator: _collaborators[i],
                resolvedName: _userDisplayNames[_collaborators[i].userId],
                resolvedAvatar: _resolveAuthorAvatarUrl(
                  _collaborators[i].userId,
                ),
                onRemove: _canManageTeam && !_collaborators[i].isOwner
                    ? () => _confirmRemove(_collaborators[i])
                    : null,
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildComposer() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: FloatingGlassNavBar.contentClearanceOf(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _composerController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: context.tr.team_chat_input_hint,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppTheme.discord,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.discord,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            tooltip: context.tr.team_chat_send,
            onPressed: _sending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  /// Encart « équipe du portail Discord », en LECTURE SEULE.
  ///
  /// Ce bloc vient des réglages du bot, où il était rendu une seconde fois : le
  /// portail ne décrit qu'une chose — qui possède l'application côté Discord —
  /// et une seule page doit la montrer. Sa donnée reste celle du portail
  /// ([getDiscordApplicationOwnerMetadata]) ; rien n'est modifiable ici.
  Widget _buildPortalTeamSection() {
    final meta = _portalMetadata;
    if (meta == null) {
      return const SizedBox.shrink();
    }
    final hasTeam = meta.teamId.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingMd),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Icon(
              hasTeam ? Icons.groups_outlined : Icons.person_outline,
              color: AppTheme.discord,
            ),
            title: Text(
              hasTeam
                  ? context.tr.settings_team_ownership
                  : context.tr.settings_personal_ownership,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              context.tr.team_portal_section_title,
              style: const TextStyle(fontSize: 11, color: AppTheme.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (hasTeam ? AppTheme.discord : AppTheme.success)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (hasTeam ? AppTheme.discord : AppTheme.success)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    hasTeam
                        ? context.tr.settings_team_pill
                        : context.tr.settings_solo_pill,
                    style: TextStyle(
                      color: hasTeam ? AppTheme.discord : AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, size: 20),
              ],
            ),
            children: [
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              // Visual Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTeam) ...[
                      // Team Name
                      Row(
                        children: [
                          Text(
                            context.tr.settings_team_name_label,
                            style: const TextStyle(
                              color: AppTheme.discordText,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            meta.teamName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            context.tr.settings_team_id_label,
                            style: const TextStyle(
                              color: AppTheme.discordText,
                              fontSize: 13,
                            ),
                          ),
                          SelectableText(
                            meta.teamId,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Team Owner
                      Text(
                        context.tr.settings_team_owner_label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.discordText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.discordDarkBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meta.teamOwnerUsername.isNotEmpty
                                        ? meta.teamOwnerUsername
                                        : context.tr.settings_owner_fallback,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SelectableText(
                                    meta.teamOwnerUserId,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: AppTheme.discordText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                context.tr.settings_owner_badge,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Team Members
                      Text(
                        context.tr.settings_team_members_label(
                          meta.teamMembersInfo.length,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.discordText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final member in meta.teamMembersInfo)
                        _PortalTeamMemberTile(
                          member: member,
                          isOwner: member['id'] == meta.teamOwnerUserId,
                        ),
                    ] else ...[
                      // Personal Owner info
                      Row(
                        children: [
                          Text(
                            context.tr.settings_personal_owner_label,
                            style: const TextStyle(
                              color: AppTheme.discordText,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            meta.ownerUsername.isNotEmpty
                                ? meta.ownerUsername
                                : context.tr.settings_personal_owner_fallback,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            context.tr.settings_personal_owner_id_label,
                            style: const TextStyle(
                              color: AppTheme.discordText,
                              fontSize: 13,
                            ),
                          ),
                          SelectableText(
                            meta.ownerId,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un membre de l'équipe officielle du portail Discord, en lecture seule.
class _PortalTeamMemberTile extends StatelessWidget {
  const _PortalTeamMemberTile({required this.member, required this.isOwner});

  final Map<String, dynamic> member;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final avatarId = member['avatar']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.discordDarkBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.discord,
            backgroundImage: avatarId.isEmpty
                ? null
                : NetworkImage(
                    makeAvatarUrl(member['id'].toString(), avatarId: avatarId),
                  ),
            child: avatarId.isEmpty
                ? const Icon(Icons.person, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['username']?.toString() ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SelectableText(
                  member['id']?.toString() ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppTheme.discordText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isOwner ? Colors.amber : AppTheme.discord).withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isOwner
                  ? context.tr.settings_owner_badge
                  : member['role']?.toString().toUpperCase() ??
                        context.tr.settings_member_badge,
              style: TextStyle(
                color: isOwner ? Colors.amber : AppTheme.discord,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un collaborateur du bot : qui il est, ses droits, et de quoi le retirer.
class _CollaboratorTile extends StatelessWidget {
  const _CollaboratorTile({
    required this.collaborator,
    this.resolvedName,
    this.resolvedAvatar,
    this.onRemove,
  });

  final BotCollaborator collaborator;
  final String? resolvedName;
  final String? resolvedAvatar;

  /// `null` pour le propriétaire : il ne se retire pas lui-même de son bot.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final displayName = collaborator.displayName.isNotEmpty
        ? collaborator.displayName
        : (resolvedName != null && resolvedName!.isNotEmpty
              ? resolvedName!
              : collaborator.userId);
    final onRemove = this.onRemove;
    final avatar = resolvedAvatar;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppTheme.discord.withValues(alpha: 0.15),
        backgroundImage: avatar != null && avatar.isNotEmpty
            ? NetworkImage(avatar)
            : null,
        child: avatar == null || avatar.isEmpty
            ? (displayName.isNotEmpty && displayName != collaborator.userId
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.discord,
                      ),
                    )
                  : const Icon(Icons.person_outline, size: 18))
            : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: displayName == collaborator.userId
          ? null
          : Text(
              collaborator.userId,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (collaborator.isOwner)
            _TeamPill(label: context.tr.team_owner_badge, color: Colors.amber)
          else if (collaborator.inDiscordTeam)
            _TeamPill(
              label: context.tr.settings_team_pill,
              color: AppTheme.discord,
            ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.person_remove_outlined, size: 18),
              tooltip: context.tr.team_remove,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

/// Un message du tchat : auteur, horodatage, contenu.
class _ChatMessageTile extends StatelessWidget {
  const _ChatMessageTile({
    required this.message,
    required this.authorName,
    this.authorAvatarUrl,
    required this.timeLabel,
  });

  final TeamChatMessage message;
  final String authorName;
  final String? authorAvatarUrl;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = authorAvatarUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppTheme.discord,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: SelectableText(
                    message.content,
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une case de droit du collaborateur (libellé localisé passé par l'appelant).
class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

/// Bandeau informatif de la modale d'ajout : l'ID n'est pas dans l'équipe du
/// portail Discord. Il explique, il ne bloque pas.
class _PortalTeamWarningBanner extends StatelessWidget {
  const _PortalTeamWarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppTheme.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr.team_not_in_portal_warning,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge compact d'état (« OWNER », « TEAM »).
class _TeamPill extends StatelessWidget {
  const _TeamPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Brouillon validé par la modale d'ajout d'un collaborateur.
class _CollaboratorDraft {
  const _CollaboratorDraft({required this.userId, required this.permissions});

  final String userId;
  final BotPermissions permissions;
}

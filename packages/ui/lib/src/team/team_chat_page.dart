// L'ÉCRAN « ÉQUIPE ET TCHAT » D'UN BOT : le tchat d'équipe (persisté côté
// serveur), les collaborateurs et leurs droits, et l'équipe officielle du portail
// Discord en lecture seule. Partagé entre l'app et le Studio ; tout ce qui parle
// au serveur passe par [TeamChatHost].
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../editor/lists/editor_sub_page_ui.dart';
import '../editor/lists/settings_group_widgets.dart';
import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../utils/discord_avatar_url.dart';
import '../widgets/app_icon.dart';
import '../widgets/floating_glass_nav_bar.dart';
import '../widgets/page_layout.dart';
import 'team_chat_host.dart';
import 'team_models.dart';

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
///     elle appartient à Discord, l'écran ne fait que la montrer (quand l'hôte
///     sait la lire).
///
/// Le temps réel arrive par [TeamChatHost.events] : un message ou un changement
/// de droits apparaît sans rechargement.
class TeamChatPage extends StatefulWidget {
  const TeamChatPage({
    super.key,
    required this.botId,
    required this.host,
    this.reserveNavBarClearance = true,
  });

  final String botId;
  final TeamChatHost host;

  /// Réserve sous le champ de saisie la place de la barre de navigation
  /// flottante de l'app, qui recouvre le contenu. Le Studio, dont la barre
  /// est hors de la page, passe `false`.
  final bool reserveNavBarClearance;

  @override
  State<TeamChatPage> createState() => _TeamChatPageState();
}

class _TeamChatPageState extends State<TeamChatPage> {
  /// L'hôte reçu à l'ouverture : il garde son état préparé ([TeamChatHost.prepare]),
  /// un parent qui se reconstruit avec un autre exemplaire ne doit pas le
  /// remplacer en cours de route.
  late final TeamChatHost _host = widget.host;
  StreamSubscription<TeamChatEvent>? _eventsSub;

  /// Vrai quand l'hôte a un serveur à qui parler (voir [TeamChatHost.prepare]).
  bool _ready = false;

  List<BotCollaborator> _collaborators = const <BotCollaborator>[];
  final List<TeamChatMessage> _messages = <TeamChatMessage>[];

  bool _loading = true;
  String? _error;
  bool _sending = false;

  /// Droits EFFECTIFS du lecteur sur CE bot, tels que le serveur les accorde
  /// (`my_permissions` de la route d'équipe, via [TeamChatHost.myPermissions]).
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
  /// réponse est rendu à CÔTÉ de `my_permissions`, que l'hôte ne remonte pas :
  /// le propriétaire y est reconnu par ses droits, pas par une seconde lecture.
  bool get _canManageTeam => _myPermissions?.canInvite == true;

  /// Le lecteur a-t-il le droit de lire et d'écrire dans le tchat ? Seul un
  /// refus EXPLICITE (`can_view_chat: false`) le ferme : le tchat précède les
  /// droits, un serveur qui ne les annonce pas ne doit pas en priver.
  bool get _canViewChat => _myPermissions?.canViewChat != false;

  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Pseudonymes et avatars Discord résolus (portail, collaborateurs ou Discord API).
  final Map<String, String> _userDisplayNames = <String, String>{};
  final Map<String, String> _userAvatars = <String, String>{};
  final Set<String> _pendingUserLookups = <String>{};

  /// Messages locaux en attente de confirmation serveur ou en échec temporaire.
  final List<_LocalPendingMessage> _pendingMessages = <_LocalPendingMessage>[];
  String _myDisplayName = '';

  /// Équipe officielle du portail Discord de CE bot, mise en cache au niveau de
  /// la page : la vérification ne coûte donc jamais un appel réseau par frappe.
  /// `null` = inconnue (jeton absent, portail injoignable) : dans ce cas aucune
  /// mise en garde n'est affichée, une absence ne se suppose pas.
  Set<String>? _portalMemberIds;
  TeamPortalInfo? _portalMetadata;
  Future<void>? _portalLookup;

  void _cachePortalUserMetadata(TeamPortalInfo metadata) {
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
    for (final member in metadata.teamMembers) {
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
    try {
      final profile = await _host.lookupUser(widget.botId, userId);
      if (profile == null || !mounted) return;
      final username = profile.name.trim();
      final avatar = profile.avatarId.trim();
      if (username.isNotEmpty || avatar.isNotEmpty) {
        setState(() {
          if (username.isNotEmpty) _userDisplayNames[userId] = username;
          if (avatar.isNotEmpty) _userAvatars[userId] = avatar;
        });
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
      return discordAvatarUrl(userId, avatarId: avatarId);
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
    final ready = await _host.prepare(widget.botId);
    if (!mounted) return;
    setState(() => _ready = ready);
    if (!ready) {
      setState(() {
        _loading = false;
        _error = context.tr.team_unavailable;
      });
      return;
    }
    _subscribeToEvents();
    unawaited(_loadCurrentUser());
    await _load();
    // Lancée en tâche de fond : l'équipe du portail sert la modale d'ajout et
    // l'encart en lecture seule, mais ne doit pas retarder le tchat.
    unawaited(_ensurePortalTeam());
  }

  Future<void> _loadCurrentUser() async {
    final name = await _host.currentUserName();
    if (mounted && name.isNotEmpty) {
      setState(() {
        _myDisplayName = name;
      });
    }
  }

  /// Abonnement au temps réel. Le désabonnement vit en [dispose] : une page
  /// fermée ne doit plus rien rafraîchir.
  void _subscribeToEvents() {
    _eventsSub = _host.events(widget.botId).listen(_onEvent);
  }

  void _onEvent(TeamChatEvent event) {
    if (!mounted) return;
    switch (event) {
      case TeamChatMessageEvent(:final message):
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
      case TeamMembersChangedEvent(:final botId):
        if (botId != null && botId.isNotEmpty && botId != widget.botId) return;
        unawaited(_reloadCollaborators());
      case TeamChatResyncEvent():
        if (!_loading) {
          // Reconnecté au temps réel : réconciliation transparente des messages
          // manqués.
          unawaited(_load(showSpinner: false));
        }
    }
  }

  bool _isKnownTeamMember(String userId) {
    if (userId.isEmpty) return false;
    return _collaborators.any((collaborator) => collaborator.userId == userId);
  }

  /// Charge collaborateurs et messages ; [showSpinner] réserve l'écran au
  /// premier chargement, un rafraîchissement garde le contenu à l'écran.
  Future<void> _load({bool showSpinner = true}) async {
    if (!_ready) return;
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    // Lancés avec le reste : les droits du lecteur décident de l'affichage des
    // contrôles de gestion, mais leur échec ne doit rien fermer d'autre.
    final permissionsLoad = _loadMyPermissions();
    try {
      final results = await Future.wait<Object?>(<Future<Object?>>[
        _host.collaborators(widget.botId),
        // Un refus du fil (`403` : pas le droit de lire le tchat) n'est pas
        // une panne de la page tant que les droits du lecteur le disent.
        (_canViewChat
                ? _host.messages(widget.botId)
                : Future<List<TeamChatMessage>>.value(<TeamChatMessage>[]))
            .then<Object?>((messages) => messages, onError: (Object e) => e),
      ]);
      if (!mounted) return;
      final fetched = results[1];
      if (fetched is! List<TeamChatMessage>) {
        await permissionsLoad;
        if (!mounted) return;
        if (_canViewChat) throw fetched!;
      }
      final messages =
          (fetched is List<TeamChatMessage>
                ? fetched.toList()
                : <TeamChatMessage>[])
            // Du plus ancien au plus récent : le serveur pagine du plus récent au
            // plus ancien, l'affichage se lit dans l'autre sens.
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      setState(() {
        _collaborators = results[0]! as List<BotCollaborator>;
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
    if (!_ready) return;
    BotPermissions? permissions;
    try {
      permissions = await _host.myPermissions(widget.botId);
    } catch (_) {
      // Droits indisponibles : rien à dire à l'utilisateur, l'écran reste
      // utilisable — seuls les contrôles de gestion s'effacent.
      permissions = null;
    }
    if (!mounted) return;
    setState(() {
      _myPermissions = permissions;
    });
  }

  /// Recharge la seule liste des collaborateurs (changement de droits poussé par
  /// le serveur) : l'échec est silencieux, la conversation reste utilisable.
  Future<void> _reloadCollaborators() async {
    if (!_ready) return;
    try {
      final collaborators = await _host.collaborators(widget.botId);
      if (!mounted) return;
      setState(() {
        _collaborators = collaborators;
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
    setState(() {
      _pendingMessages.removeWhere(
        (p) => p.content == message.content && !p.isFailed,
      );
      _messages.add(message);
    });
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
    try {
      final metadata = await _host.portalTeam(widget.botId);
      if (!mounted || metadata == null) return;
      setState(() {
        _portalMetadata = metadata;
        _portalMemberIds = metadata.memberIds;
      });
      _cachePortalUserMetadata(metadata);
    } catch (_) {
      // Portail injoignable : on ne dit RIEN sur l'appartenance d'un ID. Mieux
      // vaut aucune mise en garde qu'une accusation fondée sur une panne.
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
    if (!_ready) return;
    try {
      await _host.upsertCollaborator(
        widget.botId,
        draft.userId,
        draft.permissions,
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
    if (!_ready) return;
    try {
      await _host.removeCollaborator(widget.botId, collaborator.userId);
      if (!mounted) return;
      await _load(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      _showError(context.tr.team_remove_error);
    }
  }

  Future<void> _sendMessage() async {
    final content = _composerController.text.trim();
    if (content.isEmpty || !_ready || _sending) return;

    _composerController.clear();
    final pending = _LocalPendingMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      content: content,
      createdAt: DateTime.now(),
    );
    setState(() {
      _sending = true;
      _pendingMessages.add(pending);
    });
    _scrollToLatest();

    await _dispatchSendMessage(pending);
  }

  Future<void> _dispatchSendMessage(_LocalPendingMessage pending) async {
    if (!_ready) return;

    setState(() {
      pending.isFailed = false;
    });

    var delivered = false;
    TeamChatMessage? created;

    // Retry loop with exponential backoff: up to 3 attempts on network/route drops
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        created = await _host.postMessage(widget.botId, pending.content);
        delivered = true;
        break;
      } catch (e) {
        if (attempt < 3) {
          await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
        }
      }
    }

    if (!mounted) return;

    if (delivered) {
      setState(() {
        _pendingMessages.remove(pending);
        _sending = false;
      });
      if (created != null) {
        _appendMessage(created);
      }
    } else {
      setState(() {
        pending.isFailed = true;
        _sending = false;
      });
      _showError(context.tr.team_chat_send_error);
    }
  }

  void _retryMessage(_LocalPendingMessage pending) {
    if (_sending) return;
    setState(() => _sending = true);
    unawaited(_dispatchSendMessage(pending));
  }

  void _discardPendingMessage(_LocalPendingMessage pending) {
    setState(() {
      _pendingMessages.remove(pending);
    });
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
            icon: const AppIcon.fromMaterial(Icons.refresh),
            tooltip: context.tr.common_refresh,
            onPressed: !_ready ? null : () => _load(),
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
            const AppIcon.fromMaterial(
              Icons.error_outline,
              size: 48,
              color: AppTheme.error,
            ),
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
                SettingsSectionHeader(context.tr.team_chat_title),
                if (!_canViewChat)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingXl,
                      horizontal: AppTheme.spacingLg,
                    ),
                    child: Text(
                      context.tr.team_chat_no_access,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HomeTokens.of(context).muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  )
                else if (_messages.isEmpty && _pendingMessages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingXl,
                      horizontal: AppTheme.spacingLg,
                    ),
                    child: Column(
                      children: [
                        AppIcon.fromMaterial(
                          Icons.forum_outlined,
                          size: 44,
                          color: HomeTokens.of(context).muted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr.team_chat_empty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: HomeTokens.of(context).muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  for (final message in _messages)
                    _ChatMessageTile(
                      message: message,
                      authorName: _resolveAuthorName(message),
                      authorAvatarUrl: _resolveAuthorAvatarUrl(
                        message.authorUserId,
                      ),
                      timeLabel: _timestampLabel(context, message.createdAt),
                    ),
                  for (final pending in _pendingMessages)
                    _PendingChatMessageTile(
                      pending: pending,
                      authorName: _myDisplayName,
                      onRetry: () => _retryMessage(pending),
                      onDismiss: () => _discardPendingMessage(pending),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (_canViewChat) ...[
          const SizedBox(height: AppTheme.spacingMd),
          _buildComposer(),
        ],
      ],
    );
  }

  Widget _addCollaboratorButton({bool compact = false}) {
    return TextButton.icon(
      onPressed: !_ready ? null : _showAddCollaboratorDialog,
      icon: const AppIcon.fromMaterial(
        Icons.person_add_alt_1_outlined,
        size: 18,
      ),
      label: Text(context.tr.team_add_by_discord_id),
      style: compact
          ? TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }

  Widget _buildCollaboratorsCard() {
    final tokens = HomeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 460;
            final titleRow = Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.tr.team_collaborators_title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.84,
                              color: tokens.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SettingsChip('${_collaborators.length}'),
                      ],
                    ),
                  ),
                ),
                if (!isCompact && _canManageTeam) _addCollaboratorButton(),
              ],
            );
            if (!isCompact || !_canManageTeam) return titleRow;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleRow, _addCollaboratorButton(compact: true)],
            );
          },
        ),
        SettingsGroupCard(
          children: [
            if (_collaborators.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon.fromMaterial(
                      Icons.people_outline_rounded,
                      size: 36,
                      color: tokens.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr.team_collaborators_empty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < _collaborators.length; i++)
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
        ),
      ],
    );
  }

  Widget _buildComposer() {
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.reserveNavBarClearance
            ? FloatingGlassNavBar.contentClearanceOf(context)
            : 0,
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
                fillColor: tokens.clusterBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: border(tokens.clusterBorder),
                enabledBorder: border(tokens.clusterBorder),
                focusedBorder: border(scheme.primary),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _sending
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const AppIcon.fromMaterial(Icons.send_rounded, size: 20),
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
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(color: tokens.muted, fontSize: 13);
    final valueStyle = TextStyle(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
      fontSize: 14,
    );
    final idStyle = TextStyle(
      color: tokens.muted,
      fontFamily: 'monospace',
      fontSize: 12,
    );
    Widget overline(String text) => Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.84,
        color: tokens.muted,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingMd),
      child: Material(
        color: tokens.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.cardBorder),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            minTileHeight: kSettingsRowMinHeight,
            collapsedShape: const RoundedRectangleBorder(),
            shape: const RoundedRectangleBorder(),
            leading: SettingsRowIcon(
              hasTeam ? Icons.groups_outlined : Icons.person_outline,
            ),
            title: Text(
              hasTeam
                  ? context.tr.settings_team_ownership
                  : context.tr.settings_personal_ownership,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: scheme.onSurface,
              ),
            ),
            subtitle: Text(
              context.tr.team_portal_section_title,
              style: TextStyle(fontSize: 12.5, color: tokens.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsChip(
                  hasTeam
                      ? context.tr.settings_team_pill
                      : context.tr.settings_solo_pill,
                ),
                const SizedBox(width: 4),
                const AppIcon.fromMaterial(Icons.expand_more, size: 20),
              ],
            ),
            children: [
              Divider(height: 1, thickness: 1, color: tokens.cardBorder),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTeam) ...[
                      Row(
                        children: [
                          Text(
                            context.tr.settings_team_name_label,
                            style: labelStyle,
                          ),
                          Text(meta.teamName, style: valueStyle),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            context.tr.settings_team_id_label,
                            style: labelStyle,
                          ),
                          SelectableText(meta.teamId, style: idStyle),
                        ],
                      ),
                      const SizedBox(height: 16),
                      overline(context.tr.settings_team_owner_label),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tokens.clusterBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tokens.clusterBorder),
                        ),
                        child: Row(
                          children: [
                            AppIcon.fromMaterial(
                              Icons.stars,
                              color: tokens.muted,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meta.teamOwnerUsername.isNotEmpty
                                        ? meta.teamOwnerUsername
                                        : context.tr.settings_owner_fallback,
                                    style: valueStyle,
                                  ),
                                  SelectableText(
                                    meta.teamOwnerUserId,
                                    style: idStyle.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            SettingsChip(context.tr.settings_owner_badge),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      overline(
                        context.tr.settings_team_members_label(
                          meta.teamMembers.length,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final member in meta.teamMembers)
                        _PortalTeamMemberTile(
                          member: member,
                          isOwner: member['id'] == meta.teamOwnerUserId,
                        ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            context.tr.settings_personal_owner_label,
                            style: labelStyle,
                          ),
                          Text(
                            meta.ownerUsername.isNotEmpty
                                ? meta.ownerUsername
                                : context.tr.settings_personal_owner_fallback,
                            style: valueStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            context.tr.settings_personal_owner_id_label,
                            style: labelStyle,
                          ),
                          SelectableText(meta.ownerId, style: idStyle),
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
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final avatarId = member['avatar']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.clusterBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.clusterBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: tokens.card,
            backgroundImage: avatarId.isEmpty
                ? null
                : NetworkImage(
                    discordAvatarUrl(
                      member['id'].toString(),
                      avatarId: avatarId,
                    ),
                  ),
            child: avatarId.isEmpty
                ? AppIcon.fromMaterial(
                    Icons.person,
                    size: 14,
                    color: tokens.muted,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['username']?.toString() ?? '',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SelectableText(
                  member['id']?.toString() ?? '',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    color: tokens.muted,
                  ),
                ),
              ],
            ),
          ),
          SettingsChip(
            isOwner
                ? context.tr.settings_owner_badge
                : member['role']?.toString().toUpperCase() ??
                      context.tr.settings_member_badge,
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
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      minTileHeight: 60,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: tokens.clusterBg,
        backgroundImage: avatar != null && avatar.isNotEmpty
            ? NetworkImage(avatar)
            : null,
        child: avatar == null || avatar.isEmpty
            ? (displayName.isNotEmpty && displayName != collaborator.userId
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    )
                  : AppIcon.fromMaterial(
                      Icons.person_outline,
                      size: 18,
                      color: tokens.muted,
                    ))
            : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
      subtitle: displayName == collaborator.userId
          ? null
          : Text(
              collaborator.userId,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: tokens.muted,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (collaborator.isOwner)
            _TeamPill(label: context.tr.team_owner_badge)
          else if (collaborator.inDiscordTeam)
            _TeamPill(label: context.tr.settings_team_pill),
          if (onRemove != null)
            IconButton(
              icon: const AppIcon.fromMaterial(
                Icons.person_remove_outlined,
                size: 18,
              ),
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
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = authorAvatarUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: tokens.clusterBg,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: scheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: TextStyle(fontSize: 11, color: tokens.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: SelectableText(
                    message.content,
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
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
    final tokens = HomeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: tokens.clusterBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.clusterBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon.fromMaterial(
            Icons.info_outline,
            size: 18,
            color: AppTheme.statusWarning,
          ),
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

/// Badge compact neutre (« OWNER », « TEAM »).
class _TeamPill extends StatelessWidget {
  const _TeamPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => SettingsChip(label.toUpperCase());
}

/// Brouillon validé par la modale d'ajout d'un collaborateur.
class _CollaboratorDraft {
  const _CollaboratorDraft({required this.userId, required this.permissions});

  final String userId;
  final BotPermissions permissions;
}

/// Message local en cours d'envoi ou en échec temporaire.
class _LocalPendingMessage {
  final String id;
  final String content;
  final DateTime createdAt;
  bool isFailed = false;

  _LocalPendingMessage({
    required this.id,
    required this.content,
    required this.createdAt,
  });
}

/// Rendu d'un message local avec état en vol et bouton de réessai en cas d'échec.
class _PendingChatMessageTile extends StatelessWidget {
  const _PendingChatMessageTile({
    required this.pending,
    required this.authorName,
    required this.onRetry,
    required this.onDismiss,
  });

  final _LocalPendingMessage pending;
  final String authorName;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isFailed = pending.isFailed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isFailed ? AppTheme.statusError : tokens.clusterBg,
            child: AppIcon.fromMaterial(
              isFailed ? Icons.error_outline : Icons.person,
              size: 18,
              color: isFailed ? Colors.white : tokens.muted,
            ),
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
                        authorName.isNotEmpty
                            ? authorName
                            : context.tr.team_chat_me,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: scheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFailed
                          ? context.tr.team_chat_send_failed
                          : context.tr.team_chat_sending,
                      style: TextStyle(
                        fontSize: 11,
                        color: isFailed
                            ? AppTheme.statusErrorText
                            : tokens.muted,
                        fontWeight: isFailed
                            ? FontWeight.w500
                            : FontWeight.normal,
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
                    color: tokens.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFailed
                          ? AppTheme.statusError
                          : tokens.cardBorder,
                    ),
                  ),
                  child: SelectableText(
                    pending.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isFailed ? tokens.muted : null,
                    ),
                  ),
                ),
                if (isFailed) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: scheme.primary,
                        ),
                        icon: const AppIcon.fromMaterial(
                          Icons.refresh,
                          size: 14,
                        ),
                        label: Text(
                          context.tr.common_retry,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: onRetry,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: tokens.muted,
                        ),
                        icon: const AppIcon.fromMaterial(Icons.close, size: 14),
                        label: Text(
                          context.tr.common_cancel,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: onDismiss,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

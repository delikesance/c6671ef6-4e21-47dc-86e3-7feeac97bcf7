import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/studio_session.dart';
import '../dashboard/command_stats.dart';

class StudioApiException implements Exception {
  const StudioApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Code applicatif du serveur (`bot_quota_reached`…) : c'est le contrat,
  /// la phrase du [message] peut changer.
  final String? code;

  /// 401, ou 403 SANS code applicatif. Un 403 avec code (`bot_quota_reached`…)
  /// est un refus métier : la session est bonne, on ne la rafraîchit pas et on
  /// ne rejoue surtout pas la requête.
  bool get isUnauthorized =>
      statusCode == 401 || (statusCode == 403 && (code ?? '').isEmpty);

  /// Refus de démarrage qui disparaît tout seul en quelques secondes.
  bool get isTransientStartRefusal {
    final c = (code ?? '').toLowerCase();
    return c == 'bot_free_time_required' ||
        c == 'runner_not_deployed' ||
        c == 'runner_unreachable' ||
        message.toLowerCase().contains('free runtime credits before start');
  }

  @override
  String toString() => statusCode == null ? message : '[$statusCode] $message';
}

class StudioBot {
  const StudioBot({
    required this.id,
    required this.name,
    this.running = false,
    this.stateKnown = true,
  });

  final String id;
  final String name;
  final bool running;

  /// `false` quand la liste n'a donné aucun état : il faut alors interroger
  /// `/status` bot par bot.
  final bool stateKnown;

  StudioBot copyWith({bool? running, bool? stateKnown}) => StudioBot(
    id: id,
    name: name,
    running: running ?? this.running,
    stateKnown: stateKnown ?? this.stateKnown,
  );
}

/// Ce que le serveur rend pour `GET /gateway/bots/{id}/runtime`.
class StudioBotRuntime {
  const StudioBotRuntime({
    this.premiumFunded = false,
    this.freeMinutes,
    this.sessionExpiresAt,
    this.sessionActive = false,
  });

  final bool premiumFunded;
  final int? freeMinutes;
  final DateTime? sessionExpiresAt;
  final bool sessionActive;
}

/// Une commande ENTIÈRE telle que le serveur la stocke (`raw`), plus la
/// révision du document bot qui la porte (nécessaire pour réécrire).
class StudioCommandDetail {
  const StudioCommandDetail({required this.raw, this.revision});

  final Map<String, dynamic> raw;
  final String? revision;
}

class StudioScopedDefinition {
  const StudioScopedDefinition({
    required this.key,
    required this.scope,
    required this.valueType,
    this.defaultValue,
  });

  final String key;
  final String scope;
  final String valueType;
  final Object? defaultValue;
}

class StudioCollaborator {
  const StudioCollaborator({
    required this.userId,
    required this.displayName,
    required this.role,
    this.isOwner = false,
    this.permissions = const {},
  });

  final String userId;
  final String displayName;
  final String role;
  final bool isOwner;

  /// `can_edit_commands`, `can_start_stop`, `can_claim_ads`, `can_invite`,
  /// `can_view_chat`. Une clé absente vaut refus (sauf `can_view_chat`).
  final Map<String, bool> permissions;
}

class StudioTeam {
  const StudioTeam({required this.collaborators, required this.mine});

  final List<StudioCollaborator> collaborators;
  final Map<String, bool> mine;
}

class StudioChatMessage {
  const StudioChatMessage({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String author;
  final String content;
  final DateTime createdAt;
}

class StudioBotIdentity {
  const StudioBotIdentity({required this.id, required this.name});

  final String id;
  final String name;
}

class StudioCommand {
  const StudioCommand({
    required this.id,
    required this.name,
    this.trigger = '',
    this.card = const {},
  });

  final String id;
  final String name;
  final String trigger;

  /// La commande sous la forme que la carte de liste de l'app attend
  /// (`type`, `folder`, `data.{options, actions, legacy*}`), à partir des champs
  /// d'affichage de la liste du Manager.
  final Map<String, dynamic> card;
}

class StudioWorkflowSummary {
  const StudioWorkflowSummary({
    required this.name,
    this.type = 'general',
    this.executionMode = 'workflow',
    this.actionCount = 0,
    this.folder = '',
    this.entryPoint = 'main',
    this.argumentCount = 0,
    this.event = '',
  });

  final String folder;
  final String entryPoint;
  final int argumentCount;

  /// Événement Discord déclencheur (workflow d'événement).
  final String event;

  final String name;

  /// `general` | `event`.
  final String type;

  /// `workflow` | `bdfd_script` | `javascript`.
  final String executionMode;
  final int actionCount;
}

/// Un workflow ENTIER tel que le serveur le stocke, plus la révision du document.
class StudioWorkflowDetail {
  const StudioWorkflowDetail({required this.raw, this.revision});

  final Map<String, dynamic> raw;
  final String? revision;
}

/// Une version journalisée d'une commande (métadonnées seulement).
class StudioCommandVersion {
  const StudioCommandVersion({
    required this.historyId,
    required this.createdAt,
    this.sizeBytes = 0,
  });

  final String historyId;
  final DateTime? createdAt;
  final int sizeBytes;
}

/// Un message d'une conversation du Copilot (`role` : user, assistant, tool).
class StudioAiEvent {
  const StudioAiEvent({
    required this.id,
    required this.kind,
    required this.payload,
  });

  final int id;
  final String kind;
  final Map<String, dynamic> payload;
}

/// Client de l'API principale, compatible navigateur (aucun `dart:io`).
///
/// Mêmes routes que `MainApiClient` de l'app mobile/desktop. Le Studio est en
/// lecture seule pour l'instant : listes de bots et de commandes, profil, plan.
class StudioApi {
  StudioApi({
    required String baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = _trimSlash(baseUrl),
       _http = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  /// Fourni par le contrôleur d'authentification : rend un jeton valide
  /// (rafraîchi si besoin) ou `null` s'il n'y a plus de session.
  Future<String?> Function({bool force})? accessToken;

  static String _trimSlash(String raw) {
    var s = raw.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  // ── Authentification Discord ──────────────────────────────────────────────

  /// Renvoie l'URL Discord ET l'état que le SERVEUR y a placé : il signe le sien
  /// et ignore celui qu'on lui envoie. C'est cet état-là qui revient au retour
  /// OAuth, donc c'est lui qu'il faut mémoriser pour le comparer.
  Future<({String url, String state})> startDiscordAuthorization({
    required String redirectUri,
    required String state,
  }) async {
    final json = await _send(
      'POST',
      '/auth/discord/start',
      body: {'redirect_uri': redirectUri, 'state': state},
      auth: false,
    );
    final url = _string(json, const [
      'authorization_url',
      'authorizationUrl',
      'authorizeUrl',
      'url',
    ]);
    if (url == null || url.isEmpty) {
      throw const StudioApiException(
        'Bot Creator Server did not return an authorization URL.',
      );
    }
    final serverState =
        _string(json, const ['state']) ??
        Uri.tryParse(url)?.queryParameters['state'] ??
        state;
    return (url: url, state: serverState);
  }

  Future<StudioSession> completeDiscordAuthorization({
    required String code,
    required String state,
    required String redirectUri,
  }) async {
    final json = await _send(
      'POST',
      '/auth/discord/exchange',
      body: {'code': code, 'state': state, 'redirect_uri': redirectUri},
      auth: false,
    );
    return StudioSession.fromAuthPayload(json);
  }

  Future<StudioSession> refreshSession(String refreshToken) async {
    final json = await _send(
      'POST',
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
      auth: false,
    );
    return StudioSession.fromAuthPayload(json);
  }

  /// Valide la session côté serveur. Lève une [StudioApiException] 401/403 si
  /// le jeton n'est plus accepté.
  Future<Map<String, dynamic>> currentUser() async {
    try {
      return await _send('GET', '/auth/me');
    } on StudioApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      // Comme l'app : certains serveurs n'exposent que le résumé du runtime.
      return runtime();
    }
  }

  Future<Map<String, dynamic>> runtime() => _send('GET', '/gateway/runtime');

  /// Formule du compte. Inconnue = gratuite : le Studio ne présume jamais
  /// Premium (contrairement au repli hors ligne desktop de l'app).
  Future<StudioPlan> fetchPlan() async {
    final data = await runtime();
    for (final key in const ['plan', 'account_plan', 'subscription_plan']) {
      final raw = data[key]?.toString().trim().toUpperCase();
      if (raw == 'PREMIUM') return StudioPlan.premium;
      if (raw == 'FREE') return StudioPlan.free;
    }
    return StudioPlan.free;
  }

  // ── Bots et commandes ─────────────────────────────────────────────────────

  Future<List<StudioBot>> listBots() async {
    final json = await _send('GET', '/gateway/bots');
    final raw = json['bots'];
    if (raw is! List) return const [];
    final bots = <StudioBot>[];
    for (final item in raw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final id = _string(map, const ['bot_id', 'id', 'botId']);
      if (id == null || id.isEmpty) continue;
      final runtimeState = _string(map, const ['runtime_state'])?.toLowerCase();
      final desired = _string(map, const ['desired_state'])?.toUpperCase();
      final known = runtimeState != null || desired != null;
      bots.add(
        StudioBot(
          id: id,
          name: _string(map, const ['name', 'bot_name', 'botName']) ?? id,
          // Même règle que l'app (`GatewayBotEventPayload.isRunning`).
          running:
              runtimeState == 'running' ||
              (desired == 'RUNNING' &&
                  runtimeState != 'stopped' &&
                  runtimeState != 'error'),
          stateKnown: known,
        ),
      );
    }
    return bots;
  }

  /// Lance le bot sur les serveurs Bot Creator.
  ///
  /// Un seul POST (le serveur refuse un rejeu pendant qu'un démarrage est en
  /// cours), sauf pour les refus TRANSITOIRES — temps gratuit pas encore
  /// crédité, runner pas encore déployé — réessayés pendant 15 s comme l'app
  /// (`startManagerBotWithCreditRetry`).
  Future<void> startBot(
    String botId, {
    String botName = '',
    Duration retryWindow = const Duration(seconds: 15),
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    final deadline = DateTime.now().add(retryWindow);
    while (true) {
      try {
        await _send(
          'POST',
          '/gateway/bots/${Uri.encodeComponent(botId)}/start',
          body: {
            if (botName.isNotEmpty) 'bot_name': botName,
            if (botName.isNotEmpty) 'botName': botName,
          },
          timeout: const Duration(seconds: 60),
        );
        return;
      } on StudioApiException catch (e) {
        if (!e.isTransientStartRefusal || DateTime.now().isAfter(deadline)) {
          rethrow;
        }
        await Future<void>.delayed(retryDelay);
      }
    }
  }

  Future<void> stopBot(String botId) async {
    await _send(
      'POST',
      '/gateway/bots/${Uri.encodeComponent(botId)}/stop',
      body: const {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<StudioBotRuntime> botRuntime(String botId) async {
    final json = await _send(
      'GET',
      '/gateway/bots/${Uri.encodeComponent(botId)}/runtime',
    );
    int? asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v');
    final expires = _string(json, const [
      'session_expires_at',
      'sessionExpiresAt',
    ]);
    return StudioBotRuntime(
      premiumFunded:
          _string(json, const ['funding_mode', 'fundingMode'])?.toLowerCase() ==
          'premium',
      freeMinutes: asInt(
        json['free_minutes_balance'] ?? json['freeMinutesBalance'],
      ),
      sessionExpiresAt: expires == null
          ? null
          : DateTime.tryParse(expires)?.toLocal(),
      sessionActive: (json['session_active'] ?? json['sessionActive']) == true,
    );
  }

  /// `true` si le bot tourne (`bot.state == running`). Toute erreur = arrêté,
  /// comme dans l'app.
  Future<bool> isRunning(String botId) async {
    try {
      final json = await _send(
        'GET',
        '/gateway/bots/${Uri.encodeComponent(botId)}/status',
      );
      final bot = json['bot'];
      final state = bot is Map ? (bot['state'] ?? '').toString() : '';
      return state.toLowerCase() == 'running';
    } on StudioApiException {
      return false;
    }
  }

  Future<List<StudioCommand>> listCommands(String botId) async {
    final json = await _send(
      'GET',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/commands',
    );
    final raw = json['commands'];
    if (raw is! List) return const [];
    final commands = <StudioCommand>[];
    for (final item in raw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final id = _string(map, const ['id']);
      if (id == null || id.isEmpty) continue;
      commands.add(
        StudioCommand(
          id: id,
          name: _string(map, const ['name']) ?? id,
          trigger: _string(map, const ['trigger']) ?? '',
          card: _listCard(id, map),
        ),
      );
    }
    return commands;
  }

  static Map<String, dynamic> _listCard(String id, Map<String, dynamic> m) {
    int count(String key) => (m[key] as num?)?.toInt() ?? 0;
    return {
      'id': id,
      'name': _string(m, const ['name']) ?? id,
      'description': _string(m, const ['description']) ?? '',
      'type': _string(m, const ['type']) ?? 'chatInput',
      'folder': _string(m, const ['folder']) ?? '',
      'data': {
        // La carte ne compte que : seules les longueurs comptent.
        'options': List.filled(count('option_count'), 0),
        'actions': List.filled(count('action_count'), 0),
        if (count('subcommand_count') > 0)
          'subcommandWorkflows': {
            for (var i = 0; i < count('subcommand_count'); i++) '$i': 0,
          },
        'legacyModeEnabled': m['legacy_mode'] == true,
        'legacyLocalOnly': m['legacy_local'] == true,
        'legacyAliases': m['legacy_aliases'] is List ? m['legacy_aliases'] : [],
      },
    };
  }

  /// `GET /api/v2/bots/{b}/commands/{c}`.
  Future<StudioCommandDetail> getCommand(String botId, String commandId) async {
    final json = await _send(
      'GET',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/commands/${Uri.encodeComponent(commandId)}',
    );
    final command = json['command'];
    if (command is! Map) {
      throw const StudioApiException('Unexpected command response.');
    }
    return StudioCommandDetail(
      raw: Map<String, dynamic>.from(command),
      revision: _string(json, const ['revision']),
    );
  }

  /// `PATCH /api/v2/bots/{b}/commands/{c}` : corps `{"command": <entier>}`,
  /// `If-Match` = révision lue (entre guillemets). Un 409 signale une
  /// révision périmée : quelqu'un d'autre a modifié le bot entre-temps.
  /// Rend la nouvelle révision.
  Future<String?> saveCommand(
    String botId,
    String commandId,
    Map<String, dynamic> raw, {
    String? revision,
  }) async {
    final json = await _send(
      'PATCH',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/commands/${Uri.encodeComponent(commandId)}',
      body: {'command': raw},
      headers: {
        if (revision != null && revision.isNotEmpty) 'if-match': '"$revision"',
      },
      timeout: const Duration(seconds: 60),
    );
    return _string(json, const ['revision']) ?? revision;
  }

  /// Dernières versions journalisées d'une commande, la plus récente d'abord.
  Future<List<StudioCommandVersion>> commandHistory(
    String botId,
    String commandId,
  ) async {
    final json = await _send(
      'GET',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/commands/${Uri.encodeComponent(commandId)}/history',
    );
    final raw = json['versions'];
    if (raw is! List) return const [];
    return [
      for (final v in raw.whereType<Map>())
        StudioCommandVersion(
          historyId: '${v['history_id'] ?? ''}',
          createdAt: DateTime.tryParse('${v['created_at'] ?? ''}'),
          sizeBytes: (v['size_bytes'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  /// Réapplique une version ; le retour arrière est lui-même journalisé.
  Future<String?> restoreCommandVersion(
    String botId,
    String commandId,
    String historyId, {
    String? revision,
  }) async {
    final json = await _send(
      'POST',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/commands/${Uri.encodeComponent(commandId)}/rollback/${Uri.encodeComponent(historyId)}',
      headers: {
        if (revision != null && revision.isNotEmpty) 'if-match': '"$revision"',
      },
      timeout: const Duration(seconds: 60),
    );
    return _string(json, const ['revision']);
  }

  /// Il n'existe pas de DELETE v2 : l'app passe par cette route.
  Future<void> deleteCommand(
    String botId,
    String commandId, {
    String botName = '',
  }) async {
    await _send(
      'POST',
      '/gateway/bots/${Uri.encodeComponent(botId)}/commands/delete',
      body: {'botId': botId, 'botName': botName, 'commandId': commandId},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Dernières lignes du journal du bot (`GET …/logs?limit=`), les plus
  /// anciennes en premier. Le serveur rend `{lines:[…]}` ; une ligne peut être
  /// un texte ou un objet (`message`/`line`/`text`).
  Future<List<String>> botLogs(String botId, {int limit = 200}) async {
    final json = await _send(
      'GET',
      '/gateway/bots/${Uri.encodeComponent(botId)}/logs?limit=$limit',
    );
    final raw = json['lines'] ?? json['logs'] ?? json['data'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          _string(Map<String, dynamic>.from(item), const [
                'message',
                'line',
                'text',
              ]) ??
              jsonEncode(item)
        else
          '$item',
    ];
  }

  /// Usage des commandes sur les [hours] dernières heures.
  Future<CommandStats> commandStats(String botId, int hours) async {
    final json = await _send(
      'GET',
      '/gateway/bots/${Uri.encodeComponent(botId)}/command-stats?hours=$hours',
    );
    return CommandStats.fromJson(json);
  }

  /// URL du canal temps réel (`ws(s)://…/gateway/bots/events`).
  String get eventsUrl =>
      '${baseUrl.replaceFirst(RegExp(r'^http'), 'ws')}/gateway/bots/events';

  /// Jeton valide pour le canal temps réel, ou `null` sans session.
  Future<String?> freshToken() async => accessToken?.call();

  // ── Création d'un bot ─────────────────────────────────────────────────────

  /// Valide un jeton côté serveur (`/users/@me`) : le navigateur n'appelle
  /// jamais Discord avec le jeton. Route publique, comme dans l'app.
  Future<StudioBotIdentity> validateBotToken(String token) async {
    final json = await _send(
      'POST',
      '/gateway/turnkey/validate-token',
      body: {'bot_token': token.trim()},
      auth: false,
    );
    final nested = json['bot'] is Map
        ? Map<String, dynamic>.from(json['bot'] as Map)
        : (json['user'] is Map
              ? Map<String, dynamic>.from(json['user'] as Map)
              : json);
    return StudioBotIdentity(
      id:
          _string(nested, const ['id', 'bot_id', 'application_id']) ??
          _string(json, const ['id', 'bot_id', 'application_id']) ??
          '',
      name:
          _string(nested, const ['username', 'name', 'bot_name']) ??
          _string(json, const ['username', 'name', 'bot_name']) ??
          '',
    );
  }

  /// `POST /gateway/bots/discord/save` : crée (ou met à jour) le bot côté
  /// serveur. Peut durer ~2 min. UN SEUL envoi : un rejeu pendant que le
  /// premier tourne répond `409 bot_sync_in_progress`.
  Future<void> createBot({
    required String botId,
    required String botToken,
    required Map<String, dynamic> config,
  }) => _send(
    'POST',
    '/gateway/bots/discord/save',
    body: {'bot_token': botToken, 'bot_id': botId, 'config': config},
    timeout: const Duration(minutes: 5),
  );

  // ── Variables ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> globalVariables(String botId) async {
    final json = await _send(
      'GET',
      '/gateway/bots/${Uri.encodeComponent(botId)}/variables/global',
    );
    final raw = json['values'] ?? json['variables'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  Future<void> setGlobalVariable(String botId, String key, Object? value) =>
      _send(
        'POST',
        '/gateway/bots/${Uri.encodeComponent(botId)}/variables/global/set',
        body: {'key': key.trim(), 'value': value},
      );

  Future<void> removeGlobalVariable(String botId, String key) => _send(
    'POST',
    '/gateway/bots/${Uri.encodeComponent(botId)}/variables/global/remove',
    body: {'key': key.trim()},
  );

  Future<void> renameGlobalVariable(
    String botId,
    String oldKey,
    String newKey,
  ) => _send(
    'POST',
    '/gateway/bots/${Uri.encodeComponent(botId)}/variables/global/rename',
    body: {'oldKey': oldKey.trim(), 'newKey': newKey.trim()},
  );

  Future<List<StudioScopedDefinition>> scopedDefinitions(String botId) async {
    final json = await _send(
      'GET',
      '/gateway/bots/${Uri.encodeComponent(botId)}/variables/scoped-definitions',
    );
    final raw = json['definitions'];
    if (raw is! List) return const [];
    return [
      for (final item in raw.whereType<Map>())
        StudioScopedDefinition(
          key: '${item['key'] ?? ''}',
          scope: '${item['scope'] ?? ''}',
          valueType: '${item['valueType'] ?? item['value_type'] ?? 'string'}',
          defaultValue: item['defaultValue'] ?? item['default_value'],
        ),
    ];
  }

  /// Définit (ou met à jour) la valeur par défaut d'une variable à portée.
  Future<void> setScopedDefinition(
    String botId, {
    required String key,
    required String scope,
    Object? defaultValue,
  }) => _send(
    'POST',
    '/gateway/bots/${Uri.encodeComponent(botId)}/variables/scoped-definitions/set',
    body: {'key': key.trim(), 'scope': scope, 'defaultValue': defaultValue},
  );

  Future<void> removeScopedDefinition(
    String botId,
    String key, {
    String? scope,
    bool purgeStoredValues = false,
  }) => _send(
    'POST',
    '/gateway/bots/${Uri.encodeComponent(botId)}/variables/scoped-definitions/remove',
    body: {
      'key': key.trim(),
      if (scope != null && scope.isNotEmpty) 'scope': scope,
      if (purgeStoredValues) 'purgeStoredValues': true,
    },
  );

  // ── Workflows ─────────────────────────────────────────────────────────────

  Future<List<StudioWorkflowSummary>> listWorkflows(String botId) async {
    final json = await _send(
      'GET',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/workflows',
    );
    final raw = json['workflows'];
    if (raw is! List) return const [];
    return [
      for (final item in raw.whereType<Map>())
        if ('${item['name'] ?? ''}'.isNotEmpty)
          StudioWorkflowSummary(
            name: '${item['name']}',
            type: '${item['workflow_type'] ?? 'general'}',
            executionMode: '${item['execution_mode'] ?? 'workflow'}',
            actionCount: (item['action_count'] as num?)?.toInt() ?? 0,
            folder: '${item['folder'] ?? ''}',
            entryPoint: '${item['entry_point'] ?? 'main'}',
            argumentCount: (item['argument_count'] as num?)?.toInt() ?? 0,
            event: '${item['event'] ?? ''}',
          ),
    ];
  }

  // ── Déclencheurs planifiés ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listScheduledTriggers(String botId) async {
    final json = await _send(
      'GET',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/scheduled-triggers',
    );
    final raw = json['triggers'];
    return raw is List
        ? [for (final t in raw.whereType<Map>()) Map<String, dynamic>.from(t)]
        : const [];
  }

  Future<void> saveScheduledTrigger(
    String botId,
    String triggerId,
    Map<String, dynamic> trigger,
  ) => _send(
    'PUT',
    '/api/v2/bots/${Uri.encodeComponent(botId)}/scheduled-triggers/${Uri.encodeComponent(triggerId)}',
    body: trigger,
  );

  Future<void> deleteScheduledTrigger(String botId, String triggerId) => _send(
    'DELETE',
    '/api/v2/bots/${Uri.encodeComponent(botId)}/scheduled-triggers/${Uri.encodeComponent(triggerId)}',
  );

  // ── Webhooks entrants (secret en écriture seule) ──────────────────────────

  Future<List<Map<String, dynamic>>> listInboundWebhooks(String botId) async {
    final json = await _send(
      'GET',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/inbound-webhooks',
    );
    final raw = json['webhooks'];
    return raw is List
        ? [for (final w in raw.whereType<Map>()) Map<String, dynamic>.from(w)]
        : const [];
  }

  /// Enregistre un webhook ; rend le secret généré par le serveur, le cas
  /// échéant (il n'est montré qu'une fois).
  Future<String?> saveInboundWebhook(
    String botId,
    String webhookId,
    Map<String, dynamic> webhook,
  ) async {
    final json = await _send(
      'PUT',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/inbound-webhooks/${Uri.encodeComponent(webhookId)}',
      body: webhook,
    );
    final generated = json['generated_secret'];
    return generated is String && generated.isNotEmpty ? generated : null;
  }

  Future<void> deleteInboundWebhook(String botId, String webhookId) => _send(
    'DELETE',
    '/api/v2/bots/${Uri.encodeComponent(botId)}/inbound-webhooks/${Uri.encodeComponent(webhookId)}',
  );

  Future<StudioWorkflowDetail> getWorkflow(String botId, String name) async {
    final json = await _send(
      'GET',
      '/api/v2/bots/${Uri.encodeComponent(botId)}/workflows/${Uri.encodeComponent(name)}',
    );
    final workflow = json['workflow'];
    if (workflow is! Map) {
      throw const StudioApiException('Unexpected workflow response.');
    }
    return StudioWorkflowDetail(
      raw: Map<String, dynamic>.from(workflow),
      revision: _string(json, const ['revision']),
    );
  }

  /// Crée ou remplace un workflow (la clé de fusion est son nom).
  Future<void> saveWorkflow(
    String botId,
    String botName,
    Map<String, dynamic> workflow,
  ) async {
    final name = '${workflow['name'] ?? ''}'.trim();
    await _send(
      'POST',
      '/gateway/bots/${Uri.encodeComponent(botId)}/workflows/sync',
      body: {
        'botId': botId,
        'botName': botName,
        'workflowName': name,
        'workflow': workflow,
      },
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> deleteWorkflow(String botId, String botName, String name) =>
      _send(
        'POST',
        '/gateway/bots/${Uri.encodeComponent(botId)}/workflows/delete',
        body: {'botId': botId, 'botName': botName, 'workflowName': name},
        timeout: const Duration(seconds: 60),
      );

  // ── IA (Copilot) ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> aiWallet() => _send('GET', '/gateway/ai/wallet');

  Future<List<Map<String, dynamic>>> aiConversations({
    String? botId,
    int offset = 0,
  }) async {
    final query = Uri(
      queryParameters: {
        if (botId != null && botId.isNotEmpty) 'bot_id': botId,
        'archived': 'false',
        'offset': '$offset',
      },
    ).query;
    final json = await _send('GET', '/gateway/ai/conversations?$query');
    final raw = json['conversations'] ?? json['items'];
    if (raw is! List) return const [];
    return [
      for (final item in raw.whereType<Map>()) Map<String, dynamic>.from(item),
    ];
  }

  Future<Map<String, dynamic>> createAiConversation({
    String? botId,
    String? title,
  }) => _send(
    'POST',
    '/gateway/ai/conversations',
    body: {
      'bot_id': botId ?? '',
      'location': botId == null || botId.isEmpty ? 'global' : 'bot',
      'title': title ?? 'Nouvelle discussion',
    },
  );

  Future<Map<String, dynamic>> aiConversation(String id) =>
      _send('GET', '/gateway/ai/conversations/${Uri.encodeComponent(id)}');

  Future<void> deleteAiConversation(String id) =>
      _send('DELETE', '/gateway/ai/conversations/${Uri.encodeComponent(id)}');

  /// Démarre un tour : `{idempotency_key, revision, prompt, tools}`. Un rejeu
  /// avec la même clé est sans effet, comme dans l'app.
  Future<Map<String, dynamic>> startAiTurn(
    String id,
    Map<String, dynamic> request,
  ) => _send(
    'POST',
    '/gateway/ai/conversations/${Uri.encodeComponent(id)}/turns',
    body: request,
    timeout: const Duration(seconds: 60),
  );

  Future<Map<String, dynamic>> aiAction(
    String id,
    String callId,
    Map<String, dynamic> request,
  ) => _send(
    'POST',
    '/gateway/ai/conversations/${Uri.encodeComponent(id)}/actions/${Uri.encodeComponent(callId)}',
    body: request,
    timeout: const Duration(seconds: 60),
  );

  Future<Map<String, dynamic>> continueAiConversation(String id, String key) =>
      _send(
        'POST',
        '/gateway/ai/conversations/${Uri.encodeComponent(id)}/continue',
        body: {'idempotency_key': key},
      );

  /// Événements d'une génération (`delta`, `completed`, `error`…). Le
  /// navigateur ne rend pas la réponse au fil de l'eau avec ce client : on
  /// reçoit tout le flux une fois la génération terminée (ou au bout de 100 s).
  Future<List<StudioAiEvent>> aiEvents(
    String id,
    String key, {
    int after = 0,
  }) async {
    final token = await accessToken?.call();
    if (token == null || token.isEmpty) {
      throw const StudioApiException('Not signed in.', statusCode: 401);
    }
    final uri = Uri.parse(
      '$baseUrl/gateway/ai/conversations/${Uri.encodeComponent(id)}/requests/${Uri.encodeComponent(key)}/events?after=$after',
    );
    final http.Response response;
    try {
      response = await _http
          .get(
            uri,
            headers: {
              'authorization': 'Bearer $token',
              'accept': 'text/event-stream',
            },
          )
          .timeout(const Duration(seconds: 100));
    } on TimeoutException {
      throw const StudioApiException('Stream interrupted');
    } catch (e) {
      throw StudioApiException('Cannot reach Bot Creator Server: $e');
    }
    if (response.statusCode != 200) {
      throw StudioApiException(
        'Stream unavailable',
        statusCode: response.statusCode,
      );
    }
    return parseSse(utf8.decode(response.bodyBytes));
  }

  /// Découpe un flux `text/event-stream` en événements (public pour les tests).
  static List<StudioAiEvent> parseSse(String body) {
    final events = <StudioAiEvent>[];
    var kind = '';
    var data = '';
    var id = 0;
    void flush() {
      if (data.isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          events.add(
            StudioAiEvent(
              id: id,
              kind: kind,
              payload: decoded is Map
                  ? Map<String, dynamic>.from(decoded)
                  : <String, dynamic>{},
            ),
          );
        } catch (_) {}
      }
      kind = '';
      data = '';
    }

    for (final line in const LineSplitter().convert(body)) {
      if (line.isEmpty) {
        flush();
      } else if (line.startsWith('event:')) {
        kind = line.substring(6).trim();
      } else if (line.startsWith('id:')) {
        id = int.tryParse(line.substring(3).trim()) ?? 0;
      } else if (line.startsWith('data:')) {
        data += line.substring(5).trim();
      }
    }
    flush();
    return events;
  }

  // ── Équipe ────────────────────────────────────────────────────────────────

  Future<StudioTeam> team(String botId) async {
    final json = await _send(
      'GET',
      '/gateway/bots/${Uri.encodeComponent(botId)}/team/collaborators',
    );
    Map<String, bool> perms(Object? raw) => raw is Map
        ? {for (final e in raw.entries) '${e.key}': e.value == true}
        : const {};
    final raw = json['collaborators'];
    return StudioTeam(
      collaborators: [
        if (raw is List)
          for (final item in raw.whereType<Map>())
            StudioCollaborator(
              userId: '${item['user_id'] ?? ''}',
              displayName: '${item['display_name'] ?? ''}',
              role: '${item['role'] ?? 'collaborator'}',
              isOwner: item['is_owner'] == true,
              permissions: perms(item['permissions']),
            ),
      ],
      mine: perms(json['my_permissions']),
    );
  }

  Future<void> removeCollaborator(String botId, String userId) => _send(
    'DELETE',
    '/gateway/bots/${Uri.encodeComponent(botId)}/team/collaborators/${Uri.encodeComponent(userId)}',
  );

  /// Du plus récent au plus ancien (comme le serveur).
  Future<List<StudioChatMessage>> teamChat(
    String botId, {
    int limit = 50,
  }) async {
    final json = await _send(
      'GET',
      '/gateway/bots/${Uri.encodeComponent(botId)}/team/chat?limit=$limit',
    );
    final raw = json['messages'];
    if (raw is! List) return const [];
    return [
      for (final item in raw.whereType<Map>())
        StudioChatMessage(
          id: int.tryParse('${item['id']}') ?? 0,
          author:
              '${item['author_display_name'] ?? item['author_user_id'] ?? ''}',
          content: '${item['content'] ?? ''}',
          createdAt:
              DateTime.tryParse('${item['created_at'] ?? ''}')?.toLocal() ??
              DateTime.fromMillisecondsSinceEpoch(0),
        ),
    ];
  }

  Future<void> sendTeamChat(String botId, String content) => _send(
    'POST',
    '/gateway/bots/${Uri.encodeComponent(botId)}/team/chat',
    body: {'content': content},
  );

  // ── Transport ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    bool retried = false,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    String? token;
    if (auth) {
      token = await accessToken?.call(force: retried);
      if (token == null || token.isEmpty) {
        throw const StudioApiException('Not signed in.', statusCode: 401);
      }
    }
    final uri = Uri.parse('$baseUrl$path');
    final allHeaders = <String, String>{
      if (body != null) 'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
      ...?headers,
    };
    final http.Response response;
    try {
      final encoded = body == null ? null : jsonEncode(body);
      final request = switch (method) {
        'GET' => _http.get(uri, headers: allHeaders),
        'PUT' => _http.put(uri, headers: allHeaders, body: encoded),
        'PATCH' => _http.patch(uri, headers: allHeaders, body: encoded),
        'DELETE' => _http.delete(uri, headers: allHeaders),
        _ => _http.post(uri, headers: allHeaders, body: encoded),
      };
      response = await request.timeout(timeout ?? this.timeout);
    } on TimeoutException {
      throw const StudioApiException('Bot Creator Server did not respond.');
    } catch (e) {
      throw StudioApiException('Cannot reach Bot Creator Server: $e');
    }
    try {
      return _parse(response);
    } on StudioApiException catch (e) {
      if (auth && !retried && e.isUnauthorized) {
        return _send(
          method,
          path,
          body: body,
          auth: auth,
          retried: true,
          timeout: timeout,
          headers: headers,
        );
      }
      rethrow;
    }
  }

  Map<String, dynamic> _parse(http.Response response) {
    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = null;
      }
    }
    final map = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) return map;
    final message =
        _string(map, const ['message', 'error', 'detail']) ?? 'Request failed';
    throw StudioApiException(
      message,
      statusCode: response.statusCode,
      code: _string(map, const ['code']),
    );
  }

  void close() => _http.close();
}

String? _string(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final s = value.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}

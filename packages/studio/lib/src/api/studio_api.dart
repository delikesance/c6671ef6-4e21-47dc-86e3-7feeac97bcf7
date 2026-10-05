import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/studio_session.dart';

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
  });

  final String id;
  final String name;
  final String trigger;
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

  Future<String> startDiscordAuthorization({
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
    return url;
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
        ),
      );
    }
    return commands;
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

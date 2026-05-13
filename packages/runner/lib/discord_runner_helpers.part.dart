part of 'discord_runner.dart';

extension DiscordRunnerHelpersExtension on DiscordRunner {
  void _injectGatewayBotVariables(Map<String, String> variables) {
    // Keep a deterministic fallback so ((bot.ping)) never resolves to empty.
    variables['bot.ping'] = '0';
    variables['ping'] = '0';
    if (_gateway == null) return;
    try {
      final latencyMs = _gateway!.gateway.latency.inMilliseconds;
      final ping = latencyMs < 0 ? '0' : latencyMs.toString();
      variables['bot.ping'] = ping;
      variables['ping'] = ping;
    } catch (_) {}
    try {
      variables['bot.shardId'] = _gateway!.gateway.shardIds.join(',');
    } catch (_) {}
    if (_startedAt != null) {
      variables['bot.uptime'] =
          DateTime.now().difference(_startedAt!).inSeconds.toString();
    }

    // ── Bot info variables (always resolved) ──
    variables['bot.ownerId'] = _cachedApplicationOwnerId ?? '';
    variables['bot.commands'] = config.commands.length.toString();
    variables['bot.commandsCount'] = config.commands.length.toString();
    variables['bot.slashCommandsCount'] = config.commands.length.toString();
    variables['bot.nodeVersion'] = 'Dart ${Platform.version.split(' ').first}';
    // execution.time is injected by handleActions via its execution stopwatch.
    if (!variables.containsKey('execution.time')) {
      variables['execution.time'] = '0ms';
    }
  }

  bool _sameIntents(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if ((b[entry.key] ?? false) != entry.value) {
        return false;
      }
    }
    return true;
  }

  Flags<GatewayIntents> _buildIntentsFromKeys(Set<String> keys) {
    if (keys.isEmpty) return GatewayIntents.allUnprivileged;

    Flags<GatewayIntents> intents = GatewayIntents.none;
    for (final key in keys) {
      final flag = DiscordRunner._intentKeyToGateway[key];
      if (flag != null) {
        intents = intents | flag;
      }
    }

    return intents == GatewayIntents.none
        ? GatewayIntents.allUnprivileged
        : intents;
  }

  /// Queries the Discord API to determine which privileged gateway intents
  /// have been approved for this application.
  Future<Set<String>> _fetchApprovedPrivilegedIntents(String token) async {
    final approved = <String>{};
    try {
      final rest = await Nyxx.connectRest(token);
      try {
        final app = await rest.applications.fetchCurrentApplication();
        if (app.flags.has(ApplicationFlags.gatewayGuildMembers) ||
            app.flags.has(ApplicationFlags.gatewayGuildMembersLimited)) {
          approved.add('Guild Members');
        }
        if (app.flags.has(ApplicationFlags.gatewayPresence) ||
            app.flags.has(ApplicationFlags.gatewayPresenceLimited)) {
          approved.add('Guild Presence');
        }
        if (app.flags.has(ApplicationFlags.gatewayMessageContent) ||
            app.flags.has(ApplicationFlags.gatewayMessageContentLimited)) {
          approved.add('Message Content');
        }
      } finally {
        await rest.close();
      }
    } catch (e, st) {
      _log.warning(
        'Failed to fetch approved privileged intents from Discord API; '
        'assuming only unprivileged intents are available. Error: $e',
        e,
        st,
      );
    }
    return approved;
  }

  String _formatRunnerBdfdDiagnostics(List<BdfdCompileDiagnostic> diagnostics) {
    if (diagnostics.isEmpty) {
      return 'This BDFD script could not be compiled.';
    }

    final summary = diagnostics
        .take(5)
        .map((diagnostic) {
          final location =
              (diagnostic.line != null && diagnostic.column != null)
                  ? 'L${diagnostic.line}:C${diagnostic.column} '
                  : '';
          return '- $location${diagnostic.message}';
        })
        .join('\n');
    return 'This BDFD script could not be compiled:\n$summary';
  }

  Map<String, dynamic> _adaptLegacyActionForMessageCreate(
    Map<String, dynamic> actionJson,
    EventExecutionContext context,
  ) {
    final adapted = Map<String, dynamic>.from(actionJson);
    final type = (adapted['type'] ?? '').toString();

    if (type == BotCreatorActionType.respondWithMessage.name) {
      adapted['type'] = BotCreatorActionType.sendMessage.name;
      final payload = Map<String, dynamic>.from(
        (adapted['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      payload['channelId'] =
          (payload['channelId'] ?? '').toString().trim().isNotEmpty
              ? payload['channelId']
              : context.channelId?.toString();
      adapted['payload'] = payload;
      return adapted;
    }

    if (type == BotCreatorActionType.respondWithComponentV2.name) {
      adapted['type'] = BotCreatorActionType.sendComponentV2.name;
      final payload = Map<String, dynamic>.from(
        (adapted['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      payload['channelId'] =
          (payload['channelId'] ?? '').toString().trim().isNotEmpty
              ? payload['channelId']
              : context.channelId?.toString();
      adapted['payload'] = payload;
      return adapted;
    }

    final payload = (adapted['payload'] as Map?)?.cast<String, dynamic>();
    if (payload != null) {
      adapted['payload'] = _adaptLegacyValueForMessageCreate(
        Map<String, dynamic>.from(payload),
        context,
      );
    }

    return adapted;
  }

  dynamic _adaptLegacyValueForMessageCreate(
    dynamic raw,
    EventExecutionContext context,
  ) {
    if (raw is List) {
      return raw
          .map((entry) => _adaptLegacyValueForMessageCreate(entry, context))
          .toList(growable: false);
    }

    if (raw is Map) {
      final normalized = Map<String, dynamic>.from(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (normalized.containsKey('type')) {
        return _adaptLegacyActionForMessageCreate(normalized, context);
      }
      return normalized.map(
        (key, value) =>
            MapEntry(key, _adaptLegacyValueForMessageCreate(value, context)),
      );
    }

    return raw;
  }

  Future<void> _hydratePlaceholdersWithContexts({
    required List<Action> actions,
    required Map<String, String> variables,
    required String botId,
  }) async {
    await hydrateActionPlaceholders(
      store: store,
      botId: botId,
      actions: actions,
      variables: variables,
    );
  }
}

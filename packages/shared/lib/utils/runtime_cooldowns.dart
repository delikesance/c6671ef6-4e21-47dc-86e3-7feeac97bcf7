import 'dart:convert';

/// Shared runtime state used by cooldown actions and template reads.
class RuntimeCooldowns {
  static final expirations = <String, int>{};
  static String normalizeScope(String scope) => switch (scope.toLowerCase()) {
    'normal' || 'user' => 'user',
    'server' || 'guild' => 'guild',
    'global' => 'global',
    _ => throw FormatException('Unknown cooldown scope: $scope'),
  };
  static String key(
    String botId,
    String scope,
    String variable,
    Map<String, String> vars,
  ) {
    final normalized = normalizeScope(scope);
    final user = vars['user.id'] ?? vars['author.id'] ?? vars['userId'] ?? '';
    final guild = vars['guild.id'] ?? vars['guildId'] ?? '';
    final command =
        vars['commandId'] ??
        vars['command.id'] ??
        vars['commandName'] ??
        vars['workflow.name'] ??
        '';
    return jsonEncode([
      botId.isEmpty ? (vars['bot.id'] ?? '') : botId,
      normalized,
      variable,
      command,
      if (normalized == 'user') user,
      if (normalized != 'global') guild,
    ]);
  }

  static String defaultVariable(String scope) =>
      switch (normalizeScope(scope)) {
        'user' => 'user_cooldown',
        'guild' => 'guild_servercooldown',
        _ => 'global_globalcooldown',
      };
  static int remainingMs(String key) {
    final end = expirations[key];
    if (end == null) return 0;
    final remaining = end - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      expirations.remove(key);
      return 0;
    }
    return remaining;
  }

  static void select(
    Map<String, String> vars,
    String scope,
    String variable, {
    String? botId,
  }) {
    if (botId != null) vars['cooldown.botId'] = botId;
    vars['cooldown.type'] = normalizeScope(scope);
    vars['cooldown.key.${normalizeScope(scope)}'] = variable;
  }

  static String query(Map<String, String> vars, [String? requestedScope]) {
    final scope = requestedScope == null || requestedScope.isEmpty
        ? vars['cooldown.type']
        : normalizeScope(requestedScope);
    if (scope == null) return '0';
    final variable = vars['cooldown.key.$scope'] ?? defaultVariable(scope);
    final milliseconds = remainingMs(
      key(
        vars['cooldown.botId'] ?? vars['bot.id'] ?? vars['botId'] ?? '',
        scope,
        variable,
        vars,
      ),
    );
    final seconds = milliseconds / 1000;
    return seconds == seconds.toInt()
        ? seconds.toInt().toString()
        : seconds.toString();
  }
}

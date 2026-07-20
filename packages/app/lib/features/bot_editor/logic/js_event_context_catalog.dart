/// Catalog of globals / example property paths injected into JS event scripts.
///
/// Mirrors what `runner-js` binds via [ScriptExecutionContext] and
/// `resolveEventExecutionContext` (first event argument only).
class JsEventContextCatalog {
  JsEventContextCatalog._();

  /// Globals always present in every JS script execution.
  static const List<String> alwaysAvailable = <String>[
    'client',
    'variables',
    'db',
    'console',
    'fetch',
  ];

  /// Read-only context items for [eventName] (discord.js event camelCase).
  ///
  /// Includes always-available globals plus event-specific bindings and a few
  /// realistic property examples users can copy into their script.
  static List<String> itemsForEvent(String eventName) {
    final event = eventName.trim();
    final specific = _specificForEvent(event);
    final seen = <String>{};
    final out = <String>[];
    for (final item in [...alwaysAvailable, ...specific]) {
      if (seen.add(item)) {
        out.add(item);
      }
    }
    return out;
  }

  /// True when the runner may only bind sparse/no event objects for [eventName]
  /// because `args[0]` is not Message / Interaction / GuildMember / Channel / Guild.
  static bool hasSparseBinding(String eventName) {
    final event = eventName.trim();
    if (event.isEmpty) return true;
    return _specificForEvent(event) == _fallbackSparse;
  }

  static List<String> _specificForEvent(String event) {
    if (event == 'interactionCreate') {
      return const <String>[
        'interaction',
        'interaction.commandName',
        'interaction.customId',
        'guild',
        'channel',
        'member',
      ];
    }

    if (_messageEvents.contains(event)) {
      return const <String>[
        'message',
        'message.content',
        'message.author.username',
        'message.author.id',
        'guild',
        'channel',
        'member',
      ];
    }

    if (_memberEvents.contains(event)) {
      return const <String>[
        'member',
        'member.id',
        'member.user.username',
        'member.displayName',
        'guild',
      ];
    }

    if (_channelEvents.contains(event)) {
      return const <String>[
        'channel',
        'channel.id',
        'channel.name',
        'guild',
      ];
    }

    if (_guildEvents.contains(event)) {
      return const <String>[
        'guild',
        'guild.id',
        'guild.name',
        'guild.memberCount',
      ];
    }

    // Events whose first discord.js argument is not one of the typed hosts
    // (e.g. VoiceState, MessageReaction, Invite, Role, presence, …).
    return _fallbackSparse;
  }

  static const List<String> _fallbackSparse = <String>[
    // Only always-available globals; event objects may be unbound.
  ];

  static const Set<String> _messageEvents = <String>{
    'messageCreate',
    'messageUpdate',
    'messageDelete',
  };

  static const Set<String> _memberEvents = <String>{
    'guildMemberAdd',
    'guildMemberRemove',
    'guildMemberUpdate',
  };

  static const Set<String> _channelEvents = <String>{
    'channelCreate',
    'channelUpdate',
    'channelDelete',
    'threadCreate',
    'threadUpdate',
    'threadDelete',
  };

  static const Set<String> _guildEvents = <String>{
    'guildCreate',
    'guildUpdate',
    'guildDelete',
  };
}

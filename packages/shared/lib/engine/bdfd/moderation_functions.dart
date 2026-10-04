import '../../services/bot_moderation_service.dart';
import '../../services/bot_role_query_service.dart';
import '../../services/command_input.dart';
import '../../utils/bdfd_duration_parser.dart';
import 'program.dart';
import 'runtime.dart';

/// Native signatures; evaluated arguments are never converted into Actions.
Map<String, BdfdNativeFunction> bdfdModerationFunctions(
  BotModerationService service,
) {
  Future<String> submit(
    BdfdInvocation call,
    BotModerationRequest request,
  ) async {
    await call.context.budget.run(
      () => service.moderate(request, budget: call.context.budget),
    );
    return '';
  }

  Future<String> perform(
    BdfdInvocation call,
    BotModerationOperation operation,
    String target,
    String reason, {
    String? kickPermissionActorId,
  }) async {
    final userId = target.trim();
    final parsed = int.tryParse(userId);
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Missing or invalid user ID.', call.location);
    }
    if (kickPermissionActorId != null) {
      final actor = int.tryParse(kickPermissionActorId.trim());
      if (actor == null || actor <= 0) {
        throw BdfdNativeError(
          'A valid command author ID is required.',
          call.location,
        );
      }
    }
    if (reason.length > 512) {
      throw BdfdNativeError(
        'Reason must not exceed 512 characters.',
        call.location,
      );
    }
    return submit(
      call,
      BotModerationRequest(
        operation: operation,
        userId: userId,
        reason: reason,
        useDefaultReason: false,
        kickPermissionActorId: kickPermissionActorId,
      ),
    );
  }

  Future<String> timeout(BdfdInvocation call, bool remove) async {
    final duration = remove
        ? Duration.zero
        : parseBdfdDuration(await call.argument(0));
    if (!remove &&
        (duration == null ||
            duration <= Duration.zero ||
            duration > const Duration(days: 28))) {
      throw BdfdNativeError(
        'Timeout duration must be positive and at most 28 days.',
        call.location,
      );
    }
    final targetIndex = remove ? 0 : 1;
    final explicitId = call.argumentCount > targetIndex
        ? (await call.argument(targetIndex)).trim()
        : '';
    final targets = explicitId.isNotEmpty
        ? [explicitId]
        : CommandInput(call.context.variables).userMentions;
    final unique = <String>{};
    for (final target in targets) {
      final id = int.tryParse(target.trim());
      if (id == null || id <= 0) {
        throw BdfdNativeError('Missing or invalid user ID.', call.location);
      }
      unique.add(id.toString());
    }
    if (unique.isEmpty) {
      throw BdfdNativeError(
        'A user ID or user mention is required.',
        call.location,
      );
    }
    for (final target in unique) {
      await submit(
        call,
        BotModerationRequest(
          operation: remove
              ? BotModerationOperation.untimeout
              : BotModerationOperation.timeout,
          userId: target,
          duration: duration ?? Duration.zero,
          clampTimeout: false,
          useDefaultReason: false,
        ),
      );
    }
    return '';
  }

  Future<String> query(
    BdfdInvocation call,
    BotModerationOperation operation,
    String user,
    String guild,
  ) async {
    final parsed = int.tryParse(user.trim());
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Invalid user ID.', call.location);
    }
    final guildId = guild.trim();
    if (guildId.isNotEmpty && (int.tryParse(guildId) ?? 0) <= 0) {
      throw BdfdNativeError('Invalid guild ID.', call.location);
    }
    return call.context.budget.run(
      () => service.moderate(
        BotModerationRequest(
          operation: operation,
          userId: '$parsed',
          targetGuildId: guildId,
          useDefaultReason: false,
        ),
        budget: call.context.budget,
      ),
    );
  }

  Future<String> guildCommands(BdfdInvocation call, bool register) async {
    final targetGuild = call.argumentCount > 0
        ? (await call.argument(0)).trim()
        : '';
    if (targetGuild.isNotEmpty && (int.tryParse(targetGuild) ?? 0) <= 0) {
      throw BdfdNativeError('Invalid guild ID.', call.location);
    }
    return submit(
      call,
      BotModerationRequest(
        operation: register
            ? BotModerationOperation.registerGuildCommands
            : BotModerationOperation.unregisterGuildCommands,
        userId: '',
        targetGuildId: targetGuild,
        useDefaultReason: false,
      ),
    );
  }

  // Deprecated wiki behavior: $mute[role name] grants the named role to the
  // mentioned user, and $unmute[role name] removes it.
  Future<String> muteRole(BdfdInvocation call, bool add) async {
    final name = await call.argument(0);
    final mentions = CommandInput(call.context.variables).userMentions;
    final users = <String>{};
    for (final raw in mentions) {
      final parsed = int.tryParse(raw.trim());
      if (parsed == null || parsed <= 0) {
        throw BdfdNativeError('Missing or invalid user ID.', call.location);
      }
      users.add('$parsed');
    }
    if (users.isEmpty) {
      throw BdfdNativeError(
        'A user ID or user mention is required.',
        call.location,
      );
    }
    final roles = service is BotRoleQueryService
        ? await call.context.budget.run(
            () => (service as BotRoleQueryService).roles(
              budget: call.context.budget,
            ),
          )
        : throw BdfdNativeError(
            'Role lookup is not available.',
            call.location,
          );
    final matches = roles.where((role) => role.name == name).toList();
    if (matches.isEmpty) {
      throw BdfdNativeError('Role not found: $name.', call.location);
    }
    for (final user in users) {
      await call.context.budget.run(
        () => service.moderate(
          BotModerationRequest(
            operation: add
                ? BotModerationOperation.addRole
                : BotModerationOperation.removeRole,
            userId: user,
            roleId: matches.first.id,
            useDefaultReason: false,
          ),
          budget: call.context.budget,
        ),
      );
    }
    return '';
  }

  return {
    'kickmention': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async => perform(
        call,
        BotModerationOperation.kick,
        CommandInput(call.context.variables).userMentions.firstOrNull ?? '',
        await call.argument(0),
        kickPermissionActorId:
            call.context.variables['author.id'] ??
            call.context.variables['user.id'] ??
            '',
      ),
    ),
    'timeout': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) => timeout(call, false),
    ),
    'untimeout': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) => timeout(call, true),
    ),
    'unban': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        final username = CommandInput(call.context.variables).text.trim();
        if (username.isEmpty) {
          throw BdfdNativeError(
            'A banned username is required.',
            call.location,
          );
        }
        return submit(
          call,
          BotModerationRequest(
            operation: BotModerationOperation.unban,
            userId: '',
            username: username,
            useDefaultReason: false,
          ),
        );
      },
    ),
    'unbanid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async => perform(
        call,
        BotModerationOperation.unban,
        call.argumentCount == 0
            ? CommandInput(call.context.variables).at('>')
            : await call.argument(0),
        '',
      ),
    ),
    'kick': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 2,
      handler: (call) async => perform(
        call,
        BotModerationOperation.kick,
        call.argumentCount == 0
            ? call.context.variables['author.id'] ??
                  call.context.variables['user.id'] ??
                  ''
            : await call.argument(0),
        call.argumentCount > 1 ? await call.argument(1) : '',
      ),
    ),
    'ban': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final variables = call.context.variables;
        // No author fallback: an absent mention is an invalid target.
        final encoded = variables['message.mentions'];
        final target = encoded == null
            ? variables['message.mentions[0]'] ?? ''
            : encoded.split(',').where((id) => id.isNotEmpty).firstOrNull ?? '';
        return perform(
          call,
          BotModerationOperation.ban,
          target,
          call.argumentCount > 0 ? await call.argument(0) : '',
        );
      },
    ),
    'banid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 2,
      handler: (call) async {
        final reason = call.argumentCount > 0 ? await call.argument(0) : '';
        var target = call.argumentCount > 1 ? await call.argument(1) : '';
        if (target.trim().isEmpty) {
          target = CommandInput(call.context.variables).at('>');
        }
        return perform(call, BotModerationOperation.ban, target, reason);
      },
    ),
    'getbanreason': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async => query(
        call,
        BotModerationOperation.banReason,
        await call.argument(0),
        call.argumentCount > 1 ? await call.argument(1) : '',
      ),
    ),
    'isbanned': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async => query(
        call,
        BotModerationOperation.isBanned,
        await call.argument(0),
        '',
      ),
    ),
    'mute': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async => muteRole(call, true),
    ),
    'unmute': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async => muteRole(call, false),
    ),
    'clear': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 3,
      handler: (call) async {
        final input = CommandInput(call.context.variables);
        final rawCount = call.argumentCount == 0
            ? input.at('1')
            : await call.argument(0);
        final count = int.tryParse(rawCount.trim());
        if (count == null || count < 1 || count > 100) {
          throw BdfdNativeError(
            r'$clear amount must be between 1 and 100.',
            call.location,
          );
        }
        final only = call.argumentCount > 1
            ? (await call.argument(1)).trim()
            : '';
        if (only.isNotEmpty && (int.tryParse(only) ?? 0) <= 0) {
          throw BdfdNativeError('Invalid user ID.', call.location);
        }
        final pinned = call.argumentCount > 2
            ? (await call.argument(2)).trim().toLowerCase()
            : '';
        final removePinned = !{'no', 'false', '0', 'n'}.contains(pinned);
        final channel = call.context.variables['channel.id'] ?? '';
        if ((int.tryParse(channel) ?? 0) <= 0) {
          throw BdfdNativeError('A channel ID is required.', call.location);
        }
        return submit(
          call,
          BotModerationRequest(
            operation: BotModerationOperation.clearMessages,
            userId: '',
            count: count,
            onlyUserId: only,
            removePinned: removePinned,
            channelId: channel,
            useDefaultReason: false,
          ),
        );
      },
    ),
    'registerguildcommands': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async => guildCommands(call, true),
    ),
    'unregisterguildcommands': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async => guildCommands(call, false),
    ),
    'setnickname': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final nickname = await call.argument(0);
        final user = call.argumentCount > 1
            ? (await call.argument(1)).trim()
            : (call.context.variables['author.id'] ??
                  call.context.variables['user.id'] ??
                  '');
        if ((int.tryParse(user.trim()) ?? 0) <= 0) {
          throw BdfdNativeError('Missing or invalid user ID.', call.location);
        }
        if (nickname.length > 32) {
          throw BdfdNativeError(
            'Nickname must not exceed 32 characters.',
            call.location,
          );
        }
        return submit(
          call,
          BotModerationRequest(
            operation: BotModerationOperation.setNickname,
            userId: user.trim(),
            nickname: nickname,
            useDefaultReason: false,
          ),
        );
      },
    ),
  };
}

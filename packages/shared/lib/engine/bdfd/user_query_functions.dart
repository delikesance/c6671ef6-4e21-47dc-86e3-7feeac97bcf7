import '../../services/bot_user_query_service.dart';
import '../../services/go_time_format.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdUserQueryFunctions(
  BotUserQueryService service,
) {
  String id(BdfdInvocation call, String raw) {
    final value = raw.trim();
    final parsed = RegExp(r'^[0-9]+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Invalid user ID.', call.location);
    }
    return '$parsed';
  }

  String author(BdfdInvocation call) => id(
    call,
    call.context.variables['author.id'] ??
        call.context.variables['user.id'] ??
        '',
  );
  Future<String> target(BdfdInvocation call) async =>
      call.argumentCount == 0 ? author(call) : id(call, await call.argument(0));
  Future<BotUser> user(BdfdInvocation call, String userId) async {
    final value = await call.context.budget.run(
      () => service.user(userId, budget: call.context.budget),
    );
    if (value == null) throw BdfdNativeError('User not found.', call.location);
    return value;
  }

  Future<BotUserMember> member(BdfdInvocation call, String userId) async {
    final value = await call.context.budget.run(
      () => service.member(userId, budget: call.context.budget),
    );
    if (value == null) {
      throw BdfdNativeError(
        'User is not a member of this guild.',
        call.location,
      );
    }
    return value;
  }

  BdfdNativeFunction field(
    String Function(BotUser) read, {
    int min = 1,
    int max = 1,
  }) => BdfdNativeFunction(
    minArguments: min,
    maxArguments: max,
    handler: (call) async => read(await user(call, await target(call))),
  );
  return {
    'userexists': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final userId = id(call, await call.argument(0));
        return '${await call.context.budget.run(() => service.user(userId, budget: call.context.budget)) != null}';
      },
    ),
    'useravatar': field((value) => value.avatarUrl),
    'authoravatar': field((value) => value.avatarUrl, min: 0, max: 0),
    'username': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        if (call.argumentCount == 0) {
          final hydrated =
              call.context.variables['user.username'] ??
              call.context.variables['author.username'];
          if (hydrated != null) return hydrated;
        }
        return (await user(call, await target(call))).username;
      },
    ),
    'displayname': field((value) => value.displayName, min: 0),
    'nickname': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final userId = await target(call);
        final value = await member(call, userId);
        return value.nickname ?? (await user(call, userId)).displayName;
      },
    ),
    'discriminator': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final raw = (await call.argument(0)).trim();
        final value = await user(
          call,
          raw.isEmpty ? author(call) : id(call, raw),
        );
        return value.isBot ? value.discriminator.padLeft(4, '0') : '0000';
      },
    ),
    'userbanner': field((value) => value.bannerUrl ?? ''),
    'userbannercolor': field(
      (value) =>
          value.bannerColor?.toRadixString(16).padLeft(6, '0').toUpperCase() ??
          '',
    ),
    'userserveravatar': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final userId = await target(call);
        final value = await member(call, userId);
        return value.avatarUrl ?? (await user(call, userId)).avatarUrl;
      },
    ),
    'userjoined': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final userId = id(call, await call.argument(0));
        final layout = call.argumentCount == 2
            ? await call.argument(1)
            : '2006-01-02';
        final joinedAt = (await member(call, userId)).joinedAt;
        if (joinedAt == null) {
          throw BdfdNativeError(
            'Member joining date is unavailable.',
            call.location,
          );
        }
        return formatGoTime(
          call.context.time.inTimezone(joinedAt),
          layout,
          checkBudget: call.context.budget.check,
        );
      },
    ),
    'authorbanner': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        final hydrated = call.context.variables['author.banner'];
        if (hydrated != null) return hydrated;
        return (await user(call, author(call))).bannerUrl ?? '';
      },
    ),
    'authortag': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        final hydrated = call.context.variables['author.tag'];
        final u = call.context.variables['author.username'];
        if (u != null && hydrated != null) {
          return hydrated == '0' || hydrated == '0000' ? u : '$u#$hydrated';
        }
        final targetUser = await user(call, author(call));
        return targetUser.isBot
            ? '${targetUser.username}#${targetUser.discriminator.padLeft(4, '0')}'
            : targetUser.username;
      },
    ),
    'usertag': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final targetUser = await user(call, await target(call));
        return targetUser.isBot
            ? '${targetUser.username}#${targetUser.discriminator.padLeft(4, '0')}'
            : targetUser.username;
      },
    ),
    'authorperms': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 2,
      handler: (call) async {
        return call.context.variables['author.permissions'] ??
            call.context.variables['member.permissions'] ??
            '';
      },
    ),
    'hypesquad': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        return call.context.variables['user.hypesquad'] ?? '';
      },
    ),
    'userbadges': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        return call.context.variables['user.badges'] ?? '';
      },
    ),
    'userinfo': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        await target(call);
        final prop = call.argumentCount > 1
            ? (await call.argument(1)).trim().toLowerCase()
            : '';
        if (prop.isEmpty) return call.context.variables['user.info'] ?? '';
        return call.context.variables['user.info_$prop'] ?? '';
      },
    ),
    'isuserdmenabled': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        return call.context.variables['user.dmEnabled'] ?? 'true';
      },
    ),
    'dmchannelid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        return call.context.variables['user.dmChannelId'] ?? '';
      },
    ),
    'getuserstatus': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        return call.context.variables['user.status'] ?? 'offline';
      },
    ),
    'getcustomstatus': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        return call.context.variables['user.customStatus'] ?? '';
      },
    ),
  };
}

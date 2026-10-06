import '../../services/bot_member_query_service.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdMemberQueryFunctions(
  BotMemberQueryService service,
) {
  String id(BdfdInvocation call, String raw, String kind) {
    final value = raw.trim();
    final parsed = RegExp(r'^[0-9]+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Invalid $kind ID.', call.location);
    }
    return '$parsed';
  }

  String author(BdfdInvocation call) => id(
    call,
    call.context.variables['author.id'] ??
        call.context.variables['user.id'] ??
        '',
    'user',
  );
  Future<List<BotGuildMember>> members(BdfdInvocation call) => call
      .context
      .budget
      .run(() => service.guildMembers(budget: call.context.budget));
  Future<BotGuildMember> member(
    BdfdInvocation call,
    String user, {
    String? guild,
  }) async {
    final value = await call.context.budget.run(
      () => service.guildMember(
        user,
        guildId: guild,
        budget: call.context.budget,
      ),
    );
    if (value == null) {
      throw BdfdNativeError(
        'User is not a member of this guild.',
        call.location,
      );
    }
    return value;
  }

  BdfdNativeFunction random(String Function(BotGuildMember) read) =>
      BdfdNativeFunction(
        minArguments: 0,
        maxArguments: 0,
        handler: (call) async {
          final all = await members(call);
          return all.isEmpty
              ? ''
              : read(all[call.context.random.nextInt(all.length)]);
        },
      );
  return {
    'finduser': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final query = (await call.argument(0)).trim();
        final fallback = call.argumentCount == 1
            ? true
            : _boolean(call, await call.argument(1));
        if (query.isNotEmpty) {
          final mention = RegExp(r'^<@!?([0-9]+)>$').firstMatch(query);
          final rawId = mention?.group(1) ?? query;
          final parsed = RegExp(r'^[0-9]+$').hasMatch(rawId)
              ? int.tryParse(rawId)
              : null;
          if (parsed != null && parsed > 0) {
            final found = await call.context.budget.run(
              () => service.guildMember('$parsed', budget: call.context.budget),
            );
            if (found != null) return found.id;
          }
          if (mention == null) {
            for (final user in await members(call)) {
              call.context.budget.check();
              if (user.username == query) return user.id;
            }
          }
        }
        return fallback ? author(call) : '';
      },
    ),
    'randomuserid': random((value) => value.id),
    'randomuser': random((value) => value.username),
    'randommention': random((value) => '<@${value.id}>'),
    'memberscount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async => '${(await members(call)).length}',
    ),
    'allmemberscount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async =>
          '${await call.context.budget.run(() => service.allGuildMembersCount(budget: call.context.budget))}',
    ),
    'isbooster': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 2,
      handler: (call) async {
        final raw = call.argumentCount == 0
            ? ''
            : (await call.argument(0)).trim();
        final userId = raw.isEmpty ? author(call) : id(call, raw, 'user');
        String? guild;
        if (call.argumentCount == 2) {
          final rawGuild = (await call.argument(1)).trim();
          if (rawGuild.isNotEmpty) guild = id(call, rawGuild, 'guild');
        }
        return '${(await member(call, userId, guild: guild)).premiumSince != null}';
      },
    ),
    'istimedout': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final userId = id(call, await call.argument(0), 'user');
        final until = (await member(call, userId)).communicationDisabledUntil;
        return '${until != null && until.isAfter(call.context.time.instant)}';
      },
    ),
    'membercount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async => '${(await members(call)).length}',
    ),
    'getmemberscount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async => '${(await members(call)).length}',
    ),
    'memberid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async =>
          call.context.variables['member.id'] ?? author(call),
    ),
    'membernick': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        if (call.argumentCount == 0) {
          final hydrated =
              call.context.variables['member.nick'] ??
              call.context.variables['member.displayName'] ??
              call.context.variables['author.displayName'] ??
              call.context.variables['author.username'];
          if (hydrated != null) return hydrated;
        }
        final raw = call.argumentCount == 0
            ? ''
            : (await call.argument(0)).trim();
        final userId = raw.isEmpty ? author(call) : id(call, raw, 'user');
        final m = await member(call, userId);
        return m.nickname ?? m.username;
      },
    ),
    'memberperms': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 3,
      handler: (call) async =>
          call.context.variables['member.permissions'] ??
          call.context.variables['author.permissions'] ??
          '',
    ),
    'onlinemembers': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final cached = call.context.variables['guild.onlineMembers'];
        if (cached != null) return cached;
        return '${(await members(call)).length}';
      },
    ),
    'botcount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async =>
          '${(await members(call)).where((m) => m.isBot).length}',
    ),
    'userswithrole': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 3,
      handler: (call) async {
        final roleId = (await call.argument(0)).trim();
        final separator = call.argumentCount > 1
            ? await call.argument(1)
            : ', ';
        final matched = (await members(
          call,
        )).where((m) => m.roleIds.contains(roleId)).map((m) => m.id).toList();
        return matched.join(separator);
      },
    ),
  };
}

bool _boolean(BdfdInvocation call, String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'yes':
    case 'true':
    case 'on':
    case 'enable':
      return true;
    case 'no':
    case 'false':
    case 'off':
    case 'disable':
      return false;
    default:
      throw BdfdNativeError('Invalid return-author boolean.', call.location);
  }
}

import 'package:nyxx/nyxx.dart' show Permissions;
import '../../services/bot_channel_query_service.dart';
import '../../services/bot_permission_query_service.dart';
import '../../services/bot_role_query_service.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdAccessGuardFunctions({
  required BotPermissionQueryService permissions,
  required BotRoleQueryService roles,
  required BotChannelQueryService channels,
}) {
  String id(String raw, BdfdInvocation call) {
    final value = raw.trim();
    final parsed = RegExp(r'^[0-9]+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Invalid Discord ID.', call.location);
    }
    return '$parsed';
  }

  String author(BdfdInvocation call) => id(
    call.context.variables['author.id'] ??
        call.context.variables['user.id'] ??
        '',
    call,
  );
  Future<bool> admin(BdfdInvocation call, String userId) async {
    final value = await call.context.budget.run(
      () => permissions.memberPermissions(
        userId: userId,
        budget: call.context.budget,
      ),
    );
    call.context.budget.check();
    return value.hasAll([Permissions.administrator.value]);
  }

  Future<BotChannel?> channel(BdfdInvocation call) async {
    final channelId = id(call.context.variables['channel.id'] ?? '', call);
    final value = await call.context.budget.run(
      () => channels.channel(channelId, budget: call.context.budget),
    );
    call.context.budget.check();
    return value;
  }

  Future<BotChannel?> threadParent(
    BdfdInvocation call,
    BotChannel? value,
  ) async {
    final parentId = value?.parentId;
    if (value?.type != 'thread') return value;
    if (parentId == null || value?.guildId == null) return null;
    final parent = await call.context.budget.run(
      () => channels.channel(parentId, budget: call.context.budget),
    );
    call.context.budget.check();
    return parent != null &&
            parent.guildId == value?.guildId &&
            parent.type != 'thread'
        ? parent
        : null;
  }

  BdfdNativeFunction roleGuard({
    required bool whitelist,
    required bool names,
  }) => BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 1 << 30,
    handler: (call) async {
      final candidates = <String>[];
      for (var index = 0; index < call.argumentCount - 1; index++) {
        call.context.budget.check();
        final value = (await call.argument(index)).trim();
        if (value.isNotEmpty) candidates.add(names ? value : id(value, call));
      }
      var matches = false;
      if (candidates.isNotEmpty) {
        final userId = author(call);
        final memberIds = await call.context.budget.run(
          () => roles.memberRoleIds(userId, budget: call.context.budget),
        );
        call.context.budget.check();
        final ids = <String>{};
        for (final role in memberIds) {
          call.context.budget.check();
          ids.add(role);
        }
        final guildId = call.context.variables['guild.id'];
        if (guildId != null && guildId.trim().isNotEmpty) {
          ids.add(id(guildId, call));
        }
        final values = <String>{};
        if (names) {
          final guildRoles = await call.context.budget.run(
            () => roles.roles(budget: call.context.budget),
          );
          for (final role in guildRoles) {
            call.context.budget.check();
            if (ids.contains(role.id)) values.add(role.name);
          }
        } else {
          values.addAll(ids);
        }
        for (final candidate in candidates) {
          call.context.budget.check();
          if (values.contains(candidate)) matches = true;
        }
      }
      if (matches != whitelist) {
        call.stop(await call.argument(call.argumentCount - 1));
      }
      return '';
    },
  );
  return {
    'onlyforroles': roleGuard(whitelist: true, names: true),
    'onlyforroleids': roleGuard(whitelist: true, names: false),
    'blacklistroles': roleGuard(whitelist: false, names: true),
    'blacklistrolesids': roleGuard(whitelist: false, names: false),
    'isadmin': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async =>
          '${await admin(call, id(await call.argument(0), call))}',
    ),
    'onlyadmin': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        if (!await admin(call, author(call))) {
          call.stop(await call.argument(0));
        }
        return '';
      },
    ),
    'onlynsfw': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final value = await threadParent(call, await channel(call));
        if (value?.isNsfw != true) {
          call.stop(await call.argument(0));
        }
        return '';
      },
    ),
    'onlyforcategories': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 1 << 30,
      handler: (call) async {
        final candidates = <String>{};
        for (var index = 0; index < call.argumentCount - 1; index++) {
          call.context.budget.check();
          final value = (await call.argument(index)).trim();
          if (value.isNotEmpty) candidates.add(id(value, call));
        }
        final value = candidates.isEmpty ? null : await channel(call);
        final category = (await threadParent(call, value))?.parentId;
        if (category == null || !candidates.contains(category)) {
          call.stop(await call.argument(call.argumentCount - 1));
        }
        return '';
      },
    ),
  };
}

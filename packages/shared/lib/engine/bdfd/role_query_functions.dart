import '../../services/bot_role_query_service.dart';
import '../../services/role_permissions.dart';
import '../../utils/global.dart' show bdfdPermissionFlags;
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdRoleQueryFunctions(
  BotRoleQueryService service,
) {
  Future<List<BotRole>> roles(BdfdInvocation call) =>
      call.context.budget.run(() => service.roles(budget: call.context.budget));
  Future<BotRole> role(BdfdInvocation call) async {
    final raw = (await call.argument(0)).trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Invalid role ID.', call.location);
    }
    final result = (await roles(
      call,
    )).where((r) => r.id == parsed.toString()).firstOrNull;
    if (result == null) throw BdfdNativeError('Role not found.', call.location);
    return result;
  }

  BdfdNativeFunction field(String Function(BotRole) read) => BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async => read(await role(call)),
  );
  String userId(BdfdInvocation call, String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Invalid user ID.', call.location);
    }
    return parsed.toString();
  }

  Future<List<String>> member(BdfdInvocation call, String id) => call
      .context
      .budget
      .run(() => service.memberRoleIds(id, budget: call.context.budget));
  Future<String> boundary(BdfdInvocation call, bool highest) async {
    final ids = call.argumentCount == 0
        ? null
        : (await member(call, userId(call, await call.argument(0)))).toSet();
    final all = orderedBotRoles(await roles(call));
    final selected = ids == null
        ? all
        : all.where((r) => r.isEveryone || ids.contains(r.id)).toList();
    return selected.isEmpty
        ? ''
        : (highest ? selected.first : selected.last).id;
  }

  Future<String> boundaryWithPermissions(
    BdfdInvocation call,
    bool highest,
  ) async {
    final names = <String>[];
    for (var index = 0; index < call.argumentCount; index++) {
      names.add(await call.argument(index));
    }
    final required = bdfdPermissionFlags(names);
    if (required == null) {
      throw BdfdNativeError('Invalid role permissions.', call.location);
    }
    final masks = required.map((f) => f.value).toList();
    final selected = orderedBotRoles(
      await roles(call),
    ).where((r) => hasAllRolePermissions(r.permissions, masks)).toList();
    return selected.isEmpty
        ? ''
        : (highest ? selected.first : selected.last).id;
  }

  return {
    'findrole': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final query = (await call.argument(0)).trim();
        if (query.isEmpty) return '';
        final mention = RegExp(r'^<@&(\d+)>$').firstMatch(query);
        final numeric = int.tryParse(mention?.group(1) ?? query);
        final all = await roles(call);
        if (numeric != null && numeric > 0) {
          final found = all.where((r) => r.id == '$numeric').firstOrNull;
          if (found != null) return found.id;
          if (mention != null) return '';
        }
        return all.where((r) => r.name == query).firstOrNull?.id ?? '';
      },
    ),
    'randomroleid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        String? guild;
        if (call.argumentCount == 1) {
          final raw = (await call.argument(0)).trim();
          if (raw.isNotEmpty) {
            final parsed = int.tryParse(raw);
            if (parsed == null || parsed <= 0) {
              throw BdfdNativeError('Invalid guild ID.', call.location);
            }
            guild = '$parsed';
          }
        }
        final all = await call.context.budget.run(
          () => service.roles(guildId: guild, budget: call.context.budget),
        );
        return all.isEmpty
            ? ''
            : all[call.context.random.nextInt(all.length)].id;
      },
    ),
    'roleperms': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 3,
      handler: (call) async {
        final guild = int.tryParse((await call.argument(0)).trim());
        final id = int.tryParse((await call.argument(1)).trim());
        final separator = call.argumentCount == 3
            ? await call.argument(2)
            : ',';
        if (guild == null || guild <= 0) {
          throw BdfdNativeError('Invalid guild ID.', call.location);
        }
        if (id == null || id <= 0) {
          throw BdfdNativeError('Invalid role ID.', call.location);
        }
        final all = await call.context.budget.run(
          () => service.roles(guildId: '$guild', budget: call.context.budget),
        );
        final selected = all.where((r) => r.id == '$id').firstOrNull;
        if (selected == null) {
          throw BdfdNativeError('Role not found.', call.location);
        }
        return formatRolePermissions(
          selected.permissions,
          separator: separator,
        );
      },
    ),
    'rolecount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async => '${(await roles(call)).length}',
    ),
    'rolenames': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async => (await roles(call)).map((r) => r.name).join(','),
    ),
    'highestrolewithperms': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 10000,
      handler: (call) => boundaryWithPermissions(call, true),
    ),
    'lowestrolewithperms': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 10000,
      handler: (call) => boundaryWithPermissions(call, false),
    ),
    'hasrole': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) async {
        final user = userId(call, await call.argument(0));
        final raw = (await call.argument(1)).trim();
        if (raw.isEmpty) return 'false';
        final id = int.tryParse(raw);
        if (id == null || id <= 0) {
          throw BdfdNativeError('Invalid role ID.', call.location);
        }
        final ids = await member(call, user);
        if (ids.contains(id.toString())) return 'true';
        return (await roles(
          call,
        )).any((r) => r.id == id.toString() && r.isEveryone).toString();
      },
    ),
    'highestrole': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) => boundary(call, true),
    ),
    'lowestrole': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) => boundary(call, false),
    ),
    'roleposition': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final parsed = int.tryParse((await call.argument(0)).trim());
        if (parsed == null || parsed <= 0) {
          throw BdfdNativeError('Invalid role ID.', call.location);
        }
        final all = orderedBotRoles(await roles(call));
        final index = all.indexWhere((r) => r.id == parsed.toString());
        if (index < 0) throw BdfdNativeError('Role not found.', call.location);
        return '${index + 1}';
      },
    ),
    'roleid': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final name = await call.argument(0);
        if (name.isEmpty) return '';
        final matches = (await roles(
          call,
        )).where((r) => r.name == name).toList();
        return matches.length == 1 ? matches.single.id : '';
      },
    ),
    'rolename': field((r) => r.name),
    'getrolecolor': field(
      (r) => r.color.toRadixString(16).padLeft(6, '0').toUpperCase(),
    ),
    'ishoisted': field((r) => r.hoisted.toString()),
    'ismentionable': field((r) => r.mentionable.toString()),
    'roleexists': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final raw = (await call.argument(0)).trim();
        final parsed = int.tryParse(raw);
        if (parsed == null || parsed <= 0) return 'false';
        return (await roles(
          call,
        )).any((r) => r.id == parsed.toString()).toString();
      },
    ),
    'userroles': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final parsed = int.tryParse((await call.argument(0)).trim());
        if (parsed == null || parsed <= 0) {
          throw BdfdNativeError('Invalid user ID.', call.location);
        }
        final ids = await call.context.budget.run(
          () => service.memberRoleIds(
            parsed.toString(),
            budget: call.context.budget,
          ),
        );
        final all = await roles(call);
        final byId = {for (final r in all) r.id: r};
        return ids.map((id) => byId[id]?.name).whereType<String>().join('\n');
      },
    ),
    'getrole': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 3,
      handler: (call) async {
        final targetUser = call.argumentCount > 0
            ? (await call.argument(0)).trim()
            : '';
        final parsedUser = targetUser.isEmpty
            ? userId(call, call.context.variables['author.id'] ?? '')
            : userId(call, targetUser);
        final indexRaw = call.argumentCount > 1
            ? (await call.argument(1)).trim()
            : '1';
        final index = int.tryParse(indexRaw) ?? 1;
        final ids = await call.context.budget.run(
          () => service.memberRoleIds(parsedUser, budget: call.context.budget),
        );
        if (index <= 0 || index > ids.length) return '';
        return ids[index - 1];
      },
    ),
    'roleinfo': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final targetRole = await role(call);
        final prop = call.argumentCount > 1
            ? (await call.argument(1)).trim().toLowerCase()
            : '';
        return switch (prop) {
          'name' => targetRole.name,
          'id' => targetRole.id,
          'color' =>
            targetRole.color.toRadixString(16).padLeft(6, '0').toUpperCase(),
          'position' => '${targetRole.position}',
          'hoist' || 'hoisted' => '${targetRole.hoisted}',
          'mentionable' => '${targetRole.mentionable}',
          'perms' || 'permissions' => '${targetRole.permissions}',
          _ => targetRole.name,
        };
      },
    ),
  };
}

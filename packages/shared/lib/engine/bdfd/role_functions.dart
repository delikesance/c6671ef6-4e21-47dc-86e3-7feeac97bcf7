import '../../services/bot_moderation_service.dart';
import '../../services/command_input.dart';
import '../../services/role_definition.dart';
import '../../utils/global.dart' show bdfdPermissionFlags;
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdRoleFunctions(
  BotModerationService service,
) {
  String id(BdfdInvocation call, String raw, String label) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Missing or invalid $label ID.', call.location);
    }
    return parsed.toString();
  }

  Future<void> submit(
    BdfdInvocation call,
    String user,
    String role,
    bool add,
  ) => call.context.budget.run(() async {
    await service.moderate(
      BotModerationRequest(
        operation: add
            ? BotModerationOperation.addRole
            : BotModerationOperation.removeRole,
        userId: user,
        roleId: role,
        useDefaultReason: false,
      ),
      budget: call.context.budget,
    );
  });

  Future<String> grant(BdfdInvocation call, bool add) async {
    final first = await call.argument(0);
    final role = id(
      call,
      call.argumentCount == 1 ? first : await call.argument(1),
      'role',
    );
    final targets = call.argumentCount == 1
        ? CommandInput(call.context.variables).userMentions
        : [first];
    // Validate all mentions before issuing any mutation. Never fall back to author.
    final users = targets.map((raw) => id(call, raw, 'user')).toSet();
    if (users.isEmpty) {
      throw BdfdNativeError(
        'A user ID or user mention is required.',
        call.location,
      );
    }
    for (final user in users) {
      await submit(call, user, role, add);
    }
    return '';
  }

  bool? boolean(BdfdInvocation call, String raw, {bool optional = false}) {
    if (raw.isEmpty || (optional && raw == '!unchanged')) {
      return optional ? null : false;
    }
    if (raw.toLowerCase() == 'yes') return true;
    if (raw.toLowerCase() == 'no') return false;
    throw BdfdNativeError('Role flags must be yes or no.', call.location);
  }

  int color(BdfdInvocation call, String raw) {
    final parsed = parseBdfdRoleColor(raw);
    if (parsed == null) {
      throw BdfdNativeError('Invalid role color.', call.location);
    }
    return parsed;
  }

  Future<String> definition(
    BdfdInvocation call,
    BotModerationOperation operation, {
    String roleId = '',
    RoleDefinition? fields,
  }) async {
    final error = fields?.validate(
      create: operation == BotModerationOperation.createRole,
    );
    if (error != null) throw BdfdNativeError(error, call.location);
    await call.context.budget.run(
      () => service.moderate(
        BotModerationRequest(
          operation: operation,
          userId: '',
          roleId: roleId,
          roleDefinition: fields,
          useDefaultReason: false,
        ),
        budget: call.context.budget,
      ),
    );
    return '';
  }

  return {
    'setuserroles': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) async {
        final user = id(call, await call.argument(0), 'user');
        final roles = <String>{};
        for (var index = 1; index < call.argumentCount; index++) {
          roles.add(id(call, await call.argument(index), 'role'));
        }
        await call.context.budget.run(
          () => service.moderate(
            BotModerationRequest(
              operation: BotModerationOperation.setUserRoles,
              userId: user,
              roleReplacement: RoleReplacement(roles),
              useDefaultReason: false,
            ),
            budget: call.context.budget,
          ),
        );
        return '';
      },
    ),
    'createrole': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 4,
      handler: (call) async {
        final name = await call.argument(0);
        final roleColor = color(call, await call.argument(1));
        final hoist = call.argumentCount > 2
            ? boolean(call, await call.argument(2))
            : false;
        final mentionable = call.argumentCount > 3
            ? boolean(call, await call.argument(3))
            : false;
        return definition(
          call,
          BotModerationOperation.createRole,
          fields: RoleDefinition(
            name: name,
            color: roleColor,
            hoist: hoist,
            mentionable: mentionable,
          ),
        );
      },
    ),
    'deleterole': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async => definition(
        call,
        BotModerationOperation.deleteRole,
        roleId: id(call, await call.argument(0), 'role'),
      ),
    ),
    'colorrole': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final variables = call.context.variables;
        final encoded = variables['message.roleMentions'];
        final target = encoded == null
            ? variables['message.roleMentions[0]'] ?? ''
            : encoded.split(',').where((r) => r.isNotEmpty).firstOrNull ?? '';
        return definition(
          call,
          BotModerationOperation.updateRole,
          roleId: id(call, target, 'role'),
          fields: RoleDefinition(color: color(call, await call.argument(0))),
        );
      },
    ),
    'modifyrole': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 6,
      handler: (call) async {
        final role = id(call, await call.argument(0), 'role');
        Future<String?> optional(int index) async {
          if (call.argumentCount <= index) return null;
          final raw = await call.argument(index);
          return raw.isEmpty || raw == '!unchanged' ? null : raw;
        }

        final name = await optional(1);
        final rawColor = await optional(2);
        final rawHoist = await optional(3);
        final rawMentionable = await optional(4);
        final rawPosition = await optional(5);
        final position = rawPosition == null ? null : int.tryParse(rawPosition);
        if (rawPosition != null && (position == null || position < 0)) {
          throw BdfdNativeError('Invalid role position.', call.location);
        }
        return definition(
          call,
          BotModerationOperation.updateRole,
          roleId: role,
          fields: RoleDefinition(
            name: name,
            color: rawColor == null ? null : color(call, rawColor),
            hoist: rawHoist == null ? null : boolean(call, rawHoist),
            mentionable: rawMentionable == null
                ? null
                : boolean(call, rawMentionable),
            position: position,
          ),
        );
      },
    ),
    'modifyroleperms': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) async {
        final role = id(call, await call.argument(0), 'role');
        final names = <String>[];
        for (var index = 1; index < call.argumentCount; index++) {
          names.add(await call.argument(index));
        }
        final flags = bdfdPermissionFlags(names);
        if (flags == null) {
          throw BdfdNativeError('Invalid role permissions.', call.location);
        }
        return definition(
          call,
          BotModerationOperation.updateRole,
          roleId: role,
          fields: RoleDefinition(
            togglePermissions: flags.map((f) => f.value).toList(),
          ),
        );
      },
    ),
    'giverole': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) => grant(call, true),
    ),
    'takerole': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) => grant(call, false),
    ),
    'rolegrant': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) async {
        final user = id(call, await call.argument(0), 'user');
        final changes = <({String role, bool add})>[];
        for (var index = 1; index < call.argumentCount; index++) {
          final raw = (await call.argument(index)).trim();
          if (!raw.startsWith('+') && !raw.startsWith('-')) {
            throw BdfdNativeError(
              'A role grant must start with + or -.',
              call.location,
            );
          }
          changes.add((
            role: id(call, raw.substring(1), 'role'),
            add: raw.startsWith('+'),
          ));
        }
        for (final change in changes) {
          await submit(call, user, change.role, change.add);
        }
        return '';
      },
    ),
    'giveroles': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) async {
        final user = id(call, await call.argument(0), 'user');
        for (var index = 1; index < call.argumentCount; index++) {
          final role = id(call, await call.argument(index), 'role');
          await submit(call, user, role, true);
        }
        return '';
      },
    ),
    'takeroles': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) async {
        final user = id(call, await call.argument(0), 'user');
        for (var index = 1; index < call.argumentCount; index++) {
          final role = id(call, await call.argument(index), 'role');
          await submit(call, user, role, false);
        }
        return '';
      },
    ),
  };
}

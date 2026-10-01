import 'package:nyxx/nyxx.dart';

import '../utils/global.dart';

bool isRoleDefinitionPayload(Map<String, dynamic> payload) =>
    payload['createNew'] == true ||
    payload['deleteRole'] == true ||
    payload['modify'] == true ||
    payload.containsKey('updateColor') ||
    payload.containsKey('modifyPermissions');

int? parseBdfdRoleColor(dynamic input) {
  final raw = input?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  final value = raw.startsWith('#') ? raw.substring(1) : raw;
  final color =
      raw.startsWith('#') ||
          RegExp(r'[a-fA-F]').hasMatch(value) ||
          value.length == 6
      ? int.tryParse(value, radix: 16)
      : int.tryParse(value);
  return color != null && color >= 0 && color <= 0xffffff ? color : null;
}

Future<Map<String, String>> executeRoleDefinitionAction(
  NyxxGateway client, {
  required Snowflake guildId,
  required Map<String, dynamic> payload,
}) async {
  try {
    final manager = client.guilds[guildId].roles;
    if (payload['createNew'] == true) {
      final name = payload['name']?.toString().trim() ?? '';
      final color = parseBdfdRoleColor(payload['color']);
      if (name.isEmpty || name.length > 100 || color == null) {
        return {'error': 'Invalid role name or color'};
      }
      final created = await manager.create(
        RoleBuilder(
          name: name,
          colors: RoleColorsBuilder(primary: DiscordColor(color)),
          isHoisted: payload['hoist'] == true,
          isMentionable: payload['mentionable'] == true,
        ),
      );
      return {'roleId': created.id.toString(), 'status': 'created'};
    }

    final roleId = Snowflake(
      int.tryParse(payload['roleId']?.toString() ?? '') ?? 0,
    );
    if (roleId == Snowflake.zero) return {'error': 'Invalid role ID'};

    if (payload['deleteRole'] == true) {
      await manager.delete(roleId);
      return {'roleId': roleId.toString(), 'status': 'deleted'};
    }

    if (payload.containsKey('updateColor')) {
      final color = parseBdfdRoleColor(payload['updateColor']);
      if (color == null) return {'error': 'Invalid role color'};
      await manager.update(
        roleId,
        RoleUpdateBuilder(
          colors: RoleColorsBuilder(primary: DiscordColor(color)),
        ),
      );
      return {'roleId': roleId.toString(), 'status': 'updated'};
    }

    if (payload.containsKey('modifyPermissions')) {
      final raw = payload['modifyPermissions'];
      if (raw is! List) return {'error': 'Invalid role permissions'};
      final flags = bdfdPermissionFlags(raw.map((value) => value.toString()));
      if (flags == null) return {'error': 'Invalid role permissions'};
      final role = await manager.fetch(roleId);
      var mask = role.permissions.value;
      for (final flag in flags) {
        mask ^= flag.value;
      }
      await manager.update(
        roleId,
        RoleUpdateBuilder(permissions: Permissions(mask)),
      );
      return {'roleId': roleId.toString(), 'status': 'updated'};
    }

    if (payload['modify'] == true) {
      final color = payload.containsKey('color')
          ? parseBdfdRoleColor(payload['color'])
          : null;
      if (payload.containsKey('color') && color == null) {
        return {'error': 'Invalid role color'};
      }
      await manager.update(
        roleId,
        RoleUpdateBuilder(
          name: payload['name']?.toString(),
          colors: color == null
              ? null
              : RoleColorsBuilder(primary: DiscordColor(color)),
          isHoisted: payload['hoist'] as bool?,
          isMentionable: payload['mentionable'] as bool?,
        ),
      );
      final position = payload['position'];
      if (position is int && position >= 0) {
        await manager.updatePositions({roleId: position});
      }
      return {'roleId': roleId.toString(), 'status': 'updated'};
    }
    return {'error': 'Unsupported role definition action'};
  } catch (error) {
    return {'error': 'Failed to modify role: $error'};
  }
}

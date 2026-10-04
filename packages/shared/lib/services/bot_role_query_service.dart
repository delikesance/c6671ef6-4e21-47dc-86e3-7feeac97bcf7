import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';

class BotRole {
  const BotRole({
    required this.id,
    required this.name,
    required this.color,
    required this.hoisted,
    required this.mentionable,
    this.position = 0,
    this.isEveryone = false,
    this.permissions = 0,
  });
  final String id;
  final String name;
  final int color;
  final bool hoisted;
  final bool mentionable;
  final int position;
  final bool isEveryone;
  final int permissions;
}

abstract interface class BotRoleQueryService {
  /// Null selects the adapter's current guild; a value selects that guild only.
  Future<List<BotRole>> roles({
    String? guildId,
    required CommandExecutionBudget budget,
  });
  Future<List<String>> memberRoleIds(
    String userId, {
    required CommandExecutionBudget budget,
  });
}

/// Shared with visual entity hydration. No template or BDFD interpretation.
Future<List<Role>> readDiscordRoles(NyxxGateway client, Snowflake guildId) =>
    client.guilds[guildId].roles.list();

class DiscordBotRoleQueryService implements BotRoleQueryService {
  const DiscordBotRoleQueryService({required this.client, this.guildId});
  final NyxxGateway client;
  final Snowflake? guildId;
  Snowflake get _guild =>
      guildId ?? (throw StateError('Role lookup requires a guild.'));

  @override
  Future<List<BotRole>> roles({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final parsed = guildId == null ? null : int.tryParse(guildId.trim());
    if (guildId != null && (parsed == null || parsed <= 0)) {
      throw ArgumentError('Invalid guild ID.');
    }
    final selectedGuild = parsed == null ? _guild : Snowflake(parsed);
    final roles = await readDiscordRoles(client, selectedGuild);
    budget.check();
    return List.unmodifiable(
      roles.map(
        (r) => BotRole(
          id: '${r.id}',
          name: r.name,
          color: r.colors.primary.value,
          hoisted: r.isHoisted,
          mentionable: r.isMentionable,
          position: r.position,
          isEveryone: r.id == selectedGuild,
          permissions: r.permissions.value,
        ),
      ),
    );
  });

  @override
  Future<List<String>> memberRoleIds(
    String userId, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final parsed = int.tryParse(userId.trim());
    if (parsed == null || parsed <= 0) throw ArgumentError('Invalid user ID.');
    final member = await client.guilds[_guild].members.get(Snowflake(parsed));
    budget.check();
    return List.unmodifiable(member.roleIds.map((id) => '$id'));
  });
}

/// Highest first. At equal Discord positions, the older (smaller) ID wins.
int compareRoleHierarchy({
  required String leftId,
  required int leftPosition,
  required bool leftEveryone,
  required String rightId,
  required int rightPosition,
  required bool rightEveryone,
}) {
  if (leftEveryone != rightEveryone) return leftEveryone ? 1 : -1;
  final position = rightPosition.compareTo(leftPosition);
  if (position != 0) return position;
  final left = BigInt.tryParse(leftId);
  final right = BigInt.tryParse(rightId);
  return left != null && right != null
      ? left.compareTo(right)
      : leftId.compareTo(rightId);
}

List<BotRole> orderedBotRoles(Iterable<BotRole> roles) => roles.toList()
  ..sort(
    (a, b) => compareRoleHierarchy(
      leftId: a.id,
      leftPosition: a.position,
      leftEveryone: a.isEveryone,
      rightId: b.id,
      rightPosition: b.position,
      rightEveryone: b.isEveryone,
    ),
  );

List<Role> orderedDiscordRoles(Iterable<Role> roles, Snowflake guildId) =>
    roles.toList()..sort(
      (a, b) => compareRoleHierarchy(
        leftId: '${a.id}',
        leftPosition: a.position,
        leftEveryone: a.id == guildId,
        rightId: '${b.id}',
        rightPosition: b.position,
        rightEveryone: b.id == guildId,
      ),
    );

/// Permissions belong to the role itself; Administrator satisfies every flag.
bool hasAllRolePermissions(int permissions, Iterable<int> required) =>
    (permissions & Permissions.administrator.value) != 0 ||
    required.every((flag) => (permissions & flag) == flag);

/// Role fields are evaluated data, never source code or block placeholders.
class RoleDefinition {
  RoleDefinition({
    this.name,
    this.color,
    this.hoist,
    this.mentionable,
    this.position,
    List<int>? togglePermissions,
  }) : togglePermissions = togglePermissions == null
           ? null
           : List.unmodifiable(togglePermissions);

  final String? name;
  final int? color;
  final bool? hoist;
  final bool? mentionable;
  final int? position;
  final List<int>? togglePermissions;

  String? validate({bool create = false}) {
    if ((create && name == null) ||
        (name != null && (name!.trim().isEmpty || name!.length > 100))) {
      return 'Invalid role name';
    }
    if ((create && color == null) ||
        (color != null && (color! < 0 || color! > 0xffffff))) {
      return 'Invalid role color';
    }
    if (position != null && position! < 0) return 'Invalid role position';
    if (togglePermissions != null &&
        (togglePermissions!.isEmpty ||
            togglePermissions!.any((flag) => flag <= 0))) {
      return 'Invalid role permissions';
    }
    return null;
  }
}

int? parseBdfdRoleColor(dynamic input) {
  final raw = input?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  final value = raw.startsWith('#') ? raw.substring(1) : raw;
  final color = raw.startsWith('#') || RegExp(r'[a-fA-F]').hasMatch(value)
      ? int.tryParse(value, radix: 16)
      : int.tryParse(value);
  return color != null && color >= 0 && color <= 0xffffff ? color : null;
}

/// A snapshot of the desired member role IDs, shared by scripts and blocks.
class RoleReplacement {
  RoleReplacement(Iterable<String> roles) : roleIds = List.unmodifiable(roles);
  final List<String> roleIds;
}

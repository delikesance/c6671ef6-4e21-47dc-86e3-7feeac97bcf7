import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator_shared/utils/permission_flags.dart'
    show PermissionFlag, PermissionCategory, discordPermissionFlags;

/// A tri-state toggle picker for Discord permission overwrites.
///
/// Each permission can be toggled through three states:
///   - **Unset** (grey, default): inherit from role hierarchy
///   - **Allow** (green ✓): explicitly grant
///   - **Deny** (red ✗): explicitly deny
///
/// Value format: Map<String, String> where keys are [PermissionFlag.key]
/// and values are 'allow', 'deny', or 'unset'.
class PermissionFlagsField extends StatefulWidget {
  const PermissionFlagsField({
    super.key,
    required this.label,
    required this.currentValue,
    this.hint,
    this.suggestions,
    this.onChanged,
  });

  final String label;
  final Map<String, String>? currentValue;
  final String? hint;
  final List<dynamic>? suggestions;
  final ValueChanged<Map<String, String>>? onChanged;

  @override
  State<PermissionFlagsField> createState() => _PermissionFlagsFieldState();
}

class _PermissionFlagsFieldState extends State<PermissionFlagsField> {
  late Map<String, String> _permissionStates;
  final Set<PermissionCategory> _expandedCategories = {
    PermissionCategory.general,
    PermissionCategory.text,
  };

  @override
  void initState() {
    super.initState();
    _permissionStates = Map<String, String>.from(
      widget.currentValue ?? const {},
    );
    // Ensure all known permissions have a state
    for (final flag in discordPermissionFlags) {
      _permissionStates.putIfAbsent(flag.key, () => 'unset');
    }
  }

  @override
  void didUpdateWidget(covariant PermissionFlagsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue) {
      _permissionStates = Map<String, String>.from(
        widget.currentValue ?? const {},
      );
      for (final flag in discordPermissionFlags) {
        _permissionStates.putIfAbsent(flag.key, () => 'unset');
      }
    }
  }

  void _togglePermission(String key) {
    setState(() {
      final current = _permissionStates[key] ?? 'unset';
      switch (current) {
        case 'unset':
          _permissionStates[key] = 'allow';
        case 'allow':
          _permissionStates[key] = 'deny';
        case 'deny':
          _permissionStates[key] = 'unset';
      }
    });
    widget.onChanged?.call(Map<String, String>.from(_permissionStates));
  }

  void _toggleCategory(PermissionCategory category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  IconData _stateIcon(String state) {
    switch (state) {
      case 'allow':
        return Icons.check_circle;
      case 'deny':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'allow':
        return Colors.green;
      case 'deny':
        return Colors.red.shade400;
      default:
        return AppTheme.grey;
    }
  }

  String _categoryName(PermissionCategory category) {
    switch (category) {
      case PermissionCategory.general:
        return 'General';
      case PermissionCategory.membership:
        return 'Membership';
      case PermissionCategory.text:
        return 'Text';
      case PermissionCategory.voice:
        return 'Voice';
      case PermissionCategory.advanced:
        return 'Advanced';
    }
  }

  String _permissionDisplayName(String key) {
    // Convert camelCase to Title Case with spaces
    return key.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => ' ${match.group(0)}',
    ).trim().split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  int _countByCategory(PermissionCategory cat, String state) {
    return discordPermissionFlags
        .where((f) => f.category == cat && _permissionStates[f.key] == state)
        .length;
  }

  int _totalByCategory(PermissionCategory cat) {
    return discordPermissionFlags.where((f) => f.category == cat).length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            _buildQuickActions(),
          ],
        ),
        if (widget.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.hint!,
            style: TextStyle(color: AppTheme.grey, fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.grey),
            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
          ),
          child: Column(
            children: [
              // Legend
              _buildLegend(),
              const Divider(height: 1),
              // Permission categories
              ...PermissionCategory.values.map(_buildCategorySection),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _legendChip('Allow', Icons.check_circle, Colors.green),
          const SizedBox(width: 12),
          _legendChip('Deny', Icons.cancel, Colors.red.shade400),
          const SizedBox(width: 12),
          _legendChip('Unset', Icons.radio_button_unchecked, AppTheme.grey),
          const Spacer(),
          Text(
            'Tap to cycle',
            style: TextStyle(color: AppTheme.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _legendChip(String label, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _quickActionButton('All → Deny', Colors.red.shade400, () {
          setState(() {
            for (final flag in discordPermissionFlags) {
              _permissionStates[flag.key] = 'deny';
            }
          });
          widget.onChanged?.call(Map<String, String>.from(_permissionStates));
        }),
        const SizedBox(width: 4),
        _quickActionButton('Clear', AppTheme.grey, () {
          setState(() {
            for (final flag in discordPermissionFlags) {
              _permissionStates[flag.key] = 'unset';
            }
          });
          widget.onChanged?.call(Map<String, String>.from(_permissionStates));
        }),
      ],
    );
  }

  Widget _quickActionButton(
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ),
    );
  }

  Widget _buildCategorySection(PermissionCategory category) {
    final flags =
        discordPermissionFlags.where((f) => f.category == category).toList();
    if (flags.isEmpty) return const SizedBox.shrink();

    final isExpanded = _expandedCategories.contains(category);
    final allowCount = _countByCategory(category, 'allow');
    final denyCount = _countByCategory(category, 'deny');
    final total = _totalByCategory(category);

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleCategory(category),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppTheme.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _categoryName(category),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                if (allowCount > 0)
                  _categoryBadge('$allowCount ✓', Colors.green),
                if (denyCount > 0) ...[
                  const SizedBox(width: 4),
                  _categoryBadge('$denyCount ✗', Colors.red.shade400),
                ],
                const Spacer(),
                Text(
                  '$total',
                  style: TextStyle(color: AppTheme.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...flags.map(_buildPermissionRow),
        const Divider(height: 1),
      ],
    );
  }

  Widget _categoryBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPermissionRow(PermissionFlag flag) {
    final state = _permissionStates[flag.key] ?? 'unset';
    final color = _stateColor(state);
    final icon = _stateIcon(state);

    return InkWell(
      onTap: () => _togglePermission(flag.key),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _permissionDisplayName(flag.key),
                style: TextStyle(
                  fontSize: 13,
                  color: state == 'unset' ? AppTheme.grey : null,
                ),
              ),
            ),
            if (flag.voiceOnly)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.mic, size: 12, color: AppTheme.grey),
              ),
          ],
        ),
      ),
    );
  }
}

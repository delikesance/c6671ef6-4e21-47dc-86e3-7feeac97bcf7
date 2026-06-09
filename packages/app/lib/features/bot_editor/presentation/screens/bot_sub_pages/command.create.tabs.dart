part of 'command.create.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Tab management for Command | Interactions split
// ──────────────────────────────────────────────────────────────────────────────

enum _EditorTab { command, interactions }

extension _CommandTabs on _CommandCreatePageState {
  _EditorTab _activeTab = _EditorTab.command;

  int get _interactionCount {
    var count = 0;
    for (final action in _actions) {
      final type = (action['type'] ?? '').toString();
      if (_isInteractionAction(type)) count++;
    }
    return count;
  }

  bool _isInteractionAction(String type) {
    return type == 'addButton' ||
        type == 'addButtonCv2' ||
        type == 'addSelectMenuOption' ||
        type == 'newSelectMenu' ||
        type == 'addTextInput';
  }

  List<Map<String, dynamic>> get _interactionActions {
    return _actions.where((a) {
      final type = (a['type'] ?? '').toString();
      return _isInteractionAction(type);
    }).toList();
  }

  /// Groups interaction actions by their customId (or a fallback).
  List<_InteractionGroup> _buildInteractionGroups() {
    final groups = <String, _InteractionGroup>{};
    for (final action in _interactionActions) {
      final payload = Map<String, dynamic>.from(
        (action['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      var customId = (payload['customId'] ?? payload['custom_id'] ?? '').toString().trim();
      if (customId.isEmpty) {
        customId = (payload['id'] ?? '').toString().trim();
      }
      if (customId.isEmpty) {
        customId = (payload['label'] ?? '').toString().trim();
      }
      if (customId.isEmpty) {
        customId = 'interaction_${groups.length + 1}';
      }

      final type = (action['type'] ?? '').toString();
      final icon = _interactionIcon(type);

      groups.putIfAbsent(customId, () => _InteractionGroup(customId: customId, icon: icon));
      groups[customId]!.actions.add(action);
    }
    return groups.values.toList();
  }

  IconData _interactionIcon(String type) {
    switch (type) {
      case 'addButton':
      case 'addButtonCv2':
        return Icons.smart_button_outlined;
      case 'addSelectMenuOption':
      case 'newSelectMenu':
        return Icons.arrow_drop_down_circle_outlined;
      case 'addTextInput':
        return Icons.text_fields_outlined;
      default:
        return Icons.touch_app_outlined;
    }
  }

  Widget _buildTabBar() {
    final count = _interactionCount;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Command',
              icon: Icons.grid_view_rounded,
              isSelected: _activeTab == _EditorTab.command,
              onTap: () => setState(() => _activeTab = _EditorTab.command),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Interactions',
              icon: Icons.ads_click,
              isSelected: _activeTab == _EditorTab.interactions,
              badge: count > 0 ? count.toString() : null,
              onTap: () => setState(() => _activeTab = _EditorTab.interactions),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionsTab() {
    final groups = _buildInteractionGroups();
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No interactions yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a button, select menu or text input\nto your command to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _InteractionTile(group: group);
      },
    );
  }

  Widget _buildTabContent(double contentMaxWidth) {
    switch (_activeTab) {
      case _EditorTab.command:
        return _buildBlockEditor(contentMaxWidth: contentMaxWidth);
      case _EditorTab.interactions:
        return _buildInteractionsTab();
    }
  }
}

class _InteractionGroup {
  _InteractionGroup({required this.customId, required this.icon});
  final String customId;
  final IconData icon;
  final List<Map<String, dynamic>> actions = [];
}

class _InteractionTile extends StatelessWidget {
  const _InteractionTile({required this.group});
  final _InteractionGroup group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: open sub-flow editor for this interaction
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(group.icon, color: cs.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.customId,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        '${group.actions.length} action${group.actions.length > 1 ? 's' : ''}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.badge,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? cs.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18,
                color: isSelected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                )),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

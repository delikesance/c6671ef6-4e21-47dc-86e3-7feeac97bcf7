import 'package:flutter/material.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_type_extension.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_palette.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Context menu popup inspired by Unreal Engine's Blueprint "Spawn Action" search.
class BlueprintContextMenu extends StatefulWidget {
  final Offset position;
  final ValueChanged<BotCreatorActionType> onActionSelected;
  final VoidCallback onDismiss;
  final bool isInteraction;

  const BlueprintContextMenu({
    super.key,
    required this.position,
    required this.onActionSelected,
    required this.onDismiss,
    this.isInteraction = true,
  });

  @override
  State<BlueprintContextMenu> createState() => _BlueprintContextMenuState();
}

class _BlueprintContextMenuState extends State<BlueprintContextMenu> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actions = BotCreatorActionType.values.where((type) {
      if (!widget.isInteraction && isInteractionOnlyAction(type)) return false;
      if (isListenerAction(type)) return false;
      if (_filter.isEmpty) return true;
      return type
              .displayName(context)
              .toLowerCase()
              .contains(_filter.toLowerCase()) ||
          type.name.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: Material(
        elevation: 16,
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF1E2128),
        child: Container(
          width: 300,
          height: 380,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Search ──
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: context.tr.blueprint_search_action_hint,
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 8, right: 6),
                      child: AppIcon.fromMaterial(
                        Icons.search,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: const AppIcon.fromMaterial(
                        Icons.close,
                        color: Colors.white38,
                        size: 16,
                      ),
                      onPressed: widget.onDismiss,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF14161A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filter = val.trim();
                    });
                  },
                ),
              ),

              // ── Actions list ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: actions.length,
                  itemBuilder: (context, idx) {
                    final type = actions[idx];
                    final cat = getCategoryForAction(type);
                    final color = getCategoryColor(cat);

                    return InkWell(
                      onTap: () {
                        widget.onActionSelected(type);
                        widget.onDismiss();
                      },
                      hoverColor: Colors.white.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            AppIcon.fromMaterial(
                              type.icon,
                              size: 16,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                type.displayName(context),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

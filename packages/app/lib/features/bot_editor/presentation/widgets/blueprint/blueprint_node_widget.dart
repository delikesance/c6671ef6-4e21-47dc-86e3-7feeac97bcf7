import 'package:flutter/material.dart';
import 'blueprint_models.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Interactive node card widget for the Blueprint canvas.
class BlueprintNodeWidget extends StatelessWidget {
  final BlueprintNodeData data;
  final bool isSelected;
  final VoidCallback? onSelect;
  final Function(Offset delta)? onDragDelta;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final Function(BlueprintPin pin, Offset pinCanvasPos)? onPinStartDrag;
  final Function(Offset globalPosition)? onPinDragUpdate;
  final VoidCallback? onPinDragEnd;
  final VoidCallback? onPinDragCancel;
  final Function(BlueprintPin pin)? onBreakPinLinks;

  const BlueprintNodeWidget({
    super.key,
    required this.data,
    this.isSelected = false,
    this.onSelect,
    this.onDragDelta,
    this.onDelete,
    this.onDuplicate,
    this.onPinStartDrag,
    this.onPinDragUpdate,
    this.onPinDragEnd,
    this.onPinDragCancel,
    this.onBreakPinLinks,
  });

  static const double headerHeight = 32.0;
  static const double pinRowHeight = 24.0;
  static const double pinVerticalPadding = 6.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      onPanUpdate: onDragDelta != null
          ? (details) => onDragDelta!(details.delta)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: data.size.width,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2128), // Node dark container
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C5CF0)
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF7C5CF0).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Node Header ──
            _buildHeader(context),

            // ── Node Body (Pins + Info) ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: pinVerticalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input Pins
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.inPins
                        .map((pin) => _buildPin(context, pin))
                        .toList(),
                  ),

                  // Center Content Summary
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (data.subtitle != null &&
                              data.subtitle!.isNotEmpty)
                            Text(
                              data.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75),
                                fontFamily: 'monospace',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Output Pins
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.outPins
                        .map((pin) => _buildPin(context, pin))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final accent = data.headerColor;
    return Container(
      height: headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: AppIcon.fromMaterial(data.icon, size: 15, color: accent),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (!data.isEntryPoint && onDelete != null && isSelected)
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: AppIcon.fromMaterial(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPin(BuildContext context, BlueprintPin pin) {
    final isOut = pin.direction == BlueprintPinDirection.output;
    final pinColor = pin.customColor ?? Colors.white;

    final pinShape = GestureDetector(
      onPanStart: (details) {
        if (onPinStartDrag != null) {
          final pinCanvasPos = data.getPinCanvasPosition(pin.id);
          onPinStartDrag!(pin, pinCanvasPos);
        }
      },
      onPanUpdate: onPinDragUpdate != null
          ? (details) => onPinDragUpdate!(details.globalPosition)
          : null,
      onPanEnd: onPinDragEnd != null ? (_) => onPinDragEnd!() : null,
      onPanCancel: onPinDragCancel != null ? () => onPinDragCancel!() : null,
      onSecondaryTap: () {
        if (onBreakPinLinks != null) {
          onBreakPinLinks!(pin);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2128),
            shape: BoxShape.circle,
            border: Border.all(color: pinColor, width: 2.5),
          ),
        ),
      ),
    );

    return SizedBox(
      height: pinRowHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isOut) pinShape,
          if (!isOut) const SizedBox(width: 4),
          Text(
            pin.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (isOut) const SizedBox(width: 4),
          if (isOut) pinShape,
        ],
      ),
    );
  }
}

import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/theme/block_category.dart';
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

  static const double headerHeight = BlueprintNodeData.headerHeight;
  static const double pinRowHeight = 24.0;
  static const double pinVerticalPadding = 6.0;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final accent = tokens.accentRing;
    return GestureDetector(
      onTap: onSelect,
      onPanUpdate: onDragDelta != null
          ? (details) => onDragDelta!(details.delta)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: data.size.width,
        // Surface plate et neutre : la couleur de famille ne vit que dans la
        // pastille, le surtitre et les ports ; sélection = anneau d'action.
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : tokens.clusterBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
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
                                color: tokens.muted,
                                fontFamily: 'JetBrainsMono',
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

  /// En-tête unifié : pastille de catégorie + surtitre en majuscules + titre.
  Widget _buildHeader(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final tint = data.headerColor;
    final overline = data.overline;
    return Container(
      height: headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.clusterBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: BlockFamily.pastilleTint),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tint.withValues(alpha: BlockFamily.pastilleRing),
              ),
            ),
            child: Center(
              child: AppIcon.fromMaterial(data.icon, size: 16, color: tint),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null && overline.isNotEmpty)
                  Text(
                    overline.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      height: 1.2,
                      color: tint,
                    ),
                  ),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          // Suppression rangée dans un menu ⋮ (plus d'icône isolée).
          if (!data.isEntryPoint && onDelete != null && isSelected)
            PopupMenuButton<String>(
              tooltip: MaterialLocalizations.of(context).showMenuTooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: AppIcon.fromMaterial(
                Icons.more_vert,
                size: 16,
                color: tokens.muted,
              ),
              onSelected: (_) => onDelete?.call(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    MaterialLocalizations.of(context).deleteButtonTooltip,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPin(BuildContext context, BlueprintPin pin) {
    final isOut = pin.direction == BlueprintPinDirection.output;
    final tokens = HomeTokens.of(context);
    final pinColor = pin.customColor ?? data.headerColor;

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
            color: tokens.card,
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
              color: tokens.muted,
            ),
          ),
          if (isOut) const SizedBox(width: 4),
          if (isOut) pinShape,
        ],
      ),
    );
  }
}

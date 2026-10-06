import 'package:flutter/material.dart';

import '../../widgets/app_icon.dart';

/// Visual connector line drawn between two adjacent [ScratchBlock] widgets.
class ScratchBlockConnector extends StatelessWidget {
  const ScratchBlockConnector({
    super.key,
    this.color,
    this.height = 20,
    this.showArrow = false,
    this.onInsert,
  });

  /// Color of the connector line. Defaults to the theme's outline variant.
  final Color? color;

  /// Height of the connector segment.
  final double height;

  /// Whether to show a small downward arrow at the bottom.
  final bool showArrow;

  /// Optional callback to insert an action between the two connected blocks.
  final VoidCallback? onInsert;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.outlineVariant;
    final primaryColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (onInsert != null) {
      return SizedBox(
        height: height < 36 ? 36 : height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(child: _line(effectiveColor)),
                  if (showArrow)
                    AppIcon.fromMaterial(
                      Icons.arrow_drop_down,
                      size: 14,
                      color: effectiveColor,
                    ),
                ],
              ),
            ),
            Material(
              color: Theme.of(context).colorScheme.surface,
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                onTap: onInsert,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: effectiveColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: AppIcon.fromMaterial(
                    Icons.add,
                    size: 16,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: _line(effectiveColor)),
            if (showArrow)
              AppIcon.fromMaterial(
                Icons.arrow_drop_down,
                size: 14,
                color: effectiveColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(Color color) => Container(
    width: 2,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

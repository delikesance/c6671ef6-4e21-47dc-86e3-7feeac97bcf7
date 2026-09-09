import 'package:flutter/material.dart';

/// Visual connector line drawn between two adjacent [ScratchBlock] widgets.
class ScratchBlockConnector extends StatelessWidget {
  const ScratchBlockConnector({
    super.key,
    this.color,
    this.height = 24,
    this.showArrow = true,
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (onInsert != null) {
      return SizedBox(
        height: height < 32 ? 32 : height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(child: Container(width: 2, color: effectiveColor)),
                  if (showArrow)
                    Icon(Icons.arrow_drop_down, size: 14, color: effectiveColor),
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
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: effectiveColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add,
                    size: 13,
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
            Expanded(child: Container(width: 2, color: effectiveColor)),
            if (showArrow)
              Icon(Icons.arrow_drop_down, size: 14, color: effectiveColor),
          ],
        ),
      ),
    );
  }
}

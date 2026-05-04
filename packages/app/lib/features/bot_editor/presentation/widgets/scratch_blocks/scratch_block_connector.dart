import 'package:flutter/material.dart';

/// Visual connector line drawn between two adjacent [ScratchBlock] widgets.
class ScratchBlockConnector extends StatelessWidget {
  const ScratchBlockConnector({
    super.key,
    this.color,
    this.height = 24,
    this.showArrow = true,
  });

  /// Color of the connector line. Defaults to the theme's outline variant.
  final Color? color;

  /// Height of the connector segment.
  final double height;

  /// Whether to show a small downward arrow at the bottom.
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.outlineVariant;
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

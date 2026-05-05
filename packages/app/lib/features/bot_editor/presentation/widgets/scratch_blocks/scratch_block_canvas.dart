import 'package:flutter/material.dart';

import 'scratch_block_connector.dart';

/// A vertically scrollable canvas that lays out [ScratchBlock] widgets with
/// visual connectors between them.
///
/// Fixed blocks (metadata, entry point) are listed first, followed by
/// user-added action blocks that can be reordered via move-up/move-down.
class ScratchBlockCanvas extends StatelessWidget {
  const ScratchBlockCanvas({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.connectorColor,
    this.skipConnectorAfterIndices = const {},
  });

  /// The ordered list of block widgets to display. Connectors are inserted
  /// between each pair automatically.
  final List<Widget> children;

  /// Padding around the entire canvas.
  final EdgeInsets padding;

  /// Override color for the connector lines. Defaults to theme outline variant.
  final Color? connectorColor;

  /// Indices of children after which the connector should be omitted
  /// (e.g. final / cap blocks that terminate execution).
  final Set<int> skipConnectorAfterIndices;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1 && !skipConnectorAfterIndices.contains(i)) {
        items.add(ScratchBlockConnector(color: connectorColor));
      }
    }

    return RepaintBoundary(
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items,
        ),
      ),
    );
  }
}

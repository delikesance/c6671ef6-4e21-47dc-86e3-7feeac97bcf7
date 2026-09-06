import 'dart:io';
import 'package:flutter/material.dart';

import 'scratch_block_connector.dart';

/// A vertically scrollable canvas that lays out [ScratchBlock] widgets with
/// visual connectors between them.
///
/// Fixed blocks (metadata, entry point) are listed first, followed by
/// user-added action blocks that can be reordered via move-up/move-down.
class ScratchBlockCanvas extends StatefulWidget {
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
  State<ScratchBlockCanvas> createState() => _ScratchBlockCanvasState();
}

class _ScratchBlockCanvasState extends State<ScratchBlockCanvas> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      items.add(widget.children[i]);
      if (i < widget.children.length - 1) {
        if (!widget.skipConnectorAfterIndices.contains(i)) {
          items.add(ScratchBlockConnector(color: widget.connectorColor));
        } else {
          // Always maintain clean vertical breathing room between blocks even when
          // the arrow connector line is suppressed.
          items.add(const SizedBox(height: 12));
        }
      }
    }

    final isRunningTests = Platform.environment.containsKey('FLUTTER_TEST');
    final isDesktopPlatform =
        const [
          TargetPlatform.macOS,
          TargetPlatform.windows,
          TargetPlatform.linux,
        ].contains(Theme.of(context).platform) &&
        !isRunningTests;

    final scrollable = SingleChildScrollView(
      controller: isRunningTests ? null : _scrollController,
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      ),
    );

    return RepaintBoundary(
      child: isDesktopPlatform
          ? Scrollbar(controller: _scrollController, child: scrollable)
          : scrollable,
    );
  }
}

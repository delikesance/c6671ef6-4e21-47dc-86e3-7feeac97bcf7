import 'dart:io';
import 'package:flutter/material.dart';

import 'scratch_block_connector.dart';

/// A vertically scrollable canvas that lays out [ScratchBlock] widgets with
/// visual connectors between them.
///
/// Supports high-performance virtualized rendering and optional tactile
/// reordering via [onReorder].
class ScratchBlockCanvas extends StatefulWidget {
  const ScratchBlockCanvas({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.connectorColor,
    this.skipConnectorAfterIndices = const {},
    this.onReorder,
    this.onInsertAfter,
    this.shrinkWrap = false,
    this.physics,
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

  /// Optional callback for drag-and-drop reordering of blocks.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Optional callback to insert a new block after child at [index].
  final void Function(int index)? onInsertAfter;

  /// Whether the list should shrink-wrap its contents (e.g. when nested).
  final bool shrinkWrap;

  /// Scroll physics for the list.
  final ScrollPhysics? physics;

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

  Widget _buildItem(int index) {
    final child = widget.children[index];
    final childKey = child.key ?? ValueKey('scratch-canvas-child-$index');
    final showConnector = index < widget.children.length - 1;
    final isConnectorSuppressed = widget.skipConnectorAfterIndices.contains(index);

    return Column(
      key: childKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(child: child),
        if (showConnector) ...[
          if (!isConnectorSuppressed)
            ScratchBlockConnector(
              color: widget.connectorColor,
              onInsert: widget.onInsertAfter != null
                  ? () => widget.onInsertAfter!(index)
                  : null,
            )
          else
            const SizedBox(height: 12),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }

    final isRunningTests = Platform.environment.containsKey('FLUTTER_TEST');
    final isDesktopPlatform =
        const [
          TargetPlatform.macOS,
          TargetPlatform.windows,
          TargetPlatform.linux,
        ].contains(Theme.of(context).platform) &&
        !isRunningTests;

    final Widget scrollable;
    if (widget.onReorder != null) {
      scrollable = ReorderableListView.builder(
        scrollController: isRunningTests ? null : _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        buildDefaultDragHandles: false,
        itemCount: widget.children.length,
        itemBuilder: (context, index) => _buildItem(index),
        onReorder: widget.onReorder!,
      );
    } else {
      scrollable = ListView.builder(
        controller: isRunningTests ? null : _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: widget.children.length,
        itemBuilder: (context, index) => _buildItem(index),
      );
    }

    return RepaintBoundary(
      child: isDesktopPlatform
          ? Scrollbar(controller: _scrollController, child: scrollable)
          : scrollable,
    );
  }
}

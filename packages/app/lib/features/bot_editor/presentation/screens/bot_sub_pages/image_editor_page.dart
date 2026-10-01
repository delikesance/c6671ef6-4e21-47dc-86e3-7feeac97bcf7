/// Image Editor Page — visual editor for canvas image compositing operations.
///
/// Provides a read-only canvas preview + operations list + property editor
/// for authoring the [runtimeImageBlock] payload. Per the UX specs (v2
/// operations-based design), the canvas is read-only; users edit operation
/// parameters through the property panel.
///
/// ## Architecture
///
/// - Canvas preview: [CanvasPreviewWidget] (CustomPainter-based GPU rendering)
/// - Operations list: reorderable list with add/delete/duplicate controls
/// - Property editor: dynamic form based on the selected operation type
/// - Serialization: operations stored as `List<Map<String, dynamic>>` matching
///   the runtime executor format
///
/// ## Variable Support
///
/// Every property field shows a small variable icon (Icons.data_object)
/// in its suffix when variable suggestions are available. Tapping the
/// icon opens a dialog with a [VariableTextField] pre-populated with
/// `((` so autocomplete suggestions appear immediately. Selecting a
/// variable inserts the `((variableName))` placeholder into the field.
/// Fields support both literal values and `((variable))` placeholders
/// natively — no mode toggle needed.
///
/// ## Entry Point
///
/// Accessed from the [runtimeImageBlock] action card via an "Open Image Editor"
/// button. The editor reads/writes `payload['operations']`.
///
/// ## Related
///
/// - [CanvasPreviewWidget] — the read-only preview widget
/// - [action_card.dart] — the workflow block action card that provides the
///   entry point button
library;

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator_shared/bot_creator_shared.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

import '../../widgets/canvas_preview_widget.dart';
import '../../../../../core/widgets/variable_text_field.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';
// ─── Page Entry Point ──────────────────────────────────────────────────────

/// Full-screen image editor for canvas compositing operations.
///
/// Accepts an existing list of operations (or empty for a new canvas) and
/// returns the updated list when the user taps Save.
class ImageEditorPage extends StatefulWidget {
  /// The current list of canvas operations.
  final List<Map<String, dynamic>> operations;

  /// Variable suggestions for placeholder autocomplete in text fields.
  final List<VariableSuggestion> variableSuggestions;

  const ImageEditorPage({
    super.key,
    required this.operations,
    this.variableSuggestions = const [],
  });

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  late List<Map<String, dynamic>> _operations;
  int? _selectedIndex;
  String? _canvasError;
  double _zoom = 1.0;
  final Set<int> _hiddenIndices = {};

  // ── Undo/Redo ──────────────────────────────────────────────────────────

  static const _maxHistory = 30;

  /// Maximum total bytes across all history entries. When exceeded, the
  /// oldest entries are evicted before adding new ones.
  static const _maxHistoryBytes = 20 * 1024 * 1024; // 20 MB
  final List<List<Map<String, dynamic>>> _history = [];
  final List<int> _historyByteSizes = [];
  int _historyIndex = -1;
  int _totalHistoryBytes = 0;

  /// Per-field [TextEditingController]s so the properties panel reflects
  /// real-time position updates from canvas drag gestures.
  /// Keyed by the operation instance map to survive index changes (e.g. duplication/reordering).
  final Map<Map<String, dynamic>, Map<String, TextEditingController>>
  _propControllers = Map.identity();

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Deep-copy to avoid mutating the caller's list until save
    _operations = widget.operations
        .map((op) => Map<String, dynamic>.from(op))
        .toList();
    _pushHistory();
  }

  @override
  void dispose() {
    _clearPropControllers();
    super.dispose();
  }

  void _clearPropControllers() {
    for (final opControllers in _propControllers.values) {
      for (final c in opControllers.values) {
        c.dispose();
      }
    }
    _propControllers.clear();
  }

  bool get _hasCreate =>
      _operations.any((op) => (op['op'] ?? '').toString() == 'create');

  // ── Undo/Redo History ─────────────────────────────────────────────────

  void _pushHistory() {
    // Estimate byte size of the current operations list.
    final byteSize = _estimateByteSize(_operations);

    if (_historyIndex < _history.length - 1) {
      // Discard redo history beyond the current point.
      var removedBytes = 0;
      for (var i = _historyIndex + 1; i < _historyByteSizes.length; i++) {
        removedBytes += _historyByteSizes[i];
      }
      _history.removeRange(_historyIndex + 1, _history.length);
      _historyByteSizes.removeRange(
        _historyIndex + 1,
        _historyByteSizes.length,
      );
      _totalHistoryBytes -= removedBytes;
    }

    _history.add(
      _operations.map((op) => Map<String, dynamic>.from(op)).toList(),
    );
    _historyByteSizes.add(byteSize);
    _historyIndex = _history.length - 1;
    _totalHistoryBytes += byteSize;

    // Evict oldest entries when exceeding count or byte budget.
    while (_history.length > _maxHistory ||
        (_totalHistoryBytes > _maxHistoryBytes && _historyIndex > 0)) {
      _totalHistoryBytes -= _historyByteSizes.first;
      _history.removeAt(0);
      _historyByteSizes.removeAt(0);
      _historyIndex--;
    }
  }

  void _undo() {
    if (_historyIndex <= 0) return;
    _historyIndex--;
    setState(() {
      _operations = _history[_historyIndex]
          .map((op) => Map<String, dynamic>.from(op))
          .toList();
      _clearPropControllers();
      if (_selectedIndex != null && _selectedIndex! >= _operations.length) {
        _selectedIndex = _operations.isEmpty ? null : _operations.length - 1;
      }
    });
  }

  void _redo() {
    if (_historyIndex >= _history.length - 1) return;
    _historyIndex++;
    setState(() {
      _operations = _history[_historyIndex]
          .map((op) => Map<String, dynamic>.from(op))
          .toList();
      _clearPropControllers();
      if (_selectedIndex != null && _selectedIndex! >= _operations.length) {
        _selectedIndex = _operations.isEmpty ? null : _operations.length - 1;
      }
    });
  }

  bool get _canUndo => _historyIndex > 0;
  bool get _canRedo => _historyIndex < _history.length - 1;

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.image_editor_title),
        leading: IconButton(
          icon: const AppIcon.fromMaterial(Icons.arrow_back),
          onPressed: () {
            if (_hasUnsavedChanges()) {
              _showUnsavedDialog();
            } else {
              Navigator.pop(context, _operations);
            }
          },
        ),
        actions: [
          _buildUndoRedoActions(),
          const SizedBox(width: 4),
          _buildSaveButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          const Divider(height: 1),
          Expanded(
            child: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  // ── Toolbar ────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final tr = context.tr;
    const controlSpacing = SizedBox(width: 4);

    Widget buildAddLayerButton() {
      return PopupMenuButton<String>(
        onSelected: (opType) => _addOperation(opType),
        tooltip: tr.image_editor_add_operation,
        offset: const Offset(0, 40),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'container',
            child: Text(tr.image_editor_op_container),
          ),
          PopupMenuItem(
            value: 'loadImage',
            child: Text(tr.action_name_canvasLoadImageBlock),
          ),
          PopupMenuItem(
            value: 'drawText',
            child: Text(tr.action_name_canvasDrawTextBlock),
          ),
          PopupMenuItem(
            value: 'drawRect',
            child: Text(tr.action_name_canvasDrawRectBlock),
          ),
          PopupMenuItem(
            value: 'drawCircle',
            child: Text(tr.action_name_canvasDrawCircleBlock),
          ),
          PopupMenuItem(
            value: 'drawLine',
            child: Text(tr.action_name_canvasDrawLineBlock),
          ),
          PopupMenuItem(
            value: 'progressBar',
            child: Text(tr.image_editor_op_progress_bar),
          ),
          PopupMenuItem(
            value: 'compositeImage',
            child: Text(tr.image_editor_op_composite_image),
          ),
          PopupMenuItem(
            value: 'setPixel',
            child: Text(tr.image_editor_op_set_pixel),
          ),
          PopupMenuItem(
            value: 'invert',
            child: Text(tr.image_editor_op_invert),
          ),
          PopupMenuItem(
            value: 'grayscale',
            child: Text(tr.image_editor_op_grayscale),
          ),
          PopupMenuItem(
            value: 'rotate',
            child: Text(tr.image_editor_op_rotate),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.fromMaterial(Icons.add, size: 18, color: cs.onSurface),
              const SizedBox(width: 6),
              Text(
                tr.image_editor_add_layer,
                style: TextStyle(color: cs.onSurface, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildZoomControls() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _zoom > 0.25 ? _zoomOut : null,
            icon: const AppIcon.fromMaterial(Icons.zoom_out, size: 20),
            tooltip: tr.image_editor_zoom_out,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          controlSpacing,
          GestureDetector(
            onTap: _zoomToFit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: cs.surfaceContainerHighest,
              ),
              child: Text(
                '${(_zoom * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          controlSpacing,
          IconButton(
            onPressed: _zoom < 3.0 ? _zoomIn : null,
            icon: const AppIcon.fromMaterial(Icons.zoom_in, size: 20),
            tooltip: tr.image_editor_zoom_in,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          controlSpacing,
          IconButton(
            onPressed: _zoomToFit,
            icon: const AppIcon.fromMaterial(Icons.fit_screen, size: 18),
            tooltip: tr.image_editor_zoom_fit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          // ── Add Layer (always visible, left-aligned) ──
          buildAddLayerButton(),
          // ── Zoom controls (right-aligned on wide, scrollable on narrow) ──
          if (isWide) ...[
            const Spacer(),
            buildZoomControls(),
          ] else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const VerticalDivider(width: 1, indent: 10, endIndent: 10),
                    buildZoomControls(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Undo/Redo Buttons ─────────────────────────────────────────────────

  Widget _buildUndoRedoActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _canUndo ? _undo : null,
          icon: const AppIcon.fromMaterial(Icons.undo, size: 20),
          tooltip: context.tr.image_editor_undo,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        IconButton(
          onPressed: _canRedo ? _redo : null,
          icon: const AppIcon.fromMaterial(Icons.redo, size: 20),
          tooltip: context.tr.image_editor_redo,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  // ── Save Button (adaptive for narrow screens) ─────────────────────────

  Widget _buildSaveButton() {
    final isNarrow = MediaQuery.of(context).size.width < 360;
    if (isNarrow) {
      return IconButton(
        onPressed: () => Navigator.pop(context, _operations),
        icon: const AppIcon.fromMaterial(Icons.check, size: 20),
        tooltip: context.tr.common_save,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      );
    }
    return FilledButton.icon(
      onPressed: () => Navigator.pop(context, _operations),
      icon: const AppIcon.fromMaterial(Icons.check, size: 18),
      label: Text(context.tr.common_save),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  // ── Zoom ───────────────────────────────────────────────────────────────

  int get _canvasWidth {
    for (final op in _operations) {
      if ((op['op'] ?? '') == 'create') {
        return int.tryParse((op['width'] ?? '800').toString()) ?? 800;
      }
    }
    return 800;
  }

  int get _canvasHeight {
    for (final op in _operations) {
      if ((op['op'] ?? '') == 'create') {
        return int.tryParse((op['height'] ?? '600').toString()) ?? 600;
      }
    }
    return 600;
  }

  void _zoomIn() {
    setState(() => _zoom = (_zoom + 0.1).clamp(0.25, 3.0));
  }

  void _zoomOut() {
    setState(() => _zoom = (_zoom - 0.1).clamp(0.25, 3.0));
  }

  void _zoomToFit() {
    setState(() => _zoom = 1.0);
  }

  // ── Unsaved Changes ────────────────────────────────────────────────────

  bool _hasUnsavedChanges() {
    if (_operations.length != widget.operations.length) return true;
    for (var i = 0; i < _operations.length; i++) {
      final a = _operations[i];
      final b = i < widget.operations.length ? widget.operations[i] : null;
      if (b == null) return true;
      if (!_mapsEqual(a, b)) return true;
    }
    return false;
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key]?.toString() != b[key]?.toString()) return false;
    }
    return true;
  }

  void _showUnsavedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.command_unsaved_title),
        content: Text(context.tr.command_unsaved_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr.command_unsaved_keep),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, null);
            },
            child: Text(context.tr.common_discard),
          ),
        ],
      ),
    );
  }

  // ── Desktop: 3-zone layout (Preview | Operations | Properties) ─────────

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Operations list
        SizedBox(width: 280, child: _buildOperationsPanel()),
        const VerticalDivider(width: 1),
        // Center: Canvas preview
        Expanded(flex: 2, child: _buildCanvasPanel()),
        const VerticalDivider(width: 1),
        // Right: Properties
        SizedBox(width: 300, child: _buildPropertiesPanel()),
      ],
    );
  }

  // ── Mobile: tab-based layout ───────────────────────────────────────────

  /// Mobile layout: canvas on top, operations list always visible below.
  /// Tapping a layer tile opens the properties bottom sheet directly.
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Canvas preview — takes the majority of the screen height.
        Expanded(flex: 3, child: _buildCanvasPanel()),
        const Divider(height: 1),
        // Operations list — always visible, no tabs overhead.
        // SafeArea keeps it above the native navigation bar / gesture handle.
        Expanded(
          flex: 2,
          child: SafeArea(
            top: false,
            child: _buildOperationsPanel(isMobile: true),
          ),
        ),
      ],
    );
  }

  // ── Canvas Panel ──────────────────────────────────────────────────────

  Widget _buildCanvasPanel() {
    if (_canvasError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.warning_amber,
              size: 48,
              color: Colors.orange.shade300,
            ),
            const SizedBox(height: 12),
            Text(_canvasError!, style: const TextStyle(color: Colors.orange)),
          ],
        ),
      );
    }

    if (!_hasCreate) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.add_photo_alternate_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.image_editor_empty_hint(
                context.tr.action_name_canvasCreateBlock,
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _operations.add({
                    'op': 'create',
                    'width': '800',
                    'height': '600',
                    'color': '#2c2f33',
                  });
                  _selectedIndex = _operations.length - 1;
                  _canvasError = null;
                });
              },
              icon: const AppIcon.fromMaterial(Icons.add, size: 18),
              label: Text(context.tr.action_name_canvasCreateBlock),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: CanvasPreviewWidget(
                operations: _operations,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                borderRadius: BorderRadius.circular(8),
                selectedIndex: _selectedIndex,
                variableSuggestions: widget.variableSuggestions,
                zoom: _zoom,
                hiddenIndices: _hiddenIndices,
                onElementSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                onElementMoved: (index, canvasDx, canvasDy) {
                  setState(
                    () => _moveElementOnCanvas(index, canvasDx, canvasDy),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${(_zoom * 100).round()}%  —  $_canvasWidth×$_canvasHeight',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Operations Panel ───────────────────────────────────────────────────

  Widget _buildOperationsPanel({bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  context.tr.image_editor_operations,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_operations.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              if (isMobile) ...[
                const Spacer(),
                Text(
                  context.tr.image_editor_tap_to_edit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _operations.isEmpty
              ? Center(
                  child: Text(
                    context.tr.image_editor_no_operations,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: _operations.length,
                  onReorderItem: _onReorderItem,
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) =>
                      _buildOperationTile(index, isMobile: isMobile),
                ),
        ),
      ],
    );
  }

  Widget _buildOperationTile(int index, {bool isMobile = false}) {
    final op = _operations[index];
    final opType = (op['op'] ?? '').toString();
    final isSelected = _selectedIndex == index;
    final isHidden = _hiddenIndices.contains(index);
    final cs = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey('op_${identityHashCode(op)}'),
      decoration: BoxDecoration(
        color: isSelected ? cs.primaryContainer.withValues(alpha: 0.3) : null,
        border: Border(
          left: BorderSide(
            color: isSelected ? cs.primary : Colors.transparent,
            width: 3,
          ),
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (isMobile) _showPropertiesBottomSheet(index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              if (opType != 'create')
                ReorderableDragStartListener(
                  index: index,
                  child: const AppIcon.fromMaterial(
                    Icons.drag_handle,
                    size: 18,
                    color: Colors.grey,
                  ),
                )
              else
                const SizedBox(width: 18),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  setState(() {
                    if (isHidden) {
                      _hiddenIndices.remove(index);
                    } else {
                      _hiddenIndices.add(index);
                    }
                  });
                },
                child: AppIcon.fromMaterial(
                  isHidden ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: isHidden
                      ? Colors.grey
                      : cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              AppIcon.fromMaterial(
                _opIcon(opType),
                size: 18,
                color: isHidden ? Colors.grey : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _opLabel(op),
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                    color: isHidden
                        ? Theme.of(context).colorScheme.outline
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  _pushHistory();
                  setState(() {
                    _operations.removeAt(index);
                    _hiddenIndices.remove(index);
                    final newHidden = <int>{};
                    for (final h in _hiddenIndices) {
                      newHidden.add(h > index ? h - 1 : h);
                    }
                    _hiddenIndices.clear();
                    _hiddenIndices.addAll(newHidden);
                    if (_selectedIndex == index) {
                      _selectedIndex = null;
                    } else if (_selectedIndex != null &&
                        _selectedIndex! > index) {
                      _selectedIndex = _selectedIndex! - 1;
                    }
                  });
                },
                child: AppIcon.fromMaterial(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    if (_operations.isNotEmpty && _operations.first['op'] == 'create') {
      if (oldIndex == 0 || newIndex == 0) {
        return;
      }
    }
    setState(() {
      final op = _operations.removeAt(oldIndex);
      _operations.insert(newIndex, op);
      final wasHidden = _hiddenIndices.contains(oldIndex);
      _hiddenIndices.remove(oldIndex);
      final newHidden = <int>{};
      for (final h in _hiddenIndices) {
        if (oldIndex < newIndex) {
          newHidden.add(h > oldIndex && h <= newIndex ? h - 1 : h);
        } else {
          newHidden.add(h >= newIndex && h < oldIndex ? h + 1 : h);
        }
      }
      _hiddenIndices.clear();
      _hiddenIndices.addAll(newHidden);
      if (wasHidden) _hiddenIndices.add(newIndex);
      if (_selectedIndex == oldIndex) {
        _selectedIndex = newIndex;
      } else if (_selectedIndex != null) {
        if (oldIndex < newIndex &&
            _selectedIndex! > oldIndex &&
            _selectedIndex! <= newIndex) {
          _selectedIndex = _selectedIndex! - 1;
        } else if (oldIndex > newIndex &&
            _selectedIndex! >= newIndex &&
            _selectedIndex! < oldIndex) {
          _selectedIndex = _selectedIndex! + 1;
        }
      }
    });
    _pushHistory();
  }

  // ── Properties Panel ───────────────────────────────────────────────────

  Widget _buildPropertiesPanel() {
    final cs = Theme.of(context).colorScheme;

    if (_selectedIndex == null) {
      if (!_hasCreate) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.tr.image_editor_select_operation,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.outline, fontSize: 13),
            ),
          ),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.image_editor_canvas,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              context.tr.image_editor_width,
              '${_canvasWidth}px',
            ),
            _buildReadOnlyField(
              context.tr.image_editor_height,
              '${_canvasHeight}px',
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.image_editor_ops_summary(
                _operations.length,
                _hiddenIndices.length,
              ),
              style: TextStyle(color: cs.outline, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final index = _selectedIndex!;
    final op = _operations[index];
    final opType = (op['op'] ?? '').toString();
    final isHidden = _hiddenIndices.contains(index);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr.image_editor_properties,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              InkWell(
                onTap: () {
                  _pushHistory();
                  setState(() {
                    _operations.removeAt(index);
                    _hiddenIndices.remove(index);
                    final newHidden = <int>{};
                    for (final h in _hiddenIndices) {
                      newHidden.add(h > index ? h - 1 : h);
                    }
                    _hiddenIndices.clear();
                    _hiddenIndices.addAll(newHidden);
                    _selectedIndex = null;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AppIcon.fromMaterial(
                    Icons.delete_outline,
                    size: 18,
                    color: cs.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_opLabel(op), style: TextStyle(color: cs.outline, fontSize: 13)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(context.tr.image_editor_visible),
            value: !isHidden,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) {
              setState(() {
                if (v) {
                  _hiddenIndices.remove(index);
                } else {
                  _hiddenIndices.add(index);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          if (opType != 'create') ...[
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    context.tr.image_editor_opacity,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value:
                        (double.tryParse((op['opacity'] ?? '1').toString()) ??
                                1.0)
                            .clamp(0.0, 1.0),
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label:
                        '${((double.tryParse((op['opacity'] ?? '1').toString()) ?? 1.0) * 100).round()}%',
                    onChanged: (v) {
                      setState(() {
                        if (v >= 1.0) {
                          op.remove('opacity');
                        } else {
                          op['opacity'] = v.toStringAsFixed(2);
                        }
                      });
                    },
                    onChangeEnd: (_) => _pushHistory(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const Divider(),
          const SizedBox(height: 8),
          ..._buildPropertyFields(opType, op, index),
          if (opType != 'create') ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _pushHistory();
                setState(() {
                  _operations.insert(index + 1, Map<String, dynamic>.from(op));
                  _selectedIndex = index + 1;
                });
              },
              icon: const AppIcon.fromMaterial(Icons.copy, size: 16),
              label: Text(context.tr.common_duplicate),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mobile Properties Bottom Sheet ─────────────────────────────────────

  /// Opens a modal bottom sheet with the properties of the layer at [index].
  ///
  /// A [StatefulBuilder] is used so that interactive controls (sliders,
  /// switches, text fields) visually update inside the sheet in real time
  /// while [setState] simultaneously refreshes the canvas preview.
  void _showPropertiesBottomSheet(int index) {
    if (index < 0 || index >= _operations.length) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Calls both parent setState (canvas preview) and sheet setState
          // (sheet UI) so all controls stay in sync.
          void combinedSet(VoidCallback fn) {
            fn();
            if (mounted) setState(() {});
            setSheetState(() {});
          }

          void closeSheet() => Navigator.pop(sheetCtx);
          return _buildPropertiesSheetContent(
            ctx,
            index,
            combinedSet,
            closeSheet,
          );
        },
      ),
    );
  }

  /// Builds the content of the properties bottom sheet for the layer at [index].
  Widget _buildPropertiesSheetContent(
    BuildContext sheetContext,
    int index,
    void Function(VoidCallback) combinedSet,
    VoidCallback closeSheet,
  ) {
    if (index < 0 || index >= _operations.length) {
      return const SizedBox.shrink();
    }
    final op = _operations[index];
    final opType = (op['op'] ?? '').toString();
    final cs = Theme.of(context).colorScheme;
    final isHidden = _hiddenIndices.contains(index);

    return SafeArea(
      top: false,
      child: Padding(
        // Slide content above the software keyboard when it opens.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ───────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Header: icon + label + duplicate + delete ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  AppIcon.fromMaterial(
                    _opIcon(opType),
                    size: 20,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _opLabel(op),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (opType != 'create')
                    IconButton(
                      onPressed: () {
                        _pushHistory();
                        combinedSet(() {
                          _operations.insert(
                            index + 1,
                            Map<String, dynamic>.from(op),
                          );
                          _selectedIndex = index + 1;
                        });
                        closeSheet();
                      },
                      icon: const AppIcon.fromMaterial(
                        Icons.copy_outlined,
                        size: 20,
                      ),
                      tooltip: context.tr.common_duplicate,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      _pushHistory();
                      setState(() {
                        _operations.removeAt(index);
                        _hiddenIndices.remove(index);
                        final newHidden = <int>{};
                        for (final h in _hiddenIndices) {
                          newHidden.add(h > index ? h - 1 : h);
                        }
                        _hiddenIndices.clear();
                        _hiddenIndices.addAll(newHidden);
                        _selectedIndex = null;
                      });
                      closeSheet();
                    },
                    icon: AppIcon.fromMaterial(
                      Icons.delete_outline,
                      color: cs.error,
                      size: 20,
                    ),
                    tooltip: context.tr.common_delete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Scrollable property fields ─────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text(context.tr.image_editor_visible),
                      value: !isHidden,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        combinedSet(() {
                          if (v) {
                            _hiddenIndices.remove(index);
                          } else {
                            _hiddenIndices.add(index);
                          }
                        });
                      },
                    ),
                    if (opType != 'create') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(
                              context.tr.image_editor_opacity,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value:
                                  (double.tryParse(
                                            (op['opacity'] ?? '1').toString(),
                                          ) ??
                                          1.0)
                                      .clamp(0.0, 1.0),
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              label:
                                  '${((double.tryParse((op['opacity'] ?? '1').toString()) ?? 1.0) * 100).round()}%',
                              onChanged: (v) {
                                combinedSet(() {
                                  if (v >= 1.0) {
                                    op.remove('opacity');
                                  } else {
                                    op['opacity'] = v.toStringAsFixed(2);
                                  }
                                });
                              },
                              onChangeEnd: (_) => _pushHistory(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    const Divider(),
                    const SizedBox(height: 12),
                    ..._buildPropertyFields(
                      opType,
                      op,
                      index,
                      combinedSet: combinedSet,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPropertyFields(
    String opType,
    Map<String, dynamic> op,
    int index, {
    void Function(VoidCallback)? combinedSet,
  }) {
    final fields = <Widget>[];
    final tr = context.tr;
    final hasVars = widget.variableSuggestions.isNotEmpty;
    // When called from the bottom sheet, combinedSet updates both the sheet
    // UI and the parent canvas; otherwise falls back to the parent setState.
    final mutate = combinedSet ?? setState;

    /// Shows a dialog with a [VariableTextField] pre-populated with `((`
    /// so autocomplete suggestions appear immediately. On accept, inserts
    /// the selected variable into the operation map and syncs the prop controller.
    void showVariablePicker(String key) {
      // Show current field value so the user can insert at cursor position.
      final currentFieldValue = (op[key] ?? '').toString();
      final vc = TextEditingController(text: currentFieldValue);
      vc.selection = TextSelection.collapsed(offset: currentFieldValue.length);

      showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr.image_editor_insert_variable),
          content: SizedBox(
            width: 420,
            height: 500,
            child: VariableTextField(
              label: context.tr.image_editor_variable_label,
              hint: context.tr.image_editor_variable_hint,
              suggestions: widget.variableSuggestions,
              controller: vc,
              onChanged: (_) {},
              alwaysShowSuggestions: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, vc.text),
              child: Text(context.tr.image_editor_insert),
            ),
          ],
        ),
      ).then((result) {
        if (result != null) {
          mutate(() {
            op[key] = result;
            final c = _propControllers[op]?[key];
            if (c != null) {
              c.text = result;
            }
          });
        }
      });
    }

    /// Builds the suffix icon row for a field. When variable suggestions
    /// are available, the Icons.data_object icon appears alongside any
    /// type-specific icon (color preview or image picker).
    Widget? buildSuffix(
      String fieldKey,
      int opIndex,
      Map<String, dynamic> operation,
      bool isColor,
      bool isUrl,
    ) {
      if (!hasVars && !isColor && !isUrl) return null;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isColor)
            GestureDetector(
              onTap: () => _showColorPicker(operation, fieldKey, opIndex),
              child:
                  _buildColorPreview(op[fieldKey]) ?? const SizedBox.shrink(),
            ),
          if (isUrl)
            IconButton(
              icon: const AppIcon.fromMaterial(Icons.image, size: 20),
              onPressed: () => _pickImage(fieldKey),
              tooltip: context.tr.image_editor_pick_image,
              visualDensity: VisualDensity.compact,
            ),
          if (hasVars)
            IconButton(
              icon: const AppIcon.fromMaterial(Icons.data_object, size: 18),
              onPressed: () => showVariablePicker(fieldKey),
              tooltip: context.tr.image_editor_insert_variable,
              visualDensity: VisualDensity.compact,
            ),
        ],
      );
    }

    void addField(
      String label,
      String key, {
      String? hint,
      TextInputType? keyboardType,
      bool isColor = false,
      bool isUrl = false,
      void Function(String)? onSubmitted,
    }) {
      final suffix = buildSuffix(key, index, op, isColor, isUrl);

      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            key: ValueKey('${index}_$key'),
            controller: _getPropController(op, key, (op[key] ?? '').toString()),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: suffix,
            ),
            keyboardType: keyboardType,
            onChanged: (value) {
              mutate(() {
                if (value.isEmpty) {
                  op.remove(key);
                } else {
                  op[key] = value;
                }
              });
            },
            onFieldSubmitted: onSubmitted,
          ),
        ),
      );
    }

    /// Finds a container by name in the current operations list and returns
    /// its (x, y) position, or null if not found.
    (double, double)? findContainerPos(String name) {
      if (name.isEmpty) return null;
      for (final candidate in _operations) {
        if ((candidate['op'] ?? '') == 'container' &&
            (candidate['name'] ?? '').toString().trim() == name) {
          final cx = double.tryParse((candidate['x'] ?? '0').toString()) ?? 0;
          final cy = double.tryParse((candidate['y'] ?? '0').toString()) ?? 0;
          return (cx, cy);
        }
      }
      return null;
    }

    /// Converts operation coordinates to container-relative when the user
    /// assigns or changes a container reference.
    void convertToRelative(
      String newContainerName,
      Map<String, dynamic> targetOp,
    ) {
      final oldContainerName = (targetOp['container'] ?? '').toString().trim();
      final newPos = findContainerPos(newContainerName);
      final opTypeKey = (targetOp['op'] ?? '').toString();

      // Determine which position keys to convert based on operation type.
      List<String> posKeys;
      switch (opTypeKey) {
        case 'drawLine':
          posKeys = ['x1', 'y1', 'x2', 'y2'];
          break;
        default:
          posKeys = ['x', 'y'];
      }

      // If switching FROM another container, convert back to absolute first.
      if (oldContainerName.isNotEmpty) {
        final oldPos = findContainerPos(oldContainerName);
        if (oldPos != null) {
          for (final k in posKeys) {
            final v = double.tryParse((targetOp[k] ?? '0').toString()) ?? 0;
            targetOp[k] = (v + (k.contains('y') ? oldPos.$2 : oldPos.$1))
                .toStringAsFixed(0);
          }
        }
      }

      // Convert to new container-relative coordinates.
      if (newPos != null && newContainerName.isNotEmpty) {
        for (final k in posKeys) {
          final v = double.tryParse((targetOp[k] ?? '0').toString()) ?? 0;
          targetOp[k] = (v - (k.contains('y') ? newPos.$2 : newPos.$1))
              .toStringAsFixed(0);
        }
      }

      // Sync prop controllers so the UI reflects the converted values.
      for (final k in posKeys) {
        final c = _propControllers[op]?[k];
        if (c != null) {
          c.text = (targetOp[k] ?? '').toString();
        }
      }
    }

    switch (opType) {
      case 'create':
        addField(
          tr.image_editor_width,
          'width',
          hint: '800',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_height,
          'height',
          hint: '600',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_background_color,
          'color',
          hint: '#2c2f33',
          isColor: true,
        );
        break;
      case 'container':
        addField(tr.common_name, 'name', hint: 'frame');
        addField('X', 'x', hint: '0', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '0', keyboardType: TextInputType.number);
        addField(
          tr.image_editor_width,
          'width',
          hint: '200',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_height,
          'height',
          hint: '100',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.embed_section_color,
          'color',
          hint: tr.image_editor_hint_optional_background,
          isColor: true,
        );
        break;
      case 'loadImage':
        addField(
          tr.embed_label_image_url,
          'url',
          hint: 'https://... or data:image/...',
          isUrl: true,
        );
        addField('X', 'x', hint: '0', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '0', keyboardType: TextInputType.number);
        addField(
          tr.image_editor_width,
          'width',
          hint: tr.image_editor_hint_auto_size,
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_height,
          'height',
          hint: tr.image_editor_hint_auto_size,
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_container,
          'container',
          hint: tr.image_editor_hint_parent_container,
          onSubmitted: (v) => convertToRelative(v, op),
        );
        break;
      case 'drawText':
        addField(tr.image_editor_field_text, 'text', hint: 'Hello World');
        addField('X', 'x', hint: '50', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '200', keyboardType: TextInputType.number);
        addField(
          tr.image_editor_field_font_size,
          'fontSize',
          hint: '48',
          keyboardType: TextInputType.number,
        );
        addField(tr.embed_section_color, 'color', hint: 'white', isColor: true);
        addField(
          tr.image_editor_field_max_width,
          'maxWidth',
          hint: tr.image_editor_hint_container_width,
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_text_align,
          'textAlign',
          hint: 'left, center, or right',
        );
        addField(
          tr.image_editor_field_container,
          'container',
          hint: tr.image_editor_hint_parent_container,
          onSubmitted: (v) => convertToRelative(v, op),
        );
        break;
      case 'drawRect':
        addField('X', 'x', hint: '0', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '0', keyboardType: TextInputType.number);
        addField(
          tr.image_editor_width,
          'width',
          hint: '100',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_height,
          'height',
          hint: '100',
          keyboardType: TextInputType.number,
        );
        addField(tr.embed_section_color, 'color', hint: 'white', isColor: true);
        addField(
          tr.image_editor_field_blend,
          'blend',
          hint: 'multiply, screen, overlay, or empty',
        );
        addField(
          tr.image_editor_field_container,
          'container',
          hint: tr.image_editor_hint_parent_container,
          onSubmitted: (v) => convertToRelative(v, op),
        );
        // Fill toggle
        fields.add(
          _buildCheckbox(
            op,
            'fill',
            tr.image_editor_field_fill,
            defaultValue: true,
            mutate: mutate,
          ),
        );
        break;
      case 'drawCircle':
        addField('X', 'x', hint: '200', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '200', keyboardType: TextInputType.number);
        addField(
          tr.image_editor_field_radius,
          'radius',
          hint: '50',
          keyboardType: TextInputType.number,
        );
        addField(tr.embed_section_color, 'color', hint: 'white', isColor: true);
        addField(
          tr.image_editor_field_blend,
          'blend',
          hint: 'multiply, screen, overlay, or empty',
        );
        addField(
          tr.image_editor_field_container,
          'container',
          hint: tr.image_editor_hint_parent_container,
          onSubmitted: (v) => convertToRelative(v, op),
        );
        fields.add(
          _buildCheckbox(
            op,
            'fill',
            tr.image_editor_field_fill,
            defaultValue: true,
            mutate: mutate,
          ),
        );
        break;
      case 'drawLine':
        addField('X1', 'x1', hint: '0', keyboardType: TextInputType.number);
        addField('Y1', 'y1', hint: '0', keyboardType: TextInputType.number);
        addField('X2', 'x2', hint: '100', keyboardType: TextInputType.number);
        addField('Y2', 'y2', hint: '100', keyboardType: TextInputType.number);
        addField(tr.embed_section_color, 'color', hint: 'white', isColor: true);
        addField(
          tr.image_editor_field_thickness,
          'thickness',
          hint: '1',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_blend,
          'blend',
          hint: 'multiply, screen, overlay, or empty',
        );
        addField(
          tr.image_editor_field_container,
          'container',
          hint: tr.image_editor_hint_parent_container,
          onSubmitted: (v) => convertToRelative(v, op),
        );
        break;
      case 'compositeImage':
        addField(
          tr.embed_label_image_url,
          'url',
          hint: 'https://... or data:image/...',
          isUrl: true,
        );
        addField('X', 'x', hint: '0', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '0', keyboardType: TextInputType.number);
        addField(
          tr.image_editor_width,
          'width',
          hint: '100',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_height,
          'height',
          hint: '100',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_shape,
          'shape',
          hint: 'circle, rounded:20, triangle, or empty',
        );
        addField(
          tr.image_editor_field_blend,
          'blend',
          hint: 'overlay, multiply, screen, or empty',
        );
        break;
      case 'progressBar':
        addField('X', 'x', hint: '0', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '0', keyboardType: TextInputType.number);
        addField(
          tr.image_editor_width,
          'width',
          hint: '100',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_height,
          'height',
          hint: '20',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_percentage,
          'percentage',
          hint: '50',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_bar_color,
          'barColor',
          hint: '#4285F4',
          isColor: true,
        );
        addField(
          tr.image_editor_field_track_color,
          'trackColor',
          hint: '#E0E0E0',
          isColor: true,
        );
        addField(
          tr.image_editor_field_text_color,
          'textColor',
          hint: '#FFFFFF',
          isColor: true,
        );
        addField(
          tr.image_editor_field_border_width,
          'borderWidth',
          hint: '0',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_border_radius,
          'borderRadius',
          hint: '0',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_orientation,
          'orientation',
          hint: 'horizontal or vertical',
        );
        addField(
          tr.image_editor_field_font_size,
          'fontSize',
          hint: '14',
          keyboardType: TextInputType.number,
        );
        addField(
          tr.image_editor_field_container,
          'container',
          hint: tr.image_editor_hint_parent_container,
          onSubmitted: (v) => convertToRelative(v, op),
        );
        break;
      case 'setPixel':
        addField('X', 'x', hint: '0', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '0', keyboardType: TextInputType.number);
        addField(tr.embed_section_color, 'color', hint: 'white', isColor: true);
        addField(
          tr.image_editor_field_container,
          'container',
          hint: tr.image_editor_hint_parent_container,
          onSubmitted: (v) => convertToRelative(v, op),
        );
        break;
      case 'rotate':
        addField(
          tr.image_editor_field_angle,
          'angle',
          hint: '90',
          keyboardType: TextInputType.number,
        );
        break;
    }

    return fields;
  }

  Widget _buildCheckbox(
    Map<String, dynamic> op,
    String key,
    String label, {
    bool defaultValue = false,
    void Function(VoidCallback)? mutate,
  }) {
    final current = op[key]?.toString().toLowerCase().trim();
    final isChecked =
        current == 'true' ||
        current == 'yes' ||
        current == '1' ||
        (current == null && defaultValue);
    final doSet = mutate ?? setState;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(label),
        value: isChecked,
        dense: true,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) {
          doSet(() {
            op[key] = v.toString();
          });
        },
      ),
    );
  }

  Widget? _buildColorPreview(dynamic rawColor) {
    final s = (rawColor ?? '').toString().trim();
    if (s.isEmpty) return null;
    final color = _tryParseColor(s);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24),
        ),
      ),
    );
  }

  /// Returns (or creates) a [TextEditingController] for the given operation field.
  ///
  /// Uses the map [_propControllers] to cache controllers so that external
  /// value changes (e.g. from canvas drag) can update the displayed text
  /// without recreating the widget.
  TextEditingController _getPropController(
    Map<String, dynamic> op,
    String key,
    String initial,
  ) {
    var opControllers = _propControllers[op];
    if (opControllers == null) {
      opControllers = {};
      _propControllers[op] = opControllers;
    }
    var c = opControllers[key];
    if (c == null) {
      c = TextEditingController(text: initial);
      opControllers[key] = c;
    }
    return c;
  }

  // ── Actions ────────────────────────────────────────────────────────────

  void _addOperation(String opType) {
    final defaults = <String, dynamic>{};
    switch (opType) {
      case 'create':
        defaults.addAll({
          'op': 'create',
          'width': '800',
          'height': '600',
          'color': '#2c2f33',
        });
        _canvasError = null;
        break;
      case 'container':
        defaults.addAll({
          'op': 'container',
          'name': 'frame',
          'x': '0',
          'y': '0',
          'width': '200',
          'height': '100',
          'color': '',
        });
        break;
      case 'loadImage':
        defaults.addAll({
          'op': 'loadImage',
          'url': '',
          'x': '0',
          'y': '0',
          'width': '',
          'height': '',
        });
        break;
      case 'drawText':
        defaults.addAll({
          'op': 'drawText',
          'text': 'Hello',
          'x': '50',
          'y': '200',
          'fontSize': '48',
          'color': 'white',
        });
        break;
      case 'drawRect':
        defaults.addAll({
          'op': 'drawRect',
          'x': '0',
          'y': '0',
          'width': '100',
          'height': '100',
          'color': 'white',
          'fill': 'true',
          'blend': '',
        });
        break;
      case 'drawCircle':
        defaults.addAll({
          'op': 'drawCircle',
          'x': '200',
          'y': '200',
          'radius': '50',
          'color': 'white',
          'fill': 'true',
          'blend': '',
        });
        break;
      case 'drawLine':
        defaults.addAll({
          'op': 'drawLine',
          'x1': '0',
          'y1': '0',
          'x2': '100',
          'y2': '100',
          'color': 'white',
          'thickness': '1',
          'blend': '',
        });
        break;
      case 'compositeImage':
        defaults.addAll({
          'op': 'compositeImage',
          'url': '',
          'x': '0',
          'y': '0',
          'width': '100',
          'height': '100',
          'shape': '',
          'blend': '',
        });
        break;
      case 'progressBar':
        defaults.addAll({
          'op': 'progressBar',
          'x': '0',
          'y': '0',
          'width': '100',
          'height': '20',
          'percentage': '50',
          'barColor': '#4285F4',
          'trackColor': '#E0E0E0',
          'textColor': '#FFFFFF',
          'borderWidth': '0',
          'borderRadius': '0',
          'orientation': 'horizontal',
          'fontSize': '14',
        });
        break;
      case 'setPixel':
        defaults.addAll({
          'op': 'setPixel',
          'x': '0',
          'y': '0',
          'color': 'white',
        });
        break;
      case 'invert':
        defaults.addAll({'op': 'invert'});
        break;
      case 'grayscale':
        defaults.addAll({'op': 'grayscale'});
        break;
      case 'rotate':
        defaults.addAll({'op': 'rotate', 'angle': '90'});
        break;
    }
    _pushHistory();
    setState(() {
      final insertIndex = _selectedIndex != null
          ? _selectedIndex! + 1
          : _operations.length;
      _operations.insert(insertIndex, defaults);
      _selectedIndex = insertIndex;
    });
  }

  /// Move a drawable operation by the given canvas coordinate deltas.
  ///
  /// Updates the appropriate position fields based on the operation type:
  /// - container, drawText, drawRect, drawCircle, loadImage: `x`, `y`
  /// - drawLine: `x1`, `y1`, `x2`, `y2` (moves both endpoints)
  void _moveElementOnCanvas(int index, double dx, double dy) {
    if (index < 0 || index >= _operations.length) return;
    final op = _operations[index];
    final opType = (op['op'] ?? '').toString();
    final movedKeys = <String>[];

    void shiftX(String key, double d) {
      if (!op.containsKey(key)) return;
      if (_hasPlaceholder(op[key])) return;
      final current = double.tryParse((op[key] ?? '').toString()) ?? 0;
      op[key] = (current + d).toStringAsFixed(0);
      movedKeys.add(key);
    }

    switch (opType) {
      case 'container':
      case 'drawText':
      case 'drawRect':
      case 'drawCircle':
      case 'progressBar':
      case 'setPixel':
        shiftX('x', dx);
        shiftX('y', dy);
        break;
      case 'loadImage':
      case 'compositeImage':
        shiftX('x', dx);
        shiftX('y', dy);
        break;
      case 'drawLine':
        shiftX('x1', dx);
        shiftX('y1', dy);
        shiftX('x2', dx);
        shiftX('y2', dy);
        break;
    }

    // Sync the properties panel controllers so position fields update
    // in real time as the user drags the element on canvas.
    for (final key in movedKeys) {
      final controller = _propControllers[op]?[key];
      if (controller != null) {
        controller.text = (op[key] ?? '').toString();
      }
    }
  }

  Future<void> _pickImage(String key) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null || file.path!.isEmpty) return;
      final filePath = file.path!;
      final bytes = await File(filePath).readAsBytes();
      final ext = filePath.split('.').last.toLowerCase();
      final mime =
          {
            'png': 'image/png',
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'gif': 'image/gif',
            'webp': 'image/webp',
            'bmp': 'image/bmp',
          }[ext] ??
          'image/png';
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      setState(() {
        _operations[_selectedIndex!][key] = dataUrl;
      });
      _pushHistory();
    } catch (_) {
      // File picker error — silently ignore
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Estimates the approximate memory footprint of an operations list in bytes.
  ///
  /// Uses a conservative per-map overhead + sum of all string lengths. Not
  /// exact, but good enough for an LRU-style eviction budget.
  int _estimateByteSize(List<Map<String, dynamic>> operations) {
    var total = 0;
    for (final op in operations) {
      total += 64; // per-map overhead estimate
      for (final entry in op.entries) {
        total += (entry.key.length * 2) + 64; // key size (UTF-16) + overhead
        final value = entry.value;
        if (value is String) {
          total += value.length * 2; // UTF-16
        } else if (value != null) {
          total += value.toString().length * 2 + 16;
        }
      }
    }
    return total;
  }

  bool _hasPlaceholder(dynamic value) {
    if (value == null) return false;
    final s = value.toString();
    return s.contains('((') || s.contains('#{');
  }

  IconData _opIcon(String opType) {
    switch (opType) {
      case 'create':
        return Icons.add_to_photos;
      case 'container':
        return Icons.dashboard_customize;
      case 'loadImage':
        return Icons.image;
      case 'drawText':
        return Icons.text_fields;
      case 'drawRect':
        return Icons.crop_square;
      case 'drawCircle':
        return Icons.circle_outlined;
      case 'drawLine':
        return Icons.show_chart;
      case 'compositeImage':
        return Icons.layers;
      case 'progressBar':
        return Icons.linear_scale;
      case 'setPixel':
        return Icons.adjust;
      case 'invert':
        return Icons.invert_colors;
      case 'grayscale':
        return Icons.filter_b_and_w;
      case 'rotate':
        return Icons.rotate_right;
      default:
        return Icons.help_outline;
    }
  }

  String _opLabel(Map<String, dynamic> op) {
    final tr = context.tr;
    final opType = (op['op'] ?? '').toString();
    switch (opType) {
      case 'create':
        final w = op['width'] ?? '800';
        final h = op['height'] ?? '600';
        return '${tr.action_name_canvasCreateBlock} ($w×$h)';
      case 'container':
        final name = (op['name'] ?? 'frame').toString();
        final w = op['width'] ?? '200';
        final h = op['height'] ?? '100';
        return '${tr.image_editor_field_container}: $name ($w×$h)';
      case 'loadImage':
        final url = (op['url'] ?? '').toString();
        final label = url.isNotEmpty
            ? (url.length > 30 ? '${url.substring(0, 30)}…' : url)
            : tr.image_editor_no_url;
        final x = op['x'] ?? '0';
        final y = op['y'] ?? '0';
        return '${tr.action_name_canvasLoadImageBlock}: $label ($x,$y)';
      case 'drawText':
        final text = (op['text'] ?? '').toString();
        final label = text.length > 20 ? '${text.substring(0, 20)}…' : text;
        return '${tr.action_name_canvasDrawTextBlock}: "$label"';
      case 'drawRect':
        return tr.action_name_canvasDrawRectBlock;
      case 'drawCircle':
        return tr.action_name_canvasDrawCircleBlock;
      case 'drawLine':
        return tr.action_name_canvasDrawLineBlock;
      case 'compositeImage':
        final url = (op['url'] ?? '').toString();
        final label = url.isNotEmpty
            ? (url.length > 25 ? '${url.substring(0, 25)}…' : url)
            : tr.image_editor_no_url;
        return '${tr.image_editor_op_composite_image}: $label';
      case 'progressBar':
        final percentage = op['percentage'] ?? '50';
        return '${tr.image_editor_op_progress_bar}: $percentage%';
      case 'setPixel':
        final x = op['x'] ?? '0';
        final y = op['y'] ?? '0';
        return '${tr.image_editor_op_set_pixel} ($x,$y)';
      case 'invert':
        return tr.image_editor_op_invert;
      case 'grayscale':
        return tr.image_editor_op_grayscale;
      case 'rotate':
        final angle = op['angle'] ?? '90';
        return '${tr.image_editor_op_rotate} ($angle°)';
      default:
        return '${tr.image_editor_unknown} ($opType)';
    }
  }

  void _showColorPicker(
    Map<String, dynamic> operation,
    String fieldKey,
    int opIndex,
  ) {
    final currentColor = _tryParseColor((operation[fieldKey] ?? '').toString());
    final hsv = HSVColor.fromColor(currentColor);

    var hue = hsv.hue;
    var saturation = hsv.saturation;
    var value = hsv.value;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final previewColor = HSVColor.fromAHSV(
              1,
              hue,
              saturation,
              value,
            ).toColor();
            final hex =
                '#${(previewColor.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
                '${(previewColor.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
                '${(previewColor.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';

            return AlertDialog(
              title: Text(context.tr.image_editor_color_picker),
              content: SizedBox(
                width: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: previewColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hex,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildColorSlider(
                      context.tr.image_editor_hue,
                      hue,
                      0,
                      360,
                      (v) => setDialogState(() => hue = v),
                    ),
                    _buildColorSlider(
                      context.tr.image_editor_saturation,
                      saturation,
                      0,
                      1,
                      (v) => setDialogState(() => saturation = v),
                    ),
                    _buildColorSlider(
                      context.tr.common_value,
                      value,
                      0,
                      1,
                      (v) => setDialogState(() => value = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.tr.common_cancel),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      operation[fieldKey] = hex;
                    });
                    final ctrl = _propControllers[operation]?[fieldKey];
                    if (ctrl != null) {
                      ctrl.text = hex;
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(context.tr.common_apply),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorSlider(
    String label,
    double current,
    double min,
    double max,
    void Function(double) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: current.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            (current * (max == 360 ? 1 : 100)).toStringAsFixed(0),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _tryParseColor(String s) {
    s = s.replaceAll('#', '').trim();
    const named = <String, int>{
      'red': 0xFFFF0000,
      'green': 0xFF00FF00,
      'blue': 0xFF0000FF,
      'white': 0xFFFFFFFF,
      'black': 0xFF000000,
      'transparent': 0x00000000,
      'yellow': 0xFFFFFF00,
      'cyan': 0xFF00FFFF,
      'magenta': 0xFFFF00FF,
      'orange': 0xFFFFA500,
      'purple': 0xFF800080,
      'pink': 0xFFFFC0CB,
      'gray': 0xFF808080,
      'grey': 0xFF808080,
    };
    final lower = s.toLowerCase();
    final namedVal = named[lower];
    if (namedVal != null) return Color(namedVal);
    try {
      final hex = int.parse(s, radix: 16);
      return Color(s.length <= 6 ? 0xFF000000 | hex : hex);
    } catch (_) {
      return Colors.transparent;
    }
  }
}

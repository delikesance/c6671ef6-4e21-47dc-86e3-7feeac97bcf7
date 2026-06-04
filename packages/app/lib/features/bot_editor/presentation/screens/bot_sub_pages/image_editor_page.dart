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

import 'package:bot_creator_shared/bot_creator_shared.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

import '../../widgets/canvas_preview_widget.dart';
import '../../../../../core/widgets/variable_text_field.dart';

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

  static const _maxHistory = 50;
  final List<List<Map<String, dynamic>>> _history = [];
  int _historyIndex = -1;

  /// Per-field [TextEditingController]s so the properties panel reflects
  /// real-time position updates from canvas drag gestures.
  /// Key format: `'$index.$paramKey'` (e.g. `'2.x'`, `'3.y1'`).
  final Map<String, TextEditingController> _propControllers = {};

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
    for (final c in _propControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasCreate => _operations.any(
        (op) => (op['op'] ?? '').toString() == 'create',
      );

  // ── Undo/Redo History ─────────────────────────────────────────────────

  void _pushHistory() {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(_operations
        .map((op) => Map<String, dynamic>.from(op))
        .toList());
    _historyIndex = _history.length - 1;
    while (_history.length > _maxHistory) {
      _history.removeAt(0);
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
      _propControllers.clear();
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
      _propControllers.clear();
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
        title: const Text('Image Editor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
            child: isWide ? _buildDesktopLayout() : _buildMobileTabs(),
          ),
        ],
      ),
    );
  }

  // ── Toolbar ────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 720;
    const controlSpacing = SizedBox(width: 4);

    Widget buildAddLayerButton() {
      return PopupMenuButton<String>(
        onSelected: (opType) => _addOperation(opType),
        tooltip: 'Add operation',
        offset: const Offset(0, 40),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'create', child: Text('Create Canvas')),
          const PopupMenuItem(value: 'loadImage', child: Text('Load Image')),
          const PopupMenuItem(value: 'drawText', child: Text('Draw Text')),
          const PopupMenuItem(value: 'drawRect', child: Text('Draw Rectangle')),
          const PopupMenuItem(value: 'drawCircle', child: Text('Draw Circle')),
          const PopupMenuItem(value: 'drawLine', child: Text('Draw Line')),
        ],
        child: TextButton.icon(
          onPressed: null,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Layer'),
          style: TextButton.styleFrom(
            foregroundColor: cs.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
            icon: const Icon(Icons.zoom_out, size: 20),
            tooltip: 'Zoom out',
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
              child: Text('${(_zoom * 100).round()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          controlSpacing,
          IconButton(
            onPressed: _zoom < 3.0 ? _zoomIn : null,
            icon: const Icon(Icons.zoom_in, size: 20),
            tooltip: 'Zoom in',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          controlSpacing,
          IconButton(
            onPressed: _zoomToFit,
            icon: const Icon(Icons.fit_screen, size: 18),
            tooltip: 'Fit to screen',
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
          icon: const Icon(Icons.undo, size: 20),
          tooltip: 'Undo',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        IconButton(
          onPressed: _canRedo ? _redo : null,
          icon: const Icon(Icons.redo, size: 20),
          tooltip: 'Redo',
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
        icon: const Icon(Icons.check, size: 20),
        tooltip: 'Save',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      );
    }
    return FilledButton.icon(
      onPressed: () => Navigator.pop(context, _operations),
      icon: const Icon(Icons.check, size: 18),
      label: const Text('Save'),
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
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, null);
            },
            child: const Text('Discard & Leave'),
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
        SizedBox(
          width: 280,
          child: _buildOperationsPanel(),
        ),
        const VerticalDivider(width: 1),
        // Center: Canvas preview
        Expanded(
          flex: 2,
          child: _buildCanvasPanel(),
        ),
        const VerticalDivider(width: 1),
        // Right: Properties
        SizedBox(
          width: 300,
          child: _buildPropertiesPanel(),
        ),
      ],
    );
  }

  // ── Mobile: tab-based layout ───────────────────────────────────────────

  Widget _buildMobileTabs() {
    return Column(
      children: [
        // Canvas preview (always visible on mobile)
        Expanded(
          flex: 3,
          child: _buildCanvasPanel(),
        ),
        const Divider(height: 1),
        // Bottom: tabs for Operations and Properties
        Expanded(
          flex: 2,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Operations'),
                    Tab(text: 'Properties'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOperationsPanel(),
                      _buildPropertiesPanel(),
                    ],
                  ),
                ),
              ],
            ),
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
            Icon(Icons.warning_amber, size: 48, color: Colors.orange.shade300),
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
            Icon(Icons.add_photo_alternate_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Add a "Create Canvas" operation to start',
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
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Canvas'),
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
                  setState(() => _moveElementOnCanvas(index, canvasDx, canvasDy));
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

  Widget _buildOperationsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Flexible(child: Text('Operations',
                  style: Theme.of(context).textTheme.titleSmall)),
              const SizedBox(width: 8),
              Text('${_operations.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _operations.isEmpty
              ? Center(
                  child: Text('No operations yet',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline)))
              : ReorderableListView.builder(
                  itemCount: _operations.length,
                  onReorder: _onReorder,
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) =>
                      _buildOperationTile(index),
                ),
        ),
      ],
    );
  }

  Widget _buildOperationTile(int index) {
    final op = _operations[index];
    final opType = (op['op'] ?? '').toString();
    final isSelected = _selectedIndex == index;
    final isHidden = _hiddenIndices.contains(index);
    final cs = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey('op_${identityHashCode(op)}'),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.3)
            : null,
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
        onTap: () => setState(() => _selectedIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, size: 18, color: Colors.grey),
              ),
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
                child: Icon(
                  isHidden ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: isHidden ? Colors.grey : cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Icon(_opIcon(opType), size: 18,
                  color: isHidden ? Colors.grey : null),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _opLabel(op),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                child: Icon(Icons.close,
                    size: 16,
                    color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
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
            child: Text('Select an operation to edit its properties',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.outline, fontSize: 13)),
          ),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Canvas', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _buildReadOnlyField('Width', '${_canvasWidth}px'),
            _buildReadOnlyField('Height', '${_canvasHeight}px'),
            const SizedBox(height: 16),
            Text('${_operations.length} operations, ${_hiddenIndices.length} hidden',
                style: TextStyle(color: cs.outline, fontSize: 13)),
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
                child: Text('Properties',
                    style: Theme.of(context).textTheme.titleSmall),
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
                  child: Icon(Icons.delete_outline,
                      size: 18, color: cs.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_opLabel(op),
              style: TextStyle(color: cs.outline, fontSize: 13)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Visible'),
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
                const SizedBox(width: 80, child: Text('Opacity', style: TextStyle(fontSize: 12))),
                Expanded(
                  child: Slider(
                    value: (double.tryParse((op['opacity'] ?? '1').toString()) ?? 1.0)
                        .clamp(0.0, 1.0),
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: '${((double.tryParse((op['opacity'] ?? '1').toString()) ?? 1.0) * 100).round()}%',
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
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _pushHistory();
              setState(() {
                _operations.insert(
                    index + 1, Map<String, dynamic>.from(op));
                _selectedIndex = index + 1;
              });
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontFamily: 'monospace'))),
        ],
      ),
    );
  }

  List<Widget> _buildPropertyFields(
      String opType, Map<String, dynamic> op, int index) {
    final fields = <Widget>[];
    final hasVars = widget.variableSuggestions.isNotEmpty;

    /// Shows a dialog with a [VariableTextField] pre-populated with `((`
    /// so autocomplete suggestions appear immediately. On accept, inserts
    /// the selected variable into the operation map and syncs the prop controller.
    void showVariablePicker(String key) {
      // Pre-populate with (( so suggestions appear immediately.
      final vc = TextEditingController(text: '((');
      // Place cursor after (( so the suggestions picker activates.
      vc.selection = TextSelection.collapsed(offset: 2);

      showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Insert Variable'),
          content: SizedBox(
            width: 420,
            child: VariableTextField(
              label: 'Variable',
              hint: 'Type to filter or tap a suggestion below',
              suggestions: widget.variableSuggestions,
              controller: vc,
              onChanged: (_) {},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, vc.text.trim()),
              child: const Text('Insert'),
            ),
          ],
        ),
      ).then((result) {
        if (result != null && result.isNotEmpty) {
          setState(() {
            op[key] = result;
            final ck = '$index.$key';
            final c = _propControllers[ck];
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
    Widget? buildSuffix(String fieldKey, bool isColor, bool isUrl) {
      if (!hasVars && !isColor && !isUrl) return null;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isColor) _buildColorPreview(op[fieldKey]) ?? const SizedBox.shrink(),
          if (isUrl)
            IconButton(
              icon: const Icon(Icons.image, size: 20),
              onPressed: () => _pickImage(fieldKey),
              tooltip: 'Pick image file',
              visualDensity: VisualDensity.compact,
            ),
          if (hasVars)
            IconButton(
              icon: const Icon(Icons.data_object, size: 18),
              onPressed: () => showVariablePicker(fieldKey),
              tooltip: 'Insert variable',
              visualDensity: VisualDensity.compact,
            ),
        ],
      );
    }

    void addField(String label, String key,
        {String? hint, TextInputType? keyboardType, bool isColor = false, bool isUrl = false}) {
      final suffix = buildSuffix(key, isColor, isUrl);

      fields.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          key: ValueKey('${index}_$key'),
          controller:
              _getPropController(index, key, (op[key] ?? '').toString()),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: suffix,
          ),
          keyboardType: keyboardType,
          onChanged: (value) {
            setState(() {
              if (value.isEmpty) {
                op.remove(key);
              } else {
                op[key] = value;
              }
            });
          },
        ),
      ));
    }

    switch (opType) {
      case 'create':
        addField('Width', 'width', hint: '800', keyboardType: TextInputType.number);
        addField('Height', 'height', hint: '600', keyboardType: TextInputType.number);
        addField('Background Color', 'color', hint: '#2c2f33', isColor: true);
        break;
      case 'loadImage':
        addField('Image URL', 'url', hint: 'https://... or data:image/...', isUrl: true);
        addField('X', 'x', hint: '0', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '0', keyboardType: TextInputType.number);
        addField('Width', 'width', hint: 'auto (native size)', keyboardType: TextInputType.number);
        addField('Height', 'height', hint: 'auto (native size)', keyboardType: TextInputType.number);
        break;
      case 'drawText':
        addField('Text', 'text', hint: 'Hello World');
        addField('X', 'x', hint: '50', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '200', keyboardType: TextInputType.number);
        addField('Font Size', 'fontSize', hint: '48', keyboardType: TextInputType.number);
        addField('Color', 'color', hint: 'white', isColor: true);
        break;
      case 'drawRect':
        addField('X', 'x', hint: '0', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '0', keyboardType: TextInputType.number);
        addField('Width', 'width', hint: '100', keyboardType: TextInputType.number);
        addField('Height', 'height', hint: '100', keyboardType: TextInputType.number);
        addField('Color', 'color', hint: 'white', isColor: true);
        // Fill toggle
        fields.add(_buildCheckbox(op, 'fill', 'Fill', defaultValue: true));
        break;
      case 'drawCircle':
        addField('X', 'x', hint: '200', keyboardType: TextInputType.number);
        addField('Y', 'y', hint: '200', keyboardType: TextInputType.number);
        addField('Radius', 'radius', hint: '50', keyboardType: TextInputType.number);
        addField('Color', 'color', hint: 'white', isColor: true);
        fields.add(_buildCheckbox(op, 'fill', 'Fill', defaultValue: true));
        break;
      case 'drawLine':
        addField('X1', 'x1', hint: '0', keyboardType: TextInputType.number);
        addField('Y1', 'y1', hint: '0', keyboardType: TextInputType.number);
        addField('X2', 'x2', hint: '100', keyboardType: TextInputType.number);
        addField('Y2', 'y2', hint: '100', keyboardType: TextInputType.number);
        addField('Color', 'color', hint: 'white', isColor: true);
        addField('Thickness', 'thickness', hint: '1', keyboardType: TextInputType.number);
        break;
    }

    return fields;
  }

  Widget _buildCheckbox(
      Map<String, dynamic> op, String key, String label,
      {bool defaultValue = false}) {
    final current = op[key]?.toString().toLowerCase().trim();
    final isChecked = current == 'true' || current == 'yes' || current == '1' ||
        (current == null && defaultValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(label),
        value: isChecked,
        dense: true,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) {
          setState(() {
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
  TextEditingController _getPropController(int index, String key, String initial) {
    final ck = '$index.$key';
    var c = _propControllers[ck];
    if (c == null) {
      c = TextEditingController(text: initial);
      _propControllers[ck] = c;
    }
    return c;
  }

  // ── Actions ────────────────────────────────────────────────────────────

  void _addOperation(String opType) {
    final defaults = <String, dynamic>{};
    switch (opType) {
      case 'create':
        defaults.addAll({'op': 'create', 'width': '800', 'height': '600', 'color': '#2c2f33'});
        _canvasError = null;
        break;
      case 'loadImage':
        defaults.addAll({'op': 'loadImage', 'url': '', 'x': '0', 'y': '0', 'width': '', 'height': ''});
        break;
      case 'drawText':
        defaults.addAll({'op': 'drawText', 'text': 'Hello', 'x': '50', 'y': '200', 'fontSize': '48', 'color': 'white'});
        break;
      case 'drawRect':
        defaults.addAll({'op': 'drawRect', 'x': '0', 'y': '0', 'width': '100', 'height': '100', 'color': 'white', 'fill': 'true'});
        break;
      case 'drawCircle':
        defaults.addAll({'op': 'drawCircle', 'x': '200', 'y': '200', 'radius': '50', 'color': 'white', 'fill': 'true'});
        break;
      case 'drawLine':
        defaults.addAll({'op': 'drawLine', 'x1': '0', 'y1': '0', 'x2': '100', 'y2': '100', 'color': 'white', 'thickness': '1'});
        break;
    }
    _pushHistory();
    setState(() {
      final insertIndex = _selectedIndex != null ? _selectedIndex! + 1 : _operations.length;
      _operations.insert(insertIndex, defaults);
      _selectedIndex = insertIndex;
    });
  }

  /// Move a drawable operation by the given canvas coordinate deltas.
  ///
  /// Updates the appropriate position fields based on the operation type:
  /// - drawText, drawRect, drawCircle, loadImage: `x`, `y`
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
      case 'drawText':
      case 'drawRect':
      case 'drawCircle':
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
      final controller = _propControllers['$index.$key'];
      if (controller != null) {
        controller.text = (op[key] ?? '').toString();
      }
    }
  }

  Future<void> _pickImage(String key) async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.image,
      );
      if (result == null || result.path == null || result.path!.isEmpty) return;
      final filePath = result.path!;
      final bytes = await File(filePath).readAsBytes();
      final ext = filePath.split('.').last.toLowerCase();
      final mime = {
        'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
        'gif': 'image/gif', 'webp': 'image/webp', 'bmp': 'image/bmp',
      }[ext] ?? 'image/png';
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

  bool _hasPlaceholder(dynamic value) {
    if (value == null) return false;
    final s = value.toString();
    return s.contains('((') || s.contains('#{');
  }

  IconData _opIcon(String opType) {
    switch (opType) {
      case 'create': return Icons.add_to_photos;
      case 'loadImage': return Icons.image;
      case 'drawText': return Icons.text_fields;
      case 'drawRect': return Icons.crop_square;
      case 'drawCircle': return Icons.circle_outlined;
      case 'drawLine': return Icons.show_chart;
      default: return Icons.help_outline;
    }
  }

  String _opLabel(Map<String, dynamic> op) {
    final opType = (op['op'] ?? '').toString();
    switch (opType) {
      case 'create':
        final w = op['width'] ?? '800';
        final h = op['height'] ?? '600';
        return 'Create Canvas ($w×$h)';
      case 'loadImage':
        final url = (op['url'] ?? '').toString();
        final label = url.isNotEmpty
            ? (url.length > 30 ? '${url.substring(0, 30)}…' : url)
            : 'no URL';
        final x = op['x'] ?? '0';
        final y = op['y'] ?? '0';
        return 'Load Image: $label ($x,$y)';
      case 'drawText':
        final text = (op['text'] ?? '').toString();
        final label = text.length > 20 ? '${text.substring(0, 20)}…' : text;
        return 'Draw Text: "$label"';
      case 'drawRect':
        return 'Draw Rectangle';
      case 'drawCircle':
        return 'Draw Circle';
      case 'drawLine':
        return 'Draw Line';
      default:
        return 'Unknown ($opType)';
    }
  }

  Color _tryParseColor(String s) {
    s = s.replaceAll('#', '').trim();
    const named = <String, int>{
      'red': 0xFFFF0000, 'green': 0xFF00FF00, 'blue': 0xFF0000FF,
      'white': 0xFFFFFFFF, 'black': 0xFF000000, 'transparent': 0x00000000,
      'yellow': 0xFFFFFF00, 'cyan': 0xFF00FFFF, 'magenta': 0xFFFF00FF,
      'orange': 0xFFFFA500, 'purple': 0xFF800080, 'pink': 0xFFFFC0CB,
      'gray': 0xFF808080, 'grey': 0xFF808080,
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

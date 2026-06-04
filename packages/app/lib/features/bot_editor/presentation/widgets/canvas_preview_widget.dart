/// Canvas preview widget for the image compositing engine.
///
/// Renders a list of canvas operations to an interactive Flutter [CustomPainter]
/// preview. Supports hit testing (tap to select) and drag gestures (pan to
/// reposition elements). This is the editor-side half of the dual-mode
/// rendering strategy described in the image compositing engine architecture:
///
/// - **Runtime** (packages/shared): `image` package, CPU rendering → PNG output
/// - **Editor** (packages/app): [CanvasPreviewWidget] using Flutter
///   [CustomPainter] → GPU-accelerated live preview with drag interaction
///
/// ## Usage
///
/// ```dart
/// CanvasPreviewWidget(
///   operations: [
///     {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
///     {'op': 'drawText', 'text': 'Hello!', 'x': '50', 'y': '200',
///      'fontSize': '48', 'color': 'white'},
///   ],
///   maxWidth: 400,
///   maxHeight: 300,
///   selectedIndex: _selectedIndex,
///   onElementSelected: (i) => setState(() => _selectedIndex = i),
///   onElementMoved: (i, dx, dy) { /* update operation x/y */ },
/// )
/// ```
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator_shared/types/variable_suggestion.dart' as shared;

/// An interactive preview widget for canvas image compositing operations.
///
/// Renders a list of canvas operations (in the same format used by the
/// runtime executor) to a GPU-accelerated Flutter canvas. Supports tap-to-select
/// and drag-to-reposition of drawable elements.
///
/// The preview auto-scales to fit within [maxWidth] × [maxHeight] while
/// preserving the canvas aspect ratio.
class CanvasPreviewWidget extends StatelessWidget {
  /// The list of canvas operations to render.
  ///
  /// Each operation is a [Map] with an `'op'` field and typed parameters.
  /// Format matches the runtime executor's operation list.
  final List<Map<String, dynamic>> operations;

  /// Maximum display width for the preview (logical pixels).
  final double maxWidth;

  /// Maximum display height for the preview (logical pixels).
  final double maxHeight;

  /// Optional background color for the widget area around the canvas.
  final Color? backgroundColor;

  /// Optional border radius for the preview container.
  final BorderRadius? borderRadius;

  /// The index of the currently selected operation, or `null` if none.
  ///
  /// The selected element receives a visual highlight on the canvas.
  final int? selectedIndex;

  /// Called when the user taps an element on the canvas.
  ///
  /// Passes the index of the tapped operation, or `null` if the user
  /// tapped on empty canvas space.
  final ValueChanged<int?>? onElementSelected;

  /// Called when the user drags an element on the canvas.
  ///
  /// The [dx] and [dy] values are in canvas coordinates (not widget pixels).
  /// The caller should add these deltas to the operation's current x/y values.
  final void Function(int index, double canvasDx, double canvasDy)? onElementMoved;

  /// Override scale factor (for zoom). When null, auto-scales to fit.
  final double? zoom;

  /// Set of operation indices to hide (visibility toggle).
  final Set<int> hiddenIndices;

  /// Variable suggestions for color-coding placeholder badges on the canvas.
  ///
  /// When a text layer contains `((varName))` placeholders, the painter
  /// looks up the variable name in this list to determine its category color.
  /// Unknown variables are displayed with a warning badge.
  final List<VariableSuggestion> variableSuggestions;

  const CanvasPreviewWidget({
    super.key,
    required this.operations,
    this.maxWidth = 400,
    this.maxHeight = 400,
    this.backgroundColor,
    this.borderRadius,
    this.selectedIndex,
    this.onElementSelected,
    this.onElementMoved,
    this.zoom,
    this.hiddenIndices = const {},
    this.variableSuggestions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        color: backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: _CanvasPreview(
          operations: operations,
          selectedIndex: selectedIndex,
          onElementSelected: onElementSelected,
          onElementMoved: onElementMoved,
          zoom: zoom,
          hiddenIndices: hiddenIndices,
          variableSuggestions: variableSuggestions,
        ),
      ),
    );
  }
}

/// Internal stateful canvas preview that handles layout, hit testing,
/// gesture detection, and painting.
class _CanvasPreview extends StatefulWidget {
  final List<Map<String, dynamic>> operations;
  final int? selectedIndex;
  final ValueChanged<int?>? onElementSelected;
  final void Function(int index, double canvasDx, double canvasDy)? onElementMoved;
  final double? zoom;
  final Set<int> hiddenIndices;
  final List<VariableSuggestion> variableSuggestions;

  const _CanvasPreview({
    required this.operations,
    this.selectedIndex,
    this.onElementSelected,
    this.onElementMoved,
    this.zoom,
    this.hiddenIndices = const {},
    this.variableSuggestions = const [],
  });

  @override
  State<_CanvasPreview> createState() => _CanvasPreviewState();
}

class _CanvasPreviewState extends State<_CanvasPreview> {
  // Cached canvas dimensions from the 'create' operation.
  int _canvasWidth = 400;
  int _canvasHeight = 300;
  double _scale = 1.0;

  // Track the operation index being dragged (null = not dragging).
  int? _draggingIndex;
  // Accumulator for pan deltas (to avoid jitter from gesture resolution).
  Offset _dragAccumulator = Offset.zero;

  // ─── Image cache ───────────────────────────────────────────────────────

  /// Loaded [ui.Image] objects keyed by their source URL.
  final Map<String, ui.Image> _loadedImages = {};

  /// URLs currently being loaded (to avoid duplicate requests).
  final Set<String> _loadingUrls = {};

  @override
  void initState() {
    super.initState();
    _parseCanvasSize();
    _loadImages();
  }

  @override
  void dispose() {
    for (final image in _loadedImages.values) {
      image.dispose();
    }
    _loadedImages.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CanvasPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always re-parse canvas size — operations are mutated in-place
    // by the image editor so identity comparison is insufficient.
    _parseCanvasSize();
    // Always scan for new images on every update. The operations list may
    // be mutated in-place (e.g. URL field updated by the image picker)
    // without changing the list reference, so identity comparison alone
    // is insufficient. _loadImages() has internal dedup via
    // _loadedImages.containsKey() / _loadingUrls.contains(), so repeated
    // calls for already-loaded images are a cheap no-op.
    _loadImages();
  }

  void _parseCanvasSize() {
    for (final op in widget.operations) {
      if ((op['op'] ?? '') == 'create') {
        _canvasWidth = int.tryParse(op['width']?.toString() ?? '') ?? 400;
        _canvasHeight = int.tryParse(op['height']?.toString() ?? '') ?? 300;
        return;
      }
    }
  }

  // ─── Image loading ─────────────────────────────────────────────────────

  /// Detects [loadImage] / [compositeImage] operations with a viable URL,
  /// decodes the image data, and stores the resulting [ui.Image] in
  /// [_loadedImages]. Triggers a repaint when each image finishes loading.
  void _loadImages() {
    for (final op in widget.operations) {
      final opType = (op['op'] ?? '').toString();
      if (opType != 'loadImage' && opType != 'compositeImage') continue;

      final url = op['url']?.toString() ?? '';
      if (url.isEmpty) continue;

      // Don't reload if already cached or currently loading
      if (_loadedImages.containsKey(url)) continue;
      if (_loadingUrls.contains(url)) continue;

      // Skip URLs that contain unresolved template placeholders
      if (url.contains('((') || url.contains('#{')) continue;

      _loadingUrls.add(url);
      _decodeImageFromUrl(url);
    }
  }

  /// Decodes an image from a data URL (base64) or HTTP URL into a [ui.Image].
  Future<void> _decodeImageFromUrl(String url) async {
    try {
      late final Uint8List bytes;
      if (url.startsWith('data:')) {
        // Decode base64 data URL
        final commaIndex = url.indexOf(',');
        if (commaIndex == -1) {
          _loadingUrls.remove(url);
          return;
        }
        bytes = const Base64Decoder()
            .convert(url.substring(commaIndex + 1));
      } else {
        // Fetch from HTTP URL
        final response = await NetworkAssetBundle(
          Uri.parse(url),
        ).load(url);
        bytes = response.buffer.asUint8List();
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      if (mounted) {
        setState(() {
          _loadedImages[url] = image;
          _loadingUrls.remove(url);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingUrls.remove(url);
        });
      }
    }
  }

  // ─── Coordinate transforms ────────────────────────────────────────────

  /// Convert widget-local pixel offset to canvas coordinate offset.
  Offset _widgetToCanvas(Offset pos) {
    return Offset(pos.dx / _scale, pos.dy / _scale);
  }

  // ─── Hit testing ──────────────────────────────────────────────────────

  /// Hit-tests in reverse draw order (topmost element first).
  /// Returns the operation index, or null if no hit.
  int? _hitTest(Offset canvasPos) {
    final ops = widget.operations;
    // Iterate in reverse: last drawn is on top
    for (var i = ops.length - 1; i >= 0; i--) {
      if (widget.hiddenIndices.contains(i)) continue;
      final op = ops[i];
      if (_hitTestOperation(canvasPos, op, i)) {
        return i;
      }
    }
    return null;
  }

  bool _hitTestOperation(Offset pos, Map<String, dynamic> op, int index) {
    final opType = (op['op'] ?? '').toString();
    switch (opType) {
      case 'create':
        return false; // Canvas background is not selectable
      case 'drawRect':
        return _hitRect(pos, op);
      case 'drawCircle':
        return _hitCircle(pos, op);
      case 'drawText':
        return _hitText(pos, op);
      case 'drawLine':
        return _hitLine(pos, op);
      case 'loadImage':
      case 'compositeImage':
        return _hitImage(pos, op);
      default:
        return false;
    }
  }

  bool _hitRect(Offset pos, Map<String, dynamic> op) {
    final x = _parseDouble(op, 'x');
    final y = _parseDouble(op, 'y');
    final w = _parseDouble(op, 'width', 50);
    final h = _parseDouble(op, 'height', 50);
    return pos.dx >= x && pos.dx <= x + w && pos.dy >= y && pos.dy <= y + h;
  }

  bool _hitCircle(Offset pos, Map<String, dynamic> op) {
    final cx = _parseDouble(op, 'x');
    final cy = _parseDouble(op, 'y');
    final r = _parseDouble(op, 'radius', 10);
    final dx = pos.dx - cx;
    final dy = pos.dy - cy;
    return dx * dx + dy * dy <= r * r;
  }

  bool _hitText(Offset pos, Map<String, dynamic> op) {
    final text = op['text']?.toString() ?? '';
    if (text.isEmpty) return false;
    final x = _parseDouble(op, 'x');
    final y = _parseDouble(op, 'y');
    final fontSize = _parseDouble(op, 'fontSize', 14);

    // Measure text using TextPainter (same as the painter).
    // For variable placeholders, estimate bounds from the rendered badge.
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return pos.dx >= x &&
        pos.dx <= x + tp.width &&
        pos.dy >= y &&
        pos.dy <= y + tp.height;
  }

  bool _hitLine(Offset pos, Map<String, dynamic> op) {
    final x1 = _parseDouble(op, 'x1');
    final y1 = _parseDouble(op, 'y1');
    final x2 = _parseDouble(op, 'x2');
    final y2 = _parseDouble(op, 'y2');
    final thickness = _parseDouble(op, 'thickness', 1).clamp(1, 50);

    // Distance from point to line segment
    // https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
    final dx = x2 - x1;
    final dy = y2 - y1;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      // Degenerate: point
      return (pos.dx - x1).abs() <= thickness &&
          (pos.dy - y1).abs() <= thickness;
    }

    // Project point onto line parameter t, clamped to [0,1]
    final t = ((pos.dx - x1) * dx + (pos.dy - y1) * dy) / lengthSquared;
    if (t < 0 || t > 1) return false;

    // Perpendicular distance
    final projX = x1 + t * dx;
    final projY = y1 + t * dy;
    final dist = math.sqrt(
      (pos.dx - projX) * (pos.dx - projX) +
          (pos.dy - projY) * (pos.dy - projY),
    );
    // Hit area: half thickness + generous finger-sized margin in canvas space
    return dist <= (thickness / 2) + 8;
  }

  bool _hitImage(Offset pos, Map<String, dynamic> op) {
    final x = _parseDouble(op, 'x');
    final y = _parseDouble(op, 'y');
    final w = _parseDouble(op, 'width', 50);
    final h = _parseDouble(op, 'height', 50);
    // loadImage may not have x/y — it uses the full canvas
    final effectiveX = op.containsKey('x') ? x : 0;
    final effectiveY = op.containsKey('y') ? y : 0;
    final effectiveW = op.containsKey('width') ? w : _canvasWidth.toDouble();
    final effectiveH = op.containsKey('height') ? h : _canvasHeight.toDouble();
    return pos.dx >= effectiveX &&
        pos.dx <= effectiveX + effectiveW &&
        pos.dy >= effectiveY &&
        pos.dy <= effectiveY + effectiveH;
  }

  // ─── Bounding box for selection highlight ──────────────────────────────

  /// Returns the bounding box in canvas coordinates for the given operation,
  /// or null if the operation doesn't have a sensible bounding box.
  Rect? _getBoundingBox(Map<String, dynamic> op) {
    final opType = (op['op'] ?? '').toString();
    switch (opType) {
      case 'drawRect':
        return Rect.fromLTWH(
          _parseDouble(op, 'x'),
          _parseDouble(op, 'y'),
          _parseDouble(op, 'width', 50),
          _parseDouble(op, 'height', 50),
        );
      case 'drawCircle':
        final cx = _parseDouble(op, 'x');
        final cy = _parseDouble(op, 'y');
        final r = _parseDouble(op, 'radius', 10);
        return Rect.fromCircle(center: Offset(cx, cy), radius: r);
      case 'drawText':
        final text = op['text']?.toString() ?? '';
        if (text.isEmpty) return null;
        final x = _parseDouble(op, 'x');
        final y = _parseDouble(op, 'y');
        final fontSize = _parseDouble(op, 'fontSize', 14);
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.normal),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        return Rect.fromLTWH(x, y, tp.width, tp.height);
      case 'drawLine':
        final x1 = _parseDouble(op, 'x1');
        final y1 = _parseDouble(op, 'y1');
        final x2 = _parseDouble(op, 'x2');
        final y2 = _parseDouble(op, 'y2');
        return Rect.fromPoints(Offset(x1, y1), Offset(x2, y2));
      case 'loadImage':
      case 'compositeImage':
        final x = op.containsKey('x') ? _parseDouble(op, 'x') : 0.0;
        final y = op.containsKey('y') ? _parseDouble(op, 'y') : 0.0;
        final w = op.containsKey('width')
            ? _parseDouble(op, 'width', 50)
            : _canvasWidth.toDouble();
        final h = op.containsKey('height')
            ? _parseDouble(op, 'height', 50)
            : _canvasHeight.toDouble();
        return Rect.fromLTWH(x, y, w, h);
      default:
        return null;
    }
  }

  // ─── Gesture handling ─────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details, Size widgetSize) {
    final canvasPos = _widgetToCanvas(details.localPosition);
    final hitIndex = _hitTest(canvasPos);
    _draggingIndex = hitIndex;
    _dragAccumulator = Offset.zero;

    if (widget.onElementSelected != null) {
      widget.onElementSelected!(hitIndex);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size widgetSize) {
    if (_draggingIndex == null || widget.onElementMoved == null) return;

    final canvasDelta = _widgetToCanvas(details.delta);
    _dragAccumulator += canvasDelta;

    // Only fire movement when we've accumulated at least 1 canvas pixel
    // to avoid excessive setState calls from sub-pixel gesture deltas.
    if (_dragAccumulator.distance >= 1.0) {
      widget.onElementMoved!(
        _draggingIndex!,
        _dragAccumulator.dx,
        _dragAccumulator.dy,
      );
      _dragAccumulator = Offset.zero;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    // Flush any remaining accumulator
    if (_draggingIndex != null &&
        widget.onElementMoved != null &&
        _dragAccumulator.distance > 0) {
      widget.onElementMoved!(
        _draggingIndex!,
        _dragAccumulator.dx,
        _dragAccumulator.dy,
      );
    }
    _draggingIndex = null;
    _dragAccumulator = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final interactive =
        widget.onElementSelected != null || widget.onElementMoved != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute scale to fit canvas within constraints
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final aspect = _canvasWidth / _canvasHeight;

        double w, h;
        if (maxW / maxH > aspect) {
          h = maxH;
          w = h * aspect;
        } else {
          w = maxW;
          h = w / aspect;
        }

        _scale = w / _canvasWidth;

        // Apply user zoom — scales both the rendered size and the paint scale.
        final zoom = (widget.zoom ?? 1.0).clamp(0.25, 3.0);
        _scale *= zoom;
        final zoomedW = w * zoom;
        final zoomedH = h * zoom;

        final painter = _CanvasPreviewPainter(
          operations: widget.operations,
          selectedIndex: widget.selectedIndex,
          canvasWidth: _canvasWidth,
          canvasHeight: _canvasHeight,
          scale: _scale,
          getBoundingBox: _getBoundingBox,
          hiddenIndices: widget.hiddenIndices,
          variableSuggestions: widget.variableSuggestions,
          loadedImages: _loadedImages,
        );

        final customPaint = CustomPaint(
          size: Size(zoomedW, zoomedH),
          painter: painter,
          isComplex: true,
          willChange: true,
        );

        Widget content = customPaint;

        if (!interactive) {
          return Center(
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(child: content),
              ),
            ),
          );
        }

        content = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _onPanStart(d, Size(zoomedW, zoomedH)),
          onPanUpdate: (d) => _onPanUpdate(d, Size(zoomedW, zoomedH)),
          onPanEnd: _onPanEnd,
          onTapUp: (details) {
            final canvasPos = _widgetToCanvas(details.localPosition);
            final hitIndex = _hitTest(canvasPos);
            widget.onElementSelected?.call(hitIndex);
          },
          child: customPaint,
        );

        return Center(child: content);
      },
    );
  }
}

// ─── Custom Painter ─────────────────────────────────────────────────────

class _CanvasPreviewPainter extends CustomPainter {
  final List<Map<String, dynamic>> operations;
  final int? selectedIndex;
  final int canvasWidth;
  final int canvasHeight;
  final double scale;
  final Rect? Function(Map<String, dynamic> op) getBoundingBox;
  final Set<int> hiddenIndices;
  final List<VariableSuggestion> variableSuggestions;
  /// Pre-loaded images keyed by their source URL.
  final Map<String, ui.Image> loadedImages;

  _CanvasPreviewPainter({
    required this.operations,
    required this.selectedIndex,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.scale,
    required this.getBoundingBox,
    this.hiddenIndices = const {},
    this.variableSuggestions = const [],
    this.loadedImages = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale, scale);

    // Draw canvas background
    final bg = _parseCanvasBg();
    if (bg != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
        Paint()..color = bg,
      );
    }

    // Execute operations sequentially
    for (var i = 0; i < operations.length; i++) {
      if (hiddenIndices.contains(i)) continue;
      final op = operations[i];
      final opType = (op['op'] ?? '').toString();
      _paintOperation(canvas, op, opType);
    }

    // Draw selection highlight LAST (on top of everything)
    if (selectedIndex != null && selectedIndex! < operations.length) {
      final op = operations[selectedIndex!];
      final bounds = getBoundingBox(op);
      if (bounds != null) {
        _paintSelectionHighlight(canvas, bounds);
      }
    }

    canvas.restore();
  }

  void _paintOperation(Canvas canvas, Map<String, dynamic> rawOp, String op) {
    switch (op) {
      case 'create':
        break; // Background already drawn
      case 'drawRect':
        _paintDrawRect(canvas, rawOp);
        break;
      case 'drawCircle':
        _paintDrawCircle(canvas, rawOp);
        break;
      case 'drawText':
        _paintDrawText(canvas, rawOp);
        break;
      case 'drawLine':
        _paintDrawLine(canvas, rawOp);
        break;
      case 'compositeImage':
      case 'loadImage':
        _paintImagePlaceholder(canvas, rawOp);
        break;
    }
  }

  // ─── Shape painters ────────────────────────────────────────────────────

  void _paintDrawRect(Canvas canvas, Map<String, dynamic> op) {
    final x = _parseDouble(op, 'x');
    final y = _parseDouble(op, 'y');
    final w = _parseDouble(op, 'width', 50);
    final h = _parseDouble(op, 'height', 50);
    final color = _parseUiColor(op['color']) ?? const ui.Color(0xFFFFFFFF);
    final fill = _parseBool(op, 'fill', true);

    final paint = Paint()
      ..color = color
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
  }

  void _paintDrawCircle(Canvas canvas, Map<String, dynamic> op) {
    final x = _parseDouble(op, 'x');
    final y = _parseDouble(op, 'y');
    final radius = _parseDouble(op, 'radius', 10);
    final color = _parseUiColor(op['color']) ?? const ui.Color(0xFFFFFFFF);
    final fill = _parseBool(op, 'fill', true);

    final paint = Paint()
      ..color = color
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  void _paintDrawText(Canvas canvas, Map<String, dynamic> op) {
    final text = op['text']?.toString() ?? '';
    if (text.isEmpty) return;

    final x = _parseDouble(op, 'x');
    final y = _parseDouble(op, 'y');
    final fontSize = _parseDouble(op, 'fontSize', 14);
    final color = _parseUiColor(op['color']) ?? const ui.Color(0xFFFFFFFF);

    if (text.contains('((')) {
      _paintVariableText(canvas, text, x, y, fontSize);
      return;
    }

    final formattedColor = Color.fromARGB(
        (color.a * 255).round().clamp(0, 255),
        (color.r * 255).round().clamp(0, 255),
        (color.g * 255).round().clamp(0, 255),
        (color.b * 255).round().clamp(0, 255));

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: formattedColor,
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(x, y));
  }

  void _paintDrawLine(Canvas canvas, Map<String, dynamic> op) {
    final x1 = _parseDouble(op, 'x1');
    final y1 = _parseDouble(op, 'y1');
    final x2 = _parseDouble(op, 'x2');
    final y2 = _parseDouble(op, 'y2');
    final color = _parseUiColor(op['color']) ?? const ui.Color(0xFFFFFFFF);
    final thickness = _parseDouble(op, 'thickness', 1);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
  }

  void _paintImagePlaceholder(Canvas canvas, Map<String, dynamic> op) {
    final url = op['url']?.toString() ?? '';

    // Try to render the actual image if it's been loaded
    final loadedImage = loadedImages[url];
    if (loadedImage != null) {
      _paintImage(canvas, op, loadedImage);
      return;
    }

    // ─── Placeholder rendering (no image loaded yet) ─────────────────────
    final x = _parseDouble(op, 'x');
    final y = _parseDouble(op, 'y');
    final w = _parseDouble(op, 'width', 50);
    final h = _parseDouble(op, 'height', 50);

    final paint = Paint()
      ..color = const ui.Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = Rect.fromLTWH(x, y, w > 0 ? w : 50, h > 0 ? h : 50);
    canvas.drawRect(rect, paint);

    final iconPaint = Paint()
      ..color = const ui.Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final s = (rect.shortestSide / 2 * 0.5);
    canvas.drawLine(Offset(cx - s, cy - s), Offset(cx + s, cy + s), iconPaint);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: s * 2, height: s * 1.2),
      iconPaint,
    );
    canvas.drawCircle(Offset(cx - s * 0.3, cy - s * 0.3), s * 0.15,
        Paint()..color = const ui.Color(0x66FFFFFF));

    // Show a subtle loading indicator for URLs actively being fetched
    // (vs empty URLs that don't trigger loading at all)
    if (url.isNotEmpty && !url.contains('((') && !url.contains('#{')) {
      _paintLoadingIndicator(canvas, rect);
    }
  }

  /// Draws the loaded [ui.Image] onto the canvas.
  ///
  /// If [op] has a width/height, the image is scaled to fit those dimensions;
  /// otherwise it's drawn at its native size (clipped to canvas bounds).
  ///
  /// Shape clipping: if [op] has a `shape` key, the image is clipped to:
  /// - `circle` / `round` / `oval` / `ellipse` → circular mask
  /// - `rounded:N` / `roundrect:N` → rounded rectangle with radius N
  /// - `triangle` → triangular clip
  void _paintImage(Canvas canvas, Map<String, dynamic> op, ui.Image image) {
    final x = _parseDouble(op, 'x');
    final y = _parseDouble(op, 'y');
    final specifiedW = _parseDouble(op, 'width', -1);
    final specifiedH = _parseDouble(op, 'height', -1);
    final shape = (op['shape'] ?? '').toString().toLowerCase().trim();

    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    Rect dst;
    if (specifiedW > 0 && specifiedH > 0) {
      dst = Rect.fromLTWH(x, y, specifiedW, specifiedH);
    } else if (specifiedW > 0) {
      final ratio = image.height / image.width;
      dst = Rect.fromLTWH(x, y, specifiedW, specifiedW * ratio);
    } else if (specifiedH > 0) {
      final ratio = image.width / image.height;
      dst = Rect.fromLTWH(x, y, specifiedH * ratio, specifiedH);
    } else {
      dst = Rect.fromLTWH(x, y, image.width.toDouble(), image.height.toDouble());
    }

    final needsClip = shape.isNotEmpty && shape != 'none';

    if (needsClip) {
      final path = _shapeClipPath(shape, dst);
      canvas.saveLayer(dst, Paint());
      canvas.clipPath(path);
      canvas.drawImageRect(image, src, dst, Paint());
      canvas.restore();
    } else {
      canvas.drawImageRect(image, src, dst, Paint());
    }
  }

  /// Builds a clip [Path] for the given shape inside [rect].
  Path _shapeClipPath(String shape, Rect rect) {
    if (shape == 'circle' || shape == 'round' ||
        shape == 'oval' || shape == 'ellipse') {
      return Path()..addOval(rect);
    }
    if (shape.startsWith('rounded') || shape.startsWith('roundrect')) {
      var radius = 20.0;
      final parts = shape.split(':');
      if (parts.length > 1) {
        radius = double.tryParse(parts[1]) ?? 20.0;
      } else {
        final numStr = shape.replaceAll(RegExp(r'[^0-9.]'), '');
        if (numStr.isNotEmpty) {
          radius = double.tryParse(numStr) ?? 20.0;
        }
      }
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    }
    if (shape == 'triangle') {
      return Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close();
    }
    // Unknown shape — no clip
    return Path()..addRect(rect);
  }

  /// Draws a small animated dots indicator inside the placeholder rect
  /// to signal that image data is being fetched.
  void _paintLoadingIndicator(Canvas canvas, Rect rect) {
    final cx = rect.center.dx;
    final bottom = rect.bottom - 10;
    const dotRadius = 2.0;
    const spacing = 8.0;
    final dotPaint = Paint()..color = const ui.Color(0x88FFFFFF);

    // Three dots: left, center, right
    canvas.drawCircle(Offset(cx - spacing, bottom), dotRadius, dotPaint);
    canvas.drawCircle(Offset(cx, bottom), dotRadius, dotPaint);
    canvas.drawCircle(Offset(cx + spacing, bottom), dotRadius, dotPaint);
  }

  /// Renders a text string containing variable placeholders as interactive badges.
  ///
  /// Each `((varName))` placeholder is extracted and rendered as a colored chip.
  /// Known variables (found in [variableSuggestions]) use their category color;
  /// unknown variables are displayed with a warning (orange/red) badge.
  /// Plain text between placeholders is rendered normally.
  void _paintVariableText(
    Canvas canvas, String text, double x, double y, double fontSize,
  ) {
    // Parse the text into segments: plain text + placeholder segments
    final segments = _parsePlaceholderSegments(text);

    var cursorX = x;
    for (final seg in segments) {
      if (seg.isPlaceholder) {
        cursorX += _paintVariableChip(canvas, seg.text, cursorX, y, fontSize);
      } else {
        cursorX += _paintPlainTextSpan(canvas, seg.text, cursorX, y, fontSize);
      }
    }
  }

  /// Parses a text string into segments, separating `((...))` placeholders
  /// from plain text.
  List<_PlaceholderSegment> _parsePlaceholderSegments(String text) {
    final segments = <_PlaceholderSegment>[];
    final regex = RegExp(r'\(\(([^)]+)\)\)');
    var lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Plain text before this placeholder
      if (match.start > lastEnd) {
        segments.add(_PlaceholderSegment(
          text: text.substring(lastEnd, match.start),
          isPlaceholder: false,
        ));
      }
      // The placeholder (including the ((...)) wrapper for display)
      segments.add(_PlaceholderSegment(
        text: match.group(0)!,
        isPlaceholder: true,
      ));
      lastEnd = match.end;
    }

    // Trailing plain text
    if (lastEnd < text.length) {
      segments.add(_PlaceholderSegment(
        text: text.substring(lastEnd),
        isPlaceholder: false,
      ));
    }

    return segments;
  }

  /// Renders a plain text span and returns its width.
  double _paintPlainTextSpan(
    Canvas canvas, String text, double x, double y, double fontSize,
  ) {
    if (text.isEmpty) return 0;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
    return tp.width;
  }

  /// Renders a variable placeholder chip and returns its width.
  ///
  /// The chip color is determined by looking up the variable name (stripped of
  /// `((...))` wrapper) in [variableSuggestions]. Known variables get their
  /// category color; unknown variables get a warning orange badge with
  /// an error indicator.
  double _paintVariableChip(
    Canvas canvas, String rawPlaceholder, double x, double y, double fontSize,
  ) {
    // Extract the variable name without ((...)) wrapper
    final varName = rawPlaceholder
        .replaceAll('((', '')
        .replaceAll('))', '')
        .trim();

    // Look up the variable in suggestions to determine category
    final suggestion = _findSuggestion(varName);
    final isKnown = suggestion != null;
    final categoryColor = isKnown
        ? _categoryColor(suggestion.category)
        : const ui.Color(0xFFFF6B35); // Warning orange for unknown

    final bgColor = isKnown
        ? ui.Color((categoryColor.toARGB32() & 0x00FFFFFF) | 0x33000000)
        : const ui.Color(0x33FF6B35);

    final textColor = isKnown
        ? categoryColor
        : const ui.Color(0xFFFF6B35);

    final textPainter = TextPainter(
      text: TextSpan(
        text: rawPlaceholder,
        style: TextStyle(
          color: Color.fromARGB(
            (textColor.a * 255).round().clamp(0, 255),
            (textColor.r * 255).round().clamp(0, 255),
            (textColor.g * 255).round().clamp(0, 255),
            (textColor.b * 255).round().clamp(0, 255),
          ),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Background chip
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x - 2, y - 2,
        textPainter.width + 4, textPainter.height + 4,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = bgColor,
    );

    // Draw a subtle border for unknown variables
    if (!isKnown) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = textColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    textPainter.paint(canvas, Offset(x, y));
    return textPainter.width;
  }

  /// Finds a variable suggestion matching the given name.
  VariableSuggestion? _findSuggestion(String name) {
    for (final s in variableSuggestions) {
      if (s.name == name) return s;
    }
    return null;
  }

  /// Maps a [VariableCategory] to a display color for the variable badge.
  ui.Color _categoryColor(shared.VariableCategory category) {
    switch (category) {
      case shared.VariableCategory.author:
        return const ui.Color(0xFF7C4DFF); // Deep purple
      case shared.VariableCategory.user:
        return const ui.Color(0xFF448AFF); // Blue
      case shared.VariableCategory.member:
        return const ui.Color(0xFF40C4FF); // Light blue
      case shared.VariableCategory.guild:
        return const ui.Color(0xFF69F0AE); // Green
      case shared.VariableCategory.channel:
        return const ui.Color(0xFFB2FF59); // Light green
      case shared.VariableCategory.message:
        return const ui.Color(0xFFFFD740); // Amber
      case shared.VariableCategory.bot:
        return const ui.Color(0xFFE040FB); // Purple
      case shared.VariableCategory.temp:
        return const ui.Color(0xFFFF6E40); // Deep orange
      case shared.VariableCategory.context_:
        return const ui.Color(0xFF90CAF9); // Soft blue
      case shared.VariableCategory.interaction:
        return const ui.Color(0xFF80DEEA); // Cyan
      case shared.VariableCategory.function_:
        return const ui.Color(0xFFA5D6A7); // Soft green
      case shared.VariableCategory.other:
        return const ui.Color(0xFFB0BEC5); // Blue grey
    }
  }

  /// Draws a dashed blue selection highlight around the element's bounding box.
  void _paintSelectionHighlight(Canvas canvas, Rect bounds) {
    const selectionColor = ui.Color(0xFF2196F3); // Material Blue
    final paint = Paint()
      ..color = selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    // Inflate bounds slightly so the highlight is visible around the element
    final pad = 3.0;
    final r = bounds.inflate(pad);
    final path = Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)));

    // Draw dashed border
    final dashedPath = _dashPath(path, dashLength: 6, gapLength: 4);
    canvas.drawPath(dashedPath, paint);

    // Draw small resize handles at the corners
    const handleSize = 5.0;
    final handlePaint = Paint()
      ..color = selectionColor
      ..style = PaintingStyle.fill;
    for (final corner in [
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
    ]) {
      canvas.drawRect(
        Rect.fromCenter(
            center: corner, width: handleSize, height: handleSize),
        handlePaint,
      );
    }
  }

  /// Creates a dashed version of [source] by measuring and drawing segments.
  Path _dashPath(Path source, {double dashLength = 6, double gapLength = 4}) {
    final result = Path();
    final metrics = source.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final segLen = draw ? dashLength : gapLength;
        final end = (distance + segLen).clamp(0.0, metric.length);
        if (draw) {
          result.addPath(metric.extractPath(distance, end), Offset.zero);
        }
        distance += segLen;
        draw = !draw;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _CanvasPreviewPainter oldDelegate) {
    // Always repaint — operations are mutated in-place by the editor,
    // so identity comparison is insufficient. The CustomPainter is only
    // rebuilt when the parent calls setState (on every property change),
    // making per-property diffing unnecessary for an editor context.
    return true;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  double _parseDouble(Map<String, dynamic> op, String key,
      [double defaultValue = 0]) {
    final value = op[key];
    if (value == null) return defaultValue;
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  bool _parseBool(Map<String, dynamic> op, String key,
      [bool defaultValue = false]) {
    final value = op[key];
    if (value == null) return defaultValue;
    final s = value.toString().toLowerCase().trim();
    if (s == 'true' || s == 'yes' || s == '1') return true;
    if (s == 'false' || s == 'no' || s == '0') return false;
    return defaultValue;
  }

  ui.Color? _parseCanvasBg() {
    for (final op in operations) {
      if ((op['op'] ?? '') == 'create') {
        return _parseUiColor(op['color']);
      }
    }
    return null;
  }

  ui.Color? _parseUiColor(dynamic raw) {
    if (raw == null) return null;
    var s = raw.toString().replaceAll('#', '').trim();
    if (s.isEmpty) return null;

    const named = <String, int>{
      'red': 0xFFFF0000, 'green': 0xFF00FF00, 'blue': 0xFF0000FF,
      'white': 0xFFFFFFFF, 'black': 0xFF000000, 'transparent': 0x00000000,
      'yellow': 0xFFFFFF00, 'cyan': 0xFF00FFFF, 'magenta': 0xFFFF00FF,
      'orange': 0xFFFFA500, 'purple': 0xFF800080, 'pink': 0xFFFFC0CB,
      'gray': 0xFF808080, 'grey': 0xFF808080, 'lime': 0xFF00FF00,
      'navy': 0xFF000080, 'teal': 0xFF008080, 'aqua': 0xFF00FFFF,
      'maroon': 0xFF800000, 'silver': 0xFFC0C0C0, 'gold': 0xFFFFD700,
    };

    final lower = s.toLowerCase();
    final namedValue = named[lower];
    if (namedValue != null) return ui.Color(namedValue);

    try {
      final hex = int.parse(s, radix: 16);
      if (s.length <= 6) {
        return ui.Color(0xFF000000 | hex);
      } else {
        return ui.Color(hex);
      }
    } catch (_) {
      return null;
    }
  }
}

/// Represents a segment of text in a variable-augmented string.
class _PlaceholderSegment {
  final String text;
  final bool isPlaceholder;

  const _PlaceholderSegment({
    required this.text,
    required this.isPlaceholder,
  });
}

// ─── Reusable parse helpers (module-level for _CanvasPreviewState) ─────

double _parseDouble(Map<String, dynamic> op, String key,
    [double defaultValue = 0]) {
  final value = op[key];
  if (value == null) return defaultValue;
  return double.tryParse(value.toString()) ?? defaultValue;
}

import '../../actions/executors/image_executor.dart';
import 'program.dart';
import 'runtime.dart';

class BdfdCanvasState {
  /// Operations per canvas name, in call order; `$attachImage` renders one.
  final Map<String, List<Map<String, dynamic>>> canvases = {};
  List<Map<String, dynamic>> operations = [];
  String? currentCanvas;
  final Set<String> pending = {};
  bool finalizerRegistered = false;
  void clear() {
    pending.clear();
    canvases.clear();
    operations = [];
    currentCanvas = null;
  }
}

Map<String, BdfdNativeFunction> bdfdCanvasFunctions() {
  // Canvas state belongs to one execution, never to the shared engine.
  final states = Expando<BdfdCanvasState>('bdfdCanvas');
  final stateOf = _CanvasStates(states);

  return {
    'canvascreate': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 4,
      handler: (call) async {
        final name = await call.argument(0);
        final width = await call.argument(1);
        final height = await call.argument(2);
        final color = call.argumentCount > 3 ? await call.argument(3) : '';
        final state = stateOf(call.context);
        state.currentCanvas = name;
        state.operations = state.canvases[name.trim()] = [];
        state.pending.add(name.trim());
        if (!state.finalizerRegistered) {
          state.finalizerRegistered = true;
          final context = call.context;
          context.beforeFlush.add(() async {
            state.finalizerRegistered = false;
            for (final pendingName in state.pending.toList()) {
              await _renderCanvas(state, pendingName, context);
            }
          });
        }
        state.operations.add({
          'op': 'create',
          'name': name,
          'width': width,
          'height': height,
          'color': color,
        });
        return '';
      },
    ),
    'canvascontainer': BdfdNativeFunction(
      minArguments: 5,
      maxArguments: 6,
      handler: (call) async {
        final state = stateOf(call.context);
        final name = await call.argument(0);
        final x = await call.argument(1);
        final y = await call.argument(2);
        final width = await call.argument(3);
        final height = await call.argument(4);
        final color = call.argumentCount > 5 ? await call.argument(5) : '';
        state.operations.add({
          'op': 'container',
          'name': name,
          'x': x,
          'y': y,
          'width': width,
          'height': height,
          'color': color,
        });
        return '';
      },
    ),
    'canvasloadimage': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 6,
      handler: (call) async {
        final state = stateOf(call.context);
        final url = await call.argument(0);
        final x = call.argumentCount > 1 ? await call.argument(1) : '0';
        final y = call.argumentCount > 2 ? await call.argument(2) : '0';
        final width = call.argumentCount > 3 ? await call.argument(3) : '';
        final height = call.argumentCount > 4 ? await call.argument(4) : '';
        final container = call.argumentCount > 5 ? await call.argument(5) : '';
        state.operations.add({
          'op': 'loadImage',
          'url': url,
          'x': x,
          'y': y,
          'width': width,
          'height': height,
          if (container.isNotEmpty) 'container': container,
        });
        return '';
      },
    ),
    'canvasdrawtext': BdfdNativeFunction(
      minArguments: 5,
      maxArguments: 8,
      handler: (call) async {
        final state = stateOf(call.context);
        final text = await call.argument(0);
        final x = await call.argument(1);
        final y = await call.argument(2);
        final fontSize = await call.argument(3);
        final color = await call.argument(4);
        final textAlign = call.argumentCount > 5 ? await call.argument(5) : '';
        final maxWidth = call.argumentCount > 6 ? await call.argument(6) : '';
        final container = call.argumentCount > 7 ? await call.argument(7) : '';
        state.operations.add({
          'op': 'drawText',
          'text': text,
          'x': x,
          'y': y,
          'fontSize': fontSize,
          'color': color,
          if (textAlign.isNotEmpty) 'textAlign': textAlign,
          if (maxWidth.isNotEmpty) 'maxWidth': maxWidth,
          if (container.isNotEmpty) 'container': container,
        });
        return '';
      },
    ),
    'canvasdrawcircle': BdfdNativeFunction(
      minArguments: 5,
      maxArguments: 7,
      handler: (call) async {
        final state = stateOf(call.context);
        final x = await call.argument(0);
        final y = await call.argument(1);
        final radius = await call.argument(2);
        final color = await call.argument(3);
        final fill = await call.argument(4);
        final blend = call.argumentCount > 5 ? await call.argument(5) : '';
        final container = call.argumentCount > 6 ? await call.argument(6) : '';
        state.operations.add({
          'op': 'drawCircle',
          'x': x,
          'y': y,
          'radius': radius,
          'color': color,
          'fill': fill,
          if (blend.isNotEmpty) 'blend': blend,
          if (container.isNotEmpty) 'container': container,
        });
        return '';
      },
    ),
    'canvasdrawrect': BdfdNativeFunction(
      minArguments: 6,
      maxArguments: 8,
      handler: (call) async {
        final state = stateOf(call.context);
        final x = await call.argument(0);
        final y = await call.argument(1);
        final width = await call.argument(2);
        final height = await call.argument(3);
        final color = await call.argument(4);
        final fill = await call.argument(5);
        final blend = call.argumentCount > 6 ? await call.argument(6) : '';
        final container = call.argumentCount > 7 ? await call.argument(7) : '';
        state.operations.add({
          'op': 'drawRect',
          'x': x,
          'y': y,
          'width': width,
          'height': height,
          'color': color,
          'fill': fill,
          if (blend.isNotEmpty) 'blend': blend,
          if (container.isNotEmpty) 'container': container,
        });
        return '';
      },
    ),
    'canvasdrawline': BdfdNativeFunction(
      minArguments: 6,
      maxArguments: 8,
      handler: (call) async {
        final state = stateOf(call.context);
        final x1 = await call.argument(0);
        final y1 = await call.argument(1);
        final x2 = await call.argument(2);
        final y2 = await call.argument(3);
        final color = await call.argument(4);
        final thickness = await call.argument(5);
        final blend = call.argumentCount > 6 ? await call.argument(6) : '';
        final container = call.argumentCount > 7 ? await call.argument(7) : '';
        state.operations.add({
          'op': 'drawLine',
          'x1': x1,
          'y1': y1,
          'x2': x2,
          'y2': y2,
          'color': color,
          'thickness': thickness,
          if (blend.isNotEmpty) 'blend': blend,
          if (container.isNotEmpty) 'container': container,
        });
        return '';
      },
    ),
    'canvascompositeimage': BdfdNativeFunction(
      minArguments: 5,
      maxArguments: 8,
      handler: (call) async {
        final state = stateOf(call.context);
        final url = await call.argument(0);
        final x = await call.argument(1);
        final y = await call.argument(2);
        final width = await call.argument(3);
        final height = await call.argument(4);
        final shape = call.argumentCount > 5 ? await call.argument(5) : '';
        final blend = call.argumentCount > 6 ? await call.argument(6) : '';
        final container = call.argumentCount > 7 ? await call.argument(7) : '';
        state.operations.add({
          'op': 'compositeImage',
          'url': url,
          'x': x,
          'y': y,
          'width': width,
          'height': height,
          if (shape.isNotEmpty) 'shape': shape,
          if (blend.isNotEmpty) 'blend': blend,
          if (container.isNotEmpty) 'container': container,
        });
        return '';
      },
    ),
    'canvasprogressbar': BdfdNativeFunction(
      minArguments: 7,
      maxArguments: 13,
      handler: (call) async {
        final state = stateOf(call.context);
        final x = await call.argument(0);
        final y = await call.argument(1);
        final width = await call.argument(2);
        final height = await call.argument(3);
        final percentage = await call.argument(4);
        final barColor = await call.argument(5);
        final trackColor = await call.argument(6);
        Future<String?> optional(int index) async =>
            call.argumentCount > index ? await call.argument(index) : null;
        final textColor = await optional(7);
        final borderWidth = await optional(8);
        final orientation = await optional(9);
        final fontSize = await optional(10);
        final container = await optional(11);
        final borderRadius = await optional(12);
        state.operations.add({
          'op': 'progressBar',
          'x': x,
          'y': y,
          'width': width,
          'height': height,
          'percentage': percentage,
          'barColor': barColor,
          'trackColor': trackColor,
          if (textColor != null) 'textColor': textColor,
          if (borderWidth != null) 'borderWidth': borderWidth,
          if (orientation != null) 'orientation': orientation,
          if (fontSize != null) 'fontSize': fontSize,
          if (container != null && container.isNotEmpty) 'container': container,
          if (borderRadius != null) 'borderRadius': borderRadius,
        });
        return '';
      },
    ),
    'canvassetpixel': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 4,
      handler: (call) async {
        final state = stateOf(call.context);
        final x = await call.argument(0);
        final y = await call.argument(1);
        final color = await call.argument(2);
        final container = call.argumentCount > 3 ? await call.argument(3) : '';
        state.operations.add({
          'op': 'setPixel',
          'x': x,
          'y': y,
          'color': color,
          if (container.isNotEmpty) 'container': container,
        });
        return '';
      },
    ),
    'canvasinvert': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final state = stateOf(call.context);
        state.operations.add({'op': 'invert'});
        return '';
      },
    ),
    'canvasgrayscale': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final state = stateOf(call.context);
        state.operations.add({'op': 'grayscale'});
        return '';
      },
    ),
    'canvasrotate': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final state = stateOf(call.context);
        final angle = await call.argument(0);
        state.operations.add({'op': 'rotate', 'angle': angle});
        return '';
      },
    ),
    'attachimage': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final state = stateOf(call.context);
        final name = call.argumentCount > 0
            ? (await call.argument(0)).trim()
            : (state.currentCanvas ?? '').trim();
        if (!state.canvases.containsKey(name)) {
          throw BdfdNativeError(
            'Canvas "$name" does not exist; use \$canvasCreate first',
            call.location,
          );
        }
        await _renderCanvas(state, name, call.context);
        return '';
      },
    ),
  };
}

class _CanvasStates {
  _CanvasStates(this._states);
  final Expando<BdfdCanvasState> _states;
  BdfdCanvasState call(BdfdContext context) =>
      _states[context] ??= BdfdCanvasState();
}

/// Renders one canvas and exposes it as the `_canvasAttachment_<name>` temp
/// variable, which message senders attach as `<name>.png`.
Future<void> _renderCanvas(
  BdfdCanvasState state,
  String name,
  BdfdContext context,
) async {
  state.pending.remove(name);
  final operations = state.canvases[name] ?? const [];
  final resolver = context.imageSourceResolver;
  final rendered = <Map<String, dynamic>>[];
  for (final op in operations) {
    final copy = Map<String, dynamic>.from(op);
    if (resolver != null &&
        (copy['op'] == 'loadImage' || copy['op'] == 'compositeImage')) {
      copy['url'] = await resolver(copy['url'].toString().trim());
    }
    rendered.add(copy);
  }
  final results = <String, String>{};
  await executeRuntimeImageBlock(
    payload: {'operations': rendered, 'imageName': name},
    resultKey: 'image',
    results: results,
    variables: <String, String>{},
    resolveValue: (input) => input,
  );
  final png = results['image'] ?? '';
  if (png.isNotEmpty) {
    context.temporaryVariables['_canvasAttachment_${name.isEmpty ? 'canvas' : name}'] =
        png;
  }
}

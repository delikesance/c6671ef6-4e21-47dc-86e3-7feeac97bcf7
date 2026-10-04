import 'runtime.dart';

class BdfdCanvasState {
  final List<Map<String, dynamic>> operations = [];
  String? currentCanvas;
  void clear() {
    operations.clear();
    currentCanvas = null;
  }
}

Map<String, BdfdNativeFunction> bdfdCanvasFunctions() {
  final state = BdfdCanvasState();

  return {
    'canvascreate': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 4,
      handler: (call) async {
        final name = await call.argument(0);
        final width = await call.argument(1);
        final height = await call.argument(2);
        final color = call.argumentCount > 3 ? await call.argument(3) : '';
        state.currentCanvas = name;
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
        final x = await call.argument(0);
        final y = await call.argument(1);
        final width = await call.argument(2);
        final height = await call.argument(3);
        final percentage = await call.argument(4);
        final barColor = await call.argument(5);
        final trackColor = await call.argument(6);
        final textColor = call.argumentCount > 7 ? await call.argument(7) : '';
        state.operations.add({
          'op': 'progressBar',
          'x': x,
          'y': y,
          'width': width,
          'height': height,
          'percentage': percentage,
          'barColor': barColor,
          'trackColor': trackColor,
          if (textColor.isNotEmpty) 'textColor': textColor,
        });
        return '';
      },
    ),
    'canvassetpixel': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 4,
      handler: (call) async {
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
        state.operations.add({'op': 'invert'});
        return '';
      },
    ),
    'canvasgrayscale': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        state.operations.add({'op': 'grayscale'});
        return '';
      },
    ),
    'canvasrotate': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final angle = await call.argument(0);
        state.operations.add({'op': 'rotate', 'angle': angle});
        return '';
      },
    ),
    'attachimage': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final name = call.argumentCount > 0
            ? (await call.argument(0)).trim()
            : (state.currentCanvas ?? 'canvas');
        call.context.variables['_canvasAttachment_$name'] = name;
        return '';
      },
    ),
  };
}

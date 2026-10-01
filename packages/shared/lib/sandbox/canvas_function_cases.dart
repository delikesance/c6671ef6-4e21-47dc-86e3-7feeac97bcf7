import 'dart:convert';

import 'package:image/image.dart' as img;

import 'function_suite.dart';

final _blueSource = (() {
  final image = img.Image(width: 2, height: 2);
  img.fill(image, color: img.ColorRgba8(0, 0, 255, 255));
  return 'data:image/png;base64,${base64Encode(img.encodePng(image))}';
})();

/// Pixel contracts use the production image renderer inside the sandbox.
final sandboxCanvasFunctionCases = [
  SandboxFunctionCase(
    'canvascreate',
    r'$canvasCreate[card;3;2;red]',
    0,
    '',
    label: 'creates a red image of the requested size',
    expectedValues: {
      '/images/card/width': 3,
      '/images/card/height': 2,
      '/images/card/pixels/0,0': '#ff0000ff',
      '/images/card/pixels/2,1': '#ff0000ff',
    },
  ),
  SandboxFunctionCase(
    'canvassetpixel',
    r'$canvasCreate[card;3;3;white]$canvasSetPixel[1;1;blue]',
    0,
    '',
    label: 'changes one pixel',
    expectedValues: {
      '/images/card/pixels/0,0': '#ffffffff',
      '/images/card/pixels/1,1': '#0000ffff',
    },
  ),
  SandboxFunctionCase(
    'attachimage',
    r'$canvasCreate[card;2;2;green]$attachImage[card]',
    0,
    '',
    label: 'exposes the rendered attachment',
    expectedValues: {
      '/images/card/width': 2,
      '/images/card/pixels/0,0': '#00ff00ff',
    },
  ),
  SandboxFunctionCase(
    'canvasdrawrect',
    r'$canvasCreate[card;5;5;white]$canvasDrawRect[1;1;2;2;red;true]',
    0,
    '',
    scenario: {
      'pixelProbes': [
        [0, 0],
        [1, 1],
      ],
    },
    expectedValues: {
      '/images/card/pixels/0,0': '#ffffffff',
      '/images/card/pixels/1,1': '#ff0000ff',
    },
  ),
  SandboxFunctionCase(
    'canvasdrawcircle',
    r'$canvasCreate[card;5;5;white]$canvasDrawCircle[2;2;1;red;true]',
    0,
    '',
    expectedValues: {
      '/images/card/pixels/2,2': '#ff0000ff',
      '/images/card/pixels/0,0': '#ffffffff',
    },
  ),
  SandboxFunctionCase(
    'canvasdrawline',
    r'$canvasCreate[card;5;5;white]$canvasDrawLine[0;0;4;4;blue;1]',
    0,
    '',
    expectedValues: {
      '/images/card/pixels/0,0': '#0000ffff',
      '/images/card/pixels/4,4': '#0000ffff',
    },
  ),
  SandboxFunctionCase(
    'canvasdrawtext',
    r'$canvasCreate[card;40;20;white]$canvasDrawText[A;0;0;14;black]',
    0,
    '',
    label: 'draws visible glyph pixels',
    expectedValues: {'/images/card/width': 40, '/images/card/nonUniform': true},
  ),
  SandboxFunctionCase(
    'canvascontainer',
    r'$canvasCreate[card;5;5;white]$canvasContainer[slot;2;2;2;2]$canvasSetPixel[0;0;red;slot]',
    0,
    '',
    scenario: {
      'pixelProbes': [
        [0, 0],
        [2, 2],
      ],
    },
    expectedValues: {
      '/images/card/pixels/0,0': '#ffffffff',
      '/images/card/pixels/2,2': '#ff0000ff',
    },
  ),
  SandboxFunctionCase(
    'canvasloadimage',
    r'$canvasCreate[card;4;4;white]$canvasLoadImage[((opts.source));1;1;2;2]',
    0,
    '',
    scenario: {
      'options': {'source': _blueSource},
      'pixelProbes': [
        [0, 0],
        [1, 1],
      ],
    },
    expectedValues: {
      '/images/card/pixels/0,0': '#ffffffff',
      '/images/card/pixels/1,1': '#0000ffff',
    },
  ),
  SandboxFunctionCase(
    'canvascompositeimage',
    r'$canvasCreate[card;4;4;white]$canvasCompositeImage[((opts.source));1;1;2;2]',
    0,
    '',
    scenario: {
      'options': {'source': _blueSource},
      'pixelProbes': [
        [0, 0],
        [1, 1],
      ],
    },
    expectedValues: {
      '/images/card/pixels/0,0': '#ffffffff',
      '/images/card/pixels/1,1': '#0000ffff',
    },
  ),
  SandboxFunctionCase(
    'canvasinvert',
    r'$canvasCreate[card;2;2;red]$canvasInvert',
    0,
    '',
    expectedValues: {'/images/card/pixels/0,0': '#00ffffff'},
  ),
  SandboxFunctionCase(
    'canvasgrayscale',
    r'$canvasCreate[card;2;2;red]$canvasGrayscale',
    0,
    '',
    expectedValues: {'/images/card/pixels/0,0': '#4c4c4cff'},
  ),
  SandboxFunctionCase(
    'canvasprogressbar',
    r'$canvasCreate[card;10;4;white]$canvasProgressBar[0;0;10;4;50;red;blue;blue]',
    0,
    '',
    scenario: {
      'pixelProbes': [
        [0, 0],
        [9, 0],
      ],
    },
    expectedValues: {
      '/images/card/pixels/0,0': '#ff0000ff',
      '/images/card/pixels/9,0': '#0000ffff',
    },
  ),
  SandboxFunctionCase(
    'canvasrotate',
    r'$canvasCreate[card;2;3;white]$canvasSetPixel[0;0;red]$canvasRotate[90]',
    0,
    '',
    label: 'rotates a non-square image',
    expectedValues: {
      '/images/card/width': 3,
      '/images/card/height': 2,
      '/images/card/nonUniform': true,
    },
  ),
  SandboxFunctionCase(
    'canvasloadimage',
    r'$canvasCreate[card;2;2;white]$canvasLoadImage[https://example.com/image.png]',
    0,
    '',
    label: 'sandbox rejects a remote image source',
    expectedValues: {
      '/success': false,
      '/error':
          'Bad state: Sandbox image source must have an explicit local fixture',
    },
  ),
  SandboxFunctionCase(
    'canvasloadimage',
    r'$canvasCreate[card;4;4;white]$canvasLoadImage[https://example.com/image.png;1;1;2;2]',
    0,
    '',
    label: 'remote source resolves only through local fixture bytes',
    scenario: {
      'imageSources': {'https://example.com/image.png': _blueSource},
      'pixelProbes': [
        [0, 0],
        [1, 1],
      ],
    },
    expectedValues: {
      '/images/card/pixels/0,0': '#ffffffff',
      '/images/card/pixels/1,1': '#0000ffff',
    },
  ),
];

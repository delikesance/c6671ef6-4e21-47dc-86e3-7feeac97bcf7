import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_shared/types/action.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'helpers/fake_role_gateway.dart';
import 'helpers/golden_expectations.dart';
import 'helpers/visual_message_gateway.dart';
import 'helpers/visual_parity_harness.dart';

/// Parity of the image blocks (wave 7) between the historical executor and
/// `bc_<type>` on the native engine: runtimeImageBlock, attachImage and the six
/// visual-only canvas*Block types. Same renderer on both sides, so PNG bytes,
/// result keys, `temp._canvasAttachment_*`, source resolution and error text
/// are compared exactly.

late HttpServer _server;
final _requests = <String>[];

String get _base => 'http://127.0.0.1:${_server.port}';

String _png(int w, int h, img.Color color) {
  final canvas = img.Image(width: w, height: h);
  img.fill(canvas, color: color);
  return base64Encode(img.encodePng(canvas));
}

Action _a(
  BotCreatorActionType type,
  Map<String, dynamic> payload, {
  String? key,
  Map<String, String> error = const {},
  bool enabled = true,
}) => visualAction(
  type,
  key: key,
  payload: payload,
  error: error,
  enabled: enabled,
);

const _block = BotCreatorActionType.runtimeImageBlock;
const _attach = BotCreatorActionType.attachImage;

Future<Outcome<FakeGateway>> _parity(
  List<Action> actions, {
  Map<String, String>? variables,
  bool throwOnError = false,
  bool expectNative = true,
}) async {
  _requests.clear();
  final outcome = await visualParity<FakeGateway>(
    actions,
    makeGateway: FakeGateway.new,
    effects: (_) {
      final seen = List<String>.of(_requests);
      _requests.clear();
      return seen;
    },
    expectNative: expectNative,
    variables: variables,
    throwOnError: throwOnError,
  );
  // Explicit expectations of the native path (test/golden/image.json). The
  // historical comparison above is done by [visualParity]; once it is native
  // only, this snapshot is what keeps the test meaningful.
  expectGolden(
    {
      'effects': outcome.effects,
      'results': outcome.results,
      'variables': outcome.variables,
      'error': outcome.errorText,
    },
    // The test server port changes on every run.
    mask: {_base: 'http://BASE'},
  );
  return outcome;
}

void main() {
  useGolden('image');
  setUpAll(() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final bytes = base64Decode(_png(6, 4, img.ColorRgba8(0, 0, 255, 255)));
    _server.listen((request) {
      _requests.add(request.uri.path);
      if (request.uri.path == '/missing.png') {
        request.response.statusCode = 404;
      } else {
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add(bytes);
      }
      request.response.close();
    });
  });
  tearDownAll(() => _server.close(force: true));

  group('runtimeImageBlock parity', () {
    gtest('creates, draws and publishes the named attachment', () async {
      final outcome = await _parity(
        [
          _a(_block, {
            'imageName': 'card',
            'operations': [
              {'op': 'create', 'width': '40', 'height': '20', 'color': 'black'},
              {
                'op': 'drawText',
                'text': 'Hi ((name))',
                'x': '2',
                'y': '2',
                'color': 'white',
                'fontSize': '14',
              },
              {
                'op': 'drawCircle',
                'x': '20',
                'y': '10',
                'radius': '5',
                'color': 'red',
                'fill': 'true',
              },
              {
                'op': 'drawRect',
                'x': '1',
                'y': '1',
                'width': '8',
                'height': '8',
                'color': '#00ff00',
              },
              {
                'op': 'drawLine',
                'x1': '0',
                'y1': '0',
                'x2': '39',
                'y2': '19',
                'color': 'blue',
              },
              {
                'op': 'progressBar',
                'x': '2',
                'y': '14',
                'width': '30',
                'height': '4',
                'progress': '50',
              },
              {'op': 'setPixel', 'x': '3', 'y': '3', 'color': 'yellow'},
              {'op': 'invert'},
              {'op': 'grayscale'},
              {'op': 'rotate', 'angle': '90'},
            ],
          }, key: 'img'),
        ],
        variables: {'name': 'Ana'},
      );
      expect(outcome.results!['img'], isNotEmpty);
      expect(outcome.variables['img'], outcome.results!['img']);
      expect(
        outcome.variables['temp._canvasAttachment_card'],
        outcome.results!['img'],
      );
    });

    gtest('without an image name no attachment variable', () async {
      final outcome = await _parity([
        _a(_block, {
          'operations': [
            {'op': 'create', 'width': '4', 'height': '4', 'color': 'red'},
          ],
        }, key: 'img'),
      ]);
      expect(
        outcome.variables.keys.where((k) => k.contains('_canvasAttachment_')),
        isEmpty,
      );
    });

    gtest('no operations or no canvas gives an empty result', () async {
      final outcome = await _parity([
        _a(_block, {'imageName': 'a', 'operations': <Object>[]}, key: 'none'),
        _a(_block, {
          'imageName': 'b',
          'operations': [
            {'op': 'drawText', 'text': 'x'},
          ],
        }, key: 'nocanvas'),
      ]);
      expect(outcome.results!['none'], '');
      expect(outcome.results!['nocanvas'], '');
    });

    gtest('loads and composites from URL, data URL and raw base64', () async {
      final data =
          'data:image/png;base64,${_png(3, 3, img.ColorRgba8(255, 0, 0, 255))}';
      final raw = _png(2, 2, img.ColorRgba8(0, 255, 0, 255));
      final outcome = await _parity(
        [
          _a(_block, {
            'imageName': 'mix',
            'operations': [
              {'op': 'loadImage', 'url': '((base))/a.png'},
              {'op': 'compositeImage', 'url': data, 'x': '1', 'y': '1'},
              {'op': 'compositeImage', 'url': raw, 'x': '3', 'y': '0'},
              {
                'op': 'compositeImage',
                'url': '((base))/a.png',
                'x': '0',
                'y': '0',
              },
            ],
          }, key: 'mix'),
        ],
        variables: {'base': _base},
      );
      expect(outcome.results!['mix'], isNotEmpty);
      expect(outcome.effects, ['/a.png']);
    });

    gtest('an unreachable source follows the executor behaviour', () async {
      await _parity([
        _a(_block, {
          'imageName': 'bad',
          'operations': [
            {'op': 'loadImage', 'url': '$_base/missing.png'},
          ],
        }, key: 'bad'),
        _a(_block, {
          'imageName': 'after',
          'operations': [
            {'op': 'create', 'width': '2', 'height': '2', 'color': 'red'},
          ],
        }, key: 'after'),
      ]);
    });

    gtest(
      'result placeholders of earlier actions and variables resolve',
      () async {
        await _parity(
          [
            _a(_attach, {
              'imageName': 'first',
              'imageSource': _png(2, 2, img.ColorRgba8(1, 2, 3, 255)),
            }, key: 'first'),
            _a(_block, {
              'imageName': 'second',
              'operations': [
                {
                  'op': 'create',
                  'width': '((w))',
                  'height': '((first))',
                  'color': 'red',
                },
              ],
            }, key: 'second'),
          ],
          variables: {'w': '6'},
        );
      },
    );

    gtest('error modes of the block: continue, skip, stop', () async {
      await _parity([
        _a(
          _attach,
          {'imageName': '', 'imageSource': 'x'},
          key: 'e1',
          error: {'mode': 'continue'},
        ),
        _a(_block, {
          'imageName': 'ok',
          'operations': [
            {'op': 'create', 'width': '2', 'height': '2', 'color': 'red'},
          ],
        }, key: 'ok'),
      ]);
      await _parity([
        _a(_attach, {'imageName': 'n', 'imageSource': ''}, key: 'e2'),
        _a(_block, {'operations': <Object>[]}, key: 'never'),
      ]);
    });

    gtest('inside a protected execution (throwOnError)', () async {
      await _parity([
        _a(_attach, {'imageName': 'n', 'imageSource': ''}, key: 'e'),
      ], throwOnError: true);
    });
  });

  group('attachImage parity', () {
    gtest('stores a data URL, raw base64 and URL source', () async {
      final outcome = await _parity(
        [
          _a(_attach, {
            'imageName': 'one',
            'imageSource':
                'data:image/png;base64,${_png(2, 2, img.ColorRgba8(9, 9, 9, 255))}',
            'altText': 'ignored',
          }, key: 'one'),
          _a(_attach, {
            'imageName': ' ((n)) ',
            'imageSource': _png(3, 1, img.ColorRgba8(5, 5, 5, 255)),
          }, key: 'two'),
          _a(_attach, {
            'imageName': 'url',
            'imageSource': '((base))/pic.png',
          }, key: 'three'),
        ],
        variables: {'n': 'dyn', 'base': _base},
      );
      expect(outcome.results, {
        'one': 'attached',
        'two': 'attached',
        'three': 'attached',
      });
      expect(
        outcome.variables.containsKey('temp._canvasAttachment_dyn'),
        isTrue,
      );
      expect(outcome.effects, ['/pic.png']);
    });

    gtest('missing name or source, undecodable and 404 sources', () async {
      for (final payload in [
        {'imageName': '', 'imageSource': 'abc'},
        {'imageName': 'n', 'imageSource': ''},
        {'imageName': 'n', 'imageSource': '$_base/missing.png'},
        {'imageName': 'n', 'imageSource': '!!notbase64!!'},
      ]) {
        final outcome = await _parity([_a(_attach, payload, key: 'x')]);
        expect(outcome.error, isNotNull);
      }
    });

    gtest('a disabled action stays a no-op', () async {
      await _parity([
        _a(
          _attach,
          {'imageName': 'n', 'imageSource': ''},
          key: 'x',
          enabled: false,
        ),
      ], expectNative: false);
    });
  });

  group('canvas sub-block types parity', () {
    gtest('never executable on their own, with the historical error', () async {
      for (final type in [
        BotCreatorActionType.canvasCreateBlock,
        BotCreatorActionType.canvasLoadImageBlock,
        BotCreatorActionType.canvasDrawTextBlock,
        BotCreatorActionType.canvasDrawCircleBlock,
        BotCreatorActionType.canvasDrawRectBlock,
        BotCreatorActionType.canvasDrawLineBlock,
      ]) {
        final outcome = await _parity([
          _a(type, {'width': '2'}, key: 'c'),
        ]);
        expect(
          outcome.error.toString(),
          contains('${type.name} must be nested'),
        );
      }
    });

    gtest('error mode continue lets the next action run', () async {
      final outcome = await _parity([
        _a(
          BotCreatorActionType.canvasCreateBlock,
          {},
          key: 'c',
          error: {'mode': 'continue'},
        ),
        _a(_attach, {
          'imageName': 'k',
          'imageSource': _png(1, 1, img.ColorRgba8(1, 1, 1, 255)),
        }, key: 'k'),
      ]);
      expect(outcome.results!['k'], 'attached');
    });
  });

  group('attachment consumed by a following send', () {
    gtest('attachImage then sendMessage attaches the png', () async {
      final outcome = await messageParity([
        _a(_attach, {
          'imageName': 'card',
          'imageSource': _png(2, 2, img.ColorRgba8(1, 2, 3, 255)),
        }, key: 'att'),
        _a(BotCreatorActionType.sendMessage, {
          'channelId': '30',
          'content': 'look',
        }, key: 'send'),
      ]);
      expect(outcome.writes.single['attachments'], isNotEmpty);
    });
  });
}

import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _makeCommand({
  Map<String, dynamic>? data,
  String type = 'chatInput',
}) {
  return {'name': 'ticket', 'type': type, 'data': data ?? {}};
}

void main() {
  group('normalizeCommandData – embeds', () {
    test('migrates legacy single embed into embeds list', () {
      final command = _makeCommand(
        data: {
          'response': {
            'mode': 'text',
            'text': '',
            'type': 'normal',
            'embed': {'title': 'My Title', 'description': 'Desc', 'url': ''},
            'embeds': [],
          },
        },
      );

      final result = normalizeCommandData(command);
      final embeds = result['data']['response']['embeds'] as List;
      expect(embeds.length, 1);
      expect(embeds[0]['title'], 'My Title');
      expect(result['data']['response']['mode'], 'message');
    });

    test('limits embeds to 10', () {
      final command = _makeCommand(
        data: {
          'response': {
            'mode': 'embed',
            'text': '',
            'type': 'normal',
            'embeds': List.generate(
              15,
              (i) => {'title': 'Embed $i', 'description': '', 'url': ''},
            ),
          },
        },
      );

      final result = normalizeCommandData(command);
      final embeds = result['data']['response']['embeds'] as List;
      expect(embeds.length, 10);
    });
  });

  group('normalizeCommandData – options preservation', () {
    test('preserves serialized options including autocomplete metadata', () {
      final command = _makeCommand(
        data: {
          'options': [
            {
              'type': 'string',
              'name': 'country',
              'description': 'Country',
              'required': false,
              'autocomplete': {
                'enabled': true,
                'workflow': 'country_search',
                'entryPoint': 'main',
                'arguments': {'dataset': 'countries'},
              },
            },
            {
              'type': 'integer',
              'name': 'limit',
              'description': 'Limit',
              'required': false,
              'choices': [
                {'name': 'Five', 'value': 5},
              ],
            },
          ],
        },
      );

      final result = normalizeCommandData(command);
      final options = result['data']['options'] as List<dynamic>;

      expect(options.length, 2);
      expect(options.first, <String, dynamic>{
        'type': 'string',
        'name': 'country',
        'description': 'Country',
        'required': false,
        'autocomplete': {
          'enabled': true,
          'workflow': 'country_search',
          'entryPoint': 'main',
          'arguments': {'dataset': 'countries'},
        },
      });
      expect((options.last as Map<String, dynamic>)['choices'], [
        {'name': 'Five', 'value': 5},
      ]);
    });

  });

  group('normalizeCommandData – legacy embed migration edge cases', () {
    test('migrates legacy embed with only color field', () {
      final command = _makeCommand(
        data: {
          'response': {
            'mode': 'embed',
            'text': '',
            'type': 'normal',
            'embed': {
              'title': '',
              'description': '',
              'url': '',
              'color': '#FF0000',
            },
            'embeds': [],
          },
        },
      );

      final result = normalizeCommandData(command);
      final embeds = result['data']['response']['embeds'] as List;
      expect(embeds.length, 1);
      expect(embeds[0]['color'], '#FF0000');
      expect(result['data']['response']['mode'], 'message');
    });

    test('migrates legacy embed with only footer', () {
      final command = _makeCommand(
        data: {
          'response': {
            'mode': 'embed',
            'text': '',
            'type': 'normal',
            'embed': {
              'title': '',
              'description': '',
              'url': '',
              'footer': {'text': 'My footer'},
            },
            'embeds': [],
          },
        },
      );

      final result = normalizeCommandData(command);
      final embeds = result['data']['response']['embeds'] as List;
      expect(embeds.length, 1);
      expect(embeds[0]['footer'], {'text': 'My footer'});
    });

    test('migrates legacy embed with only fields', () {
      final command = _makeCommand(
        data: {
          'response': {
            'mode': 'embed',
            'text': '',
            'type': 'normal',
            'embed': {
              'title': '',
              'description': '',
              'url': '',
              'fields': [
                {'name': 'Field 1', 'value': 'Val 1', 'inline': true},
              ],
            },
            'embeds': [],
          },
        },
      );

      final result = normalizeCommandData(command);
      final embeds = result['data']['response']['embeds'] as List;
      expect(embeds.length, 1);
      expect((embeds[0]['fields'] as List).length, 1);
    });

    test('migrates legacy embed with only image', () {
      final command = _makeCommand(
        data: {
          'response': {
            'mode': 'embed',
            'text': '',
            'type': 'normal',
            'embed': {
              'title': '',
              'description': '',
              'url': '',
              'image': 'https://example.com/img.png',
            },
            'embeds': [],
          },
        },
      );

      final result = normalizeCommandData(command);
      final embeds = result['data']['response']['embeds'] as List;
      expect(embeds.length, 1);
      expect(embeds[0]['image'], 'https://example.com/img.png');
    });

    test('migrates legacy embed with only thumbnail', () {
      final command = _makeCommand(
        data: {
          'response': {
            'mode': 'embed',
            'text': '',
            'type': 'normal',
            'embed': {
              'title': '',
              'description': '',
              'url': '',
              'thumbnail': 'https://example.com/thumb.png',
            },
            'embeds': [],
          },
        },
      );

      final result = normalizeCommandData(command);
      final embeds = result['data']['response']['embeds'] as List;
      expect(embeds.length, 1);
      expect(embeds[0]['thumbnail'], 'https://example.com/thumb.png');
    });

    test('migrates legacy embed with only author', () {
      final command = _makeCommand(
        data: {
          'response': {
            'mode': 'embed',
            'text': '',
            'type': 'normal',
            'embed': {
              'title': '',
              'description': '',
              'url': '',
              'author': {'name': 'Bot Author'},
            },
            'embeds': [],
          },
        },
      );

      final result = normalizeCommandData(command);
      final embeds = result['data']['response']['embeds'] as List;
      expect(embeds.length, 1);
      expect(embeds[0]['author'], {'name': 'Bot Author'});
    });

    test('does not migrate truly empty legacy embed', () {
      final command = _makeCommand(
        data: {
          'response': {
            'mode': 'text',
            'text': 'Hello',
            'type': 'normal',
            'embed': {'title': '', 'description': '', 'url': ''},
            'embeds': [],
          },
        },
      );

      final result = normalizeCommandData(command);
      final embeds = result['data']['response']['embeds'] as List;
      expect(embeds, isEmpty);
      expect(result['data']['response']['mode'], 'message');
    });
  });
}

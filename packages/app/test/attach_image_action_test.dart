import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart'
    show ActionItem;
import 'package:bot_creator/features/bot_editor/logic/action_normalization.dart'
    show purgeActionPayloadStrict;

void main() {
  group('ActionItem serialization for attachImage', () {
    test('toJson preserves all attachImage parameters', () {
      final action = ActionItem(
        id: 'test-1',
        type: BotCreatorActionType.attachImage,
        actionKey: 'test-1',
        parameters: {
          'imageName': 'myPhoto',
          'imageSource': 'https://example.com/photo.png',
          'altText': 'A nice photo',
        },
      );

      final json = action.toJson();

      expect(json['type'], equals('attachImage'));
      expect(json['id'], equals('test-1'));
      expect(json['enabled'], isTrue);
      expect(json['key'], equals('test-1'));

      final payload = json['payload'] as Map<String, dynamic>;
      expect(payload['imageName'], equals('myPhoto'));
      expect(payload['imageSource'], equals('https://example.com/photo.png'));
      expect(payload['altText'], equals('A nice photo'));
    });

    test('toJson works with minimal required parameters', () {
      final action = ActionItem(
        id: 'test-min',
        type: BotCreatorActionType.attachImage,
        actionKey: 'test-min',
        parameters: {
          'imageName': 'avatar',
          'imageSource': 'data:image/png;base64,iVBORw0KGgo=',
        },
      );

      final json = action.toJson();
      final payload = json['payload'] as Map<String, dynamic>;

      expect(payload['imageName'], equals('avatar'));
      expect(payload['imageSource'],
          equals('data:image/png;base64,iVBORw0KGgo='));
      // altText is optional, should be absent if not provided
      expect(payload.containsKey('altText'), isFalse);
    });

    test('toJson handles empty optional altText', () {
      final action = ActionItem(
        id: 'test-2',
        type: BotCreatorActionType.attachImage,
        actionKey: 'test-2',
        parameters: {
          'imageName': 'logo',
          'imageSource': 'base64string',
          'altText': '',
        },
      );

      final json = action.toJson();
      final payload = json['payload'] as Map<String, dynamic>;
      expect(payload['altText'], equals(''));
    });

    test('fromJson correctly deserializes attachImage action', () {
      final json = {
        'id': 'from-json-1',
        'type': 'attachImage',
        'enabled': true,
        'key': 'from-json-1',
        'payload': {
          'imageName': 'deserialized',
          'imageSource': 'https://cdn.example.com/img.png',
          'altText': 'An image',
        },
      };

      final action = ActionItem.fromJson(json);

      expect(action.type, equals(BotCreatorActionType.attachImage));
      expect(action.id, equals('from-json-1'));
      expect(action.enabled, isTrue);
      expect(action.parameters['imageName'], equals('deserialized'));
      expect(action.parameters['imageSource'],
          equals('https://cdn.example.com/img.png'));
      expect(action.parameters['altText'], equals('An image'));
    });

    test('JSON round-trip preserves all fields', () {
      final original = ActionItem(
        id: 'round-trip-1',
        type: BotCreatorActionType.attachImage,
        actionKey: 'round-trip-1',
        parameters: {
          'imageName': 'round',
          'imageSource': 'https://example.com/trip.png',
          'altText': 'Trip image',
        },
      );

      final jsonStr = jsonEncode(original.toJson());
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final recreated = ActionItem.fromJson(decoded);

      expect(recreated.type, equals(BotCreatorActionType.attachImage));
      expect(recreated.parameters['imageName'],
          equals(original.parameters['imageName']));
      expect(recreated.parameters['imageSource'],
          equals(original.parameters['imageSource']));
      expect(
          recreated.parameters['altText'], equals(original.parameters['altText']));
    });

    test('fromJson with missing type defaults to sendMessage', () {
      final json = {
        'id': 'no-type',
        'type': 'nonexistent_type',
        'payload': {},
      };

      final action = ActionItem.fromJson(json);
      expect(action.type, equals(BotCreatorActionType.sendMessage));
    });

    test('fromJson with missing payload creates empty parameters', () {
      final json = {
        'id': 'no-payload',
        'type': 'attachImage',
      };

      final action = ActionItem.fromJson(json);
      expect(action.type, equals(BotCreatorActionType.attachImage));
      expect(action.parameters, isEmpty);
    });
  });

  group('purgeActionPayloadStrict for attachImage', () {
    test('all attachImage parameters survive purging', () {
      final params = {
        'imageName': 'photo',
        'imageSource': 'https://example.com/pic.png',
        'altText': 'Description',
      };

      final purged = purgeActionPayloadStrict(
        BotCreatorActionType.attachImage,
        params,
      );

      expect(purged['imageName'], equals('photo'));
      expect(purged['imageSource'], equals('https://example.com/pic.png'));
      expect(purged['altText'], equals('Description'));
    });

    test('legacy embed field is removed', () {
      final params = {
        'imageName': 'test',
        'imageSource': 'base64',
        'embed': {'title': 'Should be removed'},
      };

      final purged = purgeActionPayloadStrict(
        BotCreatorActionType.attachImage,
        params,
      );

      expect(purged.containsKey('embed'), isFalse);
      expect(purged['imageName'], equals('test'));
      expect(purged['imageSource'], equals('base64'));
    });

    test('extra metadata fields are preserved', () {
      final params = {
        'imageName': 'img',
        'imageSource': 'url',
        'customField': 'customValue',
        'metadata': {'key': 'val'},
      };

      final purged = purgeActionPayloadStrict(
        BotCreatorActionType.attachImage,
        params,
      );

      expect(purged['customField'], equals('customValue'));
      expect(purged['metadata'], equals({'key': 'val'}));
    });
  });

  group('ActionItem serialization integration', () {
    test('multiple actions including attachImage serialize correctly', () {
      final actions = [
        ActionItem(
          id: 'msg-1',
          type: BotCreatorActionType.sendMessage,
          actionKey: 'msg-1',
          parameters: {'content': 'Hello!'},
        ),
        ActionItem(
          id: 'attach-1',
          type: BotCreatorActionType.attachImage,
          actionKey: 'attach-1',
          parameters: {
            'imageName': 'banner',
            'imageSource': 'https://cdn.example.com/banner.png',
          },
        ),
        ActionItem(
          id: 'msg-2',
          type: BotCreatorActionType.respondWithMessage,
          actionKey: 'msg-2',
          parameters: {'content': 'Here is your image!'},
        ),
      ];

      final jsonList = actions.map((a) => a.toJson()).toList();
      expect(jsonList.length, equals(3));

      // Verify attachImage is between two messages
      expect(jsonList[0]['type'], equals('sendMessage'));
      expect(jsonList[1]['type'], equals('attachImage'));
      expect(jsonList[2]['type'], equals('respondWithMessage'));

      // Verify attachImage payload
      final attachPayload = jsonList[1]['payload'] as Map<String, dynamic>;
      expect(attachPayload['imageName'], equals('banner'));
      expect(attachPayload['imageSource'],
          equals('https://cdn.example.com/banner.png'));
    });

    test('deserialize a full workflow with attachImage', () {
      final workflowJson = {
        'actions': [
          {
            'id': 'step-1',
            'type': 'attachImage',
            'key': 'step-1',
            'enabled': true,
            'payload': {
              'imageName': 'card',
              'imageSource': 'data:image/png;base64,AAAA',
              'altText': 'Generated card',
            },
          },
          {
            'id': 'step-2',
            'type': 'sendMessage',
            'key': 'step-2',
            'enabled': true,
            'payload': {'content': 'Look at this:'},
          },
        ],
      };

      final actions = (workflowJson['actions'] as List)
          .map((json) => ActionItem.fromJson(json as Map<String, dynamic>))
          .toList();

      expect(actions.length, equals(2));
      expect(actions[0].type, equals(BotCreatorActionType.attachImage));
      expect(actions[0].parameters['imageName'], equals('card'));
      expect(actions[0].parameters['imageSource'],
          equals('data:image/png;base64,AAAA'));
      expect(actions[0].parameters['altText'], equals('Generated card'));
      expect(actions[1].type, equals(BotCreatorActionType.sendMessage));
    });

    // ── respondWithMessage componentV2 mode: preserves button actions ──
    group('purgeActionPayloadStrict for respondWithMessage', () {
      test('keeps componentV2 when messageMode=componentV2', () {
        final componentV2Data = {
          'content': '',
          'components': [
            {
              'type': 'actionRow',
              'components': [
                {
                  'type': 'button',
                  'label': 'Click me',
                  'style': 'primary',
                  'customId': 'btn_123',
                  'url': '',
                  'emoji': '',
                  'disabled': false,
                  'actions': [
                    {
                      'type': 'respondWithMessage',
                      'payload': {'content': 'Button clicked!'},
                    },
                  ],
                },
              ],
            },
          ],
          'ephemeral': false,
        };

        final params = {
          'messageMode': 'componentV2',
          'componentV2': componentV2Data,
          'content': 'should be removed',
          'embeds': ['should be removed'],
          'ephemeral': true,
          'key': 'my_action',
        };

        final purged = purgeActionPayloadStrict(
          BotCreatorActionType.respondWithMessage,
          params,
        );

        expect(purged['messageMode'], equals('componentV2'));
        expect(purged['componentV2'], isNotNull);
        expect(purged['componentV2'], equals(componentV2Data));
        expect(purged.containsKey('content'), isFalse);
        expect(purged.containsKey('embeds'), isFalse);
        expect(purged['ephemeral'], equals(true));
        expect(purged['key'], equals('my_action'));
      });

      test('removes componentV2 when messageMode=message', () {
        final params = {
          'messageMode': 'message',
          'content': 'Hello',
          'embeds': [{'title': 'Test'}],
          'componentV2': {'components': []},
          'ephemeral': false,
        };

        final purged = purgeActionPayloadStrict(
          BotCreatorActionType.respondWithMessage,
          params,
        );

        expect(purged['messageMode'], equals('message'));
        expect(purged['content'], equals('Hello'));
        expect(purged.containsKey('componentV2'), isFalse);
      });

      test('defaults to message mode when messageMode is missing', () {
        final params = {
          'content': 'Hello',
          'componentV2': {'components': []},
        };

        final purged = purgeActionPayloadStrict(
          BotCreatorActionType.respondWithMessage,
          params,
        );

        expect(purged['content'], equals('Hello'));
        expect(purged.containsKey('componentV2'), isFalse);
      });
    });
  });
}

import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Messages implements BotMessageService {
  final sent = <BotMessageRequest>[];
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    budget.check();
    sent.add(request);
    return const BotMessageResult(messageId: '100');
  }
}

BdfdEngine _engine(_Messages service) =>
    BdfdEngine(store: MemoryBotDataStore(), botId: 'bot', messages: service);

void main() {
  test(
    'text length limits include all embeds before any main response send',
    () async {
      for (final entry in {
        'title': 256,
        'description': 4096,
        'author': 256,
        'footer': 2048,
      }.entries) {
        final messages = _Messages();
        await expectLater(
          _engine(
            messages,
          ).execute('\$${entry.key}[${'x' * (entry.value + 1)}]'),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(messages.sent, isEmpty);
      }
      final messages = _Messages();
      await expectLater(
        _engine(messages).execute(
          '\$description[${'x' * 4000};1]\$description[${'y' * 3000};2]',
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(messages.sent, isEmpty);
    },
  );
  test(
    'official embed indexes separate text author footer fields and colors',
    () async {
      final messages = _Messages();
      await _engine(messages).execute(
        r'$title[First;1]$description[Second;2]$author[Author;2]$footer[Footer;2]'
        r'$color[#673ab7;2]$addField[A;B;yes;2]$addField[C;D;no;2]',
      );
      expect(messages.sent.single.payload['embeds'], [
        {'title': 'First'},
        {
          'description': 'Second',
          'author': {'name': 'Author'},
          'footer': {'text': 'Footer'},
          'color': '#673ab7',
          'fields': [
            {'name': 'A', 'value': 'B', 'inline': true},
            {'name': 'C', 'value': 'D', 'inline': false},
          ],
        },
      ]);
    },
  );
  test(
    'separate icon and URL setters preserve sections in either order',
    () async {
      for (final settersFirst in [false, true]) {
        final messages = _Messages();
        const text = r'$author[Name;2]$footer[Footer;2]$title[Title;2]';
        const properties =
            r'$authorIcon[https://example.test/a.png;2]'
            r'$authorURL[https://example.test/profile;2]'
            r'$footerIcon[https://example.test/f.png;2]'
            r'$embeddedURL[https://example.test/title;2]';
        await _engine(
          messages,
        ).execute(settersFirst ? properties + text : text + properties);
        expect(messages.sent.single.payload['embeds'], [
          {
            'author': {
              'name': 'Name',
              'icon_url': 'https://example.test/a.png',
              'url': 'https://example.test/profile',
            },
            'footer': {
              'text': 'Footer',
              'icon_url': 'https://example.test/f.png',
            },
            'title': 'Title',
            'url': 'https://example.test/title',
          },
        ]);
      }
    },
  );
  test('empty text prevents isolated author footer and title properties', () async {
    final messages = _Messages();
    await _engine(messages).execute(
      r'$authorIcon[https://example.test/a.png]$authorURL[https://example.test/profile]'
      r'$footerIcon[https://example.test/f.png]$embeddedURL[https://example.test/title]',
    );
    expect(messages.sent, isEmpty);
  });
  test('explicit empty URLs remove icons without clearing text', () async {
    final messages = _Messages();
    await _engine(messages).execute(
      r'$author[Name]$footer[Footer]$title[Title]'
      r'$authorIcon[]$authorURL[]$footerIcon[]$embeddedURL[]',
    );
    expect(messages.sent.single.payload['embeds'], [
      {
        'author': {'name': 'Name', 'icon_url': '', 'url': ''},
        'footer': {'text': 'Footer', 'icon_url': ''},
        'title': 'Title',
        'url': '',
      },
    ]);
  });
  test(
    'addTimestamp reads current injected clock in UTC independently of time',
    () async {
      final messages = _Messages();
      var reads = 0;
      final context = BdfdContext(
        clock: () => DateTime.utc(2026, 10, 4, 12, 0, reads++),
      );
      await _engine(messages).execute(
        r'$time[Europe/Paris]$addTimestamp$addTimestamp[2]',
        context: context,
      );
      expect(messages.sent.single.payload['embeds'], [
        {'timestamp': '2026-10-04T12:00:00.000Z'},
        {'timestamp': '2026-10-04T12:00:01.000Z'},
      ]);
      expect(reads, 2);
    },
  );
  test('invalid indexes produce diagnostics and no response', () async {
    for (final index in ['0', '11', '-1', 'text', '1.5']) {
      final messages = _Messages();
      await expectLater(
        _engine(messages).execute('\$title[bad;$index]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(messages.sent, isEmpty);
    }
    final messages = _Messages();
    await _engine(messages).execute(r'$title[ten;10]');
    expect(messages.sent.single.payload['embeds'], [
      {'title': 'ten'},
    ]);
  });
  test(
    'legacy author and footer overloads fail preflight before sending',
    () async {
      for (final source in [
        r'$author[name;icon;url]',
        r'$footer[text;icon;2]',
        r'$addTimestamp[1;extra]',
      ]) {
        final messages = _Messages();
        await expectLater(
          _engine(messages).execute(r'$sendMessage[side effect]' + source),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(messages.sent, isEmpty);
      }
    },
  );
  test(
    'embed field limits are per embed and errors discard main draft',
    () async {
      final messages = _Messages();
      await _engine(
        messages,
      ).execute(r'$for[25]$addField[n;v]$endfor$addField[x;y;yes;2]');
      final embeds = messages.sent.single.payload['embeds'] as List;
      expect((embeds.first['fields'] as List).length, 25);
      expect((embeds.last['fields'] as List).length, 1);
      final bad = _Messages();
      await expectLater(
        _engine(bad).execute(r'$for[26]$addField[n;v]$endfor'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(bad.sent, isEmpty);
      for (final source in [
        r'$addField[;v]',
        r'$addField[n;]',
        r'$addField[n;v;invalid]',
      ]) {
        await expectLater(
          _engine(_Messages()).execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test(
    'independent sendMessage leaves timestamp and author draft intact',
    () async {
      final messages = _Messages();
      final context = BdfdContext(clock: () => DateTime.utc(2026));
      await _engine(messages).execute(
        r'$authorIcon[https://example.test/a.png]$author[Name]$addTimestamp$sendMessage[separate]main',
        context: context,
      );
      expect(messages.sent, hasLength(2));
      expect(messages.sent.first.payload['content'], 'separate');
      expect(messages.sent.first.payload.containsKey('embeds'), false);
      expect(messages.sent.last.payload['content'], 'main');
      expect(messages.sent.last.payload['embeds'], [
        {
          'author': {'name': 'Name', 'icon_url': 'https://example.test/a.png'},
          'timestamp': '2026-01-01T00:00:00.000Z',
        },
      ]);
    },
  );
  test('unknown wrapper leaves embed mutation opaque', () async {
    final messages = _Messages();
    const source = r'$unknown[$addTimestamp$authorIcon[$var[bad;1]]]';
    final context = BdfdContext();
    expect(await _engine(messages).execute(source, context: context), source);
    expect(context.temporaryVariables['bad'], isNull);
    expect(messages.sent.single.payload['embeds'], isEmpty);
  });
  test('native sandbox executes separate embed property functions', () async {
    final result = await testCommandInSandbox({
      'script':
          r'$authorIcon[https://example.test/a.png;2]$author[Name;2]$title[Title;2]$addTimestamp[2]',
      'bdfdBackend': 'native-v1',
    });
    expect(result['success'], true, reason: '$result');
    expect(result['entity_requests'], isEmpty);
  });
}

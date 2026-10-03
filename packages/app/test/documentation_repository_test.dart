import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:bot_creator/features/documentation/documentation_repository.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> documentationFixture({
  String id = 'getvar',
  String content = '# Value',
  bool guide = false,
}) => {
  'id': id,
  'name': guide ? 'Create a bot token' : '\$getVar',
  'description': 'Read a persistent value',
  'category': 'Variables',
  'api_type': guide ? 'general' : 'bdfd',
  'status': 'documented',
  'revision': sha256.convert(utf8.encode(content)).toString(),
  'locale': 'en',
  'url': guide ? botTokenTutorialUrl : 'https://bot-creator.fr/docs/$id/',
  'markdown_url':
      'https://bot-creator.fr/api/native/${guide ? 'guides' : 'docs'}/$id.md',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a mismatched build revision cannot be displayed or cached', () async {
    final repository = DocumentationRepository(
      client: MockClient((_) async => http.Response('# Old', 200)),
    );
    final entry = DocumentationEntry.fromJson(
      documentationFixture(content: '# New'),
    );
    await expectLater(repository.article(entry), throwsFormatException);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('native_documentation_cache_v1'), isNull);
  });

  test('cache is bounded and oversized responses are rejected', () async {
    final repository = DocumentationRepository(
      client: MockClient(
        (request) async => http.Response(
          request.url.path.contains('oversized')
              ? 'x' * (1024 * 1024 + 1)
              : '# Value',
          200,
        ),
      ),
    );
    for (var i = 0; i < 70; i++) {
      await repository.article(
        DocumentationEntry.fromJson(documentationFixture(id: 'item$i')),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final cache =
        jsonDecode(prefs.getString('native_documentation_cache_v1')!) as Map;
    expect(cache.length, lessThanOrEqualTo(64));
    await expectLater(
      repository.article(
        DocumentationEntry.fromJson(documentationFixture(id: 'oversized')),
      ),
      throwsFormatException,
    );
  });

  test(
    'index cache coalesces concurrent reads and survives offline restart',
    () async {
      var calls = 0;
      var now = DateTime(2026);
      final repository = DocumentationRepository(
        now: () => now,
        client: MockClient((request) async {
          calls++;
          return http.Response(jsonEncode([documentationFixture()]), 200);
        }),
      );
      await Future.wait([
        repository.index(DocumentationSection.botCreatorDocs),
        repository.index(DocumentationSection.botCreatorDocs),
      ]);
      await repository.index(DocumentationSection.botCreatorDocs);
      expect(calls, 1);
      now = now.add(const Duration(hours: 2));
      final offline = DocumentationRepository(
        now: () => now,
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      final result = await offline.index(DocumentationSection.botCreatorDocs);
      expect(result.offline, isTrue);
      expect(result.value.single.name, '\$getVar');
    },
  );

  test('article cache follows revision rather than just URL', () async {
    var calls = 0;
    final repository = DocumentationRepository(
      client: MockClient((_) async {
        calls++;
        return http.Response('# Version $calls', 200);
      }),
    );
    final entry = DocumentationEntry.fromJson(
      documentationFixture(content: '# Version 1'),
    );
    expect((await repository.article(entry)).value, '# Version 1');
    expect((await repository.article(entry)).value, '# Version 1');
    final changed = DocumentationEntry.fromJson(
      documentationFixture(content: '# Version 2'),
    );
    expect((await repository.article(changed)).value, '# Version 2');
    expect(calls, 2);
  });

  test('HTML errors and redirects cannot poison a cached article', () async {
    var status = 200;
    var body = '# Good';
    final repository = DocumentationRepository(
      client: MockClient((_) async => http.Response(body, status)),
    );
    final entry = DocumentationEntry.fromJson(
      documentationFixture(content: '# Good'),
    );
    await repository.article(entry);
    body = '<!doctype html><html>Not found</html>';
    expect((await repository.article(entry, refresh: true)).offline, isTrue);
    status = 302;
    expect((await repository.article(entry, refresh: true)).value, '# Good');
    expect((await repository.article(entry)).value, '# Good');
  });

  test(
    'malformed cache is discarded and untrusted article endpoints rejected',
    () async {
      SharedPreferences.setMockInitialValues({
        'native_documentation_cache_v1': '{"bad":3}',
      });
      final repository = DocumentationRepository(
        client: MockClient((_) async => http.Response('# Works', 200)),
      );
      final entry = DocumentationEntry.fromJson(
        documentationFixture(content: '# Works'),
      );
      expect((await repository.article(entry)).value, '# Works');
      for (final url in [
        'http://bot-creator.fr/api/native/a.md',
        'https://evil.example/api/native/a.md',
        'https://bot-creator.fr/private/a.md',
      ]) {
        expect(
          () => DocumentationEntry.fromJson({
            ...documentationFixture(),
            'markdown_url': url,
          }),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'direct article links resolve by decoded path and ignore fragments',
    () async {
      final repository = DocumentationRepository(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode([documentationFixture(guide: true)]),
            200,
          ),
        ),
      );
      final entry = await repository.resolve(
        Uri.parse(
          '${botTokenTutorialUrl.replaceFirst('%20', ' ')}.html#step-1',
        ),
      );
      expect(entry?.name, 'Create a bot token');
      expect(
        await repository.resolve(Uri.parse('https://example.com/docs/getvar')),
        isNull,
      );
    },
  );
}

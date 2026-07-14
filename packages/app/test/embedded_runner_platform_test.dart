import 'dart:io';

import 'package:bot_creator/core/runner/embedded_runner_downloader.dart';
import 'package:bot_creator/core/runner/embedded_runner_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('embeddedRunnerLatestReleaseDownloadUrl', () {
    test('builds GitHub latest release URL', () {
      expect(
        embeddedRunnerLatestReleaseDownloadUrl(
          'bot-creator-runner-js-linux-x64',
        ),
        'https://github.com/ketsuna-org/runner-js/releases/latest/download/bot-creator-runner-js-linux-x64',
      );
    });
  });

  group('isEmbeddedRunnerBinaryValid', () {
    test('rejects payloads smaller than 1 MiB', () {
      expect(isEmbeddedRunnerBinaryValid(List.filled(1024, 0)), isFalse);
    });

    test('accepts payloads at or above 1 MiB', () {
      expect(
        isEmbeddedRunnerBinaryValid(
          List.filled(embeddedRunnerMinBinaryBytes, 0),
        ),
        isTrue,
      );
    });
  });

  group('resolveEmbeddedRunnerPlatformAsset', () {
    test('returns an asset on supported desktop platforms', () {
      final asset = resolveEmbeddedRunnerPlatformAsset();
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        expect(asset, isNull);
        return;
      }

      expect(asset, isNotNull);
      expect(asset!.fileName, startsWith('bot-creator-runner-js-'));
      expect(asset.bundleAssetPath, endsWith(asset.fileName));
    });
  });

  group('packagedEmbeddedRunnerAssetCandidates', () {
    test('includes flutter_assets and macOS bundle layouts', () {
      const assetPath =
          'assets/embedded-runner-js/bot-creator-runner-js-linux-x64';
      final candidates = packagedEmbeddedRunnerAssetCandidates(assetPath);

      expect(
        candidates.any((path) => path.contains('data/flutter_assets/$assetPath')),
        isTrue,
      );
      expect(
        candidates.any(
          (path) => path.contains('App.framework/Resources/flutter_assets'),
        ),
        isTrue,
      );
      expect(
        candidates.any((path) => path.contains('Resources/flutter_assets')),
        isTrue,
      );
    });
  });

  group('isEmbeddedRunnerBinaryFileValid', () {
    test('rejects files smaller than 1 MiB', () async {
      final dir = await Directory.systemTemp.createTemp('embedded-runner-test');
      final file = File('${dir.path}/small.bin');
      await file.writeAsBytes(List.filled(1024, 0));

      expect(await isEmbeddedRunnerBinaryFileValid(file), isFalse);

      await dir.delete(recursive: true);
    });

    test('accepts files at or above 1 MiB', () async {
      final dir = await Directory.systemTemp.createTemp('embedded-runner-test');
      final file = File('${dir.path}/valid.bin');
      await file.writeAsBytes(List.filled(embeddedRunnerMinBinaryBytes, 9));

      expect(await isEmbeddedRunnerBinaryFileValid(file), isTrue);

      await dir.delete(recursive: true);
    });
  });

  group('resolvePackagedEmbeddedRunnerAsset', () {
    test('finds a valid binary placed on a candidate path', () async {
      const assetPath =
          'assets/embedded-runner-js/bot-creator-runner-js-linux-x64';
      final candidates = packagedEmbeddedRunnerAssetCandidates(assetPath);
      expect(candidates, isNotEmpty);

      final dir = await Directory.systemTemp.createTemp('embedded-runner-test');
      final source = File('${dir.path}/${assetPath.split('/').last}');
      await source.writeAsBytes(List.filled(embeddedRunnerMinBinaryBytes, 3));

      String? resolved;
      for (final candidate in candidates) {
        final file = File(candidate);
        await file.parent.create(recursive: true);
        if (await file.exists()) {
          await file.delete();
        }
        await source.copy(candidate);
        resolved = await resolvePackagedEmbeddedRunnerAsset(assetPath);
        if (resolved != null) {
          break;
        }
      }

      expect(resolved, isNotNull);
      expect(await isEmbeddedRunnerBinaryFileValid(File(resolved!)), isTrue);

      await dir.delete(recursive: true);
      if (resolved != null) {
        final resolvedFile = File(resolved);
        if (await resolvedFile.parent.exists()) {
          await resolvedFile.parent.delete(recursive: true);
        }
      }
    });
  });

  group('downloadEmbeddedRunnerLatestRelease', () {
    test('returns bytes when response is valid', () async {
      final payload = List<int>.filled(embeddedRunnerMinBinaryBytes, 7);
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          embeddedRunnerLatestReleaseDownloadUrl(
            'bot-creator-runner-js-win.exe',
          ),
        );
        return http.Response.bytes(payload, 200);
      });

      final bytes = await downloadEmbeddedRunnerLatestRelease(
        'bot-creator-runner-js-win.exe',
        client: client,
      );

      expect(bytes, payload);
    });

    test('returns null for non-200 responses', () async {
      final client = MockClient((request) async {
        return http.Response('missing', 404);
      });

      final bytes = await downloadEmbeddedRunnerLatestRelease(
        'bot-creator-runner-js-linux-x64',
        client: client,
      );

      expect(bytes, isNull);
    });

    test('returns null when payload is too small', () async {
      final client = MockClient((request) async {
        return http.Response.bytes([1, 2, 3], 200);
      });

      final bytes = await downloadEmbeddedRunnerLatestRelease(
        'bot-creator-runner-js-linux-x64',
        client: client,
      );

      expect(bytes, isNull);
    });
  });
}

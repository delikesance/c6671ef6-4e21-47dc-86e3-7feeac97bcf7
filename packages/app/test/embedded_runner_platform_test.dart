import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/runner/embedded_runner_downloader.dart';
import 'package:bot_creator/core/runner/embedded_runner_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

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

  group('embeddedRunnerReleaseDownloadUrl', () {
    test('builds versioned GitHub release URL', () {
      expect(
        embeddedRunnerReleaseDownloadUrl(
          'runner-js-v0.5.0',
          'bot-creator-runner-js-linux-x64',
        ),
        'https://github.com/ketsuna-org/runner-js/releases/download/runner-js-v0.5.0/bot-creator-runner-js-linux-x64',
      );
    });
  });

  group('embeddedRunnerLatestReleaseApiUrl', () {
    test('points at runner-js latest release API', () {
      expect(
        embeddedRunnerLatestReleaseApiUrl(),
        'https://api.github.com/repos/ketsuna-org/runner-js/releases/latest',
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

  group('monorepoRunnerJsBuildCandidates', () {
    test('includes sibling runner-js build paths from cwd', () {
      final cwd = Directory.current.path;
      final candidates = monorepoRunnerJsBuildCandidates(
        'bot-creator-runner-js-linux-x64',
      );

      expect(
        candidates,
        contains(
          p.normalize(p.join(cwd, 'runner-js', 'build', 'bot-creator-runner-js-linux-x64')),
        ),
      );
      expect(
        candidates,
        contains(
          p.normalize(
            p.join(cwd, '..', 'runner-js', 'build', 'bot-creator-runner-js-linux-x64'),
          ),
        ),
      );
    });
  });

  group('embeddedRunnerEnvOverridePath', () {
    test('returns trimmed path when env var is set', () {
      expect(
        embeddedRunnerEnvOverridePath(
          environment: {embeddedRunnerEnvOverrideVar: '  /tmp/custom-runner  '},
        ),
        '/tmp/custom-runner',
      );
    });

    test('returns null when env var is unset', () {
      expect(embeddedRunnerEnvOverridePath(environment: {}), isNull);
    });

    test('returns null when env var is empty', () {
      expect(
        embeddedRunnerEnvOverridePath(
          environment: {embeddedRunnerEnvOverrideVar: '   '},
        ),
        isNull,
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

      final result = await downloadEmbeddedRunnerLatestRelease(
        'bot-creator-runner-js-win.exe',
        client: client,
      );

      expect(result.ok, isTrue);
      expect(result.bytes, payload);
      expect(result.failureReason, isNull);
    });

    test('returns failure reason for non-200 responses', () async {
      final client = MockClient((request) async {
        return http.Response('missing', 404);
      });

      final result = await downloadEmbeddedRunnerLatestRelease(
        'bot-creator-runner-js-linux-x64',
        client: client,
      );

      expect(result.ok, isFalse);
      expect(result.bytes, isNull);
      expect(result.failureReason, contains('HTTP 404'));
    });

    test('returns failure reason when payload is too small', () async {
      final client = MockClient((request) async {
        return http.Response.bytes([1, 2, 3], 200);
      });

      final result = await downloadEmbeddedRunnerLatestRelease(
        'bot-creator-runner-js-linux-x64',
        client: client,
      );

      expect(result.ok, isFalse);
      expect(result.failureReason, contains('payload too small'));
    });

    test('falls back to tagged release URL when latest download fails', () async {
      final payload = List<int>.filled(embeddedRunnerMinBinaryBytes, 4);
      final requests = <Uri>[];

      final client = MockClient((request) async {
        requests.add(request.url);
        if (request.url.toString() ==
            embeddedRunnerLatestReleaseDownloadUrl(
              'bot-creator-runner-js-linux-x64',
            )) {
          return http.Response('missing', 404);
        }
        if (request.url.toString() == embeddedRunnerLatestReleaseApiUrl()) {
          return http.Response(
            jsonEncode({'tag_name': 'runner-js-v0.5.0'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.toString() ==
            embeddedRunnerReleaseDownloadUrl(
              'runner-js-v0.5.0',
              'bot-creator-runner-js-linux-x64',
            )) {
          return http.Response.bytes(payload, 200);
        }
        return http.Response('unexpected', 500);
      });

      final result = await downloadEmbeddedRunnerLatestRelease(
        'bot-creator-runner-js-linux-x64',
        client: client,
      );

      expect(result.ok, isTrue);
      expect(result.bytes, payload);
      expect(
        requests.map((url) => url.toString()),
        contains(
          embeddedRunnerReleaseDownloadUrl(
            'runner-js-v0.5.0',
            'bot-creator-runner-js-linux-x64',
          ),
        ),
      );
    });

    test('reports download progress while streaming', () async {
      final payload = List<int>.filled(embeddedRunnerMinBinaryBytes, 8);
      final client = MockClient((request) async {
        return http.Response.bytes(payload, 200);
      });

      final progressUpdates = <EmbeddedRunnerDownloadProgress>[];
      final result = await downloadEmbeddedRunnerLatestRelease(
        'bot-creator-runner-js-linux-x64',
        client: client,
        onProgress: progressUpdates.add,
      );

      expect(result.ok, isTrue);
      expect(result.bytes, payload);
      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.last.receivedBytes, payload.length);
      expect(progressUpdates.last.totalBytes, payload.length);
      expect(progressUpdates.last.fraction, 1.0);
    });
  });
}

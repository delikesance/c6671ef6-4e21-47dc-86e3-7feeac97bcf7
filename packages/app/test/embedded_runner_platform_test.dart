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

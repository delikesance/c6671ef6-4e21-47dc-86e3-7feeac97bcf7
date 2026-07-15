import 'dart:async';
import 'dart:convert';

import 'package:bot_creator/core/runner/embedded_runner_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const _downloadUserAgent = 'bot-creator-embedded-runner/1.0';

/// Progress of an in-flight embedded runner binary download.
class EmbeddedRunnerDownloadProgress {
  const EmbeddedRunnerDownloadProgress({
    required this.receivedBytes,
    this.totalBytes,
  });

  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    return (receivedBytes / total).clamp(0.0, 1.0);
  }
}

typedef EmbeddedRunnerDownloadProgressCallback = void Function(
  EmbeddedRunnerDownloadProgress progress,
);

/// Result of attempting to download an embedded runner release asset.
class EmbeddedRunnerDownloadResult {
  const EmbeddedRunnerDownloadResult({
    this.bytes,
    this.failureReason,
  });

  final List<int>? bytes;
  final String? failureReason;

  bool get ok => bytes != null;
}

Map<String, String> embeddedRunnerDownloadHeaders() {
  return const {
    'User-Agent': _downloadUserAgent,
    'Accept': 'application/octet-stream',
  };
}

/// Downloads the latest runner-js release asset from GitHub.
Future<EmbeddedRunnerDownloadResult> downloadEmbeddedRunnerLatestRelease(
  String fileName, {
  http.Client? client,
  Duration timeout = const Duration(minutes: 5),
  EmbeddedRunnerDownloadProgressCallback? onProgress,
}) async {
  final ownsClient = client == null;
  final httpClient = client ?? http.Client();

  try {
    final latestUrl = embeddedRunnerLatestReleaseDownloadUrl(fileName);
    final latestResult = await _downloadFromUrl(
      httpClient,
      latestUrl,
      fileName,
      timeout,
      onProgress: onProgress,
    );
    if (latestResult.ok) {
      return latestResult;
    }

    final tag = await _resolveLatestReleaseTag(httpClient, timeout);
    if (tag == null) {
      return EmbeddedRunnerDownloadResult(
        failureReason:
            latestResult.failureReason ??
            'Could not resolve latest runner-js release tag from GitHub.',
      );
    }

    final taggedUrl = embeddedRunnerReleaseDownloadUrl(tag, fileName);
    if (taggedUrl == latestUrl) {
      return latestResult;
    }

    debugPrint(
      '[EmbeddedJsRunner] Retrying download with resolved tag $tag',
    );
    final taggedResult = await _downloadFromUrl(
      httpClient,
      taggedUrl,
      fileName,
      timeout,
      onProgress: onProgress,
    );
    if (taggedResult.ok) {
      return taggedResult;
    }

    return EmbeddedRunnerDownloadResult(
      failureReason:
          taggedResult.failureReason ??
          latestResult.failureReason ??
          'Failed to download runner-js release for $fileName.',
    );
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }
}

Future<EmbeddedRunnerDownloadResult> _downloadFromUrl(
  http.Client httpClient,
  String url,
  String fileName,
  Duration timeout, {
  EmbeddedRunnerDownloadProgressCallback? onProgress,
}) async {
  try {
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(embeddedRunnerDownloadHeaders());

    final streamedResponse = await httpClient.send(request).timeout(timeout);
    if (streamedResponse.statusCode != 200) {
      final reason =
          'Download failed for $fileName: HTTP ${streamedResponse.statusCode} from $url';
      debugPrint('[EmbeddedJsRunner] $reason');
      return EmbeddedRunnerDownloadResult(failureReason: reason);
    }

    final contentLength = streamedResponse.contentLength;
    final totalBytes =
        contentLength != null && contentLength > 0 ? contentLength : null;
    final bytes = <int>[];

    onProgress?.call(
      EmbeddedRunnerDownloadProgress(
        receivedBytes: 0,
        totalBytes: totalBytes,
      ),
    );

    await for (final chunk in streamedResponse.stream.timeout(timeout)) {
      bytes.addAll(chunk);
      onProgress?.call(
        EmbeddedRunnerDownloadProgress(
          receivedBytes: bytes.length,
          totalBytes: totalBytes,
        ),
      );
    }

    if (!isEmbeddedRunnerBinaryValid(bytes)) {
      final reason =
          'Download failed for $fileName: payload too small (${bytes.length} bytes) from $url';
      debugPrint('[EmbeddedJsRunner] $reason');
      return EmbeddedRunnerDownloadResult(failureReason: reason);
    }

    return EmbeddedRunnerDownloadResult(bytes: bytes);
  } on TimeoutException {
    final reason =
        'Download timed out after ${timeout.inSeconds}s for $fileName from $url';
    debugPrint('[EmbeddedJsRunner] $reason');
    return EmbeddedRunnerDownloadResult(failureReason: reason);
  } catch (error) {
    final reason = 'Download error for $fileName from $url: $error';
    debugPrint('[EmbeddedJsRunner] $reason');
    return EmbeddedRunnerDownloadResult(failureReason: reason);
  }
}

Future<String?> _resolveLatestReleaseTag(
  http.Client httpClient,
  Duration timeout,
) async {
  try {
    final response = await httpClient
        .get(
          Uri.parse(embeddedRunnerLatestReleaseApiUrl()),
          headers: const {
            'User-Agent': _downloadUserAgent,
            'Accept': 'application/vnd.github+json',
          },
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      debugPrint(
        '[EmbeddedJsRunner] Failed to resolve release tag: HTTP ${response.statusCode}',
      );
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final tag = decoded['tag_name'];
    if (tag is! String || tag.trim().isEmpty) {
      return null;
    }
    return tag.trim();
  } catch (error) {
    debugPrint('[EmbeddedJsRunner] Failed to resolve release tag: $error');
    return null;
  }
}

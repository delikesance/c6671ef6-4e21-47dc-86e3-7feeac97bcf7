import 'dart:async';

import 'package:bot_creator/core/runner/embedded_runner_platform.dart';
import 'package:http/http.dart' as http;

/// Downloads the latest runner-js release asset from GitHub.
Future<List<int>?> downloadEmbeddedRunnerLatestRelease(
  String fileName, {
  http.Client? client,
  Duration timeout = const Duration(seconds: 120),
}) async {
  final url = embeddedRunnerLatestReleaseDownloadUrl(fileName);
  final ownsClient = client == null;
  final httpClient = client ?? http.Client();

  try {
    final response = await httpClient
        .get(Uri.parse(url))
        .timeout(timeout);
    if (response.statusCode != 200) {
      return null;
    }
    final bytes = response.bodyBytes;
    if (!isEmbeddedRunnerBinaryValid(bytes)) {
      return null;
    }
    return bytes;
  } on TimeoutException {
    return null;
  } catch (_) {
    return null;
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }
}

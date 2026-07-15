import 'dart:io';

import 'package:path/path.dart' as p;

/// Minimum size for a valid embedded runner binary (1 MiB).
const int embeddedRunnerMinBinaryBytes = 1048576;

const _githubRepo = 'ketsuna-org/runner-js';

/// Returns true when [bytes] is at least [embeddedRunnerMinBinaryBytes].
bool isEmbeddedRunnerBinaryValid(List<int> bytes) {
  return bytes.length >= embeddedRunnerMinBinaryBytes;
}

/// GitHub latest-release download URL for a runner-js desktop asset.
String embeddedRunnerLatestReleaseDownloadUrl(String fileName) {
  return 'https://github.com/$_githubRepo/releases/latest/download/$fileName';
}

/// GitHub release download URL for a specific release tag.
String embeddedRunnerReleaseDownloadUrl(String tag, String fileName) {
  return 'https://github.com/$_githubRepo/releases/download/$tag/$fileName';
}

/// GitHub API endpoint for the latest runner-js release metadata.
String embeddedRunnerLatestReleaseApiUrl() {
  return 'https://api.github.com/repos/$_githubRepo/releases/latest';
}

/// Environment variable override for the embedded runner binary path.
const String embeddedRunnerEnvOverrideVar = 'BOT_CREATOR_EMBEDDED_RUNNER_JS_PATH';

/// Returns [embeddedRunnerEnvOverrideVar] when set, otherwise null.
String? embeddedRunnerEnvOverridePath({
  Map<String, String>? environment,
}) {
  final env = environment ?? Platform.environment;
  final value = env[embeddedRunnerEnvOverrideVar]?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

/// Candidate paths to a locally built runner-js PKG binary in a monorepo checkout.
List<String> monorepoRunnerJsBuildCandidates(String fileName) {
  final candidates = <String>{};
  try {
    var dir = Directory.current;
    for (var depth = 0; depth < 8; depth++) {
      candidates.add(
        p.normalize(p.join(dir.path, 'runner-js', 'build', fileName)),
      );
      candidates.add(
        p.normalize(p.join(dir.path, '..', 'runner-js', 'build', fileName)),
      );
      final parent = dir.parent;
      if (parent.path == dir.path) {
        break;
      }
      dir = parent;
    }
  } catch (_) {}

  return candidates.toList(growable: false);
}

/// Platform-specific bundled runner asset metadata.
class EmbeddedRunnerPlatformAsset {
  const EmbeddedRunnerPlatformAsset({
    required this.fileName,
    required this.bundleAssetPath,
  });

  final String fileName;
  final String bundleAssetPath;
}

/// Resolves the bundled runner asset for the current desktop platform.
EmbeddedRunnerPlatformAsset? resolveEmbeddedRunnerPlatformAsset() {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return null;
  }

  final bundleAssetPath = embeddedRunnerAssetPath();
  return EmbeddedRunnerPlatformAsset(
    fileName: p.basename(bundleAssetPath),
    bundleAssetPath: bundleAssetPath,
  );
}

/// Bundled asset path for the embedded runner binary on this platform.
String embeddedRunnerAssetPath() {
  if (Platform.isWindows) {
    return 'assets/embedded-runner-js/bot-creator-runner-js-win.exe';
  }
  if (Platform.isMacOS) {
    return 'assets/embedded-runner-js/bot-creator-runner-js-macos-arm64';
  }
  if (Platform.isLinux) {
    return 'assets/embedded-runner-js/bot-creator-runner-js-linux-x64';
  }
  throw UnsupportedError('Embedded runner is only supported on desktop.');
}

/// File name of the embedded runner binary on this platform.
String embeddedRunnerBinaryFileName() {
  return p.basename(embeddedRunnerAssetPath());
}

/// Returns true when [file] exists and is at least [embeddedRunnerMinBinaryBytes].
Future<bool> isEmbeddedRunnerBinaryFileValid(File file) async {
  if (!await file.exists()) {
    return false;
  }
  try {
    return await file.length() >= embeddedRunnerMinBinaryBytes;
  } catch (_) {
    return false;
  }
}

/// Candidate filesystem paths where the packaged runner binary may live.
///
/// Release layouts:
/// - Linux/Windows: `{exeDir}/data/flutter_assets/assets/embedded-runner-js/...`
/// - macOS .app: `{exeDir}/../Resources/flutter_assets/...` or
///   `{exeDir}/../Frameworks/App.framework/Resources/flutter_assets/...`
List<String> packagedEmbeddedRunnerAssetCandidates(String assetPath) {
  final candidates = <String>{};
  try {
    final executable = Platform.resolvedExecutable;
    final exeFile = File(executable);
    final exeDir = exeFile.parent.path;

    // Linux / Windows release bundle
    candidates.add(p.join(exeDir, 'data', 'flutter_assets', assetPath));

    // macOS .app bundle layouts
    candidates.add(
      p.normalize(
        p.join(exeDir, '..', 'Resources', 'flutter_assets', assetPath),
      ),
    );
    candidates.add(
      p.normalize(
        p.join(
          exeDir,
          '..',
          'Frameworks',
          'App.framework',
          'Resources',
          'flutter_assets',
          assetPath,
        ),
      ),
    );

    // Walk up from executable dir for dev / nested build outputs
    var dir = Directory(exeDir);
    for (var i = 0; i < 8; i++) {
      candidates.add(p.join(dir.path, 'data', 'flutter_assets', assetPath));
      candidates.add(p.join(dir.path, assetPath));
      final parent = dir.parent;
      if (parent.path == dir.path) {
        break;
      }
      dir = parent;
    }
  } catch (_) {}

  return candidates.toList(growable: false);
}

/// Resolves the first valid packaged runner binary on disk, if any.
Future<String?> resolvePackagedEmbeddedRunnerAsset(String assetPath) async {
  for (final candidate in packagedEmbeddedRunnerAssetCandidates(assetPath)) {
    final file = File(candidate);
    if (await isEmbeddedRunnerBinaryFileValid(file)) {
      return file.path;
    }
  }
  return null;
}

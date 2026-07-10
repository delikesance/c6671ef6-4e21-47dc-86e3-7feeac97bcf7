import 'dart:ffi' show Abi;
import 'dart:io';

/// Asset file name for the embedded runner-js binary on the current platform.
class EmbeddedRunnerPlatformAsset {
  const EmbeddedRunnerPlatformAsset({
    required this.fileName,
  });

  final String fileName;

  String get bundleAssetPath => 'assets/embedded-runner-js/$fileName';
}

/// Resolves the embedded runner binary asset for the current desktop platform.
EmbeddedRunnerPlatformAsset? resolveEmbeddedRunnerPlatformAsset() {
  if (Platform.isWindows) {
    return const EmbeddedRunnerPlatformAsset(
      fileName: 'bot-creator-runner-js-win.exe',
    );
  }

  if (Platform.isLinux) {
    final isArm64 = Abi.current() == Abi.linuxArm64;
    return EmbeddedRunnerPlatformAsset(
      fileName: isArm64
          ? 'bot-creator-runner-js-linux-arm64'
          : 'bot-creator-runner-js-linux-x64',
    );
  }

  if (Platform.isMacOS) {
    final isArm64 = Abi.current() == Abi.macosArm64;
    return EmbeddedRunnerPlatformAsset(
      fileName: isArm64
          ? 'bot-creator-runner-js-macos-arm64'
          : 'bot-creator-runner-js-macos-x64',
    );
  }

  return null;
}

/// GitHub latest-release download URL for a runner-js release asset.
String embeddedRunnerLatestReleaseDownloadUrl(String fileName) {
  return 'https://github.com/ketsuna-org/runner-js/releases/latest/download/$fileName';
}

/// Minimum valid embedded runner binary size (matches [EmbeddedJsRunnerService]).
const embeddedRunnerMinBinaryBytes = 1024 * 1024;

bool isEmbeddedRunnerBinaryValid(List<int> bytes) {
  return bytes.length >= embeddedRunnerMinBinaryBytes;
}

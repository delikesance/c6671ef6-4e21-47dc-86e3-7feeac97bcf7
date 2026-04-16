import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const String _fallbackAppFolderName = 'bot_creator';

Future<Directory> getAppStorageDirectory() async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    if (docs.path.trim().isNotEmpty) {
      if (!await docs.exists()) {
        await docs.create(recursive: true);
      }
      return docs;
    }
  } on MissingPlatformDirectoryException {
    // Fallback below when documents directory is unavailable (e.g. Steam).
  } on PlatformException catch (error) {
    if (!_isMissingDocumentsDirectoryPlatformException(error)) {
      rethrow;
    }
  }

  try {
    final support = await getApplicationSupportDirectory();
    if (!await support.exists()) {
      await support.create(recursive: true);
    }
    return support;
  } catch (_) {
    final fallback = await _resolveEnvironmentFallbackDirectory();
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }
}

Future<String> getAppStoragePath() async {
  final directory = await getAppStorageDirectory();
  return directory.path;
}

bool _isMissingDocumentsDirectoryPlatformException(PlatformException error) {
  final message = (error.message ?? '').toLowerCase();
  return message.contains('application documents') ||
      message.contains('missingplatformdirectoryexception') ||
      message.contains('unable to get');
}

Future<Directory> _resolveEnvironmentFallbackDirectory() async {
  final xdgDataHome = Platform.environment['XDG_DATA_HOME']?.trim() ?? '';
  if (xdgDataHome.isNotEmpty) {
    return Directory(path.join(xdgDataHome, _fallbackAppFolderName));
  }

  final home = Platform.environment['HOME']?.trim() ?? '';
  if (home.isNotEmpty) {
    return Directory(path.join(home, '.local', 'share', _fallbackAppFolderName));
  }

  return Directory(path.join(Directory.systemTemp.path, _fallbackAppFolderName));
}

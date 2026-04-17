import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(Uri uri) async {
  if (!kIsWeb && Platform.isLinux) {
    final env = Map<String, String>.from(Platform.environment)
      ..remove('LD_LIBRARY_PATH');

    final xdg = await Process.run('/usr/bin/xdg-open', [
      uri.toString(),
    ], environment: env);
    if (xdg.exitCode == 0) {
      return true;
    }

    final gio = await Process.run('/usr/bin/gio', [
      'open',
      uri.toString(),
    ], environment: env);
    if (gio.exitCode == 0) {
      return true;
    }

    return false;
  }

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

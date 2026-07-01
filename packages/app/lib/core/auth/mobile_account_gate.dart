import 'dart:io';

import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:flutter/foundation.dart';

/// Mobile requires an explicit Discord OAuth session — bot-token JWT exchange
/// alone is not enough to use the app (recovery + hosted apps).
class MobileAccountGate {
  MobileAccountGate._();

  static bool get isRequired {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool isDiscordOAuthSession(MainApiSession? session) {
    if (session == null || session.isExpired) {
      return false;
    }
    return session.authMethod == MainApiAuthMethod.discordOauth;
  }

  static Future<bool> hasRequiredAccount() async {
    if (!isRequired) {
      return true;
    }
    final session = await MainApiSettingsStore.loadSession();
    return isDiscordOAuthSession(session);
  }
}

import 'dart:io';

import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:flutter/foundation.dart';

/// Mobile requires a managed Bot Creator account (Discord OAuth or email/password).
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

  static bool isEmailPasswordSession(MainApiSession? session) {
    if (session == null || session.isExpired) {
      return false;
    }
    return session.authMethod == MainApiAuthMethod.emailPassword;
  }

  static bool isManagedAccountSession(MainApiSession? session) {
    if (session == null || session.isExpired) {
      return false;
    }
    return session.isManagedAccount;
  }

  static bool isRefreshableDiscordOAuthSession(MainApiSession? session) {
    if (session == null) {
      return false;
    }
    if (session.authMethod != MainApiAuthMethod.discordOauth) {
      return false;
    }
    if (!session.isExpired) {
      return true;
    }
    return session.refreshToken?.trim().isNotEmpty ?? false;
  }

  static bool isRefreshableManagedAccountSession(MainApiSession? session) {
    if (session == null || !session.isManagedAccount) {
      return false;
    }
    if (!session.isExpired) {
      return true;
    }
    return session.refreshToken?.trim().isNotEmpty ?? false;
  }

  static Future<bool> hasRequiredAccount() async {
    if (!isRequired) {
      return true;
    }

    var session = await MainApiSettingsStore.loadSession();
    if (!isRefreshableManagedAccountSession(session)) {
      return false;
    }

    if (session!.isExpired || session.expiresSoon()) {
      session = await restoreMainApiSessionIfNeeded();
    }

    return isManagedAccountSession(session);
  }
}

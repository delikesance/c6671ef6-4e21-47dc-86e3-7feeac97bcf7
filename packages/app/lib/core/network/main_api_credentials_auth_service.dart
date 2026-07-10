import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';

class MainApiCredentialsAuthException implements Exception {
  const MainApiCredentialsAuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class MainApiCredentialsAuthService {
  const MainApiCredentialsAuthService._();

  static Future<MainApiSession> login({
    required MainApiClient client,
    required String email,
    required String password,
  }) async {
    try {
      final session = await client.loginWithEmailPassword(
        email: email,
        password: password,
      );
      await MainApiSettingsStore.saveSession(
        session.copyWith(authMethod: MainApiAuthMethod.emailPassword),
      );
      return session;
    } on MainApiClientException catch (error) {
      throw MainApiCredentialsAuthException(
        error.message,
        code: _codeFromMessage(error.message),
      );
    }
  }

  static Future<Map<String, dynamic>> setCredentials({
    required MainApiClient client,
    required String email,
    required String password,
    String? currentPassword,
  }) async {
    try {
      return await client.setCredentials(
        email: email,
        password: password,
        currentPassword: currentPassword,
      );
    } on MainApiClientException catch (error) {
      throw MainApiCredentialsAuthException(
        error.message,
        code: _codeFromMessage(error.message),
      );
    }
  }

  static String? _codeFromMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid_credentials')) {
      return 'invalid_credentials';
    }
    if (lower.contains('email_already_registered')) {
      return 'email_already_registered';
    }
    if (lower.contains('password_too_weak')) {
      return 'password_too_weak';
    }
    return null;
  }
}

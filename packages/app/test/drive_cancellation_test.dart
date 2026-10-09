import 'package:bot_creator/core/storage/drive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driveSignInGateTests();
  group('isDriveAuthCancellation', () {
    test('returns true for explicit cancellation exception', () {
      expect(
        isDriveAuthCancellation(const UserCancelledGoogleSignInException()),
        isTrue,
      );
    });

    test('returns true for legacy wrapped cancellation message', () {
      expect(
        isDriveAuthCancellation(
          Exception(
            'Authentication cancelled or failed: '
            'GoogleSignInException(code GoogleSignInExceptionCode.canceled, '
            '[16] Cancelled by user., null)',
          ),
        ),
        isTrue,
      );
    });

    test('returns false for non-cancellation errors', () {
      expect(
        isDriveAuthCancellation(Exception('Authentication failed: timeout')),
        isFalse,
      );
    });
  });
}

void driveSignInGateTests() {
  group('shouldAttemptGoogleSignIn', () {
    test('never signs in silently when Drive backup is disabled', () {
      expect(
        shouldAttemptGoogleSignIn(driveEnabled: false, interactive: false),
        isFalse,
      );
    });
    test('allows explicit interactive action even if not yet enabled', () {
      expect(
        shouldAttemptGoogleSignIn(driveEnabled: false, interactive: true),
        isTrue,
      );
    });
    test('allows silent re-auth when Drive backup is enabled', () {
      expect(
        shouldAttemptGoogleSignIn(driveEnabled: true, interactive: false),
        isTrue,
      );
    });
  });
}

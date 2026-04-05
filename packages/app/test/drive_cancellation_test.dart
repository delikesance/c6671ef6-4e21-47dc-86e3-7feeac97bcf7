import 'package:bot_creator/utils/drive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

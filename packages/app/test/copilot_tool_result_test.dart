import 'package:bot_creator/features/copilot/logic/copilot_tool_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart';

class _DiscordFailure extends Fake implements HttpResponseError {
  @override
  int get statusCode => 400;
  @override
  int get errorCode => 50035;
  @override
  String get message => 'Authorization: PRIVATE; script=SECRET_SOURCE';
  @override
  String toString({bool short = false}) => message;
}

void main() {
  test(
    'Discord failures preserve status codes without exposing response text',
    () {
      final result = copilotToolFailure(_DiscordFailure());
      expect(result['code'], 'discord_request_failed');
      expect(result['http_status'], 400);
      expect(result['discord_code'], 50035);
      expect(result.toString(), isNot(contains('PRIVATE')));
      expect(result.toString(), isNot(contains('SECRET_SOURCE')));
    },
  );
  test(
    'duplicate command failures instruct an update instead of another create',
    () {
      final result = copilotToolFailure(
        StateError('Command already exists; edit it instead'),
      );
      expect(result['code'], 'command_exists');
      expect(result['message'], contains('latest ID and revision'));
      expect(result['approved'], isTrue);
      expect(result['success_confirmed'], isFalse);
      expect(result['isError'], isTrue);
    },
  );

  test('stale command IDs and runtime mismatch remain distinguishable', () {
    expect(
      copilotToolFailure(StateError('Command not found'))['code'],
      'command_not_found',
    );
    expect(
      copilotToolFailure(
        StateError('Execution mode does not match the bot runtime'),
      )['code'],
      'runtime_mismatch',
    );
    expect(
      copilotToolFailure(
        StateError('Workflow execution mode does not match bot runtime'),
      )['code'],
      'runtime_mismatch',
    );
    expect(
      copilotToolFailure(
        StateError(
          'Configuration changed; read its latest revision before editing',
        ),
      )['code'],
      'command_revision_conflict',
    );
  });

  test('unexpected failures do not leak arbitrary exception contents', () {
    const private = 'Authorization: Bearer PRIVATE; script=SECRET_SOURCE';
    for (final error in [
      Exception(private),
      StateError(private),
      const FormatException(private),
    ]) {
      final result = copilotToolFailure(error);
      expect(result.toString(), isNot(contains('PRIVATE')));
      expect(result.toString(), isNot(contains('SECRET_SOURCE')));
      expect(result['approved'], isTrue);
      expect(result['success_confirmed'], isFalse);
    }
  });
}

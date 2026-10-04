import 'dart:async';

import '../engine/execution_budget.dart';
import 'bot_message_query_service.dart';

/// An evaluated mutation scheduled against the actual sent response.
class BotTimedMessageMutation {
  BotTimedMessageMutation({
    required this.delay,
    this.edit,
    this.delete = false,
  }) {
    if (delay <= Duration.zero || (delete == (edit != null))) {
      throw ArgumentError(
        'A timed mutation needs a delay and exactly one operation.',
      );
    }
    edit?.validate();
  }
  final Duration delay;
  final MessageEdit? edit;
  final bool delete;

  MessageMutation target(String channelId, String messageId) => MessageMutation(
    kind: delete ? MessageMutationKind.delete : MessageMutationKind.edit,
    channelId: channelId,
    messageId: messageId,
    edit: edit,
  );
}

abstract interface class BotTimingService {
  /// Acceptance detaches work from the draft. The same execution deadline
  /// remains effective when a scheduled mutation eventually runs.
  Future<void> schedule(
    BotTimedMessageMutation request, {
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  });
}

class BotTimingFailure {
  const BotTimingFailure(this.mutation, this.error, this.stackTrace);
  final MessageMutation mutation;
  final Object error;
  final StackTrace stackTrace;
}

/// Timers do not retain live script expressions. Failures are captured and may
/// be reported through onFailure; timers never trigger uncaught async errors.
class RuntimeBotTimingService implements BotTimingService {
  RuntimeBotTimingService(this.messages, {this.onFailure});
  final BotMessageQueryService messages;
  final void Function(BotTimingFailure)? onFailure;
  final failures = <BotTimingFailure>[];
  final _jobs = <Future<void>>{};

  Future<void> drain() async {
    while (_jobs.isNotEmpty) {
      await Future.wait(_jobs.toList());
    }
  }

  @override
  Future<void> schedule(
    BotTimedMessageMutation request, {
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    messageQuerySnowflake(channelId);
    messageQuerySnowflake(messageId);
    final mutation = request.target(channelId, messageId);
    final completed = Completer<void>();
    _jobs.add(completed.future);
    Timer(request.delay, () async {
      try {
        budget.check();
        await budget.run(
          () => messages.mutateMessage(mutation, budget: budget),
        );
        budget.check();
      } catch (error, stackTrace) {
        final failure = BotTimingFailure(mutation, error, stackTrace);
        failures.add(failure);
        try {
          onFailure?.call(failure);
        } catch (_) {
          // Failure reporting cannot turn a handled job into an async crash.
        }
      } finally {
        _jobs.remove(completed.future);
        completed.complete();
      }
    });
  }
}

/// Sandbox scheduler records immutable requests and can apply them on demand
/// without real timers or network calls. The shared budget is checked on apply.
class SandboxBotTimingService implements BotTimingService {
  SandboxBotTimingService(this.messages);
  final BotMessageQueryService messages;
  final pending =
      <
        ({
          BotTimedMessageMutation request,
          String channelId,
          String messageId,
          CommandExecutionBudget budget,
        })
      >[];
  @override
  Future<void> schedule(
    BotTimedMessageMutation request, {
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    messageQuerySnowflake(channelId);
    messageQuerySnowflake(messageId);
    pending.add((
      request: request,
      channelId: channelId,
      messageId: messageId,
      budget: budget,
    ));
  }

  Future<void> drain() async {
    final jobs = pending.toList();
    pending.clear();
    for (final job in jobs) {
      job.budget.check();
      await job.budget.run(
        () => messages.mutateMessage(
          job.request.target(job.channelId, job.messageId),
          budget: job.budget,
        ),
      );
      job.budget.check();
    }
  }
}

abstract interface class BotDeferredTimingOutput {
  void deferTimedMutation(BotTimedMessageMutation request);
}

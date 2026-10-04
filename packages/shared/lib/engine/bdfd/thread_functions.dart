import '../../services/bot_thread_service.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdThreadFunctions(BotThreadService service) {
  Future<String> guarded(
    BdfdInvocation call,
    Future<String> Function() operation,
  ) async {
    try {
      return await operation();
    } on ArgumentError catch (e) {
      throw BdfdNativeError(e.message.toString(), call.location);
    } on StateError catch (e) {
      throw BdfdNativeError(e.message, call.location);
    }
  }

  bool boolean(String raw) {
    if (raw.trim().toLowerCase() == 'yes') return true;
    if (raw.trim().toLowerCase() == 'no') return false;
    throw ArgumentError('Expected yes or no.');
  }

  int integer(String raw) {
    final n = int.tryParse(raw.trim());
    if (n == null) throw ArgumentError('Expected an integer.');
    return n;
  }

  return {
    'startthread': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 5,
      handler: (call) => guarded(call, () async {
        final name = await call.argument(0),
            channel = await call.argument(1),
            message = (await call.argument(2)).trim();
        final rawArchive = call.argumentCount > 3
            ? (await call.argument(3)).trim()
            : '';
        final archive = rawArchive.isEmpty ? 60 : integer(rawArchive);
        final returns = call.argumentCount > 4
            ? boolean(await call.argument(4))
            : false;
        final change = ThreadCreation(
          name: name,
          channelId: channel,
          messageId: message.isEmpty ? null : message,
          archiveMinutes: archive,
        );
        change.validate();
        final id = await service.startThread(
          change,
          budget: call.context.budget,
        );
        return returns ? id : '';
      }),
    ),
    'editthread': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 6,
      handler: (call) => guarded(call, () async {
        final id = await call.argument(0);
        Future<String?> optional(int index) async {
          if (call.argumentCount <= index) return null;
          final raw = await call.argument(index);
          return raw.trim() == '!unchanged' ? null : raw;
        }

        final name = await optional(1),
            archived = await optional(2),
            archive = await optional(3),
            locked = await optional(4),
            slowmode = await optional(5);
        final change = ThreadModification(
          threadId: id,
          name: name,
          archived: archived == null ? null : boolean(archived),
          archiveMinutes: archive == null ? null : integer(archive),
          locked: locked == null ? null : boolean(locked),
          slowmodeSeconds: slowmode == null ? null : integer(slowmode),
        );
        change.validate();
        await service.editThread(change, budget: call.context.budget);
        return '';
      }),
    ),
    for (final remove in [false, true])
      remove ? 'threadremovemember' : 'threadaddmember': BdfdNativeFunction(
        minArguments: 2,
        maxArguments: 2,
        handler: (call) => guarded(call, () async {
          final change = ThreadMemberChange(
            threadId: await call.argument(0),
            userId: await call.argument(1),
          );
          change.validate();
          if (remove) {
            await service.removeThreadMember(
              change,
              budget: call.context.budget,
            );
          } else {
            await service.addThreadMember(change, budget: call.context.budget);
          }
          return '';
        }),
      ),
    for (final users in [false, true])
      users ? 'threadusercount' : 'threadmessagecount': BdfdNativeFunction(
        minArguments: 0,
        maxArguments: 0,
        handler: (call) => guarded(call, () async {
          final current = call.context.variables['channel.id'];
          final info = await service.threadInfo(
            threadId: current == null || current.isEmpty ? null : current,
            budget: call.context.budget,
          );
          return (users ? info.userCount : info.messageCount).toString();
        }),
      ),
  };
}

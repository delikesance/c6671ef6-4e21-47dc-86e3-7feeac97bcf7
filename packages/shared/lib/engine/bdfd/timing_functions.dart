import '../../services/bot_cooldown_service.dart';
import '../../services/bot_message_query_service.dart';
import '../../services/bot_timing_service.dart';
import '../../utils/bdfd_duration_parser.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdTimingFunctions({
  required BotDelayService delays,
  BotMessageQueryService? messages,
}) {
  Future<Duration> duration(
    BdfdInvocation call, {
    bool minimumSecond = false,
  }) async {
    final parsed = parseBdfdDuration(await call.argument(0));
    if (parsed == null ||
        parsed <= Duration.zero ||
        parsed > const Duration(minutes: 40) ||
        (minimumSecond && parsed < const Duration(seconds: 1))) {
      throw BdfdNativeError(
        'Duration must be positive and at most 40 minutes${minimumSecond ? ', with a minimum of one second' : ''}.',
        call.location,
      );
    }
    return parsed;
  }

  void defer(BdfdInvocation call, BotTimedMessageMutation request) {
    final output = call.context.output;
    if (output is! BotDeferredTimingOutput) {
      throw BdfdNativeError(
        'No scheduled message output configured.',
        call.location,
      );
    }
    (output as BotDeferredTimingOutput).deferTimedMutation(request);
  }

  return {
    'replyin': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final delay = await duration(call, minimumSecond: true);
        await call.context.budget.run(
          () => delays.delay(delay, budget: call.context.budget),
        );
        call.context.budget.check();
        return '';
      },
    ),
    'deletein': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        defer(
          call,
          BotTimedMessageMutation(delay: await duration(call), delete: true),
        );
        return '';
      },
    ),
    'editin': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) async {
        final delay = await duration(call);
        final content = await call.argument(1);
        if (content.isEmpty) {
          throw BdfdNativeError(
            'Edited message must not be empty.',
            call.location,
          );
        }
        try {
          defer(
            call,
            BotTimedMessageMutation(
              delay: delay,
              edit: MessageEdit(content: content),
            ),
          );
        } on ArgumentError catch (error) {
          throw BdfdNativeError(error.message.toString(), call.location);
        }
        return '';
      },
    ),
    'editembedin': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 5,
      handler: (call) async {
        final delay = await duration(call);
        Future<String> optional(int index) async =>
            call.argumentCount > index ? await call.argument(index) : '';
        final title = await optional(1),
            description = await optional(2),
            footer = await optional(3),
            rawColor = (await optional(4)).trim();
        if (title.isEmpty && description.isEmpty && footer.isEmpty) {
          throw BdfdNativeError(
            'At least one embed text field is required.',
            call.location,
          );
        }
        int? color;
        if (rawColor.isNotEmpty) {
          color = rawColor.startsWith('#')
              ? (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(rawColor)
                    ? int.tryParse(rawColor.substring(1), radix: 16)
                    : null)
              : int.tryParse(rawColor);
          color ??= RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(rawColor)
              ? int.tryParse(rawColor, radix: 16)
              : null;
          if (color == null) {
            throw BdfdNativeError('Invalid embed color.', call.location);
          }
        }
        try {
          defer(
            call,
            BotTimedMessageMutation(
              delay: delay,
              edit: MessageEdit(
                content: '',
                title: title,
                description: description,
                footer: footer,
                color: color,
                replaceEmbed: true,
              ),
            ),
          );
        } on ArgumentError catch (error) {
          throw BdfdNativeError(error.message.toString(), call.location);
        }
        return '';
      },
    ),
    'deletecommand': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        if (messages == null) {
          throw BdfdNativeError(
            'No message mutation service configured.',
            call.location,
          );
        }
        final request = MessageMutation(
          kind: MessageMutationKind.delete,
          channelId: call.context.variables['channel.id'] ?? '',
          messageId: call.context.variables['message.id'] ?? '',
        );
        try {
          request.validate();
          await call.context.budget.run(
            () => messages.mutateMessage(request, budget: call.context.budget),
          );
          call.context.budget.check();
        } on ArgumentError catch (error) {
          throw BdfdNativeError(error.message.toString(), call.location);
        }
        return '';
      },
    ),
    'defer': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final ephemeral = call.argumentCount > 0
            ? (await call.argument(0)).trim().toLowerCase()
            : '';
        final isEphemeral = ephemeral == 'yes' || ephemeral == 'true';
        call.context.response.acknowledged = true;
        if (isEphemeral) {
          call.context.response.ephemeral = true;
        }
        return '';
      },
    ),
    'wait': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final delay = await duration(call);
        await call.context.budget.run(
          () => delays.delay(delay, budget: call.context.budget),
        );
        call.context.budget.check();
        return '';
      },
    ),
    'executiontime': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        return '${call.context.budget.elapsedMilliseconds}';
      },
    ),
    'uptime': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        return call.context.variables['bot.uptime'] ?? '0';
      },
    ),
    'hostingexpiretime': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        return call.context.variables['hosting.expireTime'] ??
            call.context.variables['hosting.expiretime'] ??
            '';
      },
    ),
    'premiumexpiretime': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        return call.context.variables['premium.expireTime'] ??
            call.context.variables['premium.expiretime'] ??
            '';
      },
    ),
  };
}

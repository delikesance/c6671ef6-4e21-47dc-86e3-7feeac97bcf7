import '../../services/bot_cooldown_service.dart';
import '../../utils/bdfd_duration_parser.dart';
import 'program.dart';
import 'runtime.dart';

final _cooldownLabels = Expando<List<String>>();

Map<String, BdfdNativeFunction> bdfdCooldownFunctions(
  BotCooldownService service, {
  required String botId,
}) {
  String id(BdfdInvocation call, String raw) {
    final value = raw.trim();
    final parsed = RegExp(r'^[0-9]+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Invalid Discord ID.', call.location);
    }
    return '$parsed';
  }

  BotCooldownKey key(BdfdInvocation call, BotCooldownType type) {
    final variables = call.context.variables;
    final command = variables['command.id'] ?? variables['commandId'] ?? '';
    if (botId.isEmpty || command.isEmpty) {
      throw BdfdNativeError(
        'Cooldown requires a bot and command ID.',
        call.location,
      );
    }
    return BotCooldownKey(
      botId: botId,
      commandId: command,
      type: type,
      userId: type == BotCooldownType.server
          ? null
          : id(call, variables['author.id'] ?? variables['user.id'] ?? ''),
      guildId: type == BotCooldownType.global
          ? null
          : id(call, variables['guild.id'] ?? ''),
    );
  }

  String format(BdfdInvocation call, String message, Duration duration) {
    final labels =
        _cooldownLabels[call.context] ??
        const ['Days', 'Hours', 'Minutes', 'Seconds'];
    final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
    final amounts = [seconds / 86400, seconds / 3600, seconds / 60, seconds];
    String part(int index) {
      final value = amounts[index].toStringAsFixed(1);
      return '${value.endsWith('.0') ? value.substring(0, value.length - 2) : value} ${labels[index]}';
    }

    var index = amounts.indexWhere((amount) => amount >= 1);
    if (index < 0) index = 3;
    final replacements = {
      '%time%': part(index),
      '%time-d%': part(0),
      '%time-h%': part(1),
      '%time-m%': part(2),
      '%time-s%': part(3),
    };
    // Single pass: replacement labels remain data even when they contain tokens.
    return message.replaceAllMapped(
      RegExp(r'%time(?:-[dhms])?%'),
      (match) => replacements[match[0]]!,
    );
  }

  BdfdNativeFunction cooldown(BotCooldownType type) => BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 2,
    handler: (call) async {
      final duration = parseBdfdDuration(await call.argument(0));
      if (duration == null ||
          duration <= Duration.zero ||
          duration.inSeconds > 6041308684139) {
        throw BdfdNativeError('Invalid cooldown duration.', call.location);
      }
      final target = key(call, type);
      final remaining = await call.context.budget.run(
        () => service.acquire(target, duration, budget: call.context.budget),
      );
      call.context.budget.check();
      if (remaining > Duration.zero) {
        final message = format(call, await call.argument(1), remaining);
        if (message.isEmpty) {
          // The official BDScript 2 guide uses an empty error slot with $try.
          throw BdfdNativeError('Command is on cooldown.', call.location);
        }
        call.stop(message);
      }
      return '';
    },
  );

  return {
    'cooldown': cooldown(BotCooldownType.normal),
    'globalcooldown': cooldown(BotCooldownType.global),
    'servercooldown': cooldown(BotCooldownType.server),
    'getcooldown': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final raw = await call.argument(0);
        final type = BotCooldownType.values
            .where((type) => type.name == raw)
            .firstOrNull;
        if (type == null) {
          throw BdfdNativeError(
            'Cooldown type must be normal, server or global.',
            call.location,
          );
        }
        final remaining = await call.context.budget.run(
          () => service.remaining(key(call, type), budget: call.context.budget),
        );
        call.context.budget.check();
        return '${(remaining.inMicroseconds / Duration.microsecondsPerSecond).ceil()}';
      },
    ),
    'changecooldowntime': BdfdNativeFunction(
      minArguments: 4,
      maxArguments: 4,
      handler: (call) async {
        final labels = <String>[];
        for (var index = 0; index < 4; index++) {
          final label = await call.argument(index);
          if (label.isEmpty) {
            throw BdfdNativeError(
              'Cooldown time labels must not be empty.',
              call.location,
            );
          }
          labels.add(label);
        }
        _cooldownLabels[call.context] = labels;
        return '';
      },
    ),
  };
}

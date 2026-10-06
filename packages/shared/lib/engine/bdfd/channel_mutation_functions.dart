import '../../services/bot_channel_mutation_service.dart';
import '../../services/bot_channel_query_service.dart';
import '../../utils/bdfd_duration_parser.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdChannelMutationFunctions(
  BotChannelMutationService service, {
  BotChannelQueryService? queries,
}) => {
  'createchannel': BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 3,
    handler: (call) async {
      final name = (await call.argument(0)).trim();
      final type = (await call.argument(1)).trim().toLowerCase();
      final category = call.argumentCount > 2
          ? (await call.argument(2)).trim()
          : null;
      if (!const [
        'category',
        'text',
        'voice',
        'stage',
        'forum',
      ].contains(type)) {
        throw BdfdNativeError('Invalid BDFD channel type.', call.location);
      }
      final guild = call.context.variables['guild.id'] ?? '';
      final change = ChannelCreation(
        guildId: guild,
        name: name,
        type: type,
        categoryId: category,
      );
      change.validate();
      await service.createChannel(change, budget: call.context.budget);
      return '';
    },
  ),
  'modifychannel': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 6,
    handler: (call) async {
      final values = <String>[];
      for (var i = 0; i < call.argumentCount; i++) {
        values.add(await call.argument(i));
      }
      String? optional(int index, {bool allowEmpty = false}) {
        if (index >= values.length || values[index].trim() == '!unchanged') {
          return null;
        }
        return !allowEmpty && values[index].trim().isEmpty
            ? null
            : values[index];
      }

      final id = int.tryParse(values[0].trim());
      if (id == null || id <= 0) {
        throw BdfdNativeError('Invalid channel ID.', call.location);
      }
      final boolValue = optional(3)?.trim().toLowerCase();
      if (boolValue != null &&
          !const ['yes', 'no', 'true', 'false'].contains(boolValue)) {
        throw BdfdNativeError('NSFW must be yes or no.', call.location);
      }
      final rawPosition = optional(4)?.trim();
      final position = rawPosition == null ? null : int.tryParse(rawPosition);
      if (rawPosition != null && (position == null || position < 1)) {
        throw BdfdNativeError(
          'Channel position must be a positive integer.',
          call.location,
        );
      }
      final category = optional(5)?.trim();
      final change = ChannelModification(
        channelId: '$id',
        name: optional(1)?.trim(),
        topic: optional(2, allowEmpty: true),
        isNsfw: boolValue == null
            ? null
            : boolValue == 'yes' || boolValue == 'true',
        position: position == null ? null : position - 1,
        categoryId: category,
      );
      change.validate();
      await service.modifyChannel(change, budget: call.context.budget);
      return '';
    },
  ),
  'deletechannels': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 10000,
    handler: (call) async {
      final ids = <String>{};
      for (var i = 0; i < call.argumentCount; i++) {
        final raw = (await call.argument(i)).trim();
        final id = int.tryParse(raw);
        if (id == null || id <= 0) {
          throw BdfdNativeError('Invalid channel ID.', call.location);
        }
        ids.add('$id');
      }
      for (final id in ids) {
        await service.deleteChannel(
          ChannelDeletion(channelId: id),
          budget: call.context.budget,
        );
        call.context.budget.check();
      }
      return '';
    },
  ),
  if (queries != null)
    'deletechannelsbyname': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 10000,
      handler: (call) async {
        final names = <String>{};
        for (var i = 0; i < call.argumentCount; i++) {
          final name = (await call.argument(i)).trim();
          if (name.isEmpty) {
            throw BdfdNativeError('Channel name is required.', call.location);
          }
          names.add(name);
        }
        final channels = await queries.channels(budget: call.context.budget);
        final ids = channels
            .where((c) => names.contains(c.name))
            .map((c) => c.id)
            .toSet();
        if (ids.isEmpty) {
          throw BdfdNativeError('No matching channels found.', call.location);
        }
        for (final id in ids) {
          await service.deleteChannel(
            ChannelDeletion(channelId: id),
            budget: call.context.budget,
          );
          call.context.budget.check();
        }
        return '';
      },
    ),
  'slowmode': BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 2,
    handler: (call) async {
      final id = (await call.argument(0)).trim();
      final duration = parseBdfdDuration(await call.argument(1));
      final parsed = int.tryParse(id);
      if (parsed == null || parsed <= 0) {
        throw BdfdNativeError('Invalid channel ID.', call.location);
      }
      if (duration == null ||
          duration.isNegative ||
          duration > const Duration(hours: 6)) {
        throw BdfdNativeError(
          'Slowmode must be between 0 and 6 hours.',
          call.location,
        );
      }
      await call.context.budget.run(
        () => service.setSlowmode(
          SlowmodeChange(channelId: '$parsed', seconds: duration.inSeconds),
          budget: call.context.budget,
        ),
      );
      return '';
    },
  ),
};

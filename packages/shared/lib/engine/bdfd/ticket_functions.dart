import '../../services/bot_channel_mutation_service.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdTicketFunctions({
  BotChannelMutationService? service,
}) => {
  'newticket': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 3,
    handler: (call) async {
      final name = call.argumentCount > 0
          ? (await call.argument(0)).trim()
          : '';
      final category = call.argumentCount > 1
          ? (await call.argument(1)).trim()
          : null;
      final guild = call.context.variables['guild.id'] ?? '';
      final username =
          call.context.variables['user.username'] ??
          call.context.variables['author.username'] ??
          'user';
      final channelName = name.isEmpty ? 'ticket-$username' : name;
      if (service != null && guild.isNotEmpty) {
        final change = ChannelCreation(
          guildId: guild,
          name: channelName,
          type: 'text',
          categoryId: category?.isEmpty == true ? null : category,
        );
        change.validate();
        await call.context.budget.run(
          () => service.createChannel(change, budget: call.context.budget),
        );
      }
      return call.context.variables['channel.id'] ?? '';
    },
  ),
  'closeticket': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async {
      final channelId = call.argumentCount > 0
          ? (await call.argument(0)).trim()
          : (call.context.variables['channel.id'] ?? '');
      if (service != null && channelId.isNotEmpty) {
        await call.context.budget.run(
          () => service.deleteChannel(
            ChannelDeletion(channelId: channelId),
            budget: call.context.budget,
          ),
        );
      }
      return '';
    },
  ),
  'isticket': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async {
      final isTicket = call.context.variables['channel.isTicket'];
      if (isTicket != null) return isTicket;
      final channelName = call.context.variables['channel.name'] ?? '';
      return '${channelName.startsWith('ticket-')}';
    },
  ),
};

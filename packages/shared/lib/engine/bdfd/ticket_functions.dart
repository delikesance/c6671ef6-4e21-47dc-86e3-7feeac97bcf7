import '../../engine/execution_budget.dart';
import '../../services/bot_channel_mutation_service.dart';
import '../../services/bot_channel_query_service.dart';
import '../../services/bot_message_service.dart';
import '../../services/command_input.dart';
import 'message_functions.dart' show BdfdMessageOutput;
import 'program.dart';
import 'runtime.dart';

const _viewChannel = 1 << 10;
const _sendMessages = 1 << 11;
const _readMessageHistory = 1 << 16;

/// Wiki: $newTicket[Category ID/Name;No question message;In ticket message;
/// Message to user;Error message;(Ticket number;Return ID of the ticket
/// message?)], $closeTicket[Error message] and $isTicket[(Channel ID)].
Map<String, BdfdNativeFunction> bdfdTicketFunctions({
  BotChannelMutationService? service,
  BotChannelQueryService? queries,
}) {
  bool isTicketName(String name) => name.toLowerCase().contains('ticket');

  Future<String?> channelName(BdfdInvocation call, String id) async {
    if (queries == null) return null;
    final channel = await call.context.budget.run(
      () => queries.channel(id, budget: call.context.budget),
    );
    return channel?.name;
  }

  Future<String> categoryId(BdfdInvocation call, String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (RegExp(r'^[0-9]+$').hasMatch(value)) return value;
    if (queries == null) {
      throw ArgumentError('Category lookup by name is unavailable.');
    }
    final channels = await call.context.budget.run(
      () => queries.channels(budget: call.context.budget),
    );
    final match = channels
        .where(
          (channel) =>
              channel.type == 'category' &&
              channel.name.toLowerCase() == value.toLowerCase(),
        )
        .firstOrNull;
    if (match == null) throw ArgumentError('Ticket category not found.');
    return match.id;
  }

  String slug(String raw) {
    final text = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return text;
  }

  return {
    'newticket': BdfdNativeFunction(
      minArguments: 5,
      maxArguments: 7,
      handler: (call) async {
        final categoryRaw = await call.argument(0);
        final noSubject = await call.argument(1);
        final inTicket = await call.argument(2);
        final toUser = await call.argument(3);
        final errorMessage = await call.argument(4);
        final number = call.argumentCount > 5
            ? (await call.argument(5)).trim()
            : '';
        final returnId = call.argumentCount > 6
            ? (await call.argument(6)).trim().toLowerCase()
            : 'no';
        if (number.isNotEmpty && int.tryParse(number) == null) {
          throw BdfdNativeError(
            'Ticket number must be an integer.',
            call.location,
          );
        }
        if (!const ['yes', 'no', 'true', 'false'].contains(returnId)) {
          throw BdfdNativeError(
            'Return message ID must be yes or no.',
            call.location,
          );
        }
        final variables = call.context.variables;
        final guild = variables['guild.id'] ?? '';
        final author = variables['author.id'] ?? variables['user.id'] ?? '';
        final sink = call.context.output;
        if (service == null || sink is! BdfdMessageOutput) {
          throw BdfdNativeError(
            'Ticket creation is not available.',
            call.location,
          );
        }
        final subjectText = CommandInput(variables).text.trim();
        final subject = subjectText.isEmpty ? noSubject : subjectText;
        final username =
            variables['author.username'] ?? variables['user.username'] ?? '';
        final suffix = number.isNotEmpty
            ? number
            : (slug(username).isEmpty ? author : slug(username));
        String? channelId;
        String messageId = '';
        try {
          final category = await categoryId(call, categoryRaw);
          final bot = variables['bot.id'] ?? '';
          final change = ChannelCreation(
            guildId: guild,
            name: 'ticket-$suffix',
            type: 'text',
            categoryId: category.isEmpty ? null : category,
            overwrites: [
              ChannelOverwriteSpec(id: guild, deny: _viewChannel),
              ChannelOverwriteSpec(
                id: author,
                isMember: true,
                allow: _viewChannel | _sendMessages | _readMessageHistory,
              ),
              if (RegExp(r'^[0-9]+$').hasMatch(bot) && bot != author)
                ChannelOverwriteSpec(
                  id: bot,
                  isMember: true,
                  allow: _viewChannel | _sendMessages | _readMessageHistory,
                ),
            ],
          );
          change.validate();
          channelId = await call.context.budget.run(
            () => service.createChannel(change, budget: call.context.budget),
          );
          String fill(String text) => text
              .replaceAll('{subject}', subject)
              .replaceAll('{channel}', '<#$channelId>');
          if (inTicket.trim().isNotEmpty) {
            await sink.flush(call.context, call.location);
            messageId = await sink.send(
              BotMessageRequest(
                destination: BotMessageDestination.channel,
                payload: {
                  'channelId': channelId,
                  'content': fill(inTicket),
                  'targetType': 'channel',
                },
              ),
              call.context,
              call.location,
            );
          }
          sink.append(fill(toUser));
        } on CommandExecutionTimeout {
          rethrow;
        } on BdfdNativeError {
          rethrow;
        } catch (error) {
          if (errorMessage.isEmpty) {
            throw BdfdNativeError(
              'Ticket creation failed: $error',
              call.location,
            );
          }
          sink.append(errorMessage);
          return '';
        }
        return returnId == 'yes' || returnId == 'true' ? messageId : '';
      },
    ),
    'closeticket': BdfdNativeFunction(
      // The wiki's only parameter is Emptiable, so the bare form is allowed.
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final errorMessage = call.argumentCount == 0
            ? ''
            : await call.argument(0);
        final channelId = call.context.variables['channel.id'] ?? '';
        final name =
            call.context.variables['channel.name'] ??
            await channelName(call, channelId);
        if (name == null || !isTicketName(name)) return errorMessage;
        if (service == null || channelId.isEmpty) {
          throw BdfdNativeError(
            'Channel deletion is not available.',
            call.location,
          );
        }
        try {
          await call.context.budget.run(
            () => service.deleteChannel(
              ChannelDeletion(channelId: channelId),
              budget: call.context.budget,
            ),
          );
        } on ArgumentError catch (error) {
          throw BdfdNativeError(error.message.toString(), call.location);
        }
        return '';
      },
    ),
    'isticket': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final explicit = call.argumentCount > 0
            ? (await call.argument(0)).trim()
            : '';
        final current = call.context.variables['channel.id'] ?? '';
        if (explicit.isEmpty || explicit == current) {
          final hydrated = call.context.variables['channel.name'];
          if (hydrated != null) return '${isTicketName(hydrated)}';
        }
        final id = explicit.isEmpty ? current : explicit;
        if (!RegExp(r'^[0-9]+$').hasMatch(id)) {
          throw BdfdNativeError('Invalid channel ID.', call.location);
        }
        final name = await channelName(call, id);
        return '${name != null && isTicketName(name)}';
      },
    ),
  };
}

import 'dart:convert';
import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import '../actions/respond_modal.dart' show buildModalResponse;
import '../types/component.dart' show ModalDefinition;
import '../utils/interaction_ack_state.dart';
import 'bot_message_query_service.dart' show messageQuerySnowflake;

/// Already evaluated normal message components. Maps use the shared product
/// component schema; this service translates them directly to Discord payloads.
abstract interface class BotComponentService {
  Future<List<Map<String, dynamic>>> readComponents(
    String messageId, {
    required CommandExecutionBudget budget,
  });
  Future<void> editComponents(
    String messageId,
    List<Map<String, dynamic>> rows, {
    required CommandExecutionBudget budget,
  });
  Future<void> sendModal(
    Map<String, dynamic> definition, {
    required CommandExecutionBudget budget,
  });
}

class DiscordBotComponentService implements BotComponentService {
  const DiscordBotComponentService({
    required this.client,
    this.channelId,
    this.interaction,
  });
  final NyxxGateway client;
  final Snowflake? channelId;
  final Interaction? interaction;

  Future<Message> _message(String id, CommandExecutionBudget budget) async {
    final target = channelId ?? interaction?.channelId;
    if (target == null) {
      throw StateError('A channel is required for component edits.');
    }
    final channel = await budget.run(() => client.channels.fetch(target));
    if (channel is! TextChannel) {
      throw StateError('Component edits require a text channel.');
    }
    final message = await budget.run(
      () => channel.messages.fetch(messageQuerySnowflake(id)),
    );
    if (message.author.id != client.user.id) {
      throw StateError('Only bot-authored message components can be edited.');
    }
    return message;
  }

  @override
  Future<List<Map<String, dynamic>>> readComponents(
    String messageId, {
    required CommandExecutionBudget budget,
  }) async {
    final message = await _message(messageId, budget);
    return (message.components ?? []).map(componentSnapshot).toList();
  }

  @override
  Future<void> editComponents(
    String messageId,
    List<Map<String, dynamic>> rows, {
    required CommandExecutionBudget budget,
  }) async {
    final builders = rows.map(nativeComponentBuilder).toList();
    final message = await _message(messageId, budget);
    await budget.run(
      () => message.edit(MessageUpdateBuilder(components: builders)),
    );
  }

  @override
  Future<void> sendModal(
    Map<String, dynamic> definition, {
    required CommandExecutionBudget budget,
  }) async {
    final builder = nativeModalBuilder(definition);
    final target = interaction;
    if (target == null || isInteractionAcknowledged(target)) {
      throw StateError('A modal requires an unacknowledged interaction.');
    }
    if (target is ApplicationCommandInteraction) {
      await budget.run(() => target.respondModal(builder));
    } else if (target is MessageComponentInteraction) {
      await budget.run(() => target.respondModal(builder));
    } else {
      throw StateError('This interaction cannot open a modal.');
    }
    markInteractionAcknowledged(target);
  }
}

/// A SDK builder carrying only a snapshot; no Action or script resolution.
class _RawComponentBuilder extends ComponentBuilder<Component> {
  _RawComponentBuilder(this.payload)
    : super(type: ComponentType(payload['type'] as int));
  final Map<String, Object?> payload;
  @override
  Map<String, Object?> build() => Map<String, Object?>.from(payload);
}

Map<String, Object?>? _emoji(String raw) {
  if (raw.isEmpty) return null;
  final match = RegExp(r'^<(a?):([^:>]+):([0-9]+)>$').firstMatch(raw);
  if (match != null) {
    return {'name': match[2], 'id': match[3], 'animated': match[1] == 'a'};
  }
  return {'name': raw};
}

ComponentBuilder nativeComponentBuilder(Map<String, dynamic> node) {
  final type = node['type'];
  final Map<String, Object?> payload;
  if (type == 'actionRow') {
    payload = {
      'type': 1,
      'components': (node['components'] as List)
          .cast<Map<String, dynamic>>()
          .map((child) => nativeComponentBuilder(child).build())
          .toList(),
    };
  } else if (type == 'button') {
    final style = node['style'];
    final code = const {
      'primary': 1,
      'secondary': 2,
      'success': 3,
      'danger': 4,
      'link': 5,
    }[style];
    if (code == null) throw ArgumentError('Invalid button style.');
    payload = {
      'type': 2,
      'style': code,
      'label': node['label'],
      'disabled': node['disabled'] == 'true' || node['disabled'] == 'yes',
      if (style == 'link')
        'url': node['url']
      else
        'custom_id': node['customId'],
      if ((node['emoji'] ?? '').toString().isNotEmpty)
        'emoji': _emoji(node['emoji'].toString()),
    };
  } else if (const [
    'stringSelect',
    'userSelect',
    'roleSelect',
    'mentionableSelect',
    'channelSelect',
    'categorySelect',
    'voiceSelect',
  ].contains(type)) {
    payload = {
      'type': const {
        'stringSelect': 3,
        'userSelect': 5,
        'roleSelect': 6,
        'mentionableSelect': 7,
        'channelSelect': 8,
        'categorySelect': 8,
        'voiceSelect': 8,
      }[type],
      'custom_id': node['customId'],
      'min_values': node['minValues'],
      'max_values': node['maxValues'],
      'disabled': node['disabled'] == 'true' || node['disabled'] == 'yes',
      if ((node['placeholder'] ?? '').toString().isNotEmpty)
        'placeholder': node['placeholder'],
      if (type == 'stringSelect')
        'options': ((node['options'] as List?) ?? [])
            .map(
              (option) => <String, Object?>{
                'label': option['label'],
                'value': option['value'],
                'default': option['isDefault'] == true,
                if ((option['description'] ?? '').toString().isNotEmpty)
                  'description': option['description'],
                if ((option['emoji'] ?? '').toString().isNotEmpty)
                  'emoji': _emoji(option['emoji'].toString()),
              },
            )
            .toList(),
      if (type == 'categorySelect')
        'channel_types': [4]
      else if (type == 'voiceSelect')
        'channel_types': [2]
      else if (node['channelTypes'] != null)
        'channel_types': _channelTypes(node['channelTypes']),
      if (node['defaultValues'] != null)
        'default_values': node['defaultValues'],
    };
  } else if (type == 'separator') {
    payload = {
      'type': 14,
      'divider': node['divider'] == true || node['divider'] == 'yes',
      if (node['spacing'] != null) 'spacing': node['spacing'],
    };
  } else if (type == 'textDisplay') {
    payload = {'type': 10, 'content': node['content'] ?? ''};
  } else if (type == 'thumbnail') {
    payload = {
      'type': 11,
      'url': node['url'] ?? '',
      if (node['description'] != null) 'description': node['description'],
      if (node['spoiler'] == true) 'spoiler': true,
    };
  } else if (type == 'file') {
    payload = {
      'type': 13,
      'url': node['url'] ?? '',
      if (node['spoiler'] == true) 'spoiler': true,
    };
  } else if (type == 'container') {
    payload = {
      'type': 17,
      if (node['accentColor'] != null) 'accent_color': node['accentColor'],
      if (node['spoiler'] == true) 'spoiler': true,
      if (node['components'] != null)
        'components': (node['components'] as List)
            .cast<Map<String, dynamic>>()
            .map((c) => nativeComponentBuilder(c).build())
            .toList(),
    };
  } else if (type == 'section') {
    payload = {
      'type': 9,
      if (node['components'] != null)
        'components': (node['components'] as List)
            .cast<Map<String, dynamic>>()
            .map((c) => nativeComponentBuilder(c).build())
            .toList(),
    };
  } else if (type == 'mediaGallery') {
    payload = {
      'type': 12,
      'items': ((node['items'] as List?) ?? [])
          .map(
            (item) => <String, Object?>{
              'url': item['url'],
              if (item['description'] != null)
                'description': item['description'],
              if (item['spoiler'] == true) 'spoiler': true,
            },
          )
          .toList(),
    };
  } else {
    throw StateError('Unsupported existing component type $type.');
  }
  if (node['discordId'] != null) payload['id'] = node['discordId'];
  return _RawComponentBuilder(payload);
}

/// Discord expects channel_types as a list of integers; BDFD scripts supply a
/// single value or a comma-separated list.
List<int> _channelTypes(Object? raw) {
  final values = raw is Iterable
      ? raw
      : raw.toString().split(RegExp(r'[,;\s]+'));
  return [
    for (final value in values)
      if (int.tryParse(value.toString().trim()) != null)
        int.parse(value.toString().trim()),
  ];
}

/// Plain `$addTextInput` modals keep the classic action-row text inputs. As
/// soon as a modal uses Components V2 inputs (`$addModal*`), the staged native
/// modal is translated into the product modal definition and serialised with
/// the same builder as visual modal actions: inputs become Label-wrapped
/// components, static text stays a standalone display.
ModalBuilder nativeModalBuilder(Map<String, dynamic> modal) {
  final inputs = (modal['inputs'] as List).cast<Map<String, dynamic>>();
  if (inputs.isEmpty || inputs.length > 5) {
    throw ArgumentError('A modal requires 1 to 5 inputs.');
  }
  if (inputs.every((input) => input['type'] == null)) {
    return ModalBuilder(
      customId: modal['customId'] as String,
      title: modal['title'] as String,
      components: inputs
          .map(
            (input) => _RawComponentBuilder({
              'type': 1,
              'components': [
                {
                  'type': 4,
                  'custom_id': input['customId'],
                  'label': input['label'],
                  'style': input['style'] == 'paragraph' ? 2 : 1,
                  'min_length': input['minLength'],
                  'max_length': input['maxLength'],
                  'required': input['required'],
                  if ((input['value'] ?? '').toString().isNotEmpty)
                    'value': input['value'],
                  if ((input['placeholder'] ?? '').toString().isNotEmpty)
                    'placeholder': input['placeholder'],
                },
              ],
            }),
          )
          .toList(),
    );
  }
  final components = <Map<String, dynamic>>[
    for (final input in inputs)
      if (input['type'] == 'textDisplay')
        {'type': 'textDisplay', 'content': input['content'] ?? ''}
      else
        {
          'type': 'label',
          'label': input['label'] ?? '',
          'description': input['description'] ?? '',
          'component': {...input, 'type': input['type'] ?? 'textInput'},
        },
  ];
  return buildModalResponse(
    ModalDefinition.fromJson({
      'title': modal['title'],
      'customId': modal['customId'],
      'components': components,
    }),
    (value) => value,
  );
}

String _emojiSnapshot(Emoji? emoji) => emoji == null
    ? ''
    : emoji.id == Snowflake.zero
    ? emoji.name ?? ''
    : '<${emoji is GuildEmoji && emoji.isAnimated == true ? 'a' : ''}:${emoji.name}:${emoji.id}>';
Map<String, dynamic> componentSnapshot(Component component) {
  if (component is ActionRowComponent) {
    return {
      'type': 'actionRow',
      'discordId': component.id,
      'components': component.components.map(componentSnapshot).toList(),
    };
  }
  if (component is ButtonComponent) {
    return {
      'type': 'button',
      'discordId': component.id,
      'customId': component.customId ?? '',
      'url': component.url?.toString() ?? '',
      'label': component.label ?? '',
      'style': const {
        1: 'primary',
        2: 'secondary',
        3: 'success',
        4: 'danger',
        5: 'link',
      }[component.style.value],
      'emoji': _emojiSnapshot(component.emoji),
      'disabled': '${component.isDisabled ?? false}',
    };
  }
  if (component is SelectMenuComponent) {
    return {
      'type': const {
        3: 'stringSelect',
        5: 'userSelect',
        6: 'roleSelect',
        7: 'mentionableSelect',
        8: 'channelSelect',
      }[component.type.value],
      'discordId': component.id,
      'customId': component.customId,
      'placeholder': component.placeholder ?? '',
      'minValues': component.minValues ?? 1,
      'maxValues': component.maxValues ?? 1,
      'disabled': '${component.isDisabled ?? false}',
      'options':
          component.options
              ?.map(
                (o) => {
                  'label': o.label,
                  'value': o.value,
                  'description': o.description ?? '',
                  'emoji': _emojiSnapshot(o.emoji),
                  'isDefault': o.isDefault ?? false,
                },
              )
              .toList() ??
          [],
      if (component.channelTypes != null)
        'channelTypes': component.channelTypes!.map((t) => t.value).toList(),
      if (component.defaultValues != null)
        'defaultValues': component.defaultValues!
            .map((v) => {'id': '${v.id}', 'type': v.type.value})
            .toList(),
    };
  }
  throw StateError(
    'Editing rich/unknown components is not supported by normal component functions.',
  );
}

List<Map<String, dynamic>> copyComponentRows(List<Map<String, dynamic>> rows) =>
    (jsonDecode(jsonEncode(rows)) as List).cast<Map<String, dynamic>>();

void validateComponentRows(List<Map<String, dynamic>> rows) {
  final actionRows = rows.where((r) => r['type'] == 'actionRow').length;
  if (actionRows > 5) {
    throw ArgumentError('A message supports at most 5 rows.');
  }
  final ids = <String>{};
  for (final row in rows) {
    if (row['type'] != 'actionRow' || row['components'] == null) {
      final id = row['customId']?.toString() ?? row['id']?.toString() ?? '';
      if (id.isNotEmpty && !ids.add(id)) {
        throw ArgumentError('Duplicate component custom ID.');
      }
      continue;
    }
    final children = (row['components'] as List).cast<Map<String, dynamic>>();
    if (children.isEmpty || children.length > 5)
      throw ArgumentError('Invalid component row size.');
    for (final child in children) {
      final id = child['customId']?.toString() ?? '';
      if (id.isNotEmpty && !ids.add(id))
        throw ArgumentError('Duplicate component custom ID.');
      if (child['type'] != 'button' && children.length != 1)
        throw ArgumentError('Select menus require their own row.');
      if (child['type'] == 'stringSelect') {
        final options = child['options'] as List;
        final maximum = child['maxValues'] as int;
        if (options.isEmpty || options.length > 25 || maximum > options.length)
          throw ArgumentError(
            'Select menu option count does not support its selection bounds.',
          );
      }
    }
  }
}

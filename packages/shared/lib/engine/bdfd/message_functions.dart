import '../../services/bot_component_service.dart';
import 'component_functions.dart';
import '../../services/bot_message_query_service.dart';
import '../../services/bot_reaction_service.dart';
import '../../services/bot_timing_service.dart';
import 'reaction_functions.dart';
import '../../engine/execution_budget.dart';
import '../../services/bot_message_service.dart';
import 'program.dart';
import 'runtime.dart';

/// Per-invocation response builder. A send detaches its snapshot before awaiting
/// Discord, so catching a failed send cannot accidentally replay the message.
class BdfdMessageOutput
    implements
        BdfdOutput,
        BotDeferredMessageOutput,
        BotDeferredReactionOutput,
        BotDeferredTimingOutput,
        BdfdComponentOutput,
        BdfdErrorOutput {
  BdfdMessageOutput(
    this.service, {
    this.messageQueries,
    this.reactions,
    this.components,
    this.timing,
  });
  @override
  final BotComponentService? components;
  @override
  final BdfdComponentState componentState = BdfdComponentState();
  final BotMessageQueryService? messageQueries;
  final BotReactionService? reactions;
  final BotTimingService? timing;
  List<BotTimedMessageMutation> _timedMutations = [];
  @override
  void deferTimedMutation(BotTimedMessageMutation request) {
    if (timing == null) throw StateError('No timing service configured.');
    _timedMutations.add(request);
  }

  bool _pin = false;
  List<String> _reactions = [];
  @override
  void deferPin() {
    if (messageQueries == null) {
      throw StateError('No message mutation service configured.');
    }
    _pin = true;
  }

  @override
  void deferReactions(List<String> emojis) {
    if (reactions == null) throw StateError('No reaction service configured.');
    _reactions.addAll(emojis);
  }

  final BotMessageService service;
  StringBuffer _text = StringBuffer();
  List<Map<String, dynamic>> _embeds = [];
  Map<String, dynamic> _flags = {};
  String? channelId;

  Map<String, dynamic> get mentions => {
    if (_flags.containsKey('allowedMentions'))
      'allowedMentions': _flags['allowedMentions'],
  };

  Map<String, dynamic> embed(int index) {
    if (index < 0 || index >= 10) {
      throw ArgumentError('Embed index must be between 0 and 9.');
    }
    while (_embeds.length <= index) {
      _embeds.add({});
    }
    return _embeds[index];
  }

  void flag(String name, dynamic value) => _flags[name] = value;
  dynamic flagValue(String name) => _flags[name];

  /// `$dm` redirects the response draft to a direct message.
  String? dmUserId;

  @override
  void replaceErrorEmbed(Map<String, dynamic> embed) {
    discard();
    _embeds = [embed];
  }

  @override
  void append(String text) => _text.write(text);

  @override
  void discard() {
    componentState.clear();
    _text = StringBuffer();
    _embeds = [];
    _flags = {};
    dmUserId = null;
    _pin = false;
    _reactions = [];
    _timedMutations = [];
  }

  @override
  Future<void> flush(BdfdContext context, BdfdLocation location) async {
    await componentState.flushEdits(components, context.budget);
    if (componentState.modal != null) {
      if (components == null) {
        throw BdfdNativeError('No modal service configured.', location);
      }
      if (_text.toString().trim().isNotEmpty ||
          _embeds.isNotEmpty ||
          componentState.rows.isNotEmpty ||
          _timedMutations.isNotEmpty) {
        throw BdfdNativeError(
          'A modal cannot be combined with a message response.',
          location,
        );
      }
      final modal = componentState.modal!;
      discard();
      await context.budget.run(
        () => components!.sendModal(modal, budget: context.budget),
      );
      context.response.acknowledged = true;
      context.response.originalResponseCompleted = true;
      return;
    }
    final embeds = _embeds
        .map((source) {
          final value = Map<String, dynamic>.from(source);
          if ((value['title'] ?? '').toString().isEmpty) value.remove('url');
          if (((value['author'] as Map?)?['name'] ?? '').toString().isEmpty) {
            value.remove('author');
          }
          if (((value['footer'] as Map?)?['text'] ?? '').toString().isEmpty) {
            value.remove('footer');
          }
          return value;
        })
        .where((value) => value.isNotEmpty)
        .toList();
    var textLength = 0;
    for (final value in embeds) {
      context.budget.check();
      textLength += (value['title'] ?? '').toString().length;
      textLength += (value['description'] ?? '').toString().length;
      textLength += ((value['author'] as Map?)?['name'] ?? '')
          .toString()
          .length;
      textLength += ((value['footer'] as Map?)?['text'] ?? '')
          .toString()
          .length;
      for (final field in (value['fields'] as List?) ?? const []) {
        context.budget.check();
        textLength += (field['name'] ?? '').toString().length;
        textLength += (field['value'] ?? '').toString().length;
      }
    }
    if (textLength > 6000) {
      throw BdfdNativeError(
        'Total embed text cannot exceed 6000 characters.',
        location,
      );
    }
    if (_text.toString().trim().isEmpty &&
        embeds.isEmpty &&
        componentState.rows.isEmpty) {
      discard();
      return;
    }
    final dmUser = dmUserId;
    final request = BotMessageRequest(
      destination: dmUser != null
          ? BotMessageDestination.user
          : channelId != null ||
                _flags['replyToMessage'] == true ||
                _flags['targetType'] == 'reply'
          ? BotMessageDestination.channel
          : BotMessageDestination.response,
      payload: {
        'userId': ?dmUser,
        'content': context.removeLinks
            ? removeBdfdLinks(_text.toString())
            : _text.toString(),
        // Rich (Components V2) rows are flat staged items, so they keep the
        // `items` form whose hierarchy ComponentV2Definition reconstructs.
        if (componentState.rows.isNotEmpty)
          'components': {
            componentState.rows.any(_isRichComponentRow)
                    ? 'items'
                    : 'components':
                componentState.rows,
          },
        'embeds': embeds,
        'ephemeral': false,
        if (channelId != null) 'channelId': channelId,
        ..._flags,
      },
    );
    final pin = _pin;
    final emojis = List<String>.unmodifiable(_reactions);
    final timedMutations = List<BotTimedMessageMutation>.unmodifiable(
      _timedMutations,
    );
    discard();
    final result = await _sendResult(request, context, location);
    if (pin || emojis.isNotEmpty || timedMutations.isNotEmpty) {
      final id = result.messageId, targetChannel = result.channelId;
      if (id == null ||
          id.isEmpty ||
          targetChannel == null ||
          targetChannel.isEmpty) {
        throw BdfdNativeError(
          'The sent response has no usable channel/message ID for deferred effects.',
          location,
        );
      }
      try {
        if (pin) {
          context.budget.check();
          await messageQueries!.mutateMessage(
            MessageMutation(
              kind: MessageMutationKind.pin,
              channelId: targetChannel,
              messageId: id,
            ),
            budget: context.budget,
          );
        }
        if (emojis.isNotEmpty) {
          context.budget.check();
          await reactions!.addReactions(
            BotReactionAddRequest(
              target: BotReactionTarget(
                channelId: targetChannel,
                messageId: id,
              ),
              emojis: emojis,
            ),
            budget: context.budget,
          );
        }
        for (final mutation in timedMutations) {
          context.budget.check();
          await context.budget.run(
            () => timing!.schedule(
              mutation,
              channelId: targetChannel,
              messageId: id,
              budget: context.budget,
            ),
          );
          context.budget.check();
        }
      } on CommandExecutionTimeout {
        rethrow;
      } catch (error) {
        throw BdfdNativeError(
          error.toString(),
          location,
          cause: error,
          callStack: context.callStack,
        );
      }
    }
  }

  Future<String> send(
    BotMessageRequest request,
    BdfdContext context,
    BdfdLocation location,
  ) async => (await _sendResult(request, context, location)).messageId ?? '';

  Future<BotMessageResult> _sendResult(
    BotMessageRequest request,
    BdfdContext context,
    BdfdLocation location,
  ) async {
    try {
      final result = await service.send(
        request,
        budget: context.budget,
        variables: context.variables,
      );
      context.budget.check();
      context.response.acknowledged |= result.acknowledged;
      context.response.originalResponseCompleted |=
          result.originalResponseCompleted;
      if (result.messageId != null) {
        context.response.messageId = result.messageId;
        context.results['last.response.id'] = result.messageId!;
      }
      return result;
    } on CommandExecutionTimeout {
      rethrow;
    } on BdfdNativeError {
      rethrow;
    } catch (error) {
      throw BdfdNativeError(
        error.toString(),
        location,
        cause: error,
        callStack: context.callStack,
      );
    }
  }
}

Map<String, BdfdNativeFunction> bdfdMessageFunctions() {
  final functions = <String, BdfdNativeFunction>{};
  void add(String name, int min, int max, BdfdFunctionHandler handler) {
    functions[name] = BdfdNativeFunction(
      minArguments: min,
      maxArguments: max,
      handler: handler,
    );
  }

  BdfdMessageOutput output(BdfdInvocation call) {
    final sink = call.context.output;
    if (sink is! BdfdMessageOutput) {
      throw BdfdNativeError('No message service configured.', call.location);
    }
    return sink;
  }

  Future<Map<String, dynamic>> embed(BdfdInvocation call, int parameter) async {
    final raw = parameter < call.argumentCount
        ? (await call.argument(parameter)).trim()
        : '';
    final index = raw.isEmpty ? 1 : int.tryParse(raw);
    if (index == null || index < 1 || index > 10) {
      throw BdfdNativeError(
        'Embed index must be between 1 and 10.',
        call.location,
      );
    }
    return output(call).embed(index - 1);
  }

  void boundedText(BdfdInvocation call, String value, int limit) {
    if (value.length > limit) {
      throw BdfdNativeError(
        'Embed text cannot exceed $limit characters.',
        call.location,
      );
    }
  }

  for (final field in ['title', 'description', 'color', 'thumbnail', 'image']) {
    add(field, 1, 2, (call) async {
      final value = await call.argument(0);
      if (field == 'title') boundedText(call, value, 256);
      if (field == 'description') boundedText(call, value, 4096);
      (await embed(call, 1))[field] = field == 'image' || field == 'thumbnail'
          ? {'url': value}
          : value;
      return '';
    });
  }
  add('footer', 1, 2, (call) async {
    final text = await call.argument(0);
    boundedText(call, text, 2048);
    final selected = await embed(call, 1);
    final footer =
        selected.putIfAbsent('footer', () => <String, dynamic>{}) as Map;
    footer['text'] = text;
    return '';
  });
  add('author', 1, 2, (call) async {
    final name = await call.argument(0);
    boundedText(call, name, 256);
    final selected = await embed(call, 1);
    final author =
        selected.putIfAbsent('author', () => <String, dynamic>{}) as Map;
    author['name'] = name;
    return '';
  });
  for (final entry in {
    'authoricon': ('author', 'icon_url'),
    'authorurl': ('author', 'url'),
    'footericon': ('footer', 'icon_url'),
  }.entries) {
    add(entry.key, 1, 2, (call) async {
      final value = await call.argument(0);
      final selected = await embed(call, 1);
      final section =
          selected.putIfAbsent(entry.value.$1, () => <String, dynamic>{})
              as Map;
      section[entry.value.$2] = value;
      return '';
    });
  }
  add('embeddedurl', 1, 2, (call) async {
    final value = await call.argument(0);
    (await embed(call, 1))['url'] = value;
    return '';
  });
  add('addtimestamp', 0, 1, (call) async {
    final selected = await embed(call, 0);
    selected['timestamp'] = call.context.time.instant.toUtc().toIso8601String();
    return '';
  });
  add('addfield', 2, 4, (call) async {
    final name = await call.argument(0);
    final value = await call.argument(1);
    if (name.isEmpty || value.isEmpty) {
      throw BdfdNativeError(
        'Embed field name and value are required.',
        call.location,
      );
    }
    boundedText(call, name, 256);
    boundedText(call, value, 1024);
    final rawInline = call.argumentCount > 2
        ? (await call.argument(2)).trim().toLowerCase()
        : 'no';
    if (!const ['yes', 'no', 'true', 'false'].contains(rawInline)) {
      throw BdfdNativeError(
        'Field inline flag must be yes or no.',
        call.location,
      );
    }
    final inline = _yes(rawInline);
    final fields =
        (await embed(call, 3)).putIfAbsent('fields', () => <dynamic>[]) as List;
    final field = {'name': name, 'value': value, 'inline': inline};
    if (fields.length >= 25) {
      throw BdfdNativeError(
        'An embed cannot contain more than 25 fields.',
        call.location,
      );
    }
    fields.add(field);
    return '';
  });
  for (final entry in {'ephemeral': 'ephemeral', 'tts': 'tts'}.entries) {
    add(entry.key, 0, 0, (call) {
      output(call).flag(entry.value, true);
      return '';
    });
  }
  add('nomention', 0, 0, (call) {
    output(call).flag('allowedMentions', {'parse': <String>[]});
    return '';
  });
  // Mentions listed explicitly cannot also be requested through `parse`.
  void restrictMentions(BdfdInvocation call, String kind, List<String> ids) {
    final sink = output(call);
    final current = sink.flagValue('allowedMentions');
    final parse = <String>[
      ...((current is Map ? current['parse'] : null) as List? ??
              const ['users', 'roles'])
          .map((value) => value.toString()),
    ]..remove(kind);
    final next = <String, dynamic>{
      if (current is Map) ...Map<String, dynamic>.from(current),
      'parse': parse,
    };
    next[kind] = ids;
    sink.flag('allowedMentions', next);
  }

  for (final entry in {
    'allowusermentions': 'users',
    'allowrolementions': 'roles',
  }.entries) {
    add(entry.key, 0, 1 << 30, (call) async {
      final ids = <String>{};
      for (var i = 0; i < call.argumentCount; i++) {
        call.context.budget.check();
        final value = (await call.argument(i)).trim();
        if (value.isEmpty) continue;
        if (!RegExp(r'^[0-9]+$').hasMatch(value) || int.parse(value) <= 0) {
          throw BdfdNativeError('Invalid Discord ID.', call.location);
        }
        ids.add(value);
      }
      restrictMentions(call, entry.value, ids.toList());
      return '';
    });
  }
  // Wiki: disables replacing mentions in $message with text. The native
  // $message returns the raw mention text, so there is nothing to disable.
  add('allowmention', 0, 0, (call) => '');
  // Wiki: tells Discord the bot is typing in the current channel.
  add('bottyping', 0, 0, (call) async {
    await output(call).send(
      BotMessageRequest(
        destination: BotMessageDestination.channel,
        payload: {'targetType': 'typing', 'content': ''},
      ),
      call.context,
      call.location,
    );
    return '';
  });
  add('dm', 0, 1, (call) async {
    final raw = call.argumentCount == 1 ? (await call.argument(0)).trim() : '';
    final id = raw.isEmpty
        ? (call.context.variables['author.id'] ??
                  call.context.variables['user.id'] ??
                  '')
              .trim()
        : raw;
    if (!RegExp(r'^[0-9]+$').hasMatch(id) || int.parse(id) <= 0) {
      throw BdfdNativeError('Invalid user ID.', call.location);
    }
    output(call).dmUserId = id;
    return '';
  });
  add('reply', 0, 2, (call) async {
    if (call.argumentCount == 1) {
      throw BdfdNativeError(
        'Reply expects zero or two arguments.',
        call.location,
      );
    }
    final sink = output(call);
    if (call.argumentCount == 0) {
      sink.flag('replyToMessage', true);
    } else {
      final channel = (await call.argument(0)).trim();
      final message = (await call.argument(1)).trim();
      if (channel.isEmpty || message.isEmpty) {
        throw BdfdNativeError(
          'Reply channel and message are required.',
          call.location,
        );
      }
      sink.flag('targetType', 'reply');
      sink.flag('channelId', channel);
      sink.flag('messageId', message);
    }
    return '';
  });
  add('sendmessage', 1, 2, (call) async {
    final text = await call.argument(0);
    final flag = call.argumentCount > 1
        ? (await call.argument(1)).trim().toLowerCase()
        : 'no';
    if (!const ['yes', 'no', 'true', 'false'].contains(flag)) {
      throw BdfdNativeError(
        'Return message ID must be yes or no.',
        call.location,
      );
    }
    if (text.trim().isEmpty) {
      throw BdfdNativeError('Message text is required.', call.location);
    }
    final sink = output(call);
    // BDFD sends a distinct channel message. It neither consumes the main
    // response draft nor updates an already acknowledged interaction response.
    final id = await sink.send(
      BotMessageRequest(
        destination: BotMessageDestination.channel,
        payload: {
          'content': text,
          'targetType': 'channel',
          if (sink.channelId != null) 'channelId': sink.channelId,
          ...sink.mentions,
        },
      ),
      call.context,
      call.location,
    );
    return _yes(flag) ? id : '';
  });
  add('channelsendmessage', 2, 3, (call) async {
    final channel = (await call.argument(0)).trim();
    final content = await call.argument(1);
    final replyId = call.argumentCount > 2 ? await call.argument(2) : '';
    if (channel.isEmpty || content.trim().isEmpty) {
      throw BdfdNativeError('Channel and content are required.', call.location);
    }
    final sink = output(call);
    await sink.flush(call.context, call.location);
    await sink.send(
      BotMessageRequest(
        destination: BotMessageDestination.channel,
        payload: {
          'channelId': channel,
          'content': content,
          'targetType': replyId.isEmpty ? 'channel' : 'reply',
          if (replyId.isNotEmpty) 'messageId': replyId,
        },
      ),
      call.context,
      call.location,
    );
    return '';
  });
  add('usechannel', 1, 1, (call) async {
    final channel = (await call.argument(0)).trim();
    if (channel.isEmpty) {
      throw BdfdNativeError('Channel is required.', call.location);
    }
    final sink = output(call);
    await sink.flush(call.context, call.location);
    sink.channelId = channel;
    return '';
  });
  // Wiki: $sendEmbedMessage[Channel ID;Content;(Title;Title URL;Description;
  // Color hex;Author;Author icon;Footer;Footer icon;Thumbnail;Image;
  // Add timestamp?;Return ID?)]. Every field after Content is vacantable.
  add('sendembedmessage', 2, 14, (call) async {
    final channel = (await call.argument(0)).trim();
    final content = await call.argument(1);
    if (channel.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(channel)) {
      throw BdfdNativeError('Invalid Discord ID.', call.location);
    }
    Future<String> field(int index) async =>
        index < call.argumentCount ? await call.argument(index) : '';
    Future<bool> flag(int index, String name) async {
      final raw = (await field(index)).trim().toLowerCase();
      if (raw.isEmpty) return false;
      if (!const ['yes', 'no', 'true', 'false'].contains(raw)) {
        throw BdfdNativeError('$name must be yes or no.', call.location);
      }
      return _yes(raw);
    }

    final title = await field(2),
        titleUrl = await field(3),
        description = await field(4),
        rawColor = (await field(5)).trim(),
        author = await field(6),
        authorIcon = await field(7),
        footer = await field(8),
        footerIcon = await field(9),
        thumbnail = await field(10),
        image = await field(11);
    final timestamp = await flag(12, 'Add timestamp');
    final returnId = await flag(13, 'Return ID');
    boundedText(call, title, 256);
    boundedText(call, description, 4096);
    boundedText(call, author, 256);
    boundedText(call, footer, 2048);
    final embed = <String, dynamic>{
      if (title.isNotEmpty) 'title': title,
      if (title.isNotEmpty && titleUrl.isNotEmpty) 'url': titleUrl,
      if (description.isNotEmpty) 'description': description,
      if (rawColor.isNotEmpty)
        'color': RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(rawColor)
            ? '#${rawColor.replaceFirst('#', '')}'
            : rawColor,
      if (author.isNotEmpty)
        'author': {
          'name': author,
          if (authorIcon.isNotEmpty) 'icon_url': authorIcon,
        },
      if (footer.isNotEmpty)
        'footer': {
          'text': footer,
          if (footerIcon.isNotEmpty) 'icon_url': footerIcon,
        },
      if (thumbnail.isNotEmpty) 'thumbnail': {'url': thumbnail},
      if (image.isNotEmpty) 'image': {'url': image},
      if (timestamp)
        'timestamp': call.context.time.instant.toUtc().toIso8601String(),
    };
    final sink = output(call);
    await sink.flush(call.context, call.location);
    final id = await sink.send(
      BotMessageRequest(
        destination: BotMessageDestination.channel,
        payload: {
          'channelId': channel,
          'content': content,
          'embeds': embed.isEmpty ? <Map<String, dynamic>>[] : [embed],
          'targetType': 'channel',
          ...sink.mentions,
        },
      ),
      call.context,
      call.location,
    );
    return returnId ? id : '';
  });
  return functions;
}

bool _yes(String value) =>
    const ['true', 'yes', '1'].contains(value.trim().toLowerCase());

bool _isRichComponentRow(Map<String, dynamic> row) {
  if (row['type'] != 'actionRow') return true;
  const interactive = {
    'button',
    'stringSelect',
    'userSelect',
    'roleSelect',
    'mentionableSelect',
    'channelSelect',
  };
  return ((row['components'] as List?) ?? const []).any(
    (child) => child is Map && !interactive.contains(child['type']),
  );
}

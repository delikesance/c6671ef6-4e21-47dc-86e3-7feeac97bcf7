import '../../services/bot_webhook_service.dart';
import 'program.dart';
import 'runtime.dart';

final _states = Expando<BdfdWebhookState>();
BdfdWebhookState bdfdWebhookState(BdfdContext context) =>
    _states[context] ??= BdfdWebhookState();

class BdfdWebhookState {
  final Map<String, Map<String, dynamic>> pending = {};
  Map<String, dynamic> draft(BotWebhookReference webhook) =>
      pending.putIfAbsent(webhook.url, () => {});
  Map<String, dynamic> take(BotWebhookReference webhook) =>
      pending.remove(webhook.url) ?? {};
  void discard() => pending.clear();
  Future<void> flush(BotWebhookService service, BdfdContext context) async {
    final requests = Map<String, Map<String, dynamic>>.from(pending);
    discard();
    for (final request in requests.entries) {
      context.budget.check();
      if (_hasMessage(request.value)) {
        await context.budget.run(
          () => service.send(
            BotWebhookReference.parse(request.key),
            request.value,
            budget: context.budget,
          ),
        );
      }
    }
  }
}

bool _hasMessage(Map<String, dynamic> payload) =>
    (payload['content'] as String? ?? '').isNotEmpty ||
    ((payload['embed'] as Map?)?.keys.any(
          (key) => key != 'color' && key != 'timestamp',
        ) ??
        false);

Map<String, BdfdNativeFunction> bdfdWebhookFunctions(
  BotWebhookService service,
) {
  Future<BotWebhookReference> reference(BdfdInvocation call) async {
    try {
      return BotWebhookReference.parse(await call.argument(0));
    } on FormatException {
      throw BdfdNativeError('Invalid Discord webhook URL.', call.location);
    }
  }

  String text(
    String value,
    int limit,
    BdfdInvocation call, {
    bool required = false,
  }) {
    if (required && value.isEmpty || value.length > limit) {
      throw BdfdNativeError(
        'Webhook text must contain ${required ? "1" : "0"}–$limit characters.',
        call.location,
      );
    }
    return value;
  }

  String url(String value, BdfdInvocation call) {
    try {
      webhookImageUrl(value);
      return value;
    } on ArgumentError {
      throw BdfdNativeError('An HTTP(S) URL is required.', call.location);
    }
  }

  int color(String value, BdfdInvocation call) {
    final hex = value.startsWith('#');
    final result = hex
        ? int.tryParse(value.substring(1), radix: 16)
        : (RegExp(r'^[0-9]+$').hasMatch(value)
              ? int.tryParse(value)
              : int.tryParse(value, radix: 16));
    if (result == null || result < 0 || result > 0xffffff) {
      throw BdfdNativeError('Invalid webhook color.', call.location);
    }
    return result;
  }

  void validate(Map<String, dynamic> payload, BdfdInvocation call) {
    final embed = payload['embed'] as Map? ?? const {};
    final length =
        (embed['title'] as String? ?? '').length +
        (embed['description'] as String? ?? '').length +
        ((embed['author'] as Map?)?['name'] as String? ?? '').length +
        ((embed['footer'] as Map?)?['text'] as String? ?? '').length;
    if (length > 6000) {
      throw BdfdNativeError(
        'Webhook embed text exceeds 6000 characters.',
        call.location,
      );
    }
  }

  BdfdNativeFunction setter(String field, int limit) => BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 2,
    handler: (call) async {
      final ref = await reference(call);
      final value = text(await call.argument(1), limit, call, required: true);
      final draft = bdfdWebhookState(call.context).draft(ref);
      if (field == 'content') {
        draft[field] = value;
      } else {
        final embed =
            draft.putIfAbsent('embed', () => <String, dynamic>{}) as Map;
        embed[field] = field == 'footer' ? {'text': value} : value;
      }
      validate(draft, call);
      return '';
    },
  );
  return {
    'webhookcreate': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 3,
      handler: (call) async {
        final raw = (await call.argument(0)).trim();
        final id = RegExp(r'^[0-9]+$').hasMatch(raw) ? int.tryParse(raw) : null;
        if (id == null || id <= 0) {
          throw BdfdNativeError('Invalid channel ID.', call.location);
        }
        final name = await call.argument(1);
        validateWebhookName(name);
        final avatar = call.argumentCount == 3 ? await call.argument(2) : '';
        if (avatar.isNotEmpty) url(avatar, call);
        return call.context.budget.run(
          () =>
              service.create('$id', name, avatar, budget: call.context.budget),
        );
      },
    ),
    'webhookdelete': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final ref = await reference(call);
        await call.context.budget.run(
          () => service.delete(ref, budget: call.context.budget),
        );
        bdfdWebhookState(call.context).take(ref);
        return '';
      },
    ),
    'webhookusername': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) async {
        final ref = await reference(call);
        final name = await call.argument(1);
        validateWebhookName(name);
        await call.context.budget.run(
          () => service.update(ref, name: name, budget: call.context.budget),
        );
        return '';
      },
    ),
    'webhookavatarurl': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) async {
        final ref = await reference(call);
        final avatar = url(await call.argument(1), call);
        await call.context.budget.run(
          () => service.update(
            ref,
            avatarUrl: avatar,
            budget: call.context.budget,
          ),
        );
        return '';
      },
    ),
    'webhooktitle': setter('title', 256),
    'webhookdescription': setter('description', 4096),
    'webhookfooter': setter('footer', 2048),
    'webhookcontent': setter('content', 2000),
    'webhookcolor': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) async {
        final ref = await reference(call);
        final value = color(await call.argument(1), call);
        final draft = bdfdWebhookState(call.context).draft(ref);
        (draft.putIfAbsent('embed', () => <String, dynamic>{})
                as Map)['color'] =
            value;
        return '';
      },
    ),
    'webhooksend': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 13,
      handler: (call) async {
        final ref = await reference(call);
        final supplied = <String>[];
        for (var i = 1; i < call.argumentCount; i++) {
          supplied.add(await call.argument(i));
        }
        // Detach before effects; a failed send cannot replay buffered content.
        final draft = bdfdWebhookState(call.context).take(ref);
        final embed =
            draft.putIfAbsent('embed', () => <String, dynamic>{}) as Map;
        String at(int i) => i < supplied.length ? supplied[i] : '';
        // Content is vacantable: an empty value keeps content staged by
        // $webhookContent instead of erasing it.
        if (at(0).isNotEmpty) draft['content'] = text(at(0), 2000, call);
        if (at(1).isNotEmpty) embed['title'] = text(at(1), 256, call);
        if (at(2).isNotEmpty) embed['url'] = url(at(2), call);
        if (at(3).isNotEmpty) embed['description'] = text(at(3), 4096, call);
        if (at(4).isNotEmpty) embed['color'] = color(at(4), call);
        if (at(5).isNotEmpty) {
          embed['author'] = {
            'name': text(at(5), 256, call),
            if (at(6).isNotEmpty) 'icon_url': url(at(6), call),
          };
        }
        if (at(7).isNotEmpty) {
          embed['footer'] = {
            'text': text(at(7), 2048, call),
            if (at(8).isNotEmpty) 'icon_url': url(at(8), call),
          };
        }
        if (at(9).isNotEmpty) embed['thumbnail'] = url(at(9), call);
        if (at(10).isNotEmpty) embed['image'] = url(at(10), call);
        if (at(11).isNotEmpty) {
          final flag = at(11).toLowerCase();
          if (!{'yes', 'no', 'true', 'false'}.contains(flag)) {
            throw BdfdNativeError('Invalid timestamp boolean.', call.location);
          }
          if (flag == 'yes' || flag == 'true') {
            embed['timestamp'] = call.context.time.instant.toIso8601String();
          }
        }
        validate(draft, call);
        if (!_hasMessage(draft)) {
          throw BdfdNativeError(
            'Webhook message cannot be empty.',
            call.location,
          );
        }
        await call.context.budget.run(
          () => service.send(ref, draft, budget: call.context.budget),
        );
        return '';
      },
    ),
  };
}

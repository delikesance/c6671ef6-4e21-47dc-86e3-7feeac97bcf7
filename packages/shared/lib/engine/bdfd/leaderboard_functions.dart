import '../../bot/bot_data_store.dart';
import '../../services/bot_guild_query_service.dart';
import '../../services/bot_user_query_service.dart';
import 'message_functions.dart' show BdfdMessageOutput;
import 'program.dart';
import 'runtime.dart';

class _Entry {
  const _Entry(this.id, this.value);
  final String id;
  final num value;
}

/// Leaderboards rank the persisted variable index for one scope. Wiki:
/// $globalUserLeaderboard / $userLeaderboard / $serverLeaderboard[Variable;
/// (Sort)] fill the embed description with the top ten as "N. Name - value";
/// $getLeaderboardPosition[Type;Name;Sort;(User ID)] and
/// $getLeaderboardValue[Type;Name;Sort;Position;(Return type)] read ranks.
Map<String, BdfdNativeFunction> bdfdLeaderboardFunctions({
  required BotDataStore store,
  required String botId,
  bool legacyUserVariables = false,
  BotUserQueryService? users,
  BotGuildQueryService? guilds,
}) {
  String normalizeType(BdfdInvocation call, String raw) {
    final type = raw.trim().toLowerCase();
    if (!const ['user', 'globaluser', 'server'].contains(type)) {
      throw BdfdNativeError(
        'Variable type must be user, globalUser or server.',
        call.location,
      );
    }
    return type;
  }

  bool descending(BdfdInvocation call, String raw, {bool required = false}) {
    final sort = raw.trim().toLowerCase();
    if (sort.isEmpty && !required) return true;
    if (sort == 'desc') return true;
    if (sort == 'asc') return false;
    throw BdfdNativeError('Sort type must be asc or desc.', call.location);
  }

  Future<List<_Entry>> ranking(
    BdfdInvocation call,
    String type,
    String name,
    bool desc,
  ) async {
    final key = name.trim();
    if (key.isEmpty) {
      throw BdfdNativeError('A variable name is required.', call.location);
    }
    final scope = switch (type) {
      'server' => 'guild',
      'globaluser' => 'user',
      _ => legacyUserVariables ? 'user' : 'guildMember',
    };
    final guild = call.context.variables['guild.id'] ?? '';
    final entries = <_Entry>[];
    var offset = 0;
    while (true) {
      call.context.budget.check();
      final page = await call.context.budget.run(
        () => store.queryScopedVariableIndex(
          botId,
          scope,
          key,
          offset: offset,
          limit: 500,
        ),
      );
      final items = (page['items'] as List? ?? const []).whereType<Map>();
      var count = 0;
      for (final item in items) {
        count++;
        var id = (item['contextId'] ?? '').toString();
        if (scope == 'guildMember') {
          final split = id.split(':');
          if (split.length != 2 || split.first != guild) continue;
          id = split.last;
        }
        final value = num.tryParse('${item['value']}');
        if (value == null) continue;
        entries.add(_Entry(id, value));
      }
      offset += count;
      final total = (page['total'] as num?)?.toInt() ?? offset;
      if (count == 0 || offset >= total || offset >= 20000) break;
    }
    entries.sort(
      (a, b) => desc ? b.value.compareTo(a.value) : a.value.compareTo(b.value),
    );
    return entries;
  }

  String format(num value) =>
      value == value.truncate() ? '${value.truncate()}' : '$value';

  Future<String> label(BdfdInvocation call, String type, String id) async {
    try {
      if (type == 'server') {
        final guild = guilds == null
            ? null
            : await call.context.budget.run(
                () => guilds.guild(guildId: id, budget: call.context.budget),
              );
        return guild?.name ?? id;
      }
      final user = users == null
          ? null
          : await call.context.budget.run(
              () => users.user(id, budget: call.context.budget),
            );
      return user?.username ?? id;
    } on BdfdNativeError {
      rethrow;
    } on StateError {
      return id;
    }
  }

  BdfdNativeFunction board(String type) => BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 2,
    handler: (call) async {
      final name = await call.argument(0);
      final desc = descending(
        call,
        call.argumentCount > 1 ? await call.argument(1) : '',
      );
      final rows = (await ranking(call, type, name, desc)).take(10).toList();
      final lines = <String>[];
      for (var index = 0; index < rows.length; index++) {
        lines.add(
          '${index + 1}. ${await label(call, type, rows[index].id)} - ${format(rows[index].value)}',
        );
      }
      final sink = call.context.output;
      if (sink is! BdfdMessageOutput) {
        throw BdfdNativeError('No message service configured.', call.location);
      }
      sink.embed(0)['description'] = lines.join('\n');
      return '';
    },
  );

  return {
    'globaluserleaderboard': board('globaluser'),
    'userleaderboard': board('user'),
    'serverleaderboard': board('server'),
    'getleaderboardposition': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 4,
      handler: (call) async {
        final type = normalizeType(call, await call.argument(0));
        if (type == 'server') {
          throw BdfdNativeError(
            'Variable type must be user or globalUser.',
            call.location,
          );
        }
        final name = await call.argument(1);
        final desc = descending(call, await call.argument(2), required: true);
        var target = call.argumentCount > 3
            ? (await call.argument(3)).trim()
            : '';
        if (target.isEmpty) {
          target =
              call.context.variables['author.id'] ??
              call.context.variables['user.id'] ??
              '';
        }
        final rows = await ranking(call, type, name, desc);
        final index = rows.indexWhere((row) => row.id == target);
        return index < 0 ? '' : '${index + 1}';
      },
    ),
    'getleaderboardvalue': BdfdNativeFunction(
      minArguments: 4,
      maxArguments: 5,
      handler: (call) async {
        final type = normalizeType(call, await call.argument(0));
        final name = await call.argument(1);
        final desc = descending(call, await call.argument(2), required: true);
        final position = int.tryParse((await call.argument(3)).trim());
        if (position == null || position < 1) {
          throw BdfdNativeError(
            'Position must be a positive integer.',
            call.location,
          );
        }
        final kind = call.argumentCount > 4
            ? (await call.argument(4)).trim().toLowerCase()
            : '';
        if (!const ['', 'id', 'value', 'none'].contains(kind)) {
          throw BdfdNativeError(
            'Return type must be id, value or none.',
            call.location,
          );
        }
        final rows = await ranking(call, type, name, desc);
        if (position > rows.length) return '';
        final row = rows[position - 1];
        return switch (kind) {
          'id' => row.id,
          'value' => format(row.value),
          _ => '${await label(call, type, row.id)} - ${format(row.value)}',
        };
      },
    ),
  };
}

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

/// Guild info fetched via REST API.
class _GuildInfo {
  final String id;
  final String name;
  final String? iconHash;
  final bool isOwner;
  final int? approximateMemberCount;
  final List<String> features;

  const _GuildInfo({
    required this.id,
    required this.name,
    this.iconHash,
    this.isOwner = false,
    this.approximateMemberCount,
    this.features = const [],
  });

  String? get iconUrl => iconHash != null
      ? 'https://cdn.discordapp.com/icons/$id/$iconHash.png'
      : null;
}

class _ChannelInfo {
  final String id;
  final String name;
  final int type;
  final String? parentId;

  const _ChannelInfo({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
  });
}

class _MessageInfo {
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime timestamp;
  final List<_AttachmentInfo> attachments;
  final List<_EmbedInfo> embeds;

  const _MessageInfo({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.timestamp,
    this.attachments = const [],
    this.embeds = const [],
  });
}

class _AttachmentInfo {
  final String url;
  final String? filename;
  final int? width;
  final int? height;

  const _AttachmentInfo({required this.url, this.filename, this.width, this.height});
}

class _EmbedInfo {
  final String? title;
  final String? description;
  final String? url;
  final int? color;

  const _EmbedInfo({this.title, this.description, this.url, this.color});
}

/// Servers page — 100% REST API, no gateway.
class GuildsPage extends StatefulWidget {
  final String botId;

  const GuildsPage({super.key, required this.botId});

  @override
  State<GuildsPage> createState() => _GuildsPageState();
}

class _GuildsPageState extends State<GuildsPage> {
  final _leavingGuilds = <String>{};
  List<_GuildInfo>? _guilds;
  bool _loading = true;
  String? _error;
  NyxxRest? _restClient;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _restClient?.close();
    super.dispose();
  }

  Future<NyxxRest> _ensureClient() async {
    if (_restClient != null) return _restClient!;
    final appManager = AppManager();
    final appData = await appManager.getApp(widget.botId);
    final token = (appData['token'] ?? '').toString().trim();
    if (token.isEmpty) throw Exception('No bot token configured');
    _restClient = await Nyxx.connectRest(token);
    return _restClient!;
  }

  Future<List<_GuildInfo>> _fetchGuilds(NyxxRest rest) async {
    final route = HttpRoute()
      ..add(HttpRoutePart('users'))
      ..add(HttpRoutePart('@me'))
      ..add(HttpRoutePart('guilds'));
    final response = await rest.httpHandler.executeSafe(
      BasicRequest(route, method: 'GET', queryParameters: {'with_counts': 'true'}),
    );
    final rawList = response.jsonBody as List;
    return rawList.map((raw) {
      final map = raw as Map<String, Object?>;
      return _GuildInfo(
        id: map['id'] as String,
        name: map['name'] as String,
        iconHash: map['icon'] as String?,
        isOwner: map['owner'] as bool? ?? false,
        approximateMemberCount: map['approximate_member_count'] as int?,
        features: (map['features'] as List?)?.cast<String>() ?? [],
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<_ChannelInfo>> _fetchChannels(NyxxRest rest, String guildId) async {
    final route = HttpRoute()
      ..add(HttpRoutePart('guilds'))
      ..add(HttpRoutePart(guildId))
      ..add(HttpRoutePart('channels'));
    final response = await rest.httpHandler.executeSafe(BasicRequest(route, method: 'GET'));
    final rawList = response.jsonBody as List;
    return rawList.map((raw) {
      final map = raw as Map<String, Object?>;
      return _ChannelInfo(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as int,
        parentId: map['parent_id'] as String?,
      );
    }).toList();
  }

  static Future<List<_MessageInfo>> fetchMessages(NyxxRest rest, String channelId) async {
    final route = HttpRoute()
      ..add(HttpRoutePart('channels'))
      ..add(HttpRoutePart(channelId))
      ..add(HttpRoutePart('messages'));
    final response = await rest.httpHandler.executeSafe(
      BasicRequest(route, method: 'GET', queryParameters: {'limit': '50'}),
    );
    final rawList = response.jsonBody as List;
    return rawList.reversed.map((raw) {
      final map = raw as Map<String, Object?>;
      final author = map['author'] as Map<String, Object?>?;
      final attachments = (map['attachments'] as List?)
          ?.map((a) => _AttachmentInfo(
                url: (a as Map)['url'] as String,
                filename: a['filename'] as String?,
                width: a['width'] as int?,
                height: a['height'] as int?,
              ))
          .toList() ?? [];
      final embeds = (map['embeds'] as List?)
          ?.map((e) => _EmbedInfo(
                title: (e as Map)['title'] as String?,
                description: e['description'] as String?,
                url: e['url'] as String?,
                color: e['color'] as int?,
              ))
          .toList() ?? [];
      return _MessageInfo(
        id: map['id'] as String,
        authorName: author?['global_name'] as String? ?? author?['username'] as String? ?? 'Unknown',
        authorAvatarUrl: author?['avatar'] != null
            ? 'https://cdn.discordapp.com/avatars/${author!['id']}/${author['avatar']}.png'
            : null,
        content: map['content'] as String? ?? '',
        timestamp: DateTime.parse(map['timestamp'] as String),
        attachments: attachments,
        embeds: embeds,
      );
    }).toList();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rest = await _ensureClient();
      final guilds = await _fetchGuilds(rest);
      if (mounted) setState(() { _guilds = guilds; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _leaveGuild(_GuildInfo info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Server'),
        content: Text('Leave "${info.name}"?\nThe bot will be removed from this server. '
            'You can re-invite it later from the Discord developer portal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.tr.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _leavingGuilds.add(info.id));
    try {
      final rest = await _ensureClient();
      final route = HttpRoute()
        ..add(HttpRoutePart('users'))
        ..add(HttpRoutePart('@me'))
        ..add(HttpRoutePart('guilds'))
        ..add(HttpRoutePart(info.id));
      await rest.httpHandler.executeSafe(BasicRequest(route, method: 'DELETE'));
      if (mounted) {
        setState(() {
          _leavingGuilds.remove(info.id);
          _guilds?.removeWhere((g) => g.id == info.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left "${info.name}".')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _leavingGuilds.remove(info.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e')),
        );
      }
    }
  }

  void _exploreGuild(_GuildInfo info) async {
    final rest = await _ensureClient();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _GuildExplorePage(info: info, rest: rest),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          if (_guilds != null && _guilds!.isNotEmpty)
            Text('${_guilds!.length} servers',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loading ? null : _fetch),
        ],
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 48, color: cs.error),
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: cs.error)),
        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: _fetch, child: const Text('Retry')),
      ]));
    }
    final guilds = _guilds ?? [];
    if (guilds.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.dns_outlined, size: 48, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        Text('The bot is not in any server.\nInvite it to a server to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: guilds.length,
        separatorBuilder: (_, i2) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final guild = guilds[i];
          final isLeaving = _leavingGuilds.contains(guild.id);
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: guild.iconUrl != null ? NetworkImage(guild.iconUrl!) : null,
              child: guild.iconUrl == null
                  ? Text(guild.name.substring(0, 1).toUpperCase()) : null,
            ),
            title: Text(guild.name),
            subtitle: Text([
              'ID: ${guild.id}',
              if (guild.approximateMemberCount != null) '~${guild.approximateMemberCount} members',
              if (guild.isOwner) '👑 Owner',
            ].join(' · '), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.info_outline, size: 20),
                  tooltip: 'Explore', onPressed: () => _exploreGuild(guild)),
              IconButton(
                icon: isLeaving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                tooltip: 'Leave',
                onPressed: isLeaving ? null : () => _leaveGuild(guild),
              ),
            ]),
          );
        },
      ),
    );
  }
}

/// Full-page Discord-like server explorer with sidebar and message view.
class _GuildExplorePage extends StatefulWidget {
  final _GuildInfo info;
  final NyxxRest rest;

  const _GuildExplorePage({required this.info, required this.rest});

  @override
  State<_GuildExplorePage> createState() => _GuildExplorePageState();
}

class _GuildExplorePageState extends State<_GuildExplorePage> {
  List<_ChannelInfo>? _channels;
  bool _loadingChannels = true;

  _ChannelInfo? _selectedChannel;
  List<_MessageInfo> _messages = [];
  bool _loadingMessages = false;
  bool _loadingOlder = false;
  bool _hasMore = true;

  final ScrollController _scrollCtrl = ScrollController();
  bool _didInitialScroll = false;

  static const _sidebarBg = Color(0xFF2B2D31);
  static const _sidebarW = 240.0;
  static const _channelColor = Color(0xFF949BA4);
  static const _categoryColor = Color(0xFF949BA4);
  static const _headerBg = Color(0xFF1E1F22);
  static const _chatBg = Color(0xFF313338);
  static const _messageHover = Color(0xFF2E3035);

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels <= 100 && !_loadingOlder && _hasMore) {
      _fetchOlderMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients && _messages.isNotEmpty && !_didInitialScroll) {
      _didInitialScroll = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _loadChannels() async {
    try {
      final route = HttpRoute()
        ..add(HttpRoutePart('guilds'))
        ..add(HttpRoutePart(widget.info.id))
        ..add(HttpRoutePart('channels'));
      final response = await widget.rest.httpHandler.executeSafe(
        BasicRequest(route, method: 'GET'),
      );
      final rawList = response.jsonBody as List;
      final channels = rawList.map((raw) {
        final map = raw as Map<String, Object?>;
        return _ChannelInfo(
          id: map['id'] as String,
          name: map['name'] as String,
          type: map['type'] as int,
          parentId: map['parent_id'] as String?,
        );
      }).toList();
      if (mounted) setState(() { _channels = channels; _loadingChannels = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingChannels = false);
    }
  }

  Future<void> _selectChannel(_ChannelInfo ch) async {
    if (ch.type == 4) return; // category
    _didInitialScroll = false;
    setState(() {
      _selectedChannel = ch;
      _messages = [];
      _loadingMessages = true;
      _hasMore = true;
    });
    try {
      final msgs = await _GuildsPageState.fetchMessages(widget.rest, ch.id);
      if (mounted) {
        setState(() { _messages = msgs; _loadingMessages = false; _hasMore = msgs.length >= 50; });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _fetchOlderMessages() async {
    if (_selectedChannel == null || _messages.isEmpty || _loadingOlder) return;
    final oldestId = _messages.first.id;
    setState(() => _loadingOlder = true);
    try {
      final route = HttpRoute()
        ..add(HttpRoutePart('channels'))
        ..add(HttpRoutePart(_selectedChannel!.id))
        ..add(HttpRoutePart('messages'));
      final response = await widget.rest.httpHandler.executeSafe(
        BasicRequest(route, method: 'GET', queryParameters: {
          'limit': '50',
          'before': oldestId,
        }),
      );
      final rawList = response.jsonBody as List;
      // API returns newest first, reverse to chronological
      final older = rawList.reversed.map((raw) {
        final map = raw as Map<String, Object?>;
        final author = map['author'] as Map<String, Object?>?;
        return _MessageInfo(
          id: map['id'] as String,
          authorName: author?['global_name'] as String? ?? author?['username'] as String? ?? 'Unknown',
          authorAvatarUrl: author?['avatar'] != null
              ? 'https://cdn.discordapp.com/avatars/${author!['id']}/${author['avatar']}.png'
              : null,
          content: map['content'] as String? ?? '',
          timestamp: DateTime.parse(map['timestamp'] as String),
        );
      }).toList();
      if (mounted) {
        setState(() {
          _messages.insertAll(0, older);
          _loadingOlder = false;
          _hasMore = older.length >= 50;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  void _leaveGuild() {
    Navigator.pop(context);
    // Trigger leave from the parent page
    final pageState = context.findAncestorStateOfType<_GuildsPageState>();
    pageState?._leaveGuild(widget.info);
  }

  // ── Channel grouping helpers ──

  List<_ChannelInfo> get _textChannels {
    if (_channels == null) return [];
    return _channels!.where((c) => c.type != 4 && c.parentId == null).toList();
  }

  List<_ChannelInfo> _categoryChildren(String categoryId) {
    if (_channels == null) return [];
    return _channels!.where((c) => c.parentId == categoryId && c.type != 4).toList();
  }

  List<_ChannelInfo> get _categories {
    if (_channels == null) return [];
    return _channels!.where((c) => c.type == 4).toList();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final isLandscape = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _chatBg,
      appBar: AppBar(
        backgroundColor: _headerBg,
        title: Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: info.iconUrl != null ? NetworkImage(info.iconUrl!) : null,
            child: info.iconUrl == null
                ? Text(info.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: Colors.white))
                : null,
          ),
          const SizedBox(width: 10),
          Text(info.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          if (info.approximateMemberCount != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.people_alt_outlined, size: 16),
                const SizedBox(width: 4),
                Text('~${info.approximateMemberCount}', style: const TextStyle(fontSize: 13)),
              ]),
            ),
          if (info.isOwner)
            const Padding(padding: EdgeInsets.only(right: 12),
                child: Text('👑', style: TextStyle(fontSize: 16))),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) { if (v == 'leave') _leaveGuild(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'leave',
                child: Text('Leave Server', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: isLandscape ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  /// Desktop/tablet: sidebar + chat side by side.
  Widget _buildWideLayout() {
    return Row(children: [
      SizedBox(width: _sidebarW, child: _buildSidebar()),
      const VerticalDivider(width: 1, color: Color(0xFF3F4147)),
      Expanded(child: _buildChatArea()),
    ]);
  }

  /// Phone: sidebar as drawer or full-screen, chat behind.
  Widget _buildNarrowLayout() {
    if (_selectedChannel == null) {
      return _buildSidebar();
    }
    return Column(children: [
      // Channel header bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: _headerBg,
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => setState(() => _selectedChannel = null),
          ),
          const SizedBox(width: 4),
          Icon(_channelIcon(_selectedChannel!.type), size: 18, color: _channelColor),
          const SizedBox(width: 6),
          Text(_selectedChannel!.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      ),
      Expanded(child: _buildChatArea()),
    ]);
  }

  // ── Sidebar ──

  Widget _buildSidebar() {
    return Container(
      color: _sidebarBg,
      child: _loadingChannels
          ? const Center(child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)))
          : ListView(padding: const EdgeInsets.only(top: 8), children: [
              // Uncategorized
              if (_textChannels.isNotEmpty)
                ..._textChannels.map(_buildChannelTile),
              // Categories
              if (_categories.isNotEmpty)
                ..._categories.map((cat) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Row(children: [
                            const Icon(Icons.expand_more, size: 14, color: _categoryColor),
                            const SizedBox(width: 2),
                            Text(cat.name.toUpperCase(),
                                style: const TextStyle(color: _categoryColor, fontSize: 11,
                                    fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          ]),
                        ),
                        ..._categoryChildren(cat.id).map(_buildChannelTile),
                      ],
                    )),
              const SizedBox(height: 80),
            ]),
    );
  }

  Widget _buildChannelTile(_ChannelInfo ch) {
    final isSelected = _selectedChannel?.id == ch.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: isSelected ? const Color(0xFF404249) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _selectChannel(ch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(children: [
              Icon(_channelIcon(ch.type), size: 18,
                  color: isSelected ? Colors.white : _channelColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(ch.name,
                    style: TextStyle(
                        color: isSelected ? Colors.white : _channelColor, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Chat area ──

  Widget _buildChatArea() {
    if (_selectedChannel == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.tag, size: 48, color: _channelColor),
        const SizedBox(height: 12),
        const Text('Select a channel to view messages.',
            style: TextStyle(color: _channelColor)),
      ]));
    }

    if (_loadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty && !_loadingOlder) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.chat_bubble_outline, size: 48, color: _channelColor),
        const SizedBox(height: 12),
        Text('No messages in #${_selectedChannel!.name}.',
            style: const TextStyle(color: _channelColor)),
      ]));
    }

    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length + (_hasMore || _loadingOlder ? 1 : 0),
      itemBuilder: (ctx, i) {
        // reversed: index 0 = bottom. Loading indicator at end (visually top)
        if (i == _messages.length) {
          return _loadingOlder
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))))
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton(
                      onPressed: _fetchOlderMessages,
                      child: const Text('Load older messages',
                          style: TextStyle(color: _channelColor, fontSize: 12)),
                    ),
                  ),
                );
        }
        final msgIndex = _messages.length - 1 - i; // reverse index
        return _buildMessage(_messages[msgIndex]);
      },
    );
  }

  Widget _buildMessage(_MessageInfo msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          hoverColor: _messageHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: msg.authorAvatarUrl != null
                      ? NetworkImage(msg.authorAvatarUrl!) : null,
                  child: msg.authorAvatarUrl == null
                      ? Text(msg.authorName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 14, color: Colors.white))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(msg.authorName,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text(_formatTimestamp(msg.timestamp),
                            style: const TextStyle(color: _channelColor, fontSize: 11)),
                      ]),
                      if (msg.content.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _buildMessageContent(msg.content),
                      ],
                      // Attachments
                      if (msg.attachments.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...msg.attachments.map((a) => _buildAttachment(a)),
                      ],
                      // Embeds
                      if (msg.embeds.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...msg.embeds.map((e) => _buildEmbed(e)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(String content) {
    // Basic markdown: bold, italic, code, links
    final spans = <InlineSpan>[];
    final regex = RegExp(
      r'(\*\*(.+?)\*\*)|'     // bold
      r'(\*(.+?)\*)|'         // italic
      r'(```(.+?)```)|'       // code block
      r'(`(.+?)`)|'           // inline code
      r'(https?://\S+)',      // link
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(content)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: content.substring(lastEnd, match.start)));
      }
      lastEnd = match.end;

      if (match.group(2) != null) {
        // bold
        spans.add(TextSpan(text: match.group(2)!,
            style: const TextStyle(fontWeight: FontWeight.bold)));
      } else if (match.group(4) != null) {
        // italic
        spans.add(TextSpan(text: match.group(4)!,
            style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (match.group(6) != null) {
        // code block
        spans.add(TextSpan(text: match.group(6)!,
            style: const TextStyle(fontFamily: 'monospace', backgroundColor: Color(0xFF1E1F22))));
      } else if (match.group(8) != null) {
        // inline code
        spans.add(TextSpan(text: match.group(8)!,
            style: const TextStyle(fontFamily: 'monospace', backgroundColor: Color(0xFF2B2D31))));
      } else if (match.group(9) != null) {
        // link
        spans.add(TextSpan(text: match.group(9)!,
            style: const TextStyle(color: Color(0xFF00AFF4), decoration: TextDecoration.underline)));
      }
    }
    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFFDBDEE1), fontSize: 14, height: 1.4),
        children: spans,
      ),
    );
  }

  Widget _buildAttachment(_AttachmentInfo a) {
    final isImage = a.url.contains('.png') || a.url.contains('.jpg') ||
        a.url.contains('.jpeg') || a.url.contains('.gif') || a.url.contains('.webp');
    if (isImage) {
      final maxWidth = MediaQuery.of(context).size.width > 600 ? 300.0 : 200.0;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 250),
            child: Image.network(a.url, fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                      width: maxWidth, height: 150,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                }),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _sidebarBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.attach_file, size: 18, color: _channelColor),
        const SizedBox(width: 8),
        Text(a.filename ?? 'Attachment', style: const TextStyle(color: Color(0xFF00AFF4), fontSize: 13)),
      ]),
    );
  }

  Widget _buildEmbed(_EmbedInfo e) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _sidebarBg,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: e.color != null ? Color(e.color!) : _channelColor,
            width: 4,
          ),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (e.title != null)
          Text(e.title!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        if (e.description != null) ...[
          const SizedBox(height: 4),
          Text(e.description!, style: const TextStyle(color: _channelColor, fontSize: 13)),
        ],
      ]),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  IconData _channelIcon(int type) => switch (type) {
    0 || 5 => Icons.tag,
    2 || 13 => Icons.volume_up,
    15 => Icons.forum,
    _ => Icons.tag,
  };
}

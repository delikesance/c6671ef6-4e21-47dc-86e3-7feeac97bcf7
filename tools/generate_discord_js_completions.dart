// ignore_for_file: avoid_print
//
// Generates packages/app/assets/js_editor/discord_js_completions.json
// Run: dart run tools/generate_discord_js_completions.dart

import 'dart:convert';
import 'dart:io';

void main() {
  final data = _buildCompletionData();
  final json = const JsonEncoder.withIndent('  ').convert(data);

  final outFile = File(
    'packages/app/assets/js_editor/discord_js_completions.json',
  );
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync('$json\n');

  final globals = (data['globals'] as List).length;
  final exports = (data['discordExports'] as List).length;
  final members = data['members'] as Map<String, dynamic>;
  var memberCount = 0;
  for (final entry in members.entries) {
    memberCount += (entry.value as List).length;
  }
  print(
    'Wrote ${outFile.path}: $globals globals, $exports discord exports, '
    '${members.length} member groups, $memberCount member symbols',
  );
}

Map<String, dynamic> _buildCompletionData() {
  final members = <String, List<String>>{};

  void addMembers(String type, List<String> symbols) {
    members[type] = {...(members[type] ?? []), ...symbols}.toList()..sort();
  }

  // --- JavaScript keywords & builtins ---
  const jsKeywords = [
    'async', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue',
    'debugger', 'default', 'delete', 'do', 'else', 'export', 'extends',
    'false', 'finally', 'for', 'function', 'if', 'import', 'in', 'instanceof',
    'let', 'new', 'null', 'of', 'return', 'static', 'super', 'switch', 'this',
    'throw', 'true', 'try', 'typeof', 'undefined', 'var', 'void', 'while',
    'with', 'yield',
  ];

  const jsBuiltins = [
    'Array', 'ArrayBuffer', 'BigInt', 'Boolean', 'DataView', 'Date', 'Error',
    'EvalError', 'Float32Array', 'Float64Array', 'Function', 'Infinity',
    'Int16Array', 'Int32Array', 'Int8Array', 'Intl', 'JSON', 'Map', 'Math',
    'NaN', 'Number', 'Object', 'Promise', 'Proxy', 'RangeError', 'ReferenceError',
    'Reflect', 'RegExp', 'Set', 'String', 'Symbol', 'SyntaxError', 'TypeError',
    'URIError', 'Uint16Array', 'Uint32Array', 'Uint8Array', 'Uint8ClampedArray',
    'WeakMap', 'WeakSet', 'console', 'decodeURI', 'decodeURIComponent',
    'encodeURI', 'encodeURIComponent', 'eval', 'fetch', 'isFinite', 'isNaN',
    'parseFloat', 'parseInt', 'require', 'setInterval', 'setTimeout',
  ];

  // --- Bot Creator script globals ---
  const botCreatorGlobals = [
    'interaction', 'message', 'client', 'guild', 'channel', 'member', 'config',
    'variables', 'webhook',
  ];

  addMembers('BotCreatorInteraction', [
    'commandName', 'reply', 'editReply', 'deferReply', 'followUp', 'options',
    'isCommand', 'isButton', 'isSelectMenu', 'isModalSubmit', 'isAutocomplete',
    'user', 'member', 'guild', 'channel', 'createdAt', 'createdTimestamp',
    'id', 'token', 'type', 'deferred', 'replied', 'ephemeral',
  ]);

  addMembers('options', [
    'getString', 'getInteger', 'getNumber', 'getBoolean', 'getUser',
    'getMember', 'getChannel', 'getRole', 'getAttachment', 'getMentionable',
    'getSubcommand', 'getSubcommandGroup', 'data', 'resolved',
  ]);

  addMembers('BotCreatorMessage', [
    'content', 'author', 'reply', 'id', 'channel', 'guild', 'createdAt',
    'createdTimestamp', 'editable', 'pinned', 'system',
  ]);

  addMembers('author', ['id', 'username', 'tag', 'bot', 'discriminator']);

  addMembers('config', ['get', 'set', 'has', 'delete', 'clear', 'keys', 'values']);

  addMembers('variables', ['get', 'set', 'has', 'delete', 'clear', 'keys', 'values']);

  addMembers('webhook', ['path', 'payload', 'headers']);

  // --- discord.js v14 exports ---
  const discordExports = [
    'ActivityType', 'ApplicationCommandOptionType', 'ApplicationCommandType',
    'Attachment', 'AttachmentBuilder', 'AuditLogEvent', 'AutocompleteInteraction',
    'BaseChannel', 'BaseGuild', 'BaseGuildTextChannel', 'BaseGuildVoiceChannel',
    'ButtonBuilder', 'ButtonComponent', 'ButtonInteraction', 'ButtonStyle',
    'CategoryChannel', 'ChannelSelectMenuBuilder', 'ChannelType',
    'ChatInputCommandInteraction', 'Client', 'Collection', 'Colors',
    'CommandInteraction', 'ComponentType', 'ContextMenuCommandInteraction',
    'DMChannel', 'Embed', 'EmbedBuilder', 'Events', 'Formatters',
    'ForumChannel', 'GatewayIntentBits', 'Guild', 'GuildBan', 'GuildChannel',
    'GuildEmoji', 'GuildMember', 'GuildPreview', 'GuildScheduledEvent',
    'Integration', 'Interaction', 'InteractionCollector', 'InteractionType',
    'InteractionWebhook', 'Invite', 'InviteGuild', 'Message', 'MessageCollector',
    'MessageComponentInteraction', 'MessageFlags', 'MessagePayload',
    'MessageReaction', 'ModalBuilder', 'ModalSubmitInteraction', 'NewsChannel',
    'OAuth2Scopes', 'OverwriteType', 'PartialGroupDMChannel', 'Partials',
    'PermissionFlagsBits', 'PermissionsBitField', 'Presence', 'REST',
    'RateLimitError', 'ReactionCollector', 'ReactionEmoji', 'Role',
    'SelectMenuBuilder', 'SelectMenuInteraction', 'Shard', 'ShardClientUtil',
    'ShardingManager', 'SlashCommandBuilder', 'SnowflakeUtil', 'StageChannel',
    'StageInstance', 'Sticker', 'StringSelectMenuBuilder', 'TextChannel',
    'TextInputBuilder', 'ThreadChannel', 'ThreadMember', 'User', 'UserSelectMenuBuilder',
    'VoiceChannel', 'VoiceState', 'Webhook', 'WebhookClient', 'ActionRowBuilder',
    'MentionableSelectMenuBuilder', 'RoleSelectMenuBuilder', 'ContextMenuCommandBuilder',
    'GuildOnboarding', 'GuildOnboardingPrompt', 'AutoModerationActionExecution',
    'AutoModerationRule', 'ApplicationEmoji', 'BaseInteraction', 'Channel',
    'ClientApplication', 'ClientPresence', 'ClientUser', 'CommandInteractionOptionResolver',
    'Component', 'GuildAuditLogs', 'GuildAuditLogsEntry', 'GuildBanManager',
    'GuildChannelManager', 'GuildEmojiManager', 'GuildInviteManager',
    'GuildMemberManager', 'GuildMemberRoleManager', 'GuildScheduledEventManager',
    'GuildStickerManager', 'IntentsBitField', 'InviteStageInstance', 'MessageManager',
    'MessageMentions', 'NewsChannel', 'PartialTypes', 'PermissionOverwrites',
    'PresenceManager', 'ReactionManager', 'RoleManager', 'StageInstanceManager',
    'StickerPack', 'Sweepers', 'SystemChannelFlagsBitField', 'Team', 'TeamMember',
    'ThreadManager', 'ThreadOnlyChannel', 'Typing', 'UserManager', 'VoiceRegion',
    'Webhook', 'WelcomeChannel', 'Widget', 'WidgetMember',
  ];

  // --- discord.js member chains ---
  addMembers('Client', [
    'login', 'destroy', 'on', 'once', 'off', 'emit', 'removeListener',
    'removeAllListeners', 'guilds', 'users', 'channels', 'emojis', 'application',
    'user', 'ws', 'rest', 'token', 'isReady', 'readyAt', 'uptime', 'ping',
    'generateInvite', 'fetchInvites', 'sweepers', 'voice', 'shard',
  ]);

  addMembers('Guild', [
    'id', 'name', 'icon', 'ownerId', 'members', 'channels', 'roles', 'emojis',
    'stickers', 'bans', 'invites', 'scheduledEvents', 'fetch', 'delete',
    'edit', 'setName', 'setIcon', 'leave', 'memberCount', 'createdAt',
    'available', 'vanityURLCode', 'description', 'preferredLocale', 'shard',
    'commands', 'autoModerationRules', 'soundboardSounds',
  ]);

  addMembers('GuildMember', [
    'id', 'user', 'nickname', 'displayName', 'roles', 'permissions', 'guild',
    'joinedAt', 'premiumSince', 'manageable', 'bannable', 'kickable',
    'send', 'edit', 'kick', 'ban', 'timeout', 'fetch', 'displayHexColor',
    'voice', 'presence', 'toString',
  ]);

  addMembers('User', [
    'id', 'username', 'tag', 'discriminator', 'bot', 'system', 'createdAt',
    'displayAvatarURL', 'avatar', 'banner', 'fetch', 'send', 'createDM',
    'toString', 'globalName', 'accentColor', 'flags',
  ]);

  addMembers('Message', [
    'id', 'content', 'author', 'channel', 'guild', 'member', 'createdAt',
    'editedAt', 'reply', 'edit', 'delete', 'react', 'pin', 'unpin', 'fetch',
    'startThread', 'crosspost', 'forward', 'attachments', 'embeds', 'mentions',
    'reactions', 'components', 'flags', 'reference', 'interaction', 'poll',
    'createMessageComponentCollector', 'awaitMessageComponent', 'toJSON',
  ]);

  addMembers('TextChannel', [
    'id', 'name', 'type', 'guild', 'send', 'messages', 'createWebhook',
    'fetch', 'delete', 'edit', 'setName', 'setTopic', 'setRateLimitPerUser',
    'permissionOverwrites', 'members', 'threads', 'isTextBased', 'url',
    'createInvite', 'bulkDelete', 'createMessageCollector',
  ]);

  addMembers('Interaction', [
    'id', 'type', 'token', 'user', 'member', 'guild', 'channel', 'createdAt',
    'reply', 'editReply', 'followUp', 'deferReply', 'deleteReply', 'fetchReply',
    'isCommand', 'isButton', 'isSelectMenu', 'isModalSubmit', 'isAutocomplete',
    'isChatInputCommand', 'isContextMenuCommand', 'isMessageComponent',
    'isRepliable', 'deferred', 'replied', 'ephemeral', 'webhook', 'inGuild',
    'inCachedGuildChannel', 'applicationId', 'locale', 'guildLocale',
  ]);

  addMembers('CommandInteraction', [
    'commandId', 'commandName', 'commandType', 'command', 'options', 'channelId',
    'guildId', 'targetId', 'targetType', 'reply', 'editReply', 'deferReply',
    'followUp', 'deleteReply', 'fetchReply', 'isChatInputCommand',
  ]);

  addMembers('EmbedBuilder', [
    'setTitle', 'setDescription', 'setURL', 'setColor', 'setTimestamp',
    'setFooter', 'setImage', 'setThumbnail', 'setAuthor', 'addFields',
    'setFields', 'spliceFields', 'setVideo', 'setProvider', 'setData',
    'toJSON', 'length', 'data',
  ]);

  addMembers('SlashCommandBuilder', [
    'setName', 'setDescription', 'setNameLocalization', 'setDescriptionLocalization',
    'setNSFW', 'setDefaultMemberPermissions', 'setDMPermission', 'addStringOption',
    'addIntegerOption', 'addNumberOption', 'addBooleanOption', 'addUserOption',
    'addChannelOption', 'addRoleOption', 'addMentionableOption', 'addAttachmentOption',
    'addSubcommand', 'addSubcommandGroup', 'toJSON', 'name', 'description', 'options',
  ]);

  addMembers('ButtonBuilder', [
    'setCustomId', 'setLabel', 'setStyle', 'setEmoji', 'setDisabled', 'setURL',
    'toJSON', 'data',
  ]);

  addMembers('ActionRowBuilder', [
    'addComponents', 'setComponents', 'toJSON', 'components',
  ]);

  addMembers('Collection', [
    'get', 'set', 'has', 'delete', 'clear', 'size', 'first', 'last', 'at',
    'find', 'findKey', 'filter', 'map', 'some', 'every', 'reduce', 'sort',
    'random', 'keyAt', 'valueAt', 'toJSON', 'forEach', 'keys', 'values',
    'entries', 'concat', 'difference', 'each', 'ensure', 'equals', 'flatMap',
    'partition', 'reverse', 'sweep', 'tap', 'unique', 'merge',
  ]);

  addMembers('REST', [
    'get', 'post', 'put', 'patch', 'delete', 'setToken', 'setVersion', 'setAgent',
    'setAPI', 'setCDN', 'setOAuth2', 'setInvite', 'setGuildTemplate',
  ]);

  addMembers('Role', [
    'id', 'name', 'color', 'hoist', 'position', 'permissions', 'mentionable',
    'guild', 'members', 'icon', 'unicodeEmoji', 'edit', 'delete', 'setMentionable',
    'setHoist', 'setColor', 'setName', 'setPermissions', 'setPosition',
    'comparePositionTo', 'toString', 'createdAt',
  ]);

  addMembers('Channel', [
    'id', 'type', 'guild', 'name', 'send', 'fetch', 'delete', 'isTextBased',
    'isVoiceBased', 'isDMBased', 'isThread', 'url', 'createdAt', 'permissionsFor',
  ]);

  addMembers('Webhook', [
    'id', 'token', 'url', 'name', 'avatar', 'owner', 'channel', 'guild',
    'send', 'edit', 'delete', 'editMessage', 'deleteMessage', 'fetchMessage',
    'createdAt', 'sourceGuild', 'sourceChannel', 'applicationId',
  ]);

  addMembers('GuildMemberManager', [
    'fetch', 'search', 'add', 'remove', 'ban', 'unban', 'kick', 'edit',
    'prune', 'fetchMe', 'editMe',
  ]);

  addMembers('GuildChannelManager', [
    'fetch', 'create', 'edit', 'delete', 'setPosition', 'fetchWebhooks',
  ]);

  addMembers('MessageManager', [
    'fetch', 'fetchPinned', 'crosspost', 'edit', 'pin', 'unpin', 'react',
    'delete', 'bulkDelete', 'forward',
  ]);

  addMembers('RoleManager', [
    'fetch', 'create', 'edit', 'delete', 'setPosition', 'comparePositions',
    'everyone', 'highest', 'botRoleFor',
  ]);

  addMembers('UserManager', [
    'fetch', 'createDM', 'fetchFlags',
  ]);

  addMembers('Events', [
    'ClientReady', 'MessageCreate', 'MessageUpdate', 'MessageDelete',
    'MessageDeleteBulk', 'MessageReactionAdd', 'MessageReactionRemove',
    'InteractionCreate', 'GuildCreate', 'GuildDelete', 'GuildUpdate',
    'GuildMemberAdd', 'GuildMemberRemove', 'GuildMemberUpdate',
    'ChannelCreate', 'ChannelDelete', 'ChannelUpdate', 'ThreadCreate',
    'ThreadDelete', 'ThreadUpdate', 'VoiceStateUpdate', 'PresenceUpdate',
    'TypingStart', 'UserUpdate', 'Warn', 'Debug', 'Error', 'ShardDisconnect',
    'ShardReconnect', 'ShardReady', 'ShardResume', 'RateLimit',
  ]);

  addMembers('GatewayIntentBits', [
    'Guilds', 'GuildMembers', 'GuildModeration', 'GuildBans', 'GuildEmojisAndStickers',
    'GuildIntegrations', 'GuildWebhooks', 'GuildInvites', 'GuildVoiceStates',
    'GuildPresences', 'GuildMessages', 'GuildMessageReactions',
    'GuildMessageTyping', 'DirectMessages', 'DirectMessageReactions',
    'DirectMessageTyping', 'MessageContent', 'GuildScheduledEvents',
    'AutoModerationConfiguration', 'AutoModerationExecution', 'GuildMessagePolls',
    'DirectMessagePolls',
  ]);

  addMembers('PermissionFlagsBits', [
    'CreateInstantInvite', 'KickMembers', 'BanMembers', 'Administrator',
    'ManageChannels', 'ManageGuild', 'AddReactions', 'ViewAuditLog',
    'PrioritySpeaker', 'Stream', 'ViewChannel', 'SendMessages', 'SendTTSMessages',
    'ManageMessages', 'EmbedLinks', 'AttachFiles', 'ReadMessageHistory',
    'MentionEveryone', 'UseExternalEmojis', 'ViewGuildInsights',
    'Connect', 'Speak', 'MuteMembers', 'DeafenMembers', 'MoveMembers',
    'UseVAD', 'ChangeNickname', 'ManageNicknames', 'ManageRoles',
    'ManageWebhooks', 'ManageGuildExpressions', 'UseApplicationCommands',
    'RequestToSpeak', 'ManageEvents', 'ManageThreads', 'CreatePublicThreads',
    'CreatePrivateThreads', 'UseExternalStickers', 'SendMessagesInThreads',
    'UseEmbeddedActivities', 'ModerateMembers', 'ViewCreatorMonetizationAnalytics',
    'UseSoundboard', 'CreateGuildExpressions', 'CreateEvents',
    'UseExternalSounds', 'SendVoiceMessages', 'SendPolls', 'UseExternalApps',
  ]);

  addMembers('ChannelType', [
    'GuildText', 'DM', 'GuildVoice', 'GroupDM', 'GuildCategory', 'GuildNews',
    'GuildNewsThread', 'GuildPublicThread', 'GuildPrivateThread',
    'GuildStageVoice', 'GuildDirectory', 'GuildForum', 'GuildMedia',
  ]);

  addMembers('ButtonStyle', [
    'Primary', 'Secondary', 'Success', 'Danger', 'Link',
  ]);

  addMembers('ActivityType', [
    'Playing', 'Streaming', 'Listening', 'Watching', 'Custom', 'Competing',
  ]);

  // Type aliases for contextual member lookup
  const typeAliases = {
    'interaction': 'BotCreatorInteraction',
    'message': 'BotCreatorMessage',
    'client': 'Client',
    'guild': 'Guild',
    'channel': 'Channel',
    'member': 'GuildMember',
    'user': 'User',
    'author': 'author',
    'options': 'options',
    'embed': 'EmbedBuilder',
    'row': 'ActionRowBuilder',
    'button': 'ButtonBuilder',
    'command': 'SlashCommandBuilder',
    'rest': 'REST',
    'webhook': 'Webhook',
    'roles': 'RoleManager',
    'members': 'GuildMemberManager',
    'channels': 'GuildChannelManager',
    'messages': 'MessageManager',
    'users': 'UserManager',
    'reactions': 'ReactionManager',
    'threads': 'ThreadManager',
    'emojis': 'GuildEmojiManager',
    'stickers': 'GuildStickerManager',
    'bans': 'GuildBanManager',
    'invites': 'GuildInviteManager',
    'scheduledEvents': 'GuildScheduledEventManager',
  };

  final globals = <String>{
    ...jsKeywords,
    ...jsBuiltins,
    ...botCreatorGlobals,
    ...discordExports,
  }.toList()
    ..sort();

  return {
    'version': 1,
    'globals': globals,
    'discordExports': discordExports,
    'members': members.map((k, v) => MapEntry(k, v)),
    'typeAliases': typeAliases,
  };
}

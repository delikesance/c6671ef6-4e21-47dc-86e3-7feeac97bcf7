import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator_shared/utils/variable_catalog.dart' show inferCategory;

class CommandVariableCatalogEntry {
  const CommandVariableCatalogEntry({
    required this.name,
    required this.description,
    required this.kind,
  });

  final String name;
  final String description;
  final VariableSuggestionKind kind;
}

const List<CommandVariableCatalogEntry> commandBuiltinVariableCatalog =
    <CommandVariableCatalogEntry>[
      CommandVariableCatalogEntry(
        name: 'guildName',
        description: 'Name of the guild.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guildId',
        description: 'ID of the guild.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channelName',
        description: 'Name of the current channel.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channelId',
        description: 'ID of the current channel.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'userName',
        description: 'Display name of the user who invoked the command.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'userId',
        description: 'ID of the user who invoked the command.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'userTag',
        description: 'Discord tag or discriminator of the invoking user.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'userAvatar',
        description: 'Avatar URL of the invoking user.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'userBanner',
        description: 'Banner URL of the invoking user when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'author.username',
        description: 'Structured alias for the invoking author username.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'author.avatar',
        description: 'Structured alias for the invoking author avatar URL.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'author.banner',
        description: 'Structured alias for the invoking author banner URL.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'member.nick',
        description: 'Guild nickname of the invoking member when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'member.avatar',
        description: 'Guild member avatar URL when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channel.name',
        description: 'Structured alias for channel name.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channel.type',
        description: 'Structured alias for channel type.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channel.topic',
        description: 'Channel topic when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channel.parentId',
        description: 'Parent/category channel ID when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channel.nsfw',
        description: 'Whether channel is marked NSFW.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channel.slowmode',
        description: 'Slowmode rate limit in seconds when available.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guild.name',
        description: 'Structured alias for guild name.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guild.count',
        description: 'Structured alias for approximate guild member count.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guild.ownerId',
        description: 'Guild owner ID when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guild.description',
        description: 'Guild description when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guild.features',
        description: 'Comma-separated list of enabled guild features.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guild.features.count',
        description: 'Number of enabled guild features.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guildIcon',
        description: 'Guild icon URL when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guildCount',
        description: 'Approximate member count of the guild.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'lavalink.title',
        description: 'Title of the currently playing track.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'lavalink.author',
        description: 'Author or artist of the currently playing track.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'lavalink.duration',
        description: 'Formatted duration (m:ss) of the currently playing track.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'lavalink.position',
        description: 'Formatted current playback position (m:ss) of the track.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'lavalink.queueSize',
        description: 'Number of tracks currently in the queue.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'lavalink.volume',
        description: 'Current volume level of the player (0 to 200).',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'lavalink.isPaused',
        description: 'Whether the player is currently paused (true/false).',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'lavalink.isLooping',
        description: 'Whether queue looping is currently enabled (true/false).',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'lavalink.thumbnail',
        description: 'Artwork or thumbnail URL of the currently playing track.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'commandName',
        description: 'Registered name of the executed command.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'commandId',
        description: 'Discord ID of the executed command.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'commandType',
        description: 'Normalized command type: chatInput, user, or message.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'commandTypeValue',
        description: 'Raw Discord numeric value of the command type.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'command.type',
        description: 'Alias of commandType for portable conditions.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'interaction.command.type',
        description: 'Nested alias of the current Discord command type.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'interaction.command.route',
        description: 'Resolved subcommand route such as admin/ban.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'interaction.customId',
        description: 'Custom ID for component interactions.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'interaction.locale',
        description: 'Locale of the user who triggered the interaction (e.g. fr, ja).',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'interaction.guild_locale',
        description: 'Locale of the guild where the interaction was triggered (e.g. en-US).',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.locale',
        description: 'Alias for interaction.locale.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'modal.customId',
        description: 'Custom ID for modal submit interactions.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'interaction.user.username',
        description: 'Structured alias for interaction author username.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'interaction.user.banner',
        description: 'Structured alias for interaction author banner URL.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'interaction.channel.name',
        description: 'Structured alias for interaction channel name.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'interaction.guild.name',
        description: 'Structured alias for interaction guild name.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'autocomplete.query',
        description: 'Focused autocomplete input currently typed by the user.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'autocomplete.optionName',
        description: 'Option name currently requesting dynamic autocomplete.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'autocomplete.optionType',
        description: 'Option type currently requesting autocomplete.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.id',
        description: 'Selected target ID for user or message commands.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.user.id',
        description: 'Target user ID for user commands.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.user.username',
        description: 'Username of the selected target user.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.user.tag',
        description:
            'Discord tag or discriminator of the selected target user.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.user.avatar',
        description: 'Avatar URL of the selected target user.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.user.banner',
        description: 'Banner URL of the selected target user when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.userName',
        description: 'Shortcut alias for the selected target user name.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.userAvatar',
        description: 'Shortcut alias for the selected target user avatar.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.member.id',
        description: 'Guild member ID of the selected target when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.member.nick',
        description: 'Guild nickname of the selected target when available.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.message.id',
        description: 'ID of the selected target message.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.message.channelId',
        description: 'Channel ID containing the selected target message.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.message.content',
        description: 'Content of the selected target message when resolved.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.message.author.id',
        description: 'Author ID of the selected target message when resolved.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.messageId',
        description: 'Shortcut alias for the selected target message ID.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'target.messageContent',
        description: 'Shortcut alias for the selected target message content.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'opts',
        description:
            'Root container for slash-command options and resolved values.',
        kind: VariableSuggestionKind.unknown,
      ),
      // ── Bot ──
      CommandVariableCatalogEntry(
        name: 'bot.id',
        description: 'Bot user ID.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'bot.username',
        description: 'Bot username.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'bot.guildcount',
        description: 'Number of servers the bot is in.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'bot.ping',
        description: 'Bot latency in milliseconds.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'ping',
        description: 'Bot latency in milliseconds.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'bot.uptime',
        description: 'Time since the bot started.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      // ── Common context ──
      CommandVariableCatalogEntry(
        name: 'timestamp',
        description: 'Current Unix timestamp in seconds.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'actualtime',
        description: 'Current date and time as text.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      // ── Guild ──
      CommandVariableCatalogEntry(
        name: 'guild.id',
        description: 'Server ID.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guild.icon',
        description: 'Server icon URL.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guild.rolecount',
        description: 'Number of roles in the server.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'guild.emojicount',
        description: 'Number of custom server emojis.',
        kind: VariableSuggestionKind.numeric,
      ),
      // ── Channel ──
      CommandVariableCatalogEntry(
        name: 'channel.id',
        description: 'Channel ID.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channel.mention',
        description: 'Channel mention tag.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'channel.position',
        description: 'Channel position in the list.',
        kind: VariableSuggestionKind.numeric,
      ),
      // ── Member ──
      CommandVariableCatalogEntry(
        name: 'member.id',
        description: 'Member user ID.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'member.displayname',
        description: 'Member display name (nickname or username).',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'member.joinedat',
        description: 'When the member joined the server.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'member.roles',
        description: 'List of role IDs the member has.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'member.isadmin',
        description: 'Whether the member is administrator.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'member.permissions',
        description: 'Computed permissions of the member.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'member.mention',
        description: 'Member mention tag.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      // ── Author ──
      CommandVariableCatalogEntry(
        name: 'author.id',
        description: 'Author user ID.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'author.tag',
        description: 'Author Discord tag.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'author.displayName',
        description: 'Author display name (nickname or username).',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'author.isBot',
        description: 'Whether the author is a bot.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'author.mention',
        description: 'Author mention tag.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      // ── User ──
      CommandVariableCatalogEntry(
        name: 'user.id',
        description: 'User ID.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'user.tag',
        description: 'User Discord tag.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'user.avatar',
        description: 'User avatar URL.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'user.banner',
        description: 'User banner URL.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'user.mention',
        description: 'User mention tag.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      // ── Message ──
      CommandVariableCatalogEntry(
        name: 'message.id',
        description: 'Message ID.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'message.content',
        description: 'Full message text content.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      // ── Runtime variables ──
      CommandVariableCatalogEntry(
        name: 'temp.<key>',
        description: 'Temporary variable set during execution.',
        kind: VariableSuggestionKind.unknown,
      ),
      CommandVariableCatalogEntry(
        name: 'global.<key>',
        description: 'Global variable from the bot storage.',
        kind: VariableSuggestionKind.unknown,
      ),
      CommandVariableCatalogEntry(
        name: 'scoped.<key>',
        description: 'Scoped variable from the current context.',
        kind: VariableSuggestionKind.unknown,
      ),
      CommandVariableCatalogEntry(
        name: 'arg.<key>',
        description: 'Workflow argument passed at call time.',
        kind: VariableSuggestionKind.unknown,
      ),
      CommandVariableCatalogEntry(
        name: 'action.<key>',
        description: 'Output key of a previous action.',
        kind: VariableSuggestionKind.unknown,
      ),
      // ── Event / workflow ──
      CommandVariableCatalogEntry(
        name: 'event.name',
        description: 'Name of the event that triggered execution.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      CommandVariableCatalogEntry(
        name: 'workflow.args',
        description: 'Arguments passed to this workflow.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
      // ── Image compositing ──
      CommandVariableCatalogEntry(
        name: 'image.width',
        description: 'Width of the composited image in pixels.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'image.height',
        description: 'Height of the composited image in pixels.',
        kind: VariableSuggestionKind.numeric,
      ),
      CommandVariableCatalogEntry(
        name: 'image.url',
        description: 'Generated image URL after compositing.',
        kind: VariableSuggestionKind.nonNumeric,
      ),
    ];

const List<String> commandTemplateReferenceVariables = <String>[
  'commandName',
  'commandId',
  'commandType',
  'commandTypeValue',
  'command.type',
  'interaction.command.type',
  'interaction.command.route',
  'interaction.customId',
  'modal.customId',
  'modal.<inputCustomId>',
  'opts.<option>',
  'opts.<option>.id',
  'opts.<option>.username',
  'opts.<option>.tag',
  'opts.<option>.avatar',
  'opts.<option>.banner',
  'autocomplete.query',
  'autocomplete.optionName',
  'autocomplete.optionType',
  'target.id',
  'target.user.id',
  'target.user.username',
  'target.user.avatar',
  'target.user.banner',
  'target.message.id',
  'target.message.content',
  'target.message.author.id',
  'global.<key>',
  'workflow.name',
  'workflow.entryPoint',
  'arg.<key>',
  'action.<key>',
];

const List<String> interactionCommandReferenceVariables = <String>[
  'commandType',
  'interaction.command.type',
  'interaction.command.route',
  'autocomplete.*',
  'opts.*',
  'target.user.*',
  'target.message.*',
];

List<String> get commandBuiltinVariableNames => commandBuiltinVariableCatalog
    .map((entry) => entry.name)
    .toList(growable: false);

List<String> get commandBuiltinVariableDocumentationLines =>
    commandBuiltinVariableCatalog
        .map((entry) => '${entry.name}: ${entry.description}')
        .toList(growable: false);

List<VariableSuggestion> get builtinCommandVariableSuggestions =>
    commandBuiltinVariableCatalog
        .map((entry) => VariableSuggestion(
              name: entry.name,
              kind: entry.kind,
              category: inferCategory(entry.name),
            ))
        .toList(growable: false);

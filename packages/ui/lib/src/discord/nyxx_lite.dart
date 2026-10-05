// Équivalents web-safe des types Discord de `package:nyxx` utilisés par les
// éditeurs partagés. nyxx importe `dart:ffi` et ne compile pas pour le web ;
// ces définitions en sont recopiées (MIT, https://github.com/nyxx-discord/nyxx)
// avec les mêmes noms, valeurs et sérialisation. L'app convertit vers/depuis
// ses vrais types nyxx à la frontière (voir `nyxx_bridge.dart` dans l'app).
//
// Le nom `Locale` masque celui de Flutter : importer avec
// `import 'package:flutter/material.dart' hide Locale;`.

base class EnumLike<T extends Object, U extends EnumLike<T, U>> {
  final T value;
  const EnumLike(this.value);

  @override
  String toString() => '$runtimeType($value)';

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is U && other.value == value);
}

enum Locale {
  id._('id', 'Indonesian', 'Bahasa Indonesia'),
  da._('da', 'Danish', 'Dansk'),
  de._('de', 'German', 'Deutsch'),
  enGb._('en-GB', 'English, UK', 'English, UK'),
  enUs._('en-US', 'English, US', 'English, US'),
  esEs._('es-ES', 'Spanish', 'Español'),
  es419._('es-419', 'Spanish, LATAM', 'Español, LATAM'),
  fr._('fr', 'French', 'Français'),
  hr._('hr', 'Croatian', 'Hrvatski'),
  it._('it', 'Italian', 'Italiano'),
  lt._('lt', 'Lithuanian', 'Lietuviškai'),
  hu._('hu', 'Hungarian', 'Magyar'),
  nl._('nl', 'Dutch', 'Nederlands'),
  no._('no', 'Norwegian', 'Norsk'),
  pl._('pl', 'Polish', 'Polski'),
  ptBr._('pt-BR', 'Portuguese, Brazilian', 'Português do Brasil'),
  ro._('ro', 'Romanian, Romania', 'Română'),
  fi._('fi', 'Finnish', 'Suomi'),
  svSe._('sv-SE', 'Swedish', 'Svenska'),
  vi._('vi', 'Vietnamese', 'Tiếng Việt'),
  tr._('tr', 'Turkish', 'Türkçe'),
  cs._('cs', 'Czech', 'Čeština'),
  el._('el', 'Greek', 'Ελληνικά'),
  bg._('bg', 'Bulgarian', 'български'),
  ru._('ru', 'Russian', 'Pусский'),
  uk._('uk', 'Ukrainian', 'Українська'),
  hi._('hi', 'Hindi', 'हिन्दी'),
  th._('th', 'Thai', 'ไทย'),
  zhCn._('zh-CN', 'Chinese, China', '中文'),
  ja._('ja', 'Japanese', '日本語'),
  zhTw._('zh-TW', 'Chinese, Taiwan', '繁體中文'),
  ko._('ko', 'Korean', '한국어');

  /// The identifier for this locale.
  final String identifier;

  /// The english name of this locale.
  final String name;

  /// The native name of this locale.
  final String nativeName;

  const Locale._(this.identifier, this.name, this.nativeName);

  /// Parse a string into a locale.
  ///
  /// [identifier] must be a string containing an identifier matching [Locale.identifier] for one of
  /// the listed locales.
  factory Locale.parse(String identifier) => values.firstWhere(
    (loc) => loc.identifier == identifier,
    orElse: () => throw FormatException('Unknown Locale', identifier),
  );
}

final class ChannelType extends EnumLike<int, ChannelType> {
  /// A text channel in a [Guild].
  static const guildText = ChannelType(0);

  /// A DM channel with a single other recipient.
  static const dm = ChannelType(1);

  /// A voice channel in a [Guild].
  static const guildVoice = ChannelType(2);

  /// A DM channel with multiple recipients.
  static const groupDm = ChannelType(3);

  /// A category in a [Guild].
  static const guildCategory = ChannelType(4);

  /// An announcement channel in a [Guild].
  static const guildAnnouncement = ChannelType(5);

  /// A [Thread] in an announcement channel.
  static const announcementThread = ChannelType(10);

  /// A public thread.
  static const publicThread = ChannelType(11);

  /// A private thread.
  static const privateThread = ChannelType(12);

  /// A stage channel in a [Guild].
  static const guildStageVoice = ChannelType(13);

  /// A [Guild] directory.
  static const guildDirectory = ChannelType(14);

  /// A forum channel in a [Guild].
  static const guildForum = ChannelType(15);

  /// A media channel in a [Guild].
  static const guildMedia = ChannelType(16);

  /// @nodoc
  const ChannelType(super.value);

  @Deprecated(
    'The .parse() constructor is deprecated. Use the unnamed constructor instead.',
  )
  ChannelType.parse(int value) : this(value);
}

final class CommandOptionType extends EnumLike<int, CommandOptionType> {
  static const subCommand = CommandOptionType(1);
  static const subCommandGroup = CommandOptionType(2);
  static const string = CommandOptionType(3);
  static const integer = CommandOptionType(4);
  static const boolean = CommandOptionType(5);
  static const user = CommandOptionType(6);
  static const channel = CommandOptionType(7);
  static const role = CommandOptionType(8);
  static const mentionable = CommandOptionType(9);
  static const number = CommandOptionType(10);
  static const attachment = CommandOptionType(11);

  /// @nodoc
  const CommandOptionType(super.value);

  @Deprecated(
    'The .parse() constructor is deprecated. Use the unnamed constructor instead.',
  )
  CommandOptionType.parse(int value) : this(value);
}

final class ApplicationCommandType
    extends EnumLike<int, ApplicationCommandType> {
  /// A chat input command.
  static const chatInput = ApplicationCommandType(1);

  /// A user command.
  static const user = ApplicationCommandType(2);

  /// A message command.
  static const message = ApplicationCommandType(3);

  /// @nodoc
  const ApplicationCommandType(super.value);

  @Deprecated(
    'The .parse() constructor is deprecated. Use the unnamed constructor instead.',
  )
  ApplicationCommandType.parse(int value) : this(value);
}

class CommandOptionBuilder {
  CommandOptionType type;

  String name;

  Map<Locale, String>? nameLocalizations;

  String description;

  Map<Locale, String>? descriptionLocalizations;

  bool? isRequired;

  List<CommandOptionChoiceBuilder<dynamic>>? choices;

  List<CommandOptionBuilder>? options;

  List<ChannelType>? channelTypes;

  num? minValue;

  num? maxValue;

  int? minLength;

  int? maxLength;

  bool? hasAutocomplete;

  CommandOptionBuilder({
    required this.type,
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
    this.choices,
    this.options,
    this.channelTypes,
    this.minValue,
    this.maxValue,
    this.minLength,
    this.maxLength,
    this.hasAutocomplete,
  });

  CommandOptionBuilder.subCommand({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    required List<CommandOptionBuilder> this.options,
  }) : type = CommandOptionType.subCommand,
       isRequired = null,
       choices = null,
       channelTypes = null,
       minValue = null,
       maxValue = null,
       minLength = null,
       maxLength = null,
       hasAutocomplete = null;

  CommandOptionBuilder.subCommandGroup({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    required List<CommandOptionBuilder> this.options,
  }) : type = CommandOptionType.subCommandGroup,
       isRequired = null,
       choices = null,
       channelTypes = null,
       minValue = null,
       maxValue = null,
       minLength = null,
       maxLength = null,
       hasAutocomplete = null;

  CommandOptionBuilder.string({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
    List<CommandOptionChoiceBuilder<String>>? this.choices,
    this.minLength,
    this.maxLength,
    this.hasAutocomplete,
  }) : type = CommandOptionType.string,
       options = null,
       channelTypes = null,
       minValue = null,
       maxValue = null;

  CommandOptionBuilder.integer({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
    List<CommandOptionChoiceBuilder<int>>? this.choices,
    int? this.minValue,
    int? this.maxValue,
    this.hasAutocomplete,
  }) : type = CommandOptionType.integer,
       options = null,
       channelTypes = null,
       minLength = null,
       maxLength = null;

  CommandOptionBuilder.boolean({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
  }) : type = CommandOptionType.boolean,
       choices = null,
       options = null,
       channelTypes = null,
       minValue = null,
       maxValue = null,
       minLength = null,
       maxLength = null,
       hasAutocomplete = null;

  CommandOptionBuilder.user({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
  }) : type = CommandOptionType.user,
       choices = null,
       options = null,
       channelTypes = null,
       minValue = null,
       maxValue = null,
       minLength = null,
       maxLength = null,
       hasAutocomplete = null;

  CommandOptionBuilder.channel({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
    this.channelTypes,
  }) : type = CommandOptionType.channel,
       choices = null,
       options = null,
       minValue = null,
       maxValue = null,
       minLength = null,
       maxLength = null,
       hasAutocomplete = null;

  CommandOptionBuilder.role({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
  }) : type = CommandOptionType.role,
       choices = null,
       options = null,
       channelTypes = null,
       minValue = null,
       maxValue = null,
       minLength = null,
       maxLength = null,
       hasAutocomplete = null;

  CommandOptionBuilder.mentionable({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
  }) : type = CommandOptionType.mentionable,
       choices = null,
       options = null,
       channelTypes = null,
       minValue = null,
       maxValue = null,
       minLength = null,
       maxLength = null,
       hasAutocomplete = null;

  CommandOptionBuilder.number({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
    List<CommandOptionChoiceBuilder<double>>? this.choices,
    double? this.minValue,
    double? this.maxValue,
    this.hasAutocomplete,
  }) : type = CommandOptionType.number,
       options = null,
       channelTypes = null,
       minLength = null,
       maxLength = null;

  CommandOptionBuilder.attachment({
    required this.name,
    this.nameLocalizations,
    required this.description,
    this.descriptionLocalizations,
    this.isRequired,
  }) : type = CommandOptionType.attachment,
       choices = null,
       options = null,
       channelTypes = null,
       minValue = null,
       maxValue = null,
       minLength = null,
       maxLength = null,
       hasAutocomplete = null;

  Map<String, Object?> build() => {
    'type': type.value,
    'name': name,
    if (nameLocalizations != null)
      'name_localizations': {
        for (final MapEntry(:key, :value) in nameLocalizations!.entries)
          key.identifier: value,
      },
    'description': description,
    if (descriptionLocalizations != null)
      'description_localizations': {
        for (final MapEntry(:key, :value) in descriptionLocalizations!.entries)
          key.identifier: value,
      },
    if (isRequired != null) 'required': isRequired,
    if (choices != null) 'choices': choices!.map((e) => e.build()).toList(),
    if (options != null) 'options': options!.map((e) => e.build()).toList(),
    if (channelTypes != null)
      'channel_types': channelTypes!.map((e) => e.value).toList(),
    if (minValue != null) 'min_value': minValue,
    if (maxValue != null) 'max_value': maxValue,
    if (minLength != null) 'min_length': minLength,
    if (maxLength != null) 'max_length': maxLength,
    if (hasAutocomplete != null) 'autocomplete': hasAutocomplete,
  };
}

class CommandOptionChoiceBuilder<T> {
  String name;

  Map<Locale, String>? nameLocalizations;

  T value;

  CommandOptionChoiceBuilder({
    required this.name,
    this.nameLocalizations,
    required this.value,
  });

  Map<String, Object?> build() => {
    'name': name,
    if (nameLocalizations != null)
      'name_localizations': {
        for (final MapEntry(:key, :value) in nameLocalizations!.entries)
          key.identifier: value,
      },
    'value': value,
  };
}

final class ApplicationIntegrationType
    extends EnumLike<int, ApplicationIntegrationType> {
  /// App is installable to servers.
  static const guildInstall = ApplicationIntegrationType(0);

  /// App is installable to users.
  static const userInstall = ApplicationIntegrationType(1);

  /// @nodoc
  const ApplicationIntegrationType(super.value);

  @Deprecated(
    'The .parse() constructor is deprecated. Use the unnamed constructor instead.',
  )
  ApplicationIntegrationType.parse(int value) : this(value);
}

final class InteractionContextType
    extends EnumLike<int, InteractionContextType> {
  /// Interaction can be used within servers.
  static const InteractionContextType guild = InteractionContextType(0);

  /// Interaction can be used within DMs with the app's bot user.
  static const InteractionContextType botDm = InteractionContextType(1);

  /// Interaction can be used within Group DMs and DMs other than the app's bot user.
  static const InteractionContextType privateChannel = InteractionContextType(
    2,
  );

  /// @nodoc
  const InteractionContextType(super.value);

  @Deprecated(
    'The .parse() constructor is deprecated. Use the unnamed constructor instead.',
  )
  InteractionContextType.parse(int value) : this(value);
}

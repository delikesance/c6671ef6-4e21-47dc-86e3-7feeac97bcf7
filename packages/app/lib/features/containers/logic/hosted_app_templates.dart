import 'package:flutter/material.dart';

/// Preset turnkey hosted-app images with minimal required configuration.
enum HostedAppTemplateId { easyMusic, dynamicTemplate }

class HostedAppEnvField {
  const HostedAppEnvField({
    required this.key,
    this.label,
    this.defaultValue = '',
    this.required = true,
    this.secret = false,
    this.fixed = false,
    this.source = '',
    this.nodeVariable = '',
  });

  final String key;
  final String? label;
  final String defaultValue;
  final bool required;
  final bool secret;

  /// Le serveur impose la valeur : l'utilisateur ne peut pas la saisir et
  /// l'app ne doit jamais en inventer une.
  final bool fixed;

  /// Origine de la valeur telle que déclarée par le template :
  /// `""` (saisie utilisateur), `"value"` ou `"node"` (nœud d'hébergement).
  final String source;

  /// Variable du nœud d'hébergement qui alimente ce champ
  /// (clé `source_variable` du schéma, renseignée quand `source == "node"`).
  final String nodeVariable;

  /// Vrai si la valeur est décidée par le serveur : champ figé (`fixed`) ou
  /// alimenté par un nœud d'hébergement (`source == "node"`). Un champ
  /// verrouillé s'affiche en lecture seule et ne part jamais avec une valeur
  /// inventée côté app.
  bool get isLocked => fixed || source.toLowerCase() == 'node';

  /// Libellé affichable : celui du template, sinon la clé technique (identifiant
  /// déclaré par le serveur, pas un texte d'UI à traduire).
  String get displayLabel {
    final raw = label?.trim() ?? '';
    return raw.isNotEmpty ? raw : key.trim();
  }

  factory HostedAppEnvField.fromJson(Map<String, dynamic> json) {
    return HostedAppEnvField(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString(),
      defaultValue: json['default_value']?.toString() ?? '',
      required: json['required'] == true,
      secret: json['secret'] == true,
      fixed: json['fixed'] == true,
      source: json['source']?.toString() ?? '',
      nodeVariable: json['source_variable']?.toString() ?? '',
    );
  }
}

class HostedAppTemplate {
  const HostedAppTemplate({
    required this.id,
    this.slug,
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
    this.category = 'music',
    this.cpuMillis = 250,
    this.memoryMb = 256,
    this.storageGb = 1,
    this.requiresPrivateRegistry = false,
    this.envFields = const [],
    this.requiredIntents = const ['Message Content Intent'],
    this.tips = const [],
  });

  final HostedAppTemplateId id;
  final String? slug;
  final String title;
  final String description;
  final String image;
  final IconData icon;
  final String category;
  final int cpuMillis;
  final int memoryMb;
  final int storageGb;
  final bool requiresPrivateRegistry;
  final List<HostedAppEnvField> envFields;
  final List<String> requiredIntents;
  final List<String> tips;

  factory HostedAppTemplate.fromJson(Map<String, dynamic> json) {
    // Le manager sert `env_fields_schema` (schéma déclaratif : fixed, source,
    // default_value…). `env_fields` reste accepté en repli pour ne pas casser
    // une réponse plus ancienne.
    final envRaw = json['env_fields_schema'] ?? json['env_fields'];
    final envFields = <HostedAppEnvField>[];
    if (envRaw is List) {
      for (final e in envRaw) {
        if (e is Map) {
          envFields.add(
            HostedAppEnvField.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }

    final intentsRaw = json['required_intents'];
    final intents = <String>[];
    if (intentsRaw is List) {
      for (final item in intentsRaw) {
        if (item != null) intents.add(item.toString());
      }
    }

    final tipsRaw = json['tips'];
    final tips = <String>[];
    if (tipsRaw is List) {
      for (final item in tipsRaw) {
        if (item != null) tips.add(item.toString());
      }
    }

    IconData icon = Icons.smart_toy_rounded;
    final cat = (json['category']?.toString() ?? '').toLowerCase();
    if (cat == 'music') {
      icon = Icons.music_note_rounded;
    } else if (cat == 'moderation') {
      icon = Icons.shield_rounded;
    } else if (cat == 'utility') {
      icon = Icons.build_rounded;
    }

    final slug = json['slug']?.toString();
    final isBeatDock =
        slug == 'beatdock' ||
        (json['image']?.toString() ?? '').contains('beatdock');

    return HostedAppTemplate(
      id: isBeatDock
          ? HostedAppTemplateId.easyMusic
          : HostedAppTemplateId.dynamicTemplate,
      slug: slug,
      title:
          json['name']?.toString() ??
          json['title']?.toString() ??
          'Turnkey Bot',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      icon: icon,
      category: cat,
      cpuMillis: (json['cpu_millis'] as num?)?.toInt() ?? 250,
      memoryMb: (json['memory_mb'] as num?)?.toInt() ?? 256,
      storageGb: (json['storage_gb'] as num?)?.toInt() ?? 1,
      envFields: envFields,
      requiredIntents: intents.isNotEmpty
          ? intents
          : const ['Message Content Intent'],
      tips: tips,
    );
  }
}

/// BeatDock: public Lavalink nodes, slash commands, only `TOKEN` required.
const kEasyMusicBotImage =
    'ghcr.io/albertgmz/beatdock:latest@sha256:27dc983a9c9215a4db9be6bbe734fd23b8eb3960cd4c35c440658066e3e93ce4';

const easyMusicBotTemplate = HostedAppTemplate(
  id: HostedAppTemplateId.easyMusic,
  slug: 'beatdock',
  title: 'Bot Musique',
  description:
      'Bot de musique prêt à l\'emploi (BeatDock) avec nœuds Lavalink publics et commandes slash intégrées.',
  image: kEasyMusicBotImage,
  icon: Icons.music_note_rounded,
  category: 'music',
  cpuMillis: 250,
  memoryMb: 256,
  storageGb: 1,
  envFields: [HostedAppEnvField(key: 'TOKEN', secret: true)],
  requiredIntents: ['Message Content Intent'],
  tips: [
    'Activez le Message Content Intent dans le Discord Developer Portal.',
    'Assurez-vous que le bot a les permissions de rejoindre et parler dans les salons vocaux.',
  ],
);

List<HostedAppTemplate> _cachedDynamicTemplates = [];

List<HostedAppTemplate> get kTurnkeyBotTemplates {
  if (_cachedDynamicTemplates.isNotEmpty) {
    return _cachedDynamicTemplates;
  }
  return [easyMusicBotTemplate];
}

void setCachedTurnkeyTemplates(List<HostedAppTemplate> templates) {
  _cachedDynamicTemplates = templates;
}

HostedAppTemplate templateFor(HostedAppTemplateId id) {
  switch (id) {
    case HostedAppTemplateId.easyMusic:
      return easyMusicBotTemplate;
    case HostedAppTemplateId.dynamicTemplate:
      return kTurnkeyBotTemplates.firstWhere(
        (t) => t.id == HostedAppTemplateId.dynamicTemplate,
        orElse: () => easyMusicBotTemplate,
      );
  }
}

HostedAppTemplate? templateForImage(String image) {
  final clean = image.trim().toLowerCase();
  for (final t in kTurnkeyBotTemplates) {
    if (t.image.toLowerCase() == clean ||
        (clean.contains('beatdock') &&
            (t.slug == 'beatdock' || t.id == HostedAppTemplateId.easyMusic))) {
      return t;
    }
  }
  return null;
}

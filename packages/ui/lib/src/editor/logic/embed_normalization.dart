Map<String, dynamic> _stringKeyedMap(dynamic raw) {
  if (raw is! Map) {
    return <String, dynamic>{};
  }

  return Map<String, dynamic>.from(
    raw.map((key, value) => MapEntry(key.toString(), value)),
  );
}

Iterable<dynamic> _collectionValues(dynamic raw) {
  if (raw is List) {
    return raw;
  }

  if (raw is! Map) {
    return const <dynamic>[];
  }

  final map = _stringKeyedMap(raw);
  final numericKeys = <MapEntry<int, dynamic>>[];
  for (final entry in map.entries) {
    final parsedKey = int.tryParse(entry.key);
    if (parsedKey == null) {
      return map.values;
    }
    numericKeys.add(MapEntry(parsedKey, entry.value));
  }

  numericKeys.sort((a, b) => a.key.compareTo(b.key));
  return numericKeys.map((entry) => entry.value);
}

String _readString(dynamic raw, {List<String> aliases = const <String>[]}) {
  if (raw == null) {
    return '';
  }
  if (raw is String) {
    return raw;
  }

  final map = _stringKeyedMap(raw);
  for (final key in aliases) {
    final value = map[key];
    if (value != null) {
      return value.toString();
    }
  }

  return raw.toString();
}

bool _readBool(dynamic raw) {
  if (raw == true) {
    return true;
  }
  if (raw is String) {
    return raw.trim().toLowerCase() == 'true';
  }
  return false;
}

Map<String, dynamic> _cloneEmbedShallow(dynamic rawEmbed) {
  return _stringKeyedMap(rawEmbed);
}

Map<String, dynamic> normalizeResponseEmbed(dynamic rawEmbed) {
  final embed = _stringKeyedMap(rawEmbed);
  final type = _readString(embed['type']);

  return <String, dynamic>{
    'title': _readString(embed['title']),
    'type': type.isEmpty ? 'rich' : type,
    'description': _readString(embed['description']),
    'url': _readString(embed['url']),
    'timestamp': _readString(embed['timestamp']),
    'color': _readString(embed['color']),
    'footer': <String, dynamic>{
      'text': _readString(embed['footer'], aliases: const <String>['text']),
      'icon_url': _readString(
        embed['footer'],
        aliases: const <String>['icon_url', 'iconUrl', 'icon'],
      ),
    },
    'image': <String, dynamic>{
      'url': _readString(embed['image'], aliases: const <String>['url', 'src']),
    },
    'thumbnail': <String, dynamic>{
      'url': _readString(
        embed['thumbnail'],
        aliases: const <String>['url', 'src'],
      ),
    },
    'author': <String, dynamic>{
      'name': _readString(embed['author'], aliases: const <String>['name']),
      'url': _readString(embed['author'], aliases: const <String>['url']),
      'icon_url': _readString(
        embed['author'],
        aliases: const <String>['icon_url', 'iconUrl', 'icon'],
      ),
    },
    'fieldsTemplate': _readString(embed['fieldsTemplate']),
    'fields': normalizeResponseEmbedFields(embed['fields']),
  };
}

List<Map<String, dynamic>> normalizeResponseEmbedFields(dynamic rawFields) {
  return _collectionValues(rawFields)
      .where((field) => field is Map || field is String)
      .map((field) {
        final map = _stringKeyedMap(field);
        return <String, dynamic>{
          'name': _readString(map['name']),
          'value': field is String ? field : _readString(map['value']),
          'inline': _readBool(map['inline']),
        };
      })
      .take(25)
      .toList(growable: false);
}

bool hasMeaningfulResponseEmbedContent(dynamic rawEmbed) {
  final embed = normalizeResponseEmbed(rawEmbed);
  final footer = _stringKeyedMap(embed['footer']);
  final image = _stringKeyedMap(embed['image']);
  final thumbnail = _stringKeyedMap(embed['thumbnail']);
  final author = _stringKeyedMap(embed['author']);
  final fields = normalizeResponseEmbedFields(embed['fields']);

  return _readString(embed['title']).isNotEmpty ||
      _readString(embed['description']).isNotEmpty ||
      _readString(embed['url']).isNotEmpty ||
      _readString(embed['timestamp']).isNotEmpty ||
      _readString(embed['color']).isNotEmpty ||
      _readString(embed['fieldsTemplate']).isNotEmpty ||
      _readString(footer['text']).isNotEmpty ||
      _readString(footer['icon_url']).isNotEmpty ||
      _readString(image['url']).isNotEmpty ||
      _readString(thumbnail['url']).isNotEmpty ||
      _readString(author['name']).isNotEmpty ||
      _readString(author['url']).isNotEmpty ||
      _readString(author['icon_url']).isNotEmpty ||
      fields.isNotEmpty;
}

List<Map<String, dynamic>> normalizeResponseEmbedsPayload(
  dynamic rawEmbeds, {
  int maxEmbeds = 10,
  dynamic legacySingleEmbed,
  bool deepNormalize = true,
}) {
  final normalizer = deepNormalize
      ? normalizeResponseEmbed
      : _cloneEmbedShallow;
  final embeds = _collectionValues(rawEmbeds)
      .where((embed) => embed is Map || embed is String)
      .map(normalizer)
      .take(maxEmbeds)
      .toList(growable: false);
  if (embeds.isNotEmpty) {
    return embeds;
  }

  if (legacySingleEmbed != null &&
      hasMeaningfulResponseEmbedContent(legacySingleEmbed)) {
    return <Map<String, dynamic>>[normalizer(legacySingleEmbed)];
  }

  return <Map<String, dynamic>>[];
}

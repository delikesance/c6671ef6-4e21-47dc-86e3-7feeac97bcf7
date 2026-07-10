import 'dart:convert';

import 'package:flutter/services.dart';

/// A single autocompletion candidate.
class JsCompletionCandidate {
  const JsCompletionCandidate({
    required this.label,
    this.insertText,
  });

  final String label;
  final String? insertText;
}

/// Static completion index for JavaScript + discord.js + Bot Creator globals.
class JsCompletionIndex {
  JsCompletionIndex._({
    required this._globals,
    required List<String> discordExports,
    required this._members,
    required this._typeAliases,
  }) : _discordExports = discordExports.toSet();

  final List<String> _globals;
  final Set<String> _discordExports;
  final Map<String, List<String>> _members;
  final Map<String, String> _typeAliases;

  static const assetPath = 'assets/js_editor/discord_js_completions.json';

  static Future<JsCompletionIndex> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final members = <String, List<String>>{};
    final rawMembers = data['members'] as Map<String, dynamic>? ?? {};
    for (final entry in rawMembers.entries) {
      members[entry.key] = List<String>.from(entry.value as List);
    }

    final aliases = <String, String>{};
    final rawAliases = data['typeAliases'] as Map<String, dynamic>? ?? {};
    for (final entry in rawAliases.entries) {
      aliases[entry.key] = entry.value as String;
    }

    return JsCompletionIndex._(
      globals: List<String>.from(data['globals'] as List),
      discordExports: List<String>.from(data['discordExports'] as List),
      members: members,
      typeAliases: aliases,
    );
  }

  List<JsCompletionCandidate> completionsAt({
    required String documentText,
    required int line,
    required int character,
  }) {
    final lines = documentText.split('\n');
    if (line < 0 || line >= lines.length) {
      return const [];
    }

    final currentLine = lines[line];
    final safeCharacter = character.clamp(0, currentLine.length);
    final beforeCursor = currentLine.substring(0, safeCharacter);

    if (beforeCursor.endsWith('.')) {
      return _memberCompletions(_memberContext(beforeCursor));
    }

    final prefix = _wordPrefix(beforeCursor);
    if (prefix.isEmpty) {
      return const [];
    }

    final lowerPrefix = prefix.toLowerCase();
    final pool = <JsCompletionCandidate>{};

    for (final symbol in _globals) {
      if (_matchesPrefix(symbol, prefix, lowerPrefix)) {
        pool.add(JsCompletionCandidate(label: symbol));
      }
    }

    if (_documentMentionsDiscordJs(documentText)) {
      for (final symbol in _discordExports) {
        if (_matchesPrefix(symbol, prefix, lowerPrefix)) {
          pool.add(JsCompletionCandidate(label: symbol));
        }
      }
    }

    final sorted = pool.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return sorted.take(50).toList();
  }

  List<JsCompletionCandidate> _memberCompletions(String? receiver) {
    if (receiver == null || receiver.isEmpty) {
      return const [];
    }

    final resolvedType = _typeAliases[receiver] ?? receiver;
    final symbols = _members[resolvedType];
    if (symbols == null) {
      return const [];
    }

    return symbols
        .map((symbol) => JsCompletionCandidate(label: symbol))
        .toList();
  }

  String? _memberContext(String beforeCursor) {
    final trimmed = beforeCursor.substring(0, beforeCursor.length - 1);
    final match = RegExp(r'([a-zA-Z_$][\w$]*)\s*$').firstMatch(trimmed);
    return match?.group(1);
  }

  String _wordPrefix(String beforeCursor) {
    final match = RegExp(r'[a-zA-Z_$][\w$]*$').firstMatch(beforeCursor);
    return match?.group(0) ?? '';
  }

  bool _matchesPrefix(String symbol, String prefix, String lowerPrefix) {
    if (prefix.isEmpty) {
      return true;
    }
    if (symbol.startsWith(prefix)) {
      return true;
    }
    return symbol.toLowerCase().startsWith(lowerPrefix);
  }

  bool _documentMentionsDiscordJs(String documentText) {
    return documentText.contains("require('discord.js')") ||
        documentText.contains('require("discord.js")') ||
        documentText.contains("from 'discord.js'") ||
        documentText.contains('from "discord.js"') ||
        documentText.contains('discord.js');
  }
}

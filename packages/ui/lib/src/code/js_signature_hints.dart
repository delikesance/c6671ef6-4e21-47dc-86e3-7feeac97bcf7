import './script_editor_language.dart';

/// Signatures des API réellement exposées aux scripts JavaScript de Bot Creator.
///
/// Clé : chemin du callable tel qu'écrit dans le script (`db.user.set`) ;
/// valeur : libellés des paramètres dans l'ordre de déclaration, `?` marquant un
/// paramètre optionnel. Ce sont des identifiants techniques de l'API (et non des
/// messages d'interface), ils ne sont donc pas traduits.
///
/// Sources : `ScriptDb` / `ScriptDbScopedApi` / `ScriptDbGuildMemberApi` du
/// runner JS, `botCreatorGlobalsDts` et les snippets de l'éditeur.
const Map<String, List<String>> jsSignatureCatalog = <String, List<String>>{
  // ── Globals ──────────────────────────────────────────────────────────
  'client.login': <String>['token'],
  'require': <String>['moduleId'],
  'console.log': <String>['message'],
  'console.warn': <String>['message'],
  'console.error': <String>['message'],
  'fetch': <String>['url', 'options?'],

  // ── interaction ──────────────────────────────────────────────────────
  'interaction.reply': <String>['content'],
  'interaction.editReply': <String>['content'],
  'interaction.deferReply': <String>['options?'],
  'interaction.followUp': <String>['content'],
  'interaction.respond': <String>['choices'],

  // ── interaction.options ──────────────────────────────────────────────
  'interaction.options.getString': <String>['name', 'required?'],
  'interaction.options.getInteger': <String>['name', 'required?'],
  'interaction.options.getBoolean': <String>['name', 'required?'],
  'interaction.options.getUser': <String>['name'],
  'interaction.options.getChannel': <String>['name'],
  'interaction.options.getRole': <String>['name'],
  'interaction.options.getFocused': <String>['full?'],

  // ── message ──────────────────────────────────────────────────────────
  'message.reply': <String>['content'],

  // ── db.user / db.guild / db.channel / db.message (API scopée) ────────
  'db.user.get': <String>['key', 'id?'],
  'db.user.set': <String>['key', 'value', 'id?'],
  'db.user.delete': <String>['key', 'id?'],
  'db.user.list': <String>['key', 'order?', 'limit?', 'offset?'],
  'db.user.find': <String>['filter?'],
  'db.user.reset': <String>['key'],
  'db.guild.get': <String>['key', 'id?'],
  'db.guild.set': <String>['key', 'value', 'id?'],
  'db.guild.delete': <String>['key', 'id?'],
  'db.guild.list': <String>['key', 'order?', 'limit?', 'offset?'],
  'db.guild.find': <String>['filter?'],
  'db.guild.reset': <String>['key'],
  'db.channel.get': <String>['key', 'id?'],
  'db.channel.set': <String>['key', 'value', 'id?'],
  'db.channel.delete': <String>['key', 'id?'],
  'db.channel.list': <String>['key', 'order?', 'limit?', 'offset?'],
  'db.channel.find': <String>['filter?'],
  'db.channel.reset': <String>['key'],
  'db.message.get': <String>['key', 'id?'],
  'db.message.set': <String>['key', 'value', 'id?'],
  'db.message.delete': <String>['key', 'id?'],
  'db.message.list': <String>['key', 'order?', 'limit?', 'offset?'],
  'db.message.find': <String>['filter?'],
  'db.message.reset': <String>['key'],

  // ── db.guildMember ───────────────────────────────────────────────────
  'db.guildMember.get': <String>['key', 'userId?', 'guildId?'],
  'db.guildMember.set': <String>['key', 'value', 'userId?', 'guildId?'],
  'db.guildMember.delete': <String>['key', 'userId?', 'guildId?'],
  'db.guildMember.list': <String>['key', 'order?', 'limit?', 'offset?'],
  'db.guildMember.find': <String>['filter?'],
  'db.guildMember.reset': <String>['key'],

  // ── db.global ────────────────────────────────────────────────────────
  'db.global.get': <String>['key'],
  'db.global.set': <String>['key', 'value'],
  'db.global.delete': <String>['key'],
};

/// Signature du callable dans lequel se trouve le curseur [caretOffset], ou
/// `null` si le curseur n'est pas dans la liste d'arguments d'une API connue.
///
/// Algorithme : on avance de 0 au curseur en ignorant chaînes, templates et
/// commentaires, avec une pile d'ouvrants. L'ouvrante `(` ouverte la plus proche
/// du curseur donne le callable (chemin `a.b.c` juste avant) ; les virgules
/// comptées à la profondeur 0 de cette parenthèse donnent l'argument actif.
ScriptSignatureHint? jsSignatureHintAt(String text, int caretOffset) {
  final caret = caretOffset.clamp(0, text.length);
  final stack = <_CallFrame>[];
  var i = 0;

  while (i < caret) {
    // Texte d'un template : le sommet de la pile est un backtick.
    if (stack.isNotEmpty && stack.last.char == '`') {
      final char = text[i];
      if (char == r'\') {
        i += 2;
        continue;
      }
      if (char == '`') {
        stack.removeLast();
        i += 1;
        continue;
      }
      if (char == r'$' && i + 1 < caret && text[i + 1] == '{') {
        stack.add(_CallFrame('{', i + 1));
        i += 2;
        continue;
      }
      i += 1;
      continue;
    }

    final char = text[i];
    if (char == "'" || char == '"') {
      i = _skipQuoted(text, i, caret);
      continue;
    }
    if (char == r'/') {
      final next = i + 1 < caret ? text[i + 1] : '';
      if (next == '/') {
        final newline = text.indexOf('\n', i);
        i = newline < 0 || newline >= caret ? caret : newline + 1;
        continue;
      }
      if (next == '*') {
        final close = text.indexOf('*/', i + 2);
        i = close < 0 || close + 2 > caret ? caret : close + 2;
        continue;
      }
    }
    if (char == '`') {
      stack.add(_CallFrame('`', i));
      i += 1;
      continue;
    }
    if (char == ',') {
      if (stack.isNotEmpty && stack.last.char == '(') {
        stack.last.commas += 1;
      }
      i += 1;
      continue;
    }
    if (char == '(' || char == '[' || char == '{') {
      stack.add(_CallFrame(char, i));
      i += 1;
      continue;
    }
    final opener = _closers[char];
    if (opener != null) {
      if (stack.isNotEmpty && stack.last.char == opener) {
        stack.removeLast();
      }
      i += 1;
      continue;
    }
    i += 1;
  }

  _CallFrame? frame;
  for (var depth = stack.length - 1; depth >= 0; depth--) {
    if (stack[depth].char == '(') {
      frame = stack[depth];
      break;
    }
  }
  if (frame == null) {
    return null;
  }

  final name = _callableNameBefore(text, frame.offset);
  if (name == null) {
    return null;
  }
  final parameters = jsSignatureCatalog[name];
  if (parameters == null) {
    return null;
  }

  final lastIndex = parameters.length - 1;
  final active = lastIndex < 0
      ? 0
      : (frame.commas > lastIndex ? lastIndex : frame.commas);
  return ScriptSignatureHint(
    name: name,
    parameters: parameters,
    activeIndex: active,
  );
}

/// Un ouvrant de la pile d'analyse, avec les virgules de premier niveau vues
/// dans le cas d'une parenthèse d'appel.
class _CallFrame {
  _CallFrame(this.char, this.offset);

  final String char;
  final int offset;
  int commas = 0;
}

/// Ouvrante attendue pour chaque fermante.
const _closers = <String, String>{')': '(', ']': '[', '}': '{'};

/// Index juste après la guillemet fermante de la chaîne ouverte en [start], ou
/// [limit] si elle n'est pas fermée avant la limite / la fin de ligne.
int _skipQuoted(String text, int start, int limit) {
  final quote = text.codeUnitAt(start);
  var i = start + 1;
  while (i < limit) {
    final unit = text.codeUnitAt(i);
    if (unit == 0x5C) {
      i += 2;
      continue;
    }
    if (unit == quote) {
      return i + 1;
    }
    if (unit == 0x0A) {
      return i;
    }
    i += 1;
  }
  return limit;
}

/// Chemin du callable juste avant la parenthèse ouvrante située en
/// [openIndex] (`db.user.set`, `client.login`, `fetch`), ou `null` si rien de
/// tel ne la précède.
String? _callableNameBefore(String text, int openIndex) {
  var end = openIndex;
  while (end > 0 && _isSpace(text.codeUnitAt(end - 1))) {
    end -= 1;
  }
  final match = _pathPattern.firstMatch(text.substring(0, end));
  return match?.group(0);
}

final _pathPattern = RegExp(
  r'[A-Za-z_$][A-Za-z0-9_$]*(?:\.[A-Za-z_$][A-Za-z0-9_$]*)*$',
);

bool _isSpace(int unit) =>
    unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D;

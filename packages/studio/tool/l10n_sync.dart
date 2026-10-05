// Recopie dans les ARB du Studio les traductions que l'app possède déjà.
//
//   dart run tool/l10n_sync.dart          # écrit les ARB
//   dart run tool/l10n_sync.dart --check  # échoue si un ARB est périmé (CI)
//
// `tool/l10n_shared.json` associe une clé du Studio à une clé de l'app
// (`packages/ui/lib/src/l10n/app_<langue>.arb`). Pour ces clés, la
// valeur de l'app fait foi dans CHAQUE langue : on ne les retraduit pas et on ne
// les édite pas à la main dans les ARB du Studio. Les clés absentes de ce
// fichier sont propres au Studio et ne sont jamais touchées.
import 'dart:convert';
import 'dart:io';

const _appDir = '../ui/lib/src/l10n';
const _studioDir = 'lib/l10n';
const _locales = ['de', 'en', 'fr', 'ja', 'pt', 'tr'];

Map<String, dynamic> _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

String _encode(Map<String, dynamic> map) =>
    '${const JsonEncoder.withIndent('  ').convert(map)}\n';

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

void main(List<String> args) {
  final check = args.contains('--check');
  final shared = _read('tool/l10n_shared.json').cast<String, String>();
  final template = _read('$_studioDir/app_en.arb');
  final stale = <String>[];

  for (final locale in _locales) {
    final app = _read('$_appDir/app_$locale.arb');
    if (app.isEmpty) {
      _fail('ARB de l\'app introuvable : $_appDir/app_$locale.arb');
    }
    final path = '$_studioDir/app_$locale.arb';
    final current = _read(path);
    final next = <String, dynamic>{'@@locale': locale};

    // Ordre du modèle (anglais) : un diff lisible, indépendant de la langue.
    for (final key in template.keys) {
      if (key.startsWith('@')) continue;
      final appKey = shared[key];
      if (appKey != null) {
        final value = app[appKey];
        if (value is! String) {
          _fail(
            '$locale : la clé « $appKey » de l\'app n\'existe pas (voulue par « $key »).',
          );
        }
        // Un paramètre ICU ne se recopie pas aveuglément : il faudrait en plus
        // déclarer ses types dans le Studio.
        if (value.contains('{')) {
          _fail(
            '« $key » <- « $appKey » contient un paramètre ($value) : à écrire à la main.',
          );
        }
        next[key] = value;
      } else if (current.containsKey(key)) {
        next[key] = current[key];
        if (current.containsKey('@$key')) next['@$key'] = current['@$key'];
      } else if (locale == 'en' || locale == 'fr') {
        _fail(
          '$locale : la clé propre au Studio « $key » n\'a pas de traduction.',
        );
      }
    }

    final before = File(path).existsSync() ? File(path).readAsStringSync() : '';
    final after = _encode(next);
    if (before.replaceAll('\r\n', '\n') != after) {
      stale.add(path);
      if (!check) File(path).writeAsStringSync(after);
    }
  }

  if (check && stale.isNotEmpty) {
    _fail(
      'ARB périmés (lancez `dart run tool/l10n_sync.dart`) :\n  ${stale.join('\n  ')}',
    );
  }
  stdout.writeln(
    stale.isEmpty
        ? 'ARB à jour.'
        : 'ARB mis à jour : ${stale.map((p) => p.split('/').last).join(', ')}',
  );
}

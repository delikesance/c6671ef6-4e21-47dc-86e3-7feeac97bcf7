// Copyright 2026 Bot Creator. All rights reserved.
//
// Preuve que la typographie de l'application est 100% offline.
//
// Contexte : le redesign utilise `google_fonts` pour 5 familles (Inter,
// Space Grotesk, JetBrains Mono, Fira Code, Alexandria). Par défaut, dès
// qu'une famille n'est pas trouvée dans l'AssetManifest, le package émet un
// GET HTTPS vers fonts.gstatic.com : flash de police (FOUT) au premier rendu
// et perte totale de la typo si la machine est hors-ligne. Les 5 familles
// sont donc bundlées sous `assets/fonts/<famille>/` et le runtime fetching est
// désactivé.
//
// Ce test ne touche pas le réseau, à trois niveaux :
//   * `TestWidgetsFlutterBinding` bloque déjà tout HTTP réel (réponse 400) ;
//   * on installe en plus un `HttpOverrides` qui *lève* dès qu'une
//     `HttpClient` est créée — toute tentative de fetch ferait échouer le test ;
//   * on vérifie que chaque famille utilisée par le code est présente dans
//     l'AssetManifest, donc que la branche réseau du package n'est jamais
//     atteinte (`google_fonts_base.dart`, `loadFontIfNecessary`).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Répertoire d'assets sous lequel les 5 familles sont bundlées.
///
/// Le nom du dossier est libre (cf. README google_fonts, « Bundling fonts when
/// releasing ») : le package retrouve un fichier bundlé en comparant la *fin*
/// du nom de fichier au préfixe `<Famille>-<WeightPart>`. Le nom des fichiers,
/// lui, n'est pas libre.
const String kFontAssetDir = 'assets/fonts/';

/// Familles utilisées par l'app, groupe d'assets et fichiers attendus.
///
/// La convention de nommage (`Inter-Regular.ttf`, `Alexandria-Black.ttf`, ...)
/// est celle codée en dur dans google_fonts 6.3.3 :
/// `lib/src/google_fonts_variant.dart`, table
/// `_fontWeightToFilenameWeightParts` :
///   w100 Thin | w200 ExtraLight | w300 Light | w400 Regular | w500 Medium |
///   w600 SemiBold | w700 Bold | w800 ExtraBold | w900 Black
/// et `lib/src/google_fonts_family_with_variant.dart` :
///   `toApiFilenamePrefix() => '$family-${variant.toApiFilenamePart()}'`.
const Map<String, List<String>> kExpectedFontFiles = <String, List<String>>{
  'inter': <String>[
    'Inter-Regular',
    'Inter-Medium',
    'Inter-SemiBold',
    'Inter-Bold',
  ],
  'spacegrotesk': <String>['SpaceGrotesk-Regular', 'SpaceGrotesk-Bold'],
  'jetbrainsmono': <String>[
    'JetBrainsMono-Regular',
    'JetBrainsMono-SemiBold',
    'JetBrainsMono-Bold',
  ],
  'firacode': <String>['FiraCode-Regular', 'FiraCode-Bold'],
  'alexandria': <String>[
    'Alexandria-Regular',
    'Alexandria-Bold',
    'Alexandria-Black',
  ],
};

/// Un `HttpOverrides` qui rend toute création de client HTTP impossible.
///
/// Si `google_fonts` tentait un fetch réseau (`allowRuntimeFetching` repassé à
/// `true`, ou asset manquant), la requête échouerait ici au lieu de partir
/// silencieusement sur le réseau.
class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw UnsupportedError(
      'Réseau interdit pendant ce test : la typo doit venir des assets.',
    );
  }
}

/// Chemin d'asset attendu pour `<dir>/<file>.ttf`.
String _assetFor(String dir, String file) => '$kFontAssetDir$dir/$file.ttf';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpOverrides? previousHttpOverrides;

  setUpAll(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _NoNetworkHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = previousHttpOverrides;
  });

  setUp(() {
    // `lib/main.dart` exécute exactement cette ligne en tête de `main()`, avant
    // tout appel à `GoogleFonts.*`. Le process de test ne lance pas `main()` de
    // l'app, donc on la rejoue ici : c'est l'état de production que le reste du
    // fichier met à l'épreuve (voir aussi le garde-fou sur lib/main.dart).
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('allowRuntimeFetching est désactivé', () {
    expect(
      GoogleFonts.config.allowRuntimeFetching,
      isFalse,
      reason:
          'Le fetch runtime doit être coupé pour ne jamais contacter '
          'fonts.gstatic.com.',
    );
  });

  test('main.dart et pubspec.yaml câblent bien le mode offline', () {
    // Garde-fou anti-régression : la config ci-dessus n'est pas « inventée par
    // le test », elle est réellement appliquée par l'application au démarrage.
    // On lit les fichiers sources plutôt que de lancer `main()` (qui démarre
    // Firebase, PostHog, la DB…), ce qui rendrait le test très lourd.
    final mainSource = File('lib/main.dart').readAsStringSync();
    expect(
      mainSource,
      contains('GoogleFonts.config.allowRuntimeFetching = false'),
      reason: 'main() doit couper le runtime fetching avant tout rendu.',
    );
    expect(
      mainSource.indexOf('GoogleFonts.config.allowRuntimeFetching = false'),
      // lastIndexOf : indexOf('runApp(') matchait le commentaire du bloc
      // insere juste au-dessus ("well before runApp()"), pas l'appel reel.
      lessThan(mainSource.lastIndexOf('runApp(')),
      reason: 'La configuration doit précéder le premier runApp().',
    );

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/fonts/'));
    for (final family in <String>[
      'Inter',
      'SpaceGrotesk',
      'JetBrainsMono',
      'FiraCode',
      'Alexandria',
    ]) {
      expect(
        pubspec,
        contains('- family: $family'),
        reason: 'La famille $family doit être déclarée dans pubspec.yaml.',
      );
    }
  });

  test('chaque famille utilisée est présente dans l\'AssetManifest', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    for (final entry in kExpectedFontFiles.entries) {
      for (final file in entry.value) {
        final expected = '$kFontAssetDir${entry.key}/$file.ttf';
        expect(
          assets,
          contains(expected),
          reason:
              'Asset manquant : $expected. google_fonts ne le trouverait pas '
              'dans l\'AssetManifest et retomberait sur le réseau.',
        );
      }
    }
  });

  test(
    'le contrôle est non vacuose : une famille non bundlée est absente',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();

      // Lato n'est utilisée nulle part dans l'app et n'est donc pas bundlée.
      // Si cette assertion échouait, l'assertion précédente ne prouverait rien.
      expect(
        assets.where((a) => a.contains('Lato-')),
        isEmpty,
        reason: 'Ce test de contrôle doit rester vide pour être significatif.',
      );
    },
  );

  testWidgets(
    'GoogleFonts.inter(w600) rend le texte et résout la famille attendue',
    (tester) async {
      final style = GoogleFonts.inter(fontWeight: FontWeight.w600);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Text('Bot Creator', style: style)),
        ),
      );

      // Le texte est bien rendu.
      expect(find.text('Bot Creator'), findsOneWidget);

      // google_fonts résout la variante demandée -> famille synthétique
      // `<famille>_<variante>` avec la famille Google comme fallback bundlé.
      // google_fonts 6.3.3 enregistre la variante resolue sous
      // `<Famille>_<poids>` ('Inter_600'), l'ancien nommage
      // '<Famille>_<SemiBold>' n'existe plus : on verrouille l'essentiel,
      // a savoir que la famille Inter est bien resolue et servie en repli.
      expect(style.fontFamily, startsWith('Inter'));
      expect(style.fontFamilyFallback, contains('Inter'));
      expect(
        tester.widget<Text>(find.text('Bot Creator')).style?.fontFamily,
        startsWith('Inter'),
      );

      // Si l'asset `Inter-SemiBold.ttf` était introuvable, `allowRuntimeFetching`
      // étant false, le package lèverait une Exception (rethrow) : l'await
      // ci-dessous ferait donc échouer le test.
      await GoogleFonts.pendingFonts();
    },
  );

  testWidgets(
    'chaque famille/poids réellement utilisé par le code a son asset',
    (tester) async {
      // (style produit par google_fonts pour chaque call site de l'app) ->
      // fichier d'asset attendu.
      final cases = <String, ({TextStyle style, String asset})>{
        'homeDisplayStyle w600 (home_ui.dart:12)': (
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          asset: _assetFor('inter', 'Inter-SemiBold'),
        ),
        'homeDisplayStyle w400 override (home_page.dart:2918)': (
          style: GoogleFonts.inter(fontWeight: FontWeight.w400),
          asset: _assetFor('inter', 'Inter-Regular'),
        ),
        'nav labels w500/w700 (app_editor_page.dart:1078)': (
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          asset: _assetFor('inter', 'Inter-Bold'),
        ),
        'section label w700 (home_ui.dart:21)': (
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          asset: _assetFor('spacegrotesk', 'SpaceGrotesk-Bold'),
        ),
        'data chip w600 (home_page.dart:2782)': (
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600),
          asset: _assetFor('jetbrainsmono', 'JetBrainsMono-SemiBold'),
        ),
        'logs w400 (home.ui.part.dart:403/426)': (
          style: GoogleFonts.firaCode(),
          asset: _assetFor('firacode', 'FiraCode-Regular'),
        ),
        'app title w900 (home_page.dart:2426 getFont)': (
          style: GoogleFonts.getFont('Alexandria', fontWeight: FontWeight.w900),
          asset: _assetFor('alexandria', 'Alexandria-Black'),
        ),
      };

      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();

      for (final entry in cases.entries) {
        final resolved = entry.value.style.fontFamily;
        expect(
          resolved,
          isNotNull,
          reason: '${entry.key} : google_fonts doit résoudre une famille.',
        );
        expect(
          assets,
          contains(entry.value.asset),
          reason:
              '${entry.key} -> $resolved : aucun asset ne correspondrait, '
              'la famille serait donc récupérée par HTTP.',
        );
      }

      // Aucune de ces résolutions ne doit avoir déclenché d'erreur de fetch.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await GoogleFonts.pendingFonts();
    },
  );
}

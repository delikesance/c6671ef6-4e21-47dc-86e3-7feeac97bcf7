// Tests de la mise en page de la console de logs des bots clé en main.
//
// Deux exigences verrouillées ici :
//   1. DENSITÉ / LISIBILITÉ — une ligne de log = un horodatage discret aligné en
//      colonne + un message monospace respirant, la sévérité passant par la
//      couleur et non par des cadres empilés ; le bandeau du haut résume le
//      tampon (nombre d'erreurs).
//   2. SAFE AREA — le bas de l'écran (dernière ligne de log) ne doit plus être
//      recouvert par la barre de navigation Android. `Scaffold` ne réserve au
//      body que `viewInsets` (le clavier) : la barre système vit dans
//      `MediaQuery.padding`, qu'il faut consommer explicitement (SafeArea sur
//      l'écran de logs ouvert depuis l'accueil, padding sur la page de détail).
import 'dart:convert';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/containers/presentation/container_detail_page.dart';
import 'package:bot_creator/features/containers/presentation/home_turnkey_container_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const String _containerId = '95d85ac8-bd42-41c6-9392-3a1f0c9b7d21';

/// Hauteur de la barre de navigation Android simulée : c'est ce que le système
/// annonce dans `MediaQuery.padding.bottom` en mode bord à bord.
const double _navBarInset = 56;

/// Écran de téléphone : la barre du bas y mange une part visible du contenu.
const Size _phoneSize = Size(400, 800);

MainApiClient _clientWithLogs(String logs) {
  return MainApiClient(
    baseUrl: 'http://127.0.0.1:8080',
    accessToken: 'test-token',
    httpClient: MockClient((request) async {
      final body = request.url.path.endsWith('/logs')
          ? <String, dynamic>{'logs': logs}
          : <String, dynamic>{};
      return http.Response(
        jsonEncode(body),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    }),
  );
}

/// Monte la console de logs telle que l'écran d'accueil l'ouvre, dans un écran
/// de téléphone dont la barre de navigation recouvre les 56 derniers pixels.
Future<void> _pumpLogsPage(
  WidgetTester tester, {
  required String logs,
  double bottomInset = _navBarInset,
}) async {
  tester.view.physicalSize = _phoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: _phoneSize,
          padding: EdgeInsets.only(bottom: bottomInset),
          viewPadding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: HomeContainerLogsPage(
          client: _clientWithLogs(logs),
          containerId: _containerId,
          title: 'Easy Music Bot',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Démonte l'arbre pour que la minuterie de sondage de la console soit annulée
/// (sinon `flutter test` échoue sur « A Timer is still pending »).
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

/// Tampon de [count] lignes horodatées, terminé par un message reconnaissable.
String _logBuffer({int count = 60, String last = 'derniere ligne de log'}) {
  final buffer = StringBuffer();
  for (var index = 0; index < count; index++) {
    final seconds = (index % 60).toString().padLeft(2, '0');
    buffer.writeln('2026-09-19T10:00:${seconds}Z [INFO] evenement $index');
  }
  buffer.writeln('2026-09-19T10:01:00Z [INFO] $last');
  return buffer.toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Interdire le téléchargement des polices à l'exécution : une famille non
    // embarquée doit échouer bruyamment plutôt que partir sur le réseau.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('analyse des lignes', () {
    test('horodatage et niveau sont sortis du message', () {
      final line = parseContainerLogLines(
        '2026-09-19T12:34:56.789Z [ERROR] connexion refusee',
      ).single;

      expect(line.time, '12:34:56');
      expect(line.level, 'ERROR');
      expect(line.message, 'connexion refusee');
      expect(line.severity, ContainerLogSeverity.error);
      expect(line.isContinuation, isFalse);
      // La date complète n'est pas affichée : elle alourdirait chaque ligne.
      expect(line.time.length, 8);
    });

    test('accepte les formes courantes d\'horodatage et de niveau', () {
      final lines = parseContainerLogLines(
        '[09:15:00] INFO bot pret\n'
        '09:16:00 WARN latence elevee\n'
        '09:17:00 - DEBUG trace interne\n'
        'time=09:18:00 level=error echec',
      );

      expect(lines.map((line) => line.time).toList(), <String>[
        '09:15:00',
        '09:16:00',
        '09:17:00',
        '09:18:00',
      ]);
      expect(lines.map((line) => line.severity).toList(), <ContainerLogSeverity>[
        ContainerLogSeverity.info,
        ContainerLogSeverity.warn,
        ContainerLogSeverity.debug,
        ContainerLogSeverity.error,
      ]);
    });

    test('sans niveau explicite, le contenu décide', () {
      final lines = parseContainerLogLines(
        'Bot connecte\n'
        'Error: EACCES permission denied\n'
        'warning: memoire faible\n'
        '[bot] 42 commandes chargees',
      );

      expect(lines[0].severity, ContainerLogSeverity.info);
      expect(lines[0].time, isEmpty);
      expect(lines[0].level, isEmpty);
      expect(lines[1].severity, ContainerLogSeverity.error);
      expect(lines[2].severity, ContainerLogSeverity.warn);
      expect(lines[3].severity, ContainerLogSeverity.info);
    });

    test('une trace hérite de son en-tête, sinon elle est atténuée', () {
      final lines = parseContainerLogLines(
        'Error: boom\n'
        '    at handler.js:42\n'
        '    at next.js:7\n'
        'INFO bot pret\n'
        '    details internes',
      );

      expect(lines[1].isContinuation, isTrue);
      // Le bloc d'erreur se lit d'un seul tenant, sans compter 10 erreurs.
      expect(lines[1].severity, ContainerLogSeverity.error);
      expect(lines[2].severity, ContainerLogSeverity.error);
      expect(lines[4].isContinuation, isTrue);
      expect(lines[4].severity, ContainerLogSeverity.debug);
    });

    test('les séquences ANSI et les lignes vides sont écartées', () {
      final lines = parseContainerLogLines(
        '\u001B[31m2026-09-19T10:00:00Z [INFO] rouge\u001B[0m\n'
        '\n'
        '   \n',
      );

      expect(lines.length, 1);
      expect(lines.single.message, 'rouge');
    });
  });

  testWidgets('le bas de la console reste au-dessus de la barre Android', (
    tester,
  ) async {
    await _pumpLogsPage(tester, logs: _logBuffer());

    expect(tester.takeException(), isNull);

    // L'inset bas est bien consommé par l'écran de logs.
    final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
    expect(
      safeAreas.any((area) => area.bottom),
      isTrue,
      reason: 'La console doit réserver la barre de navigation système.',
    );

    // Le défilement est mené jusqu'en bas : la dernière ligne existe.
    await tester.drag(find.byType(ListView), const Offset(0, -10000));
    await tester.pumpAndSettle();
    final lastLine = find.text('derniere ligne de log');
    expect(lastLine, findsOneWidget);

    final lastRect = tester.getRect(lastLine);
    final viewerRect = tester.getRect(find.byType(ContainerLogsViewer));
    final usableBottom = _phoneSize.height - _navBarInset;

    // Sans SafeArea, la console s'étendait jusqu'à 800 - 12 = 788 px : la
    // dernière ligne (≈ 781 px de bas) tombait sous la barre système.
    expect(
      viewerRect.bottom,
      lessThanOrEqualTo(usableBottom),
      reason: 'La console est recouverte par la barre de navigation Android.',
    );
    expect(
      lastRect.bottom,
      lessThanOrEqualTo(usableBottom),
      reason: 'La dernière ligne de log est sous la barre de navigation.',
    );
    // La ligne est bien atteinte : l'assertion ci-dessus n'est pas vide.
    expect(lastRect.top, lessThan(usableBottom));
  });

  testWidgets('sans inset système, la console occupe tout le bas de l\'écran', (
    tester,
  ) async {
    // Contre-épreuve du test précédent : ce que la correction change est
    // exactement la réservation de l'inset, pas une réduction générale.
    await _pumpLogsPage(tester, logs: _logBuffer(), bottomInset: 0);

    final viewerRect = tester.getRect(find.byType(ContainerLogsViewer));
    expect(viewerRect.bottom, closeTo(_phoneSize.height - 12, 1));
  });

  testWidgets(
    'une ligne de log : horodatage discret, message monospace, erreur distinguable',
    (tester) async {
      await _pumpLogsPage(
        tester,
        logs: '2026-09-19T10:00:00Z [INFO] bot pret\n'
            '2026-09-19T10:00:05Z [ERROR] connexion Discord refusee\n'
            '    at handler.js:42\n'
            '2026-09-19T10:00:09Z [INFO] reprise du service\n'
            '2026-09-19T10:00:12Z [ERROR] second echec\n',
      );

      // Une ligne = un widget : aucun cadre ni badge ajouté par ligne.
      expect(find.byType(ContainerLogRow), findsNWidgets(5));

      // L'horodatage est une colonne à part, déjà débarrassé du niveau et du
      // message : il ne se relit pas au milieu du texte.
      expect(find.byKey(ContainerLogRow.timeKey), findsNWidgets(4));
      expect(find.text('10:00:00'), findsOneWidget);
      expect(find.text('bot pret'), findsOneWidget);
      expect(find.byKey(ContainerLogRow.messageKey), findsNWidgets(5));

      // Le bandeau compte les erreurs d'un coup d'œil, sans dérouler 200 lignes.
      expect(find.text('2 erreurs'), findsOneWidget);

      final messageStyle = tester
          .widget<Text>(
            find.byKey(ContainerLogRow.messageKey).first,
          )
          .style!;
      expect(messageStyle.fontFamily, 'monospace');
      expect(messageStyle.fontSize, greaterThanOrEqualTo(12));
      // Interlignage confortable : on lit une ligne sans plisser les yeux.
      expect(messageStyle.height, greaterThanOrEqualTo(1.4));

      final errorRow = tester.widgetList<ContainerLogRow>(
        find.byType(ContainerLogRow),
      ).firstWhere((row) => row.line.severity == ContainerLogSeverity.error);
      // Une trace hérite volontairement du fond de son en-tête : deux widgets
      // portent donc cette couleur. On prend le PREMIER (la ligne d'en-tête),
      // puisque c'est l'ordre de rendu.
      final errorDecoration =
          tester.widgetList<Container>(find.byWidgetPredicate((widget) {
            return widget is Container &&
                widget.child is Row &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).color ==
                    AppTheme.error.withValues(alpha: 0.10);
          })).first.decoration! as BoxDecoration;
      expect(errorRow.line.level, 'ERROR');
      expect(
        (errorDecoration.border! as Border).left.color,
        AppTheme.errorLight,
      );
      expect(
        tester
            .widget<Text>(find.text('connexion Discord refusee'))
            .style!
            .fontWeight,
        FontWeight.w600,
      );

      // Une ligne normale n'a AUCUN cadre : c'est la sobriété qui fait la
      // lisibilité, l'erreur ressort par contraste.
      final infoContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('bot pret'),
              matching: find.byType(Container),
            )
            .first,
      );
      final infoDecoration = infoContainer.decoration! as BoxDecoration;
      expect(infoDecoration.color, isNull);
      expect(infoDecoration.border, isNull);

      // La ligne de trace est en retrait, alignée sur la colonne du message.
      final traceRow = tester.widgetList<ContainerLogRow>(
        find.byType(ContainerLogRow),
      ).firstWhere((row) => row.line.isContinuation);
      expect(traceRow.line.severity, ContainerLogSeverity.error);
      expect(
        traceRow.line.displayMessage,
        'at handler.js:42',
      );
      expect(traceRow.showTime, isTrue);

      await _disposeTree(tester);
    },
  );

  testWidgets('une console sans erreur le dit calmement', (tester) async {
    await _pumpLogsPage(
      tester,
      logs: '2026-09-19T10:00:00Z [INFO] bot pret\n',
    );

    expect(find.text('Aucune erreur'), findsOneWidget);
    // Aucun cadre d'alerte à l'écran.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                AppTheme.error.withValues(alpha: 0.10),
      ),
      findsNothing,
    );

    await _disposeTree(tester);
  });

  testWidgets('le tampon brut se copie depuis la console', (tester) async {
    final logs = _logBuffer(count: 3, last: 'derniere ligne de log');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pumpLogsPage(tester, logs: logs);

    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pumpAndSettle();

    // C'est le tampon d'origine qui part dans le presse-papiers, pas la version
    // mise en page par l'application.
    expect(copied, logs);
    expect(find.text('Logs copiés'), findsOneWidget);

    await _disposeTree(tester);
  });
}

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/editor_sidebar.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sections de test : la sidebar est purement présentationnelle, donc les
/// libellés viennent de l'appelant (comme `app_editor_page` le fait avec ses
/// entrées localisées).
const _sections = <EditorSidebarSection>[
  EditorSidebarSection(
    title: 'ACCUEIL',
    items: [
      EditorSidebarItem(
        id: 'home',
        icon: Icons.dashboard_rounded,
        label: 'Tableau de bord',
      ),
    ],
  ),
  EditorSidebarSection(
    title: 'MODULES',
    items: [
      EditorSidebarItem(
        id: 'workflows',
        icon: Icons.account_tree_outlined,
        label: 'Workflows',
      ),
      EditorSidebarItem(
        id: 'globals',
        icon: Icons.data_object_rounded,
        label: 'Variables globales',
      ),
    ],
  ),
];

/// URL d'icône factice : jamais téléchargée en test (le réseau y répond 400),
/// seule la valeur transmise au composant d'avatar est vérifiée.
const _avatarUrl = 'https://cdn.discordapp.com/avatars/123456789/abc.webp';

/// Harnais : possède l'état `collapsed` comme le fait `_AppEditPageState`,
/// pour tester la vraie boucle de repli/dépli (callback → reconstruction).
class _SidebarHarness extends StatefulWidget {
  const _SidebarHarness({
    this.initialCollapsed = false,
    this.isDrawer = false,
    this.avatarUrl,
  });

  final bool initialCollapsed;
  final bool isDrawer;
  final String? avatarUrl;

  @override
  State<_SidebarHarness> createState() => _SidebarHarnessState();
}

class _SidebarHarnessState extends State<_SidebarHarness> {
  late bool collapsed = widget.initialCollapsed;
  String activeId = 'workflows';
  int beginnerToggleCount = 0;

  @override
  Widget build(BuildContext context) {
    final sidebar = EditorSidebar(
      appName: 'Météo Bot',
      botId: '123456789',
      avatarUrl: widget.avatarUrl,
      sections: _sections,
      activeItemId: activeId,
      collapsed: collapsed,
      onToggleCollapsed: () => setState(() => collapsed = !collapsed),
      onSelectItem: (id) => setState(() => activeId = id),
      onBack: () {},
      isDrawer: widget.isDrawer,
      showBeginnerMode: true,
      beginnerMode: false,
      onBeginnerModeChanged: (_) => setState(() => beginnerToggleCount++),
    );

    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: widget.isDrawer
            // Le tiroir impose sa largeur au contenu : on reproduit la même
            // situation (pas de contrainte de largeur côté sidebar).
            ? sidebar
            // Desktop : colonne fixe dans une ligne, comme l'éditeur.
            : Row(
                children: [
                  sidebar,
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
      ),
    );
  }
}

Future<_SidebarHarnessState> _pumpSidebar(
  WidgetTester tester, {
  bool collapsed = false,
  bool isDrawer = false,
  String? avatarUrl,
  Size size = const Size(1200, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _SidebarHarness(
      initialCollapsed: collapsed,
      isDrawer: isDrawer,
      avatarUrl: avatarUrl,
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_SidebarHarnessState>(find.byType(_SidebarHarness));
}

void main() {
  testWidgets(
    'déplié (1200 px) : libellés visibles et bouton de repli présent',
    (tester) async {
      await _pumpSidebar(tester);

      expect(
        tester.getSize(find.byType(EditorSidebar)).width,
        EditorSidebar.expandedWidth,
      );
      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(find.text('Workflows'), findsOneWidget);
      expect(find.text('Variables globales'), findsOneWidget);
      expect(find.text('MODULES'), findsOneWidget);
      expect(find.byTooltip('Collapse sidebar'), findsOneWidget);
      expect(find.byTooltip('Expand sidebar'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'replié via le bouton : largeur animée vers 72, libellés masqués, tooltips conservés',
    (tester) async {
      await _pumpSidebar(tester);

      await tester.tap(find.byTooltip('Collapse sidebar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midWidth = tester.getSize(find.byType(EditorSidebar)).width;
      expect(midWidth, greaterThan(EditorSidebar.collapsedWidth));
      expect(midWidth, lessThan(EditorSidebar.expandedWidth));

      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(EditorSidebar)).width,
        EditorSidebar.collapsedWidth,
      );

      // Les libellés disparaissent…
      expect(find.text('Tableau de bord'), findsNothing);
      expect(find.text('Workflows'), findsNothing);
      expect(find.text('Variables globales'), findsNothing);
      expect(find.text('MODULES'), findsNothing);

      // …mais aucune information n'est perdue : chaque item garde son tooltip,
      // le retour, le dépli et le mode débutant restent accessibles.
      expect(find.byTooltip('Tableau de bord'), findsOneWidget);
      expect(find.byTooltip('Workflows'), findsOneWidget);
      expect(find.byTooltip('Variables globales'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byTooltip('Expand sidebar'), findsOneWidget);
      expect(find.byTooltip('Beginner mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('construit replié : état cohérent dès le premier rendu', (
    tester,
  ) async {
    await _pumpSidebar(tester, collapsed: true);

    expect(
      tester.getSize(find.byType(EditorSidebar)).width,
      EditorSidebar.collapsedWidth,
    );
    expect(find.text('Workflows'), findsNothing);
    expect(find.byTooltip('Workflows'), findsOneWidget);
    expect(find.byTooltip('Expand sidebar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transition 256 → 72 → 256 : aucune exception de débordement', (
    tester,
  ) async {
    await _pumpSidebar(tester);

    await tester.tap(find.byTooltip('Collapse sidebar'));
    await tester.pump();
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull, reason: 'repli, frame $frame');
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Expand sidebar'));
    await tester.pump();
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull, reason: 'dépli, frame $frame');
    }
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(EditorSidebar)).width,
      EditorSidebar.expandedWidth,
    );
    expect(find.text('Workflows'), findsOneWidget);
  });

  testWidgets('rail : items et mode débutant restent actionnables', (
    tester,
  ) async {
    final state = await _pumpSidebar(tester, collapsed: true);

    await tester.tap(find.byTooltip('Variables globales'));
    await tester.pumpAndSettle();
    expect(state.activeId, 'globals');

    expect(state.beginnerToggleCount, 0);
    await tester.tap(find.byTooltip('Beginner mode'));
    await tester.pump();
    expect(state.beginnerToggleCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tiroir compact : pas de bouton de repli, libellés visibles (mobile inchangé)',
    (tester) async {
      await _pumpSidebar(tester, isDrawer: true, size: const Size(420, 800));

      expect(find.text('Workflows'), findsOneWidget);
      expect(find.text('MODULES'), findsOneWidget);
      expect(find.byTooltip('Collapse sidebar'), findsNothing);
      expect(find.byTooltip('Expand sidebar'), findsNothing);
      expect(find.text('Beginner mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  // ── Icône du bot dans le rail (avatarUrl) ──────────────────────────────────

  testWidgets('rail + avatarUrl : l\'icône du bot remplace la lettre', (
    tester,
  ) async {
    await _pumpSidebar(tester, collapsed: true, avatarUrl: _avatarUrl);

    // Largeur du rail, tooltip d'identité et boutons : inchangés.
    expect(
      tester.getSize(find.byType(EditorSidebar)).width,
      EditorSidebar.collapsedWidth,
    );
    expect(find.byTooltip('Météo Bot\nID 123456789'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Expand sidebar'), findsOneWidget);

    // L'avatar standard de l'app est utilisé, avec l'URL du bot et la taille
    // exacte de la pastille historique (36 px).
    final avatar = tester.widget<HomeBotAvatar>(find.byType(HomeBotAvatar));
    expect(avatar.imageUrl, _avatarUrl);
    expect(avatar.size, 36);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rail sans avatar (absent ou vide) : la pastille-lettre historique est identique',
    (tester) async {
      // Avatar absent : aucun widget d'avatar n'est construit (donc aucun
      // accès réseau), et la lettre du nom est affichée.
      await _pumpSidebar(tester, collapsed: true);
      expect(find.byType(HomeBotAvatar), findsNothing);
      expect(find.text('M'), findsOneWidget);
      expect(find.byTooltip('Météo Bot\nID 123456789'), findsOneWidget);

      // Avatar vide : strictement le même repli.
      await _pumpSidebar(tester, collapsed: true, avatarUrl: '');
      expect(find.byType(HomeBotAvatar), findsNothing);
      expect(find.text('M'), findsOneWidget);

      // Même carré (36 px, fond primaire à 12 %, coins arrondis), même lettre
      // (14 px, gras, couleur primaire) qu'avant l'ajout de l'icône.
      final theme = Theme.of(tester.element(find.text('M')));
      final letter = tester.widget<Text>(find.text('M'));
      expect(letter.style?.fontSize, 14);
      expect(letter.style?.fontWeight, FontWeight.w700);
      expect(letter.style?.color, theme.colorScheme.primary);

      final badge = tester.widget<Container>(
        find
            .ancestor(of: find.text('M'), matching: find.byType(Container))
            .first,
      );
      final decoration = badge.decoration! as BoxDecoration;
      expect(
        decoration.color,
        theme.colorScheme.primary.withValues(alpha: 0.12),
      );
      expect(decoration.borderRadius, BorderRadius.circular(AppTheme.radiusSm));
      expect(badge.constraints, BoxConstraints.tightFor(width: 36, height: 36));

      expect(find.byTooltip('Météo Bot\nID 123456789'), findsOneWidget);
      expect(
        tester.getSize(find.byType(EditorSidebar)).width,
        EditorSidebar.collapsedWidth,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('déplié avec avatarUrl : la mise en page ne change pas', (
    tester,
  ) async {
    await _pumpSidebar(tester, avatarUrl: _avatarUrl);

    expect(
      tester.getSize(find.byType(EditorSidebar)).width,
      EditorSidebar.expandedWidth,
    );
    expect(find.text('Météo Bot'), findsOneWidget);
    expect(find.text('ID 123456789'), findsOneWidget);
    // Le mode déplié garde nom + ID : l'avatar n'y est pas consommé.
    expect(find.byType(HomeBotAvatar), findsNothing);
    expect(find.byTooltip('Collapse sidebar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

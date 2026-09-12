// Tests de la variante inline de `FloatingGlassNavBar` (bandeaux de
// sous-navigation de l'éditeur de bot : pastilles modules/système et onglets
// Général / Présence & Statut / Lavalink / …).
//
// Elle doit partager le langage visuel de la barre flottante du shell
// (`AppTheme.homeNavBar` + fond sélectionné `AppTheme.homeNavSelected`) tout en
// restant plus courte (56 px) et sans positionnement flottant. La variante
// flottante, elle, doit garder exactement sa signature historique (hauteur 64,
// `DecoratedBox` peint avec `AppTheme.homeNavBar`, items de largeur égale).
//
// Le thème dark est construit à la main (`ThemeData(brightness: dark)`) plutôt
// qu'avec `AppTheme.darkTheme()` : seules les couleurs constantes du thème sont
// nécessaires ici, et cela évite tout recours à `google_fonts` (polices non
// disponibles en test).
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `DecoratedBox` peint avec le fond « verre dépoli » de la nav.
final Finder _glassSurfaceFinder = find.byWidgetPredicate(
  (widget) =>
      widget is DecoratedBox &&
      widget.decoration is BoxDecoration &&
      (widget.decoration as BoxDecoration).color == AppTheme.homeNavBar,
  description: 'surface de navigation (fond AppTheme.homeNavBar)',
);

FloatingGlassNavItem _item(
  String label, {
  required bool selected,
  VoidCallback? onTap,
}) => FloatingGlassNavItem(
  icon: Icons.circle_outlined,
  selectedIcon: Icons.circle,
  label: label,
  selected: selected,
  onTap: onTap ?? () {},
);

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(brightness: Brightness.dark),
  home: Scaffold(
    body: Align(alignment: Alignment.topCenter, child: child),
  ),
);

/// Libellé de l'item inline sélectionné.
///
/// La sélection est repérée par sa graisse (`w600`, contre `w500` au repos) et
/// non plus par une couleur codée en dur : le remplissage dépend désormais du
/// thème (rôle M3 `secondaryContainer`), pour qu'aucun violet ne subsiste dans
/// la navigation.
String? _selectedInlineLabel(WidgetTester tester) {
  for (final element in find.byType(Text, skipOffstage: false).evaluate()) {
    final text = element.widget as Text;
    if (text.style?.fontWeight == FontWeight.w600) {
      return text.data;
    }
  }
  return null;
}

/// Reproduit le câblage de `_SettingsTabsNav` (page Paramètres du bot) :
/// bandeau inline dans `AppBar.bottom`, branché sur le `TabController` du
/// `DefaultTabController` parent. Le test verrouille le contrat : tap et swipe
/// pilotent le `TabBarView`, et l'item sélectionné suit le `TabController`.
class _TabsNavHarness extends StatelessWidget implements PreferredSizeWidget {
  const _TabsNavHarness({required this.labels});

  final List<String> labels;

  @override
  Size get preferredSize =>
      const Size.fromHeight(FloatingGlassNavBar.inlinePreferredHeight);

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final animation = controller.animation;
    if (animation == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FloatingGlassNavBar.inlineHorizontalMargin,
        vertical: FloatingGlassNavBar.inlineVerticalMargin,
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final selectedIndex = animation.value.round().clamp(
            0,
            labels.length - 1,
          );
          return FloatingGlassNavBar.inline(
            scrollable: true,
            items: [
              for (var i = 0; i < labels.length; i++)
                _item(
                  labels[i],
                  selected: selectedIndex == i,
                  onTap: () => controller.animateTo(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

void main() {
  testWidgets('variante inline : plus courte, même fond en verre dépoli', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          child: FloatingGlassNavBar.inline(
            items: [
              _item('Général', selected: true),
              _item('Présence', selected: false),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Même signature visuelle que la nav de la Home.
    expect(_glassSurfaceFinder, findsOneWidget);

    // Hauteur inline : plus courte que la barre flottante (64).
    expect(
      FloatingGlassNavBar.inlineHeight,
      lessThan(FloatingGlassNavBar.defaultHeight),
    );
    final barSize = tester.getSize(
      find.descendant(
        of: find.byType(FloatingGlassNavBar),
        matching: _glassSurfaceFinder,
      ),
    );
    expect(barSize.height, FloatingGlassNavBar.inlineHeight);

    // Item sélectionné : même fond que l'item sélectionné de la Home nav.
    final selectedContainer = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byTooltip('Général'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    // Item sélectionné : remplissage piloté par le THÈME (rôle M3
    // `secondaryContainer`) et non plus par la constante violette
    // `homeNavSelected` — la sélection doit rester neutre dans tous les thèmes.
    final navContext = tester.element(find.byType(FloatingGlassNavBar).first);
    final expectedFill = Theme.of(navContext).colorScheme.secondaryContainer;
    expect((selectedContainer.decoration as BoxDecoration).color, expectedFill);
    // Item inactif : pas de fond.
    final idleContainer = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byTooltip('Présence'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      (idleContainer.decoration as BoxDecoration).color,
      Colors.transparent,
    );
  });

  testWidgets('variante inline non scrollable : largeurs égales et onTap', (
    tester,
  ) async {
    var tappedSecond = false;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 400,
          child: FloatingGlassNavBar.inline(
            items: [
              _item('Tableau de bord', selected: true),
              _item(
                'Paramètres',
                selected: false,
                onTap: () => tappedSecond = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = tester.getSize(find.byTooltip('Tableau de bord'));
    final second = tester.getSize(find.byTooltip('Paramètres'));
    expect(first.width, second.width);
    // Les items se partagent la largeur : (400 - 2 * inset - gap) / 2.
    expect(
      first.width,
      (400 - 2 * FloatingGlassNavBar.inset - FloatingGlassNavBar.itemGap) / 2,
    );

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pump();
    expect(tappedSecond, isTrue);
  });

  testWidgets(
    'variante inline scrollable : items intrinsèques, pas de débordement',
    (tester) async {
      const labels = [
        'Flux',
        'Vars',
        'Planif',
        'Webhooks',
        'Emojis',
        'Serveurs',
      ];
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: FloatingGlassNavBar.inline(
              scrollable: true,
              items: [
                for (final label in labels) _item(label, selected: false),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Aucun débordement de layout : le bandeau défile au lieu de comprimer.
      expect(tester.takeException(), isNull);

      // Tous les items sont construits, à leur largeur minimale confortable…
      for (final label in labels) {
        expect(find.byTooltip(label), findsOneWidget);
        expect(
          tester.getSize(find.byTooltip(label)).width,
          greaterThanOrEqualTo(FloatingGlassNavBar.inlineScrollItemMinWidth),
        );
      }

      // …et les derniers sont hors du champ visible (le contenu défile).
      expect(
        tester.getTopLeft(find.byTooltip(labels.last)).dx,
        greaterThan(320 - FloatingGlassNavBar.inlineHorizontalMargin),
      );
    },
  );

  testWidgets(
    'bandeau inline dans AppBar.bottom : tap et swipe pilotent le TabBarView',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Paramètres'),
                bottom: const _TabsNavHarness(
                  labels: ['Général', 'Présence & Statut', 'Lavalink'],
                ),
              ),
              body: const TabBarView(
                children: [Text('page-1'), Text('page-2'), Text('page-3')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Le bandeau inline remplace le TabBar : pas de débordement, même verre.
      expect(tester.takeException(), isNull);
      expect(find.byType(TabBar), findsNothing);
      expect(_glassSurfaceFinder, findsOneWidget);

      // Onglet initial.
      expect(find.text('page-1'), findsOneWidget);
      expect(_selectedInlineLabel(tester), 'Général');

      // Tap sur le dernier onglet : le TabBarView suit.
      await tester.tap(find.byTooltip('Lavalink'));
      await tester.pumpAndSettle();
      expect(find.text('page-3'), findsOneWidget);
      expect(_selectedInlineLabel(tester), 'Lavalink');

      // Swipe vers la droite : la sélection revient à l'onglet précédent.
      // `fling` (et non `drag`) : sur la surface de test de 800 px, un drag de
      // 400 px vaut exactement la moitié du viewport, seuil où le PageView
      // retombe sur sa page courante.
      await tester.fling(find.byType(TabBarView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('page-2'), findsOneWidget);
      expect(_selectedInlineLabel(tester), 'Présence & Statut');
    },
  );

  testWidgets('variante flottante : signature historique inchangée', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 400,
          child: FloatingGlassNavBar(
            items: [
              _item('Accueil', selected: true),
              _item('Cmd', selected: false),
              _item('Modules', selected: false),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_glassSurfaceFinder, findsOneWidget);
    final barSize = tester.getSize(
      find.descendant(
        of: find.byType(FloatingGlassNavBar),
        matching: _glassSurfaceFinder,
      ),
    );
    expect(barSize.height, FloatingGlassNavBar.defaultHeight);

    // Items de largeur égale, libellés exposés via leur tooltip.
    final widths = [
      for (final label in ['Accueil', 'Cmd', 'Modules'])
        tester.getSize(find.byTooltip(label)).width,
    ];
    expect(widths[0], widths[1]);
    expect(widths[1], widths[2]);
    expect(
      widths.first,
      greaterThan(FloatingGlassNavBar.inlineScrollItemMinWidth),
    );
  });
}

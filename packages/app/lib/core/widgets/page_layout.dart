import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:flutter/widgets.dart';

/// Vrai quand le chrome de la fenêtre fournit **déjà** la navigation arrière.
///
/// Sur les plateformes desktop, la barre de titre du shell affiche sa propre
/// flèche de retour (elle observe le `Navigator` : `DesktopTitleBarNotifier`)
/// au-dessus de la page. Une page qui rend en plus son propre bouton de retour
/// affiche donc deux flèches empilées. Sur mobile il n'y a pas de barre de
/// titre : la page reste seule responsable de son échappatoire.
bool windowChromeOwnsBackButton() => ResponsiveHelper.isDesktopPlatform();

/// Largeur de contenu et marges **communes à toutes les pages** de l'app.
///
/// Avant cette classe, chaque page codait sa propre respiration
/// (`maxWidth: 600` pour les réglages, `760` pour les listes, `1000` pour le
/// dashboard, `1200` pour l'accueil bot, et du plein-cadre à 12 px ailleurs) :
/// la même fenêtre affichait des marges de 12 px sur une page et de 660 px sur
/// la suivante. Une page ne doit plus jamais écrire ses propres bornes : elle
/// enveloppe son contenu dans [PageContent].
///
/// Ajuster la respiration de toute l'interface = modifier [maxContentWidth] et
/// [horizontalPadding] ici, et nulle part ailleurs.
abstract final class AppPageLayout {
  /// Largeur maximale du contenu centré quand la zone disponible est large.
  static const double maxContentWidth = 1200;

  /// Largeur maximale du contenu sur une zone compacte (téléphone, fenêtre
  /// rétrécie, ou zone réduite par la barre latérale de l'éditeur).
  static const double compactMaxContentWidth = 640;

  /// Marge horizontale appliquée quand la zone disponible est large.
  static const double horizontalPadding = AppTheme.spacingXxl;

  /// Marge horizontale appliquée quand la zone disponible est compacte.
  static const double compactHorizontalPadding = AppTheme.spacingLg;

  /// Vrai quand la zone disponible accepte la mise en page large.
  ///
  /// Le seuil est celui de l'app ([AppTheme.desktopBreakpoint]) : au-delà, la
  /// barre latérale de l'éditeur est déployée.
  static bool isWide(double availableWidth) =>
      availableWidth >= AppTheme.desktopBreakpoint;

  /// Largeur maximale du contenu pour une zone de largeur [availableWidth].
  static double contentMaxWidthFor(double availableWidth) =>
      isWide(availableWidth) ? maxContentWidth : compactMaxContentWidth;

  /// Marge horizontale pour une zone de largeur [availableWidth].
  static double horizontalPaddingFor(double availableWidth) =>
      isWide(availableWidth) ? horizontalPadding : compactHorizontalPadding;

  /// Marges horizontales pour une zone de largeur [availableWidth].
  static EdgeInsets paddingFor(double availableWidth) =>
      EdgeInsets.symmetric(horizontal: horizontalPaddingFor(availableWidth));
}

/// Enveloppe standard du contenu d'une page : centre le contenu et applique la
/// largeur maximale et les marges communes.
///
/// Se base sur la largeur **réellement disponible** (`LayoutBuilder`) et non sur
/// celle de la fenêtre : dans le shell de l'éditeur, la barre latérale retire
/// déjà quelques centaines de pixels.
///
/// Le défilement reste à la charge de l'enfant (`ListView`,
/// `SingleChildScrollView`) : l'enveloppe n'impose aucune contrainte de hauteur,
/// ce qui laisse chaque page réserver son bas de liste (barre de navigation
/// flottante, barre d'action) comme avant.
class PageContent extends StatelessWidget {
  const PageContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Contenu de la page (généralement un `ListView` ou un `Column` défilant).
  final Widget child;

  /// Force une largeur maximale différente de la valeur commune. Réservé aux
  /// contenus volontairement étroits (états vides, formulaires courts) — jamais
  /// pour « rattraper » la largeur d'une page qui devrait suivre la commune.
  final double? maxWidth;

  /// Force des marges différentes de la valeur commune.
  final EdgeInsets? padding;

  /// Alignement du bloc dans la zone disponible.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? AppPageLayout.contentMaxWidthFor(available),
            ),
            child: Padding(
              padding: padding ?? AppPageLayout.paddingFor(available),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

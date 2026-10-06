// Règle produit : le mapping serveur (catalogue de formules) décrit des CAPACITÉS — à
// quelle formule correspond quel achat, quels droits elle porte. L'affichage des offres est
// une fonctionnalité de l'application : ses cartes, ses textes, sa mise en page.
//
// Ce test verrouille la règle : l'écran des abonnements ne doit plus RENDRE le catalogue
// serveur. Sans lui, un « affichons aussi les formules » réintroduirait une interface qui
// change quand on renomme une formule dans l'administration, et un bouton d'achat mort pour
// toute formule sans SKU mappé (c'est exactement ce que produisait l'ancien bloc
// « Formules disponibles », avec son message « Cette offre est actuellement indisponible »).
//
// Le seul usage autorisé du catalogue côté application est l'enregistrement des SKUs, pour
// que le store reconnaisse les achats.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('l\'écran des abonnements ne rend pas le catalogue serveur', () {
    // L'écran est celui de `bot_creator_ui` (partagé avec le Studio) ; l'app en
    // garde l'enveloppe et l'hôte (où vit l'enregistrement des SKUs).
    final source = [
      '../ui/lib/src/subscriptions/subscriptions_hub_page.dart',
      'lib/features/subscriptions/presentation/subscriptions_hub_page.dart',
      'lib/features/subscriptions/presentation/app_subscriptions_host.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    for (final forbidden in <String>[
      'plans_catalog',
      '_PlanCatalogTile',
      'PurchasablePlanInfo',
    ]) {
      expect(
        source.contains(forbidden),
        isFalse,
        reason:
            'l\'écran ne doit plus afficher le catalogue serveur (trouvé : $forbidden). '
            'Les offres montrées à l\'utilisateur sont une fonctionnalité de l\'application ; '
            'le mapping serveur ne sert qu\'aux capacités.',
      );
    }

    expect(
      source.contains('registerPurchasableProductIds'),
      isTrue,
      reason:
          'le catalogue reste nécessaire pour que le store reconnaisse les SKUs des '
          'formules : le retrait doit porter sur l\'affichage, pas sur les capacités',
    );
  });
}

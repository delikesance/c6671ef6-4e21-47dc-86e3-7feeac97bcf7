/// Contrat entre l'écran « Crédits IA » (portefeuille, historique, packs,
/// roulette — partagé) et la façon dont chaque client parle au Manager : l'app
/// passe par `MainApiClient` (session locale, publicités récompensées, achat de
/// packs en boutique), le Studio par `StudioApi` en LECTURE SEULE (solde et
/// historique).
///
/// La roulette, les publicités et l'achat de packs sont des CAPACITÉS à valeur
/// par défaut « non » : le Manager n'a aucun paiement web (voir
/// `SubscriptionsHost`). L'écran masque ce qui manque, comme l'app le fait sur
/// poste de travail.
library;

import 'package:flutter/widgets.dart';

/// Un pack de crédits IA vendu dans la boutique, tel que l'écran l'affiche.
class AiCreditsPack {
  const AiCreditsPack({
    required this.id,
    required this.title,
    required this.price,
    required this.credits,
  });

  final String id;
  final String title;

  /// Prix formaté par la boutique.
  final String price;

  /// Crédits donnés (tokens), calculés par le serveur ; `0` si inconnu.
  final int credits;
}

/// Ce qui arrive à un achat de pack après son lancement.
enum AiCreditsPackEvent { credited, failed, pending }

/// Issue de « regarder une publicité » pour gagner un tour de roulette.
enum AiRewardAdOutcome {
  /// Le serveur a crédité le tour.
  credited,

  /// L'utilisateur n'est pas allé au bout de la publicité.
  abandoned,

  /// La publicité est terminée mais le serveur n'a pas encore crédité.
  pending,
}

abstract class AiCreditsHost {
  const AiCreditsHost();

  // ── Lectures ───────────────────────────────────────────────────────────────

  /// `GET /gateway/ai/wallet` (`available`, `reserved`, `purchased`,
  /// `rewarded`, `granted`, `blocked`, `spins`, `remaining_ads`, `roulette`).
  /// Lève sans session ou serveur injoignable : l'écran dit « indisponible ».
  Future<Map<String, dynamic>> wallet();

  /// `GET /gateway/ai/ledger?offset=` (`entries`, `has_more`).
  Future<Map<String, dynamic>> ledger({int offset = 0});

  // ── Roulette et publicités ─────────────────────────────────────────────────

  /// `ios` / `android` quand l'appareil diffuse des publicités récompensées et
  /// fait tourner la roulette ; `null` ailleurs (poste de travail, Studio) :
  /// l'écran n'affiche alors que le solde, l'historique et les packs.
  String? get rewardsPlatform => null;

  /// Regarde une publicité puis attend que le serveur crédite le tour.
  /// Seulement appelée quand [rewardsPlatform] n'est pas `null`.
  Future<AiRewardAdOutcome> watchRewardAd() async =>
      throw UnsupportedError('Rewarded ads are not available here.');

  /// `POST /gateway/ai/roulette/spin` (clé d'idempotence rejouée en cas
  /// d'échec ambigu : jamais deux tours consommés).
  Future<Map<String, dynamic>> spin(String idempotencyKey) async =>
      throw UnsupportedError('The roulette is not available here.');

  // ── Packs de crédits (achat en boutique) ──────────────────────────────────

  /// Les packs achetables, titrés dans [locale] (ex. `fr_FR`) quand l'offre
  /// publiée porte cette traduction.
  Future<List<AiCreditsPack>> loadPacks(String locale) async =>
      const <AiCreditsPack>[];

  /// Lance l'achat ; faux = il n'a pas démarré.
  Future<bool> buyPack(AiCreditsPack pack) async => false;

  /// Le sort des achats lancés (crédité / échoué / en attente).
  Stream<AiCreditsPackEvent> get packEvents =>
      const Stream<AiCreditsPackEvent>.empty();

  // ── Conversation liée à une ligne de l'historique ─────────────────────────

  /// Une ligne de l'historique peut-elle ouvrir la conversation du Copilot qui
  /// l'a consommée ?
  bool get canOpenConversation => false;

  void openConversation(BuildContext context, String conversationId) {}
}

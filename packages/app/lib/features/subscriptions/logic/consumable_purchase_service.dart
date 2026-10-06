import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/app_account_token.dart';
import 'package:bot_creator/features/subscriptions/logic/commerce_catalog.dart';
import 'package:bot_creator/features/subscriptions/logic/shared_purchase_stream.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un pack de credits IA vendu dans le store, tel que l'ecran l'affiche.
class ConsumablePack {
  const ConsumablePack({
    required this.offer,
    required this.product,
    required this.credits,
  });
  final CommerceOffer offer;
  final ProductDetails product;

  /// Credits donnes (tokens), calcules par le serveur depuis l'offre publiee.
  final int credits;
}

enum ConsumableEventKind { credited, failed, pending }

class ConsumableEvent {
  const ConsumableEvent(this.kind, {this.productId = ''});
  final ConsumableEventKind kind;
  final String productId;
}

/// Achat des packs de credits IA (produits consommables des stores).
///
/// Regle : le credit est decide par le SERVEUR, qui interroge le store et ne lit
/// que l'offre publiee. Le client ne « consomme » l'achat (ce qui le rend
/// re-achetable) qu'APRES la reponse du serveur : un achat paye mais non credite
/// reste en attente et est rejoue au demarrage suivant, jamais perdu.
class ConsumablePurchaseService {
  ConsumablePurchaseService._();

  static const _idsKey = 'consumable_product_ids_v1';
  static final Set<String> _ids = <String>{};
  static bool _loaded = false;
  static bool _handlerRegistered = false;
  static final StreamController<ConsumableEvent> _events =
      StreamController<ConsumableEvent>.broadcast();

  static Stream<ConsumableEvent> get events => _events.stream;

  static Future<void> _load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _ids.addAll(prefs.getStringList(_idsKey) ?? const <String>[]);
    } catch (_) {
      // Sans stockage, on retombe sur les identifiants connus de cette session.
    }
    _loaded = true;
  }

  /// Vrai si [productId] est un pack de credits. Les autres gestionnaires d'achat
  /// l'utilisent pour NE PAS terminer (donc consommer) l'achat avant le credit.
  static Future<bool> isConsumableProduct(String productId) async {
    await _load();
    return _ids.contains(productId);
  }

  /// Memorise les identifiants de packs du catalogue, aussi apres un redemarrage :
  /// un achat en attente peut etre rejoue avant que le catalogue soit recharge.
  static Future<void> rememberProducts(Iterable<String> productIds) async {
    await _load();
    final before = _ids.length;
    _ids.addAll(productIds.where((id) => id.isNotEmpty));
    if (_ids.length == before) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_idsKey, _ids.toList()..sort());
    } catch (_) {}
  }

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Branche l'ecoute des achats et rejoue ceux restes en attente.
  static Future<void> start() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!_handlerRegistered) {
      SharedPurchaseStream.instance.addHandler(_handleUpdates);
      _handlerRegistered = true;
    }
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {}
  }

  /// Les packs achetables ici, avec le prix du store. Liste vide si le store, le
  /// catalogue ou un produit manque : on n'affiche jamais un pack qu'on ne sait
  /// pas acheter.
  static Future<List<ConsumablePack>> loadPacks({
    CommerceCatalog? catalog,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return const [];
    catalog ??= await loadCommerceCatalog();
    if (catalog == null) {
      debugPrint('[Packs] aucun catalogue publie (ou pas de session)');
      return const [];
    }
    final offers = catalog.aiPacks(_platform, DateTime.now());
    if (offers.isEmpty) {
      debugPrint(
        '[Packs] catalogue publie sans pack ai_pack pour $_platform '
        '(${catalog.offers.length} offres)',
      );
      return const [];
    }
    final ids = {for (final o in offers) o.nativeBinding(_platform)!.productId};
    await rememberProducts(ids);
    if (!await InAppPurchase.instance.isAvailable()) {
      debugPrint('[Packs] le store n\'est pas disponible (Play Billing)');
      return const [];
    }
    final response = await InAppPurchase.instance.queryProductDetails(ids);
    debugPrint(
      '[Packs] demandes=$ids trouves='
      '${response.productDetails.map((p) => p.id).toList()} '
      'introuvables=${response.notFoundIDs} '
      'erreur=${response.error?.code}: ${response.error?.message}',
    );
    final byId = {for (final p in response.productDetails) p.id: p};
    final packs = <ConsumablePack>[];
    for (final offer in offers) {
      final product = byId[offer.nativeBinding(_platform)!.productId];
      if (product == null) continue;
      packs.add(
        ConsumablePack(
          offer: offer,
          product: product,
          credits: catalog.aiCreditsOnce(offer.id),
        ),
      );
    }
    return packs;
  }

  /// Ouvre la feuille d'achat. Le resultat arrive par [events] ; faux si le
  /// store n'a pas pu la demarrer.
  static Future<bool> buy(ConsumablePack pack) async {
    final session = await MainApiSettingsStore.loadSession();
    if (session == null || session.isExpired) return false;
    await rememberProducts([pack.product.id]);
    // autoConsume: false : on ne consomme qu'apres le credit serveur.
    return InAppPurchase.instance.buyConsumable(
      purchaseParam: PurchaseParam(
        productDetails: pack.product,
        applicationUserName: appAccountTokenForOwner(session.userId),
      ),
      autoConsume: false,
    );
  }

  static Future<void> _handleUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!await isConsumableProduct(purchase.productID)) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final credited = await _verifyAndCredit(purchase);
          if (credited && purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
        case PurchaseStatus.pending:
          _events.add(
            ConsumableEvent(
              ConsumableEventKind.pending,
              productId: purchase.productID,
            ),
          );
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _events.add(
            ConsumableEvent(
              ConsumableEventKind.failed,
              productId: purchase.productID,
            ),
          );
          // Un achat annule ou en erreur n'a rien debite : on le termine.
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
      }
    }
  }

  /// Vrai quand le serveur a credite l'achat ou l'avait deja credite : seul cas
  /// ou l'on peut le consommer. Toute autre reponse le laisse en attente.
  static Future<bool> _verifyAndCredit(PurchaseDetails purchase) async {
    final data = Platform.isIOS
        ? (purchase.purchaseID ?? '').trim()
        : purchase.verificationData.serverVerificationData.trim();
    if (data.isEmpty) return false;
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (!config.isConfigured || session == null || session.isExpired) {
        return false;
      }
      final response =
          await MainApiClient(
            baseUrl: config.baseUrl,
            accessToken: session.accessToken,
          ).verifyConsumableBilling(
            platform: _platform,
            serverVerificationData: data,
            productId: purchase.productID,
            localTransactionId: purchase.purchaseID,
            appAccountToken: appAccountTokenForOwner(session.userId),
          );
      final done =
          response['credited'] == true || response['duplicate'] == true;
      if (done) {
        _events.add(
          ConsumableEvent(
            ConsumableEventKind.credited,
            productId: purchase.productID,
          ),
        );
      }
      return done;
    } catch (error, stack) {
      // Reponse terminale (autre compte, produit inconnu) ou reseau : l'achat
      // reste en attente, rejoue plus tard, et le support peut le retrouver.
      unawaited(
        AppDiagnostics.logError(
          'Consumable purchase not credited',
          error,
          stack,
          fatal: false,
          reason: 'product=${purchase.productID}',
        ),
      );
      final code = error is MainApiClientException ? error.code : null;
      if (code != 'purchase_pending') {
        _events.add(
          ConsumableEvent(
            ConsumableEventKind.failed,
            productId: purchase.productID,
          ),
        );
      }
      return false;
    }
  }
}

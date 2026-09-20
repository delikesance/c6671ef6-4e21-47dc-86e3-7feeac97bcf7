import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_token_import.dart';
import 'package:flutter/material.dart';

/// Client du compte pour un import de jeton, ou `null` quand aucun compte
/// n'est connecté sur ce poste.
///
/// L'absence de compte n'est pas une panne réseau : c'est un état que
/// l'utilisateur peut corriger (« connecte-toi »), donc une information —
/// d'où le message [BotTokenImportOutcome.noAccount] plutôt qu'un échec muet.
Future<MainApiClient?> resolveAccountClientForTokenImport() async {
  try {
    final config = await MainApiSettingsStore.loadConfig();
    final session = await MainApiSettingsStore.loadSession();
    if (session != null && !session.isExpired && config.isConfigured) {
      return MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
    }
  } catch (_) {
    // Réglages illisibles : on retombe sur « aucun compte », qui a un texte.
  }
  return null;
}

/// Bouton « Importer le jeton depuis mon compte » — le SEUL chemin par lequel
/// un jeton redescend du compte vers ce poste.
///
/// Pourquoi il existe : le manager RÉDIGE volontairement `bot_token` dans ses
/// listes (« Zero plaintext token in summary lists »), et un jeton ne
/// redescend jamais par la synchro. Un appareil qui n'a pas saisi le jeton une
/// première fois lisait donc « Token invalid or missing » sans aucun recours,
/// même en rafraîchissant. Ce bouton le REDEMANDE au compte
/// (`POST /gateway/bots/{id}/token`), une fois, à la demande explicite du
/// propriétaire.
///
/// Trois états visibles, et jamais d'échec muet :
///   * repos : libellé de la clé `bot_token_import_btn`, bouton actif ;
///   * en cours : bouton VERROUILLÉ (un second geste, même dans la même frame,
///     ne produit aucun second envoi) avec son indicateur ;
///   * résultat : un message par cause, via [botTokenImportMessage] — un 404 de
///     route absente n'y dit jamais « vérifie ta connexion ».
///
/// Utilisé par l'écran « Bot Token » d'un bot hors ligne et par le menu de sa
/// carte d'accueil : le même état pour les deux, aucune divergence possible.
class BotTokenImportButton extends StatefulWidget {
  const BotTokenImportButton({
    super.key,
    required this.botId,
    this.onImported,
    this.importerFactory,
  });

  /// Bot dont le jeton est redemandé au compte.
  final String botId;

  /// Relais après un import RÉUSSI seulement : l'écran appelant se recharge
  /// (le jeton est écrit par `createOrUpdateApp`, jamais ailleurs).
  final Future<void> Function()? onImported;

  /// Couture de test : fabrique l'exportateur au lieu de le construire depuis les
  /// réglages du compte ([resolveAccountClientForTokenImport]).
  ///
  /// Pourquoi cette couture plutôt qu'un serveur local dans les tests : l'écriture
  /// d'un jeton passe par la base locale et le coffre, et une écriture de fichier
  /// lancée depuis la zone d'horloge simulée d'un test de widget ne rend JAMAIS la
  /// main (constaté : le bouton restait verrouillé et aucun message n'apparaissait).
  /// L'enchaînement réglages → client → requête → écriture est prouvé au niveau du
  /// module (`bot_token_import_test.dart`) ; ici on prouve l'interface.
  final BotTokenImporter Function()? importerFactory;

  @override
  State<BotTokenImportButton> createState() => _BotTokenImportButtonState();
}

class _BotTokenImportButtonState extends State<BotTokenImportButton> {
  bool _importing = false;

  Future<void> _import() async {
    // Garde de réentrance : deux gestes partis dans la même frame ne peuvent
    // pas produire deux exports du même jeton.
    if (_importing) return;
    setState(() => _importing = true);

    final BotTokenImportOutcome outcome;
    try {
      final factory = widget.importerFactory;
      final importer = factory != null
          ? factory()
          : BotTokenImporter(client: await resolveAccountClientForTokenImport());
      outcome = await importer.importFromUserAction(botId: widget.botId);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(botTokenImportMessage(outcome, context.tr))),
    );
    if (outcome == BotTokenImportOutcome.imported) {
      await widget.onImported?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _importing ? null : _import,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          alignment: Alignment.center,
        ),
        icon: _importing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_download_outlined, size: 18),
        label: Text(context.tr.bot_token_import_btn),
      ),
    );
  }
}

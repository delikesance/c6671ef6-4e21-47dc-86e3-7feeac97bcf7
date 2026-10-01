// LA MODALE D'HISTORIQUE D'UNE COMMANDE — CINQ VERSIONS, UNE RESTAURATION,
// ET UN CONFLIT QUI SE RÈGLE EN RECHARGEANT (PAS EN EFFAÇANT).
//
// POURQUOI CE FICHIER EXISTE : le journal par commande existe côté serveur
// (P1) et le dépôt sait le lire et le rejouer (`BotDataRepository`), mais rien
// dans l'application ne le montrait. Cette modale est le seul endroit où
// l'utilisateur voit ses versions ET où il peut en restaurer une.
//
// LES QUATRE ÉTATS, ET AUCUN N'EST UNE ERREUR DE RÉSEAU DÉGUISÉE :
//
//  1. LA LISTE. Cinq versions au plus (rétention du journal), avec date
//     LOCALISÉE, auteur et taille. La ligne est UN FORMAT traduit
//     (`command_history_version_meta`), jamais une phrase assemblée à la main :
//     c'est ce qui rend l'ordre et les séparateurs corrects dans les 6 langues.
//
//  2. LISTE VIDE. Un historique vide est un état LÉGITIME (bot jamais
//     re-sauvegardé depuis l'ouverture du journal). Il le dit comme tel :
//     l'utilisateur ne doit pas chercher une panne là où il n'y en a pas.
//
//  3. LA v2 N'EST PAS ARMÉE (`granularDataRepository == null` ou sonde en
//     échec). Ici, l'historique N'EXISTE PAS pour ce client : le serveur ne
//     sert pas `/api/v2`. Afficher « aucune version » ferait croire que son bot
//     n'a jamais rien historisé — c'est faux, et c'est précisément l'erreur que
//     cette modale refuse de commettre. Elle dit donc POURQUOI.
//
//  4. LA LISTE EST INDISPONIBLE (hors-ligne, serveur injoignable). Le journal
//     n'est pas cachable localement dans ce lot : la modale DIT qu'elle n'a pas
//     pu le récupérer, au lieu de bloquer l'écran ou de mentir sur un vide.
//
// LE 409 DE RESTAURATION EST UN CONFLIT, JAMAIS UNE PANNE. Le serveur a refusé
// d'écrire parce que la révision attendue était périmée : RIEN n'a été écrit de
// son côté, rien ne l'est du nôtre. La modale affiche donc l'état de conflit et
// propose de RECHARGER la version serveur (une lecture, puis le même rejeu avec
// la révision réellement lue) au lieu d'écraser d'office — ou de présenter cela
// comme une erreur réseau, ce qui pousserait à réessayer à l'aveugle.
//
// LE 409 ARRIVE PAR DEUX CHEMINS, ET LES DEUX SONT TRAITÉS : le dépôt le rend
// en `ConflictStale` pour les écritures ; pour une restauration, l'exception du
// client peut aussi remonter telle quelle. Selon la forme, c'est le MÊME fait,
// donc le MÊME état d'interface. Ne reconnaître qu'une des deux formes ferait
// dépendre l'affichage d'un détail d'implémentation du dépôt.
//
// AUCUNE ÉCRITURE LOCALE, ET RIEN N'EST ÉCRASÉ SANS ACCORD : la restauration
// demande confirmation (la version serveur courante est remplacée), et la
// modale ne touche jamais au stockage local. LIMITE ASSUMÉE DE CE LOT : le
// contenu local de la commande n'est donc PAS rafraîchi par une restauration —
// un enregistrement suivant dans l'éditeur republierait le contenu local. Le
// rafraîchissement de l'éditeur est un lot à part.
library;

import 'dart:async';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/bot_data_models.dart';
import 'package:bot_creator/core/network/bot_data_repository.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/storage/granular_data_layer.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Nombre de versions montrées : le journal en conserve cinq par entité, donc
/// en demander plus serait demander ce qui n'existe pas.
const int commandHistoryVersionLimit = 5;

/// Ouvre la modale d'historique d'une commande.
///
/// `repository` est un point d'injection (les tests montent la modale sans
/// couche globale) ; sans lui, c'est la couche granulaire de l'application qui
/// décide — et son absence est un ÉTAT, pas une erreur.
Future<void> showCommandHistorySheet(
  BuildContext context, {
  required String botId,
  required String commandId,
  BotDataRepository? repository,
}) {
  final resolved = repository ?? granularDataRepository;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CommandHistorySheet(
      botId: botId,
      commandId: commandId,
      repository: resolved,
    ),
  );
}

/// L'état de CHARGEMENT de la liste — les seuls cas où la modale n'affiche pas
/// d'entrées, et aucun n'est « zéro version ».
enum CommandHistoryPhase {
  /// La liste est en cours de récupération.
  loading,

  /// La liste est là (éventuellement vide : voir `versions.isEmpty`).
  ready,

  /// La v2 n'est pas armée : l'historique n'existe pas pour ce client.
  noGranularApi,

  /// La liste n'a pas pu être RÉCUPÉRÉE (hors-ligne, serveur injoignable).
  listUnavailable,
}

/// La modale d'historique d'une commande, autonome et montable seule.
class CommandHistorySheet extends StatefulWidget {
  const CommandHistorySheet({
    super.key,
    required this.botId,
    required this.commandId,
    this.repository,
  });

  final String botId;
  final String commandId;

  /// Le dépôt granulaire, ou `null` quand l'application n'en a aucun (aucune
  /// session) : la modale dit alors que l'historique n'est pas disponible, au
  /// lieu d'afficher une liste vide trompeuse.
  final BotDataRepository? repository;

  @override
  State<CommandHistorySheet> createState() => _CommandHistorySheetState();
}

class _CommandHistorySheetState extends State<CommandHistorySheet> {
  CommandHistoryPhase _phase = CommandHistoryPhase.loading;
  List<CommandVersionInfo> _versions = const <CommandVersionInfo>[];

  /// La version que l'utilisateur a demandé à restaurer. Conservée APRÈS un
  /// conflit : c'est elle que le rejeu après rechargement doit appliquer, sinon
  /// « recharger et écraser » écraserait avec autre chose que ce qui a été
  /// choisi.
  String? _pendingHistoryId;

  /// Vrai pendant une opération de restauration : les boutons sont alors
  /// inactifs, pour qu'un double tap ne déclenche pas deux écritures.
  bool _busy = false;

  /// Vrai après un `409` : la révision attendue est périmée, la modale propose
  /// de recharger au lieu d'afficher un échec.
  bool _conflict = false;

  /// Vrai quand la restauration a échoué pour une AUTRE raison (réseau, 5xx).
  /// Distinct du conflit : celui-ci n'a rien écrit, celle-là n'a rien pu faire.
  bool _restoreFailed = false;

  /// POURQUOI la restauration a échoué, quand l'application le sait.
  ///
  /// Sans lui, l'écran ne pouvait afficher qu'un « échec » indistinct : le code
  /// du serveur était capturé dans `failure` puis… jamais montré ni journalisé.
  String? _restoreFailureReason;

  /// Vrai quand le serveur a refusé la version parce qu'elle est trop pauvre
  /// (`409 bot_config_version_too_small`). C'est un refus de FOND, pas un
  /// conflit : il ne se règle ni en relisant, ni en écrasant, seulement en
  /// choisissant une autre version — ou en DEMANDANT une restauration forcée.
  bool _restoreFloorRefused = false;

  /// Vrai quand la restauration FORCÉE elle-même a été refusée : le serveur
  /// n'accepte pas (encore) de forcer ce cas, et il le dit.
  bool _restoreFloorUnforced = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  // ─── Chargement de la liste ──────────────────────────────────────────────

  Future<void> _load() async {
    final repository = widget.repository;
    if (repository == null) {
      _setPhase(CommandHistoryPhase.noGranularApi);
      return;
    }
    if (!repository.isGranularEnabled && !repository.hasProbed) {
      // La couche granulaire n'a peut-être pas ENCORE sondé (démarrage). Une
      // sonde qui échoue laisse la v2 désarmée : c'est le résultat attendu,
      // pas une raison de bloquer la modale.
      try {
        await repository.probe();
      } catch (_) {
        // Avalée volontairement : le diagnostic ci-dessous s'affiche.
      }
    }
    if (!repository.isGranularEnabled) {
      _setPhase(CommandHistoryPhase.noGranularApi);
      return;
    }
    try {
      final versions = await repository.listCommandHistory(
        widget.botId,
        widget.commandId,
        limit: commandHistoryVersionLimit,
      );
      if (!mounted) return;
      setState(() {
        _versions = versions;
        _phase = CommandHistoryPhase.ready;
      });
    } catch (_) {
      // Le legacy n'a AUCUN historique : il n'existe donc pas de repli, et
      // cette lecture n'est pas cachable localement dans ce lot. Le dire est la
      // seule réponse honnête — afficher une liste vide ferait croire à un
      // historique vide.
      _setPhase(CommandHistoryPhase.listUnavailable);
    }
  }

  void _setPhase(CommandHistoryPhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
  }

  // ─── Restauration ────────────────────────────────────────────────────────

  /// Demande confirmation AVANT de remplacer la version serveur.
  ///
  /// Le libellé de confirmation est « Restaurer » : sans accord explicite, rien
  /// n'est écrit — la fermeture du dialogue rend `false` et le rejeu n'a pas
  /// lieu.
  Future<void> _confirmAndRestore(CommandVersionInfo version) async {
    final agreed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.command_history_title,
      content: context.tr.command_history_restore_confirm,
      confirmLabel: context.tr.command_history_restore,
      cancelLabel: context.tr.common_cancel,
      isDestructive: true,
    );
    if (!agreed || !mounted) return;
    await _restore(version.historyId);
  }

  /// [confirmOvershrink] : restauration FORCÉE, demandée quand le serveur a
  /// refusé la version pour cause de plancher de plausibilité. Ce drapeau n'est
  /// posé qu'APRÈS un accord explicite (le bouton « Restaurer quand même »).
  Future<void> _restore(
    String historyId, {
    bool confirmOvershrink = false,
  }) async {
    final repository = widget.repository;
    if (repository == null) {
      _setPhase(CommandHistoryPhase.noGranularApi);
      return;
    }
    setState(() {
      _busy = true;
      _pendingHistoryId = historyId;
      _conflict = false;
      _restoreFailed = false;
      _restoreFailureReason = null;
      _restoreFloorRefused = false;
      _restoreFloorUnforced = false;
    });

    SaveOutcome? outcome;
    Object? failure;
    try {
      outcome = await repository.restoreCommandVersion(
        widget.botId,
        widget.commandId,
        historyId,
        confirmOvershrink: confirmOvershrink,
      );
    } on MainApiClientException catch (error) {
      // Un `409` n'est PAS un échec : la révision attendue est périmée, et le
      // serveur n'a rien écrit. On garde la version choisie en attente pour
      // pouvoir la rejouer après un rechargement.
      //
      // SAUF le refus de PLANCHER (la version visée pèse moins que le plancher
      // de plausibilité) : relire n'y changerait rien — la version existe, elle
      // est trop pauvre. Le poser en conflit enverrait l'utilisateur en boucle
      // sur un « recharger et écraser » qui ne peut pas aboutir.
      if (isBotConfigVersionFloorRefusal(error)) {
        AppDiagnostics.logError(
          'Command version restore refused: version below the floor',
          error,
          StackTrace.current,
          fatal: false,
          information:
              'botId=${widget.botId} commandId=${widget.commandId} '
              'historyId=$historyId code=${error.code} '
              'forced=$confirmOvershrink',
        );
        if (!mounted) return;
        setState(() {
          _busy = false;
          _conflict = false;
          _restoreFailed = true;
          _restoreFloorRefused = true;
          // Forcée ET refusée : le serveur doit accepter la restauration forcée
          // pour ce cas. Le dire, plutôt que de reproposer le même bouton.
          _restoreFloorUnforced = confirmOvershrink;
          _restoreFailureReason = null;
        });
        return;
      }
      if (error.statusCode == 409) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _conflict = true;
        });
        return;
      }
      failure = error;
    } catch (error) {
      failure = error;
    }

    if (!mounted) return;
    if (failure != null) {
      // La raison part au journal ET à l'écran : sans elle, « échec » ne dit ni
      // si la version existe encore, ni si le serveur a refusé, ni pourquoi.
      AppDiagnostics.logError(
        'Command version restore failed',
        failure,
        StackTrace.current,
        fatal: false,
        information:
            'botId=${widget.botId} commandId=${widget.commandId} '
            'historyId=$historyId',
      );
      setState(() {
        _busy = false;
        _restoreFailed = true;
        _restoreFailureReason = describeApiFailure(failure!);
      });
      return;
    }

    switch (outcome) {
      case SavedGranular() || SavedLegacy():
        // La version est restaurée côté serveur (le dépôt a mémorisé la
        // nouvelle révision). L'éditeur n'est PAS rafraîchi : voir l'en-tête.
        setState(() => _busy = false);
        Navigator.of(context).maybePop();
      case ConflictStale():
        setState(() {
          _busy = false;
          _conflict = true;
        });
      case QueuedOffline():
        // Une restauration ne part jamais en file : la dire « en attente »
        // laisserait croire qu'elle se fera « toute seule » alors que rien ne
        // la rejouera.
        setState(() {
          _busy = false;
          _restoreFailed = true;
        });
      case null:
        setState(() {
          _busy = false;
          _restoreFailed = true;
        });
    }
  }

  /// La phrase à afficher pour une restauration refusée.
  ///
  /// Quatre natures, quatre phrases — et aucune ne dit « panne » là où le
  /// serveur a simplement répondu non : un refus de plancher (la version est
  /// vide, mais forceable), un refus de plancher PERSISTANT malgré la demande
  /// forcée, une raison technique nommée, ou un échec sans détail.
  String _restoreFailureMessage(AppLocalizations tr) {
    if (_restoreFloorUnforced) {
      return tr.bot_config_versions_restore_too_small_unforced;
    }
    if (_restoreFloorRefused) {
      return tr.bot_config_versions_restore_too_small;
    }
    final reason = _restoreFailureReason;
    if (reason == null || reason.isEmpty) {
      return tr.bot_config_versions_restore_error;
    }
    return tr.bot_config_versions_restore_error_detail(reason);
  }

  /// Rejoue la restauration choisie en DEMANDANT au serveur de la forcer.
  ///
  /// Une restauration est un retour en arrière demandé : si le serveur refuse
  /// la version à cause de son plancher de plausibilité, c'est à l'utilisateur
  /// de décider s'il veut malgré tout y revenir — pas à l'application de
  /// l'en empêcher.
  Future<void> _restoreForced() async {
    final historyId = _pendingHistoryId;
    if (historyId == null) return;
    await _restore(historyId, confirmOvershrink: true);
  }

  /// RECHARGER la version serveur, PUIS rejouer la restauration choisie.
  ///
  /// L'ordre est le sujet : on relit d'abord (c'est de cette lecture que vient
  /// la révision réellement courante, mémorisée par le dépôt), on rejoue
  /// ensuite le MÊME `historyId` — la restauration part donc avec la bonne
  /// précondition au lieu de la périmée. Rien n'est écrasé avant que la version
  /// en place n'ait été lue.
  Future<void> _reloadAndOverwrite() async {
    final historyId = _pendingHistoryId;
    final repository = widget.repository;
    if (historyId == null || repository == null) return;

    setState(() {
      _busy = true;
      _restoreFailed = false;
      _restoreFailureReason = null;
    });

    try {
      await repository.getCommand(widget.botId, widget.commandId);
    } catch (error) {
      if (!mounted) return;
      // Le rechargement lui-même a échoué : on ne rejoue PAS à l'aveugle. La
      // raison est nommée, sinon l'utilisateur voit un échec sans savoir que
      // c'est la RELECTURE qui a lâché (rien n'a donc été écrit).
      AppDiagnostics.logError(
        'Command version restore aborted: reload failed',
        error,
        StackTrace.current,
        fatal: false,
        information:
            'botId=${widget.botId} commandId=${widget.commandId} '
            'historyId=$historyId',
      );
      setState(() {
        _busy = false;
        _conflict = false;
        _restoreFailed = true;
        _restoreFailureReason = describeApiFailure(error);
      });
      return;
    }

    if (!mounted) return;
    await _restore(historyId);
  }

  // ─── Rendu ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppIcon.fromMaterial(
                  Icons.history_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr.command_history_title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tr.common_close,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const AppIcon.fromMaterial(Icons.close_rounded),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 8),
            ..._buildBody(tr),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(AppLocalizations tr) {
    switch (_phase) {
      case CommandHistoryPhase.loading:
        return const <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case CommandHistoryPhase.noGranularApi:
        // POURQUOI CETTE PHRASE EXISTE : sans v2 armée, l'historique n'existe
        // pas pour ce client. Dire « aucune version » serait faux et ferait
        // croire à un bot jamais historisé.
        return <Widget>[
          _Notice(
            icon: Icons.cloud_off_rounded,
            message: tr.command_history_unavailable_no_v2,
          ),
        ];
      case CommandHistoryPhase.listUnavailable:
        return <Widget>[
          _Notice(
            icon: Icons.wifi_off_rounded,
            message: tr.command_history_unavailable_offline,
          ),
        ];
      case CommandHistoryPhase.ready:
        return <Widget>[
          if (_conflict) ...<Widget>[
            _ConflictPanel(
              message: tr.command_history_conflict,
              reloadLabel: tr.command_history_conflict_reload,
              onReload: _busy ? null : _reloadAndOverwrite,
            ),
            const SizedBox(height: 12),
          ],
          if (_restoreFailed)
            _Notice(
              icon: Icons.error_outline_rounded,
              message: _restoreFailureMessage(tr),
            ),
          // Le refus de plancher n'est pas une impasse : la version visée a déjà
          // tourné pour ce bot, la décision revient à l'utilisateur.
          if (_restoreFloorRefused && !_restoreFloorUnforced) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _restoreForced,
              icon: const AppIcon.fromMaterial(Icons.restore_page_rounded),
              label: Text(tr.bot_config_versions_force_restore_confirm),
            ),
          ],
          if (_versions.isEmpty)
            // ÉTAT LÉGITIME, pas une erreur : l'utilisateur ne doit pas
            // chercher une panne là où il n'y en a pas.
            _Notice(
              icon: Icons.history_toggle_off_rounded,
              message: tr.command_history_empty,
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _versions.length,
                itemBuilder: (context, index) => _versionTile(_versions[index]),
              ),
            ),
        ];
    }
  }

  /// Une entrée d'historique : une ligne de MÉTADONNÉES traduite, et le bouton
  /// de restauration.
  ///
  /// La ligne vient d'UN format ARB (`command_history_version_meta`) : l'ordre,
  /// la date et le séparateur appartiennent à la traduction, pas au Dart.
  Widget _versionTile(CommandVersionInfo version) {
    final tr = context.tr;
    final localeName = Localizations.localeOf(context).toString();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const AppIcon.fromMaterial(Icons.commit_rounded),
      title: Text(
        tr.command_history_version_meta(
          _authorLabel(version.authorOwnerId),
          _timestampLabel(version.createdAt, localeName),
          version.sizeBytes,
        ),
        style: const TextStyle(fontSize: 13),
      ),
      trailing: TextButton(
        onPressed: _busy ? null : () => _confirmAndRestore(version),
        child: Text(tr.command_history_restore),
      ),
    );
  }

  /// L'auteur tel que le serveur le rend : un identifiant de propriétaire. Il
  /// n'est jamais traduit ni remplacé par un nom inventé — vide quand le
  /// serveur n'en donne pas.
  String _authorLabel(String authorOwnerId) => authorOwnerId.trim();

  /// La date LOCALISÉE de la version, dans la langue de l'interface.
  String _timestampLabel(DateTime? createdAt, String localeName) {
    if (createdAt == null) return '';
    return DateFormat.yMd(localeName).add_jm().format(createdAt);
  }
}

/// Un message d'état de la modale (vide légitime, indisponible, échec).
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: <Widget>[
          AppIcon.fromMaterial(icon, size: 32, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Le panneau de CONFLIT : ce qui vient de se passer, et la seule action qui
/// fait avancer — recharger la version serveur avant de la remplacer.
class _ConflictPanel extends StatelessWidget {
  const _ConflictPanel({
    required this.message,
    required this.reloadLabel,
    required this.onReload,
  });

  final String message;
  final String reloadLabel;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIcon.fromMaterial(
                Icons.sync_problem_rounded,
                color: scheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onReload, child: Text(reloadLabel)),
        ],
      ),
    );
  }
}

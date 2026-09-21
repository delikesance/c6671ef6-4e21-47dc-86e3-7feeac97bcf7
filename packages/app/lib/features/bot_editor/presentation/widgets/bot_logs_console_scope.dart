import 'dart:async';

import 'package:bot_creator/core/network/bot_server_logs_reader.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:flutter/material.dart';

/// Donne à la console de logs d'un bot ce que la LECTURE serveur a rendu.
///
/// POURQUOI ce widget : le panneau de logs d'un bot hébergé affichait
/// « En attente d'événements en direct… » avec un badge LIVE alors que le bot
/// tournait bien sur les serveurs Bot Creator — il attendait donc un flux PUSSÉ
/// qui n'arrive jamais. Le manager EXPOSE pourtant ces lignes en lecture
/// (`GET /gateway/bots/{id}/logs`, scope `read:bots`) : on les lit.
///
/// Ce scope ne dessine rien : il résout QUI exécute le bot, lit ses logs si et
/// seulement si le bot tourne sur les serveurs Bot Creator, et passe l'état
/// obtenu au [builder]. Un bot exécuté en local n'a pas de client manager : rien
/// n'est lu, aucune requête ne part, et la console garde son comportement.
class BotServerLogsScope extends StatefulWidget {
  const BotServerLogsScope({
    super.key,
    required this.botId,
    required this.builder,
    this.runtimeResolver,
    this.readInterval = const Duration(seconds: 5),
  });

  final String botId;

  /// Reçoit l'état de la lecture serveur (vide tant qu'aucune lecture n'a eu
  /// lieu) et construit la console.
  final Widget Function(BuildContext context, BotServerLogsState state) builder;

  /// Résolution du runtime, injectable pour les tests. Par défaut, la carte
  /// résout elle-même, comme la page des logs.
  final Future<ResolvedRemoteRuntime> Function()? runtimeResolver;

  /// Cadence des relectures tant que la console est visible.
  final Duration readInterval;

  @override
  State<BotServerLogsScope> createState() => _BotServerLogsScopeState();
}

class _BotServerLogsScopeState extends State<BotServerLogsScope> {
  BotServerLogsReader? _reader;

  /// Notificateur neutre tant qu'aucun lecteur n'existe : la console doit
  /// toujours avoir quelque chose à écouter, même pour un bot local.
  static final ValueNotifier<BotServerLogsState> _idle =
      ValueNotifier<BotServerLogsState>(const BotServerLogsState());

  @override
  void initState() {
    super.initState();
    unawaited(_startServerRead());
  }

  @override
  void dispose() {
    // Le minuteur de relecture doit mourir avec le panneau : sinon il reste
    // « A Timer is still pending even after the widget tree was disposed ».
    _reader?.dispose();
    super.dispose();
  }

  Future<void> _startServerRead() async {
    try {
      final runtime = await _resolveRuntime().timeout(
        const Duration(seconds: 8),
      );
      if (!mounted) {
        return;
      }
      // Le panneau doit lire le MÊME bucket que la page des logs : sans cette
      // mémoire, une ligne poussée par le flux sur la source distante ne
      // s'afficherait jamais ici.
      setBotLogsSourceForBot(widget.botId, runtime.source);
      final reader = BotServerLogsReader(
        botId: widget.botId,
        runtime: runtime,
        interval: widget.readInterval,
      );
      _reader = reader;
      setState(() {});
      reader.start();
    } catch (_) {
      // Résolution impossible : on ne prétend pas savoir d'où viennent les logs.
      // Le flux en direct garde la main, exactement comme avant ce correctif.
      // La cause n'est pas journalisée : elle peut recracher la réponse du
      // serveur, et un log de bot peut y avoir laissé un secret échappé.
      debugPrint('[BotServerLogsScope] Runtime resolution failed.');
    }
  }

  Future<ResolvedRemoteRuntime> _resolveRuntime() {
    final resolver = widget.runtimeResolver;
    if (resolver != null) {
      return resolver();
    }
    return resolveRemoteRuntime(
      supportsManagerRuntime: supportsManagerRuntime,
      botId: widget.botId,
      getTimeout: const Duration(seconds: 5),
      postTimeout: const Duration(seconds: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BotServerLogsState>(
      valueListenable: _reader?.state ?? _idle,
      builder: (context, state, _) => widget.builder(context, state),
    );
  }
}

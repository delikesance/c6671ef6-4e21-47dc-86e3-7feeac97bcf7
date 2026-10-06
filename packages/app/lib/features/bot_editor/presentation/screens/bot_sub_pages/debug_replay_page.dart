// L'écran « Rejeu du débogueur » d'un bot vit dans `bot_creator_ui` (le Studio
// affiche le même). Ce fichier n'en garde que l'adaptateur de l'app : le runner
// configuré (`RunnerClient`) d'abord, la mémoire locale de l'appareil à défaut,
// et la porte premium de l'app.
library;

import 'dart:async';

import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_feature_gate.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:bot_creator/features/subscriptions/presentation/widgets/premium_locked_hint.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

/// Le détail d'un rejeu, ré-exporté pour les imports existants.
export 'package:bot_creator_ui/bot_creator_ui.dart' show DebugReplayDetailPage;

class DebugReplayPage extends StatefulWidget {
  const DebugReplayPage({super.key, this.botId, this.host});

  final String? botId;

  /// Hôte injectable (tests) ; par défaut [AppDebugReplayHost].
  final ui.DebugReplayHost? host;

  @override
  State<DebugReplayPage> createState() => _DebugReplayPageState();
}

class _DebugReplayPageState extends State<DebugReplayPage> {
  // Un seul hôte pour la vie de la page : il garde le client du runner.
  late final ui.DebugReplayHost _host = widget.host ?? AppDebugReplayHost();

  @override
  Widget build(BuildContext context) =>
      ui.DebugReplayPage(botId: widget.botId, host: _host);
}

/// Le rejeu tel que l'app le lit : le runner configuré quand il y en a un, sinon
/// ce que le moteur de CET appareil a capturé.
class AppDebugReplayHost extends ui.DebugReplayHost {
  AppDebugReplayHost();

  RunnerClient? _client;

  /// Le client du runner actif, créé au premier appel. `null` = pas de runner
  /// configuré : l'écran lit alors la mémoire locale.
  Future<RunnerClient?> _resolveClient() async {
    final cached = _client;
    if (cached != null) return cached;
    final config = await RunnerSettings.getConfig();
    if (config == null) return null;
    return _client = config.createClient(
      getTimeout: const Duration(seconds: 30),
      postTimeout: const Duration(seconds: 25),
    );
  }

  Future<RunnerClient> _requireClient() async {
    final client = await _resolveClient();
    if (client == null) {
      throw const RunnerClientException('No runner configured.');
    }
    return client;
  }

  /// Le rejeu de débogueur s'exécute ICI : sur un poste de travail il ne dépend
  /// donc pas de la formule tant que le bot tourne sur cet appareil. Seul le
  /// Running côté serveur reste cadré (règle produit).
  @override
  bool hasCapability(String? botId) => premiumCapabilityAvailableForBot(
    PremiumCapability.visualDebuggerReplay,
    botId: botId,
  );

  @override
  Widget buildUpgradeAction(BuildContext context) {
    if (PremiumCapabilities.canShowPurchaseUI) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: FilledButton.icon(
          onPressed: () => SubscriptionPage.show(context),
          icon: const AppIcon.fromMaterial(Icons.workspace_premium_rounded),
          label: Text(context.tr.premium_card_button),
        ),
      );
    }
    // Sans boutique native (poste de travail), il ne restait AUCUNE action :
    // on dit au moins pourquoi c'est verrouille et ou l'abonnement s'active.
    return const PremiumLockedHint();
  }

  @override
  Future<ui.DebugReplaySnapshot?> fetchReplays(
    String botId, {
    int limit = 30,
  }) async {
    final client = await _resolveClient();
    if (client == null) return null;
    final snapshot = await client.getDebugReplays(botId, limit: limit);
    return ui.DebugReplaySnapshot(
      capturing: snapshot.capturing,
      replays: snapshot.replays
          .map(ui.DebugReplayRecord.fromJson)
          .toList(growable: false),
    );
  }

  @override
  Future<void> clearReplays(String botId) async =>
      (await _requireClient()).clearDebugReplays(botId);

  @override
  Future<bool> setCapturing(String botId, bool enabled) async =>
      (await _requireClient()).setDebugReplayCapturing(botId, enabled);

  @override
  bool get hasLocalSource => true;

  @override
  bool get localCapturing => isDebugReplayCapturing;

  @override
  List<ui.DebugReplayRecord> get localReplays => debugReplays;

  @override
  Stream<List<ui.DebugReplayRecord>> get localReplaysStream =>
      debugReplaysStream;

  @override
  void setLocalCapturing(bool enabled) => setDebugReplayCapturing(enabled);

  @override
  void clearLocalReplays() => clearDebugReplays();
}

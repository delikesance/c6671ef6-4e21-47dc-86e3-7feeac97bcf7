import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../auth/auth_controller.dart';
import '../auth/studio_session.dart';
import '../premium/premium_gate.dart';
import '../premium/studio_feature.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/studio_rail.dart';
import 'bots_page.dart';
import 'commands_page.dart';
import 'dashboard_page.dart';
import 'overview_page.dart';
import 'team_page.dart';
import 'variables_page.dart';

/// Coque connectée : accueil (rail Accueil / Documentation / Paramètres) ou
/// éditeur d'un bot (rail de l'éditeur). Jamais montrée sans session valide.
class StudioShell extends StatefulWidget {
  const StudioShell({super.key, required this.auth});

  final AuthController auth;

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  StudioBot? _bot;
  String _homeSection = 'home';
  String _editorSection = 'commands';

  @override
  Widget build(BuildContext context) {
    final bot = _bot;
    return Scaffold(
      body: Row(
        children: [
          if (bot == null) _homeRail() else _editorRail(bot),
          Expanded(child: bot == null ? _homeBody() : _editorBody(bot)),
        ],
      ),
    );
  }

  // ── Accueil ───────────────────────────────────────────────────────────────

  Widget _homeRail() => StudioRail(
    badge: const RailBadge(text: 'BC', color: StudioColors.action),
    itemHeight: 64,
    selectedId: _homeSection,
    onSelect: (id) => setState(() => _homeSection = id),
    items: const [
      RailEntry('home', 'Accueil', Icons.home_outlined),
      RailEntry('docs', 'Documentation', Icons.menu_book_outlined),
      RailEntry('settings', 'Paramètres', Icons.settings_outlined),
    ],
  );

  Widget _homeBody() {
    switch (_homeSection) {
      case 'settings':
        return _SettingsPage(auth: widget.auth);
      case 'docs':
        return const ComingSoon(title: 'Documentation');
      default:
        return BotsPage(
          api: widget.auth.api,
          onOpenBot: (bot) => setState(() {
            _bot = bot;
            _editorSection = 'overview';
          }),
        );
    }
  }

  // ── Éditeur de bot ────────────────────────────────────────────────────────

  static const _editorItems = <RailEntry?>[
    RailEntry('back', 'Retour', Icons.arrow_back_rounded),
    null,
    RailEntry('overview', 'Accueil', Icons.dashboard_rounded),
    RailEntry('copilot', 'Copilote IA', Icons.auto_awesome_outlined),
    RailEntry('commands', 'Commandes', Icons.terminal_rounded),
    null,
    RailEntry('flows', 'Flux', Icons.account_tree_outlined),
    RailEntry('vars', 'Vars', Icons.data_object_rounded),
    RailEntry('sched', 'Planif', Icons.schedule_rounded),
    RailEntry('hooks', 'Webhooks entrants', Icons.webhook_rounded),
    RailEntry('emojis', 'Émojis', Icons.emoji_emotions_outlined),
    RailEntry('team', 'Équipe', Icons.groups_outlined),
    RailEntry('guilds', 'Serveurs', Icons.dns_outlined),
    null,
    RailEntry('dash', 'Tableau de bord', Icons.bar_chart_rounded),
  ];

  Widget _editorRail(StudioBot bot) {
    final initials = bot.name.trim().isEmpty
        ? '?'
        : bot.name.trim().substring(0, bot.name.trim().length >= 2 ? 2 : 1);
    return StudioRail(
      badge: RailBadge(
        text: initials.toUpperCase(),
        color: const Color(0xFF38BDF8),
      ),
      selectedId: _editorSection,
      items: _editorItems,
      bottomItems: const [
        RailEntry('settings', 'Paramètres', Icons.settings_outlined),
      ],
      onSelect: (id) => setState(() {
        if (id == 'back') {
          _bot = null;
        } else {
          _editorSection = id;
        }
      }),
    );
  }

  Widget _editorBody(StudioBot bot) {
    final api = widget.auth.api;
    final plan = widget.auth.plan;
    switch (_editorSection) {
      case 'commands':
        return CommandsPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'overview':
        return OverviewPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'dash':
        return DashboardPage(
          key: ValueKey(bot.id),
          api: api,
          bot: bot,
          plan: plan,
        );
      case 'vars':
        return VariablesPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'team':
        return TeamPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'sched':
        return _premiumSection('Planificateur', StudioFeature.scheduler, plan);
      case 'hooks':
        return _premiumSection(
          'Webhooks entrants',
          StudioFeature.inboundWebhooks,
          plan,
        );
      default:
        return ComingSoon(title: _titleOf(_editorSection));
    }
  }

  String _titleOf(String id) {
    for (final e in _editorItems) {
      if (e?.id == id) return e!.label;
    }
    return 'Paramètres';
  }

  Widget _premiumSection(String title, StudioFeature feature, StudioPlan plan) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: PageContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            PremiumGate(
              feature: feature,
              plan: plan,
              child: const Text(
                'Disponible bientôt dans le Studio.',
                style: TextStyle(color: StudioColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final name = auth.session?.username;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: PageContent(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: StudioColors.card,
                border: Border.all(color: StudioColors.cardBorder),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name == null
                        ? 'Connecté avec Discord'
                        : 'Connecté avec Discord : $name',
                    style: const TextStyle(color: StudioColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.plan == StudioPlan.premium
                        ? 'Formule Premium'
                        : "Formule gratuite : l'abonnement se gère depuis l'application mobile.",
                    style: const TextStyle(color: StudioColors.muted),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: auth.signOut,
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

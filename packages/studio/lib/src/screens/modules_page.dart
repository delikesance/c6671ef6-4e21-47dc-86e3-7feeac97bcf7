import 'package:flutter/material.dart';

import '../theme.dart';
import '../l10n_ext.dart';
import '../widgets/common.dart';
import 'beginner_mode.dart';

class _Module {
  const _Module(this.id, this.label, this.subtitle, this.icon);

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
}

List<(String, List<_Module>)> _groups(AppLocalizations l) => [
  (
    l.modulesGroupCreate,
    [
      _Module(
        'flows',
        l.modulesWorkflows,
        l.modulesDescWorkflows,
        Icons.account_tree_outlined,
      ),
      _Module(
        'vars',
        l.modulesVariables,
        l.modulesDescVariables,
        Icons.data_object_rounded,
      ),
      _Module(
        'emojis',
        l.modulesEmojis,
        l.modulesDescEmojis,
        Icons.emoji_emotions_outlined,
      ),
    ],
  ),
  (
    l.modulesGroupAutomation,
    [
      _Module(
        'sched',
        l.modulesScheduler,
        l.modulesDescScheduler,
        Icons.schedule_rounded,
      ),
      _Module('hooks', l.navHooks, l.modulesDescHooks, Icons.webhook_rounded),
    ],
  ),
  (
    l.modulesGroupManagement,
    [
      _Module('team', l.navTeam, l.modulesDescTeam, Icons.groups_outlined),
      _Module('guilds', l.navGuilds, l.modulesDescGuilds, Icons.dns_outlined),
    ],
  ),
  (
    l.modulesGroupTools,
    [
      _Module(
        'dash',
        l.navDashboard,
        l.modulesDescDashboard,
        Icons.bar_chart_rounded,
      ),
      _Module(
        'copilot',
        l.navCopilot,
        l.modulesDescCopilot,
        Icons.auto_awesome_outlined,
      ),
    ],
  ),
];

/// Page « Modules » du téléphone : les onglets secondaires d'un bot, groupés
/// comme dans l'app (Création, Automatisation, Gestion, Outils), avec recherche
/// et le réglage du mode débutant.
class ModulesPage extends StatefulWidget {
  const ModulesPage({
    super.key,
    required this.botName,
    required this.beginner,
    required this.onOpen,
  });

  final String botName;
  final BeginnerMode beginner;
  final ValueChanged<String> onOpen;

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.beginner.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.beginner.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final beginner = widget.beginner.enabled;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: PageContent(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Overline(widget.botName),
            const SizedBox(height: 6),
            Text(
              context.l10n.modulesTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _BeginnerSwitch(
              value: beginner,
              onChanged: (v) => widget.beginner.set(v),
            ),
            if (!beginner) ...[
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: context.l10n.modulesSearch,
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                ),
              ),
              for (final (title, modules) in _groups(context.l10n))
                ..._group(title, modules, q),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _group(String title, List<_Module> modules, String q) {
    final shown = [
      for (final m in modules)
        if (q.isEmpty ||
            m.label.toLowerCase().contains(q) ||
            m.subtitle.toLowerCase().contains(q))
          m,
    ];
    if (shown.isEmpty) return const [];
    return [
      const SizedBox(height: 24),
      Overline(title),
      const SizedBox(height: 8),
      for (final m in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: StudioColors.card,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: StudioColors.clusterBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => widget.onOpen(m.id),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: StudioColors.rail,
                        border: Border.all(color: StudioColors.clusterBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(m.icon, size: 20, color: StudioColors.muted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: StudioColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: StudioColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

class _BeginnerSwitch extends StatelessWidget {
  const _BeginnerSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  // Une surface `Material` (et non un `Container` décoré) : le `ListTile` de
  // l'interrupteur y dessine son effet de toucher ; sous un fond opaque il
  // serait invisible.
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x141976D2),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0x331976D2)),
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: SwitchListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      value: value,
      onChanged: onChanged,
      title: Text(
        context.l10n.navBeginner,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        value ? context.l10n.beginnerOnHint : context.l10n.beginnerOffHint,
        style: const TextStyle(fontSize: 12.5, color: StudioColors.muted),
      ),
    ),
  );
}

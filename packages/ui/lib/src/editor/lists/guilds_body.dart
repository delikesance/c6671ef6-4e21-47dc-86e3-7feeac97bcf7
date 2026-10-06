import 'package:flutter/material.dart';

import '../../l10n/tr_extension.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/floating_glass_nav_bar.dart';
import '../../widgets/home_ui.dart';
import '../../widgets/page_layout.dart';
import 'settings_group_widgets.dart';

/// Un serveur affiché par la page « Serveurs ».
class GuildRowData {
  const GuildRowData({
    required this.id,
    this.name,
    this.iconUrl,
    this.memberCount,
    this.isOwner = false,
  });

  final String id;
  final String? name;
  final String? iconUrl;
  final int? memberCount;
  final bool isOwner;
}

/// Initiale d'un serveur pour la pastille de repli.
String guildRowInitial(String? name) {
  final trimmed = (name ?? '').trim();
  return trimmed.isEmpty ? '' : String.fromCharCode(trimmed.runes.first);
}

/// Corps de la page « Serveurs » : liste alphabétique, chargement, erreur
/// (« Réessayer ») et état vide. Les données et « quitter » viennent de l'hôte.
class GuildsBody extends StatelessWidget {
  const GuildsBody({
    super.key,
    required this.guilds,
    required this.loading,
    required this.leaving,
    required this.onLeave,
    required this.onRefresh,
    this.errorMessage,
  });

  final List<GuildRowData> guilds;
  final bool loading;
  final String? errorMessage;
  final Set<String> leaving;
  final ValueChanged<GuildRowData> onLeave;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = [...guilds]
      ..sort(
        (a, b) => (a.name ?? a.id).toLowerCase().compareTo(
          (b.name ?? b.id).toLowerCase(),
        ),
      );
    // Des serveurs sont connus (y compris pendant un rafraîchissement) : on
    // garde la liste plutôt que de repasser par un spinner.
    if (sorted.isNotEmpty) {
      return PageContent(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: EdgeInsets.only(
              top: 8,
              bottom: FloatingGlassNavBar.contentClearanceOf(context) + 24,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SettingsSectionHeader(
                context.tr.guilds_server_count_other(sorted.length),
              ),
              SettingsGroupCard(
                children: [
                  for (final guild in sorted)
                    SettingsRow(
                      key: ValueKey('guild-row-${guild.id}'),
                      minHeight: 64,
                      leading: HomeBotAvatar(
                        imageUrl: guild.iconUrl,
                        size: 40,
                        fallbackLabel: guildRowInitial(guild.name),
                      ),
                      title: guild.name ?? guild.id,
                      subtitle: [
                        'ID: ${guild.id}',
                        if (guild.memberCount != null)
                          context.tr.guilds_members_count_other(
                            guild.memberCount!,
                          ),
                        if (guild.isOwner) context.tr.guilds_owner_label,
                      ].join(' · '),
                      trailing: IconButton(
                        icon: leaving.contains(guild.id)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : AppIcon.fromMaterial(
                                Icons.exit_to_app,
                                color: AppTheme.statusErrorText,
                              ),
                        tooltip: context.tr.guilds_leave_tooltip,
                        onPressed: leaving.contains(guild.id)
                            ? null
                            : () => onLeave(guild),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    if (loading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.error_outline,
              size: 48,
              color: cs.error,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr.error_with_details(errorMessage!),
              style: TextStyle(color: cs.error),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRefresh,
              child: Text(context.tr.common_retry),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.fromMaterial(
            Icons.dns_outlined,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr.guilds_empty_state,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Confirmation « quitter ce serveur » (même dialogue dans l'app et le Studio).
Future<bool> confirmLeaveGuild(BuildContext context, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.tr.guilds_leave_title),
      content: Text(context.tr.guilds_leave_confirm(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.tr.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            context.tr.delete,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

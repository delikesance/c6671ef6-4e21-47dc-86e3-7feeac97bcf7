import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_ui.dart';

/// Un serveur à montrer dans la pile d'avatars.
@immutable
class GuildStackItem {
  const GuildStackItem({required this.id, this.name, this.iconUrl});

  final String id;
  final String? name;
  final String? iconUrl;
}

/// Nombre maximal d'avatars superposés sur une carte de bot.
const int kMaxGuildStackAvatars = 2;

/// Nombre de cercles à dessiner : les vrais serveurs connus gagnent ; sinon la
/// silhouette historique (1 ou 2 cercles) est pilotée par le seul compteur.
int guildStackSlotCount({required int guildCount, required int knownGuilds}) {
  var slots = knownGuilds > 0 ? knownGuilds : (guildCount >= 2 ? 2 : 1);
  if (guildCount > 0 && slots > guildCount) slots = guildCount;
  if (slots < 1) slots = 1;
  if (slots > kMaxGuildStackAvatars) slots = kMaxGuildStackAvatars;
  return slots;
}

/// Initiale du nom d'un serveur, ou `null` si le nom est inconnu/vide.
String? guildStackInitial(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

/// Pile d'avatars de serveurs superposés d'une carte de bot (présentation
/// pure : les serveurs viennent de l'hôte).
class GuildAvatarStack extends StatelessWidget {
  const GuildAvatarStack({
    super.key,
    required this.guildCount,
    this.guilds = const <GuildStackItem>[],
    this.ringColor,
    this.size = 36,
    this.overlap = 26,
  });

  final int guildCount;
  final List<GuildStackItem> guilds;
  final Color? ringColor;
  final double size;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final tokens = HomeTokens.of(context);
    final ring =
        ringColor ?? (isDark ? tokens.clusterBg : scheme.surfaceContainerLow);
    final slots = guildStackSlotCount(
      guildCount: guildCount,
      knownGuilds: guilds.length,
    );
    return SizedBox(
      width: size + (slots - 1) * overlap,
      height: size,
      child: Stack(
        children: <Widget>[
          for (var i = 0; i < slots; i++)
            Positioned(
              left: i * overlap,
              child: HomeBotAvatar(
                imageUrl: i < guilds.length ? guilds[i].iconUrl : null,
                size: size,
                background: i == 0
                    ? (isDark ? tokens.clusterBorder : scheme.primary)
                    : AppTheme.discord,
                ringColor: ring,
                ringWidth: 2,
                fallbackIcon: Icons.dns_rounded,
                // Initiale *réelle* du serveur (jamais une lettre tirée d'une seed).
                fallbackLabel: guildStackInitial(
                  i < guilds.length ? guilds[i].name : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

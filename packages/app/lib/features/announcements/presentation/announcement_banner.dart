// Bannière d'annonce (`info` / `important`) : refermable, en haut de l'accueil,
// jamais bloquante. Elle reprend le style des cartes de l'app (`Card` du thème)
// avec la teinte de la gravité.
//
// Ce fichier ne connaît ni le réseau ni le service : il rend l'annonce qu'on
// lui donne et remonte la fermeture / l'ouverture du lien.
import 'package:flutter/material.dart';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_style.dart';

class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({
    super.key,
    required this.announcement,
    required this.onDismiss,
    this.openLink,
  });

  final Announcement announcement;

  /// Ferme la bannière. Appelé par la croix — présente uniquement si l'annonce
  /// est refermable (`dismissible: true`).
  final VoidCallback onDismiss;

  final AnnouncementLinkOpener? openLink;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final palette = AnnouncementPalette.of(context, announcement.severity);
    final textTheme = Theme.of(context).textTheme;
    final link = announcement.linkUrl;

    return Card(
      color: palette.container,
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(palette.icon, color: palette.onContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    announcement.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: palette.onContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (announcement.body.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      announcement.body,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.onContainer,
                      ),
                    ),
                  ],
                  if (link != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => openAnnouncementLink(
                          context,
                          link,
                          openLink: openLink,
                        ),
                        child: Text(tr.announcement_see_more),
                      ),
                    ),
                ],
              ),
            ),
            if (bannerShowsCloseButton(announcement))
              IconButton(
                onPressed: onDismiss,
                tooltip: tr.announcement_dismiss,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: palette.onContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

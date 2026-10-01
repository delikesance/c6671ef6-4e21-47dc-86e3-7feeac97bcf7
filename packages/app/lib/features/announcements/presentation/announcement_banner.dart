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

import 'package:bot_creator/core/widgets/app_icon.dart';

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

    return Container(
      decoration: BoxDecoration(
        color: palette.container,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AppIcon.fromMaterial(
            palette.icon,
            color: palette.iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
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
                      color: palette.onContainer.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                if (link != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: palette.buttonBackground,
                      ),
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
          if (bannerShowsCloseButton(announcement)) ...<Widget>[
            const SizedBox(width: 12),
            Tooltip(
              message: tr.announcement_dismiss,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.buttonBackground,
                  foregroundColor: palette.buttonForeground,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 34),
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onDismiss,
                child: Text(
                  tr.announcement_acknowledge,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

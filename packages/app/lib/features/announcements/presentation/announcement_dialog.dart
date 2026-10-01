// Dialogue modal d'annonce CRITIQUE.
//
// Deux garanties, et elles ne se contredisent pas :
//   * `dismissible: false` retire le report (bouton « Plus tard », tap hors du
//     dialogue, retour système) : l'annonce doit être vue et acquittée ;
//   * le bouton d'acquittement, lui, est TOUJOURS là. Un dialogue dont on ne
//     peut pas sortir serait un piège à utilisateur, jamais une intention.
//
// Ce fichier ne connaît ni le réseau ni le service : il affiche l'annonce
// qu'on lui donne et rend la main quand elle est fermée.
import 'package:flutter/material.dart';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_style.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Affiche le dialogue et rend la main quand il est fermé.
/// Renvoie `true` si l'utilisateur a cliqué sur acquitter (« Compris » / « Got it »).
Future<bool?> showAnnouncementDialog(
  BuildContext context, {
  required Announcement announcement,
  AnnouncementLinkOpener? openLink,
}) async {
  final deferAllowed = modalBarrierDismissible(announcement);
  return showDialog<bool>(
    context: context,
    barrierDismissible: deferAllowed,
    builder: (dialogContext) {
      final tr = dialogContext.tr;
      final palette = AnnouncementPalette.of(
        dialogContext,
        announcement.severity,
      );
      final link = announcement.linkUrl;

      return PopScope(
        // Le retour système ne peut pas escamoter une annonce non refermable ;
        // il reste actif pour une annonce refermable.
        canPop: deferAllowed,
        child: AlertDialog(
          icon: AppIcon.fromMaterial(palette.icon, color: palette.onContainer),
          title: Text(announcement.title),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (announcement.body.isNotEmpty) Text(announcement.body),
              if (link != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => openAnnouncementLink(
                      dialogContext,
                      link,
                      openLink: openLink,
                    ),
                    child: Text(tr.announcement_see_more),
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            // Report : seulement quand l'annonce l'autorise.
            if (deferAllowed)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(tr.announcement_later),
              ),
            // Acquittement : jamais conditionnel — c'est la sortie garantie.
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(tr.announcement_acknowledge),
            ),
          ],
        ),
      );
    },
  );
}

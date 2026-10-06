import '../l10n/tr_extension.dart';
import '../widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// Famille visuelle d'un bloc d'action (identité des blocs de la refonte).
///
/// Les blocs restent NEUTRES ; la couleur de famille n'apparaît que dans la
/// pastille d'icône ([pastilleDecoration]) et le surtitre en majuscules
/// ([overlineStyle]). Nommé `BlockFamily` pour ne pas entrer en collision avec
/// la classe `BlockCategory` de `scratch_block_palette.dart`.
enum BlockFamily {
  http(Color(0xFF38BDF8), 'action_category_http_variables'),
  logic(Color(0xFFFB7185), 'action_category_logic_flow'),
  messages(Color(0xFFA78BFA), 'action_category_messages'),
  moderation(Color(0xFF4ADE80), 'action_category_moderation'),
  data(Color(0xFFFBBF24), 'action_category_data'),
  events(Color(0xFFFB923C), 'action_category_events');

  const BlockFamily(this.color, this.l10nKey);

  /// Couleur d'identité de la famille.
  final Color color;

  /// Clé l10n du libellé (hook ; voir [label] pour la résolution).
  final String l10nKey;

  /// Opacité du fond de la pastille.
  static const double pastilleTint = 0.14;

  /// Opacité de l'anneau intérieur de la pastille.
  static const double pastilleRing = 0.32;

  /// Libellé localisé. Réutilise les clés `action_category_*` existantes ;
  /// « Data » et « Events » n'ont pas de clé : repli par langue.
  String label(BuildContext context) {
    final tr = context.tr;
    switch (this) {
      case BlockFamily.http:
        return tr.action_category_http_variables;
      case BlockFamily.logic:
        return tr.action_category_logic_flow;
      case BlockFamily.messages:
        return tr.action_category_messages;
      case BlockFamily.moderation:
        return tr.action_category_moderation;
      case BlockFamily.data:
        return _byLang(context, 'Data', 'Données');
      case BlockFamily.events:
        return _byLang(context, 'Events', 'Événements');
    }
  }

  static String _byLang(BuildContext context, String en, String fr) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;

  /// Pastille d'icône : fond teinté 14 % + anneau 32 % (bordure peinte à
  /// l'intérieur de la boîte, donc « inset »).
  BoxDecoration pastilleDecoration({double radius = 12}) => BoxDecoration(
    color: color.withValues(alpha: pastilleTint),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: color.withValues(alpha: pastilleRing)),
  );

  /// Pastille complète (icône centrée) de côté [size].
  Widget pastille(IconData icon, {double size = 36, double iconSize = 18}) =>
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: pastilleDecoration(),
        child: AppIcon.fromMaterial(icon, size: iconSize, color: color),
      );

  /// Style du surtitre : à appliquer sur un texte déjà en MAJUSCULES
  /// (`label.toUpperCase()`).
  TextStyle overlineStyle([TextStyle? base]) =>
      (base ?? const TextStyle()).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color,
      );

  /// Famille d'un identifiant de catégorie de `getCategoryForAction`
  /// (`scratch_block_palette.dart`) ou d'un nom libre (insensible à la casse).
  /// Repli : [BlockFamily.logic] pour tout nom inconnu.
  static BlockFamily fromCategoryName(String? name) {
    switch ((name ?? '').trim().toLowerCase()) {
      case 'messages':
      case 'reactions':
      case 'components':
        return BlockFamily.messages;
      case 'moderation':
      case 'channels':
      case 'guild & members':
        return BlockFamily.moderation;
      case 'http & variables':
      case 'http':
      case 'variables':
      case 'webhooks':
        return BlockFamily.http;
      case 'logic & flow':
      case 'logic':
      case 'workflows':
        return BlockFamily.logic;
      case 'interactions':
      case 'events':
      case 'event':
        return BlockFamily.events;
      case 'data':
      case 'music':
      case 'utilities':
        return BlockFamily.data;
      default:
        return BlockFamily.logic;
    }
  }
}

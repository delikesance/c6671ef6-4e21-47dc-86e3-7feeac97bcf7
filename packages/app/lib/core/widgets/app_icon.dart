import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import 'reicon_material_map.dart';

/// Shared renderer for Reicon paths, with the application's icon theme.
class AppIcon extends Icon {
  static final Map<String, String> _svgCache = {};

  const AppIcon(this.path, {Key? key, double? size, Color? color})
    : super(null, key: key, size: size, color: color);

  /// Renders an existing Material IconData through the Reicon icon set.
  const AppIcon.fromMaterial(
    super.icon, {
    super.key,
    super.size,
    super.color,
    super.semanticLabel,
    super.textDirection,
    super.shadows,
    super.fill,
    super.weight,
    super.grade,
    super.opticalSize,
    super.applyTextScaling,
    super.blendMode,
    super.fontWeight,
  }) : path = null;

  final String? path;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final extent = size ?? theme.size ?? 24;
    final tint =
        color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    final icon = this.icon;
    final iconPaths = icon == null ? null : reiconMaterialPaths[icon];
    assert(
      icon == null || iconPaths != null,
      'Missing Reicon mapping for $icon. Regenerate reicon_material_map.dart.',
    );
    final iconPath =
        path ??
        (iconPaths == null
            ? null
            : (reiconFilledMaterialIcons.contains(icon)
                  ? iconPaths.filled
                  : iconPaths.outline));
    if (iconPath == null && icon == null) {
      return SizedBox(width: extent, height: extent);
    }
    final resolvedPath = iconPath ?? Reicon.outline.widget;
    final rendered = SvgPicture.string(
      _svgCache.putIfAbsent(
        resolvedPath,
        () => reiconSvg(resolvedPath, color: '#000000'),
      ),
      width: extent,
      height: extent,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
    final direction = textDirection ?? Directionality.maybeOf(context);
    final directed =
        direction == TextDirection.rtl && icon?.matchTextDirection == true
        ? Transform.flip(flipX: true, child: rendered)
        : rendered;
    return semanticLabel == null
        ? ExcludeSemantics(child: directed)
        : Semantics(label: semanticLabel, child: directed);
  }
}

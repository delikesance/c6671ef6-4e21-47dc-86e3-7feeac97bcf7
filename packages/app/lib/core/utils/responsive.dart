import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Responsive design helper utilities
class ResponsiveHelper {
  /// Check if device is mobile (width < 600)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if device is small phone (width < 420)
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 420;
  }

  /// Check if device is tablet (width >= 600 && width < 1200)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Check if platform is a desktop OS (Windows, Linux, macOS)
  static bool isDesktopPlatform() {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  /// Get spacing based on screen size
  static double getSpacing(BuildContext context, {double factor = 1.0}) {
    if (isSmallPhone(context)) return (8.0 * factor);
    if (isMobile(context)) return (12.0 * factor);
    if (isTablet(context)) return (16.0 * factor);
    return (20.0 * factor);
  }
}

extension ScaffoldParentExtension on BuildContext {
  /// Open the parent Scaffold's drawer if it exists.
  void openParentDrawer() {
    ScaffoldState? parent;
    int count = 0;
    visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScaffoldState) {
        count++;
        if (count > 1) {
          // Skip the first (nested) Scaffold
          parent = element.state as ScaffoldState;
          return false; // stop traversing
        }
      }
      return true; // continue traversing
    });
    if (parent != null) {
      parent!.openDrawer();
    } else {
      // Fallback: if there is only one Scaffold in the context tree, open it
      Scaffold.maybeOf(this)?.openDrawer();
    }
  }
}

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

  /// Check if device is large desktop (width >= 1200)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Check if platform is a desktop OS (Windows, Linux, macOS)
  static bool isDesktopPlatform() {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.macOS => true,
      _ => false,
    };
  }

  /// Get responsive value based on screen size
  T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return mobile;
    if (width < 1200) return tablet;
    return desktop;
  }

  /// Get max width for content (for centered layouts)
  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isSmallPhone(context)) return width * 0.9;
    if (isMobile(context)) return 500;
    if (isTablet(context)) return 600;
    return 800;
  }

  /// Get horizontal padding for screens
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    final padding = getHorizontalPaddingValue(context);
    return EdgeInsets.symmetric(horizontal: padding);
  }

  /// Get horizontal padding value
  static double getHorizontalPaddingValue(BuildContext context) {
    if (isSmallPhone(context)) return 12.0;
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  /// Get vertical padding for screens
  static EdgeInsets getVerticalPadding(BuildContext context) {
    final padding = getVerticalPaddingValue(context);
    return EdgeInsets.symmetric(vertical: padding);
  }

  /// Get vertical padding value
  static double getVerticalPaddingValue(BuildContext context) {
    if (isSmallPhone(context)) return 12.0;
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 20.0;
    return 24.0;
  }

  /// Get spacing based on screen size
  static double getSpacing(BuildContext context, {double factor = 1.0}) {
    if (isSmallPhone(context)) return (8.0 * factor);
    if (isMobile(context)) return (12.0 * factor);
    if (isTablet(context)) return (16.0 * factor);
    return (20.0 * factor);
  }

  /// Get font size based on screen size
  static double getFontSize(BuildContext context, double baseMobileSize) {
    if (isSmallPhone(context)) return baseMobileSize * 0.9;
    if (isMobile(context)) return baseMobileSize;
    if (isTablet(context)) return baseMobileSize * 1.1;
    return baseMobileSize * 1.2;
  }

  /// Get device orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
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
        if (count > 1) { // Skip the first (nested) Scaffold
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

import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1025;

  // Check device type
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMinWidth;
  }

  // Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Get max width for content (prevents excessive width on large screens)
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1400;
    } else if (isTablet(context)) {
      return 900;
    }
    return double.infinity;
  }

  // Get grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) {
      return 4;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 2;
    }
  }

  // Get padding based on screen size
  static double getPadding(BuildContext context) {
    if (isDesktop(context)) {
      return 24;
    } else if (isTablet(context)) {
      return 20;
    } else {
      return 16;
    }
  }

  // Get font size scaling
  static double getFontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) {
      return baseSize * 0.9; // Slightly smaller on desktop
    } else if (isTablet(context)) {
      return baseSize * 0.95;
    } else {
      return baseSize;
    }
  }

  // Get icon size
  static double getIconSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) {
      return baseSize * 0.85;
    } else if (isTablet(context)) {
      return baseSize * 0.9;
    } else {
      return baseSize;
    }
  }

  // Get button height
  static double getButtonHeight(BuildContext context) {
    if (isDesktop(context)) {
      return 48;
    } else if (isTablet(context)) {
      return 52;
    } else {
      return 56;
    }
  }

  // Get card elevation
  static double getCardElevation(BuildContext context) {
    if (isDesktop(context)) {
      return 1;
    } else {
      return 2;
    }
  }

  // Get spacing
  static double getSpacing(BuildContext context, double baseSpacing) {
    if (isDesktop(context)) {
      return baseSpacing * 1.2;
    } else if (isTablet(context)) {
      return baseSpacing * 1.1;
    } else {
      return baseSpacing;
    }
  }

  // Get container constraints
  static BoxConstraints getContentConstraints(BuildContext context) {
    return BoxConstraints(
      maxWidth: getMaxContentWidth(context),
    );
  }

  // Check if should use two-column layout
  static bool shouldUseTwoColumnLayout(BuildContext context) {
    return !isMobile(context);
  }

  // Get dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return screenWidth * 0.4; // 40% of screen on desktop
    } else if (isTablet(context)) {
      return screenWidth * 0.6; // 60% on tablet
    } else {
      return screenWidth * 0.9; // 90% on mobile
    }
  }
}

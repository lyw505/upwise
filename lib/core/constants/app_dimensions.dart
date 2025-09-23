import 'package:flutter/material.dart';

/// UI/UX Dimensions following Material Design 3 and best practices
class AppDimensions {
  // TOUCH TARGETS (Minimum 44x44 iOS / 48x48 Android)
  static const double minTouchTarget = 48.0;
  static const double minTouchTargetIOS = 44.0;
  
  // BUTTON HEIGHTS (User-friendly sizes - reduced for better UX)
  static const double buttonHeightLarge = 48.0;    // Primary actions (reduced from 56)
  static const double buttonHeightMedium = 44.0;   // Secondary actions (reduced from 48)
  static const double buttonHeightSmall = 36.0;    // Compact actions (reduced from 40)
  static const double buttonHeightCompact = 32.0;  // Very compact (chips, etc)
  
  // BUTTON WIDTHS (Minimum widths for better proportion)
  static const double buttonMinWidth = 120.0;      // Minimum button width
  static const double buttonMinWidthSmall = 80.0;  // Small button minimum width
  
  // INPUT FIELD HEIGHTS
  static const double inputHeightLarge = 56.0;     // Standard text fields
  static const double inputHeightMedium = 48.0;    // Compact text fields
  static const double inputHeightSmall = 40.0;     // Search boxes
  
  // ICON SIZES (Consistent scaling)
  static const double iconXSmall = 16.0;
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  static const double iconXXLarge = 64.0;
  
  // SPACING (8pt grid system)
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  static const double spaceXXLarge = 48.0;
  static const double spaceXXXLarge = 64.0;
  
  // BORDER RADIUS (Modern, consistent)
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusRound = 999.0; // Fully rounded
  
  // CARD & CONTAINER DIMENSIONS
  static const double cardElevation = 2.0;
  static const double cardElevationHover = 4.0;
  static const double cardPaddingSmall = 12.0;
  static const double cardPaddingMedium = 16.0;
  static const double cardPaddingLarge = 20.0;
  static const double cardPaddingXLarge = 24.0;
  
  // AVATAR SIZES
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;
  static const double avatarXLarge = 96.0;
  
  // LIST ITEM HEIGHTS
  static const double listItemHeightSmall = 48.0;
  static const double listItemHeightMedium = 56.0;
  static const double listItemHeightLarge = 72.0;
  
  // BOTTOM NAVIGATION
  static const double bottomNavHeight = 80.0;
  static const double bottomNavIconSize = 24.0;
  
  // APP BAR
  static const double appBarHeight = 56.0;
  static const double appBarIconSize = 24.0;
  
  // FLOATING ACTION BUTTON
  static const double fabSize = 56.0;
  static const double fabSizeSmall = 40.0;
  static const double fabSizeLarge = 64.0;
  
  // PROGRESS INDICATORS
  static const double progressBarHeight = 4.0;
  static const double progressBarHeightThick = 8.0;
  static const double circularProgressSize = 24.0;
  static const double circularProgressSizeSmall = 16.0;
  static const double circularProgressSizeLarge = 32.0;
  
  // DIVIDERS
  static const double dividerThickness = 1.0;
  static const double dividerThicknessBold = 2.0;
  
  // SHADOWS & ELEVATION
  static const double shadowBlurRadius = 8.0;
  static const double shadowBlurRadiusLarge = 16.0;
  static const double shadowOffset = 2.0;
  static const double shadowOffsetLarge = 4.0;
  
  // RESPONSIVE BREAKPOINTS
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
  
  // CONTENT MAX WIDTHS
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 400.0;
  static const double maxCardWidth = 600.0;
}

/// Extension for easy access to dimensions
extension AppDimensionsExtension on num {
  /// Convert to SizedBox height
  Widget get height => SizedBox(height: toDouble());
  
  /// Convert to SizedBox width  
  Widget get width => SizedBox(width: toDouble());
  
  /// Convert to EdgeInsets all
  EdgeInsets get padding => EdgeInsets.all(toDouble());
  
  /// Convert to EdgeInsets horizontal
  EdgeInsets get paddingH => EdgeInsets.symmetric(horizontal: toDouble());
  
  /// Convert to EdgeInsets vertical
  EdgeInsets get paddingV => EdgeInsets.symmetric(vertical: toDouble());
}

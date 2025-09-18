import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Blue theme
  static const Color primary = Color(0xFF007AFF); // iOS Blue
  static const Color primaryLight = Color(0xFF3395FF); // Lighter variant
  static const Color primaryDark = Color(0xFF0056CC); // Darker variant
  
  // Secondary colors
  static const Color secondary = Color(0xFF64748B); // Slate-500
  static const Color secondaryLight = Color(0xFF94A3B8); // Slate-400
  static const Color secondaryDark = Color(0xFF475569); // Slate-600
  
  // Background colors - All white for consistency
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFFFFFFF); // White
  
<<<<<<< HEAD
  // Text colors - User friendly black tones
  static const Color textPrimary = Color(0xFF1F2937); // Gray-800 - More readable
  static const Color textSecondary = Color(0xFF374151); // Gray-700 - Darker than before
  static const Color textTertiary = Color(0xFF6B7280); // Gray-500 - Still readable
=======
  // Text colors - Better readability with user-friendly black
  static const Color textPrimary = Color(0xFF1F2937); // Gray-800 - readable black
  static const Color textSecondary = Color(0xFF374151); // Gray-700 - softer black
  static const Color textTertiary = Color(0xFF6B7280); // Gray-500 - still readable
>>>>>>> 3c476aa (ui improve : bg color, text color, error handling, ai smr header, search & create path, blue border)
  
  // Status colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color info = Color(0xFF007AFF); // Updated to match primary
  
  // Streak/Gamification colors
  static const Color streak = Color(0xFFFF6B35); // Orange for fire emoji
  static const Color streakBackground = Color(0xFFFFF7ED); // Orange-50
  
<<<<<<< HEAD
  // Card and border colors - Blue borders
  static const Color border = Color(0xFF007AFF); // Primary blue for all borders
  static const Color borderLight = Color(0xFF3395FF); // Light blue variant
=======
  // Card and border colors - Blue theme
  static const Color border = Color(0xFF007AFF); // Primary blue for borders
  static const Color borderLight = Color(0xFF3395FF); // Light blue for subtle borders
>>>>>>> 3c476aa (ui improve : bg color, text color, error handling, ai smr header, search & create path, blue border)
  static const Color cardShadow = Color(0x0F000000); // Black with 6% opacity
  
  // Disabled colors
  static const Color disabled = Color(0xFFCBD5E1); // Slate-300
  static const Color disabledText = Color(0xFF94A3B8); // Slate-400
}

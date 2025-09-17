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
  
  // Background colors
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100
  
  // Text colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate-400
  
  // Status colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color info = Color(0xFF007AFF); // Updated to match primary
  
  // Streak/Gamification colors
  static const Color streak = Color(0xFFFF6B35); // Orange for fire emoji
  static const Color streakBackground = Color(0xFFFFF7ED); // Orange-50
  
  // Card and border colors
  static const Color border = Color(0xFFE2E8F0); // Slate-200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate-100
  static const Color cardShadow = Color(0x0F000000); // Black with 6% opacity
  
  // Disabled colors
  static const Color disabled = Color(0xFFCBD5E1); // Slate-300
  static const Color disabledText = Color(0xFF94A3B8); // Slate-400
}

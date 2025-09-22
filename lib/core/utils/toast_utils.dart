import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ToastUtils {
  static void showTopToast(
    BuildContext context, 
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16, // Add padding from top
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.info,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Auto remove after duration
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
  
  static void showSuccess(BuildContext context, String message) {
    showTopToast(
      context, 
      message, 
      backgroundColor: AppColors.success,
      icon: Icons.check_circle,
    );
  }
  
  static void showError(BuildContext context, String message) {
    showTopToast(
      context, 
      message, 
      backgroundColor: AppColors.error,
      icon: Icons.error,
    );
  }
  
  static void showWarning(BuildContext context, String message) {
    showTopToast(
      context, 
      message, 
      backgroundColor: AppColors.warning,
      icon: Icons.warning,
    );
  }
  
  static void showInfo(BuildContext context, String message) {
    showTopToast(
      context, 
      message, 
      backgroundColor: AppColors.info,
      icon: Icons.info,
    );
  }
}

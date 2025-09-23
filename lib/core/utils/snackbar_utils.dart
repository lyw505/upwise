import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SnackbarUtils {
  static void showCustomSnackbar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Color? borderColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.1),
              border: Border.all(
                color: borderColor ?? backgroundColor ?? AppColors.primary,
                width: 1,
              ),
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
                    color: borderColor ?? backgroundColor ?? AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: AppColors.textPrimary,
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

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  static void showSuccess(BuildContext context, String message) {
    showCustomSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.success,
      borderColor: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext context, String message) {
    showCustomSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.error,
      borderColor: AppColors.error,
      icon: Icons.error_outline,
    );
  }

  static void showInfo(BuildContext context, String message) {
    showCustomSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.info,
      borderColor: AppColors.info,
      icon: Icons.info_outline,
    );
  }

  static void showWarning(BuildContext context, String message) {
    showCustomSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      borderColor: AppColors.warning,
      icon: Icons.warning_outlined,
    );
  }
}

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

/// Primary button widget with consistent styling
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final AppButtonType type;
  final Widget? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.type = AppButtonType.primary,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = _getButtonHeight();
    final buttonStyle = _getButtonStyle();
    final textStyle = _getTextStyle();

    Widget child = isLoading
        ? SizedBox(
            height: AppDimensions.circularProgressSize,
            width: AppDimensions.circularProgressSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.primary ? Colors.white : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: AppDimensions.spaceSmall),
              ],
              Text(text, style: textStyle),
            ],
          );

    if (type == AppButtonType.primary) {
      return SizedBox(
        width: width,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: child,
        ),
      );
    } else {
      return SizedBox(
        width: width,
        height: buttonHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: child,
        ),
      );
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case AppButtonSize.large:
        return AppDimensions.buttonHeightLarge;
      case AppButtonSize.medium:
        return AppDimensions.buttonHeightMedium;
      case AppButtonSize.small:
        return AppDimensions.buttonHeightSmall;
    }
  }

  ButtonStyle _getButtonStyle() {
    final minWidth = size == AppButtonSize.small 
        ? AppDimensions.buttonMinWidthSmall 
        : AppDimensions.buttonMinWidth;

    if (type == AppButtonType.primary) {
      return ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(minWidth, _getButtonHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLarge,
          vertical: AppDimensions.spaceSmall,
        ),
      );
    } else {
      return OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: Size(minWidth, _getButtonHeight()),
        side: BorderSide(color: AppColors.primary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLarge,
          vertical: AppDimensions.spaceSmall,
        ),
      );
    }
  }

  TextStyle _getTextStyle() {
    final baseStyle = size == AppButtonSize.small 
        ? AppTextStyles.buttonMedium 
        : AppTextStyles.buttonLarge;
    
    return baseStyle.copyWith(
      color: type == AppButtonType.primary ? Colors.white : AppColors.primary,
    );
  }
}

enum AppButtonSize { large, medium, small }
enum AppButtonType { primary, secondary }

/// Compact button for smaller spaces
class AppButtonCompact extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButtonCompact({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.buttonHeightCompact,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? Colors.white,
          minimumSize: Size(AppDimensions.buttonMinWidthSmall, AppDimensions.buttonHeightCompact),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMedium,
            vertical: AppDimensions.spaceXSmall,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              SizedBox(width: AppDimensions.spaceXSmall),
            ],
            Text(
              text,
              style: AppTextStyles.buttonSmall.copyWith(
                color: textColor ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

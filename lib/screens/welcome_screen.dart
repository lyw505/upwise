import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_dimensions.dart';
import '../core/widgets/app_button.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading if auth is still initializing
        if (authProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return _buildWelcomeScreen(context);
      },
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Welcome Title
              Text(
                'Welcome!',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "We're here to help you learn new skills.\nThe choice is yours: "),
                    TextSpan(
                      text: "Log in",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: " or "),
                    TextSpan(
                      text: "Create account",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: "."),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Welcome Illustration
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/welcome.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback illustration
                      return Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: AppDimensions.iconXXLarge + 16, // 80px
                              color: AppColors.primary,
                            ),
                            AppDimensions.spaceMedium.height,
                            Icon(
                              Icons.laptop_mac,
                              size: AppDimensions.iconXXLarge - 4, // 60px
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Log in Button
              AppButton(
                text: 'Log in',
                onPressed: () {
                  if (mounted) {
                    context.goToLogin();
                  }
                },
                width: double.infinity,
                size: AppButtonSize.large,
                type: AppButtonType.primary,
              ),

              AppDimensions.spaceMedium.height,

              // Create Account Button
              AppButton(
                text: 'Create Account',
                onPressed: () {
                  if (mounted) {
                    context.goToRegister();
                  }
                },
                width: double.infinity,
                size: AppButtonSize.large,
                type: AppButtonType.secondary,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

}

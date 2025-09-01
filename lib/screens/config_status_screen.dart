import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/config/env_config.dart';

class ConfigStatusScreen extends StatelessWidget {
  const ConfigStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configSummary = EnvConfig.getConfigSummary();
    final configErrors = EnvConfig.validateConfig();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuration Status'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Status Card
            _buildStatusCard(configErrors),
            
            const SizedBox(height: 24),
            
            // Configuration Details
            _buildConfigSection('Environment Configuration', configSummary),
            
            const SizedBox(height: 24),
            
            // API Status
            _buildApiStatusSection(),
            
            const SizedBox(height: 24),
            
            // Validation Errors
            if (configErrors.isNotEmpty) _buildErrorsSection(configErrors),
            
            const SizedBox(height: 24),
            
            // Setup Instructions
            _buildInstructionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(List<String> errors) {
    final isConfigured = errors.isEmpty;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConfigured ? AppColors.success : AppColors.error,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.error,
            size: 48,
            color: isConfigured ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            isConfigured ? 'Configuration Complete' : 'Configuration Required',
            style: AppTextStyles.titleLarge.copyWith(
              color: isConfigured ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isConfigured 
                ? 'All required API keys are configured. Real AI generation is enabled.'
                : 'Some API keys are missing. Using fallback mode.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(String title, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: config.entries.map((entry) {
              return _buildConfigItem(entry.key, entry.value);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem(String key, dynamic value) {
    Color statusColor;
    IconData statusIcon;
    
    if (value is bool) {
      statusColor = value ? AppColors.success : AppColors.textTertiary;
      statusIcon = value ? Icons.check_circle : Icons.cancel;
    } else {
      statusColor = AppColors.textSecondary;
      statusIcon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              key.replaceAll('_', ' ').toUpperCase(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: AppTextStyles.bodySmall.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Status',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildApiStatusCard(
          'Google Gemini API',
          EnvConfig.isConfigured,
          EnvConfig.isConfigured 
              ? 'Ready for AI-powered learning path generation'
              : 'API key not configured - using fallback mode',
        ),
      ],
    );
  }

  Widget _buildApiStatusCard(String title, bool isConfigured, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isConfigured ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isConfigured ? Icons.cloud_done : Icons.cloud_off,
              color: isConfigured ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsSection(List<String> errors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Errors',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((error) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.error, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setup Instructions',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionItem(
                '1. Get Gemini API Key',
                'Visit https://makersuite.google.com/app/apikey',
              ),
              _buildInstructionItem(
                '2. Configure Environment',
                'Add your API key to .env file',
              ),
              _buildInstructionItem(
                '3. Restart App',
                'Restart the application to load new configuration',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

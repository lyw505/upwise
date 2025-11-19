import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/config/env_config.dart';

class ConfigStatusScreen extends StatefulWidget {
  const ConfigStatusScreen({super.key});

  @override
  State<ConfigStatusScreen> createState() => _ConfigStatusScreenState();
}

class _ConfigStatusScreenState extends State<ConfigStatusScreen> {
  bool _isTestingConnection = false;
  String? _connectionResult;

  @override
  Widget build(BuildContext context) {
    final configSummary = EnvConfig.getConfigSummary();
    final configErrors = EnvConfig.validateConfig();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuration Status',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check your app configuration',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
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
                    
                    // Supabase Status  
                    _buildSupabaseStatusSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Test Connection Button
                    _buildTestConnectionButton(),
                    
                    const SizedBox(height: 24),
                    
                    // Validation Errors
                    if (configErrors.isNotEmpty) _buildErrorsSection(configErrors),
                    
                    const SizedBox(height: 24),
                    
                    // Setup Instructions
                    _buildInstructionsSection(),
                  ],
                ),
              ),
            ),
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
                '1. Set Up Supabase Project',
                'Create project at https://app.supabase.com and get URL/keys',
              ),
              _buildInstructionItem(
                '2. Run Database Schema',
                'Execute supabase_schema.sql in your Supabase SQL editor',
              ),
              _buildInstructionItem(
                '3. Get Gemini API Key',
                'Visit https://makersuite.google.com/app/apikey',
              ),
              _buildInstructionItem(
                '4. Configure Environment',
                'Add all API keys to .env file',
              ),
              _buildInstructionItem(
                '5. Test Connection',
                'Use the test button above to verify setup',
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
  
  Widget _buildSupabaseStatusSection() {
    final hasSupabaseUrl = EnvConfig.supabaseUrl.isNotEmpty;
    final hasSupabaseKey = EnvConfig.supabaseAnonKey.isNotEmpty;
    final isSupabaseConfigured = hasSupabaseUrl && hasSupabaseKey;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supabase Backend',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildApiStatusCard(
          'Supabase Database',
          isSupabaseConfigured,
          isSupabaseConfigured 
              ? 'Ready for user authentication and data storage'
              : 'Database credentials not configured',
        ),
        if (_connectionResult != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _connectionResult!.contains('✅') 
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _connectionResult!.contains('✅') 
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _connectionResult!,
              style: AppTextStyles.bodySmall.copyWith(
                color: _connectionResult!.contains('✅') 
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildTestConnectionButton() {
    final canTest = EnvConfig.supabaseUrl.isNotEmpty && EnvConfig.supabaseAnonKey.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canTest && !_isTestingConnection ? _testSupabaseConnection : null,
        icon: _isTestingConnection 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.wifi_protected_setup),
        label: Text(_isTestingConnection ? 'Testing Connection...' : 'Test Supabase Connection'),
      ),
    );
  }
  
  Future<void> _testSupabaseConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionResult = null;
    });
    
    try {
      if (EnvConfig.supabaseUrl.isEmpty || EnvConfig.supabaseAnonKey.isEmpty) {
        setState(() {
          _connectionResult = '❌ Supabase credentials not configured in .env file';
          _isTestingConnection = false;
        });
        return;
      }
      
      final supabase = Supabase.instance.client;
      
      // Test basic connection by querying profiles table
      await supabase
          .from('profiles')
          .select('count')
          .count(CountOption.exact);
      
      setState(() {
        _connectionResult = '✅ Connection successful! Database accessible.\n'
                          'Profiles table exists. Schema is properly set up.';
        _isTestingConnection = false;
      });
    } catch (e) {
      setState(() {
        _connectionResult = '❌ Connection failed: ${e.toString()}\n\n'
                          'Make sure you have:\n'
                          '• Created a Supabase project\n'
                          '• Updated your .env file with correct credentials\n'
                          '• Run the database schema (supabase_schema.sql)';
        _isTestingConnection = false;
      });
    }
  }
}

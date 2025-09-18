import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration class for managing API keys and settings
class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  // Helper method to safely get environment variables
  static String _getEnvVar(String key, String defaultValue) {
    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Google Gemini API Configuration
  static String get geminiApiKey => _getEnvVar('GEMINI_API_KEY', '');
  
  /// Supabase Configuration
  static String get supabaseUrl => _getEnvVar('SUPABASE_URL', '');
  static String get supabaseAnonKey => _getEnvVar('SUPABASE_ANON_KEY', '');
  
  /// App Configuration
  static String get appEnv => _getEnvVar('APP_ENV', 'development');
  static bool get isDebugMode => _getEnvVar('DEBUG_MODE', 'false').toLowerCase() == 'true';
  
  /// API Configuration
  static int get apiTimeout => int.tryParse(_getEnvVar('API_TIMEOUT', '30000')) ?? 30000;
  static int get maxRetries => int.tryParse(_getEnvVar('MAX_RETRIES', '3')) ?? 3;
  
  /// Feature Flags
  static bool get enableAnalytics => _getEnvVar('ENABLE_ANALYTICS', 'true').toLowerCase() != 'false';
  static bool get enableNotifications => _getEnvVar('ENABLE_NOTIFICATIONS', 'true').toLowerCase() != 'false';
  static bool get enableOfflineMode => _getEnvVar('ENABLE_OFFLINE_MODE', 'false').toLowerCase() == 'true';
  
  /// Check if environment is properly configured
  static bool get isConfigured => geminiApiKey.isNotEmpty && 
      supabaseUrl.isNotEmpty && 
      supabaseAnonKey.isNotEmpty;
  
  /// Check if Gemini API key is available
  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
  
  /// Check if running in production
  static bool get isProduction => appEnv.toLowerCase() == 'production';
  
  /// Check if running in development
  static bool get isDevelopment => appEnv.toLowerCase() == 'development';
  
  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'app_env': appEnv,
      'debug_mode': isDebugMode,
      'gemini_configured': isConfigured,
      'api_timeout': apiTimeout,
      'max_retries': maxRetries,
      'enable_analytics': enableAnalytics,
      'enable_notifications': enableNotifications,
      'enable_offline_mode': enableOfflineMode,
    };
  }
  
  /// Validate required environment variables
  static List<String> validateConfig() {
    final errors = <String>[];
    
    if (geminiApiKey.isEmpty) {
      errors.add('GEMINI_API_KEY is not configured');
    }
    
    if (supabaseUrl.isEmpty) {
      errors.add('SUPABASE_URL is not configured');
    }
    
    if (supabaseAnonKey.isEmpty) {
      errors.add('SUPABASE_ANON_KEY is not configured');
    }
    
    return errors;
  }
}

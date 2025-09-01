import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration class for managing API keys and settings
class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  /// Google Gemini API Configuration
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  /// Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  /// App Configuration
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
  static bool get isDebugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  
  /// API Configuration
  static int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
  static int get maxRetries => int.tryParse(dotenv.env['MAX_RETRIES'] ?? '3') ?? 3;
  
  /// Feature Flags
  static bool get enableAnalytics => dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() != 'false';
  static bool get enableNotifications => dotenv.env['ENABLE_NOTIFICATIONS']?.toLowerCase() != 'false';
  static bool get enableOfflineMode => dotenv.env['ENABLE_OFFLINE_MODE']?.toLowerCase() == 'true';
  
  /// Check if environment is properly configured
  static bool get isConfigured => geminiApiKey.isNotEmpty && geminiApiKey != 'your_gemini_api_key_here';
  
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
    
    if (geminiApiKey.isEmpty || geminiApiKey == 'your_gemini_api_key_here') {
      errors.add('GEMINI_API_KEY is not configured');
    }
    
    if (supabaseUrl.isEmpty || supabaseUrl == 'your_supabase_project_url_here') {
      errors.add('SUPABASE_URL is not configured');
    }
    
    if (supabaseAnonKey.isEmpty || supabaseAnonKey == 'your_supabase_anon_key_here') {
      errors.add('SUPABASE_ANON_KEY is not configured');
    }
    
    return errors;
  }
}

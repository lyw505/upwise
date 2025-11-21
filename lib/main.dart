import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/env_config.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/learning_path_provider.dart';
import 'providers/summarizer_provider.dart';
import 'providers/project_provider.dart';
import 'providers/analytics_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If .env file doesn't exist or can't be loaded (especially on release builds), continue with default values
    print('Warning: .env file not found or could not be loaded, using hardcoded configuration for release');
    print('Error: $e');
  }

  // Initialize Supabase with fallback configuration for release builds
  String supabaseUrl = EnvConfig.supabaseUrl;
  String supabaseAnonKey = EnvConfig.supabaseAnonKey;
  
  // Fallback configuration for release builds when .env is not available
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    supabaseUrl = 'https://emelocetqqlirzuqyygd.supabase.co';
    supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtZWxvY2V0cXFsaXJ6dXF5eWdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3MDA4MzMsImV4cCI6MjA3MjI3NjgzM30.nHjxz6t3YYiHfzF9NfC6vYHuOfvKMEf-hC-PkF287Hc';
    print('Using fallback Supabase configuration for release build');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const UpwiseApp());
}

class UpwiseApp extends StatelessWidget {
  const UpwiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LearningPathProvider()),
        ChangeNotifierProvider(create: (_) => SummarizerProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: MaterialApp.router(
        title: 'Upwise',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.createRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

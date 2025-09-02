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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If .env file doesn't exist, continue with default values
    if (EnvConfig.isDevelopment) {
      print('Warning: .env file not found, using default configuration');
    }
  }

  // Validate environment configuration
  final configErrors = EnvConfig.validateConfig();
  if (configErrors.isNotEmpty && EnvConfig.isProduction) {
    throw Exception('Missing required environment variables: ${configErrors.join(', ')}');
  }

  // Initialize Supabase
  if (EnvConfig.supabaseUrl.isEmpty || EnvConfig.supabaseAnonKey.isEmpty) {
    throw Exception('Supabase configuration is missing. Please check your .env file.');
  }

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
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

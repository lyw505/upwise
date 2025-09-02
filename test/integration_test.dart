import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:upwise/core/config/env_config.dart';

void main() {
  group('Supabase Integration Tests', () {
    setUpAll(() async {
      // Load environment variables
      await dotenv.load(fileName: ".env");
      
      // Initialize Supabase with environment credentials
      if (EnvConfig.supabaseUrl.isEmpty || EnvConfig.supabaseAnonKey.isEmpty) {
        throw Exception('Supabase configuration missing in .env file');
      }
      
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
    });

    test('Database connection works', () async {
      final supabase = Supabase.instance.client;

      // Test basic query to profiles table
      final response = await supabase
          .from('profiles')
          .select('count')
          .count(CountOption.exact);

      expect(response.count, isA<int>());
      print('✅ Database connection successful. Profiles count: ${response.count}');
    });

    test('Tables exist and are accessible', () async {
      final supabase = Supabase.instance.client;

      // Test all main tables
      final tables = ['profiles', 'learning_paths', 'daily_learning_tasks', 'project_recommendations'];

      for (final table in tables) {
        final response = await supabase
            .from(table)
            .select('count')
            .count(CountOption.exact);

        expect(response.count, isA<int>());
        print('✅ Table $table accessible. Count: ${response.count}');
      }
    });

    test('Authentication system is ready', () async {
      final supabase = Supabase.instance.client;

      // Check if we can access auth
      expect(supabase.auth, isNotNull);
      expect(supabase.auth.currentUser, isNull); // Should be null initially

      print('✅ Authentication system ready');
    });
  });
}

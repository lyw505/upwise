import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Supabase Integration Tests', () {
    setUpAll(() async {
      // Initialize Supabase with real credentials
      await Supabase.initialize(
        url: 'https://wecizrgxuibhxledozpq.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlY2l6cmd4dWliaHhsZWRvenBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5NzExMjYsImV4cCI6MjA3MDU0NzEyNn0.6uIMc70gVSPsY_h9NZR284J3n3PQByYvfl0vzmp0bXc',
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
      final tables = ['profiles', 'learning_paths', 'daily_tasks', 'project_recommendations'];

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

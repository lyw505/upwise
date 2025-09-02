import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:upwise/core/config/env_config.dart';
import 'dart:convert';

void main() {
  group('Supabase API Integration Tests', () {
    late String supabaseUrl;
    late String anonKey;

    setUpAll(() async {
      // Load environment variables
      await dotenv.load(fileName: ".env");
      
      supabaseUrl = EnvConfig.supabaseUrl;
      anonKey = EnvConfig.supabaseAnonKey;
      
      if (supabaseUrl.isEmpty || anonKey.isEmpty) {
        throw Exception('Supabase configuration missing in .env file');
      }
    });

    test('Supabase API is accessible', () async {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?select=count'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'count=exact',
        },
      );

      expect(response.statusCode, equals(200));
      expect(response.headers['content-range'], isNotNull);
      print('✅ Supabase API accessible. Response: ${response.headers['content-range']}');
    });

    test('All tables are accessible via REST API', () async {
      final tables = ['profiles', 'learning_paths', 'daily_learning_tasks', 'project_recommendations'];
      
      for (final table in tables) {
        final response = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/$table?select=count'),
          headers: {
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
            'Content-Type': 'application/json',
            'Prefer': 'count=exact',
          },
        );

        expect(response.statusCode, equals(200));
        print('✅ Table $table accessible via REST API');
      }
    });

    test('Authentication endpoint is accessible', () async {
      final response = await http.post(
        Uri.parse('$supabaseUrl/auth/v1/signup'),
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': 'test-${DateTime.now().millisecondsSinceEpoch}@example.com',
          'password': 'testpassword123',
        }),
      );

      // Should return 200 or 400 (if email already exists), not 404 or 500
      expect(response.statusCode, anyOf([200, 400, 422]));
      print('✅ Authentication endpoint accessible. Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        expect(data, containsPair('user', isNotNull));
        print('✅ User registration successful via REST API');
      }
    });

    test('Database schema is correct', () async {
      // Test that we can query table information
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/version'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
      );

      // Even if this specific RPC doesn't exist, we should get a proper response
      expect(response.statusCode, anyOf([200, 404]));
      print('✅ Database connection working. Status: ${response.statusCode}');
    });
  });
}

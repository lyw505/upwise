// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:upwise/core/theme/app_theme.dart';
import 'package:upwise/screens/welcome_screen.dart';
import 'package:upwise/providers/auth_provider.dart';
import 'package:upwise/providers/user_provider.dart';
import 'package:upwise/providers/learning_path_provider.dart';

void main() {
  testWidgets('Welcome screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => LearningPathProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const WelcomeScreen(),
        ),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that welcome screen is shown
    expect(find.text('Upwise'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I Already Have an Account'), findsOneWidget);
  });
}

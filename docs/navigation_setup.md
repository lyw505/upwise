# Navigation Setup with Go Router

This document explains the navigation system implemented in the Upwise app using Go Router.

## Overview

The app uses Go Router for declarative routing with the following features:
- Authentication guards
- Deep linking support
- Type-safe navigation
- Centralized route configuration

## Route Structure

```
/welcome          - Welcome/landing page
/login           - Login screen
/register        - Registration screen
/dashboard       - Main dashboard (protected)
/create-path     - Create learning path (protected)
/view-path/:id   - View specific learning path (protected)
/daily           - Daily tracker (protected)
/analytics       - Analytics screen (protected)
/settings        - Settings screen (protected)
```

## Authentication Guards

The router automatically handles authentication:

- **Unauthenticated users** trying to access protected routes → redirected to `/welcome`
- **Authenticated users** on auth pages → redirected to `/dashboard`
- **Loading states** → no redirect (stays on current route)

## Usage Examples

### Basic Navigation

```dart
// Using context extensions
context.goToWelcome();
context.goToLogin();
context.goToRegister();
context.goToDashboard();
context.goToCreatePath();
context.goToViewPath('path-id');
context.goToDaily();
context.goToAnalytics();
context.goToSettings();
```

### Push Navigation (for modals)

```dart
context.pushLogin();
context.pushRegister();
```

### Replace Navigation

```dart
context.replaceWithDashboard();
context.replaceWithWelcome();
```

### Using Route Constants

```dart
import '../core/router/app_router.dart';

// Type-safe route names
context.go(AppRoutes.dashboard);
context.go(AppRoutes.createPath);
```

## Router Configuration

The router is configured in `lib/core/router/app_router.dart`:

```dart
class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/welcome',
      redirect: (context, state) {
        // Authentication logic here
      },
      routes: [
        // Route definitions
      ],
    );
  }
}
```

## Authentication Integration

The router integrates with `AuthProvider` to check authentication state:

```dart
redirect: (BuildContext context, GoRouterState state) {
  final authProvider = context.read<AuthProvider>();
  final isAuthenticated = authProvider.isAuthenticated;
  final isLoading = authProvider.isLoading;
  
  // Redirect logic based on auth state
}
```

## Error Handling

The router includes a custom error page for 404 errors:

```dart
errorBuilder: (context, state) => Scaffold(
  body: Center(
    child: Column(
      children: [
        Icon(Icons.error_outline),
        Text('Page Not Found'),
        Text('The page "${state.uri}" could not be found.'),
        ElevatedButton(
          onPressed: () => context.go('/welcome'),
          child: Text('Go to Welcome'),
        ),
      ],
    ),
  ),
),
```

## Implementation Details

### 1. Router Setup in main.dart

```dart
@override
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      // Other providers...
    ],
    child: MaterialApp.router(
      routerConfig: AppRouter.createRouter(),
      // Other config...
    ),
  );
}
```

### 2. Screen Updates

All screens have been updated to use Go Router navigation:

**Before:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => LoginScreen()),
);
```

**After:**
```dart
context.goToLogin();
```

### 3. AppBar Integration

Dashboard includes navigation menu:

```dart
AppBar(
  actions: [
    PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'analytics':
            context.goToAnalytics();
            break;
          case 'settings':
            context.goToSettings();
            break;
          case 'logout':
            _handleLogout();
            break;
        }
      },
      // Menu items...
    ),
  ],
)
```

## Testing

The navigation system is tested with widget tests:

```dart
testWidgets('Welcome screen displays correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Other providers...
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const WelcomeScreen(),
      ),
    ),
  );

  expect(find.text('Upwise'), findsOneWidget);
  expect(find.text('Get Started'), findsOneWidget);
});
```

## Benefits

1. **Type Safety**: Extension methods prevent typos in route names
2. **Centralized Configuration**: All routes defined in one place
3. **Authentication Guards**: Automatic redirect based on auth state
4. **Deep Linking**: Support for web URLs and app links
5. **Error Handling**: Custom 404 page with recovery options
6. **Testing**: Easy to test navigation without full app context

## Next Steps

The navigation system is now ready for:
1. Adding new protected routes for learning path features
2. Implementing deep linking for specific learning paths
3. Adding route parameters for dynamic content
4. Implementing nested navigation if needed

All future screens can use the established navigation patterns and extension methods for consistent user experience.

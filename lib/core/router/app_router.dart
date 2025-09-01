import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/welcome_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/create_path_screen.dart';
import '../../screens/view_path_screen.dart';
import '../../screens/daily_tracker_screen.dart';
import '../../screens/analytics_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/config_status_screen.dart';
import '../../test_integration.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/welcome',
      debugLogDiagnostics: true,
      
      // Redirect logic for authentication
      redirect: (BuildContext context, GoRouterState state) {
        final authProvider = context.read<AuthProvider>();
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading = authProvider.isLoading;
        
        // Show loading screen while checking auth state
        if (isLoading) {
          return null; // Stay on current route while loading
        }
        
        final currentPath = state.uri.toString();
        final isOnAuthPages = ['/welcome', '/login', '/register'].contains(currentPath);
        final isOnProtectedPages = ['/dashboard', '/create-path', '/view-path', '/daily', '/analytics', '/settings'].contains(currentPath);
        
        // If not authenticated and trying to access protected pages
        if (!isAuthenticated && isOnProtectedPages) {
          return '/welcome';
        }
        
        // If authenticated and on auth pages, redirect to dashboard
        if (isAuthenticated && isOnAuthPages) {
          return '/dashboard';
        }
        
        // No redirect needed
        return null;
      },
      
      routes: [
        // Welcome/Auth Routes
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        
        // Protected Routes (require authentication)
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        
        // Future routes for learning path features
        GoRoute(
          path: '/create-path',
          name: 'create-path',
          builder: (context, state) => const CreatePathScreen(),
        ),
        
        GoRoute(
          path: '/view-path/:pathId',
          name: 'view-path',
          builder: (context, state) {
            final pathId = state.pathParameters['pathId']!;
            return ViewPathScreen(pathId: pathId);
          },
        ),
        
        GoRoute(
          path: '/daily',
          name: 'daily',
          builder: (context, state) => const DailyTrackerScreen(),
        ),
        
        GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        // Integration Test Route (for development)
        GoRoute(
          path: '/test-integration',
          name: 'test-integration',
          builder: (context, state) => const IntegrationTestScreen(),
        ),

        GoRoute(
          path: '/config-status',
          name: 'config-status',
          builder: (context, state) => const ConfigStatusScreen(),
        ),
      ],
      
      // Error handling
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'The page "${state.uri}" could not be found.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/welcome'),
                child: const Text('Go to Welcome'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension for easier navigation
extension AppRouterExtension on BuildContext {
  // Navigation helpers
  void goToWelcome() => go('/welcome');
  void goToLogin() => go('/login');
  void goToRegister() => go('/register');
  void goToDashboard() => go('/dashboard');
  void goToCreatePath() => go('/create-path');
  void goToViewPath(String pathId) => go('/view-path/$pathId');
  void goToDaily() => go('/daily');
  void goToAnalytics() => go('/analytics');
  void goToSettings() => go('/settings');
  void goToConfigStatus() => go('/config-status');
  void goToTestIntegration() => go('/test-integration');
  
  // Push navigation (for modals, etc.)
  void pushLogin() => push('/login');
  void pushRegister() => push('/register');
  
  // Replace navigation
  void replaceWithDashboard() => pushReplacement('/dashboard');
  void replaceWithWelcome() => pushReplacement('/welcome');
}

// Route names constants for type safety
class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String createPath = '/create-path';
  static const String viewPath = '/view-path';
  static const String daily = '/daily';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
}

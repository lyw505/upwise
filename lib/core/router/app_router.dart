import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/welcome_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/view_path_screen.dart';
import '../../screens/daily_tracker_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/config_status_screen.dart';
import '../../screens/project_debug_screen.dart';
import '../../screens/project_detail_screen.dart';
import '../../screens/project_start_debug_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/main_navigation_screen.dart';



import '../../test_integration.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
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
        final isOnSplashPage = currentPath == '/splash';
        final isOnOnboardingPage = currentPath == '/onboarding';
        final isOnAuthPages = ['/welcome', '/login', '/register', '/forgot-password'].contains(currentPath);
        final isOnProtectedPages = ['/dashboard', '/create-path', '/view-path', '/daily', '/projects', '/analytics', '/settings', '/summarizer'].contains(currentPath);
        
        // Allow splash and onboarding screens to load
        if (isOnSplashPage || isOnOnboardingPage) {
          return null;
        }
        
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
        // Splash Screen
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        
        // Onboarding Screen
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        
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
        
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        
        // Protected Routes (require authentication)
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
        ),
        
        GoRoute(
          path: '/learning-paths',
          name: 'learning-paths',
          builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
        ),
        
        GoRoute(
          path: '/create-path',
          name: 'create-path',
          builder: (context, state) => const MainNavigationScreen(initialIndex: 2),
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
          path: '/project/:projectId',
          name: 'project-detail',
          builder: (context, state) {
            final projectId = state.pathParameters['projectId']!;
            return ProjectDetailScreen(projectId: projectId);
          },
        ),

        
        GoRoute(
          path: '/daily',
          name: 'daily',
          builder: (context, state) => const DailyTrackerScreen(),
        ),
        
        GoRoute(
          path: '/projects',
          name: 'projects',
          builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
        ),
        
        GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder: (context, state) => const MainNavigationScreen(initialIndex: 5),
        ),
        
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        GoRoute(
          path: '/summarizer',
          name: 'summarizer',
          builder: (context, state) => const MainNavigationScreen(initialIndex: 4),
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

        GoRoute(
          path: '/project-debug',
          name: 'project-debug',
          builder: (context, state) => const ProjectDebugScreen(),
        ),

        GoRoute(
          path: '/project-start-debug',
          name: 'project-start-debug',
          builder: (context, state) => const ProjectStartDebugScreen(),
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
  void goToSplash() => go('/splash');
  void goToOnboarding() => go('/onboarding');
  void goToWelcome() => go('/welcome');
  void goToLogin() => go('/login');
  void goToRegister() => go('/register');
  void goToForgotPassword() => go('/forgot-password');
  void goToDashboard() => go('/dashboard');
  void goToCreatePath() => go('/create-path');
  void goToViewPath(String pathId) => go('/view-path/$pathId');
  void goToProjectDetail(String projectId) => go('/project/$projectId');

  void goToDaily() => go('/daily');
  void goToLearningPaths() => go('/learning-paths');
  void goToProjects() => go('/projects');
  void goToAnalytics() => go('/analytics');
  void goToSettings() => go('/settings');
  void goToSummarizer() => go('/summarizer');
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
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String createPath = '/create-path';
  static const String viewPath = '/view-path';
  static const String daily = '/daily';
  static const String learningPaths = '/learning-paths';
  static const String projects = '/projects';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
}

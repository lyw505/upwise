import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../screens/dashboard_screen.dart';
import '../screens/learning_paths_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/create_path_screen.dart';
import '../screens/settings_screen.dart';
import 'summarizer_screen.dart';
import 'project_builder_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late PageController _pageController;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const LearningPathsScreen(),
    const CreatePathScreen(),
    const SummarizerScreen(),
    const ProjectBuilderScreen(),
    const AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: AppDimensions.bottomNavIconSize),
              activeIcon: Icon(Icons.home, size: AppDimensions.bottomNavIconSize),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined, size: AppDimensions.bottomNavIconSize),
              activeIcon: Icon(Icons.school, size: AppDimensions.bottomNavIconSize),
              label: 'Paths',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: AppDimensions.bottomNavIconSize),
              activeIcon: Icon(Icons.add_circle, size: AppDimensions.bottomNavIconSize),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined, size: AppDimensions.bottomNavIconSize),
              activeIcon: Icon(Icons.article, size: AppDimensions.bottomNavIconSize),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined, size: AppDimensions.bottomNavIconSize),
              activeIcon: Icon(Icons.build, size: AppDimensions.bottomNavIconSize),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined, size: AppDimensions.bottomNavIconSize),
              activeIcon: Icon(Icons.analytics, size: AppDimensions.bottomNavIconSize),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }
}
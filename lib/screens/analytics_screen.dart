import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../providers/learning_path_provider.dart';
import '../providers/user_provider.dart';
import '../models/learning_path_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Analytics data
  int _totalLearningPaths = 0;
  int _completedPaths = 0;
  int _activePaths = 0;
  int _totalTasksCompleted = 0;
  int _totalStudyTimeMinutes = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  List<LearningPathModel> _learningPaths = [];
  Map<String, int> _weeklyProgress = {};
  Map<String, int> _monthlyProgress = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // This will trigger rebuild when tab changes to update icon colors
      });
    });
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalyticsData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    final authProvider = context.read<AuthProvider>();
    final learningPathProvider = context.read<LearningPathProvider>();
    final userProvider = context.read<UserProvider>();
    
    if (authProvider.currentUser != null) {
      // Load user data
      await userProvider.loadUser(authProvider.currentUser!.id);
      
      // Load learning paths
      await learningPathProvider.loadLearningPaths(authProvider.currentUser!.id);
      
      // Calculate analytics
      _calculateAnalytics(learningPathProvider.learningPaths, userProvider.user);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _calculateAnalytics(List<LearningPathModel> paths, user) {
    _learningPaths = paths;
    _totalLearningPaths = paths.length;
    _completedPaths = paths.where((p) => p.status == LearningPathStatus.completed).length;
    _activePaths = paths.where((p) => p.status == LearningPathStatus.inProgress).length;
    
    // Calculate total tasks completed and study time
    _totalTasksCompleted = 0;
    _totalStudyTimeMinutes = 0;
    
    for (final path in paths) {
      final completedTasks = path.dailyTasks.where((t) => t.status == TaskStatus.completed || t.status == TaskStatus.skipped);
      _totalTasksCompleted += completedTasks.length;
      
      for (final task in completedTasks) {
        _totalStudyTimeMinutes += task.timeSpentMinutes ?? 30; // Default 30 minutes if not specified
      }
    }
    
    // User streak data
    _currentStreak = user?.currentStreak ?? 0;
    _longestStreak = user?.longestStreak ?? 0;
    
    // Generate mock weekly/monthly data for charts
    _generateProgressData();
  }

  void _generateProgressData() {
    // Generate last 7 days data
    _weeklyProgress = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      // Mock data - in real app, this would come from database
      _weeklyProgress[dayName] = (i < 3) ? (7 - i) * 10 : 0;
    }
    
    // Generate last 6 months data
    _monthlyProgress = {};
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(date.month);
      // Mock data - in real app, this would come from database
      _monthlyProgress[monthName] = (i < 4) ? (6 - i) * 20 : 0;
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Analytics',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.all(24.0),
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.primary.withValues(alpha: 0.1);
                  }
                  return null;
                }),
                tabs: [
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dashboard_outlined,
                            size: 16,
                            color: _tabController.index == 0 ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Overview',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up_outlined,
                            size: 16,
                            color: _tabController.index == 1 ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Progress',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outlined,
                            size: 16,
                            color: _tabController.index == 2 ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Insights',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildProgressTab(),
                        _buildInsightsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          _buildStatsGrid(),
          
          const SizedBox(height: 32),
          
          // Recent Activity
          _buildSectionTitle('Recent Activity'),
          const SizedBox(height: 16),
          _buildRecentActivity(),
          
          const SizedBox(height: 32),
          
          // Learning Paths Overview
          _buildSectionTitle('Learning Paths'),
          const SizedBox(height: 16),
          _buildLearningPathsOverview(),
          
          const SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Progress Chart
          _buildSectionTitle('Weekly Progress'),
          const SizedBox(height: 16),
          _buildWeeklyChart(),
          
          const SizedBox(height: 32),
          
          // Monthly Progress Chart
          _buildSectionTitle('Monthly Progress'),
          const SizedBox(height: 16),
          _buildMonthlyChart(),
          
          const SizedBox(height: 32),
          
          // Streak Visualization
          _buildSectionTitle('Streak History'),
          const SizedBox(height: 16),
          _buildStreakVisualization(),
          
          const SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Study Habits
          _buildSectionTitle('Study Habits'),
          const SizedBox(height: 16),
          _buildStudyHabits(),
          
          const SizedBox(height: 32),
          
          // Recommendations
          _buildSectionTitle('Recommendations'),
          const SizedBox(height: 16),
          _buildRecommendations(),
          
          const SizedBox(height: 32),
          
          // Achievements
          _buildSectionTitle('Achievements'),
          const SizedBox(height: 16),
          _buildAchievements(),
          
          const SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Learning Paths',
          _totalLearningPaths.toString(),
          Icons.school_outlined,
          AppColors.primary,
        ),
        _buildStatCard(
          'Completed',
          _completedPaths.toString(),
          Icons.check_circle_outline,
          AppColors.success,
        ),
        _buildStatCard(
          'Tasks Done',
          _totalTasksCompleted.toString(),
          Icons.task_alt_outlined,
          AppColors.info,
        ),
        _buildStatCard(
          'Study Time',
          '${(_totalStudyTimeMinutes / 60).toStringAsFixed(1)}h',
          Icons.access_time_outlined,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_learningPaths.isEmpty) {
      return _buildEmptyState('No recent activity', Icons.timeline_outlined);
    }

    // Generate recent activities based on actual data
    List<Widget> activities = [];
    
    // Add completed tasks activity
    if (_totalTasksCompleted > 0) {
      activities.add(_buildActivityItem(
        'Completed daily task',
        _learningPaths.isNotEmpty ? '${_learningPaths.first.topic} - Day $_totalTasksCompleted' : 'Learning task',
        Icons.check_circle_outline,
        AppColors.success,
        '2 hours ago',
      ));
    }
    
    // Add started learning path activity
    if (_activePaths > 0) {
      activities.add(_buildActivityItem(
        'Started learning path',
        _learningPaths.where((p) => p.status == LearningPathStatus.inProgress).isNotEmpty 
            ? _learningPaths.where((p) => p.status == LearningPathStatus.inProgress).first.topic
            : 'New learning path',
        Icons.play_arrow_outlined,
        AppColors.primary,
        '1 day ago',
      ));
    }
    
    // Add streak activity
    if (_currentStreak >= 3) {
      activities.add(_buildActivityItem(
        'Achieved $_currentStreak-day streak',
        'Keep up the great work!',
        Icons.local_fire_department_outlined,
        AppColors.warning,
        '$_currentStreak days ago',
      ));
    }
    
    // If no activities, show placeholder
    if (activities.isEmpty) {
      activities.add(_buildActivityItem(
        'Welcome to Upwise!',
        'Start your first learning path to see activities here',
        Icons.waving_hand_outlined,
        AppColors.info,
        'Just now',
      ));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: activities.expand((activity) => [
          activity,
          if (activity != activities.last) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
        ]).toList(),
      ),
    );
  }

  Widget _buildActivityItem(String action, String detail, IconData icon, Color color, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  detail,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathsOverview() {
    if (_learningPaths.isEmpty) {
      return _buildEmptyState('No learning paths yet', Icons.school_outlined);
    }

    return Column(
      children: _learningPaths.take(3).map((path) {
        Color statusColor;
        switch (path.status) {
          case LearningPathStatus.completed:
            statusColor = AppColors.success;
            break;
          case LearningPathStatus.inProgress:
            statusColor = AppColors.primary;
            break;
          case LearningPathStatus.paused:
            statusColor = AppColors.warning;
            break;
          default:
            statusColor = AppColors.textTertiary;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              // Navigate to learning path detail
              context.goToViewPath(path.id);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      path.topic,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${path.progressPercentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${path.completedOrSkippedTasksCount}/${path.dailyTasks.length} tasks completed',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: path.progressPercentage / 100,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks Completed This Week',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyProgress.entries.map((entry) {
                final maxValue = _weeklyProgress.values.isNotEmpty 
                    ? _weeklyProgress.values.reduce((a, b) => a > b ? a : b) 
                    : 1;
                final height = maxValue > 0 ? (entry.value / maxValue) * 100 : 0.0;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.value > 0)
                          Text(
                            entry.value.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        SizedBox(height: entry.value > 0 ? 8 : 20),
                        Container(
                          width: double.infinity,
                          height: height.clamp(4.0, 100.0),
                          decoration: BoxDecoration(
                            color: entry.value > 0 ? AppColors.primary : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          entry.key,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Study Hours',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _monthlyProgress.entries.map((entry) {
                final maxValue = _monthlyProgress.values.isNotEmpty 
                    ? _monthlyProgress.values.reduce((a, b) => a > b ? a : b) 
                    : 1;
                final height = maxValue > 0 ? (entry.value / maxValue) * 120 : 0.0;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.value > 0)
                          Text(
                            '${entry.value}h',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        SizedBox(height: entry.value > 0 ? 8 : 20),
                        Container(
                          width: double.infinity,
                          height: height.clamp(4.0, 120.0),
                          constraints: const BoxConstraints(maxWidth: 40),
                          decoration: BoxDecoration(
                            color: entry.value > 0 ? AppColors.success : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: Text(
                            entry.key,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakVisualization() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStreakStat('Current Streak', _currentStreak, Icons.local_fire_department, AppColors.warning),
              _buildStreakStat('Longest Streak', _longestStreak, Icons.emoji_events, AppColors.success),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keep learning daily to maintain your streak!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: AppTextStyles.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStudyHabits() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildHabitItem('Average Study Time', '${(_totalStudyTimeMinutes / 60 / 7).toStringAsFixed(1)} hours/day', Icons.access_time),
          const Divider(),
          _buildHabitItem('Most Active Day', 'Monday', Icons.calendar_today),
          const Divider(),
          _buildHabitItem('Completion Rate', '${_totalLearningPaths > 0 ? ((_completedPaths / _totalLearningPaths) * 100).toStringAsFixed(0) : 0}%', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildHabitItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      children: [
        _buildRecommendationCard(
          'Maintain Your Streak',
          'You\'re doing great! Complete today\'s task to keep your $_currentStreak-day streak going.',
          Icons.local_fire_department,
          AppColors.warning,
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          'Try a New Topic',
          'Based on your progress, you might enjoy learning about Data Science or Web Development.',
          Icons.lightbulb,
          AppColors.info,
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          'Increase Study Time',
          'Consider extending your daily study sessions to 45 minutes for faster progress.',
          Icons.trending_up,
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildAchievementCard('First Steps', 'Complete your first task', Icons.baby_changing_station, _totalTasksCompleted > 0),
        _buildAchievementCard('Week Warrior', 'Maintain 7-day streak', Icons.local_fire_department, _currentStreak >= 7),
        _buildAchievementCard('Path Completer', 'Complete a learning path', Icons.emoji_events, _completedPaths > 0),
        _buildAchievementCard('Time Master', 'Study for 10+ hours', Icons.access_time, _totalStudyTimeMinutes >= 600),
      ],
    );
  }

  Widget _buildAchievementCard(String title, String description, IconData icon, bool achieved) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achieved ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achieved ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: achieved ? AppColors.success : AppColors.textTertiary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: achieved ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: achieved ? AppColors.success : AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

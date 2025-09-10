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
  // int _activePaths = 0; // Unused for now
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
    _loadAnalyticsData();
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
    // _activePaths = paths.where((p) => p.status == LearningPathStatus.inProgress).length;
    
    // Calculate total tasks completed and study time
    _totalTasksCompleted = 0;
    _totalStudyTimeMinutes = 0;
    
    for (final path in paths) {
      final completedTasks = path.dailyTasks.where((t) => t.status == TaskStatus.completed);
      _totalTasksCompleted += completedTasks.length;
      
      for (final task in completedTasks) {
        _totalStudyTimeMinutes += task.timeSpentMinutes ?? 0;
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
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Text(
                'Analytics',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF0EA5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Progress'),
              Tab(text: 'Insights'),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Tab Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
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
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          _buildStatsGrid(),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildSectionTitle('Recent Activity'),
          const SizedBox(height: 12),
          _buildRecentActivity(),
          
          const SizedBox(height: 24),
          
          // Learning Paths Overview
          _buildSectionTitle('Learning Paths'),
          const SizedBox(height: 12),
          _buildLearningPathsOverview(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Progress Chart
          _buildSectionTitle('Weekly Progress'),
          const SizedBox(height: 12),
          _buildWeeklyChart(),
          
          const SizedBox(height: 24),
          
          // Monthly Progress Chart
          _buildSectionTitle('Monthly Progress'),
          const SizedBox(height: 12),
          _buildMonthlyChart(),
          
          const SizedBox(height: 24),
          
          // Streak Visualization
          _buildSectionTitle('Streak History'),
          const SizedBox(height: 12),
          _buildStreakVisualization(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Study Habits
          _buildSectionTitle('Study Habits'),
          const SizedBox(height: 12),
          _buildStudyHabits(),
          
          const SizedBox(height: 24),
          
          // Recommendations
          _buildSectionTitle('Recommendations'),
          const SizedBox(height: 12),
          _buildRecommendations(),
          
          const SizedBox(height: 24),
          
          // Achievements
          _buildSectionTitle('Achievements'),
          const SizedBox(height: 12),
          _buildAchievements(),
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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Learning Paths',
          _totalLearningPaths.toString(),
          Icons.school,
          AppColors.primary,
        ),
        _buildStatCard(
          'Completed',
          _completedPaths.toString(),
          Icons.check_circle,
          AppColors.success,
        ),
        _buildStatCard(
          'Tasks Done',
          _totalTasksCompleted.toString(),
          Icons.task_alt,
          AppColors.info,
        ),
        _buildStatCard(
          'Study Time',
          '${(_totalStudyTimeMinutes / 60).toStringAsFixed(1)}h',
          Icons.access_time,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_learningPaths.isEmpty) {
      return _buildEmptyState('No recent activity', Icons.timeline);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildActivityItem(
            'Completed daily task',
            'Flutter Development - Day 3',
            Icons.check_circle,
            AppColors.success,
            '2 hours ago',
          ),
          const Divider(),
          _buildActivityItem(
            'Started learning path',
            'Machine Learning Basics',
            Icons.play_arrow,
            AppColors.primary,
            '1 day ago',
          ),
          const Divider(),
          _buildActivityItem(
            'Achieved 7-day streak',
            'Keep up the great work!',
            Icons.local_fire_department,
            AppColors.warning,
            '3 days ago',
          ),
        ],
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
      return _buildEmptyState('No learning paths yet', Icons.school);
    }

    return Column(
      children: _learningPaths.take(3).map((path) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path.topic,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${path.completedTasksCount}/${path.dailyTasks.length} tasks completed',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: path.progressPercentage / 100,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${path.progressPercentage.toStringAsFixed(0)}%',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'Tasks Completed This Week',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyProgress.entries.map((entry) {
                final maxValue = _weeklyProgress.values.reduce((a, b) => a > b ? a : b);
                final height = maxValue > 0 ? (entry.value / maxValue) * 120 : 0.0;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      entry.value.toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
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
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'Monthly Study Hours',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _monthlyProgress.entries.map((entry) {
                final maxValue = _monthlyProgress.values.reduce((a, b) => a > b ? a : b);
                final height = maxValue > 0 ? (entry.value / maxValue) * 120 : 0.0;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.value}h',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
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

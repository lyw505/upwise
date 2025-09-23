import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_dimensions.dart';
import '../widgets/consistent_header.dart';
import '../providers/auth_provider.dart';
import '../providers/learning_path_provider.dart';
import '../providers/user_provider.dart';
import '../models/learning_path_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
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
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalyticsData();
    });
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
      body: Column(
        children: [
          ConsistentHeader(
            title: 'Analytics',
            showProfile: false,
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _buildAnalyticsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards (only Tasks Done and Study Time)
          _buildStatsGrid(),
          
          const SizedBox(height: 16),
          
          // Streak Cards Row
          Row(
            children: [
              Expanded(child: _buildCurrentStreakCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildLongestStreakCard()),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Study Habits Card (full width)
          _buildStudyHabitsCard(),
          
          const SizedBox(height: 32),
          
          // Weekly Progress Chart
          _buildSectionTitle('Weekly Progress'),
          const SizedBox(height: 16),
          _buildWeeklyChart(),
          
          const SizedBox(height: 32),
          
          // Monthly Progress Chart
          _buildSectionTitle('Monthly Progress'),
          const SizedBox(height: 16),
          _buildMonthlyChart(),
          
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
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tasks Done',
            _totalTasksCompleted.toString(),
            Icons.task_alt_outlined,
            AppColors.info,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Study Time',
            '${(_totalStudyTimeMinutes / 60).toStringAsFixed(1)}h',
            Icons.access_time_outlined,
            AppColors.warning,
          ),
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
                            color: entry.value > 0 ? AppColors.primary : AppColors.borderLight,
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

  Widget _buildCurrentStreakCard() {
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_fire_department, color: AppColors.warning, size: 20),
              ),
              const Spacer(),
              Text(
                _currentStreak.toString(),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current Streak',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLongestStreakCard() {
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
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.emoji_events, color: AppColors.success, size: 20),
              ),
              const Spacer(),
              Text(
                _longestStreak.toString(),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Longest Streak',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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

  Widget _buildStudyHabitsCard() {
    return Container(
      width: double.infinity,
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
            'Study Habits',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHabitItem('Avg/Day', '${(_totalStudyTimeMinutes / 60 / 7).toStringAsFixed(1)}h', Icons.access_time),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildHabitItem('Rate', '${_totalLearningPaths > 0 ? ((_completedPaths / _totalLearningPaths) * 100).toStringAsFixed(0) : 0}%', Icons.trending_up),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(String label, String value, IconData icon) {
    return Row(
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
    );
  }





}

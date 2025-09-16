import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/learning_path_provider.dart';
import '../models/learning_path_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final learningPathProvider = context.read<LearningPathProvider>();

    if (authProvider.currentUser != null) {
      await userProvider.loadUser(authProvider.currentUser!.id);
      await learningPathProvider.loadLearningPaths(authProvider.currentUser!.id);
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    if (mounted) {
      context.goToWelcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with app name and profile
            _buildAppHeader(),
            
            const SizedBox(height: 24),
            
            // Welcome back card
            _buildWelcomeCard(),
            
            const SizedBox(height: 20),
            
            // Streak card
            _buildStreakCard(),
            
            const SizedBox(height: 20),
            
            // Action Buttons Row
            _buildActionButtons(),
            
            const SizedBox(height: 24),
            
            // Active Learning Path Section
            _buildActiveLearningPathSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Upwise',
          style: AppTextStyles.headlineLarge.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            // Show profile menu
            _showProfileMenu();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final userName = userProvider.user?.name ?? 'User';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD), // Light blue background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF90CAF9), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome back, $userName!',
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ready to continue your learning journey?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.goToAnalytics(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View progress',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakCard() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0EA5E9)),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFF0EA5E9),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're on ${userProvider.currentStreak} days streak!",
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You completed 12 topics this week!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Consumer<LearningPathProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Learning Paths',
                value: '${provider.totalLearningPaths}',
                icon: Icons.school,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Completed',
                value: '${provider.completedLearningPaths}',
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Active',
                value: '${provider.activeLearningPaths}',
                icon: Icons.play_circle,
                color: AppColors.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.goToCreatePath();
        },
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: Text(
          'Create Learning Path',
          style: AppTextStyles.buttonMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0EA5E9),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLearningPathSection() {
    return Consumer<LearningPathProvider>(
      builder: (context, provider, child) {
        final activePaths = provider.learningPaths
            .where((path) => path.status == LearningPathStatus.inProgress)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Learning Path :',
              style: AppTextStyles.titleLarge.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (activePaths.isEmpty)
              _buildNoActivePath()
            else
              _buildActivePathsList(activePaths),
          ],
        );
      },
    );
  }

  Widget _buildNoActivePath() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Learning Path',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first learning path to get started!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivePathCard(LearningPathModel path) {
    return GestureDetector(
      onTap: () => context.goToViewPath(path.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF90CAF9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              path.topic,
              style: AppTextStyles.titleLarge.copyWith(
                color: const Color(0xFF0EA5E9),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Cleaning',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  '${path.durationDays} days',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${path.progressPercentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF0EA5E9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: path.progressPercentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${path.completedOrSkippedTasksCount}/${path.dailyTasks.length} tasks completed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePathsList(List<LearningPathModel> activePaths) {
    // Display up to 5 active learning paths
    final displayPaths = activePaths.take(5).toList();
    final hasMorePaths = activePaths.length > 5;

    return Column(
      children: [
        // Display the active learning paths
        ...displayPaths.map((path) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCompactActivePathCard(path),
        )).toList(),
        
        // Show "Lihat Semua" button if there are more than 5 paths or if we want to navigate to all paths
        if (activePaths.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.goToLearningPaths();
                },
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Color(0xFF0EA5E9),
                ),
                label: Text(
                  'View All',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: const Color(0xFF0EA5E9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0EA5E9)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactActivePathCard(LearningPathModel path) {
    return GestureDetector(
      onTap: () => context.goToViewPath(path.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    path.topic,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'In Progress',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: const Color(0xFF0EA5E9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (path.description.isNotEmpty)
              Text(
                path.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${path.durationDays} days',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${path.dailyTimeMinutes} min/day',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${path.progressPercentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF0EA5E9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: path.progressPercentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${path.completedOrSkippedTasksCount}/${path.dailyTasks.length} tasks completed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.goToSettings();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningPathsSection() {
    return Consumer<LearningPathProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Learning Paths',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (provider.learningPaths.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Navigate to analytics to see all learning paths
                      context.goToAnalytics();
                    },
                    child: Text(
                      'View All',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.learningPaths.isEmpty)
              _buildEmptyState()
            else
              _buildLearningPathsList(provider.learningPaths.take(3).toList()),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Learning Paths Yet',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first AI-powered learning path to get started!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathsList(List learningPaths) {
    return Column(
      children: learningPaths.map((path) => _buildLearningPathCard(path)).toList(),
    );
  }

  Widget _buildLearningPathCard(LearningPathModel path) {
    // Calculate status color and text
    Color statusColor;
    String statusText;

    switch (path.status) {
      case LearningPathStatus.notStarted:
        statusColor = AppColors.textTertiary;
        statusText = 'Not Started';
        break;
      case LearningPathStatus.inProgress:
        statusColor = AppColors.primary;
        statusText = 'In Progress';
        break;
      case LearningPathStatus.completed:
        statusColor = AppColors.success;
        statusText = 'Completed';
        break;
      case LearningPathStatus.paused:
        statusColor = AppColors.warning;
        statusText = 'Paused';
        break;
    }

    return GestureDetector(
      onTap: () => context.goToViewPath(path.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
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
                    statusText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (path.description.isNotEmpty)
              Text(
                path.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: path.progressPercentage / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${path.progressPercentage.toStringAsFixed(0)}% Complete',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  ' • ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  '${path.completedTasksCount}/${path.dailyTasks.length} tasks',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTaskSection() {
    return Consumer<LearningPathProvider>(
      builder: (context, provider, child) {
        // Find active learning path with today's task
        final activePaths = provider.learningPaths
            .where((path) => path.status == LearningPathStatus.inProgress)
            .toList();

        final todayTask = activePaths.isNotEmpty ? activePaths.first.todayTask : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Today's Task",
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (todayTask != null)
                  TextButton.icon(
                    onPressed: () => context.goToDaily(),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: todayTask != null ? AppColors.primary : AppColors.border,
                  width: todayTask != null ? 2 : 1,
                ),
                boxShadow: todayTask != null ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: todayTask != null
                  ? _buildTodayTaskContent(todayTask, activePaths.first)
                  : _buildNoTaskContent(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodayTaskContent(dynamic todayTask, dynamic learningPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'TODAY',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Day ${todayTask.dayNumber}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          todayTask.mainTopic,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          todayTask.subTopic,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'From: ${learningPath.topic}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.goToDaily(),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(
              'Start Learning',
              style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoTaskContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No active learning path',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a learning path to see your daily tasks here.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.goToCreatePath(),
            icon: const Icon(Icons.add),
            label: const Text('Create Learning Path'),
          ),
        ),
      ],
    );
  }
}

// Add floating action button to Scaffold
// Note: This should be added to the Scaffold in the build method

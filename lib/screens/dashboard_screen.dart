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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
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
                case 'config-status':
                  context.goToConfigStatus();
                  break;
                case 'test-integration':
                  context.goToTestIntegration();
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Analytics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'config-status',
                child: ListTile(
                  leading: Icon(Icons.settings_applications),
                  title: Text('Config Status'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'test-integration',
                child: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Test Integration'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting and streak
                _buildHeader(),
                
                const SizedBox(height: 32),
                
                // Quick Stats
                _buildQuickStats(),
                
                const SizedBox(height: 32),
                
                // Create Learning Path Button
                _buildCreatePathButton(),
                
                const SizedBox(height: 32),
                
                // Learning Paths Section
                _buildLearningPathsSection(),
                
                const SizedBox(height: 32),
                
                // Today's Task (if any)
                _buildTodayTaskSection(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goToCreatePath(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create',
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProvider.getGreeting(),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to learn something new today?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Streak Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.streakBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.streak.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '${userProvider.currentStreak}',
                    style: AppTextStyles.streak,
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildCreatePathButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.goToCreatePath();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Learning Path',
          style: AppTextStyles.buttonLarge.copyWith(
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
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

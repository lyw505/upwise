import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../providers/learning_path_provider.dart';
import '../providers/user_provider.dart';
import '../models/learning_path_model.dart';

class ViewPathScreen extends StatefulWidget {
  final String pathId;
  
  const ViewPathScreen({
    super.key,
    required this.pathId,
  });

  @override
  State<ViewPathScreen> createState() => _ViewPathScreenState();
}

class _ViewPathScreenState extends State<ViewPathScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  LearningPathModel? _learningPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLearningPath();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLearningPath() async {
    final learningPathProvider = context.read<LearningPathProvider>();
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.currentUser != null) {
      await learningPathProvider.loadLearningPaths(authProvider.currentUser!.id);
      
      // Find the specific learning path
      final paths = learningPathProvider.learningPaths;
      final path = paths.firstWhere(
        (p) => p.id == widget.pathId,
        orElse: () => throw Exception('Learning path not found'),
      );
      
      setState(() {
        _learningPath = path;
        _isLoading = false;
      });
    }
  }

  Future<void> _startLearningPath() async {
    if (_learningPath == null) return;
    
    final learningPathProvider = context.read<LearningPathProvider>();
    final success = await learningPathProvider.startLearningPath(_learningPath!.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Learning path started! Good luck on your journey!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Reload to get updated status
      await _loadLearningPath();
    }
  }

  Future<void> _updateTaskStatus(String taskId, TaskStatus status) async {
    final learningPathProvider = context.read<LearningPathProvider>();
    final userProvider = context.read<UserProvider>();
    
    final success = await learningPathProvider.updateTaskStatus(
      taskId: taskId,
      status: status,
      timeSpentMinutes: status == TaskStatus.completed ? 30 : null, // Default 30 minutes
    );
    
    if (success) {
      // Update streak if task completed
      if (status == TaskStatus.completed) {
        await userProvider.updateStreak();
      }
      
      // Reload to show updated progress
      await _loadLearningPath();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == TaskStatus.completed 
                  ? 'Task completed! Great job!' 
                  : 'Task status updated',
            ),
            backgroundColor: status == TaskStatus.completed 
                ? AppColors.success 
                : AppColors.info,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Learning Path'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.goToDashboard(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_learningPath == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Learning Path'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.goToDashboard(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Learning Path Not Found',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.goToDashboard(),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_learningPath!.topic),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.goToDashboard(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // TODO: Implement edit functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon!')),
                  );
                  break;
                case 'delete':
                  // TODO: Implement delete functionality
                  _showDeleteConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Path'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Path', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Learning Plan'),
            Tab(text: 'Projects'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header with progress and actions
          _buildHeader(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLearningPlanTab(),
                _buildProjectsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (_learningPath!.description.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _learningPath!.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          
          // Progress and stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _learningPath!.progressPercentage / 100,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_learningPath!.progressPercentage.toStringAsFixed(0)}% Complete • ${_learningPath!.completedTasksCount}/${_learningPath!.dailyTasks.length} tasks',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _buildStatusChip(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action button
          if (_learningPath!.status == LearningPathStatus.notStarted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startLearningPath,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: Text(
                  'Start Learning Path',
                  style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
                ),
              ),
            )
          else if (_learningPath!.status == LearningPathStatus.inProgress)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final todayTask = _learningPath!.todayTask;
                  if (todayTask != null) {
                    // TODO: Navigate to daily tracker with specific task
                    context.goToDaily();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No task available for today')),
                    );
                  }
                },
                icon: const Icon(Icons.today),
                label: Text(
                  'Continue Today\'s Task',
                  style: AppTextStyles.buttonMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;
    
    switch (_learningPath!.status) {
      case LearningPathStatus.notStarted:
        chipColor = AppColors.textTertiary;
        statusText = 'Not Started';
        break;
      case LearningPathStatus.inProgress:
        chipColor = AppColors.primary;
        statusText = 'In Progress';
        break;
      case LearningPathStatus.completed:
        chipColor = AppColors.success;
        statusText = 'Completed';
        break;
      case LearningPathStatus.paused:
        chipColor = AppColors.warning;
        statusText = 'Paused';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: AppTextStyles.labelSmall.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLearningPlanTab() {
    if (_learningPath!.dailyTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Learning Tasks',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This learning path doesn\'t have any daily tasks yet.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _learningPath!.dailyTasks.length,
      itemBuilder: (context, index) {
        final task = _learningPath!.dailyTasks[index];
        return _buildTaskCard(task, index);
      },
    );
  }

  Widget _buildTaskCard(DailyLearningTask task, int index) {
    final isCompleted = task.status == TaskStatus.completed;
    final isToday = _learningPath!.todayTask?.id == task.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? AppColors.primary : AppColors.border,
          width: isToday ? 2 : 1,
        ),
        boxShadow: isToday ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: ExpansionTile(
        leading: _buildTaskStatusIcon(task.status),
        title: Row(
          children: [
            Text(
              'Day ${task.dayNumber}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TODAY',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.mainTopic,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            Text(
              task.subTopic,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.materialTitle != null) ...[
                  Text(
                    'Recommended Material:',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.materialTitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (task.exercise != null) ...[
                  Text(
                    'Exercise:',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.exercise!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Task actions
                if (_learningPath!.status == LearningPathStatus.inProgress)
                  Row(
                    children: [
                      if (task.status != TaskStatus.completed) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _updateTaskStatus(task.id, TaskStatus.completed),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Mark Complete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: BorderSide(color: AppColors.success),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _updateTaskStatus(task.id, TaskStatus.skipped),
                            icon: const Icon(Icons.skip_next, size: 16),
                            label: const Text('Skip'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Completed',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 24,
        );
      case TaskStatus.inProgress:
        return Icon(
          Icons.play_circle_outline,
          color: AppColors.primary,
          size: 24,
        );
      case TaskStatus.skipped:
        return Icon(
          Icons.skip_next,
          color: AppColors.textTertiary,
          size: 24,
        );
      case TaskStatus.notStarted:
      default:
        return Icon(
          Icons.radio_button_unchecked,
          color: AppColors.textTertiary,
          size: 24,
        );
    }
  }

  Widget _buildProjectsTab() {
    if (_learningPath!.projectRecommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Project Recommendations',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This learning path doesn\'t include project recommendations.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _learningPath!.projectRecommendations.length,
      itemBuilder: (context, index) {
        final project = _learningPath!.projectRecommendations[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(ProjectRecommendation project) {
    Color difficultyColor;
    switch (project.difficulty?.toLowerCase()) {
      case 'beginner':
        difficultyColor = AppColors.success;
        break;
      case 'intermediate':
        difficultyColor = AppColors.warning;
        break;
      case 'advanced':
        difficultyColor = AppColors.error;
        break;
      default:
        difficultyColor = AppColors.textTertiary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (project.difficulty != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: difficultyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: difficultyColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      project.difficulty!.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: difficultyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (project.estimatedHours != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Estimated: ${project.estimatedHours} hours',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
            if (project.url != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Open URL
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening: ${project.url}')),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View Project'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Learning Path'),
        content: const Text(
          'Are you sure you want to delete this learning path? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete feature coming soon!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

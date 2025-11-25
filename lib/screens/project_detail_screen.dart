import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_dimensions.dart';
import '../core/router/app_router.dart';
import '../core/utils/snackbar_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../models/project_model.dart';

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  UserProject? _project;
  List<ProjectStepCompletion> _steps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjectDetails();
    });
  }

  Future<void> _loadProjectDetails() async {
    final projectProvider = context.read<ProjectProvider>();
    
    setState(() => _isLoading = true);
    
    // Find project in provider
    final project = projectProvider.userProjects
        .where((p) => p.id == widget.projectId)
        .firstOrNull;
    
    if (project != null) {
      _project = project;
      
      // Load project steps
      _steps = await projectProvider.getProjectSteps(widget.projectId);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Project Details'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    if (_project == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Project Details'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          automaticallyImplyLeading: false,
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
                'Project Not Found',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.goToProjects(),
                child: const Text('Go to Projects'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_project!.title),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Project', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProjectHeader(),
            _buildProjectSteps(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
        currentIndex: 3, // Highlight "Projects" since we're in project detail
        onTap: (index) {
          switch (index) {
            case 0:
              context.goToDashboard();
              break;
            case 1:
              context.goToLearningPaths();
              break;
            case 2:
              context.goToCreatePath();
              break;
            case 3:
              context.goToProjects();
              break;
            case 4:
              context.goToSummarizer();
              break;
            case 5:
              context.goToAnalytics();
              break;
          }
        },
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
            icon: Icon(Icons.build_outlined, size: AppDimensions.bottomNavIconSize),
            activeIcon: Icon(Icons.build, size: AppDimensions.bottomNavIconSize),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined, size: AppDimensions.bottomNavIconSize),
            activeIcon: Icon(Icons.article, size: AppDimensions.bottomNavIconSize),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined, size: AppDimensions.bottomNavIconSize),
            activeIcon: Icon(Icons.analytics, size: AppDimensions.bottomNavIconSize),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
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
          // Project title and status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _project!.title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_project!.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _project!.description!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildStatusChip(_project!.status),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Progress section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _project!.progressPercentage / 100,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_project!.progressPercentage.toStringAsFixed(0)}% Complete',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    '${_project!.currentStep}/${_project!.totalSteps} steps',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Project stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Time Spent',
                  '${_project!.actualHoursSpent.toStringAsFixed(1)}h',
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Estimated',
                  '${_project!.estimatedHours ?? 0}h',
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Steps',
                  '${_project!.currentStep}/${_project!.totalSteps}',
                  Icons.list_alt,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          if (_project!.status == ProjectStatus.notStarted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startProject,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          else if (_project!.status == ProjectStatus.inProgress)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pauseProject,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _project!.progressPercentage >= 100 ? _completeProject : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case ProjectStatus.notStarted:
        color = AppColors.textTertiary;
        text = 'Not Started';
        break;
      case ProjectStatus.inProgress:
        color = AppColors.primary;
        text = 'In Progress';
        break;
      case ProjectStatus.completed:
        color = AppColors.success;
        text = 'Completed';
        break;
      case ProjectStatus.paused:
        color = AppColors.warning;
        text = 'Paused';
        break;
      case ProjectStatus.cancelled:
        color = AppColors.error;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProjectSteps() {
    if (_steps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No Project Steps',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This project doesn\'t have any steps defined yet.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Steps',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_steps.length, (index) {
            final step = _steps[index];
            return _buildStepCard(step, index);
          }),
        ],
      ),
    );
  }

  Widget _buildStepCard(ProjectStepCompletion step, int index) {
    final isCompleted = step.isCompleted;
    final canComplete = _project!.status == ProjectStatus.inProgress;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? AppColors.success : AppColors.border,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.success : AppColors.textTertiary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${step.stepNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        title: Text(
          step.stepTitle,
          style: AppTextStyles.titleSmall.copyWith(
            color: isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: step.timeSpentMinutes > 0
            ? Text(
                'Time spent: ${step.timeSpentMinutes} minutes',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step.completionNotes != null) ...[
                  Text(
                    'Notes:',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.completionNotes!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (canComplete && !isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _completeStep(step),
                      icon: const Icon(Icons.check),
                      label: const Text('Mark as Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Completed on ${step.completedAt?.toString().split(' ')[0] ?? 'Unknown'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startProject() async {
    final projectProvider = context.read<ProjectProvider>();
    
    final success = await projectProvider.updateProjectStatus(
      _project!.id,
      ProjectStatus.inProgress,
    );

    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Project started!');
      await _loadProjectDetails();
    }
  }

  Future<void> _pauseProject() async {
    final projectProvider = context.read<ProjectProvider>();
    
    final success = await projectProvider.updateProjectStatus(
      _project!.id,
      ProjectStatus.paused,
    );

    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Project paused');
      await _loadProjectDetails();
    }
  }

  Future<void> _completeProject() async {
    final projectProvider = context.read<ProjectProvider>();
    
    final success = await projectProvider.updateProjectStatus(
      _project!.id,
      ProjectStatus.completed,
    );

    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Project completed! 🎉');
      await _loadProjectDetails();
    }
  }

  Future<void> _completeStep(ProjectStepCompletion step) async {
    final projectProvider = context.read<ProjectProvider>();
    
    final success = await projectProvider.completeProjectStep(
      projectId: _project!.id,
      stepNumber: step.stepNumber,
      timeSpentMinutes: 30, // Default 30 minutes
    );

    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Step completed!');
      await _loadProjectDetails();
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${_project!.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProject();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject() async {
    final projectProvider = context.read<ProjectProvider>();
    
    final success = await projectProvider.deleteProject(_project!.id);

    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Project deleted');
      context.goToProjects();
    }
  }
}
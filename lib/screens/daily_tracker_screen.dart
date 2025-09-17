import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../providers/learning_path_provider.dart';
import '../providers/user_provider.dart';
import '../models/learning_path_model.dart';

class DailyTrackerScreen extends StatefulWidget {
  const DailyTrackerScreen({super.key});

  @override
  State<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends State<DailyTrackerScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  DailyLearningTask? _todayTask;
  LearningPathModel? _activeLearningPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayTask();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodayTask() async {
    final authProvider = context.read<AuthProvider>();
    final learningPathProvider = context.read<LearningPathProvider>();
    
    if (authProvider.currentUser != null) {
      await learningPathProvider.loadLearningPaths(authProvider.currentUser!.id);
      
      // Find active learning path with today's task
      final activePaths = learningPathProvider.learningPaths
          .where((path) => path.status == LearningPathStatus.inProgress)
          .toList();
      
      if (activePaths.isNotEmpty) {
        _activeLearningPath = activePaths.first;
        _todayTask = _activeLearningPath!.todayTask;
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _startTimer() {
    if (_timer != null) return;
    
    setState(() {
      _isTimerRunning = true;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isTimerRunning = false;
      _elapsedSeconds = 0;
    });
  }

  Future<void> _completeTask() async {
    if (_todayTask == null) return;
    
    final learningPathProvider = context.read<LearningPathProvider>();
    final userProvider = context.read<UserProvider>();
    
    // Stop timer and get time spent
    _pauseTimer();
    final timeSpentMinutes = (_elapsedSeconds / 60).ceil();
    
    // Update task status
    final success = await learningPathProvider.updateTaskStatus(
      taskId: _todayTask!.id,
      status: TaskStatus.completed,
      timeSpentMinutes: timeSpentMinutes,
    );
    
    if (success) {
      // Update user streak
      await userProvider.updateStreak();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Task completed! Great job! Your streak has been updated.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Reload today's task
        await _loadTodayTask();
      }
    }
  }

  Future<void> _skipTask() async {
    if (_todayTask == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Today\'s Task'),
        content: const Text(
          'Are you sure you want to skip today\'s task? This won\'t break your streak, but you won\'t get credit for completing it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final learningPathProvider = context.read<LearningPathProvider>();
      
      final success = await learningPathProvider.updateTaskStatus(
        taskId: _todayTask!.id,
        status: TaskStatus.skipped,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task skipped. Come back tomorrow for the next one!'),
            backgroundColor: AppColors.warning,
          ),
        );
        
        // Reload today's task
        await _loadTodayTask();
      }
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.goToDashboard(),
        ),
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${userProvider.user?.currentStreak ?? 0}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todayTask == null
              ? _buildNoTaskView()
              : _buildTaskView(),
    );
  }

  Widget _buildNoTaskView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppColors.success,
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'ve completed today\'s task or don\'t have any active learning paths.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.goToCreatePath(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Create Learning Path',
                style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.goToDashboard(),
              icon: const Icon(Icons.dashboard),
              label: const Text('View Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Learning Path Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeLearningPath!.topic,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Day ${_todayTask!.dayNumber} of ${_activeLearningPath!.durationDays}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.goToViewPath(_activeLearningPath!.id),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textTertiary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Today's Task Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
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
                    const Spacer(),
                    Icon(
                      Icons.today,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  _todayTask!.mainTopic,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _todayTask!.subTopic,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                if (_todayTask!.materialTitle != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.book,
                          color: AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _todayTask!.materialTitle!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (_todayTask!.exercise != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _todayTask!.exercise!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Timer Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  'Study Timer',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatTime(_elapsedSeconds),
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                      icon: Icon(
                        _isTimerRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isTimerRunning ? 'Pause' : 'Start',
                        style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
                      ),
                    ),
                    
                    OutlinedButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _completeTask,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    'Complete Task',
                    style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _skipTask,
                  icon: const Icon(Icons.skip_next),
                  label: Text(
                    'Skip Task',
                    style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/learning_path_model.dart';
import '../services/gemini_service.dart';
import '../core/config/env_config.dart';

class LearningPathProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService _geminiService = GeminiService();
  
  List<LearningPathModel> _learningPaths = [];
  LearningPathModel? _currentLearningPath;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;

  // Getters
  List<LearningPathModel> get learningPaths => _learningPaths;
  LearningPathModel? get currentLearningPath => _currentLearningPath;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;

  // Analytics
  int get totalLearningPaths => _learningPaths.length;
  int get completedLearningPaths => _learningPaths.where((path) => path.isCompleted).length;
  int get activeLearningPaths => _learningPaths.where((path) => path.isActive).length;
  double get averageProgress => _learningPaths.isEmpty 
      ? 0.0 
      : _learningPaths.map((path) => path.progressPercentage).reduce((a, b) => a + b) / _learningPaths.length;

  Future<void> loadLearningPaths(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('learning_paths')
          .select('''
            *,
            daily_learning_tasks(*),
            project_recommendations(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _learningPaths = (response as List)
          .map((json) => LearningPathModel.fromJson(json))
          .toList();

      // Ensure daily tasks are sorted by day_number for each learning path
      for (int i = 0; i < _learningPaths.length; i++) {
        final path = _learningPaths[i];
        if (path.dailyTasks.isNotEmpty) {
          final sortedTasks = List<DailyLearningTask>.from(path.dailyTasks)
            ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
          _learningPaths[i] = path.copyWith(dailyTasks: sortedTasks);
        }
      }

    } catch (e) {
      _setError('Failed to load learning paths: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<LearningPathModel?> generateLearningPath({
    required String userId,
    required String topic,
    required int durationDays,
    required int dailyTimeMinutes,
    required ExperienceLevel experienceLevel,
    required LearningStyle learningStyle,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
    bool includeVideos = true,
    String? notes,
    String language = 'id', // Default to Indonesian
  }) async {
    try {
      _setGenerating(true);
      _clearError();

      // Generate learning path with or without YouTube videos using Gemini AI
      final generatedPath = includeVideos 
          ? await _geminiService.generateLearningPathWithVideos(
              topic: topic,
              durationDays: durationDays,
              dailyTimeMinutes: dailyTimeMinutes,
              experienceLevel: experienceLevel,
              learningStyle: learningStyle,
              outputGoal: outputGoal,
              includeProjects: includeProjects,
              includeExercises: includeExercises,
              notes: notes,
              language: language,
            )
          : await _geminiService.generateLearningPath(
              topic: topic,
              durationDays: durationDays,
              dailyTimeMinutes: dailyTimeMinutes,
              experienceLevel: experienceLevel,
              learningStyle: learningStyle,
              outputGoal: outputGoal,
              includeProjects: includeProjects,
              includeExercises: includeExercises,
              notes: notes,
              language: language,
            );

      if (generatedPath == null) {
        _setError('Failed to generate learning path');
        return null;
      }

      // Save to database
      final learningPathData = {
        'user_id': userId,
        'topic': topic,
        'description': generatedPath['description'] ?? '',
        'duration_days': durationDays,
        'daily_time_minutes': dailyTimeMinutes,
        'experience_level': experienceLevel.name,
        'learning_style': learningStyle.name,
        'output_goal': outputGoal,
        'include_projects': includeProjects,
        'include_exercises': includeExercises,
        'notes': notes,
        'status': LearningPathStatus.notStarted.name,
        'created_at': DateTime.now().toIso8601String(),
      };

      final pathResponse = await _supabase
          .from('learning_paths')
          .insert(learningPathData)
          .select()
          .single();

      final learningPathId = pathResponse['id'] as String;

      // Save daily tasks
      final dailyTasksRaw = generatedPath['daily_tasks'] as List<dynamic>?;
      if (dailyTasksRaw == null || dailyTasksRaw.isEmpty) {
        throw Exception('No daily tasks found in generated path');
      }

      final dailyTasks = dailyTasksRaw.map((task) => task as Map<String, dynamic>).toList();

      if (EnvConfig.isDebugMode) {
        print('Inserting ${dailyTasks.length} daily tasks for learning path: $learningPathId');
      }

      int successfulInsertions = 0;
      final List<String> insertionErrors = [];

      for (int i = 0; i < dailyTasks.length; i++) {
        final task = dailyTasks[i];

        try {
          final taskData = {
            'learning_path_id': learningPathId,
            'day_number': i + 1, // Ensure sequential day numbering
            'main_topic': task['main_topic'] ?? 'No topic',
            'sub_topic': task['sub_topic'] ?? 'No subtopic',
            'material_url': task['material_url'],
            'material_title': task['material_title'],
            'exercise': task['exercise'],
            'status': TaskStatus.notStarted.name,
            'youtube_videos': task['youtube_videos'] ?? [], // Add YouTube videos
          };

          if (EnvConfig.isDebugMode) {
            print('Inserting task ${i + 1}: ${task['main_topic']}');
            print('YouTube videos count: ${(task['youtube_videos'] as List?)?.length ?? 0}');
          }

          await _supabase.from('daily_learning_tasks').insert(taskData);
          successfulInsertions++;

          if (EnvConfig.isDebugMode) {
            print('✅ Task ${i + 1} inserted successfully');
          }

        } catch (taskError) {
          final errorMsg = 'Failed to insert task ${i + 1} (${task['main_topic']}): $taskError';
          insertionErrors.add(errorMsg);

          if (EnvConfig.isDebugMode) {
            print('❌ $errorMsg');
          }
        }
      }

      if (EnvConfig.isDebugMode) {
        print('Task insertion summary: $successfulInsertions/${dailyTasks.length} successful');
        if (insertionErrors.isNotEmpty) {
          print('Insertion errors:');
          for (final error in insertionErrors) {
            print('  - $error');
          }
        }
      }

      // If less than half the tasks were inserted, consider it a failure
      if (successfulInsertions < (dailyTasks.length / 2).ceil()) {
        throw Exception('Failed to insert sufficient daily tasks: only $successfulInsertions out of ${dailyTasks.length} tasks were inserted successfully');
      }

      // Save project recommendations if included
      if (includeProjects && generatedPath['project_recommendations'] != null) {
        final projectsRaw = generatedPath['project_recommendations'] as List<dynamic>?;
        if (projectsRaw != null && projectsRaw.isNotEmpty) {
          final projects = projectsRaw.map((project) => project as Map<String, dynamic>).toList();
          for (final project in projects) {
          await _supabase.from('project_recommendations').insert({
            'learning_path_id': learningPathId,
            'title': project['title'],
            'description': project['description'],
            'url': project['url'],
            'difficulty': project['difficulty'],
            'estimated_hours': project['estimated_hours'],
          });
          }
        }
      }

      // Reload learning paths to get the complete data
      await loadLearningPaths(userId);

      // Find the newly created learning path
      final newPath = _learningPaths.firstWhere((path) => path.id == learningPathId);
      _currentLearningPath = newPath;

      // Auto-start the learning path
      await startLearningPath(learningPathId);

      return _currentLearningPath;
    } catch (e) {
      _setError('Failed to generate learning path: ${e.toString()}');
      return null;
    } finally {
      _setGenerating(false);
    }
  }

  Future<bool> startLearningPath(String learningPathId) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from('learning_paths')
          .update({
            'status': LearningPathStatus.inProgress.name,
            'started_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', learningPathId);

      // Update local state
      final pathIndex = _learningPaths.indexWhere((path) => path.id == learningPathId);
      if (pathIndex != -1) {
        _learningPaths[pathIndex] = _learningPaths[pathIndex].copyWith(
          status: LearningPathStatus.inProgress,
          startedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        if (_currentLearningPath?.id == learningPathId) {
          _currentLearningPath = _learningPaths[pathIndex];
        }
      }

      return true;
    } catch (e) {
      _setError('Failed to start learning path: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    int? timeSpentMinutes,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updates = <String, dynamic>{
        'status': status.name,
      };

      // Handle completion timestamps
      if (status == TaskStatus.completed || status == TaskStatus.skipped) {
        updates['completed_at'] = DateTime.now().toIso8601String();
      } else if (status == TaskStatus.notStarted || status == TaskStatus.inProgress) {
        updates['completed_at'] = null; // Clear completion timestamp when resetting
      }

      if (timeSpentMinutes != null) {
        updates['time_spent_minutes'] = timeSpentMinutes;
      }

      await _supabase
          .from('daily_learning_tasks')
          .update(updates)
          .eq('id', taskId);

      // Update local state
      for (int i = 0; i < _learningPaths.length; i++) {
        final path = _learningPaths[i];
        final taskIndex = path.dailyTasks.indexWhere((task) => task.id == taskId);
        
        if (taskIndex != -1) {
          final updatedTasks = List<DailyLearningTask>.from(path.dailyTasks);
          updatedTasks[taskIndex] = updatedTasks[taskIndex].copyWith(
            status: status,
            completedAt: (status == TaskStatus.completed || status == TaskStatus.skipped) 
                ? DateTime.now() 
                : (status == TaskStatus.notStarted || status == TaskStatus.inProgress) 
                    ? null 
                    : updatedTasks[taskIndex].completedAt,
            timeSpentMinutes: timeSpentMinutes ?? updatedTasks[taskIndex].timeSpentMinutes,
          );
          
          // Sort tasks to maintain order
          updatedTasks.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
          
          _learningPaths[i] = path.copyWith(dailyTasks: updatedTasks);
          
          if (_currentLearningPath?.id == path.id) {
            _currentLearningPath = _learningPaths[i];
          }
          
          // Check if all tasks are completed or skipped, then auto-complete the learning path
          final updatedPath = _learningPaths[i];
          if (updatedPath.status == LearningPathStatus.inProgress && updatedPath.progressPercentage >= 100.0) {
            await _autoCompleteLearningPath(updatedPath.id);
          }
          
          // Show success message for task completion
          if (status == TaskStatus.completed) {
            // Task completed successfully
          }
          
          break;
        }
      }

      return true;
    } catch (e) {
      _setError('Failed to update task status: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _autoCompleteLearningPath(String learningPathId) async {
    try {
      // Update status to completed in database
      await _supabase
          .from('learning_paths')
          .update({
            'status': LearningPathStatus.completed.name,
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', learningPathId);

      // Update local state
      final pathIndex = _learningPaths.indexWhere((path) => path.id == learningPathId);
      if (pathIndex != -1) {
        _learningPaths[pathIndex] = _learningPaths[pathIndex].copyWith(
          status: LearningPathStatus.completed,
          completedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        if (_currentLearningPath?.id == learningPathId) {
          _currentLearningPath = _learningPaths[pathIndex];
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error auto-completing learning path: $e');
    }
  }

  Future<bool> completeLearningPath(String learningPathId) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from('learning_paths')
          .update({
            'status': LearningPathStatus.completed.name,
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', learningPathId);

      // Update local state
      final pathIndex = _learningPaths.indexWhere((path) => path.id == learningPathId);
      if (pathIndex != -1) {
        _learningPaths[pathIndex] = _learningPaths[pathIndex].copyWith(
          status: LearningPathStatus.completed,
          completedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        if (_currentLearningPath?.id == learningPathId) {
          _currentLearningPath = _learningPaths[pathIndex];
        }
      }

      return true;
    } catch (e) {
      _setError('Failed to complete learning path: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setCurrentLearningPath(LearningPathModel? path) {
    _currentLearningPath = path;
    notifyListeners();
  }

  DailyLearningTask? getTodayTask(String learningPathId) {
    final path = _learningPaths.firstWhere(
      (path) => path.id == learningPathId,
      orElse: () => throw Exception('Learning path not found'),
    );
    
    return path.todayTask;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setGenerating(bool generating) {
    _isGenerating = generating;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  Future<bool> updateLearningPath(LearningPathModel updatedPath) async {
    try {
      _setLoading(true);
      _clearError();

      // Update in Supabase
      await _supabase
          .from('learning_paths')
          .update({
            'topic': updatedPath.topic,
            'description': updatedPath.description,
            'duration_days': updatedPath.durationDays,
            'daily_time_minutes': updatedPath.dailyTimeMinutes,
            'experience_level': updatedPath.experienceLevel.name,
            'learning_style': updatedPath.learningStyle.name,
            'output_goal': updatedPath.outputGoal,
            'include_projects': updatedPath.includeProjects,
            'include_exercises': updatedPath.includeExercises,
            'notes': updatedPath.notes,
            'updated_at': updatedPath.updatedAt?.toIso8601String(),
          })
          .eq('id', updatedPath.id);

      // Update in local list
      final index = _learningPaths.indexWhere((path) => path.id == updatedPath.id);
      if (index != -1) {
        _learningPaths[index] = updatedPath;
      }

      // Update current learning path if it's the same
      if (_currentLearningPath?.id == updatedPath.id) {
        _currentLearningPath = updatedPath;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating learning path: $e');
      _setError('Failed to update learning path: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteLearningPath(String pathId) async {
    try {
      _setLoading(true);
      _clearError();

      // Delete from Supabase (cascade delete will handle related records)
      await _supabase
          .from('learning_paths')
          .delete()
          .eq('id', pathId);

      // Remove from local list
      _learningPaths.removeWhere((path) => path.id == pathId);

      // Clear current learning path if it's the deleted one
      if (_currentLearningPath?.id == pathId) {
        _currentLearningPath = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting learning path: $e');
      _setError('Failed to delete learning path: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearLearningPaths() {
    _learningPaths.clear();
    _currentLearningPath = null;
    notifyListeners();
  }
}

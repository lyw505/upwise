import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';

class ProjectProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<ProjectTemplate> _projectTemplates = [];
  List<UserProject> _userProjects = [];
  List<ProjectRecommendation> _recommendations = [];
  ProjectAnalytics? _analytics;
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ProjectTemplate> get projectTemplates => _projectTemplates;
  List<UserProject> get userProjects => _userProjects;
  List<ProjectRecommendation> get recommendations => _recommendations;
  ProjectAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered getters
  List<ProjectTemplate> getTemplatesByCategory(String category) {
    return _projectTemplates.where((template) => template.category == category).toList();
  }

  List<ProjectTemplate> getTemplatesByDifficulty(String difficulty) {
    return _projectTemplates.where((template) => template.difficultyLevel.toString().split('.').last == difficulty).toList();
  }

  List<UserProject> getProjectsByStatus(ProjectStatus status) {
    return _userProjects.where((project) => project.status == status).toList();
  }

  // Load project templates
  Future<void> loadProjectTemplates() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('project_templates')
          .select()
          .eq('is_active', true)
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false);

      _projectTemplates = (response as List)
          .map((json) => ProjectTemplate.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load project templates: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user projects
  Future<void> loadUserProjects(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('user_projects_with_progress')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _userProjects = (response as List)
          .map((json) => UserProject.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load user projects: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Start a new project from template
  Future<bool> startProject({
    required String userId,
    required String templateId,
    String? learningPathId,
    String? customTitle,
    String? customDescription,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('🚀 Starting project for userId: $userId, templateId: $templateId');

      // Get template details
      final templateResponse = await _supabase
          .from('project_templates')
          .select()
          .eq('id', templateId)
          .single();

      print('📋 Template response: $templateResponse');

      final template = ProjectTemplate.fromJson(templateResponse);
      
      // Create user project
      final projectData = {
        'user_id': userId,
        'template_id': templateId,
        'learning_path_id': learningPathId,
        'title': customTitle ?? template.title,
        'description': customDescription ?? template.description,
        'status': 'not_started',
        'total_steps': (template.projectSteps['steps'] as List).length,
        'estimated_hours': template.estimatedHours,
      };

      print('💾 Project data to insert: $projectData');

      final projectResponse = await _supabase
          .from('user_projects')
          .insert(projectData)
          .select()
          .single();

      print('✅ Project created: $projectResponse');

      final userProject = UserProject.fromJson(projectResponse);

      // Create step completions
      final steps = template.projectSteps['steps'] as List;
      final stepCompletions = steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return {
          'user_project_id': userProject.id,
          'step_number': index + 1,
          'step_title': step['title'],
          'is_completed': false,
        };
      }).toList();

      await _supabase
          .from('project_step_completions')
          .insert(stepCompletions);

      print('📝 Step completions created: ${stepCompletions.length} steps');

      // Reload user projects
      await loadUserProjects(userId);
      
      print('🎉 Project started successfully!');
      return true;
    } catch (e) {
      print('❌ Error starting project: $e');
      _setError('Failed to start project: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update project status
  Future<bool> updateProjectStatus(String projectId, ProjectStatus status) async {
    try {
      _clearError();

      final updateData = {
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == ProjectStatus.inProgress) {
        updateData['started_at'] = DateTime.now().toIso8601String();
      } else if (status == ProjectStatus.completed) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('user_projects')
          .update(updateData)
          .eq('id', projectId);

      // Update local data
      final projectIndex = _userProjects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        _userProjects[projectIndex] = _userProjects[projectIndex].copyWith(
          status: status,
          startedAt: status == ProjectStatus.inProgress ? DateTime.now() : _userProjects[projectIndex].startedAt,
          completedAt: status == ProjectStatus.completed ? DateTime.now() : _userProjects[projectIndex].completedAt,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update project status: $e');
      return false;
    }
  }

  // Complete a project step
  Future<bool> completeProjectStep({
    required String projectId,
    required int stepNumber,
    String? notes,
    int? timeSpentMinutes,
    List<String>? attachments,
  }) async {
    try {
      _clearError();

      final updateData = {
        'is_completed': true,
        'completion_notes': notes,
        'time_spent_minutes': timeSpentMinutes ?? 0,
        'attachments': attachments ?? [],
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('project_step_completions')
          .update(updateData)
          .eq('user_project_id', projectId)
          .eq('step_number', stepNumber);

      // The trigger will automatically update project progress
      // Reload to get updated progress
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await loadUserProjects(userId);
      }

      return true;
    } catch (e) {
      _setError('Failed to complete project step: $e');
      return false;
    }
  }

  // Get project steps with completion status
  Future<List<ProjectStepCompletion>> getProjectSteps(String projectId) async {
    try {
      _clearError();

      final response = await _supabase
          .from('project_step_completions')
          .select()
          .eq('user_project_id', projectId)
          .order('step_number');

      return (response as List)
          .map((json) => ProjectStepCompletion.fromJson(json))
          .toList();
    } catch (e) {
      _setError('Failed to load project steps: $e');
      return [];
    }
  }

  // Load project analytics
  Future<void> loadProjectAnalytics(String userId) async {
    try {
      _clearError();

      final response = await _supabase
          .from('project_analytics')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _analytics = ProjectAnalytics.fromJson(response);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load project analytics: $e');
    }
  }

  // Load project recommendations
  Future<void> loadProjectRecommendations(String userId, {String? learningPathId}) async {
    try {
      _clearError();

      var query = _supabase
          .from('project_builder_recommendations')
          .select()
          .eq('user_id', userId)
          .eq('is_dismissed', false)
          .gt('expires_at', DateTime.now().toIso8601String());

      if (learningPathId != null) {
        query = query.eq('learning_path_id', learningPathId);
      }

      final response = await query.order('created_at', ascending: false);

      _recommendations = (response as List)
          .map((json) => ProjectRecommendation.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load project recommendations: $e');
    }
  }

  // Create project portfolio entry
  Future<bool> createPortfolioEntry({
    required String userId,
    required String projectId,
    required String title,
    String? description,
    String? demoUrl,
    String? githubUrl,
    List<String>? screenshots,
    bool isPublic = false,
  }) async {
    try {
      _clearError();

      final portfolioData = {
        'user_id': userId,
        'user_project_id': projectId,
        'title': title,
        'description': description,
        'demo_url': demoUrl,
        'github_url': githubUrl,
        'screenshots': screenshots ?? [],
        'is_public': isPublic,
      };

      await _supabase
          .from('project_portfolios')
          .insert(portfolioData);

      return true;
    } catch (e) {
      _setError('Failed to create portfolio entry: $e');
      return false;
    }
  }

  // Delete project
  Future<bool> deleteProject(String projectId) async {
    try {
      _clearError();

      await _supabase
          .from('user_projects')
          .delete()
          .eq('id', projectId);

      // Remove from local list
      _userProjects.removeWhere((project) => project.id == projectId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to delete project: $e');
      return false;
    }
  }

  // Search project templates
  List<ProjectTemplate> searchTemplates(String query) {
    if (query.isEmpty) return _projectTemplates;
    
    final lowercaseQuery = query.toLowerCase();
    return _projectTemplates.where((template) {
      return template.title.toLowerCase().contains(lowercaseQuery) ||
             template.description.toLowerCase().contains(lowercaseQuery) ||
             template.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Clear all data
  void clear() {
    _projectTemplates.clear();
    _userProjects.clear();
    _recommendations.clear();
    _analytics = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
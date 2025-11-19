import 'package:equatable/equatable.dart';

// Enums
enum ProjectStatus {
  notStarted,
  inProgress,
  completed,
  paused,
  cancelled,
}

enum ProjectDifficulty {
  beginner,
  intermediate,
  advanced,
}

// Project Template Model
class ProjectTemplate extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final ProjectDifficulty difficultyLevel;
  final int? estimatedHours;
  final List<String> techStack;
  final List<String> prerequisites;
  final List<String> learningObjectives;
  final Map<String, dynamic> projectSteps;
  final List<Map<String, dynamic>> resources;
  final List<String> tags;
  final bool isFeatured;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProjectTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficultyLevel,
    this.estimatedHours,
    required this.techStack,
    required this.prerequisites,
    required this.learningObjectives,
    required this.projectSteps,
    required this.resources,
    required this.tags,
    required this.isFeatured,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProjectTemplate.fromJson(Map<String, dynamic> json) {
    return ProjectTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      difficultyLevel: ProjectDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty_level'],
        orElse: () => ProjectDifficulty.beginner,
      ),
      estimatedHours: json['estimated_hours'] as int?,
      techStack: List<String>.from(json['tech_stack'] ?? []),
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      learningObjectives: List<String>.from(json['learning_objectives'] ?? []),
      projectSteps: Map<String, dynamic>.from(json['project_steps'] ?? {}),
      resources: List<Map<String, dynamic>>.from(json['resources'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty_level': difficultyLevel.toString().split('.').last,
      'estimated_hours': estimatedHours,
      'tech_stack': techStack,
      'prerequisites': prerequisites,
      'learning_objectives': learningObjectives,
      'project_steps': projectSteps,
      'resources': resources,
      'tags': tags,
      'is_featured': isFeatured,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  List<ProjectStep> get steps {
    final stepsData = projectSteps['steps'] as List? ?? [];
    return stepsData.map((step) => ProjectStep.fromJson(step)).toList();
  }

  String get difficultyText {
    switch (difficultyLevel) {
      case ProjectDifficulty.beginner:
        return 'Beginner';
      case ProjectDifficulty.intermediate:
        return 'Intermediate';
      case ProjectDifficulty.advanced:
        return 'Advanced';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        difficultyLevel,
        estimatedHours,
        techStack,
        prerequisites,
        learningObjectives,
        projectSteps,
        resources,
        tags,
        isFeatured,
        isActive,
        createdAt,
        updatedAt,
      ];
}

// Project Step Model
class ProjectStep extends Equatable {
  final int id;
  final String title;
  final String description;
  final int estimatedHours;

  const ProjectStep({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedHours,
  });

  factory ProjectStep.fromJson(Map<String, dynamic> json) {
    return ProjectStep(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      estimatedHours: json['estimatedHours'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'estimatedHours': estimatedHours,
    };
  }

  @override
  List<Object?> get props => [id, title, description, estimatedHours];
}

// User Project Model
class UserProject extends Equatable {
  final String id;
  final String userId;
  final String? templateId;
  final String? learningPathId;
  final String title;
  final String? description;
  final ProjectStatus status;
  final int currentStep;
  final int totalSteps;
  final double progressPercentage;
  final int? estimatedHours;
  final double actualHoursSpent;
  final Map<String, dynamic> projectData;
  final List<String> completedSteps;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // From view
  final String? templateTitle;
  final String? templateCategory;
  final ProjectDifficulty? difficultyLevel;
  final List<String>? techStack;
  final int? completedStepsCount;
  final int? totalTimeSpentMinutes;

  const UserProject({
    required this.id,
    required this.userId,
    this.templateId,
    this.learningPathId,
    required this.title,
    this.description,
    required this.status,
    required this.currentStep,
    required this.totalSteps,
    required this.progressPercentage,
    this.estimatedHours,
    required this.actualHoursSpent,
    required this.projectData,
    required this.completedSteps,
    this.startedAt,
    this.completedAt,
    this.dueDate,
    required this.createdAt,
    this.updatedAt,
    this.templateTitle,
    this.templateCategory,
    this.difficultyLevel,
    this.techStack,
    this.completedStepsCount,
    this.totalTimeSpentMinutes,
  });

  factory UserProject.fromJson(Map<String, dynamic> json) {
    return UserProject(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      templateId: json['template_id'] as String?,
      learningPathId: json['learning_path_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: ProjectStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ProjectStatus.notStarted,
      ),
      currentStep: json['current_step'] as int? ?? 0,
      totalSteps: json['total_steps'] as int,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      estimatedHours: json['estimated_hours'] as int?,
      actualHoursSpent: (json['actual_hours_spent'] as num?)?.toDouble() ?? 0.0,
      projectData: Map<String, dynamic>.from(json['project_data'] ?? {}),
      completedSteps: List<String>.from(json['completed_steps'] ?? []),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      templateTitle: json['template_title'] as String?,
      templateCategory: json['template_category'] as String?,
      difficultyLevel: json['difficulty_level'] != null
          ? ProjectDifficulty.values.firstWhere(
              (e) => e.toString().split('.').last == json['difficulty_level'],
              orElse: () => ProjectDifficulty.beginner,
            )
          : null,
      techStack: json['tech_stack'] != null ? List<String>.from(json['tech_stack']) : null,
      completedStepsCount: json['completed_steps_count'] as int?,
      totalTimeSpentMinutes: json['total_time_spent_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'template_id': templateId,
      'learning_path_id': learningPathId,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'current_step': currentStep,
      'total_steps': totalSteps,
      'progress_percentage': progressPercentage,
      'estimated_hours': estimatedHours,
      'actual_hours_spent': actualHoursSpent,
      'project_data': projectData,
      'completed_steps': completedSteps,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProject copyWith({
    String? id,
    String? userId,
    String? templateId,
    String? learningPathId,
    String? title,
    String? description,
    ProjectStatus? status,
    int? currentStep,
    int? totalSteps,
    double? progressPercentage,
    int? estimatedHours,
    double? actualHoursSpent,
    Map<String, dynamic>? projectData,
    List<String>? completedSteps,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      learningPathId: learningPathId ?? this.learningPathId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHoursSpent: actualHoursSpent ?? this.actualHoursSpent,
      projectData: projectData ?? this.projectData,
      completedSteps: completedSteps ?? this.completedSteps,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      templateTitle: templateTitle,
      templateCategory: templateCategory,
      difficultyLevel: difficultyLevel,
      techStack: techStack,
      completedStepsCount: completedStepsCount,
      totalTimeSpentMinutes: totalTimeSpentMinutes,
    );
  }

  String get statusText {
    switch (status) {
      case ProjectStatus.notStarted:
        return 'Not Started';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.paused:
        return 'Paused';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isCompleted => status == ProjectStatus.completed;
  bool get isInProgress => status == ProjectStatus.inProgress;

  @override
  List<Object?> get props => [
        id,
        userId,
        templateId,
        learningPathId,
        title,
        description,
        status,
        currentStep,
        totalSteps,
        progressPercentage,
        estimatedHours,
        actualHoursSpent,
        projectData,
        completedSteps,
        startedAt,
        completedAt,
        dueDate,
        createdAt,
        updatedAt,
      ];
}

// Project Step Completion Model
class ProjectStepCompletion extends Equatable {
  final String id;
  final String userProjectId;
  final int stepNumber;
  final String stepTitle;
  final bool isCompleted;
  final String? completionNotes;
  final int timeSpentMinutes;
  final List<String> attachments;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProjectStepCompletion({
    required this.id,
    required this.userProjectId,
    required this.stepNumber,
    required this.stepTitle,
    required this.isCompleted,
    this.completionNotes,
    required this.timeSpentMinutes,
    required this.attachments,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProjectStepCompletion.fromJson(Map<String, dynamic> json) {
    return ProjectStepCompletion(
      id: json['id'] as String,
      userProjectId: json['user_project_id'] as String,
      stepNumber: json['step_number'] as int,
      stepTitle: json['step_title'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      completionNotes: json['completion_notes'] as String?,
      timeSpentMinutes: json['time_spent_minutes'] as int? ?? 0,
      attachments: List<String>.from(json['attachments'] ?? []),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_project_id': userProjectId,
      'step_number': stepNumber,
      'step_title': stepTitle,
      'is_completed': isCompleted,
      'completion_notes': completionNotes,
      'time_spent_minutes': timeSpentMinutes,
      'attachments': attachments,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userProjectId,
        stepNumber,
        stepTitle,
        isCompleted,
        completionNotes,
        timeSpentMinutes,
        attachments,
        completedAt,
        createdAt,
        updatedAt,
      ];
}

// Project Recommendation Model
class ProjectRecommendation extends Equatable {
  final String id;
  final String userId;
  final String? learningPathId;
  final List<Map<String, dynamic>> recommendedProjects;
  final String? recommendationReason;
  final bool isViewed;
  final bool isDismissed;
  final DateTime createdAt;
  final DateTime expiresAt;

  const ProjectRecommendation({
    required this.id,
    required this.userId,
    this.learningPathId,
    required this.recommendedProjects,
    this.recommendationReason,
    required this.isViewed,
    required this.isDismissed,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ProjectRecommendation.fromJson(Map<String, dynamic> json) {
    return ProjectRecommendation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      learningPathId: json['learning_path_id'] as String?,
      recommendedProjects: List<Map<String, dynamic>>.from(json['recommended_projects'] ?? []),
      recommendationReason: json['recommendation_reason'] as String?,
      isViewed: json['is_viewed'] as bool? ?? false,
      isDismissed: json['is_dismissed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'learning_path_id': learningPathId,
      'recommended_projects': recommendedProjects,
      'recommendation_reason': recommendationReason,
      'is_viewed': isViewed,
      'is_dismissed': isDismissed,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        learningPathId,
        recommendedProjects,
        recommendationReason,
        isViewed,
        isDismissed,
        createdAt,
        expiresAt,
      ];
}

// Project Analytics Model
class ProjectAnalytics extends Equatable {
  final String userId;
  final int totalProjects;
  final int completedProjects;
  final int activeProjects;
  final double avgProgress;
  final double totalHoursSpent;

  const ProjectAnalytics({
    required this.userId,
    required this.totalProjects,
    required this.completedProjects,
    required this.activeProjects,
    required this.avgProgress,
    required this.totalHoursSpent,
  });

  factory ProjectAnalytics.fromJson(Map<String, dynamic> json) {
    return ProjectAnalytics(
      userId: json['user_id'] as String,
      totalProjects: json['total_projects'] as int? ?? 0,
      completedProjects: json['completed_projects'] as int? ?? 0,
      activeProjects: json['active_projects'] as int? ?? 0,
      avgProgress: (json['avg_progress'] as num?)?.toDouble() ?? 0.0,
      totalHoursSpent: (json['total_hours_spent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_projects': totalProjects,
      'completed_projects': completedProjects,
      'active_projects': activeProjects,
      'avg_progress': avgProgress,
      'total_hours_spent': totalHoursSpent,
    };
  }

  double get completionRate {
    if (totalProjects == 0) return 0.0;
    return (completedProjects / totalProjects) * 100;
  }

  @override
  List<Object?> get props => [
        userId,
        totalProjects,
        completedProjects,
        activeProjects,
        avgProgress,
        totalHoursSpent,
      ];
}
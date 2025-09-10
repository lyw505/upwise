enum LearningPathStatus {
  notStarted,
  inProgress,
  completed,
  paused,
}

enum ExperienceLevel {
  beginner,
  intermediate,
  advanced,
}

enum LearningStyle {
  visual,
  auditory,
  kinesthetic,
  readingWriting,
}

class LearningPathModel {
  final String id;
  final String userId;
  final String topic;
  final String description;
  final int durationDays;
  final int dailyTimeMinutes;
  final ExperienceLevel experienceLevel;
  final LearningStyle learningStyle;
  final String outputGoal;
  final bool includeProjects;
  final bool includeExercises;
  final String? notes;
  final LearningPathStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<DailyLearningTask> dailyTasks;
  final List<ProjectRecommendation> projectRecommendations;

  const LearningPathModel({
    required this.id,
    required this.userId,
    required this.topic,
    required this.description,
    required this.durationDays,
    required this.dailyTimeMinutes,
    required this.experienceLevel,
    required this.learningStyle,
    required this.outputGoal,
    this.includeProjects = false,
    this.includeExercises = false,
    this.notes,
    this.status = LearningPathStatus.notStarted,
    required this.createdAt,
    this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.dailyTasks = const [],
    this.projectRecommendations = const [],
  });

  factory LearningPathModel.fromJson(Map<String, dynamic> json) {
    return LearningPathModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      topic: json['topic'] as String,
      description: json['description'] as String,
      durationDays: json['duration_days'] as int,
      dailyTimeMinutes: json['daily_time_minutes'] as int,
      experienceLevel: ExperienceLevel.values.firstWhere(
        (e) => e.name == json['experience_level'],
        orElse: () => ExperienceLevel.beginner,
      ),
      learningStyle: LearningStyle.values.firstWhere(
        (e) => e.name == json['learning_style'],
        orElse: () => LearningStyle.visual,
      ),
      outputGoal: json['output_goal'] as String,
      includeProjects: json['include_projects'] as bool? ?? false,
      includeExercises: json['include_exercises'] as bool? ?? false,
      notes: json['notes'] as String?,
      status: LearningPathStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LearningPathStatus.notStarted,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at'] as String) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      dailyTasks: (json['daily_learning_tasks'] as List<dynamic>?)
          ?.map((task) => DailyLearningTask.fromJson(task as Map<String, dynamic>))
          .toList() ?? [],
      projectRecommendations: (json['project_recommendations'] as List<dynamic>?)
          ?.map((project) => ProjectRecommendation.fromJson(project as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'topic': topic,
      'description': description,
      'duration_days': durationDays,
      'daily_time_minutes': dailyTimeMinutes,
      'experience_level': experienceLevel.name,
      'learning_style': learningStyle.name,
      'output_goal': outputGoal,
      'include_projects': includeProjects,
      'include_exercises': includeExercises,
      'notes': notes,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'daily_tasks': dailyTasks.map((task) => task.toJson()).toList(),
      'project_recommendations': projectRecommendations.map((project) => project.toJson()).toList(),
    };
  }

  LearningPathModel copyWith({
    String? id,
    String? userId,
    String? topic,
    String? description,
    int? durationDays,
    int? dailyTimeMinutes,
    ExperienceLevel? experienceLevel,
    LearningStyle? learningStyle,
    String? outputGoal,
    bool? includeProjects,
    bool? includeExercises,
    String? notes,
    LearningPathStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<DailyLearningTask>? dailyTasks,
    List<ProjectRecommendation>? projectRecommendations,
  }) {
    return LearningPathModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      dailyTimeMinutes: dailyTimeMinutes ?? this.dailyTimeMinutes,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      learningStyle: learningStyle ?? this.learningStyle,
      outputGoal: outputGoal ?? this.outputGoal,
      includeProjects: includeProjects ?? this.includeProjects,
      includeExercises: includeExercises ?? this.includeExercises,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      projectRecommendations: projectRecommendations ?? this.projectRecommendations,
    );
  }

  // Helper methods
  int get completedTasksCount => dailyTasks.where((task) => task.status == TaskStatus.completed).length;
  
  int get completedOrSkippedTasksCount => dailyTasks.where((task) => 
    task.status == TaskStatus.completed || task.status == TaskStatus.skipped).length;
  
  double get progressPercentage => dailyTasks.isEmpty ? 0.0 : (completedOrSkippedTasksCount / dailyTasks.length) * 100;
  
  bool get isCompleted => status == LearningPathStatus.completed;
  
  bool get isActive => status == LearningPathStatus.inProgress;
  
  DailyLearningTask? get todayTask {
    if (startedAt == null) return null;
    
    final today = DateTime.now();
    final daysSinceStart = today.difference(startedAt!).inDays;
    
    if (daysSinceStart >= 0 && daysSinceStart < dailyTasks.length) {
      return dailyTasks[daysSinceStart];
    }
    
    return null;
  }
}

enum TaskStatus {
  notStarted,
  inProgress,
  completed,
  skipped,
}

class DailyLearningTask {
  final String id;
  final String learningPathId;
  final int dayNumber;
  final String mainTopic;
  final String subTopic;
  final String? materialUrl;
  final String? materialTitle;
  final String? exercise;
  final TaskStatus status;
  final DateTime? completedAt;
  final int? timeSpentMinutes;

  const DailyLearningTask({
    required this.id,
    required this.learningPathId,
    required this.dayNumber,
    required this.mainTopic,
    required this.subTopic,
    this.materialUrl,
    this.materialTitle,
    this.exercise,
    this.status = TaskStatus.notStarted,
    this.completedAt,
    this.timeSpentMinutes,
  });

  factory DailyLearningTask.fromJson(Map<String, dynamic> json) {
    return DailyLearningTask(
      id: json['id'] as String,
      learningPathId: json['learning_path_id'] as String,
      dayNumber: json['day_number'] as int,
      mainTopic: json['main_topic'] as String,
      subTopic: json['sub_topic'] as String,
      materialUrl: json['material_url'] as String?,
      materialTitle: json['material_title'] as String?,
      exercise: json['exercise'] as String?,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.notStarted,
      ),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      timeSpentMinutes: json['time_spent_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'learning_path_id': learningPathId,
      'day_number': dayNumber,
      'main_topic': mainTopic,
      'sub_topic': subTopic,
      'material_url': materialUrl,
      'material_title': materialTitle,
      'exercise': exercise,
      'status': status.name,
      'completed_at': completedAt?.toIso8601String(),
      'time_spent_minutes': timeSpentMinutes,
    };
  }

  DailyLearningTask copyWith({
    String? id,
    String? learningPathId,
    int? dayNumber,
    String? mainTopic,
    String? subTopic,
    String? materialUrl,
    String? materialTitle,
    String? exercise,
    TaskStatus? status,
    DateTime? completedAt,
    int? timeSpentMinutes,
  }) {
    return DailyLearningTask(
      id: id ?? this.id,
      learningPathId: learningPathId ?? this.learningPathId,
      dayNumber: dayNumber ?? this.dayNumber,
      mainTopic: mainTopic ?? this.mainTopic,
      subTopic: subTopic ?? this.subTopic,
      materialUrl: materialUrl ?? this.materialUrl,
      materialTitle: materialTitle ?? this.materialTitle,
      exercise: exercise ?? this.exercise,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
    );
  }
}

class ProjectRecommendation {
  final String id;
  final String learningPathId;
  final String title;
  final String description;
  final String? url;
  final String? difficulty;
  final int? estimatedHours;

  const ProjectRecommendation({
    required this.id,
    required this.learningPathId,
    required this.title,
    required this.description,
    this.url,
    this.difficulty,
    this.estimatedHours,
  });

  factory ProjectRecommendation.fromJson(Map<String, dynamic> json) {
    return ProjectRecommendation(
      id: json['id'] as String,
      learningPathId: json['learning_path_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      url: json['url'] as String?,
      difficulty: json['difficulty'] as String?,
      estimatedHours: json['estimated_hours'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'learning_path_id': learningPathId,
      'title': title,
      'description': description,
      'url': url,
      'difficulty': difficulty,
      'estimated_hours': estimatedHours,
    };
  }

  ProjectRecommendation copyWith({
    String? id,
    String? learningPathId,
    String? title,
    String? description,
    String? url,
    String? difficulty,
    int? estimatedHours,
  }) {
    return ProjectRecommendation(
      id: id ?? this.id,
      learningPathId: learningPathId ?? this.learningPathId,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      difficulty: difficulty ?? this.difficulty,
      estimatedHours: estimatedHours ?? this.estimatedHours,
    );
  }
}

import 'package:equatable/equatable.dart';

/// Model untuk milestone dalam project blueprint
class ProjectMilestone extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<String> tasks;
  final int estimatedDays;
  final bool isCompleted;

  const ProjectMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.tasks,
    required this.estimatedDays,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [id, title, description, tasks, estimatedDays, isCompleted];

  ProjectMilestone copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tasks,
    int? estimatedDays,
    bool? isCompleted,
  }) {
    return ProjectMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tasks: tasks ?? this.tasks,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tasks': tasks,
      'estimatedDays': estimatedDays,
      'isCompleted': isCompleted,
    };
  }

  factory ProjectMilestone.fromJson(Map<String, dynamic> json) {
    return ProjectMilestone(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tasks: List<String>.from(json['tasks'] ?? []),
      estimatedDays: json['estimatedDays'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

/// Model untuk Project Blueprint
class ProjectBlueprint extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String goalStatement;
  final List<String> requiredSkills;
  final List<String> requiredTools;
  final List<ProjectMilestone> milestones;
  final int estimatedDuration; // dalam hari
  final int dailyStudyHours;
  final String difficulty; // beginner, intermediate, advanced
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isStarted;
  final bool isCompleted;

  const ProjectBlueprint({
    required this.id,
    required this.userId,
    required this.title,
    required this.goalStatement,
    required this.requiredSkills,
    required this.requiredTools,
    required this.milestones,
    required this.estimatedDuration,
    required this.dailyStudyHours,
    required this.difficulty,
    required this.category,
    required this.createdAt,
    this.updatedAt,
    this.isStarted = false,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        goalStatement,
        requiredSkills,
        requiredTools,
        milestones,
        estimatedDuration,
        dailyStudyHours,
        difficulty,
        category,
        createdAt,
        updatedAt,
        isStarted,
        isCompleted,
      ];

  // Computed properties
  int get completedMilestones => milestones.where((m) => m.isCompleted).length;
  double get progress => milestones.isEmpty ? 0.0 : completedMilestones / milestones.length;
  String get progressText => '${completedMilestones}/${milestones.length} milestones';

  ProjectBlueprint copyWith({
    String? id,
    String? userId,
    String? title,
    String? goalStatement,
    List<String>? requiredSkills,
    List<String>? requiredTools,
    List<ProjectMilestone>? milestones,
    int? estimatedDuration,
    int? dailyStudyHours,
    String? difficulty,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStarted,
    bool? isCompleted,
  }) {
    return ProjectBlueprint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      goalStatement: goalStatement ?? this.goalStatement,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      requiredTools: requiredTools ?? this.requiredTools,
      milestones: milestones ?? this.milestones,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      dailyStudyHours: dailyStudyHours ?? this.dailyStudyHours,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarted: isStarted ?? this.isStarted,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'goalStatement': goalStatement,
      'requiredSkills': requiredSkills,
      'requiredTools': requiredTools,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'estimatedDuration': estimatedDuration,
      'dailyStudyHours': dailyStudyHours,
      'difficulty': difficulty,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isStarted': isStarted,
      'isCompleted': isCompleted,
    };
  }

  factory ProjectBlueprint.fromJson(Map<String, dynamic> json) {
    return ProjectBlueprint(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      goalStatement: json['goalStatement'] ?? '',
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      requiredTools: List<String>.from(json['requiredTools'] ?? []),
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((m) => ProjectMilestone.fromJson(m))
              .toList() ??
          [],
      estimatedDuration: json['estimatedDuration'] ?? 0,
      dailyStudyHours: json['dailyStudyHours'] ?? 1,
      difficulty: json['difficulty'] ?? 'beginner',
      category: json['category'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isStarted: json['isStarted'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

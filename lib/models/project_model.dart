import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final Color categoryColor;
  final IconData categoryIcon;
  final String difficulty;
  final int estimatedDays;
  final int totalSteps;
  final int completedSteps;
  final double portfolioValue;
  final String status;
  final double progressPercentage;
  final List<ProjectStep> steps;
  final List<String> resources;
  final List<String> technologies;
  final String? completedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
    required this.difficulty,
    required this.estimatedDays,
    required this.totalSteps,
    this.completedSteps = 0,
    required this.portfolioValue,
    this.status = 'Not Started',
    this.progressPercentage = 0.0,
    this.steps = const [],
    this.resources = const [],
    this.technologies = const [],
    this.completedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      categoryColor: _getCategoryColor(json['category'] ?? ''),
      categoryIcon: _getCategoryIcon(json['category'] ?? ''),
      difficulty: json['difficulty'] ?? 'Beginner',
      estimatedDays: json['estimated_days'] ?? 0,
      totalSteps: json['total_steps'] ?? 0,
      completedSteps: json['completed_steps'] ?? 0,
      portfolioValue: (json['portfolio_value'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Not Started',
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((step) => ProjectStep.fromJson(step))
          .toList() ?? [],
      resources: List<String>.from(json['resources'] ?? []),
      technologies: List<String>.from(json['technologies'] ?? []),
      completedDate: json['completed_date'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'estimated_days': estimatedDays,
      'total_steps': totalSteps,
      'completed_steps': completedSteps,
      'portfolio_value': portfolioValue,
      'status': status,
      'progress_percentage': progressPercentage,
      'steps': steps.map((step) => step.toJson()).toList(),
      'resources': resources,
      'technologies': technologies,
      'completed_date': completedDate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    Color? categoryColor,
    IconData? categoryIcon,
    String? difficulty,
    int? estimatedDays,
    int? totalSteps,
    int? completedSteps,
    double? portfolioValue,
    String? status,
    double? progressPercentage,
    List<ProjectStep>? steps,
    List<String>? resources,
    List<String>? technologies,
    String? completedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      difficulty: difficulty ?? this.difficulty,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      portfolioValue: portfolioValue ?? this.portfolioValue,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      steps: steps ?? this.steps,
      resources: resources ?? this.resources,
      technologies: technologies ?? this.technologies,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'web development':
        return AppColors.primary;
      case 'mobile development':
        return AppColors.success;
      case 'data science':
        return const Color(0xFF8B5CF6);
      case 'machine learning':
        return AppColors.warning;
      case 'design':
        return AppColors.error;
      case 'business':
        return AppColors.primaryDark;
      default:
        return AppColors.secondary;
    }
  }

  static IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'web development':
        return Icons.web;
      case 'mobile development':
        return Icons.phone_android;
      case 'data science':
        return Icons.analytics;
      case 'machine learning':
        return Icons.psychology;
      case 'design':
        return Icons.design_services;
      case 'business':
        return Icons.business;
      default:
        return Icons.folder;
    }
  }
}

class ProjectStep {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final int order;
  final List<String> resources;
  final List<String> checklist;
  final String? deliverable;
  final DateTime? completedAt;

  ProjectStep({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.order,
    this.resources = const [],
    this.checklist = const [],
    this.deliverable,
    this.completedAt,
  });

  factory ProjectStep.fromJson(Map<String, dynamic> json) {
    return ProjectStep(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      order: json['order'] ?? 0,
      resources: List<String>.from(json['resources'] ?? []),
      checklist: List<String>.from(json['checklist'] ?? []),
      deliverable: json['deliverable'],
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'order': order,
      'resources': resources,
      'checklist': checklist,
      'deliverable': deliverable,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  ProjectStep copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? order,
    List<String>? resources,
    List<String>? checklist,
    String? deliverable,
    DateTime? completedAt,
  }) {
    return ProjectStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      resources: resources ?? this.resources,
      checklist: checklist ?? this.checklist,
      deliverable: deliverable ?? this.deliverable,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

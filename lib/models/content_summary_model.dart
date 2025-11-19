import 'package:equatable/equatable.dart';

/// Enum for content type
enum ContentType {
  text('text'),
  url('url'),
  file('file');

  const ContentType(this.value);
  final String value;

  static ContentType fromString(String value) {
    return ContentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ContentType.text,
    );
  }
}

/// Enum for difficulty level
enum DifficultyLevel {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const DifficultyLevel(this.value);
  final String value;

  static DifficultyLevel fromString(String value) {
    return DifficultyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => DifficultyLevel.beginner,
    );
  }
}

/// Content Summary Model
class ContentSummaryModel extends Equatable {
  final String id;
  final String userId;
  final String? learningPathId;
  final String title;
  final String originalContent;
  final ContentType contentType;
  final String? contentSource;
  final String summary;
  final List<String> keyPoints;
  final List<String> tags;
  final int? wordCount;
  final int? estimatedReadTime;
  final DifficultyLevel? difficultyLevel;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ContentSummaryModel({
    required this.id,
    required this.userId,
    this.learningPathId,
    required this.title,
    required this.originalContent,
    required this.contentType,
    this.contentSource,
    required this.summary,
    required this.keyPoints,
    required this.tags,
    this.wordCount,
    this.estimatedReadTime,
    this.difficultyLevel,
    this.isFavorite = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON
  factory ContentSummaryModel.fromJson(Map<String, dynamic> json) {
    return ContentSummaryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      learningPathId: json['learning_path_id'],
      title: json['title'] ?? '',
      originalContent: json['original_content'] ?? '',
      contentType: ContentType.fromString(json['content_type'] ?? 'text'),
      contentSource: json['content_source'],
      summary: json['summary'] ?? '',
      keyPoints: _parseStringList(json['key_points']),
      tags: _parseStringList(json['tags']),
      wordCount: json['word_count'],
      estimatedReadTime: json['estimated_read_time'],
      difficultyLevel: json['difficulty_level'] != null
          ? DifficultyLevel.fromString(json['difficulty_level'])
          : null,
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert to JSON for database
  Map<String, dynamic> toJson() {
    final json = {
      'user_id': userId,
      'title': title,
      'original_content': originalContent,
      'content_type': contentType.value,
      'content_source': contentSource,
      'summary': summary,
      'key_points': keyPoints,
      'tags': tags,
      'word_count': wordCount,
      'estimated_read_time': estimatedReadTime,
      'difficulty_level': difficultyLevel?.value,
      'is_favorite': isFavorite,
    };
    
    // Only include learning_path_id if it's not null and not empty
    if (learningPathId != null && learningPathId!.isNotEmpty) {
      json['learning_path_id'] = learningPathId;
    }
    
    // Only include ID if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }


  /// Create copy with modifications
  ContentSummaryModel copyWith({
    String? id,
    String? userId,
    String? learningPathId,
    String? title,
    String? originalContent,
    ContentType? contentType,
    String? contentSource,
    String? summary,
    List<String>? keyPoints,
    List<String>? tags,
    int? wordCount,
    int? estimatedReadTime,
    DifficultyLevel? difficultyLevel,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentSummaryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      learningPathId: learningPathId ?? this.learningPathId,
      title: title ?? this.title,
      originalContent: originalContent ?? this.originalContent,
      contentType: contentType ?? this.contentType,
      contentSource: contentSource ?? this.contentSource,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      tags: tags ?? this.tags,
      wordCount: wordCount ?? this.wordCount,
      estimatedReadTime: estimatedReadTime ?? this.estimatedReadTime,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get summary length type
  String get lengthType {
    final summaryLength = summary.length;
    if (summaryLength < 200) return 'Short';
    if (summaryLength < 500) return 'Medium';
    return 'Long';
  }

  /// Get content type display name
  String get contentTypeDisplay {
    switch (contentType) {
      case ContentType.text:
        return 'Text';
      case ContentType.url:
        return 'Web Article';
      case ContentType.file:
        return 'File';
    }
  }

  /// Get difficulty level display name
  String get difficultyLevelDisplay {
    switch (difficultyLevel) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
      case null:
        return 'Not Set';
    }
  }

  /// Calculate word count from content
  static int calculateWordCount(String content) {
    return content.trim().split(RegExp(r'\s+')).length;
  }

  /// Estimate reading time (average 200 words per minute)
  static int estimateReadingTime(int wordCount) {
    return (wordCount / 200).ceil();
  }

  /// Helper method to parse string list from JSON
  static List<String> _parseStringList(dynamic jsonValue) {
    if (jsonValue == null) return [];
    if (jsonValue is List) {
      return jsonValue.map((item) => item.toString()).toList();
    }
    return [];
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        learningPathId,
        title,
        originalContent,
        contentType,
        contentSource,
        summary,
        keyPoints,
        tags,
        wordCount,
        estimatedReadTime,
        difficultyLevel,
        isFavorite,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'ContentSummaryModel(id: $id, title: $title, contentType: ${contentType.value})';
  }
}

/// Summary Category Model
class SummaryCategoryModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String color;
  final String? icon;
  final DateTime createdAt;

  const SummaryCategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color = '#2563EB',
    this.icon,
    required this.createdAt,
  });

  /// Create from JSON
  factory SummaryCategoryModel.fromJson(Map<String, dynamic> json) {
    return SummaryCategoryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'] ?? '#2563EB',
      icon: json['icon'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }


  /// Create copy with modifications
  SummaryCategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return SummaryCategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        color,
        icon,
        createdAt,
      ];

  @override
  String toString() {
    return 'SummaryCategoryModel(id: $id, name: $name)';
  }
}

/// Summary Request Model (for creating new summaries)
class SummaryRequestModel extends Equatable {
  final String content;
  final ContentType contentType;
  final String? contentSource;
  final String? title;
  final String? learningPathId;
  final List<String> tags;
  final DifficultyLevel? targetDifficulty;
  final int? maxSummaryLength;
  final bool includeKeyPoints;
  final String? customInstructions;

  const SummaryRequestModel({
    required this.content,
    required this.contentType,
    this.contentSource,
    this.title,
    this.learningPathId,
    this.tags = const [],
    this.targetDifficulty,
    this.maxSummaryLength,
    this.includeKeyPoints = true,
    this.customInstructions,
  });

  /// Create copy with modifications
  SummaryRequestModel copyWith({
    String? content,
    ContentType? contentType,
    String? contentSource,
    String? title,
    String? learningPathId,
    List<String>? tags,
    DifficultyLevel? targetDifficulty,
    int? maxSummaryLength,
    bool? includeKeyPoints,
    String? customInstructions,
  }) {
    return SummaryRequestModel(
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      contentSource: contentSource ?? this.contentSource,
      title: title ?? this.title,
      learningPathId: learningPathId ?? this.learningPathId,
      tags: tags ?? this.tags,
      targetDifficulty: targetDifficulty ?? this.targetDifficulty,
      maxSummaryLength: maxSummaryLength ?? this.maxSummaryLength,
      includeKeyPoints: includeKeyPoints ?? this.includeKeyPoints,
      customInstructions: customInstructions ?? this.customInstructions,
    );
  }

  @override
  List<Object?> get props => [
        content,
        contentType,
        contentSource,
        title,
        learningPathId,
        tags,
        targetDifficulty,
        maxSummaryLength,
        includeKeyPoints,
        customInstructions,
      ];
}

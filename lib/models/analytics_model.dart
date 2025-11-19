class AnalyticsData {
  final int totalLearningPaths;
  final int completedPaths;
  final int activePaths;
  final int totalTasksCompleted;
  final int totalStudyTimeMinutes;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> weeklyProgress;
  final Map<String, int> monthlyProgress;
  final StudyHabits studyHabits;

  AnalyticsData({
    required this.totalLearningPaths,
    required this.completedPaths,
    required this.activePaths,
    required this.totalTasksCompleted,
    required this.totalStudyTimeMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyProgress,
    required this.monthlyProgress,
    required this.studyHabits,
  });

  // Calculated properties
  double get totalStudyTimeHours => totalStudyTimeMinutes / 60;
  double get avgStudyTimePerDay => totalStudyTimeMinutes / 60 / 7;
  double get completionRate => totalLearningPaths > 0 
      ? (completedPaths / totalLearningPaths * 100) 
      : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalLearningPaths': totalLearningPaths,
      'completedPaths': completedPaths,
      'activePaths': activePaths,
      'totalTasksCompleted': totalTasksCompleted,
      'totalStudyTimeMinutes': totalStudyTimeMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'weeklyProgress': weeklyProgress,
      'monthlyProgress': monthlyProgress,
      'studyHabits': studyHabits.toJson(),
    };
  }

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      totalLearningPaths: json['totalLearningPaths'] ?? 0,
      completedPaths: json['completedPaths'] ?? 0,
      activePaths: json['activePaths'] ?? 0,
      totalTasksCompleted: json['totalTasksCompleted'] ?? 0,
      totalStudyTimeMinutes: json['totalStudyTimeMinutes'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      weeklyProgress: Map<String, int>.from(json['weeklyProgress'] ?? {}),
      monthlyProgress: Map<String, int>.from(json['monthlyProgress'] ?? {}),
      studyHabits: StudyHabits.fromJson(json['studyHabits'] ?? {}),
    );
  }
}

class StudyHabits {
  final double avgStudyTimePerDay;
  final double completionRate;
  final String mostActiveDay;

  StudyHabits({
    required this.avgStudyTimePerDay,
    required this.completionRate,
    required this.mostActiveDay,
  });

  Map<String, dynamic> toJson() {
    return {
      'avgStudyTimePerDay': avgStudyTimePerDay,
      'completionRate': completionRate,
      'mostActiveDay': mostActiveDay,
    };
  }

  factory StudyHabits.fromJson(Map<String, dynamic> json) {
    return StudyHabits(
      avgStudyTimePerDay: (json['avgStudyTimePerDay'] ?? 0.0).toDouble(),
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      mostActiveDay: json['mostActiveDay'] ?? 'Monday',
    );
  }
}

class LearningPathAnalytics {
  final String id;
  final String topic;
  final String status;
  final double progress;
  final int completedTasks;
  final int totalTasks;
  final int studyTimeMinutes;

  LearningPathAnalytics({
    required this.id,
    required this.topic,
    required this.status,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.studyTimeMinutes,
  });

  double get studyTimeHours => studyTimeMinutes / 60;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'status': status,
      'progress': progress,
      'completedTasks': completedTasks,
      'totalTasks': totalTasks,
      'studyTimeMinutes': studyTimeMinutes,
    };
  }

  factory LearningPathAnalytics.fromJson(Map<String, dynamic> json) {
    return LearningPathAnalytics(
      id: json['id'] ?? '',
      topic: json['topic'] ?? '',
      status: json['status'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      completedTasks: json['completedTasks'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      studyTimeMinutes: json['studyTimeMinutes'] ?? 0,
    );
  }
}

class DetailedAnalytics {
  final List<Map<String, dynamic>> tasks;
  final int totalTasks;
  final int completedTasks;
  final int totalStudyTimeMinutes;
  final DateTime startDate;
  final DateTime endDate;

  DetailedAnalytics({
    required this.tasks,
    required this.totalTasks,
    required this.completedTasks,
    required this.totalStudyTimeMinutes,
    required this.startDate,
    required this.endDate,
  });

  double get completionRate => totalTasks > 0 
      ? (completedTasks / totalTasks * 100) 
      : 0.0;

  double get totalStudyTimeHours => totalStudyTimeMinutes / 60;

  double get avgStudyTimePerDay {
    final daysDiff = endDate.difference(startDate).inDays + 1;
    return daysDiff > 0 ? (totalStudyTimeMinutes / 60 / daysDiff) : 0.0;
  }
}
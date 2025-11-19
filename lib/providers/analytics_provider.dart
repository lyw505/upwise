import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics_model.dart';

class AnalyticsProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  AnalyticsData? _analyticsData;
  bool _isLoading = false;
  String? _error;

  AnalyticsData? get analyticsData => _analyticsData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAnalytics(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load user profile data (streaks)
      final profileResponse = await _supabase
          .from('profiles')
          .select('current_streak, longest_streak, last_active_date')
          .eq('id', userId)
          .single();

      // Load learning paths statistics
      final learningPathsResponse = await _supabase
          .from('learning_paths')
          .select('id, status, created_at, completed_at')
          .eq('user_id', userId);

      // Load daily tasks with completion data
      final tasksResponse = await _supabase
          .from('daily_learning_tasks')
          .select('''
            id, 
            status, 
            completed_at, 
            time_spent_minutes,
            learning_path_id,
            learning_paths!inner(user_id)
          ''')
          .eq('learning_paths.user_id', userId);

      // Calculate analytics from real database data
      _analyticsData = _calculateAnalyticsFromDatabase(
        profileResponse,
        learningPathsResponse,
        tasksResponse,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  AnalyticsData _calculateAnalyticsFromDatabase(
    Map<String, dynamic> profile,
    List<dynamic> learningPaths,
    List<dynamic> tasks,
  ) {
    // Basic statistics
    final totalLearningPaths = learningPaths.length;
    final completedPaths = learningPaths
        .where((path) => path['status'] == 'completed')
        .length;
    final activePaths = learningPaths
        .where((path) => path['status'] == 'inProgress')
        .length;

    // Task statistics
    final completedTasks = tasks
        .where((task) => task['status'] == 'completed')
        .toList();
    final totalTasksCompleted = completedTasks.length;

    // Study time calculation
    final totalStudyTimeMinutes = completedTasks
        .map((task) => task['time_spent_minutes'] ?? 30)
        .fold<int>(0, (sum, time) => sum + (time as int));

    // Streak data
    final currentStreak = profile['current_streak'] ?? 0;
    final longestStreak = profile['longest_streak'] ?? 0;

    // Weekly progress (last 7 days)
    final weeklyProgress = _calculateWeeklyProgress(completedTasks);

    // Monthly progress (last 6 months)
    final monthlyProgress = _calculateMonthlyProgress(completedTasks);

    // Study habits
    final studyHabits = _calculateStudyHabits(
      completedTasks,
      totalStudyTimeMinutes,
      totalLearningPaths,
      completedPaths,
    );

    return AnalyticsData(
      totalLearningPaths: totalLearningPaths,
      completedPaths: completedPaths,
      activePaths: activePaths,
      totalTasksCompleted: totalTasksCompleted,
      totalStudyTimeMinutes: totalStudyTimeMinutes,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      weeklyProgress: weeklyProgress,
      monthlyProgress: monthlyProgress,
      studyHabits: studyHabits,
    );
  }

  Map<String, int> _calculateWeeklyProgress(List<dynamic> completedTasks) {
    final weeklyProgress = <String, int>{};
    final now = DateTime.now();

    // Initialize last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      weeklyProgress[dayName] = 0;
    }

    // Count tasks completed in each day
    for (final task in completedTasks) {
      if (task['completed_at'] != null) {
        final completedDate = DateTime.parse(task['completed_at']);
        final daysDiff = now.difference(completedDate).inDays;
        
        if (daysDiff >= 0 && daysDiff < 7) {
          final dayName = _getDayName(completedDate.weekday);
          weeklyProgress[dayName] = (weeklyProgress[dayName] ?? 0) + 1;
        }
      }
    }

    return weeklyProgress;
  }

  Map<String, int> _calculateMonthlyProgress(List<dynamic> completedTasks) {
    final monthlyProgress = <String, int>{};
    final now = DateTime.now();

    // Initialize last 6 months
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(date.month);
      monthlyProgress[monthName] = 0;
    }

    // Calculate study hours per month
    for (final task in completedTasks) {
      if (task['completed_at'] != null) {
        final completedDate = DateTime.parse(task['completed_at']);
        final monthsDiff = (now.year - completedDate.year) * 12 + 
                          (now.month - completedDate.month);
        
        if (monthsDiff >= 0 && monthsDiff < 6) {
          final monthName = _getMonthName(completedDate.month);
          final studyHours = ((task['time_spent_minutes'] ?? 30) / 60).round();
          final currentValue = monthlyProgress[monthName] ?? 0;
          monthlyProgress[monthName] = (currentValue + studyHours).toInt();
        }
      }
    }

    return monthlyProgress;
  }

  StudyHabits _calculateStudyHabits(
    List<dynamic> completedTasks,
    int totalStudyTimeMinutes,
    int totalLearningPaths,
    int completedPaths,
  ) {
    // Average study time per day (based on last 7 days)
    final avgStudyTimePerDay = totalStudyTimeMinutes > 0 
        ? (totalStudyTimeMinutes / 60 / 7) 
        : 0.0;

    // Completion rate
    final completionRate = totalLearningPaths > 0 
        ? (completedPaths / totalLearningPaths * 100) 
        : 0.0;

    // Most active day (day with most completed tasks)
    final dayTaskCount = <int, int>{};
    for (final task in completedTasks) {
      if (task['completed_at'] != null) {
        final completedDate = DateTime.parse(task['completed_at']);
        final weekday = completedDate.weekday;
        dayTaskCount[weekday] = (dayTaskCount[weekday] ?? 0) + 1;
      }
    }

    final mostActiveDay = dayTaskCount.isNotEmpty
        ? dayTaskCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 1; // Default to Monday

    return StudyHabits(
      avgStudyTimePerDay: avgStudyTimePerDay,
      completionRate: completionRate,
      mostActiveDay: _getDayName(mostActiveDay),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  // Get detailed analytics for specific date range
  Future<Map<String, dynamic>> getDetailedAnalytics(
    String userId, 
    DateTime startDate, 
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('daily_learning_tasks')
          .select('''
            id,
            status,
            completed_at,
            time_spent_minutes,
            day_number,
            learning_path_id,
            learning_paths!inner(user_id, topic, status)
          ''')
          .eq('learning_paths.user_id', userId)
          .gte('completed_at', startDate.toIso8601String())
          .lte('completed_at', endDate.toIso8601String());

      return {
        'tasks': response,
        'totalTasks': response.length,
        'completedTasks': response.where((t) => t['status'] == 'completed').length,
        'totalStudyTime': response
            .where((t) => t['status'] == 'completed')
            .map((t) => t['time_spent_minutes'] ?? 30)
            .fold<int>(0, (sum, time) => sum + (time as int)),
      };
    } catch (e) {
      throw Exception('Failed to load detailed analytics: $e');
    }
  }

  // Get learning path progress analytics
  Future<List<Map<String, dynamic>>> getLearningPathAnalytics(String userId) async {
    try {
      final response = await _supabase
          .from('learning_paths')
          .select('''
            id,
            topic,
            status,
            created_at,
            started_at,
            completed_at,
            duration_days,
            daily_learning_tasks(
              id,
              status,
              completed_at,
              time_spent_minutes
            )
          ''')
          .eq('user_id', userId);

      return response.map<Map<String, dynamic>>((path) {
        final tasks = path['daily_learning_tasks'] as List;
        final completedTasks = tasks.where((t) => t['status'] == 'completed').length;
        final totalTasks = tasks.length;
        final progress = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

        return {
          'id': path['id'],
          'topic': path['topic'],
          'status': path['status'],
          'progress': progress,
          'completedTasks': completedTasks,
          'totalTasks': totalTasks,
          'studyTime': tasks
              .where((t) => t['status'] == 'completed')
              .map((t) => t['time_spent_minutes'] ?? 30)
              .fold<int>(0, (sum, time) => sum + (time as int)),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load learning path analytics: $e');
    }
  }
}
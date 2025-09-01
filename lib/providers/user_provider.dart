import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Analytics data
  int get totalCompletedTasks => _user?.currentStreak ?? 0;
  int get totalHoursLearned => 0; // TODO: Calculate from completed tasks
  int get currentStreak => _user?.currentStreak ?? 0;
  int get longestStreak => _user?.longestStreak ?? 0;

  Future<void> loadUser(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _user = UserModel.fromJson(response);
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUser({
    String? name,
    String? avatarUrl,
  }) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', _user!.id);

      _user = _user!.copyWith(
        name: name ?? _user!.name,
        avatarUrl: avatarUrl ?? _user!.avatarUrl,
        updatedAt: DateTime.now(),
      );

      return true;
    } catch (e) {
      _setError('Failed to update user: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStreak() async {
    if (_user == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActiveDate = _user!.lastActiveDate;
      
      int newCurrentStreak = _user!.currentStreak;
      int newLongestStreak = _user!.longestStreak;

      if (lastActiveDate == null) {
        // First time user is active
        newCurrentStreak = 1;
      } else {
        final lastActiveDay = DateTime(
          lastActiveDate.year,
          lastActiveDate.month,
          lastActiveDate.day,
        );
        
        final daysDifference = today.difference(lastActiveDay).inDays;
        
        if (daysDifference == 0) {
          // Same day, no change to streak
          return;
        } else if (daysDifference == 1) {
          // Consecutive day, increment streak
          newCurrentStreak = _user!.currentStreak + 1;
        } else {
          // Streak broken, reset to 1
          newCurrentStreak = 1;
        }
      }

      // Update longest streak if current streak is higher
      if (newCurrentStreak > newLongestStreak) {
        newLongestStreak = newCurrentStreak;
      }

      final updates = {
        'current_streak': newCurrentStreak,
        'longest_streak': newLongestStreak,
        'last_active_date': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', _user!.id);

      _user = _user!.copyWith(
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        lastActiveDate: now,
        updatedAt: now,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating streak: $e');
      _setError('Failed to update streak: ${e.toString()}');
    }
  }

  Future<void> resetStreak() async {
    if (_user == null) return;

    try {
      final updates = {
        'current_streak': 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', _user!.id);

      _user = _user!.copyWith(
        currentStreak: 0,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting streak: $e');
      _setError('Failed to reset streak: ${e.toString()}');
    }
  }

  bool isStreakActive() {
    if (_user?.lastActiveDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActiveDay = DateTime(
      _user!.lastActiveDate!.year,
      _user!.lastActiveDate!.month,
      _user!.lastActiveDate!.day,
    );

    final daysDifference = today.difference(lastActiveDay).inDays;
    return daysDifference <= 1; // Active today or yesterday
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    final name = _user?.name ?? 'Learner';
    
    if (hour < 12) {
      return 'Good morning, $name!';
    } else if (hour < 17) {
      return 'Good afternoon, $name!';
    } else {
      return 'Good evening, $name!';
    }
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
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

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _setError('User not authenticated');
        return false;
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      // Reload user data to reflect changes
      await loadUser(userId);

      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    }
  }

  void clearError() {
    _clearError();
  }
}

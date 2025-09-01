import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  User? _currentUser;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          _currentUser = session?.user;
          _loadUserProfile();
          break;
        case AuthChangeEvent.signedOut:
          _currentUser = null;
          _userProfile = null;
          break;
        case AuthChangeEvent.userUpdated:
          _currentUser = session?.user;
          _loadUserProfile();
          break;
        default:
          break;
      }
      notifyListeners();
    });

    // Check if user is already signed in
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _currentUser = session.user;
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .single();

      _userProfile = UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // If profile doesn't exist, create one
      await _createUserProfile();
    }
    notifyListeners();
  }

  Future<void> _createUserProfile() async {
    if (_currentUser == null) return;

    try {
      final profileData = {
        'id': _currentUser!.id,
        'email': _currentUser!.email!,
        'name': _currentUser!.userMetadata?['name'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'current_streak': 0,
        'longest_streak': 0,
      };

      await _supabase.from('profiles').insert(profileData);
      
      _userProfile = UserModel.fromJson(profileData);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        _currentUser = response.user;
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Failed to create account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Failed to sign in: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _supabase.auth.signOut();
      _currentUser = null;
      _userProfile = null;
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      _setError('Failed to send reset email: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    if (_currentUser == null || _userProfile == null) return false;

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
          .eq('id', _currentUser!.id);

      _userProfile = _userProfile!.copyWith(
        name: name ?? _userProfile!.name,
        avatarUrl: avatarUrl ?? _userProfile!.avatarUrl,
        updatedAt: DateTime.now(),
      );

      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStreak(int currentStreak, int longestStreak) async {
    if (_currentUser == null || _userProfile == null) return;

    try {
      final updates = {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_active_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', _currentUser!.id);

      _userProfile = _userProfile!.copyWith(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastActiveDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
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

  void clearError() {
    _clearError();
  }
}

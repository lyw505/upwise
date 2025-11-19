import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/content_summary_model.dart';
import '../services/summarizer_service.dart';

class SummarizerProvider with ChangeNotifier {
  final SummarizerService _summarizerService = SummarizerService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // State variables
  List<ContentSummaryModel> _summaries = [];
  List<SummaryCategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;
  ContentSummaryModel? _currentSummary;

  // Getters
  List<ContentSummaryModel> get summaries => _summaries;
  List<SummaryCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  ContentSummaryModel? get currentSummary => _currentSummary;

  // Filtered getters
  List<ContentSummaryModel> get favoriteSummaries =>
      _summaries.where((summary) => summary.isFavorite).toList();

  List<ContentSummaryModel> get recentSummaries {
    final sorted = List<ContentSummaryModel>.from(_summaries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(10).toList();
  }

  /// Load all summaries from Supabase database
  Future<void> loadSummaries() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      developer.log('Loading summaries from Supabase database', name: 'SummarizerProvider');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Try to load from view first, fallback to table if view doesn't exist
      List<dynamic> response;
      try {
        response = await _supabase
            .from('summaries_with_categories')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      } catch (e) {
        developer.log('View not available, using table directly: $e', name: 'SummarizerProvider');
        // Fallback to direct table query
        response = await _supabase
            .from('content_summaries')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      }

      _summaries = response
          .map((json) => ContentSummaryModel.fromJson(json))
          .toList();

      developer.log('Loaded ${_summaries.length} summaries from database', name: 'SummarizerProvider');
      notifyListeners();

    } catch (e) {
      developer.log('Error loading summaries: $e', name: 'SummarizerProvider');
      _setError('Failed to load summaries: $e');
      _summaries = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Load categories from Supabase database
  Future<void> loadCategories() async {
    try {
      developer.log('Loading categories from Supabase database', name: 'SummarizerProvider');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('summary_categories')
          .select()
          .eq('user_id', userId)
          .order('name');

      _categories = response
          .map((json) => SummaryCategoryModel.fromJson(json))
          .toList();

      notifyListeners();

    } catch (e) {
      developer.log('Error loading categories: $e', name: 'SummarizerProvider');
      _setError('Failed to load categories: $e');
      _categories = [];
    }
  }

  /// Generate new summary using AI
  Future<ContentSummaryModel?> generateSummary({
    required SummaryRequestModel request,
    bool autoSave = true,
  }) async {
    if (_isGenerating) return null;

    _setGenerating(true);
    _clearError();

    try {
      developer.log('Starting summary generation for content type: ${request.contentType.value}', name: 'SummarizerProvider');
      developer.log('Content length: ${request.content.length} characters', name: 'SummarizerProvider');
      
      // Check authentication first
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated. Please login first.');
      }
      developer.log('User authenticated: $userId', name: 'SummarizerProvider');

      // Generate summary using AI service
      developer.log('Calling AI service for summary generation...', name: 'SummarizerProvider');
      final summaryData = await _summarizerService.generateSummary(request: request);
      
      if (summaryData == null) {
        throw Exception('AI service returned null. Check API configuration.');
      }
      
      developer.log('AI service returned data: ${summaryData.keys}', name: 'SummarizerProvider');

      // Calculate word count and reading time
      final wordCount = ContentSummaryModel.calculateWordCount(request.content);
      final readingTime = ContentSummaryModel.estimateReadingTime(wordCount);

      // Create summary model compatible with database schema
      developer.log('Creating summary model...', name: 'SummarizerProvider');
      final summary = createCompatibleSummary(
        userId: userId,
        title: summaryData['title'] ?? 'Untitled Summary',
        originalContent: request.content,
        contentType: request.contentType,
        contentSource: request.contentSource,
        summary: summaryData['summary'] ?? '',
        keyPoints: List<String>.from(summaryData['key_points'] ?? []),
        tags: List<String>.from(summaryData['tags'] ?? []),
        wordCount: wordCount,
        estimatedReadTime: readingTime,
        difficultyLevel: DifficultyLevel.fromString(summaryData['difficulty_level'] ?? 'intermediate'),
        learningPathId: request.learningPathId, // This will be ignored in createCompatibleSummary
      );

      // Save to database only if autoSave is true
      if (autoSave) {
        final savedSummary = await _saveSummaryToDatabase(summary);
        if (savedSummary != null) {
          _summaries.insert(0, savedSummary);
          _currentSummary = savedSummary;
          developer.log('Summary generated and saved to database', name: 'SummarizerProvider');
          notifyListeners();
          return savedSummary;
        }
        return null;
      } else {
        // Just return the summary without saving
        _currentSummary = summary;
        developer.log('Summary generated (not auto-saved)', name: 'SummarizerProvider');
        return summary;
      }

    } catch (e) {
      developer.log('Error generating summary: $e', name: 'SummarizerProvider');
      _setError('Failed to generate summary: $e');
      return null;
    } finally {
      _setGenerating(false);
    }
  }

  /// Save summary to Supabase database
  Future<ContentSummaryModel?> _saveSummaryToDatabase(ContentSummaryModel summary) async {
    try {
      final summaryJson = summary.toJson();
      summaryJson.remove('id'); // Let database generate ID
      
      developer.log('Attempting to save summary to database...', name: 'SummarizerProvider');
      developer.log('Summary JSON keys: ${summaryJson.keys.toList()}', name: 'SummarizerProvider');
      
      final response = await _supabase
          .from('content_summaries')
          .insert(summaryJson)
          .select()
          .single();
      
      final savedSummary = ContentSummaryModel.fromJson(response);
      developer.log('Summary saved to database successfully', name: 'SummarizerProvider');
      return savedSummary;

    } catch (e) {
      developer.log('Error saving summary to database: $e', name: 'SummarizerProvider');
      
      // Try to save without learning_path_id if that's the issue
      if (e.toString().contains('learning_path_id')) {
        try {
          developer.log('Retrying without learning_path_id...', name: 'SummarizerProvider');
          final summaryJsonRetry = summary.toJson();
          summaryJsonRetry.remove('id');
          summaryJsonRetry.remove('learning_path_id'); // Remove problematic field
          
          final response = await _supabase
              .from('content_summaries')
              .insert(summaryJsonRetry)
              .select()
              .single();
          
          final savedSummary = ContentSummaryModel.fromJson(response);
          developer.log('Summary saved to database (without learning_path_id)', name: 'SummarizerProvider');
          return savedSummary;
          
        } catch (retryError) {
          developer.log('Retry also failed: $retryError', name: 'SummarizerProvider');
          _setError('Failed to save summary: $retryError');
          return null;
        }
      } else {
        _setError('Failed to save summary: $e');
        return null;
      }
    }
  }

  /// Update existing summary in database
  Future<bool> updateSummary(ContentSummaryModel summary) async {
    try {
      final updatedSummary = summary.copyWith(updatedAt: DateTime.now());
      
      await _supabase
          .from('content_summaries')
          .update(updatedSummary.toJson())
          .eq('id', summary.id);
      
      // Update local list
      final index = _summaries.indexWhere((s) => s.id == summary.id);
      if (index != -1) {
        _summaries[index] = updatedSummary;
        notifyListeners();
      }
      
      developer.log('Summary updated successfully in database', name: 'SummarizerProvider');
      return true;

    } catch (e) {
      developer.log('Error updating summary: $e', name: 'SummarizerProvider');
      _setError('Failed to update summary: $e');
      return false;
    }
  }

  /// Delete summary from database
  Future<bool> deleteSummary(String summaryId) async {
    try {
      await _supabase
          .from('content_summaries')
          .delete()
          .eq('id', summaryId);
      
      _summaries.removeWhere((s) => s.id == summaryId);
      
      if (_currentSummary?.id == summaryId) {
        _currentSummary = null;
      }

      notifyListeners();
      developer.log('Summary deleted successfully from database', name: 'SummarizerProvider');
      return true;

    } catch (e) {
      developer.log('Error deleting summary: $e', name: 'SummarizerProvider');
      _setError('Failed to delete summary: $e');
      return false;
    }
  }

  /// Add new summary to database
  Future<bool> addSummary(ContentSummaryModel summary) async {
    try {
      final savedSummary = await _saveSummaryToDatabase(summary);
      if (savedSummary != null) {
        _summaries.insert(0, savedSummary);
        notifyListeners();
        developer.log('Summary added successfully to database', name: 'SummarizerProvider');
        return true;
      }
      return false;

    } catch (e) {
      developer.log('Error adding summary: $e', name: 'SummarizerProvider');
      _setError('Failed to add summary: $e');
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String summaryId) async {
    try {
      // Get current state from database
      final response = await _supabase
          .from('content_summaries')
          .select('is_favorite')
          .eq('id', summaryId)
          .single();
      
      final currentFavorite = response['is_favorite'] ?? false;
      
      // Update in database
      await _supabase
          .from('content_summaries')
          .update({'is_favorite': !currentFavorite})
          .eq('id', summaryId);
      
      // Update local list
      final index = _summaries.indexWhere((s) => s.id == summaryId);
      if (index != -1) {
        _summaries[index] = _summaries[index].copyWith(isFavorite: !currentFavorite);
        notifyListeners();
      }
      
      return true;

    } catch (e) {
      developer.log('Error toggling favorite: $e', name: 'SummarizerProvider');
      _setError('Failed to toggle favorite: $e');
      return false;
    }
  }

  /// Search summaries using database full-text search
  Future<List<ContentSummaryModel>> searchSummaries(String query) async {
    if (query.isEmpty) return _summaries;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('content_summaries')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,summary.ilike.%$query%')
          .order('created_at', ascending: false);

      return response
          .map((json) => ContentSummaryModel.fromJson(json))
          .toList();

    } catch (e) {
      developer.log('Error searching summaries: $e', name: 'SummarizerProvider');
      // Fallback to local search
      final lowercaseQuery = query.toLowerCase();
      return _summaries.where((summary) {
        return summary.title.toLowerCase().contains(lowercaseQuery) ||
               summary.summary.toLowerCase().contains(lowercaseQuery) ||
               summary.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    }
  }

  /// Filter summaries by content type
  List<ContentSummaryModel> filterByContentType(ContentType contentType) {
    return _summaries.where((s) => s.contentType == contentType).toList();
  }

  /// Filter summaries by learning path
  List<ContentSummaryModel> filterByLearningPath(String learningPathId) {
    return _summaries.where((s) => s.learningPathId == learningPathId).toList();
  }

  /// Get summaries by tag
  List<ContentSummaryModel> getSummariesByTag(String tag) {
    return _summaries.where((s) => s.tags.contains(tag)).toList();
  }

  /// Get all unique tags
  List<String> getAllTags() {
    final allTags = <String>{};
    for (final summary in _summaries) {
      allTags.addAll(summary.tags);
    }
    return allTags.toList()..sort();
  }

  /// Create new category in database
  Future<bool> createCategory({
    required String name,
    String? description,
    String color = '#2563EB',
    String? icon,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('summary_categories')
          .insert({
            'user_id': userId,
            'name': name,
            'description': description,
            'color': color,
            'icon': icon,
          })
          .select()
          .single();

      final category = SummaryCategoryModel.fromJson(response);
      _categories.add(category);
      _categories.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
      developer.log('Category created successfully in database', name: 'SummarizerProvider');
      return true;

    } catch (e) {
      developer.log('Error creating category: $e', name: 'SummarizerProvider');
      _setError('Failed to create category: $e');
      return false;
    }
  }

  /// Extract key points from content
  Future<List<String>> extractKeyPoints(String content) async {
    try {
      return await _summarizerService.extractKeyPoints(content: content);
    } catch (e) {
      developer.log('Error extracting key points: $e', name: 'SummarizerProvider');
      return [];
    }
  }

  /// Suggest tags for content
  Future<List<String>> suggestTags(String content) async {
    try {
      return await _summarizerService.suggestTags(content: content);
    } catch (e) {
      developer.log('Error suggesting tags: $e', name: 'SummarizerProvider');
      return [];
    }
  }

  /// Set current summary
  void setCurrentSummary(ContentSummaryModel? summary) {
    _currentSummary = summary;
    notifyListeners();
  }

  /// Clear current summary
  void clearCurrentSummary() {
    _currentSummary = null;
    notifyListeners();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final totalSummaries = _summaries.length;
    final favoritesCount = favoriteSummaries.length;
    final totalWordCount = _summaries.fold<int>(
      0, 
      (sum, summary) => sum + (summary.wordCount ?? 0),
    );
    final avgReadTime = _summaries.isEmpty 
        ? 0 
        : _summaries.fold<int>(
            0, 
            (sum, summary) => sum + (summary.estimatedReadTime ?? 0),
          ) / _summaries.length;

    final typeDistribution = <ContentType, int>{};
    for (final summary in _summaries) {
      typeDistribution[summary.contentType] = 
          (typeDistribution[summary.contentType] ?? 0) + 1;
    }

    return {
      'totalSummaries': totalSummaries,
      'favoritesCount': favoritesCount,
      'totalWordCount': totalWordCount,
      'averageReadTime': avgReadTime.round(),
      'typeDistribution': typeDistribution,
    };
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setGenerating(bool generating) {
    _isGenerating = generating;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Delete category from database
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _supabase
          .from('summary_categories')
          .delete()
          .eq('id', categoryId);
      
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
      
      developer.log('Category deleted successfully from database', name: 'SummarizerProvider');
      return true;

    } catch (e) {
      developer.log('Error deleting category: $e', name: 'SummarizerProvider');
      _setError('Failed to delete category: $e');
      return false;
    }
  }

  /// Assign summary to category
  Future<bool> assignSummaryToCategory(String summaryId, String categoryId) async {
    try {
      await _supabase
          .from('summary_category_relations')
          .insert({
            'summary_id': summaryId,
            'category_id': categoryId,
          });
      
      developer.log('Summary assigned to category successfully', name: 'SummarizerProvider');
      return true;

    } catch (e) {
      developer.log('Error assigning summary to category: $e', name: 'SummarizerProvider');
      _setError('Failed to assign summary to category: $e');
      return false;
    }
  }

  /// Remove summary from category
  Future<bool> removeSummaryFromCategory(String summaryId, String categoryId) async {
    try {
      await _supabase
          .from('summary_category_relations')
          .delete()
          .eq('summary_id', summaryId)
          .eq('category_id', categoryId);
      
      developer.log('Summary removed from category successfully', name: 'SummarizerProvider');
      return true;

    } catch (e) {
      developer.log('Error removing summary from category: $e', name: 'SummarizerProvider');
      _setError('Failed to remove summary from category: $e');
      return false;
    }
  }

  /// Get summaries by category
  Future<List<ContentSummaryModel>> getSummariesByCategory(String categoryId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('content_summaries')
          .select('''
            *,
            summary_category_relations!inner(category_id)
          ''')
          .eq('user_id', userId)
          .eq('summary_category_relations.category_id', categoryId)
          .order('created_at', ascending: false);

      return response
          .map((json) => ContentSummaryModel.fromJson(json))
          .toList();

    } catch (e) {
      developer.log('Error getting summaries by category: $e', name: 'SummarizerProvider');
      return [];
    }
  }

  /// Get user statistics from database
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('content_summaries')
          .select()
          .eq('user_id', userId);

      final totalSummaries = response.length;
      final favoritesCount = response.where((s) => s['is_favorite'] == true).length;
      final totalWordCount = response.fold<int>(
        0, 
        (sum, summary) => sum + ((summary['word_count'] ?? 0) as int),
      );
      final avgReadTime = totalSummaries > 0 
          ? response.fold<int>(
              0, 
              (sum, summary) => sum + ((summary['estimated_read_time'] ?? 0) as int),
            ) / totalSummaries
          : 0;

      final typeDistribution = <String, int>{};
      for (final summary in response) {
        final type = summary['content_type'] ?? 'text';
        typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
      }

      return {
        'totalSummaries': totalSummaries,
        'favoritesCount': favoritesCount,
        'totalWordCount': totalWordCount,
        'averageReadTime': avgReadTime.round(),
        'typeDistribution': typeDistribution,
        'thisWeek': response.where((s) {
          final created = DateTime.parse(s['created_at']);
          return DateTime.now().difference(created).inDays <= 7;
        }).length,
        'thisMonth': response.where((s) {
          final created = DateTime.parse(s['created_at']);
          return DateTime.now().difference(created).inDays <= 30;
        }).length,
      };

    } catch (e) {
      developer.log('Error getting database statistics: $e', name: 'SummarizerProvider');
      return getStatistics(); // Fallback to local statistics
    }
  }

  /// Initialize default categories for new user
  Future<void> initializeDefaultCategories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Check if user already has categories
      final existingCategories = await _supabase
          .from('summary_categories')
          .select('id')
          .eq('user_id', userId);

      if (existingCategories.isNotEmpty) return; // User already has categories

      // Create default categories
      final defaultCategories = [
        {'name': 'General', 'color': '#6B7280', 'icon': 'folder'},
        {'name': 'Work', 'color': '#3B82F6', 'icon': 'briefcase'},
        {'name': 'Study', 'color': '#10B981', 'icon': 'book'},
        {'name': 'Personal', 'color': '#F59E0B', 'icon': 'user'},
      ];

      for (final category in defaultCategories) {
        await _supabase
            .from('summary_categories')
            .insert({
              'user_id': userId,
              'name': category['name'],
              'color': category['color'],
              'icon': category['icon'],
            });
      }

      // Reload categories
      await loadCategories();
      
      developer.log('Default categories initialized', name: 'SummarizerProvider');

    } catch (e) {
      developer.log('Error initializing default categories: $e', name: 'SummarizerProvider');
    }
  }

  /// Check database schema compatibility
  Future<bool> checkDatabaseSchema() async {
    try {
      // Try to query with learning_path_id to see if column exists
      await _supabase
          .from('content_summaries')
          .select('learning_path_id')
          .limit(1);
      
      developer.log('Database schema is compatible', name: 'SummarizerProvider');
      return true;
    } catch (e) {
      developer.log('Database schema issue detected: $e', name: 'SummarizerProvider');
      return false;
    }
  }

  /// Create a summary model compatible with current database schema
  ContentSummaryModel createCompatibleSummary({
    required String userId,
    required String title,
    required String originalContent,
    required ContentType contentType,
    String? contentSource,
    required String summary,
    required List<String> keyPoints,
    required List<String> tags,
    int? wordCount,
    int? estimatedReadTime,
    DifficultyLevel? difficultyLevel,
    String? learningPathId,
  }) {
    return ContentSummaryModel(
      id: '', // Will be generated by database
      userId: userId,
      learningPathId: null, // Always null to avoid schema issues
      title: title,
      originalContent: originalContent,
      contentType: contentType,
      contentSource: contentSource,
      summary: summary,
      keyPoints: keyPoints,
      tags: tags,
      wordCount: wordCount,
      estimatedReadTime: estimatedReadTime,
      difficultyLevel: difficultyLevel,
      createdAt: DateTime.now(),
    );
  }

  /// Reset provider state
  void reset() {
    _summaries.clear();
    _categories.clear();
    _currentSummary = null;
    _isLoading = false;
    _isGenerating = false;
    _error = null;
    notifyListeners();
  }
}

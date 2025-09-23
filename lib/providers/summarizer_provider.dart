import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_summary_model.dart';
import '../services/summarizer_service.dart';

class SummarizerProvider with ChangeNotifier {
  final SummarizerService _summarizerService = SummarizerService();
  static const String _summariesKey = 'upwise_summaries';
  static const String _categoriesKey = 'upwise_categories';

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

  /// Load all summaries from local storage
  Future<void> loadSummaries() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      developer.log('Loading summaries from local storage', name: 'SummarizerProvider');

      final prefs = await SharedPreferences.getInstance();
      final summariesJson = prefs.getString(_summariesKey);
      
      if (summariesJson != null) {
        final List<dynamic> summariesList = json.decode(summariesJson);
        _summaries = summariesList
            .map((json) => ContentSummaryModel.fromJson(json))
            .toList();
        
        // Sort by created date, newest first
        _summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        // Add dummy data if no summaries exist
        _summaries = _createDummySummaries();
        // Save dummy data to storage
        await _saveSummariesToStorage();
      }

      developer.log('Loaded ${_summaries.length} summaries from local storage', name: 'SummarizerProvider');
      notifyListeners();

    } catch (e) {
      developer.log('Error loading summaries: $e', name: 'SummarizerProvider');
      _setError('Failed to load summaries: $e');
      _summaries = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Load categories from local storage
  Future<void> loadCategories() async {
    try {
      developer.log('Loading categories from local storage', name: 'SummarizerProvider');

      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey);
      
      if (categoriesJson != null) {
        final List<dynamic> categoriesList = json.decode(categoriesJson);
        _categories = categoriesList
            .map((json) => SummaryCategoryModel.fromJson(json))
            .toList();
        
        // Sort by name
        _categories.sort((a, b) => a.name.compareTo(b.name));
      } else {
        _categories = [];
      }

      notifyListeners();

    } catch (e) {
      developer.log('Error loading categories: $e', name: 'SummarizerProvider');
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
      developer.log('Generating summary for content type: ${request.contentType.value}', name: 'SummarizerProvider');

      // Generate summary using AI service
      final summaryData = await _summarizerService.generateSummary(request: request);
      
      if (summaryData == null) {
        throw Exception('Failed to generate summary');
      }

      // Calculate word count and reading time
      final wordCount = ContentSummaryModel.calculateWordCount(request.content);
      final readingTime = ContentSummaryModel.estimateReadingTime(wordCount);

      // Create summary model with unique ID
      final summary = ContentSummaryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'local_user', // Frontend-only user
        learningPathId: request.learningPathId,
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
        createdAt: DateTime.now(),
      );

      // Save to local storage only if autoSave is true
      if (autoSave) {
        final savedSummary = await _saveSummaryToLocal(summary);
        if (savedSummary != null) {
          _summaries.insert(0, savedSummary);
          _currentSummary = savedSummary;
          developer.log('Summary generated and saved to local storage', name: 'SummarizerProvider');
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

  /// Save summary to local storage
  Future<ContentSummaryModel?> _saveSummaryToLocal(ContentSummaryModel summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Add new summary to existing list
      _summaries.insert(0, summary);
      
      // Convert to JSON and save
      final summariesJson = json.encode(
        _summaries.map((s) => s.toJson()).toList()
      );
      
      await prefs.setString(_summariesKey, summariesJson);
      
      developer.log('Summary saved to local storage', name: 'SummarizerProvider');
      return summary;

    } catch (e) {
      developer.log('Error saving summary to local storage: $e', name: 'SummarizerProvider');
      return null;
    }
  }

  /// Update existing summary in local storage
  Future<bool> updateSummary(ContentSummaryModel summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update local list
      final index = _summaries.indexWhere((s) => s.id == summary.id);
      if (index != -1) {
        _summaries[index] = summary.copyWith(updatedAt: DateTime.now());
        
        // Save updated list to local storage
        final summariesJson = json.encode(
          _summaries.map((s) => s.toJson()).toList()
        );
        await prefs.setString(_summariesKey, summariesJson);
        
        notifyListeners();
        developer.log('Summary updated successfully in local storage', name: 'SummarizerProvider');
        return true;
      }

      return false;

    } catch (e) {
      developer.log('Error updating summary: $e', name: 'SummarizerProvider');
      _setError('Failed to update summary: $e');
      return false;
    }
  }

  /// Delete summary from local storage
  Future<bool> deleteSummary(String summaryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _summaries.removeWhere((s) => s.id == summaryId);
      
      if (_currentSummary?.id == summaryId) {
        _currentSummary = null;
      }

      // Save updated list to local storage
      final summariesJson = json.encode(
        _summaries.map((s) => s.toJson()).toList()
      );
      await prefs.setString(_summariesKey, summariesJson);

      notifyListeners();
      developer.log('Summary deleted successfully from local storage', name: 'SummarizerProvider');
      return true;

    } catch (e) {
      developer.log('Error deleting summary: $e', name: 'SummarizerProvider');
      _setError('Failed to delete summary: $e');
      return false;
    }
  }

  /// Add new summary to local storage
  Future<bool> addSummary(ContentSummaryModel summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _summaries.insert(0, summary); // Add to beginning of list
      
      // Save updated list to local storage
      final summariesJson = json.encode(
        _summaries.map((s) => s.toJson()).toList()
      );
      await prefs.setString(_summariesKey, summariesJson);
      
      notifyListeners();
      developer.log('Summary added successfully to local storage', name: 'SummarizerProvider');
      return true;

    } catch (e) {
      developer.log('Error adding summary: $e', name: 'SummarizerProvider');
      _setError('Failed to add summary: $e');
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String summaryId) async {
    try {
      final summary = _summaries.firstWhere((s) => s.id == summaryId);
      final updatedSummary = summary.copyWith(isFavorite: !summary.isFavorite);
      
      return await updateSummary(updatedSummary);

    } catch (e) {
      developer.log('Error toggling favorite: $e', name: 'SummarizerProvider');
      return false;
    }
  }

  /// Search summaries
  List<ContentSummaryModel> searchSummaries(String query) {
    if (query.isEmpty) return _summaries;

    final lowercaseQuery = query.toLowerCase();
    return _summaries.where((summary) {
      return summary.title.toLowerCase().contains(lowercaseQuery) ||
             summary.summary.toLowerCase().contains(lowercaseQuery) ||
             summary.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
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

  /// Create new category in local storage
  Future<bool> createCategory({
    required String name,
    String? description,
    String color = '#2563EB',
    String? icon,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final category = SummaryCategoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'local_user',
        name: name,
        description: description,
        color: color,
        icon: icon,
        createdAt: DateTime.now(),
      );

      _categories.add(category);
      _categories.sort((a, b) => a.name.compareTo(b.name));

      // Save to local storage
      final categoriesJson = json.encode(
        _categories.map((c) => c.toJson()).toList()
      );
      await prefs.setString(_categoriesKey, categoriesJson);

      notifyListeners();
      developer.log('Category created successfully in local storage', name: 'SummarizerProvider');
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

  /// Create dummy summaries for demonstration
  List<ContentSummaryModel> _createDummySummaries() {
    final now = DateTime.now();
    return [
      ContentSummaryModel(
        id: 'dummy_1',
        userId: 'dummy_user',
        title: 'Flutter State Management Guide',
        originalContent: 'Flutter offers several state management solutions including Provider, Bloc, Riverpod, and GetX. Each has its own strengths and use cases...',
        summary: 'A comprehensive overview of state management patterns in Flutter, covering Provider, Bloc, Riverpod, and GetX. This guide explains when to use each approach and provides practical examples for building scalable Flutter applications.',
        contentType: ContentType.url,
        contentSource: 'https://flutter.dev/docs/development/data-and-backend/state-mgmt',
        tags: ['flutter', 'state-management', 'provider', 'bloc'],
        keyPoints: [
          'Provider is great for simple state management',
          'Bloc provides predictable state management',
          'Riverpod offers compile-time safety',
          'Choose based on app complexity'
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        isFavorite: true,
        wordCount: 1250,
        estimatedReadTime: 5,
        difficultyLevel: DifficultyLevel.intermediate,
      ),
      ContentSummaryModel(
        id: 'dummy_2',
        userId: 'dummy_user',
        title: 'JavaScript ES6+ Features Summary',
        originalContent: 'ES6 introduced many powerful features including arrow functions, destructuring, async/await, modules, and more...',
        summary: 'Modern JavaScript features introduced in ES6 and beyond, including arrow functions, destructuring, async/await, modules, and more. Essential knowledge for modern web development.',
        contentType: ContentType.text,
        tags: ['javascript', 'es6', 'modern-js', 'web-development'],
        keyPoints: [
          'Arrow functions provide cleaner syntax',
          'Destructuring simplifies data extraction',
          'Async/await makes promises easier',
          'Modules enable better code organization'
        ],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        isFavorite: false,
        wordCount: 890,
        estimatedReadTime: 4,
        difficultyLevel: DifficultyLevel.intermediate,
      ),
      ContentSummaryModel(
        id: 'dummy_3',
        userId: 'dummy_user',
        title: 'React Hooks Best Practices',
        originalContent: 'React Hooks revolutionized how we write React components by allowing us to use state and lifecycle methods in functional components...',
        summary: 'Best practices for using React Hooks effectively, including useState, useEffect, useContext, and custom hooks. Learn how to avoid common pitfalls and write cleaner React code.',
        contentType: ContentType.url,
        contentSource: 'https://reactjs.org/docs/hooks-intro.html',
        tags: ['react', 'hooks', 'best-practices', 'frontend'],
        keyPoints: [
          'Use useState for local component state',
          'useEffect replaces lifecycle methods',
          'Custom hooks enable logic reuse',
          'Follow the rules of hooks'
        ],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        isFavorite: true,
        wordCount: 1100,
        estimatedReadTime: 5,
        difficultyLevel: DifficultyLevel.advanced,
      ),
      ContentSummaryModel(
        id: 'dummy_4',
        userId: 'dummy_user',
        title: 'Python Data Science Fundamentals',
        originalContent: 'Python is the leading language for data science with powerful libraries like NumPy, Pandas, and Matplotlib...',
        summary: 'Introduction to data science with Python, covering NumPy, Pandas, and Matplotlib. Learn how to manipulate data, perform analysis, and create visualizations.',
        contentType: ContentType.text,
        tags: ['python', 'data-science', 'numpy', 'pandas'],
        keyPoints: [
          'NumPy provides efficient array operations',
          'Pandas simplifies data manipulation',
          'Matplotlib creates beautiful visualizations',
          'Jupyter notebooks enhance workflow'
        ],
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        isFavorite: false,
        wordCount: 1450,
        estimatedReadTime: 6,
        difficultyLevel: DifficultyLevel.beginner,
      ),
      ContentSummaryModel(
        id: 'dummy_5',
        userId: 'dummy_user',
        title: 'Node.js Performance Optimization',
        originalContent: 'Node.js performance optimization involves several strategies including clustering, caching, database optimization, and monitoring...',
        summary: 'Techniques for optimizing Node.js application performance, including clustering, caching, database optimization, and monitoring. Essential for production applications.',
        contentType: ContentType.url,
        contentSource: 'https://nodejs.org/en/docs/guides/simple-profiling/',
        tags: ['nodejs', 'performance', 'optimization', 'backend'],
        keyPoints: [
          'Use clustering for CPU-intensive tasks',
          'Implement caching strategies',
          'Optimize database queries',
          'Monitor application metrics'
        ],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        isFavorite: false,
        wordCount: 980,
        estimatedReadTime: 4,
        difficultyLevel: DifficultyLevel.advanced,
      ),
    ];
  }

  /// Save summaries to local storage
  Future<void> _saveSummariesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summariesJson = json.encode(_summaries.map((s) => s.toJson()).toList());
      await prefs.setString(_summariesKey, summariesJson);
    } catch (e) {
      developer.log('Error saving summaries: $e', name: 'SummarizerProvider');
    }
  }
}

# 🚀 AI Summarizer Database Migration - Simple Guide

## 📋 Overview
Panduan sederhana untuk migrasi AI Summarizer dari local storage ke Supabase database.

## 🎯 Tujuan
- ❌ **Local Storage**: Data hilang saat clear browser
- ✅ **Supabase Database**: Data persistent, sync antar device

## 🗄️ Database Schema

### 3 Tabel Utama:
1. **`content_summaries`** - Penyimpanan summary
2. **`summary_categories`** - Kategori organisasi  
3. **`summary_category_relations`** - Relasi summary-kategori

## 📊 Struktur Tabel

### 1. Content Summaries
```sql
content_summaries:
- id (UUID, Primary Key)
- user_id (UUID, Link ke auth.users)
- title (TEXT, Judul summary)
- original_content (TEXT, Konten asli)
- content_type (text/url/file)
- content_source (TEXT, URL/path)
- summary (TEXT, AI summary)
- key_points (JSONB, Array key points)
- tags (JSONB, Array tags)
- word_count (INTEGER)
- estimated_read_time (INTEGER, menit)
- difficulty_level (beginner/intermediate/advanced)
- is_favorite (BOOLEAN)
- created_at, updated_at (TIMESTAMP)
```

### 2. Summary Categories
```sql
summary_categories:
- id (UUID, Primary Key)
- user_id (UUID, Link ke user)
- name (TEXT, Nama kategori)
- color (TEXT, Warna hex)
- icon (TEXT, Nama icon)
- created_at (TIMESTAMP)
```

### 3. Relations (Many-to-Many)
```sql
summary_category_relations:
- summary_id (UUID, Link ke summary)
- category_id (UUID, Link ke kategori)
```

## 🔧 Cara Setup

### Step 1: Run Schema di Supabase
1. Buka **Supabase Dashboard**
2. Go to **SQL Editor**
3. Copy paste isi file `ai_summarizer_simple_schema.sql`
4. Klik **Run** untuk execute

### Step 2: Verify Installation
```sql
-- Check tables created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%summar%';

-- Should return:
-- content_summaries
-- summary_categories  
-- summary_category_relations
```

### Step 3: Test dengan Sample Data
```sql
-- Insert sample category
INSERT INTO summary_categories (user_id, name, color) 
VALUES (auth.uid(), 'Test Category', '#3B82F6');

-- Insert sample summary
INSERT INTO content_summaries (
    user_id, title, original_content, content_type, 
    summary, key_points, tags
) VALUES (
    auth.uid(), 
    'Test Summary', 
    'This is original content', 
    'text',
    'This is AI generated summary',
    '["Point 1", "Point 2"]'::jsonb,
    '["tag1", "tag2"]'::jsonb
);
```

## 🔄 Flutter Integration

### Update SummarizerProvider
```dart
class SummarizerProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Load summaries from database
  Future<List<ContentSummaryModel>> loadSummaries() async {
    try {
      final response = await _supabase
          .from('summaries_with_categories')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
      
      return response
          .map((json) => ContentSummaryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load summaries: $e');
    }
  }
  
  // Save summary to database
  Future<void> saveSummary(ContentSummaryModel summary) async {
    try {
      await _supabase
          .from('content_summaries')
          .insert(summary.toJson());
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to save summary: $e');
    }
  }
  
  // Delete summary
  Future<void> deleteSummary(String id) async {
    try {
      await _supabase
          .from('content_summaries')
          .delete()
          .eq('id', id);
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete summary: $e');
    }
  }
  
  // Toggle favorite
  Future<void> toggleFavorite(String id) async {
    try {
      // Get current state
      final current = await _supabase
          .from('content_summaries')
          .select('is_favorite')
          .eq('id', id)
          .single();
      
      // Toggle
      await _supabase
          .from('content_summaries')
          .update({'is_favorite': !current['is_favorite']})
          .eq('id', id);
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }
  
  // Search summaries
  Future<List<ContentSummaryModel>> searchSummaries(String query) async {
    try {
      final response = await _supabase
          .from('content_summaries')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .or('title.ilike.%$query%,summary.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return response
          .map((json) => ContentSummaryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search summaries: $e');
    }
  }
}
```

### Update ContentSummaryModel
```dart
class ContentSummaryModel {
  final String id;
  final String userId;
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
  final DateTime updatedAt;
  final List<CategoryModel>? categories; // From view
  
  // Constructor...
  
  // From JSON (from Supabase)
  factory ContentSummaryModel.fromJson(Map<String, dynamic> json) {
    return ContentSummaryModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      originalContent: json['original_content'],
      contentType: ContentType.values.firstWhere(
        (e) => e.name == json['content_type']
      ),
      contentSource: json['content_source'],
      summary: json['summary'],
      keyPoints: List<String>.from(json['key_points'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      wordCount: json['word_count'],
      estimatedReadTime: json['estimated_read_time'],
      difficultyLevel: json['difficulty_level'] != null
          ? DifficultyLevel.values.firstWhere(
              (e) => e.name == json['difficulty_level']
            )
          : null,
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((cat) => CategoryModel.fromJson(cat))
              .toList()
          : null,
    );
  }
  
  // To JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'original_content': originalContent,
      'content_type': contentType.name,
      'content_source': contentSource,
      'summary': summary,
      'key_points': keyPoints,
      'tags': tags,
      'word_count': wordCount,
      'estimated_read_time': estimatedReadTime,
      'difficulty_level': difficultyLevel?.name,
      'is_favorite': isFavorite,
    };
  }
}
```

## 🎨 New Features Available

### 1. Categories Management
```dart
// Load categories
Future<List<CategoryModel>> loadCategories() async {
  final response = await _supabase
      .from('summary_categories')
      .select()
      .eq('user_id', _supabase.auth.currentUser!.id)
      .order('name');
  
  return response.map((json) => CategoryModel.fromJson(json)).toList();
}

// Create category
Future<void> createCategory(String name, String color, String icon) async {
  await _supabase.from('summary_categories').insert({
    'user_id': _supabase.auth.currentUser!.id,
    'name': name,
    'color': color,
    'icon': icon,
  });
}
```

### 2. Full-text Search
```dart
// Advanced search with full-text
Future<List<ContentSummaryModel>> fullTextSearch(String query) async {
  final response = await _supabase
      .rpc('search_summaries', params: {
        'search_query': query,
        'user_id': _supabase.auth.currentUser!.id,
      });
  
  return response.map((json) => ContentSummaryModel.fromJson(json)).toList();
}
```

### 3. Statistics
```dart
// Get user statistics
Future<Map<String, dynamic>> getUserStats() async {
  final response = await _supabase
      .from('content_summaries')
      .select()
      .eq('user_id', _supabase.auth.currentUser!.id);
  
  return {
    'total': response.length,
    'favorites': response.where((s) => s['is_favorite']).length,
    'thisWeek': response.where((s) {
      final created = DateTime.parse(s['created_at']);
      return DateTime.now().difference(created).inDays <= 7;
    }).length,
  };
}
```

## 🔄 Migration Steps

### Phase 1: Setup Database ✅
1. Run schema di Supabase
2. Verify tables created
3. Test dengan sample data

### Phase 2: Update Flutter Code
1. Update SummarizerProvider untuk use Supabase
2. Update models untuk match database schema
3. Replace SharedPreferences calls dengan Supabase queries
4. Add error handling

### Phase 3: Data Migration (Optional)
1. Export existing local storage data
2. Transform ke format database
3. Import ke Supabase
4. Verify data integrity

### Phase 4: Testing
1. Test CRUD operations
2. Test search functionality
3. Test categories
4. Test sync antar device

## ✅ Benefits

### Sebelum:
- ❌ Data hilang saat clear browser
- ❌ Tidak sync antar device
- ❌ Limited storage
- ❌ No search

### Sesudah:
- ✅ **Cloud storage persistent**
- ✅ **Real-time sync antar device**
- ✅ **Unlimited storage**
- ✅ **Full-text search**
- ✅ **Categories untuk organisasi**
- ✅ **Favorites dan filtering**
- ✅ **Statistics dan analytics**

## 🚀 Ready to Use!

Schema sudah siap digunakan dan akan memberikan foundation yang solid untuk AI Summarizer yang lebih powerful dengan cloud storage! 🎉
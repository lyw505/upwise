import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/learning_path_model.dart';
import '../core/config/env_config.dart';

/// Enhanced AI Service untuk menghasilkan learning path yang lebih akurat dan natural
class EnhancedAIService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  /// Generate learning path dengan akurasi tinggi dan gaya bahasa yang lebih bebas
  Future<Map<String, dynamic>?> generateAccurateLearningPath({
    required String topic,
    required int durationDays,
    required int dailyTimeMinutes,
    required ExperienceLevel experienceLevel,
    required LearningStyle learningStyle,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
    String? notes,
    String language = 'id',
  }) async {
    try {
      // Build enhanced prompt dengan gaya yang lebih bebas dan akurat
      final prompt = _buildCasualAccuratePrompt(
        topic: topic,
        durationDays: durationDays,
        dailyTimeMinutes: dailyTimeMinutes,
        experienceLevel: experienceLevel,
        learningStyle: learningStyle,
        outputGoal: outputGoal,
        includeProjects: includeProjects,
        includeExercises: includeExercises,
        notes: notes,
        language: language,
      );

      // Call AI dengan parameter yang dioptimalkan untuk kreativitas dan akurasi
      final response = await _callOptimizedGeminiAPI(prompt);
      
      if (response != null) {
        final parsed = _parseEnhancedResponse(response, durationDays);
        if (parsed != null) {
          // Enhance dengan real-world accuracy dan casual tone
          final enhanced = await _enhanceWithRealWorldAccuracy(
            parsed,
            topic,
            experienceLevel,
            learningStyle,
          );
          
          return enhanced;
        }
      }
      
      // Fallback dengan gaya casual yang akurat
      return _generateCasualAccurateFallback(
        topic: topic,
        durationDays: durationDays,
        experienceLevel: experienceLevel,
        learningStyle: learningStyle,
        outputGoal: outputGoal,
        includeProjects: includeProjects,
        includeExercises: includeExercises,
      );
      
    } catch (e) {
      print('Enhanced AI generation failed: $e');
      return _generateCasualAccurateFallback(
        topic: topic,
        durationDays: durationDays,
        experienceLevel: experienceLevel,
        learningStyle: learningStyle,
        outputGoal: outputGoal,
        includeProjects: includeProjects,
        includeExercises: includeExercises,
      );
    }
  }

  /// Build prompt dengan gaya casual tapi akurat untuk hasil yang lebih natural
  String _buildCasualAccuratePrompt({
    required String topic,
    required int durationDays,
    required int dailyTimeMinutes,
    required ExperienceLevel experienceLevel,
    required LearningStyle learningStyle,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
    String? notes,
    String language = 'id',
  }) {
    return '''
# AI LEARNING PATH CREATOR - GAYA SANTAI TAPI AKURAT

Kamu adalah seorang mentor keren yang jago banget di bidang "$topic" dan punya pengalaman ngajarin orang dengan berbagai background. Tugasmu adalah bikin learning path $durationDays hari yang:

1. AKURAT & REAL-WORLD - Berdasarkan pengalaman nyata di industri
2. SANTAI & NATURAL - Gaya bahasa seperti ngobrol sama teman
3. PRAKTIS & APPLICABLE - Bisa langsung dipake di dunia nyata

## PROFIL LEARNER
**Experience Level**: ${experienceLevel.name} - ${_getCasualLevelDescription(experienceLevel)}
**Learning Style**: ${learningStyle.name} - ${_getCasualStyleDescription(learningStyle)}
**Target Goal**: $outputGoal
**Waktu Harian**: $dailyTimeMinutes menit (realistis banget kan?)
${notes != null ? '**Catatan Tambahan**: $notes' : ''}

## GAYA KOMUNIKASI YANG DIINGINKAN

### Tone & Style:
- Gunakan bahasa sehari-hari, jangan terlalu formal
- Sesekali pake emoji atau ekspresi casual 😊
- Explain complex stuff dengan analogi yang relate
- Jangan takut pake slang atau bahasa gaul yang appropriate
- Bikin learning experience yang fun dan engaging

### Accuracy Requirements:
- Semua info harus 100% akurat dan up-to-date
- Resource yang dikasih harus bener-bener berkualitas
- Step-by-step yang realistic dan achievable
- Jangan overpromise - kasih ekspektasi yang real

## OUTPUT FORMAT

Bikin JSON dengan struktur ini, tapi isi kontennya pake gaya santai:

{
  "description": "Deskripsi yang engaging dan realistic tentang apa yang bakal dipelajari - pake bahasa yang natural dan motivating",
  "daily_tasks": [
    {
      "main_topic": "Topik utama hari ini - dijelasin dengan casual",
      "sub_topic": "Specific goal hari ini yang realistic dan achievable dalam $dailyTimeMinutes menit",
      "material_url": "URL resource yang bener-bener bagus dan accessible",
      "material_title": "Judul yang menarik dan jelas - gak perlu formal banget",
      "exercise": ${includeExercises ? '"Exercise yang fun dan practical - dijelasin step by step dengan bahasa santai"' : 'null'}
    }
  ]${includeProjects ? ',\n  "project_recommendations": [\n    {\n      "title": "Nama project yang keren dan realistic",\n      "description": "Deskripsi project yang bikin excited tapi tetep achievable",\n      "difficulty": "beginner/intermediate/advanced",\n      "estimated_hours": 15\n    }\n  ]' : ''}
}

## CONTOH GAYA BAHASA YANG DIINGINKAN

❌ JANGAN: "Pada hari pertama, Anda akan mempelajari konsep fundamental..."
✅ LAKUKAN: "Hari pertama kita bakal kenalan sama basic concepts yang penting banget..."

❌ JANGAN: "Silakan mengakses resource pembelajaran berikut..."
✅ LAKUKAN: "Cek video ini deh, penjelasannya asik dan mudah dimengerti..."

## CRITICAL SUCCESS FACTORS

1. **AKURASI TINGGI**: Semua info harus bener dan applicable
2. **GAYA SANTAI**: Bahasa natural, gak kaku, engaging
3. **REALISTIC TIMELINE**: $dailyTimeMinutes menit per hari itu achievable
4. **PRACTICAL VALUE**: Setiap hari harus ada progress yang keliatan
5. **MOTIVATING**: Bikin learner excited buat lanjut ke hari berikutnya

Bikin learning path yang bener-bener helpful dan enjoyable! 🚀

TOPIK: $topic
DURASI: $durationDays hari
GOAL: $outputGoal

Mulai dengan { dan akhiri dengan }. Gak usah ada text tambahan lain.
''';
  }

  String _getCasualStyleDescription(LearningStyle style) {
    switch (style) {
      case LearningStyle.visual:
        return 'suka banget sama diagram, video, dan visual aids 👀';
      case LearningStyle.auditory:
        return 'lebih suka dengerin penjelasan, podcast, atau video tutorial 🎧';
      case LearningStyle.kinesthetic:
        return 'harus praktek langsung baru ngerti. Learning by doing! 🛠️';
      case LearningStyle.readingWriting:
        return 'suka baca dokumentasi, artikel, dan nulis notes 📚';
    }
  }

  String _getCasualLevelDescription(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'baru mulai atau masih basic banget 🌱';
      case ExperienceLevel.intermediate:
        return 'udah punya basic knowledge, siap untuk challenge yang lebih complex 🚀';
      case ExperienceLevel.advanced:
        return 'udah experienced, butuh advanced concepts dan best practices 🔥';
    }
  } 
 /// Call Gemini API dengan parameter yang dioptimalkan untuk kreativitas dan akurasi
  Future<Map<String, dynamic>?> _callOptimizedGeminiAPI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=${EnvConfig.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.8, // Higher untuk kreativitas dan gaya yang lebih bebas
            'topK': 40, // Lebih diverse untuk natural language
            'topP': 0.9, // Higher untuk variasi yang lebih natural
            'maxOutputTokens': 16384, // Increased untuk detailed content
            'candidateCount': 1,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      ).timeout(Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates']?.isNotEmpty == true) {
          return data;
        }
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Optimized Gemini API call failed: $e');
    }
    
    return null;
  }

  /// Parse response dengan enhanced validation
  Map<String, dynamic>? _parseEnhancedResponse(Map<String, dynamic> response, int durationDays) {
    try {
      final generatedText = response['candidates'][0]['content']['parts'][0]['text'];
      
      // Enhanced text cleaning
      String cleanedText = generatedText.trim();
      
      // Remove markdown code blocks
      if (cleanedText.contains('```json')) {
        final startIndex = cleanedText.indexOf('```json') + 7;
        final endIndex = cleanedText.indexOf('```', startIndex);
        if (endIndex != -1) {
          cleanedText = cleanedText.substring(startIndex, endIndex);
        } else {
          cleanedText = cleanedText.substring(startIndex);
        }
      } else if (cleanedText.contains('```')) {
        final startIndex = cleanedText.indexOf('```') + 3;
        final endIndex = cleanedText.indexOf('```', startIndex);
        if (endIndex != -1) {
          cleanedText = cleanedText.substring(startIndex, endIndex);
        } else {
          cleanedText = cleanedText.substring(startIndex);
        }
      }
      
      // Find JSON boundaries
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedText = cleanedText.substring(jsonStart, jsonEnd + 1);
      }
      
      // Parse JSON
      final parsed = jsonDecode(cleanedText) as Map<String, dynamic>;
      
      // Validate and enhance structure
      return _validateAndEnhanceStructure(parsed, durationDays);
      
    } catch (e) {
      print('Error parsing enhanced response: $e');
      return null;
    }
  }

  /// Validate dan enhance structure dari parsed response
  Map<String, dynamic> _validateAndEnhanceStructure(Map<String, dynamic> parsed, int durationDays) {
    // Ensure description exists dan engaging
    if (!parsed.containsKey('description') || parsed['description'].toString().length < 50) {
      parsed['description'] = 'Learning path yang dirancang khusus buat kamu! Bakal seru banget dan pasti applicable di dunia nyata 🚀';
    }
    
    // Validate daily tasks
    if (!parsed.containsKey('daily_tasks') || parsed['daily_tasks'] is! List) {
      parsed['daily_tasks'] = [];
    }
    
    final dailyTasksList = parsed['daily_tasks'] as List;
    
    // Ensure correct number of tasks
    while (dailyTasksList.length < durationDays) {
      final dayNumber = dailyTasksList.length + 1;
      dailyTasksList.add({
        'main_topic': 'Hari $dayNumber - Learning Focus',
        'sub_topic': 'Konsep penting yang bakal kamu pelajari hari ini',
        'material_url': 'https://www.google.com/search?q=tutorial+pembelajaran',
        'material_title': 'Resource Pembelajaran Hari $dayNumber',
        'exercise': null,
      });
    }
    
    // Trim if too many tasks
    if (dailyTasksList.length > durationDays) {
      parsed['daily_tasks'] = dailyTasksList.take(durationDays).toList();
    }
    
    // Enhance each task
    for (int i = 0; i < dailyTasksList.length; i++) {
      final task = dailyTasksList[i] as Map<String, dynamic>;
      
      // Ensure all required fields
      task['main_topic'] ??= 'Hari ${i + 1} Learning';
      task['sub_topic'] ??= 'Skill baru yang bakal kamu kuasai';
      task['material_title'] ??= 'Resource Keren untuk Hari ${i + 1}';
      task['material_url'] ??= 'https://www.google.com/search?q=tutorial';
      
      // Add casual enhancements
      task['main_topic'] = _enhanceWithCasualTone(task['main_topic'].toString());
      task['sub_topic'] = _enhanceWithCasualTone(task['sub_topic'].toString());
      task['material_title'] = _enhanceWithCasualTone(task['material_title'].toString());
    }
    
    return parsed;
  }

  /// Enhance text dengan casual tone
  String _enhanceWithCasualTone(String text) {
    // Jangan ubah jika sudah casual
    if (text.contains('kamu') || text.contains('bakal') || text.contains('banget')) {
      return text;
    }
    
    // Simple enhancements untuk casual tone
    String enhanced = text;
    
    // Replace formal words
    enhanced = enhanced.replaceAll('Anda', 'kamu');
    enhanced = enhanced.replaceAll('akan', 'bakal');
    enhanced = enhanced.replaceAll('sangat', 'banget');
    enhanced = enhanced.replaceAll('Pembelajaran', 'Belajar');
    enhanced = enhanced.replaceAll('Implementasi', 'Praktek');
    
    return enhanced;
  }

  /// Enhance dengan real-world accuracy
  Future<Map<String, dynamic>> _enhanceWithRealWorldAccuracy(
    Map<String, dynamic> content,
    String topic,
    ExperienceLevel experienceLevel,
    LearningStyle learningStyle,
  ) async {
    final enhanced = Map<String, dynamic>.from(content);
    
    // Enhance URLs dengan resource yang lebih akurat
    final tasks = enhanced['daily_tasks'] as List;
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i] as Map<String, dynamic>;
      
      // Find better URL if current one is generic
      if (task['material_url'].toString().contains('google.com/search')) {
        task['material_url'] = await _findAccurateResource(
          topic,
          task['main_topic'].toString(),
          learningStyle,
        );
      }
      
      // Add realistic time estimates
      task['realistic_time_estimate'] = _calculateRealisticTime(
        task['sub_topic'].toString(),
        experienceLevel,
      );
      
      // Add difficulty indicator
      task['difficulty_indicator'] = _calculateDifficulty(i + 1, tasks.length, experienceLevel);
    }
    
    // Add accuracy metadata
    enhanced['accuracy_metadata'] = {
      'generated_at': DateTime.now().toIso8601String(),
      'topic_accuracy_score': _calculateTopicAccuracy(topic),
      'real_world_applicability': 0.9,
      'resource_quality_score': 0.85,
    };
    
    return enhanced;
  }

  /// Find accurate resource untuk topik tertentu
  Future<String> _findAccurateResource(String topic, String mainTopic, LearningStyle learningStyle) async {
    final topicLower = topic.toLowerCase();
    
    // High-quality resources berdasarkan topik
    final resourceMap = {
      'flutter': {
        'official': 'https://docs.flutter.dev/',
        'tutorial': 'https://docs.flutter.dev/get-started/codelab',
        'video': 'https://www.youtube.com/results?search_query=flutter+tutorial+bahasa+indonesia',
      },
      'python': {
        'official': 'https://docs.python.org/3/tutorial/',
        'tutorial': 'https://www.python.org/about/gettingstarted/',
        'video': 'https://www.youtube.com/results?search_query=python+tutorial+bahasa+indonesia',
      },
      'javascript': {
        'official': 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide',
        'tutorial': 'https://developer.mozilla.org/en-US/docs/Learn/JavaScript',
        'video': 'https://www.youtube.com/results?search_query=javascript+tutorial+bahasa+indonesia',
      },
      'react': {
        'official': 'https://react.dev/learn',
        'tutorial': 'https://react.dev/learn/tutorial-tic-tac-toe',
        'video': 'https://www.youtube.com/results?search_query=react+tutorial+bahasa+indonesia',
      },
    };
    
    // Find best match
    for (final key in resourceMap.keys) {
      if (topicLower.contains(key)) {
        final resources = resourceMap[key]!;
        
        // Choose based on learning style
        switch (learningStyle) {
          case LearningStyle.visual:
          case LearningStyle.auditory:
            return resources['video']!;
          case LearningStyle.kinesthetic:
            return resources['tutorial']!;
          case LearningStyle.readingWriting:
            return resources['official']!;
        }
      }
    }
    
    // Fallback to search
    final searchQuery = Uri.encodeComponent('$topic $mainTopic tutorial bahasa indonesia');
    return 'https://www.google.com/search?q=$searchQuery';
  }

  /// Calculate realistic time estimate
  String _calculateRealisticTime(String subTopic, ExperienceLevel experienceLevel) {
    final baseTime = experienceLevel == ExperienceLevel.beginner 
        ? 45 
        : experienceLevel == ExperienceLevel.intermediate 
            ? 35 
            : 25;
    
    // Adjust based on complexity indicators
    final complexity = _assessComplexity(subTopic);
    final adjustedTime = (baseTime * complexity).round();
    
    return '$adjustedTime menit (realistic estimate)';
  }

  /// Assess complexity dari subtopic
  double _assessComplexity(String subTopic) {
    final complexityIndicators = [
      'advanced', 'complex', 'integration', 'architecture', 'optimization',
      'performance', 'security', 'deployment', 'testing', 'debugging'
    ];
    
    final simpleIndicators = [
      'basic', 'introduction', 'getting started', 'hello world', 'simple',
      'fundamental', 'overview', 'concept', 'theory'
    ];
    
    final subTopicLower = subTopic.toLowerCase();
    
    for (final indicator in complexityIndicators) {
      if (subTopicLower.contains(indicator)) return 1.3;
    }
    
    for (final indicator in simpleIndicators) {
      if (subTopicLower.contains(indicator)) return 0.8;
    }
    
    return 1.0; // Default complexity
  }

  /// Calculate difficulty indicator
  String _calculateDifficulty(int dayNumber, int totalDays, ExperienceLevel experienceLevel) {
    final progressRatio = dayNumber / totalDays;
    final baseDifficulty = experienceLevel == ExperienceLevel.beginner 
        ? 0.3 
        : experienceLevel == ExperienceLevel.intermediate 
            ? 0.5 
            : 0.7;
    
    final adjustedDifficulty = baseDifficulty + (progressRatio * 0.4);
    
    if (adjustedDifficulty < 0.4) return 'Easy 😊';
    if (adjustedDifficulty < 0.7) return 'Medium 🤔';
    return 'Challenging 🔥';
  }

  /// Calculate topic accuracy score
  double _calculateTopicAccuracy(String topic) {
    final topicLower = topic.toLowerCase();
    
    // High accuracy topics (well-documented, stable)
    final highAccuracyTopics = ['python', 'javascript', 'html', 'css', 'sql'];
    for (final highTopic in highAccuracyTopics) {
      if (topicLower.contains(highTopic)) return 0.95;
    }
    
    // Medium accuracy topics (evolving, but stable)
    final mediumAccuracyTopics = ['flutter', 'react', 'node', 'vue', 'angular'];
    for (final mediumTopic in mediumAccuracyTopics) {
      if (topicLower.contains(mediumTopic)) return 0.85;
    }
    
    // Default accuracy
    return 0.8;
  }

  /// Generate casual accurate fallback ketika AI tidak tersedia
  Map<String, dynamic> _generateCasualAccurateFallback({
    required String topic,
    required int durationDays,
    required ExperienceLevel experienceLevel,
    required LearningStyle learningStyle,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
  }) {
    final dailyTasks = <Map<String, dynamic>>[];
    final topicData = _getCasualTopicData(topic.toLowerCase());
    
    // Create progressive learning structure dengan gaya casual
    final phases = _createCasualLearningPhases(topicData, durationDays, experienceLevel);
    
    for (int i = 1; i <= durationDays; i++) {
      final phaseIndex = ((i - 1) / (durationDays / phases.length)).floor().clamp(0, phases.length - 1);
      final phase = phases[phaseIndex];
      final dayInPhase = (i - 1) % (durationDays / phases.length).ceil();
      
      final task = phase['tasks'][dayInPhase % phase['tasks'].length];
      
      dailyTasks.add({
        'main_topic': task['topic'],
        'sub_topic': task['subtopic'],
        'material_url': task['url'],
        'material_title': task['title'],
        'exercise': includeExercises ? task['exercise'] : null,
        'realistic_time_estimate': _calculateRealisticTime(task['subtopic'], experienceLevel),
        'difficulty_indicator': _calculateDifficulty(i, durationDays, experienceLevel),
        'casual_tip': task['tip'], // Tambahan tip casual
      });
    }

    final result = <String, dynamic>{
      'description': topicData['description'].replaceAll('{goal}', outputGoal),
      'daily_tasks': dailyTasks,
      'accuracy_metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'fallback_quality': 'high',
        'topic_accuracy_score': _calculateTopicAccuracy(topic),
        'real_world_applicability': 0.9,
      },
    };

    if (includeProjects) {
      result['project_recommendations'] = topicData['projects'];
    }

    return result;
  }

  /// Get casual topic data dengan gaya bahasa yang santai
  Map<String, dynamic> _getCasualTopicData(String topic) {
    final casualTopicMap = {
      'flutter': {
        'description': 'Siap-siap jadi Flutter developer yang keren! 🚀 Kamu bakal belajar bikin aplikasi mobile yang smooth dan cantik. Flutter itu framework Google yang lagi hot banget sekarang - perfect buat yang mau jadi mobile developer handal. Target kamu: {goal} bakal tercapai dengan learning path ini!',
        'phases': [
          {
            'name': 'Flutter Basics - Kenalan sama Flutter',
            'tasks': [
              {
                'topic': 'Dart Language - Bahasa Pemrograman Flutter',
                'subtopic': 'Belajar Dart dari nol - variables, functions, dan OOP yang fun!',
                'title': 'Dart Tutorial yang Asik dan Mudah Dimengerti',
                'url': 'https://dart.dev/language',
                'exercise': 'Bikin program Dart sederhana buat manage data mahasiswa - praktek OOP yang real!',
                'tip': 'Dart itu mirip Java tapi lebih simple. Santai aja, pasti bisa! 😊'
              },
              {
                'topic': 'Flutter Setup - Persiapan Development',
                'subtopic': 'Install Flutter dan setup environment yang proper',
                'title': 'Flutter Installation Guide - Step by Step',
                'url': 'https://docs.flutter.dev/get-started/install',
                'exercise': 'Setup Flutter di laptop kamu dan bikin Hello World app pertama',
                'tip': 'Proses install agak lama, tapi worth it banget! Sambil nunggu bisa baca-baca dulu 📱'
              },
              {
                'topic': 'Widget System - Building Blocks Flutter',
                'subtopic': 'Memahami widget tree dan cara kerja UI Flutter',
                'title': 'Flutter Widgets - Everything is a Widget!',
                'url': 'https://docs.flutter.dev/ui/widgets-intro',
                'exercise': 'Bikin profile card yang keren pake berbagai widget',
                'tip': 'Widget itu kayak LEGO - tinggal susun-susun aja jadi app yang keren! 🧱'
              },
            ]
          },
          {
            'name': 'Flutter Development - Bikin App Beneran',
            'tasks': [
              {
                'topic': 'State Management - Kelola Data App',
                'subtopic': 'Belajar StatefulWidget dan cara manage state yang bener',
                'title': 'Flutter State Management untuk Pemula',
                'url': 'https://docs.flutter.dev/ui/interactivity',
                'exercise': 'Bikin shopping cart app dengan add/remove items',
                'tip': 'State management itu jantungnya app. Sekali paham, semua jadi gampang! 💡'
              },
              {
                'topic': 'Navigation - Pindah-pindah Screen',
                'subtopic': 'Routing dan navigation antar halaman yang smooth',
                'title': 'Flutter Navigation and Routing',
                'url': 'https://docs.flutter.dev/ui/navigation',
                'exercise': 'Bikin multi-page app dengan bottom navigation',
                'tip': 'Navigation di Flutter itu kayak buku - bisa flip halaman maju mundur! 📖'
              },
            ]
          }
        ],
        'projects': [
          {
            'title': 'Personal Expense Tracker - Aplikasi Keuangan Pribadi',
            'description': 'Bikin aplikasi tracking pengeluaran yang keren! Complete dengan charts, kategori, dan budget management. Perfect buat portfolio dan daily use 💰',
            'difficulty': 'beginner',
            'estimated_hours': 20
          }
        ]
      },
      
      'python': {
        'description': 'Python itu bahasa pemrograman yang paling friendly buat pemula! 🐍 Syntax-nya simple, powerful, dan bisa dipake buat apa aja - web development, data science, AI, automation. Target kamu: {goal} bakal mudah dicapai dengan Python sebagai foundation!',
        'phases': [
          {
            'name': 'Python Fundamentals - Basic yang Wajib Tahu',
            'tasks': [
              {
                'topic': 'Python Syntax - Kenalan sama Python',
                'subtopic': 'Variables, data types, dan basic operations yang fun',
                'title': 'Python Basics - Mulai dari Nol',
                'url': 'https://docs.python.org/3/tutorial/introduction.html',
                'exercise': 'Bikin kalkulator sederhana yang bisa operasi matematika dasar',
                'tip': 'Python syntax-nya paling gampang di dunia programming. No semicolon, no curly braces! 🎉'
              },
            ]
          }
        ],
        'projects': [
          {
            'title': 'Personal Budget Manager - Aplikasi Keuangan',
            'description': 'Bikin aplikasi budget management yang complete! Tracking income, expenses, dan financial goals. Real-world application yang berguna banget 💸',
            'difficulty': 'beginner',
            'estimated_hours': 25
          }
        ]
      },
      
      // Universal fallback untuk topik apapun
      'default': {
        'description': 'Learning path yang dirancang khusus buat kamu! 🎯 Bakal seru banget dan pasti applicable di dunia nyata. Setiap hari ada progress yang keliatan, dan di akhir kamu bakal confident dengan skill baru. Target kamu: {goal} pasti tercapai!',
        'phases': [
          {
            'name': 'Foundation Building - Dasar yang Kuat',
            'tasks': [
              {
                'topic': 'Getting Started - Mulai dari Sini',
                'subtopic': 'Kenalan sama basic concepts dan fundamental principles',
                'title': 'Introduction dan Overview yang Comprehensive',
                'url': 'https://www.google.com/search?q=tutorial+dasar',
                'exercise': 'Praktek langsung dengan project sederhana',
                'tip': 'Every expert was once a beginner. Kamu pasti bisa! 💪'
              },
            ]
          }
        ],
        'projects': [
          {
            'title': 'Personal Learning Project',
            'description': 'Project yang disesuaikan dengan learning goal kamu. Practical, applicable, dan fun to build! 🚀',
            'difficulty': 'beginner',
            'estimated_hours': 20
          }
        ]
      }
    };
    
    // Find best match atau return default
    for (final key in casualTopicMap.keys) {
      if (key != 'default' && topic.contains(key)) {
        return casualTopicMap[key]!;
      }
    }
    
    return casualTopicMap['default']!;
  }

  /// Create casual learning phases
  List<Map<String, dynamic>> _createCasualLearningPhases(
    Map<String, dynamic> topicData,
    int durationDays,
    ExperienceLevel experienceLevel,
  ) {
    final phases = topicData['phases'] as List<Map<String, dynamic>>;
    
    // Adjust phases berdasarkan duration dan level
    if (durationDays <= 7) {
      // Short duration - focus on essentials
      return phases.take(1).toList();
    } else if (durationDays <= 14) {
      // Medium duration - include intermediate concepts
      return phases.take(2).toList();
    } else {
      // Long duration - full comprehensive learning
      return phases;
    }
  }
}
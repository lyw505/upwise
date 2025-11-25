import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/learning_path_model.dart';
import '../core/config/env_config.dart';
import 'enhanced_prompt_service.dart';
import 'content_quality_service.dart';
import 'youtube_search_service.dart';
import 'enhanced_ai_service.dart';

class GeminiService {
  static String get _apiKey => EnvConfig.geminiApiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  // Instance of enhanced AI service
  final EnhancedAIService _enhancedAI = EnhancedAIService();

  Future<Map<String, dynamic>?> generateLearningPath({
    required String topic,
    required int durationDays,
    required int dailyTimeMinutes,
    required ExperienceLevel experienceLevel,
    required LearningStyle learningStyle,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
    String? notes,
    String language = 'id', // Default to Indonesian
  }) async {
    try {
      // Check if API key is configured
      if (!EnvConfig.isConfigured) {
        if (EnvConfig.isDebugMode) {
          print('Gemini API key not configured, using enhanced fallback');
        }
        return _enhancedAI.generateAccurateLearningPath(
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
      }

      // Use enhanced AI service for better, more casual results
      if (EnvConfig.isDebugMode) {
        print('🚀 Using Enhanced AI Service for more accurate and casual learning path');
      }
      
      final result = await _enhancedAI.generateAccurateLearningPath(
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
      
      if (result != null) {
        // Add YouTube videos to enhance the learning experience
        final enhancedWithVideos = await _addYouTubeVideosToTasks(result, experienceLevel);
        
        if (EnvConfig.isDebugMode) {
          print('✅ Enhanced AI generated casual and accurate learning path with ${(result['daily_tasks'] as List).length} tasks');
        }
        
        return enhancedWithVideos;
      }

      // Fallback to original method if enhanced AI fails
      if (EnvConfig.isDebugMode) {
        print('⚠️ Enhanced AI failed, falling back to original method');
      }
      
      // Use enhanced prompt service for better AI responses
      final prompt = EnhancedPromptService.generateAdvancedPrompt(
        topic: topic,
        durationDays: durationDays,
        dailyTimeMinutes: dailyTimeMinutes,
        experienceLevel: experienceLevel,
        learningStyle: learningStyle,
        outputGoal: outputGoal,
        includeProjects: includeProjects,
        includeExercises: includeExercises,
        language: language,
        notes: notes,
      );

      if (EnvConfig.isDebugMode) {
        print('🤖 Making request to Gemini API...');
        print('📍 URL: $_baseUrl');
        print('🔑 API Key: ${_apiKey.substring(0, 10)}...');
        print('🌍 Language: $language');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2, // Even lower temperature for more consistent, structured output
            'topK': 20, // Reduced for more focused responses
            'topP': 0.8, // Reduced for more deterministic output
            'maxOutputTokens': 12288, // Increased for more detailed content
            'stopSequences': [],
            'candidateCount': 1, // Single candidate for consistency
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
      ).timeout(
        Duration(seconds: EnvConfig.apiTimeout ~/ 1000),
        onTimeout: () {
          throw Exception('API request timeout after ${EnvConfig.apiTimeout ~/ 1000} seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if response has the expected structure
        if (data['candidates'] == null ||
            data['candidates'].isEmpty ||
            data['candidates'][0]['content'] == null ||
            data['candidates'][0]['content']['parts'] == null ||
            data['candidates'][0]['content']['parts'].isEmpty) {
          throw Exception('Invalid API response structure');
        }

        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];

        // Parse the generated JSON response
        final result = _parseGeneratedResponse(generatedText, durationDays);

        if (result != null) {
          // Validate and enhance content quality
          final enhancedResult = ContentQualityService.validateAndEnhanceContent(
            result,
            topic,
            durationDays,
            experienceLevel,
            learningStyle,
          );
          
          // Add YouTube videos to each daily task
          final enhancedWithVideos = await _addYouTubeVideosToTasks(
            enhancedResult,
            experienceLevel,
          );
          
          // Final quality check
          if (ContentQualityService.validateLearningPathQuality(enhancedWithVideos)) {
            if (EnvConfig.isDebugMode) {
              print('✅ AI-generated content with YouTube videos passed quality validation');
            }
            return enhancedWithVideos;
          } else {
            if (EnvConfig.isDebugMode) {
              print('⚠️ AI-generated content failed quality validation, using enhanced fallback');
            }
            // Use enhanced fallback if quality check fails
            final fallback = createFallbackLearningPath(
              topic: topic,
              durationDays: durationDays,
              outputGoal: outputGoal,
              includeProjects: includeProjects,
              includeExercises: includeExercises,
              experienceLevel: experienceLevel,
              learningStyle: learningStyle,
            );
            return await _addYouTubeVideosToTasks(fallback, experienceLevel);
          }
        } else {
          // If parsing failed, fall back to enhanced mock data
          throw Exception('Failed to parse AI response');
        }
      } else {
        if (EnvConfig.isDebugMode) {
          print('❌ Gemini API error: ${response.statusCode}');
          print('📄 Response body: ${response.body}');
          print('🔄 Using fallback learning path');
        }
        return createFallbackLearningPath(
          topic: topic,
          durationDays: durationDays,
          outputGoal: outputGoal,
          includeProjects: includeProjects,
          includeExercises: includeExercises,
          experienceLevel: experienceLevel,
          learningStyle: learningStyle,
        );
      }
    } catch (e) {
      if (EnvConfig.isDebugMode) {
        print('Error generating learning path: $e, using fallback');
      }
      return createFallbackLearningPath(
        topic: topic,
        durationDays: durationDays,
        outputGoal: outputGoal,
        includeProjects: includeProjects,
        includeExercises: includeExercises,
        experienceLevel: experienceLevel,
        learningStyle: learningStyle,
      );
    }
  }

  String _buildPrompt({
    required String topic,
    required int durationDays,
    required int dailyTimeMinutes,
    required ExperienceLevel experienceLevel,
    required LearningStyle learningStyle,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
    String? notes,
  }) {
    final experienceDesc = _getExperienceLevelDescription(experienceLevel);
    final styleDesc = _getLearningStyleDescription(learningStyle);
    final learningPhases = _generateLearningPhases(durationDays);
    final topicContext = _getTopicContext(topic);
    
    return '''
You are an expert learning path designer with deep knowledge in curriculum development and instructional design. Create a comprehensive, progressive $durationDays-day learning path for "$topic".

LEARNER PROFILE:
- Experience Level: $experienceDesc
- Learning Style: $styleDesc  
- Daily Time Available: $dailyTimeMinutes minutes
- Learning Goal: $outputGoal
${notes != null && notes.isNotEmpty ? '- Additional Notes: $notes' : ''}

TOPIC CONTEXT & PREREQUISITES:
$topicContext

LEARNING PHASES STRUCTURE:
$learningPhases

QUALITY REQUIREMENTS:
1. PROGRESSIVE DIFFICULTY: Each day must build logically on previous concepts
2. REALISTIC SCOPE: Content must be achievable within $dailyTimeMinutes minutes
3. PRACTICAL APPLICATION: Include real-world examples and use cases
4. QUALITY RESOURCES: Use only reputable, current learning materials
5. CLEAR OBJECTIVES: Each day should have specific, measurable learning outcomes
6. RETENTION STRATEGIES: Include review and reinforcement of previous concepts

CONTENT SPECIFICATIONS:
- Main Topic: Broad concept area (e.g., "Variables and Data Types")
- Sub Topic: Specific, actionable learning goal (e.g., "Understanding string manipulation and formatting")
- Material Title: Descriptive, engaging title that clearly indicates content
- Material URL: Real, accessible, high-quality educational resource
- Exercise: ${includeExercises ? 'Hands-on, practical exercise that reinforces the day\'s learning with clear instructions' : 'Not required'}

LEARNING STYLE OPTIMIZATION:
Focus on ${_getLearningStyleFocus(learningStyle)}

Return ONLY this JSON structure with EXACTLY $durationDays daily tasks:

{
  "description": "Compelling 2-3 sentence overview explaining what the learner will master, the practical skills they'll gain, and how it connects to their goal: $outputGoal",
  "daily_tasks": [
    {
      "main_topic": "Clear, broad concept area for this learning phase",
      "sub_topic": "Specific, actionable learning objective achievable in $dailyTimeMinutes minutes with clear outcome", 
      "material_url": "Real URL to high-quality, current educational resource (official docs, reputable tutorials, courses)",
      "material_title": "Descriptive, engaging title that clearly indicates what the learner will learn",
      "exercise": ${includeExercises ? '"Detailed, step-by-step hands-on exercise with clear instructions, expected outcomes, and practical application"' : 'null'}
    }
  ]${includeProjects ? ',\n  "project_recommendations": [\n    {\n      "title": "Practical project name that demonstrates real-world application",\n      "description": "Detailed description of what you\'ll build, technologies used, and skills demonstrated", \n      "difficulty": "beginner/intermediate/advanced",\n      "estimated_hours": 8\n    }\n  ]' : ''}
}

CRITICAL: Ensure each day has a clear learning objective, builds on previous knowledge, and provides practical value. Start response with { and end with }.''';
  }

  String _getLearningStyleFocus(LearningStyle style) {
    switch (style) {
      case LearningStyle.visual:
        return 'video tutorials, diagrams, infographics, visual examples, interactive demos, and visual learning aids that help understand concepts through sight';
      case LearningStyle.auditory:
        return 'podcasts, lectures, audio explanations, discussion-based content, and verbal instructions that help understand concepts through listening';
      case LearningStyle.kinesthetic:
        return 'hands-on activities, practical exercises, interactive projects, step-by-step tutorials, and learning-by-doing activities that help understand concepts through direct practice';
      case LearningStyle.readingWriting:
        return 'comprehensive articles, documentation, written guides, text-based exercises, and note-taking activities that help understand concepts through reading and writing';
    }
  }

  String _getTopicContext(String topic) {
    final topicLower = topic.toLowerCase();
    
    // Enhanced topic context with prerequisites and learning objectives - Universal Learning Support
    final contextMap = {
      // Programming & Technology
      'flutter': '''
Flutter is Google's UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
Prerequisites: Basic programming concepts, familiarity with object-oriented programming
Key Learning Areas: Dart language, Widget system, State management, Navigation, API integration, Platform-specific features
Industry Applications: Mobile app development, Cross-platform development, UI/UX implementation
Career Relevance: High demand for Flutter developers, especially in startups and companies focusing on rapid development''',
      
      'python': '''
Python is a versatile, high-level programming language known for its simplicity and readability.
Prerequisites: Basic computer literacy, logical thinking skills
Key Learning Areas: Syntax and semantics, Data structures, Object-oriented programming, Libraries and frameworks, Web development, Data science
Industry Applications: Web development, Data analysis, Machine learning, Automation, Scientific computing
Career Relevance: One of the most in-demand programming languages across multiple industries''',
      
      'javascript': '''
JavaScript is the programming language of the web, essential for front-end development and increasingly popular for back-end development.
Prerequisites: Basic HTML and CSS knowledge, understanding of web browsers
Key Learning Areas: Language fundamentals, DOM manipulation, Asynchronous programming, Frameworks and libraries, Node.js, Modern ES6+ features
Industry Applications: Web development, Mobile app development, Server-side development, Desktop applications
Career Relevance: Essential skill for web developers, with high demand across all company sizes''',
      
      'react': '''
React is a JavaScript library for building user interfaces, particularly web applications with dynamic, interactive components.
Prerequisites: Solid JavaScript knowledge, HTML/CSS proficiency, understanding of ES6+ features
Key Learning Areas: Component architecture, JSX, State management, Hooks, Routing, API integration, Testing
Industry Applications: Web application development, Single-page applications, Progressive web apps
Career Relevance: Extremely high demand, especially in tech companies and startups''',
      
      'machine learning': '''
Machine Learning is a subset of artificial intelligence that enables computers to learn and make decisions from data without explicit programming.
Prerequisites: Basic mathematics (statistics, linear algebra), programming experience (preferably Python), understanding of data concepts
Key Learning Areas: Supervised/unsupervised learning, Neural networks, Data preprocessing, Model evaluation, Popular libraries (scikit-learn, TensorFlow, PyTorch)
Industry Applications: Predictive analytics, Computer vision, Natural language processing, Recommendation systems
Career Relevance: Rapidly growing field with high-paying opportunities across industries''',
      
      'data science': '''
Data Science combines statistics, programming, and domain expertise to extract insights from data and inform decision-making.
Prerequisites: Basic statistics, programming skills, mathematical thinking
Key Learning Areas: Data analysis, Statistical modeling, Data visualization, Machine learning, Big data tools, Business intelligence
Industry Applications: Business analytics, Research, Healthcare analytics, Financial modeling, Marketing optimization
Career Relevance: High demand across industries as organizations become more data-driven''',
      
      // Culinary & Cooking
      'memasak': '''
Memasak adalah seni kuliner yang menggabungkan kreativitas, teknik, dan pengetahuan bahan untuk menciptakan makanan lezat dan bergizi.
Prerequisites: Pengetahuan dasar bahan makanan, keselamatan dapur, dan kebersihan
Key Learning Areas: Teknik memasak dasar, penggunaan bumbu, food safety, presentasi makanan, nutrisi
Industry Applications: Chef profesional, food blogger, catering business, culinary instructor
Career Relevance: Tinggi dalam industri kuliner yang terus berkembang dan content creation''',
      
      'cooking': '''
Cooking is a culinary art that combines creativity, technique, and ingredient knowledge to create delicious and nutritious food.
Prerequisites: Basic knowledge of ingredients, kitchen safety, and hygiene
Key Learning Areas: Basic cooking techniques, seasoning, food safety, food presentation, nutrition
Industry Applications: Professional chef, food blogger, catering business, culinary instructor
Career Relevance: High in the growing culinary industry and content creation''',
      
      // Fitness & Sports
      'olahraga': '''
Olahraga dan fitness adalah aktivitas fisik yang meningkatkan kesehatan, kekuatan, dan kesejahteraan mental.
Prerequisites: Pemahaman dasar kondisi kesehatan, motivasi konsisten, dan komitmen jangka panjang
Key Learning Areas: Exercise techniques, nutrition, recovery, injury prevention, goal setting
Industry Applications: Personal trainer, fitness instructor, sports coach, wellness consultant
Career Relevance: Tinggi dengan meningkatnya kesadaran kesehatan masyarakat''',
      
      'fitness': '''
Fitness and sports are physical activities that improve health, strength, and mental well-being.
Prerequisites: Basic understanding of health condition, consistent motivation, and long-term commitment
Key Learning Areas: Exercise techniques, nutrition, recovery, injury prevention, goal setting
Industry Applications: Personal trainer, fitness instructor, sports coach, wellness consultant
Career Relevance: High with increasing public health awareness''',
      
      // Arts & Design
      'seni': '''
Seni adalah ekspresi kreatif yang menggunakan berbagai medium untuk menyampaikan ide, emosi, dan keindahan.
Prerequisites: Kreativitas, kesabaran, dan apresiasi terhadap estetika visual
Key Learning Areas: Drawing techniques, color theory, composition, digital tools, art history
Industry Applications: Graphic designer, illustrator, concept artist, art director
Career Relevance: Tinggi dalam industri kreatif, advertising, dan media digital''',
      
      'art': '''
Art is creative expression using various mediums to convey ideas, emotions, and beauty.
Prerequisites: Creativity, patience, and appreciation for visual aesthetics
Key Learning Areas: Drawing techniques, color theory, composition, digital tools, art history
Industry Applications: Graphic designer, illustrator, concept artist, art director
Career Relevance: High in creative industries, advertising, and digital media''',
      
      // Business & Finance
      'bisnis': '''
Bisnis adalah kegiatan ekonomi yang melibatkan produksi, distribusi, dan penjualan barang atau jasa untuk mencapai keuntungan.
Prerequisites: Pemahaman dasar matematika, komunikasi yang baik, dan mindset entrepreneurial
Key Learning Areas: Business planning, financial management, marketing, leadership, operations
Industry Applications: Entrepreneur, business manager, consultant, financial advisor
Career Relevance: Universal - berlaku di semua industri dan sektor ekonomi''',
      
      'business': '''
Business is economic activity involving the production, distribution, and sale of goods or services to achieve profit.
Prerequisites: Basic mathematics understanding, good communication skills, and entrepreneurial mindset
Key Learning Areas: Business planning, financial management, marketing, leadership, operations
Industry Applications: Entrepreneur, business manager, consultant, financial advisor
Career Relevance: Universal - applicable across all industries and economic sectors''',
      
      // Music
      'musik': '''
Musik adalah seni suara yang menggabungkan melodi, harmoni, dan ritme untuk menciptakan ekspresi artistik dan emosional.
Prerequisites: Apresiasi musik, kesabaran untuk latihan, dan pendengaran yang baik
Key Learning Areas: Music theory, instrument techniques, composition, recording, performance
Industry Applications: Musician, music teacher, composer, sound engineer, music therapist
Career Relevance: Tinggi dalam industri entertainment, pendidikan, dan terapi''',
      
      'music': '''
Music is the art of sound that combines melody, harmony, and rhythm to create artistic and emotional expression.
Prerequisites: Music appreciation, patience for practice, and good hearing
Key Learning Areas: Music theory, instrument techniques, composition, recording, performance
Industry Applications: Musician, music teacher, composer, sound engineer, music therapist
Career Relevance: High in entertainment, education, and therapy industries''',
    };
    
    // Check for partial matches
    for (final key in contextMap.keys) {
      if (topicLower.contains(key) || key.contains(topicLower)) {
        return contextMap[key]!;
      }
    }
    
    // Generic context for any learning topic - Universal Learning Support
    return '''
This topic represents an area of knowledge that can be learned through structured, progressive learning and practical application.
Prerequisites: Varies based on topic complexity - basic curiosity and willingness to learn are the main requirements
Key Learning Areas: Fundamental concepts, practical applications, best practices, real-world implementation, skill development
Industry Applications: Learning any skill can open new opportunities for personal growth, career advancement, or hobby development
Career Relevance: Continuous learning and skill development are essential for personal fulfillment and professional growth in any field''';
  }

  String _generateLearningPhases(int durationDays) {
    if (durationDays <= 3) {
      return '''
Phase 1 (Days 1-$durationDays): Intensive Fundamentals
- Focus on core concepts and basic understanding
- Establish foundation knowledge
- Introduce essential terminology and concepts''';
    } else if (durationDays <= 7) {
      final midPoint = (durationDays / 2).ceil();
      return '''
Phase 1 (Days 1-$midPoint): Foundation Building
- Core concepts and fundamental principles
- Essential terminology and basic understanding
- Simple practical examples

Phase 2 (Days ${midPoint + 1}-$durationDays): Application & Practice
- Practical application of learned concepts
- Hands-on exercises and real-world examples
- Integration of knowledge and skill building''';
    } else if (durationDays <= 14) {
      final firstPhase = (durationDays * 0.4).ceil();
      final secondPhase = (durationDays * 0.7).ceil();
      return '''
Phase 1 (Days 1-$firstPhase): Foundation & Fundamentals
- Core concepts and basic principles
- Essential vocabulary and terminology
- Simple examples and introductory exercises

Phase 2 (Days ${firstPhase + 1}-$secondPhase): Skill Development
- Intermediate concepts and techniques
- Practical applications and hands-on practice
- Building confidence through guided exercises

Phase 3 (Days ${secondPhase + 1}-$durationDays): Advanced Application
- Complex scenarios and real-world applications
- Integration of multiple concepts
- Independent practice and problem-solving''';
    } else {
      final firstPhase = (durationDays * 0.3).ceil();
      final secondPhase = (durationDays * 0.6).ceil();
      final thirdPhase = (durationDays * 0.85).ceil();
      return '''
Phase 1 (Days 1-$firstPhase): Foundation & Core Concepts
- Fundamental principles and basic understanding
- Essential terminology and key concepts
- Simple examples and basic exercises

Phase 2 (Days ${firstPhase + 1}-$secondPhase): Skill Building & Practice
- Intermediate concepts and practical techniques
- Hands-on exercises and guided practice
- Building proficiency through repetition

Phase 3 (Days ${secondPhase + 1}-$thirdPhase): Advanced Topics & Integration
- Complex concepts and advanced techniques
- Real-world applications and case studies
- Integration of multiple skills and concepts

Phase 4 (Days ${thirdPhase + 1}-$durationDays): Mastery & Specialization
- Advanced problem-solving and optimization
- Specialized topics and industry best practices
- Portfolio development and practical projects''';
    }
  }

  String _getExperienceLevelDescription(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Complete beginner - needs foundational concepts and step-by-step guidance';
      case ExperienceLevel.intermediate:
        return 'Some experience - can handle moderate complexity and build on existing knowledge';
      case ExperienceLevel.advanced:
        return 'Experienced learner - ready for advanced concepts and complex challenges';
    }
  }

  String _getLearningStyleDescription(LearningStyle style) {
    switch (style) {
      case LearningStyle.visual:
        return 'Visual learner - prefers diagrams, videos, infographics, and visual demonstrations';
      case LearningStyle.auditory:
        return 'Auditory learner - prefers podcasts, lectures, discussions, and audio content';
      case LearningStyle.kinesthetic:
        return 'Hands-on learner - prefers practical exercises, labs, coding, and interactive activities';
      case LearningStyle.readingWriting:
        return 'Reading/Writing learner - prefers articles, books, documentation, and written exercises';
    }
  }

  Map<String, dynamic>? _parseGeneratedResponse(String generatedText, int durationDays) {
    try {
      // Enhanced text cleaning with multiple strategies
      String cleanedText = generatedText.trim();
      
      if (EnvConfig.isDebugMode) {
        print('Raw AI response length: ${cleanedText.length}');
        print('First 200 chars: ${cleanedText.substring(0, cleanedText.length > 200 ? 200 : cleanedText.length)}');
      }
      
      // Remove markdown code blocks and any extra text
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
      
      // Find JSON object boundaries with better detection
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedText = cleanedText.substring(jsonStart, jsonEnd + 1);
      }
      
      // Additional cleaning for common AI response issues
      cleanedText = cleanedText
          .replaceAll(RegExp(r'^\s*Here.*?:\s*', multiLine: true), '') // Remove "Here is the JSON:" type prefixes
          .replaceAll(RegExp(r'^\s*```.*?\n', multiLine: true), '') // Remove remaining code block markers
          .replaceAll(RegExp(r'\n\s*```\s*$', multiLine: true), '') // Remove trailing code block markers
          .trim();
      
      if (EnvConfig.isDebugMode) {
        print('Cleaned text length: ${cleanedText.length}');
        print('Attempting to parse JSON...');
      }
      
      // Parse JSON with better error handling
      final parsed = jsonDecode(cleanedText) as Map<String, dynamic>;
      
      if (EnvConfig.isDebugMode) {
        print('JSON parsed successfully');
        print('Keys found: ${parsed.keys.toList()}');
      }
      
      // Enhanced validation and structure fixing
      if (!parsed.containsKey('description') || parsed['description'] == null || parsed['description'].toString().trim().isEmpty) {
        parsed['description'] = 'A comprehensive, structured learning path designed to help you master your chosen topic through progressive, hands-on learning experiences.';
      }
      
      if (!parsed.containsKey('daily_tasks') || parsed['daily_tasks'] is! List) {
        throw Exception('Invalid response format: missing or invalid daily_tasks array');
      }

      final dailyTasksList = parsed['daily_tasks'] as List;
      
      if (EnvConfig.isDebugMode) {
        print('Found ${dailyTasksList.length} daily tasks');
      }
      
      // Enhanced task validation and enrichment
      for (int i = 0; i < dailyTasksList.length; i++) {
        final task = dailyTasksList[i] as Map<String, dynamic>;
        
        // Ensure all required fields exist with meaningful defaults
        task['main_topic'] ??= 'Day ${i + 1} Learning Focus';
        task['sub_topic'] ??= 'Essential concepts and practical skills for day ${i + 1}';
        task['material_title'] ??= 'Learning Resource for ${task['main_topic']}';
        
        // Improve material URL with better fallbacks
        if (task['material_url'] == null || task['material_url'].toString().trim().isEmpty) {
          final searchQuery = Uri.encodeComponent('${task['main_topic']} ${task['sub_topic']} tutorial');
          task['material_url'] = 'https://www.google.com/search?q=$searchQuery';
        }
        
        // Validate and improve exercise content
        if (task['exercise'] != null && task['exercise'].toString().trim().isEmpty) {
          task['exercise'] = null; // Convert empty strings to null for consistency
        }
        
        // Ensure content quality by checking minimum lengths
        if (task['sub_topic'].toString().length < 10) {
          task['sub_topic'] = 'Comprehensive study of ${task['main_topic']} with practical applications and hands-on exercises';
        }
        
        if (task['material_title'].toString().length < 5) {
          task['material_title'] = 'Essential Guide to ${task['main_topic']}';
        }
      }
      
      // Smart task count adjustment with content preservation
      if (dailyTasksList.length < durationDays) {
        if (EnvConfig.isDebugMode) {
          print('Expanding ${dailyTasksList.length} tasks to $durationDays days');
        }
        
        // Intelligent task expansion
        while (dailyTasksList.length < durationDays) {
          final sourceIndex = (dailyTasksList.length - 1) % dailyTasksList.length;
          final sourceTask = Map<String, dynamic>.from(dailyTasksList[sourceIndex]);
          
          // Create meaningful variations for extended tasks
          final dayNumber = dailyTasksList.length + 1;
          sourceTask['main_topic'] = '${sourceTask['main_topic']} - Advanced Practice';
          sourceTask['sub_topic'] = 'Advanced application and reinforcement of ${sourceTask['main_topic'].toString().replaceAll(' - Advanced Practice', '')} concepts';
          sourceTask['material_title'] = 'Advanced ${sourceTask['material_title']}';
          
          if (sourceTask['exercise'] != null) {
            sourceTask['exercise'] = 'Extended practice: ${sourceTask['exercise']}';
          }
          
          dailyTasksList.add(sourceTask);
        }
      } else if (dailyTasksList.length > durationDays) {
        if (EnvConfig.isDebugMode) {
          print('Trimming ${dailyTasksList.length} tasks to $durationDays days');
        }
        // Trim excess tasks while preserving the most important ones
        parsed['daily_tasks'] = dailyTasksList.take(durationDays).toList();
      }
      
      // Validate project recommendations if present
      if (parsed.containsKey('project_recommendations') && parsed['project_recommendations'] is List) {
        final projects = parsed['project_recommendations'] as List;
        for (int i = 0; i < projects.length; i++) {
          final project = projects[i] as Map<String, dynamic>;
          project['title'] ??= 'Project ${i + 1}';
          project['description'] ??= 'A practical project to apply your learning';
          project['difficulty'] ??= 'intermediate';
          project['estimated_hours'] ??= 20;
        }
      }

      if (EnvConfig.isDebugMode) {
        print('Successfully processed learning path with ${(parsed['daily_tasks'] as List).length} tasks');
      }

      return parsed;
    } catch (e) {
      if (EnvConfig.isDebugMode) {
        print('Error parsing generated response: $e');
        print('Generated text (first 500 chars): ${generatedText.substring(0, generatedText.length > 500 ? 500 : generatedText.length)}');
        print('Stack trace: ${StackTrace.current}');
      }
      return null;
    }
  }

  // Enhanced fallback method with topic-specific, high-quality content
  Map<String, dynamic> createFallbackLearningPath({
    required String topic,
    required int durationDays,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
    ExperienceLevel? experienceLevel,
    LearningStyle? learningStyle,
  }) {
    final dailyTasks = <Map<String, dynamic>>[];
    final topicData = _getTopicSpecificData(topic.toLowerCase());
    
    // Create progressive learning structure
    final phases = _createLearningPhases(topicData, durationDays);
    
    for (int i = 1; i <= durationDays; i++) {
      final phaseIndex = ((i - 1) / (durationDays / phases.length)).floor().clamp(0, phases.length - 1);
      final phase = phases[phaseIndex];
      final dayInPhase = (i - 1) % (durationDays / phases.length).ceil();
      
      final task = phase['tasks'][dayInPhase % phase['tasks'].length];
      
      dailyTasks.add({
        'main_topic': phase['name'],
        'sub_topic': task['topic'],
        'material_url': task['url'],
        'material_title': task['title'],
        'exercise': includeExercises ? task['exercise'] : null,
      });
    }

    final result = <String, dynamic>{
      'description': topicData['description'].replaceAll('{goal}', outputGoal),
      'daily_tasks': dailyTasks,
    };

    if (includeProjects) {
      result['project_recommendations'] = topicData['projects'];
    }

    // Enhance fallback content with quality service if parameters are provided
    if (experienceLevel != null && learningStyle != null) {
      return ContentQualityService.validateAndEnhanceContent(
        result,
        topic,
        durationDays,
        experienceLevel,
        learningStyle,
      );
    }

    return result;
  }

  Map<String, dynamic> _getTopicSpecificData(String topic) {
    // Universal topic-specific data with real resources for any subject
    final topicMap = {
      'flutter': {
        'description': 'Master Flutter development from fundamentals to production-ready apps. Learn to build beautiful, performant cross-platform mobile applications using Google\'s modern UI toolkit and achieve: {goal}',
        'phases': [
          {
            'name': 'Flutter Fundamentals & Dart Mastery',
            'tasks': [
              {'topic': 'Dart Language Fundamentals', 'title': 'Complete Dart Language Tour - Variables, Functions, and Classes', 'url': 'https://dart.dev/language', 'exercise': 'Create a Dart program with classes, inheritance, and mixins to model a library system'},
              {'topic': 'Flutter Development Environment', 'title': 'Flutter Installation and IDE Setup Guide', 'url': 'https://docs.flutter.dev/get-started/install', 'exercise': 'Set up Flutter development environment and create your first "Hello World" app'},
              {'topic': 'Widget System Architecture', 'title': 'Understanding Flutter\'s Widget Tree and Composition', 'url': 'https://docs.flutter.dev/ui/widgets-intro', 'exercise': 'Build a profile card using StatelessWidget with proper widget composition'},
              {'topic': 'Layout System Mastery', 'title': 'Flutter Layout Widgets - Row, Column, Stack, and Flex', 'url': 'https://docs.flutter.dev/ui/layout', 'exercise': 'Create a responsive Instagram-like post layout using various layout widgets'},
              {'topic': 'Styling and Theming', 'title': 'Material Design and Custom Styling in Flutter', 'url': 'https://docs.flutter.dev/ui/design', 'exercise': 'Design a custom theme and apply consistent styling across multiple screens'},
            ]
          },
          {
            'name': 'State Management & User Interaction',
            'tasks': [
              {'topic': 'StatefulWidget Lifecycle', 'title': 'Understanding Widget Lifecycle and State Management', 'url': 'https://docs.flutter.dev/ui/interactivity', 'exercise': 'Build an interactive shopping cart with add/remove functionality and real-time total calculation'},
              {'topic': 'Advanced State Patterns', 'title': 'Provider Pattern for State Management', 'url': 'https://pub.dev/packages/provider', 'exercise': 'Refactor shopping cart to use Provider for global state management'},
              {'topic': 'Navigation Architecture', 'title': 'Navigation 2.0 and Route Management', 'url': 'https://docs.flutter.dev/ui/navigation', 'exercise': 'Implement nested navigation with bottom tabs and modal screens'},
              {'topic': 'Form Handling & Validation', 'title': 'Building Robust Forms with Validation', 'url': 'https://docs.flutter.dev/cookbook/forms', 'exercise': 'Create a multi-step registration form with real-time validation and error handling'},
              {'topic': 'Animations & Transitions', 'title': 'Flutter Animation Framework and Custom Transitions', 'url': 'https://docs.flutter.dev/ui/animations', 'exercise': 'Add smooth page transitions and micro-interactions to enhance user experience'},
            ]
          },
          {
            'name': 'Data Integration & Advanced Features',
            'tasks': [
              {'topic': 'HTTP Networking', 'title': 'REST API Integration and HTTP Client', 'url': 'https://docs.flutter.dev/cookbook/networking/fetch-data', 'exercise': 'Integrate with a public API to fetch and display dynamic data with loading states'},
              {'topic': 'Local Data Persistence', 'title': 'SQLite Database and Shared Preferences', 'url': 'https://docs.flutter.dev/cookbook/persistence', 'exercise': 'Implement offline data storage with SQLite for user preferences and cached data'},
              {'topic': 'Platform Integration', 'title': 'Native Platform Features and Plugins', 'url': 'https://docs.flutter.dev/platform-integration', 'exercise': 'Access device camera, location, and notifications using platform-specific plugins'},
              {'topic': 'Performance Optimization', 'title': 'Flutter Performance Best Practices', 'url': 'https://docs.flutter.dev/perf', 'exercise': 'Profile and optimize app performance using Flutter DevTools and best practices'},
              {'topic': 'Testing & Quality Assurance', 'title': 'Unit, Widget, and Integration Testing', 'url': 'https://docs.flutter.dev/testing', 'exercise': 'Write comprehensive tests for your app including unit tests, widget tests, and integration tests'},
            ]
          }
        ],
        'projects': [
          {'title': 'Personal Expense Tracker', 'description': 'Build a comprehensive expense tracking app with categories, charts, and budget management using SQLite and Provider', 'difficulty': 'beginner', 'estimated_hours': 18},
          {'title': 'Social Media Dashboard', 'description': 'Create a multi-platform social media client with real-time updates, image sharing, and push notifications', 'difficulty': 'intermediate', 'estimated_hours': 35},
          {'title': 'E-commerce Marketplace', 'description': 'Develop a full-featured marketplace app with user authentication, payment integration, real-time chat, and admin panel', 'difficulty': 'advanced', 'estimated_hours': 60}
        ]
      },
      'python': {
        'description': 'Master Python programming from core fundamentals to advanced applications. Learn the most versatile and in-demand programming language for web development, data science, automation, and AI, and achieve: {goal}',
        'phases': [
          {
            'name': 'Python Core Fundamentals',
            'tasks': [
              {'topic': 'Python Environment & Syntax', 'title': 'Python Installation, IDLE, and Basic Syntax Mastery', 'url': 'https://docs.python.org/3/tutorial/interpreter.html', 'exercise': 'Set up Python environment and write programs using variables, operators, and basic I/O operations'},
              {'topic': 'Data Types & String Manipulation', 'title': 'Python Data Types, Strings, and Formatting', 'url': 'https://docs.python.org/3/tutorial/introduction.html', 'exercise': 'Create a text processing program that manipulates strings, formats output, and handles different data types'},
              {'topic': 'Control Structures & Logic', 'title': 'Conditional Statements, Loops, and Program Flow', 'url': 'https://docs.python.org/3/tutorial/controlflow.html', 'exercise': 'Build a number guessing game with input validation, loops, and conditional logic'},
              {'topic': 'Functions & Modular Programming', 'title': 'Function Definition, Parameters, and Scope', 'url': 'https://docs.python.org/3/tutorial/controlflow.html#defining-functions', 'exercise': 'Create a calculator module with multiple functions for different mathematical operations'},
              {'topic': 'Data Structures Mastery', 'title': 'Lists, Dictionaries, Sets, and Tuples', 'url': 'https://docs.python.org/3/tutorial/datastructures.html', 'exercise': 'Build a student grade management system using various data structures'},
            ]
          },
          {
            'name': 'Object-Oriented Programming & Libraries',
            'tasks': [
              {'topic': 'Classes & Object Design', 'title': 'Object-Oriented Programming Principles in Python', 'url': 'https://docs.python.org/3/tutorial/classes.html', 'exercise': 'Design and implement a library management system with classes, inheritance, and encapsulation'},
              {'topic': 'File Handling & Exception Management', 'title': 'File I/O Operations and Error Handling', 'url': 'https://docs.python.org/3/tutorial/inputoutput.html', 'exercise': 'Create a log file analyzer that reads, processes, and handles various file formats with proper error handling'},
              {'topic': 'Standard Library Exploration', 'title': 'Python Standard Library - datetime, os, sys, json', 'url': 'https://docs.python.org/3/library/', 'exercise': 'Build a file organizer tool that uses multiple standard library modules'},
              {'topic': 'Third-Party Libraries', 'title': 'Package Management with pip and Popular Libraries', 'url': 'https://packaging.python.org/tutorials/installing-packages/', 'exercise': 'Install and use requests library to build a weather information fetcher'},
              {'topic': 'Data Analysis Fundamentals', 'title': 'Introduction to NumPy and Pandas for Data Manipulation', 'url': 'https://pandas.pydata.org/docs/getting_started/intro_tutorials/', 'exercise': 'Analyze a CSV dataset using Pandas to generate insights and visualizations'},
            ]
          },
          {
            'name': 'Advanced Applications & Frameworks',
            'tasks': [
              {'topic': 'Web Development with Flask', 'title': 'Building Web Applications with Flask Framework', 'url': 'https://flask.palletsprojects.com/tutorial/', 'exercise': 'Create a personal blog web application with user authentication and database integration'},
              {'topic': 'Database Integration', 'title': 'SQLite and Database Operations in Python', 'url': 'https://docs.python.org/3/library/sqlite3.html', 'exercise': 'Build a contact management system with full CRUD operations using SQLite'},
              {'topic': 'API Development & Testing', 'title': 'RESTful API Creation and Testing with Flask-RESTful', 'url': 'https://flask-restful.readthedocs.io/', 'exercise': 'Develop and test a complete REST API for a task management system'},
              {'topic': 'Automation & Scripting', 'title': 'Python for Automation and System Administration', 'url': 'https://automatetheboringstuff.com/', 'exercise': 'Create automation scripts for file management, email sending, and system monitoring'},
              {'topic': 'Testing & Code Quality', 'title': 'Unit Testing with pytest and Code Quality Tools', 'url': 'https://docs.pytest.org/en/stable/', 'exercise': 'Write comprehensive tests for your applications and implement code quality checks'},
            ]
          }
        ],
        'projects': [
          {'title': 'Personal Budget Manager', 'description': 'Build a comprehensive budget tracking application with expense categorization, reporting, and data visualization using Pandas and Matplotlib', 'difficulty': 'beginner', 'estimated_hours': 20},
          {'title': 'Web Scraping Analytics Dashboard', 'description': 'Create an automated web scraping system with data analysis, visualization dashboard, and scheduled reports using BeautifulSoup and Flask', 'difficulty': 'intermediate', 'estimated_hours': 35},
          {'title': 'Machine Learning Prediction System', 'description': 'Develop an end-to-end ML pipeline with data preprocessing, model training, evaluation, and deployment using scikit-learn and Flask API', 'difficulty': 'advanced', 'estimated_hours': 50}
        ]
      },
      'javascript': {
        'description': 'Master JavaScript from core fundamentals to modern full-stack development. Learn the language that powers the web, from interactive front-end experiences to server-side applications, and achieve: {goal}',
        'phases': [
          {
            'name': 'JavaScript Core & DOM Mastery',
            'tasks': [
              {'topic': 'JavaScript Fundamentals & Syntax', 'title': 'Variables, Data Types, and Operators in Modern JavaScript', 'url': 'https://developer.mozilla.org/en-US/docs/Learn/JavaScript/First_steps', 'exercise': 'Create a personal calculator with memory functions using proper variable scoping and data type handling'},
              {'topic': 'Functions & Scope Management', 'title': 'Function Declarations, Expressions, and Arrow Functions', 'url': 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Functions', 'exercise': 'Build a utility library with various function types, closures, and higher-order functions'},
              {'topic': 'DOM Manipulation & Events', 'title': 'Document Object Model and Event Handling', 'url': 'https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Client-side_web_APIs/Manipulating_documents', 'exercise': 'Create an interactive to-do list with add, edit, delete, and filter functionality'},
              {'topic': 'Arrays & Object Manipulation', 'title': 'Advanced Array Methods and Object Operations', 'url': 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array', 'exercise': 'Build a student grade book with sorting, filtering, and statistical calculations'},
              {'topic': 'Error Handling & Debugging', 'title': 'Exception Handling and Debugging Techniques', 'url': 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Control_flow_and_error_handling', 'exercise': 'Implement robust error handling in a form validation system with user-friendly error messages'},
            ]
          },
          {
            'name': 'Asynchronous Programming & Modern Features',
            'tasks': [
              {'topic': 'Promises & Async/Await', 'title': 'Asynchronous JavaScript - Promises and Async Functions', 'url': 'https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Asynchronous', 'exercise': 'Create a weather dashboard that fetches data from multiple APIs with proper error handling'},
              {'topic': 'ES6+ Modern Syntax', 'title': 'Modern JavaScript Features - Destructuring, Modules, Classes', 'url': 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide', 'exercise': 'Refactor existing code to use modern ES6+ features including modules, classes, and destructuring'},
              {'topic': 'Fetch API & HTTP Requests', 'title': 'Making HTTP Requests and Handling Responses', 'url': 'https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API', 'exercise': 'Build a news aggregator that fetches from multiple sources with loading states and error handling'},
              {'topic': 'Local Storage & Browser APIs', 'title': 'Browser Storage and Web APIs', 'url': 'https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API', 'exercise': 'Create a note-taking app with local storage, search functionality, and data persistence'},
              {'topic': 'Module System & Build Tools', 'title': 'JavaScript Modules and Modern Build Pipeline', 'url': 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules', 'exercise': 'Set up a modular project structure with webpack or Vite and implement code splitting'},
            ]
          },
          {
            'name': 'Framework Development & Advanced Concepts',
            'tasks': [
              {'topic': 'React Component Architecture', 'title': 'React Fundamentals - Components, Props, and JSX', 'url': 'https://react.dev/learn', 'exercise': 'Build a reusable component library with proper prop validation and documentation'},
              {'topic': 'State Management & Hooks', 'title': 'React Hooks and State Management Patterns', 'url': 'https://react.dev/reference/react', 'exercise': 'Create a shopping cart application using useState, useEffect, and custom hooks'},
              {'topic': 'Routing & Navigation', 'title': 'Client-Side Routing with React Router', 'url': 'https://reactrouter.com/docs/', 'exercise': 'Implement multi-page navigation with protected routes and dynamic routing'},
              {'topic': 'API Integration & Data Flow', 'title': 'Connecting React to REST APIs and Managing Data', 'url': 'https://react.dev/learn/synchronizing-with-effects', 'exercise': 'Build a blog application with CRUD operations, pagination, and real-time updates'},
              {'topic': 'Testing & Performance', 'title': 'Testing React Applications and Performance Optimization', 'url': 'https://testing-library.com/docs/react-testing-library/intro/', 'exercise': 'Write comprehensive tests and optimize application performance using React DevTools'},
            ]
          }
        ],
        'projects': [
          {'title': 'Personal Portfolio Website', 'description': 'Build a responsive portfolio website with interactive animations, contact forms, and project showcases using vanilla JavaScript and modern CSS', 'difficulty': 'beginner', 'estimated_hours': 25},
          {'title': 'Task Management Dashboard', 'description': 'Create a full-featured project management tool with React, including drag-and-drop functionality, real-time collaboration, and data visualization', 'difficulty': 'intermediate', 'estimated_hours': 40},
          {'title': 'Real-time Social Media Platform', 'description': 'Develop a complete social media application with React, Node.js, WebSocket integration, user authentication, and real-time messaging', 'difficulty': 'advanced', 'estimated_hours': 65}
        ]
      },
      
      'react': {
        'description': 'Master React development from fundamentals to advanced patterns. Build modern, scalable web applications using the most popular JavaScript library and achieve: {goal}',
        'phases': [
          {
            'name': 'React Fundamentals & Component Architecture',
            'tasks': [
              {'topic': 'React Setup & JSX Mastery', 'title': 'React Environment Setup and JSX Syntax Deep Dive', 'url': 'https://react.dev/learn/installation', 'exercise': 'Set up React development environment and create interactive components using JSX with proper syntax and best practices'},
              {'topic': 'Component Design Patterns', 'title': 'Functional Components, Props, and Component Composition', 'url': 'https://react.dev/learn/passing-props-to-a-component', 'exercise': 'Build a reusable card component library with various layouts and prop configurations'},
              {'topic': 'State Management Fundamentals', 'title': 'useState Hook and State Management Principles', 'url': 'https://react.dev/learn/state-a-components-memory', 'exercise': 'Create an interactive form with multiple input types, validation, and dynamic state updates'},
              {'topic': 'Event Handling & User Interaction', 'title': 'Event Handling Patterns and User Input Management', 'url': 'https://react.dev/learn/responding-to-events', 'exercise': 'Build a dynamic calculator with keyboard support and comprehensive event handling'},
              {'topic': 'Conditional Rendering & Lists', 'title': 'Dynamic Content Rendering and List Management', 'url': 'https://react.dev/learn/conditional-rendering', 'exercise': 'Create a filterable product catalog with search, sorting, and category filtering'},
            ]
          },
          {
            'name': 'Advanced Hooks & State Management',
            'tasks': [
              {'topic': 'useEffect & Lifecycle Management', 'title': 'Side Effects and Component Lifecycle with useEffect', 'url': 'https://react.dev/learn/synchronizing-with-effects', 'exercise': 'Build a real-time clock with timezone support and cleanup on component unmount'},
              {'topic': 'Custom Hooks Development', 'title': 'Creating Reusable Logic with Custom Hooks', 'url': 'https://react.dev/learn/reusing-logic-with-custom-hooks', 'exercise': 'Develop custom hooks for API calls, local storage, and form validation'},
              {'topic': 'Context API & Global State', 'title': 'React Context for State Management Across Components', 'url': 'https://react.dev/learn/passing-data-deeply-with-context', 'exercise': 'Implement a theme system and user authentication context across the entire application'},
              {'topic': 'Performance Optimization', 'title': 'React.memo, useMemo, and useCallback for Performance', 'url': 'https://react.dev/learn/render-and-commit', 'exercise': 'Optimize a data-heavy dashboard application using memoization techniques'},
              {'topic': 'Error Boundaries & Error Handling', 'title': 'Error Boundaries and Graceful Error Handling', 'url': 'https://react.dev/learn/error-boundaries', 'exercise': 'Implement comprehensive error handling with user-friendly error messages and recovery options'},
            ]
          }
        ],
        'projects': [
          {'title': 'Personal Dashboard App', 'description': 'Build a customizable personal dashboard with widgets, weather, news, and productivity tools using React hooks and context', 'difficulty': 'beginner', 'estimated_hours': 22},
          {'title': 'E-learning Platform', 'description': 'Create a comprehensive online learning platform with course management, progress tracking, and interactive quizzes', 'difficulty': 'intermediate', 'estimated_hours': 45},
          {'title': 'Collaborative Project Management Tool', 'description': 'Develop a full-featured project management application with real-time collaboration, file sharing, and advanced reporting', 'difficulty': 'advanced', 'estimated_hours': 70}
        ]
      },
      
      'node.js': {
        'description': 'Master Node.js backend development from server fundamentals to production deployment. Build scalable server-side applications and APIs using JavaScript and achieve: {goal}',
        'phases': [
          {
            'name': 'Node.js Fundamentals & Server Basics',
            'tasks': [
              {'topic': 'Node.js Environment & Modules', 'title': 'Node.js Installation, NPM, and Module System', 'url': 'https://nodejs.org/en/docs/guides/getting-started-guide/', 'exercise': 'Set up Node.js development environment and create modular applications using CommonJS and ES modules'},
              {'topic': 'File System & Path Operations', 'title': 'Working with File System and Path Modules', 'url': 'https://nodejs.org/api/fs.html', 'exercise': 'Build a file organizer tool that reads, processes, and organizes files based on type and date'},
              {'topic': 'HTTP Server & Request Handling', 'title': 'Creating HTTP Servers and Handling Requests', 'url': 'https://nodejs.org/api/http.html', 'exercise': 'Create a basic web server that serves static files and handles different HTTP methods'},
              {'topic': 'Asynchronous Programming', 'title': 'Callbacks, Promises, and Async/Await in Node.js', 'url': 'https://nodejs.org/en/docs/guides/blocking-vs-non-blocking/', 'exercise': 'Build an asynchronous file processing system with proper error handling and concurrency control'},
              {'topic': 'NPM & Package Management', 'title': 'Package Management and Dependency Handling', 'url': 'https://docs.npmjs.com/', 'exercise': 'Create and publish your own NPM package with proper versioning and documentation'},
            ]
          },
          {
            'name': 'Express.js & API Development',
            'tasks': [
              {'topic': 'Express.js Framework Setup', 'title': 'Express.js Fundamentals and Middleware', 'url': 'https://expressjs.com/en/starter/installing.html', 'exercise': 'Build a RESTful API server with Express.js including routing, middleware, and error handling'},
              {'topic': 'Database Integration', 'title': 'MongoDB and Mongoose for Data Persistence', 'url': 'https://mongoosejs.com/docs/guide.html', 'exercise': 'Integrate MongoDB database with user authentication and CRUD operations'},
              {'topic': 'Authentication & Security', 'title': 'JWT Authentication and Security Best Practices', 'url': 'https://jwt.io/introduction/', 'exercise': 'Implement secure user authentication with JWT tokens, password hashing, and role-based access control'},
              {'topic': 'API Testing & Documentation', 'title': 'API Testing with Jest and Documentation with Swagger', 'url': 'https://jestjs.io/docs/getting-started', 'exercise': 'Write comprehensive API tests and create interactive API documentation'},
              {'topic': 'Deployment & Production', 'title': 'Production Deployment and Performance Monitoring', 'url': 'https://expressjs.com/en/advanced/best-practice-performance.html', 'exercise': 'Deploy application to cloud platform with monitoring, logging, and performance optimization'},
            ]
          }
        ],
        'projects': [
          {'title': 'Blog API Backend', 'description': 'Build a complete blog backend with user management, post creation, comments, and file uploads using Express.js and MongoDB', 'difficulty': 'beginner', 'estimated_hours': 28},
          {'title': 'E-commerce API Platform', 'description': 'Create a scalable e-commerce backend with product management, order processing, payment integration, and inventory tracking', 'difficulty': 'intermediate', 'estimated_hours': 50},
          {'title': 'Real-time Collaboration Platform', 'description': 'Develop a real-time collaboration backend with WebSocket support, document sharing, live editing, and user presence tracking', 'difficulty': 'advanced', 'estimated_hours': 75}
        ]
      },
      
      // Universal Topics - Culinary Arts
      'memasak': {
        'description': 'Kuasai seni memasak dari dasar hingga teknik advanced. Pelajari cara membuat makanan lezat, sehat, dan menarik untuk keluarga atau karir kuliner dan capai: {goal}',
        'phases': [
          {
            'name': 'Dasar-Dasar Memasak',
            'tasks': [
              {'topic': 'Keselamatan Dapur & Kebersihan', 'title': 'Food Safety dan Hygiene dalam Memasak', 'url': 'https://www.google.com/search?q=food+safety+hygiene+cooking+basics', 'exercise': 'Praktik mencuci tangan, membersihkan peralatan, dan menyimpan bahan makanan dengan benar'},
              {'topic': 'Teknik Memotong Dasar', 'title': 'Cara Memotong Sayuran dan Daging dengan Benar', 'url': 'https://www.google.com/search?q=basic+knife+skills+cutting+vegetables', 'exercise': 'Latihan memotong bawang, wortel, dan kentang dengan berbagai teknik'},
              {'topic': 'Metode Memasak Fundamental', 'title': 'Teknik Merebus, Menggoreng, dan Menumis', 'url': 'https://www.google.com/search?q=basic+cooking+methods+boiling+frying', 'exercise': 'Masak nasi, tumis sayuran, dan goreng telur dengan teknik yang benar'},
              {'topic': 'Bumbu dan Rasa Dasar', 'title': 'Mengenal Bumbu Dapur dan Cara Menggunakannya', 'url': 'https://www.google.com/search?q=basic+spices+seasoning+cooking', 'exercise': 'Buat bumbu dasar untuk masakan Indonesia dan cicipi perbedaan rasa'},
            ]
          },
          {
            'name': 'Teknik Memasak Lanjutan',
            'tasks': [
              {'topic': 'Memasak Protein', 'title': 'Teknik Memasak Daging, Ikan, dan Ayam', 'url': 'https://www.google.com/search?q=cooking+meat+fish+chicken+techniques', 'exercise': 'Masak ayam bakar, ikan goreng, dan daging sapi dengan tingkat kematangan yang tepat'},
              {'topic': 'Membuat Saus dan Kuah', 'title': 'Cara Membuat Saus, Kuah, dan Kaldu', 'url': 'https://www.google.com/search?q=making+sauce+broth+cooking', 'exercise': 'Buat saus tomat, kuah soto, dan kaldu ayam dari bahan dasar'},
              {'topic': 'Teknik Memanggang', 'title': 'Memanggang dan Mengoven Makanan', 'url': 'https://www.google.com/search?q=baking+roasting+oven+cooking', 'exercise': 'Panggang kue sederhana dan roast sayuran dengan oven'},
            ]
          }
        ],
        'projects': [
          {'title': 'Menu Keluarga Sehat', 'description': 'Buat menu makanan sehat untuk keluarga selama seminggu dengan variasi protein, sayuran, dan karbohidrat', 'difficulty': 'beginner', 'estimated_hours': 15},
          {'title': 'Katering Rumahan', 'description': 'Mulai bisnis katering kecil dengan menu signature dan sistem pemesanan', 'difficulty': 'intermediate', 'estimated_hours': 30},
        ]
      },
      
      'cooking': {
        'description': 'Master the art of cooking from basics to advanced techniques. Learn to create delicious, healthy, and appealing food for family or culinary career and achieve: {goal}',
        'phases': [
          {
            'name': 'Cooking Fundamentals',
            'tasks': [
              {'topic': 'Kitchen Safety & Hygiene', 'title': 'Food Safety and Hygiene in Cooking', 'url': 'https://www.google.com/search?q=food+safety+hygiene+cooking+basics', 'exercise': 'Practice proper handwashing, equipment cleaning, and food storage techniques'},
              {'topic': 'Basic Knife Skills', 'title': 'How to Cut Vegetables and Meat Properly', 'url': 'https://www.google.com/search?q=basic+knife+skills+cutting+vegetables', 'exercise': 'Practice cutting onions, carrots, and potatoes using various techniques'},
              {'topic': 'Fundamental Cooking Methods', 'title': 'Boiling, Frying, and Sautéing Techniques', 'url': 'https://www.google.com/search?q=basic+cooking+methods+boiling+frying', 'exercise': 'Cook rice, sauté vegetables, and fry eggs using proper techniques'},
              {'topic': 'Basic Seasonings and Flavors', 'title': 'Understanding Spices and How to Use Them', 'url': 'https://www.google.com/search?q=basic+spices+seasoning+cooking', 'exercise': 'Create basic spice blends and taste the difference in flavors'},
            ]
          }
        ],
        'projects': [
          {'title': 'Healthy Family Menu', 'description': 'Create a week-long healthy meal plan for family with variety of proteins, vegetables, and carbohydrates', 'difficulty': 'beginner', 'estimated_hours': 15},
        ]
      },
      
      // Fitness & Sports
      'olahraga': {
        'description': 'Kuasai olahraga dan fitness untuk kesehatan optimal. Pelajari teknik exercise, nutrisi, dan gaya hidup sehat untuk mencapai: {goal}',
        'phases': [
          {
            'name': 'Dasar-Dasar Fitness',
            'tasks': [
              {'topic': 'Pemanasan dan Pendinginan', 'title': 'Teknik Warm-up dan Cool-down yang Benar', 'url': 'https://www.google.com/search?q=proper+warm+up+cool+down+exercise', 'exercise': 'Lakukan rutinitas pemanasan 10 menit dan pendinginan 5 menit'},
              {'topic': 'Latihan Kardio Dasar', 'title': 'Cardio Training untuk Pemula', 'url': 'https://www.google.com/search?q=beginner+cardio+workout+routine', 'exercise': 'Lakukan jalan cepat 20 menit atau jogging ringan sesuai kemampuan'},
              {'topic': 'Latihan Kekuatan Bodyweight', 'title': 'Strength Training Tanpa Alat', 'url': 'https://www.google.com/search?q=bodyweight+strength+training+beginner', 'exercise': 'Lakukan push-up, squat, dan plank dengan form yang benar'},
              {'topic': 'Nutrisi untuk Olahraga', 'title': 'Pola Makan Sehat untuk Aktif Berolahraga', 'url': 'https://www.google.com/search?q=nutrition+for+exercise+healthy+eating', 'exercise': 'Buat meal plan seimbang untuk mendukung aktivitas olahraga'},
            ]
          }
        ],
        'projects': [
          {'title': 'Program Fitness Personal', 'description': 'Buat program latihan personal selama 30 hari dengan target spesifik dan tracking progress', 'difficulty': 'beginner', 'estimated_hours': 20},
        ]
      },
      
      'fitness': {
        'description': 'Master fitness and sports for optimal health. Learn exercise techniques, nutrition, and healthy lifestyle to achieve: {goal}',
        'phases': [
          {
            'name': 'Fitness Fundamentals',
            'tasks': [
              {'topic': 'Warm-up and Cool-down', 'title': 'Proper Warm-up and Cool-down Techniques', 'url': 'https://www.google.com/search?q=proper+warm+up+cool+down+exercise', 'exercise': 'Perform 10-minute warm-up and 5-minute cool-down routine'},
              {'topic': 'Basic Cardio Training', 'title': 'Cardio Training for Beginners', 'url': 'https://www.google.com/search?q=beginner+cardio+workout+routine', 'exercise': 'Do 20-minute brisk walk or light jogging according to your ability'},
              {'topic': 'Bodyweight Strength Training', 'title': 'Strength Training Without Equipment', 'url': 'https://www.google.com/search?q=bodyweight+strength+training+beginner', 'exercise': 'Perform push-ups, squats, and planks with proper form'},
            ]
          }
        ],
        'projects': [
          {'title': 'Personal Fitness Program', 'description': 'Create a 30-day personal workout program with specific goals and progress tracking', 'difficulty': 'beginner', 'estimated_hours': 20},
        ]
      },
      
      // Arts & Design
      'seni': {
        'description': 'Kuasai seni dan desain untuk ekspresi kreatif. Pelajari teknik menggambar, melukis, dan desain digital untuk mencapai: {goal}',
        'phases': [
          {
            'name': 'Dasar-Dasar Seni',
            'tasks': [
              {'topic': 'Teknik Menggambar Dasar', 'title': 'Belajar Menggambar Bentuk dan Proporsi', 'url': 'https://www.google.com/search?q=basic+drawing+techniques+shapes+proportions', 'exercise': 'Gambar bentuk geometri dasar dan objek sederhana dengan pensil'},
              {'topic': 'Teori Warna', 'title': 'Memahami Warna dan Kombinasinya', 'url': 'https://www.google.com/search?q=color+theory+basics+art', 'exercise': 'Buat color wheel dan eksplorasi kombinasi warna komplementer'},
              {'topic': 'Komposisi dan Layout', 'title': 'Prinsip Komposisi dalam Seni Visual', 'url': 'https://www.google.com/search?q=composition+principles+visual+art', 'exercise': 'Buat sketsa dengan menerapkan rule of thirds dan balance'},
            ]
          }
        ],
        'projects': [
          {'title': 'Portfolio Seni Digital', 'description': 'Buat portfolio seni digital dengan berbagai teknik dan style untuk showcase kemampuan', 'difficulty': 'beginner', 'estimated_hours': 25},
        ]
      },
      
      // Music
      'musik': {
        'description': 'Kuasai musik dan instrumen untuk ekspresi artistik. Pelajari teori musik, teknik bermain, dan komposisi untuk mencapai: {goal}',
        'phases': [
          {
            'name': 'Dasar-Dasar Musik',
            'tasks': [
              {'topic': 'Teori Musik Dasar', 'title': 'Not, Tangga Nada, dan Chord Dasar', 'url': 'https://www.google.com/search?q=basic+music+theory+notes+scales', 'exercise': 'Pelajari tangga nada C mayor dan mainkan chord C-F-G'},
              {'topic': 'Ritme dan Tempo', 'title': 'Memahami Beat, Rhythm, dan Time Signature', 'url': 'https://www.google.com/search?q=rhythm+tempo+music+basics', 'exercise': 'Latihan clapping dengan berbagai time signature dan tempo'},
              {'topic': 'Teknik Instrumen Dasar', 'title': 'Cara Memegang dan Memainkan Instrumen', 'url': 'https://www.google.com/search?q=basic+instrument+techniques+beginner', 'exercise': 'Pilih satu instrumen dan pelajari posisi dasar serta chord/scale sederhana'},
            ]
          }
        ],
        'projects': [
          {'title': 'Komposisi Musik Sederhana', 'description': 'Buat komposisi musik sederhana menggunakan software atau instrumen akustik', 'difficulty': 'beginner', 'estimated_hours': 20},
        ]
      }
    };

    // Return specific topic data or generic fallback
    return topicMap[topic] ?? _getGenericTopicData(topic);
  }

  Map<String, dynamic> _getGenericTopicData(String topic) {
    return {
      'description': 'Master $topic through a structured learning approach. Build practical skills and achieve: {goal}',
      'phases': [
        {
          'name': 'Fundamentals',
          'tasks': [
            {'topic': 'Introduction to $topic', 'title': 'Getting Started with $topic', 'url': 'https://www.google.com/search?q=$topic+tutorial', 'exercise': 'Complete introductory exercises'},
            {'topic': 'Core Concepts', 'title': 'Understanding $topic Basics', 'url': 'https://www.google.com/search?q=$topic+fundamentals', 'exercise': 'Practice basic concepts'},
            {'topic': 'Practical Applications', 'title': 'Applying $topic Knowledge', 'url': 'https://www.google.com/search?q=$topic+examples', 'exercise': 'Build a simple project'},
            {'topic': 'Best Practices', 'title': '$topic Best Practices', 'url': 'https://www.google.com/search?q=$topic+best+practices', 'exercise': 'Implement industry standards'},
          ]
        },
        {
          'name': 'Advanced Topics',
          'tasks': [
            {'topic': 'Advanced Techniques', 'title': 'Advanced $topic Concepts', 'url': 'https://www.google.com/search?q=advanced+$topic', 'exercise': 'Implement advanced features'},
            {'topic': 'Real-world Projects', 'title': '$topic Project Examples', 'url': 'https://www.google.com/search?q=$topic+projects', 'exercise': 'Build a comprehensive project'},
            {'topic': 'Optimization & Performance', 'title': 'Optimizing $topic Applications', 'url': 'https://www.google.com/search?q=$topic+optimization', 'exercise': 'Optimize existing code'},
            {'topic': 'Professional Development', 'title': 'Professional $topic Skills', 'url': 'https://www.google.com/search?q=$topic+career', 'exercise': 'Create portfolio project'},
          ]
        }
      ],
      'projects': [
        {'title': 'Beginner $topic Project', 'description': 'A foundational project to practice $topic basics', 'difficulty': 'beginner', 'estimated_hours': 15},
        {'title': 'Intermediate $topic Application', 'description': 'A practical application demonstrating $topic skills', 'difficulty': 'intermediate', 'estimated_hours': 30},
        {'title': 'Advanced $topic Portfolio Project', 'description': 'A comprehensive project showcasing $topic mastery', 'difficulty': 'advanced', 'estimated_hours': 50}
      ]
    };
  }

  List<Map<String, dynamic>> _createLearningPhases(Map<String, dynamic> topicData, int durationDays) {
    final phases = List<Map<String, dynamic>>.from(topicData['phases']);
    
    // Adjust phases based on duration
    if (durationDays <= 7) {
      return [phases.first]; // Only fundamentals for short courses
    } else if (durationDays <= 14) {
      return phases.take(2).toList(); // First two phases
    } else {
      return phases; // All phases for longer courses
    }
  }

  /// Add relevant YouTube videos to each daily task using AI-powered search
  Future<Map<String, dynamic>> _addYouTubeVideosToTasks(
    Map<String, dynamic> learningPathData,
    ExperienceLevel experienceLevel,
  ) async {
    try {
      if (EnvConfig.isDebugMode) {
        print('🎥 Adding YouTube videos to learning tasks...');
      }

      final dailyTasks = learningPathData['daily_tasks'] as List<dynamic>;
      final enhancedTasks = <Map<String, dynamic>>[];

      for (final task in dailyTasks) {
        final taskMap = Map<String, dynamic>.from(task);
        
        // Extract topic information
        final mainTopic = taskMap['main_topic'] as String;
        final subTopic = taskMap['sub_topic'] as String;
        
        // Debug: Log the topics being used for video search
        if (EnvConfig.isDebugMode) {
          print('🔍 Searching videos for:');
          print('   Main Topic: "$mainTopic"');
          print('   Sub Topic: "$subTopic"');
          print('   Experience Level: "${experienceLevel.name}"');
        }
        
        // Find relevant YouTube videos for this specific task
        final videos = await YouTubeSearchService.findRelevantVideos(
          topic: mainTopic,
          subTopic: subTopic,
          experienceLevel: experienceLevel.name,
          maxResults: 2, // Limit to 2 videos per task to avoid overwhelming
        );

        // Add videos to task
        taskMap['youtube_videos'] = videos.map((video) => video.toJson()).toList();
        
        enhancedTasks.add(taskMap);

        if (EnvConfig.isDebugMode) {
          print('📹 Added ${videos.length} videos for: $subTopic');
        }
      }

      // Update the learning path data with enhanced tasks
      final enhancedData = Map<String, dynamic>.from(learningPathData);
      enhancedData['daily_tasks'] = enhancedTasks;

      if (EnvConfig.isDebugMode) {
        print('✅ Successfully added YouTube videos to all ${enhancedTasks.length} tasks');
      }

      return enhancedData;
    } catch (e) {
      if (EnvConfig.isDebugMode) {
        print('⚠️ Error adding YouTube videos: $e');
      }
      
      // Return original data if YouTube integration fails
      return learningPathData;
    }
  }

  /// Generate YouTube-enhanced learning path with smart video recommendations
  Future<Map<String, dynamic>?> generateLearningPathWithVideos({
    required String topic,
    required int durationDays,
    required int dailyTimeMinutes,
    required ExperienceLevel experienceLevel,
    required LearningStyle learningStyle,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
    String? notes,
    String language = 'id', // Default to Indonesian
  }) async {
    // Generate the base learning path
    final baseLearningPath = await generateLearningPath(
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

    if (baseLearningPath == null) {
      return null;
    }

    // Add YouTube videos to the learning path
    return await _addYouTubeVideosToTasks(baseLearningPath, experienceLevel);
  }
}

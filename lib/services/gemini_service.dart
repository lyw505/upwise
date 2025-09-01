import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/learning_path_model.dart';
import '../core/config/env_config.dart';

class GeminiService {
  static String get _apiKey => EnvConfig.geminiApiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

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
  }) async {
    try {
      // Check if API key is configured
      if (!EnvConfig.isConfigured) {
        if (EnvConfig.isDebugMode) {
          print('Gemini API key not configured, using fallback');
        }
        return createFallbackLearningPath(
          topic: topic,
          durationDays: durationDays,
          outputGoal: outputGoal,
          includeProjects: includeProjects,
          includeExercises: includeExercises,
        );
      }

      final prompt = _buildPrompt(
        topic: topic,
        durationDays: durationDays,
        dailyTimeMinutes: dailyTimeMinutes,
        experienceLevel: experienceLevel,
        learningStyle: learningStyle,
        outputGoal: outputGoal,
        includeProjects: includeProjects,
        includeExercises: includeExercises,
        notes: notes,
      );

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
            'temperature': 0.3, // Lower temperature for more consistent JSON output
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 8192,
            'stopSequences': [],
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
          return result;
        } else {
          // If parsing failed, fall back to mock data
          throw Exception('Failed to parse AI response');
        }
      } else {
        if (EnvConfig.isDebugMode) {
          print('Gemini API error: ${response.statusCode}, using fallback');
        }
        return createFallbackLearningPath(
          topic: topic,
          durationDays: durationDays,
          outputGoal: outputGoal,
          includeProjects: includeProjects,
          includeExercises: includeExercises,
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
    final buffer = StringBuffer();

    // Enhanced prompt for better AI generation
    buffer.writeln('You are an expert learning path designer. Create a comprehensive, personalized $durationDays-day learning path for: "$topic"');
    buffer.writeln('');
    buffer.writeln('LEARNER PROFILE:');
    buffer.writeln('- Experience Level: ${_getExperienceLevelDescription(experienceLevel)}');
    buffer.writeln('- Learning Style: ${_getLearningStyleDescription(learningStyle)}');
    buffer.writeln('- Daily Time Available: $dailyTimeMinutes minutes');
    buffer.writeln('- Learning Goal: $outputGoal');
    
    if (notes != null && notes.isNotEmpty) {
      buffer.writeln('- Additional Notes: $notes');
    }
    
    buffer.writeln('');
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('1. Create a progressive learning path that builds knowledge systematically');
    buffer.writeln('2. Each day should have achievable goals within the time limit');
    buffer.writeln('3. Include diverse, high-quality learning resources');
    buffer.writeln('4. Tailor content to the specified learning style and experience level');
    buffer.writeln('5. Ensure the path leads to achieving the stated learning goal');
    buffer.writeln('6. CRITICAL: Create EXACTLY $durationDays daily tasks, one for each day of the $durationDays-day learning path');
    buffer.writeln('');
    buffer.writeln('RESPONSE FORMAT - Return ONLY valid JSON:');
    buffer.writeln('{');
    buffer.writeln('  "description": "Compelling 2-3 sentence description of what the learner will achieve",');
    buffer.writeln('  "daily_tasks": [');
    buffer.writeln('    {');
    buffer.writeln('      "main_topic": "Clear, specific main topic for the day",');
    buffer.writeln('      "sub_topic": "Focused subtopic that can be completed in the allocated time",');
    buffer.writeln('      "material_url": "Provide real, working URLs to quality resources (YouTube, documentation, tutorials)",');
    buffer.writeln('      "material_title": "Descriptive title of the recommended material",');
    
    if (includeExercises) {
      buffer.writeln('      "exercise": "Specific, actionable exercise that reinforces the day\'s learning",');
    } else {
      buffer.writeln('      "exercise": null,');
    }
    
    buffer.writeln('    }');
    buffer.writeln('  ]');
    
    if (includeProjects) {
      buffer.writeln('  "project_recommendations": [');
      buffer.writeln('    {');
      buffer.writeln('      "title": "Project title",');
      buffer.writeln('      "description": "Project description",');
      buffer.writeln('      "url": "URL to project resources (optional)",');
      buffer.writeln('      "difficulty": "beginner/intermediate/advanced",');
      buffer.writeln('      "estimated_hours": 10');
      buffer.writeln('    }');
      buffer.writeln('  ]');
    }
    
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('Guidelines:');
    buffer.writeln('- Structure the learning path progressively from basics to advanced concepts');
    buffer.writeln('- Each day should build upon previous days');
    buffer.writeln('- Consider the specified learning style when recommending materials');
    buffer.writeln('- Ensure daily tasks can be completed within the specified time limit');
    buffer.writeln('- Provide diverse and high-quality learning resources');
    buffer.writeln('- Make sure the path leads to achieving the specified output goal');
    
    if (learningStyle == LearningStyle.visual) {
      buffer.writeln('- Prioritize visual learning materials like videos, diagrams, and infographics');
    } else if (learningStyle == LearningStyle.auditory) {
      buffer.writeln('- Prioritize audio content like podcasts, lectures, and discussions');
    } else if (learningStyle == LearningStyle.kinesthetic) {
      buffer.writeln('- Prioritize hands-on activities, labs, and practical exercises');
    } else if (learningStyle == LearningStyle.readingWriting) {
      buffer.writeln('- Prioritize text-based materials like articles, books, and written exercises');
    }
    
    buffer.writeln('');
    buffer.writeln('IMPORTANT: ');
    buffer.writeln('- Return ONLY the JSON object. No markdown formatting, no explanations, no additional text.');
    buffer.writeln('- Create EXACTLY $durationDays tasks in the daily_tasks array');
    buffer.writeln('- Start your response with { and end with }.');
    
    return buffer.toString();
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
      // Clean the response to extract JSON
      String cleanedText = generatedText.trim();

      // Remove any markdown code block formatting
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      // Remove any leading/trailing whitespace and newlines
      cleanedText = cleanedText.trim();

      // Try to find JSON object boundaries if there's extra text
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedText = cleanedText.substring(jsonStart, jsonEnd + 1);
      }
      
      cleanedText = cleanedText.trim();
      
      // Parse JSON
      final parsed = jsonDecode(cleanedText) as Map<String, dynamic>;
      
      // Validate required fields
      if (!parsed.containsKey('daily_tasks') || parsed['daily_tasks'] is! List) {
        throw Exception('Invalid response format: missing daily_tasks');
      }

      // Validate correct number of tasks
      final dailyTasksList = parsed['daily_tasks'] as List;
      if (dailyTasksList.length != durationDays) {
        if (EnvConfig.isDebugMode) {
          print('Warning: AI generated ${dailyTasksList.length} tasks instead of $durationDays');
        }

        // If significantly fewer tasks, consider it an error
        if (dailyTasksList.length < (durationDays * 0.7).ceil()) {
          throw Exception('Insufficient daily tasks: got ${dailyTasksList.length}, expected $durationDays');
        }
      }

      return parsed;
    } catch (e) {
      if (EnvConfig.isDebugMode) {
        print('Error parsing generated response: $e');
        print('Generated text: $generatedText');
      }
      return null;
    }
  }

  // Fallback method to create a basic learning path if AI generation fails
  Map<String, dynamic> createFallbackLearningPath({
    required String topic,
    required int durationDays,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
  }) {
    final dailyTasks = <Map<String, dynamic>>[];

    // Create more realistic daily tasks based on common learning patterns
    final phases = _getTopicPhases(topic, durationDays);

    for (int i = 1; i <= durationDays; i++) {
      final phaseIndex = ((i - 1) / (durationDays / phases.length)).floor();
      final phase = phases[phaseIndex.clamp(0, phases.length - 1)];

      dailyTasks.add({
        'main_topic': phase['main_topic'],
        'sub_topic': phase['sub_topics'][(i - 1) % phase['sub_topics'].length],
        'material_url': _getSampleMaterialUrl(topic),
        'material_title': 'Day $i: ${phase['sub_topics'][(i - 1) % phase['sub_topics'].length]}',
        'exercise': includeExercises ? _getSampleExercise(topic, i) : null,
      });
    }

    final result = <String, dynamic>{
      'description': 'A comprehensive $durationDays-day learning path for $topic. This structured approach will help you achieve: $outputGoal',
      'daily_tasks': dailyTasks,
    };

    if (includeProjects) {
      result['project_recommendations'] = _getSampleProjects(topic);
    }

    return result;
  }

  List<Map<String, dynamic>> _getTopicPhases(String topic, int durationDays) {
    // Generic learning phases that work for most topics
    if (durationDays <= 7) {
      return [
        {
          'main_topic': 'Fundamentals',
          'sub_topics': ['Introduction and Overview', 'Basic Concepts', 'Core Principles', 'Getting Started', 'First Steps', 'Foundation Building', 'Key Terminology']
        }
      ];
    } else if (durationDays <= 21) {
      return [
        {
          'main_topic': 'Fundamentals',
          'sub_topics': ['Introduction and Overview', 'Basic Concepts', 'Core Principles', 'Getting Started', 'Foundation Building']
        },
        {
          'main_topic': 'Intermediate Concepts',
          'sub_topics': ['Advanced Techniques', 'Practical Applications', 'Real-world Examples', 'Problem Solving', 'Best Practices']
        }
      ];
    } else {
      return [
        {
          'main_topic': 'Fundamentals',
          'sub_topics': ['Introduction and Overview', 'Basic Concepts', 'Core Principles', 'Getting Started']
        },
        {
          'main_topic': 'Intermediate Concepts',
          'sub_topics': ['Advanced Techniques', 'Practical Applications', 'Real-world Examples', 'Problem Solving']
        },
        {
          'main_topic': 'Advanced Topics',
          'sub_topics': ['Expert Techniques', 'Optimization', 'Advanced Patterns', 'Industry Standards']
        },
        {
          'main_topic': 'Mastery & Application',
          'sub_topics': ['Project Development', 'Portfolio Building', 'Professional Practice', 'Continuous Learning']
        }
      ];
    }
  }

  String? _getSampleMaterialUrl(String topic) {
    // Return null for now, but could be enhanced with actual URLs
    return null;
  }

  String _getSampleExercise(String topic, int day) {
    final exercises = [
      'Complete the introductory exercises',
      'Practice the concepts learned today',
      'Build a small example project',
      'Solve practice problems',
      'Create a mini-project',
      'Review and reinforce concepts',
      'Apply knowledge to real scenarios',
    ];
    return exercises[(day - 1) % exercises.length];
  }

  List<Map<String, dynamic>> _getSampleProjects(String topic) {
    return [
      {
        'title': 'Beginner $topic Project',
        'description': 'A starter project to apply basic $topic concepts and build confidence',
        'url': null,
        'difficulty': 'beginner',
        'estimated_hours': 10,
      },
      {
        'title': 'Intermediate $topic Application',
        'description': 'A more complex project that demonstrates practical $topic skills',
        'url': null,
        'difficulty': 'intermediate',
        'estimated_hours': 25,
      },
      {
        'title': 'Advanced $topic Portfolio Project',
        'description': 'A comprehensive project showcasing advanced $topic mastery',
        'url': null,
        'difficulty': 'advanced',
        'estimated_hours': 40,
      }
    ];
  }
}

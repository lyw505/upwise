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
    final experienceDesc = _getExperienceLevelDescription(experienceLevel);
    final styleDesc = _getLearningStyleDescription(learningStyle);
    
    return '''
Create a $durationDays-day learning path for "$topic" (${experienceDesc.toLowerCase()}, ${styleDesc.toLowerCase()}, $dailyTimeMinutes min/day).

Goal: $outputGoal
${notes != null && notes.isNotEmpty ? 'Notes: $notes' : ''}

Requirements:
- Progressive structure from basics to advanced
- Each day builds on previous knowledge  
- Realistic goals for $dailyTimeMinutes minutes daily
- High-quality, specific learning resources
- Practical, actionable content

Return ONLY this JSON structure with EXACTLY $durationDays daily tasks:

{
  "description": "Compelling 2-3 sentence overview of what learner will master and achieve",
  "daily_tasks": [
    {
      "main_topic": "Specific main concept for this day",
      "sub_topic": "Focused subtopic achievable in $dailyTimeMinutes minutes", 
      "material_url": "Real URL to quality resource (YouTube, docs, tutorials, courses)",
      "material_title": "Clear, descriptive title of the resource",
      "exercise": ${includeExercises ? '"Specific hands-on exercise to reinforce learning"' : 'null'}
    }
  ]${includeProjects ? ',\n  "project_recommendations": [\n    {\n      "title": "Project name",\n      "description": "What you\'ll build and learn", \n      "difficulty": "beginner/intermediate/advanced",\n      "estimated_hours": 8\n    }\n  ]' : ''}
}

Focus on ${_getLearningStyleFocus(learningStyle)}. Start response with { and end with }.''';
  }

  String _getLearningStyleFocus(LearningStyle style) {
    switch (style) {
      case LearningStyle.visual:
        return 'video tutorials, diagrams, visual examples, and interactive demos';
      case LearningStyle.auditory:
        return 'podcasts, lectures, audio explanations, and discussion-based content';
      case LearningStyle.kinesthetic:
        return 'hands-on labs, coding exercises, practical projects, and interactive tutorials';
      case LearningStyle.readingWriting:
        return 'comprehensive articles, documentation, written guides, and text-based exercises';
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
      // Clean up the response text more aggressively
      String cleanedText = generatedText.trim();
      
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
      
      // Find JSON object boundaries
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedText = cleanedText.substring(jsonStart, jsonEnd + 1);
      }
      
      cleanedText = cleanedText.trim();
      
      // Parse JSON
      final parsed = jsonDecode(cleanedText) as Map<String, dynamic>;
      
      // Validate and fix structure
      if (!parsed.containsKey('description')) {
        parsed['description'] = 'A comprehensive learning path to master your chosen topic.';
      }
      
      if (!parsed.containsKey('daily_tasks') || parsed['daily_tasks'] is! List) {
        throw Exception('Invalid response format: missing daily_tasks');
      }

      final dailyTasksList = parsed['daily_tasks'] as List;
      
      // Ensure each task has required fields
      for (int i = 0; i < dailyTasksList.length; i++) {
        final task = dailyTasksList[i] as Map<String, dynamic>;
        task['main_topic'] ??= 'Learning Topic ${i + 1}';
        task['sub_topic'] ??= 'Daily Learning Goal ${i + 1}';
        task['material_title'] ??= 'Learning Resource ${i + 1}';
        task['material_url'] ??= 'https://www.google.com/search?q=${Uri.encodeComponent(task['sub_topic'])}';
      }
      
      // Adjust task count if needed
      if (dailyTasksList.length < durationDays) {
        // Duplicate tasks to reach target
        while (dailyTasksList.length < durationDays) {
          final sourceIndex = dailyTasksList.length % dailyTasksList.length;
          final sourceTask = Map<String, dynamic>.from(dailyTasksList[sourceIndex]);
          sourceTask['sub_topic'] = '${sourceTask['sub_topic']} - Extended Practice';
          dailyTasksList.add(sourceTask);
        }
      } else if (dailyTasksList.length > durationDays) {
        // Trim excess tasks
        parsed['daily_tasks'] = dailyTasksList.take(durationDays).toList();
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

  // Enhanced fallback method with topic-specific, high-quality content
  Map<String, dynamic> createFallbackLearningPath({
    required String topic,
    required int durationDays,
    required String outputGoal,
    bool includeProjects = false,
    bool includeExercises = false,
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

    return result;
  }

  Map<String, dynamic> _getTopicSpecificData(String topic) {
    // Enhanced topic-specific data with real resources
    final topicMap = {
      'flutter': {
        'description': 'Master Flutter development from basics to advanced concepts. Build beautiful, cross-platform mobile apps and achieve: {goal}',
        'phases': [
          {
            'name': 'Flutter Fundamentals',
            'tasks': [
              {'topic': 'Dart Language Basics', 'title': 'Dart Programming Tutorial', 'url': 'https://dart.dev/tutorials', 'exercise': 'Write basic Dart functions and classes'},
              {'topic': 'Flutter Setup & First App', 'title': 'Flutter Installation Guide', 'url': 'https://docs.flutter.dev/get-started/install', 'exercise': 'Create and run your first Flutter app'},
              {'topic': 'Widgets & UI Basics', 'title': 'Introduction to Widgets', 'url': 'https://docs.flutter.dev/ui/widgets-intro', 'exercise': 'Build a simple UI with basic widgets'},
              {'topic': 'Layouts & Styling', 'title': 'Flutter Layouts', 'url': 'https://docs.flutter.dev/ui/layout', 'exercise': 'Create responsive layouts using Row, Column, and Container'},
            ]
          },
          {
            'name': 'State Management & Navigation',
            'tasks': [
              {'topic': 'StatefulWidget & setState', 'title': 'Managing State in Flutter', 'url': 'https://docs.flutter.dev/ui/interactivity', 'exercise': 'Build an interactive counter app'},
              {'topic': 'Navigation & Routing', 'title': 'Navigation and Routing', 'url': 'https://docs.flutter.dev/ui/navigation', 'exercise': 'Create multi-screen navigation'},
              {'topic': 'Forms & Input Handling', 'title': 'Building Forms', 'url': 'https://docs.flutter.dev/cookbook/forms', 'exercise': 'Build a user registration form'},
              {'topic': 'Provider State Management', 'title': 'Provider Package Tutorial', 'url': 'https://pub.dev/packages/provider', 'exercise': 'Implement Provider for state management'},
            ]
          }
        ],
        'projects': [
          {'title': 'Todo App', 'description': 'Build a complete todo application with CRUD operations', 'difficulty': 'beginner', 'estimated_hours': 12},
          {'title': 'Weather App', 'description': 'Create a weather app with API integration and beautiful UI', 'difficulty': 'intermediate', 'estimated_hours': 20},
          {'title': 'E-commerce App', 'description': 'Full-featured shopping app with authentication and payments', 'difficulty': 'advanced', 'estimated_hours': 40}
        ]
      },
      'python': {
        'description': 'Learn Python programming from fundamentals to advanced applications. Master one of the most versatile programming languages and achieve: {goal}',
        'phases': [
          {
            'name': 'Python Fundamentals',
            'tasks': [
              {'topic': 'Python Syntax & Variables', 'title': 'Python Basics Tutorial', 'url': 'https://docs.python.org/3/tutorial/', 'exercise': 'Write programs using variables, strings, and numbers'},
              {'topic': 'Control Flow & Functions', 'title': 'Control Flow Tools', 'url': 'https://docs.python.org/3/tutorial/controlflow.html', 'exercise': 'Create functions with loops and conditionals'},
              {'topic': 'Data Structures', 'title': 'Python Data Structures', 'url': 'https://docs.python.org/3/tutorial/datastructures.html', 'exercise': 'Work with lists, dictionaries, and sets'},
              {'topic': 'File I/O & Error Handling', 'title': 'Reading and Writing Files', 'url': 'https://docs.python.org/3/tutorial/inputoutput.html', 'exercise': 'Build a file processing script with error handling'},
            ]
          },
          {
            'name': 'Object-Oriented & Libraries',
            'tasks': [
              {'topic': 'Classes & Objects', 'title': 'Python Classes', 'url': 'https://docs.python.org/3/tutorial/classes.html', 'exercise': 'Create a class hierarchy for a real-world scenario'},
              {'topic': 'Popular Libraries (NumPy, Pandas)', 'title': 'NumPy Quickstart', 'url': 'https://numpy.org/doc/stable/user/quickstart.html', 'exercise': 'Analyze data using NumPy and Pandas'},
              {'topic': 'Web Development with Flask', 'title': 'Flask Tutorial', 'url': 'https://flask.palletsprojects.com/tutorial/', 'exercise': 'Build a simple web application'},
              {'topic': 'API Development & Testing', 'title': 'Building APIs with Flask', 'url': 'https://flask-restful.readthedocs.io/', 'exercise': 'Create and test a REST API'},
            ]
          }
        ],
        'projects': [
          {'title': 'Personal Finance Tracker', 'description': 'Build a CLI tool to track expenses and income', 'difficulty': 'beginner', 'estimated_hours': 15},
          {'title': 'Web Scraper Dashboard', 'description': 'Create a web scraping tool with data visualization', 'difficulty': 'intermediate', 'estimated_hours': 25},
          {'title': 'Machine Learning Pipeline', 'description': 'Build an end-to-end ML project with data processing and model deployment', 'difficulty': 'advanced', 'estimated_hours': 45}
        ]
      },
      'javascript': {
        'description': 'Master JavaScript from basics to modern frameworks. Build dynamic web applications and achieve: {goal}',
        'phases': [
          {
            'name': 'JavaScript Fundamentals',
            'tasks': [
              {'topic': 'Variables, Types & Functions', 'title': 'JavaScript Basics', 'url': 'https://developer.mozilla.org/en-US/docs/Learn/JavaScript/First_steps', 'exercise': 'Build interactive calculator functions'},
              {'topic': 'DOM Manipulation', 'title': 'Manipulating Documents', 'url': 'https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Client-side_web_APIs/Manipulating_documents', 'exercise': 'Create dynamic webpage interactions'},
              {'topic': 'Events & Async Programming', 'title': 'Asynchronous JavaScript', 'url': 'https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Asynchronous', 'exercise': 'Build an async data fetching application'},
              {'topic': 'ES6+ Features', 'title': 'Modern JavaScript Features', 'url': 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide', 'exercise': 'Refactor code using arrow functions, destructuring, and modules'},
            ]
          },
          {
            'name': 'Modern Development',
            'tasks': [
              {'topic': 'React Fundamentals', 'title': 'React Tutorial', 'url': 'https://react.dev/learn', 'exercise': 'Build your first React component'},
              {'topic': 'State Management & Hooks', 'title': 'React Hooks', 'url': 'https://react.dev/reference/react', 'exercise': 'Create stateful components with hooks'},
              {'topic': 'API Integration', 'title': 'Fetch API Guide', 'url': 'https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API', 'exercise': 'Build an app that consumes REST APIs'},
              {'topic': 'Build Tools & Deployment', 'title': 'Vite Build Tool', 'url': 'https://vitejs.dev/guide/', 'exercise': 'Set up modern build pipeline and deploy'},
            ]
          }
        ],
        'projects': [
          {'title': 'Interactive Quiz App', 'description': 'Build a quiz application with scoring and feedback', 'difficulty': 'beginner', 'estimated_hours': 18},
          {'title': 'Task Management Dashboard', 'description': 'Create a full-featured task manager with React', 'difficulty': 'intermediate', 'estimated_hours': 30},
          {'title': 'Real-time Chat Application', 'description': 'Build a chat app with WebSockets and modern UI', 'difficulty': 'advanced', 'estimated_hours': 50}
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
}

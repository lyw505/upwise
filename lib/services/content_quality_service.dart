import '../models/learning_path_model.dart';

/// Service for validating and enhancing the quality of AI-generated learning content
class ContentQualityService {
  
  /// Validate and enhance the quality of generated learning path content
  static Map<String, dynamic> validateAndEnhanceContent(
    Map<String, dynamic> generatedContent,
    String topic,
    int durationDays,
    ExperienceLevel experienceLevel,
    LearningStyle learningStyle,
  ) {
    final enhanced = Map<String, dynamic>.from(generatedContent);
    
    // Enhance description
    enhanced['description'] = _enhanceDescription(
      enhanced['description'] ?? '',
      topic,
      experienceLevel,
    );
    
    // Validate and enhance daily tasks
    if (enhanced['daily_tasks'] is List) {
      final tasks = enhanced['daily_tasks'] as List;
      enhanced['daily_tasks'] = _enhanceDailyTasks(
        tasks,
        topic,
        durationDays,
        experienceLevel,
        learningStyle,
      );
    }
    
    // Enhance project recommendations if present
    if (enhanced['project_recommendations'] is List) {
      final projects = enhanced['project_recommendations'] as List;
      enhanced['project_recommendations'] = _enhanceProjectRecommendations(
        projects,
        topic,
        experienceLevel,
      );
    }
    
    return enhanced;
  }
  
  static String _enhanceDescription(String description, String topic, ExperienceLevel experienceLevel) {
    if (description.isEmpty || description.length < 50) {
      return _generateQualityDescription(topic, experienceLevel);
    }
    
    // Enhance existing description
    String enhanced = description;
    
    // Ensure it mentions practical skills
    if (!enhanced.toLowerCase().contains('practical') && !enhanced.toLowerCase().contains('hands-on')) {
      enhanced += ' You\'ll gain practical, hands-on experience through real-world applications.';
    }
    
    // Ensure it mentions the learning progression
    if (!enhanced.toLowerCase().contains('progress') && !enhanced.toLowerCase().contains('build')) {
      enhanced += ' The curriculum is designed to build your skills progressively from fundamentals to advanced concepts.';
    }
    
    return enhanced;
  }
  
  static String _generateQualityDescription(String topic, ExperienceLevel experienceLevel) {
    final levelAdjective = experienceLevel == ExperienceLevel.beginner 
        ? 'beginner-friendly' 
        : experienceLevel == ExperienceLevel.intermediate 
            ? 'comprehensive' 
            : 'advanced';
    
    return 'Master $topic through this $levelAdjective learning path designed to take you from your current level to practical proficiency. '
           'You\'ll build real-world skills through hands-on exercises, practical projects, and progressive learning that connects theory to application. '
           'By the end, you\'ll have the confidence and competence to apply $topic in professional settings.';
  }
  
  static List<Map<String, dynamic>> _enhanceDailyTasks(
    List tasks,
    String topic,
    int durationDays,
    ExperienceLevel experienceLevel,
    LearningStyle learningStyle,
  ) {
    final enhanced = <Map<String, dynamic>>[];
    
    for (int i = 0; i < tasks.length; i++) {
      final task = Map<String, dynamic>.from(tasks[i]);
      
      // Enhance main topic
      task['main_topic'] = _enhanceMainTopic(
        task['main_topic'] ?? 'Day ${i + 1} Learning',
        i + 1,
        durationDays,
        topic,
      );
      
      // Enhance sub topic with more detail
      task['sub_topic'] = _enhanceSubTopic(
        task['sub_topic'] ?? 'Learning objectives for day ${i + 1}',
        task['main_topic'],
        experienceLevel,
      );
      
      // Enhance material title
      task['material_title'] = _enhanceMaterialTitle(
        task['material_title'] ?? 'Learning Resource',
        task['main_topic'],
        learningStyle,
      );
      
      // Validate and enhance material URL
      task['material_url'] = _validateAndEnhanceUrl(
        task['material_url'] ?? '',
        task['main_topic'],
        topic,
      );
      
      // Enhance exercise if present
      if (task['exercise'] != null && task['exercise'].toString().isNotEmpty) {
        task['exercise'] = _enhanceExercise(
          task['exercise'].toString(),
          task['main_topic'],
          experienceLevel,
        );
      }
      
      enhanced.add(task);
    }
    
    return enhanced;
  }
  
  static String _enhanceMainTopic(String mainTopic, int dayNumber, int totalDays, String topic) {
    // Ensure main topic is descriptive and contextual
    if (mainTopic.length < 10 || mainTopic.toLowerCase().contains('day $dayNumber')) {
      // Generate a better main topic based on learning progression
      if (dayNumber <= totalDays * 0.3) {
        return '$topic Fundamentals - Core Concepts';
      } else if (dayNumber <= totalDays * 0.7) {
        return '$topic Application - Practical Skills';
      } else {
        return '$topic Mastery - Advanced Techniques';
      }
    }
    
    return mainTopic;
  }
  
  static String _enhanceSubTopic(String subTopic, String mainTopic, ExperienceLevel experienceLevel) {
    if (subTopic.length < 20) {
      final complexity = experienceLevel == ExperienceLevel.beginner 
          ? 'fundamental concepts and basic implementation'
          : experienceLevel == ExperienceLevel.intermediate
              ? 'practical applications and intermediate techniques'
              : 'advanced patterns and optimization strategies';
      
      return 'Explore $complexity related to ${mainTopic.toLowerCase()}, with hands-on practice and real-world examples';
    }
    
    // Enhance existing sub topic
    String enhanced = subTopic;
    
    // Ensure it mentions practical application
    if (!enhanced.toLowerCase().contains('practical') && !enhanced.toLowerCase().contains('hands-on')) {
      enhanced += ' with practical exercises';
    }
    
    // Ensure it mentions learning outcome
    if (!enhanced.toLowerCase().contains('learn') && !enhanced.toLowerCase().contains('understand') && !enhanced.toLowerCase().contains('master')) {
      enhanced = 'Learn ' + enhanced.toLowerCase();
    }
    
    return enhanced;
  }
  
  static String _enhanceMaterialTitle(String materialTitle, String mainTopic, LearningStyle learningStyle) {
    if (materialTitle.length < 10) {
      final stylePrefix = learningStyle == LearningStyle.visual 
          ? 'Visual Guide to'
          : learningStyle == LearningStyle.auditory
              ? 'Complete Tutorial on'
              : learningStyle == LearningStyle.kinesthetic
                  ? 'Hands-on Workshop:'
                  : 'Comprehensive Guide to';
      
      return '$stylePrefix $mainTopic';
    }
    
    return materialTitle;
  }
  
  static String _validateAndEnhanceUrl(String url, String mainTopic, String topic) {
    // If URL is empty or just a search URL, try to provide a better default
    if (url.isEmpty || url.contains('google.com/search')) {
      return _generateBetterUrl(mainTopic, topic);
    }
    
    // Validate that URL looks reasonable
    if (!url.startsWith('http')) {
      return 'https://$url';
    }
    
    return url;
  }
  
  static String _generateBetterUrl(String mainTopic, String topic) {
    final topicLower = topic.toLowerCase();
    
    // Provide topic-specific high-quality resources
    if (topicLower.contains('flutter')) {
      return 'https://docs.flutter.dev/';
    } else if (topicLower.contains('python')) {
      return 'https://docs.python.org/3/tutorial/';
    } else if (topicLower.contains('javascript')) {
      return 'https://developer.mozilla.org/en-US/docs/Web/JavaScript';
    } else if (topicLower.contains('react')) {
      return 'https://react.dev/learn';
    } else if (topicLower.contains('node')) {
      return 'https://nodejs.org/en/docs/';
    }
    
    // Generic high-quality search
    final searchQuery = Uri.encodeComponent('$mainTopic $topic tutorial');
    return 'https://www.google.com/search?q=$searchQuery';
  }
  
  static String _enhanceExercise(String exercise, String mainTopic, ExperienceLevel experienceLevel) {
    if (exercise.length < 30) {
      final complexity = experienceLevel == ExperienceLevel.beginner 
          ? 'Create a simple project that demonstrates'
          : experienceLevel == ExperienceLevel.intermediate
              ? 'Build a practical application that implements'
              : 'Develop an advanced solution that showcases';
      
      return '$complexity the key concepts of ${mainTopic.toLowerCase()}. Include proper error handling and documentation.';
    }
    
    // Enhance existing exercise
    String enhanced = exercise;
    
    // Ensure it has clear instructions
    if (!enhanced.toLowerCase().contains('create') && !enhanced.toLowerCase().contains('build') && !enhanced.toLowerCase().contains('implement')) {
      enhanced = 'Create a practical exercise: ' + enhanced;
    }
    
    // Ensure it mentions expected outcome
    if (!enhanced.contains('.') || enhanced.split('.').length < 2) {
      enhanced += ' Document your approach and reflect on the key concepts learned.';
    }
    
    return enhanced;
  }
  
  static List<Map<String, dynamic>> _enhanceProjectRecommendations(
    List projects,
    String topic,
    ExperienceLevel experienceLevel,
  ) {
    final enhanced = <Map<String, dynamic>>[];
    
    for (int i = 0; i < projects.length; i++) {
      final project = Map<String, dynamic>.from(projects[i]);
      
      // Enhance project title
      if (project['title'] == null || project['title'].toString().length < 10) {
        project['title'] = _generateProjectTitle(topic, i, experienceLevel);
      }
      
      // Enhance project description
      if (project['description'] == null || project['description'].toString().length < 30) {
        project['description'] = _generateProjectDescription(
          project['title'].toString(),
          topic,
          experienceLevel,
        );
      }
      
      // Validate difficulty
      if (project['difficulty'] == null || !['beginner', 'intermediate', 'advanced'].contains(project['difficulty'])) {
        project['difficulty'] = experienceLevel.name;
      }
      
      // Validate estimated hours
      if (project['estimated_hours'] == null || project['estimated_hours'] < 5) {
        project['estimated_hours'] = experienceLevel == ExperienceLevel.beginner 
            ? 15 
            : experienceLevel == ExperienceLevel.intermediate 
                ? 25 
                : 40;
      }
      
      enhanced.add(project);
    }
    
    return enhanced;
  }
  
  static String _generateProjectTitle(String topic, int index, ExperienceLevel experienceLevel) {
    final complexity = experienceLevel == ExperienceLevel.beginner 
        ? 'Personal'
        : experienceLevel == ExperienceLevel.intermediate
            ? 'Professional'
            : 'Enterprise';
    
    final projectTypes = [
      '$complexity $topic Application',
      '$topic Portfolio Project',
      'Real-world $topic Solution',
    ];
    
    return projectTypes[index % projectTypes.length];
  }
  
  static String _generateProjectDescription(String title, String topic, ExperienceLevel experienceLevel) {
    final complexity = experienceLevel == ExperienceLevel.beginner 
        ? 'fundamental concepts with a user-friendly interface'
        : experienceLevel == ExperienceLevel.intermediate
            ? 'intermediate features including data persistence and user management'
            : 'advanced architecture patterns, performance optimization, and scalability considerations';
    
    return 'Build a comprehensive $title that demonstrates $complexity. '
           'This project will showcase your $topic skills through practical implementation, '
           'proper code organization, and professional development practices.';
  }
  
  /// Validate that the learning path meets quality standards
  static bool validateLearningPathQuality(Map<String, dynamic> content) {
    // Check required fields
    if (!content.containsKey('description') || content['description'].toString().length < 50) {
      return false;
    }
    
    if (!content.containsKey('daily_tasks') || content['daily_tasks'] is! List) {
      return false;
    }
    
    final tasks = content['daily_tasks'] as List;
    if (tasks.isEmpty) {
      return false;
    }
    
    // Validate each task
    for (final task in tasks) {
      if (task is! Map<String, dynamic>) return false;
      
      if (!task.containsKey('main_topic') || task['main_topic'].toString().length < 5) {
        return false;
      }
      
      if (!task.containsKey('sub_topic') || task['sub_topic'].toString().length < 10) {
        return false;
      }
      
      if (!task.containsKey('material_title') || task['material_title'].toString().length < 5) {
        return false;
      }
      
      if (!task.containsKey('material_url') || task['material_url'].toString().isEmpty) {
        return false;
      }
    }
    
    return true;
  }
}
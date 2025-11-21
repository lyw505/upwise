import '../models/learning_path_model.dart';
import 'gemini_service.dart';
import 'content_quality_service.dart';

/// Service for testing and demonstrating enhanced Gemini AI capabilities
class GeminiTestService {
  static final GeminiService _geminiService = GeminiService();
  
  /// Test the enhanced AI with various scenarios
  static Future<void> runEnhancementTests() async {
    print('🚀 Starting Enhanced Gemini AI Tests...\n');
    
    // Test 1: Flutter for Beginners
    await _testScenario(
      'Flutter Development',
      7,
      30,
      ExperienceLevel.beginner,
      LearningStyle.visual,
      'Build my first mobile app',
      includeProjects: true,
      includeExercises: true,
    );
    
    // Test 2: Python for Data Science (Intermediate)
    await _testScenario(
      'Python for Data Science',
      14,
      45,
      ExperienceLevel.intermediate,
      LearningStyle.kinesthetic,
      'Become a data analyst',
      includeProjects: true,
      includeExercises: true,
    );
    
    // Test 3: JavaScript Advanced (Short Course)
    await _testScenario(
      'Advanced JavaScript',
      5,
      60,
      ExperienceLevel.advanced,
      LearningStyle.readingWriting,
      'Master modern JavaScript for senior developer role',
      includeProjects: false,
      includeExercises: true,
    );
    
    // Test 4: React for Career Change
    await _testScenario(
      'React Development',
      21,
      90,
      ExperienceLevel.beginner,
      LearningStyle.auditory,
      'Change career to frontend developer',
      includeProjects: true,
      includeExercises: true,
      notes: 'Coming from backend development background',
    );
    
    print('✅ All Enhanced Gemini AI Tests Completed!\n');
  }
  
  static Future<void> _testScenario(
    String topic,
    int durationDays,
    int dailyTimeMinutes,
    ExperienceLevel experienceLevel,
    LearningStyle learningStyle,
    String outputGoal, {
    bool includeProjects = false,
    bool includeExercises = false,
    String? notes,
  }) async {
    print('📚 Testing: $topic (${experienceLevel.name}, ${learningStyle.name})');
    print('⏱️  Duration: $durationDays days, $dailyTimeMinutes min/day');
    print('🎯 Goal: $outputGoal');
    if (notes != null) print('📝 Notes: $notes');
    print('');
    
    try {
      final result = await _geminiService.generateLearningPath(
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
      
      if (result != null) {
        _analyzeResult(result, topic, durationDays);
      } else {
        print('❌ Failed to generate learning path for $topic');
      }
    } catch (e) {
      print('❌ Error testing $topic: $e');
    }
    
    print('${'=' * 60}\n');
  }
  
  static void _analyzeResult(Map<String, dynamic> result, String topic, int expectedDays) {
    print('✅ Successfully generated learning path for $topic');
    
    // Analyze description
    final description = result['description'] as String? ?? '';
    print('📖 Description length: ${description.length} chars');
    print('📖 Description quality: ${description.length >= 50 ? '✅ Good' : '⚠️ Needs improvement'}');
    
    // Analyze daily tasks
    final dailyTasks = result['daily_tasks'] as List? ?? [];
    print('📅 Daily tasks count: ${dailyTasks.length} (expected: $expectedDays)');
    print('📅 Task count accuracy: ${dailyTasks.length == expectedDays ? '✅ Perfect' : '⚠️ Adjusted'}');
    
    // Analyze task quality
    int qualityTasks = 0;
    int detailedSubTopics = 0;
    int validUrls = 0;
    int practicalExercises = 0;
    
    for (final task in dailyTasks) {
      if (task is Map<String, dynamic>) {
        final mainTopic = task['main_topic'] as String? ?? '';
        final subTopic = task['sub_topic'] as String? ?? '';
        final materialTitle = task['material_title'] as String? ?? '';
        final materialUrl = task['material_url'] as String? ?? '';
        final exercise = task['exercise'] as String?;
        
        // Check quality criteria
        if (mainTopic.length >= 10 && subTopic.length >= 20 && materialTitle.length >= 10) {
          qualityTasks++;
        }
        
        if (subTopic.length >= 30) {
          detailedSubTopics++;
        }
        
        if (materialUrl.isNotEmpty && !materialUrl.contains('google.com/search')) {
          validUrls++;
        }
        
        if (exercise != null && exercise.length >= 30) {
          practicalExercises++;
        }
      }
    }
    
    print('🎯 Quality tasks: $qualityTasks/${dailyTasks.length} (${(qualityTasks / dailyTasks.length * 100).toStringAsFixed(1)}%)');
    print('📝 Detailed sub-topics: $detailedSubTopics/${dailyTasks.length} (${(detailedSubTopics / dailyTasks.length * 100).toStringAsFixed(1)}%)');
    print('🔗 Quality URLs: $validUrls/${dailyTasks.length} (${(validUrls / dailyTasks.length * 100).toStringAsFixed(1)}%)');
    
    if (result.containsKey('project_recommendations')) {
      final projects = result['project_recommendations'] as List? ?? [];
      print('🚀 Project recommendations: ${projects.length}');
      
      if (practicalExercises > 0) {
        print('💪 Practical exercises: $practicalExercises/${dailyTasks.length} (${(practicalExercises / dailyTasks.length * 100).toStringAsFixed(1)}%)');
      }
    }
    
    // Overall quality assessment
    final overallQuality = (qualityTasks / dailyTasks.length) * 0.4 +
                          (detailedSubTopics / dailyTasks.length) * 0.3 +
                          (validUrls / dailyTasks.length) * 0.3;
    
    print('⭐ Overall Quality Score: ${(overallQuality * 100).toStringAsFixed(1)}%');
    
    if (overallQuality >= 0.8) {
      print('🏆 Excellent quality learning path!');
    } else if (overallQuality >= 0.6) {
      print('👍 Good quality learning path');
    } else {
      print('⚠️ Quality could be improved');
    }
    
    // Sample first task for detailed analysis
    if (dailyTasks.isNotEmpty) {
      print('\n📋 Sample Task (Day 1):');
      final firstTask = dailyTasks[0] as Map<String, dynamic>;
      print('  Main Topic: ${firstTask['main_topic']}');
      print('  Sub Topic: ${firstTask['sub_topic']}');
      print('  Material: ${firstTask['material_title']}');
      print('  URL: ${firstTask['material_url']}');
      if (firstTask['exercise'] != null) {
        print('  Exercise: ${firstTask['exercise']}');
      }
    }
  }
  
  /// Test content quality service independently
  static void testContentQualityService() {
    print('🔧 Testing Content Quality Service...\n');
    
    // Test with minimal content
    final minimalContent = {
      'description': 'Learn Flutter',
      'daily_tasks': [
        {
          'main_topic': 'Flutter',
          'sub_topic': 'Widgets',
          'material_title': 'Tutorial',
          'material_url': '',
          'exercise': 'Make app'
        }
      ]
    };
    
    print('📝 Original minimal content:');
    print('  Description: "${minimalContent['description']}"');
    final originalTask = (minimalContent['daily_tasks'] as List)[0];
    print('  Task: "${originalTask['sub_topic']}"');
    print('  Exercise: "${originalTask['exercise']}"');
    
    // Enhance content
    final enhanced = ContentQualityService.validateAndEnhanceContent(
      minimalContent,
      'Flutter',
      7,
      ExperienceLevel.beginner,
      LearningStyle.visual,
    );
    
    print('\n✨ Enhanced content:');
    print('  Description: "${enhanced['description']}"');
    final enhancedTask = (enhanced['daily_tasks'] as List)[0];
    print('  Task: "${enhancedTask['sub_topic']}"');
    print('  Exercise: "${enhancedTask['exercise']}"');
    
    // Validate quality
    final isValid = ContentQualityService.validateLearningPathQuality(enhanced);
    print('\n🎯 Quality validation: ${isValid ? '✅ Passed' : '❌ Failed'}');
    
    print('${'=' * 60}\n');
  }
  
  /// Demonstrate learning style optimizations
  static void demonstrateLearningStyleOptimizations() {
    print('🎨 Demonstrating Learning Style Optimizations...\n');
    
    final topic = 'JavaScript Fundamentals';
    final styles = [
      LearningStyle.visual,
      LearningStyle.auditory,
      LearningStyle.kinesthetic,
      LearningStyle.readingWriting,
    ];
    
    for (final style in styles) {
      print('📚 Learning Style: ${style.name.toUpperCase()}');
      
      final sampleContent = {
        'description': 'Learn JavaScript programming',
        'daily_tasks': [
          {
            'main_topic': 'JavaScript Basics',
            'sub_topic': 'Variables and functions',
            'material_title': 'Tutorial',
            'material_url': '',
            'exercise': 'Practice coding'
          }
        ]
      };
      
      final enhanced = ContentQualityService.validateAndEnhanceContent(
        sampleContent,
        topic,
        7,
        ExperienceLevel.intermediate,
        style,
      );
      
      final task = (enhanced['daily_tasks'] as List)[0];
      print('  Material Title: "${task['material_title']}"');
      print('  Enhanced Sub-topic: "${task['sub_topic']}"');
      print('');
    }
    
    print('${'=' * 60}\n');
  }
}
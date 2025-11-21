import '../models/learning_path_model.dart';

/// Enhanced prompt service for generating more intelligent and detailed learning paths
class EnhancedPromptService {
  
  /// Generate an advanced, context-aware prompt for AI learning path generation
  static String generateAdvancedPrompt({
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
    final contextualInfo = _getTopicContextualInfo(topic);
    final learningPhases = _generateDetailedLearningPhases(durationDays, topic);
    final styleOptimization = _getLearningStyleOptimization(learningStyle);
    final experienceAdjustments = _getExperienceLevelAdjustments(experienceLevel);
    final qualityFramework = _getQualityAssuranceFramework();
    
    return '''
# EXPERT LEARNING PATH DESIGNER PROMPT

You are a world-class curriculum designer and educational expert with deep expertise in instructional design, cognitive science, and adult learning principles. Your task is to create an exceptional $durationDays-day learning path for "$topic" that will transform a learner from their current level to achieving their specific goal.

## LEARNER PROFILE ANALYSIS
**Experience Level**: ${experienceLevel.name.toUpperCase()}
$experienceAdjustments

**Learning Style**: ${learningStyle.name.toUpperCase()}
$styleOptimization

**Time Commitment**: $dailyTimeMinutes minutes per day
**Learning Goal**: $outputGoal
${notes != null && notes.isNotEmpty ? '**Additional Context**: $notes' : ''}

## TOPIC EXPERTISE & CONTEXT
$contextualInfo

## LEARNING ARCHITECTURE
$learningPhases

## QUALITY ASSURANCE FRAMEWORK
$qualityFramework

## CONTENT CREATION SPECIFICATIONS

### Daily Task Structure Requirements:
1. **Main Topic**: Broad conceptual area that provides clear learning focus
2. **Sub Topic**: Specific, measurable learning objective achievable in $dailyTimeMinutes minutes
3. **Material Title**: Engaging, descriptive title that clearly communicates learning value
4. **Material URL**: Real, high-quality, accessible educational resource (prioritize official docs, reputable platforms)
5. **Exercise**: ${includeExercises ? 'Detailed, hands-on exercise with clear instructions and expected outcomes' : 'Not required for this learning path'}

### Resource Quality Standards:
- Use official documentation, established educational platforms, and reputable sources
- Ensure resources are current, accessible, and appropriate for the experience level
- Provide diverse resource types to maintain engagement
- Include interactive elements when possible

### Progressive Learning Design:
- Each day must build logically on previous concepts
- Include review and reinforcement of key concepts
- Gradually increase complexity and independence
- Provide clear connections between daily topics

## OUTPUT FORMAT
Return ONLY a valid JSON object with this exact structure:

{
  "description": "Compelling 2-3 sentence description that explains what the learner will master, the practical skills they'll gain, and how it directly connects to achieving: $outputGoal",
  "daily_tasks": [
    {
      "main_topic": "Clear, focused main concept area",
      "sub_topic": "Specific, actionable learning objective with clear outcome", 
      "material_url": "Real URL to high-quality educational resource",
      "material_title": "Descriptive, engaging title that indicates learning value",
      "exercise": ${includeExercises ? '"Detailed exercise with step-by-step instructions and practical application"' : 'null'}
    }
  ]${includeProjects ? ',\n  "project_recommendations": [\n    {\n      "title": "Practical project name demonstrating real-world application",\n      "description": "Detailed description of what will be built, technologies used, and skills demonstrated", \n      "difficulty": "beginner/intermediate/advanced",\n      "estimated_hours": 15\n    }\n  ]' : ''}
}

## CRITICAL SUCCESS FACTORS
- Ensure EXACTLY $durationDays daily tasks
- Each task must be completable within $dailyTimeMinutes minutes
- Content must be progressive and logically sequenced
- Resources must be real, accessible, and high-quality
- Learning objectives must be specific and measurable
- Include practical application and real-world relevance

Start your response with { and end with }. No additional text or explanations.
''';
  }

  static String _getTopicContextualInfo(String topic) {
    final topicLower = topic.toLowerCase();
    
    final contextMap = {
      'flutter': '''
**Domain**: Cross-platform mobile development using Google's UI toolkit
**Industry Relevance**: High demand in mobile app development, especially for startups and rapid prototyping
**Prerequisites**: Basic programming concepts, object-oriented programming understanding
**Key Technologies**: Dart language, Widget system, State management, Platform channels
**Career Applications**: Mobile app developer, UI/UX developer, Cross-platform specialist
**Learning Complexity**: Moderate - requires understanding of both programming concepts and mobile UI patterns''',
      
      'python': '''
**Domain**: General-purpose programming language with applications in web development, data science, automation, and AI
**Industry Relevance**: Extremely high demand across multiple industries, consistently top-ranked programming language
**Prerequisites**: Basic computer literacy, logical thinking, mathematical concepts (for advanced applications)
**Key Technologies**: Core syntax, Libraries (NumPy, Pandas, Flask/Django), Package management, Virtual environments
**Career Applications**: Web developer, Data scientist, DevOps engineer, AI/ML engineer, Automation specialist
**Learning Complexity**: Beginner-friendly syntax with scalable complexity for advanced applications''',
      
      'javascript': '''
**Domain**: Web development language for both front-end and back-end applications
**Industry Relevance**: Essential for web development, highest demand in tech industry
**Prerequisites**: Basic HTML/CSS knowledge, understanding of web browsers and client-server architecture
**Key Technologies**: ES6+ features, DOM manipulation, Async programming, Frameworks (React, Vue, Angular), Node.js
**Career Applications**: Front-end developer, Full-stack developer, Web application developer, Mobile app developer (React Native)
**Learning Complexity**: Easy to start, complex to master due to asynchronous nature and ecosystem complexity''',
      
      'react': '''
**Domain**: JavaScript library for building user interfaces, particularly single-page applications
**Industry Relevance**: Extremely high demand, used by major companies like Facebook, Netflix, Airbnb
**Prerequisites**: Solid JavaScript knowledge, HTML/CSS proficiency, understanding of ES6+ features
**Key Technologies**: JSX, Component architecture, Hooks, State management, Virtual DOM, Ecosystem tools
**Career Applications**: Front-end developer, React developer, UI developer, Full-stack developer
**Learning Complexity**: Moderate - requires good JavaScript foundation and understanding of component-based architecture''',
      
      'node.js': '''
**Domain**: JavaScript runtime for server-side development and backend applications
**Industry Relevance**: High demand for full-stack JavaScript development and API creation
**Prerequisites**: Strong JavaScript knowledge, understanding of asynchronous programming, basic server concepts
**Key Technologies**: NPM ecosystem, Express.js, Database integration, Authentication, API development
**Career Applications**: Backend developer, Full-stack developer, API developer, DevOps engineer
**Learning Complexity**: Moderate to advanced - requires understanding of server architecture and asynchronous patterns''',
    };
    
    for (final key in contextMap.keys) {
      if (topicLower.contains(key) || key.contains(topicLower)) {
        return contextMap[key]!;
      }
    }
    
    return '''
**Domain**: Specialized knowledge area requiring structured learning approach
**Industry Relevance**: Varies based on current market demands and technological trends
**Prerequisites**: Foundation knowledge may be required depending on topic complexity
**Key Technologies**: Topic-specific tools, frameworks, and methodologies
**Career Applications**: Depends on industry application and specialization level
**Learning Complexity**: Varies - assess based on learner's background and topic depth''';
  }

  static String _generateDetailedLearningPhases(int durationDays, String topic) {
    if (durationDays <= 3) {
      return '''
### INTENSIVE LEARNING PHASE (Days 1-$durationDays)
**Focus**: Core fundamentals and immediate application
**Approach**: Concentrated learning with immediate practice
**Outcome**: Basic competency and confidence to continue learning independently''';
    } else if (durationDays <= 7) {
      final midPoint = (durationDays / 2).ceil();
      return '''
### PHASE 1: FOUNDATION BUILDING (Days 1-$midPoint)
**Focus**: Core concepts, terminology, and basic understanding
**Approach**: Structured introduction with guided examples
**Outcome**: Solid foundation and readiness for practical application

### PHASE 2: PRACTICAL APPLICATION (Days ${midPoint + 1}-$durationDays)
**Focus**: Hands-on practice and real-world application
**Approach**: Project-based learning with increasing independence
**Outcome**: Practical skills and confidence in applying knowledge''';
    } else if (durationDays <= 14) {
      final firstPhase = (durationDays * 0.35).ceil();
      final secondPhase = (durationDays * 0.75).ceil();
      return '''
### PHASE 1: FOUNDATION & FUNDAMENTALS (Days 1-$firstPhase)
**Focus**: Core concepts, essential terminology, and basic principles
**Approach**: Structured learning with simple examples and guided practice
**Outcome**: Strong conceptual foundation and basic practical skills

### PHASE 2: SKILL DEVELOPMENT & PRACTICE (Days ${firstPhase + 1}-$secondPhase)
**Focus**: Intermediate concepts, practical techniques, and skill building
**Approach**: Hands-on exercises with increasing complexity and independence
**Outcome**: Proficiency in core skills and confidence in problem-solving

### PHASE 3: ADVANCED APPLICATION & INTEGRATION (Days ${secondPhase + 1}-$durationDays)
**Focus**: Complex scenarios, real-world applications, and knowledge integration
**Approach**: Project-based learning with minimal guidance
**Outcome**: Advanced skills and ability to tackle real-world challenges''';
    } else {
      final firstPhase = (durationDays * 0.25).ceil();
      final secondPhase = (durationDays * 0.5).ceil();
      final thirdPhase = (durationDays * 0.8).ceil();
      return '''
### PHASE 1: FOUNDATION MASTERY (Days 1-$firstPhase)
**Focus**: Fundamental principles, core concepts, and essential terminology
**Approach**: Systematic introduction with comprehensive examples
**Outcome**: Deep understanding of foundational concepts

### PHASE 2: SKILL BUILDING & PRACTICE (Days ${firstPhase + 1}-$secondPhase)
**Focus**: Practical techniques, intermediate concepts, and skill development
**Approach**: Guided practice with progressive complexity
**Outcome**: Solid practical skills and problem-solving abilities

### PHASE 3: ADVANCED CONCEPTS & INTEGRATION (Days ${secondPhase + 1}-$thirdPhase)
**Focus**: Advanced topics, complex scenarios, and knowledge synthesis
**Approach**: Independent learning with challenging projects
**Outcome**: Advanced proficiency and ability to handle complex challenges

### PHASE 4: MASTERY & SPECIALIZATION (Days ${thirdPhase + 1}-$durationDays)
**Focus**: Specialization, optimization, and professional-level application
**Approach**: Self-directed learning with real-world projects
**Outcome**: Professional competency and readiness for advanced challenges''';
    }
  }

  static String _getLearningStyleOptimization(LearningStyle style) {
    switch (style) {
      case LearningStyle.visual:
        return '''
**Optimization Strategy**: Prioritize visual learning resources
- Video tutorials with clear visual demonstrations
- Infographics, diagrams, and visual aids
- Interactive demos and visual examples
- Code visualization tools and visual debugging
- Mind maps and visual concept connections
**Resource Types**: YouTube tutorials, interactive coding platforms, visual documentation''';
      
      case LearningStyle.auditory:
        return '''
**Optimization Strategy**: Focus on audio-based learning resources
- Podcasts and audio explanations
- Video lectures with strong verbal instruction
- Discussion-based content and community forums
- Verbal walkthroughs and explanations
- Audio summaries and review sessions
**Resource Types**: Podcasts, lecture videos, audio courses, discussion forums''';
      
      case LearningStyle.kinesthetic:
        return '''
**Optimization Strategy**: Emphasize hands-on, practical learning
- Interactive coding exercises and labs
- Step-by-step practical tutorials
- Learning-by-doing approach with immediate feedback
- Real-world projects and simulations
- Trial-and-error experimentation opportunities
**Resource Types**: Interactive coding platforms, hands-on tutorials, practical workshops''';
      
      case LearningStyle.readingWriting:
        return '''
**Optimization Strategy**: Leverage text-based learning resources
- Comprehensive written documentation
- Detailed articles and written guides
- Note-taking and written exercise activities
- Text-based tutorials with code examples
- Written summaries and documentation practice
**Resource Types**: Official documentation, written tutorials, technical articles, books''';
    }
  }

  static String _getExperienceLevelAdjustments(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return '''
**Learning Adjustments for Beginners**:
- Start with fundamental concepts and build gradually
- Provide extensive context and background information
- Include more detailed explanations and step-by-step guidance
- Use simple, practical examples before complex scenarios
- Ensure each concept is thoroughly understood before progression
- Include review and reinforcement of previous concepts''';
      
      case ExperienceLevel.intermediate:
        return '''
**Learning Adjustments for Intermediate Learners**:
- Build on existing knowledge and make connections to familiar concepts
- Focus on practical application and real-world scenarios
- Introduce intermediate complexity with appropriate challenges
- Provide opportunities for independent problem-solving
- Include best practices and common pitfalls to avoid
- Balance guided learning with self-directed exploration''';
      
      case ExperienceLevel.advanced:
        return '''
**Learning Adjustments for Advanced Learners**:
- Focus on advanced concepts, optimization, and best practices
- Provide challenging scenarios and complex problem-solving opportunities
- Emphasize industry standards and professional-level techniques
- Include performance considerations and advanced patterns
- Encourage experimentation and exploration of edge cases
- Connect learning to broader architectural and design principles''';
    }
  }

  static String _getQualityAssuranceFramework() {
    return '''
### CONTENT QUALITY STANDARDS
1. **Accuracy**: All information must be current, correct, and verified
2. **Relevance**: Content must directly support the learning objectives
3. **Clarity**: Explanations must be clear, concise, and understandable
4. **Practicality**: Include real-world applications and practical examples
5. **Progression**: Ensure logical flow and appropriate difficulty progression

### RESOURCE VALIDATION CRITERIA
1. **Authority**: Use official documentation and reputable sources
2. **Currency**: Ensure resources are up-to-date and relevant
3. **Accessibility**: Verify resources are freely accessible and functional
4. **Quality**: Select high-quality, well-structured learning materials
5. **Diversity**: Include various resource types to maintain engagement

### LEARNING EFFECTIVENESS MEASURES
1. **Measurable Objectives**: Each day should have clear, achievable goals
2. **Active Learning**: Include hands-on activities and practical application
3. **Retention Strategies**: Build in review and reinforcement mechanisms
4. **Engagement**: Maintain learner interest through varied activities
5. **Assessment**: Provide opportunities for self-evaluation and progress tracking''';
  }
}
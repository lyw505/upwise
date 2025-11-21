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
    String language = 'id', // Default to Indonesian
  }) {
    final contextualInfo = _getTopicContextualInfo(topic);
    final learningPhases = _generateDetailedLearningPhases(durationDays, topic);
    final styleOptimization = _getLearningStyleOptimization(learningStyle);
    final experienceAdjustments = _getExperienceLevelAdjustments(experienceLevel);
    final qualityFramework = _getQualityAssuranceFramework();
    final languageInstructions = _getLanguageInstructions(language);
    
    return '''
# EXPERT LEARNING PATH DESIGNER PROMPT

$languageInstructions

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
      // Programming & Technology
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
      
      // Culinary & Cooking
      'memasak': '''
**Domain**: Seni kuliner dan keterampilan memasak untuk kehidupan sehari-hari dan profesional
**Industry Relevance**: Tinggi dalam industri kuliner, restoran, katering, dan content creation
**Prerequisites**: Pengetahuan dasar bahan makanan, keselamatan dapur, dan kebersihan
**Key Technologies**: Teknik memasak, penggunaan peralatan dapur, food safety, presentasi makanan
**Career Applications**: Chef, food blogger, catering business, culinary instructor, food photographer
**Learning Complexity**: Mudah untuk pemula, membutuhkan latihan konsisten untuk menguasai teknik advanced''',
      
      'cooking': '''
**Domain**: Culinary arts and cooking skills for daily life and professional applications
**Industry Relevance**: High in culinary industry, restaurants, catering, and content creation
**Prerequisites**: Basic knowledge of ingredients, kitchen safety, and hygiene
**Key Technologies**: Cooking techniques, kitchen equipment usage, food safety, food presentation
**Career Applications**: Chef, food blogger, catering business, culinary instructor, food photographer
**Learning Complexity**: Easy for beginners, requires consistent practice for advanced techniques''',
      
      // Fitness & Sports
      'olahraga': '''
**Domain**: Aktivitas fisik dan kebugaran untuk kesehatan dan performa atletik
**Industry Relevance**: Tinggi dalam industri fitness, wellness, dan healthcare
**Prerequisites**: Pemahaman dasar anatomi, kondisi kesehatan personal, dan motivasi konsisten
**Key Technologies**: Exercise techniques, nutrition science, recovery methods, performance tracking
**Career Applications**: Personal trainer, fitness instructor, sports coach, wellness consultant, physiotherapist
**Learning Complexity**: Mudah dimulai, membutuhkan dedikasi dan konsistensi untuk hasil optimal''',
      
      'fitness': '''
**Domain**: Physical activity and wellness for health and athletic performance
**Industry Relevance**: High in fitness, wellness, and healthcare industries
**Prerequisites**: Basic understanding of anatomy, personal health condition, and consistent motivation
**Key Technologies**: Exercise techniques, nutrition science, recovery methods, performance tracking
**Career Applications**: Personal trainer, fitness instructor, sports coach, wellness consultant, physiotherapist
**Learning Complexity**: Easy to start, requires dedication and consistency for optimal results''',
      
      // Arts & Design
      'seni': '''
**Domain**: Ekspresi kreatif melalui berbagai medium visual dan digital
**Industry Relevance**: Tinggi dalam industri kreatif, advertising, game development, dan media
**Prerequisites**: Kreativitas, kesabaran, dan apresiasi terhadap estetika visual
**Key Technologies**: Drawing techniques, digital tools (Photoshop, Illustrator), color theory, composition
**Career Applications**: Graphic designer, illustrator, concept artist, art director, freelance artist
**Learning Complexity**: Mudah dimulai, membutuhkan latihan konsisten dan pengembangan style personal''',
      
      'art': '''
**Domain**: Creative expression through various visual and digital mediums
**Industry Relevance**: High in creative industries, advertising, game development, and media
**Prerequisites**: Creativity, patience, and appreciation for visual aesthetics
**Key Technologies**: Drawing techniques, digital tools (Photoshop, Illustrator), color theory, composition
**Career Applications**: Graphic designer, illustrator, concept artist, art director, freelance artist
**Learning Complexity**: Easy to start, requires consistent practice and personal style development''',
      
      // Business & Finance
      'bisnis': '''
**Domain**: Kewirausahaan dan manajemen bisnis untuk kesuksesan finansial
**Industry Relevance**: Universal - berlaku di semua industri dan sektor ekonomi
**Prerequisites**: Pemahaman dasar matematika, komunikasi yang baik, dan mindset entrepreneurial
**Key Technologies**: Business planning, financial management, marketing strategies, digital tools
**Career Applications**: Entrepreneur, business manager, consultant, financial advisor, startup founder
**Learning Complexity**: Moderate - membutuhkan kombinasi teori dan praktik real-world''',
      
      'business': '''
**Domain**: Entrepreneurship and business management for financial success
**Industry Relevance**: Universal - applicable across all industries and economic sectors
**Prerequisites**: Basic mathematics understanding, good communication skills, and entrepreneurial mindset
**Key Technologies**: Business planning, financial management, marketing strategies, digital tools
**Career Applications**: Entrepreneur, business manager, consultant, financial advisor, startup founder
**Learning Complexity**: Moderate - requires combination of theory and real-world practice''',
      
      // Music
      'musik': '''
**Domain**: Seni musik dan keterampilan bermusik untuk ekspresi dan karir
**Industry Relevance**: Tinggi dalam industri entertainment, pendidikan, dan terapi
**Prerequisites**: Apresiasi musik, kesabaran untuk latihan, dan pendengaran yang baik
**Key Technologies**: Music theory, instrument techniques, recording software, performance skills
**Career Applications**: Musician, music teacher, composer, sound engineer, music therapist
**Learning Complexity**: Mudah dimulai, membutuhkan latihan rutin dan dedikasi jangka panjang''',
      
      'music': '''
**Domain**: Musical arts and skills for expression and career development
**Industry Relevance**: High in entertainment, education, and therapy industries
**Prerequisites**: Music appreciation, patience for practice, and good hearing
**Key Technologies**: Music theory, instrument techniques, recording software, performance skills
**Career Applications**: Musician, music teacher, composer, sound engineer, music therapist
**Learning Complexity**: Easy to start, requires regular practice and long-term dedication''',
      
      // Languages & Communication
      'bahasa': '''
**Domain**: Pembelajaran bahasa untuk komunikasi dan pengembangan karir global
**Industry Relevance**: Tinggi dalam era globalisasi, diplomasi, pariwisata, dan bisnis internasional
**Prerequisites**: Motivasi belajar, kesabaran, dan praktik konsisten
**Key Technologies**: Grammar rules, vocabulary building, pronunciation, cultural context, conversation practice
**Career Applications**: Translator, interpreter, language teacher, international business, tourism guide
**Learning Complexity**: Moderate - membutuhkan latihan speaking, listening, reading, dan writing secara seimbang''',
      
      'language': '''
**Domain**: Language learning for communication and global career development
**Industry Relevance**: High in globalization era, diplomacy, tourism, and international business
**Prerequisites**: Learning motivation, patience, and consistent practice
**Key Technologies**: Grammar rules, vocabulary building, pronunciation, cultural context, conversation practice
**Career Applications**: Translator, interpreter, language teacher, international business, tourism guide
**Learning Complexity**: Moderate - requires balanced practice in speaking, listening, reading, and writing''',
      
      // Health & Wellness
      'kesehatan': '''
**Domain**: Kesehatan dan wellness untuk kehidupan yang lebih baik dan karir di bidang kesehatan
**Industry Relevance**: Sangat tinggi dengan meningkatnya kesadaran kesehatan masyarakat
**Prerequisites**: Pemahaman dasar anatomi, motivasi untuk hidup sehat, dan komitmen jangka panjang
**Key Technologies**: Nutrition science, exercise physiology, mental health practices, preventive care
**Career Applications**: Nutritionist, wellness coach, health educator, fitness trainer, healthcare worker
**Learning Complexity**: Moderate - membutuhkan pemahaman ilmiah dan aplikasi praktis sehari-hari''',
      
      'health': '''
**Domain**: Health and wellness for better living and healthcare career development
**Industry Relevance**: Very high with increasing public health awareness
**Prerequisites**: Basic anatomy understanding, motivation for healthy living, and long-term commitment
**Key Technologies**: Nutrition science, exercise physiology, mental health practices, preventive care
**Career Applications**: Nutritionist, wellness coach, health educator, fitness trainer, healthcare worker
**Learning Complexity**: Moderate - requires scientific understanding and practical daily application''',
      
      // Photography & Visual Arts
      'fotografi': '''
**Domain**: Seni fotografi untuk ekspresi kreatif dan karir profesional
**Industry Relevance**: Tinggi dalam era digital, social media, marketing, dan content creation
**Prerequisites**: Mata artistik, kesabaran, dan akses ke kamera (smartphone sudah cukup untuk memulai)
**Key Technologies**: Camera techniques, composition rules, lighting, photo editing software, digital workflow
**Career Applications**: Professional photographer, content creator, social media manager, visual storyteller
**Learning Complexity**: Mudah dimulai dengan smartphone, berkembang kompleks dengan teknik advanced''',
      
      'photography': '''
**Domain**: Photography arts for creative expression and professional career
**Industry Relevance**: High in digital era, social media, marketing, and content creation
**Prerequisites**: Artistic eye, patience, and access to camera (smartphone sufficient to start)
**Key Technologies**: Camera techniques, composition rules, lighting, photo editing software, digital workflow
**Career Applications**: Professional photographer, content creator, social media manager, visual storyteller
**Learning Complexity**: Easy to start with smartphone, becomes complex with advanced techniques''',
      
      // Crafting & DIY
      'kerajinan': '''
**Domain**: Seni kerajinan tangan untuk hobi, terapi, dan peluang bisnis
**Industry Relevance**: Tinggi dalam industri kreatif, handmade market, dan therapeutic activities
**Prerequisites**: Kreativitas, kesabaran, dan keterampilan motorik halus
**Key Technologies**: Various crafting techniques, material knowledge, tool usage, design principles
**Career Applications**: Craft entrepreneur, art therapist, workshop instructor, product designer
**Learning Complexity**: Mudah dimulai dengan proyek sederhana, berkembang dengan teknik yang lebih kompleks''',
      
      'crafting': '''
**Domain**: Handicraft arts for hobby, therapy, and business opportunities
**Industry Relevance**: High in creative industries, handmade market, and therapeutic activities
**Prerequisites**: Creativity, patience, and fine motor skills
**Key Technologies**: Various crafting techniques, material knowledge, tool usage, design principles
**Career Applications**: Craft entrepreneur, art therapist, workshop instructor, product designer
**Learning Complexity**: Easy to start with simple projects, develops with more complex techniques''',
      
      // Gardening & Agriculture
      'berkebun': '''
**Domain**: Seni berkebun untuk kemandirian pangan, hobi, dan bisnis pertanian
**Industry Relevance**: Tinggi dengan tren urban farming, organic food, dan sustainability
**Prerequisites**: Kesabaran, observasi alam, dan komitmen perawatan rutin
**Key Technologies**: Plant biology, soil science, irrigation systems, pest management, harvest techniques
**Career Applications**: Urban farmer, landscape designer, agricultural consultant, organic food producer
**Learning Complexity**: Mudah dimulai dengan tanaman sederhana, berkembang dengan sistem yang kompleks''',
      
      'gardening': '''
**Domain**: Gardening arts for food independence, hobby, and agricultural business
**Industry Relevance**: High with urban farming trends, organic food, and sustainability
**Prerequisites**: Patience, nature observation, and commitment to routine care
**Key Technologies**: Plant biology, soil science, irrigation systems, pest management, harvest techniques
**Career Applications**: Urban farmer, landscape designer, agricultural consultant, organic food producer
**Learning Complexity**: Easy to start with simple plants, develops with complex systems''',
    };
    
    for (final key in contextMap.keys) {
      if (topicLower.contains(key) || key.contains(topicLower)) {
        return contextMap[key]!;
      }
    }
    
    return '''
**Domain**: Universal learning area with broad applications across personal and professional development
**Industry Relevance**: Applicable across multiple industries and personal growth contexts
**Prerequisites**: Basic curiosity and willingness to learn - no specific background required
**Key Technologies**: Learning-specific tools, techniques, and best practices for the subject area
**Career Applications**: Skill development for personal enrichment, career advancement, or professional specialization
**Learning Complexity**: Adaptable to learner's pace and background - structured approach ensures progressive mastery''';
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

  static String _getLanguageInstructions(String language) {
    switch (language.toLowerCase()) {
      case 'id':
      case 'indonesian':
        return '''
## INSTRUKSI BAHASA
PENTING: Hasilkan seluruh konten learning path dalam BAHASA INDONESIA yang natural dan mudah dipahami. 
- Gunakan terminologi teknis dalam bahasa Inggris jika diperlukan, tetapi berikan penjelasan dalam bahasa Indonesia
- Struktur kalimat harus sesuai dengan tata bahasa Indonesia yang baik dan benar
- Gunakan gaya bahasa yang ramah dan mudah dipahami untuk pembelajar Indonesia
- Semua judul, deskripsi, dan konten harus dalam bahasa Indonesia
''';

      case 'en':
      case 'english':
        return '''
## LANGUAGE INSTRUCTIONS
IMPORTANT: Generate all learning path content in NATURAL and CLEAR ENGLISH.
- Use proper English grammar and sentence structure
- Maintain a friendly and accessible tone for English-speaking learners
- Use technical terminology appropriately with clear explanations
- All titles, descriptions, and content should be in English
''';

      case 'es':
      case 'spanish':
        return '''
## INSTRUCCIONES DE IDIOMA
IMPORTANTE: Genera todo el contenido del plan de aprendizaje en ESPAÑOL NATURAL y CLARO.
- Usa gramática y estructura de oraciones apropiadas en español
- Mantén un tono amigable y accesible para estudiantes de habla hispana
- Usa terminología técnica apropiadamente con explicaciones claras
- Todos los títulos, descripciones y contenido deben estar en español
''';

      case 'fr':
      case 'french':
        return '''
## INSTRUCTIONS DE LANGUE
IMPORTANT: Générez tout le contenu du parcours d'apprentissage en FRANÇAIS NATUREL et CLAIR.
- Utilisez une grammaire française appropriée et une structure de phrase correcte
- Maintenez un ton amical et accessible pour les apprenants francophones
- Utilisez la terminologie technique de manière appropriée avec des explications claires
- Tous les titres, descriptions et contenus doivent être en français
''';

      case 'de':
      case 'german':
        return '''
## SPRACHANWEISUNGEN
WICHTIG: Erstellen Sie alle Lernpfad-Inhalte in NATÜRLICHEM und KLAREM DEUTSCH.
- Verwenden Sie angemessene deutsche Grammatik und Satzstruktur
- Behalten Sie einen freundlichen und zugänglichen Ton für deutschsprachige Lernende bei
- Verwenden Sie Fachterminologie angemessen mit klaren Erklärungen
- Alle Titel, Beschreibungen und Inhalte sollten auf Deutsch sein
''';

      case 'ja':
      case 'japanese':
        return '''
## 言語指示
重要：学習パスのすべてのコンテンツを自然で明確な日本語で生成してください。
- 適切な日本語の文法と文構造を使用してください
- 日本語学習者にとって親しみやすくアクセスしやすいトーンを維持してください
- 技術用語を適切に使用し、明確な説明を提供してください
- すべてのタイトル、説明、コンテンツは日本語である必要があります
''';

      case 'ko':
      case 'korean':
        return '''
## 언어 지침
중요: 모든 학습 경로 콘텐츠를 자연스럽고 명확한 한국어로 생성하세요.
- 적절한 한국어 문법과 문장 구조를 사용하세요
- 한국어 학습자들에게 친근하고 접근하기 쉬운 톤을 유지하세요
- 기술 용어를 적절히 사용하고 명확한 설명을 제공하세요
- 모든 제목, 설명, 콘텐츠는 한국어로 작성되어야 합니다
''';

      case 'zh':
      case 'chinese':
        return '''
## 语言说明
重要：用自然清晰的中文生成所有学习路径内容。
- 使用正确的中文语法和句子结构
- 为中文学习者保持友好和易于理解的语调
- 适当使用技术术语并提供清晰的解释
- 所有标题、描述和内容都应该用中文
''';

      case 'pt':
      case 'portuguese':
        return '''
## INSTRUÇÕES DE IDIOMA
IMPORTANTE: Gere todo o conteúdo do caminho de aprendizagem em PORTUGUÊS NATURAL e CLARO.
- Use gramática portuguesa apropriada e estrutura de frases
- Mantenha um tom amigável e acessível para estudantes de língua portuguesa
- Use terminologia técnica apropriadamente com explicações claras
- Todos os títulos, descrições e conteúdo devem estar em português
''';

      case 'ru':
      case 'russian':
        return '''
## ЯЗЫКОВЫЕ ИНСТРУКЦИИ
ВАЖНО: Создавайте весь контент учебного пути на ЕСТЕСТВЕННОМ и ПОНЯТНОМ РУССКОМ ЯЗЫКЕ.
- Используйте правильную русскую грамматику и структуру предложений
- Поддерживайте дружелюбный и доступный тон для русскоязычных учащихся
- Используйте техническую терминологию уместно с четкими объяснениями
- Все заголовки, описания и контент должны быть на русском языке
''';

      case 'ar':
      case 'arabic':
        return '''
## تعليمات اللغة
مهم: قم بإنشاء جميع محتويات مسار التعلم باللغة العربية الطبيعية والواضحة.
- استخدم القواعد النحوية العربية المناسبة وبنية الجملة
- حافظ على نبرة ودية ومتاحة للمتعلمين الناطقين بالعربية
- استخدم المصطلحات التقنية بشكل مناسب مع تفسيرات واضحة
- يجب أن تكون جميع العناوين والأوصاف والمحتوى باللغة العربية
''';

      default:
        // Default to English if language not supported
        return '''
## LANGUAGE INSTRUCTIONS
IMPORTANT: Generate all learning path content in NATURAL and CLEAR ENGLISH.
- Use proper English grammar and sentence structure
- Maintain a friendly and accessible tone for learners
- Use technical terminology appropriately with clear explanations
- All titles, descriptions, and content should be in English
''';
    }
  }
}
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../models/content_summary_model.dart';
import 'enhanced_content_extractor.dart';

/// Enhanced Summarizer Service dengan improved content extraction dan AI processing
class EnhancedSummarizerService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  /// Generate enhanced summary dengan improved content extraction
  Future<Map<String, dynamic>?> generateEnhancedSummary({
    required SummaryRequestModel request,
    Map<String, dynamic>? userPreferences,
  }) async {
    try {
      developer.log('🚀 Starting enhanced summary generation', name: 'EnhancedSummarizer');
      
      // Enhanced content processing
      final processedContent = await _processContentEnhanced(request);
      
      if (!processedContent['isSuccess']) {
        developer.log('⚠️ Content processing failed, using fallback', name: 'EnhancedSummarizer');
      }
      
      // Build enhanced prompt
      final prompt = _buildEnhancedSummaryPrompt(processedContent, request, userPreferences);
      
      // Generate summary with AI
      if (EnvConfig.hasGeminiApiKey) {
        final aiResult = await _callEnhancedGeminiAPI(prompt);
        if (aiResult != null) {
          final parsed = _parseEnhancedSummaryResponse(aiResult);
          if (parsed != null) {
            // Enhance with metadata dan quality metrics
            return _enhanceWithMetadata(parsed, processedContent, request);
          }
        }
      }
      
      // Fallback to enhanced local processing
      return _generateEnhancedFallbackSummary(processedContent, request);
      
    } catch (e) {
      developer.log('❌ Enhanced summary generation failed: $e', name: 'EnhancedSummarizer');
      return _generateErrorSummary(request, e.toString());
    }
  }

  /// Process content dengan enhanced extraction
  Future<Map<String, dynamic>> _processContentEnhanced(SummaryRequestModel request) async {
    if (request.contentType == ContentType.url && request.contentSource != null) {
      developer.log('📥 Processing URL content with enhanced extractor', name: 'EnhancedSummarizer');
      
      // Use enhanced content extractor
      final extracted = await EnhancedContentExtractor.extractFromUrl(request.contentSource!);
      
      // Merge dengan original content jika ada
      if (request.content.isNotEmpty) {
        extracted['content'] = '${extracted['content']}\n\n--- Additional Context ---\n${request.content}';
      }
      
      return extracted;
    } else {
      // Process text content
      return {
        'content': request.content,
        'title': request.title ?? 'Text Content',
        'isSuccess': true,
        'wordCount': _countWords(request.content),
        'readingTime': _estimateReadingTime(request.content),
        'metadata': {
          'type': 'text_content',
          'processedAt': DateTime.now().toIso8601String(),
        },
      };
    }
  }

  /// Build enhanced summary prompt dengan better context
  String _buildEnhancedSummaryPrompt(
    Map<String, dynamic> contentData,
    SummaryRequestModel request,
    Map<String, dynamic>? userPreferences,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('# EXPERT CONTENT ANALYZER & INTELLIGENT SUMMARIZER');
    buffer.writeln();
    buffer.writeln('You are an advanced AI content analyst with expertise in information extraction, knowledge synthesis, and educational content creation.');
    buffer.writeln();
    
    // Content context
    buffer.writeln('## CONTENT ANALYSIS CONTEXT');
    buffer.writeln('**Content Type**: ${_getContentTypeDescription(contentData)}');
    buffer.writeln('**Word Count**: ${contentData['wordCount'] ?? 'Unknown'}');
    buffer.writeln('**Estimated Reading Time**: ${contentData['readingTime'] ?? 'Unknown'} minutes');
    
    if (contentData['metadata'] != null) {
      final metadata = contentData['metadata'] as Map<String, dynamic>;
      if (metadata['author'] != null) {
        buffer.writeln('**Author**: ${metadata['author']}');
      }
      if (metadata['publishDate'] != null) {
        buffer.writeln('**Published**: ${metadata['publishDate']}');
      }
      if (metadata['domain'] != null) {
        buffer.writeln('**Source**: ${metadata['domain']}');
      }
    }
    buffer.writeln();
    
    // User preferences
    if (userPreferences != null) {
      buffer.writeln('## USER PREFERENCES');
      if (userPreferences['focusAreas'] != null) {
        buffer.writeln('**Focus Areas**: ${userPreferences['focusAreas']}');
      }
      if (userPreferences['summaryStyle'] != null) {
        buffer.writeln('**Preferred Style**: ${userPreferences['summaryStyle']}');
      }
      buffer.writeln();
    }
    
    // Target difficulty
    if (request.targetDifficulty != null) {
      buffer.writeln('## TARGET AUDIENCE');
      buffer.writeln('**Difficulty Level**: ${request.targetDifficulty!.value}');
      buffer.writeln(_getDifficultyInstructions(request.targetDifficulty!));
      buffer.writeln();
    }
    
    // Custom instructions
    if (request.customInstructions != null && request.customInstructions!.isNotEmpty) {
      buffer.writeln('## SPECIAL INSTRUCTIONS');
      buffer.writeln(request.customInstructions);
      buffer.writeln();
    }
    
    // Analysis requirements
    buffer.writeln('## ANALYSIS REQUIREMENTS');
    buffer.writeln();
    buffer.writeln('### Deep Content Analysis:');
    buffer.writeln('1. **Main Themes**: Identify core concepts and central arguments');
    buffer.writeln('2. **Key Insights**: Extract actionable takeaways and important findings');
    buffer.writeln('3. **Supporting Evidence**: Note important data, examples, or case studies');
    buffer.writeln('4. **Practical Applications**: Identify real-world uses and implementations');
    buffer.writeln('5. **Knowledge Gaps**: Highlight areas that need additional context');
    buffer.writeln();
    
    buffer.writeln('### Quality Standards:');
    buffer.writeln('- Maintain accuracy and factual integrity');
    buffer.writeln('- Preserve important nuances and context');
    buffer.writeln('- Use clear, engaging language appropriate for the target audience');
    buffer.writeln('- Focus on practical value and actionable insights');
    buffer.writeln('- Ensure logical flow and coherent structure');
    buffer.writeln();
    
    // Output format
    buffer.writeln('## OUTPUT FORMAT');
    buffer.writeln('Return ONLY a valid JSON object with this structure:');
    buffer.writeln();
    buffer.writeln('''{
  "title": "Engaging, descriptive title that captures the essence",
  "summary": "Comprehensive summary (200-500 words) with main ideas and insights",
  "key_points": [
    "Specific, actionable insight #1",
    "Important finding #2 with practical application",
    "Critical concept #3 with real-world relevance"
  ],
  "main_themes": [
    "Core theme #1",
    "Central concept #2",
    "Key area #3"
  ],
  "practical_applications": [
    "Real-world use case #1",
    "Implementation strategy #2",
    "Practical tip #3"
  ],
  "target_audience": "Who would benefit most from this content",
  "difficulty_level": "beginner|intermediate|advanced",
  "confidence_score": 0.95,
  "estimated_read_time": 8,
  "content_quality": "high|medium|low",
  "learning_objectives": [
    "What readers will learn #1",
    "Key skill or knowledge #2",
    "Understanding they'll gain #3"
  ]
}''');
    buffer.writeln();
    
    // Content to analyze
    buffer.writeln('## CONTENT TO ANALYZE');
    buffer.writeln('═' * 50);
    buffer.writeln();
    
    final content = contentData['content']?.toString() ?? request.content;
    final maxLength = 8000; // Limit content length for API
    
    if (content.length > maxLength) {
      buffer.writeln('${content.substring(0, maxLength)}...');
      buffer.writeln();
      buffer.writeln('[Content truncated due to length. Original length: ${content.length} characters]');
    } else {
      buffer.writeln(content);
    }
    
    return buffer.toString();
  }

  /// Get content type description
  String _getContentTypeDescription(Map<String, dynamic> contentData) {
    final metadata = contentData['metadata'] as Map<String, dynamic>?;
    if (metadata == null) return 'Text Content';
    
    switch (metadata['type']) {
      case 'youtube_video':
        return 'YouTube Video';
      case 'web_content':
        return 'Web Article';
      case 'text_content':
        return 'Text Content';
      default:
        return 'Mixed Content';
    }
  }

  /// Get difficulty-specific instructions
  String _getDifficultyInstructions(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return '''
**Beginner-Friendly Approach**:
- Use simple, clear language and avoid jargon
- Explain technical terms when necessary
- Provide context and background information
- Focus on fundamental concepts and basic understanding
- Include analogies and relatable examples''';
      
      case DifficultyLevel.intermediate:
        return '''
**Intermediate Level Approach**:
- Use moderate technical language with explanations
- Build on assumed foundational knowledge
- Focus on practical applications and implementation
- Include some advanced concepts with proper context
- Balance theory with real-world examples''';
      
      case DifficultyLevel.advanced:
        return '''
**Advanced Level Approach**:
- Use technical language appropriate for experts
- Assume strong foundational knowledge
- Focus on complex concepts, optimization, and best practices
- Include industry-specific terminology and advanced techniques
- Emphasize strategic thinking and architectural considerations''';
    }
  }

  /// Call enhanced Gemini API dengan optimized parameters
  Future<Map<String, dynamic>?> _callEnhancedGeminiAPI(String prompt) async {
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
            'temperature': 0.3, // Lower for more focused, analytical responses
            'topK': 20, // More focused vocabulary
            'topP': 0.8, // Balanced creativity and consistency
            'maxOutputTokens': 4096, // Sufficient for detailed summaries
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
      ).timeout(Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates']?.isNotEmpty == true) {
          return data;
        }
      } else {
        developer.log('Gemini API error: ${response.statusCode} - ${response.body}', name: 'EnhancedSummarizer');
      }
    } catch (e) {
      developer.log('Enhanced Gemini API call failed: $e', name: 'EnhancedSummarizer');
    }
    
    return null;
  }

  /// Parse enhanced summary response dari AI
  Map<String, dynamic>? _parseEnhancedSummaryResponse(Map<String, dynamic> response) {
    try {
      final generatedText = response['candidates'][0]['content']['parts'][0]['text'];
      
      // Clean and extract JSON
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
      
      // Validate required fields
      return _validateAndEnhanceSummaryStructure(parsed);
      
    } catch (e) {
      developer.log('Error parsing enhanced summary response: $e', name: 'EnhancedSummarizer');
      return null;
    }
  }

  /// Validate dan enhance summary structure
  Map<String, dynamic> _validateAndEnhanceSummaryStructure(Map<String, dynamic> parsed) {
    // Ensure required fields exist
    parsed['title'] ??= 'Content Summary';
    parsed['summary'] ??= 'Summary not available';
    parsed['key_points'] ??= [];
    parsed['main_themes'] ??= [];
    parsed['practical_applications'] ??= [];
    parsed['difficulty_level'] ??= 'intermediate';
    parsed['confidence_score'] ??= 0.8;
    parsed['estimated_read_time'] ??= 5;
    parsed['content_quality'] ??= 'medium';
    parsed['learning_objectives'] ??= [];
    
    // Ensure arrays are properly formatted
    parsed['key_points'] = _ensureStringArray(parsed['key_points']);
    parsed['main_themes'] = _ensureStringArray(parsed['main_themes']);
    parsed['practical_applications'] = _ensureStringArray(parsed['practical_applications']);
    parsed['learning_objectives'] = _ensureStringArray(parsed['learning_objectives']);
    
    // Validate confidence score
    if (parsed['confidence_score'] is! num || 
        parsed['confidence_score'] < 0 || 
        parsed['confidence_score'] > 1) {
      parsed['confidence_score'] = 0.8;
    }
    
    // Validate estimated read time
    if (parsed['estimated_read_time'] is! int || parsed['estimated_read_time'] < 1) {
      parsed['estimated_read_time'] = 5;
    }
    
    return parsed;
  }

  /// Ensure array contains strings
  List<String> _ensureStringArray(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  /// Enhance summary dengan metadata dan quality metrics
  Map<String, dynamic> _enhanceWithMetadata(
    Map<String, dynamic> summary,
    Map<String, dynamic> contentData,
    SummaryRequestModel request,
  ) {
    // Add generation metadata
    summary['generation_metadata'] = {
      'generated_at': DateTime.now().toIso8601String(),
      'content_source': request.contentSource,
      'content_type': request.contentType.value,
      'extraction_success': contentData['isSuccess'] ?? false,
      'original_word_count': contentData['wordCount'] ?? 0,
      'processing_method': 'enhanced_ai',
    };
    
    // Add content metadata if available
    if (contentData['metadata'] != null) {
      summary['source_metadata'] = contentData['metadata'];
    }
    
    // Add quality metrics
    summary['quality_metrics'] = {
      'content_extraction_quality': _calculateExtractionQuality(contentData),
      'summary_completeness': _calculateSummaryCompleteness(summary),
      'information_density': _calculateInformationDensity(summary, contentData),
    };
    
    // Add personalized tags
    summary['personalized_tags'] = _generatePersonalizedTags(summary, request);
    
    return summary;
  }

  /// Calculate extraction quality score
  double _calculateExtractionQuality(Map<String, dynamic> contentData) {
    double score = 0.0;
    
    // Base success score
    if (contentData['isSuccess'] == true) score += 0.4;
    
    // Content length score
    final wordCount = contentData['wordCount'] as int? ?? 0;
    if (wordCount > 100) score += 0.2;
    if (wordCount > 500) score += 0.2;
    
    // Metadata completeness
    final metadata = contentData['metadata'] as Map<String, dynamic>?;
    if (metadata != null) {
      if (metadata['title'] != null) score += 0.1;
      if (metadata['author'] != null) score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate summary completeness score
  double _calculateSummaryCompleteness(Map<String, dynamic> summary) {
    double score = 0.0;
    
    // Required fields
    if (summary['title']?.toString().isNotEmpty == true) score += 0.2;
    if (summary['summary']?.toString().isNotEmpty == true) score += 0.3;
    
    // Optional but valuable fields
    final keyPoints = summary['key_points'] as List? ?? [];
    if (keyPoints.isNotEmpty) score += 0.2;
    
    final themes = summary['main_themes'] as List? ?? [];
    if (themes.isNotEmpty) score += 0.15;
    
    final applications = summary['practical_applications'] as List? ?? [];
    if (applications.isNotEmpty) score += 0.15;
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate information density score
  double _calculateInformationDensity(
    Map<String, dynamic> summary,
    Map<String, dynamic> contentData,
  ) {
    final summaryLength = summary['summary']?.toString().length ?? 0;
    final originalLength = contentData['content']?.toString().length ?? 1;
    
    if (originalLength == 0) return 0.0;
    
    final compressionRatio = summaryLength / originalLength;
    
    // Optimal compression ratio is around 0.1-0.3 (10-30% of original)
    if (compressionRatio >= 0.1 && compressionRatio <= 0.3) {
      return 1.0;
    } else if (compressionRatio < 0.1) {
      return compressionRatio / 0.1; // Too compressed
    } else {
      return 0.3 / compressionRatio; // Not compressed enough
    }
  }

  /// Generate personalized tags berdasarkan content dan user preferences
  List<String> _generatePersonalizedTags(
    Map<String, dynamic> summary,
    SummaryRequestModel request,
  ) {
    final tags = <String>[];
    
    // Add content type tag
    tags.add(request.contentType.value);
    
    // Add difficulty level tag
    if (summary['difficulty_level'] != null) {
      tags.add(summary['difficulty_level'].toString());
    }
    
    // Extract tags dari main themes
    final themes = summary['main_themes'] as List? ?? [];
    for (final theme in themes.take(3)) {
      final words = theme.toString().toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 3 && !tags.contains(word)) {
          tags.add(word);
        }
      }
    }
    
    // Add domain-specific tags
    if (request.contentSource != null) {
      try {
        final domain = Uri.parse(request.contentSource!).host;
        if (domain.isNotEmpty) {
          tags.add(domain.replaceAll('www.', ''));
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    return tags.take(8).toList(); // Limit to 8 tags
  }

  /// Generate enhanced fallback summary
  Map<String, dynamic> _generateEnhancedFallbackSummary(
    Map<String, dynamic> contentData,
    SummaryRequestModel request,
  ) {
    final content = contentData['content']?.toString() ?? request.content;
    final wordCount = _countWords(content);
    
    // Enhanced extractive summarization
    final sentences = _extractSentences(content);
    final importantSentences = _selectImportantSentences(sentences, 3);
    final summary = importantSentences.join(' ');
    
    // Extract key points using simple heuristics
    final keyPoints = _extractKeyPointsHeuristic(content);
    
    // Extract themes using keyword analysis
    final themes = _extractThemesHeuristic(content);
    
    return {
      'title': request.title ?? contentData['title'] ?? 'Content Summary',
      'summary': summary.isNotEmpty ? summary : 'Summary not available due to content extraction issues.',
      'key_points': keyPoints,
      'main_themes': themes,
      'practical_applications': _extractApplicationsHeuristic(content),
      'target_audience': _determineTargetAudience(content),
      'difficulty_level': request.targetDifficulty?.value ?? 'intermediate',
      'confidence_score': contentData['isSuccess'] == true ? 0.7 : 0.4,
      'estimated_read_time': _estimateReadingTime(content),
      'content_quality': _assessContentQuality(content),
      'learning_objectives': _extractLearningObjectives(content),
      'generation_metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'processing_method': 'enhanced_fallback',
        'content_source': request.contentSource,
        'content_type': request.contentType.value,
      },
    };
  }

  /// Generate error summary
  Map<String, dynamic> _generateErrorSummary(SummaryRequestModel request, String error) {
    return {
      'title': 'Summary Generation Failed',
      'summary': 'Unable to generate summary due to technical issues. Please try again or provide the content manually.',
      'key_points': ['Content extraction failed', 'Manual input recommended'],
      'main_themes': ['Technical Error'],
      'practical_applications': ['Try copying content manually', 'Check URL accessibility'],
      'target_audience': 'General',
      'difficulty_level': 'beginner',
      'confidence_score': 0.0,
      'estimated_read_time': 1,
      'content_quality': 'low',
      'learning_objectives': ['Understand the limitation', 'Try alternative approaches'],
      'generation_metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'processing_method': 'error_fallback',
        'error': error,
        'content_source': request.contentSource,
        'content_type': request.contentType.value,
      },
    };
  }

  // Utility methods
  int _countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  int _estimateReadingTime(String text) {
    final wordCount = _countWords(text);
    return (wordCount / 200).ceil(); // 200 words per minute
  }

  List<String> _extractSentences(String text) {
    return text.split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 20)
        .toList();
  }

  List<String> _selectImportantSentences(List<String> sentences, int count) {
    // Simple heuristic: prefer longer sentences and those with keywords
    final keywords = ['important', 'key', 'main', 'significant', 'crucial', 'essential'];
    
    sentences.sort((a, b) {
      int scoreA = a.length;
      int scoreB = b.length;
      
      for (final keyword in keywords) {
        if (a.toLowerCase().contains(keyword)) scoreA += 50;
        if (b.toLowerCase().contains(keyword)) scoreB += 50;
      }
      
      return scoreB.compareTo(scoreA);
    });
    
    return sentences.take(count).toList();
  }

  List<String> _extractKeyPointsHeuristic(String content) {
    final sentences = _extractSentences(content);
    return _selectImportantSentences(sentences, 5);
  }

  List<String> _extractThemesHeuristic(String content) {
    // Simple keyword extraction
    final words = content.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 4)
        .toList();
    
    final wordCount = <String, int>{};
    for (final word in words) {
      wordCount[word] = (wordCount[word] ?? 0) + 1;
    }
    
    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords.take(5).map((entry) => entry.key).toList();
  }

  List<String> _extractApplicationsHeuristic(String content) {
    final sentences = content.split('.')
        .where((s) => s.toLowerCase().contains(RegExp(r'\b(use|apply|implement|practice)\b')))
        .take(3)
        .map((s) => s.trim())
        .toList();
    
    return sentences.isNotEmpty ? sentences : ['Practical applications to be determined'];
  }

  String _determineTargetAudience(String content) {
    final technicalTerms = RegExp(r'\b(API|algorithm|framework|implementation|architecture)\b', caseSensitive: false);
    final basicTerms = RegExp(r'\b(learn|understand|basic|simple|introduction)\b', caseSensitive: false);
    
    if (technicalTerms.allMatches(content).length > 5) {
      return 'Technical professionals and developers';
    } else if (basicTerms.allMatches(content).length > 3) {
      return 'Beginners and general audience';
    } else {
      return 'General audience with some background knowledge';
    }
  }

  String _assessContentQuality(String content) {
    final wordCount = _countWords(content);
    final sentences = _extractSentences(content);
    
    if (wordCount > 500 && sentences.length > 10) {
      return 'high';
    } else if (wordCount > 200 && sentences.length > 5) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  List<String> _extractLearningObjectives(String content) {
    final objectives = <String>[];
    
    // Look for explicit learning objectives
    final objectivePatterns = [
      RegExp(r'you will learn (.*?)\.', caseSensitive: false),
      RegExp(r'this (article|post|content) covers (.*?)\.', caseSensitive: false),
      RegExp(r'by the end.*?you.*?(will|can) (.*?)\.', caseSensitive: false),
    ];
    
    for (final pattern in objectivePatterns) {
      final matches = pattern.allMatches(content);
      for (final match in matches.take(3)) {
        if (match.groupCount > 0) {
          objectives.add(match.group(match.groupCount)!.trim());
        }
      }
    }
    
    // Fallback to generic objectives
    if (objectives.isEmpty) {
      objectives.addAll([
        'Understand the main concepts presented',
        'Gain insights into practical applications',
        'Learn key takeaways and best practices',
      ]);
    }
    
    return objectives.take(5).toList();
  }
}
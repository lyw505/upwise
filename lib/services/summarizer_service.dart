import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../models/content_summary_model.dart';

class SummarizerService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  /// Extract content from URL (including YouTube)
  Future<String?> extractContentFromUrl(String url) async {
    try {
      // Handle YouTube URLs
      if (_isYouTubeUrl(url)) {
        return await _extractYouTubeContent(url);
      }
      
      // Handle regular web URLs
      return await _extractWebContent(url);
      
    } catch (e) {
      developer.log('Error extracting content from URL: $e', name: 'SummarizerService');
      return null;
    }
  }
  
  /// Check if URL is a YouTube URL
  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }
  
  /// Extract content from YouTube URL
  Future<String?> _extractYouTubeContent(String url) async {
    try {
      // For YouTube, we'll use the URL as a description and let AI know it's a video
      final videoId = _extractYouTubeVideoId(url);
      if (videoId != null) {
        return 'YouTube Video URL: $url\nVideo ID: $videoId\nNote: This is a YouTube video. Please provide a summary request for this video content.'
            '\n\nTo get the best summary, please describe what the video is about or paste the video transcript if available.';
      }
      return 'YouTube Video: $url\nNote: This is a YouTube video URL. For better summarization, please provide the video transcript or description.';
    } catch (e) {
      return 'YouTube Video: $url';
    }
  }
  
  /// Extract YouTube video ID from URL
  String? _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
    } catch (e) {
      developer.log('Error extracting YouTube video ID: $e', name: 'SummarizerService');
    }
    return null;
  }
  
  /// Extract content from regular web URL
  Future<String?> _extractWebContent(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Basic HTML content extraction
        String content = response.body;
        
        // Remove HTML tags and extract text content
        content = _extractTextFromHtml(content);
        
        return content.isNotEmpty ? content : 'Web content from: $url';
      }
    } catch (e) {
      developer.log('Error extracting web content: $e', name: 'SummarizerService');
    }
    
    return 'Web Article from: $url\nNote: Unable to extract content automatically. Please paste the article text for better summarization.';
  }
  
  /// Extract text content from HTML
  String _extractTextFromHtml(String html) {
    try {
      // Remove script and style tags
      html = html.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');
      html = html.replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '');
      
      // Remove HTML tags
      html = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
      
      // Clean up whitespace
      html = html.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      // Limit content length
      if (html.length > 5000) {
        html = html.substring(0, 5000) + '...';
      }
      
      return html;
    } catch (e) {
      return '';
    }
  }
  
  /// Generate AI-powered summary from content
  Future<Map<String, dynamic>?> generateSummary({
    required SummaryRequestModel request,
  }) async {
    try {
      // Check if Gemini API key is available
      if (!EnvConfig.hasGeminiApiKey) {
        developer.log('Gemini API key not configured, using fallback', name: 'SummarizerService');
        return _generateFallbackSummary(request);
      }

      // Process content based on type
      String processedContent = request.content;
      
      // If it's a URL, try to extract content
      if (request.contentType == ContentType.url && request.contentSource != null) {
        final extractedContent = await extractContentFromUrl(request.contentSource!);
        if (extractedContent != null && extractedContent.isNotEmpty) {
          processedContent = extractedContent;
        }
      }

      // Create modified request with processed content
      final processedRequest = SummaryRequestModel(
        title: request.title,
        content: processedContent,
        contentType: request.contentType,
        contentSource: request.contentSource,
        targetDifficulty: request.targetDifficulty,
        maxSummaryLength: request.maxSummaryLength,
        customInstructions: request.customInstructions,
        learningPathId: request.learningPathId,
      );

      final prompt = _buildSummaryPrompt(processedRequest);
      
      developer.log('Generating AI summary for content type: ${request.contentType.value}', name: 'SummarizerService');
      
      final response = await _callGeminiApi(prompt);
      
      if (response != null) {
        final parsedSummary = _parseSummaryResponse(response, processedRequest);
        if (parsedSummary != null) {
          developer.log('Successfully generated AI summary', name: 'SummarizerService');
          return parsedSummary;
        }
      }
      
      // Fallback if AI generation fails
      developer.log('AI summary generation failed, using fallback', name: 'SummarizerService');
      return _generateFallbackSummary(processedRequest);
      
    } catch (e) {
      developer.log('Error generating summary: $e', name: 'SummarizerService');
      return _generateFallbackSummary(request);
    }
  }

  /// Extract key points from content using AI
  Future<List<String>> extractKeyPoints({
    required String content,
    int maxPoints = 5,
  }) async {
    try {
      if (!EnvConfig.hasGeminiApiKey) {
        return _extractFallbackKeyPoints(content, maxPoints);
      }

      final prompt = _buildKeyPointsPrompt(content, maxPoints);
      final response = await _callGeminiApi(prompt);
      
      if (response != null) {
        final keyPoints = _parseKeyPointsResponse(response);
        if (keyPoints.isNotEmpty) {
          return keyPoints;
        }
      }
      
      return _extractFallbackKeyPoints(content, maxPoints);
      
    } catch (e) {
      developer.log('Error extracting key points: $e', name: 'SummarizerService');
      return _extractFallbackKeyPoints(content, maxPoints);
    }
  }

  /// Auto-suggest tags for content
  Future<List<String>> suggestTags({
    required String content,
    int maxTags = 5,
  }) async {
    try {
      if (!EnvConfig.hasGeminiApiKey) {
        return _generateFallbackTags(content, maxTags);
      }

      final prompt = _buildTagsPrompt(content, maxTags);
      final response = await _callGeminiApi(prompt);
      
      if (response != null) {
        final tags = _parseTagsResponse(response);
        if (tags.isNotEmpty) {
          return tags;
        }
      }
      
      return _generateFallbackTags(content, maxTags);
      
    } catch (e) {
      developer.log('Error suggesting tags: $e', name: 'SummarizerService');
      return _generateFallbackTags(content, maxTags);
    }
  }

  /// Call Gemini API with prompt
  Future<String?> _callGeminiApi(String prompt) async {
    try {
      final apiKey = EnvConfig.geminiApiKey;
      final url = Uri.parse('$_baseUrl?key=$apiKey');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        Duration(seconds: EnvConfig.apiTimeout),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          return content?.toString();
        }
      } else {
        developer.log('Gemini API error: ${response.statusCode} - ${response.body}', name: 'SummarizerService');
      }
    } catch (e) {
      developer.log('Error calling Gemini API: $e', name: 'SummarizerService');
    }
    
    return null;
  }

  /// Build comprehensive summary prompt
  String _buildSummaryPrompt(SummaryRequestModel request) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are an expert content summarizer and educational assistant.');
    buffer.writeln('Your task is to create a comprehensive, accurate, and well-structured summary.');
    buffer.writeln();
    
    // Content type specific instructions
    switch (request.contentType) {
      case ContentType.url:
        if (request.contentSource != null && _isYouTubeUrl(request.contentSource!)) {
          buffer.writeln('The content is from a YouTube video URL.');
          buffer.writeln('Create a summary based on the video information provided.');
          buffer.writeln('If transcript or description is available, use it for detailed analysis.');
          buffer.writeln('Focus on educational value and key learning points.');
        } else {
          buffer.writeln('The content is from a web article/URL.');
          buffer.writeln('Extract the main ideas, arguments, and important information.');
        }
        break;
      case ContentType.file:
        buffer.writeln('The content is from a file/document (PDF, text, etc.).');
        buffer.writeln('Analyze the document structure and extract key information.');
        buffer.writeln('Identify main topics, conclusions, and important details.');
        break;
      case ContentType.text:
        buffer.writeln('The content is plain text or pasted content.');
        buffer.writeln('Analyze and summarize the main ideas and concepts.');
        break;
    }
    
    // Difficulty level instructions
    if (request.targetDifficulty != null) {
      buffer.writeln('Target audience level: ${request.targetDifficulty!.value}');
      buffer.writeln('Adjust language and complexity accordingly.');
      switch (request.targetDifficulty!) {
        case DifficultyLevel.beginner:
          buffer.writeln('Use simple language and explain technical terms.');
          break;
        case DifficultyLevel.intermediate:
          buffer.writeln('Use moderate complexity with some technical terms.');
          break;
        case DifficultyLevel.advanced:
          buffer.writeln('Use technical language appropriate for experts.');
          break;
      }
    }
    
    // Length constraints
    if (request.maxSummaryLength != null) {
      buffer.writeln('Keep summary under ${request.maxSummaryLength} words.');
    } else {
      buffer.writeln('Create a comprehensive summary (200-500 words).');
    }
    
    // Custom instructions
    if (request.customInstructions != null && request.customInstructions!.isNotEmpty) {
      buffer.writeln('Special instructions: ${request.customInstructions}');
    }
    
    buffer.writeln();
    buffer.writeln('IMPORTANT: Provide meaningful content analysis, not just metadata.');
    buffer.writeln('Extract actual insights, main arguments, and educational value.');
    buffer.writeln('Generate relevant tags based on topics, not just URLs or filenames.');
    buffer.writeln();
    buffer.writeln('RESPONSE FORMAT (JSON only):');
    buffer.writeln('{');
    buffer.writeln('  "title": "Descriptive title based on content",');
    buffer.writeln('  "summary": "Comprehensive summary with main ideas and insights",');
    buffer.writeln('  "key_points": ["Specific actionable point", "Key insight", "Important concept"],');
    buffer.writeln('  "tags": ["topic-based-tag", "subject-area", "concept"],');
    buffer.writeln('  "difficulty_level": "beginner|intermediate|advanced",');
    buffer.writeln('  "estimated_read_time": 5');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('CONTENT TO SUMMARIZE:');
    buffer.writeln(request.content);
    
    return buffer.toString();
  }

  /// Build key points extraction prompt
  String _buildKeyPointsPrompt(String content, int maxPoints) {
    return '''
Extract the $maxPoints most important key points from this content.
Focus on main concepts, important facts, and actionable insights.

RESPONSE FORMAT (JSON array only):
["Key point 1", "Key point 2", "Key point 3"]

CONTENT:
$content
''';
  }

  /// Build tags suggestion prompt
  String _buildTagsPrompt(String content, int maxTags) {
    return '''
Suggest $maxTags relevant tags for this content.
Tags should be single words or short phrases that categorize the content.
Focus on topics, concepts, technologies, or subject areas mentioned.

RESPONSE FORMAT (JSON array only):
["tag1", "tag2", "tag3"]

CONTENT:
$content
''';
  }

  /// Parse summary response from AI
  Map<String, dynamic>? _parseSummaryResponse(String response, SummaryRequestModel request) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final data = json.decode(jsonString) as Map<String, dynamic>;
        
        return {
          'title': data['title'] ?? request.title ?? 'Untitled Summary',
          'summary': data['summary'] ?? '',
          'key_points': _parseStringList(data['key_points']),
          'tags': _parseStringList(data['tags']),
          'difficulty_level': data['difficulty_level'] ?? 'beginner',
          'estimated_read_time': data['estimated_read_time'] ?? 5,
        };
      }
    } catch (e) {
      developer.log('Error parsing AI summary response: $e', name: 'SummarizerService');
    }
    
    return null;
  }

  /// Parse key points response
  List<String> _parseKeyPointsResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final list = json.decode(jsonString) as List;
        return list.map((item) => item.toString()).toList();
      }
    } catch (e) {
      developer.log('Error parsing key points response: $e', name: 'SummarizerService');
    }
    
    return [];
  }

  /// Parse tags response
  List<String> _parseTagsResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final list = json.decode(jsonString) as List;
        return list.map((item) => item.toString()).toList();
      }
    } catch (e) {
      developer.log('Error parsing tags response: $e', name: 'SummarizerService');
    }
    
    return [];
  }

  /// Generate fallback summary when AI is not available
  Map<String, dynamic> _generateFallbackSummary(SummaryRequestModel request) {
    final content = request.content;
    final wordCount = ContentSummaryModel.calculateWordCount(content);
    
    // Simple extractive summary (first few sentences)
    final sentences = content.split(RegExp(r'[.!?]+'));
    final summaryLength = (sentences.length * 0.3).round().clamp(1, 5);
    final summary = sentences.take(summaryLength).join('. ').trim();
    
    return {
      'title': request.title ?? 'Content Summary',
      'summary': summary.isNotEmpty ? summary : 'Summary not available',
      'key_points': _extractFallbackKeyPoints(content, 3),
      'tags': _generateFallbackTags(content, 3),
      'difficulty_level': request.targetDifficulty?.value ?? 'intermediate',
      'estimated_read_time': ContentSummaryModel.estimateReadingTime(wordCount),
    };
  }

  /// Extract key points using simple text analysis
  List<String> _extractFallbackKeyPoints(String content, int maxPoints) {
    final sentences = content.split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
    
    // Simple heuristic: longer sentences often contain key information
    sentences.sort((a, b) => b.length.compareTo(a.length));
    
    return sentences
        .take(maxPoints)
        .map((s) => s.length > 100 ? '${s.substring(0, 100)}...' : s)
        .toList();
  }

  /// Generate basic tags using keyword extraction
  List<String> _generateFallbackTags(String content, int maxTags) {
    final words = content
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .toList();
    
    // Count word frequency
    final wordCount = <String, int>{};
    for (final word in words) {
      wordCount[word] = (wordCount[word] ?? 0) + 1;
    }
    
    // Get most frequent words as tags
    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords
        .take(maxTags)
        .map((entry) => entry.key)
        .toList();
  }

  /// Helper method to parse string list
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }
}

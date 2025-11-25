import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// Enhanced content extractor dengan multiple extraction methods dan better error handling
class EnhancedContentExtractor {
  static const Duration _timeout = Duration(seconds: 20);
  static const int _maxRetries = 3;
  
  /// Extract content dari URL dengan multiple fallback methods
  static Future<Map<String, dynamic>> extractFromUrl(String url) async {
    try {
      developer.log('🔍 Starting enhanced content extraction from: $url', name: 'EnhancedExtractor');
      
      // Validate URL
      if (!_isValidUrl(url)) {
        throw Exception('Invalid URL format');
      }
      
      // Determine content type dan use appropriate extractor
      if (_isYouTubeUrl(url)) {
        return await _extractYouTubeContentEnhanced(url);
      } else if (_isTwitterUrl(url)) {
        return await _extractTwitterContent(url);
      } else if (_isMediumUrl(url)) {
        return await _extractMediumContent(url);
      } else if (_isGitHubUrl(url)) {
        return await _extractGitHubContent(url);
      } else {
        return await _extractWebContentEnhanced(url);
      }
      
    } catch (e) {
      developer.log('❌ Enhanced extraction failed: $e', name: 'EnhancedExtractor');
      return _createErrorFallback(url, e.toString());
    }
  }

  /// Enhanced YouTube content extraction dengan multiple methods
  static Future<Map<String, dynamic>> _extractYouTubeContentEnhanced(String url) async {
    developer.log('🎥 Extracting YouTube content with enhanced methods', name: 'EnhancedExtractor');
    
    final videoId = _extractYouTubeVideoId(url);
    if (videoId == null) {
      throw Exception('Could not extract YouTube video ID');
    }
    
    // Try multiple extraction methods
    final extractionMethods = [
      () => _extractFromYouTubeOEmbed(videoId),
      () => _extractFromYouTubePage(url),
      () => _extractFromYouTubeAPI(videoId), // If API key available
    ];
    
    Map<String, dynamic>? bestResult;
    final errors = <String>[];
    
    for (final method in extractionMethods) {
      try {
        final result = await method();
        if (result['isSuccess'] == true) {
          bestResult = _mergeYouTubeResults(bestResult, result);
          if (_isCompleteYouTubeData(bestResult)) {
            break; // We have enough data
          }
        }
      } catch (e) {
        errors.add(e.toString());
        continue;
      }
    }
    
    if (bestResult != null && bestResult['isSuccess'] == true) {
      developer.log('✅ YouTube extraction successful', name: 'EnhancedExtractor');
      return _enhanceYouTubeContent(bestResult, url, videoId);
    }
    
    // All methods failed
    developer.log('⚠️ All YouTube extraction methods failed', name: 'EnhancedExtractor');
    return _createYouTubeFallback(url, videoId, errors);
  }

  /// Extract menggunakan YouTube oEmbed API (no API key required)
  static Future<Map<String, dynamic>> _extractFromYouTubeOEmbed(String videoId) async {
    final oembedUrl = 'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';
    
    final response = await http.get(
      Uri.parse(oembedUrl),
      headers: _getHeaders(),
    ).timeout(_timeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'title': data['title'] ?? 'YouTube Video',
        'author': data['author_name'] ?? 'Unknown Channel',
        'thumbnail': data['thumbnail_url'],
        'width': data['width'],
        'height': data['height'],
        'provider': 'YouTube',
        'isSuccess': true,
        'method': 'oEmbed',
      };
    }
    
    throw Exception('oEmbed API returned ${response.statusCode}');
  }

  /// Extract dari YouTube page HTML
  static Future<Map<String, dynamic>> _extractFromYouTubePage(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    ).timeout(_timeout);
    
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    
    final document = html_parser.parse(response.body);
    
    // Extract dari meta tags
    final title = _extractMetaContent(document, [
      'meta[property="og:title"]',
      'meta[name="twitter:title"]',
      'title'
    ]) ?? 'YouTube Video';
    
    final description = _extractMetaContent(document, [
      'meta[property="og:description"]',
      'meta[name="twitter:description"]',
      'meta[name="description"]'
    ]) ?? '';
    
    final thumbnail = _extractMetaContent(document, [
      'meta[property="og:image"]',
      'meta[name="twitter:image"]'
    ]);
    
    final author = _extractMetaContent(document, [
      'meta[name="author"]',
      'link[itemprop="name"]'
    ]);
    
    // Try to extract duration dari structured data
    final duration = _extractYouTubeDuration(document);
    
    return {
      'title': title.replaceAll(' - YouTube', '').trim(),
      'description': description,
      'author': author ?? 'Unknown Channel',
      'thumbnail': thumbnail,
      'duration': duration,
      'isSuccess': true,
      'method': 'HTML parsing',
    };
  }

  /// Extract YouTube duration dari structured data
  static String? _extractYouTubeDuration(dom.Document document) {
    try {
      // Look for JSON-LD structured data
      final scripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (final script in scripts) {
        final jsonText = script.text;
        if (jsonText.contains('duration')) {
          final data = jsonDecode(jsonText);
          if (data is Map && data.containsKey('duration')) {
            return data['duration'].toString();
          }
        }
      }
      
      // Look for meta tags
      final durationMeta = document.querySelector('meta[itemprop="duration"]');
      if (durationMeta != null) {
        return durationMeta.attributes['content'];
      }
      
    } catch (e) {
      developer.log('Could not extract duration: $e', name: 'EnhancedExtractor');
    }
    
    return null;
  }

  /// Enhanced web content extraction dengan better parsing
  static Future<Map<String, dynamic>> _extractWebContentEnhanced(String url) async {
    developer.log('🌐 Extracting web content with enhanced methods', name: 'EnhancedExtractor');
    
    final response = await _makeHttpRequestWithRetry(url);
    final document = html_parser.parse(response.body);
    
    // Extract title dengan multiple fallbacks
    final title = _extractTitle(document, url);
    
    // Extract main content dengan smart detection
    final content = _extractMainContent(document);
    
    // Extract metadata
    final metadata = _extractMetadata(document, url);
    
    // Extract images
    final images = _extractImages(document, url);
    
    // Calculate content quality score
    final qualityScore = _calculateContentQuality(content, title);
    
    return {
      'title': title,
      'content': content,
      'metadata': metadata,
      'images': images,
      'qualityScore': qualityScore,
      'wordCount': _countWords(content),
      'readingTime': _estimateReadingTime(content),
      'isSuccess': content.isNotEmpty,
      'extractedAt': DateTime.now().toIso8601String(),
      'url': url,
    };
  }

  /// Smart main content extraction
  static String _extractMainContent(dom.Document document) {
    // Remove unwanted elements
    _removeUnwantedElements(document);
    
    // Try content selectors in order of preference
    final contentSelectors = [
      'article',
      'main',
      '[role="main"]',
      '.post-content',
      '.entry-content',
      '.article-content',
      '.content',
      '#content',
      '.main-content',
      '#main',
      '.post-body',
      '.story-body',
    ];
    
    for (final selector in contentSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final text = _extractTextFromElement(element);
        if (text.length > 200) { // Minimum content length
          return _cleanText(text);
        }
      }
    }
    
    // Fallback: extract from body with smart filtering
    return _extractFromBodyWithFiltering(document);
  }

  /// Remove unwanted elements dari document
  static void _removeUnwantedElements(dom.Document document) {
    final unwantedSelectors = [
      'script', 'style', 'nav', 'header', 'footer', 'aside',
      '.advertisement', '.ads', '.sidebar', '.menu', '.navigation',
      '.social-share', '.comments', '.related-posts', '.popup',
      '.modal', '.cookie-notice', '.newsletter', '.subscription',
      '[class*="ad-"]', '[id*="ad-"]', '[class*="advertisement"]',
    ];
    
    for (final selector in unwantedSelectors) {
      document.querySelectorAll(selector).forEach((element) => element.remove());
    }
  }

  /// Extract text dari element dengan smart formatting
  static String _extractTextFromElement(dom.Element element) {
    final buffer = StringBuffer();
    
    for (final node in element.nodes) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        buffer.write(node.text);
      } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
        final elem = node as dom.Element;
        
        // Add line breaks for block elements
        if (_isBlockElement(elem.localName)) {
          buffer.write('\n');
        }
        
        buffer.write(_extractTextFromElement(elem));
        
        if (_isBlockElement(elem.localName)) {
          buffer.write('\n');
        }
      }
    }
    
    return buffer.toString();
  }

  /// Check if element is block element
  static bool _isBlockElement(String? tagName) {
    final blockElements = {
      'div', 'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'article', 'section', 'header', 'footer', 'main',
      'ul', 'ol', 'li', 'blockquote', 'pre'
    };
    return blockElements.contains(tagName?.toLowerCase());
  }

  /// Extract metadata dari document
  static Map<String, dynamic> _extractMetadata(dom.Document document, String url) {
    return {
      'description': _extractMetaContent(document, [
        'meta[property="og:description"]',
        'meta[name="twitter:description"]',
        'meta[name="description"]'
      ]),
      'author': _extractMetaContent(document, [
        'meta[name="author"]',
        'meta[property="article:author"]',
        '[rel="author"]'
      ]),
      'publishDate': _extractMetaContent(document, [
        'meta[property="article:published_time"]',
        'meta[name="publish_date"]',
        'time[datetime]'
      ]),
      'keywords': _extractMetaContent(document, [
        'meta[name="keywords"]'
      ]),
      'language': _extractMetaContent(document, [
        'meta[property="og:locale"]',
        'html[lang]'
      ]),
      'siteName': _extractMetaContent(document, [
        'meta[property="og:site_name"]'
      ]),
      'domain': Uri.parse(url).host,
    };
  }

  /// Extract images dari document
  static List<Map<String, String>> _extractImages(dom.Document document, String url) {
    final images = <Map<String, String>>[];
    final baseUri = Uri.parse(url);
    
    // Extract dari meta tags first (usually best quality)
    final ogImage = _extractMetaContent(document, ['meta[property="og:image"]']);
    if (ogImage != null) {
      images.add({
        'url': _resolveUrl(ogImage, baseUri),
        'type': 'og:image',
        'alt': 'Featured image',
      });
    }
    
    // Extract dari img tags
    final imgElements = document.querySelectorAll('img');
    for (final img in imgElements.take(5)) { // Limit to 5 images
      final src = img.attributes['src'];
      final alt = img.attributes['alt'] ?? '';
      
      if (src != null && src.isNotEmpty) {
        images.add({
          'url': _resolveUrl(src, baseUri),
          'type': 'content',
          'alt': alt,
        });
      }
    }
    
    return images;
  }

  /// Resolve relative URL to absolute
  static String _resolveUrl(String url, Uri baseUri) {
    try {
      final uri = Uri.parse(url);
      if (uri.isAbsolute) {
        return url;
      }
      return baseUri.resolve(url).toString();
    } catch (e) {
      return url;
    }
  }

  /// Calculate content quality score
  static double _calculateContentQuality(String content, String title) {
    double score = 0.0;
    
    // Length score (0-0.3)
    final wordCount = _countWords(content);
    if (wordCount > 100) score += 0.1;
    if (wordCount > 300) score += 0.1;
    if (wordCount > 500) score += 0.1;
    
    // Structure score (0-0.3)
    if (content.contains('\n\n')) score += 0.1; // Has paragraphs
    if (content.split('\n').length > 5) score += 0.1; // Multiple sections
    if (title.isNotEmpty && title.length > 10) score += 0.1; // Good title
    
    // Content quality indicators (0-0.4)
    final qualityIndicators = [
      RegExp(r'\b(introduction|conclusion|summary)\b', caseSensitive: false),
      RegExp(r'\b(first|second|third|finally)\b', caseSensitive: false),
      RegExp(r'\b(however|therefore|moreover|furthermore)\b', caseSensitive: false),
      RegExp(r'[.!?]\s+[A-Z]'), // Proper sentences
    ];
    
    for (final indicator in qualityIndicators) {
      if (indicator.hasMatch(content)) {
        score += 0.1;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Extract title dengan multiple fallbacks
  static String _extractTitle(dom.Document document, String url) {
    final titleSources = [
      () => _extractMetaContent(document, ['meta[property="og:title"]']),
      () => _extractMetaContent(document, ['meta[name="twitter:title"]']),
      () => document.querySelector('h1')?.text?.trim(),
      () => document.querySelector('title')?.text?.trim(),
      () => document.querySelector('.title')?.text?.trim(),
      () => document.querySelector('#title')?.text?.trim(),
    ];
    
    for (final source in titleSources) {
      try {
        final title = source();
        if (title != null && title.isNotEmpty && title.length > 3) {
          return _cleanTitle(title);
        }
      } catch (e) {
        continue;
      }
    }
    
    // Fallback to domain name
    try {
      return Uri.parse(url).host.replaceAll('www.', '');
    } catch (e) {
      return 'Web Article';
    }
  }

  /// Clean title dari unwanted suffixes
  static String _cleanTitle(String title) {
    final suffixesToRemove = [
      ' - YouTube',
      ' | Twitter',
      ' - Medium',
      ' | LinkedIn',
      ' - Facebook',
      ' | Instagram',
    ];
    
    String cleaned = title;
    for (final suffix in suffixesToRemove) {
      cleaned = cleaned.replaceAll(suffix, '');
    }
    
    return cleaned.trim();
  }

  /// Extract meta content dengan multiple selectors
  static String? _extractMetaContent(dom.Document document, List<String> selectors) {
    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'] ?? 
                       element.attributes['href'] ?? 
                       element.text;
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
    }
    return null;
  }

  /// Make HTTP request dengan retry logic
  static Future<http.Response> _makeHttpRequestWithRetry(String url) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        developer.log('🔄 HTTP request attempt $attempt/$_maxRetries', name: 'EnhancedExtractor');
        
        final response = await http.get(
          Uri.parse(url),
          headers: _getHeaders(),
        ).timeout(_timeout);
        
        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          // Client error, don't retry
          throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        } else {
          // Server error, might be temporary
          throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt < _maxRetries) {
          // Wait before retry with exponential backoff
          final delay = Duration(seconds: attempt * 2);
          developer.log('⏳ Waiting ${delay.inSeconds}s before retry...', name: 'EnhancedExtractor');
          await Future.delayed(delay);
        }
      }
    }
    
    throw lastException ?? Exception('All retry attempts failed');
  }

  /// Get HTTP headers untuk requests
  static Map<String, String> _getHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
    };
  }

  /// Utility methods
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  static bool _isTwitterUrl(String url) {
    return url.contains('twitter.com') || url.contains('x.com');
  }

  static bool _isMediumUrl(String url) {
    return url.contains('medium.com') || url.contains('@');
  }

  static bool _isGitHubUrl(String url) {
    return url.contains('github.com');
  }

  static String? _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
    } catch (e) {
      developer.log('Error extracting YouTube video ID: $e', name: 'EnhancedExtractor');
    }
    return null;
  }

  static int _countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  static int _estimateReadingTime(String text) {
    final wordCount = _countWords(text);
    return (wordCount / 200).ceil(); // Average reading speed: 200 words per minute
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple whitespace to single space
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Multiple newlines to double newline
        .trim();
  }

  /// Merge YouTube results dari multiple sources
  static Map<String, dynamic> _mergeYouTubeResults(
    Map<String, dynamic>? existing,
    Map<String, dynamic> newResult,
  ) {
    if (existing == null) return newResult;
    
    final merged = Map<String, dynamic>.from(existing);
    
    // Merge fields, preferring non-empty values
    newResult.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        if (!merged.containsKey(key) || 
            merged[key] == null || 
            merged[key].toString().isEmpty) {
          merged[key] = value;
        }
      }
    });
    
    return merged;
  }

  /// Check if YouTube data is complete
  static bool _isCompleteYouTubeData(Map<String, dynamic>? data) {
    if (data == null) return false;
    
    final requiredFields = ['title', 'author'];
    final optionalFields = ['description', 'thumbnail'];
    
    // Check required fields
    for (final field in requiredFields) {
      if (!data.containsKey(field) || 
          data[field] == null || 
          data[field].toString().isEmpty) {
        return false;
      }
    }
    
    // Check if we have at least one optional field
    return optionalFields.any((field) => 
      data.containsKey(field) && 
      data[field] != null && 
      data[field].toString().isNotEmpty
    );
  }

  /// Enhance YouTube content untuk AI processing
  static Map<String, dynamic> _enhanceYouTubeContent(
    Map<String, dynamic> data,
    String url,
    String videoId,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('🎥 YouTube Video Analysis');
    buffer.writeln('═' * 50);
    buffer.writeln();
    
    buffer.writeln('📺 Title: ${data['title']}');
    buffer.writeln('🔗 URL: $url');
    buffer.writeln('🆔 Video ID: $videoId');
    
    if (data['author'] != null) {
      buffer.writeln('👤 Channel: ${data['author']}');
    }
    
    if (data['duration'] != null) {
      buffer.writeln('⏱️ Duration: ${data['duration']}');
    }
    
    buffer.writeln();
    
    if (data['description'] != null && data['description'].toString().isNotEmpty) {
      buffer.writeln('📝 Description:');
      buffer.writeln('─' * 20);
      buffer.writeln(data['description']);
      buffer.writeln();
    }
    
    buffer.writeln('💡 AI Analysis Note:');
    buffer.writeln('This summary is based on the video\'s title, description, and metadata.');
    buffer.writeln('For more accurate analysis, consider providing the video transcript or key points manually.');
    
    return {
      'content': buffer.toString(),
      'title': data['title'],
      'metadata': {
        'type': 'youtube_video',
        'videoId': videoId,
        'url': url,
        'author': data['author'],
        'thumbnail': data['thumbnail'],
        'duration': data['duration'],
        'extractionMethod': data['method'],
      },
      'isSuccess': true,
      'wordCount': _countWords(buffer.toString()),
      'readingTime': 2, // Estimated time to read video info
    };
  }

  /// Create fallback untuk YouTube ketika extraction gagal
  static Map<String, dynamic> _createYouTubeFallback(
    String url,
    String videoId,
    List<String> errors,
  ) {
    final content = '''🎥 YouTube Video: $url

Video ID: $videoId

⚠️ Automatic extraction failed. This could be due to:
• Video is private, unlisted, or restricted
• Geographic restrictions or age restrictions
• Network connectivity issues
• YouTube blocking automated access
• Video has been deleted or made unavailable

💡 For better AI analysis, please provide:
1. The video title and description manually
2. Key points or transcript from the video
3. Main topics covered in the video

The AI will do its best to provide insights based on the URL and any additional context you provide.

🔧 Technical Details:
${errors.map((e) => '• $e').join('\n')}''';

    return {
      'content': content,
      'title': 'YouTube Video (Extraction Failed)',
      'metadata': {
        'type': 'youtube_video',
        'videoId': videoId,
        'url': url,
        'extractionErrors': errors,
      },
      'isSuccess': false,
      'wordCount': _countWords(content),
      'readingTime': 1,
    };
  }

  /// Create error fallback untuk general URLs
  static Map<String, dynamic> _createErrorFallback(String url, String error) {
    final content = '''🌐 Web Content: $url

⚠️ Automatic content extraction failed.

This could be due to:
• Website blocking automated access
• JavaScript-heavy content that requires browser rendering
• Network connectivity issues
• Content behind authentication or paywall
• Invalid or broken URL
• Server temporarily unavailable

💡 For better AI analysis, please:
1. Copy and paste the article text manually
2. Provide a summary of the main points
3. Check if the URL is accessible and correct

🔧 Technical Error: $error''';

    return {
      'content': content,
      'title': 'Web Content (Extraction Failed)',
      'metadata': {
        'type': 'web_content',
        'url': url,
        'extractionError': error,
      },
      'isSuccess': false,
      'wordCount': _countWords(content),
      'readingTime': 1,
    };
  }

  /// Extract dari body dengan smart filtering
  static String _extractFromBodyWithFiltering(dom.Document document) {
    final body = document.querySelector('body');
    if (body == null) return '';
    
    final paragraphs = body.querySelectorAll('p');
    final buffer = StringBuffer();
    
    for (final p in paragraphs) {
      final text = p.text.trim();
      if (text.length > 50) { // Filter out short paragraphs
        buffer.writeln(text);
        buffer.writeln();
      }
    }
    
    final result = buffer.toString().trim();
    return result.isNotEmpty ? result : body.text.trim();
  }

  /// Placeholder methods untuk specialized extractors
  static Future<Map<String, dynamic>> _extractTwitterContent(String url) async {
    // TODO: Implement Twitter-specific extraction
    return await _extractWebContentEnhanced(url);
  }

  static Future<Map<String, dynamic>> _extractMediumContent(String url) async {
    // TODO: Implement Medium-specific extraction
    return await _extractWebContentEnhanced(url);
  }

  static Future<Map<String, dynamic>> _extractGitHubContent(String url) async {
    // TODO: Implement GitHub-specific extraction
    return await _extractWebContentEnhanced(url);
  }

  static Future<Map<String, dynamic>> _extractFromYouTubeAPI(String videoId) async {
    // TODO: Implement YouTube Data API v3 extraction if API key available
    throw Exception('YouTube API not implemented');
  }
}
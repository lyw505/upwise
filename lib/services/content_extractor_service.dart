import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Enhanced content extractor service for URLs and PDFs
class ContentExtractorService {
  static const int _maxContentLength = 10000; // Limit content to prevent API overload
  static const Duration _requestTimeout = Duration(seconds: 15);

  /// Extract content from various sources
  static Future<ExtractedContent> extractContent({
    required String source,
    required ContentSourceType sourceType,
  }) async {
    try {
      switch (sourceType) {
        case ContentSourceType.url:
          return await _extractFromUrl(source);
        case ContentSourceType.pdf:
          return await _extractFromPdf(source);
        case ContentSourceType.text:
          return ExtractedContent(
            content: source,
            title: 'Text Content',
            sourceType: sourceType,
            isSuccess: true,
          );
      }
    } catch (e) {
      developer.log('Error extracting content: $e', name: 'ContentExtractorService');
      return ExtractedContent(
        content: source,
        title: 'Content',
        sourceType: sourceType,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Extract content from URL
  static Future<ExtractedContent> _extractFromUrl(String url) async {
    try {
      // Validate URL
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasAbsolutePath) {
        throw Exception('Invalid URL format');
      }

      // Handle different URL types
      if (_isYouTubeUrl(url)) {
        return await _extractYouTubeContent(url);
      } else if (_isPdfUrl(url)) {
        return await _extractPdfFromUrl(url);
      } else {
        return await _extractWebContent(url);
      }
    } catch (e) {
      return ExtractedContent(
        content: url,
        title: 'Web Content',
        sourceType: ContentSourceType.url,
        isSuccess: false,
        errorMessage: 'Failed to extract content from URL: $e',
      );
    }
  }

  /// Extract content from PDF file path
  static Future<ExtractedContent> _extractFromPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('PDF file not found');
      }

      final bytes = await file.readAsBytes();
      return await _extractPdfContent(bytes, file.path.split('/').last);
    } catch (e) {
      return ExtractedContent(
        content: filePath,
        title: 'PDF Document',
        sourceType: ContentSourceType.pdf,
        isSuccess: false,
        errorMessage: 'Failed to extract PDF content: $e',
      );
    }
  }

  /// Extract content from web URL
  static Future<ExtractedContent> _extractWebContent(String url) async {
    try {
      developer.log('Extracting web content from: $url', name: 'ContentExtractorService');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch content');
      }

      // Parse HTML content
      final document = html_parser.parse(response.body);
      
      // Extract title
      String title = _extractTitle(document, url);
      
      // Extract main content
      String content = _extractMainContent(document);
      
      if (content.trim().isEmpty) {
        throw Exception('No readable content found on the page');
      }

      // Limit content length
      if (content.length > _maxContentLength) {
        content = '${content.substring(0, _maxContentLength)}...';
      }

      developer.log('Successfully extracted ${content.length} characters from web page', name: 'ContentExtractorService');

      return ExtractedContent(
        content: content,
        title: title,
        sourceType: ContentSourceType.url,
        isSuccess: true,
        metadata: {
          'url': url,
          'contentLength': content.length,
          'extractedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      developer.log('Error extracting web content: $e', name: 'ContentExtractorService');
      return ExtractedContent(
        content: 'Web Article from: $url\n\nNote: Unable to extract content automatically. This could be due to:\n• Website blocking automated access\n• JavaScript-heavy content\n• Network connectivity issues\n• Content behind authentication\n\nPlease copy and paste the article text manually for better summarization.',
        title: 'Web Article',
        sourceType: ContentSourceType.url,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Extract YouTube content
  static Future<ExtractedContent> _extractYouTubeContent(String url) async {
    try {
      final videoId = _extractYouTubeVideoId(url);
      if (videoId == null) {
        throw Exception('Invalid YouTube URL');
      }

      // Try to extract basic info from YouTube page
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(_requestTimeout);

      String title = 'YouTube Video';
      String description = '';

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Try to extract title from meta tags
        final titleElement = document.querySelector('meta[property="og:title"]') ??
                           document.querySelector('title');
        if (titleElement != null) {
          title = titleElement.attributes['content'] ?? titleElement.text ?? title;
          title = title.replaceAll(' - YouTube', '').trim();
        }

        // Try to extract description
        final descElement = document.querySelector('meta[property="og:description"]') ??
                          document.querySelector('meta[name="description"]');
        if (descElement != null) {
          description = descElement.attributes['content'] ?? '';
        }
      }

      final content = '''YouTube Video: $title

Video URL: $url
Video ID: $videoId

${description.isNotEmpty ? 'Description: $description\n' : ''}
Note: This is a YouTube video. For the most accurate summary, please:
1. Watch the video and provide key points manually, or
2. Paste the video transcript if available, or  
3. Describe the main topics covered in the video

The AI will do its best to provide insights based on the title and description, but manual input will yield better results.''';

      return ExtractedContent(
        content: content,
        title: title,
        sourceType: ContentSourceType.url,
        isSuccess: true,
        metadata: {
          'videoId': videoId,
          'url': url,
          'platform': 'youtube',
        },
      );
    } catch (e) {
      return ExtractedContent(
        content: 'YouTube Video: $url\n\nNote: Unable to extract video information. Please provide the video transcript or describe the content manually.',
        title: 'YouTube Video',
        sourceType: ContentSourceType.url,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Extract PDF content from URL
  static Future<ExtractedContent> _extractPdfFromUrl(String url) async {
    try {
      developer.log('Downloading PDF from URL: $url', name: 'ContentExtractorService');

      final response = await http.get(Uri.parse(url)).timeout(_requestTimeout);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }

      return await _extractPdfContent(response.bodyBytes, url.split('/').last);
    } catch (e) {
      return ExtractedContent(
        content: 'PDF Document from: $url\n\nNote: Unable to extract PDF content automatically. Please download the PDF and upload it directly, or copy and paste the text content.',
        title: 'PDF Document',
        sourceType: ContentSourceType.url,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Extract content from PDF bytes
  static Future<ExtractedContent> _extractPdfContent(Uint8List bytes, String fileName) async {
    try {
      developer.log('Extracting text from PDF: $fileName', name: 'ContentExtractorService');

      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      final StringBuffer textBuffer = StringBuffer();
      
      // Extract text from each page
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final String pageText = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        
        if (pageText.trim().isNotEmpty) {
          textBuffer.writeln(pageText.trim());
          textBuffer.writeln(); // Add spacing between pages
        }
      }

      document.dispose();

      String content = textBuffer.toString().trim();
      
      if (content.isEmpty) {
        throw Exception('No text content found in PDF');
      }

      // Limit content length
      if (content.length > _maxContentLength) {
        content = '${content.substring(0, _maxContentLength)}...';
      }

      // Clean up the text
      content = _cleanPdfText(content);

      developer.log('Successfully extracted ${content.length} characters from PDF', name: 'ContentExtractorService');

      return ExtractedContent(
        content: content,
        title: fileName.replaceAll('.pdf', ''),
        sourceType: ContentSourceType.pdf,
        isSuccess: true,
        metadata: {
          'fileName': fileName,
          'contentLength': content.length,
          'extractedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      developer.log('Error extracting PDF content: $e', name: 'ContentExtractorService');
      return ExtractedContent(
        content: 'PDF Document: $fileName\n\nNote: Unable to extract text from PDF automatically. This could be due to:\n• Scanned PDF without OCR\n• Password-protected PDF\n• Corrupted PDF file\n• Unsupported PDF format\n\nPlease copy and paste the text content manually.',
        title: fileName,
        sourceType: ContentSourceType.pdf,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Extract title from HTML document
  static String _extractTitle(dom.Document document, String url) {
    // Try different methods to get title
    final titleSources = [
      document.querySelector('meta[property="og:title"]')?.attributes['content'],
      document.querySelector('meta[name="twitter:title"]')?.attributes['content'],
      document.querySelector('h1')?.text,
      document.querySelector('title')?.text,
    ];

    for (final title in titleSources) {
      if (title != null && title.trim().isNotEmpty) {
        return title.trim();
      }
    }

    // Fallback to URL-based title
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (e) {
      return 'Web Article';
    }
  }

  /// Extract main content from HTML document
  static String _extractMainContent(dom.Document document) {
    // Remove unwanted elements
    final unwantedSelectors = [
      'script', 'style', 'nav', 'header', 'footer', 'aside',
      '.advertisement', '.ads', '.sidebar', '.menu', '.navigation',
      '.social-share', '.comments', '.related-posts'
    ];

    for (final selector in unwantedSelectors) {
      document.querySelectorAll(selector).forEach((element) => element.remove());
    }

    // Try to find main content using common selectors
    final contentSelectors = [
      'article',
      'main',
      '.content',
      '.post-content',
      '.entry-content',
      '.article-content',
      '.main-content',
      '#content',
      '#main',
    ];

    for (final selector in contentSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final text = _extractTextFromElement(element);
        if (text.length > 200) { // Minimum content length
          return text;
        }
      }
    }

    // Fallback: extract from body
    final body = document.querySelector('body');
    if (body != null) {
      return _extractTextFromElement(body);
    }

    return document.body?.text ?? '';
  }

  /// Extract clean text from HTML element
  static String _extractTextFromElement(dom.Element element) {
    // Get text content and clean it up
    String text = element.text ?? '';
    
    // Clean up whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return text;
  }

  /// Clean up PDF text
  static String _cleanPdfText(String text) {
    // Remove excessive whitespace
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    text = text.replaceAll(RegExp(r' +'), ' ');
    
    // Remove page numbers and headers/footers (simple heuristic)
    final lines = text.split('\n');
    final cleanedLines = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Skip likely page numbers
      if (RegExp(r'^\d+$').hasMatch(trimmed)) continue;
      
      // Skip very short lines that might be headers/footers
      if (trimmed.length < 3) continue;
      
      cleanedLines.add(trimmed);
    }
    
    return cleanedLines.join('\n');
  }

  /// Check if URL is YouTube
  static bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  /// Check if URL points to PDF
  static bool _isPdfUrl(String url) {
    return url.toLowerCase().endsWith('.pdf') || 
           url.toLowerCase().contains('.pdf?') ||
           url.toLowerCase().contains('pdf');
  }

  /// Extract YouTube video ID
  static String? _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
    } catch (e) {
      developer.log('Error extracting YouTube video ID: $e', name: 'ContentExtractorService');
    }
    return null;
  }
}

/// Enum for content source types
enum ContentSourceType {
  url,
  pdf,
  text,
}

/// Model for extracted content
class ExtractedContent {
  final String content;
  final String title;
  final ContentSourceType sourceType;
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  ExtractedContent({
    required this.content,
    required this.title,
    required this.sourceType,
    required this.isSuccess,
    this.errorMessage,
    this.metadata,
  });

  @override
  String toString() {
    return 'ExtractedContent(title: $title, success: $isSuccess, contentLength: ${content.length})';
  }
}
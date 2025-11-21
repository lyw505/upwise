import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';

class YouTubeSearchService {
  static String get _geminiApiKey => EnvConfig.geminiApiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  /// Generate multiple smart search URLs for better video discovery
  static List<String> generateSmartSearchUrls(String topic, String subTopic) {
    final channelData = _getTopicSpecificChannels(topic.toLowerCase());
    final primaryChannels = List<String>.from(channelData['primary']);
    
    final queries = [
      '${primaryChannels[0]} $topic $subTopic tutorial complete',
      '$subTopic $topic step by step tutorial',
      'learn $subTopic $topic beginner complete guide',
      '${primaryChannels.length > 1 ? primaryChannels[1] : primaryChannels[0]} $topic $subTopic practical',
      '$subTopic tutorial $topic 2024 complete course',
      'freeCodeCamp $topic $subTopic full tutorial',
    ];
    
    return queries.map((query) {
      final encoded = Uri.encodeComponent(query);
      return 'https://www.youtube.com/results?search_query=$encoded';
    }).toList();
  }
  
  /// Create a highly specific search URL for a given topic and subtopic
  static String createSpecificSearchUrl(String topic, String subTopic, String channel) {
    final query = '$channel $topic $subTopic tutorial complete guide';
    final encoded = Uri.encodeComponent(query);
    return 'https://www.youtube.com/results?search_query=$encoded';
  }

  /// Generate YouTube search queries and find relevant videos for learning topics
  static Future<List<YouTubeVideo>> findRelevantVideos({
    required String topic,
    required String subTopic,
    required String experienceLevel,
    int maxResults = 3,
  }) async {
    try {
      if (EnvConfig.isDebugMode) {
        print('🎥 Finding YouTube videos for: $subTopic (topic: $topic, level: $experienceLevel)');
      }
      
      if (!EnvConfig.isConfigured) {
        if (EnvConfig.isDebugMode) {
          print('⚠️ Gemini API not configured, using fallback videos');
        }
        return _getFallbackVideos(topic, subTopic);
      }

      // Use Gemini AI to generate smart YouTube search queries and find videos
      final prompt = _buildYouTubeSearchPrompt(topic, subTopic, experienceLevel, maxResults);
      
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 20,
            'topP': 0.8,
            'maxOutputTokens': 2048,
          },
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        
        final videos = _parseYouTubeResponse(generatedText);
        if (EnvConfig.isDebugMode) {
          print('✅ Found ${videos.length} videos from AI for: $subTopic');
        }
        return videos;
      } else {
        if (EnvConfig.isDebugMode) {
          print('❌ AI request failed with status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (EnvConfig.isDebugMode) {
        print('Error finding YouTube videos: $e');
      }
    }

    return _getFallbackVideos(topic, subTopic);
  }

  static String _buildYouTubeSearchPrompt(String topic, String subTopic, String experienceLevel, int maxResults) {
    return '''
Anda adalah kurator konten YouTube ahli dengan pengetahuan mendalam tentang channel edukasi terbaik. Temukan $maxResults video YouTube edukasi TERBAIK untuk mempelajari "$subTopic" dalam konteks "$topic" untuk pelajar level $experienceLevel.

CHANNEL PRIORITAS BERDASARKAN TOPIK:
Programming/Tech: Traversy Media, freeCodeCamp, The Net Ninja, Programming with Mosh, Academind, Corey Schafer, Derek Banas, Fireship, Web Dev Simplified, Kevin Powell
Flutter/Mobile: Flutter, The Net Ninja, Reso Coder, FilledStacks, Marcus Ng, Santos Enoque, Flutter Mapp
Python: Corey Schafer, Programming with Mosh, freeCodeCamp, Real Python, Tech With Tim, Python Engineer
JavaScript/Web: Traversy Media, The Net Ninja, Academind, Web Dev Simplified, JavaScript Mastery, Fireship
Data Science/ML: 3Blue1Brown, StatQuest, Krish Naik, Data School, Andrew Ng, Sentdex
PHP: Traversy Media, The Net Ninja, Program With Gio, Dani Krossing, freeCodeCamp
React: Traversy Media, The Net Ninja, Academind, Web Dev Simplified, Codevolution
Node.js: Traversy Media, The Net Ninja, Academind, Programming with Mosh, freeCodeCamp

STRATEGI PENCARIAN CERDAS:
1. Gunakan istilah pencarian yang SANGAT SPESIFIK dan realistis
2. Fokus pada channel edukasi populer dan terpercaya
3. Pilih tutorial komprehensif daripada tips singkat
4. Sesuaikan tingkat kesulitan dengan tepat
5. Pastikan video praktis dan hands-on
6. Berikan search query yang akan menghasilkan video yang tepat

PERSYARATAN KUALITAS:
- Video harus dari channel edukasi terpercaya
- Konten harus komprehensif dan terstruktur dengan baik
- Sesuai untuk pelajar level $experienceLevel
- Fokus pada pembelajaran praktis dan actionable
- Konten terbaru (lebih disukai 2020 atau lebih baru)
- Search query harus sangat spesifik untuk menemukan video yang tepat

Kembalikan HANYA format JSON ini dengan rekomendasi video NYATA dan SPESIFIK:
{
  "videos": [
    {
      "title": "Judul video yang tepat dan realistis (gunakan bahasa Inggris untuk judul asli)",
      "channel": "Nama channel nyata dari daftar prioritas di atas",
      "description": "Deskripsi detail tentang apa yang diajarkan video dan yang dicakup (2-3 kalimat dalam bahasa Indonesia)",
      "search_query": "Query pencarian yang SANGAT SPESIFIK yang akan menemukan video ini di YouTube (gunakan nama channel + topik spesifik)",
      "estimated_duration": "Durasi realistis (contoh: '12 menit', '45 menit', '1.2 jam')",
      "difficulty": "$experienceLevel",
      "why_relevant": "Penjelasan spesifik mengapa video ini sempurna untuk mempelajari $subTopic dalam konteks $topic (dalam bahasa Indonesia)",
      "direct_search_url": "URL pencarian YouTube yang sangat spesifik untuk menemukan video ini"
    }
  ]
}

SANGAT PENTING: 
- Buat query pencarian SANGAT SPESIFIK dengan nama channel. Contoh: "Traversy Media React Complete Tutorial" bukan hanya "React Tutorial"
- Fokus pada video yang secara khusus mengajarkan konsep $subTopic dengan contoh praktis
- Pastikan search query akan menghasilkan video yang relevan dan berkualitas tinggi
- Berikan URL pencarian yang akan langsung mengarah ke hasil yang tepat
- Gunakan kombinasi nama channel + topik spesifik + kata kunci yang tepat
''';
  }

  static List<YouTubeVideo> _parseYouTubeResponse(String response) {
    try {
      // Clean the response
      String cleanedResponse = response.trim();
      
      // Remove markdown code blocks if present
      if (cleanedResponse.contains('```json')) {
        final startIndex = cleanedResponse.indexOf('```json') + 7;
        final endIndex = cleanedResponse.indexOf('```', startIndex);
        if (endIndex != -1) {
          cleanedResponse = cleanedResponse.substring(startIndex, endIndex);
        }
      } else if (cleanedResponse.contains('```')) {
        final startIndex = cleanedResponse.indexOf('```') + 3;
        final endIndex = cleanedResponse.indexOf('```', startIndex);
        if (endIndex != -1) {
          cleanedResponse = cleanedResponse.substring(startIndex, endIndex);
        }
      }
      
      // Find JSON boundaries
      final jsonStart = cleanedResponse.indexOf('{');
      final jsonEnd = cleanedResponse.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1) {
        cleanedResponse = cleanedResponse.substring(jsonStart, jsonEnd + 1);
      }

      final parsed = jsonDecode(cleanedResponse) as Map<String, dynamic>;
      final videosList = parsed['videos'] as List;

      final videos = videosList.map((video) => YouTubeVideo.fromJson(video)).toList();
      
      if (EnvConfig.isDebugMode) {
        print('🎥 Parsed ${videos.length} videos from AI response');
        for (final video in videos) {
          print('   - ${video.title} by ${video.channel}');
          print('     Search: ${video.searchQuery}');
          print('     URL: ${video.youtubeUrl}');
        }
      }
      
      return videos;
    } catch (e) {
      if (EnvConfig.isDebugMode) {
        print('Error parsing YouTube response: $e');
        print('Raw response: $response');
      }
      return [];
    }
  }

  static List<YouTubeVideo> _getFallbackVideos(String topic, String subTopic) {
    // Smart fallback videos with topic-specific channels and realistic search queries
    final topicLower = topic.toLowerCase();
    
    // Get topic-specific channels and search strategies
    final channelData = _getTopicSpecificChannels(topicLower);
    final smartQueries = _generateSmartSearchQueries(topic, subTopic, channelData);
    
    return smartQueries.map((query) {
      final encodedQuery = Uri.encodeComponent(query['search_terms']);
      return YouTubeVideo(
        title: query['title'],
        channel: query['channel'],
        description: query['description'],
        searchQuery: query['search_terms'],
        estimatedDuration: query['duration'],
        difficulty: query['difficulty'],
        whyRelevant: query['why_relevant'],
        youtubeUrl: query['youtube_url'] ?? 'https://www.youtube.com/results?search_query=$encodedQuery',
      );
    }).toList();
  }

  static Map<String, dynamic> _getTopicSpecificChannels(String topic) {
    final channelMap = {
      'flutter': {
        'primary': ['Flutter', 'The Net Ninja', 'Reso Coder'],
        'secondary': ['FilledStacks', 'Marcus Ng', 'Santos Enoque', 'Flutter Mapp'],
        'keywords': ['flutter', 'dart', 'widget', 'mobile app', 'tutorial']
      },
      'python': {
        'primary': ['Corey Schafer', 'Programming with Mosh', 'freeCodeCamp'],
        'secondary': ['Real Python', 'Tech With Tim', 'Sentdex', 'Python Engineer'],
        'keywords': ['python', 'programming', 'tutorial', 'beginner', 'complete']
      },
      'javascript': {
        'primary': ['Traversy Media', 'The Net Ninja', 'Academind'],
        'secondary': ['Web Dev Simplified', 'JavaScript Mastery', 'Fireship'],
        'keywords': ['javascript', 'js', 'web development', 'tutorial', 'complete']
      },
      'react': {
        'primary': ['Traversy Media', 'Academind', 'The Net Ninja'],
        'secondary': ['Web Dev Simplified', 'Codevolution', 'React'],
        'keywords': ['react', 'reactjs', 'component', 'hooks', 'tutorial']
      },
      'php': {
        'primary': ['Traversy Media', 'The Net Ninja', 'freeCodeCamp'],
        'secondary': ['Program With Gio', 'Dani Krossing', 'PHP'],
        'keywords': ['php', 'web development', 'backend', 'tutorial', 'complete']
      },
      'node': {
        'primary': ['Traversy Media', 'The Net Ninja', 'Academind'],
        'secondary': ['Programming with Mosh', 'freeCodeCamp', 'Web Dev Simplified'],
        'keywords': ['nodejs', 'node', 'backend', 'server', 'tutorial']
      },
      'css': {
        'primary': ['Kevin Powell', 'Traversy Media', 'The Net Ninja'],
        'secondary': ['Web Dev Simplified', 'freeCodeCamp', 'Academind'],
        'keywords': ['css', 'styling', 'web design', 'tutorial', 'complete']
      },
      'html': {
        'primary': ['Traversy Media', 'freeCodeCamp', 'The Net Ninja'],
        'secondary': ['Web Dev Simplified', 'Academind', 'Kevin Powell'],
        'keywords': ['html', 'web development', 'markup', 'tutorial', 'beginner']
      }
    };

    // Find matching topic or return generic
    for (final key in channelMap.keys) {
      if (topic.contains(key) || key.contains(topic)) {
        return channelMap[key]!;
      }
    }

    return {
      'primary': ['freeCodeCamp', 'Traversy Media', 'The Net Ninja'],
      'secondary': ['Academind', 'Programming with Mosh', 'Derek Banas'],
      'keywords': [topic, 'tutorial', 'beginner', 'guide', 'complete']
    };
  }

  static List<Map<String, dynamic>> _generateSmartSearchQueries(
    String topic, 
    String subTopic, 
    Map<String, dynamic> channelData
  ) {
    final primaryChannels = List<String>.from(channelData['primary']);
    final keywords = List<String>.from(channelData['keywords']);
    
    return [
      {
        'title': '$subTopic - Tutorial Lengkap',
        'channel': primaryChannels[0],
        'description': 'Tutorial komprehensif yang mencakup dasar-dasar $subTopic dengan contoh praktis. Sempurna untuk memahami konsep inti dan mendapatkan pengalaman hands-on.',
        'search_terms': '${primaryChannels[0]} $subTopic tutorial complete guide',
        'duration': '25-35 menit',
        'difficulty': 'beginner',
        'why_relevant': 'Memberikan cakupan komprehensif tentang $subTopic dengan penjelasan step-by-step dan contoh praktis.',
        'youtube_url': 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${primaryChannels[0]} $subTopic tutorial complete guide')}'
      },
      {
        'title': '$topic $subTopic - Contoh Praktis',
        'channel': primaryChannels.length > 1 ? primaryChannels[1] : primaryChannels[0],
        'description': 'Contoh praktis hands-on dan aplikasi real-world dari $subTopic dalam pengembangan $topic. Termasuk contoh kode dan best practices.',
        'search_terms': '${primaryChannels.length > 1 ? primaryChannels[1] : primaryChannels[0]} $topic $subTopic practical examples',
        'duration': '18-28 menit',
        'difficulty': 'intermediate',
        'why_relevant': 'Menunjukkan implementasi real-world dan use case praktis dari $subTopic dalam proyek $topic.',
        'youtube_url': 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${primaryChannels.length > 1 ? primaryChannels[1] : primaryChannels[0]} $topic $subTopic practical examples')}'
      },
      {
        'title': 'Belajar $subTopic dalam $topic - Langkah demi Langkah',
        'channel': primaryChannels.length > 2 ? primaryChannels[2] : primaryChannels[0],
        'description': 'Panduan step-by-step untuk menguasai konsep $subTopic dengan penjelasan yang jelas dan latihan coding. Ideal untuk membangun fondasi yang solid.',
        'search_terms': '$subTopic $topic step by step tutorial ${keywords[0]}',
        'duration': '30-45 menit',
        'difficulty': 'beginner',
        'why_relevant': 'Menawarkan pendekatan pembelajaran terstruktur dengan progres yang jelas dari dasar hingga konsep $subTopic yang advanced.',
        'youtube_url': 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$subTopic $topic step by step tutorial complete')}'
      },
      {
        'title': '$subTopic Best Practices dan Tips',
        'channel': 'freeCodeCamp',
        'description': 'Tips advanced, best practices, dan kesalahan umum saat bekerja dengan $subTopic. Termasuk teknik optimisasi dan insight profesional.',
        'search_terms': 'freeCodeCamp $subTopic best practices tips $topic',
        'duration': '40-60 menit',
        'difficulty': 'intermediate',
        'why_relevant': 'Mengajarkan teknik level profesional dan best practices untuk mengimplementasikan $subTopic secara efektif.',
        'youtube_url': 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('freeCodeCamp $subTopic best practices $topic complete course')}'
      }
    ];
  }
}

class YouTubeVideo {
  final String title;
  final String channel;
  final String description;
  final String searchQuery;
  final String estimatedDuration;
  final String difficulty;
  final String whyRelevant;
  final String youtubeUrl;
  final List<String> alternativeSearchUrls;

  YouTubeVideo({
    required this.title,
    required this.channel,
    required this.description,
    required this.searchQuery,
    required this.estimatedDuration,
    required this.difficulty,
    required this.whyRelevant,
    required this.youtubeUrl,
    this.alternativeSearchUrls = const [],
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final searchQuery = json['search_query'] ?? '';
    final encodedQuery = Uri.encodeComponent(searchQuery);
    
    // Use direct search URL if provided, otherwise create search URL
    String youtubeUrl;
    if (json['direct_search_url'] != null && json['direct_search_url'].toString().isNotEmpty) {
      youtubeUrl = json['direct_search_url'];
    } else {
      youtubeUrl = 'https://www.youtube.com/results?search_query=$encodedQuery';
    }
    
    // Generate alternative search URLs
    final title = json['title'] ?? 'Educational Video';
    final channel = json['channel'] ?? 'YouTube';
    final alternativeUrls = <String>[];
    
    // Create alternative search queries
    if (searchQuery.isNotEmpty) {
      final baseQuery = searchQuery.replaceAll(RegExp(r'\s+'), ' ').trim();
      alternativeUrls.addAll([
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$channel $baseQuery')}',
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$baseQuery tutorial')}',
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$baseQuery complete guide')}',
      ]);
    }
    
    return YouTubeVideo(
      title: title,
      channel: channel,
      description: json['description'] ?? 'Educational content',
      searchQuery: searchQuery,
      estimatedDuration: json['estimated_duration'] ?? '20 min',
      difficulty: json['difficulty'] ?? 'intermediate',
      whyRelevant: json['why_relevant'] ?? 'Relevant educational content',
      youtubeUrl: youtubeUrl,
      alternativeSearchUrls: alternativeUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'channel': channel,
      'description': description,
      'search_query': searchQuery,
      'estimated_duration': estimatedDuration,
      'difficulty': difficulty,
      'why_relevant': whyRelevant,
      'youtube_url': youtubeUrl,
      'alternative_search_urls': alternativeSearchUrls,
    };
  }
  
  /// Get the best search URL for this video
  String getBestSearchUrl() {
    return youtubeUrl;
  }
  
  /// Get all available search URLs for this video
  List<String> getAllSearchUrls() {
    return [youtubeUrl, ...alternativeSearchUrls];
  }
}
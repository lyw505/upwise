import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';

class YouTubeSearchService {
  static String get _geminiApiKey => EnvConfig.geminiApiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
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
    final cleanTopic = _cleanTopic(topic);
    final cleanSubTopic = _cleanTopic(subTopic);
    final query = '$channel $cleanTopic $cleanSubTopic tutorial';
    final encoded = Uri.encodeComponent(query);
    return 'https://www.youtube.com/results?search_query=$encoded';
  }

  /// Get curated direct video URLs for popular programming topics
  static Map<String, List<Map<String, String>>> getCuratedVideoDatabase() {
    return {
      'react': [
        {
          'title': 'React Tutorial for Beginners',
          'channel': 'Programming with Mosh',
          'url': 'https://www.youtube.com/watch?v=Ke90Tje7VS0',
          'duration': '1:18:00'
        },
        {
          'title': 'React Course - Beginner\'s Tutorial',
          'channel': 'freeCodeCamp',
          'url': 'https://www.youtube.com/watch?v=bMknfKXIFA8',
          'duration': '11:55:00'
        }
      ],
      'javascript': [
        {
          'title': 'JavaScript Tutorial for Beginners',
          'channel': 'Programming with Mosh',
          'url': 'https://www.youtube.com/watch?v=W6NZfCO5SIk',
          'duration': '1:00:00'
        },
        {
          'title': 'JavaScript Full Course',
          'channel': 'freeCodeCamp',
          'url': 'https://www.youtube.com/watch?v=PkZNo7MFNFg',
          'duration': '3:26:00'
        }
      ],
      'python': [
        {
          'title': 'Python Tutorial for Beginners',
          'channel': 'Programming with Mosh',
          'url': 'https://www.youtube.com/watch?v=_uQrJ0TkZlc',
          'duration': '6:14:00'
        },
        {
          'title': 'Python for Everybody Course',
          'channel': 'freeCodeCamp',
          'url': 'https://www.youtube.com/watch?v=8DvywoWv6fI',
          'duration': '13:40:00'
        }
      ],
      'flutter': [
        {
          'title': 'Flutter Tutorial for Beginners',
          'channel': 'The Net Ninja',
          'url': 'https://www.youtube.com/watch?v=1ukSR1GRtMU',
          'duration': '37:00'
        },
        {
          'title': 'Flutter Course for Beginners',
          'channel': 'freeCodeCamp',
          'url': 'https://www.youtube.com/watch?v=VPvVD8t02U8',
          'duration': '37:28:00'
        }
      ]
    };
  }

  /// Try to get direct video URL for specific topics
  static String? getDirectVideoUrl(String topic, String subTopic) {
    final cleanTopic = _cleanTopic(topic).toLowerCase();
    final curatedVideos = getCuratedVideoDatabase();
    
    // Try to find direct video for the topic
    if (curatedVideos.containsKey(cleanTopic)) {
      final videos = curatedVideos[cleanTopic]!;
      if (videos.isNotEmpty) {
        return videos.first['url'];
      }
    }
    
    return null;
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
Anda adalah kurator konten YouTube ahli dengan pengetahuan mendalam tentang berbagai channel edukasi. Temukan $maxResults video YouTube edukasi TERBAIK untuk mempelajari "$subTopic" dalam konteks "$topic" untuk pelajar level $experienceLevel.

PENTING: FOKUS PADA KONTEN EDUKASI BERKUALITAS TINGGI UNTUK TOPIK APAPUN - programming, memasak, olahraga, seni, bisnis, musik, bahasa, crafting, kesehatan, atau bidang lainnya.

CHANNEL PRIORITAS BERDASARKAN TOPIK:
Programming/Tech: Traversy Media, freeCodeCamp, The Net Ninja, Programming with Mosh, Academind, Corey Schafer, Derek Banas, Fireship, Web Dev Simplified, Kevin Powell
Memasak/Kuliner: Bon Appétit, Tasty, Joshua Weissman, Binging with Babish, Chef John, Maangchi, Peaceful Cuisine, Gordon Ramsay, Jamie Oliver, Babish Culinary Universe
Olahraga/Fitness: Athlean-X, Calisthenic Movement, Yoga with Adriene, FitnessBlender, Jeff Nippard, Natacha Océane, Pamela Reif, MadFit, HIIT Workouts, Chloe Ting
Seni/Desain: Proko, Draw with Jazza, Peter Draws, The Art Assignment, Adobe Creative Cloud, Skillshare, Art Prof, Ctrl+Paint, Marco Bucci, Sinix Design
Bisnis/Keuangan: Ali Abdaal, Thomas Frank, Graham Stephan, Andrei Jikh, The Financial Diet, Harvard Business Review, Gary Vaynerchuk, Grant Cardone, Meet Kevin
Musik: Music Theory Guy, Andrew Huang, Rick Beato, Pianote, JustinGuitar, Marty Music, David Bennett Piano, 12tone, Nahre Sol, Piano Video Lessons
Bahasa: SpanishDict, Learn French with Alexa, JapanesePod101, FluentU, Babbel, italki, SpanishPod101, ChinesePod, Learn German with Jenny, English with Lucy
Kesehatan/Wellness: Dr. Mike, What I've Learned, Kurzgesagt, TED-Ed, Crash Course, SciShow, Dr. Berg, Thomas DeLauer, Yoga with Adriene, Headspace
Crafting/DIY: 5-Minute Crafts, DIY Creators, Steve Ramsey, April Wilkerson, Jimmy DiResta, Make Something, Crafty Panda, SoCraftastic, The Sorry Girls
Fotografi: Peter McKinnon, Mango Street, Sean Tucker, Jamie Windsor, Thomas Heaton, Ted Forbes, Matti Haapoja, Jordy Vandeput, COOPH, Kai W
Berkebun/Pertanian: Epic Gardening, Roots and Refuge Farm, Self Sufficient Me, Garden Answer, Migardener, Charles Dowding, Huw Richards, Swedish Homestead
Kecantikan/Fashion: James Charles, NikkieTutorials, Safiya Nygaard, bestdressed, Hyram, Caroline Hirons, Wayne Goss, Jackie Aina, Tati Westbrook
Parenting/Keluarga: What to Expect, BabyCenter, The Modern Parents, Dad University, Mom vs The Boys, Family Fun Pack, Jordan Page Fun Cheap
Teknologi/Gadget: Marques Brownlee, Unbox Therapy, Austin Evans, Dave2D, iJustine, Linus Tech Tips, The Verge, Mrwhosetheboss, MKBHD

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
- Buat query pencarian SANGAT SPESIFIK dengan nama channel. Contoh: "Bon Appétit Pasta Making Tutorial" atau "Traversy Media React Complete Tutorial"
- Rekomendasikan video edukasi berkualitas tinggi untuk TOPIK APAPUN - programming, memasak, olahraga, seni, bisnis, musik, bahasa, crafting, kesehatan, fotografi, berkebun, kecantikan, parenting, teknologi, dll.
- Fokus pada video yang secara khusus mengajarkan konsep $subTopic dengan contoh praktis dan tutorial yang jelas
- Pastikan search query akan menghasilkan video yang relevan dan berkualitas tinggi untuk topik yang diminta
- Berikan URL pencarian yang akan langsung mengarah ke hasil yang tepat
- Gunakan kombinasi nama channel + topik spesifik + kata kunci yang tepat untuk bidang tersebut
- Sesuaikan rekomendasi dengan konteks dan bidang dari $topic dan $subTopic yang diminta
- Pilih channel yang paling sesuai dengan bidang pembelajaran yang diminta
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
    // Debug logging
    if (EnvConfig.isDebugMode) {
      print('🔍 Looking for channels for topic: "$topic"');
    }
    
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
      },
      'java': {
        'primary': ['Programming with Mosh', 'Derek Banas', 'Cave of Programming'],
        'secondary': ['Coding with John', 'Java Brains', 'Spring Developer'],
        'keywords': ['java', 'programming', 'oop', 'tutorial', 'complete']
      },
      'android': {
        'primary': ['Coding in Flow', 'Philipp Lackner', 'Android Developers'],
        'secondary': ['CodingWithMitch', 'Stevdza-San', 'Simplified Coding'],
        'keywords': ['android', 'mobile', 'app development', 'tutorial', 'complete']
      },
      'ios': {
        'primary': ['CodeWithChris', 'Sean Allen', 'iOS Academy'],
        'secondary': ['Brian Advent', 'Lets Build That App', 'Swift Arcade'],
        'keywords': ['ios', 'swift', 'mobile', 'app development', 'tutorial']
      },
      'web development': {
        'primary': ['Traversy Media', 'freeCodeCamp', 'The Net Ninja'],
        'secondary': ['Web Dev Simplified', 'Academind', 'Dev Ed'],
        'keywords': ['web development', 'frontend', 'backend', 'tutorial', 'complete']
      },
      'data science': {
        'primary': ['freeCodeCamp', 'Corey Schafer', 'Krish Naik'],
        'secondary': ['Data School', 'Sentdex', 'StatQuest'],
        'keywords': ['data science', 'machine learning', 'python', 'tutorial', 'complete']
      },
      'machine learning': {
        'primary': ['3Blue1Brown', 'Andrew Ng', 'Krish Naik'],
        'secondary': ['Sentdex', 'Two Minute Papers', 'StatQuest'],
        'keywords': ['machine learning', 'ai', 'deep learning', 'tutorial', 'complete']
      },
      'memasak': {
        'primary': ['Bon Appétit', 'Tasty', 'Joshua Weissman'],
        'secondary': ['Binging with Babish', 'Chef John', 'Maangchi'],
        'keywords': ['memasak', 'resep', 'kuliner', 'tutorial', 'cooking']
      },
      'cooking': {
        'primary': ['Bon Appétit', 'Tasty', 'Joshua Weissman'],
        'secondary': ['Binging with Babish', 'Chef John', 'Maangchi'],
        'keywords': ['cooking', 'recipe', 'culinary', 'tutorial', 'food']
      },
      'olahraga': {
        'primary': ['Athlean-X', 'Calisthenic Movement', 'Yoga with Adriene'],
        'secondary': ['FitnessBlender', 'Jeff Nippard', 'Natacha Océane'],
        'keywords': ['olahraga', 'fitness', 'workout', 'exercise', 'training']
      },
      'fitness': {
        'primary': ['Athlean-X', 'Calisthenic Movement', 'Yoga with Adriene'],
        'secondary': ['FitnessBlender', 'Jeff Nippard', 'Natacha Océane'],
        'keywords': ['fitness', 'workout', 'exercise', 'training', 'health']
      },
      'seni': {
        'primary': ['Proko', 'Draw with Jazza', 'Peter Draws'],
        'secondary': ['The Art Assignment', 'Adobe Creative Cloud', 'Skillshare'],
        'keywords': ['seni', 'menggambar', 'lukis', 'tutorial', 'art']
      },
      'art': {
        'primary': ['Proko', 'Draw with Jazza', 'Peter Draws'],
        'secondary': ['The Art Assignment', 'Adobe Creative Cloud', 'Skillshare'],
        'keywords': ['art', 'drawing', 'painting', 'tutorial', 'creative']
      },
      'bisnis': {
        'primary': ['Ali Abdaal', 'Thomas Frank', 'Graham Stephan'],
        'secondary': ['Andrei Jikh', 'The Financial Diet', 'Harvard Business Review'],
        'keywords': ['bisnis', 'keuangan', 'investasi', 'tutorial', 'business']
      },
      'business': {
        'primary': ['Ali Abdaal', 'Thomas Frank', 'Graham Stephan'],
        'secondary': ['Andrei Jikh', 'The Financial Diet', 'Harvard Business Review'],
        'keywords': ['business', 'finance', 'investment', 'tutorial', 'money']
      },
      'musik': {
        'primary': ['Music Theory Guy', 'Andrew Huang', 'Rick Beato'],
        'secondary': ['Pianote', 'JustinGuitar', 'Marty Music'],
        'keywords': ['musik', 'instrumen', 'teori musik', 'tutorial', 'music']
      },
      'music': {
        'primary': ['Music Theory Guy', 'Andrew Huang', 'Rick Beato'],
        'secondary': ['Pianote', 'JustinGuitar', 'Marty Music'],
        'keywords': ['music', 'instrument', 'music theory', 'tutorial', 'song']
      },
      'bahasa': {
        'primary': ['SpanishDict', 'Learn French with Alexa', 'JapanesePod101'],
        'secondary': ['FluentU', 'Babbel', 'italki'],
        'keywords': ['bahasa', 'language', 'belajar bahasa', 'tutorial', 'conversation']
      },
      'language': {
        'primary': ['SpanishDict', 'Learn French with Alexa', 'JapanesePod101'],
        'secondary': ['FluentU', 'Babbel', 'italki'],
        'keywords': ['language', 'learning', 'conversation', 'tutorial', 'grammar']
      },
      'kesehatan': {
        'primary': ['Dr. Mike', 'What I\'ve Learned', 'Kurzgesagt'],
        'secondary': ['TED-Ed', 'Crash Course', 'SciShow'],
        'keywords': ['kesehatan', 'health', 'medical', 'tutorial', 'wellness']
      },
      'health': {
        'primary': ['Dr. Mike', 'What I\'ve Learned', 'Kurzgesagt'],
        'secondary': ['TED-Ed', 'Crash Course', 'SciShow'],
        'keywords': ['health', 'medical', 'wellness', 'tutorial', 'fitness']
      },
      'crafting': {
        'primary': ['5-Minute Crafts', 'DIY Creators', 'Steve Ramsey'],
        'secondary': ['April Wilkerson', 'Jimmy DiResta', 'Make Something'],
        'keywords': ['crafting', 'diy', 'handmade', 'tutorial', 'creative']
      },
      'fotografi': {
        'primary': ['Peter McKinnon', 'Mango Street', 'Sean Tucker'],
        'secondary': ['Jamie Windsor', 'Thomas Heaton', 'Ted Forbes'],
        'keywords': ['fotografi', 'photography', 'camera', 'tutorial', 'editing']
      },
      'photography': {
        'primary': ['Peter McKinnon', 'Mango Street', 'Sean Tucker'],
        'secondary': ['Jamie Windsor', 'Thomas Heaton', 'Ted Forbes'],
        'keywords': ['photography', 'camera', 'editing', 'tutorial', 'composition']
      },
      'berkebun': {
        'primary': ['Epic Gardening', 'Roots and Refuge Farm', 'Self Sufficient Me'],
        'secondary': ['Garden Answer', 'Migardener', 'Charles Dowding'],
        'keywords': ['berkebun', 'gardening', 'tanaman', 'tutorial', 'organic']
      },
      'gardening': {
        'primary': ['Epic Gardening', 'Roots and Refuge Farm', 'Self Sufficient Me'],
        'secondary': ['Garden Answer', 'Migardener', 'Charles Dowding'],
        'keywords': ['gardening', 'plants', 'organic', 'tutorial', 'growing']
      },
      'kecantikan': {
        'primary': ['James Charles', 'NikkieTutorials', 'Safiya Nygaard'],
        'secondary': ['Hyram', 'Caroline Hirons', 'Wayne Goss'],
        'keywords': ['kecantikan', 'makeup', 'skincare', 'tutorial', 'beauty']
      },
      'beauty': {
        'primary': ['James Charles', 'NikkieTutorials', 'Safiya Nygaard'],
        'secondary': ['Hyram', 'Caroline Hirons', 'Wayne Goss'],
        'keywords': ['beauty', 'makeup', 'skincare', 'tutorial', 'cosmetics']
      },
      'fashion': {
        'primary': ['bestdressed', 'Emma Chamberlain', 'Safiya Nygaard'],
        'secondary': ['Jenn Im', 'Aimee Song', 'Chriselle Lim'],
        'keywords': ['fashion', 'style', 'outfit', 'tutorial', 'clothing']
      },
      'parenting': {
        'primary': ['What to Expect', 'BabyCenter', 'The Modern Parents'],
        'secondary': ['Dad University', 'Mom vs The Boys', 'Family Fun Pack'],
        'keywords': ['parenting', 'baby', 'children', 'tutorial', 'family']
      },
      'teknologi': {
        'primary': ['Marques Brownlee', 'Unbox Therapy', 'Austin Evans'],
        'secondary': ['Dave2D', 'iJustine', 'Linus Tech Tips'],
        'keywords': ['teknologi', 'gadget', 'review', 'tutorial', 'tech']
      },
      'technology': {
        'primary': ['Marques Brownlee', 'Unbox Therapy', 'Austin Evans'],
        'secondary': ['Dave2D', 'iJustine', 'Linus Tech Tips'],
        'keywords': ['technology', 'gadget', 'review', 'tutorial', 'tech']
      },
      'yoga': {
        'primary': ['Yoga with Adriene', 'Breathe and Flow', 'Boho Beautiful'],
        'secondary': ['SarahBethYoga', 'Fightmaster Yoga', 'DoYogaWithMe'],
        'keywords': ['yoga', 'meditation', 'mindfulness', 'tutorial', 'wellness']
      },
      'meditation': {
        'primary': ['Headspace', 'Calm', 'The Honest Guys'],
        'secondary': ['Jason Stephenson', 'Michael Sealey', 'Mindful Movement'],
        'keywords': ['meditation', 'mindfulness', 'relaxation', 'tutorial', 'peace']
      },
      'travel': {
        'primary': ['Mark Wiens', 'Kara and Nate', 'Drew Binsky'],
        'secondary': ['Lost LeBlanc', 'Hey Nadine', 'Samuel and Audrey'],
        'keywords': ['travel', 'adventure', 'culture', 'tutorial', 'explore']
      },
      'wisata': {
        'primary': ['Mark Wiens', 'Kara and Nate', 'Drew Binsky'],
        'secondary': ['Lost LeBlanc', 'Hey Nadine', 'Samuel and Audrey'],
        'keywords': ['wisata', 'travel', 'adventure', 'tutorial', 'explore']
      }
    };

    // Find matching topic (more flexible matching)
    String? matchedKey;
    for (final key in channelMap.keys) {
      if (topic.toLowerCase().contains(key) || key.contains(topic.toLowerCase())) {
        matchedKey = key;
        break;
      }
    }
    
    if (matchedKey != null) {
      if (EnvConfig.isDebugMode) {
        print('✅ Found matching channels for: "$matchedKey"');
      }
      return channelMap[matchedKey]!;
    }

    // Generic fallback for any topic
    if (EnvConfig.isDebugMode) {
      print('⚠️ No specific channels found, using generic educational channels');
    }
    
    return {
      'primary': ['TED-Ed', 'Crash Course', 'Khan Academy'],
      'secondary': ['Skillshare', 'MasterClass', 'Coursera'],
      'keywords': ['tutorial', 'learning', 'education', 'guide', 'complete', topic.toLowerCase()]
    };
  }

  static List<Map<String, dynamic>> _generateSmartSearchQueries(
    String topic, 
    String subTopic, 
    Map<String, dynamic> channelData
  ) {
    final primaryChannels = List<String>.from(channelData['primary']);
    final keywords = List<String>.from(channelData['keywords']);
    
    // Clean topic/subtopic for any subject area
    final cleanTopic = _cleanTopic(topic);
    final cleanSubTopic = _cleanTopic(subTopic);
    
    if (EnvConfig.isDebugMode) {
      print('🧹 Cleaned topic: "$cleanTopic", subtopic: "$cleanSubTopic"');
    }
    
    // Try to get direct video URL for the main topic
    final directVideoUrl = getDirectVideoUrl(cleanTopic, cleanSubTopic);
    
    return [
      {
        'title': '$cleanSubTopic Tutorial - ${primaryChannels[0]}',
        'channel': primaryChannels[0],
        'description': 'Comprehensive tutorial covering $cleanSubTopic fundamentals with practical examples. Perfect for learning $cleanTopic step by step.',
        'search_terms': '${primaryChannels[0]} $cleanTopic $cleanSubTopic tutorial',
        'duration': '25-35 minutes',
        'difficulty': 'beginner',
        'why_relevant': 'Provides comprehensive coverage of $cleanSubTopic with step-by-step explanations and practical examples.',
        'direct_video_url': directVideoUrl,
        'youtube_url': directVideoUrl ?? 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${primaryChannels[0]} $cleanTopic $cleanSubTopic tutorial')}'
      },
      {
        'title': '$cleanTopic: $cleanSubTopic Practical Guide',
        'channel': primaryChannels.length > 1 ? primaryChannels[1] : primaryChannels[0],
        'description': 'Hands-on practical guide for $cleanSubTopic in $cleanTopic. Includes real-world examples and best practices.',
        'search_terms': '${primaryChannels.length > 1 ? primaryChannels[1] : primaryChannels[0]} $cleanTopic $cleanSubTopic guide',
        'duration': '20-30 minutes',
        'difficulty': 'intermediate',
        'why_relevant': 'Shows real-world implementation and practical use cases of $cleanSubTopic in $cleanTopic.',
        'youtube_url': 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${primaryChannels.length > 1 ? primaryChannels[1] : primaryChannels[0]} $cleanTopic $cleanSubTopic guide')}'
      },
      {
        'title': 'Learn $cleanSubTopic in $cleanTopic - Complete Course',
        'channel': primaryChannels.length > 2 ? primaryChannels[2] : primaryChannels[0],
        'description': 'Complete course for mastering $cleanSubTopic concepts in $cleanTopic. Includes exercises and practical examples.',
        'search_terms': '${primaryChannels.length > 2 ? primaryChannels[2] : primaryChannels[0]} $cleanTopic $cleanSubTopic complete course',
        'duration': '45-60 minutes',
        'difficulty': 'beginner',
        'why_relevant': 'Offers structured learning approach with clear progression from basics to advanced $cleanSubTopic concepts.',
        'youtube_url': 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${primaryChannels.length > 2 ? primaryChannels[2] : primaryChannels[0]} $cleanTopic $cleanSubTopic complete course')}'
      }
    ];
  }

  /// Clean and validate topics for any subject area - universal learning support
  static String _cleanTopic(String topic) {
    // Clean up the topic for universal learning - supports any subject
    final cleanedTopic = topic
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();
    
    if (EnvConfig.isDebugMode) {
      print('🧹 Cleaned topic: "$topic" -> "$cleanedTopic"');
    }
    
    return cleanedTopic.isEmpty ? 'Learning' : cleanedTopic;
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
    final title = json['title'] ?? 'Educational Video';
    final channel = json['channel'] ?? 'YouTube';
    
    // Try to get direct video URL first
    String youtubeUrl;
    if (json['direct_video_url'] != null && json['direct_video_url'].toString().isNotEmpty) {
      // Use direct video URL if provided
      youtubeUrl = json['direct_video_url'];
    } else if (json['direct_search_url'] != null && json['direct_search_url'].toString().isNotEmpty) {
      // Use direct search URL if provided
      youtubeUrl = json['direct_search_url'];
    } else {
      // Create search URL as fallback
      final encodedQuery = Uri.encodeComponent(searchQuery);
      youtubeUrl = 'https://www.youtube.com/results?search_query=$encodedQuery';
    }
    
    // Generate alternative search URLs for universal learning topics
    final alternativeUrls = <String>[];
    if (searchQuery.isNotEmpty) {
      final baseQuery = searchQuery.replaceAll(RegExp(r'\s+'), ' ').trim();
      alternativeUrls.addAll([
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$channel $baseQuery tutorial')}',
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$baseQuery tutorial complete')}',
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$baseQuery guide beginner')}',
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$baseQuery step by step')}',
      ]);
    }
    
    return YouTubeVideo(
      title: title,
      channel: channel,
      description: json['description'] ?? 'Educational content for learning',
      searchQuery: searchQuery,
      estimatedDuration: json['estimated_duration'] ?? '20 min',
      difficulty: json['difficulty'] ?? 'intermediate',
      whyRelevant: json['why_relevant'] ?? 'Relevant educational content for learning',
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
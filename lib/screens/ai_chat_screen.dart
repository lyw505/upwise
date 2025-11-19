import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../core/constants/app_colors.dart';
import '../models/content_summary_model.dart';
import '../providers/summarizer_provider.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialContent;
  final String? initialUrl;
  final ContentType contentType;
  final String? title;
  final DifficultyLevel? targetDifficulty;
  final List<String> tags;
  final bool includeKeyPoints;
  final String? learningPathId;

  const AiChatScreen({
    super.key,
    this.initialContent,
    this.initialUrl,
    required this.contentType,
    this.title,
    this.targetDifficulty,
    this.tags = const [],
    this.includeKeyPoints = true,
    this.learningPathId,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Start initial AI generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialGeneration();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startInitialGeneration() async {
    setState(() {
      _isGenerating = true;
    });

    // Add user's initial request
    _addMessage(ChatMessage(
      text: "Please summarize this content: ${widget.initialContent ?? widget.initialUrl}",
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Add AI thinking message
    _addMessage(ChatMessage(
      text: "",
      isUser: false,
      timestamp: DateTime.now(),
      isGenerating: true,
    ));

    try {
      final summarizerProvider = context.read<SummarizerProvider>();
      
      final request = SummaryRequestModel(
        content: widget.initialContent ?? widget.initialUrl ?? '',
        contentType: widget.contentType,
        title: widget.title,
        targetDifficulty: widget.targetDifficulty,
        customInstructions: widget.tags.join(', '),
        learningPathId: widget.learningPathId,
        contentSource: widget.initialUrl,
      );
      
      final summary = await summarizerProvider.generateSummary(request: request, autoSave: false);

      // Remove generating message
      setState(() {
        _messages.removeLast();
      });

      // Add AI response
      if (summary != null) {
        _addMessage(ChatMessage(
          text: _formatSummaryResponse(summary),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        _addMessage(ChatMessage(
          text: "I've processed your content, but encountered an issue generating the summary. How can I help you with this content?",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }

    } catch (e) {
      // Remove generating message
      setState(() {
        _messages.removeLast();
      });

      // Add error message
      _addMessage(ChatMessage(
        text: "Sorry, I encountered an error while generating the summary. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _formatSummaryResponse(ContentSummaryModel summary) {
    String response = "# ${summary.title}\n\n";
    response += "## Summary\n${summary.summary}\n\n";
    
    if (summary.keyPoints.isNotEmpty) {
      response += "## Key Points\n";
      for (String point in summary.keyPoints) {
        response += "• $point\n";
      }
      response += "\n";
    }
    
    if (summary.tags.isNotEmpty) {
      response += "## Tags\n${summary.tags.join(', ')}\n\n";
    }
    
    response += "💡 **What would you like to know more about?** You can ask me questions about this content!";
    
    return response;
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Add user message
    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Add AI thinking message
    _addMessage(ChatMessage(
      text: "",
      isUser: false,
      timestamp: DateTime.now(),
      isGenerating: true,
    ));

    setState(() {
      _isGenerating = true;
    });

    try {
      // Simulate AI response (replace with actual AI service call)
      await Future.delayed(const Duration(seconds: 2));
      
      // Remove generating message
      setState(() {
        _messages.removeLast();
      });

      // Add AI response
      _addMessage(ChatMessage(
        text: "I understand your question about: \"$text\". Let me provide more details based on the content we discussed earlier...",
        isUser: false,
        timestamp: DateTime.now(),
      ));

    } catch (e) {
      // Remove generating message
      setState(() {
        _messages.removeLast();
      });

      // Add error message
      _addMessage(ChatMessage(
        text: "Sorry, I couldn't process your request. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.psychology, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Assistant',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Chat with AI about your content',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.white),
                    onPressed: _saveConversation,
                    tooltip: 'Save to Library',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey[50]!,
                      Colors.white,
                    ],
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.psychology,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppColors.primary 
                    : message.isError 
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: message.isError 
                    ? Border.all(color: Colors.red.withValues(alpha: 0.3))
                    : null,
              ),
              child: message.isGenerating 
                  ? _buildTypingIndicator()
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser 
                            ? Colors.white 
                            : message.isError 
                                ? Colors.red[700]
                                : Colors.grey[800],
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AI is thinking',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        LoadingAnimationWidget.staggeredDotsWave(
          color: AppColors.primary,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Ask me anything about this content...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isGenerating 
                    ? [Colors.grey[400]!, Colors.grey[500]!]
                    : [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _isGenerating ? null : _sendMessage,
              icon: _isGenerating 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConversation() async {
    if (_messages.isEmpty) return;
    
    // Create a summary from the conversation
    final conversationText = _messages
        .where((m) => !m.isGenerating)
        .map((m) => "${m.isUser ? 'User' : 'AI'}: ${m.text}")
        .join('\n\n');
    
    // Save to library using SummarizerProvider
    final summarizerProvider = context.read<SummarizerProvider>();
    
    final summary = ContentSummaryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Will be set by provider if user is authenticated
      title: widget.title ?? 'AI Conversation',
      summary: conversationText,
      originalContent: widget.initialContent ?? widget.initialUrl ?? '',
      contentType: widget.contentType,
      tags: [...widget.tags, 'conversation', 'ai-chat'],
      keyPoints: [],
      difficultyLevel: widget.targetDifficulty ?? DifficultyLevel.intermediate,
      estimatedReadTime: (conversationText.length / 1000 * 5).round(),
      createdAt: DateTime.now(),
      isFavorite: false,
      learningPathId: widget.learningPathId,
    );
    
    await summarizerProvider.addSummary(summary);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation saved to library!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isGenerating;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isGenerating = false,
    this.isError = false,
  });
}

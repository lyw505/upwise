import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/content_summary_model.dart';
import '../providers/summarizer_provider.dart';
import '../core/constants/app_colors.dart';

class ConversationViewerScreen extends StatelessWidget {
  final ContentSummaryModel conversation;

  const ConversationViewerScreen({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse the conversation text back into messages
    final messages = _parseConversationText(conversation.summary);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(conversation.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              conversation.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () => _toggleFavorite(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteConversation(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Conversation'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with conversation info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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
                            'AI Conversation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Saved ${_formatDate(conversation.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (conversation.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: conversation.tags
                        .where((tag) => tag != 'conversation' && tag != 'ai-chat')
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ChatMessage> _parseConversationText(String conversationText) {
    final messages = <ChatMessage>[];
    final lines = conversationText.split('\n\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      if (line.startsWith('User: ')) {
        messages.add(ChatMessage(
          text: line.substring(6), // Remove "User: " prefix
          isUser: true,
          timestamp: DateTime.now(), // We don't have original timestamps
        ));
      } else if (line.startsWith('AI: ')) {
        messages.add(ChatMessage(
          text: line.substring(4), // Remove "AI: " prefix
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    }
    
    return messages;
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _toggleFavorite(BuildContext context) {
    final provider = context.read<SummarizerProvider>();
    provider.toggleFavorite(conversation.id);
  }

  void _deleteConversation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final provider = context.read<SummarizerProvider>();
              provider.deleteSummary(conversation.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to library
            },
            child: const Text('Delete'),
          ),
        ],
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

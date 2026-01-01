import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:datingapp/models/message_model.dart';
import 'package:datingapp/models/message_model.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/providers/user_provider.dart';
import 'package:datingapp/widgets/common/loading_indicator.dart';
import 'package:datingapp/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

// Provider for chat by ID
final chatProvider = StreamProvider.family<ChatModel?, String>((ref, chatId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return Stream.value(null);
  }
  
  return firestoreService.streamUserChats(currentUser.uid).map(
    (chats) => chats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => throw Exception('Chat not found'),
    ),
  );
});

// Provider for messages in a chat
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamMessages(chatId);
});

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    final currentUserData = ref.read(currentUserDataProvider).value;
    final chatAsync = ref.read(chatProvider(widget.chatId));
    
    if (currentUser == null || currentUserData == null) return;
    
    final chat = chatAsync.value;
    if (chat == null) return;

    final otherUserId = chat.getOtherUserId(currentUser.uid);

    setState(() => _isSending = true);

    try {
      final message = MessageModel(
        id: const Uuid().v4(),
        senderId: currentUser.uid,
        senderName: currentUserData.name,
        receiverId: otherUserId,
        text: _messageController.text.trim(),
        timestamp: DateTime.now(),
        read: false,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.sendMessage(widget.chatId, message);

      _messageController.clear();
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final currentUser = ref.watch(currentUserProvider);

    return chatAsync.when(
      data: (chat) {
        if (chat == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Chat not found')),
          );
        }

        final otherUserId = chat.getOtherUserId(currentUser!.uid);
        final otherUserAsync = ref.watch(userProvider(otherUserId));

        return Scaffold(
          appBar: AppBar(
            title: otherUserAsync.when(
              data: (otherUser) => otherUser != null
                  ? Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: otherUser.photoUrl.isNotEmpty
                              ? NetworkImage(otherUser.photoUrl)
                              : null,
                          child: otherUser.photoUrl.isEmpty
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(otherUser.name),
                      ],
                    )
                  : const Text('Chat'),
              loading: () => const Text('Loading...'),
              error: (_, __) => const Text('Chat'),
            ),
          ),
          body: Column(
            children: [
              // Messages List
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 60,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Send a message to start the conversation!',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUser.uid;
                        final showTime = index == messages.length - 1 ||
                            messages[index + 1].senderId != message.senderId;

                        return _MessageBubble(
                          message: message,
                          isMe: isMe,
                          showTime: showTime,
                        );
                      },
                    );
                  },
                  loading: () => const LoadingIndicator(),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ),

              // Message Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppTheme.cardDark,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                        onPressed: _isSending ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: LoadingIndicator(),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showTime;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showTime,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMe ? AppTheme.primaryGradient : null,
              color: isMe ? null : AppTheme.cardDark,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(
              message.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isMe ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
          if (showTime) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                timeFormat.format(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

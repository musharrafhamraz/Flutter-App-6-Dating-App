import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:datingapp/models/message_model.dart';
import 'package:datingapp/models/user_model.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/providers/user_provider.dart';
import 'package:datingapp/widgets/common/loading_indicator.dart';
import 'package:datingapp/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

// Provider for user chats
final userChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamUserChats(currentUser.uid);
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Messages Yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start chatting with your matches!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.getOtherUserId(currentUser!.uid);

              return _ChatTile(
                chat: chat,
                otherUserId: otherUserId,
              );
            },
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading chats...'),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String otherUserId;

  const _ChatTile({
    required this.chat,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserAsync = ref.watch(userProvider(otherUserId));

    return otherUserAsync.when(
      data: (otherUser) {
        if (otherUser == null) return const SizedBox();

        final timeFormat = DateFormat('hh:mm a');
        final lastMessageTime = chat.lastMessage != null
            ? timeFormat.format(chat.lastMessage!.timestamp)
            : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: otherUser.photoUrl.isNotEmpty
                  ? NetworkImage(otherUser.photoUrl)
                  : null,
              child: otherUser.photoUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              otherUser.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: chat.lastMessage != null
                ? Text(
                    chat.lastMessage!.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : Text(
                    'Start a conversation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessageTime.isNotEmpty)
                  Text(
                    lastMessageTime,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (chat.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${chat.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () => context.push('/chat/${chat.id}'),
          ),
        );
      },
      loading: () => const Card(
        child: ListTile(
          leading: CircleAvatar(child: CircularProgressIndicator()),
          title: Text('Loading...'),
        ),
      ),
      error: (_, __) => const SizedBox(),
    );
  }
}

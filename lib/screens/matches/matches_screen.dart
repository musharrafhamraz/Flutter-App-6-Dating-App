import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/user_provider.dart';
import 'package:datingapp/models/match_model.dart';
import 'package:datingapp/widgets/common/loading_indicator.dart';
import 'package:datingapp/core/theme/app_theme.dart';

// Provider for user matches
final userMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamUserMatches(currentUser.uid);
});

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(userMatchesProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Matches'),
      ),
      body: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Matches Yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join an event and play games to make connections!',
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
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final otherUserId = match.userIds.firstWhere((id) => id != currentUser?.uid);

              return _MatchTile(
                match: match,
                otherUserId: otherUserId,
              );
            },
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading matches...'),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _MatchTile extends ConsumerStatefulWidget {
  final MatchModel match;
  final String otherUserId;

  const _MatchTile({
    required this.match,
    required this.otherUserId,
  });

  @override
  ConsumerState<_MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends ConsumerState<_MatchTile> {
  bool _isNavigating = false;

  Future<void> _handleChatTap() async {
    if (_isNavigating) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isNavigating = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // 1. Check if chat already exists
      String? chatId = await firestoreService.getChatByMatchId(widget.match.id);
      
      // 2. If not, create it
      if (chatId == null) {
        chatId = await firestoreService.createChat(
          matchId: widget.match.id,
          participantIds: [currentUser.uid, widget.otherUserId],
        );
      }

      // 3. Navigate to chat
      if (mounted) {
        context.push('/chat/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUserAsync = ref.watch(userProvider(widget.otherUserId));

    return otherUserAsync.when(
      data: (otherUser) {
        if (otherUser == null) return const SizedBox();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: otherUser.photoUrl.isNotEmpty
                  ? NetworkImage(otherUser.photoUrl)
                  : null,
              child: otherUser.photoUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(otherUser.name),
            subtitle: Text('Matched via ${widget.match.gameType}'),
            trailing: _isNavigating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryPurple),
            onTap: _handleChatTap,
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.only(bottom: 16),
        child: ListTile(title: Text('Loading...')),
      ),
      error: (_, __) => const SizedBox(),
    );
  }
}

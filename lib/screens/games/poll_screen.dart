import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:datingapp/models/game_model.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/screens/games/icebreaker_screen.dart';
import 'package:datingapp/widgets/common/custom_button.dart';
import 'package:datingapp/widgets/common/loading_indicator.dart';
import 'package:datingapp/core/theme/app_theme.dart';

// Sample poll questions
final pollQuestions = [
  {
    'question': 'Best drink at this party?',
    'options': ['Beer', 'Wine', 'Cocktail', 'Soft Drink'],
  },
  {
    'question': 'Music preference?',
    'options': ['Pop', 'Rock', 'Hip-Hop', 'Electronic'],
  },
  {
    'question': 'Ideal weekend activity?',
    'options': ['Party', 'Netflix', 'Outdoor Adventure', 'Chill at Home'],
  },
  {
    'question': 'Favorite food type?',
    'options': ['Italian', 'Asian', 'Mexican', 'American'],
  },
  {
    'question': 'Travel style?',
    'options': ['Beach Resort', 'City Tour', 'Adventure', 'Road Trip'],
  },
];

class PollScreen extends ConsumerStatefulWidget {
  final String eventId;

  const PollScreen({super.key, required this.eventId});

  @override
  ConsumerState<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends ConsumerState<PollScreen> {
  bool _isSubmitting = false;

  Future<void> _createNewPoll() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final pollData = (pollQuestions..shuffle()).first;
      
      final game = GameModel(
        id: const Uuid().v4(),
        eventId: widget.eventId,
        type: GameType.poll,
        content: pollData['question'] as String,
        options: pollData['options'] as List<String>,
        responses: [],
        createdAt: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createGame(game);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New poll created!')),
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitVote(GameModel game, String option) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final response = GameResponse(
        userId: currentUser.uid,
        answer: option,
        timestamp: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.addGameResponse(game.id, response);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote submitted! 🗳️')),
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(eventGamesProvider(widget.eventId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Polls'),
      ),
      body: gamesAsync.when(
        data: (games) {
          final polls = games.where((g) => g.type == GameType.poll).toList();

          if (polls.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.poll,
                      size: 80,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Polls Yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create the first poll for this event!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Create Poll',
                      onPressed: _createNewPoll,
                      isLoading: _isSubmitting,
                      icon: Icons.add,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: polls.length + 1,
            itemBuilder: (context, index) {
              if (index == polls.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: CustomButton(
                    text: 'Create New Poll',
                    onPressed: _createNewPoll,
                    isLoading: _isSubmitting,
                    icon: Icons.add,
                    isOutlined: true,
                  ),
                );
              }

              final poll = polls[index];
              final hasVoted = poll.responses.any((r) => r.userId == currentUser?.uid);
              final totalVotes = poll.responses.length;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.poll,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              poll.content,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Vote count
                      Text(
                        '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      // Options
                      if (poll.options != null)
                        ...poll.options!.map((option) {
                          final optionVotes = poll.responses.where((r) => r.answer == option).length;
                          final percentage = totalVotes > 0 ? (optionVotes / totalVotes * 100).round() : 0;
                          final isUserChoice = hasVoted && 
                              poll.responses.any((r) => r.userId == currentUser?.uid && r.answer == option);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: hasVoted ? null : () => _submitVote(poll, option),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isUserChoice 
                                      ? AppTheme.primaryPurple.withOpacity(0.2)
                                      : AppTheme.surfaceDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isUserChoice
                                      ? Border.all(color: AppTheme.primaryPurple, width: 2)
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          option,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: isUserChoice ? FontWeight.bold : null,
                                          ),
                                        ),
                                        if (hasVoted)
                                          Text(
                                            '$percentage%',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.primaryPurple,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (hasVoted) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: totalVotes > 0 ? optionVotes / totalVotes : 0,
                                          backgroundColor: AppTheme.backgroundDark,
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            AppTheme.primaryPurple,
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading polls...'),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

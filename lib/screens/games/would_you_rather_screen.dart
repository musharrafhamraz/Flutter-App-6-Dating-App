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

// Would You Rather questions
final wouldYouRatherQuestions = [
  {
    'question': 'Would you rather...',
    'optionA': 'Have the ability to fly',
    'optionB': 'Have the ability to be invisible',
  },
  {
    'question': 'Would you rather...',
    'optionA': 'Always be 10 minutes late',
    'optionB': 'Always be 20 minutes early',
  },
  {
    'question': 'Would you rather...',
    'optionA': 'Live without music',
    'optionB': 'Live without movies',
  },
  {
    'question': 'Would you rather...',
    'optionA': 'Be able to speak all languages',
    'optionB': 'Be able to talk to animals',
  },
  {
    'question': 'Would you rather...',
    'optionA': 'Have unlimited money',
    'optionB': 'Have unlimited time',
  },
  {
    'question': 'Would you rather...',
    'optionA': 'Never use social media again',
    'optionB': 'Never watch another movie/show',
  },
  {
    'question': 'Would you rather...',
    'optionA': 'Always have to say everything on your mind',
    'optionB': 'Never speak again',
  },
  {
    'question': 'Would you rather...',
    'optionA': 'Be stuck on a broken ski lift',
    'optionB': 'Be stuck in a broken elevator',
  },
  {
    'question': 'Would you rather...',
    'optionA': 'Have a rewind button for your life',
    'optionB': 'Have a pause button for your life',
  },
  {
    'question': 'Would you rather...',
    'optionA': 'Always win at rock-paper-scissors',
    'optionB': 'Always know when someone is lying',
  },
];

class WouldYouRatherScreen extends ConsumerStatefulWidget {
  final String eventId;

  const WouldYouRatherScreen({super.key, required this.eventId});

  @override
  ConsumerState<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends ConsumerState<WouldYouRatherScreen> {
  bool _isSubmitting = false;

  Future<void> _createQuestion() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final questionData = (wouldYouRatherQuestions..shuffle()).first;
      
      final game = GameModel(
        id: const Uuid().v4(),
        eventId: widget.eventId,
        type: GameType.poll,
        content: questionData['question']!,
        options: [questionData['optionA']!, questionData['optionB']!],
        responses: [],
        createdAt: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createGame(game);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New question created! 🤔')),
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
          const SnackBar(content: Text('Choice submitted! 👍')),
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
        title: const Text('Would You Rather'),
      ),
      body: gamesAsync.when(
        data: (games) {
          // Filter would you rather games (polls with 2 options)
          final wyrGames = games.where((g) => 
            g.type == GameType.poll && 
            g.options != null && 
            g.options!.length == 2 &&
            g.content.contains('Would you rather')
          ).toList();

          if (wyrGames.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.help_outline,
                      size: 80,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Questions Yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create the first "Would You Rather" question!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Create Question',
                      onPressed: _createQuestion,
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
            itemCount: wyrGames.length + 1,
            itemBuilder: (context, index) {
              if (index == wyrGames.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: CustomButton(
                    text: 'New Question',
                    onPressed: _createQuestion,
                    isLoading: _isSubmitting,
                    icon: Icons.refresh,
                    isOutlined: true,
                  ),
                );
              }

              final game = wyrGames[index];
              final hasVoted = game.responses.any((r) => r.userId == currentUser?.uid);
              final totalVotes = game.responses.length;

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
                                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.help_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              game.content,
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
                      if (game.options != null)
                        ...game.options!.asMap().entries.map((entry) {
                          final option = entry.value;
                          final optionVotes = game.responses.where((r) => r.answer == option).length;
                          final percentage = totalVotes > 0 ? (optionVotes / totalVotes * 100).round() : 0;
                          final isUserChoice = hasVoted && 
                              game.responses.any((r) => r.userId == currentUser?.uid && r.answer == option);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: hasVoted ? null : () => _submitVote(game, option),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: isUserChoice 
                                      ? const LinearGradient(
                                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                                        )
                                      : null,
                                  color: isUserChoice ? null : AppTheme.surfaceDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isUserChoice
                                      ? Border.all(color: Colors.white, width: 2)
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: isUserChoice ? FontWeight.bold : null,
                                              color: isUserChoice ? Colors.white : null,
                                            ),
                                          ),
                                        ),
                                        if (hasVoted)
                                          Text(
                                            '$percentage%',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: isUserChoice ? Colors.white : AppTheme.primaryPurple,
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
                                          backgroundColor: isUserChoice 
                                              ? Colors.white.withOpacity(0.3)
                                              : AppTheme.backgroundDark,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isUserChoice ? Colors.white : AppTheme.primaryPurple,
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
        loading: () => const LoadingIndicator(message: 'Loading questions...'),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

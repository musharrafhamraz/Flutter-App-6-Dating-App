import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:datingapp/models/game_model.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/widgets/common/custom_button.dart';
import 'package:datingapp/widgets/common/loading_indicator.dart';
import 'package:datingapp/core/theme/app_theme.dart';

// Sample ice-breaker questions
final icebreakerQuestions = [
  "What's your go-to karaoke song?",
  "If you could have dinner with anyone, dead or alive, who would it be?",
  "What's the most spontaneous thing you've ever done?",
  "Beach vacation or mountain adventure?",
  "What's your hidden talent?",
  "Coffee or tea?",
  "Early bird or night owl?",
  "What's your favorite way to spend a weekend?",
  "If you could live in any era, which would you choose?",
  "What's the best concert you've ever been to?",
  "Cats or dogs?",
  "What's your comfort food?",
  "What's one thing on your bucket list?",
  "Favorite season and why?",
  "What's your superpower in the kitchen?",
];

// Provider for event games
final eventGamesProvider = StreamProvider.family<List<GameModel>, String>((ref, eventId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamEventGames(eventId);
});

class IcebreakerScreen extends ConsumerStatefulWidget {
  final String eventId;

  const IcebreakerScreen({super.key, required this.eventId});

  @override
  ConsumerState<IcebreakerScreen> createState() => _IcebreakerScreenState();
}

class _IcebreakerScreenState extends ConsumerState<IcebreakerScreen> {
  final _answerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(GameModel game) async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final response = GameResponse(
        userId: currentUser.uid,
        answer: _answerController.text.trim(),
        timestamp: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.addGameResponse(game.id, response);

      if (mounted) {
        _answerController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer submitted! 🎉')),
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

  Future<void> _createNewQuestion() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final question = (icebreakerQuestions..shuffle()).first;
      
      final game = GameModel(
        id: const Uuid().v4(),
        eventId: widget.eventId,
        type: GameType.icebreaker,
        content: question,
        responses: [],
        createdAt: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createGame(game);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New question generated!')),
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
        title: const Text('Ice-Breaker Questions'),
      ),
      body: gamesAsync.when(
        data: (games) {
          // Filter ice-breaker games
          final icebreakers = games.where((g) => g.type == GameType.icebreaker).toList();

          if (icebreakers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.question_answer,
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
                      'Be the first to start an ice-breaker!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Start Ice-Breaker',
                      onPressed: _createNewQuestion,
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
            itemCount: icebreakers.length + 1,
            itemBuilder: (context, index) {
              if (index == icebreakers.length) {
                // Add new question button
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: CustomButton(
                    text: 'Get New Question',
                    onPressed: _createNewQuestion,
                    isLoading: _isSubmitting,
                    icon: Icons.refresh,
                    isOutlined: true,
                  ),
                );
              }

              final game = icebreakers[index];
              final hasAnswered = game.responses.any((r) => r.userId == currentUser?.uid);

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
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.question_answer,
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

                      // Responses count
                      Text(
                        '${game.responses.length} ${game.responses.length == 1 ? 'response' : 'responses'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      // Answer input or user's answer
                      if (!hasAnswered) ...[
                        TextField(
                          controller: _answerController,
                          decoration: const InputDecoration(
                            hintText: 'Your answer...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Submit Answer',
                          onPressed: () => _submitAnswer(game),
                          isLoading: _isSubmitting,
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You answered: ${game.responses.firstWhere((r) => r.userId == currentUser?.uid).answer}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Show other responses
                        if (game.responses.length > 1) ...[
                          Text(
                            'Other Answers:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ...game.responses
                              .where((r) => r.userId != currentUser?.uid)
                              .map((response) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardDark,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        response.answer,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  )),
                        ],
                      ],
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

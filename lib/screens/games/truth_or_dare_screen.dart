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

// Truth or Dare prompts
final truthPrompts = [
  "What's the most embarrassing thing you've done at a party?",
  "Have you ever had a crush on someone here?",
  "What's your biggest fear in a relationship?",
  "What's the craziest thing you've done for love?",
  "Have you ever lied to get out of a date?",
  "What's your most awkward first date story?",
  "What's something you've never told anyone?",
  "Who was your first kiss?",
  "What's your guilty pleasure?",
  "Have you ever ghosted someone?",
];

final darePrompts = [
  "Dance with no music for 30 seconds",
  "Do your best celebrity impression",
  "Sing a song chosen by the group",
  "Tell a joke (it has to be funny!)",
  "Do 10 pushups right now",
  "Speak in an accent for the next 5 minutes",
  "Let someone go through your phone for 1 minute",
  "Post an embarrassing selfie",
  "Call someone and sing them happy birthday",
  "Do your best TikTok dance",
];

class TruthOrDareScreen extends ConsumerStatefulWidget {
  final String eventId;

  const TruthOrDareScreen({super.key, required this.eventId});

  @override
  ConsumerState<TruthOrDareScreen> createState() => _TruthOrDareScreenState();
}

class _TruthOrDareScreenState extends ConsumerState<TruthOrDareScreen> {
  bool _isSubmitting = false;

  Future<void> _createTruth() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final truth = (truthPrompts..shuffle()).first;
      
      final game = GameModel(
        id: const Uuid().v4(),
        eventId: widget.eventId,
        type: GameType.icebreaker, // Reusing icebreaker type
        content: "TRUTH: $truth",
        responses: [],
        createdAt: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createGame(game);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Truth revealed! 🤫')),
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

  Future<void> _createDare() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final dare = (darePrompts..shuffle()).first;
      
      final game = GameModel(
        id: const Uuid().v4(),
        eventId: widget.eventId,
        type: GameType.challenge, // Reusing challenge type
        content: "DARE: $dare",
        responses: [],
        createdAt: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createGame(game);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dare accepted! 💪')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Truth or Dare'),
      ),
      body: gamesAsync.when(
        data: (games) {
          // Filter truth or dare games
          final truthOrDareGames = games.where((g) => 
            g.content.startsWith('TRUTH:') || g.content.startsWith('DARE:')
          ).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.psychology,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Truth or Dare?',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your challenge and show everyone what you\'re made of!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Truth Button
                CustomButton(
                  text: 'TRUTH',
                  onPressed: _createTruth,
                  isLoading: _isSubmitting,
                  icon: Icons.question_answer,
                ),
                const SizedBox(height: 16),

                // Dare Button
                CustomButton(
                  text: 'DARE',
                  onPressed: _createDare,
                  isLoading: _isSubmitting,
                  icon: Icons.bolt,
                  isOutlined: true,
                ),
                const SizedBox(height: 32),

                // Recent Truths and Dares
                if (truthOrDareGames.isNotEmpty) ...[
                  Text(
                    'Recent Challenges',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...truthOrDareGames.take(5).map((game) {
                    final isTruth = game.content.startsWith('TRUTH:');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isTruth ? Colors.blue : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isTruth ? 'TRUTH' : 'DARE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              game.content.replaceFirst('TRUTH: ', '').replaceFirst('DARE: ', ''),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading...'),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

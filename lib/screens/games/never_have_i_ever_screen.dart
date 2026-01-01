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

final neverHaveIEverPrompts = [
  "Never have I ever been on a blind date.",
  "Never have I ever lied about my age.",
  "Never have I ever ghosted someone after a first date.",
  "Never have I ever fallen in love at first sight.",
  "Never have I ever gone on a date with someone I met at a party like this.",
  "Never have I ever sent a drink to a stranger.",
  "Never have I ever forgotten an anniversary.",
  "Never have I ever had a crush on a friend's sibling.",
  "Never have I ever snooped through a partner's phone.",
  "Never have I ever been to a music festival.",
  "Never have I ever done karaoke in public.",
  "Never have I ever used a fake name at a bar.",
  "Never have I ever had a crush on a teacher or boss.",
  "Never have I ever gone skinny dipping.",
  "Never have I ever stayed up all night talking to someone.",
];

class NeverHaveIEverScreen extends ConsumerStatefulWidget {
  final String eventId;

  const NeverHaveIEverScreen({super.key, required this.eventId});

  @override
  ConsumerState<NeverHaveIEverScreen> createState() => _NeverHaveIEverScreenState();
}

class _NeverHaveIEverScreenState extends ConsumerState<NeverHaveIEverScreen> {
  bool _isSubmitting = false;

  Future<void> _createNewPrompt() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final prompt = (neverHaveIEverPrompts..shuffle()).first;
      
      final game = GameModel(
        id: const Uuid().v4(),
        eventId: widget.eventId,
        type: GameType.icebreaker,
        content: "NEVER HAVE I EVER: $prompt",
        responses: [],
        createdAt: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createGame(game);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New prompt added! 😮')),
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
        title: const Text('Never Have I Ever'),
      ),
      body: gamesAsync.when(
        data: (games) {
          final neverGames = games.where((g) => g.content.startsWith('NEVER HAVE I EVER:')).toList();

          if (neverGames.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 80, color: AppTheme.textSecondary),
                    const SizedBox(height: 24),
                    Text('No Prompts Yet', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Start the Game',
                      onPressed: _createNewPrompt,
                      isLoading: _isSubmitting,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: neverGames.length,
                  itemBuilder: (context, index) {
                    final game = neverGames[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          game.content.replaceFirst('NEVER HAVE I EVER: ', ''),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  text: 'New Prompt',
                  onPressed: _createNewPrompt,
                  isLoading: _isSubmitting,
                  icon: Icons.refresh,
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

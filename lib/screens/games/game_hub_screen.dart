import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:datingapp/models/game_model.dart';
import 'package:datingapp/widgets/game_card.dart';
import 'package:datingapp/core/theme/app_theme.dart';

class GameHubScreen extends ConsumerWidget {
  final String eventId;

  const GameHubScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games & Ice-Breakers'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.games,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Break the Ice!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Play games to connect with people at this event',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Choose a Game',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Ice-Breaker Game
              GameCard(
                gameType: GameType.icebreaker,
                title: 'Ice-Breaker Questions',
                description: 'Answer fun questions and see who thinks like you',
                icon: Icons.question_answer,
                onTap: () => context.push('/game/icebreaker/$eventId'),
              ),
              const SizedBox(height: 16),

              // Poll Game
              GameCard(
                gameType: GameType.poll,
                title: 'Quick Polls',
                description: 'Vote on fun topics and find people with similar tastes',
                icon: Icons.poll,
                onTap: () => context.push('/game/poll/$eventId'),
              ),
              const SizedBox(height: 16),

              // Challenge Game
              GameCard(
                gameType: GameType.challenge,
                title: 'Send a Challenge',
                description: 'Send fun challenges to people nearby',
                icon: Icons.emoji_events,
                onTap: () => context.push('/game/challenge/$eventId'),
              ),
              const SizedBox(height: 16),

              // Truth or Dare
              GameCard(
                gameType: GameType.icebreaker,
                title: 'Truth or Dare',
                description: 'Reveal your secrets or show your courage',
                icon: Icons.psychology,
                onTap: () => context.push('/game/truth-or-dare/$eventId'),
              ),
              const SizedBox(height: 16),

              // Would You Rather
              GameCard(
                gameType: GameType.poll,
                title: 'Would You Rather',
                description: 'Make impossible choices and see what others choose',
                icon: Icons.help_outline,
                onTap: () => context.push('/game/would-you-rather/$eventId'),
              ),
              const SizedBox(height: 16),

              // Never Have I Ever
              GameCard(
                gameType: GameType.icebreaker,
                title: 'Never Have I Ever',
                description: 'Reveal your secrets with this classic party game',
                icon: Icons.warning_amber_rounded,
                onTap: () => context.push('/game/never-have-i-ever/$eventId'),
              ),
              const SizedBox(height: 16),

              // Spin the Bottle
              GameCard(
                gameType: GameType.challenge,
                title: 'Spin the Bottle',
                description: 'Virtual bottle spin to decide who speaks or acts next',
                icon: Icons.refresh,
                onTap: () => context.push('/game/spin-the-bottle/$eventId'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

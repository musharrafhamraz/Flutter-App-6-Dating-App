import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:datingapp/models/game_model.dart';
import 'package:datingapp/models/user_model.dart';
import 'package:datingapp/models/match_model.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/screens/events/active_event_screen.dart';
import 'package:datingapp/widgets/common/custom_button.dart';
import 'package:datingapp/widgets/common/loading_indicator.dart';
import 'package:datingapp/core/theme/app_theme.dart';

// Sample challenge prompts
final challengePrompts = [
  'Dance-off challenge! 💃',
  'Tell me your best joke 😄',
  'Let\'s grab a drink together 🍹',
  'Karaoke duet? 🎤',
  'Want to take a selfie? 📸',
  'Truth or dare? 🎲',
  'Rock paper scissors battle! ✊',
  'Let\'s start a conversation 💬',
];

class ChallengeScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String? initialUserId;

  const ChallengeScreen({
    super.key,
    required this.eventId,
    this.initialUserId,
  });

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  String? _selectedUserId;
  String? _selectedChallenge;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.initialUserId;
  }

  Future<void> _sendChallenge() async {
    if (_selectedUserId == null || _selectedChallenge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a person and a challenge')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Create game for the challenge
      final game = GameModel(
        id: const Uuid().v4(),
        eventId: widget.eventId,
        type: GameType.challenge,
        content: _selectedChallenge!,
        responses: [
          GameResponse(
            userId: currentUser.uid,
            answer: 'sent to $_selectedUserId',
            timestamp: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      await firestoreService.createGame(game);

      // Create a match
      final match = MatchModel(
        id: const Uuid().v4(),
        userIds: [currentUser.uid, _selectedUserId!],
        eventId: widget.eventId,
        gameType: 'challenge',
        createdAt: DateTime.now(),
      );

      await firestoreService.createMatch(match);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge sent! You\'ve matched! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset selection
        setState(() {
          _selectedUserId = null;
          _selectedChallenge = null;
        });
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
    final nearbyUsersAsync = ref.watch(nearbyUsersProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send a Challenge'),
      ),
      body: nearbyUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 80,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No One Nearby',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Wait for more people to join the event!',
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
                      colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Send a Fun Challenge',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pick someone and send them a challenge to connect!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Select Person
                Text(
                  'Step 1: Choose Someone',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                ...users.map((user) => _UserSelectionCard(
                      user: user,
                      isSelected: _selectedUserId == user.uid,
                      onTap: () => setState(() => _selectedUserId = user.uid),
                    )),

                const SizedBox(height: 24),

                // Select Challenge
                Text(
                  'Step 2: Pick a Challenge',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                ...challengePrompts.map((challenge) => _ChallengeCard(
                      challenge: challenge,
                      isSelected: _selectedChallenge == challenge,
                      onTap: () => setState(() => _selectedChallenge = challenge),
                    )),

                const SizedBox(height: 32),

                // Send Button
                CustomButton(
                  text: 'Send Challenge',
                  onPressed: _sendChallenge,
                  isLoading: _isSubmitting,
                  icon: Icons.send,
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Finding people...'),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _UserSelectionCard extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserSelectionCard({
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? AppTheme.primaryPurple.withOpacity(0.2) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.age} years old',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryPurple,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String challenge;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? AppTheme.primaryPink.withOpacity(0.2) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  challenge,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryPink,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

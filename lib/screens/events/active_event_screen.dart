import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datingapp/models/user_model.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/providers/user_provider.dart';
import 'package:datingapp/widgets/common/loading_indicator.dart';
import 'package:datingapp/core/theme/app_theme.dart';
import 'package:datingapp/core/constants/app_constants.dart';

// Provider for nearby users at event
final nearbyUsersProvider = StreamProvider.family<List<UserModel>, String>((ref, eventId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  final currentUserData = ref.watch(currentUserDataProvider);
  
  return firestoreService.streamEventAttendees(eventId).map((users) {
    // Filter out current user
    final currentUserId = currentUserData.value?.uid;
    return users.where((user) => user.uid != currentUserId).toList();
  });
});

class ActiveEventScreen extends ConsumerWidget {
  final String eventId;

  const ActiveEventScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyUsersAsync = ref.watch(nearbyUsersProvider(eventId));
    final currentUserData = ref.watch(currentUserDataProvider);
    final locationService = ref.read(locationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final shouldLeave = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Leave Event?'),
                  content: const Text('Are you sure you want to leave this event?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              );

              if (shouldLeave == true && context.mounted) {
                final firestoreService = ref.read(firestoreServiceProvider);
                final currentUser = currentUserData.value;
                if (currentUser != null) {
                  await firestoreService.leaveEvent(eventId, currentUser.uid);
                  if (context.mounted) {
                    context.go('/home');
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You\'re at the Event!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start playing games to connect with people nearby',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Nearby Users
            Expanded(
              child: nearbyUsersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    size: 60,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No One Nearby Yet',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Be patient! More people will join soon.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'People at this Event (${users.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            String? distance;

                            // Calculate distance if both users have location
                            if (currentUserData.value?.location != null && user.location != null) {
                              final distanceInMeters = locationService.calculateDistance(
                                currentUserData.value!.location!,
                                user.location!,
                              );
                              distance = locationService.formatDistance(distanceInMeters);
                            }

                            return _UserCard(
                              user: user,
                              distance: distance,
                              onTap: () {
                                context.push('/game/challenge/$eventId?userId=${user.uid}');
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const LoadingIndicator(message: 'Finding people nearby...'),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push('/event-chat/$eventId?name=Event'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        backgroundColor: AppTheme.surfaceDark,
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 20),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Group Chat',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push('/games/$eventId'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.games, size: 20),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Games & Mix',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final String? distance;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${user.age} years old',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (distance != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppTheme.primaryPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distance!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

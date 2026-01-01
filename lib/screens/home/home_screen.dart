import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/user_provider.dart';
import 'package:datingapp/core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(currentUserDataProvider);

    return userDataAsync.when(
      data: (userData) {
        if (userData == null) {
          return const Scaffold(
            body: Center(child: Text('User data not found')),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: userData.photoUrl.isNotEmpty
                                ? NetworkImage(userData.photoUrl)
                                : null,
                            child: userData.photoUrl.isEmpty
                                ? const Icon(Icons.person, size: 30)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hey, ${userData.name}! 👋',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ready to mix?',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'What would you like to do?',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),

                        // Active Event Card (if any)
                        if (userData.currentEventId != null) ...[
                          _MenuCard(
                            icon: Icons.bolt,
                            title: 'Active Event',
                            subtitle: 'You are currently at an event!',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                            ),
                            onTap: () => context.push('/active-event/${userData.currentEventId}'),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Events Card
                        _MenuCard(
                          icon: Icons.celebration,
                          title: 'Discover Events',
                          subtitle: 'Find parties and events near you',
                          gradient: AppTheme.primaryGradient,
                          onTap: () => context.push('/events'),
                        ),
                        const SizedBox(height: 16),
                        
                        // Matches Card
                        _MenuCard(
                          icon: Icons.favorite,
                          title: 'My Matches',
                          subtitle: 'See your connections',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                          ),
                          onTap: () => context.push('/matches'),
                        ),
                        const SizedBox(height: 16),
                        
                        // Chat Card
                        _MenuCard(
                          icon: Icons.chat_bubble,
                          title: 'Messages',
                          subtitle: 'Chat with your matches',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                          ),
                          onTap: () => context.push('/chats'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: AppTheme.surfaceDark,
            selectedItemColor: AppTheme.primaryPurple,
            unselectedItemColor: AppTheme.textSecondary,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.celebration),
                label: 'Events',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Matches',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/home');
                  break;
                case 1:
                  context.push('/events');
                  break;
                case 2:
                  context.push('/matches');
                  break;
                case 3:
                  context.push('/profile');
                  break;
              }
            },
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

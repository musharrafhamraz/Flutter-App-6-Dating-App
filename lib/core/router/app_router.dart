import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/user_provider.dart';
import 'package:datingapp/screens/auth/login_screen.dart';
import 'package:datingapp/screens/auth/signup_screen.dart';
import 'package:datingapp/screens/auth/profile_setup_screen.dart';
import 'package:datingapp/screens/home/home_screen.dart';
import 'package:datingapp/screens/events/event_discovery_screen.dart';
import 'package:datingapp/screens/events/event_detail_screen.dart';
import 'package:datingapp/screens/events/active_event_screen.dart';
import 'package:datingapp/screens/matches/matches_screen.dart';
import 'package:datingapp/screens/chat/chat_list_screen.dart';
import 'package:datingapp/screens/games/game_hub_screen.dart';
import 'package:datingapp/screens/games/icebreaker_screen.dart';
import 'package:datingapp/screens/games/poll_screen.dart';
import 'package:datingapp/screens/games/challenge_screen.dart';
import 'package:datingapp/screens/games/truth_or_dare_screen.dart';
import 'package:datingapp/screens/games/would_you_rather_screen.dart';
import 'package:datingapp/screens/games/never_have_i_ever_screen.dart';
import 'package:datingapp/screens/games/spin_the_bottle_screen.dart';
import 'package:datingapp/screens/chat/chat_screen.dart';
import 'package:datingapp/screens/chat/event_chat_screen.dart';
import 'package:datingapp/screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userDataAsync = ref.watch(currentUserDataProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isProfileSetup = state.matchedLocation == '/profile-setup';

      // If not logged in and not on auth screens, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in, check if user has completed profile setup
      if (isLoggedIn && !isProfileSetup) {
        final userData = userDataAsync.value;
        
        // If user data doesn't exist in Firestore, redirect to profile setup
        if (userData == null && !isLoggingIn) {
          return '/profile-setup';
        }
        
        // If on login/signup screens and profile is complete, go to home
        if (isLoggingIn && userData != null) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventDiscoveryScreen(),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventDetailScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/active-event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return ActiveEventScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/games/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return GameHubScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/game/icebreaker/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return IcebreakerScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/game/poll/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return PollScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/game/challenge/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final userId = state.uri.queryParameters['userId'];
          return ChallengeScreen(eventId: eventId, initialUserId: userId);
        },
      ),
      GoRoute(
        path: '/game/truth-or-dare/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return TruthOrDareScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/game/would-you-rather/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return WouldYouRatherScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/game/never-have-i-ever/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return NeverHaveIEverScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/game/spin-the-bottle/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return SpinTheBottleScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/matches',
        builder: (context, state) => const MatchesScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          return ChatScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '/event-chat/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final eventName = state.uri.queryParameters['name'] ?? 'Event';
          return EventChatScreen(
            eventId: eventId,
            eventName: eventName,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

class AppConstants {
  // App Info
  static const String appName = 'EventMix';
  static const String appTagline = 'Mix, Play, Connect at Live Events';
  
  // Proximity Settings
  static const double eventProximityRadius = 500.0; // meters
  static const double userProximityRadius = 100.0; // meters
  
  // Location Update Intervals
  static const int locationUpdateInterval = 30; // seconds
  
  // Game Types
  static const String gameTypeIcebreaker = 'icebreaker';
  static const String gameTypePoll = 'poll';
  static const String gameTypeChallenge = 'challenge';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String matchesCollection = 'matches';
  static const String chatsCollection = 'chats';
  static const String gamesCollection = 'games';
  
  // Storage Paths
  static const String profilePhotosPath = 'profile_photos';
  static const String eventPhotosPath = 'event_photos';
  
  // Validation
  static const int minAge = 18;
  static const int maxAge = 100;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minBioLength = 0;
  static const int maxBioLength = 500;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  
  // Animation Durations
  static const int shortAnimationDuration = 200; // milliseconds
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datingapp/core/constants/app_constants.dart';
import 'package:datingapp/models/user_model.dart';
import 'package:datingapp/models/event_model.dart';
import 'package:datingapp/models/game_model.dart';
import 'package:datingapp/models/match_model.dart';
import 'package:datingapp/models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================

  // Create user
  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestore());
  }

  // Get user
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(data);
  }

  // Update user location
  Future<void> updateUserLocation(String uid, GeoPoint location) async {
    await updateUser(uid, {'location': location});
  }

  // Stream user
  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ==================== EVENT OPERATIONS ====================

  // Create event
  Future<String> createEvent(EventModel event) async {
    final docRef = await _firestore
        .collection(AppConstants.eventsCollection)
        .add(event.toFirestore());
    return docRef.id;
  }

  // Get event
  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .get();

    if (doc.exists) {
      return EventModel.fromFirestore(doc);
    }
    return null;
  }

  // Stream nearby events
  Stream<List<EventModel>> streamNearbyEvents(GeoPoint userLocation) {
    // Note: For production, use GeoFlutterFire or similar for proper geoqueries
    // This is a simplified version
    return _firestore
        .collection(AppConstants.eventsCollection)
        .where('endTime', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Join event
  Future<void> joinEvent(String eventId, String userId) async {
    await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .update({
      'attendeeIds': FieldValue.arrayUnion([userId]),
    });

    await updateUser(userId, {'currentEventId': eventId});
  }

  // Leave event
  Future<void> leaveEvent(String eventId, String userId) async {
    await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .update({
      'attendeeIds': FieldValue.arrayRemove([userId]),
    });

    await updateUser(userId, {'currentEventId': null});
  }

  // Get users at event
  Stream<List<UserModel>> streamEventAttendees(String eventId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('currentEventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // ==================== GAME OPERATIONS ====================

  // Create game
  Future<String> createGame(GameModel game) async {
    final docRef = await _firestore
        .collection(AppConstants.gamesCollection)
        .add(game.toFirestore());
    return docRef.id;
  }

  // Get games for event
  Stream<List<GameModel>> streamEventGames(String eventId) {
    return _firestore
        .collection(AppConstants.gamesCollection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GameModel.fromFirestore(doc)).toList());
  }

  // Add game response
  Future<void> addGameResponse(String gameId, GameResponse response) async {
    await _firestore
        .collection(AppConstants.gamesCollection)
        .doc(gameId)
        .update({
      'responses': FieldValue.arrayUnion([response.toMap()]),
    });
  }

  // ==================== MATCH OPERATIONS ====================

  // Create match
  Future<String> createMatch(MatchModel match) async {
    final docRef = await _firestore
        .collection(AppConstants.matchesCollection)
        .add(match.toFirestore());
    return docRef.id;
  }

  // Get user matches
  Stream<List<MatchModel>> streamUserMatches(String userId) {
    return _firestore
        .collection(AppConstants.matchesCollection)
        .where('userIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc))
            .toList());
  }

  // Check if match exists
  Future<bool> matchExists(String userId1, String userId2) async {
    final snapshot = await _firestore
        .collection(AppConstants.matchesCollection)
        .where('userIds', arrayContains: userId1)
        .get();

    return snapshot.docs.any((doc) {
      final match = MatchModel.fromFirestore(doc);
      return match.userIds.contains(userId2);
    });
  }

  // ==================== CHAT OPERATIONS ====================

  // Create chat
  Future<String> createChat({
    String? matchId,
    String? eventId,
    String type = 'private',
    required List<String> participantIds,
  }) async {
    final chatData = {
      'matchId': matchId,
      'eventId': eventId,
      'type': type,
      'participantIds': participantIds,
      'lastMessage': null,
      'unreadCount': 0,
    };

    final docRef = await _firestore
        .collection(AppConstants.chatsCollection)
        .add(chatData);
    return docRef.id;
  }

  // Get chat by match ID
  Future<String?> getChatByMatchId(String matchId) async {
    final snapshot = await _firestore
        .collection(AppConstants.chatsCollection)
        .where('matchId', isEqualTo: matchId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }

  // Get existing private chat between two users
  Future<String?> getPrivateChat(String userId1, String userId2) async {
    final snapshot = await _firestore
        .collection(AppConstants.chatsCollection)
        .where('type', isEqualTo: 'private')
        .where('participantIds', arrayContains: userId1)
        .get();

    for (var doc in snapshot.docs) {
      final participants = List<String>.from(doc['participantIds'] ?? []);
      if (participants.contains(userId2)) {
        return doc.id;
      }
    }
    return null;
  }

  // Send message
  Future<void> sendMessage(String chatId, MessageModel message) async {
    // Add message to subcollection
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    // Update chat with last message
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
      'lastMessage': message.toFirestore(),
    });
  }

  // Stream messages
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Stream user chats
  Stream<List<ChatModel>> streamUserChats(String userId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList());
  }

  // Stream event group chat messages
  Stream<List<MessageModel>> streamEventMessages(String eventId) {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Send message to event group chat
  Future<void> sendEventMessage(String eventId, MessageModel message) async {
    await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .collection('messages')
        .add(message.toFirestore());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messagesSnapshot = await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // Seed test events nearby
  Future<void> seedEvents(GeoPoint location) async {
    final now = DateTime.now();
    
    final events = [
      EventModel(
        id: '',
        name: 'Rooftop Mixer',
        description: 'A cozy rooftop gathering for local professionals and creatives.',
        location: GeoPoint(location.latitude + 0.002, location.longitude + 0.002),
        address: '123 Sky Lounge, Downtown',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 4)),
        attendeeIds: [],
        createdBy: 'system',
        createdAt: now,
      ),
      EventModel(
        id: '',
        name: 'Tech & Coffee Meetup',
        description: 'Networking and coffee for developers and designers.',
        location: GeoPoint(location.latitude - 0.001, location.longitude + 0.003),
        address: 'Bean & Byte Cafe',
        startTime: now,
        endTime: now.add(const Duration(hours: 3)),
        attendeeIds: [],
        createdBy: 'system',
        createdAt: now,
      ),
      EventModel(
        id: '',
        name: 'Live Jazz Night',
        description: 'Enjoy smooth jazz and meet great people.',
        location: GeoPoint(location.latitude + 0.004, location.longitude - 0.001),
        address: 'Indigo Jazz Club',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 2)),
        attendeeIds: [],
        createdBy: 'system',
        createdAt: now,
      ),
    ];

    final batch = _firestore.batch();
    for (var event in events) {
      final docRef = _firestore.collection(AppConstants.eventsCollection).doc();
      batch.set(docRef, event.toFirestore());
    }
    await batch.commit();
  }
}

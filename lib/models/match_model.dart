import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MatchModel extends Equatable {
  final String id;
  final List<String> userIds;
  final String eventId;
  final String gameType;
  final DateTime createdAt;

  const MatchModel({
    required this.id,
    required this.userIds,
    required this.eventId,
    required this.gameType,
    required this.createdAt,
  });

  // From Firestore
  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      id: doc.id,
      userIds: List<String>.from(data['userIds'] ?? []),
      eventId: data['eventId'] ?? '',
      gameType: data['gameType'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userIds': userIds,
      'eventId': eventId,
      'gameType': gameType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Get other user ID
  String getOtherUserId(String currentUserId) {
    return userIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  @override
  List<Object?> get props => [id, userIds, eventId, gameType, createdAt];
}

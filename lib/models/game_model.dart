import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum GameType {
  icebreaker,
  poll,
  challenge,
}

class GameResponse extends Equatable {
  final String userId;
  final String answer;
  final DateTime timestamp;

  const GameResponse({
    required this.userId,
    required this.answer,
    required this.timestamp,
  });

  factory GameResponse.fromMap(Map<String, dynamic> map) {
    return GameResponse(
      userId: map['userId'] ?? '',
      answer: map['answer'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'answer': answer,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  @override
  List<Object?> get props => [userId, answer, timestamp];
}

class GameModel extends Equatable {
  final String id;
  final String eventId;
  final GameType type;
  final String content;
  final List<String>? options; // For polls
  final List<GameResponse> responses;
  final DateTime createdAt;

  const GameModel({
    required this.id,
    required this.eventId,
    required this.type,
    required this.content,
    this.options,
    required this.responses,
    required this.createdAt,
  });

  // From Firestore
  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    GameType gameType;
    switch (data['type']) {
      case 'poll':
        gameType = GameType.poll;
        break;
      case 'challenge':
        gameType = GameType.challenge;
        break;
      default:
        gameType = GameType.icebreaker;
    }

    return GameModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      type: gameType,
      content: data['content'] ?? '',
      options: data['options'] != null
          ? List<String>.from(data['options'])
          : null,
      responses: (data['responses'] as List<dynamic>?)
              ?.map((r) => GameResponse.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'type': type.name,
      'content': content,
      'options': options,
      'responses': responses.map((r) => r.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with
  GameModel copyWith({
    String? id,
    String? eventId,
    GameType? type,
    String? content,
    List<String>? options,
    List<GameResponse>? responses,
    DateTime? createdAt,
  }) {
    return GameModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      content: content ?? this.content,
      options: options ?? this.options,
      responses: responses ?? this.responses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        type,
        content,
        options,
        responses,
        createdAt,
      ];
}

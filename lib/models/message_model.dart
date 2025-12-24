import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final String id;
  final String senderId;
  final String senderName; // Add sender name for group chats
  final String receiverId; // Can be empty for group chats
  final String text;
  final DateTime timestamp;
  final bool read;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  // From Firestore
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] ?? false,
    );
  }

  // From Map (for subcollection)
  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] ?? false,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }

  // Copy with
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    bool? read,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }

  @override
  List<Object?> get props => [id, senderId, receiverId, text, timestamp, read];
}

class ChatModel extends Equatable {
  final String id;
  final String? matchId; // Null for group chats
  final String? eventId; // Set for group chats
  final String type; // 'private' or 'group'
  final List<String> participantIds;
  final MessageModel? lastMessage;
  final int unreadCount;

  const ChatModel({
    required this.id,
    this.matchId,
    this.eventId,
    this.type = 'private',
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
  });

  // From Firestore
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      matchId: data['matchId'],
      eventId: data['eventId'],
      type: data['type'] ?? 'private',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'] != null
          ? MessageModel.fromMap('', data['lastMessage'])
          : null,
      unreadCount: data['unreadCount'] ?? 0,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'eventId': eventId,
      'type': type,
      'participantIds': participantIds,
      'lastMessage': lastMessage?.toFirestore(),
      'unreadCount': unreadCount,
    };
  }

  // Get other user ID
  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  @override
  List<Object?> get props => [id, matchId, participantIds, lastMessage, unreadCount];
}

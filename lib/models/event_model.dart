import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class EventModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final GeoPoint location;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> attendeeIds;
  final String createdBy;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.attendeeIds,
    required this.createdBy,
    required this.createdAt,
  });

  // From Firestore
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] as GeoPoint,
      address: data['address'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'address': address,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'attendeeIds': attendeeIds,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with
  EventModel copyWith({
    String? id,
    String? name,
    String? description,
    GeoPoint? location,
    String? address,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? attendeeIds,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Check if event is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // Check if event is upcoming
  bool get isUpcoming {
    return DateTime.now().isBefore(startTime);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        location,
        address,
        startTime,
        endTime,
        attendeeIds,
        createdBy,
        createdAt,
      ];
}

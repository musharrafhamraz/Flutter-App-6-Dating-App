import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String name;
  final int age;
  final String bio;
  final String photoUrl;
  final GeoPoint? location;
  final String? currentEventId;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.age,
    required this.bio,
    required this.photoUrl,
    this.location,
    this.currentEventId,
    required this.createdAt,
  });

  // From Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      location: data['location'] as GeoPoint?,
      currentEventId: data['currentEventId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      'bio': bio,
      'photoUrl': photoUrl,
      'location': location,
      'currentEventId': currentEventId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with
  UserModel copyWith({
    String? uid,
    String? name,
    int? age,
    String? bio,
    String? photoUrl,
    GeoPoint? location,
    String? currentEventId,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      currentEventId: currentEventId ?? this.currentEventId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        age,
        bio,
        photoUrl,
        location,
        currentEventId,
        createdAt,
      ];
}

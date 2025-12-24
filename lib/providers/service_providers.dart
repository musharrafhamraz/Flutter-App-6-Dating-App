import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datingapp/services/firestore_service.dart';
import 'package:datingapp/services/location_service.dart';
import 'package:datingapp/services/storage_service.dart';

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Location Service Provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

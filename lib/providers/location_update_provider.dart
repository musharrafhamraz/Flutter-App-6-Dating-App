import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/service_providers.dart';

final locationUpdateProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final locationService = ref.read(locationServiceProvider);
  final firestoreService = ref.read(firestoreServiceProvider);

  // Stop if not logged in
  if (authState.value == null) return;

  final userId = authState.value!.uid;

  // Listen to location stream
  final stream = locationService.getLocationStream();
  
  final subscription = stream.listen((Position position) async {
    final geoPoint = GeoPoint(position.latitude, position.longitude);
    try {
      await firestoreService.updateUserLocation(userId, geoPoint);
      print('Location updated for user $userId: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  });

  // Cancel subscription when provider is disposed
  ref.onDispose(() => subscription.cancel());
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datingapp/models/user_model.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/service_providers.dart';

// Current User Data Provider
final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return Stream.value(null);
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUser(currentUser.uid);
});

// User Provider by ID
final userProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUser(userId);
});

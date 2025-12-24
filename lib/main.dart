import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:datingapp/core/theme/app_theme.dart';
import 'package:datingapp/core/router/app_router.dart';
import 'package:datingapp/providers/location_update_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start automated location updates
    ref.watch(locationUpdateProvider);
    
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'EventMix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

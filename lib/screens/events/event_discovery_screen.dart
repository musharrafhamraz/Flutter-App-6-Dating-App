import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datingapp/models/event_model.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/widgets/event_card.dart';
import 'package:datingapp/widgets/common/loading_indicator.dart';
import 'package:datingapp/core/theme/app_theme.dart';

// Provider for user location
final userLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  try {
    return await locationService.getCurrentLocation();
  } catch (e) {
    return null;
  }
});

// Provider for nearby events
final nearbyEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  final userLocationAsync = ref.watch(userLocationProvider);
  
  return userLocationAsync.when(
    data: (position) {
      if (position == null) {
        return Stream.value([]);
      }
      final geoPoint = GeoPoint(position.latitude, position.longitude);
      return firestoreService.streamNearbyEvents(geoPoint);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

class EventDiscoveryScreen extends ConsumerStatefulWidget {
  const EventDiscoveryScreen({super.key});

  @override
  ConsumerState<EventDiscoveryScreen> createState() => _EventDiscoveryScreenState();
}

class _EventDiscoveryScreenState extends ConsumerState<EventDiscoveryScreen> {
  bool _locationPermissionGranted = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final locationService = ref.read(locationServiceProvider);
    
    try {
      final permission = await locationService.checkPermission();
      
      if (permission == LocationPermission.denied) {
        final newPermission = await locationService.requestPermission();
        setState(() {
          _locationPermissionGranted = newPermission == LocationPermission.always ||
              newPermission == LocationPermission.whileInUse;
          _isCheckingPermission = false;
        });
      } else if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationPermissionGranted = false;
          _isCheckingPermission = false;
        });
      } else {
        setState(() {
          _locationPermissionGranted = true;
          _isCheckingPermission = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationPermissionGranted = false;
        _isCheckingPermission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Checking location permissions...'),
      );
    }

    if (!_locationPermissionGranted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Discover Events'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_off,
                  size: 80,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Location Permission Required',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We need your location to show nearby events and connect you with people at the same venue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _checkLocationPermission,
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final eventsAsync = ref.watch(nearbyEventsProvider);
    final userLocationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(nearbyEventsProvider);
              ref.invalidate(userLocationProvider);
            },
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.celebration_outlined,
                      size: 80,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Events Nearby',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'There are no events happening near you right now. Check back later!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final position = userLocationAsync.value;
                        if (position != null) {
                          final firestoreService = ref.read(firestoreServiceProvider);
                          await firestoreService.seedEvents(
                            GeoPoint(position.latitude, position.longitude),
                          );
                          ref.invalidate(nearbyEventsProvider);
                        }
                      },
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Seed Test Events Nearby'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return userLocationAsync.when(
            data: (position) {
              final locationService = ref.read(locationServiceProvider);
              
              // Sort events by distance
              final sortedEvents = List<EventModel>.from(events);
              if (position != null) {
                final userGeoPoint = GeoPoint(position.latitude, position.longitude);
                locationService.sortByDistance(
                  sortedEvents,
                  userGeoPoint,
                  (event) => event.location,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedEvents.length,
                itemBuilder: (context, index) {
                  final event = sortedEvents[index];
                  String? distance;
                  
                  if (position != null) {
                    final userGeoPoint = GeoPoint(position.latitude, position.longitude);
                    final distanceInMeters = locationService.calculateDistance(
                      userGeoPoint,
                      event.location,
                    );
                    distance = locationService.formatDistance(distanceInMeters);
                  }

                  return EventCard(
                    event: event,
                    distance: distance,
                    onTap: () => context.push('/event/${event.id}'),
                  );
                },
              );
            },
            loading: () => const LoadingIndicator(),
            error: (_, __) => const Center(child: Text('Error loading location')),
          );
        },
        loading: () => const LoadingIndicator(message: 'Finding events near you...'),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:datingapp/models/event_model.dart';
import 'package:datingapp/models/user_model.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/user_provider.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/widgets/common/custom_button.dart';
import 'package:datingapp/widgets/common/loading_indicator.dart';
import 'package:datingapp/core/theme/app_theme.dart';

// Provider for event by ID
final eventProvider = StreamProvider.family<EventModel?, String>((ref, eventId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamNearbyEvents(const GeoPoint(0, 0)).map(
    (events) => events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found'),
    ),
  );
});

// Provider for event attendees
final eventAttendeesProvider = StreamProvider.family<List<UserModel>, String>((ref, eventId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamEventAttendees(eventId);
});

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final currentUser = ref.watch(currentUserProvider);
    final currentUserData = ref.watch(currentUserDataProvider);

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Event not found')),
          );
        }

        final isAttending = currentUserData.value?.currentEventId == eventId;
        final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
        final timeFormat = DateFormat('hh:mm a');

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.celebration,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Name
                      Text(
                        event.name,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 16),

                      // Date & Time
                      _InfoRow(
                        icon: Icons.calendar_today,
                        text: dateFormat.format(event.startTime),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.access_time,
                        text: '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}',
                      ),
                      const SizedBox(height: 12),

                      // Location
                      _InfoRow(
                        icon: Icons.location_on,
                        text: event.address,
                      ),
                      const SizedBox(height: 12),

                      // Attendees
                      _InfoRow(
                        icon: Icons.people,
                        text: '${event.attendeeIds.length} people attending',
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Attendees Section
                      Text(
                        'Who\'s Going',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _AttendeesList(eventId: eventId),
                      const SizedBox(height: 32),

                      // Join/Leave/Go Button
                      if (currentUser != null)
                        Column(
                          children: [
                            if (isAttending)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CustomButton(
                                  text: 'Go to Event Mode',
                                  onPressed: () => context.push('/active-event/$eventId'),
                                  icon: Icons.celebration,
                                ),
                              ),
                            _JoinLeaveButton(
                              event: event,
                              isAttending: isAttending,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: LoadingIndicator(),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _AttendeesList extends ConsumerWidget {
  final String eventId;

  const _AttendeesList({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(eventAttendeesProvider(eventId));

    return attendeesAsync.when(
      data: (attendees) {
        if (attendees.isEmpty) {
          return Text(
            'No one has joined yet. Be the first!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          );
        }

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attendees.length,
            itemBuilder: (context, index) {
              final attendee = attendees[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: attendee.photoUrl.isNotEmpty
                          ? NetworkImage(attendee.photoUrl)
                          : null,
                      child: attendee.photoUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attendee.name,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _JoinLeaveButton extends ConsumerStatefulWidget {
  final EventModel event;
  final bool isAttending;

  const _JoinLeaveButton({
    required this.event,
    required this.isAttending,
  });

  @override
  ConsumerState<_JoinLeaveButton> createState() => _JoinLeaveButtonState();
}

class _JoinLeaveButtonState extends ConsumerState<_JoinLeaveButton> {
  bool _isLoading = false;

  Future<void> _handleJoinLeave() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      if (widget.isAttending) {
        await firestoreService.leaveEvent(widget.event.id, currentUser.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left event')),
          );
        }
      } else {
        await firestoreService.joinEvent(widget.event.id, currentUser.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined event! Start mixing!')),
          );
          context.push('/active-event/${widget.event.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: widget.isAttending ? 'Leave Event' : 'Join Event',
      onPressed: _handleJoinLeave,
      isLoading: _isLoading,
      backgroundColor: widget.isAttending ? Colors.red : null,
      icon: widget.isAttending ? Icons.exit_to_app : Icons.celebration,
    );
  }
}

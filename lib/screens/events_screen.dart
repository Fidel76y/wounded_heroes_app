import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
// Note: Assumes AddEventScreen exists in your project structure
import 'package:wounded_heroes_app/screens/add_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // Set default format to week for a more compact view, better fitting the "calendar on the right" feel on a mobile screen.
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _selectedEvents = [];
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchUserRole();
    // Fetch events right away
    _fetchEvents();
  }

  Future<void> _fetchUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      // Fetch only the 'role'
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _userRole = data['role'];
        });
      }
    } catch (e) { /* Optionally log error */ }
  }

  Future<void> _fetchEvents() async {
    // NOTE: Assuming the 'events' table now contains 'location', 'address', 'house_type', and 'image_url'
    final response = await Supabase.instance.client.from('events').select();
    final Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var event in response) {
      // Parse the event_date field to get a local DateTime object
      final eventDate = DateTime.parse(event['event_date']).toLocal();
      // Use UTC date for the key to ensure event loading works consistently across time zones
      final dayOnly = DateTime.utc(eventDate.year, eventDate.month, eventDate.day);

      if (events[dayOnly] == null) {
        events[dayOnly] = [];
      }
      events[dayOnly]!.add(event);
    }

    // Sort events by time
    events.forEach((key, value) {
      value.sort((a, b) =>
          DateTime.parse(a['event_date']).compareTo(DateTime.parse(b['event_date'])));
    });

    setState(() {
      _events = events;
      // Re-load events for the currently selected day
      _selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
    });
  }

  // Helper function to correctly get events for a given day key
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dayKey = DateTime.utc(day.year, day.month, day.day);
    return _events[dayKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  // --- NEW RICH EVENT CARD WIDGET ---
  Widget _buildEventCard(Map<String, dynamic> event) {
    final DateTime eventTime = DateTime.parse(event['event_date']).toLocal();

    // Safely retrieve assumed new fields
    final String location = event['location'] ?? 'Unknown Location';
    final String address = event['address'] ?? 'Address N/A';
    final String houseType = event['house_type'] ?? 'Venue Type N/A';
    final String imageUrl = event['image_url'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image and Date/Time Header
          Stack(
            children: [
              // Event Image (Placeholder or Network Image)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey.shade800,
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white70)),
                  ),
                )
                    : Container(
                  height: 150,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  child: Center(
                      child: Icon(Icons.event, size: 50, color: Theme.of(context).colorScheme.primary)
                  ),
                ),
              ),
              // Time and Date Overlay (Far Right)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('h:mm a').format(eventTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        DateFormat('EEE, MMM d').format(eventTime),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Title and Description
                Text(
                  event['title'] ?? 'No Title',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  event['description'] ?? 'No description provided.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Divider(height: 24),

                // 3. Location and Place Details
                _buildDetailRow(Icons.location_on, 'Location:', location),
                _buildDetailRow(Icons.place, 'Venue Type:', houseType),
                _buildDetailRow(Icons.directions, 'Address:', address),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for consistent detail display
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall, // Use bodySmall for consistency
                children: <TextSpan>[
                  TextSpan(
                    text: label,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  TextSpan(
                    text: ' $value',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    bool isAdminOrStaff = _userRole == 'admin' || _userRole == 'staff';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Events'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Calendar View (Top Position to maintain standard usability)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: (day) {
                return _getEventsForDay(day);
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() { _calendarFormat = format; });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // Hides the format button for a cleaner look
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _selectedEvents.isEmpty
                  ? 'No events scheduled for ${DateFormat('EEEE, MMM d').format(_selectedDay ?? _focusedDay)}.'
                  : 'Events for ${DateFormat('EEEE, MMM d').format(_selectedDay ?? _focusedDay)}:',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8.0),

          // 2. Events List View (Enhanced)
          Expanded(
            child: ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return _buildEventCard(event);
              },
            ),
          ),
        ],
      ),

      // Floating Action Button for Admins/Staff
      floatingActionButton: isAdminOrStaff
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEventScreen()))
          // Refresh events after returning from the AddEventScreen
              .then((_) {
            _fetchEvents();
            // Reset selected events to refresh the list
            setState(() {
              _selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
            });
          });
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
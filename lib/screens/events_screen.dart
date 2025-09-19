// lib/screens/events_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:wounded_heroes_app/screens/add_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
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
    _fetchEvents();
  }

  Future<void> _fetchUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
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
    } catch (e) { /* Handle error */ }
  }

  Future<void> _fetchEvents() async {
    final response = await Supabase.instance.client.from('events').select();
    final Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var event in response) {
      final eventDate = DateTime.parse(event['event_date']).toLocal();
      final dayOnly = DateTime.utc(eventDate.year, eventDate.month, eventDate.day);
      if (events[dayOnly] == null) {
        events[dayOnly] = [];
      }
      events[dayOnly]!.add(event);
    }
    setState(() {
      _events = events;
      _onDaySelected(_selectedDay!, _focusedDay);
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _events[DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day)] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdminOrStaff = _userRole == 'admin' || _userRole == 'staff';
    return Scaffold(
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: (day) {
              return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() { _calendarFormat = format; });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(event['title']),
                    subtitle: Text(event['description'] ?? ''),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdminOrStaff
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEventScreen()))
              .then((_) => _fetchEvents()); // Refresh events after adding
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
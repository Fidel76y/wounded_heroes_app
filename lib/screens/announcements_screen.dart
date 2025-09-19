// lib/screens/announcements_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wounded_heroes_app/screens/add_announcement_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _stream = Supabase.instance.client
      .from('announcements')
      .stream(primaryKey: ['id']).order('created_at', ascending: false);

  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
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
    } catch (e) {
      // Handle error, e.g., show a snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdminOrStaff = _userRole == 'admin' || _userRole == 'staff';

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final announcements = snapshot.data!;
          if (announcements.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              final createdAt = DateTime.parse(announcement['created_at']);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(
                    announcement['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(announcement['content']),
                  trailing: Text(timeago.format(createdAt)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isAdminOrStaff
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAnnouncementScreen()),
          );
        },
        child: const Icon(Icons.add),
      )
          : null, // Show nothing if not admin/staff
    );
  }
}
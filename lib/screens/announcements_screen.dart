// lib/screens/announcements_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:wounded_heroes_app/screens/add_announcement_screen.dart';
import 'package:wounded_heroes_app/screens/edit_announcement_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  Future<List<Map<String, dynamic>>>? _announcementsFuture;
  String? _userRole;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _announcementsFuture = _fetchAnnouncements();
    _fetchUserRole();
  }

  Future<List<Map<String, dynamic>>> _fetchAnnouncements() async {
    // Ensuring 'image_url' and 'id' are selected explicitly alongside '*'
    // to guarantee their presence, and joining to get the author's name.
    return await Supabase.instance.client
        .from('announcements')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false);
  }

  Future<void> _fetchUserRole() async {
    if (_userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', _userId!)
          .single();
      if (mounted) {
        setState(() { _userRole = data['role']; });
      }
    } catch (e) { /* Handle error */ }
  }

  Future<void> _deleteAnnouncement(String id) async {
    await Supabase.instance.client.from('announcements').delete().eq('id', id);
    _refreshAnnouncements();
  }

  void _refreshAnnouncements() {
    setState(() {
      _announcementsFuture = _fetchAnnouncements();
    });
  }

  void _showDeleteDialog(String announcementId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this announcement?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteAnnouncement(announcementId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- NEW RICH ANNOUNCEMENT CARD WIDGET ---
  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final author = announcement['profiles']?['full_name'] ?? 'Unknown Author';
    final createdAt = DateTime.parse(announcement['created_at']);
    final imageUrl = announcement['image_url'] as String? ?? '';
    final bool canEdit = (_userRole == 'admin' || _userRole == 'staff') &&
        _userId == announcement['author_id'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Header (Optional)
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    color: Colors.grey.shade800,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey.shade800,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.white70, size: 40)),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Author and Time Header with Actions
                Row(
                  children: [
                    CircleAvatar(child: Text(author.substring(0, 1).toUpperCase())),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              author,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                          // Displaying both exact date and time ago for best context
                          Text(
                              '${timeago.format(createdAt)} (${DateFormat('MMM d, yyyy').format(createdAt)})',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70)
                          ),
                        ],
                      ),
                    ),
                    if (canEdit)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditAnnouncementScreen(announcement: announcement)),
                              );
                              if (result == true) _refreshAnnouncements();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                            onPressed: () => _showDeleteDialog(announcement['id']),
                          ),
                        ],
                      )
                  ],
                ),

                const Divider(height: 24),

                // 3. Title
                Text(
                  announcement['title'] ?? 'Untitled Announcement',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // 4. Content/Body
                Text(
                  announcement['content'] ?? 'No content provided.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  // Removed maxLines to show full content
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAdminOrStaff = _userRole == 'admin' || _userRole == 'staff';

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAnnouncements();
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _announcementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final announcements = snapshot.data;
            if (announcements == null || announcements.isEmpty) {
              return const Center(child: Text('No announcements yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return _buildAnnouncementCard(announcement);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // We navigate to the add announcement screen
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAnnouncementScreen()),
          );
          // Refresh the list after returning
          _refreshAnnouncements();
        },
        child: const Icon(Icons.add),
      ),

    );
  }
}
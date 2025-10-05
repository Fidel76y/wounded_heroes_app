// lib/screens/add_announcement_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  _AddAnnouncementScreenState createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;
  bool _consentGiven = false;
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
        setState(() { _userRole = data['role']; });
      }
    } catch (e) { /* Handle error */ }
  }

  Future<void> _addAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      if (!_consentGiven) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You must consent to your name being displayed.'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      setState(() { _isLoading = true; });
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', userId)
            .single();
        final authorName = profile['full_name'] ?? 'Anonymous';
        final bool isAdmin = _userRole == 'admin' || _userRole == 'staff';

        await Supabase.instance.client.from('announcements').insert({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'image_url': _imageUrlController.text.trim(),
          'author_id': userId,
          'author_name': authorName,
          'is_approved': isAdmin,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAdmin
                ? 'Announcement posted successfully!'
                : 'Announcement submitted for approval!'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ));
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Announcement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Corrected TextFormField sections ---
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value!.isEmpty ? 'Title cannot be empty' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content/Body'),
              maxLines: 5,
              validator: (value) => value!.isEmpty ? 'Content cannot be empty' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (Optional)',
                helperText: 'A link to an image to include in the announcement card.',
              ),
              keyboardType: TextInputType.url,
            ),
            const Divider(height: 24),
            CheckboxListTile(
              title: const Text('I consent to my name being displayed with this announcement.'),
              value: _consentGiven,
              onChanged: (bool? value) {
                setState(() {
                  _consentGiven = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _addAnnouncement,
              child: const Text('Submit for Approval'),
            ),
          ],
        ),
      ),
    );
  }
}
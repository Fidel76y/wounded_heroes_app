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
  bool _isLoading = false;

  Future<void> _addAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        await Supabase.instance.client.from('announcements').insert({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'author_id': userId,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Announcement posted successfully!'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context); // Go back to the previous screen
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error posting announcement: $e'),
          backgroundColor: Colors.red,
        ));
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
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value!.isEmpty ? 'Title cannot be empty' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
              validator: (value) => value!.isEmpty ? 'Content cannot be empty' : null,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _addAnnouncement,
              child: const Text('Post Announcement'),
            ),
          ],
        ),
      ),
    );
  }
}
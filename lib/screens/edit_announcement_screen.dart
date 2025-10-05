// lib/screens/edit_announcement_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;

  const EditAnnouncementScreen({super.key, required this.announcement});

  @override
  _EditAnnouncementScreenState createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement['title']);
    _contentController = TextEditingController(text: widget.announcement['content']);
  }

  Future<void> _updateAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        await Supabase.instance.client.from('announcements').update({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
        }).eq('id', widget.announcement['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Announcement updated successfully!'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating announcement: $e'),
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
      appBar: AppBar(title: const Text('Edit Announcement')),
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
              onPressed: _updateAnnouncement,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
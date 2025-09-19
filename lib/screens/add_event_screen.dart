// lib/screens/add_event_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a date for the event.'),
          backgroundColor: Colors.red,
        ));
        return;
      }
      setState(() { _isLoading = true; });
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        await Supabase.instance.client.from('events').insert({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'event_date': _selectedDate!.toIso8601String(),
          'created_by': userId,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Event created successfully!'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error creating event: $e'),
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
      appBar: AppBar(title: const Text('New Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Event Title'),
              validator: (value) => value!.isEmpty ? 'Title cannot be empty' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'No date chosen!'
                        : 'Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Choose Date'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _addEvent, child: const Text('Create Event')),
          ],
        ),
      ),
    );
  }
}
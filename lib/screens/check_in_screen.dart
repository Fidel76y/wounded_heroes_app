// lib/screens/check_in_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  _CheckInScreenState createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  double _moodRating = 3.0;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitLog() async {
    setState(() { _isLoading = true; });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('wellbeing_logs').insert({
        'user_id': user.id,
        'mood_rating': _moodRating.toInt(),
        'notes': _notesController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Check-in saved successfully!'),
          backgroundColor: Colors.green,
        ));
        _notesController.clear();
        setState(() {
          _moodRating = 3.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving check-in: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'How are you feeling today?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Text(
            'Mood: ${_moodRating.toInt()}',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Slider(
            value: _moodRating,
            min: 1,
            max: 5,
            divisions: 4,
            label: _moodRating.round().toString(),
            onChanged: (value) {
              setState(() {
                _moodRating = value;
              });
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Optional Notes',
              hintText: 'Any thoughts you want to record?',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _submitLog,
            child: const Text('Save Today\'s Check-in'),
          ),
        ],
      ),
    );
  }
}
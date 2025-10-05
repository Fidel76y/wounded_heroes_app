import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- DATA MODELS ---
class MoodOption {
  final int rating;
  final String emoji;
  final String label;
  MoodOption(this.rating, this.emoji, this.label);
}

class BookSuggestion {
  final String title;
  final String author;
  final String vibe;
  BookSuggestion(this.title, this.author, this.vibe);
}
// --------------------

final List<MoodOption> moodOptions = [
  MoodOption(1, '😭', 'Terrible'),
  MoodOption(2, '😔', 'Bad'),
  MoodOption(3, '😐', 'Okay'),
  MoodOption(4, '😊', 'Good'),
  MoodOption(5, '🤩', 'Fantastic'),
];

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});
  @override
  _CheckInScreenState createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  int _moodRating = 3;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isReflecting = false;

  // --- CONTENT BY MOOD LEVEL ---

  // Mood 1/2: Low Mood Resources
  final String _encouragement =
      "It takes immense courage to show up, even on tough days. Your feelings are valid. Remember, you've faced hard times before and you are strong enough to get through this one. We're here for you.";

  final List<String> _lowMoodSuggestions = const [
    "Book Suggestion: 'The Alchemist' by Paulo Coelho (for perspective).",
    "Mindfulness Resource: Try a 5-minute guided meditation on YouTube for immediate calm.",
    "Actionable Tip: Go for a 10-minute walk outside, even if you don't feel like it.",
    "Quote: 'The best way out is always through.' - Robert Frost.",
  ];

  // Mood 3, 4, 5: High Mood Prompt & Mandatory Note Hint
  final String _gratitudePrompt =
      "You're in a great space! Take a moment to name **three things** you are grateful for right now. Guard this mood fiercely; it is a shield against negativity.";

  final String _upliftNoteHint =
      "***Mandatory:*** Please share your thoughts, your three grateful items, or one positive goal to help uplift others who may read this!";

  // Mood 3: Okay - Stability and Gentle Uplift
  final List<BookSuggestion> _okayBooks = [
    BookSuggestion("The Things You Can See Only When You Slow Down", "Haemin Sunim", "Soothing and mindful."),
    BookSuggestion("The Comfort Book", "Matt Haig", "Gentle, reassuring reflections."),
    BookSuggestion("Walden", "Henry David Thoreau", "Grounding and peace-inducing."),
  ];

  // Mood 4: Good - Momentum and Sustainable Growth
  final List<BookSuggestion> _goodBooks = [
    BookSuggestion("The Power of Habit", "Charles Duhigg", "Strategy for sustainable growth."),
    BookSuggestion("Deep Work", "Cal Newport", "Focuses existing energy on mastery."),
    BookSuggestion("Shoe Dog", "Phil Knight", "Inspiring memoir on persistence."),
  ];

  // Mood 5: Fantastic - High Energy, Adventure, and Bold Vision
  final List<BookSuggestion> _fantasticBooks = [
    BookSuggestion("Mistborn: The Final Empire", "Brandon Sanderson", "High-stakes, action-packed fantasy."),
    BookSuggestion("Cosmos", "Carl Sagan", "Amplifies wonder and grand vision."),
    BookSuggestion("Ready Player One", "Ernest Cline", "Fast-moving, high-octane escapism."),
  ];
  // -------------------------------------------

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_checkReflectionStatus);
  }

  @override
  void dispose() {
    _notesController.removeListener(_checkReflectionStatus);
    _notesController.dispose();
    super.dispose();
  }

  void _setMood(int newRating) {
    setState(() {
      _moodRating = newRating;
      if (newRating != 1) {
        _isReflecting = false;
      } else {
        _startReflectionPause();
      }
    });
  }

  void _checkReflectionStatus() {
    if (_moodRating == 1 && _isReflecting) {
      setState(() {
        _isReflecting = false;
      });
    }
  }

  void _startReflectionPause() async {
    if (_moodRating == 1 && _notesController.text.isEmpty) {
      setState(() {
        _isReflecting = true;
      });

      await Future.delayed(const Duration(seconds: 60));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reflection complete. Please record your thoughts.'),
          backgroundColor: Colors.blueGrey,
        ));
        setState(() {
          _isReflecting = false;
        });
      }
    }
  }

  Future<void> _submitLog() async {
    if (_isReflecting) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please complete the reflection pause before saving.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // NEW VALIDATION: Mandatory notes for positive moods
    if (_moodRating >= 3 && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please share your thoughts and gratitude to help uplift others! Notes are required for Good and Fantastic moods.'),
        backgroundColor: Colors.yellow,
        duration: Duration(seconds: 4),
      ));
      return;
    }

    setState(() { _isLoading = true; });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error: User not logged in.'),
          backgroundColor: Colors.red,
        ));
      }
      setState(() { _isLoading = false; });
      return;
    }

    try {
      await Supabase.instance.client.from('wellbeing_logs').insert({
        'user_id': user.id,
        'mood_rating': _moodRating,
        'notes': _notesController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Check-in saved successfully!'),
          backgroundColor: Colors.green,
        ));
        _notesController.clear();
        setState(() {
          _moodRating = 3;
          _isReflecting = false;
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

  // --- UI BUILDERS ---

  Widget _buildEncouragementSection() {
    if (_moodRating == 1) {
      if (_isReflecting) {
        return _buildReflectionPauseUI();
      }
      return _buildLowMoodSection('Terrible', Colors.redAccent);
    }
    else if (_moodRating == 2) {
      return _buildLowMoodSection('Bad', Theme.of(context).colorScheme.primary);
    }
    else if (_moodRating >= 3) {
      return _buildHighMoodSection();
    }
    return const SizedBox.shrink();
  }

  Widget _buildLowMoodSection(String moodLabel, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32),
          Text(
            'We see you\'re feeling $moodLabel. Here\'s some support:',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(color: color),
          ),
          const SizedBox(height: 12),
          _buildLowMoodResources(),
        ],
      ),
    );
  }

  // UPDATED: Now includes dynamic book recommendations
  Widget _buildHighMoodSection() {
    List<BookSuggestion> books;
    Color borderColor;
    String moodEmoji;

    if (_moodRating == 3) {
      books = _okayBooks;
      borderColor = Colors.blueGrey;
      moodEmoji = '👍';
    } else if (_moodRating == 4) {
      books = _goodBooks;
      borderColor = Colors.lightGreen;
      moodEmoji = '🚀';
    } else { // Mood 5
      books = _fantasticBooks;
      borderColor = Colors.amber;
      moodEmoji = '🌟';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32),
          Text(
            '✨ Cultivate and Protect Your Mood! ✨',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.greenAccent),
          ),
          const SizedBox(height: 12),

          // Main Gratitude Prompt Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(moodEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _gratitudePrompt,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            '📚 Tailored Reading to Amplify Your Mood:',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Book Suggestions
          ...books.map((book) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📖', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('by ${book.author}'),
                      Text('Vibe: ${book.vibe}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildLowMoodResources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.yellow.shade800),
          ),
          child: Text(
            _encouragement,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 16),
        ..._lowMoodSuggestions.map((suggestion) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Expanded(child: Text(suggestion)),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildReflectionPauseUI() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
      child: Column(
        children: [
          Text(
            '✋ Pause for 1 Minute',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          const Text(
            'Before typing, just pause. Close your eyes, take three deep breaths, and think of **one small thing** you are grateful for today.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Text(
            'You will automatically proceed in 60 seconds...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: moodOptions.map((mood) {
        bool isSelected = mood.rating == _moodRating;

        return GestureDetector(
          onTap: () => _setMood(mood.rating),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                      : null,
                ),
                child: Text(
                  mood.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mood.label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium!.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool notesDisabled = _isReflecting && _moodRating == 1;
    bool notesRequired = _moodRating >= 3;
    String labelText = notesRequired ? 'Notes (Required for Positive Moods)' : 'Optional Notes';
    String hintText;

    if (notesDisabled) {
      hintText = 'Please complete the pause before typing.';
    } else if (notesRequired) {
      hintText = _upliftNoteHint;
    } else {
      hintText = 'Any thoughts you want to record?';
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'How are you feeling today?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 30),

          _buildEmojiSelector(),
          const SizedBox(height: 40),

          _buildEncouragementSection(),

          TextFormField(
            controller: _notesController,
            enabled: !notesDisabled,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              // Use a red border to emphasize the requirement when mood is positive
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: notesRequired ? Colors.green : Colors.grey,
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: notesRequired ? Colors.green : Colors.grey.shade400,
                  width: 1.0,
                ),
              ),
              fillColor: notesDisabled ? Colors.grey.shade900 : null,
              filled: notesDisabled,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          _isLoading || notesDisabled
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
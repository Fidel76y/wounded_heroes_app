// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wounded_heroes_app/theme_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _fullName;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      setState(() {
        _fullName = data['full_name'];
        _email = user.email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: _fullName == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(_fullName ?? 'Loading...'),
            subtitle: Text(_email ?? ''),
          ),
          const Divider(),
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: const Icon(Icons.brightness_6),
                value: themeNotifier.themeMode == ThemeMode.dark,
                onChanged: (bool value) {
                  themeNotifier.toggleTheme();
                },
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              // Navigator.pop(context) is not needed because the AuthGate will handle the navigation
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
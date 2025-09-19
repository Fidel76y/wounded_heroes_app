// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wounded_heroes_app/screens/home_screen.dart';
import 'package:wounded_heroes_app/screens/login_screen.dart';
import 'package:wounded_heroes_app/theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nvoenaerhzmuqigbwwix.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im52b2VuYWVyaHptdXFpZ2J3d2l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyMzk2MzUsImV4cCI6MjA3MzgxNTYzNX0.e7M29ik8Hf2i_QHT6qSrSrJ7PbBi0tDneNJ5s_J2tHI',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Wounded Heroes Association',
          theme: ThemeData.light(), // Light theme data
          darkTheme: ThemeData.dark(), // Dark theme data
          themeMode: themeNotifier.themeMode, // Controlled by the notifier
          home: const AuthGate(),
        );
      },
    );
  }
}

// ... (AuthGate class remains the same) ...
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
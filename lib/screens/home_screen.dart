// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:wounded_heroes_app/screens/announcements_screen.dart';
import 'package:wounded_heroes_app/screens/events_screen.dart';
import 'package:wounded_heroes_app/screens/check_in_screen.dart';
import 'package:wounded_heroes_app/screens/dashboard_screen.dart';
import 'package:wounded_heroes_app/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // FIX 1: Changed 'const' to 'final' because the screen widgets aren't constant.
  static final List<Widget> _pages = <Widget>[
    const AnnouncementsScreen(),
    const EventsScreen(),
    const CheckInScreen(),
    const DashboardScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wounded Heroes'),
        actions: [
          IconButton(
            // FIX 2: Corrected the icon name to a valid Material icon.
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Announce',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Check-in',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
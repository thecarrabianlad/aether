import 'package:flutter/material.dart';
import 'package:aether/widgets/bottom_navbar.dart';
import 'package:aether/widgets/dashboard_top_bar.dart';
import 'package:aether/screens/dashboard/dashboard_screen.dart';
import 'package:aether/screens/academics/academics_screen.dart';
void main() {
  runApp(const AetherApp());
}

class AetherApp extends StatefulWidget {
  const AetherApp({super.key});

  @override
  State<AetherApp> createState() => _AetherAppState();
}

class _AetherAppState extends State<AetherApp> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    AcademicsScreen(),
    Center(
      child: Text(
        'Habits',
        style: TextStyle(color: Colors.white, fontSize: 32),
      ),
    ),
    Center(
      child: Text(
        'Health',
        style: TextStyle(color: Colors.white, fontSize: 32),
      ),
    ),
  ];

  void _onMenuTap() {
    // TODO: open drawer / menu
    print('Menu tapped');
  }

  void _onProfileTap() {
    // TODO: navigate to profile
    print('Profile tapped');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onAddTapped() {
    print('Add button tapped');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AETHER',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            DashboardTopBar(
              onMenuTap: _onMenuTap,
              onProfileTap: _onProfileTap,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavbar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          onAddTapped: _onAddTapped,
        ),
      ),
    );
  }
}
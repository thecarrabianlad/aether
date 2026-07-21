import 'package:flutter/material.dart';
import 'package:aether/widgets/bottom_navbar.dart';
import 'package:aether/widgets/dashboard_top_bar.dart';
import 'package:aether/screens/dashboard/dashboard_screen.dart';

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
              onMenuTap: () {
                // TODO: open drawer / menu
                print('Menu tapped');
              },
              onProfileTap: () {
                // TODO: navigate to profile
                print('Profile tapped');
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  DashboardScreen(),
                  Center(
                    child: Text(
                      'Academics',
                      style: TextStyle(color: Colors.white, fontSize: 32),
                    ),
                  ),
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
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavbar(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          onAddTapped: () {
            print('Add button tapped');
          },
        ),
      ),
    );
  }
}
// Standalone preview harness for the Habits screen.
//
// This renders the HabitsScreen directly, bypassing Supabase auth, so the
// UI can be visually verified against the reference design without a login
// flow or backend. It is NOT wired into the production app or router.
//
// Run with: flutter run -d edge -t lib/habits_preview.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/features/habits/screens/habits_screen.dart';
import 'package:aether/widgets/bottom_navbar.dart';

void main() {
  runApp(const ProviderScope(child: _HabitsPreviewApp()));
}

class _HabitsPreviewApp extends StatelessWidget {
  const _HabitsPreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habits Preview',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const _PreviewScaffold(),
    );
  }
}

class _PreviewScaffold extends StatelessWidget {
  const _PreviewScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const HabitsScreen(),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: 2,
        onItemTapped: (_) {},
        onAddTapped: () {},
      ),
    );
  }
}

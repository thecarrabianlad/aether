import 'package:aether/core/routing/app_router.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:aether/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aether/screens/academics/academics_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: AetherApp()));
}



class _AetherAppState extends State<AetherApp> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
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
  ];

  void _onMenuTap() {
    // TODO: open drawer / menu
    print('Menu tapped');
  }

  void _onProfileTap() {
    // TODO: navigate to profile
    print('Profile tapped');
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/academics');
        break;
      case 2:
        GoRouter.of(context).go('/habits');
        break;
      case 3:
        GoRouter.of(context).go('/health');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _calculateSelectedIndex(context),
        onItemTapped: (index) => _onItemTapped(index, context),
        onAddTapped: () {
          // TODO: Handle Add button tap, maybe show a modal
        },
      ),
    );
  }
}

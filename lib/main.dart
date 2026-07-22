import 'package:aether/core/routing/app_router.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:aether/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: AetherApp()));
}

class AetherApp extends ConsumerWidget {
  const AetherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AETHER',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        // You can add more theme customizations here to match your design
      ),
      routerConfig: router,
    );
  }
}

// This will be the main screen with the BottomNavbar after login
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({required this.child, super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/academics')) return 1;
    if (location.startsWith('/habits')) return 2;
    if (location.startsWith('/health')) return 3;
    if (location.startsWith('/')) return 0;
    return 0;
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

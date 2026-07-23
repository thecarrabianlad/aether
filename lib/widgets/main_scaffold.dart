import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aether/widgets/bottom_navbar.dart';
import 'package:aether/widgets/side_drawer.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/core/models/profile.dart';

/// Main scaffold with bottom navbar wrapping all authenticated routes.
class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({required this.child, super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/academics')) return 1;
    if (location.startsWith('/habits')) return 2;
    if (location.startsWith('/health')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
      case 1:
        GoRouter.of(context).go('/academics');
      case 2:
        GoRouter.of(context).go('/habits');
      case 3:
        GoRouter.of(context).go('/health');
    }
  }

  void _onNavItemTap(String itemId, BuildContext context, WidgetRef ref) {
    // Close drawer first
    ref.read(drawerProvider.notifier).state = false;

    // Navigate based on item id
    switch (itemId) {
      case 'profile':
        // TODO: Navigate to profile screen
        break;
      case 'premium':
        // TODO: Navigate to premium screen
        break;
      case 'settings':
        // TODO: Navigate to settings screen
        break;
    }
  }

  Future<void> _onLogout(BuildContext context, WidgetRef ref) async {
    // Close drawer
    ref.read(drawerProvider.notifier).state = false;
    await ref.read(authProvider).signOut();
    // GoRouter.of(context).go('/login'); // Handled by router refresh listener
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDrawerOpen = ref.watch(drawerProvider);

    // Default menu items
    const menuItems = [
      DrawerMenuItem(id: 'profile', label: 'Profile', icon: Icons.person_outline_rounded),
      DrawerMenuItem(id: 'premium', label: 'Premium', icon: Icons.diamond_outlined),
      DrawerMenuItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
    ];

    final profileAsync = ref.watch(profileProvider);

    final DrawerUserData userData;
    if (profileAsync is AsyncData && profileAsync.value != null) {
      final profile = profileAsync.value!;
      userData = DrawerUserData(
        name: profile.name,
        role: profile.role,
        avatarUrl: profile.avatarUrl,
        isPremium: profile.isPremium,
      );
    } else {
      userData = const DrawerUserData(
        name: 'Guest User',
        role: 'Not Logged In',
        isPremium: false,
      );
    }

    return Stack(
      children: [
        Scaffold(
          body: child,
          bottomNavigationBar: BottomNavbar(
            selectedIndex: _calculateSelectedIndex(context),
            onItemTapped: (index) => _onItemTapped(index, context),
            onAddTapped: () => GoRouter.of(context).go('/academics'),
          ),
        ),
        // Side drawer overlay
        SideDrawer(
          isOpen: isDrawerOpen,
          onClose: () => ref.read(drawerProvider.notifier).state = false,
          userData: userData,
          menuItems: menuItems,
          activeItemId: 'profile',
          onNavItemTap: (id) => _onNavItemTap(id, context, ref),
          onLogout: () => _onLogout(context, ref),
        ),
      ],
    );
  }
}



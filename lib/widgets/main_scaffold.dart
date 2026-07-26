import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState; // For AuthState
import 'package:aether/widgets/bottom_navbar.dart';
import 'package:aether/widgets/side_drawer.dart'; // New import for SideDrawer
import 'package:aether/widgets/first_login_dialog.dart'; // New import for FirstLoginDialog
import 'package:aether/core/providers.dart'; // For all new providers
import 'package:aether/core/models/profile.dart'; // For Profile model
import 'package:aether/core/services/profile_service.dart'; // For ProfileService

/// Main scaffold with bottom navbar wrapping all authenticated routes.
class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({required this.child, super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  bool _hasCheckedFirstLogin = false;

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
    // Navigation to /login is handled by router refresh listener
  }

  /// Check if this is a first-time login and prompt for username.
  Future<void> _checkFirstLogin(Profile? profile) async {
    debugPrint('MainScaffold: _checkFirstLogin called. Profile: $profile');
    if (_hasCheckedFirstLogin) {
      debugPrint('MainScaffold: Already checked first login, returning.');
      return;
    }
    _hasCheckedFirstLogin = true;

    // If no profile exists, this is a first login
    if (profile == null) {
      debugPrint('MainScaffold: Profile is null, showing first login dialog.');
      // Show the first login dialog
      final name = await showFirstLoginDialog(context);

      // Create/update profile with the entered name or default
      final service = ref.read(profileServiceProvider);
      final defaultName = ref.read(authProvider).currentUser?.email?.split('@').first ?? 'User';

      await service.upsertProfile(
        name: name ?? defaultName,
        avatarUrl: ProfileService.generateRandomAvatarUrl(),
      );

      // Refresh the profile provider
      ref.read(profileProvider.notifier).refresh();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logged in successfully!'),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes and invalidate profile provider
    ref.listen<AsyncValue<AuthState>>(
      authStateChangesProvider,
      (previous, next) {
        if (previous?.value?.event != next.value?.event) {
          debugPrint('MainScaffold: Auth state changed, invalidating profileProvider');
          ref.invalidate(profileProvider);
        }
      },
    );

    final isDrawerOpen = ref.watch(drawerProvider);
    debugPrint('MainScaffold: isDrawerOpen rebuilt as $isDrawerOpen');
    final profileAsync = ref.watch(profileProvider);

    // Check for first login when profile loads (deferred — showing a dialog
    // mid-build would push a route while the tree is locked).
    profileAsync.when(
      data: (profile) => WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkFirstLogin(profile),
      ),
      loading: () {},
      error: (_, __) {},
    );

    // Default menu items
    const menuItems = [
      DrawerMenuItem(id: 'profile', label: 'Profile', icon: Icons.person_outline_rounded),
      DrawerMenuItem(id: 'premium', label: 'Premium', icon: Icons.diamond_outlined),
      DrawerMenuItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
    ];

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
          body: widget.child,
          bottomNavigationBar: BottomNavbar(
            selectedIndex: _calculateSelectedIndex(context),
            onItemTapped: (index) => _onItemTapped(index, context),
            onAddTapped: () => GoRouter.of(context).go('/academics'), // Default action
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

import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Data Models
// ──────────────────────────────────────────────────────────────────────────────

/// Represents a navigation item in the drawer menu.
class DrawerMenuItem {
  final String id;
  final String label;
  final IconData icon;

  const DrawerMenuItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Represents the user's profile data shown in the drawer header.
class DrawerUserData {
  final String name;
  final String role;
  final String? avatarUrl;
  final bool isPremium;

  const DrawerUserData({
    required this.name,
    required this.role,
    this.avatarUrl,
    this.isPremium = false,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Side Drawer Widget
// ──────────────────────────────────────────────────────────────────────────────

/// Premium dark-mode side drawer / navigation panel.
///
/// Features:
/// - Slides in from the left with smooth animation
/// - Semi-transparent overlay that dims the background
/// - Profile header with avatar, name, role, and premium badge
/// - Configurable navigation items with active state highlighting
/// - Logout button at the bottom
///
/// Usage:
/// ```dart
/// SideDrawer(
///   isOpen: true,
///   onClose: () => setState(() => _isDrawerOpen = false),
///   userData: DrawerUserData(name: 'Alex Rivers', role: 'Computer Science Major'),
///   menuItems: [
///     DrawerMenuItem(id: 'profile', label: 'Profile', icon: Icons.person_outline),
///   ],
///   activeItemId: 'profile',
///   onNavItemTap: (id) { /* navigate */ },
///   onLogout: () { /* logout */ },
/// )
/// ```
class SideDrawer extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  // User data
  final DrawerUserData? userData;

  // Navigation items
  final List<DrawerMenuItem> menuItems;

  // Active / selected item
  final String? activeItemId;
  final void Function(String itemId)? onNavItemTap;

  // Logout
  final VoidCallback? onLogout;

  const SideDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.userData,
    this.menuItems = const [],
    this.activeItemId,
    this.onNavItemTap,
    this.onLogout,
  });

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  // ────────────────────────────────────────────────────────────────────────────
  // Animation Lifecycle
  // ────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // If initially open, show immediately
    if (widget.isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SideDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Color Palette
  // ────────────────────────────────────────────────────────────────────────────

  static const Color _overlayColor = Color(0xBE000000);
  static const Color _bgColor = Color(0xFF0D0D0D);
  static const Color _surfaceColor = Color(0xFF18181A);
  static const Color _borderColor = Color(0x1AFFFFFF);
  static const Color _accentColor = Color(0xFFE88D8A);
  static const Color _mutedTextColor = Color(0xFF8E8E93);
  static const Color _textColor = Color(0xFFF5F5F5);
  static const Color _badgeBgColor = Color(0xFF4A1E1E);
  static const Color _badgeBorderColor = Color(0xFFCC5E5E);
  static const Color _activeItemBgColor = Color(0x22E88D8A);
  static const Color _inactiveItemColor = Color(0xFFB0B0B0);
  static const Color _logoutBgColor = Color(0xFF2A1A1A);
  static const Color _logoutBorderColor = Color(0xFF4A2A2A);

  // ────────────────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Remove from tree when fully closed (not animating)
    if (_controller.isDismissed && !widget.isOpen) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.75;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          label: 'Navigation drawer',
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _controller.isAnimating ? null : widget.onClose,
              child: Container(
                color: _overlayColor.withValues(alpha: _fadeAnimation.value * 0.75),
                child: GestureDetector(
                  onTap: () {}, // prevent close on drawer tap
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: drawerWidth,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                          border: Border(
                            right: BorderSide(
                              color: _borderColor.withValues(alpha: _fadeAnimation.value * 0.1),
                              width: 1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _fadeAnimation.value * 0.5),
                              blurRadius: 40,
                              spreadRadius: 5,
                              offset: const Offset(4, 0),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Profile section
                              _buildProfileSection(),
                              // Navigation items
                              Expanded(child: _buildNavList()),
                              // Logout button
                              _buildLogoutSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Profile Section
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildProfileSection() {
    final user = widget.userData;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with glow ring and online status
          _buildAvatar(),

          const SizedBox(height: 20),

          // User name
          Text(
            user?.name ?? 'User',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textColor,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 4),

          // User role / subtitle
          Text(
            user?.role ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _mutedTextColor,
            ),
          ),

          const SizedBox(height: 16),

          // Premium badge
          if (user?.isPremium == true) _buildPremiumBadge(),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Avatar
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Semantics(
      label: '${widget.userData?.name ?? 'User'}\'s profile picture',
      image: true,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          children: [
            // Glowing ring
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _accentColor.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  backgroundColor: _surfaceColor,
                  backgroundImage: widget.userData?.avatarUrl != null
                      ? NetworkImage(widget.userData!.avatarUrl!)
                      : null,
                  child: widget.userData?.avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 36,
                          color: _mutedTextColor,
                        )
                      : null,
                ),
              ),
            ),

            // Online status dot
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CD964),
                  border: Border.all(color: _bgColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CD964).withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Premium Badge
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _badgeBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _badgeBorderColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _badgeBorderColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 16,
            color: _badgeBorderColor.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            'PREMIUM MEMBER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _badgeBorderColor.withValues(alpha: 0.9),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Navigation List
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildNavList() {
    if (widget.menuItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: widget.menuItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final item = widget.menuItems[index];
          final isActive = item.id == widget.activeItemId;

          return _buildNavItem(item, isActive);
        },
      ),
    );
  }

  Widget _buildNavItem(DrawerMenuItem item, bool isActive) {
    return Semantics(
      button: true,
      selected: isActive,
      label: '${item.label}${isActive ? ', selected' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onNavItemTap?.call(item.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: isActive ? _activeItemBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: isActive ? _accentColor : _inactiveItemColor,
                ),
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? _accentColor : _inactiveItemColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Logout Section
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Semantics(
        button: true,
        label: 'Log out',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onLogout,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: _logoutBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _logoutBorderColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: _badgeBorderColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _badgeBorderColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

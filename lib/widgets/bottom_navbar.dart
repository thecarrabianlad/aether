import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable dark glassmorphism bottom navigation bar.
///
/// Usage:
/// ```dart
/// BottomNavbar(
///   selectedIndex: _selectedIndex,
///   onItemTapped: (index) => setState(() => _selectedIndex = index),
///   onAddTapped: () {
///     // handle add button tap
///   },
/// )
/// ```
class BottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback? onAddTapped;

  const BottomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.onAddTapped,
  });

  static const Color _accentRed = Color(0xFFE8443F);
  static const Color _bgColor = Color(0xFF111111);

  // Nav items excluding the center Add button.
  // Index mapping to selectedIndex: 0=Dashboard, 1=Academics, 2=Habits, 3=Health
  static const List<_NavItemData> _items = [
    _NavItemData(icon: Icons.widgets_outlined, label: 'Dashboard'),
    _NavItemData(icon: Icons.menu_book_outlined, label: 'Academics'),
    _NavItemData(icon: Icons.back_hand_outlined, label: 'Habits'),
    _NavItemData(icon: Icons.favorite_border, label: 'Health'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Glassmorphism navbar container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 85,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgColor.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0),
                      _buildNavItem(1),
                      // Empty space reserved for the floating Add button
                      const SizedBox(width: 64),
                      _buildNavItem(2),
                      _buildNavItem(3),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating center "Add" button
          Positioned(
            bottom: 60,
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isSelected = selectedIndex == index;
    final Color color = isSelected ? _accentRed : Colors.white;
    final item = _items[index];

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          // Glowing red dot indicator for the selected tab
          AnimatedOpacity(
            opacity: isSelected ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentRed,
                boxShadow: [
                  BoxShadow(
                    color: _accentRed.withValues(alpha: 0.8),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAddTapped,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bgColor,
          border: Border.all(color: _accentRed, width: 2),
          boxShadow: [
            BoxShadow(
              color: _accentRed.withValues(alpha: 0.7),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: _accentRed.withValues(alpha: 0.4),
              blurRadius: 35,
              spreadRadius: 6,
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}
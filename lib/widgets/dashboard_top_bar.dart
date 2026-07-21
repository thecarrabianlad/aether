import 'dart:ui';

import 'package:flutter/material.dart';

class DashboardTopBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  const DashboardTopBar({
    super.key,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  static const Color _bgColor = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: _bgColor.withValues(alpha: 0.65),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                _TopBarIconButton(
                  icon: Icons.menu_rounded,
                  onTap: onMenuTap,
                ),
                Expanded(
                  child: Text(
                    'AETHER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 4,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                _TopBarIconButton(
                  icon: Icons.person_outline_rounded,
                  onTap: onProfileTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

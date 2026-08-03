import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A [CustomTransitionPage] that uses AETHER's shared fade-through
/// transition: the outgoing page fades out while the incoming page
/// fades in and slides up 8 px.
///
/// Transition durations/curves come from `context.motion` so they respect
/// the user's reduced-motion preference.
///
/// Usage in go_router:
/// ```dart
/// GoRoute(
///   path: '/settings',
///   pageBuilder: (context, state) => AetherPage(
///     key: state.pageKey,
///     name: state.name,
///     child: const SettingsScreen(),
///   ),
/// ),
/// ```
class AetherPage extends CustomTransitionPage<void> {
  AetherPage({
    required super.key,
    super.name,
    required Widget child,
    super.restorationId,
  }) : super(
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _AetherTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

class _AetherTransition extends StatelessWidget {
  const _AetherTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final dur = motion.of(context, motion.slow);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, widget) {
        // When dur is zero (reduced motion), skip the slide and just
        // cross-fade instantly.
        if (dur == Duration.zero) {
          return FadeTransition(opacity: animation, child: child);
        }
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: motion.emphasized,
          )),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0, 0.4, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
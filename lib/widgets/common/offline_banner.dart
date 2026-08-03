import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A slide-down banner that appears at the top of the screen when the
/// device is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final motion = context.motion;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: motion.base,
      curve: motion.easeOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: motion.base,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: aether.danger.withValues(alpha: 0.9),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'You\'re offline. Changes will sync later.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
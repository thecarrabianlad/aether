import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A button that morphs its label into a spinner while [isPending] is true.
/// Disables interaction while pending. Uses [AnimatedSwitcher] for the transition.
class ProgressButton extends StatelessWidget {
  const ProgressButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isPending = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isPending;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final motion = context.motion;

    return FilledButton(
      onPressed: isPending ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? aether.accent,
        foregroundColor: foregroundColor ?? Colors.black,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: AnimatedSwitcher(
        duration: motion.fast,
        child: isPending
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black54,
                ),
              )
            : Text(
                label,
                key: const ValueKey('label'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
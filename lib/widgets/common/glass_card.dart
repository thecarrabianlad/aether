import 'dart:ui';
import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;

  /// Card fill; defaults to the theme's card color.
  final Color? color;

  /// Hairline border; defaults to the theme's border color.
  final Color? borderColor;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.blur = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? aether.card).withValues(alpha: 0.6),
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: Border.all(
              color: (borderColor ?? aether.border).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

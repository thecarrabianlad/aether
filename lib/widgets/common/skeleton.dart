import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A shimmer placeholder matching the shape of a [GlassCard].
/// Pulses opacity 0.4→0.7→0.4 over ~1200 ms. Wrapped in a [RepaintBoundary]
/// so the pulse repaint stays cheap.
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({
    super.key,
    this.height = 96,
    this.width,
    this.radius = 24,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = 0.4 + 0.3 * _ctrl.value;
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: aether.card.withValues(alpha: t),
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: aether.border.withValues(alpha: 0.3 * t),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A list of skeleton cards for a screen that hasn't loaded yet.
/// Defaults to 6 cards at 96 px tall, 24 px radius.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonCard(),
        ),
      ),
    );
  }
}
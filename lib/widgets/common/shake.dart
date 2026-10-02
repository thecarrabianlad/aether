import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Wraps [child] and shakes it horizontally when [trigger] changes.
/// Ideal for signaling invalid input or failed authentication.
class ShakeWidget extends StatelessWidget {
  const ShakeWidget({
    super.key,
    required this.child,
    required this.trigger,
    this.offset = 8.0,
  });

  final Widget child;

  /// Every time this value changes, the shake animation fires.
  final Object? trigger;

  /// Horizontal displacement in pixels.
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Animate(
      key: ValueKey(trigger),
      effects: [
        ShakeEffect(
          curve: Curves.easeInOutSine,
          duration: 300.ms,
          offset: Offset(offset, 0),
          hz: 4,
        ),
      ],
      child: child,
    );
  }
}
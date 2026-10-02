import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aether/core/theme/app_theme.dart';

/// Animated 6-digit OTP input: a hidden [TextField] drives a row of
/// styled digit boxes.
///
/// Animations:
///  • Staggered entrance — boxes fade + slide up one after another.
///  • Focus/fill pop — the active box scales up with an accent glow and
///    digits pop in with a scale/fade.
///  • Error shake — the row shakes horizontally while boxes flash danger,
///    then the input clears and refocuses (trigger via [OtpInputState.shakeError]).
///  • Success — boxes and digits transition to the success color with a
///    glow (trigger via [OtpInputState.showSuccess]).
///
/// The parent drives error/success feedback through a
/// `GlobalKey<OtpInputState>`.
class OtpInput extends StatefulWidget {
  final int length;

  /// Fired once the full code has been entered.
  final ValueChanged<String> onCompleted;

  /// Disable input while the code is being verified.
  final bool enabled;

  const OtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.enabled = true,
  });

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _entrance;
  late final AnimationController _shake;

  bool _error = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    // Focus once the entrance animation has had a moment to play.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _shake.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    setState(() {});
    if (_controller.text.length == widget.length) {
      widget.onCompleted(_controller.text);
    }
  }

  /// Shakes the row, flashes danger, then clears and refocuses.
  void shakeError() {
    if (!mounted) return;
    setState(() => _error = true);
    HapticFeedback.mediumImpact();
    _shake.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _error = false;
        _controller.clear();
      });
      _focusNode.requestFocus();
    });
  }

  /// Transitions all boxes to the success color.
  void showSuccess() {
    if (!mounted) return;
    setState(() => _success = true);
    HapticFeedback.lightImpact();
    _focusNode.unfocus();
  }

  /// Clears the entered code and refocuses.
  void clear() {
    if (!mounted) return;
    setState(() {
      _error = false;
      _success = false;
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden field that actually receives keyboard input.
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 1,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled && !_success,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                autofillHints: const [AutofillHints.oneTimeCode],
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final v = _shake.value;
              // Three decaying horizontal oscillations.
              final dx = math.sin(v * math.pi * 6) * 8 * (1 - v);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.length, (i) {
                final entranceCurve = CurvedAnimation(
                  parent: _entrance,
                  curve: Interval(
                    i * 0.08,
                    i * 0.08 + 0.5,
                    curve: Curves.easeOutCubic,
                  ),
                );
                return AnimatedBuilder(
                  animation: entranceCurve,
                  builder: (context, child) {
                    return Opacity(
                      opacity: entranceCurve.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - entranceCurve.value) * 16),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: i == widget.length - 1 ? 0 : 10),
                    child: _OtpBox(
                      digit: i < text.length ? text[i] : '',
                      isActive: widget.enabled &&
                          !_success &&
                          _focusNode.hasFocus &&
                          i == text.length.clamp(0, widget.length - 1) &&
                          text.length < widget.length,
                      isFilled: i < text.length,
                      isError: _error,
                      isSuccess: _success,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single digit box. All state transitions animate implicitly.
class _OtpBox extends StatelessWidget {
  final String digit;
  final bool isActive;
  final bool isFilled;
  final bool isError;
  final bool isSuccess;

  const _OtpBox({
    required this.digit,
    required this.isActive,
    required this.isFilled,
    required this.isError,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;

    final Color borderColor;
    if (isError) {
      borderColor = aether.danger;
    } else if (isSuccess) {
      borderColor = aether.success;
    } else if (isActive || isFilled) {
      borderColor = aether.accent;
    } else {
      borderColor = aether.border;
    }

    final bool glowing = isActive || isError || isSuccess;

    return AnimatedScale(
      scale: isActive ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aether.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: glowing
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween(begin: 0.5, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            digit,
            key: ValueKey(digit),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isSuccess ? aether.success : aether.text,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius borderRadius;

  const CustomProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor = const Color(0xFF3A3A3C),
    this.height = 6.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(3)),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

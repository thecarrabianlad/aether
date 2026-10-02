import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DateNavigatorCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const DateNavigatorCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: context.aether.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.aether.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onPrevious,
            child: Icon(Icons.chevron_left,
                color: context.aether.textMuted, size: 22),
          ),
          Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.aether.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.aether.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onNext,
            child: Icon(Icons.chevron_right,
                color: context.aether.textMuted, size: 22),
          ),
        ],
      ),
    );
  }
}

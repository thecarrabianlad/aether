import 'package:flutter/material.dart';
import 'package:aether/widgets/common/glass_card.dart';

class UpcomingLectureTile extends StatelessWidget {
  final String title;
  final String chapter;
  final String tag;
  final String time;
  final Color accentColor;
  final bool isCompleted;
  final ValueChanged<bool>? onCompletionChanged;

  const UpcomingLectureTile({
    super.key,
    required this.title,
    required this.chapter,
    required this.tag,
    required this.time,
    required this.accentColor,
    this.isCompleted = false,
    this.onCompletionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onCompletionChanged?.call(!isCompleted),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? accentColor : const Color(0xFF5A5A5E),
                  width: 1.5,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    )),
                const SizedBox(height: 4),
                Text(chapter,
                    style: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Text(tag, style: TextStyle(color: accentColor, fontSize: 11)),
              ),
              const SizedBox(height: 6),
              Text(time,
                  style: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
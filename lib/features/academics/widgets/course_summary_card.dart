import 'package:flutter/material.dart';
import 'package:aether/widgets/common/glass_card.dart';
import 'package:aether/widgets/common/progress_bar.dart';

class CourseSummaryCard extends StatelessWidget {
  final String courseName;
  final String professor;
  final String time;
  final String room;
  final double progress;
  final Color accentColor;
  final VoidCallback onTap;

  const CourseSummaryCard({
    super.key,
    required this.courseName,
    required this.professor,
    required this.time,
    required this.room,
    required this.progress,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12),
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.menu_book_outlined, color: accentColor, size: 18),
              ),
              const SizedBox(height: 12),
              Text(courseName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(professor,
                  style: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 11)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF9A9A9E), size: 12),
                  const SizedBox(width: 4),
                  Text(time,
                      style: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 11)),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on, color: Color(0xFF9A9A9E), size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(room,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 11))),
                ],
              ),
              const SizedBox(height: 12),
              CustomProgressBar(progress: progress, color: accentColor, height: 4),
              const SizedBox(height: 4),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: accentColor, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
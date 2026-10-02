import 'package:flutter/material.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class GradeTile extends StatelessWidget {
  final Grade grade;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GradeTile({
    super.key,
    required this.grade,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    // Determine color based on grade value
    Color gradeColor;
    if (grade.gradeValue == null || grade.totalPoints == null || grade.totalPoints == 0) {
      gradeColor = aether.textMuted; // Neutral for ungraded
    } else {
      double percentage = (grade.gradeValue! / grade.totalPoints!) * 100;
      if (percentage >= 90) {
        gradeColor = Colors.green.shade400; // Excellent
      } else if (percentage >= 80) {
        gradeColor = Colors.lightGreen.shade400; // Good
      } else if (percentage >= 70) {
        gradeColor = Colors.orange.shade400; // Average
      } else if (percentage >= 60) {
        gradeColor = Colors.deepOrange.shade400; // Below average
      } else {
        gradeColor = Colors.red.shade400; // Failing
      }
    }


    return Card(
      color: aether.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.title,
                    style: TextStyle(
                      color: aether.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (grade.gradedAt != null)
                    Text(
                      'Graded on: ${DateFormat('dd MMM yyyy').format(grade.gradedAt!)}',
                      style: TextStyle(
                        color: aether.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  if (grade.feedback != null && grade.feedback!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        grade.feedback!,
                        style: TextStyle(
                          color: aether.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  grade.gradeValue != null && grade.totalPoints != null
                      ? '${grade.gradeValue!.toStringAsFixed(1)} / ${grade.totalPoints!.toStringAsFixed(1)}'
                      : 'N/A',
                  style: TextStyle(
                    color: gradeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (grade.gradeValue != null && grade.totalPoints != null && grade.totalPoints! > 0)
                  Text(
                    '${((grade.gradeValue! / grade.totalPoints!) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: gradeColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: aether.textMuted, size: 20),
                  color: aether.surfaceAlt,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit', style: TextStyle(color: aether.text)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: aether.danger)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

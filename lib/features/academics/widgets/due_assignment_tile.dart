import 'package:flutter/material.dart';
import 'package:aether/widgets/common/glass_card.dart';

class DueAssignmentTile extends StatelessWidget {
  final String title;
  final String dueDate;
  final String daysLeft;
  final Color color;
  final bool isCompleted;
  final ValueChanged<bool>? onCompletionChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DueAssignmentTile({
    super.key,
    required this.title,
    required this.dueDate,
    required this.daysLeft,
    required this.color,
    this.isCompleted = false,
    this.onCompletionChanged,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1C1C1E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A5A5E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (onEdit != null)
                    ListTile(
                      leading: const Icon(Icons.edit_outlined, color: Colors.white),
                      title: const Text('Edit Assignment',
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        onEdit!();
                      },
                    ),
                  if (onDelete != null)
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Delete Assignment',
                          style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        onDelete!();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: GlassCard(
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
                  color: isCompleted ? color : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? color : const Color(0xFF5A5A5E),
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
                  Text(dueDate,
                      style: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8443F).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(daysLeft,
                  style: const TextStyle(
                      color: Color(0xFFE8443F),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
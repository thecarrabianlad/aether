import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:aether/features/tasks/screens/daily_tasks_screen.dart'
    show DailyTasksScreen;

/// Opens the task 3-dot menu. Each action fires its callback immediately
/// (no intermediate confirmation for priority/category — delete asks first).
void showTaskOptionsSheet(
  BuildContext context, {
  required String currentPriority,
  required String currentCategory,
  required String taskTitle,
  required ValueChanged<String> onPriorityChanged,
  required ValueChanged<String> onCategoryChanged,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _TaskOptionsSheet(
      currentPriority: currentPriority,
      currentCategory: currentCategory,
      taskTitle: taskTitle,
      onPriorityChanged: onPriorityChanged,
      onCategoryChanged: onCategoryChanged,
      onDelete: onDelete,
    ),
  );
}

class _TaskOptionsSheet extends StatelessWidget {
  final String currentPriority;
  final String currentCategory;
  final String taskTitle;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onDelete;

  const _TaskOptionsSheet({
    required this.currentPriority,
    required this.currentCategory,
    required this.taskTitle,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: context.aether.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: context.aether.border),
          left: BorderSide(color: context.aether.border),
          right: BorderSide(color: context.aether.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.aether.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            taskTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.aether.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.flag_outlined,
            label: 'Edit Priority',
            onTap: () {
              Navigator.of(context).pop();
              _showPriorityPicker(context);
            },
          ),
          _OptionTile(
            icon: Icons.category_outlined,
            label: 'Edit Category',
            onTap: () {
              Navigator.of(context).pop();
              _showCategoryPicker(context);
            },
          ),
          _OptionTile(
            icon: Icons.delete_outline,
            label: 'Delete Task',
            color: DailyTasksScreen.red,
            onTap: () {
              Navigator.of(context).pop();
              _confirmDelete(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPriorityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Priority',
        options: const [
          ('High', DailyTasksScreen.red),
          ('Medium', DailyTasksScreen.orange),
          ('Low', DailyTasksScreen.grey),
        ],
        current: currentPriority,
        onSelected: onPriorityChanged,
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Category',
        options: const [
          ('Study', DailyTasksScreen.purple),
          ('Personal', DailyTasksScreen.green),
          ('Other', DailyTasksScreen.grey),
        ],
        current: currentCategory,
        onSelected: onCategoryChanged,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.aether.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.aether.border),
        ),
        title: Text(
          'Delete task?',
          style: TextStyle(color: context.aether.text),
        ),
        content: Text(
          '"$taskTitle" will be removed from this device and your account.',
          style: TextStyle(color: context.aether.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.aether.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: DailyTasksScreen.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.aether.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<(String, Color)> options;
  final String current;
  final ValueChanged<String> onSelected;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: context.aether.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: context.aether.border),
          left: BorderSide(color: context.aether.border),
          right: BorderSide(color: context.aether.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.aether.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: context.aether.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...options.map((o) {
            final (label, color) = o;
            final selected = label == current;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onSelected(label);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.15)
                        : context.aether.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? color : context.aether.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: selected ? color : context.aether.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Icon(Icons.check, size: 16, color: color),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
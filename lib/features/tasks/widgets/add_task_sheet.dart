import 'package:flutter/material.dart';
import 'package:aether/features/tasks/screens/daily_tasks_screen.dart'
    show DailyTasksScreen;

class NewTaskResult {
  final String title;
  final String priority;
  final String category;

  const NewTaskResult({
    required this.title,
    required this.priority,
    required this.category,
  });
}

/// Opens the "new task" bottom sheet and resolves with the entered data,
/// or null if the user dismissed it without confirming.
Future<NewTaskResult?> showAddTaskSheet(BuildContext context) {
  return showModalBottomSheet<NewTaskResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddTaskSheet(),
  );
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  String _priority = 'Medium';
  String _category = 'Study';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _confirm() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      NewTaskResult(title: title, priority: _priority, category: _category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: DailyTasksScreen.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: DailyTasksScreen.cardBorder),
            left: BorderSide(color: DailyTasksScreen.cardBorder),
            right: BorderSide(color: DailyTasksScreen.cardBorder),
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
                  color: DailyTasksScreen.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'New Task',
              style: TextStyle(
                color: DailyTasksScreen.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(
                color: DailyTasksScreen.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Task title',
                hintStyle: const TextStyle(color: DailyTasksScreen.grey),
                filled: true,
                fillColor: DailyTasksScreen.bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: DailyTasksScreen.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: DailyTasksScreen.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DailyTasksScreen.red),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Priority',
              style: TextStyle(color: DailyTasksScreen.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _OptionChip(
                  label: 'High',
                  color: DailyTasksScreen.red,
                  selected: _priority == 'High',
                  onTap: () => setState(() => _priority = 'High'),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'Medium',
                  color: DailyTasksScreen.orange,
                  selected: _priority == 'Medium',
                  onTap: () => setState(() => _priority = 'Medium'),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'Low',
                  color: DailyTasksScreen.grey,
                  selected: _priority == 'Low',
                  onTap: () => setState(() => _priority = 'Low'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Category',
              style: TextStyle(color: DailyTasksScreen.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _OptionChip(
                  label: 'Study',
                  color: DailyTasksScreen.purple,
                  selected: _category == 'Study',
                  onTap: () => setState(() => _category = 'Study'),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'Personal',
                  color: DailyTasksScreen.green,
                  selected: _category == 'Personal',
                  onTap: () => setState(() => _category = 'Personal'),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'Other',
                  color: DailyTasksScreen.grey,
                  selected: _category == 'Other',
                  onTap: () => setState(() => _category = 'Other'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DailyTasksScreen.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Add Task',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : DailyTasksScreen.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : DailyTasksScreen.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : DailyTasksScreen.grey,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
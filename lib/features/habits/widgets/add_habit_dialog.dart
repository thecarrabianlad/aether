import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

/// Result returned by the habit dialog.
class HabitDialogResult {
  final String name;
  final HabitCategory category;
  final IconData icon;
  final Color color;

  const HabitDialogResult({
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
  });
}

/// Shows a dialog to create a new habit.
/// Returns the result on submit, or null if cancelled.
Future<HabitDialogResult?> showAddHabitDialog(BuildContext context) {
  return _showHabitDialog(context);
}

/// Shows a dialog to edit an existing habit, pre-filled with current values.
/// Returns the updated result on submit, or null if cancelled.
Future<HabitDialogResult?> showEditHabitDialog(
    BuildContext context, {required String currentName, required HabitCategory currentCategory}) {
  return _showHabitDialog(
    context,
    initialName: currentName,
    initialCategory: currentCategory,
  );
}

Future<HabitDialogResult?> _showHabitDialog(
  BuildContext context, {
  String initialName = '',
  HabitCategory initialCategory = HabitCategory.study,
}) {
  return showDialog<HabitDialogResult>(
    context: context,
    builder: (ctx) => _HabitFormDialog(
      initialName: initialName,
      initialCategory: initialCategory,
    ),
  );
}

class _HabitFormDialog extends StatefulWidget {
  final String initialName;
  final HabitCategory initialCategory;

  const _HabitFormDialog({
    required this.initialName,
    required this.initialCategory,
  });

  @override
  State<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<_HabitFormDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  late HabitCategory _selectedCategory;

  bool get _isEditing => widget.initialName.isNotEmpty;

  static const _categoryIconMap = {
    HabitCategory.study: Icons.menu_book_outlined,
    HabitCategory.health: Icons.favorite_border,
    HabitCategory.mind: Icons.self_improvement,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(HabitDialogResult(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      icon: _categoryIconMap[_selectedCategory]!,
      color: _selectedCategory.color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEditing ? 'Edit Habit' : 'Add New Habit',
        style: const TextStyle(
          color: HabitRepository.whiteText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Habit name',
                hintStyle:
                    const TextStyle(color: Color(0xFF5A5A5E), fontSize: 15),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: HabitRepository.redAccent.withOpacity(0.5),
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a habit name' : null,
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category',
                style: TextStyle(
                  color: HabitRepository.greyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: HabitCategory.values.map((cat) {
                final selected = _selectedCategory == cat;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? cat.color.withOpacity(0.15)
                              : const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? cat.color.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _categoryIconMap[cat]!,
                              color:
                                  selected ? cat.color : HabitRepository.greyText,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat.label,
                              style: TextStyle(
                                color: selected
                                    ? cat.color
                                    : HabitRepository.greyText,
                                fontSize: 12,
                                fontWeight:
                                    selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text(
            'Cancel',
            style: TextStyle(color: HabitRepository.greyText),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            _isEditing ? 'Save' : 'Add Habit',
            style: const TextStyle(color: HabitRepository.redAccent),
          ),
        ),
      ],
    );
  }
}

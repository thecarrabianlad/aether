import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';

/// Result returned by the habit dialog.
class HabitDialogResult {
  final String name;
  final HabitCategory category;
  final IconData icon;
  final Color color;
  final String? reminderTime; // 'HH:mm', null = no reminder
  final String? reminderDays; // '1,3,5' ISO weekdays (1=Mon..7=Sun)

  const HabitDialogResult({
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    this.reminderTime,
    this.reminderDays,
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
  BuildContext context, {
  required String currentName,
  required HabitCategory currentCategory,
  String? currentReminderTime,
  String? currentReminderDays,
}) {
  return _showHabitDialog(
    context,
    initialName: currentName,
    initialCategory: currentCategory,
    initialReminderTime: currentReminderTime,
    initialReminderDays: currentReminderDays,
  );
}

Future<HabitDialogResult?> _showHabitDialog(
  BuildContext context, {
  String initialName = '',
  HabitCategory initialCategory = HabitCategory.study,
  String? initialReminderTime,
  String? initialReminderDays,
}) {
  return showDialog<HabitDialogResult>(
    context: context,
    builder: (ctx) => _HabitFormDialog(
      initialName: initialName,
      initialCategory: initialCategory,
      initialReminderTime: initialReminderTime,
      initialReminderDays: initialReminderDays,
    ),
  );
}

class _HabitFormDialog extends StatefulWidget {
  final String initialName;
  final HabitCategory initialCategory;
  final String? initialReminderTime;
  final String? initialReminderDays;

  const _HabitFormDialog({
    required this.initialName,
    required this.initialCategory,
    this.initialReminderTime,
    this.initialReminderDays,
  });

  @override
  State<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<_HabitFormDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  late HabitCategory _selectedCategory;
  TimeOfDay? _reminderTime;
  List<int> _reminderDays = []; // ISO weekdays 1=Mon..7=Sun

  bool get _isEditing => widget.initialName.isNotEmpty;
  bool _permissionRequested = false;

  static const _categoryIconMap = {
    HabitCategory.study: Icons.menu_book_outlined,
    HabitCategory.health: Icons.favorite_border,
    HabitCategory.mind: Icons.self_improvement,
  };

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedCategory = widget.initialCategory;

    if (widget.initialReminderTime != null &&
        widget.initialReminderTime!.isNotEmpty) {
      final parts = widget.initialReminderTime!.split(':');
      if (parts.length == 2) {
        _reminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    if (widget.initialReminderDays != null &&
        widget.initialReminderDays!.isNotEmpty) {
      _reminderDays = widget.initialReminderDays!
          .split(',')
          .map((s) => int.parse(s.trim()))
          .toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    // Request notification permission the first time a reminder is set.
    if (!_permissionRequested &&
        _reminderTime != null &&
        _reminderDays.isNotEmpty) {
      _permissionRequested = true;
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Notification permission needed for reminders.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.aether.surface,
          ),
        );
        // Still save — schedules just won't fire until permission is granted.
      }
    }

    String? reminderTime;
    if (_reminderTime != null) {
      reminderTime =
          '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}';
    }

    // Only persist reminderDays if a time is also set.
    final effectiveDays =
        (_reminderTime != null && _reminderDays.isNotEmpty)
            ? _reminderDays.join(',')
            : null;
    // Clear time without days.
    final effectiveTime =
        (_reminderTime != null && _reminderDays.isNotEmpty) ? reminderTime : null;

    if (!mounted) return;
    Navigator.of(context).pop(HabitDialogResult(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      icon: _categoryIconMap[_selectedCategory]!,
      color: _selectedCategory.color,
      reminderTime: effectiveTime,
      reminderDays: effectiveDays,
    ));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.aether.accent,
              onSurface: context.aether.text,
              surface: context.aether.surfaceAlt,
              onPrimary: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: context.aether.accent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _toggleDay(int weekdayIso) {
    setState(() {
      if (_reminderDays.contains(weekdayIso)) {
        _reminderDays.remove(weekdayIso);
      } else {
        _reminderDays.add(weekdayIso);
        _reminderDays.sort();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.aether.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEditing ? 'Edit Habit' : 'Add New Habit',
        style: TextStyle(
          color: context.aether.text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Name ──────────────────────────────
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Habit name',
                hintStyle:
                    TextStyle(color: context.aether.textMuted, fontSize: 15),
                filled: true,
                fillColor: context.aether.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.aether.accent.withValues(alpha: 0.5),
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a habit name' : null,
            ),
            const SizedBox(height: 20),

            // ── Category ──────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category',
                style: TextStyle(
                  color: context.aether.textMuted,
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
                              : context.aether.surfaceAlt,
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
                                  selected ? cat.color : context.aether.textMuted,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat.label,
                              style: TextStyle(
                                color: selected
                                    ? cat.color
                                    : context.aether.textMuted,
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
            const SizedBox(height: 20),

            // ── Reminder ──────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reminder',
                style: TextStyle(
                  color: context.aether.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Time picker row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: Icon(
                      _reminderTime != null
                          ? Icons.access_time_filled
                          : Icons.access_time,
                      size: 18,
                    ),
                    label: Text(
                      _reminderTime != null
                          ? _reminderTime!.format(context)
                          : 'Set time',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _reminderTime != null
                          ? context.aether.accent
                          : context.aether.textMuted,
                      side: BorderSide(
                        color: _reminderTime != null
                            ? context.aether.accent.withValues(alpha: 0.5)
                            : context.aether.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                  ),
                ),
                if (_reminderTime != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.clear, color: context.aether.textMuted, size: 18),
                    onPressed: () => setState(() => _reminderTime = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Weekday selector chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final weekday = i + 1; // 1=Mon..7=Sun
                final selected = _reminderDays.contains(weekday);
                return GestureDetector(
                  onTap: () => _toggleDay(weekday),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? context.aether.accent.withValues(alpha: 0.2)
                          : context.aether.surfaceAlt,
                      border: Border.all(
                        color: selected
                            ? context.aether.accent
                            : context.aether.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _weekdayLabels[i],
                      style: TextStyle(
                        color: selected
                            ? context.aether.accent
                            : context.aether.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.aether.textMuted),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            _isEditing ? 'Save' : 'Add Habit',
            style: TextStyle(color: context.aether.accent),
          ),
        ),
      ],
    );
  }
}
import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/database/database.dart' show Task;
import 'package:aether/features/tasks/providers/task_providers.dart';
import 'package:aether/features/tasks/widgets/add_task_sheet.dart';
import 'package:aether/features/tasks/widgets/task_options_sheet.dart';

/// ---------------------------------------------------------------------
/// AETHER — Daily Tasks screen
/// ---------------------------------------------------------------------
/// Offline-first: UI reads from Drift via [tasksForDateProvider]. Writes go
/// to Drift first (instant UI update) then sync to Supabase in the
/// background, same pattern as the Academics feature. Body content only —
/// bottom nav bar is handled by the parent Scaffold/router shell.
/// ---------------------------------------------------------------------

enum TaskFilter { all, study, personal, other }

class DailyTasksScreen extends ConsumerStatefulWidget {
  const DailyTasksScreen({super.key});

  // Palette (kept consistent with DashboardScreen)
  // Fixed semantic colors — categories/priorities keep their meaning.
  static const red = Color(0xFFFF3B30);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFE08A2E);
  static const blue = Color(0xFF3B82F6);
  static const grey = Color(0xFF9A9A9E);

  @override
  ConsumerState<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends ConsumerState<DailyTasksScreen> {
  int _dayOffset = 0;
  TaskFilter _activeFilter = TaskFilter.all;
  final TextEditingController _newTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCurrentDate());
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    super.dispose();
  }

  void _syncCurrentDate() {
    ref.read(taskServiceProvider).syncTasksForDate(_dateKey);
  }

  // ---------------------------------------------------------------------
  // Derived
  // ---------------------------------------------------------------------

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday', //
  ];

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December', //
  ];

  DateTime get _selectedDate => DateTime.now().add(Duration(days: _dayOffset));

  /// 'YYYY-MM-DD' — matches the `date` column in the tasks table.
  String get _dateKey {
    final d = _selectedDate;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String _ordinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String get _fullDateLabel {
    final day = _selectedDate.day;
    final month = _monthNames[_selectedDate.month - 1];
    final year = _selectedDate.year;
    return '$day${_ordinalSuffix(day)} $month $year';
  }

  String get _dateNavigatorLabel {
    if (_dayOffset == 0) return 'Today';
    if (_dayOffset == -1) return 'Yesterday';
    if (_dayOffset == 1) return 'Tomorrow';
    return _weekdayNames[_selectedDate.weekday - 1];
  }

  List<Task> _filtered(List<Task> tasks) {
    switch (_activeFilter) {
      case TaskFilter.all:
        return tasks;
      case TaskFilter.study:
        return tasks.where((t) => t.category == 'Study').toList();
      case TaskFilter.personal:
        return tasks.where((t) => t.category == 'Personal').toList();
      case TaskFilter.other:
        return tasks.where((t) => t.category == 'Other').toList();
    }
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  void _goToPreviousDay() {
    setState(() => _dayOffset -= 1);
    _syncCurrentDate();
  }

  void _goToNextDay() {
    setState(() => _dayOffset += 1);
    _syncCurrentDate();
  }

  void _cycleStatus(Task task) {
    final next = switch (task.status) {
      'Pending' => 'InProgress',
      'InProgress' => 'Completed',
      _ => 'Pending',
    };
    ref.read(taskServiceProvider).updateTaskStatus(task.id, next);
  }

  Future<void> _openAddTaskSheet() async {
    final result = await showAddTaskSheet(context);
    if (result == null) return;
    await ref.read(taskServiceProvider).createTask(
          dateKey: _dateKey,
          title: result.title,
          priority: result.priority,
          category: result.category,
        );
  }

  void _openTaskOptions(Task task) {
    final service = ref.read(taskServiceProvider);
    showTaskOptionsSheet(
      context,
      currentPriority: task.priority,
      currentCategory: task.category,
      taskTitle: task.title,
      onPriorityChanged: (p) => service.updateTaskPriority(task.id, p),
      onCategoryChanged: (c) => service.updateTaskCategory(task.id, c),
      onDelete: () => service.deleteTask(task.id),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksForDateProvider(_dateKey));

    return Container(
      color: context.aether.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: tasksAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: context.aether.accent,
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Could not load tasks',
                    style: TextStyle(color: context.aether.textMuted),
                  ),
                ),
                data: (tasks) {
                  final filtered = _filtered(tasks);
                  final completed =
                      tasks.where((t) => t.status == 'Completed').length;
                  final inProgress =
                      tasks.where((t) => t.status == 'InProgress').length;
                  final pending =
                      tasks.where((t) => t.status == 'Pending').length;
                  final totalMinutes = tasks.fold<int>(
                    0,
                    (sum, t) => sum + (t.durationMinutes ?? 0),
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateNavigator(
                          label: _dateNavigatorLabel,
                          fullDateLabel: _fullDateLabel,
                          onPrevious: _goToPreviousDay,
                          onNext: _goToNextDay,
                        ),
                        const SizedBox(height: 16),
                        _StatsRow(
                          completed: completed,
                          inProgress: inProgress,
                          pending: pending,
                          totalFocus: _formatMinutes(totalMinutes),
                        ),
                        const SizedBox(height: 16),
                        _FilterRow(
                          active: _activeFilter,
                          onSelected: (f) =>
                              setState(() => _activeFilter = f),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Tasks',
                          style: TextStyle(
                            color: context.aether.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No tasks for this day yet',
                                style: TextStyle(
                                  color: context.aether.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          ...filtered.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TaskRow(
                                task: t,
                                onToggle: () => _cycleStatus(t),
                                onMenuTap: () => _openTaskOptions(t),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        _AddTaskField(
                          controller: _newTaskController,
                          onTap: _openAddTaskSheet,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

// ---------------------------------------------------------------------
// Category / priority display helpers
// ---------------------------------------------------------------------
Color _categoryColor(String category) {
  // Fixed semantic colors — category identity must not change with theme.
  switch (category) {
    case 'Study':
      return DailyTasksScreen.purple;
    case 'Personal':
      return DailyTasksScreen.green;
    default:
      return DailyTasksScreen.grey;
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Study':
      return Icons.menu_book_outlined;
    case 'Personal':
      return Icons.person_outline;
    default:
      return Icons.description_outlined;
  }
}

Color _priorityColor(String priority) {
  // Fixed semantic colors — priority meaning must not change with theme.
  switch (priority) {
    case 'High':
      return DailyTasksScreen.red;
    case 'Medium':
      return DailyTasksScreen.orange;
    default:
      return DailyTasksScreen.grey;
  }
}

// ---------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.menu, color: context.aether.text),
          ),
          Text(
            'DAILY TASKS',
            style: TextStyle(
              color: context.aether.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert,
              color: context.aether.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Date navigator
// ---------------------------------------------------------------------
class _DateNavigator extends StatelessWidget {
  final String label;
  final String fullDateLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DateNavigator({
    required this.label,
    required this.fullDateLabel,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavArrow(icon: Icons.chevron_left, onTap: onPrevious),
        Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.aether.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fullDateLabel,
              style: TextStyle(
                color: context.aether.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        _NavArrow(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.aether.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.aether.border),
        ),
        child: Icon(icon, color: context.aether.text, size: 18),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------
class _StatsRow extends StatelessWidget {
  final int completed;
  final int inProgress;
  final int pending;
  final String totalFocus;

  const _StatsRow({
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.totalFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle,
            iconColor: context.aether.accent,
            value: '$completed',
            label: 'Completed',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.autorenew,
            iconColor: DailyTasksScreen.orange,
            value: '$inProgress',
            label: 'In Progress',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.radio_button_unchecked,
            iconColor: DailyTasksScreen.blue,
            value: '$pending',
            label: 'Pending',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.access_time,
            iconColor: DailyTasksScreen.purple,
            value: totalFocus,
            label: 'Total Focus',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: context.aether.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.aether.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: context.aether.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: context.aether.textMuted,
              fontSize: 9.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Filter row
// ---------------------------------------------------------------------
class _FilterRow extends StatelessWidget {
  final TaskFilter active;
  final ValueChanged<TaskFilter> onSelected;

  const _FilterRow({required this.active, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  color: DailyTasksScreen.red,
                  selected: active == TaskFilter.all,
                  onTap: () => onSelected(TaskFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Study',
                  color: DailyTasksScreen.purple,
                  selected: active == TaskFilter.study,
                  onTap: () => onSelected(TaskFilter.study),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Personal',
                  color: DailyTasksScreen.green,
                  selected: active == TaskFilter.personal,
                  onTap: () => onSelected(TaskFilter.personal),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Other',
                  color: context.aether.textMuted,
                  selected: active == TaskFilter.other,
                  onTap: () => onSelected(TaskFilter.other),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.aether.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.aether.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 14, color: context.aether.textMuted),
              SizedBox(width: 4),
              Text(
                'Priority',
                style: TextStyle(color: context.aether.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : context.aether.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : context.aether.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : context.aether.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Task row
// ---------------------------------------------------------------------
class _TaskRow extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onMenuTap;

  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    final categoryColor = _categoryColor(task.category);
    final completed = task.status == 'Completed';
    final durationLabel = task.durationMinutes == null
        ? '—'
        : '${task.durationMinutes}m';

    return Container(
      decoration: BoxDecoration(
        color: context.aether.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.aether.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 60,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onToggle,
                    child: _StatusIndicator(status: task.status),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            color: completed
                                ? context.aether.textMuted
                                : context.aether.text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              task.category,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '  •  ',
                              style: TextStyle(
                                color: context.aether.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              durationLabel,
                              style: TextStyle(
                                color: context.aether.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(Icons.flag, size: 12, color: priorityColor),
                      const SizedBox(width: 3),
                      Text(
                        task.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _categoryIcon(task.category),
                    size: 16,
                    color: context.aether.textMuted,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onMenuTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: context.aether.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'Completed':
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: DailyTasksScreen.red,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        );
      case 'InProgress':
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DailyTasksScreen.orange, width: 2),
          ),
        );
      default:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.aether.textMuted, width: 1.4),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------
// Add task field — tapping opens the New Task sheet
// ---------------------------------------------------------------------
class _AddTaskField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const _AddTaskField({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: context.aether.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.aether.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: DailyTasksScreen.red,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: IgnorePointer(
                child: TextField(
                  controller: controller,
                  enabled: false,
                  style: TextStyle(
                    color: context.aether.text,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a new task',
                    hintStyle: TextStyle(
                      color: context.aether.textMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            Icon(Icons.mic_none, color: context.aether.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
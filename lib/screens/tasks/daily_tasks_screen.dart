import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// AETHER — Daily Tasks screen
/// ---------------------------------------------------------------------
/// Body content only — top app bar row is included here since this is a
/// pushed detail screen, bottom nav bar is assumed handled by the parent
/// Scaffold/router shell (MainScaffold).
/// ---------------------------------------------------------------------

enum TaskPriority { high, medium, low }

enum TaskStatus { completed, inProgress, pending }

enum TaskFilter { all, study, personal, other }

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  // Palette (kept consistent with DashboardScreen)
  static const bg = Color(0xFF000000);
  static const card = Color(0xFF121212);
  static const cardBorder = Color(0xFF262626);
  static const red = Color(0xFFFF3B30);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFE08A2E);
  static const blue = Color(0xFF3B82F6);
  static const grey = Color(0xFF9A9A9E);
  static const white = Color(0xFFF5F5F5);

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  int _dayOffset = 0;
  TaskFilter _activeFilter = TaskFilter.all;
  final TextEditingController _newTaskController = TextEditingController();

  List<_TaskItemData> _tasks = const [
    _TaskItemData(
      title: 'Physics Class Notes',
      category: 'Study',
      categoryColor: DailyTasksScreen.purple,
      duration: '1h 30m',
      priority: TaskPriority.high,
      status: TaskStatus.completed,
      icon: Icons.menu_book_outlined,
    ),
    _TaskItemData(
      title: 'Maths Problem Practice',
      category: 'Study',
      categoryColor: DailyTasksScreen.purple,
      duration: '2h 00m',
      priority: TaskPriority.medium,
      status: TaskStatus.inProgress,
      icon: Icons.calculate_outlined,
    ),
    _TaskItemData(
      title: 'Chemistry Revision',
      category: 'Study',
      categoryColor: DailyTasksScreen.purple,
      duration: '1h 30m',
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      icon: Icons.science_outlined,
    ),
    _TaskItemData(
      title: 'Read 20 Pages',
      category: 'Personal',
      categoryColor: DailyTasksScreen.green,
      duration: '40m',
      priority: TaskPriority.low,
      status: TaskStatus.pending,
      icon: Icons.person_outline,
    ),
    _TaskItemData(
      title: 'Workout',
      category: 'Health',
      categoryColor: DailyTasksScreen.red,
      duration: '1h 00m',
      priority: TaskPriority.medium,
      status: TaskStatus.pending,
      icon: Icons.favorite_border,
    ),
    _TaskItemData(
      title: 'Meditation',
      category: 'Habits',
      categoryColor: DailyTasksScreen.purple,
      duration: '20m',
      priority: TaskPriority.low,
      status: TaskStatus.pending,
      icon: Icons.self_improvement,
    ),
    _TaskItemData(
      title: 'Plan Tomorrow',
      category: 'Other',
      categoryColor: DailyTasksScreen.grey,
      duration: '30m',
      priority: TaskPriority.low,
      status: TaskStatus.pending,
      icon: Icons.description_outlined,
    ),
  ];

  @override
  void dispose() {
    _newTaskController.dispose();
    super.dispose();
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

  int get _completedCount =>
      _tasks.where((t) => t.status == TaskStatus.completed).length;
  int get _inProgressCount =>
      _tasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get _pendingCount =>
      _tasks.where((t) => t.status == TaskStatus.pending).length;

  List<_TaskItemData> get _filteredTasks {
    switch (_activeFilter) {
      case TaskFilter.all:
        return _tasks;
      case TaskFilter.study:
        return _tasks.where((t) => t.category == 'Study').toList();
      case TaskFilter.personal:
        return _tasks.where((t) => t.category == 'Personal').toList();
      case TaskFilter.other:
        return _tasks
            .where((t) => t.category != 'Study' && t.category != 'Personal')
            .toList();
    }
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  void _goToPreviousDay() => setState(() => _dayOffset -= 1);
  void _goToNextDay() => setState(() => _dayOffset += 1);

  void _cycleStatus(_TaskItemData task) {
    final index = _tasks.indexOf(task);
    if (index == -1) return;
    setState(() {
      final next = switch (task.status) {
        TaskStatus.pending => TaskStatus.inProgress,
        TaskStatus.inProgress => TaskStatus.completed,
        TaskStatus.completed => TaskStatus.pending,
      };
      _tasks = List.of(_tasks)..[index] = task.copyWith(status: next);
    });
  }

  void _addTask() {
    final text = _newTaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks = [
        ..._tasks,
        _TaskItemData(
          title: text,
          category: 'Other',
          categoryColor: DailyTasksScreen.grey,
          duration: '—',
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          icon: Icons.description_outlined,
        ),
      ];
      _newTaskController.clear();
    });
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DailyTasksScreen.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: SingleChildScrollView(
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
                      completed: _completedCount,
                      inProgress: _inProgressCount,
                      pending: _pendingCount,
                      totalFocus: '15h 30m',
                    ),
                    const SizedBox(height: 16),
                    _FilterRow(
                      active: _activeFilter,
                      onSelected: (f) => setState(() => _activeFilter = f),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tasks',
                      style: TextStyle(
                        color: DailyTasksScreen.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._filteredTasks.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TaskRow(
                          task: t,
                          onToggle: () => _cycleStatus(t),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AddTaskField(
                      controller: _newTaskController,
                      onSubmit: _addTask,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Task data model
// ---------------------------------------------------------------------
class _TaskItemData {
  final String title;
  final String category;
  final Color categoryColor;
  final String duration;
  final TaskPriority priority;
  final TaskStatus status;
  final IconData icon;

  const _TaskItemData({
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.duration,
    required this.priority,
    required this.status,
    required this.icon,
  });

  _TaskItemData copyWith({TaskStatus? status}) => _TaskItemData(
    title: title,
    category: category,
    categoryColor: categoryColor,
    duration: duration,
    priority: priority,
    status: status ?? this.status,
    icon: icon,
  );
}

Color _priorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return DailyTasksScreen.red;
    case TaskPriority.medium:
      return DailyTasksScreen.orange;
    case TaskPriority.low:
      return DailyTasksScreen.grey;
  }
}

String _priorityLabel(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return 'High';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.low:
      return 'Low';
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
            icon: const Icon(Icons.menu, color: DailyTasksScreen.white),
          ),
          const Text(
            'DAILY TASKS',
            style: TextStyle(
              color: DailyTasksScreen.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
              color: DailyTasksScreen.white,
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
              style: const TextStyle(
                color: DailyTasksScreen.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fullDateLabel,
              style: const TextStyle(
                color: DailyTasksScreen.grey,
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
          color: DailyTasksScreen.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DailyTasksScreen.cardBorder),
        ),
        child: Icon(icon, color: DailyTasksScreen.white, size: 18),
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
            iconColor: DailyTasksScreen.red,
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
        color: DailyTasksScreen.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DailyTasksScreen.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: DailyTasksScreen.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: DailyTasksScreen.grey,
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
                  color: DailyTasksScreen.grey,
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
            color: DailyTasksScreen.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DailyTasksScreen.cardBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 14, color: DailyTasksScreen.grey),
              SizedBox(width: 4),
              Text(
                'Priority',
                style: TextStyle(color: DailyTasksScreen.grey, fontSize: 12),
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
          color: selected ? color.withOpacity(0.15) : DailyTasksScreen.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : DailyTasksScreen.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : DailyTasksScreen.grey,
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
  final _TaskItemData task;
  final VoidCallback onToggle;

  const _TaskRow({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    final completed = task.status == TaskStatus.completed;

    return Container(
      decoration: BoxDecoration(
        color: DailyTasksScreen.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DailyTasksScreen.cardBorder),
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
                                ? DailyTasksScreen.grey
                                : DailyTasksScreen.white,
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
                                color: task.categoryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              '  •  ',
                              style: TextStyle(
                                color: DailyTasksScreen.grey,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              task.duration,
                              style: const TextStyle(
                                color: DailyTasksScreen.grey,
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
                        _priorityLabel(task.priority),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Icon(task.icon, size: 16, color: DailyTasksScreen.grey),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.more_vert,
                    size: 16,
                    color: DailyTasksScreen.grey,
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
  final TaskStatus status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TaskStatus.completed:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: DailyTasksScreen.red,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        );
      case TaskStatus.inProgress:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DailyTasksScreen.orange, width: 2),
          ),
        );
      case TaskStatus.pending:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DailyTasksScreen.grey, width: 1.4),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------
// Add task field
// ---------------------------------------------------------------------
class _AddTaskField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _AddTaskField({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: DailyTasksScreen.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DailyTasksScreen.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onSubmit,
            child: const Icon(
              Icons.add_circle_outline,
              color: DailyTasksScreen.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSubmit(),
              style: const TextStyle(
                color: DailyTasksScreen.white,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'Add a new task',
                hintStyle: TextStyle(
                  color: DailyTasksScreen.grey,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Icon(Icons.mic_none, color: DailyTasksScreen.red, size: 20),
        ],
      ),
    );
  }
}
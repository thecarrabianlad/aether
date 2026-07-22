import 'package:flutter/material.dart';
import 'package:aether/screens/schedule/schedule_screen.dart';
import 'package:aether/screens/tasks/daily_tasks_screen.dart';
/// ---------------------------------------------------------------------
/// AETHER — Dashboard content
/// ---------------------------------------------------------------------
/// This file ONLY contains the body content of the dashboard screen.
/// The top app bar (logo / menu / profile) and the bottom navigation
/// bar are assumed to already exist elsewhere in the app — this widget
/// is meant to be dropped straight into the `body:` of that Scaffold.
/// ---------------------------------------------------------------------
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  // Palette
  static const bg = Color(0xFF000000);
  static const card = Color(0xFF121212);
  static const cardBorder = Color(0xFF262626);
  static const red = Color(0xFFFF3B30);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF34C759);
  static const grey = Color(0xFF9A9A9E);
  static const white = Color(0xFFF5F5F5);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  // ---------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------

  // Reference date lines up with the original "Tuesday, 12th August 2025"
  // mock. `_dayOffset` tracks how many days the user has navigated away
  // from it via the date navigator.
  // static final DateTime _referenceDate = DateTime(2025, 8, 12);

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {});
    });
  }

  // DateTime _referenceDate = DateTime.now();
  int _dayOffset = 0;

  // final TimeOfDay _currentTime = const TimeOfDay(hour: 7, minute: 42);
  final double _progressPercent = 0.625;

  final int _tasksPending = 6;
  final int _classesToday = 3;
  final int _habitsCompleted = 4;
  final int _habitsTotal = 7;
  final int _healthScore = 72;

  final List<_ScheduleItemData> _scheduleItems = const [
    _ScheduleItemData(
      time: '9:00 AM',
      title: 'Physics Class',
      subtitle: 'Electromagnetism',
      icon: Icons.menu_book_outlined,
      color: DashboardScreen.purple,
    ),
    _ScheduleItemData(
      time: '11:30 AM',
      title: 'Maths Practice',
      subtitle: 'Calculus & Integrals',
      icon: Icons.calculate_outlined,
      color: Color(0xFFE08A2E),
    ),
    _ScheduleItemData(
      time: '3:00 PM',
      title: 'Chemistry Revision',
      subtitle: 'Organic Chemistry',
      icon: Icons.science_outlined,
      color: Color(0xFF3B82F6),
    ),
  ];

  List<_TaskItemData> _tasks = const [
    _TaskItemData(
      title: 'Finish Physics Notes',
      subtitle: 'Electromagnetism',
      flagged: true,
    ),
    _TaskItemData(
      title: 'Practice PYQs',
      subtitle: 'JEE Main 2024',
      flagged: true,
    ),
    _TaskItemData(title: 'Workout', subtitle: 'Completed', completed: true),
  ];

  final List<_HabitItemData> _habits = const [
    _HabitItemData(
      icon: Icons.menu_book_outlined,
      title: 'Study',
      fraction: '5/7',
      progress: 5 / 7,
    ),
    _HabitItemData(
      icon: Icons.self_improvement,
      title: 'Meditation',
      fraction: '4/7',
      progress: 4 / 7,
    ),
    _HabitItemData(
      icon: Icons.water_drop_outlined,
      title: 'No Sugar',
      fraction: '5/7',
      progress: 5 / 7,
    ),
    _HabitItemData(
      icon: Icons.nightlight_outlined,
      title: 'Sleep Early',
      fraction: '3/7',
      progress: 3 / 7,
    ),
  ];

  final _UpcomingEventData _upcomingEvent = const _UpcomingEventData(
    day: '18',
    month: 'AUG',
    title: 'Maths Test',
    subtitle: 'Calculus • 5 Chapters',
    daysLeftLabel: '6 Days Left',
  );

  // ---------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------

  DateTime get _selectedDate => DateTime.now().add(Duration(days: _dayOffset));

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get _timeText {
    final now = DateTime.now();

    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;

    return '$hour:${now.minute.toString().padLeft(2, '0')}';
  }

  String get _periodText {
    final now = DateTime.now();

    return now.hour >= 12 ? 'PM' : 'AM';
  }

  String get _weekdayLabel => _weekdayNames[_selectedDate.weekday - 1];

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
    return _fullDateLabel;
  }

  String get _habitsCompletedFraction => '$_habitsCompleted/$_habitsTotal';

  String get _healthScoreLabel => '$_healthScore%';

  List<_GlanceItemData> get _glanceItems => [
    _GlanceItemData(
      icon: Icons.assignment_outlined,
      iconColor: DashboardScreen.red,
      value: '$_tasksPending',
      label: 'Tasks pending',
    ),
    _GlanceItemData(
      icon: Icons.menu_book_outlined,
      iconColor: DashboardScreen.purple,
      value: '$_classesToday',
      label: 'Classes today',
    ),
    _GlanceItemData(
      icon: Icons.check_circle_outline,
      iconColor: DashboardScreen.green,
      value: _habitsCompletedFraction,
      label: 'Habits completed',
    ),
    _GlanceItemData(
      icon: Icons.favorite_border,
      iconColor: DashboardScreen.red,
      value: _healthScoreLabel,
      label: 'Health score',
    ),
  ];

  // ---------------------------------------------------------------------
  // Helper methods
  // ---------------------------------------------------------------------

  void _goToPreviousDay() {
    setState(() {
      _dayOffset -= 1;
    });
  }

  void _goToNextDay() {
    setState(() {
      _dayOffset += 1;
    });
  }

  void _toggleTask(int index) {
    setState(() {
      final t = _tasks[index];
      _tasks = List.of(_tasks)
        ..[index] = _TaskItemData(
          title: t.title,
          subtitle: t.subtitle,
          completed: !t.completed,
          flagged: t.flagged,
        );
    });
  }

  void _onViewAllSchedule() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const ScheduleScreen(),
    ),
  );
}

  void _onViewAllTasks() {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const DailyTasksScreen()),
  );
}

  void _onViewAllHabits() {
    // TODO: navigate to full habits view
    print('View all habits tapped');
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardScreen.bg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(
                timeText: _timeText,
                periodText: _periodText,
                weekdayLabel: _weekdayLabel,
                fullDateLabel: _fullDateLabel,
                progressPercent: _progressPercent,
              ),
              const SizedBox(height: 16),
              _DateNavigator(
                label: _dateNavigatorLabel,
                onPrevious: _goToPreviousDay,
                onNext: _goToNextDay,
              ),
              const SizedBox(height: 20),
              _GlanceRow(items: _glanceItems),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Today\'s Schedule',
                onViewAll: _onViewAllSchedule,
              ),
              const SizedBox(height: 12),
              _ScheduleCard(items: _scheduleItems),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TasksCard(
                      tasks: _tasks,
                      onViewAll: _onViewAllTasks,
                      onToggleTask: _toggleTask,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HabitTrackerCard(
                      habits: _habits,
                      onViewAll: _onViewAllHabits,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Upcoming', onViewAll: () {}),
              const SizedBox(height: 12),
              _UpcomingCard(event: _upcomingEvent),
            ],
          ),
        ),
      ),
    );
  }

  @override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
}

// ---------------------------------------------------------------------
// Header: time / date + progress ring
// ---------------------------------------------------------------------
class _HeaderRow extends StatelessWidget {
  final String timeText;
  final String periodText;
  final String weekdayLabel;
  final String fullDateLabel;
  final double progressPercent;

  const _HeaderRow({
    required this.timeText,
    required this.periodText,
    required this.weekdayLabel,
    required this.fullDateLabel,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: DashboardScreen.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    periodText,
                    style: const TextStyle(
                      color: DashboardScreen.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                weekdayLabel,
                style: const TextStyle(
                  color: DashboardScreen.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fullDateLabel,
                style: const TextStyle(
                  color: DashboardScreen.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _ProgressRing(percent: progressPercent),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double percent; // 0..1
  const _ProgressRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 128,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DashboardScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardScreen.cardBorder),
      ),
      child: Center(
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DashboardScreen.red.withValues(alpha: 0.55),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFF3A3A3C),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    DashboardScreen.red,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(color: DashboardScreen.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(percent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: DashboardScreen.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Date navigator: "< Today >"
// ---------------------------------------------------------------------
class _DateNavigator extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DateNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardScreen.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardScreen.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onPrevious,
            child: const Icon(
              Icons.chevron_left,
              color: DashboardScreen.grey,
              size: 22,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: DashboardScreen.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: onNext,
            child: const Icon(
              Icons.chevron_right,
              color: DashboardScreen.grey,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// "Today at a glance" — 4 stat cards
// ---------------------------------------------------------------------
class _GlanceItemData {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _GlanceItemData({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
}

class _GlanceRow extends StatelessWidget {
  final List<_GlanceItemData> items;

  const _GlanceRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today at a glance',
          style: TextStyle(
            color: DashboardScreen.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _GlanceCard(
                  icon: items[i].icon,
                  iconColor: items[i].iconColor,
                  value: items[i].value,
                  label: items[i].label,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _GlanceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _GlanceCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: DashboardScreen.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: DashboardScreen.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: DashboardScreen.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Shared "section header" row (title + View All)
// ---------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: DashboardScreen.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Row(
            children: [
              Text(
                'View All',
                style: TextStyle(color: DashboardScreen.grey, fontSize: 12),
              ),
              Icon(Icons.chevron_right, color: DashboardScreen.grey, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Today's Schedule — timeline list
// ---------------------------------------------------------------------
class _ScheduleItemData {
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ScheduleItemData({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _ScheduleCard extends StatelessWidget {
  final List<_ScheduleItemData> items;

  const _ScheduleCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardScreen.cardBorder),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return _ScheduleRow(item: item, showLine: !isLast);
        }),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final _ScheduleItemData item;
  final bool showLine;

  const _ScheduleRow({required this.item, required this.showLine});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.time,
                style: const TextStyle(
                  color: DashboardScreen.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardScreen.grey,
                ),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: DashboardScreen.cardBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 20 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: DashboardScreen.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: DashboardScreen.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Tasks card
// ---------------------------------------------------------------------
class _TaskItemData {
  final String title;
  final String subtitle;
  final bool completed;
  final bool flagged;

  const _TaskItemData({
    required this.title,
    required this.subtitle,
    this.completed = false,
    this.flagged = false,
  });
}

class _TasksCard extends StatelessWidget {
  final List<_TaskItemData> tasks;
  final VoidCallback onViewAll;
  final ValueChanged<int> onToggleTask;

  const _TasksCard({
    required this.tasks,
    required this.onViewAll,
    required this.onToggleTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardScreen.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tasks',
                style: TextStyle(
                  color: DashboardScreen.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: DashboardScreen.grey,
                        fontSize: 11,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: DashboardScreen.grey,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(tasks.length, (i) {
            final t = tasks[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: GestureDetector(
                onTap: () => onToggleTask(i),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t.completed
                        ? const CircleAvatar(
                            radius: 9,
                            backgroundColor: DashboardScreen.red,
                            child: Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          )
                        : Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DashboardScreen.grey,
                                width: 1.4,
                              ),
                            ),
                          ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: TextStyle(
                              color: t.completed
                                  ? DashboardScreen.grey
                                  : DashboardScreen.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: t.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            t.subtitle,
                            style: const TextStyle(
                              color: DashboardScreen.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (t.flagged)
                      const Icon(
                        Icons.flag,
                        size: 14,
                        color: DashboardScreen.red,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Habit Tracker card
// ---------------------------------------------------------------------
class _HabitItemData {
  final IconData icon;
  final String title;
  final String fraction;
  final double progress; // 0..1

  const _HabitItemData({
    required this.icon,
    required this.title,
    required this.fraction,
    required this.progress,
  });
}

class _HabitTrackerCard extends StatelessWidget {
  final List<_HabitItemData> habits;
  final VoidCallback onViewAll;

  const _HabitTrackerCard({required this.habits, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardScreen.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Habit Tracker',
                style: TextStyle(
                  color: DashboardScreen.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: DashboardScreen.grey,
                        fontSize: 11,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: DashboardScreen.grey,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...habits.map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(h.icon, size: 14, color: DashboardScreen.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          h.title,
                          style: const TextStyle(
                            color: DashboardScreen.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        h.fraction,
                        style: const TextStyle(
                          color: DashboardScreen.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: h.progress,
                      minHeight: 3,
                      backgroundColor: const Color(0xFF2A2A2A),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        DashboardScreen.red,
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

// ---------------------------------------------------------------------
// Upcoming card
// ---------------------------------------------------------------------
class _UpcomingEventData {
  final String day;
  final String month;
  final String title;
  final String subtitle;
  final String daysLeftLabel;

  const _UpcomingEventData({
    required this.day,
    required this.month,
    required this.title,
    required this.subtitle,
    required this.daysLeftLabel,
  });
}

class _UpcomingCard extends StatelessWidget {
  final _UpcomingEventData event;

  const _UpcomingCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardScreen.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DashboardScreen.cardBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.day,
                  style: const TextStyle(
                    color: DashboardScreen.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                Text(
                  event.month,
                  style: const TextStyle(
                    color: DashboardScreen.red,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: DashboardScreen.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.subtitle,
                  style: const TextStyle(
                    color: DashboardScreen.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            event.daysLeftLabel,
            style: const TextStyle(
              color: DashboardScreen.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// AETHER — Dashboard content
/// ---------------------------------------------------------------------
/// This file ONLY contains the body content of the dashboard screen.
/// The top app bar (logo / menu / profile) and the bottom navigation
/// bar are assumed to already exist elsewhere in the app — this widget
/// is meant to be dropped straight into the `body:` of that Scaffold.
/// ---------------------------------------------------------------------

class DashboardScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(),
              const SizedBox(height: 16),
              _DateNavigator(),
              const SizedBox(height: 20),
              _GlanceRow(),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Today\'s Schedule', onViewAll: () {}),
              const SizedBox(height: 12),
              _ScheduleCard(),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _TasksCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _HabitTrackerCard()),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Upcoming', onViewAll: () {}),
              const SizedBox(height: 12),
              _UpcomingCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Header: time / date + progress ring
// ---------------------------------------------------------------------
class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

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
                children: const [
                  Text(
                    '7:42',
                    style: TextStyle(
                      color: DashboardScreen.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'AM',
                    style: TextStyle(
                      color: DashboardScreen.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tuesday',
                style: TextStyle(
                  color: DashboardScreen.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '12th August 2025',
                style: TextStyle(
                  color: DashboardScreen.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const _ProgressRing(percent: 0.625),
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
                      color: DashboardScreen.red.withOpacity(0.55),
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
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(DashboardScreen.red),
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
  const _DateNavigator();

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
          const Icon(Icons.chevron_left, color: DashboardScreen.grey, size: 22),
          const Text(
            'Today',
            style: TextStyle(
              color: DashboardScreen.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(Icons.chevron_right, color: DashboardScreen.grey, size: 22),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// "Today at a glance" — 4 stat cards
// ---------------------------------------------------------------------
class _GlanceRow extends StatelessWidget {
  const _GlanceRow();

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
          children: const [
            Expanded(
              child: _GlanceCard(
                icon: Icons.assignment_outlined,
                iconColor: DashboardScreen.red,
                value: '6',
                label: 'Tasks pending',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _GlanceCard(
                icon: Icons.menu_book_outlined,
                iconColor: DashboardScreen.purple,
                value: '3',
                label: 'Classes today',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _GlanceCard(
                icon: Icons.check_circle_outline,
                iconColor: DashboardScreen.green,
                value: '4/7',
                label: 'Habits completed',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _GlanceCard(
                icon: Icons.favorite_border,
                iconColor: DashboardScreen.red,
                value: '72%',
                label: 'Health score',
              ),
            ),
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
        border: Border.all(color: iconColor.withOpacity(0.4)),
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
  const _ScheduleCard();

  static const items = [
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
                style: const TextStyle(color: DashboardScreen.grey, fontSize: 12),
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
                    style:
                        const TextStyle(color: DashboardScreen.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
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
  const _TasksCard();

  static const tasks = [
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
    _TaskItemData(
      title: 'Workout',
      subtitle: 'Completed',
      completed: true,
    ),
  ];

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
            children: const [
              Text(
                'Tasks',
                style: TextStyle(
                  color: DashboardScreen.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text('View All',
                      style: TextStyle(color: DashboardScreen.grey, fontSize: 11)),
                  Icon(Icons.chevron_right,
                      color: DashboardScreen.grey, size: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tasks.map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t.completed
                        ? const CircleAvatar(
                            radius: 9,
                            backgroundColor: DashboardScreen.red,
                            child: Icon(Icons.check,
                                size: 12, color: Colors.white),
                          )
                        : Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: DashboardScreen.grey, width: 1.4),
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
                                color: DashboardScreen.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (t.flagged)
                      const Icon(Icons.flag,
                          size: 14, color: DashboardScreen.red),
                  ],
                ),
              )),
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
  const _HabitTrackerCard();

  static const habits = [
    _HabitItemData(
        icon: Icons.menu_book_outlined,
        title: 'Study',
        fraction: '5/7',
        progress: 5 / 7),
    _HabitItemData(
        icon: Icons.self_improvement,
        title: 'Meditation',
        fraction: '4/7',
        progress: 4 / 7),
    _HabitItemData(
        icon: Icons.water_drop_outlined,
        title: 'No Sugar',
        fraction: '5/7',
        progress: 5 / 7),
    _HabitItemData(
        icon: Icons.nightlight_outlined,
        title: 'Sleep Early',
        fraction: '3/7',
        progress: 3 / 7),
  ];

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
            children: const [
              Text(
                'Habit Tracker',
                style: TextStyle(
                  color: DashboardScreen.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text('View All',
                      style: TextStyle(color: DashboardScreen.grey, fontSize: 11)),
                  Icon(Icons.chevron_right,
                      color: DashboardScreen.grey, size: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...habits.map((h) => Padding(
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
                              color: DashboardScreen.grey, fontSize: 11),
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
                            DashboardScreen.red),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Upcoming card
// ---------------------------------------------------------------------
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard();

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
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '18',
                  style: TextStyle(
                    color: DashboardScreen.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                Text(
                  'AUG',
                  style: TextStyle(
                    color: DashboardScreen.red,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maths Test',
                  style: TextStyle(
                    color: DashboardScreen.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Calculus • 5 Chapters',
                  style: TextStyle(color: DashboardScreen.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Text(
            '6 Days Left',
            style: TextStyle(
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
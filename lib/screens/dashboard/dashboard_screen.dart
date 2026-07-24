import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/features/academics/providers/academics_providers.dart';
import 'package:aether/widgets/common/glass_card.dart';
import 'package:aether/features/habits/providers/habits_providers.dart'; // Added for habits provider
import 'package:aether/features/habits/widgets/add_habit_dialog.dart'; // Added for habits dialog

/// ---------------------------------------------------------------------
/// AETHER — Dashboard content
/// ---------------------------------------------------------------------
/// Fully wired to real Riverpod streams from academics & habits databases.
/// Falls back gracefully when data is empty or loading.
/// ---------------------------------------------------------------------

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Register the habit add action for the global Add button
    Future.microtask(() {
      ref.read(globalAddActionProvider.notifier).state = () => _showAddHabitDialog();
    });
  }

  @override
  void dispose() {
    // Clear the action when leaving the screen if it's still this screen's action
    if (ref.read(globalAddActionProvider) == _showAddHabitDialog) {
      ref.read(globalAddActionProvider.notifier).state = null;
    }
    super.dispose();
  }

  Future<void> _showAddHabitDialog() async {
    final result = await showAddHabitDialog(context);
    if (result == null || !mounted) return;
    ref.read(habitsProvider.notifier).createHabit(
          name: result.name,
          category: result.category,
          icon: result.icon,
          color: result.color,
        );
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return Container(
      color: const Color(0xFF000000),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu button row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(drawerProvider.notifier).state = true,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        size: 22,
                        color: _white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _HeaderRow(
                weekdayLabel: _weekdayName(DateTime.now()),
                fullDateLabel: _formattedDate(DateTime.now()),
              ),
              const SizedBox(height: 20),
              _GlanceRow(coursesAsync: coursesAsync),
              const SizedBox(height: 24),
              _SectionHeader(title: "Today's Schedule", onViewAll: () {}),
              const SizedBox(height: 12),
              _ScheduleCard(coursesAsync: coursesAsync),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TasksCard(coursesAsync: coursesAsync),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _HabitTrackerCard(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Upcoming', onViewAll: () {}),
              const SizedBox(height: 12),
              _UpcomingCard(coursesAsync: coursesAsync),
            ],
          ),
        ),
      ),
    );
  }

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _weekdayName(DateTime d) => _weekdayNames[d.weekday - 1];

  String _ordinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  String _formattedDate(DateTime d) {
    return '${d.day}${_ordinalSuffix(d.day)} ${_monthNames[d.month - 1]} ${d.year}';
  }
}

// Palette
const _card = Color(0xFF121212);
const _cardBorder = Color(0xFF262626);
const _red = Color(0xFFFF3B30);
const _purple = Color(0xFF8B5CF6);
const _green = Color(0xFF34C759);
const _grey = Color(0xFF9A9A9E);
const _white = Color(0xFFF5F5F5);

// ── Header ──────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  final String weekdayLabel;
  final String fullDateLabel;
  const _HeaderRow({required this.weekdayLabel, required this.fullDateLabel});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeText = DateFormat('h:mm').format(now);
    final period = DateFormat('a').format(now).toUpperCase();

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
                  Text(timeText, style: const TextStyle(color: _white, fontSize: 40, fontWeight: FontWeight.w600, height: 1)),
                  const SizedBox(width: 6),
                  Text(period, style: const TextStyle(color: _grey, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 6),
              Text(weekdayLabel, style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(fullDateLabel, style: const TextStyle(color: _grey, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _ProgressRing(),
      ],
    );
  }
}

class _ProgressRing extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final progress = coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) return 0.0;
        double total = 0;
        for (final c in courses) {
          final pAsync = ref.watch(courseProgressProvider(c.id));
          total += pAsync.valueOrNull ?? 0.0;
        }
        return total / courses.length;
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    return Container(
      width: 140, height: 128, padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cardBorder)),
      child: Center(
        child: SizedBox(
          width: 96, height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.55), blurRadius: 20, spreadRadius: 1)],
                ),
              ),
              SizedBox(
                width: 96, height: 96,
                child: CircularProgressIndicator(
                  value: progress, strokeWidth: 6,
                  backgroundColor: const Color(0xFF3A3A3C),
                  valueColor: const AlwaysStoppedAnimation<Color>(_red),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Progress', style: TextStyle(color: _grey, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glance Row ──────────────────────────────────────

class _GlanceRow extends ConsumerWidget {
  final AsyncValue<List<Course>> coursesAsync;
  const _GlanceRow({required this.coursesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = coursesAsync.valueOrNull ?? [];

    int tasksPending = 0;
    int classesToday = 0;
    for (final c in courses) {
      final assignments = ref.watch(assignmentsProvider(c.id)).valueOrNull ?? [];
      tasksPending += assignments.where((a) => !a.isCompleted).length;

      final lectures = ref.watch(lecturesProvider(c.id)).valueOrNull ?? [];
      final today = DateTime.now();
      classesToday += lectures.where((l) =>
          l.scheduledAt != null &&
          l.scheduledAt!.year == today.year &&
          l.scheduledAt!.month == today.month &&
          l.scheduledAt!.day == today.day).length;
    }

    final items = [
      _GlanceItemData(icon: Icons.assignment_outlined, iconColor: _red, value: '$tasksPending', label: 'Tasks pending'),
      _GlanceItemData(icon: Icons.menu_book_outlined, iconColor: _purple, value: '${courses.length}', label: 'Courses'),
      _GlanceItemData(icon: Icons.check_circle_outline, iconColor: _green, value: '$classesToday', label: 'Classes today'),
      _GlanceItemData(icon: Icons.favorite_border, iconColor: _red, value: '--', label: 'Health score'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today at a glance', style: TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _GlanceCard(icon: items[i].icon, iconColor: items[i].iconColor, value: items[i].value, label: items[i].label)),
          ],
        ]),
      ],
    );
  }
}

class _GlanceItemData {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _GlanceItemData({required this.icon, required this.iconColor, required this.value, required this.label});
}

class _GlanceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _GlanceCard({required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _grey, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w600)),
        GestureDetector(
          onTap: onViewAll,
          child: const Row(children: [
            Text('View All', style: TextStyle(color: _grey, fontSize: 12)),
            Icon(Icons.chevron_right, color: _grey, size: 16),
          ]),
        ),
      ],
    );
  }
}

// ── Schedule Card ───────────────────────────────────

class _ScheduleCard extends ConsumerWidget {
  final AsyncValue<List<Course>> coursesAsync;
  const _ScheduleCard({required this.coursesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = coursesAsync.valueOrNull ?? [];
    final today = DateTime.now();
    final todayName = DateFormat('EEEE').format(today);

    final todayItems = <_ScheduleItemData>[];
    for (final c in courses) {
      final lectures = ref.watch(lecturesProvider(c.id)).valueOrNull ?? [];
      for (final l in lectures) {
        if (l.scheduledAt != null && l.scheduledAt!.year == today.year && l.scheduledAt!.month == today.month && l.scheduledAt!.day == today.day) {
          final color = Color(int.parse(c.color.replaceFirst('#', '0xFF')));
          todayItems.add(_ScheduleItemData(
            time: DateFormat('h:mm a').format(l.scheduledAt!.toLocal()),
            title: l.title, subtitle: c.name,
            icon: Icons.menu_book_outlined, color: color,
          ));
        }
      }
    }

    for (final c in courses) {
      if (c.scheduleDays != null && c.scheduleStart != null) {
        final days = c.scheduleDays!.split(',').map((s) => s.trim().toLowerCase()).toList();
        if (days.any((d) => d.startsWith(todayName.substring(0, 3).toLowerCase()))) {
          if (!todayItems.any((i) => i.title == c.name)) {
            final color = Color(int.parse(c.color.replaceFirst('#', '0xFF')));
            todayItems.add(_ScheduleItemData(
              time: c.scheduleStart!, title: c.name,
              subtitle: c.professor ?? 'No instructor',
              icon: Icons.menu_book_outlined, color: color,
            ));
          }
        }
      }
    }

    todayItems.sort((a, b) => a.time.compareTo(b.time));

    if (todayItems.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20), borderRadius: BorderRadius.circular(16),
        child: const Center(child: Column(children: [
          Icon(Icons.event_busy, color: _grey, size: 32),
          SizedBox(height: 8),
          Text('No classes scheduled today', style: TextStyle(color: _grey, fontSize: 14)),
        ])),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cardBorder)),
      child: Column(children: List.generate(todayItems.length, (i) {
        final item = todayItems[i];
        return _ScheduleRow(item: item, showLine: i < todayItems.length - 1);
      })),
    );
  }
}

class _ScheduleItemData {
  final String time; final String title; final String subtitle; final IconData icon; final Color color;
  const _ScheduleItemData({required this.time, required this.title, required this.subtitle, required this.icon, required this.color});
}

class _ScheduleRow extends StatelessWidget {
  final _ScheduleItemData item; final bool showLine;
  const _ScheduleRow({required this.item, required this.showLine});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 70, child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(item.time, style: const TextStyle(color: _grey, fontSize: 12)),
        )),
        Column(children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(shape: BoxShape.circle, color: _grey)),
          if (showLine) Expanded(child: Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: _cardBorder)),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: showLine ? 20 : 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(item.subtitle, style: const TextStyle(color: _grey, fontSize: 12)),
          ]),
        )),
        Container(width: 36, height: 36, decoration: BoxDecoration(color: item.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(item.icon, color: item.color, size: 18)),
      ]),
    );
  }
}

// ── Tasks Card ──────────────────────────────────────

class _TasksCard extends ConsumerWidget {
  final AsyncValue<List<Course>> coursesAsync;
  const _TasksCard({required this.coursesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = coursesAsync.valueOrNull ?? [];
    final today = DateTime.now();

    final allTasks = <_TaskItemData>[];
    for (final c in courses) {
      final assignments = ref.watch(assignmentsProvider(c.id)).valueOrNull ?? [];
      for (final a in assignments) {
        if (!a.isCompleted) {
          String subtitle = c.name;
          if (a.dueDate != null) {
            final diff = a.dueDate!.difference(today).inDays;
            subtitle += ' • ${diff == 0 ? "Due today" : diff < 0 ? "Overdue" : "$diff days left"}';
          }
          allTasks.add(_TaskItemData(title: a.title, subtitle: subtitle, flagged: a.dueDate != null && a.dueDate!.isBefore(today)));
        }
      }
    }
    allTasks.sort((a, b) => a.subtitle.compareTo(b.subtitle));
    final display = allTasks.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tasks', style: TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (display.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No pending tasks', style: TextStyle(color: _grey, fontSize: 12)))
        else
          ...display.map((t) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _grey, width: 1.4))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title, style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(t.subtitle, style: const TextStyle(color: _grey, fontSize: 11)),
              ])),
              if (t.flagged) const Icon(Icons.flag, size: 14, color: _red),
            ]),
          )),
      ]),
    );
  }
}

class _TaskItemData {
  final String title; final String subtitle; final bool flagged;
  const _TaskItemData({required this.title, required this.subtitle, this.flagged = false, this.completed = false});
  final bool completed;
}

// ── Habit Tracker Card ──────────────────────────────

class _HabitTrackerCard extends StatelessWidget {
  const _HabitTrackerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cardBorder)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Habit Tracker', style: TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600)),
        SizedBox(height: 16),
        Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Coming Soon', style: TextStyle(color: _grey, fontSize: 13)))),
      ]),
    );
  }
}

// ── Upcoming Card ───────────────────────────────────

class _UpcomingCard extends ConsumerWidget {
  final AsyncValue<List<Course>> coursesAsync;
  const _UpcomingCard({required this.coursesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = coursesAsync.valueOrNull ?? [];
    final today = DateTime.now();
    final events = <_UpcomingEventData>[];

    for (final c in courses) {
      final assignments = ref.watch(assignmentsProvider(c.id)).valueOrNull ?? [];
      for (final a in assignments) {
        if (!a.isCompleted && a.dueDate != null && a.dueDate!.isAfter(today)) {
          final diff = a.dueDate!.difference(today).inDays;
          events.add(_UpcomingEventData(
            day: a.dueDate!.day.toString(),
            month: DateFormat('MMM').format(a.dueDate!).toUpperCase(),
            title: a.title, subtitle: c.name,
            daysLeftLabel: diff == 0 ? 'Due Today' : '$diff Days Left',
          ));
        }
      }
    }
    events.sort((a, b) => a.day.compareTo(b.day));
    final event = events.isNotEmpty ? events.first : null;

    if (event == null) {
      return GlassCard(
        padding: const EdgeInsets.all(20), borderRadius: BorderRadius.circular(16),
        child: const Center(child: Text('No upcoming events', style: TextStyle(color: _grey, fontSize: 14))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cardBorder)),
      child: Row(children: [
        Container(width: 48, height: 48, alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: _cardBorder)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(event.day, style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700, height: 1)),
            Text(event.month, style: const TextStyle(color: _red, fontSize: 9, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event.title, style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(event.subtitle, style: const TextStyle(color: _grey, fontSize: 12)),
        ])),
        Text(event.daysLeftLabel, style: const TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _UpcomingEventData {
  final String day; final String month; final String title; final String subtitle; final String daysLeftLabel;
  const _UpcomingEventData({required this.day, required this.month, required this.title, required this.subtitle, required this.daysLeftLabel});
}

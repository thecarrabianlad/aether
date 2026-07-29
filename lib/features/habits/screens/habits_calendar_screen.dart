import 'package:aether/core/providers.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/providers/habits_providers.dart';
import 'package:aether/features/habits/services/habits_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// View: Full-screen monthly heatmap calendar.
///
/// Renders a GitHub-style contribution grid where each cell represents
/// a day, coloured by completion intensity (ratio of habits done).
/// Filterable by category or individual habit.
class HabitsCalendarScreen extends ConsumerStatefulWidget {
  const HabitsCalendarScreen({super.key});

  @override
  ConsumerState<HabitsCalendarScreen> createState() =>
      _HabitsCalendarScreenState();
}

class _HabitsCalendarScreenState extends ConsumerState<HabitsCalendarScreen> {
  late DateTime _displayedMonth; // First day of the displayed month.
  HabitCategory? _categoryFilter;
  String? _habitIdFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final habitsAsync = ref.watch(habitsProvider);
    final habitsService = ref.read(habitsServiceProvider);

    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon..7=Sun

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: aether.text.withValues(alpha: 0.75)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Calendar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: aether.text,
          ),
        ),
      ),
      body: habitsAsync.when(
        data: (habits) {
          var filtered = habits;
          if (_categoryFilter != null) {
            filtered = filtered.where((h) => h.category == _categoryFilter).toList();
          }

          return _CalendarBody(
            year: year,
            month: month,
            daysInMonth: daysInMonth,
            firstWeekday: firstWeekday,
            filteredHabits: filtered,
            habitsService: habitsService,
            categoryFilter: _categoryFilter,
            habitIdFilter: _habitIdFilter,
            allHabits: habits,
            onPreviousMonth: _previousMonth,
            onNextMonth: _nextMonth,
            onCategoryChanged: (cat) =>
                setState(() => _categoryFilter = cat),
            onHabitIdChanged: (id) =>
                setState(() => _habitIdFilter = id),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: TextStyle(color: aether.danger)),
        ),
      ),
    );
  }
}

class _CalendarBody extends ConsumerWidget {
  final int year;
  final int month;
  final int daysInMonth;
  final int firstWeekday;
  final List<Habit> filteredHabits;
  final HabitsService habitsService;
  final HabitCategory? categoryFilter;
  final String? habitIdFilter;
  final List<Habit> allHabits;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final void Function(HabitCategory?) onCategoryChanged;
  final void Function(String?) onHabitIdChanged;

  const _CalendarBody({
    required this.year,
    required this.month,
    required this.daysInMonth,
    required this.firstWeekday,
    required this.filteredHabits,
    required this.habitsService,
    required this.categoryFilter,
    required this.habitIdFilter,
    required this.allHabits,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onCategoryChanged,
    required this.onHabitIdChanged,
  });

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _weekdayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aether = context.aether;
    final now = DateTime.now();

    // Load logs for filtered habits.
    // A FutureBuilder approach: load logs synchronously at build time.
    return FutureBuilder<Map<String, double>>(
      future: _buildHeatmapData(filteredHabits, habitsService, year, month),
      builder: (context, snapshot) {
        final heatmap = snapshot.data ?? <String, double>{};

        // ── Month navigator ──────────────────────────────
        return Column(
          children: [
            // Month navigator + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: aether.text),
                    onPressed: onPreviousMonth,
                  ),
                  Text(
                    '${_monthNames[month - 1]} $year',
                    style: TextStyle(
                      color: aether.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: aether.text),
                    onPressed: onNextMonth,
                  ),
                ],
              ),
            ),

            // ── Filters ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Category dropdown
                  Expanded(
                    child: DropdownButtonFormField<HabitCategory?>(
                      initialValue: categoryFilter,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: aether.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      ),
                      dropdownColor: aether.surface,
                      style: TextStyle(color: aether.text, fontSize: 13),
                      icon:
                          Icon(Icons.expand_more, color: aether.textMuted, size: 18),
                      hint: Text('All Categories',
                          style: TextStyle(color: aether.textMuted, fontSize: 13)),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...HabitCategory.values.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.label),
                            )),
                      ],
                      onChanged: (v) => onCategoryChanged(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Individual habit dropdown
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: habitIdFilter,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: aether.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      ),
                      dropdownColor: aether.surface,
                      style: TextStyle(color: aether.text, fontSize: 13),
                      icon:
                          Icon(Icons.expand_more, color: aether.textMuted, size: 18),
                      hint: Text('All Habits',
                          style: TextStyle(color: aether.textMuted, fontSize: 13)),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Habits'),
                        ),
                        ...allHabits.map((h) => DropdownMenuItem(
                              value: h.id,
                              child: Text(h.name),
                            )),
                      ],
                      onChanged: (v) => onHabitIdChanged(v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Weekday headers ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _weekdayHeaders
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                color: aether.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 6),

            // ── Calendar grid ────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount:
                      firstWeekday - 1 + daysInMonth, // Offset empty cells
                  itemBuilder: (context, index) {
                    final day = index - (firstWeekday - 1) + 1;
                    if (day < 1 || day > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final dateStr =
                        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                    final intensity = heatmap[dateStr] ?? 0.0;
                    final isToday = year == now.year &&
                        month == now.month &&
                        day == now.day;

                    return GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: intensity >= 0.99
                              ? aether.success.withValues(alpha: 0.45)
                              : intensity > 0
                                  ? aether.accent
                                      .withValues(alpha: 0.15 + intensity * 0.35)
                                  : aether.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isToday
                                ? aether.accent
                                : aether.border,
                            width: isToday ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isToday ? FontWeight.w700 : FontWeight.w400,
                              color: intensity >= 0.99
                                  ? aether.success
                                  : intensity > 0
                                      ? aether.accent
                                      : aether.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build a heatmap by loading logs for filtered habits for the given month.
  ///
  /// Returns `Map<dateString, completionRatio>`.
  Future<Map<String, double>> _buildHeatmapData(
    List<Habit> filteredHabits,
    HabitsService service,
    int year,
    int month,
  ) async {
    if (filteredHabits.isEmpty) return {};

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    final totalHabits = filteredHabits.length;

    final dayCounts = <String, int>{};
    for (int d = 1; d <= endDate.day; d++) {
      dayCounts['${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}'] = 0;
    }

    for (final habit in filteredHabits) {
      final logs = await service.watchLogsForHabit(habit.id).first;
      for (final log in logs) {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        if (log.isCompleted &&
            !logDate.isBefore(startDate) &&
            !logDate.isAfter(endDate)) {
          final key =
              '${logDate.year.toString().padLeft(4, '0')}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';
          dayCounts[key] = (dayCounts[key] ?? 0) + 1;
        }
      }
    }

    return dayCounts.map((key, count) =>
        MapEntry(key, totalHabits > 0 ? count / totalHabits : 0.0));
  }
}

import 'package:flutter/material.dart';
import 'package:aether/features/schedule/screens/schedule_screen.dart'
    show ScheduleScreen;

/// Icon keys stored in Drift ('icon' column on both schedule_templates and
/// schedule_blocks) mapped to the actual IconData. Drift has no IconData
/// column type, so we persist the key and resolve it at render time.
const Map<String, IconData> kScheduleIconOptions = {
  'wake_up': Icons.wb_sunny_outlined,
  'run': Icons.directions_run_rounded,
  'shower': Icons.shower_outlined,
  'meditate': Icons.self_improvement,
  'study': Icons.menu_book_outlined,
  'coffee': Icons.local_cafe_outlined,
  'meal': Icons.restaurant_outlined,
  'school': Icons.school_outlined,
  'rest': Icons.weekend_outlined,
  'travel': Icons.card_travel_outlined,
  'exam': Icons.track_changes_outlined,
  'work': Icons.work_outline,
  'workout': Icons.fitness_center,
  'laptop': Icons.laptop_mac,
  'music': Icons.music_note_outlined,
  'other': Icons.more_horiz,
};

IconData iconForKey(String key) =>
    kScheduleIconOptions[key] ?? Icons.more_horiz;

/// Swatches offered for schedule blocks — same palette already used
/// throughout the app (DashboardScreen / ScheduleScreen).
const Map<String, Color> kScheduleColorOptions = {
  '#FF3B30': ScheduleScreen.red,
  '#8B5CF6': ScheduleScreen.purple,
  '#34C759': ScheduleScreen.green,
  '#E08A2E': ScheduleScreen.orange,
  '#3B82F6': ScheduleScreen.blue,
};

Color colorForHex(String hex) =>
    kScheduleColorOptions[hex] ?? ScheduleScreen.grey;

/// 'HH:mm' (24h) -> TimeOfDay.
TimeOfDay timeOfDayFromKey(String hhmm) {
  final parts = hhmm.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 0,
    minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
  );
}

/// TimeOfDay -> 'HH:mm' (24h), zero-padded so it sorts correctly as text.
String timeOfDayToKey(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// 'HH:mm' -> '5:00\nAM' display label matching the timeline's two-line style.
String formatTimeLabel(String hhmm) {
  final t = timeOfDayFromKey(hhmm);
  final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour12:$minute\n$period';
}

/// 'HH:mm' -> '5:00 AM' single-line, used inside pickers/forms.
String formatTimeInline(String hhmm) {
  final t = timeOfDayFromKey(hhmm);
  final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

/// Minutes between two 'HH:mm' keys. Wraps past midnight if end <= start.
int minutesBetween(String startKey, String endKey) {
  final start = timeOfDayFromKey(startKey);
  final end = timeOfDayFromKey(endKey);
  final startMinutes = start.hour * 60 + start.minute;
  var endMinutes = end.hour * 60 + end.minute;
  if (endMinutes <= startMinutes) endMinutes += 24 * 60;
  return endMinutes - startMinutes;
}

/// e.g. 45 -> '45m', 120 -> '2h 00m'.
String formatDuration(int minutes) {
  if (minutes <= 0) return '0m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

/// e.g. 525 -> '8h 45m Total'.
String formatTotalDuration(int minutes) {
  if (minutes <= 0) return '0m Total';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m Total';
  if (m == 0) return '${h}h Total';
  return '${h}h ${m}m Total';
}

const List<String> kWeekdayShort = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
];

/// Comma-separated weekday indices ('0,1,2') -> display label, matching the
/// original static "Weekdays (Mon – Fri)" style.
String repeatDaysLabel(String repeatDays) {
  final indices = repeatDays
      .split(',')
      .where((s) => s.trim().isNotEmpty)
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .toSet();

  if (indices.isEmpty) return 'Not repeating';
  if (indices.length == 7) return 'Every day';
  if (indices.length == 5 && !indices.contains(5) && !indices.contains(6)) {
    return 'Weekdays (Mon – Fri)';
  }
  if (indices.length == 2 && indices.contains(5) && indices.contains(6)) {
    return 'Weekends (Sat – Sun)';
  }
  final sorted = indices.toList()..sort();
  return sorted.map((i) => kWeekdayShort[i]).join(', ');
}
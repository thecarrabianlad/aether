import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';

import 'package:aether/core/database/database.dart'; // For HabitEntry

/// Top-level background handler required by flutter_local_notifications.
/// Must be a top-level or static function annotated with vm:entry-point.
@pragma('vm:entry-point')
void _notificationBackgroundHandler(NotificationResponse response) {
  NotificationService._handleTap(response.payload);
}

/// Offline-first local notification service for habit reminders.
///
/// Uses [flutter_local_notifications] with [zonedSchedule] and
/// [DateTimeComponents.dayOfWeekAndTime] so each notification fires
/// weekly on the chosen weekday without manual re-scheduling.
///
/// Initialised once at app startup ([main]) — permissions are requested
/// lazily when the user first sets a reminder on a habit.
class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  static GoRouter? _router;

  /// Provide a router reference so notification taps can navigate.
  /// Set from [AetherApp] build (or [main]) after the router is available.
  static set router(GoRouter? r) => _router = r;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Lifecycle ──────────────────────────────────────────

  /// Initialise the plugin, timezone database, and Android channel.
  /// Call once from [main] before [runApp].
  Future<void> init() async {
    if (_initialized) return;

    // Timezone setup for zonedSchedule.
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onForegroundTap,
      onDidReceiveBackgroundNotificationResponse: _notificationBackgroundHandler,
    );

    // Android 8+ notification channel.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'habit_reminders',
            'Habit Reminders',
            description: 'Daily reminders for your habits',
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  /// Request notification permissions (Android 13+, iOS).
  /// Call lazily when the user first sets a reminder on a habit.
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        (await android?.requestNotificationsPermission()) ?? false;
    final iosGranted = (await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    )) ?? false;

    return androidGranted || iosGranted;
  }

  // ── Scheduling helpers for the plan ────────────────────

  /// Schedule one [zonedSchedule] per selected weekday.
  /// If [habit.reminderTime] or [habit.reminderDays] is null, cancels any
  /// existing notifications for this habit instead.
  ///
  /// Each notification gets a deterministic ID = `habitId.hashCode ^ weekday`
  /// so we can cancel them individually without storing IDs.
  Future<void> scheduleHabitReminder(HabitEntry habit) async {
    if (habit.reminderTime == null || habit.reminderDays == null) {
      await cancelHabitReminders(habit.id);
      return;
    }

    final timeParts = habit.reminderTime!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final days = habit.reminderDays!
        .split(',')
        .map((s) => int.parse(s.trim()))
        .toList();

    for (final weekday in days) {
      // Use a consistent ID generation for each weekday of this habit.
      // habit.id is a UUID string.
      final notificationId = (habit.id.hashCode ^ weekday).toUnsigned(31);
      final scheduledDate = _nextWeekdayTime(weekday, hour, minute);

      await _plugin.zonedSchedule(
        notificationId,
        'Time for ${habit.name}!',
        'Tap to log your habit.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Daily reminders for your habits',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: habit.id,
      );
    }
  }

  /// Cancel all scheduled notifications for a given habit (weekdays 1–7).
  Future<void> cancelHabitReminders(String habitId) async {
    for (int weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel((habitId.hashCode ^ weekday).toUnsigned(31));
    }
  }

  /// Cancel every scheduled notification (all habits, all weekdays).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancel all, then re-schedule for every habit that has a reminder.
  Future<void> rescheduleAll(List<HabitEntry> habits) async {
    await cancelAll();
    for (final habit in habits) {
      await scheduleHabitReminder(habit);
    }
  }

  // ── Tap handling (foreground + background) ────────────

  void _onForegroundTap(NotificationResponse response) {
    _handleTap(response.payload);
  }

  /// Navigate to the habits screen when a habit-reminder notification is tapped.
  static void _handleTap(String? payload) {
    // payload carries the habitId for future habit-detail deep linking.
    _router?.go('/habits');
  }

  // ── Helpers ────────────────────────────────────────────

  /// Compute the next [tz.TZDateTime] matching [weekday] at [hour]:[minute].
  /// If today is the target weekday but the time has passed, skip to next week.
  tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Advance until the target weekday.
    while (date.weekday != weekday) {
      date = date.add(const Duration(days: 1));
      date = tz.TZDateTime(tz.local, date.year, date.month, date.day, hour, minute);
    }

    // If already past today, schedule for next week (the plugin's
    // dayOfWeekAndTime component handles recurrence after that).
    if (date.isBefore(now)) {
      date = date.add(const Duration(days: 7));
      date = tz.TZDateTime(tz.local, date.year, date.month, date.day, hour, minute);
    }

    return date;
  }
}

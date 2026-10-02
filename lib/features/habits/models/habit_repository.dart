import 'package:flutter/material.dart';

// This file now only holds UI-related constants for habits
// All persistence logic has moved to HabitsService.
class HabitRepository {
  HabitRepository._(); // Private constructor

  // ── Category colours used across the feature ──
  // Fixed semantic colors — habit categories keep their identity
  // regardless of the active app theme.
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color greenAccent = Color(0xFF34C759);
  static const Color orangeAccent = Color(0xFFFF9500);
  static const Color blueAccent = Color(0xFF3B82F6);
}

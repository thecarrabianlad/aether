import 'package:flutter/material.dart';

// This file now only holds UI-related constants for habits
// All persistence logic has moved to HabitsService.
class HabitRepository {
  HabitRepository._(); // Private constructor

  // ── Category colours used across the feature ──
  static const Color redAccent = Color(0xFFE8443F);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color greenAccent = Color(0xFF34C759);
  static const Color orangeAccent = Color(0xFFFF9500);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color cardBg = Color(0xFF121212);
  static const Color cardBorder = Color(0xFF262626);
  static const Color greyText = Color(0xFF9A9A9E);
  static const Color whiteText = Color(0xFFF5F5F5);
  static const Color darkBg = Color(0xFF000000);
}
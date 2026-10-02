import 'package:flutter/material.dart';

/// Serialization helpers shared by every screen that creates or edits a habit.
///
/// Habits are stored in Drift with `icon` and `color` as text columns, so the
/// UI's `IconData`/`Color` values have to be converted on the way in and back
/// on the way out.
class HabitCodec {
  const HabitCodec._();

  static final Map<IconData, String> _iconNames = <IconData, String>{
    Icons.menu_book_outlined: 'menu_book_outlined',
    Icons.favorite_border: 'favorite_border',
    Icons.self_improvement: 'self_improvement',
    Icons.directions_run: 'directions_run',
    Icons.spa_outlined: 'spa_outlined',
    Icons.water_drop_outlined: 'water_drop_outlined',
    Icons.calculate_outlined: 'calculate_outlined',
    Icons.medication_outlined: 'medication_outlined',
    Icons.nightlight_outlined: 'nightlight_outlined',
  };

  static final Map<String, IconData> _iconData =
      _iconNames.map((icon, name) => MapEntry(name, icon));

  static String iconToString(IconData icon) =>
      _iconNames[icon] ?? 'help_outline';

  static IconData stringToIcon(String name) =>
      _iconData[name] ?? Icons.help_outline;

  static String colorToString(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static Color stringToColor(String hex) {
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.tryParse(value, radix: 16) ?? 0xFFE8443F);
  }
}

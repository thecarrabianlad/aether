import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// AETHER — Theme system
/// ---------------------------------------------------------------------
/// Centralizes the app's dark aesthetic into a configurable theme:
///  • [AccentPreset]  — curated accent colors the user can pick from
///  • [BackgroundVariant] — graphite (default) or pure-black AMOLED
///  • [AetherTheme]   — a [ThemeExtension] carrying all app colors so
///    widgets read them via `Theme.of(context).extension<AetherTheme>()`
///    (or the [AetherThemeX.aether] shorthand) instead of hardcoding.
/// ---------------------------------------------------------------------

/// Curated accent colors. Each carries a display name and the accent
/// color used for highlights, active states, and glows app-wide.
enum AccentPreset {
  ember('Ember', Color(0xFFE8443F)),
  rose('Rose', Color(0xFFE88D8A)),
  violet('Violet', Color(0xFF8B5CF6)),
  ocean('Ocean', Color(0xFF4A9DE8)),
  mint('Mint', Color(0xFF34C759)),
  amber('Amber', Color(0xFFE8A33F));

  final String label;
  final Color color;

  const AccentPreset(this.label, this.color);

  /// Lookup by stored name; falls back to [ember] (the app's original red).
  static AccentPreset fromName(String? name) {
    return AccentPreset.values.firstWhere(
      (p) => p.name == name,
      orElse: () => AccentPreset.ember,
    );
  }
}

/// Background darkness variants.
enum BackgroundVariant {
  graphite('Graphite'),
  amoled('AMOLED');

  final String label;

  const BackgroundVariant(this.label);

  static BackgroundVariant fromName(String? name) {
    return BackgroundVariant.values.firstWhere(
      (v) => v.name == name,
      orElse: () => BackgroundVariant.graphite,
    );
  }
}

/// User's theme selection. Immutable value object held by the theme
/// controller and persisted via SettingsService.
@immutable
class AppThemeState {
  final AccentPreset accent;
  final BackgroundVariant background;

  const AppThemeState({
    this.accent = AccentPreset.ember,
    this.background = BackgroundVariant.graphite,
  });

  AppThemeState copyWith({
    AccentPreset? accent,
    BackgroundVariant? background,
  }) {
    return AppThemeState(
      accent: accent ?? this.accent,
      background: background ?? this.background,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppThemeState &&
      other.accent == accent &&
      other.background == background;

  @override
  int get hashCode => Object.hash(accent, background);
}

/// App-wide color tokens, resolved from an [AppThemeState].
///
/// Widgets should read these instead of hardcoding colors:
/// ```dart
/// final aether = context.aether;
/// Container(color: aether.card, child: Icon(color: aether.accent));
/// ```
class AetherTheme extends ThemeExtension<AetherTheme> {
  /// Primary accent — highlights, active nav items, glows, CTAs.
  final Color accent;

  /// Scaffold / page background.
  final Color background;

  /// Elevated surface (cards, sheets, dialogs).
  final Color surface;

  /// Slightly raised surface (input fills, chips).
  final Color surfaceAlt;

  /// Card fill used by glass cards.
  final Color card;

  /// Hairline borders on cards and dividers.
  final Color border;

  /// Primary text.
  final Color text;

  /// Secondary / muted text.
  final Color textMuted;

  /// Success (streaks, confirmations).
  final Color success;

  /// Destructive actions and errors.
  final Color danger;

  const AetherTheme({
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.danger,
  });

  /// Builds the token set for a given user selection.
  factory AetherTheme.fromState(AppThemeState state) {
    final amoled = state.background == BackgroundVariant.amoled;
    return AetherTheme(
      accent: state.accent.color,
      background: amoled ? const Color(0xFF000000) : const Color(0xFF0D0D0D),
      surface: amoled ? const Color(0xFF101012) : const Color(0xFF18181A),
      surfaceAlt: amoled ? const Color(0xFF1A1A1C) : const Color(0xFF2C2C2E),
      card: amoled ? const Color(0xFF0E0E0E) : const Color(0xFF121212),
      border: const Color(0xFF262626),
      text: const Color(0xFFF5F5F5),
      textMuted: const Color(0xFF8E8E93),
      success: const Color(0xFF34C759),
      danger: const Color(0xFFFF3B30),
    );
  }

  @override
  AetherTheme copyWith({
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? card,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? success,
    Color? danger,
  }) {
    return AetherTheme(
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      card: card ?? this.card,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      danger: danger ?? this.danger,
    );
  }

  @override
  AetherTheme lerp(ThemeExtension<AetherTheme>? other, double t) {
    if (other is! AetherTheme) return this;
    return AetherTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Convenience accessor: `context.aether.accent`.
extension AetherThemeX on BuildContext {
  AetherTheme get aether =>
      Theme.of(this).extension<AetherTheme>() ??
      AetherTheme.fromState(const AppThemeState());
}

/// Builds the app's [ThemeData] for the given user selection.
ThemeData buildAetherTheme(AppThemeState state) {
  final aether = AetherTheme.fromState(state);

  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: aether.background,
    colorScheme: ColorScheme.dark(
      primary: aether.accent,
      secondary: aether.accent,
      surface: aether.surface,
      error: aether.danger,
    ),
    extensions: [aether],
    snackBarTheme: SnackBarThemeData(
      backgroundColor: aether.surface,
      contentTextStyle: TextStyle(color: aether.text),
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? aether.accent : aether.textMuted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? aether.accent.withValues(alpha: 0.35)
              : aether.surfaceAlt),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}

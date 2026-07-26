import 'package:aether/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user settings (theme, notification toggles, sync metadata)
/// locally via SharedPreferences. Device-local by design — settings do
/// not sync to the cloud.
class SettingsService {
  SettingsService._(this._prefs);

  static const _keyAccent = 'settings.theme.accent';
  static const _keyBackground = 'settings.theme.background';
  static const _keyNotificationsEnabled = 'settings.notifications.enabled';
  static const _keyNotifyTasks = 'settings.notifications.tasks';
  static const _keyNotifyHabits = 'settings.notifications.habits';
  static const _keyNotifyLectures = 'settings.notifications.lectures';
  static const _keyLastSyncedAt = 'settings.sync.lastSyncedAt';

  final SharedPreferences _prefs;

  /// Loads the backing store. Call once at startup.
  static Future<SettingsService> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs);
  }

  // --- Theme ---

  AppThemeState get themeState => AppThemeState(
        accent: AccentPreset.fromName(_prefs.getString(_keyAccent)),
        background: BackgroundVariant.fromName(_prefs.getString(_keyBackground)),
      );

  Future<void> saveThemeState(AppThemeState state) async {
    await _prefs.setString(_keyAccent, state.accent.name);
    await _prefs.setString(_keyBackground, state.background.name);
  }

  // --- Notifications ---

  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;
  bool get notifyTasks => _prefs.getBool(_keyNotifyTasks) ?? true;
  bool get notifyHabits => _prefs.getBool(_keyNotifyHabits) ?? true;
  bool get notifyLectures => _prefs.getBool(_keyNotifyLectures) ?? true;

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_keyNotificationsEnabled, value);
  Future<void> setNotifyTasks(bool value) =>
      _prefs.setBool(_keyNotifyTasks, value);
  Future<void> setNotifyHabits(bool value) =>
      _prefs.setBool(_keyNotifyHabits, value);
  Future<void> setNotifyLectures(bool value) =>
      _prefs.setBool(_keyNotifyLectures, value);

  // --- Sync metadata ---

  DateTime? get lastSyncedAt {
    final millis = _prefs.getInt(_keyLastSyncedAt);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  Future<void> setLastSyncedAt(DateTime time) =>
      _prefs.setInt(_keyLastSyncedAt, time.millisecondsSinceEpoch);
}

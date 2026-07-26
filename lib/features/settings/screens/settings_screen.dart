import 'package:aether/core/providers.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/settings/widgets/settings_section.dart';
import 'package:aether/features/settings/widgets/theme_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Settings page reached from the side drawer.
///
/// Sections: Appearance (theme customization), Account, Notifications,
/// Data & Sync, and About. Settings persist locally via SettingsService.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await ref.read(syncServiceProvider).syncAllData();
      await ref.read(syncQueueServiceProvider).processQueue();

      final now = DateTime.now();
      await ref.read(settingsServiceProvider).setLastSyncedAt(now);
      ref.read(lastSyncedAtProvider.notifier).state = now;
      ref.invalidate(pendingSyncCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sync complete'),
            backgroundColor: context.aether.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: context.aether.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _editProfileField({
    required String title,
    required String currentValue,
    required Future<void> Function(String) onSave,
  }) async {
    final result = await showEditFieldDialog(
      context,
      title: title,
      initialValue: currentValue,
    );
    if (result == null || result == currentValue) return;

    try {
      await onSave(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: context.aether.danger,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final aether = context.aether;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: aether.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log out?', style: TextStyle(color: aether.text)),
        content: Text(
          'You can log back in at any time.',
          style: TextStyle(color: aether.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: aether.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Log Out', style: TextStyle(color: aether.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider).signOut();
    // Router redirect handles navigation to /login.
  }

  String _formatLastSynced(DateTime? time) {
    if (time == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return DateFormat('d MMM, HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final themeState = ref.watch(themeControllerProvider);
    final notifications = ref.watch(notificationSettingsProvider);
    final profileAsync = ref.watch(profileProvider);
    final lastSynced = ref.watch(lastSyncedAtProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    final profile = profileAsync.valueOrNull;
    final email = ref.watch(authProvider).currentUser?.email ?? '—';

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
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: aether.text,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // --- Appearance ---
          SettingsSection(
            title: 'Appearance',
            children: [
              const SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Accent Color',
                subtitle: 'Used for highlights across the app',
              ),
              AccentPicker(
                selected: themeState.accent,
                onSelected: (preset) =>
                    ref.read(themeControllerProvider.notifier).setAccent(preset),
              ),
              const SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Background',
                subtitle: 'AMOLED uses pure black to save battery',
              ),
              BackgroundVariantPicker(
                selected: themeState.background,
                onSelected: (variant) => ref
                    .read(themeControllerProvider.notifier)
                    .setBackground(variant),
              ),
            ],
          ),

          // --- Account ---
          SettingsSection(
            title: 'Account',
            children: [
              SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Display Name',
                subtitle: profile?.name ?? 'Loading...',
                trailing: Icon(Icons.chevron_right_rounded,
                    color: aether.textMuted),
                onTap: profile == null
                    ? null
                    : () => _editProfileField(
                          title: 'Display Name',
                          currentValue: profile.name,
                          onSave: (value) => ref
                              .read(profileProvider.notifier)
                              .updateProfile(name: value),
                        ),
              ),
              SettingsTile(
                icon: Icons.school_outlined,
                title: 'Role',
                subtitle: profile?.role ?? 'Loading...',
                trailing: Icon(Icons.chevron_right_rounded,
                    color: aether.textMuted),
                onTap: profile == null
                    ? null
                    : () => _editProfileField(
                          title: 'Role',
                          currentValue: profile.role,
                          onSave: (value) => ref
                              .read(profileProvider.notifier)
                              .updateProfile(role: value),
                        ),
              ),
              SettingsTile(
                icon: Icons.alternate_email_rounded,
                title: 'Email',
                subtitle: email,
              ),
              SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                tint: aether.danger,
                onTap: _logout,
              ),
            ],
          ),

          // --- Notifications ---
          SettingsSection(
            title: 'Notifications',
            children: [
              SettingsSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Enable Notifications',
                subtitle: 'Master switch for all reminders',
                value: notifications.enabled,
                onChanged: (v) => ref
                    .read(notificationSettingsProvider.notifier)
                    .setEnabled(v),
              ),
              SettingsSwitchTile(
                icon: Icons.check_circle_outline_rounded,
                title: 'Task Reminders',
                value: notifications.tasks,
                onChanged: notifications.enabled
                    ? (v) => ref
                        .read(notificationSettingsProvider.notifier)
                        .setTasks(v)
                    : null,
              ),
              SettingsSwitchTile(
                icon: Icons.local_fire_department_outlined,
                title: 'Habit Reminders',
                value: notifications.habits,
                onChanged: notifications.enabled
                    ? (v) => ref
                        .read(notificationSettingsProvider.notifier)
                        .setHabits(v)
                    : null,
              ),
              SettingsSwitchTile(
                icon: Icons.menu_book_outlined,
                title: 'Lecture Reminders',
                value: notifications.lectures,
                onChanged: notifications.enabled
                    ? (v) => ref
                        .read(notificationSettingsProvider.notifier)
                        .setLectures(v)
                    : null,
              ),
            ],
          ),

          // --- Data & Sync ---
          SettingsSection(
            title: 'Data & Sync',
            children: [
              SettingsTile(
                icon: Icons.sync_rounded,
                title: 'Sync Now',
                subtitle: 'Last synced: ${_formatLastSynced(lastSynced)}',
                trailing: _isSyncing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: aether.accent,
                        ),
                      )
                    : Icon(Icons.chevron_right_rounded,
                        color: aether.textMuted),
                onTap: _syncNow,
              ),
              SettingsTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Pending Changes',
                subtitle: 'Waiting to upload when online',
                trailing: Text(
                  pendingCount.valueOrNull?.toString() ?? '—',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: (pendingCount.valueOrNull ?? 0) > 0
                        ? aether.accent
                        : aether.textMuted,
                  ),
                ),
              ),
            ],
          ),

          // --- About ---
          SettingsSection(
            title: 'About',
            children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) => SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: snapshot.hasData
                      ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                      : '...',
                ),
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: 'Open Source Licenses',
                trailing: Icon(Icons.chevron_right_rounded,
                    color: aether.textMuted),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'AETHER',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dark-styled single-field edit dialog. Returns the trimmed value, or
/// null if cancelled/empty. Mirrors the first-login dialog's styling.
Future<String?> showEditFieldDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _EditFieldDialog(
      title: title,
      initialValue: initialValue,
    ),
  );
}

class _EditFieldDialog extends StatefulWidget {
  final String title;
  final String initialValue;

  const _EditFieldDialog({
    required this.title,
    required this.initialValue,
  });

  @override
  State<_EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<_EditFieldDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Dialog(
      backgroundColor: aether.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: aether.text,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: aether.text, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: aether.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: aether.textMuted, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: aether.accent,
                    foregroundColor: aether.text,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/database/database.dart'
    show ScheduleTemplate, ScheduleBlock;
import 'package:aether/features/schedule/providers/schedule_providers.dart';
import 'package:aether/features/schedule/widgets/schedule_options.dart';
import 'package:aether/features/schedule/widgets/custom_template_dialog.dart';
import 'package:aether/features/schedule/widgets/block_form_sheet.dart';
import 'package:aether/features/schedule/widgets/block_options_sheet.dart';

/// ---------------------------------------------------------------------
/// AETHER — Daily Schedule screen
/// ---------------------------------------------------------------------
/// Full page, pushed from the Dashboard's "View All" on the Today's
/// Schedule card. Includes its own top bar (back / title / menu) since
/// it differs from DashboardTopBar. Bottom navbar is NOT included here —
/// reuse the existing BottomNavbar widget if this is kept inside the
/// tab shell, otherwise push as a normal full-screen route.
///
/// Offline-first: templates and blocks are read from Drift via
/// templatesProvider / scheduleBlocksProvider. Writes go to Drift first
/// (instant UI update) then sync to Supabase in the background — same
/// pattern as Academics / Tasks.
/// ---------------------------------------------------------------------

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  // Palette — kept consistent with DashboardScreen
  // Fixed semantic colors — categories/priorities keep their meaning.
  static const red = Color(0xFFFF3B30);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFE08A2E);
  static const blue = Color(0xFF3B82F6);
  static const grey = Color(0xFF9A9A9E);

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _dayOffset = 0;

  /// True once the user taps a template card directly — until then (and
  /// again after the viewed date changes) the screen auto-selects
  /// whichever template's repeatDays includes the viewed weekday.
  bool _manualOverride = false;

  static const _weekdayShort = kWeekdayShort;
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTemplates());
  }

  void _syncTemplates() {
    ref.read(scheduleServiceProvider).syncTemplates();
  }

  DateTime get _selectedDate => DateTime.now().add(Duration(days: _dayOffset));

  String _ordinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String get _fullDateLabel {
    final d = _selectedDate;
    return '${d.day}${_ordinalSuffix(d.day)} ${_monthNames[d.month - 1]} ${d.year}';
  }

  String get _dateNavigatorLabel {
    if (_dayOffset == 0) return 'Today';
    if (_dayOffset == -1) return 'Yesterday';
    if (_dayOffset == 1) return 'Tomorrow';
    return _fullDateLabel;
  }

  Set<int> _parseRepeatDays(String csv) => csv
      .split(',')
      .where((s) => s.trim().isNotEmpty)
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .toSet();

  ScheduleTemplate? _findTemplate(List<ScheduleTemplate> templates, String id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _goToPreviousDay() {
    setState(() {
      _dayOffset -= 1;
      _manualOverride = false;
    });
    _recomputeAutoSelection(ref.read(templatesProvider).valueOrNull ?? []);
  }

  void _goToNextDay() {
    setState(() {
      _dayOffset += 1;
      _manualOverride = false;
    });
    _recomputeAutoSelection(ref.read(templatesProvider).valueOrNull ?? []);
  }

  /// Resolves the template whose repeatDays includes the viewed weekday
  /// and, unless the user has manually picked a different template since,
  /// makes it the selected one.
  void _recomputeAutoSelection(List<ScheduleTemplate> templates) {
    if (_manualOverride) return;
    final weekdayIndex = _selectedDate.weekday - 1;
    ScheduleTemplate? match;
    for (final t in templates) {
      if (_parseRepeatDays(t.repeatDays).contains(weekdayIndex)) {
        match = t;
        break;
      }
    }
    final newId = match?.id;
    if (ref.read(selectedTemplateProvider) != newId) {
      ref.read(selectedTemplateProvider.notifier).state = newId;
    }
  }

  void _selectTemplate(String id) {
    setState(() => _manualOverride = true);
    ref.read(selectedTemplateProvider.notifier).state = id;
  }

  Future<void> _onCustomTemplate() async {
    final result = await showCustomTemplateDialog(context);
    if (result == null) return;
    final template = await ref.read(scheduleServiceProvider).createTemplate(
          title: result.title,
          icon: result.icon,
          repeatDays: [_selectedDate.weekday - 1],
        );
    setState(() => _manualOverride = true);
    ref.read(selectedTemplateProvider.notifier).state = template.id;
  }

  void _toggleWeekday(ScheduleTemplate template, int index) {
    final days = _parseRepeatDays(template.repeatDays);
    if (days.contains(index)) {
      days.remove(index);
    } else {
      days.add(index);
    }
    final sorted = days.toList()..sort();
    ref.read(scheduleServiceProvider).updateTemplateRepeatDays(
          template.id,
          sorted,
        );
  }

  Future<void> _onAddTimeBlock(String? templateId) async {
    if (templateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select or create a template first')),
      );
      return;
    }
    final result = await showBlockFormSheet(context);
    if (result == null) return;
    await ref.read(scheduleServiceProvider).createBlock(
          templateId: templateId,
          title: result.title,
          startTime: result.startTime,
          endTime: result.endTime,
          color: result.color,
          icon: result.icon,
        );
  }

  Future<void> _onEditBlock(ScheduleBlock block) async {
    final result = await showBlockFormSheet(
      context,
      initial: BlockFormResult(
        title: block.title,
        startTime: block.startTime,
        endTime: block.endTime,
        color: block.color,
        icon: block.icon,
      ),
    );
    if (result == null) return;
    await ref.read(scheduleServiceProvider).updateBlock(
          block.id,
          title: result.title,
          startTime: result.startTime,
          endTime: result.endTime,
          color: result.color,
          icon: result.icon,
        );
  }

  void _onBlockOptions(ScheduleBlock block) {
    showBlockOptionsSheet(
      context,
      blockTitle: block.title,
      onEdit: () => _onEditBlock(block),
      onDelete: () =>
          ref.read(scheduleServiceProvider).deleteBlock(block.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
    ref.listen<AsyncValue<List<ScheduleTemplate>>>(templatesProvider,
        (previous, next) {
      next.whenData(_recomputeAutoSelection);
    });

    final selectedTemplateId = ref.watch(selectedTemplateProvider);
    ref.listen<String?>(selectedTemplateProvider, (previous, next) {
      if (next != null) {
        ref.read(scheduleServiceProvider).syncBlocks(next);
      }
    });

    final templates = templatesAsync.valueOrNull ?? const <ScheduleTemplate>[];
    final selectedTemplate = selectedTemplateId == null
        ? null
        : _findTemplate(templates, selectedTemplateId);

    final blocksAsync = selectedTemplateId == null
        ? const AsyncValue<List<ScheduleBlock>>.data(<ScheduleBlock>[])
        : ref.watch(scheduleBlocksProvider(selectedTemplateId));
    final blocks = blocksAsync.valueOrNull ?? const <ScheduleBlock>[];

    final totalMinutes = blocks.fold<int>(
      0,
      (sum, b) => sum + minutesBetween(b.startTime, b.endTime),
    );

    return Scaffold(
      backgroundColor: context.aether.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateNavigator(),
                    const SizedBox(height: 18),
                    _buildTemplateSection(templates, selectedTemplateId),
                    const SizedBox(height: 16),
                    _buildTemplateSettingsCard(selectedTemplate),
                    const SizedBox(height: 18),
                    _buildSchedulePreviewHeader(totalMinutes),
                    const SizedBox(height: 12),
                    _buildTimeline(selectedTemplate, blocks),
                    const SizedBox(height: 12),
                    _buildActionRow(
                      icon: Icons.add_circle_outline,
                      iconColor: context.aether.accent,
                      title: 'Add New Time Block',
                      subtitle: 'Add task, break, or custom activity',
                      onTap: () => _onAddTimeBlock(selectedTemplateId),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.aether.text,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              'DAILY SCHEDULE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.aether.text,
                fontSize: 15,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.more_vert, color: context.aether.text, size: 22),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Date navigator
  // ---------------------------------------------------------------------
  Widget _buildDateNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navArrow(Icons.chevron_left, _goToPreviousDay),
        Column(
          children: [
            Text(
              _dateNavigatorLabel,
              style: TextStyle(
                color: context.aether.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _fullDateLabel,
              style: TextStyle(color: context.aether.textMuted, fontSize: 11),
            ),
          ],
        ),
        _navArrow(Icons.chevron_right, _goToNextDay),
      ],
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.aether.card,
          shape: BoxShape.circle,
          border: Border.all(color: context.aether.border),
        ),
        child: Icon(icon, color: context.aether.text, size: 18),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Choose Template — dynamic templates + a single trailing Custom
  // Template card. "Manage Templates" removed.
  // ---------------------------------------------------------------------
  Widget _buildTemplateSection(
    List<ScheduleTemplate> templates,
    String? selectedTemplateId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Template',
          style: TextStyle(
            color: context.aether.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isCustomCard = index == templates.length;

              if (isCustomCard) {
                return GestureDetector(
                  onTap: _onCustomTemplate,
                  child: Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.aether.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.aether.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: context.aether.textMuted, size: 20),
                        SizedBox(height: 6),
                        Text(
                          'Custom Template',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.aether.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final template = templates[index];
              final selected = template.id == selectedTemplateId;
              return GestureDetector(
                onTap: () => _selectTemplate(template.id),
                child: Container(
                  width: 78,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.aether.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          selected ? context.aether.accent : context.aether.border,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (selected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(Icons.check_circle,
                              color: context.aether.accent, size: 14),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            iconForKey(template.icon),
                            color: selected
                                ? context.aether.accent
                                : context.aether.textMuted,
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            template.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? context.aether.accent
                                  : context.aether.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Template Settings card
  // ---------------------------------------------------------------------
  Widget _buildTemplateSettingsCard(ScheduleTemplate? template) {
    if (template == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.aether.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.aether.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.aether.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.calendar_today_outlined,
                  color: context.aether.accent, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No template selected — tap Custom Template to create one.',
                style: TextStyle(color: context.aether.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final selectedDays = _parseRepeatDays(template.repeatDays);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.aether.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.aether.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.aether.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconForKey(template.icon),
                    color: context.aether.accent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Settings',
                      style: TextStyle(
                        color: context.aether.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      template.title,
                      style: TextStyle(
                          color: context.aether.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Repeat on',
                    style: TextStyle(color: context.aether.textMuted, fontSize: 10),
                  ),
                  Text(
                    repeatDaysLabel(template.repeatDays),
                    style: TextStyle(
                      color: context.aether.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_weekdayShort.length, (index) {
              final selected = selectedDays.contains(index);
              final isWeekend = index >= 5;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _toggleWeekday(template, index),
                  child: Container(
                    margin: EdgeInsets.only(right: index == 6 ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? ScheduleScreen.red.withOpacity(0.15)
                          : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? context.aether.accent
                            : context.aether.border,
                      ),
                    ),
                    child: Text(
                      _weekdayShort[index],
                      style: TextStyle(
                        color: selected
                            ? context.aether.accent
                            : (isWeekend
                                ? context.aether.textMuted
                                : context.aether.text.withValues(alpha: 0.7)),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Schedule Preview header
  // ---------------------------------------------------------------------
  Widget _buildSchedulePreviewHeader(int totalMinutes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, color: context.aether.text, size: 16),
            SizedBox(width: 6),
            Text(
              'Schedule Preview',
              style: TextStyle(
                color: context.aether.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          formatTotalDuration(totalMinutes),
          style: TextStyle(color: context.aether.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Timeline
  // ---------------------------------------------------------------------
  Widget _buildTimeline(
    ScheduleTemplate? template,
    List<ScheduleBlock> blocks,
  ) {
    if (template == null) {
      return const _TimelineEmptyState(
        message: 'Select or create a template to see its schedule.',
      );
    }
    if (blocks.isEmpty) {
      return const _TimelineEmptyState(
        message: 'No time blocks yet — tap "Add New Time Block" below.',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: List.generate(blocks.length, (index) {
          final block = blocks[index];
          final isLast = index == blocks.length - 1;
          final color = colorForHex(block.color);
          final durationLabel =
              formatDuration(minutesBetween(block.startTime, block.endTime));
          final timeRangeLabel =
              '${formatTimeInline(block.startTime)} – ${formatTimeInline(block.endTime)}';

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline rail
                Column(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(top: 6),
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                            width: 1.4, color: context.aether.border),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                // Time label
                SizedBox(
                  width: 40,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 12),
                    child: Text(
                      formatTimeLabel(block.startTime),
                      style: TextStyle(
                          color: context.aether.textMuted, fontSize: 10, height: 1.2),
                    ),
                  ),
                ),
                // Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.aether.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.aether.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(iconForKey(block.icon),
                                color: color, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  block.title,
                                  style: TextStyle(
                                    color: context.aether.text,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  timeRangeLabel,
                                  style: TextStyle(
                                      color: context.aether.textMuted,
                                      fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              durationLabel,
                              style: TextStyle(
                                  color: context.aether.textMuted, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _onBlockOptions(block),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(Icons.more_vert,
                                  color: context.aether.textMuted, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Action row (Add New Time Block)
  // ---------------------------------------------------------------------
  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.aether.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.aether.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.aether.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style:
                        TextStyle(color: context.aether.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.aether.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  final String message;
  const _TimelineEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.aether.textMuted, fontSize: 12.5),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// AETHER — Daily Schedule screen
/// ---------------------------------------------------------------------
/// Full page, pushed from the Dashboard's "View All" on the Today's
/// Schedule card. Includes its own top bar (back / title / menu) since
/// it differs from DashboardTopBar. Bottom navbar is NOT included here —
/// reuse the existing BottomNavbar widget if this is kept inside the
/// tab shell, otherwise push as a normal full-screen route.
/// ---------------------------------------------------------------------

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  // Palette — kept consistent with DashboardScreen
  static const bg = Color(0xFF000000);
  static const card = Color(0xFF121212);
  static const cardBorder = Color(0xFF262626);
  static const red = Color(0xFFFF3B30);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFE08A2E);
  static const blue = Color(0xFF3B82F6);
  static const grey = Color(0xFF9A9A9E);
  static const white = Color(0xFFF5F5F5);
  static const white54 = Color(0xB3F5F5F5);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _dayOffset = 0;
  int _selectedTemplateIndex = 0;

  final Set<int> _selectedWeekdays = {0, 1, 2, 3, 4}; // Mon–Fri

  final List<_TemplateData> _templates = const [
    _TemplateData(label: 'Study Day', icon: Icons.school_outlined),
    _TemplateData(label: 'Rest Day', icon: Icons.weekend_outlined),
    _TemplateData(label: 'Travel Day', icon: Icons.card_travel_outlined),
    _TemplateData(label: 'Exam Day', icon: Icons.track_changes_outlined),
    _TemplateData(label: 'Custom', icon: Icons.add),
  ];

  final List<_ScheduleBlockData> _blocks = const [
    _ScheduleBlockData(
      time: '5:00\nAM',
      title: 'Wake Up',
      subtitle: 'Start your day',
      icon: Icons.wb_sunny_outlined,
      color: ScheduleScreen.red,
      duration: '15m',
    ),
    _ScheduleBlockData(
      time: '5:15\nAM',
      title: 'Morning Run',
      subtitle: 'Cardio & Warmup',
      icon: Icons.directions_run_rounded,
      color: ScheduleScreen.red,
      duration: '45m',
    ),
    _ScheduleBlockData(
      time: '6:00\nAM',
      title: 'Shower & Freshen Up',
      subtitle: 'Get ready',
      icon: Icons.shower_outlined,
      color: ScheduleScreen.orange,
      duration: '30m',
    ),
    _ScheduleBlockData(
      time: '6:30\nAM',
      title: 'Meditation',
      subtitle: 'Mindfulness',
      icon: Icons.self_improvement,
      color: ScheduleScreen.orange,
      duration: '20m',
    ),
    _ScheduleBlockData(
      time: '7:00\nAM',
      title: 'Study Session 1',
      subtitle: 'Physics',
      icon: Icons.menu_book_outlined,
      color: ScheduleScreen.purple,
      duration: '2h 00m',
    ),
    _ScheduleBlockData(
      time: '9:00\nAM',
      title: 'Short Break',
      subtitle: 'Relax & Recharge',
      icon: Icons.local_cafe_outlined,
      color: ScheduleScreen.blue,
      duration: '15m',
    ),
    _ScheduleBlockData(
      time: '9:15\nAM',
      title: 'Study Session 2',
      subtitle: 'Mathematics',
      icon: Icons.menu_book_outlined,
      color: ScheduleScreen.purple,
      duration: '2h 00m',
    ),
    _ScheduleBlockData(
      time: '11:15\nAM',
      title: 'Lunch',
      subtitle: 'Eat healthy',
      icon: Icons.restaurant_outlined,
      color: ScheduleScreen.green,
      duration: '45m',
    ),
  ];

  static const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

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

  String get _totalDurationLabel {
    // Sums the mock durations above → static label for now.
    return '8h 45m Total';
  }

  void _goToPreviousDay() => setState(() => _dayOffset -= 1);
  void _goToNextDay() => setState(() => _dayOffset += 1);

  void _toggleWeekday(int index) {
    setState(() {
      if (_selectedWeekdays.contains(index)) {
        _selectedWeekdays.remove(index);
      } else {
        _selectedWeekdays.add(index);
      }
    });
  }

  void _onAddTimeBlock() {
    // TODO: open add time block sheet
  }

  void _onOptimizeSchedule() {
    // TODO: trigger AI schedule optimization
  }

  void _onManageTemplates() {
    // TODO: navigate to template management
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScheduleScreen.bg,
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
                    _buildTemplateSection(),
                    const SizedBox(height: 16),
                    _buildTemplateSettingsCard(),
                    const SizedBox(height: 18),
                    _buildSchedulePreviewHeader(),
                    const SizedBox(height: 12),
                    _buildTimeline(),
                    const SizedBox(height: 12),
                    _buildActionRow(
                      icon: Icons.add_circle_outline,
                      iconColor: ScheduleScreen.red,
                      title: 'Add New Time Block',
                      subtitle: 'Add task, break, or custom activity',
                      onTap: _onAddTimeBlock,
                    ),
                    const SizedBox(height: 10),
                    _buildActionRow(
                      icon: Icons.auto_awesome,
                      iconColor: ScheduleScreen.red,
                      title: 'Optimize Schedule',
                      subtitle: 'AI helps you balance your day better',
                      onTap: _onOptimizeSchedule,
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
  child: const Icon(
    Icons.arrow_back_ios_new_rounded,
    color: ScheduleScreen.white,
    size: 20,
  ),
),
          const Expanded(
            child: Text(
              'DAILY SCHEDULE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ScheduleScreen.white,
                fontSize: 15,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.more_vert, color: ScheduleScreen.white, size: 22),
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
              style: const TextStyle(
                color: ScheduleScreen.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _fullDateLabel,
              style: const TextStyle(color: ScheduleScreen.grey, fontSize: 11),
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
          color: ScheduleScreen.card,
          shape: BoxShape.circle,
          border: Border.all(color: ScheduleScreen.cardBorder),
        ),
        child: Icon(icon, color: ScheduleScreen.white, size: 18),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Choose Template
  // ---------------------------------------------------------------------
  Widget _buildTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Choose Template',
              style: TextStyle(
                color: ScheduleScreen.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: _onManageTemplates,
              child: const Row(
                children: [
                  Text(
                    'Manage Templates',
                    style: TextStyle(color: ScheduleScreen.red, fontSize: 11),
                  ),
                  Icon(Icons.chevron_right, color: ScheduleScreen.red, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final template = _templates[index];
              final selected = _selectedTemplateIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedTemplateIndex = index),
                child: Container(
                  width: 78,
                  padding: const EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 6,
  ),
                  decoration: BoxDecoration(
                    color: ScheduleScreen.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? ScheduleScreen.red : ScheduleScreen.cardBorder,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (selected)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(Icons.check_circle, color: ScheduleScreen.red, size: 14),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            template.icon,
                            color: selected ? ScheduleScreen.red : ScheduleScreen.grey,
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            template.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? ScheduleScreen.red : ScheduleScreen.grey,
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
  Widget _buildTemplateSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ScheduleScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScheduleScreen.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ScheduleScreen.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_outlined, color: ScheduleScreen.red, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Template Settings',
                      style: TextStyle(
                        color: ScheduleScreen.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _templates[_selectedTemplateIndex].label,
                      style: const TextStyle(color: ScheduleScreen.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Repeat on',
                    style: TextStyle(color: ScheduleScreen.grey, fontSize: 10),
                  ),
                  Row(
                    children: const [
                      Text(
                        'Weekdays (Mon – Fri)',
                        style: TextStyle(
                          color: ScheduleScreen.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: ScheduleScreen.red, size: 14),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_weekdayShort.length, (index) {
              final selected = _selectedWeekdays.contains(index);
              final isWeekend = index >= 5;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _toggleWeekday(index),
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
                        color: selected ? ScheduleScreen.red : ScheduleScreen.cardBorder,
                      ),
                    ),
                    child: Text(
                      _weekdayShort[index],
                      style: TextStyle(
                        color: selected
                            ? ScheduleScreen.red
                            : (isWeekend ? ScheduleScreen.grey : ScheduleScreen.white54),
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
  Widget _buildSchedulePreviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.schedule, color: ScheduleScreen.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Schedule Preview',
              style: TextStyle(
                color: ScheduleScreen.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          _totalDurationLabel,
          style: const TextStyle(color: ScheduleScreen.grey, fontSize: 11),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Timeline
  // ---------------------------------------------------------------------
  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: List.generate(_blocks.length, (index) {
          final block = _blocks[index];
          final isLast = index == _blocks.length - 1;
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
                      decoration: BoxDecoration(shape: BoxShape.circle, color: block.color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(width: 1.4, color: ScheduleScreen.cardBorder),
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
                      block.time,
                      style: const TextStyle(color: ScheduleScreen.grey, fontSize: 10, height: 1.2),
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
                        color: ScheduleScreen.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ScheduleScreen.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: block.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(block.icon, color: block.color, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  block.title,
                                  style: const TextStyle(
                                    color: ScheduleScreen.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  block.subtitle,
                                  style: const TextStyle(color: ScheduleScreen.grey, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              block.duration,
                              style: const TextStyle(color: ScheduleScreen.grey, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.more_vert, color: ScheduleScreen.grey, size: 15),
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
  // Action row (Add Time Block / Optimize Schedule)
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
          color: ScheduleScreen.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ScheduleScreen.cardBorder),
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
                    style: const TextStyle(
                      color: ScheduleScreen.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: ScheduleScreen.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ScheduleScreen.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TemplateData {
  final String label;
  final IconData icon;
  const _TemplateData({required this.label, required this.icon});
}

class _ScheduleBlockData {
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String duration;

  const _ScheduleBlockData({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.duration,
  });
}
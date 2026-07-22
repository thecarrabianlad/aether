import 'package:flutter/material.dart';
import 'package:aether/features/academics/widgets/course_summary_card.dart';
import 'package:aether/features/academics/widgets/upcoming_lecture_tile.dart';
import 'package:aether/features/academics/widgets/due_assignment_tile.dart';
import 'package:aether/features/academics/widgets/quick_access_button.dart';
import 'package:aether/widgets/dashboard_top_bar.dart';

class AcademicsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;
  const AcademicsScreen({super.key, this.onMenuTap, this.onProfileTap});

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  int _selectedTab = 0;
  String? _selectedCourseId;

  static const Color _accentRed = Color(0xFFE8443F);
  static const Color _accentGreen = Color(0xFF34C759);
  static const Color _accentOrange = Color(0xFFE08A2E);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _accentPurple = Color(0xFF8B5CF6);

  // --- Mock data ---
  final List<Map<String, dynamic>> _courses = [
    {'id': '1', 'name': 'Physics', 'professor': 'Dr. Smith', 'time': '9:00 AM', 'room': 'B12', 'progress': 0.68, 'color': _accentPurple},
    {'id': '2', 'name': 'Mathematics', 'professor': 'Dr. John', 'time': '11:30 AM', 'room': 'A5', 'progress': 0.45, 'color': _accentOrange},
    {'id': '3', 'name': 'Computer Sci.', 'professor': 'Dr. Lee', 'time': '3:00 PM', 'room': 'C2', 'progress': 0.32, 'color': _accentBlue},
    {'id': '4', 'name': 'Chemistry', 'professor': 'Dr. Patel', 'time': '8:00 AM', 'room': 'Lab 3', 'progress': 0.80, 'color': _accentGreen},
  ];

  final List<Map<String, dynamic>> _lectures = [
    {'title': 'Wave Optics', 'chapter': 'Ch. 10', 'tag': 'Ongoing', 'time': '9:00 AM', 'color': _accentPurple},
    {'title': 'Electrostatics', 'chapter': 'Ch. 2', 'tag': 'Upcoming', 'time': '11:30 AM', 'color': _accentPurple},
    {'title': 'Semiconductors', 'chapter': 'Ch. 14', 'tag': 'Upcoming', 'time': '3:00 PM', 'color': _accentPurple},
  ];

  final List<Map<String, dynamic>> _assignments = [
    {'title': 'Physics Problem Set 4', 'dueDate': 'Due: 18th Aug', 'daysLeft': '6 Days Left', 'color': _accentRed},
    {'title': 'Physics Lab Report', 'dueDate': 'Due: 20th Aug', 'daysLeft': '8 Days Left', 'color': _accentRed},
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.notes_rounded, 'label': 'All Notes', 'color': _accentGreen},
    {'icon': Icons.assignment_rounded, 'label': 'Past Papers', 'color': _accentOrange},
    {'icon': Icons.timer_rounded, 'label': 'Pomodoro', 'color': _accentRed},
    {'icon': Icons.auto_stories_rounded, 'label': 'Flashcards', 'color': _accentBlue},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            DashboardTopBar(
              onMenuTap: widget.onMenuTap ?? () {},
              onProfileTap: widget.onProfileTap ?? () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildCourseCards(),
                    const SizedBox(height: 20),
                    _buildTabSelector(),
                    const SizedBox(height: 20),
                    if (_selectedTab == 0) _buildMyCoursesView(),
                    if (_selectedTab == 1) _buildTimetableView(),
                    const SizedBox(height: 24),
                    _buildQuickAccessBar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Academics',
            style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('Manage courses, lectures & assignments.',
            style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 14)),
      ],
    );
  }

  Widget _buildCourseCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Courses',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () => _showAddCourseDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: _accentRed, size: 16),
                    SizedBox(width: 4),
                    Text('Add Course',
                        style: TextStyle(
                            color: _accentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _courses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final c = _courses[index];
              return CourseSummaryCard(
                courseName: c['name'],
                professor: c['professor'],
                time: c['time'],
                room: c['room'],
                progress: c['progress'],
                accentColor: c['color'],
                onTap: () => setState(() => _selectedCourseId = c['id']),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Row(
      children: [
        _buildTab('My Courses', 0),
        const SizedBox(width: 12),
        _buildTab('Timetable', 1),
      ],
    );
  }

  Widget _buildTab(String title, int index) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accentRed : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(title,
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _buildMyCoursesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upcoming Lectures',
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ..._lectures.map((l) => UpcomingLectureTile(
              title: l['title'],
              chapter: l['chapter'],
              tag: l['tag'],
              time: l['time'],
              accentColor: l['color'],
            )),
        const SizedBox(height: 20),
        const Text('Due Assignments',
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ..._assignments.map((a) => DueAssignmentTile(
              title: a['title'],
              dueDate: a['dueDate'],
              daysLeft: a['daysLeft'],
              color: a['color'],
            )),
      ],
    );
  }

  Widget _buildTimetableView() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: const Text('Timetable view coming soon.',
          style: TextStyle(color: Color(0xFF9A9A9E))),
    );
  }

  Widget _buildQuickAccessBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Access',
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: _quickActions.map((a) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: QuickAccessButton(
                  icon: a['icon'],
                  label: a['label'],
                  color: a['color'],
                  onTap: () {},
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Add Course', style: TextStyle(color: Colors.white)),
        content: const Text('Course creation form will go here.',
            style: TextStyle(color: Color(0xFF9A9A9E))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Add')),
        ],
      ),
    );
  }
}
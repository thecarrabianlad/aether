import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/features/academics/providers/academics_providers.dart';
import 'package:aether/features/academics/widgets/course_summary_card.dart';
import 'package:aether/features/academics/widgets/upcoming_lecture_tile.dart';
import 'package:aether/features/academics/widgets/due_assignment_tile.dart';
import 'package:aether/features/academics/widgets/quick_access_button.dart';
import 'package:aether/core/database/tables/courses.dart';
import 'package:aether/core/database/tables/lectures.dart';
import 'package:aether/core/database/tables/assignments.dart';
import 'package:aether/widgets/dashboard_top_bar.dart';
import 'package:intl/intl.dart';

class AcademicsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;
  const AcademicsScreen({super.key, this.onMenuTap, this.onProfileTap});

  @override
  ConsumerState<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends ConsumerState<AcademicsScreen> {
  int _selectedTab = 0;

  static const _accentRed = Color(0xFFE8443F);
  static const _accentGreen = Color(0xFF34C759);
  static const _accentOrange = Color(0xFFE08A2E);
  static const _accentBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

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
                    _buildCourseCards(coursesAsync),
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
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('Manage courses, lectures & assignments.',
            style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 14)),
      ],
    );
  }

  Widget _buildCourseCards(AsyncValue<List<Course>> asyncCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Courses',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () => _showAddCourseDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: _accentRed, size: 16),
                    SizedBox(width: 4),
                    Text('Add Course',
                        style: TextStyle(color: _accentRed, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        asyncCourses.when(
          data: (courses) => courses.isEmpty
              ? _buildEmptyCourses()
              : SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final c = courses[index];
                      final color = _colorFromHex(c.color);
                      return CourseSummaryCard(
                        courseName: c.name,
                        professor: c.professor ?? 'No instructor',
                        time: _formatTime(c.scheduleStart),
                        room: c.location ?? 'TBD',
                        progress: 0.0,
                        accentColor: color,
                        onTap: () => ref.read(selectedCourseProvider.notifier).state = c,
                      );
                    },
                  ),
                ),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator(color: _accentRed)),
          ),
          error: (e, _) => SizedBox(
            height: 200,
            child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, color: Color(0xFF5A5A5E), size: 40),
            const SizedBox(height: 12),
            const Text('No courses added yet.',
                style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 14)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showAddCourseDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _accentRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('+ Add your first course',
                    style: TextStyle(color: _accentRed, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
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
    final selectedCourse = ref.watch(selectedCourseProvider);
    if (selectedCourse == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const Text('Select a course to view details.',
            style: TextStyle(color: Color(0xFF9A9A9E))),
      );
    }

    final lecturesAsync = ref.watch(lecturesProvider(selectedCourse.id));
    final assignmentsAsync = ref.watch(assignmentsProvider(selectedCourse.id));
    final color = _colorFromHex(selectedCourse.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(selectedCourse.name,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Color(0xFF9A9A9E)),
              color: const Color(0xFF1C1C1E),
              onSelected: (value) {
                if (value == 'edit') _showEditCourseDialog(selectedCourse);
                if (value == 'delete') _confirmDelete(selectedCourse);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit Course', style: TextStyle(color: Colors.white))),
                PopupMenuItem(value: 'delete', child: Text('Delete Course', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
        if (selectedCourse.professor != null)
          Text(selectedCourse.professor!,
              style: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 13)),
        const SizedBox(height: 20),
        const Text('Upcoming Lectures',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        lecturesAsync.when(
          data: (lectures) => lectures.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("You're all caught up.", style: TextStyle(color: Color(0xFF9A9A9E))))
              : Column(
                  children: lectures.map((l) => UpcomingLectureTile(
                    title: l.title,
                    chapter: l.chapter ?? '',
                    tag: l.tag ?? 'Upcoming',
                    time: _formatDateTime(l.scheduledAt),
                    accentColor: color,
                    isCompleted: l.isCompleted,
                    onCompletionChanged: (val) {
                      ref.read(academicsServiceProvider).toggleLectureCompletion(l.id, val);
                    },
                  )).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Colors.red))),
        ),
        const SizedBox(height: 20),
        const Text('Due Assignments',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        assignmentsAsync.when(
          data: (assignments) => assignments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No assignments due.', style: TextStyle(color: Color(0xFF9A9A9E))),
              )
              : Column(
                  children: assignments.map((a) => DueAssignmentTile(
                    title: a.title,
                    dueDate: 'Due: ${DateFormat('dd MMM').format(a.dueDate!)}',
                    daysLeft: _daysLeft(a.dueDate),
                    color: _accentRed,
                    isCompleted: a.isCompleted,
                    onCompletionChanged: (val) {
                      ref.read(academicsServiceProvider).toggleAssignmentCompletion(a.id, val);
                    },
                  )).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        ),
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
    final actions = [
      (Icons.notes_rounded, 'All Notes', _accentGreen),
      (Icons.assignment_rounded, 'Past Papers', _accentOrange),
      (Icons.timer_rounded, 'Pomodoro', _accentRed),
      (Icons.auto_stories_rounded, 'Flashcards', _accentBlue),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Access',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: actions.map((a) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: QuickAccessButton(
                icon: a.$1, label: a.$2, color: a.$3, onTap: () {},
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ── Dialogs ──────────────────────────

  void _showAddCourseDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final profCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final semCtrl = TextEditingController();
    Color selectedColor = const Color(0xFF8B5CF6);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Add Course', style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField('Course Name *', nameCtrl, required: true),
                  _buildField('Course Code', codeCtrl),
                  _buildField('Professor', profCtrl),
                  _buildField('Location', locCtrl),
                  _buildField('Semester', semCtrl),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Color:', style: TextStyle(color: Color(0xFF9A9A9E))),
                      const SizedBox(width: 12),
                      ..._colorOptions.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: c, shape: BoxShape.circle,
                              border: selectedColor == c ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await ref.read(academicsServiceProvider).createCourse(
                  name: nameCtrl.text,
                  code: codeCtrl.text.isEmpty ? null : codeCtrl.text,
                  professor: profCtrl.text.isEmpty ? null : profCtrl.text,
                  location: locCtrl.text.isEmpty ? null : locCtrl.text,
                  semester: semCtrl.text.isEmpty ? null : semCtrl.text,
                  color: '#${selectedColor.value.toRadixString(16).substring(2)}',
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: _accentRed)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCourseDialog(Course course) {
    final nameCtrl = TextEditingController(text: course.name);
    final codeCtrl = TextEditingController(text: course.code ?? '');
    final profCtrl = TextEditingController(text: course.professor ?? '');
    final locCtrl = TextEditingController(text: course.location ?? '');
    final semCtrl = TextEditingController(text: course.semester ?? '');
    Color selectedColor = _colorFromHex(course.color);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Edit Course', style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField('Course Name *', nameCtrl, required: true),
                  _buildField('Course Code', codeCtrl),
                  _buildField('Professor', profCtrl),
                  _buildField('Location', locCtrl),
                  _buildField('Semester', semCtrl),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Color:', style: TextStyle(color: Color(0xFF9A9A9E))),
                      const SizedBox(width: 12),
                      ..._colorOptions.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: c, shape: BoxShape.circle,
                              border: selectedColor == c ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await ref.read(academicsServiceProvider).updateCourse(course.copyWith(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.isEmpty ? null : codeCtrl.text,
                  professor: profCtrl.text.isEmpty ? null : profCtrl.text,
                  location: locCtrl.text.isEmpty ? null : locCtrl.text,
                  semester: semCtrl.text.isEmpty ? null : semCtrl.text,
                  color: '#${selectedColor.value.toRadixString(16).substring(2)}',
                ));
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: _accentRed)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Course course) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Course', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${course.name}" and all its lectures, assignments, notes, and flashcards?',
            style: const TextStyle(color: Color(0xFF9A9A9E))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(academicsServiceProvider).deleteCourse(course.id);
              if (mounted) {
                ref.read(selectedCourseProvider.notifier).state = null;
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  // ── Helpers ──────────────────────────

  static const _colorOptions = [
    Color(0xFF8B5CF6), Color(0xFFE8443F), Color(0xFF34C759),
    Color(0xFFE08A2E), Color(0xFF3B82F6), Color(0xFF0A84FF),
  ];

  Color _colorFromHex(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  Color? _colorProfile(String color) => Color(int.parse(color.replaceFirst('#', '0xFF')));

  String _formatDateTime(DateTime? dt) =>
      dt == null ? '' : DateFormat('h:mm a').format(dt.toLocal());

  String _formatTime(String? ts) {
    if (ts == null) return 'TBD';
    try {
      return DateFormat('h:mm a').format(DateFormat('HH:mm').parse(ts));
    } catch (_) {
      return ts;
    }
  }

  String _daysLeft(DateTime? due) {
    if (due == null) return '';
    final diff = due.difference(DateTime.now()).inDays;
    return diff == 0 ? 'Today' : '$diff Days Left';
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:aether/core/providers.dart';
import 'package:aether/features/academics/providers/academics_providers.dart';
import 'package:aether/features/academics/widgets/course_summary_card.dart';
import 'package:aether/features/academics/widgets/upcoming_lecture_tile.dart';
import 'package:aether/features/academics/widgets/due_assignment_tile.dart';
import 'package:aether/features/academics/widgets/quick_access_button.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/widgets/dashboard_top_bar.dart';

class AcademicsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onProfileTap;
  const AcademicsScreen({super.key, this.onProfileTap});

  @override
  ConsumerState<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends ConsumerState<AcademicsScreen> {
  int _selectedTab = 0;
  bool _isSyncing = false;

  static const _red = Color(0xFFE8443F);
  static const _green = Color(0xFF34C759);
  static const _orange = Color(0xFFE08A2E);
  static const _blue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startSync();
      }
    });
  }

  Future<void> _startSync() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(academicsServiceProvider).syncCourses();
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

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
              onMenuTap: () => ref.read(drawerProvider.notifier).state = true,
              onProfileTap: widget.onProfileTap ?? () {},
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _startSync,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _selectedTab == 0
                            ? _buildMyCoursesView()
                            : _buildTimetableView(),
                      ),
                      const SizedBox(height: 24),
                      _buildQuickAccessBar(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Academics',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
            ),
            if (_isSyncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('Manage courses, lectures & assignments.',
            style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 14)),
      ],
    );
  }

  // ── Course Cards ──────────────────────────────────

  Widget _buildCourseCards(AsyncValue<List<Course>> asyncCourses) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: _red, size: 16),
                    SizedBox(width: 4),
                    Text('Add Course',
                        style: TextStyle(
                            color: _red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
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
                      return _CourseCardWithProgress(
                        course: c,
                        onTap: () {
                          final service = ref.read(academicsServiceProvider);
                          service.syncLectures(c.id);
                          service.syncAssignments(c.id);
                          ref.read(selectedCourseProvider.notifier).state = c;
                        },
                      );
                    },
                  ),
                ),
          loading: () => const SizedBox(
            height: 200,
            child:
                Center(child: CircularProgressIndicator(color: _red)),
          ),
          error: (e, _) => _buildError('Error loading courses: $e'),
        ),
      ],
    );
  }

  Widget _buildEmptyCourses() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined,
                color: Color(0xFF5A5A5E), size: 48),
            const SizedBox(height: 16),
            const Text('No courses added yet.',
                style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 16)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showAddCourseDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('+ Add your first course',
                    style: TextStyle(
                        color: _red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _red : const Color(0xFF1C1C1E),
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

  // ── My Courses Detail View ────────────────────────

  Widget _buildMyCoursesView() {
    final selectedCourse = ref.watch(selectedCourseProvider);
    if (selectedCourse == null) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app_outlined,
                color: Color(0xFF5A5A5E), size: 48),
            const SizedBox(height: 16),
            const Text('Select a course from above',
                style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 16)),
          ],
        ),
      );
    }

    return _CourseDetailView(
      course: selectedCourse,
      onEdit: () => _showEditCourseDialog(selectedCourse),
      onDelete: () => _confirmDelete(selectedCourse),
      onAddLecture: () => _showAddLectureDialog(selectedCourse.id),
      onAddAssignment: () => _showAddAssignmentDialog(selectedCourse.id),
    );
  }

  Widget _buildTimetableView() {
    final coursesAsync = ref.watch(coursesProvider);
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      key: const ValueKey('timetable'),
      child: coursesAsync.when(
        data: (courses) {
          final scheduled = courses.where((c) => c.scheduleDays != null && c.scheduleDays!.isNotEmpty).toList();
          if (scheduled.isEmpty) {
            return Container(
              height: 300,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      color: Color(0xFF5A5A5E), size: 48),
                  const SizedBox(height: 16),
                  const Text('No courses with schedule set.',
                      style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Edit a course to add schedule days.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            );
          }

          final timeSlots = <String>[];
          for (final c in scheduled) {
            if (c.scheduleStart != null && !timeSlots.contains(c.scheduleStart)) {
              timeSlots.add(c.scheduleStart!);
            }
            if (c.scheduleEnd != null && !timeSlots.contains(c.scheduleEnd)) {
              timeSlots.add(c.scheduleEnd!);
            }
          }
          timeSlots.sort();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Weekly Schedule',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 120 + daysOfWeek.length * 100.0,
                  child: Column(
                    children: [
                      // Header row
                      Row(
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Time',
                                  style: TextStyle(
                                      color: Color(0xFF9A9A9E),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          ...daysOfWeek.map((d) => SizedBox(
                                width: 100,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(d,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Color(0xFF9A9A9E),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              )),
                        ],
                      ),
                      const Divider(color: Color(0xFF2C2C2E), height: 1),
                      // Time rows
                      ...timeSlots.map((time) {
                        final rowCourses = scheduled.where((c) =>
                            c.scheduleStart == time ||
                            c.scheduleEnd == time);
                        return Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(time,
                                        style: const TextStyle(
                                            color: Color(0xFF9A9A9E),
                                            fontSize: 11)),
                                  ),
                                ),
                                ...daysOfWeek.map((d) {
                                  final dayMatch = rowCourses.where((c) =>
                                      c.scheduleDays!
                                          .split(',')
                                          .map((s) => s.trim().toLowerCase())
                                          .any((sd) => sd.startsWith(d.toLowerCase())));
                                  final course = dayMatch.isNotEmpty
                                      ? dayMatch.first
                                      : null;
                                  return SizedBox(
                                    width: 100,
                                    child: course != null
                                        ? Container(
                                            margin:
                                                const EdgeInsets.all(3),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Color(int.parse(
                                                      course.color
                                                          .replaceFirst(
                                                              '#', '0xFF')))
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Color(int.parse(
                                                        course.color
                                                            .replaceFirst(
                                                                '#', '0xFF')))
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              course.name,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  );
                                }),
                              ],
                            ),
                            const Divider(
                                color: Color(0xFF2C2C2E), height: 1),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 300,
          child: Center(
              child: CircularProgressIndicator(color: _red)),
        ),
        error: (e, _) => _buildError('Error loading courses: $e'),
      ),
    );
  }

  Widget _buildQuickAccessBar() {
    final actions = [
      (Icons.notes_rounded, 'All Notes', _green, 'Notes coming soon'),
      (Icons.assignment_rounded, 'Past Papers', _orange, 'Past papers coming soon'),
      (Icons.timer_rounded, 'Pomodoro', _red, 'Pomodoro timer coming soon'),
      (Icons.auto_stories_rounded, 'Flashcards', _blue, 'Flashcards coming soon'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Access',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: actions
              .map((a) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: QuickAccessButton(
                        icon: a.$1,
                        label: a.$2,
                        color: a.$3,
                        onTap: () => _showSnack(a.$4),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFE8443F), size: 40),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────

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
          title:
              const Text('Add Course', style: TextStyle(color: Colors.white)),
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
                  _ColorPicker(
                      selectedColor: selectedColor,
                      onChanged: (c) =>
                          setDialogState(() => selectedColor = c)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  if (mounted) _showSnack('Course name is required.');
                  return;
                }
                try {
                  await ref.read(academicsServiceProvider).createCourse(
                        name: nameCtrl.text.trim(),
                        code: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                        professor: profCtrl.text.trim().isEmpty ? null : profCtrl.text.trim(),
                        location: locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim(),
                        semester: semCtrl.text.trim().isEmpty ? null : semCtrl.text.trim(),
                        color: '#${selectedColor.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}',
                      );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) _showSnack('Failed to add course: $e');
                }
              },
              child:
                  const Text('Add', style: TextStyle(color: _red)),
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
    Color selectedColor = _hexToColor(course.color);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title:
              const Text('Edit Course', style: TextStyle(color: Colors.white)),
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
                  _ColorPicker(
                      selectedColor: selectedColor,
                      onChanged: (c) =>
                          setDialogState(() => selectedColor = c)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await ref
                    .read(academicsServiceProvider)
                    .updateCourse(course.copyWith(
                      name: nameCtrl.text.trim(),
                      code: codeCtrl.text.isEmpty
                          ? const Value.absent()
                          : Value(codeCtrl.text),
                      professor: profCtrl.text.isEmpty
                          ? const Value.absent()
                          : Value(profCtrl.text),
                      location: locCtrl.text.isEmpty
                          ? const Value.absent()
                          : Value(locCtrl.text),
                      semester: semCtrl.text.isEmpty
                          ? const Value.absent()
                          : Value(semCtrl.text),
                      color:
                      '#${selectedColor.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}',
                    ));
                if (mounted) Navigator.pop(context);
              },
              child:
                  const Text('Save', style: TextStyle(color: _red)),
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
        title: const Text('Delete Course',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'Delete "${course.name}" and all its lectures, assignments, notes, and flashcards?',
            style: const TextStyle(color: Color(0xFF9A9A9E))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref
                  .read(academicsServiceProvider)
                  .deleteCourse(course.id);
              if (mounted) {
                ref.read(selectedCourseProvider.notifier).state = null;
                Navigator.pop(context);
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddLectureDialog(String courseId) {
    final titleCtrl = TextEditingController();
    final chapterCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? scheduledAt;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title:
              const Text('Add Lecture', style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField('Lecture Title *', titleCtrl, required: true),
                _buildField('Chapter', chapterCtrl),
                _DateTimeField(
                  label: 'Scheduled Date & Time',
                  value: scheduledAt,
                  onPick: () async {
                    final picked = await _pickDateTime(context, scheduledAt);
                    if (picked != null) setDialogState(() => scheduledAt = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref.read(academicsServiceProvider).createLecture(
                        courseId,
                        titleCtrl.text.trim(),
                        chapter: chapterCtrl.text.isEmpty ? null : chapterCtrl.text.trim(),
                        scheduledAt: scheduledAt,
                      );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) _showSnack('Failed to add lecture: $e');
                }
              },
              child: const Text('Add', style: TextStyle(color: _red)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLectureDialog(Lecture lecture) {
    final titleCtrl = TextEditingController(text: lecture.title);
    final chapterCtrl = TextEditingController(text: lecture.chapter ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? scheduledAt = lecture.scheduledAt;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Edit Lecture',
              style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField('Lecture Title *', titleCtrl, required: true),
                _buildField('Chapter', chapterCtrl),
                _DateTimeField(
                  label: 'Scheduled Date & Time',
                  value: scheduledAt,
                  onPick: () async {
                    final picked = await _pickDateTime(context, scheduledAt);
                    if (picked != null) setDialogState(() => scheduledAt = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final now = DateTime.now();
                  await ref.read(academicsServiceProvider).updateLecture(
                        lecture.copyWith(
                          title: titleCtrl.text.trim(),
                          chapter: chapterCtrl.text.isEmpty
                              ? const Value.absent()
                              : Value(chapterCtrl.text.trim()),
                          scheduledAt: scheduledAt != null
                              ? Value(scheduledAt)
                              : const Value.absent(),
                          updatedAt: now,
                        ),
                      );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) _showSnack('Failed to update lecture: $e');
                }
              },
              child: const Text('Save', style: TextStyle(color: _red)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteLecture(Lecture lecture) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Lecture',
            style: TextStyle(color: Colors.white)),
        content: Text('Delete "${lecture.title}"?',
            style: const TextStyle(color: Color(0xFF9A9A9E))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref
                  .read(academicsServiceProvider)
                  .deleteLecture(lecture.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditAssignmentDialog(Assignment assignment) {
    final titleCtrl = TextEditingController(text: assignment.title);
    final descCtrl = TextEditingController(text: assignment.description ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? dueDate = assignment.dueDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Edit Assignment',
              style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField('Assignment Title *', titleCtrl, required: true),
                _buildField('Description', descCtrl),
                _DateTimeField(
                  label: 'Due Date',
                  value: dueDate,
                  dateOnly: true,
                  onPick: () async {
                    final picked = await _pickDate(context, dueDate);
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final now = DateTime.now();
                  await ref.read(academicsServiceProvider).updateAssignment(
                        assignment.copyWith(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.isEmpty
                              ? const Value.absent()
                              : Value(descCtrl.text.trim()),
                          dueDate: dueDate != null
                              ? Value(dueDate)
                              : const Value.absent(),
                          updatedAt: now,
                        ),
                      );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) _showSnack('Failed to update assignment: $e');
                }
              },
              child: const Text('Save', style: TextStyle(color: _red)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAssignment(Assignment assignment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Assignment',
            style: TextStyle(color: Colors.white)),
        content: Text('Delete "${assignment.title}"?',
            style: const TextStyle(color: Color(0xFF9A9A9E))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref
                  .read(academicsServiceProvider)
                  .deleteAssignment(assignment.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddAssignmentDialog(String courseId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Add Assignment',
              style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField('Assignment Title *', titleCtrl, required: true),
                _buildField('Description', descCtrl),
                _DateTimeField(
                  label: 'Due Date',
                  value: dueDate,
                  dateOnly: true,
                  onPick: () async {
                    final picked = await _pickDate(context, dueDate);
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref.read(academicsServiceProvider).createAssignment(
                        courseId,
                        titleCtrl.text.trim(),
                        description: descCtrl.text.isEmpty ? null : descCtrl.text.trim(),
                        dueDate: dueDate,
                      );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) _showSnack('Failed to add assignment: $e');
                }
              },
              child: const Text('Add', style: TextStyle(color: _red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _red),
        ),
        child: child!,
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime? initial) async {
    final date = await _pickDate(context, initial);
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _red),
        ),
        child: child!,
      ),
    );
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFE8443F),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: Color(0xFF9A9A9E), fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────

  Color _hexToColor(String hex) {
    final sanitized = hex.replaceFirst('#', '');
    final padded = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
    return Color(int.parse(padded, radix: 16));
  }
}

// ── Extracted Widgets ────────────────────────────────

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final bool dateOnly;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onPick,
    this.dateOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? label
        : dateOnly
            ? '${value!.day}/${value!.month}/${value!.year}'
            : '${value!.day}/${value!.month}/${value!.year}  '
                '${value!.hour.toString().padLeft(2, '0')}:'
                '${value!.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF9A9A9E), size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        color: value == null
                            ? const Color(0xFF9A9A9E)
                            : Colors.white,
                        fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onChanged;
  const _ColorPicker({required this.selectedColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorOptions = [
      const Color(0xFF8B5CF6), const Color(0xFFE8443F), const Color(0xFF34C759),
      const Color(0xFFE08A2E), const Color(0xFF3B82F6), const Color(0xFF0A84FF),
    ];

    return Row(
      children: [
        const Text('Color:',
            style: TextStyle(color: Color(0xFF9A9A9E))),
        const SizedBox(width: 12),
        ...colorOptions
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(c),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selectedColor == c
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ],
    );
  }
}

class _CourseCardWithProgress extends ConsumerWidget {
  final Course course;
  final VoidCallback onTap;
  const _CourseCardWithProgress(
      {required this.course, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(courseProgressProvider(course.id));
    final progress = progressAsync.when(
      data: (p) => p,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
    final color = Color(int.parse(course.color.replaceFirst('#', '0xFF')));

    return CourseSummaryCard(
      courseName: course.name,
      professor: course.professor ?? 'No instructor',
      time: course.scheduleStart ?? 'TBD',
      room: course.location ?? '',
      progress: progress,
      accentColor: color,
      onTap: onTap,
    );
  }
}

class _CourseDetailView extends ConsumerWidget {
  final Course course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddLecture;
  final VoidCallback onAddAssignment;

  const _CourseDetailView({
    required this.course,
    required this.onEdit,
    required this.onDelete,
    required this.onAddLecture,
    required this.onAddAssignment,
  });

  void _editLecture(BuildContext context, WidgetRef ref, Lecture lecture) {
    final screen = context.findAncestorStateOfType<_AcademicsScreenState>();
    screen?._showEditLectureDialog(lecture);
  }

  void _deleteLecture(BuildContext context, WidgetRef ref, Lecture lecture) {
    final screen = context.findAncestorStateOfType<_AcademicsScreenState>();
    screen?._confirmDeleteLecture(lecture);
  }

  void _editAssignment(BuildContext context, WidgetRef ref, Assignment assignment) {
    final screen = context.findAncestorStateOfType<_AcademicsScreenState>();
    screen?._showEditAssignmentDialog(assignment);
  }

  void _deleteAssignment(BuildContext context, WidgetRef ref, Assignment assignment) {
    final screen = context.findAncestorStateOfType<_AcademicsScreenState>();
    screen?._confirmDeleteAssignment(assignment);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(int.parse(course.color.replaceFirst('#', '0xFF')));
    final lecturesAsync = ref.watch(lecturesProvider(course.id));
    final assignmentsAsync = ref.watch(assignmentsProvider(course.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                if (course.professor != null)
                  Text(course.professor!,
                      style: const TextStyle(
                          color: Color(0xFF9A9A9E), fontSize: 13)),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz,
                  color: Color(0xFF9A9A9E)),
              color: const Color(0xFF1C1C1E),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Course',
                        style: TextStyle(color: Colors.white))),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Course',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Lectures
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Lectures',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: onAddLecture,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('+ Add',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        lecturesAsync.when(
          data: (lectures) => lectures.isEmpty
              ? _emptyState('No lectures yet. Add one!')
              : Column(
                  children: lectures
                      .map((l) => UpcomingLectureTile(
                            title: l.title,
                            chapter: l.chapter ?? '',
                            tag: l.tag ?? 'Upcoming',
                            time: l.scheduledAt != null
                                ? DateFormat('h:mm a')
                                    .format(l.scheduledAt!.toLocal())
                                : 'TBD',
                            accentColor: color,
                            isCompleted: l.isCompleted,
                            onCompletionChanged: (val) => ref
                                .read(academicsServiceProvider)
                                .toggleLectureCompletion(l.id, val),
                            onEdit: () => _editLecture(context, ref, l),
                            onDelete: () => _deleteLecture(context, ref, l),
                          ))
                      .toList(),
                ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 20),
        // Assignments
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Due Assignments',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: onAddAssignment,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('+ Add',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        assignmentsAsync.when(
          data: (assignments) => assignments.isEmpty
              ? _emptyState('No assignments due.')
              : Column(
                  children: assignments
                      .map((a) => DueAssignmentTile(
                            title: a.title,
                            dueDate: a.dueDate != null
                                ? 'Due: ${DateFormat('dd MMM').format(a.dueDate!)}'
                                : '',
                            daysLeft: a.dueDate != null
                                ? _daysLeft(a.dueDate!)
                                : '',
                            color: const Color(0xFFE8443F),
                            isCompleted: a.isCompleted,
                            onCompletionChanged: (val) => ref
                                .read(academicsServiceProvider)
                                .toggleAssignmentCompletion(a.id, val),
                            onEdit: () => _editAssignment(context, ref, a),
                            onDelete: () => _deleteAssignment(context, ref, a),
                          ))
                      .toList(),
                ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF5A5A5E), size: 32),
          const SizedBox(height: 8),
          Text(msg,
              style: const TextStyle(color: Color(0xFF9A9A9E), fontSize: 14)),
        ],
      ),
    );
  }

  String _daysLeft(DateTime due) {
    final diff = due.difference(DateTime.now()).inDays;
    return diff == 0 ? 'Due Today' : '$diff Days Left';
  }
}

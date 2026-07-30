import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:go_router/go_router.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/academics/providers/academics_providers.dart';
import 'package:aether/features/academics/widgets/course_summary_card.dart';
import 'package:aether/features/academics/widgets/upcoming_lecture_tile.dart';
import 'package:aether/features/academics/widgets/due_assignment_tile.dart';
import 'package:aether/features/academics/widgets/quick_access_button.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/widgets/dashboard_top_bar.dart';

class AcademicsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onProfileTap;
  const AcademicsScreen({super.key, this.onProfileTap});

  @override
  ConsumerState<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends ConsumerState<AcademicsScreen> {
  int _selectedTab = 0;

  /// Theme tokens — safe to read anywhere below build (dialogs, snackbars).
  AetherTheme get _aether => context.aether;

  /// Named method (not an inline closure) so the dispose-time equality check
  /// below matches what initState registered — tear-offs of the same instance
  /// method compare equal.
  void _addCourseAction() => _showAddCourseDialog();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(academicsServiceProvider).syncCourses();
        ref.read(globalAddActionProvider.notifier).state = _addCourseAction;
      }
    });
  }

  @override
  void dispose() {
    // Capture the notifier now (ref is unusable after dispose), but defer the
    // actual clear — mutating a provider synchronously mid-tree-teardown can
    // throw "modified a provider while the widget tree was building".
    final notifier = ref.read(globalAddActionProvider.notifier);
    final action = _addCourseAction;
    Future.microtask(() {
      // Only clear if we still own the action; a newly-mounted screen may
      // have already registered its own by the time this runs.
      if (notifier.state == action) notifier.state = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final coursesAsync = ref.watch(coursesProvider);
    return Container(
      color: aether.background,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            DashboardTopBar(
              onProfileTap: widget.onProfileTap ?? () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(aether),
                    const SizedBox(height: 20),
                    _buildCourseCards(coursesAsync),
                    const SizedBox(height: 20),
                    _buildTabSelector(aether),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _selectedTab == 0
                          ? _buildMyCoursesView(aether)
                          : _buildTimetableView(aether),
                    ),
                    const SizedBox(height: 24),
                    _buildQuickAccessBar(aether),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AetherTheme aether) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Academics',
            style: TextStyle(
                color: aether.text, fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Manage courses, lectures & assignments.',
            style: TextStyle(color: aether.textMuted, fontSize: 14)),
      ],
    );
  }

  // ── Course Cards ──────────────────────────────────

  Widget _buildCourseCards(AsyncValue<List<Course>> asyncCourses) {
    final aether = context.aether;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Courses',
                style: TextStyle(
                    color: aether.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () => _showAddCourseDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: aether.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, color: aether.accent, size: 16),
                    const SizedBox(width: 4),
                    Text('Add Course',
                        style: TextStyle(
                            color: aether.accent,
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
              ? _buildEmptyCourses(aether)
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
                          service.syncLectures(courseId: c.id);
                          service.syncAssignments(courseId: c.id);
                          ref.read(selectedCourseProvider.notifier).state = c;
                        },
                      );
                    },
                  ),
                ),
          loading: () => SizedBox(
            height: 200,
            child:
                Center(child: CircularProgressIndicator(color: aether.accent)),
          ),
          error: (e, _) => _buildError('Error loading courses: $e', aether),
        ),
      ],
    );
  }

  Widget _buildEmptyCourses(AetherTheme aether) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, color: aether.textMuted, size: 48),
            const SizedBox(height: 16),
            Text('No courses added yet.',
                style: TextStyle(color: aether.textMuted, fontSize: 16)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showAddCourseDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: aether.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('+ Add your first course',
                    style: TextStyle(
                        color: aether.accent,
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

  Widget _buildTabSelector(AetherTheme aether) {
    return Row(
      children: [
        _buildTab('My Courses', 0, aether),
        const SizedBox(width: 12),
        _buildTab('Timetable', 1, aether),
      ],
    );
  }

  Widget _buildTab(String title, int index, AetherTheme aether) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? aether.accent : aether.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(title,
            style: TextStyle(
                color: aether.text,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  // ── My Courses Detail View ────────────────────────

  Widget _buildMyCoursesView(AetherTheme aether) {
    final selectedCourse = ref.watch(selectedCourseProvider);
    if (selectedCourse == null) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, color: aether.textMuted, size: 48),
            const SizedBox(height: 16),
            Text('Select a course from above',
                style: TextStyle(color: aether.textMuted, fontSize: 16)),
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

  Widget _buildTimetableView(AetherTheme aether) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined,
              color: aether.textMuted, size: 48),
          const SizedBox(height: 16),
          Text('Timetable view coming soon.',
              style: TextStyle(color: aether.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildQuickAccessBar(AetherTheme aether) {
    // Fixed category colors — each shortcut keeps its own identity.
    final actions = [
      (Icons.notes_rounded, 'All Notes', const Color(0xFF34C759), '/notes'),
      (Icons.assignment_rounded, 'Past Papers', const Color(0xFFE08A2E), '/past-papers'),
      (Icons.timer_rounded, 'Pomodoro', aether.accent, '/pomodoro'),
      (Icons.auto_stories_rounded, 'Flashcards', const Color(0xFF3B82F6), '/flashcards'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Access',
            style: TextStyle(
                color: aether.text,
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
                        onTap: () => context.push(a.$4),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildError(String msg, AetherTheme aether) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: aether.danger, size: 40),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(color: aether.textMuted, fontSize: 14),
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
          backgroundColor: _aether.surface,
          title:
              Text('Add Course', style: TextStyle(color: _aether.text)),
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
                if (!mounted) return;
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
                  Text('Add', style: TextStyle(color: _aether.accent)),
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
          backgroundColor: _aether.surface,
          title:
              Text('Edit Course', style: TextStyle(color: _aether.text)),
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
                if (!mounted) return;
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
                          '#${selectedColor.value.toRadixString(16).substring(2)}',
                    ));
                if (mounted) Navigator.pop(context);
              },
              child:
                  Text('Save', style: TextStyle(color: _aether.accent)),
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
        backgroundColor: _aether.surface,
        title: Text('Delete Course',
            style: TextStyle(color: _aether.text)),
        content: Text(
            'Delete "${course.name}" and all its lectures, assignments, notes, and flashcards?',
            style: TextStyle(color: _aether.textMuted)),
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
          backgroundColor: _aether.surface,
          title:
              Text('Add Lecture', style: TextStyle(color: _aether.text)),
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
                if (!mounted) return;
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref.read(academicsServiceProvider).createLecture(
                        courseId: courseId,
                        title: titleCtrl.text.trim(),
                        chapter: chapterCtrl.text.isEmpty ? null : chapterCtrl.text.trim(),
                        scheduledAt: scheduledAt,
                      );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) _showSnack('Failed to add lecture: $e');
                }
              },
              child: Text('Add', style: TextStyle(color: _aether.accent)),
            ),
          ],
        ),
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
          backgroundColor: _aether.surface,
          title: Text('Add Assignment',
              style: TextStyle(color: _aether.text)),
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
                if (!mounted) return;
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref.read(academicsServiceProvider).createAssignment(
                        courseId: courseId,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.isEmpty ? null : descCtrl.text.trim(),
                        dueDate: dueDate,
                      );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) _showSnack('Failed to add assignment: $e');
                }
              },
              child: Text('Add', style: TextStyle(color: _aether.accent)),
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
          colorScheme: ColorScheme.dark(primary: _aether.accent),
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
          colorScheme: ColorScheme.dark(primary: _aether.accent),
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
      backgroundColor: _aether.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(color: _aether.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: _aether.textMuted, fontSize: 12),
          filled: true,
          fillColor: _aether.surfaceAlt,
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

  Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));
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
            color: context.aether.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: context.aether.textMuted, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        color: value == null
                            ? context.aether.textMuted
                            : context.aether.text,
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
        Text('Color:',
            style: TextStyle(color: context.aether.textMuted)),
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
                    style: TextStyle(
                        color: context.aether.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                if (course.professor != null)
                  Text(course.professor!,
                      style: TextStyle(
                          color: context.aether.textMuted, fontSize: 13)),
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz,
                  color: context.aether.textMuted),
              color: context.aether.surface,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Course',
                        style: TextStyle(color: context.aether.text))),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Course',
                        style: TextStyle(color: context.aether.danger))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Lectures
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming Lectures',
                style: TextStyle(
                    color: context.aether.text,
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
              ? _emptyState(context, 'No lectures yet. Add one!')
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
                          ))
                      .toList(),
                ),
          loading: () => Center(
              child: CircularProgressIndicator(color: context.aether.accent)),
          error: (e, _) =>
              Text('Error: $e', style: TextStyle(color: context.aether.danger)),
        ),
        const SizedBox(height: 20),
        // Assignments
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Due Assignments',
                style: TextStyle(
                    color: context.aether.text,
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
              ? _emptyState(context, 'No assignments due.')
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
                            color: context.aether.danger,
                            isCompleted: a.isCompleted,
                            onCompletionChanged: (val) => ref
                                .read(academicsServiceProvider)
                                .toggleAssignmentCompletion(a.id, val),
                          ))
                      .toList(),
                ),
          loading: () => Center(
              child: CircularProgressIndicator(color: context.aether.accent)),
          error: (e, _) =>
              Text('Error: $e', style: TextStyle(color: context.aether.danger)),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context, String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.info_outline, color: context.aether.textMuted, size: 32),
          const SizedBox(height: 8),
          Text(msg,
              style: TextStyle(color: context.aether.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  String _daysLeft(DateTime due) {
    final diff = due.difference(DateTime.now()).inDays;
    return diff == 0 ? 'Due Today' : '$diff Days Left';
  }
}

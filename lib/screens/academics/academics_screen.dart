export 'package:aether/features/academics/screens/academics_screen.dart';import 'package:flutter/material.dart';

class Course {
  final String name;
  final String professor;
  final IconData icon;
  final Color color;
  final double progress;

  Course({
    required this.name,
    required this.professor,
    required this.icon,
    required this.color,
    required this.progress,
  });
}

class Lecture {
  final String date;
  final String month;
  final String title;
  final String subtitle;
  final String time;
  final String status;

  Lecture({
    required this.date,
    required this.month,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
  });
}

class AssignmentItem {
  final String title;
  final String subtitle;
  final String due;
  final String daysLeft;
  final Color urgencyColor;

  AssignmentItem({
    required this.title,
    required this.subtitle,
    required this.due,
    required this.daysLeft,
    required this.urgencyColor,
  });
}

class AcademicsScreen extends StatefulWidget {
  const AcademicsScreen({super.key});

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  int _topTabIndex = 0; // 0 = My Courses, 1 = Timetable
  int _selectedCourseIndex = 0;
  int _courseTabIndex = 0; // Lectures, Assignments, Notes, Syllabus

  final List<Course> _courses = [
    Course(
      name: 'Physics',
      professor: 'Dr. Arjun Mehta',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFFE63946),
      progress: 0.68,
    ),
    Course(
      name: 'Mathematics',
      professor: 'Prof. Neha Sharma',
      icon: Icons.calculate_rounded,
      color: const Color(0xFFF4A340),
      progress: 0.52,
    ),
    Course(
      name: 'Chemistry',
      professor: 'Dr. Rohan Iyer',
      icon: Icons.science_rounded,
      color: const Color(0xFF4CD964),
      progress: 0.41,
    ),
    Course(
      name: 'Computer Science',
      professor: 'Prof. Karan Malhotra',
      icon: Icons.laptop_mac_rounded,
      color: const Color(0xFF4A9EF4),
      progress: 0.73,
    ),
  ];

  final List<Lecture> _lectures = [
    Lecture(
      date: '15',
      month: 'MAY\nWED',
      title: 'Laws of Motion',
      subtitle: 'Chapter 1',
      time: '9:00 AM\n1h 30m',
      status: 'Upcoming',
    ),
    Lecture(
      date: '17',
      month: 'MAY\nFRI',
      title: 'Work, Energy & Power',
      subtitle: 'Chapter 2',
      time: '9:00 AM\n1h 30m',
      status: 'Upcoming',
    ),
    Lecture(
      date: '20',
      month: 'MAY\nMON',
      title: 'System of Particles',
      subtitle: 'Chapter 3',
      time: '9:00 AM\n1h 30m',
      status: 'Upcoming',
    ),
  ];

  final List<AssignmentItem> _assignments = [
    AssignmentItem(
      title: 'Numerical Problems Set 1',
      subtitle: 'Chapter 1: Laws of Motion',
      due: 'Due 18 May, 2025',
      daysLeft: '3 Days Left',
      urgencyColor: const Color(0xFFE63946),
    ),
    AssignmentItem(
      title: 'Derivation Worksheet',
      subtitle: 'Chapter 2: Work, Energy & Power',
      due: 'Due 24 May, 2025',
      daysLeft: '9 Days Left',
      urgencyColor: const Color(0xFFF4A340),
    ),
  ];

  Course get _selectedCourse => _courses[_selectedCourseIndex];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopTabs(),
              const SizedBox(height: 16),
              _buildCourseCards(),
              const SizedBox(height: 20),
              _buildSelectedCourseHeader(),
              const SizedBox(height: 12),
              _buildCourseTabs(),
              const SizedBox(height: 20),
              _buildSectionHeader('Upcoming Lectures', onViewAll: () {}),
              const SizedBox(height: 12),
              ..._lectures.map(_buildLectureCard),
              const SizedBox(height: 20),
              _buildSectionHeader('Due Assignments', onViewAll: () {}),
              const SizedBox(height: 12),
              ..._assignments.map(_buildAssignmentCard),
              const SizedBox(height: 20),
              const Text(
                'Quick Access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickAccessGrid(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Top Tabs (My Courses / Timetable) ----------
  Widget _buildTopTabs() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _topTab('My Courses', 0),
              const SizedBox(width: 8),
              _topTab('Timetable', 1),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Row(
            children: const [
              Icon(Icons.add_circle_outline, color: Color(0xFFE63946), size: 18),
              SizedBox(width: 4),
              Text(
                'Add Course',
                style: TextStyle(
                  color: Color(0xFFE63946),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topTab(String label, int index) {
    final bool selected = _topTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _topTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE63946).withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFE63946) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFE63946) : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ---------- Course Cards ----------
  Widget _buildCourseCards() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _courses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final course = _courses[index];
          final bool selected = index == _selectedCourseIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCourseIndex = index),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? course.color : Colors.white.withOpacity(0.08),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: course.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(course.icon, color: course.color, size: 18),
                      ),
                      const Icon(Icons.more_vert, color: Colors.white38, size: 16),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    course.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.professor,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(course.progress * 100).round()}% Complete',
                    style: TextStyle(color: course.color, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(course.color),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Selected Course Header ----------
  Widget _buildSelectedCourseHeader() {
    final course = _selectedCourse;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: course.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(course.icon, color: course.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      course.professor,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: course.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(course.progress * 100).round()}%',
                  style: TextStyle(color: course.color, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.more_vert, color: Colors.white38, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 13),
              SizedBox(width: 4),
              Text('Mon, Wed, Fri', style: TextStyle(color: Colors.white54, fontSize: 11)),
              SizedBox(width: 14),
              Icon(Icons.access_time_rounded, color: Colors.white38, size: 13),
              SizedBox(width: 4),
              Text('9:00 AM - 10:30 AM', style: TextStyle(color: Colors.white54, fontSize: 11)),
              SizedBox(width: 14),
              Icon(Icons.location_on_outlined, color: Colors.white38, size: 13),
              SizedBox(width: 4),
              Text('Room 302', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Course Detail Tabs ----------
  Widget _buildCourseTabs() {
    final tabs = [
      ('Lectures', Icons.play_circle_outline),
      ('Assignments', Icons.description_outlined),
      ('Notes', Icons.note_outlined),
      ('Syllabus', Icons.menu_book_outlined),
    ];
    return Row(
      children: List.generate(tabs.length, (index) {
        final bool selected = _courseTabIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _courseTabIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? const Color(0xFFE63946) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    tabs[index].$2,
                    size: 16,
                    color: selected ? const Color(0xFFE63946) : Colors.white38,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tabs[index].$1,
                    style: TextStyle(
                      color: selected ? const Color(0xFFE63946) : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------- Section Header ----------
  Widget _buildSectionHeader(String title, {required VoidCallback onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Row(
            children: const [
              Text('View All', style: TextStyle(color: Color(0xFFE63946), fontSize: 12)),
              Icon(Icons.chevron_right, color: Color(0xFFE63946), size: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Lecture Card ----------
  Widget _buildLectureCard(Lecture lecture) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFB16CEA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                lecture.date,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              Text(
                lecture.month,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 9, height: 1.1),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lecture.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(lecture.subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB16CEA).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lecture.status,
                        style: const TextStyle(color: Color(0xFFB16CEA), fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lecture.time,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.3),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFB16CEA).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFB16CEA), size: 16),
          ),
        ],
      ),
    );
  }

  // ---------- Assignment Card ----------
  Widget _buildAssignmentCard(AssignmentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.urgencyColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.description_outlined, color: item.urgencyColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.white24, size: 10),
                    const SizedBox(width: 4),
                    Text(item.due, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.urgencyColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.daysLeft,
              style: TextStyle(color: item.urgencyColor, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ],
      ),
    );
  }

  // ---------- Quick Access Grid ----------
  Widget _buildQuickAccessGrid() {
    final items = [
      ('All Notes', '23 Notes', Icons.menu_book_outlined, const Color(0xFF4A9EF4)),
      ('Past Papers', '12 Papers', Icons.description_outlined, const Color(0xFFF4A340)),
      ('Resources', '8 Links', Icons.link_rounded, const Color(0xFF4CD964)),
      ('Flashcards', '36 Cards', Icons.style_outlined, const Color(0xFFB16CEA)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.$4.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.$3, color: item.$4, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(item.$2, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
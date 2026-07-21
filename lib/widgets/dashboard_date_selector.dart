import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  const DashboardDateSelector({
    super.key,
    required this.selectedDate,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  static const Color _cardColor = Color(0xFF141821);

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String getDisplayText() {
    if (isToday(selectedDate)) return 'Today';
    if (isTomorrow(selectedDate)) return 'Tomorrow';
    if (isYesterday(selectedDate)) return 'Yesterday';
    return DateFormat('d MMM').format(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _cardColor.withOpacity(0.52),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _ChevronButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPreviousDay,
              ),
              Flexible(
  fit: FlexFit.loose,
                child: Text(
                  getDisplayText(),
                  textAlign: TextAlign.center,
                //   textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.82),
                    
                  ),
                ),
              ),
              _ChevronButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNextDay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ChevronButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: Colors.white.withOpacity(0.92),
          ),
        ),
      ),
    );
  }
}

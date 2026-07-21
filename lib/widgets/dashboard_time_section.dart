import 'package:flutter/material.dart';
import 'package:aether/widgets/dashboard_date_selector.dart';

class DashboardTimeSection extends StatelessWidget {
  final String currentTime;
  final String dayName;
  final String formattedDate;
  final DateTime selectedDate;
final VoidCallback onPreviousDay;
final VoidCallback onNextDay;

  const DashboardTimeSection({
  super.key,
  required this.currentTime,
  required this.dayName,
  required this.formattedDate,
  required this.selectedDate,
  required this.onPreviousDay,
  required this.onNextDay,
});

  @override
  Widget build(BuildContext context) {
    final timeParts = currentTime.trim().split(RegExp(r'\s+'));
    final period = timeParts.length > 1 ? timeParts.last : '';
    final timeValue = timeParts.length > 1
        ? timeParts.sublist(0, timeParts.length - 1).join(' ')
        : currentTime;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeValue,
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w300,
                      height: 1,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  if (period.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 6),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          height: 1,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
              DashboardDateSelector(
  selectedDate: selectedDate,
  onPreviousDay: onPreviousDay,
  onNextDay: onNextDay,
)
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

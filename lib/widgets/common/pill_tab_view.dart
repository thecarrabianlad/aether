import 'package:flutter/material.dart';

class PillTabView extends StatefulWidget {
  final List<String> tabTitles;
  final ValueChanged<int> onTabChanged;
  final int initialIndex;

  const PillTabView({
    super.key,
    required this.tabTitles,
    required this.onTabChanged,
    this.initialIndex = 0,
  });

  @override
  State<PillTabView> createState() => _PillTabViewState();
}

class _PillTabViewState extends State<PillTabView> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.tabTitles.length, (index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
              widget.onTabChanged(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8443F) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.tabTitles[index],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

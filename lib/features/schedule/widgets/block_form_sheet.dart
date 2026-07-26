import 'package:flutter/material.dart';
import 'package:aether/features/schedule/screens/schedule_screen.dart'
    show ScheduleScreen;
import 'package:aether/features/schedule/widgets/schedule_options.dart';

class BlockFormResult {
  final String title;
  final String startTime; // 'HH:mm'
  final String endTime; // 'HH:mm'
  final String color; // hex
  final String icon; // key

  const BlockFormResult({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.icon,
  });
}

/// Opens the add/edit time block sheet. Pass [initial] to prefill for
/// editing; omit for a fresh "Add New Time Block". Resolves with the
/// entered data, or null if dismissed without confirming.
Future<BlockFormResult?> showBlockFormSheet(
  BuildContext context, {
  BlockFormResult? initial,
}) {
  return showModalBottomSheet<BlockFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BlockFormSheet(initial: initial),
  );
}

class _BlockFormSheet extends StatefulWidget {
  final BlockFormResult? initial;
  const _BlockFormSheet({this.initial});

  @override
  State<_BlockFormSheet> createState() => _BlockFormSheetState();
}

class _BlockFormSheetState extends State<_BlockFormSheet> {
  late final TextEditingController _titleController;
  late String _startTime;
  late String _endTime;
  late String _color;
  late String _icon;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _titleController = TextEditingController(text: i?.title ?? '');
    _startTime = i?.startTime ?? '09:00';
    _endTime = i?.endTime ?? '10:00';
    _color = i?.color ?? kScheduleColorOptions.keys.first;
    _icon = i?.icon ?? kScheduleIconOptions.keys.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = timeOfDayFromKey(isStart ? _startTime : _endTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = timeOfDayToKey(picked);
      } else {
        _endTime = timeOfDayToKey(picked);
      }
    });
  }

  void _confirm() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      BlockFormResult(
        title: title,
        startTime: _startTime,
        endTime: _endTime,
        color: _color,
        icon: _icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final durationLabel = formatDuration(minutesBetween(_startTime, _endTime));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: ScheduleScreen.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: ScheduleScreen.cardBorder),
            left: BorderSide(color: ScheduleScreen.cardBorder),
            right: BorderSide(color: ScheduleScreen.cardBorder),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ScheduleScreen.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isEditing ? 'Edit Time Block' : 'New Time Block',
                style: const TextStyle(
                  color: ScheduleScreen.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                autofocus: !isEditing,
                style: const TextStyle(
                  color: ScheduleScreen.white,
                  fontSize: 14,
                ),
                decoration: _fieldDecoration('Title'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Start Time',
                      value: formatTimeInline(_startTime),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeField(
                      label: 'End Time',
                      value: formatTimeInline(_endTime),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Duration: $durationLabel',
                style: const TextStyle(
                  color: ScheduleScreen.grey,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Color',
                style: TextStyle(color: ScheduleScreen.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: kScheduleColorOptions.entries.map((entry) {
                  final selected = _color == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _color = entry.key),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? ScheduleScreen.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              const Text(
                'Icon',
                style: TextStyle(color: ScheduleScreen.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kScheduleIconOptions.entries.map((entry) {
                  final selected = _icon == entry.key;
                  final swatch = colorForHex(_color);
                  return GestureDetector(
                    onTap: () => setState(() => _icon = entry.key),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? swatch.withOpacity(0.15)
                            : ScheduleScreen.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? swatch
                              : ScheduleScreen.cardBorder,
                        ),
                      ),
                      child: Icon(
                        entry.value,
                        size: 18,
                        color: selected ? swatch : ScheduleScreen.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScheduleScreen.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Block',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: ScheduleScreen.grey),
        filled: true,
        fillColor: ScheduleScreen.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ScheduleScreen.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ScheduleScreen.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ScheduleScreen.red),
        ),
      );
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: ScheduleScreen.grey, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: ScheduleScreen.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ScheduleScreen.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: ScheduleScreen.white,
                    fontSize: 13,
                  ),
                ),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: ScheduleScreen.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
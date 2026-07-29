import 'dart:typed_data';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/past_papers/providers/past_papers_providers.dart';
import 'package:aether/widgets/common/glass_card.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PastPapersScreen extends ConsumerStatefulWidget {
  const PastPapersScreen({super.key});

  @override
  ConsumerState<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends ConsumerState<PastPapersScreen> {
  static const _examColors = {
    'midterm': Color(0xFF8B5CF6),
    'final': Color(0xFFFF3B30),
    'quiz': Color(0xFF34C759),
    'test': Color(0xFFE08A2E),
    'other': Color(0xFF3B82F6),
  };

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final papersAsync = ref.watch(papersProvider);

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: aether.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Past Papers',
            style: TextStyle(
                color: aether.text, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: papersAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: aether.accent)),
        error: (e, _) => Center(
          child: Text('Could not load papers',
              style: TextStyle(color: aether.textMuted)),
        ),
        data: (papers) {
          if (papers.isEmpty) return _buildEmpty(aether);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: papers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _PaperCard(
              paper: papers[i],
              examColor: _examColors[papers[i].examType?.toLowerCase()] ??
                  _examColors['other']!,
              onTap: () => _openPaperSheet(papers[i]),
              onDelete: () => _deletePaper(papers[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPaperSheet(null),
        backgroundColor: aether.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty(AetherTheme aether) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_rounded,
                color: aether.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('No past papers yet',
                style: TextStyle(color: aether.textMuted, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Tap + to add a past paper',
                style: TextStyle(color: aether.textMuted, fontSize: 13)),
          ],
        ),
      );

  void _openPaperSheet(PastPaper? paper) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPaperSheet(
        paper: paper,
        onSave: (title, year, examType, fileBytes, fileName) async {
          final service = ref.read(pastPapersServiceProvider);
          String? fileUrl;
          String? storedName;
          if (fileBytes != null) {
            storedName = fileName;
            fileUrl = await service.uploadFile(fileName: fileName!, bytes: fileBytes);
          }
          if (paper == null) {
            await service.createPaper(
              title: title,
              year: year,
              examType: examType,
              fileUrl: fileUrl,
              fileName: storedName,
            );
          } else {
            // drift's copyWith wraps nullable fields in Value<> for null-safety
            await service.updatePaper(paper.copyWith(
              title: title,
              year: Value<String?>(year),
              examType: Value<String?>(examType),
              fileUrl: Value<String?>(fileUrl ?? paper.fileUrl),
              fileName: Value<String?>(storedName ?? paper.fileName),
            ));
          }
        },
      ),
    );
  }

  void _deletePaper(PastPaper paper) {
    final aether = context.aether;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: aether.surface,
        title: Text('Delete Paper', style: TextStyle(color: aether.text)),
        content: Text('Delete "${paper.title}"?',
            style: TextStyle(color: aether.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(pastPapersServiceProvider).deletePaper(paper.id);
            },
            child: Text('Delete', style: TextStyle(color: aether.danger)),
          ),
        ],
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final PastPaper paper;
  final Color examColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PaperCard({
    required this.paper,
    required this.examColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: examColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (paper.examType ?? 'other').toUpperCase(),
                style: TextStyle(
                    color: examColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paper.title,
                      style: TextStyle(
                          color: aether.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  if (paper.year != null) ...[
                    const SizedBox(height: 4),
                    Text('Year: ${paper.year}',
                        style: TextStyle(
                            color: aether.textMuted, fontSize: 12)),
                  ],
                  if (paper.fileName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.attach_file_rounded,
                            size: 14, color: aether.accent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(paper.fileName!,
                              style: TextStyle(
                                  color: aether.accent, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPaperSheet extends StatefulWidget {
  final PastPaper? paper;
  final Future<void> Function(
      String title, String? year, String? examType,
      Uint8List? fileBytes, String? fileName) onSave;

  const _AddPaperSheet({this.paper, required this.onSave});

  @override
  State<_AddPaperSheet> createState() => _AddPaperSheetState();
}

class _AddPaperSheetState extends State<_AddPaperSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _yearCtrl;
  String _examType = 'final';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.paper?.title ?? '');
    _yearCtrl = TextEditingController(text: widget.paper?.year ?? '');
    _examType = widget.paper?.examType ?? 'final';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(
      _titleCtrl.text.trim(),
      _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
      _examType,
      null, // file upload skipped for v1 — add file_picker later
      null,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: aether.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: aether.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.paper == null ? 'Add Paper' : 'Edit Paper',
              style: TextStyle(
                  color: aether.text, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: aether.text),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: aether.textMuted),
                filled: true, fillColor: aether.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yearCtrl,
                    style: TextStyle(color: aether.text),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Year (e.g. 2026)',
                      hintStyle: TextStyle(color: aether.textMuted),
                      filled: true, fillColor: aether.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _examType,
                    dropdownColor: aether.surface,
                    style: TextStyle(color: aether.text),
                    decoration: InputDecoration(
                      filled: true, fillColor: aether.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'final', child: Text('Final')),
                      DropdownMenuItem(value: 'midterm', child: Text('Midterm')),
                      DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                      DropdownMenuItem(value: 'test', child: Text('Test')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _examType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: aether.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
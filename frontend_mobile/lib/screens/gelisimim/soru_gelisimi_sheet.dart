import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/gelisimim_provider.dart';
import '../../services/gelisimim_service.dart';

class SoruGelisimiSheet extends ConsumerStatefulWidget {
  const SoruGelisimiSheet({super.key});

  @override
  ConsumerState<SoruGelisimiSheet> createState() => _SoruGelisimiSheetState();
}

class _SoruGelisimiSheetState extends ConsumerState<SoruGelisimiSheet> {
  // subjectKey → pending count entered by user (0 = not edited yet)
  final Map<String, int> _pending = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(questionSubjectsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                children: [
                  const Text(
                    'Bugün Kaç Soru Çözdün?',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tüm derslerdeki günlük soru sayılarını kaydet',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            // Subject list
            Expanded(
              child: subjectsAsync.when(
                data: (subjects) => ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: subjects.length,
                  separatorBuilder: (context, i) =>
                      const Divider(height: 1, indent: 60),
                  itemBuilder: (_, i) =>
                      _SubjectRow(
                    entry: subjects[i],
                    pendingCount: _pending[subjects[i].key],
                    onEnter: (count) => setState(
                        () => _pending[subjects[i].key] = count),
                  ),
                ),
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Dersler yüklenemedi: $e',
                      style:
                          TextStyle(color: Colors.red.shade400)),
                ),
              ),
            ),
            // Save button
            _SaveButton(
              saving: _saving,
              onSave: _canSave(ref.read(questionSubjectsProvider).valueOrNull)
                  ? () => _save(ref)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  bool _canSave(List<SubjectEntry>? subjects) {
    if (subjects == null) return false;
    return _pending.values.any((c) => c > 0) ||
        subjects.any((s) => s.todayCount > 0);
  }

  Future<void> _save(WidgetRef ref) async {
    final subjects = ref.read(questionSubjectsProvider).valueOrNull;
    if (subjects == null) return;

    // Merge pending into entries
    final toSave = subjects.map((s) {
      final p = _pending[s.key];
      return SubjectEntry(
        key: s.key,
        name: s.name,
        icon: s.icon,
        todayCount: s.todayCount,
        pendingCount: p ?? 0,
      );
    }).toList();

    setState(() => _saving = true);
    try {
      await GelisimimService().saveQuestions(toSave);
      ref.invalidate(questionSubjectsProvider);
      ref.invalidate(gelisimimStatsProvider('all'));
      ref.invalidate(gelisimimStatsProvider('today'));
      ref.invalidate(lessonDistributionProvider('all'));
      ref.invalidate(lessonDistributionProvider('today'));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Soru sayıları başarıyla kaydedildi! 🎉',
                style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Subject Row ──────────────────────────────────────────────────────────────

class _SubjectRow extends StatelessWidget {
  final SubjectEntry entry;
  final int? pendingCount;
  final ValueChanged<int> onEnter;

  const _SubjectRow({
    required this.entry,
    required this.pendingCount,
    required this.onEnter,
  });

  int get _displayCount => pendingCount ?? entry.todayCount;
  bool get _hasSavedData => _displayCount > 0;
  bool get _hasAnyData => _displayCount > 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(entry.icon,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          // Name + count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (_hasAnyData)
                  Text(
                    '$_displayCount soru',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo.shade400,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          // Enter / Edit button
          GestureDetector(
            onTap: () => _showCountDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _hasSavedData
                    ? const Color(0xFFEEF2FF)
                    : const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _hasSavedData ? 'Düzelt' : 'Gir',
                style: TextStyle(
                  color: _hasSavedData
                      ? const Color(0xFF4F46E5)
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _CountDialog(
        subjectName: entry.name,
        initial: _displayCount,
        onApply: (count) {
          Navigator.of(dialogCtx).pop();
          onEnter(count);
        },
      ),
    );
  }
}

// ─── Count Dialog ─────────────────────────────────────────────────────────────

class _CountDialog extends StatefulWidget {
  final String subjectName;
  final int initial;
  final ValueChanged<int> onApply;

  const _CountDialog({
    required this.subjectName,
    required this.initial,
    required this.onApply,
  });

  @override
  State<_CountDialog> createState() => _CountDialogState();
}

class _CountDialogState extends State<_CountDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.initial > 0 ? '${widget.initial}' : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Aynı gün içindeyken bu dersin soru sayısını düzeltebilirsin.',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Soru sayısını gir',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF4F46E5), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final v = int.tryParse(_ctrl.text) ?? 0;
                      widget.onApply(v);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Uygula',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onSave;

  const _SaveButton({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: saving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              disabledBackgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Kaydet',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}

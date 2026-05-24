import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/quick_note.dart';
import '../providers/study_plan_provider.dart';

class QuickNoteSheet extends ConsumerStatefulWidget {
  final ScaffoldMessengerState? messenger;
  const QuickNoteSheet({super.key, this.messenger});

  @override
  ConsumerState<QuickNoteSheet> createState() => _QuickNoteSheetState();
}

class _QuickNoteSheetState extends ConsumerState<QuickNoteSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mq = MediaQuery.of(context);
    // Klavye açıksa viewInsets nav bar'ı zaten kapsar; kapalıysa safe area + 20.
    final bottomPadding = mq.viewInsets.bottom > 0
        ? mq.viewInsets.bottom + 16
        : mq.padding.bottom + 20;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Text('⚡', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hızlı Not Ekle',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(
                    DateFormat('d MMMM yyyy · HH:mm', 'tr_TR')
                        .format(now),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: 'Başlık girin (Opsiyonel)',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Aklına geleni yaz...',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final content = _contentCtrl.text.trim();
                if (content.isEmpty) return;
                final note = QuickNote(
                  id: '${DateTime.now().millisecondsSinceEpoch}',
                  title: _titleCtrl.text.trim().isEmpty
                      ? null
                      : _titleCtrl.text.trim(),
                  content: content,
                  createdAt: DateTime.now(),
                );
                ref.read(quickNotesProvider.notifier).addNote(note);
                Navigator.pop(context);
                widget.messenger?.showSnackBar(
                  const SnackBar(content: Text('Not kaydedildi.')),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

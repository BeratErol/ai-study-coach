import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';

class ExamResultScreen extends ConsumerStatefulWidget {
  const ExamResultScreen({super.key});

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  String   _examType = 'TYT';
  DateTime _examDate = DateTime.now();
  bool     _saving   = false;

  static const _examTypes = ['TYT', 'AYT', 'YDT', 'BRANŞ'];

  final List<_LessonEntry> _entries = [
    _LessonEntry('Türkçe'),
    _LessonEntry('Matematik'),
    _LessonEntry('Fen Bilimleri'),
    _LessonEntry('Sosyal Bilimler'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  double _net(_LessonEntry e) {
    final c = int.tryParse(e.correctCtrl.text) ?? 0;
    final w = int.tryParse(e.wrongCtrl.text) ?? 0;
    return c - (w / 4.0);
  }

  double get _totalNet =>
      _entries.fold(0.0, (sum, e) => sum + _net(e));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final details = _entries
          .where((e) =>
              (int.tryParse(e.correctCtrl.text) ?? 0) > 0 ||
              (int.tryParse(e.wrongCtrl.text) ?? 0) > 0)
          .map((e) => {
                'lessonName': e.name,
                'correct':    int.tryParse(e.correctCtrl.text) ?? 0,
                'incorrect':  int.tryParse(e.wrongCtrl.text) ?? 0,
              })
          .toList();

      await ApiService().dio.post('/Exam', data: {
        'title':   _titleCtrl.text.trim(),
        'type':    _examType,
        'date':    _examDate.toUtc().toIso8601String(),
        'details': details,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deneme sonucu kaydedildi!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/stats');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deneme kaydedilirken hata oluştu.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deneme Sonucu Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Exam info ─────────────────────────────────────────────────
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deneme Adı',
                  hintText: 'Örn: Türkiye Geneli 3D TYT',
                  prefixIcon: Icon(Icons.edit_document),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Deneme adı gerekli' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _examType,
                      decoration: const InputDecoration(
                        labelText: 'Tür',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: _examTypes
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _examType = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 15),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .inputDecorationTheme
                              .fillColor,
                          borderRadius: AppRadius.md,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_examDate.day}.${_examDate.month}.${_examDate.year}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Total net preview ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Toplam Net',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        Text('Canlı hesaplama',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    Text(
                      _totalNet.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Lesson entries ────────────────────────────────────────────
              const Text('Ders Bazlı Sonuçlar',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              ...List.generate(_entries.length, (i) {
                final entry = _entries[i];
                final net   = _net(entry);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: AppRadius.lg,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: net >= 0
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: AppRadius.full,
                            ),
                            child: Text(
                              'Net: ${net.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: net >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: entry.correctCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Doğru',
                                prefixIcon: Icon(Icons.check_circle_rounded,
                                    color: AppColors.success, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: entry.wrongCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Yanlış',
                                prefixIcon: Icon(Icons.cancel_rounded,
                                    color: AppColors.error, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Kaydet', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonEntry {
  final String name;
  final TextEditingController correctCtrl = TextEditingController();
  final TextEditingController wrongCtrl   = TextEditingController();

  _LessonEntry(this.name);

  void dispose() {
    correctCtrl.dispose();
    wrongCtrl.dispose();
  }
}

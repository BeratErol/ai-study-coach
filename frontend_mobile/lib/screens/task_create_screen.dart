import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import 'lessons_screen.dart' show lessonsListProvider;

class TaskCreateScreen extends ConsumerStatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  ConsumerState<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends ConsumerState<TaskCreateScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _aiPromptCtrl = TextEditingController();

  int       _selectedColorIdx = 0;
  DateTime? _plannedDate;
  bool      _saving    = false;
  bool      _aiLoading = false;
  String?   _aiAdvice;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aiPromptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateAiPlan() async {
    final prompt = _aiPromptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() { _aiLoading = true; _aiAdvice = null; });
    try {
      final res = await ApiService().postAiPlan(prompt);
      if (res != null && res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        setState(() {
          _nameCtrl.text = data['suggestedName'] as String? ?? '';
          _aiAdvice      = data['advice'] as String?;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
      );
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final color = AppColors.lessonColors[_selectedColorIdx];
      final hex   = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
      await ApiService().dio.post('/Lesson', data: {
        'name':        _nameCtrl.text.trim(),
        'colorCode':   hex,
        'plannedDate': _plannedDate?.toUtc().toIso8601String(),
      });
      ref.invalidate(lessonsListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ders başarıyla oluşturuldu!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/lessons');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ders oluşturulurken hata oluştu.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _plannedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Ders Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AI Planner ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('AI ile Otomatik Planla',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _aiPromptCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Örn: Vizeye 3 gün kaldı, matematik...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.15),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.md,
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _aiLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : GestureDetector(
                                onTap: _generateAiPlan,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: AppRadius.md,
                                  ),
                                  child: const Icon(Icons.send_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                      ],
                    ),
                    if (_aiAdvice != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: AppRadius.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_rounded,
                                color: AppColors.secondary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _aiAdvice!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Name ──────────────────────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ders / Konu Adı',
                  hintText: 'Örn: Matematik - Türev',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ders adı gerekli' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Color picker ──────────────────────────────────────────────
              const Text('Renk',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children:
                    List.generate(AppColors.lessonColors.length, (i) {
                  final c   = AppColors.lessonColors[i];
                  final sel = _selectedColorIdx == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIdx = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: sel
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Planned date ──────────────────────────────────────────────
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _plannedDate == null
                            ? 'Hedef tarih seç (opsiyonel)'
                            : '${_plannedDate!.day}.${_plannedDate!.month}.${_plannedDate!.year}',
                        style: TextStyle(
                          color: _plannedDate == null
                              ? AppColors.textHint
                              : null,
                        ),
                      ),
                      if (_plannedDate != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _plannedDate = null),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textHint),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Save button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Oluştur',
                          style: TextStyle(fontSize: 16)),
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

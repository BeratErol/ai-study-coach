import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../models/subject_data.dart';
import '../../providers/onboarding_provider.dart';

class Step8Subjects extends ConsumerWidget {
  const Step8Subjects({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);

    if (data.targetExam == 'OkulSinavi') {
      return _OkulSinaviSubjectsStep(data: data, ref: ref);
    }

    final n = ref.read(onboardingProvider.notifier);
    final subjects = getSubjectsForExam(data.targetExam, data.selectedArea);

    return _StandardSubjectsStep(data: data, notifier: n, subjects: subjects);
  }
}

// ── Standard step (non-OkulSinavi) ──────────────────────────────────────────

class _StandardSubjectsStep extends StatelessWidget {
  final dynamic data;
  final dynamic notifier;
  final List<SubjectData> subjects;

  const _StandardSubjectsStep({
    required this.data,
    required this.notifier,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📚', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(
                'Derslerini Belirle',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Güçlü Dersler ──
          _SectionHeader(
            emoji: '💪',
            title: 'Güçlü Olduğun / Daha Az Çalışmak İstediğin Dersler',
            subtitle: "Çalışma planının %25'i bu derslerden oluşacak.",
            color: const Color(0xFF2E7D32),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: const Color(0xFFC8E6C9)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: _SubjectGrid(
              subjects: subjects,
              selectedSubjects: data.strongSubjects,
              disabledSubjects: data.weakSubjects,
              selectedColor: const Color(0xFF2E7D32),
              selectedBg: const Color(0xFFE8F5E9),
              onToggle: (name) {
                final updated = List<String>.from(data.strongSubjects);
                if (updated.contains(name)) {
                  updated.remove(name);
                } else {
                  updated.add(name);
                }
                notifier.updateStrongSubjects(updated);
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Zayıf Dersler ──
          _SectionHeader(
            emoji: '⚡',
            title: 'Zorlandığın / Daha Çok Çalışmak İstediğin Dersler',
            subtitle: "Çalışma planının %75'i bu derslerden oluşacak. En az 1 ders seçmelisin.",
            color: const Color(0xFFE65100),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: const Color(0xFFFFCC80)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: _SubjectGrid(
              subjects: subjects,
              selectedSubjects: data.weakSubjects,
              disabledSubjects: data.strongSubjects,
              selectedColor: const Color(0xFFE65100),
              selectedBg: const Color(0xFFFFF3E0),
              onToggle: (name) {
                final updated = List<String>.from(data.weakSubjects);
                if (updated.contains(name)) {
                  updated.remove(name);
                } else {
                  updated.add(name);
                }
                notifier.updateWeakSubjects(updated);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── OkulSinavi step ──────────────────────────────────────────────────────────

class _OkulSinaviSubjectsStep extends ConsumerStatefulWidget {
  final dynamic data;
  final WidgetRef ref;

  const _OkulSinaviSubjectsStep({required this.data, required this.ref});

  @override
  ConsumerState<_OkulSinaviSubjectsStep> createState() =>
      _OkulSinaviSubjectsStepState();
}

class _OkulSinaviSubjectsStepState
    extends ConsumerState<_OkulSinaviSubjectsStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSubject(String name, dynamic n, dynamic data) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (!data.customSubjects.contains(trimmed)) {
      final updated = List<String>.from(data.customSubjects)..add(trimmed);
      n.updateCustomSubjects(updated);
    }
    _controller.clear();
  }

  void _removeSubject(String name, dynamic n, dynamic data) {
    final updatedCustom = List<String>.from(data.customSubjects)..remove(name);
    n.updateCustomSubjects(updatedCustom);
    final updatedStrong = List<String>.from(data.strongSubjects)..remove(name);
    n.updateStrongSubjects(updatedStrong);
    final updatedWeak = List<String>.from(data.weakSubjects)..remove(name);
    n.updateWeakSubjects(updatedWeak);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final n = ref.read(onboardingProvider.notifier);
    // uni_diger = fully manual; all other areas have a predefined base pool
    final isFullyManual = data.selectedArea == 'uni_diger';

    final baseSubjects = isFullyManual
        ? <SubjectData>[]
        : getSubjectsForExam(data.targetExam, data.selectedArea);
    final baseNames = baseSubjects.map((s) => s.name).toSet();

    final extraNames = List<String>.from(data.customSubjects)
        .where((n) => !baseNames.contains(n))
        .toList();

    final allSubjects = [
      ...baseSubjects,
      ...extraNames.map((name) => SubjectData(name: name, emoji: '📝')),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📚', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFullyManual ? 'Derslerini Ekle' : 'Derslerini Belirle',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isFullyManual
                ? 'Sınava gireceğin dersleri aşağıya ekle, sonra güçlü/zayıf olarak işaretle.'
                : 'Listeye ek ders ekleyebilir ya da eklediğin dersleri çıkarabilirsin.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          _AddSubjectField(
            controller: _controller,
            onAdd: (name) => _addSubject(name, n, data),
          ),
          const SizedBox(height: 20),

          // Predefined pool (non-manual areas)
          if (!isFullyManual && baseSubjects.isNotEmpty) ...[
            _SectionHeader(
              emoji: '📋',
              title: 'Ders Havuzu',
              subtitle: 'Eklediğin dersler de havuza dahil edilir.',
              color: AppColors.primary,
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: _EditableSubjectPool(
                subjects: allSubjects,
                removableNames: extraNames.toSet(),
                onRemove: (name) => _removeSubject(name, n, data),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Fully manual: show added subjects
          if (isFullyManual && allSubjects.isNotEmpty) ...[
            _SectionHeader(
              emoji: '📋',
              title: 'Eklenen Dersler',
              subtitle: 'Tüm dersler kendi seçimindir.',
              color: AppColors.primary,
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: _EditableSubjectPool(
                subjects: allSubjects,
                removableNames: allSubjects.map((s) => s.name).toSet(),
                onRemove: (name) => _removeSubject(name, n, data),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (isFullyManual && allSubjects.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: AppRadius.lg,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Center(
                child: Text(
                  'Henüz ders eklenmedi. Yukarıdan ders ekle.',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (allSubjects.isNotEmpty) ...[
            // ── Güçlü Dersler ──
            _SectionHeader(
              emoji: '💪',
              title: 'Güçlü Olduğun / Daha Az Çalışmak İstediğin Dersler',
              subtitle: "Çalışma planının %25'i bu derslerden oluşacak.",
              color: const Color(0xFF2E7D32),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: const Color(0xFFC8E6C9)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: _SubjectGrid(
                subjects: allSubjects,
                selectedSubjects: data.strongSubjects,
                disabledSubjects: data.weakSubjects,
                selectedColor: const Color(0xFF2E7D32),
                selectedBg: const Color(0xFFE8F5E9),
                onToggle: (name) {
                  final updated = List<String>.from(data.strongSubjects);
                  if (updated.contains(name)) {
                    updated.remove(name);
                  } else {
                    updated.add(name);
                  }
                  n.updateStrongSubjects(updated);
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Zayıf Dersler ──
            _SectionHeader(
              emoji: '⚡',
              title: 'Zorlandığın / Daha Çok Çalışmak İstediğin Dersler',
              subtitle: "Çalışma planının %75'i bu derslerden oluşacak. En az 1 ders seçmelisin.",
              color: const Color(0xFFE65100),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: const Color(0xFFFFCC80)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: _SubjectGrid(
                subjects: allSubjects,
                selectedSubjects: data.weakSubjects,
                disabledSubjects: data.strongSubjects,
                selectedColor: const Color(0xFFE65100),
                selectedBg: const Color(0xFFFFF3E0),
                onToggle: (name) {
                  final updated = List<String>.from(data.weakSubjects);
                  if (updated.contains(name)) {
                    updated.remove(name);
                  } else {
                    updated.add(name);
                  }
                  n.updateWeakSubjects(updated);
                },
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $title',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSubjectField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onAdd;

  const _AddSubjectField({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Ders adı yaz (örn. Fizik)',
              hintStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onSubmitted: onAdd,
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => onAdd(controller.text),
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}

class _EditableSubjectPool extends StatelessWidget {
  final List<SubjectData> subjects;
  final Set<String> removableNames;
  final void Function(String) onRemove;

  const _EditableSubjectPool({
    required this.subjects,
    required this.removableNames,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return Text(
        'Henüz ders eklenmedi.',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 13,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subjects.map((s) {
        final canRemove = removableNames.contains(s.name);
        return Container(
          padding: EdgeInsets.only(
              left: 10, right: canRemove ? 4 : 10, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: AppRadius.md,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                s.name,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              if (canRemove) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onRemove(s.name),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  final List<SubjectData> subjects;
  final List<String> selectedSubjects;
  final List<String> disabledSubjects;
  final Color selectedColor;
  final Color selectedBg;
  final void Function(String name) onToggle;

  const _SubjectGrid({
    required this.subjects,
    required this.selectedSubjects,
    required this.disabledSubjects,
    required this.selectedColor,
    required this.selectedBg,
    required this.onToggle,
  });

  bool get _hasMultipleGroups =>
      subjects.any((s) => s.group == 'tyt') && subjects.any((s) => s.group == 'ayt');

  @override
  Widget build(BuildContext context) {
    if (!_hasMultipleGroups) {
      return _buildChips(context, subjects);
    }

    final tytSubjects = subjects.where((s) => s.group == 'tyt').toList();
    final aytSubjects = subjects.where((s) => s.group == 'ayt').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GroupLabel(label: '📘 TYT Dersleri', color: const Color(0xFF1565C0)),
        const SizedBox(height: 8),
        _buildChips(context, tytSubjects),
        const SizedBox(height: 12),
        _GroupLabel(label: '📙 AYT Dersleri', color: const Color(0xFFE65100)),
        const SizedBox(height: 8),
        _buildChips(context, aytSubjects),
      ],
    );
  }

  Widget _buildChips(BuildContext context, List<SubjectData> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((s) {
        final isSelected = selectedSubjects.contains(s.name);
        final isDisabled = disabledSubjects.contains(s.name);

        return GestureDetector(
          onTap: isDisabled ? null : () => onToggle(s.name),
          child: Opacity(
            opacity: isDisabled ? 0.35 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : Theme.of(context).cardColor,
                borderRadius: AppRadius.md,
                border: Border.all(
                  color: isSelected ? selectedColor : Theme.of(context).dividerColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    s.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? selectedColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _GroupLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

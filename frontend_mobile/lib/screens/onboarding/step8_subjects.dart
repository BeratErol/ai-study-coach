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
    final n = ref.read(onboardingProvider.notifier);
    final subjects = getSubjectsForExam(data.targetExam, data.selectedArea);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('📚', style: TextStyle(fontSize: 26)),
              SizedBox(width: 8),
              Text(
                'Derslerini Belirle',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Güçlü Dersler ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💪 Güçlü Olduğun / Daha Az Çalışmak İstediğin Dersler',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  "Çalışma planının %25'i bu derslerden oluşacak.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
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
                n.updateStrongSubjects(updated);
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Zayıf Dersler ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚡ Zorlandığın / Daha Çok Çalışmak İstediğin Dersler',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  "Çalışma planının %75'i bu derslerden oluşacak. En az 1 ders seçmelisin.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
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
                n.updateWeakSubjects(updated);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
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
      return _buildChips(subjects);
    }

    final tytSubjects = subjects.where((s) => s.group == 'tyt').toList();
    final aytSubjects = subjects.where((s) => s.group == 'ayt').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GroupLabel(label: '📘 TYT Dersleri', color: const Color(0xFF1565C0)),
        const SizedBox(height: 8),
        _buildChips(tytSubjects),
        const SizedBox(height: 12),
        _GroupLabel(label: '📙 AYT Dersleri', color: const Color(0xFFE65100)),
        const SizedBox(height: 8),
        _buildChips(aytSubjects),
      ],
    );
  }

  Widget _buildChips(List<SubjectData> items) {
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
                color: isSelected ? selectedBg : Colors.white,
                borderRadius: AppRadius.md,
                border: Border.all(
                  color: isSelected ? selectedColor : AppColors.borderLight,
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
                      color: isSelected ? selectedColor : AppColors.textPrimary,
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

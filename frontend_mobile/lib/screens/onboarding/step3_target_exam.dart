import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../providers/onboarding_provider.dart';

class _ExamOption {
  final String icon;
  final String title;
  final String subtitle;
  final String value;
  const _ExamOption(this.icon, this.title, this.subtitle, this.value);
}

const _examsByLevel = {
  'ortaokul': [
    _ExamOption('📋', 'LGS', 'Liselere Geçiş Sınavı (8. Sınıf)', 'LGS'),
    _ExamOption('🏫', 'Okul Sınavlarım', 'Yazılı sınavlar için hazırlan', 'OkulSinavi'),
  ],
  'lise': [
    _ExamOption('🎓', 'YKS', 'Yükseköğretim Kurumları Sınavı', 'YKS'),
    _ExamOption('🏫', 'Okul Sınavlarım', 'Yazılı sınavlar için hazırlan', 'OkulSinavi'),
  ],
  'universite': [
    _ExamOption('🏢', 'KPSS', 'Kamu Personeli Seçme Sınavı', 'KPSS'),
    _ExamOption('📐', 'ALES', 'Akademik Personel ve Lisansüstü Eğitimi Giriş Sınavı', 'ALES'),
    _ExamOption('🌐', 'YDS', 'Yabancı Dil Sınavı', 'YDS'),
    _ExamOption('👩‍🏫', 'Öğretmenlik', 'AGS ve ÖABT', 'Öğretmenlik'),
    _ExamOption('🏛️', 'Okul Sınavlarım', 'Vize/Final sınavları için hazırlan', 'OkulSinavi'),
  ],
};

class Step3TargetExam extends ConsumerWidget {
  const Step3TargetExam({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final exams = _examsByLevel[data.educationLevel] ?? _examsByLevel['lise']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(
                'Hedefin Ne?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.educationLevel == 'ortaokul'
                ? 'Ortaokul için uygun hedefler'
                : 'Sınav hedefini seç',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ...exams.map(
            (exam) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExamCard(
                option: exam,
                selected: data.targetExam == exam.value,
                onTap: () {
                  notifier.updateTargetExam(exam.value);
                  notifier.updateSelectedArea('');
                  notifier.updateStrongSubjects([]);
                  notifier.updateWeakSubjects([]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final _ExamOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ExamCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : Theme.of(context).cardColor,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: selected ? AppColors.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(option.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: selected ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

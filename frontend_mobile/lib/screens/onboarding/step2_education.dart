import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../providers/onboarding_provider.dart';

class Step2Education extends ConsumerWidget {
  const Step2Education({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).educationLevel;
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🎓', style: TextStyle(fontSize: 26)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Eğitim Serüveninde Hangi Kademedesin?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _EducationCard(
            emoji: '🏫',
            title: 'Ortaokul',
            subtitle: '5, 6, 7 veya 8. sınıf',
            selected: selected == 'ortaokul',
            onTap: () {
              notifier.updateEducationLevel('ortaokul');
              notifier.updateTargetExam('');
              notifier.updateSelectedArea('');
              notifier.updateStrongSubjects([]);
              notifier.updateWeakSubjects([]);
            },
          ),
          const SizedBox(height: 12),
          _EducationCard(
            emoji: '🏛️',
            title: 'Lise',
            subtitle: '9, 10, 11 veya 12. sınıf',
            selected: selected == 'lise',
            onTap: () {
              notifier.updateEducationLevel('lise');
              notifier.updateTargetExam('');
              notifier.updateSelectedArea('');
              notifier.updateStrongSubjects([]);
              notifier.updateWeakSubjects([]);
            },
          ),
          const SizedBox(height: 12),
          _EducationCard(
            emoji: '🎓',
            title: 'Üniversite / Mezun',
            subtitle: 'AGS, ÖABT, KPSS Lisans/Önlisans, ALES, YDS',
            selected: selected == 'universite',
            onTap: () {
              notifier.updateEducationLevel('universite');
              notifier.updateTargetExam('');
              notifier.updateSelectedArea('');
              notifier.updateStrongSubjects([]);
              notifier.updateWeakSubjects([]);
            },
          ),
        ],
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _EducationCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
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
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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

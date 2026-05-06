import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../providers/onboarding_provider.dart';

class Step5StudyType extends ConsumerWidget {
  const Step5StudyType({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).studyType;
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('⏰', style: TextStyle(fontSize: 26)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ne Zaman Daha Verimlisin?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Programını buna göre optimize edeceğiz. Sabah Kuşunu seçersen programın, dersi başlatma ve iş/okul çıkış saatine göre günün uygun olan ilk saatinde başlayacak. Gece Baykuşunu seçersen programın, en geç ders bitiş saatinde bitecek şekilde ayarlanacak.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _StudyTypeCard(
            emoji: '🌅',
            title: 'Sabah Kuşu',
            subtitle: 'Program, derslerimi müsait olduğum en erken saatte başlatsın',
            selected: selected == 'sabah',
            onTap: () => notifier.updateStudyType('sabah'),
          ),
          const SizedBox(height: 12),
          _StudyTypeCard(
            emoji: '🌙',
            title: 'Gece Baykuşu',
            subtitle: 'Program, derslerimi müsait olduğum en geç saatte bitirsin',
            selected: selected == 'gece',
            onTap: () => notifier.updateStudyType('gece'),
          ),
        ],
      ),
    );
  }
}

class _StudyTypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _StudyTypeCard({
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

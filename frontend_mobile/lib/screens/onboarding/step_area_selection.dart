import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../providers/onboarding_provider.dart';

class _AreaOption {
  final String icon;
  final String title;
  final String subtitle;
  final String value;
  const _AreaOption(this.icon, this.title, this.subtitle, this.value);
}

const _yksOptions = [
  _AreaOption('📘', 'Sadece TYT', 'Sadece TYT dersleri ve TYT denemeleri', 'sadece_tyt'),
  _AreaOption('🔢', 'Sayısal (MF)', 'Matematik, Fizik, Kimya, Biyoloji', 'sayisal'),
  _AreaOption('⚖️', 'Eşit Ağırlık (TM)', 'Matematik, Edebiyat, Tarih, Coğrafya', 'esit_agirlik'),
  _AreaOption('📚', 'Sözel (TS)', 'Edebiyat, Tarih, Coğrafya, Felsefe', 'sozel'),
  _AreaOption('🌐', 'Dil', 'Yabancı Dil (İngilizce)', 'dil'),
];

const _kpssOptions = [
  _AreaOption('💼', 'KPSS Lisans', 'Genel Yetenek - Genel Kültür', 'kpss_lisans'),
  _AreaOption('📁', 'KPSS Önlisans', 'Genel Yetenek - Genel Kültür', 'kpss_onlisans'),
];

class StepAreaSelection extends ConsumerWidget {
  const StepAreaSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final isYKS = data.targetExam == 'YKS';
    final options = isYKS ? _yksOptions : _kpssOptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🗺️', style: TextStyle(fontSize: 26)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hangi Alandan Hazırlanıyorsun?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bu seçim ders havuzunu belirleyecek',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ...options.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AreaCard(
                option: opt,
                selected: data.selectedArea == opt.value,
                onTap: () {
                  notifier.updateSelectedArea(opt.value);
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

class _AreaCard extends StatelessWidget {
  final _AreaOption option;
  final bool selected;
  final VoidCallback onTap;

  const _AreaCard({
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
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
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
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
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

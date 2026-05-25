import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../providers/onboarding_provider.dart';

class Step1NameGender extends ConsumerStatefulWidget {
  const Step1NameGender({super.key});

  @override
  ConsumerState<Step1NameGender> createState() => _Step1NameGenderState();
}

class _Step1NameGenderState extends ConsumerState<Step1NameGender> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(onboardingProvider).name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👋', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(
                'Merhaba!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bilgilerini girerek başlayalım. Seni tam olarak tanımalıyım ki sana özel haftalık programını oluşturabileyim. Bu programı beğenmezsen yeni program için bilgilerini Profilim sekmesinden değiştirebilirsin.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'İsmin',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: AppRadius.md,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: TextField(
              controller: _nameCtrl,
              onChanged: notifier.updateName,
              decoration: const InputDecoration(
                hintText: 'İsmin...',
                prefixIcon: Icon(Icons.person, color: AppColors.primary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cinsiyetin',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  emoji: '🧑‍🎓',
                  label: 'Erkek',
                  selected: data.gender == 'erkek',
                  onTap: () => notifier.updateGender('erkek'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderCard(
                  emoji: '👩‍🎓',
                  label: 'Kız',
                  selected: data.gender == 'kiz',
                  onTap: () => notifier.updateGender('kiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : Theme.of(context).cardColor,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: selected ? AppColors.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

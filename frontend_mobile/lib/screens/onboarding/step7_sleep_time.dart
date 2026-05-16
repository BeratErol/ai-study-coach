import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../providers/onboarding_provider.dart';

TimeOfDay _parseTime(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

String _fmt(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class Step7SleepTime extends ConsumerWidget {
  const Step7SleepTime({super.key});

  Future<void> _pick(
    BuildContext context,
    String current,
    void Function(String) onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(current),
    );
    if (picked != null) onPicked(_fmt(picked));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);
    final n = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⏳', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Çalışma Saatlerin En Geç Kaça Kadar?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sistem, uyku ve dinlenme saatlerine saygı duyarak yarına sarkma miktarını hesaplar. Eğer ki Gece Baykuşuysan dersler belirlediğin saatte bitecek.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _TimePickerCard(
            label: 'Hafta İçi En Geç',
            value: data.weekdayLatestTime,
            onTap: () => _pick(
              context,
              data.weekdayLatestTime,
              n.updateWeekdayLatestTime,
            ),
          ),
          const SizedBox(height: 12),
          _TimePickerCard(
            label: 'Hafta Sonu En Geç',
            value: data.weekendLatestTime,
            onTap: () => _pick(
              context,
              data.weekendLatestTime,
              n.updateWeekendLatestTime,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimePickerCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppRadius.lg,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryO10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}

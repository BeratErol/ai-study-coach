import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../providers/onboarding_provider.dart';

const _dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cts', 'Paz'];

TimeOfDay _parseTime(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

String _fmt(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class Step6DailyRoutine extends ConsumerWidget {
  const Step6DailyRoutine({super.key});

  Future<void> _pickTime(
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
              const Text('🏫', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Okul & Çalışma Planın',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Haftalık planını okul, kurs ve iş saatlerine göre otomatikleştireceğiz.',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          // ── Hafta İçi ──
          _sectionTitle('Hafta İçi'),
          const SizedBox(height: 12),
          _switchRow(
            label: 'Okulum / İşim var',
            value: data.hasWeekdaySchool,
            onChanged: n.updateHasWeekdaySchool,
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: data.hasWeekdaySchool ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !data.hasWeekdaySchool,
                child: SizedBox(
                  height: data.hasWeekdaySchool ? null : 0,
                  child: _timeCard(context, [
                    _TimeRow(
                      label: 'Okul/İş Başlangıç Saati',
                      value: data.weekdayStartTime,
                      onTap: () => _pickTime(
                        context,
                        data.weekdayStartTime,
                        n.updateWeekdayStartTime,
                      ),
                    ),
                    _TimeRow(
                      label: 'Okul/İş Bitiş Saati',
                      value: data.weekdayEndTime,
                      onTap: () => _pickTime(
                        context,
                        data.weekdayEndTime,
                        n.updateWeekdayEndTime,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hafta İçi Günlük Çalışma Saatin: ${data.weekdayStudyHours} Saat',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Slider(
            min: 1,
            max: 8,
            divisions: 7,
            value: data.weekdayStudyHours.toDouble(),
            activeColor: AppColors.primary,
            onChanged: (v) => n.updateWeekdayStudyHours(v.round()),
          ),
          const SizedBox(height: 20),

          // ── Hafta Sonu ──
          _sectionTitle('Hafta Sonu'),
          const SizedBox(height: 12),
          _switchRow(
            label: 'Hafta sonu kursum / işim var',
            value: data.hasWeekendCourse,
            onChanged: n.updateHasWeekendCourse,
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: data.hasWeekendCourse ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !data.hasWeekendCourse,
                child: SizedBox(
                  height: data.hasWeekendCourse ? null : 0,
                  child: _timeCard(context, [
                    _TimeRow(
                      label: 'Derse Başlama Saati',
                      value: data.weekendStartTime,
                      onTap: () => _pickTime(
                        context,
                        data.weekendStartTime,
                        n.updateWeekendStartTime,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hafta Sonu Günlük Çalışma Saatin: ${data.weekendStudyHours} Saat',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Slider(
            min: 1,
            max: 8,
            divisions: 7,
            value: data.weekendStudyHours.toDouble(),
            activeColor: AppColors.primary,
            onChanged: (v) => n.updateWeekendStudyHours(v.round()),
          ),
          const SizedBox(height: 20),

          // ── Tatil Günleri ──
          _sectionTitle('Ders Olmasını İstemediğin Günler'),
          const SizedBox(height: 6),
          Text(
            'Seçtiğin günlerde programa ders atanmaz.',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final selected = data.offDays.contains(i);
              return GestureDetector(
                onTap: () {
                  final updated = List<int>.from(data.offDays);
                  if (selected) {
                    updated.remove(i);
                  } else {
                    updated.add(i);
                  }
                  n.updateOffDays(updated);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Theme.of(context).cardColor,
                    borderRadius: AppRadius.full,
                    border: Border.all(
                      color: selected ? AppColors.primary : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    _dayLabels[i],
                    style: TextStyle(
                      color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );

  Widget _switchRow({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: AppColors.primary),
      ],
    );
  }

  Widget _timeCard(BuildContext context, List<_TimeRow> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.md,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.borderLight),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

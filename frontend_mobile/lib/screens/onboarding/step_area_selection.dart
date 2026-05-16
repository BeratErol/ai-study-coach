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

// ── YKS ──────────────────────────────────────────────────────────────────────
const _yksOptions = [
  _AreaOption('📘', 'Sadece TYT', 'Sadece TYT dersleri ve TYT denemeleri', 'sadece_tyt'),
  _AreaOption('🔢', 'Sayısal (MF)', 'Matematik, Fizik, Kimya, Biyoloji', 'sayisal'),
  _AreaOption('⚖️', 'Eşit Ağırlık (TM)', 'Matematik, Edebiyat, Tarih, Coğrafya', 'esit_agirlik'),
  _AreaOption('📚', 'Sözel (TS)', 'Edebiyat, Tarih, Coğrafya, Felsefe', 'sozel'),
  _AreaOption('🌐', 'Dil', 'Yabancı Dil (İngilizce)', 'dil'),
];

// ── KPSS ─────────────────────────────────────────────────────────────────────
const _kpssOptions = [
  _AreaOption('💼', 'KPSS Lisans', 'Genel Yetenek - Genel Kültür', 'kpss_lisans'),
  _AreaOption('📁', 'KPSS Önlisans', 'Genel Yetenek - Genel Kültür', 'kpss_onlisans'),
];

// ── OkulSinavi — Ortaokul (sınıf) ────────────────────────────────────────────
const _okulOrtaokulOptions = [
  _AreaOption('5️⃣', '5. Sınıf', 'Türkçe, Matematik, Fen, Sosyal, İngilizce, Din', 'sinif_5'),
  _AreaOption('6️⃣', '6. Sınıf', 'Türkçe, Matematik, Fen, Sosyal, İngilizce, Din', 'sinif_6'),
  _AreaOption('7️⃣', '7. Sınıf', 'Türkçe, Matematik, Fen, Sosyal, İngilizce, Din', 'sinif_7'),
  _AreaOption('8️⃣', '8. Sınıf', 'Türkçe, Matematik, Fen, İnkılap, İngilizce, Din', 'sinif_8'),
];

// ── OkulSinavi — Lise 9-10 ────────────────────────────────────────────────────
const _okulLise910Options = [
  _AreaOption('9️⃣', '9. Sınıf', 'Matematik, Fizik, Kimya, Biyoloji, Tarih, Edebiyat, Coğrafya, Din, İngilizce, Almanca', 'lise_9'),
  _AreaOption('🔟', '10. Sınıf', 'Matematik, Fizik, Kimya, Biyoloji, Tarih, Edebiyat, Coğrafya, Din, İngilizce, Almanca, Felsefe', 'lise_10'),
];

// ── OkulSinavi — Lise 11-12 alan seçimi ─────────────────────────────────────
const _okulLise1112Options = [
  _AreaOption('🔢', '11-12 Sayısal (MF)', 'Ortak Dersler (Edebiyat, Tarih…) + Seçmeli Matematik, Fizik, Kimya, Biyoloji', 'lise_1112_sayisal'),
  _AreaOption('⚖️', '11-12 Eşit Ağırlık (EA)', 'Ortak Dersler (Felsefe, İngilizce…) + Seçmeli Matematik, Edebiyat, Coğrafya', 'lise_1112_ea'),
  _AreaOption('📚', '11-12 Sözel (TS)', 'Ortak Dersler (Tarih, İngilizce…) + Seçmeli Edebiyat, Coğrafya, Psikoloji', 'lise_1112_sozel'),
  _AreaOption('🌐', '11-12 Dil (YDT)', 'Ortak Dersler (Tarih, Felsefe…) + İngilizce, İngilizce Edebiyatı, Almanca', 'lise_1112_dil'),
];

// ── OkulSinavi — Üniversite bölüm seçimi ─────────────────────────────────────
const _okulUniversiteOptions = [
  _AreaOption('💻', 'Yazılım / Bilgisayar', 'Algoritma, Veri Yapıları, Diferansiyel…', 'uni_yazilim'),
  _AreaOption('🏥', 'Tıp', 'Anatomi, Fizyoloji, Biyokimya, Histoloji…', 'uni_tip'),
  _AreaOption('⚖️', 'Hukuk', 'Medeni, Borçlar, Ticaret, Ceza, İdare Hukuku…', 'uni_hukuk'),
  _AreaOption('🧠', 'Psikoloji', 'Genel, Gelişim, Sosyal, Klinik Psikoloji…', 'uni_psikoloji'),
  _AreaOption('📈', 'İşletme / Ekonomi', 'Muhasebe, Finans, Pazarlama, Yönetim…', 'uni_isletme'),
  _AreaOption('⚙️', 'Mühendislik', 'Diferansiyel, Fizik, Kimya, Termodinamik…', 'uni_muhendislik'),
  _AreaOption('🏫', 'Eğitim / Öğretmenlik', 'Eğitim Psikolojisi, Öğretim Yöntemleri…', 'uni_egitim'),
  _AreaOption('✏️', 'Diğer / Kendi Ekle', 'Tüm dersleri kendin belirle', 'uni_diger'),
];

class StepAreaSelection extends ConsumerWidget {
  const StepAreaSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    final isYKS = data.targetExam == 'YKS';
    final isKPSS = data.targetExam == 'KPSS';
    final isOkul = data.targetExam == 'OkulSinavi';

    String title;
    String subtitle;
    List<_AreaOption> options;

    if (isYKS) {
      title = 'Hangi Alandan Hazırlanıyorsun?';
      subtitle = 'Bu seçim ders havuzunu belirleyecek';
      options = _yksOptions;
    } else if (isKPSS) {
      title = 'Hangi KPSS\'ye Hazırlanıyorsun?';
      subtitle = 'Bu seçim ders havuzunu belirleyecek';
      options = _kpssOptions;
    } else if (isOkul) {
      final edu = data.educationLevel;
      if (edu == 'ortaokul') {
        title = 'Kaçıncı Sınıftasın?';
        subtitle = 'Sınıfına göre ders havuzu belirlenir';
        options = _okulOrtaokulOptions;
      } else if (edu == 'lise') {
        title = 'Kaçıncı Sınıftasın?';
        subtitle = '11-12. sınıflar için alan seçimi de yapılır';
        options = [..._okulLise910Options, ..._okulLise1112Options];
      } else {
        // universite / mezun
        title = 'Hangi Bölümdesin?';
        subtitle = 'Bölümüne uygun ders havuzu hazırlanır';
        options = _okulUniversiteOptions;
      }
    } else {
      title = 'Alan Seçimi';
      subtitle = 'Bu seçim ders havuzunu belirleyecek';
      options = _kpssOptions;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isOkul ? '🏫' : '🗺️', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Group label for lise (9-10 vs 11-12)
          if (isOkul && data.educationLevel == 'lise') ...[
            _GroupDivider(label: '9. ve 10. Sınıf'),
            const SizedBox(height: 8),
            ..._okulLise910Options.map((opt) => _optionCard(opt, data, notifier)),
            const SizedBox(height: 12),
            _GroupDivider(label: '11. ve 12. Sınıf — Alan Seçimi'),
            const SizedBox(height: 8),
            ..._okulLise1112Options.map((opt) => _optionCard(opt, data, notifier)),
          ] else ...[
            ...options.map((opt) => _optionCard(opt, data, notifier)),
          ],
        ],
      ),
    );
  }

  Widget _optionCard(_AreaOption opt, dynamic data, dynamic notifier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _AreaCard(
        option: opt,
        selected: data.selectedArea == opt.value,
        onTap: () {
          notifier.updateSelectedArea(opt.value);
          notifier.updateStrongSubjects([]);
          notifier.updateWeakSubjects([]);
          notifier.updateCustomSubjects([]);
        },
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  final String label;
  const _GroupDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
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
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Theme.of(context).cardColor,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: selected ? AppColors.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(option.icon, style: const TextStyle(fontSize: 26)),
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
                      color: selected
                          ? AppColors.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
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
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class SubjectData {
  final String name;
  final String emoji;
  final String group; // 'tyt' | 'ayt' | 'default'

  const SubjectData({
    required this.name,
    required this.emoji,
    this.group = 'default',
  });
}

const _tytSubjects = [
  SubjectData(name: 'TYT Matematik', emoji: '📐', group: 'tyt'),
  SubjectData(name: 'TYT Türkçe', emoji: '📖', group: 'tyt'),
  SubjectData(name: 'TYT Fizik', emoji: '⚡', group: 'tyt'),
  SubjectData(name: 'TYT Kimya', emoji: '🧪', group: 'tyt'),
  SubjectData(name: 'TYT Biyoloji', emoji: '🧬', group: 'tyt'),
  SubjectData(name: 'TYT Tarih', emoji: '🏛️', group: 'tyt'),
  SubjectData(name: 'TYT Coğrafya', emoji: '🌍', group: 'tyt'),
  SubjectData(name: 'TYT Felsefe', emoji: '💭', group: 'tyt'),
  SubjectData(name: 'TYT Din Kültürü', emoji: '🕌', group: 'tyt'),
];

List<SubjectData> getSubjectsForExam(String targetExam, String selectedArea) {
  switch (targetExam) {
    case 'LGS':
      return const [
        SubjectData(name: 'Matematik', emoji: '📐'),
        SubjectData(name: 'Türkçe', emoji: '📖'),
        SubjectData(name: 'Fen Bilimleri', emoji: '🔬'),
        SubjectData(name: 'T.C. İnkılap Tarihi', emoji: '🏛️'),
        SubjectData(name: 'Din Kültürü', emoji: '🕌'),
        SubjectData(name: 'İngilizce', emoji: '🇬🇧'),
      ];
    case 'YKS':
      switch (selectedArea) {
        case 'sadece_tyt':
          return _tytSubjects;
        case 'sayisal':
          return [
            ..._tytSubjects,
            const SubjectData(name: 'AYT Matematik', emoji: '📐', group: 'ayt'),
            const SubjectData(name: 'AYT Geometri', emoji: '📐', group: 'ayt'),
            const SubjectData(name: 'AYT Fizik', emoji: '⚡', group: 'ayt'),
            const SubjectData(name: 'AYT Kimya', emoji: '🧪', group: 'ayt'),
            const SubjectData(name: 'AYT Biyoloji', emoji: '🧬', group: 'ayt'),
          ];
        case 'esit_agirlik':
          return [
            ..._tytSubjects,
            const SubjectData(name: 'AYT Matematik', emoji: '📐', group: 'ayt'),
            const SubjectData(name: 'AYT Geometri', emoji: '📐', group: 'ayt'),
            const SubjectData(name: 'AYT Edebiyat', emoji: '📖', group: 'ayt'),
            const SubjectData(name: 'AYT Tarih-1', emoji: '🏛️', group: 'ayt'),
            const SubjectData(name: 'AYT Coğrafya-1', emoji: '🌍', group: 'ayt'),
          ];
        case 'sozel':
          return [
            ..._tytSubjects,
            const SubjectData(name: 'AYT Edebiyat', emoji: '✏️', group: 'ayt'),
            const SubjectData(name: 'AYT Tarih', emoji: '🏛️', group: 'ayt'),
            const SubjectData(name: 'AYT Coğrafya', emoji: '🌍', group: 'ayt'),
            const SubjectData(name: 'AYT Felsefe', emoji: '💭', group: 'ayt'),
            const SubjectData(name: 'AYT Mantık', emoji: '🧩', group: 'ayt'),
            const SubjectData(name: 'AYT Sosyoloji', emoji: '👥', group: 'ayt'),
            const SubjectData(name: 'AYT Psikoloji', emoji: '🧠', group: 'ayt'),
            const SubjectData(name: 'AYT Din Kültürü', emoji: '🕌', group: 'ayt'),
          ];
        case 'dil':
          return [
            ..._tytSubjects,
            const SubjectData(name: 'YDT Kelime Bilgisi', emoji: '🔤', group: 'ayt'),
            const SubjectData(name: 'YDT Dilbilgisi / Gramer', emoji: '✏️', group: 'ayt'),
            const SubjectData(name: 'YDT Cloze Test', emoji: '🧩', group: 'ayt'),
            const SubjectData(name: 'YDT Cümle Tamamlama', emoji: '🖊️', group: 'ayt'),
            const SubjectData(name: 'YDT Çeviri', emoji: '🔄', group: 'ayt'),
            const SubjectData(name: 'YDT Okuma Parçaları', emoji: '📖', group: 'ayt'),
            const SubjectData(name: 'YDT Diyalog Tamamlama', emoji: '💬', group: 'ayt'),
            const SubjectData(name: 'YDT Anlamca En Yakın Cümle', emoji: '🔍', group: 'ayt'),
            const SubjectData(name: 'YDT Paragraf Tamamlama', emoji: '📄', group: 'ayt'),
            const SubjectData(name: 'YDT Anlam Bütünlüğünü Bozan Cümle', emoji: '🚫', group: 'ayt'),
          ];
        default:
          return _tytSubjects;
      }
    case 'KPSS':
      if (selectedArea == 'kpss_onlisans') {
        return const [
          SubjectData(name: 'Önlisans Türkçe', emoji: '📖'),
          SubjectData(name: 'Önlisans Matematik', emoji: '📐'),
          SubjectData(name: 'Önlisans Tarih', emoji: '🏛️'),
          SubjectData(name: 'Önlisans Coğrafya', emoji: '🌍'),
          SubjectData(name: 'Önlisans Vatandaşlık', emoji: '⚖️'),
          SubjectData(name: 'Önlisans Güncel Bilgiler', emoji: '📰'),
        ];
      }
      return const [
        SubjectData(name: 'Lisans Türkçe', emoji: '📖'),
        SubjectData(name: 'Lisans Matematik', emoji: '📐'),
        SubjectData(name: 'Lisans Tarih', emoji: '🏛️'),
        SubjectData(name: 'Lisans Coğrafya', emoji: '🌍'),
        SubjectData(name: 'Lisans Vatandaşlık', emoji: '⚖️'),
        SubjectData(name: 'Lisans Güncel Bilgiler', emoji: '📰'),
      ];
    case 'ALES':
      return const [
        SubjectData(name: 'Sayısal (Matematik)', emoji: '📐'),
        SubjectData(name: 'Sözel (Türkçe Mantık)', emoji: '📖'),
      ];
    case 'YDS':
      return const [
        SubjectData(name: 'YDS Kelime Bilgisi', emoji: '🔤'),
        SubjectData(name: 'YDS Dilbilgisi / Gramer', emoji: '✏️'),
        SubjectData(name: 'YDS Cloze Test', emoji: '🧩'),
        SubjectData(name: 'YDS Cümle Tamamlama', emoji: '🖊️'),
        SubjectData(name: 'YDS Çeviri', emoji: '🔄'),
        SubjectData(name: 'YDS Okuma Parçaları', emoji: '📖'),
        SubjectData(name: 'YDS Diyalog Tamamlama', emoji: '💬'),
        SubjectData(name: 'YDS Anlamca En Yakın Cümle', emoji: '🔍'),
        SubjectData(name: 'YDS Paragraf Tamamlama', emoji: '📄'),
        SubjectData(name: 'YDS Anlam Bütünlüğünü Bozan Cümle', emoji: '🚫'),
      ];
    case 'Öğretmenlik':
      return const [
        SubjectData(name: 'Türkçe (AGS)', emoji: '📖'),
        SubjectData(name: 'Matematik (AGS)', emoji: '📐'),
        SubjectData(name: 'Tarih (AGS)', emoji: '🏛️'),
        SubjectData(name: 'Coğrafya (AGS)', emoji: '🌍'),
        SubjectData(name: 'Eğitim Bilimleri ve Millî Eğitim Sistemi', emoji: '🎓'),
        SubjectData(name: 'Mevzuat', emoji: '📜'),
        SubjectData(name: 'ÖABT (Alan Bilgisi)', emoji: '👩‍🏫'),
      ];
    case 'OkulSinavi':
      return getOkulSinaviSubjects(selectedArea);
    default:
      return _tytSubjects;
  }
}

// ── OkulSinavi ders havuzu ────────────────────────────────────────────────────

// selectedArea encoding for OkulSinavi:
//  ortaokul: 'sinif_5' | 'sinif_6' | 'sinif_7' | 'sinif_8'
//  lise 9-10: 'lise_9' | 'lise_10'
//  lise 11-12 + alan: 'lise_1112_sayisal' | 'lise_1112_ea' | 'lise_1112_sozel' | 'lise_1112_dil'
//  universite bölüm: 'uni_yazilim' | 'uni_tip' | 'uni_hukuk' | 'uni_psikoloji' |
//                    'uni_isletme' | 'uni_muhendislik' | 'uni_egitim' | 'uni_diger'

List<SubjectData> getOkulSinaviSubjects(String selectedArea) {
  switch (selectedArea) {
    // ── Ortaokul ──
    case 'sinif_5':
    case 'sinif_6':
    case 'sinif_7':
      return const [
        SubjectData(name: 'Türkçe', emoji: '📖'),
        SubjectData(name: 'Matematik', emoji: '📐'),
        SubjectData(name: 'Fen Bilimleri', emoji: '🔬'),
        SubjectData(name: 'Sosyal Bilgiler', emoji: '🌍'),
        SubjectData(name: 'İngilizce', emoji: '🇬🇧'),
        SubjectData(name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌'),
      ];
    case 'sinif_8':
      return const [
        SubjectData(name: 'Türkçe', emoji: '📖'),
        SubjectData(name: 'Matematik', emoji: '📐'),
        SubjectData(name: 'Fen Bilimleri', emoji: '🔬'),
        SubjectData(name: 'İnkılap Tarihi ve Atatürkçülük', emoji: '🏛️'),
        SubjectData(name: 'İngilizce', emoji: '🇬🇧'),
        SubjectData(name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌'),
      ];

    // ── Lise 9 ──
    case 'lise_9':
      return const [
        SubjectData(name: 'Matematik', emoji: '📐'),
        SubjectData(name: 'Fizik', emoji: '⚡'),
        SubjectData(name: 'Kimya', emoji: '🧪'),
        SubjectData(name: 'Biyoloji', emoji: '🧬'),
        SubjectData(name: 'Tarih', emoji: '🏛️'),
        SubjectData(name: 'Türk Dili ve Edebiyatı', emoji: '📖'),
        SubjectData(name: 'Coğrafya', emoji: '🌍'),
        SubjectData(name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌'),
        SubjectData(name: 'İngilizce', emoji: '🇬🇧'),
        SubjectData(name: 'Almanca', emoji: '🇩🇪'),
      ];

    // ── Lise 10 ──
    case 'lise_10':
      return const [
        SubjectData(name: 'Matematik', emoji: '📐'),
        SubjectData(name: 'Fizik', emoji: '⚡'),
        SubjectData(name: 'Kimya', emoji: '🧪'),
        SubjectData(name: 'Biyoloji', emoji: '🧬'),
        SubjectData(name: 'Tarih', emoji: '🏛️'),
        SubjectData(name: 'Türk Dili ve Edebiyatı', emoji: '📖'),
        SubjectData(name: 'Coğrafya', emoji: '🌍'),
        SubjectData(name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌'),
        SubjectData(name: 'İngilizce', emoji: '🇬🇧'),
        SubjectData(name: 'Almanca', emoji: '🇩🇪'),
        SubjectData(name: 'Felsefe', emoji: '💭'),
      ];

    // ── Lise 11-12 Sayısal ──
    case 'lise_1112_sayisal':
      return const [
        SubjectData(name: 'Türk Dili ve Edebiyatı', emoji: '📖'),
        SubjectData(name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌'),
        SubjectData(name: 'Tarih', emoji: '🏛️'),
        SubjectData(name: 'Felsefe', emoji: '💭'),
        SubjectData(name: 'İngilizce', emoji: '🇬🇧'),
        SubjectData(name: 'İkinci Yabancı Dil', emoji: '🌐'),
        SubjectData(name: 'Seçmeli Matematik', emoji: '📐'),
        SubjectData(name: 'Seçmeli Fizik', emoji: '⚡'),
        SubjectData(name: 'Seçmeli Kimya', emoji: '🧪'),
        SubjectData(name: 'Seçmeli Biyoloji', emoji: '🧬'),
      ];

    // ── Lise 11-12 Eşit Ağırlık ──
    case 'lise_1112_ea':
      return const [
        SubjectData(name: 'Türk Dili ve Edebiyatı', emoji: '📖'),
        SubjectData(name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌'),
        SubjectData(name: 'Tarih', emoji: '🏛️'),
        SubjectData(name: 'Felsefe', emoji: '💭'),
        SubjectData(name: 'İngilizce', emoji: '🇬🇧'),
        SubjectData(name: 'İkinci Yabancı Dil', emoji: '🌐'),
        SubjectData(name: 'Seçmeli Matematik', emoji: '📐'),
        SubjectData(name: 'Seçmeli Türk Dili ve Edebiyatı', emoji: '✏️'),
        SubjectData(name: 'Seçmeli Coğrafya', emoji: '🌍'),
        SubjectData(name: 'Seçmeli Tarih / Medeniyet Tarihi', emoji: '🏺'),
      ];

    // ── Lise 11-12 Sözel ──
    case 'lise_1112_sozel':
      return const [
        SubjectData(name: 'Türk Dili ve Edebiyatı', emoji: '📖'),
        SubjectData(name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌'),
        SubjectData(name: 'Tarih', emoji: '🏛️'),
        SubjectData(name: 'Felsefe', emoji: '💭'),
        SubjectData(name: 'İngilizce', emoji: '🇬🇧'),
        SubjectData(name: 'İkinci Yabancı Dil', emoji: '🌐'),
        SubjectData(name: 'Seçmeli Türk Dili ve Edebiyatı', emoji: '✏️'),
        SubjectData(name: 'Türk Kültür ve Medeniyet Tarihi', emoji: '🏺', group: 'default'),
        SubjectData(name: 'Seçmeli Coğrafya', emoji: '🌍'),
        SubjectData(name: 'Psikoloji/Sosyoloji/Mantık', emoji: '🧠'),
      ];

    // ── Lise 11-12 Dil ──
    case 'lise_1112_dil':
      return const [
        SubjectData(name: 'Türk Dili ve Edebiyatı', emoji: '📖'),
        SubjectData(name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌'),
        SubjectData(name: 'Tarih', emoji: '🏛️'),
        SubjectData(name: 'Felsefe', emoji: '💭'),
        SubjectData(name: 'Matematik', emoji: '📐'),
        SubjectData(name: 'İngilizce', emoji: '🇬🇧'),
        SubjectData(name: 'İngilizce Edebiyatı', emoji: '📚'),
        SubjectData(name: 'Almanca', emoji: '🇩🇪'),
      ];

    // ── Üniversite bölümleri ──
    case 'uni_yazilim':
      return const [
        SubjectData(name: 'Algoritma ve Programlama', emoji: '💻'),
        SubjectData(name: 'Veri Yapıları', emoji: '🗂️'),
        SubjectData(name: 'Diferansiyel ve İntegral', emoji: '📐'),
        SubjectData(name: 'Lineer Cebir', emoji: '🔢'),
        SubjectData(name: 'Olasılık ve İstatistik', emoji: '📊'),
        SubjectData(name: 'Veritabanı Sistemleri', emoji: '🛢️'),
        SubjectData(name: 'Bilgisayar Ağları', emoji: '🌐'),
        SubjectData(name: 'İşletim Sistemleri', emoji: '🖥️'),
        SubjectData(name: 'Yazılım Mühendisliği', emoji: '⚙️'),
      ];
    case 'uni_tip':
      return const [
        SubjectData(name: 'Anatomi', emoji: '🦴'),
        SubjectData(name: 'Fizyoloji', emoji: '🫀'),
        SubjectData(name: 'Biyokimya', emoji: '🧪'),
        SubjectData(name: 'Histoloji', emoji: '🔬'),
        SubjectData(name: 'Mikrobiyoloji', emoji: '🦠'),
        SubjectData(name: 'Farmakoloji', emoji: '💊'),
        SubjectData(name: 'Patoloji', emoji: '🏥'),
        SubjectData(name: 'Dahiliye', emoji: '👨‍⚕️'),
      ];
    case 'uni_hukuk':
      return const [
        SubjectData(name: 'Medeni Hukuk', emoji: '⚖️'),
        SubjectData(name: 'Borçlar Hukuku', emoji: '📜'),
        SubjectData(name: 'Ticaret Hukuku', emoji: '🏢'),
        SubjectData(name: 'Ceza Hukuku', emoji: '🔒'),
        SubjectData(name: 'İdare Hukuku', emoji: '🏛️'),
        SubjectData(name: 'Anayasa Hukuku', emoji: '📋'),
        SubjectData(name: 'Uluslararası Hukuk', emoji: '🌍'),
      ];
    case 'uni_psikoloji':
      return const [
        SubjectData(name: 'Genel Psikoloji', emoji: '🧠'),
        SubjectData(name: 'Gelişim Psikolojisi', emoji: '🌱'),
        SubjectData(name: 'Sosyal Psikoloji', emoji: '👥'),
        SubjectData(name: 'Klinik Psikoloji', emoji: '💆'),
        SubjectData(name: 'Psikolojik Testler', emoji: '📝'),
        SubjectData(name: 'Nöropsikoloji', emoji: '🔬'),
        SubjectData(name: 'İstatistik', emoji: '📊'),
      ];
    case 'uni_isletme':
      return const [
        SubjectData(name: 'Muhasebe', emoji: '📒'),
        SubjectData(name: 'Finans', emoji: '💰'),
        SubjectData(name: 'Pazarlama', emoji: '📈'),
        SubjectData(name: 'Yönetim ve Organizasyon', emoji: '🏢'),
        SubjectData(name: 'İşletme İktisadı', emoji: '📊'),
        SubjectData(name: 'Ticaret Hukuku', emoji: '⚖️'),
        SubjectData(name: 'İstatistik', emoji: '🔢'),
      ];
    case 'uni_muhendislik':
      return const [
        SubjectData(name: 'Diferansiyel Denklemler', emoji: '📐'),
        SubjectData(name: 'Lineer Cebir', emoji: '🔢'),
        SubjectData(name: 'Fizik I - II', emoji: '⚡'),
        SubjectData(name: 'Kimya', emoji: '🧪'),
        SubjectData(name: 'Termodinamik', emoji: '🌡️'),
        SubjectData(name: 'Mekanik', emoji: '⚙️'),
        SubjectData(name: 'Malzeme Bilimi', emoji: '🏗️'),
      ];
    case 'uni_egitim':
      return const [
        SubjectData(name: 'Eğitim Psikolojisi', emoji: '🧠'),
        SubjectData(name: 'Öğretim İlke ve Yöntemleri', emoji: '📚'),
        SubjectData(name: 'Sınıf Yönetimi', emoji: '🏫'),
        SubjectData(name: 'Ölçme ve Değerlendirme', emoji: '📊'),
        SubjectData(name: 'Alan Bilgisi', emoji: '🎓'),
        SubjectData(name: 'Özel Öğretim Yöntemleri', emoji: '✏️'),
      ];
    case 'uni_diger':
      return []; // kullanıcı tanımlı
    default:
      return [];
  }
}

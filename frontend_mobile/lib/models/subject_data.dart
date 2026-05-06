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
    default:
      return _tytSubjects;
  }
}

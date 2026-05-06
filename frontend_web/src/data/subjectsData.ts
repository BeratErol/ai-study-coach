export interface SubjectData {
  name: string
  emoji: string
  group: 'tyt' | 'ayt' | 'default'
}

const tytSubjects: SubjectData[] = [
  { name: 'TYT Matematik', emoji: '📐', group: 'tyt' },
  { name: 'TYT Türkçe', emoji: '📖', group: 'tyt' },
  { name: 'TYT Fizik', emoji: '⚡', group: 'tyt' },
  { name: 'TYT Kimya', emoji: '🧪', group: 'tyt' },
  { name: 'TYT Biyoloji', emoji: '🧬', group: 'tyt' },
  { name: 'TYT Tarih', emoji: '🏛️', group: 'tyt' },
  { name: 'TYT Coğrafya', emoji: '🌍', group: 'tyt' },
  { name: 'TYT Felsefe', emoji: '💭', group: 'tyt' },
  { name: 'TYT Din Kültürü', emoji: '🕌', group: 'tyt' },
]

export function getSubjectsForExam(targetExam: string, selectedArea: string): SubjectData[] {
  switch (targetExam) {
    case 'LGS':
      return [
        { name: 'Matematik', emoji: '📐', group: 'default' },
        { name: 'Türkçe', emoji: '📖', group: 'default' },
        { name: 'Fen Bilimleri', emoji: '🔬', group: 'default' },
        { name: 'T.C. İnkılap Tarihi', emoji: '🏛️', group: 'default' },
        { name: 'Din Kültürü', emoji: '🕌', group: 'default' },
        { name: 'İngilizce', emoji: '🇬🇧', group: 'default' },
      ]
    case 'YKS':
      switch (selectedArea) {
        case 'sadece_tyt':
          return [...tytSubjects]
        case 'sayisal':
          return [
            ...tytSubjects,
            { name: 'AYT Matematik', emoji: '📐', group: 'ayt' },
            { name: 'AYT Geometri', emoji: '📐', group: 'ayt' },
            { name: 'AYT Fizik', emoji: '⚡', group: 'ayt' },
            { name: 'AYT Kimya', emoji: '🧪', group: 'ayt' },
            { name: 'AYT Biyoloji', emoji: '🧬', group: 'ayt' },
          ]
        case 'esit_agirlik':
          return [
            ...tytSubjects,
            { name: 'AYT Matematik', emoji: '📐', group: 'ayt' },
            { name: 'AYT Geometri', emoji: '📐', group: 'ayt' },
            { name: 'AYT Edebiyat', emoji: '📖', group: 'ayt' },
            { name: 'AYT Tarih-1', emoji: '🏛️', group: 'ayt' },
            { name: 'AYT Coğrafya-1', emoji: '🌍', group: 'ayt' },
          ]
        case 'sozel':
          return [
            ...tytSubjects,
            { name: 'AYT Edebiyat', emoji: '✏️', group: 'ayt' },
            { name: 'AYT Tarih', emoji: '🏛️', group: 'ayt' },
            { name: 'AYT Coğrafya', emoji: '🌍', group: 'ayt' },
            { name: 'AYT Felsefe', emoji: '💭', group: 'ayt' },
            { name: 'AYT Mantık', emoji: '🧩', group: 'ayt' },
            { name: 'AYT Sosyoloji', emoji: '👥', group: 'ayt' },
            { name: 'AYT Psikoloji', emoji: '🧠', group: 'ayt' },
            { name: 'AYT Din Kültürü', emoji: '🕌', group: 'ayt' },
          ]
        case 'dil':
          return [
            ...tytSubjects,
            { name: 'YDT Kelime Bilgisi', emoji: '🔤', group: 'ayt' },
            { name: 'YDT Dilbilgisi / Gramer', emoji: '✏️', group: 'ayt' },
            { name: 'YDT Cloze Test', emoji: '🧩', group: 'ayt' },
            { name: 'YDT Cümle Tamamlama', emoji: '🖊️', group: 'ayt' },
            { name: 'YDT Çeviri', emoji: '🔄', group: 'ayt' },
            { name: 'YDT Okuma Parçaları', emoji: '📖', group: 'ayt' },
            { name: 'YDT Diyalog Tamamlama', emoji: '💬', group: 'ayt' },
            { name: 'YDT Anlamca En Yakın Cümle', emoji: '🔍', group: 'ayt' },
            { name: 'YDT Paragraf Tamamlama', emoji: '📄', group: 'ayt' },
            { name: 'YDT Anlam Bütünlüğünü Bozan Cümle', emoji: '🚫', group: 'ayt' },
          ]
        default:
          return [...tytSubjects]
      }
    case 'KPSS':
      if (selectedArea === 'kpss_onlisans') {
        return [
          { name: 'Önlisans Türkçe', emoji: '📖', group: 'default' },
          { name: 'Önlisans Matematik', emoji: '📐', group: 'default' },
          { name: 'Önlisans Tarih', emoji: '🏛️', group: 'default' },
          { name: 'Önlisans Coğrafya', emoji: '🌍', group: 'default' },
          { name: 'Önlisans Vatandaşlık', emoji: '⚖️', group: 'default' },
          { name: 'Önlisans Güncel Bilgiler', emoji: '📰', group: 'default' },
        ]
      }
      return [
        { name: 'Lisans Türkçe', emoji: '📖', group: 'default' },
        { name: 'Lisans Matematik', emoji: '📐', group: 'default' },
        { name: 'Lisans Tarih', emoji: '🏛️', group: 'default' },
        { name: 'Lisans Coğrafya', emoji: '🌍', group: 'default' },
        { name: 'Lisans Vatandaşlık', emoji: '⚖️', group: 'default' },
        { name: 'Lisans Güncel Bilgiler', emoji: '📰', group: 'default' },
      ]
    case 'ALES':
      return [
        { name: 'Sayısal (Matematik)', emoji: '📐', group: 'default' },
        { name: 'Sözel (Türkçe Mantık)', emoji: '📖', group: 'default' },
      ]
    case 'YDS':
      return [
        { name: 'YDS Kelime Bilgisi', emoji: '🔤', group: 'default' },
        { name: 'YDS Dilbilgisi / Gramer', emoji: '✏️', group: 'default' },
        { name: 'YDS Cloze Test', emoji: '🧩', group: 'default' },
        { name: 'YDS Cümle Tamamlama', emoji: '🖊️', group: 'default' },
        { name: 'YDS Çeviri', emoji: '🔄', group: 'default' },
        { name: 'YDS Okuma Parçaları', emoji: '📖', group: 'default' },
        { name: 'YDS Diyalog Tamamlama', emoji: '💬', group: 'default' },
        { name: 'YDS Anlamca En Yakın Cümle', emoji: '🔍', group: 'default' },
        { name: 'YDS Paragraf Tamamlama', emoji: '📄', group: 'default' },
        { name: 'YDS Anlam Bütünlüğünü Bozan Cümle', emoji: '🚫', group: 'default' },
      ]
    case 'Öğretmenlik':
      return [
        { name: 'Türkçe (AGS)', emoji: '📖', group: 'default' },
        { name: 'Matematik (AGS)', emoji: '📐', group: 'default' },
        { name: 'Tarih (AGS)', emoji: '🏛️', group: 'default' },
        { name: 'Coğrafya (AGS)', emoji: '🌍', group: 'default' },
        { name: 'Eğitim Bilimleri ve Millî Eğitim Sistemi', emoji: '🎓', group: 'default' },
        { name: 'Mevzuat', emoji: '📜', group: 'default' },
        { name: 'ÖABT (Alan Bilgisi)', emoji: '👩‍🏫', group: 'default' },
      ]
    default:
      return [...tytSubjects]
  }
}

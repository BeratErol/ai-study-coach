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
    case 'OkulSinavi':
      return getOkulSinaviSubjects(selectedArea)
    default:
      return [...tytSubjects]
  }
}

// ── OkulSinavi ders havuzu (mobil ile birebir) ───────────────────────────────
// selectedArea kodlaması:
//  ortaokul: 'sinif_5' | 'sinif_6' | 'sinif_7' | 'sinif_8'
//  lise 9-10: 'lise_9' | 'lise_10'
//  lise 11-12 + alan: 'lise_1112_sayisal' | 'lise_1112_ea' | 'lise_1112_sozel' | 'lise_1112_dil'
//  universite bölüm: 'uni_yazilim' | 'uni_tip' | 'uni_hukuk' | 'uni_psikoloji' |
//                    'uni_isletme' | 'uni_muhendislik' | 'uni_egitim' | 'uni_diger'
export function getOkulSinaviSubjects(selectedArea: string): SubjectData[] {
  switch (selectedArea) {
    case 'sinif_5':
    case 'sinif_6':
    case 'sinif_7':
      return [
        { name: 'Türkçe', emoji: '📖', group: 'default' },
        { name: 'Matematik', emoji: '📐', group: 'default' },
        { name: 'Fen Bilimleri', emoji: '🔬', group: 'default' },
        { name: 'Sosyal Bilgiler', emoji: '🌍', group: 'default' },
        { name: 'İngilizce', emoji: '🇬🇧', group: 'default' },
        { name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌', group: 'default' },
      ]
    case 'sinif_8':
      return [
        { name: 'Türkçe', emoji: '📖', group: 'default' },
        { name: 'Matematik', emoji: '📐', group: 'default' },
        { name: 'Fen Bilimleri', emoji: '🔬', group: 'default' },
        { name: 'İnkılap Tarihi ve Atatürkçülük', emoji: '🏛️', group: 'default' },
        { name: 'İngilizce', emoji: '🇬🇧', group: 'default' },
        { name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌', group: 'default' },
      ]
    case 'lise_9':
      return [
        { name: 'Matematik', emoji: '📐', group: 'default' },
        { name: 'Fizik', emoji: '⚡', group: 'default' },
        { name: 'Kimya', emoji: '🧪', group: 'default' },
        { name: 'Biyoloji', emoji: '🧬', group: 'default' },
        { name: 'Tarih', emoji: '🏛️', group: 'default' },
        { name: 'Türk Dili ve Edebiyatı', emoji: '📖', group: 'default' },
        { name: 'Coğrafya', emoji: '🌍', group: 'default' },
        { name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌', group: 'default' },
        { name: 'İngilizce', emoji: '🇬🇧', group: 'default' },
        { name: 'Almanca', emoji: '🇩🇪', group: 'default' },
      ]
    case 'lise_10':
      return [
        { name: 'Matematik', emoji: '📐', group: 'default' },
        { name: 'Fizik', emoji: '⚡', group: 'default' },
        { name: 'Kimya', emoji: '🧪', group: 'default' },
        { name: 'Biyoloji', emoji: '🧬', group: 'default' },
        { name: 'Tarih', emoji: '🏛️', group: 'default' },
        { name: 'Türk Dili ve Edebiyatı', emoji: '📖', group: 'default' },
        { name: 'Coğrafya', emoji: '🌍', group: 'default' },
        { name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌', group: 'default' },
        { name: 'İngilizce', emoji: '🇬🇧', group: 'default' },
        { name: 'Almanca', emoji: '🇩🇪', group: 'default' },
        { name: 'Felsefe', emoji: '💭', group: 'default' },
      ]
    case 'lise_1112_sayisal':
      return [
        { name: 'Türk Dili ve Edebiyatı', emoji: '📖', group: 'default' },
        { name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌', group: 'default' },
        { name: 'Tarih', emoji: '🏛️', group: 'default' },
        { name: 'Felsefe', emoji: '💭', group: 'default' },
        { name: 'İngilizce', emoji: '🇬🇧', group: 'default' },
        { name: 'İkinci Yabancı Dil', emoji: '🌐', group: 'default' },
        { name: 'Seçmeli Matematik', emoji: '📐', group: 'default' },
        { name: 'Seçmeli Fizik', emoji: '⚡', group: 'default' },
        { name: 'Seçmeli Kimya', emoji: '🧪', group: 'default' },
        { name: 'Seçmeli Biyoloji', emoji: '🧬', group: 'default' },
      ]
    case 'lise_1112_ea':
      return [
        { name: 'Türk Dili ve Edebiyatı', emoji: '📖', group: 'default' },
        { name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌', group: 'default' },
        { name: 'Tarih', emoji: '🏛️', group: 'default' },
        { name: 'Felsefe', emoji: '💭', group: 'default' },
        { name: 'İngilizce', emoji: '🇬🇧', group: 'default' },
        { name: 'İkinci Yabancı Dil', emoji: '🌐', group: 'default' },
        { name: 'Seçmeli Matematik', emoji: '📐', group: 'default' },
        { name: 'Seçmeli Türk Dili ve Edebiyatı', emoji: '✏️', group: 'default' },
        { name: 'Seçmeli Coğrafya', emoji: '🌍', group: 'default' },
        { name: 'Seçmeli Tarih / Medeniyet Tarihi', emoji: '🏺', group: 'default' },
      ]
    case 'lise_1112_sozel':
      return [
        { name: 'Türk Dili ve Edebiyatı', emoji: '📖', group: 'default' },
        { name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌', group: 'default' },
        { name: 'Tarih', emoji: '🏛️', group: 'default' },
        { name: 'Felsefe', emoji: '💭', group: 'default' },
        { name: 'İngilizce', emoji: '🇬🇧', group: 'default' },
        { name: 'İkinci Yabancı Dil', emoji: '🌐', group: 'default' },
        { name: 'Seçmeli Türk Dili ve Edebiyatı', emoji: '✏️', group: 'default' },
        { name: 'Türk Kültür ve Medeniyet Tarihi', emoji: '🏺', group: 'default' },
        { name: 'Seçmeli Coğrafya', emoji: '🌍', group: 'default' },
        { name: 'Psikoloji/Sosyoloji/Mantık', emoji: '🧠', group: 'default' },
      ]
    case 'lise_1112_dil':
      return [
        { name: 'Türk Dili ve Edebiyatı', emoji: '📖', group: 'default' },
        { name: 'Din Kültürü ve Ahlak Bilgisi', emoji: '🕌', group: 'default' },
        { name: 'Tarih', emoji: '🏛️', group: 'default' },
        { name: 'Felsefe', emoji: '💭', group: 'default' },
        { name: 'Matematik', emoji: '📐', group: 'default' },
        { name: 'İngilizce', emoji: '🇬🇧', group: 'default' },
        { name: 'İngilizce Edebiyatı', emoji: '📚', group: 'default' },
        { name: 'Almanca', emoji: '🇩🇪', group: 'default' },
      ]
    case 'uni_yazilim':
      return [
        { name: 'Algoritma ve Programlama', emoji: '💻', group: 'default' },
        { name: 'Veri Yapıları', emoji: '🗂️', group: 'default' },
        { name: 'Diferansiyel ve İntegral', emoji: '📐', group: 'default' },
        { name: 'Lineer Cebir', emoji: '🔢', group: 'default' },
        { name: 'Olasılık ve İstatistik', emoji: '📊', group: 'default' },
        { name: 'Veritabanı Sistemleri', emoji: '🛢️', group: 'default' },
        { name: 'Bilgisayar Ağları', emoji: '🌐', group: 'default' },
        { name: 'İşletim Sistemleri', emoji: '🖥️', group: 'default' },
        { name: 'Yazılım Mühendisliği', emoji: '⚙️', group: 'default' },
      ]
    case 'uni_tip':
      return [
        { name: 'Anatomi', emoji: '🦴', group: 'default' },
        { name: 'Fizyoloji', emoji: '🫀', group: 'default' },
        { name: 'Biyokimya', emoji: '🧪', group: 'default' },
        { name: 'Histoloji', emoji: '🔬', group: 'default' },
        { name: 'Mikrobiyoloji', emoji: '🦠', group: 'default' },
        { name: 'Farmakoloji', emoji: '💊', group: 'default' },
        { name: 'Patoloji', emoji: '🏥', group: 'default' },
        { name: 'Dahiliye', emoji: '👨‍⚕️', group: 'default' },
      ]
    case 'uni_hukuk':
      return [
        { name: 'Medeni Hukuk', emoji: '⚖️', group: 'default' },
        { name: 'Borçlar Hukuku', emoji: '📜', group: 'default' },
        { name: 'Ticaret Hukuku', emoji: '🏢', group: 'default' },
        { name: 'Ceza Hukuku', emoji: '🔒', group: 'default' },
        { name: 'İdare Hukuku', emoji: '🏛️', group: 'default' },
        { name: 'Anayasa Hukuku', emoji: '📋', group: 'default' },
        { name: 'Uluslararası Hukuk', emoji: '🌍', group: 'default' },
      ]
    case 'uni_psikoloji':
      return [
        { name: 'Genel Psikoloji', emoji: '🧠', group: 'default' },
        { name: 'Gelişim Psikolojisi', emoji: '🌱', group: 'default' },
        { name: 'Sosyal Psikoloji', emoji: '👥', group: 'default' },
        { name: 'Klinik Psikoloji', emoji: '💆', group: 'default' },
        { name: 'Psikolojik Testler', emoji: '📝', group: 'default' },
        { name: 'Nöropsikoloji', emoji: '🔬', group: 'default' },
        { name: 'İstatistik', emoji: '📊', group: 'default' },
      ]
    case 'uni_isletme':
      return [
        { name: 'Muhasebe', emoji: '📒', group: 'default' },
        { name: 'Finans', emoji: '💰', group: 'default' },
        { name: 'Pazarlama', emoji: '📈', group: 'default' },
        { name: 'Yönetim ve Organizasyon', emoji: '🏢', group: 'default' },
        { name: 'İşletme İktisadı', emoji: '📊', group: 'default' },
        { name: 'Ticaret Hukuku', emoji: '⚖️', group: 'default' },
        { name: 'İstatistik', emoji: '🔢', group: 'default' },
      ]
    case 'uni_muhendislik':
      return [
        { name: 'Diferansiyel Denklemler', emoji: '📐', group: 'default' },
        { name: 'Lineer Cebir', emoji: '🔢', group: 'default' },
        { name: 'Fizik I - II', emoji: '⚡', group: 'default' },
        { name: 'Kimya', emoji: '🧪', group: 'default' },
        { name: 'Termodinamik', emoji: '🌡️', group: 'default' },
        { name: 'Mekanik', emoji: '⚙️', group: 'default' },
        { name: 'Malzeme Bilimi', emoji: '🏗️', group: 'default' },
      ]
    case 'uni_egitim':
      return [
        { name: 'Eğitim Psikolojisi', emoji: '🧠', group: 'default' },
        { name: 'Öğretim İlke ve Yöntemleri', emoji: '📚', group: 'default' },
        { name: 'Sınıf Yönetimi', emoji: '🏫', group: 'default' },
        { name: 'Ölçme ve Değerlendirme', emoji: '📊', group: 'default' },
        { name: 'Alan Bilgisi', emoji: '🎓', group: 'default' },
        { name: 'Özel Öğretim Yöntemleri', emoji: '✏️', group: 'default' },
      ]
    case 'uni_diger':
      return [] // kullanıcı tanımlı
    default:
      return []
  }
}

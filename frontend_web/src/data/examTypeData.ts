// Mobildeki exam_type_data.dart portu — deneme türleri ve sabit ders listeleri.

export interface LessonSlot {
  name: string
  maxQuestions: number
}

export interface ExamTypeInfo {
  displayName: string
  apiType: string
  lessons: LessonSlot[]
}

export const examTypes: ExamTypeInfo[] = [
  {
    displayName: 'TYT',
    apiType: 'TYT',
    lessons: [
      { name: 'TYT Türkçe', maxQuestions: 40 },
      { name: 'TYT Sosyal Bilimler', maxQuestions: 20 },
      { name: 'TYT Matematik', maxQuestions: 40 },
      { name: 'TYT Fen Bilimleri', maxQuestions: 20 },
    ],
  },
  {
    displayName: 'AYT (Sayısal)',
    apiType: 'AYT_SAYISAL',
    lessons: [
      { name: 'Matematik', maxQuestions: 40 },
      { name: 'Fen Bilimleri', maxQuestions: 40 },
    ],
  },
  {
    displayName: 'AYT (Eşit Ağırlık)',
    apiType: 'AYT_EA',
    lessons: [
      { name: 'Matematik', maxQuestions: 40 },
      { name: 'Edebiyat', maxQuestions: 24 },
      { name: 'Tarih-1', maxQuestions: 10 },
      { name: 'Coğrafya-1', maxQuestions: 6 },
    ],
  },
  {
    displayName: 'AYT (Sözel)',
    apiType: 'AYT_SOZEL',
    lessons: [
      { name: 'Edebiyat', maxQuestions: 24 },
      { name: 'Tarih-1', maxQuestions: 10 },
      { name: 'Coğrafya-1', maxQuestions: 6 },
      { name: 'Tarih-2', maxQuestions: 11 },
      { name: 'Coğrafya-2', maxQuestions: 11 },
      { name: 'Felsefe Grubu', maxQuestions: 12 },
      { name: 'Din Kültürü', maxQuestions: 6 },
    ],
  },
  {
    displayName: 'AYT (Dil)',
    apiType: 'AYT_DIL',
    lessons: [{ name: 'Yabancı Dil', maxQuestions: 80 }],
  },
  {
    displayName: 'Branş Denemesi',
    apiType: 'BRANS',
    lessons: [
      { name: 'Matematik', maxQuestions: 40 },
      { name: 'Fizik', maxQuestions: 30 },
      { name: 'Kimya', maxQuestions: 30 },
      { name: 'Biyoloji', maxQuestions: 30 },
      { name: 'Türkçe', maxQuestions: 40 },
      { name: 'Edebiyat', maxQuestions: 40 },
      { name: 'Tarih', maxQuestions: 20 },
      { name: 'Coğrafya', maxQuestions: 20 },
    ],
  },
  {
    displayName: 'LGS',
    apiType: 'LGS',
    lessons: [
      { name: 'Türkçe', maxQuestions: 20 },
      { name: 'Matematik', maxQuestions: 20 },
      { name: 'Fen Bilimleri', maxQuestions: 20 },
      { name: 'İnkılap Tarihi', maxQuestions: 10 },
      { name: 'Din Kültürü', maxQuestions: 10 },
      { name: 'Yabancı Dil', maxQuestions: 10 },
    ],
  },
  {
    displayName: 'KPSS (Lisans)',
    apiType: 'KPSS_LISANS',
    lessons: [
      // Genel Yetenek (60 soru): Türkçe 30, Matematik 27, Geometri 3.
      { name: 'Türkçe', maxQuestions: 30 },
      { name: 'Matematik', maxQuestions: 27 },
      { name: 'Geometri', maxQuestions: 3 },
      // Genel Kültür (60 soru): Tarih 27, Coğrafya 18, Vatandaşlık 9, Güncel 6.
      { name: 'Tarih', maxQuestions: 27 },
      { name: 'Coğrafya', maxQuestions: 18 },
      { name: 'Vatandaşlık', maxQuestions: 9 },
      { name: 'Güncel Bilgiler', maxQuestions: 6 },
    ],
  },
  {
    displayName: 'KPSS (Önlisans)',
    apiType: 'KPSS_ONLISANS',
    lessons: [
      { name: 'Türkçe', maxQuestions: 30 },
      { name: 'Matematik', maxQuestions: 27 },
      { name: 'Geometri', maxQuestions: 3 },
      { name: 'Tarih', maxQuestions: 27 },
      { name: 'Coğrafya', maxQuestions: 18 },
      { name: 'Vatandaşlık', maxQuestions: 9 },
      { name: 'Güncel Bilgiler', maxQuestions: 6 },
    ],
  },
  {
    displayName: 'ALES',
    apiType: 'ALES',
    lessons: [
      { name: 'Sayısal', maxQuestions: 50 },
      { name: 'Sözel', maxQuestions: 50 },
    ],
  },
  {
    displayName: 'YDS / e-YDS',
    apiType: 'YDS',
    lessons: [
      { name: 'Vocabulary', maxQuestions: 6 },
      { name: 'Grammar', maxQuestions: 10 },
      { name: 'Cloze Test', maxQuestions: 10 },
      { name: 'Sentence Completion', maxQuestions: 10 },
      { name: 'Translation', maxQuestions: 6 },
      { name: 'Reading Passages', maxQuestions: 20 },
      { name: 'Dialogue Completion', maxQuestions: 5 },
      { name: 'Restatement', maxQuestions: 4 },
      { name: 'Paragraph Completion', maxQuestions: 4 },
      { name: 'Irrelevant Sentence', maxQuestions: 5 },
    ],
  },
  {
    displayName: 'ÖABT',
    apiType: 'OABT',
    lessons: [
      { name: 'Alan Bilgisi', maxQuestions: 40 },
      { name: 'Alan Eğitimi', maxQuestions: 10 },
    ],
  },
  {
    displayName: 'AGS (MEB Akademi Giriş)',
    apiType: 'AGS',
    lessons: [
      { name: 'Sözel Yetenek', maxQuestions: 15 },
      { name: 'Matematik (Sayısal Yetenek)', maxQuestions: 15 },
      { name: 'Eğitim Bilimleri', maxQuestions: 30 },
      { name: 'Mevzuat', maxQuestions: 8 },
      { name: 'Tarih', maxQuestions: 6 },
      { name: 'Türkiye Coğrafyası', maxQuestions: 6 },
    ],
  },
]

/**
 * Sınava göre hangi deneme türlerinin gösterileceğini döner. Bilinmeyen sınav
 * için boş liste — "tüm türleri göster" fallback'i yoktur, her sınav kendi
 * havuzuna sahip olmak zorunda.
 */
export function availableExamTypes(targetExam: string, selectedArea: string): ExamTypeInfo[] {
  const exam = targetExam.toUpperCase()
  const area = selectedArea.toUpperCase()
  let allowed: string[]
  if (exam === 'YKS') {
    if (area.includes('SAYISAL')) allowed = ['TYT', 'AYT_SAYISAL', 'BRANS']
    else if (area.includes('EŞİT') || area.includes('ESIT') || area.includes('EA')) allowed = ['TYT', 'AYT_EA', 'BRANS']
    else if (area.includes('SÖZEL') || area.includes('SOZEL')) allowed = ['TYT', 'AYT_SOZEL', 'BRANS']
    else if (area.includes('DİL') || area.includes('DIL')) allowed = ['TYT', 'AYT_DIL', 'BRANS']
    else allowed = ['TYT', 'AYT_SAYISAL', 'AYT_EA', 'AYT_SOZEL', 'AYT_DIL', 'BRANS']
  } else if (exam === 'TYT') allowed = ['TYT']
  else if (exam === 'AYT') allowed = ['AYT_SAYISAL', 'AYT_EA', 'AYT_SOZEL', 'AYT_DIL', 'BRANS']
  else if (exam === 'YDT') allowed = ['AYT_DIL']
  else if (exam === 'KPSS') {
    // KPSS Lisans/Önlisans seçimine göre yalnızca ilgili sınav türü gösterilir.
    if (area.includes('ONLISANS') || area.includes('ÖNLISANS')) {
      allowed = ['KPSS_ONLISANS', 'BRANS']
    } else if (area.includes('LISANS')) {
      allowed = ['KPSS_LISANS', 'BRANS']
    } else {
      allowed = ['KPSS_LISANS', 'KPSS_ONLISANS', 'BRANS']
    }
  }
  else if (exam === 'LGS') allowed = ['LGS', 'BRANS']
  else if (exam === 'ALES') allowed = ['ALES']
  else if (exam === 'YDS') allowed = ['YDS']
  else if (exam === 'ÖĞRETMENLIK' || exam === 'OGRETMENLIK' || exam === 'ÖĞRETMENLİK') allowed = ['AGS', 'OABT']
  else if (exam === 'OKULSINAVI' || exam === 'OKUL_SINAVI') allowed = ['OKUL_SINAVI']
  else return []
  return examTypes.filter((t) => allowed.includes(t.apiType))
}

/**
 * Okul Sınavı için dinamik deneme türü — kullanıcının seçtiği derslerden
 * (varsayılan + custom) oluşturulur. Mobil ile birebir mantık.
 */
export function buildOkulSinaviType(subjectNames: string[]): ExamTypeInfo {
  return {
    displayName: 'Sınav/Çıkmış Denemesi',
    apiType: 'OKUL_SINAVI',
    lessons: subjectNames.map((n) => ({ name: n, maxQuestions: 20 })),
  }
}

/** BRANS türü için, diğer türlerin derslerinden benzersiz bir ders havuzu üretir. */
export function bransBranchLessons(types: ExamTypeInfo[]): LessonSlot[] {
  const seen = new Set<string>()
  const lessons: LessonSlot[] = []
  for (const t of types) {
    if (t.apiType === 'BRANS') continue
    for (const l of t.lessons) {
      if (!seen.has(l.name)) {
        seen.add(l.name)
        lessons.push(l)
      }
    }
  }
  if (lessons.length === 0) {
    return examTypes.find((t) => t.apiType === 'BRANS')?.lessons ?? examTypes[0].lessons
  }
  return lessons
}

export function examTypeDisplayName(apiType: string): string {
  return examTypes.find((t) => t.apiType === apiType)?.displayName ?? apiType
}

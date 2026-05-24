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
      { name: 'Genel Yetenek', maxQuestions: 60 },
      { name: 'Genel Kültür', maxQuestions: 60 },
    ],
  },
]

/** Kullanıcının sınavına/alanına göre hangi deneme türlerinin gösterileceğini belirler. */
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
  } else if (exam === 'KPSS') {
    allowed = ['KPSS_LISANS', 'BRANS']
  } else if (exam === 'LGS') {
    allowed = ['LGS', 'BRANS']
  } else {
    return examTypes
  }
  return examTypes.filter((t) => allowed.includes(t.apiType))
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

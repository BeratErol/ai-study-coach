class ExamTypeInfo {
  final String displayName;
  final String apiType;
  final List<LessonSlot> lessons;
  const ExamTypeInfo({
    required this.displayName,
    required this.apiType,
    required this.lessons,
  });
}

class LessonSlot {
  final String name;
  final int maxQuestions;
  const LessonSlot(this.name, this.maxQuestions);
}

const List<ExamTypeInfo> kExamTypes = [
  ExamTypeInfo(
    displayName: 'TYT',
    apiType: 'TYT',
    lessons: [
      LessonSlot('TYT Türkçe', 40),
      LessonSlot('TYT Sosyal Bilimler', 20),
      LessonSlot('TYT Matematik', 40),
      LessonSlot('TYT Fen Bilimleri', 20),
    ],
  ),
  ExamTypeInfo(
    displayName: 'AYT (Sayısal)',
    apiType: 'AYT_SAYISAL',
    lessons: [
      LessonSlot('Matematik', 40),
      LessonSlot('Fen Bilimleri', 40),
    ],
  ),
  ExamTypeInfo(
    displayName: 'AYT (Eşit Ağırlık)',
    apiType: 'AYT_EA',
    lessons: [
      LessonSlot('Matematik', 40),
      LessonSlot('Edebiyat', 24),
      LessonSlot('Tarih-1', 10),
      LessonSlot('Coğrafya-1', 6),
    ],
  ),
  ExamTypeInfo(
    displayName: 'AYT (Sözel)',
    apiType: 'AYT_SOZEL',
    lessons: [
      LessonSlot('Edebiyat', 24),
      LessonSlot('Tarih-1', 10),
      LessonSlot('Coğrafya-1', 6),
      LessonSlot('Tarih-2', 11),
      LessonSlot('Coğrafya-2', 11),
      LessonSlot('Felsefe Grubu', 12),
      LessonSlot('Din Kültürü', 6),
    ],
  ),
  ExamTypeInfo(
    displayName: 'AYT (Dil)',
    apiType: 'AYT_DIL',
    lessons: [
      LessonSlot('Yabancı Dil', 80),
    ],
  ),
  ExamTypeInfo(
    displayName: 'Branş Denemesi',
    apiType: 'BRANS',
    lessons: [
      LessonSlot('Matematik', 40),
      LessonSlot('Fizik', 30),
      LessonSlot('Kimya', 30),
      LessonSlot('Biyoloji', 30),
      LessonSlot('Türkçe', 40),
      LessonSlot('Edebiyat', 40),
      LessonSlot('Tarih', 20),
      LessonSlot('Coğrafya', 20),
    ],
  ),
  ExamTypeInfo(
    displayName: 'LGS',
    apiType: 'LGS',
    lessons: [
      LessonSlot('Türkçe', 20),
      LessonSlot('Matematik', 20),
      LessonSlot('Fen Bilimleri', 20),
      LessonSlot('İnkılap Tarihi', 10),
      LessonSlot('Din Kültürü', 10),
      LessonSlot('Yabancı Dil', 10),
    ],
  ),
  ExamTypeInfo(
    displayName: 'KPSS (Lisans)',
    apiType: 'KPSS_LISANS',
    lessons: [
      // Genel Yetenek (60): Türkçe 30, Matematik 27, Geometri 3.
      LessonSlot('Türkçe', 30),
      LessonSlot('Matematik', 27),
      LessonSlot('Geometri', 3),
      // Genel Kültür (60): Tarih 27, Coğrafya 18, Vatandaşlık 9, Güncel 6.
      LessonSlot('Tarih', 27),
      LessonSlot('Coğrafya', 18),
      LessonSlot('Vatandaşlık', 9),
      LessonSlot('Güncel Bilgiler', 6),
    ],
  ),
  ExamTypeInfo(
    displayName: 'KPSS (Önlisans)',
    apiType: 'KPSS_ONLISANS',
    lessons: [
      LessonSlot('Türkçe', 30),
      LessonSlot('Matematik', 27),
      LessonSlot('Geometri', 3),
      LessonSlot('Tarih', 27),
      LessonSlot('Coğrafya', 18),
      LessonSlot('Vatandaşlık', 9),
      LessonSlot('Güncel Bilgiler', 6),
    ],
  ),
  ExamTypeInfo(
    displayName: 'ALES',
    apiType: 'ALES',
    lessons: [
      LessonSlot('Sayısal', 50),
      LessonSlot('Sözel', 50),
    ],
  ),
  ExamTypeInfo(
    displayName: 'YDS / e-YDS',
    apiType: 'YDS',
    lessons: [
      LessonSlot('Vocabulary', 6),
      LessonSlot('Grammar', 10),
      LessonSlot('Cloze Test', 10),
      LessonSlot('Sentence Completion', 10),
      LessonSlot('Translation', 6),
      LessonSlot('Reading Passages', 20),
      LessonSlot('Dialogue Completion', 5),
      LessonSlot('Restatement', 4),
      LessonSlot('Paragraph Completion', 4),
      LessonSlot('Irrelevant Sentence', 5),
    ],
  ),
  ExamTypeInfo(
    displayName: 'ÖABT',
    apiType: 'OABT',
    lessons: [
      LessonSlot('Alan Bilgisi', 40),
      LessonSlot('Alan Eğitimi', 10),
    ],
  ),
  ExamTypeInfo(
    displayName: 'AGS (MEB Akademi Giriş)',
    apiType: 'AGS',
    lessons: [
      LessonSlot('Sözel Yetenek', 15),
      LessonSlot('Matematik (Sayısal Yetenek)', 15),
      LessonSlot('Eğitim Bilimleri', 30),
      LessonSlot('Mevzuat', 8),
      LessonSlot('Tarih', 6),
      LessonSlot('Türkiye Coğrafyası', 6),
    ],
  ),
];

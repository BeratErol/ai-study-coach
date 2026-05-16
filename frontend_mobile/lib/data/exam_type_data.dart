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
      LessonSlot('Edebiyat', 40),
      LessonSlot('Tarih-1', 10),
      LessonSlot('Coğrafya-1', 10),
    ],
  ),
  ExamTypeInfo(
    displayName: 'AYT (Sözel)',
    apiType: 'AYT_SOZEL',
    lessons: [
      LessonSlot('Edebiyat', 40),
      LessonSlot('Tarih-1', 10),
      LessonSlot('Coğrafya-1', 10),
      LessonSlot('Tarih-2', 10),
      LessonSlot('Coğrafya-2', 10),
      LessonSlot('Felsefe', 10),
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
      LessonSlot('Genel Yetenek', 60),
      LessonSlot('Genel Kültür', 60),
    ],
  ),
];

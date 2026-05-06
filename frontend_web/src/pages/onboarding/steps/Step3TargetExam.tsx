import { useOnboardingStore } from '../../../stores/onboardingStore'

const examsByLevel: Record<string, { icon: string; title: string; subtitle: string; value: string }[]> = {
  ortaokul: [{ icon: '📋', title: 'LGS', subtitle: 'Liselere Geçiş Sınavı (8. Sınıf)', value: 'LGS' }],
  lise: [{ icon: '🎓', title: 'YKS', subtitle: 'Yükseköğretim Kurumları Sınavı', value: 'YKS' }],
  universite: [
    { icon: '🏢', title: 'KPSS', subtitle: 'Kamu Personeli Seçme Sınavı', value: 'KPSS' },
    { icon: '📐', title: 'ALES', subtitle: 'Akademik Personel ve Lisansüstü Eğitimi Giriş Sınavı', value: 'ALES' },
    { icon: '🌐', title: 'YDS', subtitle: 'Yabancı Dil Sınavı', value: 'YDS' },
    { icon: '👩‍🏫', title: 'Öğretmenlik', subtitle: 'AGS ve ÖABT', value: 'Öğretmenlik' },
  ],
}

export default function Step3TargetExam() {
  const { educationLevel, targetExam, updateTargetExam, updateSelectedArea, updateStrongSubjects, updateWeakSubjects } =
    useOnboardingStore()

  const exams = examsByLevel[educationLevel] ?? examsByLevel['lise']

  function select(value: string) {
    updateTargetExam(value)
    updateSelectedArea('')
    updateStrongSubjects([])
    updateWeakSubjects([])
  }

  return (
    <div className="w-full">
      <div className="mb-10">
        <div className="flex items-center gap-4 mb-4">
          <span className="text-6xl">🎯</span>
          <h2 className="text-4xl font-bold text-gray-900 leading-tight">Hedefin Ne?</h2>
        </div>
        <p className="text-lg text-gray-500 mt-3">Sınav hedefini seç</p>
      </div>

      <div className="space-y-4">
        {exams.map((exam) => (
          <button
            key={exam.value}
            onClick={() => select(exam.value)}
            className={`w-full flex items-center gap-5 p-6 rounded-3xl border-2 cursor-pointer transition-all duration-200 select-none text-left ${
              targetExam === exam.value
                ? 'border-indigo-600 bg-indigo-50 shadow-md shadow-indigo-100'
                : 'border-gray-200 bg-white hover:border-indigo-300 hover:bg-indigo-50/40 hover:shadow-sm'
            }`}
          >
            <span className="text-4xl flex-shrink-0">{exam.icon}</span>
            <div className="flex-1">
              <p className={`font-bold text-xl ${targetExam === exam.value ? 'text-indigo-700' : 'text-gray-900'}`}>
                {exam.title}
              </p>
              <p className="text-gray-500 text-base mt-1">{exam.subtitle}</p>
            </div>
            {targetExam === exam.value && (
              <div className="w-8 h-8 bg-indigo-600 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-white font-bold text-base">✓</span>
              </div>
            )}
          </button>
        ))}
      </div>
    </div>
  )
}

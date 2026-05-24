import { useOnboardingStore } from '../../../stores/onboardingStore'
import StepHeader from './StepHeader'

const examsByLevel: Record<string, { icon: string; title: string; subtitle: string; value: string }[]> = {
  ortaokul: [
    { icon: '📋', title: 'LGS', subtitle: 'Liselere Geçiş Sınavı (8. Sınıf)', value: 'LGS' },
    { icon: '🏫', title: 'Okul Sınavlarım', subtitle: 'Yazılı sınavlar için hazırlan', value: 'OkulSinavi' },
  ],
  lise: [
    { icon: '🎓', title: 'YKS', subtitle: 'Yükseköğretim Kurumları Sınavı', value: 'YKS' },
    { icon: '🏫', title: 'Okul Sınavlarım', subtitle: 'Yazılı sınavlar için hazırlan', value: 'OkulSinavi' },
  ],
  universite: [
    { icon: '🏢', title: 'KPSS', subtitle: 'Kamu Personeli Seçme Sınavı', value: 'KPSS' },
    { icon: '📐', title: 'ALES', subtitle: 'Akademik Personel ve Lisansüstü Eğitimi Giriş Sınavı', value: 'ALES' },
    { icon: '🌐', title: 'YDS', subtitle: 'Yabancı Dil Sınavı', value: 'YDS' },
    { icon: '👩‍🏫', title: 'Öğretmenlik', subtitle: 'AGS ve ÖABT', value: 'Öğretmenlik' },
    { icon: '🏛️', title: 'Okul Sınavlarım', subtitle: 'Vize/Final sınavları için hazırlan', value: 'OkulSinavi' },
  ],
}

export default function Step3TargetExam() {
  const { educationLevel, targetExam, updateTargetExam, updateSelectedArea, updateStrongSubjects, updateWeakSubjects, updateCustomSubjects } =
    useOnboardingStore()

  const exams = examsByLevel[educationLevel] ?? examsByLevel['lise']

  function select(value: string) {
    updateTargetExam(value)
    updateSelectedArea('')
    updateStrongSubjects([])
    updateWeakSubjects([])
    updateCustomSubjects([])
  }

  return (
    <div className="w-full max-w-3xl mx-auto">
      <StepHeader
        emoji="🎯"
        title="Hedefin Ne?"
        subtitle={educationLevel === 'ortaokul' ? 'Ortaokul için uygun hedefler' : 'Sınav hedefini seç'}
      />

      <div className="space-y-5">
        {exams.map((exam) => {
          const active = targetExam === exam.value
          return (
            <button
              key={exam.value}
              onClick={() => select(exam.value)}
              className={`w-full flex items-center gap-5 p-7 rounded-3xl border-2 cursor-pointer transition-all duration-200 select-none text-left ${
                active
                  ? 'border-indigo-600 bg-indigo-50 shadow-lg shadow-indigo-100'
                  : 'border-gray-200 bg-white hover:border-indigo-300 hover:bg-indigo-50/40 hover:shadow-md'
              }`}
            >
              <span className="text-5xl flex-shrink-0">{exam.icon}</span>
              <div className="flex-1">
                <p className={`font-bold text-2xl ${active ? 'text-indigo-700' : 'text-gray-900'}`}>
                  {exam.title}
                </p>
                <p className="text-gray-500 text-base mt-1.5">{exam.subtitle}</p>
              </div>
              {active && (
                <div className="w-10 h-10 bg-indigo-600 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white font-bold text-lg">✓</span>
                </div>
              )}
            </button>
          )
        })}
      </div>
    </div>
  )
}

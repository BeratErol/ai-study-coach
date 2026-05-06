import { useOnboardingStore } from '../../../stores/onboardingStore'

const yksOptions = [
  { icon: '📘', title: 'Sadece TYT', subtitle: 'Sadece TYT dersleri ve TYT denemeleri', value: 'sadece_tyt' },
  { icon: '🔢', title: 'Sayısal (MF)', subtitle: 'Matematik, Fizik, Kimya, Biyoloji', value: 'sayisal' },
  { icon: '⚖️', title: 'Eşit Ağırlık (TM)', subtitle: 'Matematik, Edebiyat, Tarih, Coğrafya', value: 'esit_agirlik' },
  { icon: '📚', title: 'Sözel (TS)', subtitle: 'Edebiyat, Tarih, Coğrafya, Felsefe', value: 'sozel' },
  { icon: '🌐', title: 'Dil', subtitle: 'Yabancı Dil (İngilizce)', value: 'dil' },
]

const kpssOptions = [
  { icon: '💼', title: 'KPSS Lisans', subtitle: 'Genel Yetenek - Genel Kültür', value: 'kpss_lisans' },
  { icon: '📁', title: 'KPSS Önlisans', subtitle: 'Genel Yetenek - Genel Kültür', value: 'kpss_onlisans' },
]

export default function Step4AreaSelection() {
  const { targetExam, selectedArea, updateSelectedArea, updateStrongSubjects, updateWeakSubjects } =
    useOnboardingStore()

  const options = targetExam === 'YKS' ? yksOptions : kpssOptions

  function select(value: string) {
    updateSelectedArea(value)
    updateStrongSubjects([])
    updateWeakSubjects([])
  }

  return (
    <div className="w-full">
      <div className="mb-10">
        <div className="flex items-center gap-4 mb-4">
          <span className="text-6xl">🗺️</span>
          <h2 className="text-4xl font-bold text-gray-900 leading-tight">Hangi Alandan Hazırlanıyorsun?</h2>
        </div>
        <p className="text-lg text-gray-500 mt-3">Bu seçim ders havuzunu belirleyecek</p>
      </div>

      <div className="space-y-4">
        {options.map((opt) => (
          <button
            key={opt.value}
            onClick={() => select(opt.value)}
            className={`w-full flex items-center gap-5 p-6 rounded-3xl border-2 cursor-pointer transition-all duration-200 select-none text-left ${
              selectedArea === opt.value
                ? 'border-indigo-600 bg-indigo-50 shadow-md shadow-indigo-100'
                : 'border-gray-200 bg-white hover:border-indigo-300 hover:bg-indigo-50/40 hover:shadow-sm'
            }`}
          >
            <span className="text-4xl flex-shrink-0">{opt.icon}</span>
            <div className="flex-1">
              <p className={`font-bold text-xl ${selectedArea === opt.value ? 'text-indigo-700' : 'text-gray-900'}`}>
                {opt.title}
              </p>
              <p className="text-gray-500 text-base mt-1">{opt.subtitle}</p>
            </div>
            {selectedArea === opt.value && (
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

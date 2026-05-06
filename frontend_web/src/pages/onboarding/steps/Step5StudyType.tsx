import { useOnboardingStore } from '../../../stores/onboardingStore'

const options = [
  {
    emoji: '🌅',
    title: 'Sabah Kuşu',
    subtitle: 'Program, derslerimi müsait olduğum en erken saatte başlatsın',
    value: 'sabah',
  },
  {
    emoji: '🌙',
    title: 'Gece Baykuşu',
    subtitle: 'Program, derslerimi müsait olduğum en geç saatte bitirsin',
    value: 'gece',
  },
]

export default function Step5StudyType() {
  const { studyType, updateStudyType } = useOnboardingStore()

  return (
    <div className="w-full">
      <div className="mb-10">
        <div className="flex items-center gap-4 mb-4">
          <span className="text-6xl">⏰</span>
          <h2 className="text-4xl font-bold text-gray-900 leading-tight">Ne Zaman Daha Verimlisin?</h2>
        </div>
        <p className="text-lg text-gray-500 mt-3 leading-relaxed">
          Sabah Kuşunu seçersen programın, okul/iş çıkışından sonra günün ilk uygun saatinde başlayacak.
          Gece Baykuşunu seçersen programın, belirlediğin en geç saatte bitecek şekilde ayarlanacak.
        </p>
      </div>

      <div className="space-y-4">
        {options.map((opt) => (
          <button
            key={opt.value}
            onClick={() => updateStudyType(opt.value)}
            className={`w-full flex items-center gap-5 p-6 rounded-3xl border-2 cursor-pointer transition-all duration-200 select-none text-left ${
              studyType === opt.value
                ? 'border-indigo-600 bg-indigo-50 shadow-md shadow-indigo-100'
                : 'border-gray-200 bg-white hover:border-indigo-300 hover:bg-indigo-50/40 hover:shadow-sm'
            }`}
          >
            <span className="text-4xl flex-shrink-0">{opt.emoji}</span>
            <div className="flex-1">
              <p className={`font-bold text-xl ${studyType === opt.value ? 'text-indigo-700' : 'text-gray-900'}`}>
                {opt.title}
              </p>
              <p className="text-gray-500 text-base mt-1 leading-relaxed">{opt.subtitle}</p>
            </div>
            {studyType === opt.value && (
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

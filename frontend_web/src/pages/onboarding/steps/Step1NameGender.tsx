import { useOnboardingStore } from '../../../stores/onboardingStore'
import StepHeader from './StepHeader'

export default function Step1NameGender() {
  const { name, gender, updateName, updateGender } = useOnboardingStore()

  return (
    <div className="w-full max-w-2xl mx-auto">
      <StepHeader emoji="👤" title="Seni Tanıyalım" subtitle="Koçun sana özel bir deneyim sunacak" />

      <label className="block text-lg font-semibold text-gray-700 mb-3">İsmin</label>
      <input
        type="text"
        value={name}
        onChange={(e) => updateName(e.target.value)}
        placeholder="İsmin..."
        className="w-full border-2 border-gray-200 rounded-2xl px-6 py-5 text-xl focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50 outline-none transition-all bg-white mb-8"
      />

      <label className="block text-lg font-semibold text-gray-700 mb-4">Cinsiyet</label>
      <div className="grid grid-cols-2 gap-4">
        {[
          { label: '👦', text: 'Erkek', value: 'erkek' },
          { label: '👧', text: 'Kız', value: 'kiz' },
        ].map((opt) => (
          <button
            key={opt.value}
            onClick={() => updateGender(opt.value)}
            className={`flex flex-col items-center justify-center p-6 min-h-[100px] rounded-3xl border-2 cursor-pointer transition-all duration-200 select-none ${
              gender === opt.value
                ? 'border-indigo-600 bg-indigo-50 shadow-md shadow-indigo-100'
                : 'border-gray-200 bg-white hover:border-indigo-300 hover:bg-indigo-50/40 hover:shadow-sm'
            }`}
          >
            <span className="text-5xl mb-2">{opt.label}</span>
            <span className={`font-bold text-xl ${gender === opt.value ? 'text-indigo-700' : 'text-gray-900'}`}>
              {opt.text}
            </span>
          </button>
        ))}
      </div>
    </div>
  )
}

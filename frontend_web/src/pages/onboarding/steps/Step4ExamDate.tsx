import { useOnboardingStore } from '../../../stores/onboardingStore'
import StepHeader from './StepHeader'

export default function Step4ExamDate({ onSkip }: { onSkip: () => void }) {
  const { examDate, targetExam, updateExamDate } = useOnboardingStore()

  return (
    <div className="w-full max-w-3xl mx-auto">
      <StepHeader
        emoji="📆"
        title="Sınav Tarihin"
        subtitle={`Geri sayım için ${targetExam} sınav tarihini seç. İstersen atlayabilirsin.`}
      />

      <div className="bg-white rounded-3xl border-2 border-gray-200 p-8 mb-6">
        <label className="block text-xl font-semibold text-gray-700 mb-4">Sınav tarihi</label>
        <input
          type="date"
          value={examDate ?? ''}
          onChange={(e) => updateExamDate(e.target.value || null)}
          min={new Date().toISOString().split('T')[0]}
          className="w-full h-16 border-2 border-gray-200 rounded-2xl px-6 text-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50 transition-all bg-white"
        />
      </div>

      {examDate && (
        <div className="bg-indigo-50 border-2 border-indigo-200 rounded-2xl px-6 py-5 mb-6 text-lg text-indigo-700 font-medium">
          📅 Seçilen tarih: {new Date(examDate).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
        </div>
      )}

      <div className="text-center">
        <button
          onClick={onSkip}
          className="text-lg text-gray-400 hover:text-gray-600 underline transition cursor-pointer"
        >
          Şimdilik atla →
        </button>
      </div>
    </div>
  )
}

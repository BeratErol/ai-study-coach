import { useOnboardingStore } from '../../../stores/onboardingStore'

export default function Step4ExamDate({ onSkip }: { onSkip: () => void }) {
  const { examDate, targetExam, updateExamDate } = useOnboardingStore()

  return (
    <div className="w-full">
      <div className="mb-10">
        <div className="flex items-center gap-4 mb-4">
          <span className="text-6xl">📆</span>
          <h2 className="text-4xl font-bold text-gray-900 leading-tight">Sınav Tarihin</h2>
        </div>
        <p className="text-lg text-gray-500 mt-3">
          Geri sayım için {targetExam} sınav tarihini seç. İstersen atlayabilirsin.
        </p>
      </div>

      <div className="bg-white rounded-3xl border-2 border-gray-200 p-6 mb-5">
        <label className="block text-lg font-semibold text-gray-700 mb-3">Sınav tarihi</label>
        <input
          type="date"
          value={examDate ?? ''}
          onChange={(e) => updateExamDate(e.target.value || null)}
          min={new Date().toISOString().split('T')[0]}
          className="w-full border-2 border-gray-200 rounded-2xl px-6 py-5 text-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50 transition-all bg-white"
        />
      </div>

      {examDate && (
        <div className="bg-indigo-50 border-2 border-indigo-200 rounded-3xl px-6 py-4 mb-5 text-base text-indigo-700 font-medium">
          📅 Seçilen tarih: {new Date(examDate).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
        </div>
      )}

      <button
        onClick={onSkip}
        className="text-base text-gray-400 hover:text-gray-600 underline transition cursor-pointer"
      >
        Şimdilik atla →
      </button>
    </div>
  )
}

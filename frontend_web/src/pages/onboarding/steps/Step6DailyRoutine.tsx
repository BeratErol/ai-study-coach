import { useOnboardingStore } from '../../../stores/onboardingStore'
import StepHeader from './StepHeader'

const DAY_LABELS = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cts', 'Paz']

function Toggle({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <label className="relative inline-flex items-center cursor-pointer">
      <input type="checkbox" className="sr-only peer" checked={checked} onChange={(e) => onChange(e.target.checked)} />
      <div className="w-12 h-6 bg-gray-300 peer-checked:bg-indigo-600 rounded-full transition-colors after:content-[''] after:absolute after:top-0.5 after:left-0.5 after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-6" />
    </label>
  )
}

function TimeRow({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <div className="flex items-center justify-between px-7 py-6 bg-white rounded-2xl border-2 border-gray-200 cursor-pointer hover:border-indigo-300 transition-colors mb-3">
      <span className="text-gray-700 font-semibold text-xl">{label}</span>
      <div className="flex items-center gap-3">
        <input
          type="time"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="text-indigo-600 font-bold text-3xl border-none bg-transparent outline-none cursor-pointer"
        />
        <span className="text-3xl">🕐</span>
      </div>
    </div>
  )
}

export default function Step6DailyRoutine() {
  const {
    hasWeekdaySchool, weekdayStartTime, weekdayEndTime, weekdayStudyHours,
    hasWeekendCourse, weekendStartTime, weekendStudyHours,
    offDays,
    updateHasWeekdaySchool, updateWeekdayStartTime, updateWeekdayEndTime, updateWeekdayStudyHours,
    updateHasWeekendCourse, updateWeekendStartTime, updateWeekendStudyHours,
    updateOffDays,
  } = useOnboardingStore()

  function toggleDay(idx: number) {
    const updated = offDays.includes(idx)
      ? offDays.filter((d) => d !== idx)
      : [...offDays, idx]
    updateOffDays(updated)
  }

  return (
    <div className="w-full max-w-3xl mx-auto">
      <StepHeader emoji="📅" title="Günlük Rutinin" subtitle="Okul/kurs saatlerin ve çalışma süren" />

      {/* Hafta içi */}
      <div className="bg-slate-50 rounded-3xl border-2 border-gray-200 p-6 mb-5">
        <h3 className="text-indigo-600 font-bold text-2xl mb-5 flex items-center gap-2">
          🏫 Hafta İçi
        </h3>
        <div className="flex items-center justify-between p-5 bg-white rounded-2xl border-2 border-gray-200 mb-4">
          <span className="text-gray-800 font-semibold text-lg">Okulum var</span>
          <Toggle checked={hasWeekdaySchool} onChange={updateHasWeekdaySchool} />
        </div>
        {hasWeekdaySchool && (
          <div className="mb-2">
            <TimeRow label="Okul başlangıç" value={weekdayStartTime} onChange={updateWeekdayStartTime} />
            <TimeRow label="Okul bitiş" value={weekdayEndTime} onChange={updateWeekdayEndTime} />
          </div>
        )}
        <div className="bg-white rounded-2xl border-2 border-gray-200 p-5">
          <div className="flex justify-between items-center mb-3">
            <span className="text-gray-700 font-semibold text-lg">Günlük Çalışma Saatin</span>
            <span className="text-indigo-600 font-bold text-2xl">{weekdayStudyHours} Saat</span>
          </div>
          <input
            type="range"
            min={1}
            max={10}
            value={weekdayStudyHours}
            onChange={(e) => updateWeekdayStudyHours(Number(e.target.value))}
            className="w-full h-3 bg-indigo-200 rounded-full appearance-none cursor-pointer accent-indigo-600"
          />
        </div>
      </div>

      {/* Hafta sonu */}
      <div className="bg-slate-50 rounded-3xl border-2 border-gray-200 p-6 mb-5">
        <h3 className="text-indigo-600 font-bold text-2xl mb-5 flex items-center gap-2">
          🏖️ Hafta Sonu
        </h3>
        <div className="flex items-center justify-between p-5 bg-white rounded-2xl border-2 border-gray-200 mb-4">
          <span className="text-gray-800 font-semibold text-lg">Kursum var</span>
          <Toggle checked={hasWeekendCourse} onChange={updateHasWeekendCourse} />
        </div>
        {hasWeekendCourse && (
          <div className="mb-2">
            <TimeRow label="Kurs başlangıç" value={weekendStartTime} onChange={updateWeekendStartTime} />
          </div>
        )}
        <div className="bg-white rounded-2xl border-2 border-gray-200 p-5">
          <div className="flex justify-between items-center mb-3">
            <span className="text-gray-700 font-semibold text-lg">Hafta Sonu Çalışma Saatin</span>
            <span className="text-indigo-600 font-bold text-2xl">{weekendStudyHours} Saat</span>
          </div>
          <input
            type="range"
            min={1}
            max={12}
            value={weekendStudyHours}
            onChange={(e) => updateWeekendStudyHours(Number(e.target.value))}
            className="w-full h-3 bg-indigo-200 rounded-full appearance-none cursor-pointer accent-indigo-600"
          />
        </div>
      </div>

      {/* Dinlenme günleri */}
      <div className="bg-slate-50 rounded-3xl border-2 border-gray-200 p-6">
        <h3 className="text-indigo-600 font-bold text-2xl mb-5 flex items-center gap-2">
          😴 Dinlenme Günlerin
        </h3>
        <div className="flex flex-wrap gap-3 mt-4">
          {DAY_LABELS.map((label, idx) => (
            <button
              key={idx}
              onClick={() => toggleDay(idx)}
              className={`px-6 py-3 rounded-2xl font-bold text-lg border-2 transition-all cursor-pointer ${
                offDays.includes(idx)
                  ? 'bg-indigo-600 border-indigo-600 text-white shadow-md'
                  : 'bg-white border-gray-200 text-gray-700 hover:border-indigo-300'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}

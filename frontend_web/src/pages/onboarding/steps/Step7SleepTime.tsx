import { useOnboardingStore } from '../../../stores/onboardingStore'
import StepHeader from './StepHeader'

function TimeRow({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <div className="flex items-center justify-between px-7 py-6 bg-white rounded-2xl border-2 border-gray-200 cursor-pointer hover:border-indigo-300 transition-colors">
      <span className="text-gray-700 font-semibold text-xl">{label}</span>
      <div className="flex items-center gap-3">
        <input
          type="time"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="text-indigo-600 font-bold text-3xl border-none bg-transparent outline-none cursor-pointer"
        />
      </div>
    </div>
  )
}

export default function Step7SleepTime() {
  const {
    weekdayLatestTime, weekendLatestTime,
    updateWeekdayLatestTime, updateWeekendLatestTime,
  } = useOnboardingStore()

  return (
    <div className="w-full max-w-3xl mx-auto">
      <StepHeader
        emoji="🌙"
        title="En Geç Saat"
        subtitle="Gece Baykuşu modunda program bu saatte biter. Sabah Kuşu için referans alınmaz."
      />

      <div className="flex flex-col gap-4">
        <TimeRow
          label="Hafta içi en geç bitiş"
          value={weekdayLatestTime}
          onChange={updateWeekdayLatestTime}
        />
        <TimeRow
          label="Hafta sonu en geç bitiş"
          value={weekendLatestTime}
          onChange={updateWeekendLatestTime}
        />
      </div>
    </div>
  )
}

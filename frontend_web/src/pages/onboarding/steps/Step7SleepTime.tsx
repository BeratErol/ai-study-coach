import { useOnboardingStore } from '../../../stores/onboardingStore'

function TimeRow({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <div className="flex items-center justify-between px-6 py-5 bg-white rounded-2xl border-2 border-gray-200 cursor-pointer hover:border-indigo-300 transition-colors">
      <span className="text-gray-700 font-semibold text-lg">{label}</span>
      <div className="flex items-center gap-3">
        <input
          type="time"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="text-indigo-600 font-bold text-2xl border-none bg-transparent outline-none cursor-pointer"
        />
        <span className="text-2xl">🕐</span>
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
    <div className="w-full">
      <div className="mb-10">
        <div className="flex items-center gap-4 mb-4">
          <span className="text-6xl">🌙</span>
          <h2 className="text-4xl font-bold text-gray-900 leading-tight">En Geç Saat</h2>
        </div>
        <p className="text-lg text-gray-500 mt-3 leading-relaxed">
          Gece Baykuşu modunda program bu saatte bitecek şekilde ayarlanır.
          Sabah Kuşu için bu saat referans alınmaz.
        </p>
      </div>

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

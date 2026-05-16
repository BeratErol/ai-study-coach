import { useOnboardingStore } from '../../../stores/onboardingStore'
import { getSubjectsForExam, type SubjectData } from '../../../data/subjectsData'
import StepHeader from './StepHeader'

function GroupLabel({ label, colorClass }: { label: string; colorClass: string }) {
  return (
    <div className={`inline-flex items-center gap-2 px-5 py-2 rounded-full text-base font-bold mb-4 mt-6 ${colorClass}`}>
      {label}
    </div>
  )
}

function SubjectChips({
  subjects,
  selected,
  disabled,
  onToggle,
  selectedClass,
}: {
  subjects: SubjectData[]
  selected: string[]
  disabled: string[]
  onToggle: (name: string) => void
  selectedClass: string
}) {
  return (
    <div className="flex flex-wrap gap-3">
      {subjects.map((s) => {
        const isSelected = selected.includes(s.name)
        const isDisabled = disabled.includes(s.name)
        return (
          <button
            key={s.name}
            onClick={() => !isDisabled && onToggle(s.name)}
            disabled={isDisabled}
            className={`flex items-center gap-3 px-5 py-3.5 rounded-2xl border-2 font-semibold text-base transition-all cursor-pointer ${
              isDisabled
                ? 'opacity-40 cursor-not-allowed border-gray-200 bg-white text-gray-700'
                : isSelected
                ? selectedClass
                : 'border-gray-200 bg-white text-gray-700 hover:border-gray-400 hover:shadow-sm'
            }`}
          >
            <span className="text-2xl">{s.emoji}</span>
            <span>{s.name}</span>
          </button>
        )
      })}
    </div>
  )
}

function SubjectGrid({
  subjects,
  selected,
  disabled,
  onToggle,
  selectedClass,
}: {
  subjects: SubjectData[]
  selected: string[]
  disabled: string[]
  onToggle: (name: string) => void
  selectedClass: string
}) {
  const hasTyt = subjects.some((s) => s.group === 'tyt')
  const hasAyt = subjects.some((s) => s.group === 'ayt')

  if (hasTyt && hasAyt) {
    const tyt = subjects.filter((s) => s.group === 'tyt')
    const ayt = subjects.filter((s) => s.group === 'ayt')
    return (
      <div>
        <GroupLabel label="📘 TYT Dersleri" colorClass="bg-blue-100 text-blue-700" />
        <SubjectChips subjects={tyt} selected={selected} disabled={disabled} onToggle={onToggle} selectedClass={selectedClass} />
        <GroupLabel label="📙 AYT Dersleri" colorClass="bg-orange-100 text-orange-700" />
        <SubjectChips subjects={ayt} selected={selected} disabled={disabled} onToggle={onToggle} selectedClass={selectedClass} />
      </div>
    )
  }

  return (
    <SubjectChips
      subjects={subjects}
      selected={selected}
      disabled={disabled}
      onToggle={onToggle}
      selectedClass={selectedClass}
    />
  )
}

export default function Step8Subjects() {
  const { targetExam, selectedArea, strongSubjects, weakSubjects, updateStrongSubjects, updateWeakSubjects } =
    useOnboardingStore()

  const subjects = getSubjectsForExam(targetExam, selectedArea)

  function toggleStrong(name: string) {
    const updated = strongSubjects.includes(name)
      ? strongSubjects.filter((s) => s !== name)
      : [...strongSubjects, name]
    updateStrongSubjects(updated)
  }

  function toggleWeak(name: string) {
    const updated = weakSubjects.includes(name)
      ? weakSubjects.filter((s) => s !== name)
      : [...weakSubjects, name]
    updateWeakSubjects(updated)
  }

  return (
    <div className="w-full max-w-4xl mx-auto">
      <StepHeader emoji="📚" title="Derslerini Belirle" subtitle="Güçlü ve zayıf derslerini seç" />

      {/* Güçlü dersler */}
      <div className="bg-green-50 border-2 border-green-200 rounded-3xl p-6 mb-6">
        <div className="flex items-center gap-4 mb-3">
          <span className="text-4xl">💪</span>
          <h3 className="text-2xl font-bold text-gray-900">Güçlü Olduğun Dersler</h3>
        </div>
        <p className="text-gray-600 text-base leading-relaxed mb-4">
          Çalışma planının %25'i bu derslerden oluşacak. Seçmesen de olur.
        </p>
        <SubjectGrid
          subjects={subjects}
          selected={strongSubjects}
          disabled={weakSubjects}
          onToggle={toggleStrong}
          selectedClass="border-green-500 bg-green-50 text-green-800"
        />
      </div>

      {/* Zayıf dersler */}
      <div className="bg-orange-50 border-2 border-orange-200 rounded-3xl p-6">
        <div className="flex items-center gap-4 mb-3">
          <span className="text-4xl">⚡</span>
          <h3 className="text-2xl font-bold text-gray-900">Zorlandığın Dersler</h3>
        </div>
        <p className="text-gray-600 text-base leading-relaxed mb-4">
          Çalışma planının %75'i bu derslerden oluşacak. En az 1 ders seç.
        </p>
        <SubjectGrid
          subjects={subjects}
          selected={weakSubjects}
          disabled={strongSubjects}
          onToggle={toggleWeak}
          selectedClass="border-orange-500 bg-orange-50 text-orange-800"
        />
      </div>
    </div>
  )
}

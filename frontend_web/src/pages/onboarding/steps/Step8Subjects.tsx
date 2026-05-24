import { useState } from 'react'
import { useOnboardingStore } from '../../../stores/onboardingStore'
import { getSubjectsForExam, type SubjectData } from '../../../data/subjectsData'
import StepHeader from './StepHeader'

// ── Ortak: ders grubu etiketi ────────────────────────────────────────────────
function GroupLabel({ label, colorClass }: { label: string; colorClass: string }) {
  return (
    <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl text-base font-bold mb-3 ${colorClass}`}>
      {label}
    </div>
  )
}

// ── Ders seçim chip'leri ─────────────────────────────────────────────────────
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
            className={`flex items-center gap-2.5 px-5 py-3.5 rounded-2xl border-2 font-semibold text-base transition-all cursor-pointer ${
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
        <div className="mt-5">
          <GroupLabel label="📙 AYT Dersleri" colorClass="bg-orange-100 text-orange-700" />
        </div>
        <SubjectChips subjects={ayt} selected={selected} disabled={disabled} onToggle={onToggle} selectedClass={selectedClass} />
      </div>
    )
  }

  return (
    <SubjectChips subjects={subjects} selected={selected} disabled={disabled} onToggle={onToggle} selectedClass={selectedClass} />
  )
}

// ── Güçlü/Zayıf bölüm kartı ──────────────────────────────────────────────────
function SectionCard({
  emoji,
  title,
  subtitle,
  headerBg,
  borderColor,
  children,
}: {
  emoji: string
  title: string
  subtitle: string
  headerBg: string
  borderColor: string
  children: React.ReactNode
}) {
  return (
    <div className="rounded-3xl overflow-hidden" style={{ border: `2px solid ${borderColor}` }}>
      <div className="px-6 py-5" style={{ background: headerBg }}>
        <p className="font-extrabold text-lg text-gray-900">{emoji} {title}</p>
        <p className="text-base text-gray-600 mt-1">{subtitle}</p>
      </div>
      <div className="p-6 bg-white">{children}</div>
    </div>
  )
}

// ── Standart adım (OkulSinavi olmayan) ───────────────────────────────────────
function StandardSubjects({ subjects }: { subjects: SubjectData[] }) {
  const { strongSubjects, weakSubjects, updateStrongSubjects, updateWeakSubjects } = useOnboardingStore()

  function toggle(list: string[], setter: (v: string[]) => void, name: string) {
    setter(list.includes(name) ? list.filter((s) => s !== name) : [...list, name])
  }

  return (
    <div className="space-y-6">
      <SectionCard
        emoji="💪"
        title="Güçlü Olduğun / Daha Az Çalışmak İstediğin Dersler"
        subtitle="Çalışma planının %25'i bu derslerden oluşacak. Seçmesen de olur."
        headerBg="#E8F5E9"
        borderColor="#C8E6C9"
      >
        <SubjectGrid
          subjects={subjects}
          selected={strongSubjects}
          disabled={weakSubjects}
          onToggle={(n) => toggle(strongSubjects, updateStrongSubjects, n)}
          selectedClass="border-green-500 bg-green-50 text-green-800"
        />
      </SectionCard>

      <SectionCard
        emoji="⚡"
        title="Zorlandığın / Daha Çok Çalışmak İstediğin Dersler"
        subtitle="Çalışma planının %75'i bu derslerden oluşacak. En az 1 ders seçmelisin."
        headerBg="#FFF3E0"
        borderColor="#FFCC80"
      >
        <SubjectGrid
          subjects={subjects}
          selected={weakSubjects}
          disabled={strongSubjects}
          onToggle={(n) => toggle(weakSubjects, updateWeakSubjects, n)}
          selectedClass="border-orange-500 bg-orange-50 text-orange-800"
        />
      </SectionCard>
    </div>
  )
}

// ── OkulSinavi adımı (manuel ders ekleme) ────────────────────────────────────
function OkulSinaviSubjects() {
  const {
    targetExam, selectedArea,
    strongSubjects, weakSubjects, customSubjects,
    updateStrongSubjects, updateWeakSubjects, updateCustomSubjects,
  } = useOnboardingStore()
  const [input, setInput] = useState('')

  const isFullyManual = selectedArea === 'uni_diger'
  const baseSubjects = isFullyManual ? [] : getSubjectsForExam(targetExam, selectedArea)
  const baseNames = new Set(baseSubjects.map((s) => s.name))
  const extraNames = customSubjects.filter((n) => !baseNames.has(n))
  const allSubjects: SubjectData[] = [
    ...baseSubjects,
    ...extraNames.map((name) => ({ name, emoji: '📝', group: 'default' as const })),
  ]

  function addSubject() {
    const trimmed = input.trim()
    if (!trimmed) return
    if (!customSubjects.includes(trimmed)) {
      updateCustomSubjects([...customSubjects, trimmed])
    }
    setInput('')
  }

  function removeSubject(name: string) {
    updateCustomSubjects(customSubjects.filter((s) => s !== name))
    updateStrongSubjects(strongSubjects.filter((s) => s !== name))
    updateWeakSubjects(weakSubjects.filter((s) => s !== name))
  }

  function toggle(list: string[], setter: (v: string[]) => void, name: string) {
    setter(list.includes(name) ? list.filter((s) => s !== name) : [...list, name])
  }

  return (
    <div className="space-y-6">
      <p className="text-base text-gray-500 -mt-4 text-center">
        {isFullyManual
          ? 'Sınava gireceğin dersleri aşağıya ekle, sonra güçlü/zayıf olarak işaretle.'
          : 'Listeye ek ders ekleyebilir ya da eklediğin dersleri çıkarabilirsin.'}
      </p>

      {/* Ders ekleme alanı */}
      <div className="flex gap-3">
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && addSubject()}
          placeholder="Ders adı yaz (örn. Fizik)"
          className="flex-1 h-14 border-2 border-gray-200 rounded-2xl px-5 text-lg outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50 transition-all"
        />
        <button
          onClick={addSubject}
          className="w-14 h-14 rounded-2xl flex items-center justify-center text-white text-2xl font-bold transition-all hover:opacity-90"
          style={{ background: '#4F46E5' }}
        >
          +
        </button>
      </div>

      {/* Ders havuzu / eklenenler */}
      {allSubjects.length > 0 ? (
        <SectionCard
          emoji="📋"
          title={isFullyManual ? 'Eklenen Dersler' : 'Ders Havuzu'}
          subtitle={isFullyManual ? 'Tüm dersler kendi seçimindir.' : 'Eklediğin dersler de havuza dahil edilir.'}
          headerBg="#EEF2FF"
          borderColor="#C7D2FE"
        >
          <div className="flex flex-wrap gap-3">
            {allSubjects.map((s) => {
              const removable = isFullyManual || extraNames.includes(s.name)
              return (
                <div
                  key={s.name}
                  className="flex items-center gap-2 px-4 py-2.5 rounded-2xl border-2 border-gray-200 bg-white text-base"
                >
                  <span className="text-xl">{s.emoji}</span>
                  <span className="text-gray-800">{s.name}</span>
                  {removable && (
                    <button
                      onClick={() => removeSubject(s.name)}
                      className="ml-1 w-6 h-6 rounded-full flex items-center justify-center text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors"
                    >
                      ✕
                    </button>
                  )}
                </div>
              )
            })}
          </div>
        </SectionCard>
      ) : (
        <div className="rounded-3xl border-2 border-dashed border-gray-300 bg-white px-6 py-10 text-center">
          <p className="text-base text-gray-500">Henüz ders eklenmedi. Yukarıdan ders ekle.</p>
        </div>
      )}

      {/* Güçlü / Zayıf seçimi */}
      {allSubjects.length > 0 && (
        <>
          <SectionCard
            emoji="💪"
            title="Güçlü Olduğun / Daha Az Çalışmak İstediğin Dersler"
            subtitle="Çalışma planının %25'i bu derslerden oluşacak."
            headerBg="#E8F5E9"
            borderColor="#C8E6C9"
          >
            <SubjectGrid
              subjects={allSubjects}
              selected={strongSubjects}
              disabled={weakSubjects}
              onToggle={(n) => toggle(strongSubjects, updateStrongSubjects, n)}
              selectedClass="border-green-500 bg-green-50 text-green-800"
            />
          </SectionCard>

          <SectionCard
            emoji="⚡"
            title="Zorlandığın / Daha Çok Çalışmak İstediğin Dersler"
            subtitle="Çalışma planının %75'i bu derslerden oluşacak. En az 1 ders seçmelisin."
            headerBg="#FFF3E0"
            borderColor="#FFCC80"
          >
            <SubjectGrid
              subjects={allSubjects}
              selected={weakSubjects}
              disabled={strongSubjects}
              onToggle={(n) => toggle(weakSubjects, updateWeakSubjects, n)}
              selectedClass="border-orange-500 bg-orange-50 text-orange-800"
            />
          </SectionCard>
        </>
      )}
    </div>
  )
}

export default function Step8Subjects() {
  const { targetExam, selectedArea } = useOnboardingStore()
  const isOkul = targetExam === 'OkulSinavi'

  return (
    <div className="w-full max-w-4xl mx-auto">
      <StepHeader
        emoji="📚"
        title={isOkul && selectedArea === 'uni_diger' ? 'Derslerini Ekle' : 'Derslerini Belirle'}
        subtitle="Güçlü ve zayıf derslerini seç"
      />
      {isOkul ? <OkulSinaviSubjects /> : <StandardSubjects subjects={getSubjectsForExam(targetExam, selectedArea)} />}
    </div>
  )
}

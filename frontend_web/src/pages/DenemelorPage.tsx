import { useEffect, useMemo, useState } from 'react'
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar,
} from 'recharts'
import { useUserProfile } from '../hooks/useUserProfile'
import { denemeService, type ExamRecord, type CreateExamBody } from '../services/denemeService'
import {
  availableExamTypes, bransBranchLessons, examTypeDisplayName, buildOkulSinaviType,
  type ExamTypeInfo, type LessonSlot,
} from '../data/examTypeData'
import { getSubjectsForExam } from '../data/subjectsData'
import { getOnboardingData } from '../services/userPrefsService'
import { getUserId } from '../services/tokenService'

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

const CHART_COLORS = ['#5B5FC7', '#10B981', '#EF4444', '#F59E0B', '#8B5CF6']

// Deneme adı için sınav türüne göre örnek placeholder
function examNamePlaceholder(apiType: string): string {
  switch (apiType) {
    case 'TYT':            return '3D Yayınları TYT Genel'
    case 'AYT_SAYISAL':    return 'Karekök AYT Sayısal'
    case 'AYT_EA':         return 'Limit AYT Eşit Ağırlık'
    case 'AYT_SOZEL':      return 'Palme AYT Sözel'
    case 'AYT_DIL':        return 'Pelikan YDT İngilizce'
    case 'BRANS':          return 'Bilfen Matematik Branş Denemesi'
    case 'LGS':            return 'Çağdaş Eğitim LGS Genel'
    case 'KPSS_LISANS':    return '2024 KPSS Çıkmış Sorular'
    case 'KPSS_ONLISANS':  return 'Yargı KPSS Ön Lisans'
    case 'KPSS_ORTAOGRETIM': return 'Yediiklim KPSS Ortaöğretim'
    case 'ALES':           return 'Pegem ALES Genel — 50+50 soru'
    case 'YDS':            return 'ÖSYM YDS Çıkmış Sorular — 80 soru'
    case 'OABT':           return 'Pegem ÖABT — 40+10 soru'
    case 'AGS':            return 'MEB AGS Denemesi — 80 soru'
    case 'OKUL_SINAVI':    return '2024 Okul Sınavı'
    default:               return 'Deneme adı'
  }
}

function sortByDate(exams: ExamRecord[]): ExamRecord[] {
  return [...exams].sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
}

function detailNet(exam: ExamRecord, lessonName: string): number {
  return exam.details.find((d) => d.lessonName === lessonName)?.net ?? 0
}

// Net formatlama: değeri en yakın 0.25'e yuvarlar (gerçek deneme net birimi).
// Tam sayıysa ondalıksız (35), aksi takdirde .25/.5/.75 olarak gösterir
// (ortalama 59.63 → 59.75 gibi).
function fmtNet(n: number): string {
  const rounded = Math.round(n * 4) / 4
  if (Number.isInteger(rounded)) return rounded.toString()
  return rounded
    .toFixed(2)
    .replace(/0+$/, '')
    .replace(/\.$/, '')
}

function fmtDate(s: string): string {
  const d = new Date(s)
  return `${String(d.getDate()).padStart(2, '0')}.${String(d.getMonth() + 1).padStart(2, '0')}.${d.getFullYear()}`
}

function shortDate(s: string): string {
  const d = new Date(s)
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`
}

// ─── Modal kabuğu ─────────────────────────────────────────────────────────────

function ModalShell({ title, subtitle, onClose, children }: {
  title: string
  subtitle?: string
  onClose: () => void
  children: React.ReactNode
}) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      style={{ background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(4px)' }}
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="w-full max-w-xl rounded-3xl shadow-2xl overflow-hidden max-h-[92vh] flex flex-col"
        style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
      >
        <div className="px-7 py-6" style={{ background: 'linear-gradient(135deg, #C0392B, #E74C3C)' }}>
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-2xl font-extrabold text-white">{title}</h3>
              {subtitle && <p className="text-base text-white/75 mt-1">{subtitle}</p>}
            </div>
            <button
              onClick={onClose}
              className="w-10 h-10 rounded-full flex items-center justify-center text-white/70 hover:text-white hover:bg-white/10 transition-all text-xl"
            >
              ✕
            </button>
          </div>
        </div>
        <div className="p-7 overflow-y-auto">{children}</div>
      </div>
    </div>
  )
}

// ─── Deneme ekleme/düzenleme formu ────────────────────────────────────────────

function ExamFormModal({ existing, availableTypes, branchLessons, onClose, onSaved }: {
  existing: ExamRecord | null
  availableTypes: ExamTypeInfo[]
  branchLessons: LessonSlot[]
  onClose: () => void
  onSaved: () => void
}) {
  const initialType = existing
    ? availableTypes.find((t) => t.apiType === existing.type) ?? availableTypes[0]
    : availableTypes[0]

  const [title, setTitle] = useState(existing?.title ?? '')
  const [selectedType, setSelectedType] = useState<ExamTypeInfo>(initialType)
  const [date, setDate] = useState(
    existing ? existing.date.slice(0, 10) : new Date().toISOString().slice(0, 10),
  )
  const [bransLesson, setBransLesson] = useState<string>(
    existing?.type === 'BRANS' ? existing.details[0]?.lessonName ?? '' : '',
  )
  const [okulLesson, setOkulLesson] = useState<string>(
    existing?.type === 'OKUL_SINAVI' ? existing.details[0]?.lessonName ?? '' : '',
  )
  // OkulSinavi için kullanıcının girdiği soru sayısı (ders başına)
  const [okulMaxQ, setOkulMaxQ] = useState<Record<string, number>>(() => {
    const init: Record<string, number> = {}
    if (existing?.type === 'OKUL_SINAVI') {
      existing.details.forEach((d) => {
        const total = (d.correct ?? 0) + (d.incorrect ?? 0)
        if (total > 0) init[d.lessonName] = total
      })
    }
    return init
  })
  // lessonName → { correct, wrong }
  const [values, setValues] = useState<Record<string, { correct: number; wrong: number }>>(() => {
    const init: Record<string, { correct: number; wrong: number }> = {}
    existing?.details.forEach((d) => {
      init[d.lessonName] = { correct: d.correct, wrong: d.incorrect }
    })
    return init
  })
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const isBrans = selectedType.apiType === 'BRANS'
  const isOkulSinavi = selectedType.apiType === 'OKUL_SINAVI'
  let activeLessons: LessonSlot[]
  if (isBrans) {
    activeLessons = branchLessons.filter((l) => l.name === bransLesson)
  } else if (isOkulSinavi) {
    // OkulSinavi: tek ders + kullanıcının girdiği soru sayısı
    const ls = selectedType.lessons.find((l) => l.name === okulLesson)
    activeLessons = ls
      ? [{ name: ls.name, maxQuestions: okulMaxQ[ls.name] ?? 0 }]
      : []
  } else {
    activeLessons = selectedType.lessons
  }

  const totalNet = activeLessons.reduce((sum, l) => {
    const v = values[l.name] ?? { correct: 0, wrong: 0 }
    // OkulSinavi'de net = doğru sayısı (yanlış cezası yok); diğer sınavlarda
    // doğru - yanlış/4.
    return sum + (isOkulSinavi ? v.correct : v.correct - v.wrong / 4)
  }, 0)

  function setVal(lesson: string, field: 'correct' | 'wrong', n: number) {
    setValues((prev) => ({
      ...prev,
      [lesson]: { ...(prev[lesson] ?? { correct: 0, wrong: 0 }), [field]: Math.max(0, n) },
    }))
  }

  async function save() {
    if (isBrans && !bransLesson) {
      setError('Lütfen bir ders seç.')
      return
    }
    if (isOkulSinavi && !okulLesson) {
      setError('Lütfen bir ders seç.')
      return
    }
    if (isOkulSinavi && (okulMaxQ[okulLesson] ?? 0) <= 0) {
      setError('Soru sayısını gir.')
      return
    }
    const details = activeLessons.map((l) => {
      const v = values[l.name] ?? { correct: 0, wrong: 0 }
      // OkulSinavi'de yanlış cezası yok → backend net = correct olsun diye
      // incorrect=0 gönderilir.
      return {
        lessonName: l.name,
        correct: v.correct,
        incorrect: isOkulSinavi ? 0 : v.wrong,
      }
    })
    if (details.every((d) => d.correct === 0 && d.incorrect === 0)) {
      setError('En az bir derse sonuç girmelisin.')
      return
    }
    setSaving(true)
    setError(null)
    try {
      const body: CreateExamBody = {
        title: title.trim() || `${selectedType.displayName} Denemesi`,
        date: new Date(`${date}T12:00:00`).toISOString(),
        type: selectedType.apiType,
        details,
      }
      if (existing) await denemeService.update(existing.id, body)
      else await denemeService.create(body)
      onSaved()
      onClose()
    } catch {
      setError('Kayıt sırasında bir hata oluştu.')
      setSaving(false)
    }
  }

  return (
    <ModalShell
      title={existing ? '📝 Denemeyi Düzenle' : '📝 Deneme Sonucu Ekle'}
      onClose={onClose}
    >
      <div className="space-y-5">
        {error && (
          <div className="px-4 py-3 rounded-xl text-base" style={{ background: '#FEF2F2', color: '#EF4444' }}>
            {error}
          </div>
        )}

        <div>
          <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>Deneme Adı</label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder={`örn. ${examNamePlaceholder(selectedType.apiType)}`}
            className="w-full h-14 px-4 rounded-xl text-base outline-none"
            style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
          />
        </div>

        <div>
          <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>Deneme Türü</label>
          <select
            value={selectedType.apiType}
            onChange={(e) => {
              const t = availableTypes.find((x) => x.apiType === e.target.value)!
              setSelectedType(t)
              setBransLesson('')
              setOkulLesson('')
              setOkulMaxQ({})
              setValues({})
            }}
            className="w-full h-14 px-4 rounded-xl text-base outline-none"
            style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
          >
            {availableTypes.map((t) => <option key={t.apiType} value={t.apiType}>{t.displayName}</option>)}
          </select>
        </div>

        {isBrans && (
          <div>
            <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>Ders Seç</label>
            <select
              value={bransLesson}
              onChange={(e) => setBransLesson(e.target.value)}
              className="w-full h-14 px-4 rounded-xl text-base outline-none"
              style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
            >
              <option value="">Ders seç</option>
              {branchLessons.map((l) => <option key={l.name} value={l.name}>{l.name}</option>)}
            </select>
          </div>
        )}

        {isOkulSinavi && (
          <>
            <div>
              <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>Sınav Dersi Seç</label>
              <select
                value={okulLesson}
                onChange={(e) => {
                  setOkulLesson(e.target.value)
                  setValues({})
                }}
                className="w-full h-14 px-4 rounded-xl text-base outline-none"
                style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
              >
                <option value="">Ders seç</option>
                {selectedType.lessons.map((l) => <option key={l.name} value={l.name}>{l.name}</option>)}
              </select>
            </div>
            {okulLesson && (
              <div>
                <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>Soru Sayısı</label>
                <input
                  type="number"
                  min={1}
                  value={okulMaxQ[okulLesson] || ''}
                  onChange={(e) =>
                    setOkulMaxQ((prev) => ({ ...prev, [okulLesson]: Math.max(0, parseInt(e.target.value) || 0) }))
                  }
                  placeholder="örn. 20"
                  className="w-full h-14 px-4 rounded-xl text-base outline-none"
                  style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
                />
              </div>
            )}
          </>
        )}

        <div>
          <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>Tarih</label>
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            max={new Date().toISOString().slice(0, 10)}
            className="w-full h-14 px-4 rounded-xl text-base outline-none"
            style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
          />
        </div>

        {/* Toplam net */}
        <div
          className="rounded-2xl py-5 px-6 text-center"
          style={{ background: 'rgba(79,70,229,0.07)', border: '1.5px solid rgba(79,70,229,0.35)' }}
        >
          <p className="text-xl font-extrabold" style={{ color: 'var(--primary)' }}>
            Toplam Net: {fmtNet(totalNet)}
          </p>
          <p className="text-base mt-1" style={{ color: 'var(--text-hint)' }}>
            {isOkulSinavi ? 'Net = Doğru Soru Sayısı' : 'Net = Doğru − (Yanlış ÷ 4)'}
          </p>
        </div>

        {/* Ders bazlı doğru/yanlış */}
        <div>
          <p className="text-base font-bold mb-3" style={{ color: 'var(--text-primary)' }}>Ders Bazlı Doğru / Yanlış</p>
          {(isBrans && !bransLesson) || (isOkulSinavi && (!okulLesson || (okulMaxQ[okulLesson] ?? 0) <= 0)) ? (
            <p className="text-base" style={{ color: 'var(--text-hint)' }}>Ders ve soru sayısını seçtikten sonra doğru/yanlış girebilirsin.</p>
          ) : (
            <div className="space-y-3">
              <div className="flex gap-3 px-1">
                <div className="flex-1" />
                <span className="w-24 text-center text-base font-bold" style={{ color: '#10B981' }}>Doğru</span>
                <span className="w-24 text-center text-base font-bold" style={{ color: '#EF4444' }}>Yanlış</span>
              </div>
              {activeLessons.map((l) => {
                const v = values[l.name] ?? { correct: 0, wrong: 0 }
                return (
                  <div key={l.name} className="flex items-center gap-3">
                    <span className="flex-1 text-base font-semibold" style={{ color: 'var(--text-primary)' }}>
                      {l.name} <span style={{ color: 'var(--text-hint)' }}>({l.maxQuestions})</span>
                    </span>
                    <input
                      type="number"
                      value={v.correct || ''}
                      onChange={(e) => setVal(l.name, 'correct', parseInt(e.target.value) || 0)}
                      placeholder="0"
                      className="w-24 h-12 px-2 rounded-xl text-base text-center outline-none"
                      style={{ background: 'var(--bg)', border: '1.5px solid #BBF7D0', color: 'var(--text-primary)' }}
                    />
                    <input
                      type="number"
                      value={v.wrong || ''}
                      onChange={(e) => setVal(l.name, 'wrong', parseInt(e.target.value) || 0)}
                      placeholder="0"
                      className="w-24 h-12 px-2 rounded-xl text-base text-center outline-none"
                      style={{ background: 'var(--bg)', border: '1.5px solid #FECACA', color: 'var(--text-primary)' }}
                    />
                  </div>
                )
              })}
            </div>
          )}
        </div>

        <button
          onClick={save}
          disabled={saving}
          className="w-full py-4 rounded-xl text-base font-bold text-white transition-all hover:opacity-90 disabled:opacity-50"
          style={{ background: 'var(--primary)' }}
        >
          {saving ? 'Kaydediliyor...' : '💾 Deneme Sonucunu Kaydet'}
        </button>
      </div>
    </ModalShell>
  )
}

// ─── Net özeti ────────────────────────────────────────────────────────────────

function NetSummary({ exams, typeName }: { exams: ExamRecord[]; typeName: string }) {
  const nets = exams.map((e) => e.totalNet)
  const max = Math.max(...nets)
  const min = Math.min(...nets)
  const avg = nets.reduce((a, b) => a + b, 0) / nets.length
  const boxes = [
    { label: 'En Yüksek', value: max, arrow: '↑', color: '#10B981' },
    { label: 'En Düşük', value: min, arrow: '↓', color: '#EF4444' },
    { label: 'Ortalama', value: avg, arrow: '→', color: '#3B82F6' },
  ]
  return (
    <div className="rounded-2xl p-6" style={{ background: '#4F46E514', border: '1.5px solid #4F46E540' }}>
      <p className="text-lg font-extrabold mb-4" style={{ color: 'var(--text-primary)' }}>📊 {typeName} — Net Özeti</p>
      <div className="grid grid-cols-3 gap-3">
        {boxes.map((b) => (
          <div key={b.label} className="rounded-xl py-4 text-center" style={{ background: `${b.color}1A` }}>
            <p className="text-xl font-extrabold" style={{ color: b.color }}>{b.arrow} {fmtNet(b.value)}</p>
            <p className="text-base mt-1" style={{ color: 'var(--text-secondary)' }}>{b.label}</p>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── Trend grafiği ────────────────────────────────────────────────────────────

function TrendChart({ exams }: { exams: ExamRecord[] }) {
  const sorted = sortByDate(exams)
  let running = 0
  const data = sorted.map((e, i) => {
    running += e.totalNet
    return {
      label: shortDate(e.date),
      net: e.totalNet,
      level: running / (i + 1),
      title: e.title || examTypeDisplayName(e.type),
    }
  })
  const avg = sorted.reduce((s, e) => s + e.totalNet, 0) / sorted.length

  return (
    <div className="rounded-2xl p-6" style={{ background: '#10B98114', border: '1.5px solid #10B98140' }}>
      <p className="text-lg font-extrabold mb-1" style={{ color: 'var(--text-primary)' }}>📈 Net Trend</p>
      <div className="flex gap-5 mb-4 text-base" style={{ color: 'var(--text-secondary)' }}>
        <span className="flex items-center gap-1.5"><span className="inline-block w-4 h-1 rounded" style={{ background: '#4F46E5' }} /> Gerçek Net</span>
        <span className="flex items-center gap-1.5"><span className="inline-block w-4 h-0.5 rounded" style={{ background: '#9CA3AF' }} /> Kayan Ortalama</span>
      </div>
      <div style={{ width: '100%', height: 240 }}>
        <ResponsiveContainer>
          <LineChart data={data} margin={{ top: 10, right: 20, bottom: 10, left: -10 }}>
            <CartesianGrid stroke="var(--border)" vertical={false} />
            <XAxis dataKey="label" tick={{ fontSize: 12, fill: 'var(--text-hint)' }} />
            <YAxis tick={{ fontSize: 12, fill: 'var(--text-hint)' }} />
            <Tooltip
              contentStyle={{ background: 'var(--card)', border: '1px solid var(--border)', borderRadius: 12 }}
              formatter={(v, name) => [fmtNet(v as number), name === 'net' ? 'Gerçek Net' : 'Seviye']}
            />
            <Line type="monotone" dataKey="net" stroke="#4F46E5" strokeWidth={3} dot={{ r: 5, fill: '#4F46E5' }} />
            <Line type="monotone" dataKey="level" stroke="#9CA3AF" strokeWidth={2} strokeDasharray="6 4" dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>
      <p className="text-base mt-2" style={{ color: 'var(--text-hint)' }}>Genel ortalama: {fmtNet(avg)} Net</p>
    </div>
  )
}

// ─── Denge radarı ─────────────────────────────────────────────────────────────

function RadarCard({ exams, typeInfo }: { exams: ExamRecord[]; typeInfo: ExamTypeInfo }) {
  const last3 = sortByDate(exams).slice(-3)
  const lessons = typeInfo.lessons
  const [selectedLesson, setSelectedLesson] = useState(0)

  function shortLesson(name: string): string {
    return name.replace(/^(TYT|AYT) /, '')
  }

  // Recharts radar verisi: her ders bir satır, her deneme bir alan
  const data = lessons.map((l) => {
    const row: Record<string, number | string> = { lesson: shortLesson(l.name) }
    last3.forEach((e, i) => {
      row[`exam${i}`] = detailNet(e, l.name)
    })
    return row
  })

  const activeLesson = lessons[selectedLesson]

  return (
    <div className="rounded-2xl p-6" style={{ background: '#F59E0B14', border: '1.5px solid #F59E0B40' }}>
      <p className="text-lg font-extrabold mb-3" style={{ color: 'var(--text-primary)' }}>
        🎯 {typeInfo.displayName} Denge Radarı
      </p>
      <div className="flex flex-wrap gap-4 mb-3">
        {last3.map((e, i) => (
          <span key={e.id} className="flex items-center gap-1.5 text-base" style={{ color: 'var(--text-secondary)' }}>
            <span className="inline-block w-3 h-3 rounded-full" style={{ background: CHART_COLORS[i] }} />
            {(e.title || `Deneme ${i + 1}`)} ({shortDate(e.date)})
          </span>
        ))}
      </div>
      <div style={{ width: '100%', height: 300 }}>
        <ResponsiveContainer>
          <RadarChart data={data} outerRadius="75%">
            <PolarGrid stroke="var(--border)" />
            <PolarAngleAxis dataKey="lesson" tick={{ fontSize: 12, fill: 'var(--text-secondary)' }} />
            {/* Eksen sayıları gizli — net bilgisi alttaki satırlarda */}
            <PolarRadiusAxis tick={false} axisLine={false} />
            {last3.map((e, i) => (
              <Radar
                key={e.id}
                name={e.title || `Deneme ${i + 1}`}
                dataKey={`exam${i}`}
                stroke={CHART_COLORS[i]}
                fill={CHART_COLORS[i]}
                fillOpacity={0.25}
              />
            ))}
          </RadarChart>
        </ResponsiveContainer>
      </div>

      {/* Ders seçim chip'leri */}
      <div className="flex flex-wrap gap-2 mt-4">
        {lessons.map((l, i) => (
          <button
            key={l.name}
            onClick={() => setSelectedLesson(i)}
            className="px-4 py-2 rounded-full text-base font-semibold transition-all"
            style={{
              background: selectedLesson === i ? '#1F2937' : 'var(--bg)',
              color: selectedLesson === i ? '#fff' : 'var(--text-secondary)',
            }}
          >
            {shortLesson(l.name)}
          </button>
        ))}
      </div>

      {/* Seçili dersin denemelere göre netleri */}
      <div className="space-y-2 mt-4">
        {last3.map((e, i) => (
          <div
            key={e.id}
            className="flex items-center gap-3 px-4 py-2.5 rounded-xl"
            style={{ background: `${CHART_COLORS[i]}1A`, border: `1px solid ${CHART_COLORS[i]}59` }}
          >
            <span className="w-3 h-3 rounded-full shrink-0" style={{ background: CHART_COLORS[i] }} />
            <span className="flex-1 text-base font-semibold" style={{ color: CHART_COLORS[i] }}>
              {(e.title || `Deneme ${i + 1}`)} ({shortDate(e.date)})
            </span>
            <span className="text-base font-bold" style={{ color: CHART_COLORS[i] }}>
              {fmtNet(detailNet(e, activeLesson.name))} net
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── Koç analizi ──────────────────────────────────────────────────────────────

interface Insight {
  text: string
  isPositive: boolean
}

function CoachCard({ exams }: { exams: ExamRecord[] }) {
  const sorted = sortByDate(exams)
  const last3 = sorted.slice(-3)
  const lessons = new Set<string>()
  last3.forEach((e) => e.details.forEach((d) => d.lessonName && lessons.add(d.lessonName)))

  const insights: Insight[] = []
  for (const lesson of lessons) {
    const nets = last3.map((e) => detailNet(e, lesson))
    if (nets.length < 2) continue
    const netStr = nets.map(fmtNet).join(' → ')
    if (nets.length >= 3 && nets[0] < nets[1] && nets[1] < nets[2]) {
      insights.push({ text: `🎉 ${lesson} netiniz son 3 denemede sürekli artıyor (${netStr}). Harika ilerleme, böyle devam!`, isPositive: true })
    } else if (nets[nets.length - 1] > nets[0]) {
      insights.push({ text: `📈 ${lesson} netiniz artış gösterdi (${netStr}). İyi gidiyorsunuz, devam et!`, isPositive: true })
    } else if (nets[nets.length - 1] < nets[0]) {
      insights.push({ text: `📉 ${lesson} netiniz düşüş gösterdi (${netStr}). Bu derse daha fazla vakit ayırmanı öneririz.`, isPositive: false })
    }
  }

  if (insights.length === 0) return null

  return (
    <div className="rounded-2xl p-6" style={{ background: '#0EA5E914', border: '1.5px solid #0EA5E940' }}>
      <p className="text-lg font-extrabold mb-3 flex items-center gap-2" style={{ color: 'var(--text-primary)' }}>
        🎓 Koç Analizi
      </p>
      <div className="space-y-2.5">
        {insights.map((ins, i) => (
          <div
            key={i}
            className="px-4 py-3 rounded-xl text-base leading-relaxed"
            style={{
              background: ins.isPositive ? '#10B98120' : '#EF444420',
              border: `1px solid ${ins.isPositive ? '#10B98140' : '#EF444440'}`,
              color: ins.isPositive ? 'var(--success-text)' : 'var(--danger-text)',
            }}
          >
            {ins.text}
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── Deneme karşılaştırması ───────────────────────────────────────────────────

function ComparisonModal({ exams, typeInfo, onClose }: {
  exams: ExamRecord[]
  typeInfo: ExamTypeInfo | null
  onClose: () => void
}) {
  const [selectedIds, setSelectedIds] = useState<number[]>([])
  const sortedAll = sortByDate(exams)
  const selected = sortByDate(exams.filter((e) => selectedIds.includes(e.id)))

  function toggle(id: number) {
    setSelectedIds((prev) => {
      if (prev.includes(id)) return prev.filter((x) => x !== id)
      if (prev.length < 3) return [...prev, id]
      return prev
    })
  }

  const nets = selected.map((e) => e.totalNet)
  let trendText: string | null = null
  let trendUp = true
  if (nets.length >= 2) {
    const diff = nets[nets.length - 1] - nets[0]
    trendUp = diff >= 0
    trendText = trendUp
      ? `Seçtiğin denemeler arasında toplam netinde +${fmtNet(diff)} artış var. Harika gidiyorsun! 🚀`
      : `Seçtiğin denemeler arasında toplam netinde ${fmtNet(diff)} düşüş var. Daha çok çalış. 💪`
  }

  // Ders bazlı karşılaştırma
  const lessons = typeInfo?.lessons ?? []

  return (
    <ModalShell title="📊 Deneme Karşılaştırması" subtitle="Karşılaştırmak için max 3 deneme seç" onClose={onClose}>
      <div className="flex gap-3 overflow-x-auto pb-2 mb-5">
        {sortedAll.map((e) => {
          const idx = selectedIds.indexOf(e.id)
          const isSel = idx !== -1
          return (
            <button
              key={e.id}
              onClick={() => toggle(e.id)}
              className="shrink-0 w-32 p-3 rounded-xl text-center transition-all"
              style={{
                background: isSel ? 'var(--primary)' : 'var(--bg)',
                border: `2px solid ${isSel ? 'var(--primary)' : 'var(--border)'}`,
              }}
            >
              {isSel && <p className="text-lg font-extrabold text-white">{idx + 1}</p>}
              <p className="text-base font-semibold truncate" style={{ color: isSel ? '#fff' : 'var(--text-primary)' }}>
                {e.title || examTypeDisplayName(e.type)}
              </p>
              <p className="text-base mt-0.5" style={{ color: isSel ? 'rgba(255,255,255,0.7)' : 'var(--text-hint)' }}>
                {fmtDate(e.date)}
              </p>
            </button>
          )
        })}
      </div>

      {selected.length < 2 ? (
        <p className="text-base text-center py-6" style={{ color: 'var(--text-hint)' }}>
          Karşılaştırmak için en az 2 deneme seç.
        </p>
      ) : (
        <div className="space-y-5">
          {trendText && (
            <div
              className="px-4 py-3 rounded-xl text-base"
              style={{ background: trendUp ? '#E8F5E9' : '#FFEBEE', color: trendUp ? '#2E7D32' : '#C62828' }}
            >
              {trendText}
            </div>
          )}

          {/* Toplam net grafiği */}
          <div>
            <p className="text-base font-bold mb-2" style={{ color: 'var(--text-primary)' }}>Toplam Net Karşılaştırması</p>
            <div style={{ width: '100%', height: 200 }}>
              <ResponsiveContainer>
                <LineChart
                  data={selected.map((e, i) => ({
                    label: e.title || shortDate(e.date),
                    net: e.totalNet,
                    idx: i,
                  }))}
                  margin={{ top: 10, right: 20, bottom: 10, left: -10 }}
                >
                  <CartesianGrid stroke="var(--border)" vertical={false} />
                  <XAxis dataKey="label" tick={{ fontSize: 11, fill: 'var(--text-hint)' }} />
                  <YAxis tick={{ fontSize: 11, fill: 'var(--text-hint)' }} />
                  <Tooltip
                    contentStyle={{ background: 'var(--card)', border: '1px solid var(--border)', borderRadius: 12 }}
                    formatter={(v) => [fmtNet(v as number), 'Net']}
                  />
                  <Line type="monotone" dataKey="net" stroke="#F59E0B" strokeWidth={3} dot={{ r: 6, fill: '#F59E0B' }} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Toplam net kutucukları */}
          <div className="flex gap-3">
            {selected.map((e, i) => (
              <div key={e.id} className="flex-1 rounded-xl py-3 text-center" style={{ background: `${CHART_COLORS[i]}1A` }}>
                <p className="text-xl font-extrabold" style={{ color: CHART_COLORS[i] }}>{fmtNet(e.totalNet)}</p>
                <p className="text-base" style={{ color: 'var(--text-secondary)' }}>{shortDate(e.date)}</p>
              </div>
            ))}
          </div>

          {/* Ders bazlı net — çubuk karşılaştırma */}
          {lessons.length > 0 && (
            <div>
              <p className="text-base font-bold mb-2" style={{ color: 'var(--text-primary)' }}>Ders Bazlı Net</p>
              <div className="space-y-3">
                {lessons.map((l) => {
                  const maxN = Math.max(1, ...selected.map((e) => detailNet(e, l.name)), l.maxQuestions)
                  return (
                    <div key={l.name}>
                      <p className="text-base font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>{l.name}</p>
                      <div className="space-y-1">
                        {selected.map((e, i) => {
                          const net = detailNet(e, l.name)
                          return (
                            <div key={e.id} className="flex items-center gap-2">
                              <div className="flex-1 h-5 rounded-full overflow-hidden" style={{ background: 'var(--bg)' }}>
                                <div
                                  className="h-full rounded-full"
                                  style={{ width: `${(net / maxN) * 100}%`, background: CHART_COLORS[i] }}
                                />
                              </div>
                              <span className="w-12 text-right text-base font-bold" style={{ color: CHART_COLORS[i] }}>
                                {fmtNet(net)}
                              </span>
                            </div>
                          )
                        })}
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          )}
        </div>
      )}
    </ModalShell>
  )
}

// ─── Deneme kartı ─────────────────────────────────────────────────────────────

function ExamCard({ exam, onEdit, onDelete }: {
  exam: ExamRecord
  onEdit: () => void
  onDelete: () => void
}) {
  return (
    <div
      className="flex items-center gap-4 p-5 rounded-2xl"
      style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
    >
      <div className="w-11 h-11 rounded-xl flex items-center justify-center text-white text-xl shrink-0" style={{ background: 'var(--primary)' }}>
        ✓
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-base font-bold truncate" style={{ color: 'var(--text-primary)' }}>
          {exam.title || examTypeDisplayName(exam.type)}
        </p>
        <p className="text-base" style={{ color: 'var(--text-hint)' }}>{fmtDate(exam.date)}</p>
      </div>
      <span
        className="px-3 py-1.5 rounded-full text-base font-bold"
        style={{ background: '#DCFCE7', color: '#166534' }}
      >
        {fmtNet(exam.totalNet)} Net
      </span>
      <button onClick={onEdit} className="text-xl" style={{ color: '#3B82F6' }} title="Düzenle">✏️</button>
      <button onClick={onDelete} className="text-xl" style={{ color: '#EF4444' }} title="Sil">🗑️</button>
    </div>
  )
}

// ─── BRANS bölümü — ders adına göre gruplanmış denemeler için ────────────────
// Her ders kendi NetSummary + TrendChart + CoachCard + karşılaştırma + geçmiş
// listesine sahip olur. Mobildeki _BransLessonSection'la birebir aynı davranır.

function BransLessonSection({ lessonName, exams, onEdit, onDelete, onCompare }: {
  lessonName: string
  exams: ExamRecord[]
  onEdit: (e: ExamRecord) => void
  onDelete: (id: number) => void
  onCompare: () => void
}) {
  const sorted = sortByDate(exams)
  return (
    <div>
      {/* Bölüm başlığı */}
      <div className="flex items-center gap-3 mb-4">
        <span className="inline-block w-1 h-6 rounded-sm" style={{ background: 'var(--primary)' }} />
        <h2 className="text-xl font-extrabold flex-1" style={{ color: 'var(--text-primary)' }}>
          Branş — {lessonName}
        </h2>
        <span className="text-sm" style={{ color: 'var(--text-hint)' }}>
          {exams.length} deneme
        </span>
      </div>

      <div className="space-y-6">
        <NetSummary exams={exams} typeName={lessonName} />

        {sorted.length >= 2 ? (
          <TrendChart exams={sorted} />
        ) : (
          <div className="rounded-2xl p-5 flex items-center gap-3" style={{ background: 'var(--card)', border: '1px solid var(--border)' }}>
            <span className="text-xl">ℹ️</span>
            <span className="text-base" style={{ color: 'var(--text-secondary)' }}>
              Net Trend grafiği için en az 2 deneme gerekli.
            </span>
          </div>
        )}

        {sorted.length >= 3 && <CoachCard exams={sorted} />}

        {sorted.length >= 2 && (
          <div className="flex justify-center">
            <button
              onClick={onCompare}
              className="w-1/2 py-4 rounded-xl text-lg font-bold text-white transition-all hover:opacity-90"
              style={{ background: 'linear-gradient(135deg, #F59E0B, #F97316)' }}
            >
              ⇄ Deneme Karşılaştırması Yap
            </button>
          </div>
        )}

        <section>
          <h3 className="text-lg font-extrabold mb-2" style={{ color: 'var(--text-primary)' }}>Geçmiş Denemeler</h3>
          <div className="space-y-3">
            {sorted.slice().reverse().map((e) => (
              <ExamCard
                key={e.id}
                exam={e}
                onEdit={() => onEdit(e)}
                onDelete={() => onDelete(e.id)}
              />
            ))}
          </div>
        </section>
      </div>
    </div>
  )
}

// ─── Ana sayfa ─────────────────────────────────────────────────────────────────

export default function DenemelorPage() {
  const { profile } = useUserProfile()
  const [allExams, setAllExams] = useState<ExamRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [filterType, setFilterType] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editExam, setEditExam] = useState<ExamRecord | null>(null)
  const [showCompare, setShowCompare] = useState(false)
  // Karşılaştırma için gönderilecek deneme alt-kümesi (BRANS gruplarında ders bazlı).
  const [compareExams, setCompareExams] = useState<ExamRecord[]>([])
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const localData = useMemo(() => {
    const uid = getUserId()
    return uid ? getOnboardingData(uid) : null
  }, [])

  const types = useMemo(() => {
    const targetExam = profile?.targetExam || localData?.targetExam || ''
    const selectedArea = profile?.selectedArea || localData?.selectedArea || ''
    // OkulSinavi: kullanıcının seçtiği derslerden dinamik tür (mobil ile birebir).
    if (targetExam === 'OkulSinavi') {
      const base = selectedArea === 'uni_diger'
        ? []
        : getSubjectsForExam(targetExam, selectedArea)
      const baseNames = new Set(base.map((s) => s.name))
      const extras = (localData?.customSubjects ?? []).filter((n) => !baseNames.has(n))
      const allSubjects = [...base.map((s) => s.name), ...extras]
      return [buildOkulSinaviType(allSubjects)]
    }
    return availableExamTypes(targetExam, selectedArea)
  }, [profile, localData])

  const branchLessons = useMemo(() => bransBranchLessons(types), [types])

  function load() {
    setLoading(true)
    denemeService.getAll().then(setAllExams).catch(() => {}).finally(() => setLoading(false))
  }
  useEffect(() => { load() }, [])

  // Sınavın izin verdiği türlere göre filtrele — başka sınava ait eski
  // denemeler bu sınav seçiliyken gösterilmez.
  const allowedApiTypes = useMemo(() => new Set(types.map((t) => t.apiType)), [types])
  const allowedExams = useMemo(
    () => allExams.filter((e) => allowedApiTypes.has(e.type)),
    [allExams, allowedApiTypes],
  )

  // Mevcut deneme türleri. OKUL_SINAVI denemeleri ders bazında ayrı tür gibi
  // gösterilir (filter id "OKUL_SINAVI:<lessonName>") — kullanıcı CERRAHİ,
  // PATOLOJİ vb. ayrı sekmeler görür.
  const presentTypes = useMemo(() => {
    const set = new Set<string>()
    for (const e of allowedExams) {
      if (!e.type) continue
      if (e.type === 'OKUL_SINAVI') {
        const lesson = e.details[0]?.lessonName ?? 'Diğer'
        set.add(`OKUL_SINAVI:${lesson}`)
      } else {
        set.add(e.type)
      }
    }
    return [...set].sort()
  }, [allowedExams])

  const effectiveFilter = filterType ?? presentTypes[0] ?? null
  function matchesFilter(e: ExamRecord): boolean {
    if (!effectiveFilter) return false
    if (effectiveFilter.startsWith('OKUL_SINAVI:')) {
      if (e.type !== 'OKUL_SINAVI') return false
      const wanted = effectiveFilter.substring('OKUL_SINAVI:'.length)
      return (e.details[0]?.lessonName ?? '') === wanted
    }
    return e.type === effectiveFilter
  }
  const filtered = effectiveFilter ? allowedExams.filter(matchesFilter) : []
  const isBrans = effectiveFilter === 'BRANS'
  const isOkulSinavi = effectiveFilter?.startsWith('OKUL_SINAVI:') ?? false
  // OKUL_SINAVI:<lesson> için tek-dersli sentetik tür (radar/lesson info için).
  let selectedTypeInfo: ExamTypeInfo | null = null
  if (isOkulSinavi && effectiveFilter) {
    const lessonName = effectiveFilter.substring('OKUL_SINAVI:'.length)
    const okulType = types.find((t) => t.apiType === 'OKUL_SINAVI')
    const slot = okulType?.lessons.find((l) => l.name === lessonName)
    if (slot) {
      selectedTypeInfo = {
        displayName: lessonName,
        apiType: 'OKUL_SINAVI',
        lessons: [slot],
      }
    }
  } else if (!isBrans && effectiveFilter) {
    selectedTypeInfo = types.find((t) => t.apiType === effectiveFilter) ?? null
  }

  // Filter chip etiketi: OKUL_SINAVI:<lesson> → <LESSON>, diğer → displayName.
  function filterLabel(t: string): string {
    if (t.startsWith('OKUL_SINAVI:')) {
      return t.substring('OKUL_SINAVI:'.length).toLocaleUpperCase('tr-TR')
    }
    return examTypeDisplayName(t)
  }

  async function handleDelete(id: number) {
    try {
      await denemeService.delete(id)
      setAllExams((prev) => prev.filter((e) => e.id !== id))
    } catch {}
    setDeleteId(null)
  }

  return (
    <>
      <div className="min-h-full pb-24">
        {/* Header */}
        <div
          className="px-8 sm:px-10 pt-10 pb-16 flex items-center justify-between gap-6"
          style={{ background: 'linear-gradient(135deg, #C0392B, #E74C3C)', minHeight: '232px' }}
        >
          <div>
            <h1 className="text-4xl sm:text-5xl font-extrabold text-white">📝 Denemelerim</h1>
            <p className="text-white/80 text-lg mt-2">
              Deneme sınavlarını takip et, trendini gör, gelişimini ölç.
            </p>
          </div>
          <button
            onClick={() => { setEditExam(null); setShowForm(true) }}
            className="shrink-0 flex items-center gap-2 px-7 h-14 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
            style={{ background: 'rgba(0,0,0,0.55)' }}
          >
            <span className="text-2xl">+</span> Deneme Sonucu Ekle
          </button>
        </div>

        <div className="px-8 sm:px-10 pt-8 space-y-8 sm:space-y-12">
          {loading ? (
            <div className="h-40 rounded-2xl animate-pulse" style={{ background: 'var(--bg)' }} />
          ) : allowedExams.length === 0 ? (
            <div className="text-center py-20 rounded-2xl" style={{ background: 'var(--card)', border: '1px solid var(--border)' }}>
              <p className="text-6xl mb-4">📝</p>
              <p className="text-xl font-bold" style={{ color: 'var(--text-primary)' }}>Henüz deneme eklenmedi</p>
              <p className="text-base mt-1" style={{ color: 'var(--text-hint)' }}>
                "Deneme Sonucu Ekle" butonuna tıklayarak ilk denemeni gir.
              </p>
            </div>
          ) : (
            <>
              {/* Tür filtreleri */}
              <div className="flex gap-2 overflow-x-auto pb-1">
                {presentTypes.map((t) => (
                  <button
                    key={t}
                    onClick={() => setFilterType(t)}
                    className="shrink-0 px-5 py-2.5 rounded-full text-base font-bold transition-all"
                    style={{
                      background: effectiveFilter === t ? 'var(--primary)' : 'var(--card)',
                      color: effectiveFilter === t ? '#fff' : 'var(--text-secondary)',
                      border: `1.5px solid ${effectiveFilter === t ? 'var(--primary)' : 'var(--border)'}`,
                    }}
                  >
                    {filterLabel(t)}
                  </button>
                ))}
              </div>

              {/* BRANS: ders adına göre gruplanmış bölümler — her ders ayrı net özeti,
                  trend, koç analizi, karşılaştırma ve geçmiş listesi alır. */}
              {isBrans ? (
                (() => {
                  // Ders adına göre grupla (ilk detail.lessonName)
                  const groups = new Map<string, ExamRecord[]>()
                  for (const e of filtered) {
                    const lessonName = e.details?.[0]?.lessonName ?? 'Diğer'
                    if (!groups.has(lessonName)) groups.set(lessonName, [])
                    groups.get(lessonName)!.push(e)
                  }
                  const groupArr = [...groups.entries()]
                  return (
                    <div className="space-y-10">
                      {groupArr.map(([lessonName, groupExams]) => (
                        <BransLessonSection
                          key={lessonName}
                          lessonName={lessonName}
                          exams={groupExams}
                          onEdit={(e) => { setEditExam(e); setShowForm(true) }}
                          onDelete={(id) => setDeleteId(id)}
                          onCompare={() => { setCompareExams(groupExams); setShowCompare(true) }}
                        />
                      ))}
                    </div>
                  )
                })()
              ) : (
                <>
                  {filtered.length > 0 && (
                    <NetSummary exams={filtered} typeName={filterLabel(effectiveFilter ?? '')} />
                  )}

                  {filtered.length >= 2 ? (
                    <TrendChart exams={filtered} />
                  ) : (
                    <div className="rounded-2xl p-5 flex items-center gap-3" style={{ background: 'var(--card)', border: '1px solid var(--border)' }}>
                      <span className="text-xl">ℹ️</span>
                      <span className="text-base" style={{ color: 'var(--text-secondary)' }}>
                        Net Trend grafiği için en az 2 deneme gerekli.
                      </span>
                    </div>
                  )}

                  {filtered.length > 0 && selectedTypeInfo && selectedTypeInfo.lessons.length >= 3 && (
                    <RadarCard exams={filtered} typeInfo={selectedTypeInfo} />
                  )}

                  {filtered.length >= 3 && <CoachCard exams={filtered} />}

                  {filtered.length >= 2 && (
                    <div className="flex justify-center">
                      <button
                        onClick={() => { setCompareExams(filtered); setShowCompare(true) }}
                        className="w-1/2 py-4 rounded-xl text-lg font-bold text-white transition-all hover:opacity-90"
                        style={{ background: 'linear-gradient(135deg, #F59E0B, #F97316)' }}
                      >
                        ⇄ Deneme Karşılaştırması Yap
                      </button>
                    </div>
                  )}

                  {/* Geçmiş denemeler */}
                  <section>
                    <h2 className="text-2xl font-extrabold mb-3" style={{ color: 'var(--text-primary)' }}>Geçmiş Denemeler</h2>
                    <div className="space-y-3">
                      {sortByDate(filtered).reverse().map((e) => (
                        <ExamCard
                          key={e.id}
                          exam={e}
                          onEdit={() => { setEditExam(e); setShowForm(true) }}
                          onDelete={() => setDeleteId(e.id)}
                        />
                      ))}
                    </div>
                  </section>
                </>
              )}
            </>
          )}
        </div>
      </div>

      {showForm && (
        <ExamFormModal
          existing={editExam}
          availableTypes={types}
          branchLessons={branchLessons}
          onClose={() => { setShowForm(false); setEditExam(null) }}
          onSaved={load}
        />
      )}
      {showCompare && (
        <ComparisonModal
          exams={compareExams.length > 0 ? compareExams : filtered}
          typeInfo={selectedTypeInfo}
          onClose={() => { setShowCompare(false); setCompareExams([]) }}
        />
      )}
      {deleteId !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.6)' }}>
          <div className="w-full max-w-md rounded-3xl p-7" style={{ background: 'var(--card)' }}>
            <h4 className="text-xl font-extrabold mb-2" style={{ color: 'var(--text-primary)' }}>Denemeyi Sil</h4>
            <p className="text-base mb-6" style={{ color: 'var(--text-secondary)' }}>
              Bu deneme sonucunu silmek istediğine emin misin?
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setDeleteId(null)}
                className="flex-1 py-3.5 rounded-xl text-base font-semibold"
                style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}
              >
                İptal
              </button>
              <button
                onClick={() => handleDelete(deleteId)}
                className="flex-1 py-3.5 rounded-xl text-base font-bold text-white"
                style={{ background: '#EF4444' }}
              >
                Sil
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}

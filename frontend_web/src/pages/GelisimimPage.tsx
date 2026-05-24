import { useEffect, useMemo, useState } from 'react'
import {
  gelisimimService,
  applyXpBoost,
  xpProgressFraction,
  type GelisimimStats,
  type XpInfo,
  type LessonDistribution,
  type DailyReport,
} from '../services/gelisimimService'
import { getStudyPlan } from '../services/studyPlanLocal'
import {
  getCompletedTaskIds, getManualTasks, getRestDays, getTopicAssignments,
  getAllCompletedTaskDays, getCompletedTaskIdsForDate,
  getAllCompletedLessons, getCompletedLessons, type CompletedLessonRecord,
} from '../services/localData'
import { getSubjectsForExam } from '../data/subjectsData'
import { getOnboardingData } from '../services/userPrefsService'
import { getUserId } from '../services/tokenService'

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

function ymd(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function fmtMin(m: number): string {
  if (m < 60) return `${m}dk`
  const h = Math.floor(m / 60)
  const rem = m % 60
  return rem > 0 ? `${h}s ${rem}dk` : `${h}s`
}

function taskTypeLabel(type: string): string {
  const map: Record<string, string> = {
    konu_anlatimi: 'Konu Anlatımı',
    soru_cozumu: 'Soru Çözümü',
    deneme: 'Deneme Sınavı',
    tekrar: 'Tekrar',
  }
  return map[type] ?? type
}

// mobildeki _subjectKey ile aynı
function subjectKey(name: string): string {
  return name.toLowerCase().replace(/ /g, '_').replace(/\//g, '_').replace(/-/g, '_').replace(/\./g, '')
}

interface CompletedLesson {
  id: string
  subjectName: string
  emoji: string
  taskType: string
  durationMinutes: number
  topicName?: string
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
        className="w-full max-w-lg rounded-3xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col"
        style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
      >
        <div className="px-7 py-6" style={{ background: 'linear-gradient(135deg, #059669, #10B981)' }}>
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

// ─── Soru Gelişimi modalı ─────────────────────────────────────────────────────

function SoruGelisimiModal({ subjects, onClose, onSaved }: {
  subjects: { key: string; name: string; emoji: string }[]
  onClose: () => void
  onSaved: () => void
}) {
  const [counts, setCounts] = useState<Record<string, number>>({})
  const [editing, setEditing] = useState<string | null>(null)
  const [editValue, setEditValue] = useState('')
  const [saving, setSaving] = useState(false)

  // Açılışta bugün girilmiş soru sayılarını yükle — bir derse daha önce
  // sayı girildiyse "Düzelt" görünür, tekrar sıfırdan girilemez.
  useEffect(() => {
    gelisimimService
      .getTodayQuestionCounts()
      .then((map) => setCounts(map))
      .catch(() => {})
  }, [])

  async function save() {
    const entries = subjects
      .filter((s) => (counts[s.name] ?? 0) > 0)
      .map((s) => ({ subjectKey: s.key, subjectName: s.name, count: counts[s.name] }))
    if (entries.length === 0) return
    setSaving(true)
    try {
      await gelisimimService.saveQuestions(entries)
      onSaved()
      onClose()
    } catch {
      setSaving(false)
    }
  }

  return (
    <ModalShell title="✏️ Soru Gelişimi" subtitle="Bugün kaç soru çözdün?" onClose={onClose}>
      <div className="space-y-2">
        {subjects.map((s) => {
          // counts ders ADI ile indekslenir — mobil/web key uyuşmazlığını aşmak için
          const c = counts[s.name] ?? 0
          const isEditing = editing === s.key
          return (
            <div
              key={s.key}
              className="flex items-center gap-3 p-3 rounded-xl"
              style={{ border: '1.5px solid var(--border)' }}
            >
              <div className="w-11 h-11 rounded-xl flex items-center justify-center text-xl" style={{ background: '#F5F3FF' }}>
                {s.emoji}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-base font-semibold truncate" style={{ color: 'var(--text-primary)' }}>{s.name}</p>
                {c > 0 && <p className="text-base" style={{ color: 'var(--primary)' }}>{c} soru</p>}
              </div>
              {isEditing ? (
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    value={editValue}
                    onChange={(e) => setEditValue(e.target.value)}
                    placeholder="0"
                    className="w-20 h-10 px-2 rounded-lg text-base text-center outline-none"
                    style={{ background: 'var(--bg)', border: '2px solid var(--primary)', color: 'var(--text-primary)' }}
                    autoFocus
                  />
                  <button
                    onClick={() => {
                      setCounts((p) => ({ ...p, [s.name]: parseInt(editValue) || 0 }))
                      setEditing(null)
                    }}
                    className="px-3 h-10 rounded-lg text-base font-bold text-white"
                    style={{ background: '#4F46E5' }}
                  >
                    ✓
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => { setEditing(s.key); setEditValue(c > 0 ? String(c) : '') }}
                  className="px-4 py-2 rounded-lg text-base font-bold"
                  style={{
                    background: c > 0 ? '#EEF2FF' : '#4F46E5',
                    color: c > 0 ? '#4F46E5' : '#fff',
                  }}
                >
                  {c > 0 ? 'Düzelt' : 'Gir'}
                </button>
              )}
            </div>
          )
        })}
      </div>
      <button
        onClick={save}
        disabled={saving || Object.values(counts).every((c) => !c)}
        className="w-full mt-5 py-3.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90 disabled:opacity-50"
        style={{ background: '#4F46E5' }}
      >
        {saving ? 'Kaydediliyor...' : 'Kaydet'}
      </button>
    </ModalShell>
  )
}

// ─── Geçmişi Gör takvim modalı ────────────────────────────────────────────────

const WEEKDAYS = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
const MONTHS = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık']

function GecmisiGorModal({ completedLessons, onClose }: {
  completedLessons: CompletedLesson[]
  onClose: () => void
}) {
  const today = new Date()
  const [viewYear, setViewYear] = useState(today.getFullYear())
  const [viewMonth, setViewMonth] = useState(today.getMonth())
  const [activeDays, setActiveDays] = useState<Set<string>>(new Set())
  const [selectedDay, setSelectedDay] = useState<string | null>(null)
  const [report, setReport] = useState<DailyReport | null>(null)
  const [reportLoading, setReportLoading] = useState(false)

  const plan = useMemo(() => getStudyPlan(), [])

  useEffect(() => {
    gelisimimService
      .getCalendarActiveDays(viewYear, viewMonth + 1)
      .then((days) => setActiveDays(new Set(days)))
      .catch(() => setActiveDays(new Set()))
  }, [viewYear, viewMonth])

  function selectDay(dateStr: string) {
    setSelectedDay(dateStr)
    setReportLoading(true)
    gelisimimService
      .getDailyReport(dateStr)
      .then(setReport)
      .catch(() => setReport(null))
      .finally(() => setReportLoading(false))
  }

  // Takvim grid'i
  const firstDay = new Date(viewYear, viewMonth, 1)
  const startOffset = (firstDay.getDay() + 6) % 7 // Pzt=0
  const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
  const cells: (number | null)[] = [
    ...Array(startOffset).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
  ]

  const todayStr = ymd(today)
  const planByDate = new Map(plan.map((d) => [d.date.slice(0, 10), d]))

  return (
    <ModalShell title="📅 Geçmişi Gör" subtitle="Bir güne tıkla, detayını gör" onClose={onClose}>
      {/* Ay gezinme */}
      <div className="flex items-center justify-between mb-4">
        <button
          onClick={() => {
            const m = viewMonth - 1
            if (m < 0) { setViewMonth(11); setViewYear((y) => y - 1) } else setViewMonth(m)
          }}
          className="w-10 h-10 rounded-xl flex items-center justify-center text-xl"
          style={{ background: 'var(--bg)', color: 'var(--text-primary)' }}
        >
          ‹
        </button>
        <span className="text-lg font-extrabold" style={{ color: 'var(--text-primary)' }}>
          {MONTHS[viewMonth]} {viewYear}
        </span>
        <button
          onClick={() => {
            const m = viewMonth + 1
            if (m > 11) { setViewMonth(0); setViewYear((y) => y + 1) } else setViewMonth(m)
          }}
          className="w-10 h-10 rounded-xl flex items-center justify-center text-xl"
          style={{ background: 'var(--bg)', color: 'var(--text-primary)' }}
        >
          ›
        </button>
      </div>

      {/* Hafta günleri */}
      <div className="grid grid-cols-7 gap-1 mb-1">
        {WEEKDAYS.map((w) => (
          <div key={w} className="text-center text-base font-bold py-1" style={{ color: 'var(--text-hint)' }}>{w}</div>
        ))}
      </div>

      {/* Günler */}
      <div className="grid grid-cols-7 gap-1">
        {cells.map((day, i) => {
          if (day === null) return <div key={`e${i}`} />
          const dateStr = `${viewYear}-${String(viewMonth + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
          const isActive = activeDays.has(dateStr)
          const isToday = dateStr === todayStr
          const isSelected = dateStr === selectedDay
          return (
            <button
              key={day}
              onClick={() => selectDay(dateStr)}
              className="aspect-square rounded-lg flex items-center justify-center text-base font-bold transition-all"
              style={{
                background: isSelected ? '#10B981' : isActive ? '#D1FAE5' : 'var(--bg)',
                color: isSelected ? '#fff' : isActive ? '#059669' : 'var(--text-primary)',
                border: isToday ? '2px solid #10B981' : '1px solid var(--border)',
              }}
            >
              {day}
            </button>
          )
        })}
      </div>

      {/* Seçili gün detayı */}
      {selectedDay && (
        <div className="mt-6">
          <p className="text-base font-extrabold mb-3" style={{ color: 'var(--text-primary)' }}>
            {new Date(selectedDay).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
          </p>
          {reportLoading ? (
            <div className="h-20 rounded-xl animate-pulse" style={{ background: 'var(--bg)' }} />
          ) : (() => {
            const planDay = planByDate.get(selectedDay)
            const isFuture = selectedDay > todayStr
            const isToday = selectedDay === todayStr
            const inPlan = !!planDay

            // Bugün ya da geçmiş gün için: kullanıcı dinlenme işaretlediyse
            // ya da plan'da o gün isOffDay ise "Dinlenme günü" göster.
            const restDaysLocal = getRestDays()
            const isRestDay =
              (planDay?.isOffDay ?? false) || restDaysLocal.includes(selectedDay)
            if (!isFuture && isRestDay) {
              return (
                <p
                  className="text-base px-4 py-6 rounded-xl text-center"
                  style={{ background: '#F0FDF4', color: '#059669' }}
                >
                  😴 Dinlenme günü
                </p>
              )
            }

            // Gelecek günler → planı göster
            if (isFuture) {
              if (!inPlan) {
                return (
                  <p className="text-base px-4 py-6 rounded-xl text-center" style={{ background: 'var(--bg)', color: 'var(--text-hint)' }}>
                    📭 Bu gün programa dahil değil.
                  </p>
                )
              }
              const blocks = planDay!.blocks.filter((b) => !b.isMola)
              return (
                <div className="space-y-2">
                  <p className="text-base font-bold" style={{ color: 'var(--primary)' }}>📋 Planlanan Program</p>
                  {planDay!.isOffDay ? (
                    <p className="text-base px-4 py-3 rounded-xl" style={{ background: '#F0FDF4', color: '#059669' }}>😴 Dinlenme günü</p>
                  ) : blocks.length === 0 ? (
                    <p className="text-base" style={{ color: 'var(--text-hint)' }}>Plan yok</p>
                  ) : (
                    blocks.map((b) => (
                      <div key={b.id} className="flex items-center gap-3 px-4 py-2.5 rounded-xl" style={{ background: 'var(--bg)' }}>
                        <span className="text-lg">{b.emoji}</span>
                        <span className="flex-1 text-base font-semibold" style={{ color: 'var(--text-primary)' }}>{b.subjectName}</span>
                        <span className="text-base" style={{ color: 'var(--text-hint)' }}>{b.startTime}</span>
                      </div>
                    ))
                  )}
                </div>
              )
            }

            // Tamamlanan dersler: bugün → completedLessons, geçmiş → kayıtlı detay
            const doneLessons = isToday
              ? completedLessons.map((l) => ({
                  id: l.id, subjectName: l.subjectName, emoji: l.emoji,
                  taskType: l.taskType, durationMinutes: l.durationMinutes, topicName: l.topicName,
                }))
              : getCompletedLessons(selectedDay)
            const doneIds = new Set(doneLessons.map((l) => l.id))
            const localMin = doneLessons.reduce((s, t) => s + t.durationMinutes, 0)

            // Detay kaydı olmayan eski tamamlanmış id'ler (ders adı bilinmiyor)
            const allDoneIds = getCompletedTaskIdsForDate(selectedDay)
            const orphanIds = [...allDoneIds].filter(
              (id) => !id.startsWith('m_') && !doneIds.has(id),
            )
            const orphanMin = orphanIds.reduce((s, id) => s + (id.startsWith('s_') ? 30 : 60), 0)

            // O günün planındaki tamamlanmamış görevler (plan penceresindeyse)
            const dayBlocks = (planDay?.blocks ?? []).filter((b) => !b.isMola)
            const missedTasks = dayBlocks.filter((b) => !allDoneIds.has(b.id))

            const completedCount = (report?.tasks.completed ?? 0) + doneLessons.length + orphanIds.length
            const totalMin = (report?.tasks.totalMinutes ?? 0) + localMin + orphanMin
            const questions = report?.questions ?? []

            const hasAnything = completedCount > 0 || totalMin > 0 || questions.length > 0 || missedTasks.length > 0
            if (!hasAnything) {
              return (
                <p className="text-base px-4 py-6 rounded-xl text-center" style={{ background: 'var(--bg)', color: 'var(--text-hint)' }}>
                  {inPlan ? 'Bu gün için henüz kayıt yok.' : '📭 Bu gün programa dahil değil.'}
                </p>
              )
            }
            return (
              <div className="space-y-3">
                <div className="flex gap-3">
                  <div className="flex-1 px-4 py-3 rounded-xl text-center" style={{ background: '#EEF2FF' }}>
                    <p className="text-2xl font-extrabold" style={{ color: '#4F46E5' }}>{completedCount}</p>
                    <p className="text-base" style={{ color: 'var(--text-secondary)' }}>Tamamlanan</p>
                  </div>
                  <div className="flex-1 px-4 py-3 rounded-xl text-center" style={{ background: '#FFF7ED' }}>
                    <p className="text-2xl font-extrabold" style={{ color: '#F97316' }}>{fmtMin(totalMin)}</p>
                    <p className="text-base" style={{ color: 'var(--text-secondary)' }}>Toplam Süre</p>
                  </div>
                </div>
                {/* Tamamlanan dersler */}
                {doneLessons.length > 0 && (
                  <div>
                    <p className="text-base font-bold mb-2" style={{ color: 'var(--text-primary)' }}>✅ Tamamlanan Dersler</p>
                    <div className="space-y-1.5">
                      {doneLessons.map((t) => (
                        <div key={t.id} className="flex items-center gap-3 px-4 py-2.5 rounded-xl" style={{ background: 'var(--bg)' }}>
                          <span className="text-lg">{t.emoji}</span>
                          <span className="flex-1 text-base font-semibold" style={{ color: 'var(--text-primary)' }}>
                            {t.subjectName}{t.topicName ? ` — ${t.topicName}` : ''}
                          </span>
                          <span className="text-base" style={{ color: 'var(--text-hint)' }}>{t.durationMinutes} dk</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
                {/* Detayı bilinmeyen eski tamamlananlar */}
                {orphanIds.length > 0 && (
                  <p className="text-sm px-4 py-2 rounded-xl" style={{ background: 'var(--bg)', color: 'var(--text-hint)' }}>
                    + {orphanIds.length} tamamlanmış görev (ders detayı kaydedilmemiş)
                  </p>
                )}
                {/* Tamamlanmamış görevler — plan o günü kapsıyorsa */}
                {missedTasks.length > 0 && (
                  <div>
                    <p className="text-base font-bold mb-2" style={{ color: '#EF4444' }}>⏳ Tamamlanmayan Oturumlar</p>
                    <div className="space-y-1.5">
                      {missedTasks.map((b) => (
                        <div key={b.id} className="flex items-center gap-3 px-4 py-2.5 rounded-xl"
                          style={{ background: 'var(--bg)', opacity: 0.7 }}>
                          <span className="text-lg">{b.emoji}</span>
                          <span className="flex-1 text-base font-semibold" style={{ color: 'var(--text-primary)' }}>
                            {b.subjectName}
                          </span>
                          <span className="text-base" style={{ color: 'var(--text-hint)' }}>{b.durationMinutes} dk</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
                {questions.length > 0 && (
                  <div>
                    <p className="text-base font-bold mb-2" style={{ color: 'var(--text-primary)' }}>Çözülen Sorular</p>
                    <div className="space-y-1.5">
                      {questions.map((q) => (
                        <div key={q.subjectName} className="flex items-center justify-between px-4 py-2.5 rounded-xl" style={{ background: 'var(--bg)' }}>
                          <span className="text-base font-semibold" style={{ color: 'var(--text-primary)' }}>{q.subjectName}</span>
                          <span className="text-base" style={{ color: 'var(--text-secondary)' }}>{q.count} soru</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )
          })()}
        </div>
      )}
    </ModalShell>
  )
}

// ─── İstatistik kartı ─────────────────────────────────────────────────────────

function StatCard({ label, value, sub, icon, color }: {
  label: string
  value: string
  sub: string
  icon: string
  color: string
}) {
  return (
    <div
      className="rounded-2xl p-5 shadow-sm"
      style={{ background: `${color}14`, border: `1.5px solid ${color}40` }}
    >
      <p className="text-base font-bold mb-2" style={{ color }}>{label}</p>
      <div className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl mb-2" style={{ background: `${color}26` }}>
        {icon}
      </div>
      <p className="text-2xl font-extrabold" style={{ color: 'var(--text-primary)' }}>{value}</p>
      <p className="text-base" style={{ color: 'var(--text-hint)' }}>{sub}</p>
    </div>
  )
}

// ─── Ana sayfa ─────────────────────────────────────────────────────────────────

export default function GelisimimPage() {
  const [filter, setFilter] = useState<'all' | 'today'>('today')
  const [stats, setStats] = useState<GelisimimStats | null>(null)
  const [xp, setXp] = useState<XpInfo | null>(null)
  const [dist, setDist] = useState<LessonDistribution[]>([])
  // Tüm Zamanlar için: günlük soru dağılımı [{ date, questions }]
  const [questionsByDay, setQuestionsByDay] = useState<{ date: string; questions: DailyReport['questions'] }[]>([])
  const [loading, setLoading] = useState(true)
  const [showSoru, setShowSoru] = useState(false)
  const [showGecmis, setShowGecmis] = useState(false)

  // Lokal veriler
  const completedIds = useMemo(() => getCompletedTaskIds(), [])
  const restDays = useMemo(() => getRestDays(), [])
  const topicAssignments = useMemo(() => getTopicAssignments(), [])
  const plan = useMemo(() => getStudyPlan(), [])
  const manualTasks = useMemo(() => getManualTasks(), [])

  const localData = useMemo(() => {
    const uid = getUserId()
    return uid ? getOnboardingData(uid) : null
  }, [])

  function load() {
    setLoading(true)
    Promise.all([
      gelisimimService.getStats(filter).then(setStats).catch(() => {}),
      gelisimimService.getXpInfo().then(setXp).catch(() => {}),
      gelisimimService.getLessonDistribution(filter).then(setDist).catch(() => {}),
    ]).finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [filter])

  // Tüm Zamanlar: aktif günlerin günlük soru dağılımını çek
  useEffect(() => {
    if (filter !== 'all') { setQuestionsByDay([]); return }
    let cancelled = false
    ;(async () => {
      const now = new Date()
      // Son 2 ay (bu ay + önceki) aktif günleri topla
      const dates = new Set<string>()
      for (let m = 0; m < 2; m++) {
        const d = new Date(now.getFullYear(), now.getMonth() - m, 1)
        try {
          const days = await gelisimimService.getCalendarActiveDays(d.getFullYear(), d.getMonth() + 1)
          days.forEach((x) => dates.add(x))
        } catch (e) {
          console.warn('[Gelisimim] takvim ayı atlandı', d.getFullYear(), d.getMonth() + 1, e)
        }
      }
      const reports = await Promise.all(
        [...dates].map(async (date) => {
          try {
            const r = await gelisimimService.getDailyReport(date)
            return { date, questions: r.questions }
          } catch (e) {
            console.warn('[Gelisimim] günlük rapor alınamadı', date, e)
            return { date, questions: [] as DailyReport['questions'] }
          }
        }),
      )
      if (cancelled) return
      const withQuestions = reports.filter((r) => r.questions.length > 0)
      console.info('[Gelisimim] soru çözümleri günleri:', withQuestions.map((r) => r.date))
      setQuestionsByDay(
        withQuestions.sort((a, b) => b.date.localeCompare(a.date)),
      )
    })()
    return () => { cancelled = true }
  }, [filter])

  // Bugün tamamlanan dersler (plan blokları + manuel görevler)
  const today = new Date()
  const todayStr = ymd(today)
  const todayPlan = plan.find((d) => d.date.startsWith(todayStr)) ?? plan[0]
  const completedLessons: CompletedLesson[] = useMemo(() => {
    const fromPlan: CompletedLesson[] = (todayPlan?.blocks ?? [])
      .filter((b) => !b.isMola && completedIds.has(b.id))
      .map((b) => ({
        id: b.id, subjectName: b.subjectName, emoji: b.emoji,
        taskType: b.taskType, durationMinutes: b.durationMinutes,
        topicName: topicAssignments[b.id],
      }))
    const fromManual: CompletedLesson[] = manualTasks
      .filter((t) => t.date === todayStr && completedIds.has(t.id))
      .map((t) => ({
        id: t.id, subjectName: t.subjectName, emoji: '📝',
        taskType: t.taskType, durationMinutes: t.durationMinutes,
        topicName: t.topicName,
      }))
    return [...fromPlan, ...fromManual]
  }, [todayPlan, manualTasks, completedIds, topicAssignments, todayStr])

  // Tüm zamanlar: tamamlanan dersler güne göre gruplu (en yeni gün üstte)
  const lessonsByDay = useMemo(() => {
    const detailed = getAllCompletedLessons()
    // Bugünü her zaman güncel completedLessons'tan al (detay kaydı eksik olabilir)
    detailed[todayStr] = completedLessons.map((l) => ({
      id: l.id, subjectName: l.subjectName, emoji: l.emoji,
      taskType: l.taskType, durationMinutes: l.durationMinutes, topicName: l.topicName,
    }))

    // Detay kaydı olmayan eski günler için id'lerden placeholder kayıt üret
    const allIdDays = getAllCompletedTaskDays()
    const merged: Record<string, CompletedLessonRecord[]> = { ...detailed }
    for (const [date, ids] of Object.entries(allIdDays)) {
      const known = new Set((detailed[date] ?? []).map((l) => l.id))
      const orphans = [...ids].filter((id) => !id.startsWith('m_') && !known.has(id))
      if (orphans.length === 0) continue
      const placeholders: CompletedLessonRecord[] = orphans.map((id) => ({
        id,
        subjectName: 'Tamamlanan Görev',
        emoji: '✅',
        taskType: id.startsWith('s_') ? 'soru_cozumu' : 'konu_anlatimi',
        durationMinutes: id.startsWith('s_') ? 30 : 60,
      }))
      merged[date] = [...(detailed[date] ?? []), ...placeholders]
    }

    return Object.entries(merged)
      .filter(([, list]) => list.length > 0)
      .sort((a, b) => b[0].localeCompare(a[0])) // tarih azalan
  }, [completedLessons, todayStr])

  // Lokal bugün istatistikleri (mobildeki localTodayStatsProvider)
  const localCompleted = completedLessons.length
  const localMinutes = completedLessons.reduce((s, t) => s + t.durationMinutes, 0)
  const localXpBoost = localCompleted * 10

  // Tüm zamanlar: geçmiş günlerdeki tamamlanan görevleri tara (mobildeki localAllTimeStats)
  const allTimeLocal = useMemo(() => {
    // Plan + manuel görev sürelerini id → dk olarak map'le
    const durations: Record<string, number> = {}
    plan.forEach((d) => d.blocks.forEach((b) => {
      if (!b.isMola) durations[b.id] = b.durationMinutes
    }))
    manualTasks.forEach((t) => { durations[t.id] = t.durationMinutes })

    const allDays = getAllCompletedTaskDays()
    let totalCompleted = 0
    let totalMinutes = 0
    for (const [date, ids] of Object.entries(allDays)) {
      if (date === todayStr) continue // bugün ayrıca eklenir
      for (const id of ids) {
        if (id.startsWith('m_') && !durations[id]) continue // mola id'si — atla
        totalCompleted += 1
        // Bilinmiyorsa: s_=güçlü ~30dk, w_=zayıf ~60dk, manuel ~60dk
        totalMinutes += durations[id] ?? (id.startsWith('s_') ? 30 : 60)
      }
    }
    return { totalCompleted, totalMinutes }
  }, [plan, manualTasks, todayStr])

  // Birleşik istatistikler — mobildeki merge mantığı
  const mergedStats: GelisimimStats = useMemo(() => {
    const base = stats ?? { completedTasks: 0, totalMinutes: 0, totalQuestions: 0, restDays: 0 }
    if (filter === 'today') {
      return {
        completedTasks: localCompleted,
        totalMinutes: localMinutes,
        totalQuestions: base.totalQuestions,
        restDays: restDays.includes(todayStr) ? 1 : 0,
      }
    }
    return {
      completedTasks: base.completedTasks + localCompleted + allTimeLocal.totalCompleted,
      totalMinutes: base.totalMinutes + localMinutes + allTimeLocal.totalMinutes,
      totalQuestions: base.totalQuestions,
      restDays: base.restDays + restDays.length,
    }
  }, [stats, filter, localCompleted, localMinutes, allTimeLocal, restDays, todayStr])

  const effectiveXp = xp ? applyXpBoost(xp, localXpBoost) : null
  const xpFraction = effectiveXp ? xpProgressFraction(effectiveXp) : 0

  // Soru gelişimi için ders havuzu
  const questionSubjects = useMemo(() => {
    const targetExam = localData?.targetExam || ''
    const selectedArea = localData?.selectedArea || ''
    const base = getSubjectsForExam(targetExam, selectedArea)
    const baseNames = new Set(base.map((s) => s.name))
    const extra = (localData?.customSubjects ?? [])
      .filter((n) => !baseNames.has(n))
      .map((n) => ({ name: n, emoji: '📝' as const }))
    return [...base, ...extra].map((s) => ({ key: subjectKey(s.name), name: s.name, emoji: s.emoji }))
  }, [localData])

  return (
    <>
      <div className="min-h-full pb-28">
        {/* ── XP Header (yeşil) ───────────────────────────────────────────── */}
        <div
          className="px-8 sm:px-10 pt-10 pb-10 relative"
          style={{ background: 'linear-gradient(135deg, #059669, #10B981)' }}
        >
          {/* Sol üst: streak (o gün çalışma varsa) */}
          {(effectiveXp?.streakDays ?? 0) > 0 && (
            <span
              className="absolute top-8 left-8 sm:left-10 px-5 py-2.5 rounded-full text-lg font-bold text-white"
              style={{ background: 'rgba(255,255,255,0.25)' }}
            >
              🔥 {effectiveXp?.streakDays} Gün
            </span>
          )}

          {/* Sağ üst: toplam XP */}
          <span
            className="absolute top-8 right-8 sm:right-10 px-5 py-2.5 rounded-full text-lg font-extrabold"
            style={{ background: '#FBBF24', color: '#1F2937' }}
          >
            {effectiveXp?.totalXP ?? 0} XP
          </span>

          {/* Ortalı içerik */}
          <div className="flex flex-col items-center text-center pt-2">
            <div
              className="w-20 h-20 rounded-full flex items-center justify-center text-4xl mb-3"
              style={{ background: 'rgba(255,255,255,0.25)' }}
            >
              {effectiveXp?.levelEmoji ?? '🌱'}
            </div>
            <h1 className="text-4xl font-extrabold text-white">{effectiveXp?.levelName ?? 'Çırak Öğrenci'}</h1>
            <p className="text-xl font-semibold mt-2" style={{ color: '#FBBF24' }}>
              🎯 Toplam {effectiveXp?.totalQuestions ?? 0} Soru Çözüldü
            </p>

            {/* XP bar */}
            <div className="w-full max-w-md mt-5">
              <div className="flex justify-between text-lg text-white/75 mb-1.5">
                <span>{effectiveXp?.currentLevelXP ?? 0} XP</span>
                <span>{effectiveXp?.nextLevelXP ?? 2000} XP</span>
              </div>
              <div className="h-3 rounded-full overflow-hidden" style={{ background: 'rgba(255,255,255,0.25)' }}>
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{ width: `${xpFraction * 100}%`, background: '#FBBF24' }}
                />
              </div>
            </div>
          </div>
        </div>

        <div className="px-8 sm:px-10 pt-8 space-y-8 sm:space-y-12">
          {/* ── Stat kartları ─────────────────────────────────────────────── */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {loading ? (
              [1, 2, 3, 4].map((i) => (
                <div key={i} className="h-36 rounded-2xl animate-pulse" style={{ background: 'var(--bg)' }} />
              ))
            ) : (
              <>
                <StatCard label="Tamamlanan" value={String(mergedStats.completedTasks)} sub="oturum" icon="✅" color="#10B981" />
                <StatCard label="Toplam Süre" value={fmtMin(mergedStats.totalMinutes)} sub="çalışma" icon="⏱️" color="#F59E0B" />
                <StatCard label="Çözülen Soru" value={String(mergedStats.totalQuestions)} sub="soru" icon="📝" color="#EF4444" />
                <StatCard label="Dinlenme" value={String(mergedStats.restDays)} sub="gün" icon="😴" color="#14B8A6" />
              </>
            )}
          </div>

          {/* ── Aksiyon butonları ─────────────────────────────────────────── */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <button
              onClick={() => setShowSoru(true)}
              className="flex items-center gap-4 p-5 rounded-2xl text-white transition-all hover:opacity-90"
              style={{ background: 'linear-gradient(135deg, #F59E0B, #F97316)' }}
            >
              <span className="text-3xl">✏️</span>
              <div className="text-left">
                <p className="text-lg font-extrabold">Soru Gelişimi</p>
                <p className="text-base text-white/80">Bugün kaç soru çözdün?</p>
              </div>
            </button>
            <button
              onClick={() => setShowGecmis(true)}
              className="flex items-center gap-4 p-5 rounded-2xl transition-all hover:opacity-90"
              style={{ background: 'var(--card)', border: '2px solid var(--primary)' }}
            >
              <span className="text-3xl">📅</span>
              <div className="text-left">
                <p className="text-lg font-extrabold" style={{ color: 'var(--primary)' }}>Geçmişi Gör</p>
                <p className="text-base" style={{ color: 'var(--text-secondary)' }}>
                  {(effectiveXp?.streakDays ?? 0) > 0 ? `${effectiveXp?.streakDays} günlük seri` : 'Takvimi incele'}
                </p>
              </div>
            </button>
          </div>

          {/* ── Filtre ────────────────────────────────────────────────────── */}
          <div className="flex gap-1 p-1.5 rounded-2xl" style={{ background: 'var(--bg)' }}>
            {([
              { v: 'today' as const, label: 'Bugün' },
              { v: 'all' as const, label: 'Tüm Zamanlar' },
            ]).map((b) => (
              <button
                key={b.v}
                onClick={() => setFilter(b.v)}
                className="flex-1 py-3 rounded-xl text-base font-bold transition-all"
                style={{
                  background: filter === b.v ? 'var(--primary)' : 'var(--card)',
                  color: filter === b.v ? '#fff' : 'var(--text-secondary)',
                  border: `2px solid ${filter === b.v ? 'var(--primary)' : 'var(--border)'}`,
                }}
              >
                {b.label}
              </button>
            ))}
          </div>

          {/* ── Ders Dağılımı: tamamlanan dersler ─────────────────────────── */}
          <section>
            <h2 className="text-2xl font-extrabold mb-3" style={{ color: 'var(--text-primary)' }}>Ders Dağılımı</h2>
            <div className="rounded-2xl p-6" style={{ background: 'var(--card)', border: '1px solid var(--border)' }}>
              {(() => {
                // Bugün filtresi → sadece bugünün dersleri; Tüm Zamanlar → günlere göre gruplu
                const days = filter === 'today'
                  ? lessonsByDay.filter(([d]) => d === todayStr)
                  : lessonsByDay
                if (days.length === 0) {
                  return (
                    <div className="text-center py-6">
                      <p className="text-5xl mb-2">✅</p>
                      <p className="text-base font-bold" style={{ color: 'var(--text-secondary)' }}>Henüz tamamlanan ders yok.</p>
                      <p className="text-base mt-1" style={{ color: 'var(--text-hint)' }}>Dersler tamamlandıkça burada görünecek!</p>
                    </div>
                  )
                }
                const lessonRow = (t: CompletedLessonRecord) => (
                  <div key={t.id} className="flex items-center gap-3">
                    <span className="text-2xl">{t.emoji}</span>
                    <div className="flex-1 min-w-0">
                      <p className="text-base font-bold" style={{ color: 'var(--text-primary)' }}>
                        {t.subjectName}
                        {t.topicName && <span className="font-normal" style={{ color: 'var(--text-secondary)' }}> — {t.topicName}</span>}
                      </p>
                      <p className="text-base" style={{ color: 'var(--text-hint)' }}>{taskTypeLabel(t.taskType)}</p>
                    </div>
                    <span className="text-base" style={{ color: 'var(--text-secondary)' }}>{t.durationMinutes} dk</span>
                    <span className="text-lg">✅</span>
                  </div>
                )
                // Tek gün (Bugün filtresi) → düz liste, başlık yok
                if (filter === 'today') {
                  return <div className="space-y-3">{days[0][1].map(lessonRow)}</div>
                }
                // Tüm Zamanlar → her gün için tarih başlığı + araya boşluk
                return (
                  <div className="space-y-6">
                    {days.map(([date, list], idx) => (
                      <div key={date}>
                        <div
                          className="flex items-center gap-2 mb-3 pb-2"
                          style={{ borderBottom: idx === 0 ? 'none' : undefined }}
                        >
                          <span
                            className="px-3 py-1 rounded-lg text-sm font-bold"
                            style={{ background: '#EEF2FF', color: 'var(--primary)' }}
                          >
                            {date === todayStr
                              ? 'Bugün'
                              : new Date(date).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', weekday: 'long' })}
                          </span>
                          <span className="text-sm" style={{ color: 'var(--text-hint)' }}>{list.length} ders</span>
                        </div>
                        <div className="space-y-3">{list.map(lessonRow)}</div>
                      </div>
                    ))}
                  </div>
                )
              })()}
            </div>
          </section>

          {/* ── Soru Çözümleri ────────────────────────────────────────────── */}
          <section>
            <h2 className="text-2xl font-extrabold mb-3" style={{ color: 'var(--text-primary)' }}>Soru Çözümleri</h2>
            <div className="rounded-2xl p-6" style={{ background: 'var(--card)', border: '1px solid var(--border)' }}>
              {(() => {
                // Çubuk satırı render'ı
                const qRow = (lesson: string, count: number, max: number) => (
                  <div key={lesson}>
                    <div className="flex justify-between mb-1.5">
                      <span className="text-base font-semibold" style={{ color: 'var(--text-primary)' }}>{lesson}</span>
                      <span className="text-base" style={{ color: 'var(--text-secondary)' }}>{count} soru</span>
                    </div>
                    <div className="h-2.5 rounded-full overflow-hidden" style={{ background: 'var(--bg)' }}>
                      <div className="h-full rounded-full" style={{ width: `${(count / max) * 100}%`, background: 'var(--primary)' }} />
                    </div>
                  </div>
                )

                // Bugün filtresi → toplam dağılım (dist)
                if (filter === 'today') {
                  if (dist.length === 0) {
                    return (
                      <div className="text-center py-6">
                        <p className="text-5xl mb-2">📊</p>
                        <p className="text-base font-bold" style={{ color: 'var(--text-secondary)' }}>Henüz çözülen soru yok.</p>
                        <p className="text-base mt-1" style={{ color: 'var(--text-hint)' }}>Soru çözdükçe burada ders dağılımın görünecek!</p>
                      </div>
                    )
                  }
                  const max = dist[0]?.totalQuestions || 1
                  return <div className="space-y-4">{dist.map((i) => qRow(i.lessonName, i.totalQuestions, max))}</div>
                }

                // Tüm Zamanlar → tarihe göre gruplu günlük soru dağılımı
                if (questionsByDay.length === 0) {
                  return (
                    <div className="text-center py-6">
                      <p className="text-5xl mb-2">📊</p>
                      <p className="text-base font-bold" style={{ color: 'var(--text-secondary)' }}>Henüz çözülen soru yok.</p>
                      <p className="text-base mt-1" style={{ color: 'var(--text-hint)' }}>Soru çözdükçe burada ders dağılımın görünecek!</p>
                    </div>
                  )
                }
                return (
                  <div className="space-y-6">
                    {questionsByDay.map(({ date, questions }) => {
                      const sorted = [...questions].sort((a, b) => b.count - a.count)
                      const max = sorted[0]?.count || 1
                      const total = sorted.reduce((s, q) => s + q.count, 0)
                      return (
                        <div key={date}>
                          <div className="flex items-center gap-2 mb-3">
                            <span className="px-3 py-1 rounded-lg text-sm font-bold" style={{ background: '#EEF2FF', color: 'var(--primary)' }}>
                              {date === todayStr
                                ? 'Bugün'
                                : new Date(date).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', weekday: 'long' })}
                            </span>
                            <span className="text-sm" style={{ color: 'var(--text-hint)' }}>{total} soru</span>
                          </div>
                          <div className="space-y-4">{sorted.map((q) => qRow(q.subjectName, q.count, max))}</div>
                        </div>
                      )
                    })}
                  </div>
                )
              })()}
            </div>
          </section>
        </div>
      </div>

      {showSoru && (
        <SoruGelisimiModal
          subjects={questionSubjects}
          onClose={() => setShowSoru(false)}
          onSaved={load}
        />
      )}
      {showGecmis && (
        <GecmisiGorModal completedLessons={completedLessons} onClose={() => setShowGecmis(false)} />
      )}
    </>
  )
}

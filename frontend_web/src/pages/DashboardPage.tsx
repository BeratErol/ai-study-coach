import { useEffect, useState, useRef } from 'react'
import api from '../services/api'
import { getUserName } from '../hooks/useAuth'
import { useUserProfile } from '../hooks/useUserProfile'
import { useStudySessionStore, type StudyTask } from '../stores/studySessionStore'
import StudySessionModal from '../components/StudySessionModal'
import { getStudyPlan } from '../services/studyPlanLocal'
import {
  getManualTasks,
  saveManualTasks,
  getQuickNotes,
  saveQuickNotes,
  getCompletedTaskIds,
  saveCompletedTaskIds,
  type ManualTask as LocalManualTask,
  type QuickNote as LocalQuickNote,
} from '../services/localData'

// ─── Types ────────────────────────────────────────────────────────────────────

interface WeeklySummary {
  totalMinutes: number
  totalSessions: number
  pomodoroCount: number
}

interface ExamData { id: number; totalNet: number; date: string }

interface PlanBlock {
  id: string
  subjectName: string
  emoji: string
  startTime: string
  endTime: string
  durationMinutes: number
  taskType: string
  isMola: boolean
  isStrong: boolean
}

interface StudyPlanDay {
  date: string
  dayName: string
  blocks: PlanBlock[]
  totalMinutes: number
}

type QuickNote = LocalQuickNote
type ManualTask = LocalManualTask

// ─── Helpers ──────────────────────────────────────────────────────────────────

function subjectEmoji(name: string): string {
  const n = name.toLowerCase()
  if (n.includes('matematik') || n.includes('geometri')) return '📐'
  if (n.includes('türkçe') || n.includes('edebiyat') || n.includes('dil')) return '📖'
  if (n.includes('fizik')) return '⚡'
  if (n.includes('kimya')) return '🧪'
  if (n.includes('biyoloji') || n.includes('fen')) return '🧬'
  if (n.includes('tarih') || n.includes('inkılap')) return '🏛️'
  if (n.includes('coğrafya')) return '🌍'
  if (n.includes('felsefe') || n.includes('mantık')) return '💭'
  if (n.includes('din')) return '🕌'
  if (n.includes('ingilizce') || n.includes('yds') || n.includes('ydt')) return '🇬🇧'
  return '📚'
}

/** Lokal generator StudyDay'lerini Dashboard'un beklediği plan şekline çevirir. */
function adaptPlan(days: import('../services/studyPlanGenerator').StudyDay[]): StudyPlanDay[] {
  return days.map((d) => ({
    date: d.date,
    dayName: d.dayName,
    totalMinutes: d.totalMinutes,
    blocks: d.blocks.map((b, i) => ({
      id: `${d.date}-${i}`,
      subjectName: b.subjectName,
      emoji: subjectEmoji(b.subjectName),
      startTime: b.startTime,
      endTime: b.endTime,
      durationMinutes: b.durationMinutes,
      taskType: b.isStrong ? 'Soru Çözümü' : 'Konu Anlatımı',
      isMola: false,
      isStrong: b.isStrong,
    })),
  }))
}

function fmtMinutes(m: number): string {
  if (m < 60) return `${m}dk`
  const h = Math.floor(m / 60)
  const rem = m % 60
  return rem ? `${h}s ${rem}dk` : `${h}s`
}

function daysUntil(dateStr: string | null | undefined): number | null {
  if (!dateStr) return null
  const d = new Date(dateStr)
  const now = new Date()
  now.setHours(0, 0, 0, 0)
  d.setHours(0, 0, 0, 0)
  const diff = Math.round((d.getTime() - now.getTime()) / 86400000)
  return diff >= 0 ? diff : null
}

function taskTypeLabel(type: string): string {
  const map: Record<string, string> = {
    konu_anlatimi: 'Konu Anlatımı',
    soru_cozumu: 'Soru Çözümü',
    tekrar: 'Tekrar',
    deneme: 'Deneme',
    Konu_Anlatımı: 'Konu Anlatımı',
    Soru_Çözümü: 'Soru Çözümü',
    Tekrar: 'Tekrar',
    Deneme: 'Deneme',
  }
  return map[type] ?? type
}

const TASK_TYPES = ['Konu Anlatımı', 'Soru Çözümü', 'Tekrar', 'Deneme'] as const
const DURATION_OPTIONS = [30, 45, 60, 90, 120] as const

// ─── AddTaskModal ─────────────────────────────────────────────────────────────

interface AddTaskModalProps {
  onClose: () => void
  onAdd: (task: ManualTask) => void
}

function AddTaskModal({ onClose, onAdd }: AddTaskModalProps) {
  const [subjectName, setSubjectName] = useState('')
  const [taskType, setTaskType] = useState<string>(TASK_TYPES[0])
  const [duration, setDuration] = useState<number>(60)
  const [saving, setSaving] = useState(false)

  function handleSave() {
    const name = subjectName.trim()
    if (!name) return
    setSaving(true)
    const d = new Date()
    const task: ManualTask = {
      id: `manual-${Date.now()}`,
      subjectName: name,
      taskType,
      durationMinutes: duration,
      date: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`,
    }
    onAdd(task)
    setSaving(false)
    onClose()
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      style={{ background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(4px)' }}
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="w-full max-w-md rounded-3xl shadow-2xl overflow-hidden"
        style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
      >
        {/* Modal header */}
        <div
          className="px-6 py-5"
          style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
        >
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-extrabold text-white">+ Manuel Görev Ekle</h3>
              <p className="text-sm text-white/70 mt-0.5">Bugünkü programa görev ekle</p>
            </div>
            <button
              onClick={onClose}
              className="w-9 h-9 rounded-full flex items-center justify-center text-white/70 hover:text-white hover:bg-white/10 transition-all"
            >
              ✕
            </button>
          </div>
        </div>

        {/* Form */}
        <div className="p-6 space-y-5">
          {/* Subject */}
          <div>
            <label className="block text-sm font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>
              📚 Ders Adı
            </label>
            <input
              value={subjectName}
              onChange={(e) => setSubjectName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSave()}
              placeholder="örn. Matematik, Fizik..."
              className="w-full px-4 py-3 rounded-xl text-sm outline-none transition-all"
              style={{
                background: 'var(--bg)',
                border: '2px solid var(--border)',
                color: 'var(--text-primary)',
              }}
              autoFocus
            />
          </div>

          {/* Task type */}
          <div>
            <label className="block text-sm font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>
              📝 Görev Türü
            </label>
            <div className="grid grid-cols-2 gap-2">
              {TASK_TYPES.map((t) => (
                <button
                  key={t}
                  onClick={() => setTaskType(t)}
                  className="py-2.5 px-3 rounded-xl text-sm font-semibold transition-all"
                  style={{
                    background: taskType === t ? 'linear-gradient(135deg, #4F46E5, #6D28D9)' : 'var(--bg)',
                    color: taskType === t ? '#fff' : 'var(--text-secondary)',
                    border: `1.5px solid ${taskType === t ? 'transparent' : 'var(--border)'}`,
                  }}
                >
                  {t}
                </button>
              ))}
            </div>
          </div>

          {/* Duration */}
          <div>
            <label className="block text-sm font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>
              ⏱️ Süre
            </label>
            <div className="flex gap-2 flex-wrap">
              {DURATION_OPTIONS.map((d) => (
                <button
                  key={d}
                  onClick={() => setDuration(d)}
                  className="px-4 py-2 rounded-xl text-sm font-semibold transition-all"
                  style={{
                    background: duration === d ? '#EEF2FF' : 'var(--bg)',
                    color: duration === d ? 'var(--primary)' : 'var(--text-secondary)',
                    border: `1.5px solid ${duration === d ? 'var(--primary)' : 'var(--border)'}`,
                  }}
                >
                  {d}dk
                </button>
              ))}
            </div>
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-2">
            <button
              onClick={onClose}
              className="flex-1 py-3 rounded-xl text-sm font-semibold transition-all"
              style={{
                background: 'var(--bg)',
                color: 'var(--text-secondary)',
                border: '1.5px solid var(--border)',
              }}
            >
              İptal
            </button>
            <button
              onClick={handleSave}
              disabled={!subjectName.trim() || saving}
              className="flex-1 py-3 rounded-xl text-sm font-bold text-white transition-all hover:opacity-90 disabled:opacity-50"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
            >
              {saving ? 'Ekleniyor...' : '✓ Kaydet'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── Main Page ─────────────────────────────────────────────────────────────────

export default function DashboardPage() {
  const userName = getUserName()
  const { profile } = useUserProfile()
  const { open: openSession } = useStudySessionStore()
  const isModalOpen = useStudySessionStore((s) => s.isOpen)

  const [weekly, setWeekly]         = useState<WeeklySummary | null>(null)
  const [lastExam, setLastExam]     = useState<ExamData | null>(null)
  const [plan, setPlan]             = useState<StudyPlanDay[]>([])
  const [notes, setNotes]           = useState<QuickNote[]>([])
  const [noteInput, setNoteInput]   = useState('')
  const [loading, setLoading]       = useState(true)
  const [completedIds, setCompletedIds] = useState<Set<string>>(new Set())
  const [streakDays, setStreakDays]  = useState(0)
  const [showAddTask, setShowAddTask] = useState(false)
  const [manualTasks, setManualTasks] = useState<ManualTask[]>([])
  const noteInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    // Lokal veriler (mobil ile aynı: plan/not/manuel görev/tamamlama localStorage'da)
    setCompletedIds(getCompletedTaskIds())
    setManualTasks(getManualTasks())
    setNotes(getQuickNotes())
    setPlan(adaptPlan(getStudyPlan()))

    // Backend verileri (gerçekten var olan endpoint'ler)
    Promise.all([
      api.get('/StudySession/weekly-summary').then((r) => setWeekly(r.data)).catch(() => {}),
      api.get('/Exam').then((r) => {
        const exams: ExamData[] = r.data
        if (exams.length > 0) {
          const sorted = [...exams].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
          setLastExam(sorted[0])
        }
      }).catch(() => {}),
      api.get('/Gelisimim/xp-info').then((r) => setStreakDays(r.data?.streakDays ?? r.data?.currentStreak ?? 0)).catch(() => {}),
    ]).finally(() => setLoading(false))
  }, [])

  const today = new Date()
  const todayStr = today.toISOString().split('T')[0]
  const todayPlan = plan.find((d) => d.date.startsWith(todayStr)) ?? plan[0] ?? null
  const todayTasks = (todayPlan?.blocks ?? []).filter((b) => !b.isMola)
  const todayManual = manualTasks.filter((t) => t.date === todayStr)
  const daysLeft = daysUntil(profile?.examDate)

  const weekDays = plan.slice(0, 7)
  const totalWeekTasks = weekDays.reduce((s, d) => s + d.blocks.filter((b) => !b.isMola).length, 0)
  const totalWeekMinutes = weekDays.reduce((s, d) => s + d.totalMinutes, 0)

  function toggleComplete(id: string) {
    setCompletedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id); else next.add(id)
      saveCompletedTaskIds(next)
      return next
    })
  }

  function handleAddManualTask(task: ManualTask) {
    setManualTasks((prev) => {
      const next = [...prev, task]
      saveManualTasks(next)
      return next
    })
  }

  function addNote() {
    const content = noteInput.trim()
    if (!content) return
    const note: QuickNote = {
      id: `note-${Date.now()}`,
      content,
      createdAt: new Date().toISOString(),
    }
    setNotes((n) => {
      const next = [note, ...n]
      saveQuickNotes(next)
      return next
    })
    setNoteInput('')
  }

  function deleteNote(id: string) {
    setNotes((n) => {
      const next = n.filter((x) => x.id !== id)
      saveQuickNotes(next)
      return next
    })
  }

  // ── Stat card data ─────────────────────────────────────────────────────────
  const stats = [
    {
      icon: '⏱️',
      label: 'Bu Hafta',
      value: weekly ? fmtMinutes(weekly.totalMinutes) : '—',
      sub: 'çalışma süresi',
      color: '#F59E0B',
      bg: '#FFFBEB',
      darkBg: '#2A2518',
    },
    {
      icon: '🍅',
      label: 'Pomodoro',
      value: weekly?.pomodoroCount != null ? String(weekly.pomodoroCount) : '—',
      sub: 'tamamlanan',
      color: '#EF4444',
      bg: '#FEF2F2',
      darkBg: '#2A1818',
    },
    {
      icon: '🔥',
      label: 'Günlük Seri',
      value: streakDays > 0 ? `${streakDays}` : '—',
      sub: streakDays > 0 ? 'gün üst üste' : 'başlamamış',
      color: '#F97316',
      bg: '#FFF7ED',
      darkBg: '#2A1F14',
    },
    {
      icon: '📊',
      label: 'Son Net',
      value: lastExam ? lastExam.totalNet.toFixed(1) : '—',
      sub: 'deneme puanı',
      color: '#8B5CF6',
      bg: '#F5F3FF',
      darkBg: '#1E1A2E',
    },
  ]

  return (
    <>
      <div className="min-h-full">
        {/* ── Gradient Header Banner ────────────────────────────────────────── */}
        <div
          className="relative overflow-hidden px-10 pt-12 pb-16"
          style={{ background: 'linear-gradient(135deg, #4F46E5 0%, #6D28D9 60%, #7C3AED 100%)' }}
        >
          {/* Decorative circles */}
          <div
            className="absolute -top-16 -right-16 w-64 h-64 rounded-full opacity-10"
            style={{ background: '#fff' }}
          />
          <div
            className="absolute -bottom-20 -left-10 w-56 h-56 rounded-full opacity-10"
            style={{ background: '#fff' }}
          />

          <div className="relative flex flex-col sm:flex-row sm:items-start sm:justify-between gap-6">
            {/* Left: greeting */}
            <div>
              <p className="text-white/70 text-base font-medium mb-1">
                {today.toLocaleDateString('tr-TR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
              </p>
              <h1 className="text-5xl sm:text-6xl font-extrabold text-white leading-tight">
                Merhaba, {userName || 'Öğrenci'}! 👋
              </h1>
              <p className="text-white/70 text-lg mt-4 max-w-xl">
                Bugün de harika bir çalışma günü seni bekliyor. Hadi başlayalım!
              </p>
            </div>

            {/* Right: countdown badge */}
            {daysLeft !== null && (
              <div
                className="flex items-center gap-4 px-6 py-4 rounded-2xl self-start shrink-0"
                style={{ background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.25)' }}
              >
                <div className="text-center">
                  <p className="text-5xl font-extrabold text-white leading-none">{daysLeft}</p>
                  <p className="text-white/80 text-xs font-bold mt-1 tracking-widest uppercase">GÜN KALDI</p>
                </div>
                <div className="h-12 w-px" style={{ background: 'rgba(255,255,255,0.3)' }} />
                <div>
                  <p className="text-white/70 text-xs font-semibold mb-0.5">Hedef Sınav</p>
                  <p className="text-white font-extrabold text-lg leading-tight">{profile?.targetExam ?? 'Sınav'}</p>
                  <p className="text-white/60 text-xs mt-0.5">🎯 Başarıya odaklan</p>
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="px-8 sm:px-10 -mt-8 pb-12 space-y-8">
          {/* ── Stats Row ────────────────────────────────────────────────────── */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
            {stats.map((s, i) => (
              <div
                key={i}
                className="rounded-3xl p-6 shadow-md relative overflow-hidden"
                style={{ background: 'var(--card)', border: '2px solid var(--border)' }}
              >
                {/* Colored left stripe */}
                <div
                  className="absolute top-0 left-0 bottom-0 w-1.5 rounded-l-3xl"
                  style={{ background: s.color }}
                />
                <div
                  className="w-14 h-14 rounded-2xl flex items-center justify-center text-3xl mb-5"
                  style={{ background: `${s.color}20` }}
                >
                  {s.icon}
                </div>
                <p
                  className="text-5xl font-extrabold leading-none mb-2"
                  style={{ color: s.color }}
                >
                  {loading ? (
                    <span className="inline-block w-20 h-10 rounded-xl animate-pulse" style={{ background: 'var(--border)' }} />
                  ) : s.value}
                </p>
                <p className="text-base font-extrabold" style={{ color: 'var(--text-primary)' }}>{s.label}</p>
                <p className="text-sm mt-0.5" style={{ color: 'var(--text-hint)' }}>{s.sub}</p>
              </div>
            ))}
          </div>

          {/* ── Two Column ───────────────────────────────────────────────────── */}
          <div className="grid grid-cols-1 xl:grid-cols-2 gap-7">
            {/* Bugünün Programı */}
            <div
              className="rounded-3xl shadow-sm overflow-hidden"
              style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
            >
              {/* Card header */}
              <div className="px-6 py-5" style={{ borderBottom: '1px solid var(--border)' }}>
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-2xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                      📅 Bugünün Programı
                    </h2>
                    {todayPlan && (
                      <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                        {todayPlan.dayName} • {fmtMinutes(todayPlan.totalMinutes)} toplam
                      </p>
                    )}
                  </div>
                  {todayPlan && (
                    <span
                      className="px-3 py-1.5 rounded-xl text-sm font-bold"
                      style={{ background: '#EEF2FF', color: 'var(--primary)' }}
                    >
                      {todayTasks.length} görev
                    </span>
                  )}
                </div>
              </div>

              <div className="p-6">
                {loading ? (
                  <div className="space-y-3">
                    {[1, 2, 3].map((i) => (
                      <div key={i} className="h-20 rounded-2xl animate-pulse" style={{ background: 'var(--bg)' }} />
                    ))}
                  </div>
                ) : todayTasks.length === 0 && todayManual.length === 0 ? (
                  <div className="text-center py-12">
                    <p className="text-5xl mb-3">📚</p>
                    <p className="text-base font-bold" style={{ color: 'var(--text-primary)' }}>Bugün için plan yok</p>
                    <p className="text-sm mt-1" style={{ color: 'var(--text-hint)' }}>Manuel görev ekleyerek başlayabilirsin</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {todayTasks.map((task) => {
                      const done = completedIds.has(task.id)
                      return (
                        <div
                          key={task.id}
                          className="flex items-center gap-3 p-4 rounded-2xl transition-all"
                          style={{
                            background: done ? '#F0FDF4' : 'var(--bg)',
                            border: `1.5px solid ${done ? '#BBF7D0' : 'var(--border)'}`,
                          }}
                        >
                          <button
                            onClick={() => toggleComplete(task.id)}
                            className="w-7 h-7 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-all"
                            style={{
                              borderColor: done ? '#10B981' : 'var(--border)',
                              background: done ? '#10B981' : 'transparent',
                            }}
                          >
                            {done && <span className="text-white text-xs font-bold">✓</span>}
                          </button>

                          <div className="flex-1 min-w-0">
                            <p
                              className="text-sm font-bold truncate"
                              style={{
                                color: done ? '#059669' : 'var(--text-primary)',
                                textDecoration: done ? 'line-through' : 'none',
                              }}
                            >
                              {task.emoji} {task.subjectName}
                            </p>
                            <p className="text-xs mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                              {task.startTime} – {task.endTime} &nbsp;·&nbsp; {taskTypeLabel(task.taskType)} &nbsp;·&nbsp; {task.durationMinutes}dk
                            </p>
                          </div>

                          <button
                            onClick={() => openSession({
                              id: task.id,
                              subjectName: task.subjectName,
                              emoji: task.emoji,
                              startTime: task.startTime,
                              endTime: task.endTime,
                              durationMinutes: task.durationMinutes,
                              taskType: task.taskType,
                              isCompleted: done,
                              isMola: false,
                            } satisfies StudyTask)}
                            disabled={done}
                            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold text-white transition-all hover:opacity-90 shrink-0 disabled:opacity-40"
                            style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
                          >
                            ▶ Başla
                          </button>
                        </div>
                      )
                    })}

                    {/* Manual tasks */}
                    {todayManual.map((task) => {
                      const done = completedIds.has(task.id)
                      return (
                        <div
                          key={task.id}
                          className="flex items-center gap-3 p-4 rounded-2xl transition-all"
                          style={{
                            background: done ? '#F0FDF4' : 'var(--bg)',
                            border: `1.5px dashed ${done ? '#BBF7D0' : 'var(--border)'}`,
                          }}
                        >
                          <button
                            onClick={() => toggleComplete(task.id)}
                            className="w-7 h-7 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-all"
                            style={{
                              borderColor: done ? '#10B981' : 'var(--border)',
                              background: done ? '#10B981' : 'transparent',
                            }}
                          >
                            {done && <span className="text-white text-xs font-bold">✓</span>}
                          </button>
                          <div className="flex-1 min-w-0">
                            <p
                              className="text-sm font-bold truncate"
                              style={{
                                color: done ? '#059669' : 'var(--text-primary)',
                                textDecoration: done ? 'line-through' : 'none',
                              }}
                            >
                              📝 {task.subjectName}
                            </p>
                            <p className="text-xs mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                              {task.taskType} &nbsp;·&nbsp; {task.durationMinutes}dk &nbsp;·&nbsp;
                              <span style={{ color: 'var(--text-hint)' }}>Manuel</span>
                            </p>
                          </div>
                          <button
                            onClick={() => openSession({
                              id: task.id,
                              subjectName: task.subjectName,
                              emoji: '📝',
                              startTime: '',
                              endTime: '',
                              durationMinutes: task.durationMinutes,
                              taskType: task.taskType,
                              isCompleted: done,
                              isMola: false,
                            } satisfies StudyTask)}
                            disabled={done}
                            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold text-white transition-all hover:opacity-90 shrink-0 disabled:opacity-40"
                            style={{ background: 'linear-gradient(135deg, #10B981, #059669)' }}
                          >
                            ▶ Başla
                          </button>
                        </div>
                      )
                    })}
                  </div>
                )}

                {/* Add task button */}
                <button
                  onClick={() => setShowAddTask(true)}
                  className="mt-4 w-full py-3 rounded-2xl text-sm font-semibold transition-all hover:opacity-80 flex items-center justify-center gap-2"
                  style={{
                    background: 'var(--bg)',
                    border: '1.5px dashed var(--border)',
                    color: 'var(--text-secondary)',
                  }}
                >
                  <span className="text-lg">+</span> Manuel Görev Ekle
                </button>
              </div>
            </div>

            {/* Haftalık Takvim */}
            <div
              className="rounded-3xl shadow-sm overflow-hidden"
              style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
            >
              {/* Card header */}
              <div className="px-6 py-5" style={{ borderBottom: '1px solid var(--border)' }}>
                <h2 className="text-2xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                  📆 Haftalık Takvim
                </h2>
                <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                  {today.toLocaleDateString('tr-TR', { month: 'long', year: 'numeric' })}
                </p>
              </div>

              <div className="p-6">
                {loading ? (
                  <div className="grid grid-cols-7 gap-2">
                    {Array.from({ length: 7 }).map((_, i) => (
                      <div key={i} className="h-24 rounded-2xl animate-pulse" style={{ background: 'var(--bg)' }} />
                    ))}
                  </div>
                ) : weekDays.length === 0 ? (
                  <div className="text-center py-12">
                    <p className="text-5xl mb-3">📅</p>
                    <p className="text-base font-bold" style={{ color: 'var(--text-primary)' }}>Çalışma planı bulunamadı</p>
                    <p className="text-sm mt-1" style={{ color: 'var(--text-hint)' }}>Önce profil oluşturup plan ürettirmelisin</p>
                  </div>
                ) : (
                  <>
                    <div className="grid grid-cols-7 gap-2">
                      {weekDays.map((day) => {
                        const isToday = day.date.startsWith(todayStr)
                        const taskCount = day.blocks.filter((b) => !b.isMola).length
                        const dayDate = new Date(day.date)
                        const shortName = dayDate.toLocaleDateString('tr-TR', { weekday: 'short' })
                        return (
                          <div
                            key={day.date}
                            className="flex flex-col items-center py-3 px-1 rounded-2xl text-center transition-all"
                            style={{
                              background: isToday
                                ? 'linear-gradient(135deg, #4F46E5, #6D28D9)'
                                : 'var(--bg)',
                              border: `1.5px solid ${isToday ? 'transparent' : 'var(--border)'}`,
                            }}
                          >
                            <span
                              className="text-[10px] font-bold uppercase tracking-wide mb-1"
                              style={{ color: isToday ? 'rgba(255,255,255,0.65)' : 'var(--text-hint)' }}
                            >
                              {shortName}
                            </span>
                            <span
                              className="text-xl font-extrabold"
                              style={{ color: isToday ? '#fff' : 'var(--text-primary)' }}
                            >
                              {dayDate.getDate()}
                            </span>
                            {taskCount > 0 ? (
                              <span
                                className="mt-2 text-[10px] font-extrabold px-1.5 py-0.5 rounded-full min-w-[20px]"
                                style={{
                                  background: isToday ? 'rgba(255,255,255,0.25)' : '#EEF2FF',
                                  color: isToday ? '#fff' : 'var(--primary)',
                                }}
                              >
                                {taskCount}
                              </span>
                            ) : (
                              <span
                                className="mt-2 text-[11px]"
                                style={{ color: isToday ? 'rgba(255,255,255,0.4)' : 'var(--border)' }}
                              >
                                –
                              </span>
                            )}
                          </div>
                        )
                      })}
                    </div>

                    {/* Week summary */}
                    <div
                      className="mt-5 pt-5 grid grid-cols-3 gap-4"
                      style={{ borderTop: '1px solid var(--border)' }}
                    >
                      {[
                        { label: 'Toplam Görev', value: totalWeekTasks, icon: '📋' },
                        { label: 'Toplam Süre', value: fmtMinutes(totalWeekMinutes), icon: '⏳' },
                        { label: 'Oturum', value: weekly?.totalSessions ?? '—', icon: '🎯' },
                      ].map((item, i) => (
                        <div key={i} className="text-center">
                          <p className="text-2xl mb-1">{item.icon}</p>
                          <p className="text-2xl font-extrabold" style={{ color: 'var(--primary)' }}>
                            {item.value}
                          </p>
                          <p className="text-xs mt-0.5" style={{ color: 'var(--text-secondary)' }}>{item.label}</p>
                        </div>
                      ))}
                    </div>
                  </>
                )}
              </div>
            </div>
          </div>

          {/* ── Quick Notes ─────────────────────────────────────────────────── */}
          <div
            className="rounded-3xl shadow-sm overflow-hidden"
            style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
          >
            {/* Card header */}
            <div className="px-6 py-5" style={{ borderBottom: '1px solid var(--border)' }}>
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-2xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                    📝 Hızlı Notlar
                  </h2>
                  <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                    Aklındakileri hızlıca kaydet
                  </p>
                </div>
                {notes.length > 0 && (
                  <span
                    className="px-3 py-1.5 rounded-xl text-sm font-bold"
                    style={{ background: '#EEF2FF', color: 'var(--primary)' }}
                  >
                    {notes.length} not
                  </span>
                )}
              </div>
            </div>

            <div className="p-6">
              {/* Input row */}
              <div className="flex gap-3 mb-5">
                <input
                  ref={noteInputRef}
                  value={noteInput}
                  onChange={(e) => setNoteInput(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && addNote()}
                  placeholder="Bir not ekle... (Enter ile kaydet)"
                  className="flex-1 px-5 py-3.5 rounded-2xl text-sm outline-none transition-all"
                  style={{
                    background: 'var(--bg)',
                    border: '1.5px solid var(--border)',
                    color: 'var(--text-primary)',
                    fontSize: '15px',
                  }}
                />
                <button
                  onClick={addNote}
                  disabled={!noteInput.trim()}
                  className="px-6 py-3.5 rounded-2xl text-sm font-bold text-white transition-all hover:opacity-90 disabled:opacity-50"
                  style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)', whiteSpace: 'nowrap' }}
                >
                  + Ekle
                </button>
              </div>

              {notes.length === 0 ? (
                <div className="text-center py-8" style={{ color: 'var(--text-hint)' }}>
                  <p className="text-4xl mb-2">🗒️</p>
                  <p className="text-sm font-medium">Henüz not yok. İlkini ekle!</p>
                </div>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {notes.map((n) => (
                    <div
                      key={n.id}
                      className="group flex items-center gap-2 px-4 py-2.5 rounded-2xl text-sm transition-all hover:shadow-sm"
                      style={{
                        background: 'var(--bg)',
                        border: '1.5px solid var(--border)',
                        color: 'var(--text-primary)',
                        fontSize: '14px',
                        maxWidth: '280px',
                      }}
                    >
                      <span className="truncate">{n.content}</span>
                      <button
                        onClick={() => deleteNote(n.id)}
                        className="flex-shrink-0 w-5 h-5 rounded-full flex items-center justify-center text-xs opacity-40 group-hover:opacity-100 transition-opacity hover:bg-red-100"
                        style={{ color: 'var(--error)' }}
                      >
                        ✕
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Modals */}
      {showAddTask && (
        <AddTaskModal
          onClose={() => setShowAddTask(false)}
          onAdd={handleAddManualTask}
        />
      )}
      {isModalOpen && <StudySessionModal />}
    </>
  )
}

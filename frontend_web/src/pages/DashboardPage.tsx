import { useEffect, useMemo, useState } from 'react'
import { useUserProfile } from '../hooks/useUserProfile'
import { useStudySessionStore, type StudyTask } from '../stores/studySessionStore'
import StudySessionModal from '../components/StudySessionModal'
import { getStudyPlan, type StudyDayView } from '../services/studyPlanLocal'
import {
  getManualTasks, saveManualTasks,
  getQuickNotes, saveQuickNotes,
  getCompletedTaskIds, saveCompletedTaskIds,
  getTopicAssignments, saveTopicAssignments,
  getRestDays, saveRestDays,
  addCompletedLesson, removeCompletedLesson,
  type ManualTask, type QuickNote,
} from '../services/localData'
import { hydrateAppState } from '../services/appStateService'
import { getSubjectsForExam } from '../data/subjectsData'
import { getTopicsForSubject } from '../data/subjectTopics'
import { getOnboardingData, getExamGoal } from '../services/userPrefsService'
import { getUserId } from '../services/tokenService'

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

function ymd(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function daysUntil(dateStr: string | null | undefined): number | null {
  if (!dateStr) return null
  const d = new Date(dateStr)
  const now = new Date()
  now.setHours(0, 0, 0, 0)
  d.setHours(0, 0, 0, 0)
  const diff = Math.round((d.getTime() - now.getTime()) / 86400000)
  return diff > 0 ? diff : null
}

function taskTypeLabel(type: string): string {
  const map: Record<string, string> = {
    konu_anlatimi: 'Konu Anlatımı',
    soru_cozumu: 'Soru Çözümü',
    tekrar: 'Tekrar',
    deneme: 'Deneme Sınavı',
    mola: 'Mola',
  }
  return map[type] ?? type
}

const TASK_TYPES = [
  { value: 'konu_anlatimi', label: 'Konu Çalışması' },
  { value: 'soru_cozumu', label: 'Soru Çözümü' },
  { value: 'deneme', label: 'Deneme Sınavı' },
  { value: 'tekrar', label: 'Tekrar' },
] as const
const DURATION_OPTIONS = [30, 45, 60, 90, 120] as const

// Dashboard'un gösterdiği birleşik görev tipi
interface DayTask {
  id: string
  subjectName: string
  emoji: string
  startTime: string
  endTime: string
  durationMinutes: number
  taskType: string
  isMola: boolean
  isStrong: boolean
  topicName?: string
}

// ─── Modal kabuğu ─────────────────────────────────────────────────────────────

function ModalShell({ title, subtitle, onClose, headerAction, children }: {
  title: string
  subtitle?: string
  onClose: () => void
  headerAction?: React.ReactNode
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
        <div className="px-7 py-6" style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}>
          <div className="flex items-center justify-between gap-3">
            <div className="min-w-0">
              <h3 className="text-2xl font-extrabold text-white">{title}</h3>
              {subtitle && <p className="text-base text-white/70 mt-1">{subtitle}</p>}
            </div>
            <div className="flex items-center gap-2 shrink-0">
              {headerAction}
              <button
                onClick={onClose}
                className="w-10 h-10 rounded-full flex items-center justify-center text-white/70 hover:text-white hover:bg-white/10 transition-all text-xl"
              >
                ✕
              </button>
            </div>
          </div>
        </div>
        <div className="p-7 overflow-y-auto">{children}</div>
      </div>
    </div>
  )
}

// ─── +Görev menüsü (3 seçenek) ────────────────────────────────────────────────

function AddTaskMenu({ onClose, onTopic, onManual, onRest }: {
  onClose: () => void
  onTopic: () => void
  onManual: () => void
  onRest: () => void
}) {
  const tiles = [
    { color: '#4F46E5', icon: '📋', title: 'Çalışma Programıma Konu Ekle', subtitle: 'Derslerine konu ata ve takibini yap', onClick: onTopic },
    { color: '#F97316', icon: '✏️', title: 'Kendim Görev Ekle', subtitle: 'Manuel olarak ders, konu ve süre belirle', onClick: onManual },
    { color: '#10B981', icon: '😴', title: 'Hastayım / Dinlenme Modu', subtitle: 'Bugün çalışamayacak kadar kötüysen', onClick: onRest },
  ]
  return (
    <ModalShell title="Ne Yapmak İstersin?" onClose={onClose}>
      <div className="space-y-4">
        {tiles.map((t) => (
          <button
            key={t.title}
            onClick={t.onClick}
            className="w-full flex items-center gap-4 p-6 rounded-2xl text-left transition-all hover:opacity-90"
            style={{ background: `${t.color}15` }}
          >
            <div
              className="w-16 h-16 rounded-2xl flex items-center justify-center text-3xl shrink-0"
              style={{ background: `${t.color}25` }}
            >
              {t.icon}
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-bold text-lg" style={{ color: 'var(--text-primary)' }}>{t.title}</p>
              <p className="text-base mt-0.5" style={{ color: 'var(--text-secondary)' }}>{t.subtitle}</p>
            </div>
            <span className="text-xl" style={{ color: 'var(--text-hint)' }}>›</span>
          </button>
        ))}
      </div>
    </ModalShell>
  )
}

// ─── Dinlenme modu onayı ──────────────────────────────────────────────────────

function RestConfirmModal({ onClose, onConfirm }: { onClose: () => void; onConfirm: () => void }) {
  return (
    <ModalShell title="😴 Dinlenme Modu" onClose={onClose}>
      <p className="text-base leading-relaxed mb-6" style={{ color: 'var(--text-primary)' }}>
        Bugünü dinlenme günü olarak işaretlemek istediğine emin misin? Bugünkü tüm görevler
        tamamlanmış sayılacak ve programın yarın kaldığı yerden devam edecek.
      </p>
      <div className="flex gap-3">
        <button
          onClick={onClose}
          className="flex-1 py-3.5 rounded-xl text-base font-semibold"
          style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}
        >
          Vazgeç
        </button>
        <button
          onClick={onConfirm}
          className="flex-1 py-3.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
          style={{ background: 'linear-gradient(135deg, #10B981, #059669)' }}
        >
          Evet, dinleneceğim
        </button>
      </div>
    </ModalShell>
  )
}

// ─── Manuel görev ekleme ──────────────────────────────────────────────────────

function ManualTaskModal({ subjects, onClose, onAdd }: {
  subjects: string[]
  onClose: () => void
  onAdd: (task: ManualTask) => void
}) {
  const [subject, setSubject] = useState('')
  const [topic, setTopic] = useState('')
  const [taskType, setTaskType] = useState<string>('konu_anlatimi')
  const [duration, setDuration] = useState(60)

  function save() {
    const name = subject.trim()
    if (!name) return
    const d = new Date()
    onAdd({
      id: `manual-${Date.now()}`,
      subjectName: name,
      taskType,
      durationMinutes: duration,
      date: ymd(d),
      topicName: topic.trim() || undefined,
      isStrong: false,
    })
    onClose()
  }

  return (
    <ModalShell title="✏️ Görev Ekle" subtitle="Bugünkü programa görev ekle" onClose={onClose}>
      <div className="space-y-5">
        <div>
          <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>📚 Ders</label>
          {subjects.length > 0 ? (
            <select
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              className="w-full h-14 px-4 rounded-xl text-base outline-none"
              style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
            >
              <option value="">Ders seç</option>
              {subjects.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
          ) : (
            <input
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              placeholder="Ders adı yaz"
              className="w-full h-14 px-4 rounded-xl text-base outline-none"
              style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
            />
          )}
        </div>

        <div>
          <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>📝 Konu (isteğe bağlı)</label>
          {(() => {
            const topics = getTopicsForSubject(subject)
            return topics.length > 0 ? (
              <select
                value={topic}
                onChange={(e) => setTopic(e.target.value)}
                className="w-full h-14 px-4 rounded-xl text-base outline-none"
                style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
              >
                <option value="">🚫 Konu belirtmek istemiyorum</option>
                {topics.map((t) => <option key={t} value={t}>{t}</option>)}
              </select>
            ) : (
              <input
                value={topic}
                onChange={(e) => setTopic(e.target.value)}
                placeholder="Konu adı yaz"
                className="w-full h-14 px-4 rounded-xl text-base outline-none"
                style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
              />
            )
          })()}
        </div>

        <div>
          <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>🎯 Görev Türü</label>
          <div className="grid grid-cols-2 gap-2.5">
            {TASK_TYPES.map((t) => (
              <button
                key={t.value}
                onClick={() => setTaskType(t.value)}
                className="py-3 px-3 rounded-xl text-sm font-semibold transition-all"
                style={{
                  background: taskType === t.value ? 'linear-gradient(135deg, #4F46E5, #6D28D9)' : 'var(--bg)',
                  color: taskType === t.value ? '#fff' : 'var(--text-secondary)',
                  border: `1.5px solid ${taskType === t.value ? 'transparent' : 'var(--border)'}`,
                }}
              >
                {t.label}
              </button>
            ))}
          </div>
        </div>

        <div>
          <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>⏱️ Süre</label>
          <div className="flex gap-2 flex-wrap">
            {DURATION_OPTIONS.map((d) => (
              <button
                key={d}
                onClick={() => setDuration(d)}
                className="px-4 py-2.5 rounded-xl text-sm font-semibold transition-all"
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

        <div className="flex gap-3 pt-2">
          <button
            onClick={onClose}
            className="flex-1 h-13 py-3.5 rounded-xl text-base font-semibold"
            style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}
          >
            İptal
          </button>
          <button
            onClick={save}
            disabled={!subject.trim()}
            className="flex-1 py-3.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90 disabled:opacity-50"
            style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
          >
            ✓ Kaydet
          </button>
        </div>
      </div>
    </ModalShell>
  )
}

// ─── Konu atama (tüm haftalık programdaki bloklara konu ekle) ─────────────────

function TopicEditorModal({ plan, assignments, onClose, onSave }: {
  plan: StudyDayView[]
  assignments: Record<string, string>
  onClose: () => void
  onSave: (map: Record<string, string>) => void
}) {
  const [draft, setDraft] = useState<Record<string, string>>({ ...assignments })
  const [expandedId, setExpandedId] = useState<string | null>(null)

  const hasAny = plan.some((d) => d.blocks.some((b) => !b.isMola))

  return (
    <ModalShell title="📋 Konuları Düzenle" subtitle="Derse tıkla, konu seç" onClose={onClose}>
      {!hasAny ? (
        <p className="text-base text-center py-6" style={{ color: 'var(--text-secondary)' }}>
          Programda ders bloğu yok.
        </p>
      ) : (
        <div className="space-y-6">
          {plan.map((day) => {
            const blocks = day.blocks.filter((b) => !b.isMola)
            if (day.isOffDay || blocks.length === 0) return null
            return (
              <div key={day.date}>
                <p className="font-extrabold text-base mb-3" style={{ color: 'var(--primary)' }}>
                  {day.dayName} · {new Date(day.date).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long' })}
                </p>
                <div className="space-y-2.5">
                  {blocks.map((b) => {
                    const topics = getTopicsForSubject(b.subjectName)
                    const selected = draft[b.id] ?? ''
                    const isOpen = expandedId === b.id
                    return (
                      <div
                        key={b.id}
                        className="rounded-xl overflow-hidden"
                        style={{ border: '1.5px solid var(--border)' }}
                      >
                        {/* Ders satırı — tıklanınca konular açılır */}
                        <button
                          onClick={() => setExpandedId(isOpen ? null : b.id)}
                          className="w-full flex items-center gap-3 px-4 py-3.5 text-left"
                          style={{ background: 'var(--bg)' }}
                        >
                          <span className="text-xl">{b.emoji}</span>
                          <div className="flex-1 min-w-0">
                            <p className="text-base font-bold truncate" style={{ color: 'var(--text-primary)' }}>
                              {b.subjectName}
                            </p>
                            {selected && (
                              <p className="text-sm truncate" style={{ color: 'var(--primary)' }}>
                                Konu: {selected}
                              </p>
                            )}
                          </div>
                          <span className="text-sm" style={{ color: 'var(--text-hint)' }}>{isOpen ? '▲' : '▼'}</span>
                        </button>

                        {/* Konu listesi — sadece açıkken */}
                        {isOpen && (
                          <div className="px-3 py-3 space-y-1.5" style={{ borderTop: '1px solid var(--border)' }}>
                            {topics.length > 0 ? (
                              <>
                                {selected && (
                                  <button
                                    onClick={() => {
                                      setDraft((d) => { const n = { ...d }; delete n[b.id]; return n })
                                    }}
                                    className="w-full text-left px-3 py-2 rounded-lg text-sm"
                                    style={{ color: 'var(--error)' }}
                                  >
                                    ✕ Konu seçimini kaldır
                                  </button>
                                )}
                                {topics.map((t) => (
                                  <button
                                    key={t}
                                    onClick={() => {
                                      setDraft((d) => ({ ...d, [b.id]: t }))
                                      setExpandedId(null)
                                    }}
                                    className="w-full text-left px-3 py-2.5 rounded-lg text-sm font-medium transition-all"
                                    style={{
                                      background: selected === t ? '#EEF2FF' : 'transparent',
                                      color: selected === t ? 'var(--primary)' : 'var(--text-primary)',
                                    }}
                                  >
                                    {selected === t ? '✓ ' : ''}{t}
                                  </button>
                                ))}
                              </>
                            ) : (
                              <input
                                value={selected}
                                onChange={(e) => setDraft((d) => ({ ...d, [b.id]: e.target.value }))}
                                placeholder="Konu adı yaz (opsiyonel)"
                                className="w-full h-12 px-3 rounded-lg text-sm outline-none"
                                style={{ background: 'var(--card)', border: '1.5px solid var(--border)', color: 'var(--text-primary)' }}
                              />
                            )}
                          </div>
                        )}
                      </div>
                    )
                  })}
                </div>
              </div>
            )
          })}
          <button
            onClick={() => { onSave(draft); onClose() }}
            className="w-full py-3.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
            style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
          >
            ✓ Kaydet
          </button>
        </div>
      )}
    </ModalShell>
  )
}

// ─── Haftalık planı incele ────────────────────────────────────────────────────

function WeeklyPlanModal({ plan, assignments, onClose }: {
  plan: StudyDayView[]
  assignments: Record<string, string>
  onClose: () => void
}) {
  // Planı yazdırılabilir HTML olarak yeni pencerede aç → kullanıcı "PDF olarak kaydet" ile indirir
  function downloadPdf() {
    const rows = plan.map((day) => {
      const blocks = day.blocks
      const inner = day.isOffDay
        ? '<div class="off">😴 Dinlenme günü</div>'
        : blocks.length === 0
        ? '<div class="empty">Plan yok</div>'
        : blocks.map((b) => {
            const topic = !b.isMola && assignments[b.id] ? ` — ${assignments[b.id]}` : ''
            const name = b.isMola ? 'Mola' : `${b.subjectName}${topic}`
            const type = b.isMola ? '' : ` · ${taskTypeLabel(b.taskType)}`
            return `<div class="block${b.isMola ? ' mola' : ''}">
              <span class="emoji">${b.emoji}</span>
              <span class="name">${name}${type}</span>
              <span class="time">${b.startTime} – ${b.endTime}</span>
            </div>`
          }).join('')
      const dateStr = new Date(day.date).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long' })
      return `<div class="day">
        <h2>${day.dayName} <small>${dateStr}</small></h2>
        ${inner}
      </div>`
    }).join('')

    const html = `<!doctype html><html lang="tr"><head><meta charset="utf-8">
      <title>Haftalık Çalışma Planı</title>
      <style>
        body{font-family:'Inter',Arial,sans-serif;margin:32px;color:#111827;}
        h1{color:#4F46E5;font-size:24px;margin-bottom:4px;}
        .sub{color:#6B7280;font-size:13px;margin-bottom:24px;}
        .day{margin-bottom:20px;page-break-inside:avoid;}
        .day h2{font-size:16px;margin:0 0 8px;}
        .day h2 small{color:#9CA3AF;font-weight:400;font-size:12px;}
        .block{display:flex;gap:10px;align-items:center;padding:8px 12px;border:1px solid #E5E7EB;border-radius:8px;margin-bottom:6px;font-size:13px;}
        .block.mola{background:#F0FDF4;border-color:#BBF7D0;}
        .block .name{flex:1;font-weight:600;}
        .block .time{color:#9CA3AF;font-size:12px;}
        .off{padding:8px 12px;background:#F0FDF4;color:#059669;border-radius:8px;font-size:13px;}
        .empty{padding:8px 12px;background:#F3F4F6;color:#9CA3AF;border-radius:8px;font-size:13px;}
      </style></head><body>
      <h1>📅 Haftalık Çalışma Planı</h1>
      <div class="sub">AI Study Coach — 7 günlük program</div>
      ${rows}
      <script>window.onload=function(){window.print();}</script>
      </body></html>`

    const w = window.open('', '_blank')
    if (w) {
      w.document.write(html)
      w.document.close()
    }
  }

  return (
    <ModalShell
      title="📅 Haftalık Planım"
      subtitle="Bu haftanın 7 günlük çalışma planı"
      onClose={onClose}
      headerAction={
        <button
          onClick={downloadPdf}
          className="flex items-center gap-1.5 px-3.5 h-10 rounded-xl text-sm font-bold text-white transition-all"
          style={{ background: 'rgba(255,255,255,0.2)' }}
          title="PDF olarak indir"
        >
          ⬇ PDF
        </button>
      }
    >
      <div className="space-y-5">
        {plan.map((day) => {
          const studyBlocks = day.blocks.filter((b) => !b.isMola)
          const dayDate = new Date(day.date)
          const todayD = new Date()
          todayD.setHours(0, 0, 0, 0)
          const dayD = new Date(dayDate.getFullYear(), dayDate.getMonth(), dayDate.getDate())
          const isPast = dayD.getTime() < todayD.getTime()
          return (
            <div key={day.date} style={{ opacity: isPast ? 0.55 : 1 }}>
              <div className="flex items-center gap-2 mb-2">
                <span className="font-extrabold text-lg" style={{ color: 'var(--text-primary)' }}>
                  {day.dayName}
                </span>
                <span className="text-sm" style={{ color: 'var(--text-hint)' }}>
                  {new Date(day.date).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long' })}
                </span>
                {isPast && (
                  <span
                    className="px-2 py-0.5 rounded-md text-xs font-bold"
                    style={{ background: 'var(--bg)', color: 'var(--text-hint)', border: '1px solid var(--border)' }}
                  >
                    Geçmiş Gün
                  </span>
                )}
              </div>
              {day.isOffDay ? (
                <div className="px-4 py-3 rounded-xl text-sm" style={{ background: '#F0FDF4', color: '#059669' }}>
                  😴 Dinlenme günü
                </div>
              ) : studyBlocks.length === 0 ? (
                <div className="px-4 py-3 rounded-xl text-sm" style={{ background: 'var(--bg)', color: 'var(--text-hint)' }}>
                  Plan yok
                </div>
              ) : (
                <div className="space-y-2">
                  {day.blocks.map((b) => (
                    <div
                      key={b.id}
                      className="flex items-center gap-3 px-4 py-3 rounded-xl"
                      style={{
                        background: b.isMola ? '#F0FDF4' : 'var(--bg)',
                        border: `1px solid ${b.isMola ? '#BBF7D0' : 'var(--border)'}`,
                      }}
                    >
                      <span className="text-xl">{b.emoji}</span>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-bold truncate" style={{ color: 'var(--text-primary)' }}>
                          {b.isMola ? 'Mola' : b.subjectName}
                          {!b.isMola && assignments[b.id] && (
                            <span className="font-normal" style={{ color: 'var(--primary)' }}> — {assignments[b.id]}</span>
                          )}
                        </p>
                        {!b.isMola && (
                          <p className="text-xs" style={{ color: 'var(--text-secondary)' }}>
                            {taskTypeLabel(b.taskType)}
                          </p>
                        )}
                      </div>
                      <span className="text-xs font-semibold" style={{ color: 'var(--text-hint)' }}>
                        {b.startTime} – {b.endTime}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )
        })}
      </div>
    </ModalShell>
  )
}

// ─── Görev kartı ──────────────────────────────────────────────────────────────

function TaskCard({ task, done, locked, topic, onToggle, onStart, onLockedTap }: {
  task: DayTask
  done: boolean
  locked: boolean
  topic?: string
  onToggle: () => void
  onStart: () => void
  onLockedTap: () => void
}) {
  if (task.isMola) {
    return (
      <div
        className="flex items-center gap-3 p-5 rounded-2xl"
        style={{ background: 'var(--success-bg)', border: '1.5px solid var(--success-border)' }}
      >
        <span className="text-3xl">☕</span>
        <div className="flex-1">
          <p className="text-base font-bold" style={{ color: 'var(--success-text)' }}>Mola</p>
          <p className="text-sm" style={{ color: 'var(--success-text)' }}>{task.startTime} – {task.endTime} · {task.durationMinutes}dk</p>
        </div>
      </div>
    )
  }
  return (
    <div
      className="flex items-center gap-5 p-6 rounded-2xl transition-all"
      style={{
        background: done ? 'var(--success-bg)' : 'var(--card)',
        border: `2px solid ${done ? 'var(--success-border)' : 'var(--border)'}`,
        opacity: locked ? 0.6 : 1,
      }}
    >
      {/* Ders adına tıkla → çalışma ekranı */}
      <button
        onClick={locked ? onLockedTap : onStart}
        className="flex-1 min-w-0 text-left cursor-pointer"
      >
        <p
          className="text-lg font-extrabold truncate"
          style={{ color: done ? 'var(--success-text)' : 'var(--text-primary)', textDecoration: done ? 'line-through' : 'none' }}
        >
          {task.emoji} {task.subjectName}
          {topic && <span className="font-medium" style={{ color: 'var(--text-secondary)' }}> — {topic}</span>}
        </p>
        <p className="text-base mt-1" style={{ color: 'var(--text-secondary)' }}>
          {task.startTime ? `${task.startTime} – ${task.endTime} · ` : ''}{taskTypeLabel(task.taskType)} · {task.durationMinutes}dk
        </p>
      </button>

      {locked && <span className="text-2xl shrink-0">🔒</span>}

      {/* Tamamlama yuvarlağı — sağda, belirgin çerçeveli, basınca yeşil tik */}
      <button
        onClick={locked ? onLockedTap : onToggle}
        className="w-11 h-11 rounded-full flex items-center justify-center flex-shrink-0 transition-all"
        style={{
          border: `3px solid ${done ? '#10B981' : '#9CA3AF'}`,
          background: done ? '#10B981' : 'transparent',
        }}
        title={done ? 'Tamamlandı' : 'Tamamlandı işaretle'}
      >
        {done && <span className="text-white text-xl font-bold">✓</span>}
      </button>
    </div>
  )
}

function SectionHeader({ icon, text, color, locked }: { icon: string; text: string; color: string; locked?: boolean }) {
  return (
    <div
      className="flex items-center gap-3 px-5 py-4 rounded-xl"
      style={{ background: `${color}14`, borderLeft: `5px solid ${color}` }}
    >
      <span className="text-2xl">{icon}</span>
      <span className="font-extrabold text-xl flex-1" style={{ color }}>{text}</span>
      {locked && <span className="text-xl" style={{ color }}>🔒</span>}
    </div>
  )
}

// ─── Ana sayfa ─────────────────────────────────────────────────────────────────

export default function DashboardPage() {
  const { profile } = useUserProfile()
  const { open: openSession } = useStudySessionStore()
  const isModalOpen = useStudySessionStore((s) => s.isOpen)

  const [plan, setPlan] = useState<StudyDayView[]>([])
  const [manualTasks, setManualTasks] = useState<ManualTask[]>([])
  const [notes, setNotes] = useState<QuickNote[]>([])
  const [completedIds, setCompletedIds] = useState<Set<string>>(new Set())
  const [topicAssignments, setTopicAssignments] = useState<Record<string, string>>({})
  const [restDays, setRestDays] = useState<string[]>([])
  const [loading, setLoading] = useState(true)

  const [showAddMenu, setShowAddMenu] = useState(false)
  const [showManual, setShowManual] = useState(false)
  const [showTopicEditor, setShowTopicEditor] = useState(false)
  const [showWeekly, setShowWeekly] = useState(false)
  const [showNotes, setShowNotes] = useState(false)
  const [showRestConfirm, setShowRestConfirm] = useState(false)
  const [showInfo, setShowInfo] = useState(false)
  const [pendingStart, setPendingStart] = useState<DayTask | null>(null)
  const [noteTitle, setNoteTitle] = useState('')
  const [noteContent, setNoteContent] = useState('')
  const [noteConfirmId, setNoteConfirmId] = useState<string | null>(null)
  const [toast, setToast] = useState<string | null>(null)

  function showToast(msg: string) {
    setToast(msg)
    window.setTimeout(() => setToast(null), 2600)
  }

  function reloadLocal() {
    setPlan(getStudyPlan())
    setManualTasks(getManualTasks())
    setNotes(getQuickNotes())
    setCompletedIds(getCompletedTaskIds())
    setTopicAssignments(getTopicAssignments())
    setRestDays(getRestDays())
  }

  useEffect(() => {
    // Önce backend'den AppState'i indir (mobilin push ettiği güncel plan,
    // notlar vb. gelsin), sonra local'den oku.
    let cancelled = false
    ;(async () => {
      await hydrateAppState()
      if (cancelled) return
      reloadLocal()
      setLoading(false)
    })()
    return () => { cancelled = true }
  }, [])

  // Çalışma modalı kapandığında tamamlanan görevleri yansıt
  useEffect(() => {
    if (!isModalOpen) setCompletedIds(getCompletedTaskIds())
  }, [isModalOpen])

  const today = new Date()
  const todayStr = ymd(today)
  const isRestToday = restDays.includes(todayStr)

  const todayPlan = useMemo(
    () => plan.find((d) => d.date.startsWith(todayStr)) ?? plan[0] ?? null,
    [plan, todayStr],
  )

  // Plan blokları + bugünün manuel görevleri → birleşik görev listesi
  const todayTasks: DayTask[] = useMemo(() => {
    if (isRestToday) return []
    const planTasks: DayTask[] = (todayPlan?.blocks ?? []).map((b) => ({
      id: b.id,
      subjectName: b.subjectName,
      emoji: b.emoji,
      startTime: b.startTime,
      endTime: b.endTime,
      durationMinutes: b.durationMinutes,
      taskType: b.taskType,
      isMola: b.isMola,
      isStrong: b.isStrong,
    }))
    const manual: DayTask[] = manualTasks
      // date 'YYYY-MM-DD' ya da tam ISO timestamp olabilir (eski mobil verisi);
      // ilk 10 karakteri (gün) karşılaştır.
      .filter((t) => (t.date ?? '').slice(0, 10) === todayStr)
      .map((t) => ({
        id: t.id,
        subjectName: t.subjectName,
        emoji: '📝',
        startTime: '',
        endTime: '',
        durationMinutes: t.durationMinutes,
        taskType: t.taskType,
        isMola: false,
        isStrong: !!t.isStrong,
        topicName: t.topicName,
      }))
    return [...planTasks, ...manual]
  }, [todayPlan, manualTasks, todayStr, isRestToday])

  // Mobildeki gruplama: zayıf+mola → öncelikli, güçlü → pekiştirme (zayıflar bitince açılır)
  const weakTasks = todayTasks.filter((t) => !t.isStrong && !t.isMola && t.id.startsWith('w_'))
  const molaTasks = todayTasks.filter((t) => t.isMola)
  const generatedStrong = todayTasks.filter((t) => t.isStrong && !t.isMola && t.id.startsWith('s_'))
  const manualTasksList = todayTasks.filter((t) => t.id.startsWith('manual-'))
  // Gece kuşu: 04:00 öncesi saatler ertesi günün gece saati (+24h) sayılır,
  // böylece "23:00 → 00:30 → 01:30" doğru sıralanır.
  function sortKey(hhmm: string): number {
    const [h, m] = hhmm.split(':').map((s) => Number(s) || 0)
    const mins = h * 60 + m
    return mins < 4 * 60 ? mins + 24 * 60 : mins
  }
  const priorityTasks = [...weakTasks, ...molaTasks].sort((a, b) => sortKey(a.startTime) - sortKey(b.startTime))
  const weakDone = weakTasks.length === 0 || weakTasks.every((t) => completedIds.has(t.id))

  const taskCount = todayTasks.filter((t) => !t.isMola).length
  const dayName = today.toLocaleDateString('tr-TR', { weekday: 'long' })

  // localStorage onboarding verisi — ders havuzu ve sınav tarihi için güvenilir kaynak
  const localData = useMemo(() => {
    const uid = getUserId()
    return uid ? getOnboardingData(uid) : null
  }, [])

  const examGoal = useMemo(() => {
    const uid = getUserId()
    return uid ? getExamGoal(uid) : null
  }, [])

  const daysLeft = daysUntil(profile?.examDate ?? localData?.examDate)

  const subjectPool = useMemo(() => {
    const targetExam = profile?.targetExam || localData?.targetExam || ''
    const selectedArea = profile?.selectedArea || localData?.selectedArea || ''
    const base = getSubjectsForExam(targetExam, selectedArea).map((s) => s.name)
    const customs = profile?.customSubjects ?? localData?.customSubjects ?? []
    const extra = customs.filter((s) => !base.includes(s))
    return [...base, ...extra]
  }, [profile, localData])

  // ── Eylemler ───────────────────────────────────────────────────────────────

  function toggleComplete(task: DayTask) {
    setCompletedIds((prev) => {
      const next = new Set(prev)
      if (next.has(task.id)) {
        next.delete(task.id)
        removeCompletedLesson(todayStr, task.id)
      } else {
        next.add(task.id)
        // Geçmiş günlerde ders adını gösterebilmek için detayı da kaydet
        addCompletedLesson(todayStr, {
          id: task.id,
          subjectName: task.subjectName,
          emoji: task.emoji,
          taskType: task.taskType,
          durationMinutes: task.durationMinutes,
          topicName: task.topicName ?? topicAssignments[task.id],
        })
      }
      saveCompletedTaskIds(next)
      return next
    })
  }

  // Derse tıklanınca önce onay modalı açılır
  function requestStart(task: DayTask) {
    setPendingStart(task)
  }

  // Onaydan sonra çalışma ekranını açar
  function confirmStart() {
    const task = pendingStart
    if (!task) return
    setPendingStart(null)
    openSession({
      id: task.id,
      subjectName: task.subjectName,
      emoji: task.emoji,
      startTime: task.startTime,
      endTime: task.endTime,
      durationMinutes: task.durationMinutes,
      taskType: task.taskType,
      isCompleted: completedIds.has(task.id),
      isMola: task.isMola,
    } satisfies StudyTask)
  }

  function addManualTask(task: ManualTask) {
    const next = [...manualTasks, task]
    setManualTasks(next)
    saveManualTasks(next)
  }

  function saveTopics(map: Record<string, string>) {
    setTopicAssignments(map)
    saveTopicAssignments(map)
  }

  function enableRestToday() {
    const next = [...restDays, todayStr]
    setRestDays(next)
    saveRestDays(next)
    // Bugünkü tüm görevleri tamamlandı say (mobil ile aynı)
    const ids = getCompletedTaskIds()
    todayTasks.forEach((t) => ids.add(t.id))
    saveCompletedTaskIds(ids)
    setCompletedIds(ids)
    setShowRestConfirm(false)
    showToast('Dinlenme modu aktif. İyi dinlenmeler! 🌙')
  }

  function disableRestToday() {
    const next = restDays.filter((d) => d !== todayStr)
    setRestDays(next)
    saveRestDays(next)
  }

  function addNote() {
    const content = noteContent.trim()
    if (!content) return
    const next: QuickNote[] = [
      {
        id: `note-${Date.now()}`,
        title: noteTitle.trim() || 'Not',
        content,
        createdAt: new Date().toISOString(),
      },
      ...notes,
    ]
    setNotes(next)
    saveQuickNotes(next)
    setNoteTitle('')
    setNoteContent('')
  }

  function deleteNote(id: string) {
    const next = notes.filter((n) => n.id !== id)
    setNotes(next)
    saveQuickNotes(next)
    setNoteConfirmId(null)
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <>
      <div className="min-h-full pb-32">
        {/* Üst banner */}
        <div
          className="relative overflow-hidden px-8 sm:px-10 pt-10 pb-16 flex items-center"
          style={{ background: 'linear-gradient(135deg, #4338CA 0%, #6D28D9 100%)', minHeight: '232px' }}
        >
          <div className="relative w-full flex items-start justify-between gap-6">
            <div className="min-w-0">
              <p className="text-white/70 text-lg font-semibold">
                {today.toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
              </p>
              <div className="flex items-center gap-3 mt-3">
                <h1 className="text-4xl sm:text-5xl font-extrabold text-white leading-tight">
                  Bugünün Görevleri
                </h1>
                <button
                  onClick={() => setShowInfo(true)}
                  className="w-9 h-9 rounded-full flex items-center justify-center text-white text-lg font-bold shrink-0 transition-all hover:bg-white/10"
                  style={{ border: '2px solid rgba(255,255,255,0.5)' }}
                  title="Bilgi"
                >
                  i
                </button>
              </div>
              <p className="text-white/75 text-xl font-medium mt-2">
                {dayName} · {taskCount === 0 ? 'Bugün için planlanmış görev yok' : `${taskCount} görev planlandı`}
              </p>
            </div>
            {daysLeft !== null && (
              <div
                className="flex flex-col items-center justify-center w-28 h-28 rounded-full shrink-0 self-center"
                style={{ background: 'linear-gradient(135deg, #F97316, #EF4444)', boxShadow: '0 8px 24px rgba(239,68,68,0.4)' }}
              >
                <span className="text-4xl font-extrabold text-white leading-none">{daysLeft}</span>
                <span className="text-white/90 text-xs font-bold tracking-widest mt-1">GÜN</span>
              </div>
            )}
          </div>
        </div>

        <div className="px-8 sm:px-10 pt-8 space-y-8 sm:space-y-12">
          {/* Hedefe Kalan Yol — sadece kullanıcı profilden hedef girdiyse gösterilir */}
          {(() => {
            const tytH = (examGoal?.tytHedef ?? '').trim()
            const aytH = (examGoal?.aytHedef ?? '').trim()
            const hasTyt = tytH.length > 0
            const hasAyt = aytH.length > 0
            if (!hasTyt && !hasAyt) return null
            const line = (hedef: string, net: number | null) =>
              net != null ? `${hedef} — ${net.toFixed(1)} Net` : hedef
            return (
              <div
                className="rounded-3xl p-6 shadow-md"
                style={{ background: 'linear-gradient(135deg, #1E1B4B, #312E81)' }}
              >
                <div className="flex items-center gap-3 mb-4">
                  <span className="text-3xl">🎯</span>
                  <p className="text-2xl font-extrabold text-white">Hedefe Kalan Yol</p>
                </div>
                <div className="space-y-2.5">
                  {hasTyt && (
                    <div>
                      {hasAyt && <p className="text-white/50 text-sm font-bold">TYT</p>}
                      <p className="text-white font-bold text-xl">{line(tytH, examGoal!.tytNet)}</p>
                    </div>
                  )}
                  {hasAyt && (
                    <div>
                      {hasTyt && <p className="text-white/50 text-sm font-bold">AYT</p>}
                      <p className="text-white font-bold text-xl">{line(aytH, examGoal!.aytNet)}</p>
                    </div>
                  )}
                </div>
                <p className="text-indigo-300 text-base font-semibold mt-4">Bas Gaza! 💪</p>
              </div>
            )
          })()}

          {/* Haftalık planı incele */}
          <button
            onClick={() => setShowWeekly(true)}
            className="w-full flex items-center gap-4 p-6 rounded-2xl transition-all hover:opacity-90"
            style={{ background: 'var(--card)', border: '2px solid rgba(79,70,229,0.35)' }}
          >
            <span className="text-4xl">📅</span>
            <span className="flex-1 text-left font-extrabold text-xl" style={{ color: 'var(--primary)' }}>
              Haftalık Planımı İncele
            </span>
            <span className="text-2xl" style={{ color: 'var(--primary)' }}>›</span>
          </button>

          {/* Görev listesi */}
          {loading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-20 rounded-2xl animate-pulse" style={{ background: 'var(--bg)' }} />
              ))}
            </div>
          ) : isRestToday ? (
            <div className="text-center py-16 rounded-3xl" style={{ background: 'var(--card)', border: '1px solid var(--border)' }}>
              <p className="text-5xl mb-3">😴</p>
              <p className="text-lg font-bold" style={{ color: 'var(--text-primary)' }}>Bugün dinlenme günü</p>
              <p className="text-sm mt-1" style={{ color: 'var(--text-hint)' }}>İyileş ve yarın güçlü dön!</p>
              <button
                onClick={disableRestToday}
                className="mt-4 px-6 py-2.5 rounded-xl text-sm font-bold transition-all"
                style={{ background: '#EEF2FF', color: 'var(--primary)' }}
              >
                Dinlenme modunu kapat
              </button>
            </div>
          ) : todayTasks.length === 0 ? (
            <div className="text-center py-16 rounded-3xl" style={{ background: 'var(--card)', border: '1px solid var(--border)' }}>
              <p className="text-5xl mb-3">📥</p>
              <p className="text-lg font-bold" style={{ color: 'var(--text-primary)' }}>Bugün için planlanmış görev yok</p>
              <p className="text-sm mt-1" style={{ color: 'var(--text-hint)' }}>
                Sağ alttaki butona basarak görev ekle ya da haftalık planını incele.
              </p>
            </div>
          ) : (
            <div className="space-y-10">
              {(weakTasks.length > 0 || molaTasks.length > 0) && (
                <section className="space-y-3">
                  <SectionHeader icon="🔥" text="Öncelikli: Zorlandığım Dersler" color="#EF4444" />
                  {priorityTasks.map((t) => (
                    <TaskCard
                      key={t.id}
                      task={t}
                      done={completedIds.has(t.id)}
                      locked={false}
                      topic={topicAssignments[t.id]}
                      onToggle={() => toggleComplete(t)}
                      onStart={() => requestStart(t)}
                      onLockedTap={() => {}}
                    />
                  ))}
                </section>
              )}
              {(generatedStrong.length > 0 || manualTasksList.length > 0) && (
                <section className="space-y-3">
                  <SectionHeader
                    icon="⚡"
                    text="Pekiştirme: Güçlü Dersler"
                    color="#F59E0B"
                    locked={!weakDone}
                  />
                  {generatedStrong.map((t) => (
                    <TaskCard
                      key={t.id}
                      task={t}
                      done={completedIds.has(t.id)}
                      locked={!weakDone}
                      topic={topicAssignments[t.id]}
                      onToggle={() => toggleComplete(t)}
                      onStart={() => requestStart(t)}
                      onLockedTap={() => showToast('Önce zorlandığın dersleri tamamlamalısın 🔥')}
                    />
                  ))}
                  {manualTasksList.map((t) => (
                    <TaskCard
                      key={t.id}
                      task={t}
                      done={completedIds.has(t.id)}
                      locked={false}
                      topic={t.topicName}
                      onToggle={() => toggleComplete(t)}
                      onStart={() => requestStart(t)}
                      onLockedTap={() => {}}
                    />
                  ))}
                </section>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Sol-alt: Not FAB — içerik alanının (sidebar'ın sağı) sol-altında */}
      <button
        onClick={() => setShowNotes(true)}
        className="fixed bottom-6 left-6 lg:left-[304px] w-16 h-16 rounded-full flex items-center justify-center text-3xl shadow-lg transition-all hover:opacity-90 z-40"
        style={{ background: 'linear-gradient(135deg, #F59E0B, #F97316)' }}
        title="Hızlı Not"
      >
        📝
      </button>

      {/* Sağ-alt: +Görev FAB */}
      <button
        onClick={() => setShowAddMenu(true)}
        className="fixed bottom-6 right-6 h-20 px-10 rounded-full flex items-center justify-center gap-2 text-white text-xl font-extrabold shadow-xl transition-all hover:opacity-90 z-40"
        style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
      >
        <span className="text-3xl">+</span> Görev
      </button>

      {/* Toast bildirimi */}
      {toast && (
        <div
          className="fixed bottom-32 left-1/2 -translate-x-1/2 px-8 py-5 rounded-2xl text-white text-lg font-bold shadow-xl z-50"
          style={{ background: 'linear-gradient(135deg, #F97316, #EF4444)' }}
        >
          {toast}
        </div>
      )}

      {/* Modallar */}
      {showAddMenu && (
        <AddTaskMenu
          onClose={() => setShowAddMenu(false)}
          onTopic={() => { setShowAddMenu(false); setShowTopicEditor(true) }}
          onManual={() => { setShowAddMenu(false); setShowManual(true) }}
          onRest={() => { setShowAddMenu(false); setShowRestConfirm(true) }}
        />
      )}
      {showRestConfirm && (
        <RestConfirmModal onClose={() => setShowRestConfirm(false)} onConfirm={enableRestToday} />
      )}
      {showManual && (
        <ManualTaskModal
          subjects={subjectPool}
          onClose={() => setShowManual(false)}
          onAdd={addManualTask}
        />
      )}
      {showTopicEditor && (
        <TopicEditorModal
          plan={plan}
          assignments={topicAssignments}
          onClose={() => setShowTopicEditor(false)}
          onSave={saveTopics}
        />
      )}
      {showWeekly && (
        <WeeklyPlanModal plan={plan} assignments={topicAssignments} onClose={() => setShowWeekly(false)} />
      )}
      {pendingStart && (
        <ModalShell title="Derse Başla" onClose={() => setPendingStart(null)}>
          <div className="text-center">
            <p className="text-5xl mb-3">{pendingStart.emoji}</p>
            <p className="text-xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
              {pendingStart.subjectName}
            </p>
            <p className="text-base mt-1" style={{ color: 'var(--text-secondary)' }}>
              {taskTypeLabel(pendingStart.taskType)} · {pendingStart.durationMinutes} dakika
            </p>
            {(topicAssignments[pendingStart.id] || pendingStart.topicName) && (
              <p className="text-base mt-1" style={{ color: 'var(--primary)' }}>
                Konu: {topicAssignments[pendingStart.id] || pendingStart.topicName}
              </p>
            )}
          </div>
          <div className="flex gap-3 mt-7">
            <button
              onClick={() => setPendingStart(null)}
              className="flex-1 py-3.5 rounded-xl text-base font-semibold"
              style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}
            >
              Vazgeç
            </button>
            <button
              onClick={confirmStart}
              className="flex-1 py-3.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
            >
              ▶ Dersi Başlat
            </button>
          </div>
        </ModalShell>
      )}
      {showInfo && (
        <ModalShell title="ℹ️ Bilgilendirme" onClose={() => setShowInfo(false)}>
          <div className="rounded-2xl p-5" style={{ background: '#1F2937' }}>
            <p className="text-base leading-relaxed text-white">
              Çalışacağın saatleri biz senin biyoritmine göre seçtik, fakat zorunlu
              durumlarda bu saatlere tam uymayabilirsin. Esnek ol!
            </p>
          </div>
        </ModalShell>
      )}
      {showNotes && (
        <ModalShell title="📝 Hızlı Not" subtitle="Aklına geleni hızlıca kaydet" onClose={() => setShowNotes(false)}>
          <div className="space-y-4">
            <div>
              <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>Başlık</label>
              <input
                value={noteTitle}
                onChange={(e) => setNoteTitle(e.target.value)}
                placeholder="Başlık girin..."
                className="w-full h-14 px-4 rounded-xl text-base outline-none"
                style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
                autoFocus
              />
            </div>
            <div>
              <label className="block text-base font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>Not</label>
              <textarea
                value={noteContent}
                onChange={(e) => setNoteContent(e.target.value)}
                placeholder="Aklına geleni yaz..."
                rows={4}
                className="w-full px-4 py-3 rounded-xl text-base outline-none resize-none"
                style={{ background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }}
              />
            </div>
            <button
              onClick={addNote}
              disabled={!noteContent.trim()}
              className="w-full py-3.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90 disabled:opacity-50"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
            >
              ✓ Kaydet
            </button>
          </div>

          {notes.length > 0 && (
            <div className="space-y-2.5 mt-6">
              <p className="text-sm font-bold" style={{ color: 'var(--text-hint)' }}>KAYITLI NOTLAR</p>
              {notes.map((n) => (
                <div
                  key={n.id}
                  className="flex items-start gap-3 px-4 py-3 rounded-xl"
                  style={{ background: 'var(--bg)', border: '1.5px solid var(--border)' }}
                >
                  <div className="flex-1 min-w-0">
                    <p className="text-base font-bold" style={{ color: 'var(--text-primary)' }}>{n.title}</p>
                    <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>{n.content}</p>
                  </div>
                  <button
                    onClick={() => setNoteConfirmId(n.id)}
                    className="w-7 h-7 rounded-full flex items-center justify-center text-sm transition-colors hover:bg-red-100 shrink-0"
                    style={{ color: 'var(--error)' }}
                  >
                    ✕
                  </button>
                </div>
              ))}
            </div>
          )}
        </ModalShell>
      )}

      {/* Not silme onayı */}
      {noteConfirmId && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.6)' }}>
          <div className="w-full max-w-sm rounded-3xl p-7 text-center" style={{ background: 'var(--card)' }}>
            <p className="text-5xl mb-3">🗑️</p>
            <h4 className="text-xl font-extrabold mb-2" style={{ color: 'var(--text-primary)' }}>Notu Sil</h4>
            <p className="text-base mb-6" style={{ color: 'var(--text-secondary)' }}>
              Bu notu silmek istediğine emin misin?
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setNoteConfirmId(null)}
                className="flex-1 py-3.5 rounded-xl text-base font-semibold"
                style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}
              >
                İptal
              </button>
              <button
                onClick={() => deleteNote(noteConfirmId)}
                className="flex-1 py-3.5 rounded-xl text-base font-bold text-white"
                style={{ background: 'var(--error)' }}
              >
                Sil
              </button>
            </div>
          </div>
        </div>
      )}

      {isModalOpen && <StudySessionModal />}
    </>
  )
}

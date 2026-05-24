import { useEffect, useRef, useState, useCallback } from 'react'
import { useStudySessionStore } from '../stores/studySessionStore'
import { getCompletedTaskIds, saveCompletedTaskIds, addCompletedLesson } from '../services/localData'
import { ambientSounds, studyChannels } from '../data/studyWithMe'

const BREAK_MINS = 5

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

function fmt(sec: number): string {
  const m = Math.floor(sec / 60)
  const s = sec % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

// ─── Ortam Sesleri & Çalışma Yayınları kartı ─────────────────────────────────

function StudyWithMeCard() {
  const [expanded, setExpanded] = useState(false)
  const [tab, setTab] = useState<0 | 1>(0)
  const [search, setSearch] = useState('')

  function open(url: string) {
    window.open(url, '_blank', 'noopener,noreferrer')
  }

  function openSearch() {
    const raw = search.trim()
    if (!raw) return
    const url = raw.startsWith('http')
      ? raw
      : `https://www.youtube.com/results?search_query=${encodeURIComponent(raw)}`
    open(url)
  }

  return (
    <div className="rounded-2xl overflow-hidden" style={{ background: '#1E2433', border: '1px solid #2A3350' }}>
      <button
        onClick={() => setExpanded((v) => !v)}
        className="w-full flex items-center gap-3 px-5 py-4"
      >
        <div className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0" style={{ background: '#4F46E5' }}>
          🎧
        </div>
        <div className="flex-1 text-left">
          <p className="text-base font-bold" style={{ color: '#E2E8F0' }}>Ortam Sesleri & Çalışma Yayınları</p>
          <p className="text-sm" style={{ color: '#94A3B8' }}>Odaklanmana yardımcı olur</p>
        </div>
        <span className="text-lg" style={{ color: '#94A3B8' }}>{expanded ? '▲' : '▼'}</span>
      </button>

      {expanded && (
        <div style={{ borderTop: '1px solid #2A3350' }}>
          <div className="flex gap-2 px-5 pt-4">
            {[
              { i: 0 as const, label: '🎵 Ortam Sesleri' },
              { i: 1 as const, label: '▶️ Çalışma Yayınları' },
            ].map((t) => (
              <button
                key={t.i}
                onClick={() => setTab(t.i)}
                className="px-4 py-2 rounded-full text-sm font-semibold transition-all"
                style={{
                  background: tab === t.i ? '#4F46E5' : 'rgba(255,255,255,0.08)',
                  color: tab === t.i ? '#fff' : '#94A3B8',
                }}
              >
                {t.label}
              </button>
            ))}
          </div>

          <div className="px-5 py-4 space-y-1">
            {tab === 0
              ? ambientSounds.map((s) => (
                  <button
                    key={s.name}
                    onClick={() => open(s.url)}
                    className="w-full flex items-center gap-3 py-2.5 text-left"
                  >
                    <span className="text-xl">{s.emoji}</span>
                    <span className="flex-1 text-base font-semibold" style={{ color: '#E2E8F0' }}>{s.name}</span>
                    <span className="text-sm" style={{ color: '#94A3B8' }}>↗</span>
                  </button>
                ))
              : studyChannels.map((ch) => (
                  <button
                    key={ch.name}
                    onClick={() => open(ch.url)}
                    className="w-full flex items-center gap-3 py-2.5 text-left"
                  >
                    <span className="text-xl">{ch.emoji}</span>
                    <div className="flex-1">
                      <p className="text-base font-semibold" style={{ color: '#E2E8F0' }}>{ch.name}</p>
                      <p className="text-sm" style={{ color: '#94A3B8' }}>{ch.description}</p>
                    </div>
                    <span className="text-sm" style={{ color: '#94A3B8' }}>↗</span>
                  </button>
                ))}

            <div className="flex gap-2 pt-3">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && openSearch()}
                placeholder="YouTube linki veya arama..."
                className="flex-1 h-12 px-4 rounded-lg text-base outline-none"
                style={{ background: '#252D40', color: '#E2E8F0', border: 'none' }}
              />
              <button
                onClick={openSearch}
                className="w-12 h-12 rounded-lg flex items-center justify-center text-white text-base shrink-0"
                style={{ background: '#FF0000' }}
              >
                ↗
              </button>
            </div>
            <p className="text-sm pt-2" style={{ color: '#94A3B8' }}>
              💡 Sayaç arka planda çalışmaya devam eder.
            </p>
          </div>
        </div>
      )}
    </div>
  )
}

// ─── Çalışma ekranı ───────────────────────────────────────────────────────────

export default function StudySessionModal() {
  const { activeTask, close } = useStudySessionStore()

  const totalStudySec = (activeTask?.durationMinutes ?? 25) * 60
  const [isBreak, setIsBreak] = useState(false)
  const [secondsLeft, setSecondsLeft] = useState(totalStudySec)
  const [breakSeconds, setBreakSeconds] = useState(BREAK_MINS * 60)
  const [isRunning, setIsRunning] = useState(true)
  const [showFinishConfirm, setShowFinishConfirm] = useState(false)
  const [showDone, setShowDone] = useState(false)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const totalSeconds = isBreak ? BREAK_MINS * 60 : totalStudySec
  const shown = isBreak ? breakSeconds : secondsLeft
  const progress = 1 - shown / totalSeconds
  const radius = 130
  const circumference = 2 * Math.PI * radius
  const strokeDash = circumference * (1 - progress)

  const markComplete = useCallback(() => {
    if (activeTask && !activeTask.isMola) {
      const ids = getCompletedTaskIds()
      ids.add(activeTask.id)
      saveCompletedTaskIds(ids)
      const today = new Date()
      const dateStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`
      addCompletedLesson(dateStr, {
        id: activeTask.id,
        subjectName: activeTask.subjectName,
        emoji: activeTask.emoji,
        taskType: activeTask.taskType,
        durationMinutes: activeTask.durationMinutes,
      })
    }
  }, [activeTask])

  // Çalışma süresi dolunca → görev tamamlanır
  const onStudyComplete = useCallback(() => {
    markComplete()
    setIsRunning(false)
    setShowDone(true)
  }, [markComplete])

  useEffect(() => {
    if (!isRunning) return
    intervalRef.current = setInterval(() => {
      if (isBreak) {
        setBreakSeconds((s) => {
          if (s <= 1) {
            setIsBreak(false)
            return BREAK_MINS * 60
          }
          return s - 1
        })
      } else {
        setSecondsLeft((s) => {
          if (s <= 1) {
            onStudyComplete()
            return 0
          }
          return s - 1
        })
      }
    }, 1000)
    return () => { if (intervalRef.current) clearInterval(intervalRef.current) }
  }, [isRunning, isBreak, onStudyComplete])

  if (!activeTask) return null

  const bg = isBreak ? '#1B4332' : '#1A1A2E'

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.75)' }}>
      <div
        className="w-full max-w-2xl rounded-3xl shadow-2xl overflow-y-auto max-h-[95vh]"
        style={{ background: bg }}
      >
        <div className="p-8">
          {/* Üst bar */}
          <div className="flex items-center justify-between mb-6">
            <button
              onClick={() => setShowFinishConfirm(true)}
              className="w-11 h-11 flex items-center justify-center rounded-full text-white text-2xl"
              style={{ background: 'rgba(255,255,255,0.12)' }}
            >
              ‹
            </button>
            <div
              className="px-5 py-2.5 rounded-full flex items-center gap-2"
              style={{ background: 'rgba(255,255,255,0.15)' }}
            >
              <span className="text-base">{isBreak ? '⏸' : '🔥'}</span>
              <span className="text-white text-base font-semibold">{isBreak ? 'Mola' : 'Odaklanıyor'}</span>
            </div>
            <div className="w-11" />
          </div>

          {/* Başlık */}
          <h3 className="text-white text-2xl sm:text-3xl font-extrabold mb-1">
            {activeTask.subjectName}
          </h3>
          <p className="text-white/60 text-lg mb-6">{taskTypeLabel(activeTask.taskType)}</p>

          {/* Ortam sesleri (sadece çalışma modu) */}
          {!isBreak && (
            <div className="mb-6">
              <StudyWithMeCard />
            </div>
          )}

          {/* Timer ring */}
          <div className="flex justify-center mb-6">
            <div className="relative" style={{ width: 300, height: 300 }}>
              <svg width="300" height="300" className="-rotate-90">
                <circle cx="150" cy="150" r={radius} fill="none" stroke="rgba(255,255,255,0.1)" strokeWidth="16" />
                <circle
                  cx="150" cy="150" r={radius} fill="none"
                  stroke={isBreak ? '#10B981' : '#F59E0B'}
                  strokeWidth="16"
                  strokeLinecap="round"
                  strokeDasharray={circumference}
                  strokeDashoffset={strokeDash}
                  style={{ transition: 'stroke-dashoffset 1s linear' }}
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-7xl font-light text-white tracking-wider">
                  {fmt(shown)}
                </span>
                {isBreak && (
                  <span
                    className="mt-3 px-4 py-1.5 rounded-full text-sm font-semibold"
                    style={{ background: 'rgba(16,185,129,0.25)', color: '#6EE7B7' }}
                  >
                    Nefes Al
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Mola bilgi kartı */}
          {isBreak && (
            <div
              className="flex items-center gap-4 px-5 py-4 rounded-2xl mb-6"
              style={{ background: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.12)' }}
            >
              <span className="text-2xl">🧘</span>
              <div className="flex-1">
                <p className="text-white text-base font-bold">Acil Durum Molası</p>
                <p className="text-white/60 text-sm">Kalan: {fmt(breakSeconds)}</p>
              </div>
              <button
                onClick={() => { setIsBreak(false); setBreakSeconds(BREAK_MINS * 60) }}
                className="px-4 py-2 rounded-xl text-base font-bold"
                style={{ color: '#6EE7B7' }}
              >
                Atla
              </button>
            </div>
          )}

          {/* Kontroller */}
          <div className="flex items-center justify-center gap-8">
            {/* Duraklat/Devam */}
            <button
              onClick={() => setIsRunning((r) => !r)}
              className="flex flex-col items-center gap-2"
            >
              <div
                className="w-20 h-20 rounded-full flex items-center justify-center text-3xl"
                style={{ background: 'rgba(255,255,255,0.15)' }}
              >
                {isRunning ? '⏸' : '▶'}
              </div>
              <span className="text-white/70 text-sm">{isRunning ? 'Duraklat' : 'Devam'}</span>
            </button>

            {/* Mola (sadece çalışma modunda) */}
            {!isBreak && (
              <button
                onClick={() => { setIsBreak(true); setBreakSeconds(BREAK_MINS * 60) }}
                className="flex flex-col items-center gap-2"
              >
                <div
                  className="w-20 h-20 rounded-full flex items-center justify-center text-3xl"
                  style={{ background: 'rgba(255,255,255,0.15)' }}
                >
                  🧘
                </div>
                <span className="text-white/70 text-sm">Mola</span>
              </button>
            )}

            {/* Bitir */}
            <button
              onClick={() => setShowFinishConfirm(true)}
              className="flex flex-col items-center gap-2"
            >
              <div
                className="w-20 h-20 rounded-full flex items-center justify-center text-3xl"
                style={{ background: 'rgba(255,255,255,0.15)' }}
              >
                ⏹
              </div>
              <span className="text-white/70 text-sm">Bitir</span>
            </button>
          </div>
        </div>
      </div>

      {/* Bitir onayı */}
      {showFinishConfirm && (
        <div className="fixed inset-0 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.6)' }}>
          <div className="w-full max-w-md rounded-3xl p-7" style={{ background: 'var(--card)' }}>
            <h4 className="text-xl font-extrabold mb-3" style={{ color: 'var(--text-primary)' }}>Çalışmayı Bitir?</h4>
            <p className="text-base mb-6" style={{ color: 'var(--text-secondary)' }}>
              Süre dolmadan bitirirsen görev tamamlanmış sayılmaz. Emin misin?
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowFinishConfirm(false)}
                className="flex-1 py-3.5 rounded-xl text-base font-semibold"
                style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}
              >
                İptal
              </button>
              <button
                onClick={close}
                className="flex-1 py-3.5 rounded-xl text-base font-bold text-white"
                style={{ background: '#EF4444' }}
              >
                Evet, Bitir
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Tamamlandı */}
      {showDone && (
        <div className="fixed inset-0 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.6)' }}>
          <div className="w-full max-w-md rounded-3xl p-7 text-center" style={{ background: 'var(--card)' }}>
            <p className="text-5xl mb-3">🎉</p>
            <h4 className="text-2xl font-extrabold mb-2" style={{ color: 'var(--text-primary)' }}>Harika!</h4>
            <p className="text-base mb-6" style={{ color: 'var(--text-secondary)' }}>
              {activeTask.subjectName} görevini tamamladın! Devam et! 💪
            </p>
            <button
              onClick={close}
              className="w-full py-3.5 rounded-xl text-base font-bold text-white"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
            >
              Devam
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

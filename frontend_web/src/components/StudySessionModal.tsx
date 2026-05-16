import { useEffect, useRef, useState, useCallback } from 'react'
import { useStudySessionStore } from '../stores/studySessionStore'

const POMODORO_MINS = 25
const BREAK_MINS = 5

export default function StudySessionModal() {
  const { activeTask, close } = useStudySessionStore()
  const [secondsLeft, setSecondsLeft] = useState(POMODORO_MINS * 60)
  const [isRunning, setIsRunning] = useState(false)
  const [isBreak, setIsBreak] = useState(false)
  const [sessions, setSessions] = useState(0)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const totalSeconds = isBreak ? BREAK_MINS * 60 : POMODORO_MINS * 60
  const progress = 1 - secondsLeft / totalSeconds
  const radius = 80
  const circumference = 2 * Math.PI * radius
  const strokeDash = circumference * (1 - progress)

  const mins = String(Math.floor(secondsLeft / 60)).padStart(2, '0')
  const secs = String(secondsLeft % 60).padStart(2, '0')

  const finish = useCallback(() => {
    setIsRunning(false)
    if (!isBreak) {
      setSessions((s) => s + 1)
      setIsBreak(true)
      setSecondsLeft(BREAK_MINS * 60)
    } else {
      setIsBreak(false)
      setSecondsLeft(POMODORO_MINS * 60)
    }
  }, [isBreak])

  useEffect(() => {
    if (isRunning) {
      intervalRef.current = setInterval(() => {
        setSecondsLeft((s) => {
          if (s <= 1) { finish(); return 0 }
          return s - 1
        })
      }, 1000)
    }
    return () => { if (intervalRef.current) clearInterval(intervalRef.current) }
  }, [isRunning, finish])

  function reset() {
    setIsRunning(false)
    setIsBreak(false)
    setSecondsLeft(POMODORO_MINS * 60)
  }

  if (!activeTask) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.5)' }}>
      <div
        className="w-full max-w-sm rounded-3xl p-6 shadow-2xl"
        style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
      >
        {/* Header */}
        <div className="flex items-center justify-between mb-5">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: 'var(--text-secondary)' }}>
              {isBreak ? '☕ Mola' : '📚 Ders Çalışma'}
            </p>
            <p className="font-bold text-base mt-0.5" style={{ color: 'var(--text-primary)' }}>
              {activeTask.emoji} {activeTask.subjectName}
            </p>
          </div>
          <button
            onClick={close}
            className="w-8 h-8 flex items-center justify-center rounded-full text-sm"
            style={{ background: 'var(--bg)', color: 'var(--text-secondary)' }}
          >
            ✕
          </button>
        </div>

        {/* Ring Timer */}
        <div className="flex justify-center mb-6">
          <div className="relative" style={{ width: 200, height: 200 }}>
            <svg width="200" height="200" className="-rotate-90">
              <circle cx="100" cy="100" r={radius} fill="none" stroke="var(--bg)" strokeWidth="12" />
              <circle
                cx="100" cy="100" r={radius} fill="none"
                stroke={isBreak ? '#10B981' : '#4F46E5'}
                strokeWidth="12"
                strokeLinecap="round"
                strokeDasharray={circumference}
                strokeDashoffset={strokeDash}
                style={{ transition: 'stroke-dashoffset 1s linear' }}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-4xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                {mins}:{secs}
              </span>
              <span className="text-xs mt-1" style={{ color: 'var(--text-secondary)' }}>
                {sessions} 🍅 tamamlandı
              </span>
            </div>
          </div>
        </div>

        {/* Controls */}
        <div className="flex gap-3 justify-center">
          <button
            onClick={reset}
            className="px-4 py-2.5 rounded-xl text-sm font-semibold"
            style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1px solid var(--border)' }}
          >
            ↺ Sıfırla
          </button>
          <button
            onClick={() => setIsRunning((r) => !r)}
            className="flex-1 py-2.5 rounded-xl text-sm font-bold text-white transition-all hover:opacity-90"
            style={{ background: isBreak ? 'linear-gradient(135deg, #10B981, #059669)' : 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
          >
            {isRunning ? '⏸ Duraklat' : '▶ Başlat'}
          </button>
          <button
            onClick={close}
            className="px-4 py-2.5 rounded-xl text-sm font-semibold"
            style={{ background: '#FEF2F2', color: '#EF4444' }}
          >
            ⏹ Bitir
          </button>
        </div>
      </div>
    </div>
  )
}

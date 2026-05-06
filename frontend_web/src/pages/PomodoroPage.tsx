import { useEffect, useRef, useState } from 'react'
import api from '../services/api'

interface Topic { id: number; name: string }
interface Lesson { id: number; name: string; colorCode: string; topics: Topic[] }

function parseColor(hex: string | undefined) {
  if (!hex) return '#4F46E5'
  return hex.startsWith('#') ? hex : `#${hex}`
}

function pad(n: number) { return String(n).padStart(2, '0') }

export default function PomodoroPage() {
  const [workMin, setWorkMin]     = useState(25)
  const [breakMin, setBreakMin]   = useState(5)
  const [timeLeft, setTimeLeft]   = useState(25 * 60)
  const [running, setRunning]     = useState(false)
  const [isWork, setIsWork]       = useState(true)
  const [lessons, setLessons]     = useState<Lesson[]>([])
  const [selLesson, setSelLesson] = useState<Lesson | null>(null)
  const [selTopic, setSelTopic]   = useState<Topic | null>(null)
  const [saved, setSaved]         = useState(false)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  useEffect(() => {
    api.get('/Lesson').then((r) => setLessons(r.data)).catch(() => {})
  }, [])

  useEffect(() => {
    document.title = `${pad(Math.floor(timeLeft / 60))}:${pad(timeLeft % 60)} | Pomodoro`
    return () => { document.title = 'AI Study Coach' }
  }, [timeLeft])

  function start() {
    if (running) return
    setRunning(true)
    intervalRef.current = setInterval(() => {
      setTimeLeft((t) => {
        if (t <= 1) {
          clearInterval(intervalRef.current!)
          setRunning(false)
          onComplete()
          return 0
        }
        return t - 1
      })
    }, 1000)
  }

  function pause() {
    clearInterval(intervalRef.current!)
    setRunning(false)
  }

  function reset() {
    clearInterval(intervalRef.current!)
    setRunning(false)
    setTimeLeft((isWork ? workMin : breakMin) * 60)
    setSaved(false)
  }

  function switchMode(toWork: boolean) {
    clearInterval(intervalRef.current!)
    setRunning(false)
    setIsWork(toWork)
    setTimeLeft((toWork ? workMin : breakMin) * 60)
    setSaved(false)
  }

  async function onComplete() {
    if (isWork && selTopic) {
      try {
        await api.post('/StudySession', {
          topicId: selTopic.id,
          durationMinutes: workMin,
          type: 'pomodoro',
          date: new Date().toISOString(),
        })
        setSaved(true)
      } catch { /* noop */ }
    }
    setTimeout(() => switchMode(!isWork), 800)
  }

  const total   = (isWork ? workMin : breakMin) * 60
  const pct     = timeLeft / total
  const radius  = 90
  const circ    = 2 * Math.PI * radius
  const stroke  = circ * (1 - pct)
  const color   = isWork ? '#4F46E5' : '#10B981'

  return (
    <div className="p-6 max-w-lg mx-auto">
      <h1 className="text-2xl font-extrabold text-gray-900 mb-6">Pomodoro</h1>

      {/* Mode toggle */}
      <div className="flex gap-2 mb-8 bg-gray-100 rounded-full p-1">
        <button
          onClick={() => switchMode(true)}
          className={`flex-1 py-2 rounded-full text-sm font-bold transition ${isWork ? 'bg-white text-indigo-700 shadow' : 'text-gray-500'}`}
        >Çalışma</button>
        <button
          onClick={() => switchMode(false)}
          className={`flex-1 py-2 rounded-full text-sm font-bold transition ${!isWork ? 'bg-white text-emerald-700 shadow' : 'text-gray-500'}`}
        >Mola</button>
      </div>

      {/* Timer circle */}
      <div className="flex justify-center mb-8">
        <div className="relative">
          <svg width="220" height="220" className="-rotate-90">
            <circle cx="110" cy="110" r={radius} fill="none" stroke="#F3F4F6" strokeWidth="14" />
            <circle
              cx="110" cy="110" r={radius}
              fill="none"
              stroke={color}
              strokeWidth="14"
              strokeLinecap="round"
              strokeDasharray={circ}
              strokeDashoffset={stroke}
              style={{ transition: 'stroke-dashoffset 0.5s ease' }}
            />
          </svg>
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-5xl font-black tabular-nums" style={{ color }}>
              {pad(Math.floor(timeLeft / 60))}:{pad(timeLeft % 60)}
            </span>
            <span className="text-sm text-gray-400 font-medium mt-1">
              {isWork ? 'Çalışma' : 'Mola'}
            </span>
            {saved && <span className="text-xs text-emerald-500 font-semibold mt-1">✓ Kaydedildi</span>}
          </div>
        </div>
      </div>

      {/* Controls */}
      <div className="flex justify-center gap-4 mb-8">
        <button
          onClick={reset}
          className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200 transition text-xl"
        >↺</button>
        <button
          onClick={running ? pause : start}
          className="w-16 h-16 rounded-full text-white text-2xl flex items-center justify-center shadow-lg transition hover:opacity-90"
          style={{ backgroundColor: color }}
        >
          {running ? '⏸' : '▶'}
        </button>
        <button
          onClick={() => switchMode(!isWork)}
          className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200 transition text-xl"
        >⏭</button>
      </div>

      {/* Duration settings */}
      <div className="flex gap-4 mb-6">
        <div className="flex-1 bg-white rounded-xl border border-gray-100 p-3 text-center">
          <p className="text-xs text-gray-400 mb-2">Çalışma (dk)</p>
          <div className="flex items-center justify-center gap-3">
            <button onClick={() => { if (workMin > 5) { setWorkMin(w => w - 5); if (isWork && !running) setTimeLeft((workMin - 5) * 60) } }} className="text-gray-400 hover:text-gray-700 font-bold">−</button>
            <span className="font-extrabold text-indigo-600 w-8 text-center">{workMin}</span>
            <button onClick={() => { if (workMin < 60) { setWorkMin(w => w + 5); if (isWork && !running) setTimeLeft((workMin + 5) * 60) } }} className="text-gray-400 hover:text-gray-700 font-bold">+</button>
          </div>
        </div>
        <div className="flex-1 bg-white rounded-xl border border-gray-100 p-3 text-center">
          <p className="text-xs text-gray-400 mb-2">Mola (dk)</p>
          <div className="flex items-center justify-center gap-3">
            <button onClick={() => { if (breakMin > 1) { setBreakMin(b => b - 1); if (!isWork && !running) setTimeLeft((breakMin - 1) * 60) } }} className="text-gray-400 hover:text-gray-700 font-bold">−</button>
            <span className="font-extrabold text-emerald-600 w-8 text-center">{breakMin}</span>
            <button onClick={() => { if (breakMin < 30) { setBreakMin(b => b + 1); if (!isWork && !running) setTimeLeft((breakMin + 1) * 60) } }} className="text-gray-400 hover:text-gray-700 font-bold">+</button>
          </div>
        </div>
      </div>

      {/* Lesson/Topic selector */}
      <div className="bg-white rounded-xl border border-gray-100 p-4">
        <p className="text-sm font-semibold text-gray-700 mb-3">Ders & Konu</p>
        <div className="flex gap-2 mb-3">
          <select
            value={selLesson?.id ?? ''}
            onChange={(e) => {
              const l = lessons.find((l) => l.id === Number(e.target.value)) ?? null
              setSelLesson(l)
              setSelTopic(null)
            }}
            className="flex-1 px-3 py-2 text-sm rounded-lg border border-gray-200 outline-none focus:border-indigo-400"
          >
            <option value="">Ders seç...</option>
            {lessons.map((l) => (
              <option key={l.id} value={l.id}>{l.name}</option>
            ))}
          </select>
          {selLesson && (
            <select
              value={selTopic?.id ?? ''}
              onChange={(e) => {
                const t = selLesson.topics.find((t) => t.id === Number(e.target.value)) ?? null
                setSelTopic(t)
              }}
              className="flex-1 px-3 py-2 text-sm rounded-lg border border-gray-200 outline-none focus:border-indigo-400"
            >
              <option value="">Konu seç...</option>
              {selLesson.topics.map((t) => (
                <option key={t.id} value={t.id}>{t.name}</option>
              ))}
            </select>
          )}
        </div>
        {selTopic ? (
          <div className="flex items-center gap-2 text-sm">
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: parseColor(selLesson?.colorCode) }} />
            <span className="text-gray-600">{selLesson?.name} → <strong>{selTopic.name}</strong></span>
          </div>
        ) : (
          <p className="text-xs text-gray-400">Konu seçersen oturum otomatik kaydedilir.</p>
        )}
      </div>
    </div>
  )
}

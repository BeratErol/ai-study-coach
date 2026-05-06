import { useEffect, useState } from 'react'
import api from '../services/api'
import { getUserName } from '../hooks/useAuth'

interface CoachData {
  greeting: string
  todayFocus: string
  weakAreaWarning: string
  motivationNote: string
  actionItems: string[]
}

interface LessonData {
  id: number
  name: string
  colorCode: string
  topics: { isCompleted: boolean }[]
}

interface WeeklySummary {
  totalMinutes: number
  totalSessions: number
  pomodoroCount: number
}

interface ExamData {
  id: number
  totalNet: number
  date: string
}

function parseColor(hex: string | undefined): string {
  if (!hex) return '#4F46E5'
  return hex.startsWith('#') ? hex : `#${hex}`
}

function fmtMinutes(minutes: number): string {
  if (minutes < 60) return `${minutes}dk`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m > 0 ? `${h}s ${m}dk` : `${h}s`
}

function StatCardSkeleton() {
  return (
    <div className="bg-white rounded-xl p-4 border border-gray-100 animate-pulse">
      <div className="w-9 h-9 rounded-lg bg-gray-200 mb-3" />
      <div className="h-6 w-16 bg-gray-200 rounded mb-1" />
      <div className="h-3 w-24 bg-gray-100 rounded" />
    </div>
  )
}

function StatCard({
  label,
  value,
  icon,
  color,
}: {
  label: string
  value: string
  icon: string
  color: string
}) {
  return (
    <div className="bg-white rounded-xl p-4 border border-gray-100">
      <div
        className="w-9 h-9 rounded-lg flex items-center justify-center text-base mb-3"
        style={{ backgroundColor: `${color}1A` }}
      >
        {icon}
      </div>
      <p className="text-xl font-extrabold text-gray-900">{value}</p>
      <p className="text-xs text-gray-500 mt-0.5">{label}</p>
    </div>
  )
}

export default function DashboardPage() {
  const userName = getUserName()

  const [coach, setCoach]           = useState<CoachData | null>(null)
  const [lessons, setLessons]       = useState<LessonData[]>([])
  const [weekly, setWeekly]         = useState<WeeklySummary | null>(null)
  const [lastExam, setLastExam]     = useState<ExamData | null>(null)
  const [coachLoading, setCoachLoading] = useState(true)
  const [dataLoading, setDataLoading]   = useState(true)

  useEffect(() => {
    api.get('/Ai/dashboard-coach')
      .then((r) => setCoach(r.data))
      .catch(() => {})
      .finally(() => setCoachLoading(false))

    Promise.all([
      api.get('/Lesson').then((r) => setLessons(r.data)).catch(() => {}),
      api.get('/StudySession/weekly-summary').then((r) => setWeekly(r.data)).catch(() => {}),
      api.get('/Exam').then((r) => {
        const exams: ExamData[] = r.data
        if (exams.length > 0) {
          const sorted = [...exams].sort(
            (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
          )
          setLastExam(sorted[0])
        }
      }).catch(() => {}),
    ]).finally(() => setDataLoading(false))
  }, [])

  const totalDone = lessons.reduce(
    (s, l) => s + l.topics.filter((t) => t.isCompleted).length,
    0
  )
  const totalTopics = lessons.reduce((s, l) => s + l.topics.length, 0)

  return (
    <div className="p-6 max-w-4xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-extrabold text-gray-900">
          Merhaba, {userName || 'Öğrenci'} 👋
        </h1>
        <p className="text-gray-500 text-sm mt-1">
          {new Date().toLocaleDateString('tr-TR', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric',
          })}
        </p>
      </div>

      {/* AI Coach Card */}
      {coachLoading ? (
        <div className="rounded-2xl p-6 mb-6 h-40 animate-pulse bg-gray-200" />
      ) : coach ? (
        <div
          className="rounded-2xl p-6 mb-6 text-white"
          style={{ background: 'linear-gradient(135deg, #312E81, #4F46E5, #6D28D9)' }}
        >
          <div className="flex items-center gap-2 mb-3">
            <span className="text-yellow-300 text-sm">✨</span>
            <span className="text-white/70 text-xs font-semibold uppercase tracking-wide">AI Koç</span>
          </div>
          <p className="text-lg font-bold mb-1">{coach.greeting}</p>
          <p className="text-white/80 text-sm mb-3">{coach.todayFocus}</p>
          {coach.weakAreaWarning && (
            <div className="bg-white/10 rounded-xl px-4 py-2 mb-3 text-sm">
              ⚠️ {coach.weakAreaWarning}
            </div>
          )}
          <div className="flex flex-wrap gap-2">
            {coach.actionItems.map((item, i) => (
              <span key={i} className="bg-white/15 text-white text-xs px-3 py-1.5 rounded-full font-medium">
                {item}
              </span>
            ))}
          </div>
          <p className="text-white/60 text-xs mt-4 italic">{coach.motivationNote}</p>
        </div>
      ) : (
        <div className="rounded-2xl p-6 mb-6 bg-indigo-50 border border-indigo-100 text-indigo-700 text-sm">
          AI Koç verisi yüklenemedi. Backend çalışıyor mu?
        </div>
      )}

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
        {dataLoading ? (
          <>
            <StatCardSkeleton />
            <StatCardSkeleton />
            <StatCardSkeleton />
            <StatCardSkeleton />
          </>
        ) : (
          <>
            <StatCard
              label="Bu Hafta"
              value={weekly ? fmtMinutes(weekly.totalMinutes) : '—'}
              icon="⏱️"
              color="#F59E0B"
            />
            <StatCard
              label="Toplam Ders"
              value={`${lessons.length}`}
              icon="📚"
              color="#4F46E5"
            />
            <StatCard
              label="Konu"
              value={`${totalDone}/${totalTopics}`}
              icon="✅"
              color="#10B981"
            />
            <StatCard
              label="Son Net"
              value={lastExam ? lastExam.totalNet.toFixed(1) : '—'}
              icon="📊"
              color="#8B5CF6"
            />
          </>
        )}
      </div>

      {/* Lessons */}
      <div>
        <h2 className="text-lg font-bold text-gray-900 mb-3">Derslerim</h2>
        {dataLoading ? (
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-16 rounded-xl bg-gray-100 animate-pulse" />
            ))}
          </div>
        ) : lessons.length === 0 ? (
          <div className="text-center py-10 text-gray-400">
            <p className="text-4xl mb-3">📚</p>
            <p className="font-semibold">Henüz ders eklenmedi</p>
          </div>
        ) : (
          <div className="space-y-3">
            {lessons.map((lesson) => {
              const total    = lesson.topics.length
              const done     = lesson.topics.filter((t) => t.isCompleted).length
              const progress = total > 0 ? done / total : 0
              const color    = parseColor(lesson.colorCode)
              return (
                <div
                  key={lesson.id}
                  className="bg-white rounded-xl p-4 border flex items-center gap-4"
                  style={{ borderColor: `${color}33` }}
                >
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center text-white text-base flex-shrink-0"
                    style={{ backgroundColor: color }}
                  >
                    📖
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-gray-900 text-sm truncate">{lesson.name}</p>
                    <p className="text-xs text-gray-500 mb-1.5">{done} / {total} konu</p>
                    <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all"
                        style={{ width: `${progress * 100}%`, backgroundColor: color }}
                      />
                    </div>
                  </div>
                  <span className="text-sm font-bold" style={{ color }}>
                    {Math.round(progress * 100)}%
                  </span>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}

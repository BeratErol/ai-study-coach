import { useEffect, useState } from 'react'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
} from 'recharts'
import {
  gelisimimService,
  type GelisimimStats as Stats,
  type XpInfo,
  type ActivityDay,
  type LessonDist,
} from '../services/gelisimimService'

// ─── Constants ────────────────────────────────────────────────────────────────

const PIE_COLORS = [
  '#4F46E5', '#6D28D9', '#10B981', '#F59E0B',
  '#EF4444', '#EC4899', '#06B6D4', '#8B5CF6',
  '#F97316', '#14B8A6',
]

const TR_WEEKDAY_SHORT: Record<string, string> = {
  Mon: 'Pzt', Tue: 'Sal', Wed: 'Çar', Thu: 'Per',
  Fri: 'Cum', Sat: 'Cmt', Sun: 'Paz',
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function fmtMinutes(m: number): string {
  if (!m) return '0dk'
  if (m < 60) return `${m}dk`
  const h = Math.floor(m / 60)
  const rem = m % 60
  return rem ? `${h}s ${rem}dk` : `${h}s`
}

function toTrShort(date: string): string {
  const d = new Date(date)
  const en = d.toLocaleDateString('en-US', { weekday: 'short' })
  return TR_WEEKDAY_SHORT[en] ?? en
}

// ─── Custom Tooltip ───────────────────────────────────────────────────────────

interface BarTooltipProps {
  active?: boolean
  payload?: { value: number }[]
  label?: string
}

function CustomBarTooltip({ active, payload, label }: BarTooltipProps) {
  if (!active || !payload?.length) return null
  return (
    <div
      className="rounded-xl px-4 py-3 shadow-lg text-sm"
      style={{
        background: 'var(--card)',
        border: '1px solid var(--border)',
        color: 'var(--text-primary)',
      }}
    >
      <p className="font-bold mb-0.5">{label}</p>
      <p style={{ color: '#4F46E5' }}>
        <span className="font-extrabold">{payload[0].value}</span> dakika
      </p>
    </div>
  )
}

// ─── Loading Skeleton ─────────────────────────────────────────────────────────

function Skeleton({ className, style }: { className?: string; style?: React.CSSProperties }) {
  return (
    <div
      className={`animate-pulse rounded-xl ${className ?? ''}`}
      style={{ background: 'var(--border)', ...style }}
    />
  )
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function GelisimimPage() {
  const [filter, setFilter]     = useState<'all' | 'today'>('all')
  const [stats, setStats]       = useState<Stats | null>(null)
  const [xp, setXp]             = useState<XpInfo | null>(null)
  const [activity, setActivity] = useState<ActivityDay[]>([])
  const [dist, setDist]         = useState<LessonDist[]>([])
  const [loading, setLoading]   = useState(true)

  useEffect(() => {
    setLoading(true)
    Promise.all([
      gelisimimService.getStats(filter).then(setStats).catch(() => {}),
      gelisimimService.getXpInfo().then(setXp).catch(() => {}),
      gelisimimService.getWeeklyActivity().then(setActivity).catch(() => {}),
      gelisimimService.getLessonDistribution(filter).then(setDist).catch(() => {}),
    ]).finally(() => setLoading(false))
  }, [filter])

  const xpProgress = xp
    ? Math.min(1, xp.currentXp / Math.max(1, xp.xpForNextLevel))
    : 0

  const barData = activity.map((d) => ({
    name: toTrShort(d.date),
    dakika: d.totalMinutes,
  }))

  const statCards = [
    {
      icon: '✅',
      label: 'Tamamlanan Görev',
      value: stats?.totalCompletedTasks != null ? String(stats.totalCompletedTasks) : '—',
      color: '#10B981',
      gradient: 'linear-gradient(135deg, #10B981, #059669)',
      bgLight: '#F0FDF4',
    },
    {
      icon: '⏱️',
      label: 'Çalışma Süresi',
      value: stats ? fmtMinutes(stats.totalStudyMinutes) : '—',
      color: '#4F46E5',
      gradient: 'linear-gradient(135deg, #4F46E5, #6D28D9)',
      bgLight: '#EEF2FF',
    },
    {
      icon: '❓',
      label: 'Toplam Soru',
      value: stats?.totalQuestions != null ? String(stats.totalQuestions) : '—',
      color: '#F59E0B',
      gradient: 'linear-gradient(135deg, #F59E0B, #D97706)',
      bgLight: '#FFFBEB',
    },
    {
      icon: '🍅',
      label: 'Pomodoro',
      value: stats?.totalPomodoros != null ? String(stats.totalPomodoros) : '—',
      color: '#EF4444',
      gradient: 'linear-gradient(135deg, #EF4444, #DC2626)',
      bgLight: '#FEF2F2',
    },
  ]

  return (
    <div className="min-h-full">
      {/* ── XP Gradient Header ───────────────────────────────────────────────── */}
      <div
        className="relative overflow-hidden px-10 pt-12 pb-16"
        style={{ background: 'linear-gradient(135deg, #059669 0%, #10B981 60%, #34D399 100%)' }}
      >
        {/* Decorative blobs */}
        <div
          className="absolute -top-12 -right-12 w-56 h-56 rounded-full opacity-10"
          style={{ background: '#fff' }}
        />
        <div
          className="absolute -bottom-16 -left-8 w-48 h-48 rounded-full opacity-10"
          style={{ background: '#fff' }}
        />

        <div className="relative flex flex-col lg:flex-row lg:items-center gap-6">
          {/* Title */}
          <div className="flex-1">
            <h1 className="text-5xl sm:text-6xl font-extrabold text-white leading-tight mb-2">
              📈 Gelişimim
            </h1>
            <p className="text-white/70 text-lg">İlerleme, istatistik ve aktivitelerine genel bakış</p>
          </div>

          {/* XP info block */}
          {loading ? (
            <div className="flex items-center gap-4 p-5 rounded-2xl" style={{ background: 'rgba(255,255,255,0.15)' }}>
              <Skeleton style={{ width: 56, height: 56, borderRadius: 16 }} />
              <div className="space-y-2">
                <Skeleton style={{ width: 140, height: 18 }} />
                <Skeleton style={{ width: 200, height: 10, borderRadius: 999 }} />
                <Skeleton style={{ width: 100, height: 12 }} />
              </div>
            </div>
          ) : xp ? (
            <div
              className="flex flex-col sm:flex-row items-start sm:items-center gap-5 px-6 py-5 rounded-2xl"
              style={{ background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.25)' }}
            >
              {/* Level icon */}
              <div
                className="w-16 h-16 rounded-2xl flex items-center justify-center text-3xl shrink-0"
                style={{ background: 'rgba(255,255,255,0.2)' }}
              >
                {xp.levelEmoji}
              </div>

              {/* Level + progress */}
              <div className="flex-1 min-w-0" style={{ minWidth: 220 }}>
                <div className="flex items-center gap-2 mb-0.5">
                  <p className="text-white font-extrabold text-xl">
                    Seviye {xp.level}
                  </p>
                  <span
                    className="px-2.5 py-0.5 rounded-full text-xs font-bold"
                    style={{ background: 'rgba(255,255,255,0.25)', color: '#fff' }}
                  >
                    {xp.levelName}
                  </span>
                </div>
                <p className="text-white/70 text-sm mb-2">
                  {xp.currentXp.toLocaleString('tr-TR')} / {xp.xpForNextLevel.toLocaleString('tr-TR')} XP
                </p>
                {/* Progress bar */}
                <div className="h-3 rounded-full overflow-hidden" style={{ background: 'rgba(0,0,0,0.2)' }}>
                  <div
                    className="h-full rounded-full transition-all duration-700"
                    style={{
                      width: `${xpProgress * 100}%`,
                      background: 'linear-gradient(90deg, #FCD34D, #FBBF24)',
                    }}
                  />
                </div>
                <p className="text-white/60 text-xs mt-1.5">
                  %{Math.round(xpProgress * 100)} — sonraki seviyeye {xp.xpForNextLevel - xp.currentXp} XP
                </p>
              </div>

              {/* Streak */}
              {xp.streakDays > 0 && (
                <>
                  <div className="hidden sm:block h-14 w-px" style={{ background: 'rgba(255,255,255,0.25)' }} />
                  <div className="text-center shrink-0">
                    <p className="text-4xl font-extrabold text-white">🔥 {xp.streakDays}</p>
                    <p className="text-white/70 text-xs font-semibold mt-1 uppercase tracking-wide">günlük seri</p>
                  </div>
                </>
              )}

              {/* XP badge */}
              <div
                className="flex items-center justify-center px-4 py-2 rounded-xl shrink-0"
                style={{ background: 'rgba(252,211,77,0.25)', border: '1.5px solid rgba(252,211,77,0.5)' }}
              >
                <span className="text-2xl font-extrabold" style={{ color: '#FCD34D' }}>
                  ⭐ {xp.currentXp.toLocaleString('tr-TR')} XP
                </span>
              </div>
            </div>
          ) : null}
        </div>
      </div>

      <div className="px-8 sm:px-10 -mt-8 pb-12 space-y-8">
        {/* ── Filter chips ─────────────────────────────────────────────────── */}
        <div className="flex items-center gap-3">
          <p className="text-base font-semibold" style={{ color: 'var(--text-secondary)' }}>Göster:</p>
          {(['all', 'today'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className="px-5 py-2.5 rounded-2xl text-sm font-bold transition-all"
              style={{
                background: filter === f ? 'linear-gradient(135deg, #059669, #10B981)' : 'var(--card)',
                color: filter === f ? '#fff' : 'var(--text-secondary)',
                border: `1.5px solid ${filter === f ? 'transparent' : 'var(--border)'}`,
                boxShadow: filter === f ? '0 4px 12px rgba(16,185,129,0.3)' : 'none',
              }}
            >
              {f === 'all' ? '🌐 Tümü' : '📅 Bugün'}
            </button>
          ))}
        </div>

        {/* ── Stats Grid ───────────────────────────────────────────────────── */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
          {statCards.map((s, i) => (
            <div
              key={i}
              className="rounded-3xl p-6 shadow-md relative overflow-hidden"
              style={{ background: 'var(--card)', border: '2px solid var(--border)' }}
            >
              {/* Left stripe */}
              <div
                className="absolute top-0 left-0 bottom-0 w-1.5 rounded-l-3xl"
                style={{ background: s.gradient }}
              />
              {/* Icon */}
              <div
                className="w-14 h-14 rounded-2xl flex items-center justify-center text-3xl mb-5"
                style={{ background: `${s.color}18` }}
              >
                {s.icon}
              </div>
              {/* Value */}
              <p className="text-5xl font-extrabold leading-none mb-2" style={{ color: s.color }}>
                {loading ? (
                  <span className="inline-block w-20 h-10 rounded-xl animate-pulse" style={{ background: 'var(--border)' }} />
                ) : s.value}
              </p>
              <p className="text-base font-extrabold" style={{ color: 'var(--text-primary)' }}>{s.label}</p>
            </div>
          ))}
        </div>

        {/* ── Charts Row ───────────────────────────────────────────────────── */}
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
          {/* Weekly Activity Bar — wider */}
          <div
            className="lg:col-span-3 rounded-3xl shadow-sm overflow-hidden"
            style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
          >
            <div className="px-6 py-5" style={{ borderBottom: '1px solid var(--border)' }}>
              <h2 className="text-2xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                📊 Haftalık Aktivite
              </h2>
              <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                Son 7 günün çalışma süresi (dakika)
              </p>
            </div>
            <div className="p-6">
              {loading ? (
                <div className="h-52 flex items-center justify-center" style={{ color: 'var(--text-hint)' }}>
                  <div className="flex flex-col items-center gap-3">
                    <div className="flex gap-2 items-end">
                      {[40, 70, 55, 90, 35, 75, 50].map((h, i) => (
                        <div
                          key={i}
                          className="w-8 rounded-t-lg animate-pulse"
                          style={{ height: h, background: 'var(--border)' }}
                        />
                      ))}
                    </div>
                    <p className="text-sm">Yükleniyor...</p>
                  </div>
                </div>
              ) : barData.length === 0 ? (
                <div className="h-52 flex flex-col items-center justify-center gap-3" style={{ color: 'var(--text-hint)' }}>
                  <p className="text-4xl">📉</p>
                  <p className="text-sm font-medium">Henüz aktivite verisi yok</p>
                  <p className="text-xs">Çalışma seansları kayıt edilince grafiği göreceksin</p>
                </div>
              ) : (
                <ResponsiveContainer width="100%" height={220}>
                  <BarChart data={barData} margin={{ top: 8, right: 8, left: -16, bottom: 0 }} barCategoryGap="35%">
                    <XAxis
                      dataKey="name"
                      tick={{ fontSize: 12, fill: 'var(--text-secondary)', fontWeight: 600 }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <YAxis
                      tick={{ fontSize: 11, fill: 'var(--text-hint)' }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <Tooltip content={<CustomBarTooltip />} cursor={{ fill: 'var(--bg)', radius: 6 }} />
                    <Bar dataKey="dakika" radius={[8, 8, 0, 0]}>
                      {barData.map((entry, index) => {
                        const today = new Date()
                        const todayShort = toTrShort(today.toISOString().split('T')[0])
                        const isToday = entry.name === todayShort
                        return (
                          <Cell
                            key={`cell-${index}`}
                            fill={isToday
                              ? 'url(#barGradientActive)'
                              : '#4F46E540'}
                          />
                        )
                      })}
                    </Bar>
                    <defs>
                      <linearGradient id="barGradientActive" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#4F46E5" />
                        <stop offset="100%" stopColor="#6D28D9" />
                      </linearGradient>
                    </defs>
                  </BarChart>
                </ResponsiveContainer>
              )}
            </div>
          </div>

          {/* Ders Dağılımı Pie — narrower */}
          <div
            className="lg:col-span-2 rounded-3xl shadow-sm overflow-hidden"
            style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
          >
            <div className="px-6 py-5" style={{ borderBottom: '1px solid var(--border)' }}>
              <h2 className="text-xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                🎯 Ders Dağılımı
              </h2>
              <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                Derslere göre çalışma oranı
              </p>
            </div>
            <div className="p-6">
              {loading ? (
                <div className="h-52 flex flex-col items-center justify-center gap-3" style={{ color: 'var(--text-hint)' }}>
                  <div
                    className="w-32 h-32 rounded-full animate-pulse"
                    style={{ background: 'var(--border)' }}
                  />
                  <p className="text-sm">Yükleniyor...</p>
                </div>
              ) : dist.length === 0 ? (
                <div className="h-52 flex flex-col items-center justify-center gap-3" style={{ color: 'var(--text-hint)' }}>
                  <p className="text-4xl">📚</p>
                  <p className="text-sm font-medium">Dağılım verisi yok</p>
                </div>
              ) : (
                <ResponsiveContainer width="100%" height={220}>
                  <PieChart>
                    <Pie
                      data={dist}
                      dataKey="percentage"
                      nameKey="lessonName"
                      cx="50%"
                      cy="45%"
                      innerRadius={50}
                      outerRadius={80}
                      paddingAngle={3}
                      labelLine={false}
                    >
                      {dist.map((_, i) => (
                        <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                      ))}
                    </Pie>
                    <Legend
                      formatter={(v) => (
                        <span style={{ fontSize: 11, color: 'var(--text-secondary)', fontWeight: 600 }}>{v}</span>
                      )}
                      iconType="circle"
                      iconSize={8}
                    />
                    <Tooltip
                      formatter={(v, name) => [`%${Number(v).toFixed(1)}`, name as string]}
                      contentStyle={{
                        background: 'var(--card)',
                        border: '1px solid var(--border)',
                        borderRadius: 12,
                        fontSize: 13,
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              )}
            </div>
          </div>
        </div>

        {/* ── Ders Dağılımı Detail List ────────────────────────────────────── */}
        {!loading && dist.length > 0 && (
          <div
            className="rounded-3xl shadow-sm overflow-hidden"
            style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
          >
            <div className="px-6 py-5" style={{ borderBottom: '1px solid var(--border)' }}>
              <h2 className="text-xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                📚 Ders Bazlı Analiz
              </h2>
              <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                Her derste harcadığın süre ve oran
              </p>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                {[...dist]
                  .sort((a, b) => b.percentage - a.percentage)
                  .map((lesson, i) => (
                    <div key={lesson.lessonName} className="flex items-center gap-4">
                      {/* Rank badge */}
                      <div
                        className="w-8 h-8 rounded-xl flex items-center justify-center text-xs font-extrabold shrink-0"
                        style={{
                          background: `${PIE_COLORS[i % PIE_COLORS.length]}20`,
                          color: PIE_COLORS[i % PIE_COLORS.length],
                        }}
                      >
                        {i + 1}
                      </div>

                      {/* Name + bar */}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between mb-1.5">
                          <p className="text-sm font-bold truncate" style={{ color: 'var(--text-primary)' }}>
                            {lesson.lessonName}
                          </p>
                          <div className="flex items-center gap-3 ml-3 shrink-0">
                            <span className="text-sm font-bold" style={{ color: PIE_COLORS[i % PIE_COLORS.length] }}>
                              %{lesson.percentage.toFixed(1)}
                            </span>
                            <span className="text-xs" style={{ color: 'var(--text-hint)' }}>
                              {fmtMinutes(lesson.totalMinutes)}
                            </span>
                          </div>
                        </div>
                        {/* Progress bar */}
                        <div
                          className="h-2.5 rounded-full overflow-hidden"
                          style={{ background: 'var(--bg)' }}
                        >
                          <div
                            className="h-full rounded-full transition-all duration-700"
                            style={{
                              width: `${Math.min(100, lesson.percentage)}%`,
                              background: PIE_COLORS[i % PIE_COLORS.length],
                            }}
                          />
                        </div>
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          </div>
        )}

        {/* ── Soru Gelişimi (empty state) ──────────────────────────────────── */}
        <div
          className="rounded-3xl shadow-sm overflow-hidden"
          style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
        >
          <div className="px-6 py-5" style={{ borderBottom: '1px solid var(--border)' }}>
            <h2 className="text-xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
              📈 Soru Gelişimi
            </h2>
            <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
              Çözdüğün sorular ve doğruluk oranı
            </p>
          </div>
          <div className="p-10 flex flex-col items-center justify-center text-center">
            <div
              className="w-20 h-20 rounded-3xl flex items-center justify-center text-4xl mb-5"
              style={{ background: '#EEF2FF' }}
            >
              🧠
            </div>
            <p className="text-lg font-extrabold mb-2" style={{ color: 'var(--text-primary)' }}>
              Soru kaydı bulunamadı
            </p>
            <p className="text-sm max-w-xs" style={{ color: 'var(--text-secondary)' }}>
              Deneme sınavı girerek ya da soru çözüm seansı başlatarak bu bölümü doldurmaya başlayabilirsin.
            </p>
            <div className="flex gap-3 mt-6">
              <div
                className="px-5 py-2.5 rounded-xl text-sm font-semibold"
                style={{ background: '#EEF2FF', color: 'var(--primary)' }}
              >
                🎯 Deneme Sınavı Gir
              </div>
              <div
                className="px-5 py-2.5 rounded-xl text-sm font-semibold"
                style={{ background: '#F0FDF4', color: '#059669' }}
              >
                ✏️ Soru Çözümü Başlat
              </div>
            </div>
          </div>
        </div>

        {/* ── Achievement / motivational footer ───────────────────────────── */}
        {!loading && xp && (
          <div
            className="rounded-3xl p-6 sm:p-8 relative overflow-hidden"
            style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
          >
            <div
              className="absolute -top-10 -right-10 w-48 h-48 rounded-full opacity-10"
              style={{ background: '#fff' }}
            />
            <div className="relative flex flex-col sm:flex-row sm:items-center justify-between gap-5">
              <div>
                <p className="text-white/70 text-sm font-semibold mb-1 uppercase tracking-wide">Seviye Durumu</p>
                <p className="text-3xl font-extrabold text-white mb-1">
                  {xp.levelEmoji} {xp.levelName}
                </p>
                <p className="text-white/70 text-sm">
                  Sonraki seviyeye <span className="text-white font-bold">{(xp.xpForNextLevel - xp.currentXp).toLocaleString('tr-TR')} XP</span> kaldı
                </p>
              </div>
              <div
                className="flex items-center gap-4 px-6 py-4 rounded-2xl shrink-0"
                style={{ background: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.2)' }}
              >
                <div className="text-center">
                  <p className="text-4xl font-extrabold text-white">{xp.level}</p>
                  <p className="text-white/60 text-xs font-semibold mt-1 uppercase tracking-widest">Seviye</p>
                </div>
                <div className="h-10 w-px" style={{ background: 'rgba(255,255,255,0.3)' }} />
                <div className="text-center">
                  <p className="text-4xl font-extrabold" style={{ color: '#FCD34D' }}>
                    {xp.currentXp.toLocaleString('tr-TR')}
                  </p>
                  <p className="text-white/60 text-xs font-semibold mt-1 uppercase tracking-widest">Toplam XP</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

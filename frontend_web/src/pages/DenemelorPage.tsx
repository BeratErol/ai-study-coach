import { useEffect, useState } from 'react'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
  CartesianGrid,
} from 'recharts'
import { denemeService, type CreateExamDto, type ExamRecord } from '../services/denemeService'
import { useUserProfile } from '../hooks/useUserProfile'
import { getSubjectsForExam } from '../data/subjectsData'

// ─── Types ────────────────────────────────────────────────────────────────────

type FilterRange = '7' | '30' | 'all'

// ─── Constants ────────────────────────────────────────────────────────────────

const PIE_COLORS = [
  '#4F46E5', '#6D28D9', '#10B981', '#F59E0B',
  '#EF4444', '#EC4899', '#06B6D4', '#8B5CF6',
  '#F97316', '#14B8A6',
]

// ─── Helpers ──────────────────────────────────────────────────────────────────

function calcNet(correct: number, wrong: number): number {
  return Math.max(0, correct - wrong / 4)
}

function filterByRange(exams: ExamRecord[], range: FilterRange): ExamRecord[] {
  if (range === 'all') return exams
  const days = parseInt(range, 10)
  const cutoff = new Date()
  cutoff.setDate(cutoff.getDate() - days)
  return exams.filter((e) => new Date(e.date) >= cutoff)
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

function Skeleton({ className }: { className?: string }) {
  return (
    <div
      className={`animate-pulse rounded-xl ${className ?? ''}`}
      style={{ background: 'var(--border)' }}
    />
  )
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function DenemelorPage() {
  const { profile } = useUserProfile()
  const [allExams, setAllExams] = useState<ExamRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [deleteId, setDeleteId] = useState<number | null>(null)
  const [expandedId, setExpandedId] = useState<number | null>(null)
  const [filter, setFilter] = useState<FilterRange>('all')
  const [aiText, setAiText] = useState<string | null>(null)
  const [aiLoading, setAiLoading] = useState(true)
  const [aiError, setAiError] = useState(false)

  // Fetch exams
  useEffect(() => {
    denemeService
      .getAll()
      .then((list) => setAllExams(list))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  // Fetch AI recommendation
  useEffect(() => {
    denemeService
      .getAiRecommendation()
      .then((text) => {
        if (text) setAiText(text)
        else setAiError(true)
      })
      .catch(() => setAiError(true))
      .finally(() => setAiLoading(false))
  }, [])

  const exams = filterByRange(allExams, filter)

  // Sort newest first for the table
  const tableExams = [...exams].sort(
    (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
  )

  // Sort oldest first for the line chart
  const chartExams = [...exams].sort(
    (a, b) => new Date(a.date).getTime() - new Date(b.date).getTime(),
  )

  const lineData = chartExams.map((e) => ({
    tarih: new Date(e.date).toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit' }),
    net: parseFloat(e.totalNet.toFixed(2)),
  }))

  // Pie: average net per subject
  const subjectMap: Record<string, number[]> = {}
  exams.forEach((e) => {
    e.subjectNets?.forEach((s) => {
      if (!subjectMap[s.subjectName]) subjectMap[s.subjectName] = []
      subjectMap[s.subjectName].push(s.net)
    })
  })
  const pieData = Object.entries(subjectMap)
    .map(([name, nets]) => ({
      name,
      value: parseFloat((nets.reduce((a, b) => a + b, 0) / nets.length).toFixed(2)),
    }))
    .filter((d) => d.value > 0)
    .sort((a, b) => b.value - a.value)

  // Summary stats
  const avgNet =
    exams.length > 0
      ? (exams.reduce((s, e) => s + e.totalNet, 0) / exams.length).toFixed(2)
      : '—'
  const bestNet =
    exams.length > 0 ? Math.max(...exams.map((e) => e.totalNet)).toFixed(2) : '—'

  async function handleDelete(id: number) {
    await denemeService.delete(id).catch(() => {})
    setAllExams((prev) => prev.filter((e) => e.id !== id))
    setDeleteId(null)
    setExpandedId(null)
  }

  function onAdded(exam: ExamRecord) {
    setAllExams((prev) => [exam, ...prev])
    setShowModal(false)
  }

  return (
    <div className="min-h-screen" style={{ background: 'var(--bg)' }}>
      {/* ── Gradient Header Banner ─────────────────────────────────────────── */}
      <div
        className="px-10 py-14"
        style={{ background: 'linear-gradient(135deg, #312E81 0%, #4F46E5 50%, #7C3AED 100%)' }}
      >
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
            <div>
              <h1 className="text-5xl sm:text-6xl font-extrabold text-white tracking-tight">
                📝 Denemeler
              </h1>
              <p className="text-white/70 mt-2 text-lg">
                Deneme sınavlarını takip et, trendini gör, gelişimini ölç.
              </p>
            </div>
            <button
              onClick={() => setShowModal(true)}
              className="flex items-center gap-2 px-8 py-4 rounded-2xl text-lg font-bold text-white shadow-lg hover:opacity-90 transition-opacity self-start sm:self-auto"
              style={{ background: 'rgba(255,255,255,0.2)', border: '2px solid rgba(255,255,255,0.4)', backdropFilter: 'blur(8px)' }}
            >
              <span className="text-2xl">+</span>
              Deneme Ekle
            </button>
          </div>

          {/* Filter Chips */}
          <div className="flex gap-2 mt-6 flex-wrap">
            {([['7', 'Son 7 Gün'], ['30', 'Son 30 Gün'], ['all', 'Tümü']] as [FilterRange, string][]).map(
              ([val, label]) => (
                <button
                  key={val}
                  onClick={() => setFilter(val)}
                  className="px-5 py-2 rounded-full text-sm font-semibold transition-all"
                  style={{
                    background: filter === val ? '#fff' : 'rgba(255,255,255,0.15)',
                    color: filter === val ? '#4F46E5' : 'rgba(255,255,255,0.85)',
                    border: `2px solid ${filter === val ? '#fff' : 'rgba(255,255,255,0.3)'}`,
                  }}
                >
                  {label}
                </button>
              ),
            )}
          </div>

          {/* Summary Stats Strip */}
          <div className="grid grid-cols-3 gap-5 mt-7">
            {[
              { label: 'Ortalama Net', value: avgNet, icon: '📊' },
              { label: 'En İyi Net', value: bestNet, icon: '🏆' },
              { label: 'Toplam Deneme', value: exams.length, icon: '📝' },
            ].map((stat) => (
              <div
                key={stat.label}
                className="rounded-2xl px-6 py-5"
                style={{ background: 'rgba(255,255,255,0.12)', border: '1.5px solid rgba(255,255,255,0.25)' }}
              >
                <p className="text-white/60 text-sm font-semibold uppercase tracking-widest">
                  {stat.icon} {stat.label}
                </p>
                <p className="text-5xl font-extrabold text-white mt-2">{stat.value}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── Page Body ─────────────────────────────────────────────────────── */}
      <div className="max-w-7xl mx-auto px-10 py-10 space-y-8">
        {/* Charts Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Net Trendi */}
          <div
            className="rounded-3xl p-6 shadow-lg"
            style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
          >
            <div className="flex items-center justify-between mb-5">
              <div>
                <h2 className="text-2xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                  📈 Net Trendi
                </h2>
                <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                  Zaman içindeki net gelişimin
                </p>
              </div>
            </div>
            {loading ? (
              <div className="space-y-3">
                <Skeleton className="h-5 w-1/3" />
                <Skeleton className="h-48 w-full" />
              </div>
            ) : lineData.length < 2 ? (
              <div className="h-52 flex flex-col items-center justify-center gap-2" style={{ color: 'var(--text-hint)' }}>
                <span className="text-5xl">📉</span>
                <p className="text-sm font-medium">En az 2 deneme ekleyin</p>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={220}>
                <LineChart data={lineData} margin={{ top: 5, right: 10, left: -15, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" vertical={false} />
                  <XAxis
                    dataKey="tarih"
                    tick={{ fontSize: 12, fill: 'var(--text-secondary)' }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <YAxis
                    tick={{ fontSize: 11, fill: 'var(--text-hint)' }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <Tooltip
                    contentStyle={{
                      background: 'var(--card)',
                      border: '1px solid var(--border)',
                      borderRadius: 16,
                      boxShadow: '0 8px 32px rgba(0,0,0,0.12)',
                    }}
                    labelStyle={{ color: 'var(--text-primary)', fontWeight: 700, marginBottom: 4 }}
                    formatter={(v) => [v as number, 'Toplam Net']}
                  />
                  <Line
                    type="monotone"
                    dataKey="net"
                    stroke="#4F46E5"
                    strokeWidth={3}
                    dot={{ fill: '#4F46E5', r: 5, strokeWidth: 2, stroke: '#fff' }}
                    activeDot={{ r: 7, strokeWidth: 2, stroke: '#fff' }}
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </div>

          {/* Ders Net Dağılımı */}
          <div
            className="rounded-3xl p-6 shadow-lg"
            style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
          >
            <div className="mb-5">
              <h2 className="text-xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                🎯 Ders Net Dağılımı
              </h2>
              <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                Derslere göre ortalama netler
              </p>
            </div>
            {loading ? (
              <div className="space-y-3">
                <Skeleton className="h-48 w-full" />
              </div>
            ) : pieData.length === 0 ? (
              <div className="h-52 flex flex-col items-center justify-center gap-2" style={{ color: 'var(--text-hint)' }}>
                <span className="text-5xl">🍕</span>
                <p className="text-sm font-medium">Ders verisi henüz yok</p>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={240}>
                <PieChart>
                  <Pie
                    data={pieData}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="48%"
                    outerRadius={85}
                    innerRadius={40}
                    paddingAngle={2}
                    labelLine={false}
                  >
                    {pieData.map((_, i) => (
                      <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Legend
                    formatter={(v) => (
                      <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{v}</span>
                    )}
                  />
                  <Tooltip
                    formatter={(v) => [(v as number).toFixed(2), 'Ort. Net']}
                    contentStyle={{
                      background: 'var(--card)',
                      border: '1px solid var(--border)',
                      borderRadius: 14,
                      boxShadow: '0 8px 24px rgba(0,0,0,0.1)',
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* AI Tavsiyesi */}
        <div
          className="rounded-3xl p-6 shadow-lg overflow-hidden relative"
          style={{
            background: 'linear-gradient(135deg, #1E1B4B 0%, #312E81 40%, #4C1D95 100%)',
          }}
        >
          {/* Decorative circles */}
          <div
            className="absolute top-0 right-0 w-64 h-64 rounded-full opacity-10"
            style={{
              background: 'radial-gradient(circle, #818CF8, transparent)',
              transform: 'translate(30%, -30%)',
              pointerEvents: 'none',
            }}
          />
          <div className="relative">
            <div className="flex items-center gap-3 mb-4">
              <div
                className="w-12 h-12 rounded-2xl flex items-center justify-center text-2xl"
                style={{ background: 'rgba(255,255,255,0.15)' }}
              >
                🤖
              </div>
              <div>
                <h2 className="text-xl font-extrabold text-white">AI Tavsiyesi</h2>
                <p className="text-white/60 text-sm">Yapay zeka analizine dayalı kişisel tavsiye</p>
              </div>
            </div>

            {aiLoading ? (
              <div className="space-y-3">
                <div className="h-4 rounded-full animate-pulse" style={{ background: 'rgba(255,255,255,0.15)', width: '85%' }} />
                <div className="h-4 rounded-full animate-pulse" style={{ background: 'rgba(255,255,255,0.12)', width: '70%' }} />
                <div className="h-4 rounded-full animate-pulse" style={{ background: 'rgba(255,255,255,0.10)', width: '60%' }} />
              </div>
            ) : aiError || !aiText ? (
              <div className="flex items-center gap-3 px-4 py-3 rounded-2xl" style={{ background: 'rgba(239,68,68,0.15)', border: '1px solid rgba(239,68,68,0.3)' }}>
                <span className="text-xl">⚠️</span>
                <p className="text-white/80 text-sm">AI tavsiyesi yüklenemedi. Lütfen daha sonra tekrar deneyin.</p>
              </div>
            ) : (
              <p className="text-white/90 text-base leading-relaxed">{aiText}</p>
            )}
          </div>
        </div>

        {/* Exams Table */}
        <div
          className="rounded-3xl overflow-hidden shadow-lg"
          style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
        >
          <div
            className="px-6 py-5 flex items-center justify-between"
            style={{ borderBottom: '1px solid var(--border)' }}
          >
            <div>
              <h2 className="text-xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                Son Denemeler
              </h2>
              <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                {exams.length} deneme {filter !== 'all' ? `(son ${filter} gün)` : ''}
              </p>
            </div>
          </div>

          {loading ? (
            <div className="p-6 space-y-4">
              {[1, 2, 3].map((i) => (
                <Skeleton key={i} className="h-14 w-full" />
              ))}
            </div>
          ) : exams.length === 0 ? (
            <div className="text-center py-16" style={{ color: 'var(--text-hint)' }}>
              <p className="text-6xl mb-4">📝</p>
              <p className="font-bold text-lg" style={{ color: 'var(--text-secondary)' }}>
                Henüz deneme eklenmedi
              </p>
              <p className="text-sm mt-1">
                "Deneme Ekle" butonuna tıklayarak ilk denemenizi girin.
              </p>
              <button
                onClick={() => setShowModal(true)}
                className="mt-6 px-6 py-3 rounded-2xl text-sm font-bold text-white inline-flex items-center gap-2"
                style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
              >
                + İlk Denemeyi Ekle
              </button>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr style={{ borderBottom: '2px solid var(--border)' }}>
                    {['Tarih', 'Toplam Net', 'Ders Sayısı', 'İşlemler'].map((h) => (
                      <th
                        key={h}
                        className="px-6 py-4 text-left text-xs font-bold uppercase tracking-widest"
                        style={{ color: 'var(--text-secondary)' }}
                      >
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {tableExams.map((exam) => (
                    <>
                      <tr
                        key={exam.id}
                        className="transition-colors cursor-pointer"
                        style={{ borderBottom: '1px solid var(--border)' }}
                        onMouseEnter={(e) => (e.currentTarget.style.background = 'var(--bg)')}
                        onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                        onClick={() => setExpandedId(expandedId === exam.id ? null : exam.id)}
                      >
                        <td className="px-6 py-4">
                          <div
                            className="font-semibold text-base"
                            style={{ color: 'var(--text-primary)' }}
                          >
                            {new Date(exam.date).toLocaleDateString('tr-TR', {
                              day: '2-digit',
                              month: 'long',
                              year: 'numeric',
                            })}
                          </div>
                          <div className="text-xs mt-0.5" style={{ color: 'var(--text-hint)' }}>
                            {new Date(exam.date).toLocaleDateString('tr-TR', { weekday: 'long' })}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className="text-3xl font-extrabold"
                            style={{ color: 'var(--primary)' }}
                          >
                            {exam.totalNet.toFixed(2)}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className="inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold"
                            style={{ background: '#EEF2FF', color: '#4F46E5' }}
                          >
                            {exam.subjectNets?.length ?? 0} ders
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-2">
                            <button
                              onClick={(e) => {
                                e.stopPropagation()
                                setExpandedId(expandedId === exam.id ? null : exam.id)
                              }}
                              className="px-3 py-1.5 rounded-xl text-xs font-semibold transition-all"
                              style={{ background: '#EEF2FF', color: '#4F46E5' }}
                            >
                              {expandedId === exam.id ? '▲ Gizle' : '▼ Detay'}
                            </button>

                            {deleteId === exam.id ? (
                              <>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation()
                                    handleDelete(exam.id)
                                  }}
                                  className="px-3 py-1.5 rounded-xl text-xs font-bold text-white"
                                  style={{ background: '#EF4444' }}
                                >
                                  Evet, Sil
                                </button>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation()
                                    setDeleteId(null)
                                  }}
                                  className="px-3 py-1.5 rounded-xl text-xs font-semibold"
                                  style={{
                                    background: 'var(--bg)',
                                    color: 'var(--text-secondary)',
                                    border: '1px solid var(--border)',
                                  }}
                                >
                                  İptal
                                </button>
                              </>
                            ) : (
                              <button
                                onClick={(e) => {
                                  e.stopPropagation()
                                  setDeleteId(exam.id)
                                }}
                                className="w-9 h-9 flex items-center justify-center rounded-xl text-base transition-all hover:scale-110"
                                style={{ background: '#FEF2F2', color: '#EF4444' }}
                                title="Sil"
                              >
                                🗑️
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>

                      {/* Expanded row */}
                      {expandedId === exam.id && exam.subjectNets && exam.subjectNets.length > 0 && (
                        <tr key={`${exam.id}-detail`} style={{ background: 'var(--bg)' }}>
                          <td colSpan={4} className="px-6 py-4">
                            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
                              {exam.subjectNets.map((s) => (
                                <div
                                  key={s.subjectName}
                                  className="rounded-2xl p-3"
                                  style={{
                                    background: 'var(--card)',
                                    border: '1px solid var(--border)',
                                  }}
                                >
                                  <p
                                    className="text-xs font-semibold truncate"
                                    style={{ color: 'var(--text-secondary)' }}
                                  >
                                    {s.subjectName}
                                  </p>
                                  <p
                                    className="text-2xl font-extrabold mt-1"
                                    style={{ color: 'var(--primary)' }}
                                  >
                                    {s.net.toFixed(2)}
                                  </p>
                                  <p className="text-xs mt-1" style={{ color: 'var(--text-hint)' }}>
                                    ✅ {s.correct} &nbsp; ❌ {s.wrong}
                                  </p>
                                </div>
                              ))}
                            </div>
                          </td>
                        </tr>
                      )}
                    </>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Add Exam Modal */}
      {showModal && (
        <AddExamModal
          profile={profile}
          onClose={() => setShowModal(false)}
          onAdded={onAdded}
        />
      )}
    </div>
  )
}

// ─── Add Exam Modal ───────────────────────────────────────────────────────────

interface SubjectRow {
  name: string
  correct: number
  wrong: number
}

function AddExamModal({
  profile,
  onClose,
  onAdded,
}: {
  profile: { targetExam: string; selectedArea: string } | null
  onClose: () => void
  onAdded: (exam: ExamRecord) => void
}) {
  const subjects =
    profile ? getSubjectsForExam(profile.targetExam, profile.selectedArea) : []

  const [date, setDate] = useState(new Date().toISOString().split('T')[0])
  const [rows, setRows] = useState<SubjectRow[]>(() =>
    subjects.length > 0
      ? subjects.map((s) => ({ name: s.name, correct: 0, wrong: 0 }))
      : [{ name: '', correct: 0, wrong: 0 }],
  )
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  function updateRow(i: number, field: keyof SubjectRow, val: number | string) {
    setRows((prev) =>
      prev.map((r, idx) => {
        if (idx !== i) return r
        if (field === 'name') return { ...r, name: val as string }
        return { ...r, [field]: Math.max(0, val as number) }
      }),
    )
  }

  function addManualRow() {
    setRows((prev) => [...prev, { name: '', correct: 0, wrong: 0 }])
  }

  function removeRow(i: number) {
    setRows((prev) => prev.filter((_, idx) => idx !== i))
  }

  const totalNet = rows.reduce((s, r) => s + calcNet(r.correct, r.wrong), 0)

  async function save() {
    if (!date) {
      setError('Lütfen bir tarih seçin.')
      return
    }
    const validRows = rows.filter((r) => r.name.trim() && (r.correct > 0 || r.wrong > 0))
    if (validRows.length === 0) {
      setError('En az bir derse sonuç girmelisin.')
      return
    }
    setSaving(true)
    setError(null)
    try {
      const examType = profile?.targetExam || 'Deneme'
      const dto: CreateExamDto = {
        title: `${examType} Denemesi - ${new Date(date).toLocaleDateString('tr-TR')}`,
        type: examType,
        date: new Date(`${date}T12:00:00`).toISOString(),
        subjects: validRows.map((r) => ({
          name: r.name,
          correct: r.correct,
          wrong: r.wrong,
        })),
      }
      const exam = await denemeService.create(dto)
      onAdded(exam)
    } catch {
      setError('Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyin.')
      setSaving(false)
    }
  }

  const isManual = subjects.length === 0

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      style={{ background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(4px)' }}
      onClick={(e) => { if (e.target === e.currentTarget) onClose() }}
    >
      <div
        className="w-full max-w-2xl rounded-3xl overflow-hidden shadow-2xl flex flex-col"
        style={{ background: 'var(--card)', maxHeight: '92vh' }}
      >
        {/* Modal Header */}
        <div
          className="px-6 py-5 flex items-center justify-between"
          style={{
            background: 'linear-gradient(135deg, #312E81, #4F46E5)',
          }}
        >
          <div>
            <h2 className="text-xl font-extrabold text-white">📝 Yeni Deneme Ekle</h2>
            {profile && (
              <p className="text-white/70 text-sm mt-0.5">
                {profile.targetExam}
                {profile.selectedArea ? ` — ${profile.selectedArea}` : ''}
              </p>
            )}
          </div>
          <button
            onClick={onClose}
            className="w-9 h-9 rounded-xl flex items-center justify-center text-white/80 hover:text-white hover:bg-white/20 transition-all"
          >
            ✕
          </button>
        </div>

        {/* Modal Body */}
        <div className="overflow-y-auto flex-1 px-6 py-5 space-y-5">
          {/* Date */}
          <div>
            <label
              className="block text-sm font-bold mb-2"
              style={{ color: 'var(--text-primary)' }}
            >
              📅 Sınav Tarihi
            </label>
            <input
              type="date"
              value={date}
              max={new Date().toISOString().split('T')[0]}
              onChange={(e) => setDate(e.target.value)}
              className="w-full px-4 py-3 rounded-2xl text-base outline-none transition-all"
              style={{
                background: 'var(--bg)',
                border: '2px solid var(--border)',
                color: 'var(--text-primary)',
              }}
              onFocus={(e) => (e.currentTarget.style.borderColor = '#4F46E5')}
              onBlur={(e) => (e.currentTarget.style.borderColor = 'var(--border)')}
            />
          </div>

          {/* Rows */}
          <div>
            <div
              className="grid gap-2 mb-3 text-xs font-bold uppercase tracking-widest"
              style={{
                gridTemplateColumns: isManual ? '1fr 80px 80px 60px 32px' : '1fr 80px 80px 60px',
                color: 'var(--text-secondary)',
              }}
            >
              <span>Ders</span>
              <span className="text-center">Doğru</span>
              <span className="text-center">Yanlış</span>
              <span className="text-center">Net</span>
              {isManual && <span />}
            </div>

            <div className="space-y-2">
              {rows.map((row, i) => {
                const net = calcNet(row.correct, row.wrong)
                return (
                  <div
                    key={i}
                    className="grid gap-2 items-center"
                    style={{
                      gridTemplateColumns: isManual ? '1fr 80px 80px 60px 32px' : '1fr 80px 80px 60px',
                    }}
                  >
                    {isManual ? (
                      <input
                        type="text"
                        placeholder="Ders adı"
                        value={row.name}
                        onChange={(e) => updateRow(i, 'name', e.target.value)}
                        className="px-3 py-2 rounded-xl text-sm outline-none"
                        style={{
                          background: 'var(--bg)',
                          border: '1px solid var(--border)',
                          color: 'var(--text-primary)',
                        }}
                      />
                    ) : (
                      <div
                        className="flex items-center gap-2 px-3 py-2 rounded-xl"
                        style={{ background: 'var(--bg)', border: '1px solid var(--border)' }}
                      >
                        <span className="text-sm font-medium truncate" style={{ color: 'var(--text-primary)' }}>
                          {row.name}
                        </span>
                      </div>
                    )}

                    <input
                      type="number"
                      min={0}
                      value={row.correct === 0 ? '' : row.correct}
                      placeholder="0"
                      onChange={(e) => updateRow(i, 'correct', parseInt(e.target.value) || 0)}
                      className="px-2 py-2 rounded-xl text-sm text-center outline-none"
                      style={{
                        background: '#F0FDF4',
                        border: '1px solid #BBF7D0',
                        color: '#065F46',
                        fontWeight: 700,
                      }}
                    />
                    <input
                      type="number"
                      min={0}
                      value={row.wrong === 0 ? '' : row.wrong}
                      placeholder="0"
                      onChange={(e) => updateRow(i, 'wrong', parseInt(e.target.value) || 0)}
                      className="px-2 py-2 rounded-xl text-sm text-center outline-none"
                      style={{
                        background: '#FEF2F2',
                        border: '1px solid #FECACA',
                        color: '#991B1B',
                        fontWeight: 700,
                      }}
                    />
                    <div
                      className="px-2 py-2 rounded-xl text-sm text-center font-extrabold"
                      style={{ background: '#EEF2FF', color: '#4F46E5' }}
                    >
                      {net.toFixed(1)}
                    </div>
                    {isManual && (
                      <button
                        onClick={() => removeRow(i)}
                        className="w-8 h-8 flex items-center justify-center rounded-xl text-sm hover:opacity-80 transition-opacity"
                        style={{ background: '#FEF2F2', color: '#EF4444' }}
                      >
                        ✕
                      </button>
                    )}
                  </div>
                )
              })}
            </div>

            {isManual && (
              <button
                onClick={addManualRow}
                className="mt-3 w-full py-2.5 rounded-xl text-sm font-semibold transition-all hover:opacity-80"
                style={{
                  background: 'var(--bg)',
                  border: '2px dashed var(--border)',
                  color: 'var(--text-secondary)',
                }}
              >
                + Ders Ekle
              </button>
            )}
          </div>

          {error && (
            <p className="text-sm font-semibold px-4 py-3 rounded-xl" style={{ background: '#FEF2F2', color: '#EF4444' }}>
              ⚠️ {error}
            </p>
          )}
        </div>

        {/* Modal Footer */}
        <div
          className="px-6 py-5 flex items-center justify-between gap-3"
          style={{ borderTop: '2px solid var(--border)' }}
        >
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--text-secondary)' }}>
              Toplam Net
            </p>
            <p className="text-4xl font-extrabold" style={{ color: 'var(--primary)' }}>
              {totalNet.toFixed(2)}
            </p>
          </div>
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="px-5 py-3 rounded-2xl text-sm font-semibold"
              style={{
                background: 'var(--bg)',
                color: 'var(--text-secondary)',
                border: '2px solid var(--border)',
              }}
            >
              İptal
            </button>
            <button
              onClick={save}
              disabled={saving}
              className="px-6 py-3 rounded-2xl text-sm font-bold text-white disabled:opacity-60 transition-all hover:opacity-90"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
            >
              {saving ? '⏳ Kaydediliyor...' : '💾 Kaydet'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

import { useEffect, useState } from 'react'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
  PieChart, Pie, Cell, Legend,
} from 'recharts'
import api from '../services/api'

interface ExamData {
  id: number
  title: string
  type: string
  date: string
  totalNet: number
}

interface ByLesson {
  name: string
  averageNet: number
  correct: number
  incorrect: number
}

interface Analysis {
  bestLesson: string | null
  worstLesson: string | null
  bestNet: number
  worstNet: number
  trend: 'improving' | 'declining' | 'stable'
  totalExams: number
  averageNet: number
  byLesson: ByLesson[]
  lessonAverages: { lessonName: string; averageNet: number }[]
}

const COLORS = ['#4F46E5', '#10B981', '#EF4444', '#F59E0B', '#8B5CF6', '#3B82F6', '#EC4899', '#14B8A6']

function netColor(net: number) {
  if (net >= 20) return '#10B981'
  if (net >= 10) return '#F59E0B'
  return '#EF4444'
}

function Skeleton({ className = '' }: { className?: string }) {
  return <div className={`bg-gray-100 rounded-xl animate-pulse ${className}`} />
}

export default function StatsPage() {
  const [exams, setExams]       = useState<ExamData[]>([])
  const [analysis, setAnalysis] = useState<Analysis | null>(null)
  const [totalMin, setTotalMin] = useState(0)
  const [loading, setLoading]   = useState(true)

  useEffect(() => {
    Promise.all([
      api.get('/Exam').then((r) => setExams(r.data)).catch(() => {}),
      api.get('/Exam/analysis').then((r) => setAnalysis(r.data)).catch(() => {}),
      api.get('/StudySession/summary').then((r) => setTotalMin(r.data?.totalDurationMinutes ?? 0)).catch(() => {}),
    ]).finally(() => setLoading(false))
  }, [])

  function fmtHours(min: number) {
    if (min < 60) return `${min}dk`
    return `${Math.floor(min / 60)}s ${min % 60}dk`
  }

  const barData = [...exams]
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
    .slice(-7)
    .map((e) => ({
      name: new Date(e.date).toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit' }),
      net: Number(e.totalNet.toFixed(1)),
    }))

  const pieData = (analysis?.byLesson ?? []).map((b) => ({
    name: b.name,
    value: Number(b.averageNet.toFixed(1)),
  }))

  const trendIcon  = analysis?.trend === 'improving' ? '📈' : analysis?.trend === 'declining' ? '📉' : '➡️'
  const trendLabel = analysis?.trend === 'improving' ? 'Yükseliyor' : analysis?.trend === 'declining' ? 'Düşüyor' : 'Stabil'
  const trendColor = analysis?.trend === 'improving' ? 'text-emerald-600' : analysis?.trend === 'declining' ? 'text-red-500' : 'text-gray-500'

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <h1 className="text-2xl font-extrabold text-gray-900 mb-6">İstatistikler</h1>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
        {loading ? (
          Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-24" />)
        ) : (
          <>
            <div className="bg-white rounded-xl p-4 border border-gray-100">
              <p className="text-xs text-gray-500 mb-1">Toplam Çalışma</p>
              <p className="text-xl font-extrabold text-emerald-600">{fmtHours(totalMin)}</p>
            </div>
            <div className="bg-white rounded-xl p-4 border border-gray-100">
              <p className="text-xs text-gray-500 mb-1">Deneme Sayısı</p>
              <p className="text-xl font-extrabold text-indigo-600">{analysis?.totalExams ?? exams.length}</p>
            </div>
            <div className="bg-white rounded-xl p-4 border border-gray-100">
              <p className="text-xs text-gray-500 mb-1">Ort. Net</p>
              <p className="text-xl font-extrabold text-amber-500">
                {analysis?.averageNet != null ? Number(analysis.averageNet).toFixed(1) : '—'}
              </p>
            </div>
            <div className="bg-white rounded-xl p-4 border border-gray-100">
              <p className="text-xs text-gray-500 mb-1">Trend</p>
              <p className={`text-xl font-extrabold ${trendColor}`}>{trendIcon} {trendLabel}</p>
            </div>
          </>
        )}
      </div>

      {/* Best / Worst lesson */}
      {!loading && analysis?.bestLesson && (
        <div className="grid grid-cols-2 gap-3 mb-6">
          <div className="bg-emerald-50 border border-emerald-100 rounded-xl p-4">
            <p className="text-xs text-emerald-600 font-semibold mb-1">En İyi Ders</p>
            <p className="font-bold text-gray-900">{analysis.bestLesson}</p>
            <p className="text-emerald-600 font-extrabold">{Number(analysis.bestNet).toFixed(1)} net</p>
          </div>
          <div className="bg-red-50 border border-red-100 rounded-xl p-4">
            <p className="text-xs text-red-500 font-semibold mb-1">Geliştirilecek Ders</p>
            <p className="font-bold text-gray-900">{analysis.worstLesson}</p>
            <p className="text-red-500 font-extrabold">{Number(analysis.worstNet).toFixed(1)} net</p>
          </div>
        </div>
      )}

      {/* Bar Chart */}
      {loading ? (
        <Skeleton className="h-56 mb-6" />
      ) : barData.length >= 2 ? (
        <div className="bg-white rounded-xl p-5 border border-gray-100 mb-6">
          <h2 className="font-bold text-gray-900 mb-4">Son Denemeler — Net Skorları</h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={barData} barSize={28}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F3F4F6" />
              <XAxis dataKey="name" tick={{ fontSize: 11, fill: '#6B7280' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#6B7280' }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ borderRadius: 12, border: '1px solid #E5E7EB', fontSize: 12 }}
                formatter={(v) => [`${v} net`, 'Net']}
              />
              <Bar dataKey="net" radius={[6, 6, 0, 0]}>
                {barData.map((entry, i) => (
                  <Cell key={i} fill={netColor(entry.net)} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      ) : null}

      {/* Pie Chart */}
      {loading ? (
        <Skeleton className="h-56 mb-6" />
      ) : pieData.length > 0 ? (
        <div className="bg-white rounded-xl p-5 border border-gray-100 mb-6">
          <h2 className="font-bold text-gray-900 mb-4">Ders Net Dağılımı</h2>
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie
                data={pieData}
                cx="50%"
                cy="50%"
                innerRadius={55}
                outerRadius={85}
                dataKey="value"
                paddingAngle={2}
              >
                {pieData.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip formatter={(v) => [`${v} net`, 'Ort. Net']} />
              <Legend iconType="circle" iconSize={8} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      ) : null}

      {/* Recent Exams list */}
      <h2 className="font-bold text-gray-900 mb-3">Son Denemeler</h2>
      {loading ? (
        <div className="space-y-2">
          {[1, 2, 3].map((i) => <Skeleton key={i} className="h-16" />)}
        </div>
      ) : exams.length === 0 ? (
        <p className="text-gray-400 text-sm text-center py-8">Henüz deneme girilmedi</p>
      ) : (
        <div className="space-y-2">
          {exams.slice(0, 7).map((e) => {
            const date = new Date(e.date)
            return (
              <div key={e.id} className="bg-white rounded-xl px-4 py-3 border border-gray-100 flex items-center justify-between">
                <div>
                  <p className="font-semibold text-gray-900 text-sm">{e.title}</p>
                  <p className="text-xs text-gray-400">{e.type} • {date.toLocaleDateString('tr-TR')}</p>
                </div>
                <span className="text-xl font-extrabold" style={{ color: netColor(e.totalNet) }}>
                  {Number(e.totalNet).toFixed(1)}
                </span>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

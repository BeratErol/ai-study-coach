import { useEffect, useState, type FormEvent } from 'react'
import api from '../services/api'

interface Topic {
  id: number
  name: string
  isCompleted: boolean
}

interface Lesson {
  id: number
  name: string
  colorCode: string
  plannedDate?: string
  topics: Topic[]
}

const PALETTE = [
  '#4F46E5', '#10B981', '#EF4444', '#F59E0B', '#8B5CF6',
  '#3B82F6', '#EC4899', '#14B8A6', '#F97316', '#6366F1',
]

function parseColor(hex: string | undefined): string {
  if (!hex) return '#4F46E5'
  return hex.startsWith('#') ? hex : `#${hex}`
}

export default function LessonsPage() {
  const [lessons, setLessons]           = useState<Lesson[]>([])
  const [loading, setLoading]           = useState(true)
  const [expandedId, setExpandedId]     = useState<number | null>(null)
  const [showAddModal, setShowAddModal] = useState(false)
  const [newName, setNewName]           = useState('')
  const [newColor, setNewColor]         = useState(PALETTE[0])
  const [newDate, setNewDate]           = useState('')
  const [addLoading, setAddLoading]     = useState(false)
  const [newTopic, setNewTopic]         = useState<Record<number, string>>({})

  async function loadLessons() {
    try {
      const r = await api.get('/Lesson')
      setLessons(r.data)
    } catch { /* noop */ } finally {
      setLoading(false)
    }
  }

  useEffect(() => { loadLessons() }, [])

  async function addLesson(e: FormEvent) {
    e.preventDefault()
    if (!newName.trim()) return
    setAddLoading(true)
    try {
      await api.post('/Lesson', {
        name: newName.trim(),
        colorCode: newColor.replace('#', ''),
        plannedDate: newDate || null,
      })
      setShowAddModal(false)
      setNewName('')
      setNewColor(PALETTE[0])
      setNewDate('')
      await loadLessons()
    } catch { /* noop */ } finally {
      setAddLoading(false)
    }
  }

  async function deleteLesson(id: number) {
    if (!confirm('Bu dersi silmek istediğine emin misin?')) return
    try {
      await api.delete(`/Lesson/${id}`)
      setLessons((prev) => prev.filter((l) => l.id !== id))
      if (expandedId === id) setExpandedId(null)
    } catch { /* noop */ }
  }

  async function addTopic(lessonId: number) {
    const name = (newTopic[lessonId] ?? '').trim()
    if (!name) return
    try {
      await api.post('/Topic', { name, lessonId })
      setNewTopic((prev) => ({ ...prev, [lessonId]: '' }))
      await loadLessons()
    } catch { /* noop */ }
  }

  async function toggleTopic(topicId: number) {
    try {
      await api.put(`/Topic/${topicId}/toggle`)
      await loadLessons()
    } catch { /* noop */ }
  }

  async function deleteTopic(topicId: number) {
    try {
      await api.delete(`/Topic/${topicId}`)
      await loadLessons()
    } catch { /* noop */ }
  }

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-extrabold text-gray-900">Derslerim</h1>
        <button
          onClick={() => setShowAddModal(true)}
          className="px-4 py-2 rounded-xl text-sm font-bold text-white"
          style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
        >
          + Ders Ekle
        </button>
      </div>

      {loading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => <div key={i} className="h-20 rounded-xl bg-gray-100 animate-pulse" />)}
        </div>
      ) : lessons.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <p className="text-5xl mb-4">📚</p>
          <p className="font-semibold text-lg">Henüz ders eklenmedi</p>
          <button
            onClick={() => setShowAddModal(true)}
            className="mt-4 px-6 py-2 rounded-xl text-sm font-bold text-white"
            style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
          >
            İlk Dersi Ekle
          </button>
        </div>
      ) : (
        <div className="space-y-3">
          {lessons.map((lesson) => {
            const total    = lesson.topics.length
            const done     = lesson.topics.filter((t) => t.isCompleted).length
            const progress = total > 0 ? done / total : 0
            const color    = parseColor(lesson.colorCode)
            const isOpen   = expandedId === lesson.id

            return (
              <div
                key={lesson.id}
                className="bg-white rounded-2xl border overflow-hidden"
                style={{ borderColor: `${color}33` }}
              >
                {/* Lesson header */}
                <div className="p-4 flex items-center gap-4">
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center text-white text-xl flex-shrink-0 cursor-pointer"
                    style={{ backgroundColor: color }}
                    onClick={() => setExpandedId(isOpen ? null : lesson.id)}
                  >
                    📖
                  </div>
                  <div className="flex-1 min-w-0 cursor-pointer" onClick={() => setExpandedId(isOpen ? null : lesson.id)}>
                    <p className="font-bold text-gray-900">{lesson.name}</p>
                    <p className="text-xs text-gray-500 mb-1.5">{done} / {total} konu</p>
                    <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                      <div className="h-full rounded-full transition-all" style={{ width: `${progress * 100}%`, backgroundColor: color }} />
                    </div>
                  </div>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <span className="text-sm font-extrabold" style={{ color }}>{Math.round(progress * 100)}%</span>
                    <button
                      onClick={() => deleteLesson(lesson.id)}
                      className="text-red-400 hover:text-red-600 transition text-lg"
                      title="Dersi sil"
                    >✕</button>
                  </div>
                </div>

                {/* Topics accordion */}
                {isOpen && (
                  <div className="border-t px-4 pt-3 pb-4" style={{ borderColor: `${color}22` }}>
                    <div className="space-y-2 mb-3">
                      {lesson.topics.length === 0 ? (
                        <p className="text-sm text-gray-400 text-center py-2">Henüz konu eklenmedi</p>
                      ) : (
                        lesson.topics.map((topic) => (
                          <div key={topic.id} className="flex items-center gap-3 group">
                            <input
                              type="checkbox"
                              checked={topic.isCompleted}
                              onChange={() => toggleTopic(topic.id)}
                              className="w-4 h-4 rounded accent-indigo-600 cursor-pointer"
                            />
                            <span className={`flex-1 text-sm ${topic.isCompleted ? 'line-through text-gray-400' : 'text-gray-700'}`}>
                              {topic.name}
                            </span>
                            <button
                              onClick={() => deleteTopic(topic.id)}
                              className="opacity-0 group-hover:opacity-100 text-red-400 hover:text-red-600 text-xs transition"
                            >✕</button>
                          </div>
                        ))
                      )}
                    </div>
                    <div className="flex gap-2">
                      <input
                        type="text"
                        value={newTopic[lesson.id] ?? ''}
                        onChange={(e) => setNewTopic((prev) => ({ ...prev, [lesson.id]: e.target.value }))}
                        onKeyDown={(e) => { if (e.key === 'Enter') addTopic(lesson.id) }}
                        placeholder="Yeni konu..."
                        className="flex-1 px-3 py-2 text-sm rounded-lg border border-gray-200 outline-none focus:border-indigo-400"
                      />
                      <button
                        onClick={() => addTopic(lesson.id)}
                        className="px-3 py-2 text-sm font-bold text-white rounded-lg"
                        style={{ backgroundColor: color }}
                      >Ekle</button>
                    </div>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}

      {/* Add Lesson Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/40 flex items-end md:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6">
            <h2 className="text-lg font-extrabold text-gray-900 mb-5">Yeni Ders Ekle</h2>
            <form onSubmit={addLesson} className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Ders Adı</label>
                <input
                  type="text"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="Örn: Matematik"
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-indigo-500"
                  autoFocus
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">Renk</label>
                <div className="flex gap-2 flex-wrap">
                  {PALETTE.map((c) => (
                    <button
                      key={c}
                      type="button"
                      onClick={() => setNewColor(c)}
                      className="w-8 h-8 rounded-full border-2 transition"
                      style={{
                        backgroundColor: c,
                        borderColor: newColor === c ? '#1F2937' : 'transparent',
                        transform: newColor === c ? 'scale(1.2)' : 'scale(1)',
                      }}
                    />
                  ))}
                </div>
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Hedef Tarih (opsiyonel)</label>
                <input
                  type="date"
                  value={newDate}
                  onChange={(e) => setNewDate(e.target.value)}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-indigo-500"
                />
              </div>
              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="flex-1 py-3 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600"
                >
                  İptal
                </button>
                <button
                  type="submit"
                  disabled={addLoading || !newName.trim()}
                  className="flex-1 py-3 rounded-xl text-sm font-bold text-white disabled:opacity-60"
                  style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
                >
                  {addLoading ? 'Ekleniyor...' : 'Ekle'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}

import { useRef, useEffect, useState } from 'react'
import { useChatbotStore, WELCOME } from '../stores/chatbotStore'
import api from '../services/api'
import { getOnboardingData } from '../services/userPrefsService'
import { getUserId } from '../services/tokenService'
import { getStudyPlan } from '../services/studyPlanLocal'
import { getCompletedTaskIds } from '../services/localData'

function ymd(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export default function ChatbotPanel() {
  const {
    isOpen, close, isLoading, setLoading,
    conversations, activeIndex, newConversation, switchConversation, deleteConversation, renameConversation, addMessage,
  } = useChatbotStore()

  const [text, setText] = useState('')
  const [showConvList, setShowConvList] = useState(false)
  const [editingIdx, setEditingIdx] = useState<number | null>(null)
  const [editTitle, setEditTitle] = useState('')
  const bottomRef = useRef<HTMLDivElement>(null)

  const active = conversations[activeIndex]
  const messages = active?.messages ?? []

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isLoading])

  async function send() {
    const trimmed = text.trim()
    if (!trimmed || isLoading || !active) return
    setText('')
    addMessage({ role: 'user', content: trimmed, time: new Date().toISOString() })
    setLoading(true)

    try {
      // Karşılama mesajını gönderme, son 6 mesajla sınırla
      const history = messages
        .filter((m) => !(m.role === 'model' && m.content === WELCOME))
        .slice(-5)
        .map((m) => ({ role: m.role, content: m.content }))
      history.push({ role: 'user', content: trimmed })

      // Kullanıcı bağlamı
      const uid = getUserId()
      const onboarding = uid ? getOnboardingData(uid) : null

      // Bugünkü görevler
      const plan = getStudyPlan()
      const todayStr = ymd(new Date())
      const todayDay = plan.find((d) => d.date.startsWith(todayStr)) ?? plan[0]
      // Tamamlanma durumunu da payload'a koy ki Koç bitenleri/kalanları görsün.
      const completedIds = getCompletedTaskIds()
      const todayTasks = (todayDay?.blocks ?? [])
        .filter((b) => !b.isMola)
        .map((b) => ({
          id: b.id,
          subjectName: b.subjectName,
          taskType: b.taskType,
          durationMinutes: b.durationMinutes,
          startTime: b.startTime,
          endTime: b.endTime,
          isCompleted: completedIds.has(b.id),
        }))

      const res = await api.post('/Ai/chat', {
        messages: history,
        userName: onboarding?.name ?? '',
        targetExam: onboarding?.targetExam ?? '',
        selectedArea: onboarding?.selectedArea ?? '',
        weakLessons: onboarding?.weakSubjects ?? [],
        strongLessons: onboarding?.strongSubjects ?? [],
        todayTasks,
      })
      const reply = res.data?.message ?? '...'
      addMessage({ role: 'model', content: reply, time: new Date().toISOString() })
    } catch {
      addMessage({
        role: 'model',
        content: 'Şu an yanıt veremiyorum, biraz sonra tekrar dene. 🙏',
        time: new Date().toISOString(),
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <>
      {isOpen && (
        <div className="fixed inset-0 z-40 bg-black/30" onClick={close} />
      )}

      <div
        className={`fixed top-0 right-0 h-full w-full max-w-xl z-50 flex flex-col shadow-2xl transition-transform duration-300 ${
          isOpen ? 'translate-x-0' : 'translate-x-full'
        }`}
        style={{ background: 'var(--card)', borderLeft: '1px solid var(--border)' }}
      >
        {/* Header */}
        <div
          className="flex items-center gap-3 px-5 py-4"
          style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)', flexShrink: 0 }}
        >
          <div className="w-11 h-11 rounded-xl bg-white/20 flex items-center justify-center text-2xl">🤖</div>
          <div className="flex-1 min-w-0">
            <p className="text-white font-extrabold text-lg">AI Koç</p>
            <p className="text-white/70 text-base truncate">{active?.title ?? 'Her zaman buradayım'}</p>
          </div>
          <button
            onClick={() => setShowConvList((v) => !v)}
            className="w-9 h-9 rounded-lg flex items-center justify-center text-white/80 hover:bg-white/10 transition text-lg"
            title="Sohbetler"
          >
            ☰
          </button>
          <button
            onClick={close}
            className="w-9 h-9 rounded-lg flex items-center justify-center text-white/80 hover:bg-white/10 transition text-xl"
          >
            ✕
          </button>
        </div>

        {/* Sohbet listesi (açılır) */}
        {showConvList && (
          <div className="px-4 py-3 space-y-2" style={{ background: 'var(--bg)', borderBottom: '1px solid var(--border)' }}>
            {conversations.map((c, i) => {
              const isEditing = editingIdx === i
              return (
                <div
                  key={c.id}
                  className="flex items-center gap-2 px-3 py-2.5 rounded-xl cursor-pointer"
                  style={{
                    background: i === activeIndex ? '#EEF2FF' : 'var(--card)',
                    border: `1.5px solid ${i === activeIndex ? 'var(--primary)' : 'var(--border)'}`,
                  }}
                  onClick={() => { if (!isEditing) { switchConversation(i); setShowConvList(false) } }}
                >
                  <span className="text-base">💬</span>
                  {isEditing ? (
                    <input
                      value={editTitle}
                      onChange={(e) => setEditTitle(e.target.value)}
                      onClick={(e) => e.stopPropagation()}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') { renameConversation(i, editTitle); setEditingIdx(null) }
                        if (e.key === 'Escape') setEditingIdx(null)
                      }}
                      autoFocus
                      className="flex-1 min-w-0 px-2 py-1 rounded-lg text-base outline-none"
                      style={{ background: 'var(--bg)', border: '1.5px solid var(--primary)', color: 'var(--text-primary)' }}
                    />
                  ) : (
                    <span
                      className="flex-1 text-base font-semibold truncate"
                      style={{ color: i === activeIndex ? 'var(--primary)' : 'var(--text-primary)' }}
                    >
                      {c.title}
                    </span>
                  )}
                  {isEditing ? (
                    <button
                      onClick={(e) => { e.stopPropagation(); renameConversation(i, editTitle); setEditingIdx(null) }}
                      className="text-base shrink-0 font-bold"
                      style={{ color: 'var(--primary)' }}
                    >
                      ✓
                    </button>
                  ) : (
                    <button
                      onClick={(e) => { e.stopPropagation(); setEditingIdx(i); setEditTitle(c.title) }}
                      className="text-base shrink-0"
                      style={{ color: 'var(--text-secondary)' }}
                      title="Başlığı düzenle"
                    >
                      ✏️
                    </button>
                  )}
                  <button
                    onClick={(e) => { e.stopPropagation(); deleteConversation(i); if (editingIdx === i) setEditingIdx(null) }}
                    className="text-base shrink-0"
                    style={{ color: 'var(--error)' }}
                  >
                    🗑️
                  </button>
                </div>
              )
            })}
            <button
              onClick={() => {
                if (!newConversation()) {
                  alert('En fazla 3 sohbet açabilirsin. Yeni sohbet için birini sil.')
                } else {
                  setShowConvList(false)
                }
              }}
              className="w-full py-2.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
            >
              + Yeni Sohbet
            </button>
          </div>
        )}

        {/* Mesajlar */}
        <div className="flex-1 overflow-y-auto px-4 py-4 flex flex-col gap-3">
          {messages.map((msg, i) => {
            const isUser = msg.role === 'user'
            return (
              <div key={i} className={`flex ${isUser ? 'justify-end' : 'justify-start'}`}>
                <div
                  className="max-w-[82%] px-4 py-3 text-base leading-relaxed whitespace-pre-wrap"
                  style={{
                    background: isUser ? 'var(--primary)' : 'var(--bg)',
                    color: isUser ? '#fff' : 'var(--text-primary)',
                    borderRadius: isUser ? '18px 18px 4px 18px' : '18px 18px 18px 4px',
                    border: isUser ? 'none' : '1px solid var(--border)',
                  }}
                >
                  {msg.content}
                </div>
              </div>
            )
          })}
          {isLoading && (
            <div className="flex justify-start">
              <div
                className="px-4 py-3 rounded-2xl text-base"
                style={{ background: 'var(--bg)', border: '1px solid var(--border)', color: 'var(--text-hint)' }}
              >
                Yazıyor...
              </div>
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        {/* Giriş */}
        <div className="px-4 py-4" style={{ borderTop: '1px solid var(--border)', flexShrink: 0 }}>
          <div className="flex gap-2">
            <input
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && send()}
              placeholder="Mesajını yaz..."
              className="flex-1 h-12 px-4 rounded-xl text-base outline-none"
              style={{ background: 'var(--bg)', border: '1.5px solid var(--border)', color: 'var(--text-primary)' }}
            />
            <button
              onClick={send}
              disabled={isLoading || !text.trim()}
              className="w-12 h-12 rounded-xl flex items-center justify-center text-white text-lg transition disabled:opacity-50"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
            >
              ➤
            </button>
          </div>
        </div>
      </div>
    </>
  )
}

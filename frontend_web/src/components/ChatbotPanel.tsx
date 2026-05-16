import { useRef, useEffect, useState } from 'react'
import { useChatbotStore } from '../stores/chatbotStore'
import api from '../services/api'
import { getUserName } from '../hooks/useAuth'

export default function ChatbotPanel() {
  const { isOpen, close, messages, addMessage, isLoading, setLoading } = useChatbotStore()
  const [text, setText] = useState('')
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isLoading])

  async function send() {
    const trimmed = text.trim()
    if (!trimmed || isLoading) return
    setText('')
    addMessage({ role: 'user', content: trimmed, time: new Date().toISOString() })
    setLoading(true)
    try {
      const history = messages
        .filter((m) => !(m.role === 'model' && m.content.startsWith('Merhaba!')))
        .slice(-6)
        .map((m) => ({ role: m.role, content: m.content }))
      history.push({ role: 'user', content: trimmed })

      const res = await api.post('/Ai/chat', {
        messages: history,
        userName: getUserName(),
        todayTasks: [],
      })
      const reply = res.data?.message ?? '...'
      addMessage({ role: 'model', content: reply, time: new Date().toISOString() })
    } catch {
      addMessage({ role: 'model', content: 'Şu an yanıt veremiyorum, biraz sonra tekrar dene. 🙏', time: new Date().toISOString() })
    } finally {
      setLoading(false)
    }
  }

  return (
    <>
      {/* Backdrop */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/20 md:hidden"
          onClick={close}
        />
      )}

      {/* Panel */}
      <div
        className={`fixed top-0 right-0 h-full w-96 z-50 flex flex-col shadow-2xl transition-transform duration-300 ${
          isOpen ? 'translate-x-0' : 'translate-x-full'
        }`}
        style={{ background: 'var(--card)', borderLeft: '1px solid var(--border)' }}
      >
        {/* Header */}
        <div
          className="flex items-center gap-3 px-4 py-4"
          style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)', flexShrink: 0 }}
        >
          <div className="w-9 h-9 rounded-xl bg-white/20 flex items-center justify-center text-lg">
            🤖
          </div>
          <div className="flex-1">
            <p className="text-white font-bold text-sm">AI Koç</p>
            <p className="text-white/70 text-xs">Her zaman buradayım</p>
          </div>
          <button onClick={close} className="text-white/70 hover:text-white transition text-xl leading-none">
            ✕
          </button>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-4 py-4 flex flex-col gap-3">
          {messages.map((msg, i) => {
            const isUser = msg.role === 'user'
            return (
              <div key={i} className={`flex ${isUser ? 'justify-end' : 'justify-start'}`}>
                <div
                  className="max-w-[80%] px-4 py-2.5 rounded-2xl text-sm leading-relaxed"
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
                className="px-4 py-2.5 rounded-2xl text-sm"
                style={{ background: 'var(--bg)', border: '1px solid var(--border)', color: 'var(--text-hint)' }}
              >
                Yazıyor...
              </div>
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        {/* Input */}
        <div className="px-4 py-4" style={{ borderTop: '1px solid var(--border)', flexShrink: 0 }}>
          <div className="flex gap-2">
            <input
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && send()}
              placeholder="Mesajını yaz..."
              className="flex-1 px-3 py-2.5 rounded-xl text-sm outline-none"
              style={{
                background: 'var(--bg)',
                border: '1px solid var(--border)',
                color: 'var(--text-primary)',
              }}
            />
            <button
              onClick={send}
              disabled={isLoading || !text.trim()}
              className="w-10 h-10 rounded-xl flex items-center justify-center text-white transition disabled:opacity-50"
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

import { create } from 'zustand'

interface ChatMessage {
  role: 'user' | 'model'
  content: string
  time: string
}

interface ChatbotStore {
  isOpen: boolean
  messages: ChatMessage[]
  isLoading: boolean
  open: () => void
  close: () => void
  toggle: () => void
  addMessage: (msg: ChatMessage) => void
  setLoading: (v: boolean) => void
  clearMessages: () => void
}

const WELCOME = 'Merhaba! Ben senin AI koçunum 🎓 Ders programın, uygulama özellikleri veya çalışma stratejin hakkında her şeyi sorabilirsin!'

export const useChatbotStore = create<ChatbotStore>((set) => ({
  isOpen: false,
  isLoading: false,
  messages: [{ role: 'model', content: WELCOME, time: new Date().toISOString() }],
  open: () => set({ isOpen: true }),
  close: () => set({ isOpen: false }),
  toggle: () => set((s) => ({ isOpen: !s.isOpen })),
  addMessage: (msg) => set((s) => ({ messages: [...s.messages, msg] })),
  setLoading: (v) => set({ isLoading: v }),
  clearMessages: () => set({ messages: [{ role: 'model', content: WELCOME, time: new Date().toISOString() }] }),
}))

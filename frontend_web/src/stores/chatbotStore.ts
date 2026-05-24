import { create } from 'zustand'
import { getUserId } from '../services/tokenService'
import { pushAppState } from '../services/appStateService'

export interface ChatMessage {
  role: 'user' | 'model'
  content: string
  time: string
}

export interface Conversation {
  id: string
  title: string
  messages: ChatMessage[]
}

const MAX_CONVERSATIONS = 3
export const WELCOME =
  'Merhaba! Ben senin AI koçunum 🎓 Ders programın, uygulama özellikleri veya çalışma stratejin hakkında her şeyi sorabilirsin!'

function freshConversation(id?: string): Conversation {
  return {
    id: id ?? `conv_${Date.now()}`,
    title: 'Yeni Sohbet',
    messages: [{ role: 'model', content: WELCOME, time: new Date().toISOString() }],
  }
}

// localStorage cache anahtarı — appStateService ile ortak `user_{uid}_{key}` formatı.
function storageKey(): string | null {
  const uid = getUserId()
  return uid ? `user_${uid}_chatbot_conversations` : null
}

function loadConversations(): Conversation[] {
  const key = storageKey()
  if (!key) return [freshConversation()]
  const raw = localStorage.getItem(key)
  if (!raw) return [freshConversation()]
  try {
    const list = JSON.parse(raw) as Conversation[]
    return list.length > 0 ? list : [freshConversation()]
  } catch {
    return [freshConversation()]
  }
}

// localStorage cache + backend senkronu (mobil ile ortak 'chatbot_conversations')
function persist(conversations: Conversation[]): void {
  const key = storageKey()
  if (key) localStorage.setItem(key, JSON.stringify(conversations))
  pushAppState('chatbot_conversations', conversations)
}

interface ChatbotStore {
  isOpen: boolean
  isLoading: boolean
  conversations: Conversation[]
  activeIndex: number
  open: () => void
  close: () => void
  toggle: () => void
  setLoading: (v: boolean) => void
  /** Yeni sohbet — limit dolduysa false döner */
  newConversation: () => boolean
  switchConversation: (index: number) => void
  deleteConversation: (index: number) => void
  renameConversation: (index: number, title: string) => void
  /** Aktif sohbete mesaj ekler, ilk kullanıcı mesajından başlık türetir */
  addMessage: (msg: ChatMessage) => void
  /** localStorage cache'inden sohbetleri yeniden yükler (login sonrası hydrate için) */
  reloadFromCache: () => void
}

const initial = loadConversations()

export const useChatbotStore = create<ChatbotStore>((set, get) => ({
  isOpen: false,
  isLoading: false,
  conversations: initial,
  activeIndex: 0,

  open: () => set({ isOpen: true }),
  close: () => set({ isOpen: false }),
  toggle: () => set((s) => ({ isOpen: !s.isOpen })),
  setLoading: (v) => set({ isLoading: v }),

  newConversation: () => {
    const { conversations } = get()
    if (conversations.length >= MAX_CONVERSATIONS) return false
    const next = [...conversations, freshConversation()]
    persist(next)
    set({ conversations: next, activeIndex: next.length - 1 })
    return true
  },

  switchConversation: (index) => {
    const { conversations } = get()
    if (index < 0 || index >= conversations.length) return
    set({ activeIndex: index })
  },

  deleteConversation: (index) => {
    const { conversations, activeIndex } = get()
    if (conversations.length <= 1) {
      const fresh = [freshConversation()]
      persist(fresh)
      set({ conversations: fresh, activeIndex: 0 })
      return
    }
    const next = conversations.filter((_, i) => i !== index)
    const newIdx = activeIndex >= next.length ? next.length - 1 : activeIndex
    persist(next)
    set({ conversations: next, activeIndex: newIdx })
  },

  renameConversation: (index, title) => {
    const { conversations } = get()
    if (index < 0 || index >= conversations.length) return
    const next = [...conversations]
    next[index] = {
      ...next[index],
      title: title.trim() || `Sohbet ${index + 1}`,
    }
    persist(next)
    set({ conversations: next })
  },

  addMessage: (msg) => {
    const { conversations, activeIndex } = get()
    const active = conversations[activeIndex]
    if (!active) return
    const hasUserMsg = active.messages.some((m) => m.role === 'user')
    const title =
      !hasUserMsg && msg.role === 'user'
        ? msg.content.length > 24 ? `${msg.content.slice(0, 24)}…` : msg.content
        : active.title
    const next = [...conversations]
    next[activeIndex] = { ...active, title, messages: [...active.messages, msg] }
    persist(next)
    set({ conversations: next })
  },

  reloadFromCache: () => {
    set({ conversations: loadConversations(), activeIndex: 0 })
  },
}))

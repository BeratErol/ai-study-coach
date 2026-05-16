import { NavLink } from 'react-router-dom'
import { useChatbotStore } from '../stores/chatbotStore'

const NAV = [
  { to: '/dashboard', icon: '🏠', label: 'Ana Sayfa' },
  { to: '/gelisimim', icon: '📈', label: 'Gelişimim' },
  { to: '/denemeler', icon: '📝', label: 'Denemeler' },
  { to: '/profile',   icon: '👤', label: 'Profil' },
]

interface Props {
  dark: boolean
  onToggleDark: () => void
}

export default function MobileNav(_props: Props) {
  const { toggle } = useChatbotStore()

  return (
    <>
      {/* Top bar */}
      <header
        className="md:hidden flex items-center justify-between px-4 py-3"
        style={{ background: 'var(--card)', borderBottom: '1px solid var(--border)' }}
      >
        <div className="flex items-center gap-2">
          <div
            className="w-8 h-8 rounded-lg flex items-center justify-center text-white text-sm"
            style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
          >
            📖
          </div>
          <span className="font-extrabold text-sm" style={{ color: 'var(--text-primary)' }}>AI Study Coach</span>
        </div>
        <button
          onClick={toggle}
          className="w-9 h-9 flex items-center justify-center rounded-xl text-lg"
          style={{ background: 'var(--bg)' }}
        >
          🤖
        </button>
      </header>

      {/* Bottom nav */}
      <nav
        className="md:hidden fixed bottom-0 left-0 right-0 z-30 flex items-center justify-around px-2"
        style={{
          background: 'var(--card)',
          borderTop: '1px solid var(--border)',
          paddingTop: '8px',
          paddingBottom: 'max(env(safe-area-inset-bottom), 8px)',
        }}
      >
        {NAV.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className="flex flex-col items-center gap-0.5 px-2 py-1 rounded-xl transition-all"
            style={({ isActive }) => ({ color: isActive ? 'var(--primary)' : 'var(--text-hint)' })}
          >
            <span className="text-xl">{item.icon}</span>
            <span className="text-[10px] font-semibold">{item.label}</span>
          </NavLink>
        ))}
      </nav>
    </>
  )
}

import { NavLink, useNavigate } from 'react-router-dom'
import { clearToken, getUserName } from '../hooks/useAuth'
import { useChatbotStore } from '../stores/chatbotStore'
import { useUserProfile } from '../hooks/useUserProfile'

const NAV_ITEMS = [
  { to: '/dashboard', label: 'Ana Sayfa',  icon: '🏠' },
  { to: '/gelisimim', label: 'Gelişimim',  icon: '📈' },
  { to: '/denemeler', label: 'Denemeler',  icon: '📝' },
  { to: '/profile',   label: 'Profil',     icon: '👤' },
]

interface Props {
  dark: boolean
  onToggleDark: () => void
}

export default function Sidebar({ dark, onToggleDark }: Props) {
  const navigate = useNavigate()
  const { toggle: toggleChatbot } = useChatbotStore()
  const { profile } = useUserProfile()
  const userName = getUserName()

  function logout() {
    clearToken()
    navigate('/login')
  }

  return (
    <aside
      className="hidden md:flex flex-col h-screen sticky top-0"
      style={{
        width: '280px',
        minWidth: '280px',
        background: 'var(--card)',
        borderRight: '2px solid var(--border)',
        flexShrink: 0,
      }}
    >
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-6" style={{ borderBottom: '1px solid var(--border)' }}>
        <div
          className="w-11 h-11 rounded-2xl flex items-center justify-center text-white text-xl flex-shrink-0 shadow-md"
          style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
        >
          📖
        </div>
        <div>
          <span className="font-extrabold text-base block" style={{ color: 'var(--text-primary)' }}>
            AI Study Coach
          </span>
          <span className="text-xs" style={{ color: 'var(--text-hint)' }}>Akıllı çalışma koçun</span>
        </div>
      </div>

      {/* User info card */}
      {(userName || profile?.targetExam) && (
        <div className="mx-4 mt-5 mb-2 p-4 rounded-2xl" style={{ background: 'linear-gradient(135deg, #EEF2FF, #F5F3FF)', border: '1.5px solid #C7D2FE' }}>
          <div className="flex items-center gap-3">
            <div
              className="w-11 h-11 rounded-2xl flex items-center justify-center text-white text-lg font-bold flex-shrink-0 shadow-sm"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
            >
              {userName?.[0]?.toUpperCase() || '?'}
            </div>
            <div className="flex-1 min-w-0">
              <span className="font-bold text-base block truncate" style={{ color: '#3730A3' }}>
                {userName || 'Öğrenci'}
              </span>
              {profile?.targetExam && (
                <span className="text-sm font-semibold" style={{ color: '#6366F1' }}>
                  🎯 {profile.targetExam}
                </span>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Nav */}
      <nav className="flex flex-col gap-1 flex-1 px-3 py-4">
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              `flex items-center gap-4 px-4 py-3.5 rounded-2xl text-base font-semibold transition-all ${
                isActive ? 'shadow-sm' : 'hover:opacity-80'
              }`
            }
            style={({ isActive }) => ({
              background: isActive ? 'linear-gradient(135deg, #4F46E5, #6D28D9)' : 'transparent',
              color: isActive ? '#ffffff' : 'var(--text-secondary)',
            })}
          >
            <span className="text-xl w-7 text-center">{item.icon}</span>
            {item.label}
          </NavLink>
        ))}
      </nav>

      {/* Bottom actions */}
      <div className="flex flex-col gap-1 px-3 pb-5 pt-3" style={{ borderTop: '1px solid var(--border)' }}>
        {/* AI Chatbot */}
        <button
          onClick={toggleChatbot}
          className="flex items-center gap-4 px-4 py-3.5 rounded-2xl text-base font-semibold transition-all w-full text-left"
          style={{ color: 'var(--primary)', background: '#EEF2FF' }}
          onMouseEnter={(e) => (e.currentTarget.style.background = '#E0E7FF')}
          onMouseLeave={(e) => (e.currentTarget.style.background = '#EEF2FF')}
        >
          <span className="text-xl w-7 text-center">🤖</span>
          AI Koç
        </button>

        {/* Dark mode */}
        <button
          onClick={onToggleDark}
          className="flex items-center gap-4 px-4 py-3.5 rounded-2xl text-base font-semibold transition-all w-full text-left"
          style={{ color: 'var(--text-secondary)' }}
          onMouseEnter={(e) => (e.currentTarget.style.background = 'var(--bg)')}
          onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
        >
          <span className="text-xl w-7 text-center">{dark ? '☀️' : '🌙'}</span>
          {dark ? 'Aydınlık Mod' : 'Karanlık Mod'}
        </button>

        {/* Logout */}
        <button
          onClick={logout}
          className="flex items-center gap-4 px-4 py-3.5 rounded-2xl text-base font-semibold transition-all w-full text-left"
          style={{ color: '#EF4444' }}
          onMouseEnter={(e) => (e.currentTarget.style.background = '#FEF2F2')}
          onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
        >
          <span className="text-xl w-7 text-center">🚪</span>
          Çıkış Yap
        </button>
      </div>
    </aside>
  )
}

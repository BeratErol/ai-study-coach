import { NavLink, useNavigate } from 'react-router-dom'
import { clearToken } from '../hooks/useAuth'

const NAV_ITEMS = [
  { to: '/dashboard', label: 'Ana Sayfa',  icon: '🏠' },
  { to: '/lessons',   label: 'Dersler',    icon: '📚' },
  { to: '/pomodoro',  label: 'Pomodoro',   icon: '⏱️' },
  { to: '/stats',     label: 'İstatistik', icon: '📊' },
  { to: '/profile',   label: 'Profil',     icon: '👤' },
]

interface Props {
  dark: boolean
  onToggleDark: () => void
}

export default function Sidebar({ dark, onToggleDark }: Props) {
  const navigate = useNavigate()

  function logout() {
    clearToken()
    navigate('/login')
  }

  return (
    <aside className="hidden md:flex flex-col w-60 min-h-screen bg-white dark:bg-gray-900 border-r border-gray-100 dark:border-gray-800 py-6 px-4">
      {/* Logo */}
      <div className="flex items-center gap-3 px-2 mb-8">
        <div
          className="w-9 h-9 rounded-xl flex items-center justify-center text-white text-lg"
          style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
        >
          📖
        </div>
        <span className="font-extrabold text-gray-900 dark:text-white text-sm">AI Study Coach</span>
      </div>

      {/* Nav */}
      <nav className="flex flex-col gap-1 flex-1">
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition ${
                isActive
                  ? 'bg-indigo-50 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300'
                  : 'text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-gray-800 dark:hover:text-white'
              }`
            }
          >
            <span className="text-base">{item.icon}</span>
            {item.label}
          </NavLink>
        ))}
      </nav>

      {/* Dark mode toggle */}
      <button
        onClick={onToggleDark}
        className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 transition mb-1"
      >
        <span className="text-base">{dark ? '☀️' : '🌙'}</span>
        {dark ? 'Aydınlık Mod' : 'Karanlık Mod'}
      </button>

      <button
        onClick={logout}
        className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold text-red-500 hover:bg-red-50 dark:hover:bg-red-950 transition"
      >
        <span className="text-base">🚪</span>
        Çıkış Yap
      </button>
    </aside>
  )
}

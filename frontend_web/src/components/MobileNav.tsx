import { useState } from 'react'
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

export default function MobileNav({ dark, onToggleDark }: Props) {
  const [open, setOpen] = useState(false)
  const navigate = useNavigate()

  function logout() {
    clearToken()
    navigate('/login')
  }

  return (
    <>
      {/* Top bar (mobile only) */}
      <header className="md:hidden flex items-center justify-between px-4 py-3 bg-white dark:bg-gray-900 border-b border-gray-100 dark:border-gray-800">
        <div className="flex items-center gap-2">
          <div
            className="w-8 h-8 rounded-lg flex items-center justify-center text-white text-sm"
            style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
          >
            📖
          </div>
          <span className="font-extrabold text-gray-900 dark:text-white text-sm">AI Study Coach</span>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={onToggleDark} className="w-9 h-9 flex items-center justify-center rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-lg">
            {dark ? '☀️' : '🌙'}
          </button>
          <button
            onClick={() => setOpen((o) => !o)}
            className="w-9 h-9 flex flex-col items-center justify-center gap-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
          >
            <span className={`block w-5 h-0.5 bg-gray-700 dark:bg-gray-300 transition-all ${open ? 'rotate-45 translate-y-2' : ''}`} />
            <span className={`block w-5 h-0.5 bg-gray-700 dark:bg-gray-300 transition-all ${open ? 'opacity-0' : ''}`} />
            <span className={`block w-5 h-0.5 bg-gray-700 dark:bg-gray-300 transition-all ${open ? '-rotate-45 -translate-y-2' : ''}`} />
          </button>
        </div>
      </header>

      {/* Dropdown menu */}
      {open && (
        <div className="md:hidden bg-white dark:bg-gray-900 border-b border-gray-100 dark:border-gray-800 px-4 py-3 space-y-1 z-50">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={() => setOpen(false)}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition ${
                  isActive
                    ? 'bg-indigo-50 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300'
                    : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800'
                }`
              }
            >
              <span>{item.icon}</span>{item.label}
            </NavLink>
          ))}
          <button
            onClick={logout}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold text-red-500 hover:bg-red-50 dark:hover:bg-red-950 transition"
          >
            <span>🚪</span>Çıkış Yap
          </button>
        </div>
      )}
    </>
  )
}

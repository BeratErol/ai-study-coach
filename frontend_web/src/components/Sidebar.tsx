import { useEffect, useState } from 'react'
import { createPortal } from 'react-dom'
import { NavLink, useLocation, useNavigate } from 'react-router-dom'
import { clearToken } from '../hooks/useAuth'
import { useChatbotStore } from '../stores/chatbotStore'
import { useUserProfile } from '../hooks/useUserProfile'
import { getOnboardingData } from '../services/userPrefsService'
import { getUserId } from '../services/tokenService'

const NAV_ITEMS = [
  { to: '/dashboard', label: 'Ana Sayfa',  icon: '🏠' },
  { to: '/gelisimim', label: 'Gelişimim',  icon: '📈' },
  { to: '/denemeler', label: 'Denemeler',  icon: '📝' },
  { to: '/profile',   label: 'Profil',     icon: '👤' },
]

// Backend'in döndürdüğü kısa kodları okunabilir adlara çevirir.
const EXAM_LABELS: Record<string, string> = {
  OkulSinavi: 'Okul Sınavı',
  YKS: 'YKS',
  LGS: 'LGS',
  KPSS: 'KPSS',
  ALES: 'ALES',
  YDS: 'YDS',
  Öğretmenlik: 'Öğretmenlik',
}

interface Props {
  dark: boolean
  onToggleDark: () => void
}

export default function Sidebar({ dark, onToggleDark }: Props) {
  const navigate = useNavigate()
  const location = useLocation()
  const { toggle: toggleChatbot } = useChatbotStore()
  const { profile, refresh } = useUserProfile()
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false)

  // Profil değişikliği sonrası Sidebar güncel kalsın — her route geçişinde
  // backend'den profili tazele (kullanıcı Profil sayfasında sınavı değiştirip
  // başka sayfaya gittiğinde sidebar'daki sınav etiketi güncellensin).
  useEffect(() => {
    refresh()
  }, [location.pathname, refresh])

  // İsim: onboarding'de girilen ad
  const uid = getUserId()
  const userName = (uid ? getOnboardingData(uid)?.name : '')?.trim() || ''

  function logout() {
    clearToken()
    navigate('/login')
  }

  return (
    <>
    <aside
      className="hidden md:flex flex-col h-screen sticky top-0 sidebar-surface"
      style={{
        width: '280px',
        minWidth: '280px',
        borderRight: '2px solid var(--sidebar-divider)',
        flexShrink: 0,
      }}
    >
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-6" style={{ borderBottom: '2px solid var(--sidebar-divider)' }}>
        <div
          className="w-12 h-12 rounded-2xl flex items-center justify-center text-white text-2xl flex-shrink-0 shadow-md"
          style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
        >
          📖
        </div>
        <div>
          <span className="font-extrabold text-xl block" style={{ color: 'var(--text-primary)' }}>
            AI Study Coach
          </span>
          <span className="text-base font-semibold" style={{ color: 'var(--text-secondary)' }}>Akıllı çalışma koçun</span>
        </div>
      </div>

      {/* User info card */}
      {(userName || profile?.targetExam) && (
        <div
          className="mx-4 mt-5 mb-2 p-4 rounded-2xl"
          style={{ background: 'rgba(79,70,229,0.1)', border: '1.5px solid rgba(79,70,229,0.3)' }}
        >
          <div className="flex items-center gap-3">
            <div
              className="w-11 h-11 rounded-2xl flex items-center justify-center text-white text-lg font-bold flex-shrink-0 shadow-sm"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
            >
              {userName?.[0]?.toUpperCase() || '?'}
            </div>
            <div className="flex-1 min-w-0">
              <span className="font-bold text-base block truncate" style={{ color: 'var(--text-primary)' }}>
                {userName || 'Öğrenci'}
              </span>
              {profile?.targetExam && (
                <span className="text-sm font-semibold" style={{ color: 'var(--primary)' }}>
                  🎯 {EXAM_LABELS[profile.targetExam] ?? profile.targetExam}
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
      <div className="flex flex-col gap-1 px-3 pb-5 pt-3" style={{ borderTop: '2px solid var(--sidebar-divider)' }}>
        {/* AI Chatbot */}
        <button
          onClick={toggleChatbot}
          className="flex items-center gap-4 px-4 py-3.5 rounded-2xl text-base font-semibold transition-all w-full text-left"
          style={{ color: 'var(--primary)', background: 'rgba(79,70,229,0.1)' }}
          onMouseEnter={(e) => (e.currentTarget.style.background = 'rgba(79,70,229,0.2)')}
          onMouseLeave={(e) => (e.currentTarget.style.background = 'rgba(79,70,229,0.1)')}
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
          onClick={() => setShowLogoutConfirm(true)}
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

    {/* Çıkış onayı — body'ye portal: tüm sayfayı kaplar, sidebar stacking context'inden çıkar */}
    {showLogoutConfirm && createPortal(
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.6)' }}>
        <div className="w-full max-w-sm rounded-3xl p-7 text-center" style={{ background: 'var(--card)' }}>
          <p className="text-5xl mb-3">🚪</p>
          <h4 className="text-xl font-extrabold mb-2" style={{ color: 'var(--text-primary)' }}>Çıkış Yap</h4>
          <p className="text-base mb-6" style={{ color: 'var(--text-secondary)' }}>
            Hesabından çıkış yapmak istediğine emin misin?
          </p>
          <div className="flex gap-3">
            <button
              onClick={() => setShowLogoutConfirm(false)}
              className="flex-1 py-3.5 rounded-xl text-base font-semibold"
              style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}
            >
              İptal
            </button>
            <button
              onClick={logout}
              className="flex-1 py-3.5 rounded-xl text-base font-bold text-white"
              style={{ background: '#EF4444' }}
            >
              Çıkış Yap
            </button>
          </div>
        </div>
      </div>,
      document.body,
    )}
    </>
  )
}

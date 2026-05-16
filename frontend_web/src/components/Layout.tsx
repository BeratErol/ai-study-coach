import { useState, useEffect } from 'react'
import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import MobileNav from './MobileNav'
import ChatbotPanel from './ChatbotPanel'

export default function Layout() {
  const [dark, setDark] = useState(() => localStorage.getItem('darkMode') === 'true')

  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark)
    localStorage.setItem('darkMode', String(dark))
  }, [dark])

  return (
    <div className="flex h-screen overflow-hidden" style={{ background: 'var(--bg)' }}>
      {/* Desktop sidebar */}
      <Sidebar dark={dark} onToggleDark={() => setDark((d) => !d)} />

      {/* Main content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Mobile top bar */}
        <MobileNav dark={dark} onToggleDark={() => setDark((d) => !d)} />

        <main
          className="flex-1 overflow-y-auto"
        >
          <Outlet />
        </main>
      </div>

      {/* Chatbot sliding panel */}
      <ChatbotPanel />
    </div>
  )
}

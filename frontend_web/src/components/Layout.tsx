import { useState, useEffect } from 'react'
import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import MobileNav from './MobileNav'

export default function Layout() {
  const [dark, setDark] = useState(() => localStorage.getItem('darkMode') === 'true')

  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark)
    localStorage.setItem('darkMode', String(dark))
  }, [dark])

  return (
    <div className="flex min-h-screen bg-[#F8F7FF] dark:bg-gray-950">
      {/* Desktop sidebar */}
      <Sidebar dark={dark} onToggleDark={() => setDark((d) => !d)} />

      <div className="flex-1 flex flex-col overflow-auto">
        {/* Mobile top bar */}
        <MobileNav dark={dark} onToggleDark={() => setDark((d) => !d)} />
        <main className="flex-1">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

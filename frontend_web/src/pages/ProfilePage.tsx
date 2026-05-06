import { useNavigate } from 'react-router-dom'
import { clearToken, getUserName } from '../hooks/useAuth'

export default function ProfilePage() {
  const navigate  = useNavigate()
  const userName  = getUserName()

  function logout() {
    clearToken()
    navigate('/login')
  }

  return (
    <div className="p-6 max-w-md mx-auto">
      <h1 className="text-2xl font-extrabold text-gray-900 mb-6">Profil</h1>

      {/* Avatar */}
      <div className="flex flex-col items-center mb-8">
        <div
          className="w-20 h-20 rounded-full flex items-center justify-center text-white text-3xl mb-3"
          style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
        >
          👤
        </div>
        <p className="text-lg font-bold text-gray-900">{userName || 'Kullanıcı'}</p>
      </div>

      {/* Actions */}
      <div className="bg-white rounded-2xl border border-gray-100 divide-y divide-gray-100">
        <div className="px-5 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-xl">🏆</span>
            <span className="font-semibold text-sm text-gray-800">Uygulama Versiyonu</span>
          </div>
          <span className="text-sm text-gray-400 font-medium">v1.0.0</span>
        </div>

        <button
          onClick={logout}
          className="w-full px-5 py-4 flex items-center gap-3 hover:bg-red-50 transition"
        >
          <span className="text-xl">🚪</span>
          <span className="font-semibold text-sm text-red-600">Çıkış Yap</span>
        </button>
      </div>
    </div>
  )
}

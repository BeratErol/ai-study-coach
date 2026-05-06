import { useState, type FormEvent } from 'react'
import { useNavigate, Link, useLocation } from 'react-router-dom'
import api from '../services/api'
import { setToken } from '../hooks/useAuth'
import { getUserId } from '../services/tokenService'
import { isOnboardingCompleted, setOnboardingCompleted } from '../services/userPrefsService'

export default function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const successMessage = (location.state as any)?.message ?? null

  const [email, setEmail]       = useState('')
  const [password, setPassword] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [loading, setLoading]   = useState(false)
  const [error, setError]       = useState<string | null>(null)

  async function checkOnboardingStatus() {
    try {
      await api.get('/UserProfile')
      const userId = getUserId() ?? ''
      setOnboardingCompleted(userId, true)
      navigate('/dashboard')
    } catch (err: any) {
      if (err.response?.status === 404) {
        navigate('/onboarding')
      } else {
        const userId = getUserId() ?? ''
        const completed = isOnboardingCompleted(userId)
        navigate(completed ? '/dashboard' : '/onboarding')
      }
    }
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    if (!email || !password) { setError('Lütfen tüm alanları doldurun.'); return }
    if (!email.includes('@')) { setError('Geçerli bir e-posta girin.'); return }

    setLoading(true)
    try {
      const res = await api.post('/Auth/login', { email, password })
      setToken(res.data.token)
      await checkOnboardingStatus()
    } catch (err: any) {
      setError(err.response?.data?.error || 'Giriş başarısız. Bilgilerinizi kontrol edin.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col">
      <div
        className="h-[42vh] flex flex-col items-center justify-center gap-4"
        style={{ background: 'linear-gradient(135deg, #4F46E5 0%, #7C3AED 100%)' }}
      >
        <div className="w-20 h-20 bg-white/20 rounded-3xl flex items-center justify-center">
          <span className="text-4xl">🎓</span>
        </div>
        <h1 className="text-white text-4xl font-bold tracking-tight">AI Study Coach</h1>
        <p className="text-white/70 text-base">Koçun seni bekliyor</p>
      </div>

      <div className="flex-1 bg-gray-50 flex justify-center px-4 pt-0 pb-12">
        <div className="w-full max-w-lg bg-white rounded-3xl shadow-lg border border-gray-100 p-10 h-fit -mt-10">
          <h2 className="text-3xl font-bold text-gray-900 mb-1">Giriş Yap</h2>
          <p className="text-gray-500 text-base mb-8">Hesabınla devam et</p>

          {successMessage && (
            <div className="mb-5 p-4 bg-green-50 border border-green-200 rounded-xl text-green-700 text-sm font-medium">
              ✓ {successMessage}
            </div>
          )}

          {error && (
            <div className="mb-5 p-4 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-base font-semibold text-gray-700 mb-2">E-posta</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="ornek@email.com"
                className="w-full border-2 border-gray-200 rounded-2xl px-5 py-4 text-base focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50 outline-none transition-all"
              />
            </div>

            <div>
              <label className="block text-base font-semibold text-gray-700 mb-2">Şifre</label>
              <div className="relative">
                <input
                  type={showPass ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full border-2 border-gray-200 rounded-2xl px-5 py-4 text-base focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50 outline-none transition-all pr-14"
                />
                <button
                  type="button"
                  onClick={() => setShowPass(!showPass)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 p-1"
                >
                  {showPass ? '🙈' : '👁️'}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-400 text-white font-bold py-4 rounded-2xl text-lg mt-2 transition-all shadow-md hover:shadow-lg cursor-pointer"
            >
              {loading ? 'Giriş yapılıyor...' : 'Giriş Yap'}
            </button>
          </form>

          <p className="text-center text-base text-gray-500 mt-6">
            Hesabın yok mu?{' '}
            <Link to="/register" className="text-indigo-600 font-semibold hover:text-indigo-700">
              Kayıt Ol
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}

import { useState, type FormEvent } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import api from '../services/api'

export default function RegisterPage() {
  const navigate = useNavigate()
  const [email, setEmail]         = useState('')
  const [password, setPassword]   = useState('')
  const [password2, setPassword2] = useState('')
  const [showPass, setShowPass]   = useState(false)
  const [showPass2, setShowPass2] = useState(false)
  const [loading, setLoading]     = useState(false)
  const [error, setError]         = useState<string | null>(null)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    if (!email.includes('@')) { setError('Geçerli bir e-posta girin.'); return }
    if (password.length < 6) { setError('Şifre en az 6 karakter olmalı.'); return }
    if (password !== password2) { setError('Şifreler eşleşmiyor.'); return }

    setLoading(true)
    try {
      const fullName = email.split('@')[0]
      await api.post('/Auth/register', { fullName, email, password })
      navigate('/login', { state: { message: 'Hesabın oluşturuldu! Şimdi giriş yap.' } })
    } catch (err: any) {
      setError(err.response?.data?.error || 'Kayıt sırasında bir hata oluştu.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col" style={{ background: '#F8F7FF' }}>
      <div
        className="flex flex-col items-center justify-center gap-6 shrink-0"
        style={{
          background: 'linear-gradient(135deg, #4F46E5 0%, #7C3AED 100%)',
          minHeight: '33vh',
        }}
      >
        <div className="w-24 h-24 bg-white/20 rounded-3xl flex items-center justify-center">
          <span className="text-5xl">🎓</span>
        </div>
        <h1 className="text-white text-5xl font-extrabold tracking-tight">Hesap Oluştur</h1>
        <p className="text-white/75 text-xl">Ücretsiz başla</p>
      </div>

      <div className="flex-1 flex items-start justify-center px-4 pt-10 pb-16">
        <div className="w-full max-w-xl bg-white rounded-3xl shadow-xl border border-gray-100 px-12 pt-14 pb-12">
          <h2 className="text-4xl font-extrabold text-gray-900">Kayıt Ol</h2>
          <p className="text-gray-500 text-lg mt-2 mb-7">Yeni hesabını oluştur</p>

          {error && (
            <div className="mb-8 px-6 py-5 bg-red-50 border border-red-200 rounded-xl text-red-600 text-base">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-lg font-semibold text-gray-700 mb-2">E-posta</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="ornek@email.com"
                className="w-full h-16 border-2 border-gray-200 rounded-xl px-6 text-lg focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50 outline-none transition-all"
              />
            </div>

            <div>
              <label className="block text-lg font-semibold text-gray-700 mb-2">Şifre</label>
              <div className="relative">
                <input
                  type={showPass ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="En az 6 karakter"
                  className="w-full h-16 border-2 border-gray-200 rounded-xl px-6 pr-16 text-lg focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50 outline-none transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPass(!showPass)}
                  className="absolute right-5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 p-1 text-xl"
                >
                  {showPass ? '🙈' : '👁️'}
                </button>
              </div>
            </div>

            <div>
              <label className="block text-lg font-semibold text-gray-700 mb-2">Şifre Tekrar</label>
              <div className="relative">
                <input
                  type={showPass2 ? 'text' : 'password'}
                  value={password2}
                  onChange={(e) => setPassword2(e.target.value)}
                  placeholder="Şifreni tekrar gir"
                  className="w-full h-16 border-2 border-gray-200 rounded-xl px-6 pr-16 text-lg focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50 outline-none transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPass2(!showPass2)}
                  className="absolute right-5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 p-1 text-xl"
                >
                  {showPass2 ? '🙈' : '👁️'}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full h-14 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-400 text-white font-bold rounded-xl text-lg mt-2 transition-all shadow-md hover:shadow-lg cursor-pointer"
            >
              {loading ? 'Kayıt yapılıyor...' : 'Kayıt Ol'}
            </button>
          </form>

          <p className="text-center text-lg text-gray-500 mt-10">
            Zaten hesabın var mı?{' '}
            <Link to="/login" className="text-indigo-600 font-semibold hover:text-indigo-700">
              Giriş Yap
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}

import { useState, type FormEvent } from 'react'
import { useNavigate, Link, useLocation } from 'react-router-dom'
import api from '../services/api'
import { setToken } from '../hooks/useAuth'
import { getUserId } from '../services/tokenService'
import { setOnboardingCompleted, getOnboardingData, saveOnboardingData } from '../services/userPrefsService'
import { generateAndStorePlan } from '../services/studyPlanLocal'
import { hydrateAppState } from '../services/appStateService'
import { useChatbotStore } from '../stores/chatbotStore'
import { defaultOnboardingData, type OnboardingData } from '../models/OnboardingData'

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
    const userId = getUserId() ?? ''

    // Tek doğruluk kaynağı: backend'de UserProfile kaydı varsa onboarding
    // tamamlanmıştır. Her cihazda (mobil/web) aynı sonucu verir.
    let profile: any = null
    try {
      const res = await api.get('/UserProfile')
      if (res.status === 200 && res.data) profile = res.data
    } catch (err: any) {
      if (err.response?.status === 404) {
        // Profil yok → yeni kullanıcı. Sohbet store'u önceki kullanıcıdan
        // kalmasın diye sıfırla, sonra onboarding'e yönlendir.
        useChatbotStore.getState().reloadFromCache()
        navigate('/onboarding')
        return
      }
      // Ağ/sunucu hatası → karar veremiyoruz; kullanıcı tekrar denesin
      setError('Sunucuya ulaşılamadı. Lütfen tekrar deneyin.')
      return
    }

    if (!profile) {
      useChatbotStore.getState().reloadFromCache()
      navigate('/onboarding')
      return
    }

    // Profil var → onboarding tamamlandı. Backend AppState tek doğruluk
    // kaynağıdır: hydrate ile sohbetler, planlar, notlar vb. local cache'e
    // indirilir. Web kendi local plan'ını geri yazmaz — mobilden gelen
    // güncel plan korunur, böylece iki cihaz her zaman senkron.
    setOnboardingCompleted(userId, true)
    await hydrateAppState()
    // Sohbet store'u indirilen cache'le yenile (Zustand store login öncesi
    // initialize olmuş olabilir).
    useChatbotStore.getState().reloadFromCache()

    if (!getOnboardingData(userId)) {
      const p = profile
      const data: OnboardingData = {
        ...defaultOnboardingData,
        gender: p.gender ?? '',
        educationLevel: p.educationLevel ?? '',
        targetExam: p.targetExam ?? '',
        selectedArea: p.selectedArea ?? '',
        examDate: p.examDate ?? null,
        studyType: p.studyType ?? '',
        hasWeekdaySchool: p.hasWeekdaySchool ?? false,
        weekdayStartTime: p.weekdayStartTime || defaultOnboardingData.weekdayStartTime,
        weekdayEndTime: p.weekdayEndTime || defaultOnboardingData.weekdayEndTime,
        weekdayStudyHours: p.weekdayStudyHours ?? defaultOnboardingData.weekdayStudyHours,
        hasWeekendCourse: p.hasWeekendCourse ?? false,
        weekendStartTime: p.weekendStartTime || defaultOnboardingData.weekendStartTime,
        weekendStudyHours: p.weekendStudyHours ?? defaultOnboardingData.weekendStudyHours,
        weekdayLatestTime: p.weekdayLatestTime || defaultOnboardingData.weekdayLatestTime,
        weekendLatestTime: p.weekendLatestTime || defaultOnboardingData.weekendLatestTime,
        offDays: Array.isArray(p.offDays) ? p.offDays : [],
        strongSubjects: Array.isArray(p.strongSubjects) ? p.strongSubjects : [],
        weakSubjects: Array.isArray(p.weakSubjects) ? p.weakSubjects : [],
      }
      saveOnboardingData(userId, data)
      generateAndStorePlan(userId, data)
    }
    navigate('/dashboard')
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
        <h1 className="text-white text-5xl font-extrabold tracking-tight">AI Study Coach</h1>
        <p className="text-white/75 text-xl">Koçun seni bekliyor</p>
      </div>

      <div className="flex-1 flex items-start justify-center px-4 pt-10 pb-16">
        <div className="w-full max-w-xl bg-white rounded-3xl shadow-xl border border-gray-100 px-12 pt-14 pb-12">
          <h2 className="text-4xl font-extrabold text-gray-900">Giriş Yap</h2>
          <p className="text-gray-500 text-lg mt-2 mb-7">Hesabınla devam et</p>

          {successMessage && (
            <div className="mb-8 px-6 py-5 bg-green-50 border border-green-200 rounded-xl text-green-700 text-base font-medium">
              ✓ {successMessage}
            </div>
          )}

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
                  placeholder="••••••••"
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

            <button
              type="submit"
              disabled={loading}
              className="w-full h-14 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-400 text-white font-bold rounded-xl text-lg mt-2 transition-all shadow-md hover:shadow-lg cursor-pointer"
            >
              {loading ? 'Giriş yapılıyor...' : 'Giriş Yap'}
            </button>
          </form>

          <p className="text-center text-lg text-gray-500 mt-10">
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

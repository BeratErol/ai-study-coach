import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { clearToken, getUserName } from '../hooks/useAuth'
import { useUserProfile } from '../hooks/useUserProfile'
import { getSubjectsForExam } from '../data/subjectsData'
import api from '../services/api'
import { gelisimimService, type XpInfo } from '../services/gelisimimService'
import { getQuickNotes, saveQuickNotes, type QuickNote } from '../services/localData'
import { getUserId } from '../services/tokenService'
import { getOnboardingData, saveOnboardingData } from '../services/userPrefsService'
import { generateAndStorePlan } from '../services/studyPlanLocal'
import { defaultOnboardingData } from '../models/OnboardingData'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function daysUntil(dateStr: string | null | undefined): number | null {
  if (!dateStr) return null
  const d = new Date(dateStr)
  const now = new Date()
  now.setHours(0, 0, 0, 0)
  d.setHours(0, 0, 0, 0)
  const diff = Math.round((d.getTime() - now.getTime()) / 86400000)
  return diff >= 0 ? diff : null
}

function Skeleton({ className }: { className?: string }) {
  return (
    <div
      className={`animate-pulse rounded-xl ${className ?? ''}`}
      style={{ background: 'var(--border)' }}
    />
  )
}

// ─── Section Card ─────────────────────────────────────────────────────────────

function SectionCard({
  title,
  children,
  action,
}: {
  title: React.ReactNode
  children: React.ReactNode
  action?: React.ReactNode
}) {
  return (
    <div
      className="rounded-3xl overflow-hidden shadow-md"
      style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
    >
      <div
        className="px-6 py-5 flex items-center justify-between"
        style={{ borderBottom: '1px solid var(--border)' }}
      >
        <h2 className="text-xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
          {title}
        </h2>
        {action}
      </div>
      <div className="px-6 py-5">{children}</div>
    </div>
  )
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function ProfilePage() {
  const navigate = useNavigate()
  const userName = getUserName()
  const { profile, loading: profileLoading, refresh: refreshProfile } = useUserProfile()

  const [xp, setXp] = useState<XpInfo | null>(null)
  const [notes, setNotes] = useState<QuickNote[]>([])
  const [noteInput, setNoteInput] = useState('')
  const [dark, setDark] = useState(() => document.documentElement.classList.contains('dark'))
  const [examDateEdit, setExamDateEdit] = useState(false)
  const [examDateValue, setExamDateValue] = useState('')
  const [savingDate, setSavingDate] = useState(false)
  const [subjectEditMode, setSubjectEditMode] = useState(false)
  const [editStrong, setEditStrong] = useState<string[]>([])
  const [editWeak, setEditWeak] = useState<string[]>([])
  const [savingSubjects, setSavingSubjects] = useState(false)

  useEffect(() => {
    gelisimimService.getXpInfo().then(setXp).catch(() => {})
    setNotes(getQuickNotes())
  }, [])

  useEffect(() => {
    if (profile?.examDate) {
      setExamDateValue(profile.examDate.split('T')[0])
    }
    if (profile) {
      setEditStrong(profile.strongSubjects ?? [])
      setEditWeak(profile.weakSubjects ?? [])
    }
  }, [profile])

  function toggleDark() {
    const next = !dark
    setDark(next)
    document.documentElement.classList.toggle('dark', next)
    localStorage.setItem('darkMode', String(next))
  }

  function logout() {
    clearToken()
    navigate('/login')
  }

  function addNote() {
    const content = noteInput.trim()
    if (!content) return
    const note: QuickNote = {
      id: `note-${Date.now()}`,
      content,
      createdAt: new Date().toISOString(),
    }
    setNotes((n) => {
      const next = [note, ...n]
      saveQuickNotes(next)
      return next
    })
    setNoteInput('')
  }

  function deleteNote(id: string) {
    setNotes((n) => {
      const next = n.filter((x) => x.id !== id)
      saveQuickNotes(next)
      return next
    })
  }

  /** Profili backend'e (POST = upsert) gönderir, localStorage'ı senkron tutar, planı yeniden üretir. */
  async function persistProfile(patch: Partial<typeof profile>) {
    const merged = { ...(profile ?? {}), ...patch }
    await api.post('/UserProfile', merged)
    const userId = getUserId()
    if (userId) {
      const local = getOnboardingData(userId) ?? { ...defaultOnboardingData }
      const updated = { ...local, ...patch }
      saveOnboardingData(userId, updated)
      generateAndStorePlan(userId, updated)
    }
    await refreshProfile()
  }

  async function saveExamDate() {
    if (!examDateValue) return
    setSavingDate(true)
    try {
      await persistProfile({ examDate: examDateValue })
      setExamDateEdit(false)
    } catch {}
    setSavingDate(false)
  }

  async function saveSubjects() {
    setSavingSubjects(true)
    try {
      await persistProfile({ strongSubjects: editStrong, weakSubjects: editWeak })
      setSubjectEditMode(false)
    } catch {}
    setSavingSubjects(false)
  }

  function toggleSubject(list: string[], setList: (v: string[]) => void, name: string) {
    setList(list.includes(name) ? list.filter((s) => s !== name) : [...list, name])
  }

  const xpProgress = xp ? Math.min(1, xp.currentXp / Math.max(1, xp.xpForNextLevel)) : 0
  const daysLeft = daysUntil(profile?.examDate)
  const allSubjects = profile
    ? getSubjectsForExam(profile.targetExam, profile.selectedArea)
    : []

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <div className="min-h-screen" style={{ background: 'var(--bg)' }}>
      {/* ── Profile Header Banner ──────────────────────────────────────────── */}
      <div
        className="relative overflow-hidden"
        style={{ background: 'linear-gradient(135deg, #0F0C29 0%, #1A1A2E 40%, #2D1B69 100%)' }}
      >
        {/* Decorative blobs */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background:
              'radial-gradient(circle at 80% 50%, rgba(109,40,217,0.25) 0%, transparent 60%)',
          }}
        />
        <div
          className="absolute top-0 left-0 w-72 h-72 rounded-full opacity-10 pointer-events-none"
          style={{
            background: 'radial-gradient(circle, #818CF8, transparent)',
            transform: 'translate(-40%, -40%)',
          }}
        />

        <div className="relative max-w-7xl mx-auto px-10 py-12">
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-7">
            {/* Avatar */}
            <div
              className="w-32 h-32 rounded-3xl flex items-center justify-center text-6xl font-extrabold text-white shadow-2xl flex-shrink-0"
              style={{
                background: 'linear-gradient(135deg, #4F46E5, #7C3AED)',
                border: '3px solid rgba(255,255,255,0.2)',
              }}
            >
              {(profile?.name ?? userName)?.[0]?.toUpperCase() || '?'}
            </div>

            {/* Name + Info */}
            <div className="flex-1 min-w-0">
              <h1 className="text-5xl font-extrabold text-white tracking-tight uppercase">
                {profile?.name ?? userName ?? 'Öğrenci'}
              </h1>
              {profile?.targetExam && (
                <p className="text-white/60 text-base mt-1">
                  🎓 {profile.targetExam}
                  {profile.selectedArea ? ` · ${profile.selectedArea}` : ''}
                </p>
              )}

              {/* XP Progress */}
              {xp && (
                <div className="mt-4 max-w-sm">
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-white/80 text-sm font-semibold">
                      {xp.levelEmoji} Seviye {xp.level} — {xp.levelName}
                    </span>
                    <span className="text-white/50 text-xs">
                      {xp.currentXp.toLocaleString('tr-TR')} / {xp.xpForNextLevel.toLocaleString('tr-TR')} XP
                    </span>
                  </div>
                  <div className="h-2.5 rounded-full overflow-hidden" style={{ background: 'rgba(255,255,255,0.15)' }}>
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{
                        width: `${xpProgress * 100}%`,
                        background: 'linear-gradient(90deg, #818CF8, #C084FC)',
                      }}
                    />
                  </div>
                </div>
              )}
            </div>

            {/* Badges */}
            <div className="flex flex-col sm:flex-row gap-3 self-start">
              {xp && (
                <div
                  className="flex items-center gap-2 px-4 py-3 rounded-2xl"
                  style={{ background: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.2)' }}
                >
                  <span className="text-2xl">{xp.levelEmoji}</span>
                  <div>
                    <p className="text-white/60 text-[10px] uppercase tracking-widest font-bold">Seviye</p>
                    <p className="text-white font-extrabold text-xl leading-none">{xp.level}</p>
                  </div>
                </div>
              )}
              {xp?.streakDays ? (
                <div
                  className="flex items-center gap-2 px-4 py-3 rounded-2xl"
                  style={{ background: 'rgba(249,115,22,0.2)', border: '1px solid rgba(249,115,22,0.4)' }}
                >
                  <span className="text-2xl">🔥</span>
                  <div>
                    <p className="text-orange-300 text-[10px] uppercase tracking-widest font-bold">Seri</p>
                    <p className="text-white font-extrabold text-xl leading-none">{xp.streakDays} gün</p>
                  </div>
                </div>
              ) : null}
            </div>
          </div>
        </div>
      </div>

      {/* ── Body ──────────────────────────────────────────────────────────── */}
      <div className="max-w-7xl mx-auto px-10 py-10 space-y-7">
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          {/* Left Column */}
          <div className="xl:col-span-2 space-y-6">
            {/* XP / Level Card */}
            {xp && (
              <div
                className="rounded-3xl p-6 shadow-md overflow-hidden relative"
                style={{
                  background: 'linear-gradient(135deg, #1E1B4B 0%, #312E81 100%)',
                }}
              >
                <div className="relative flex items-center gap-5">
                  <div
                    className="w-16 h-16 rounded-2xl flex items-center justify-center text-4xl flex-shrink-0"
                    style={{ background: 'rgba(255,255,255,0.12)' }}
                  >
                    {xp.levelEmoji}
                  </div>
                  <div className="flex-1">
                    <p className="text-white/60 text-sm font-semibold uppercase tracking-widest">
                      Mevcut Seviye
                    </p>
                    <p className="text-3xl font-extrabold text-white mt-0.5">
                      {xp.level} — {xp.levelName}
                    </p>
                    <div className="mt-3">
                      <div className="flex justify-between text-xs text-white/50 mb-1.5 font-medium">
                        <span>{xp.currentXp.toLocaleString('tr-TR')} XP</span>
                        <span>Seviye {xp.level + 1} için {xp.xpForNextLevel.toLocaleString('tr-TR')} XP</span>
                      </div>
                      <div className="h-3 rounded-full overflow-hidden" style={{ background: 'rgba(255,255,255,0.15)' }}>
                        <div
                          className="h-full rounded-full transition-all duration-700"
                          style={{
                            width: `${xpProgress * 100}%`,
                            background: 'linear-gradient(90deg, #818CF8, #C084FC)',
                          }}
                        />
                      </div>
                      <p className="text-xs text-white/40 mt-1.5 text-right">
                        %{Math.round(xpProgress * 100)} tamamlandı
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Akademik Hedefim */}
            <SectionCard
              title="🎯 Akademik Hedefim"
              action={
                !examDateEdit ? (
                  <button
                    onClick={() => setExamDateEdit(true)}
                    className="px-4 py-1.5 rounded-xl text-sm font-semibold transition-all hover:opacity-80"
                    style={{ background: '#EEF2FF', color: '#4F46E5' }}
                  >
                    ✏️ Düzenle
                  </button>
                ) : null
              }
            >
              {profileLoading ? (
                <div className="space-y-3">
                  <Skeleton className="h-5 w-1/2" />
                  <Skeleton className="h-5 w-1/3" />
                </div>
              ) : profile ? (
                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <InfoItem label="Hedef Sınav" value={profile.targetExam} icon="📚" />
                    <InfoItem label="Alan" value={profile.selectedArea || '—'} icon="🗂️" />
                  </div>

                  {/* Exam date */}
                  <div>
                    <p className="text-xs font-bold uppercase tracking-widest mb-2" style={{ color: 'var(--text-hint)' }}>
                      📅 Sınav Tarihi
                    </p>
                    {examDateEdit ? (
                      <div className="flex items-center gap-3">
                        <input
                          type="date"
                          value={examDateValue}
                          onChange={(e) => setExamDateValue(e.target.value)}
                          className="flex-1 px-4 py-2.5 rounded-2xl text-base outline-none"
                          style={{
                            background: 'var(--bg)',
                            border: '2px solid #4F46E5',
                            color: 'var(--text-primary)',
                          }}
                        />
                        <button
                          onClick={saveExamDate}
                          disabled={savingDate}
                          className="px-4 py-2.5 rounded-2xl text-sm font-bold text-white disabled:opacity-60"
                          style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
                        >
                          {savingDate ? '...' : 'Kaydet'}
                        </button>
                        <button
                          onClick={() => setExamDateEdit(false)}
                          className="px-4 py-2.5 rounded-2xl text-sm font-semibold"
                          style={{
                            background: 'var(--bg)',
                            color: 'var(--text-secondary)',
                            border: '1px solid var(--border)',
                          }}
                        >
                          İptal
                        </button>
                      </div>
                    ) : (
                      <div className="flex items-center gap-4">
                        <p className="text-2xl font-extrabold" style={{ color: 'var(--text-primary)' }}>
                          {profile.examDate
                            ? new Date(profile.examDate).toLocaleDateString('tr-TR', {
                                day: 'numeric',
                                month: 'long',
                                year: 'numeric',
                              })
                            : 'Belirtilmemiş'}
                        </p>
                        {daysLeft !== null && (
                          <span
                            className="px-3 py-1 rounded-full text-sm font-bold"
                            style={{
                              background:
                                daysLeft < 30
                                  ? '#FEF2F2'
                                  : daysLeft < 90
                                  ? '#FFFBEB'
                                  : '#F0FDF4',
                              color:
                                daysLeft < 30
                                  ? '#EF4444'
                                  : daysLeft < 90
                                  ? '#F59E0B'
                                  : '#10B981',
                            }}
                          >
                            {daysLeft} gün kaldı
                          </span>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              ) : (
                <p className="text-sm" style={{ color: 'var(--text-hint)' }}>
                  Profil bilgisi yüklenemedi.
                </p>
              )}
            </SectionCard>

            {/* Ders Profilim */}
            <SectionCard
              title="📖 Ders Profilim"
              action={
                <button
                  onClick={() => setSubjectEditMode((v) => !v)}
                  className="px-4 py-1.5 rounded-xl text-sm font-semibold transition-all hover:opacity-80"
                  style={{ background: '#EEF2FF', color: '#4F46E5' }}
                >
                  {subjectEditMode ? '✕ Kapat' : '✏️ Düzenle'}
                </button>
              }
            >
              {profileLoading ? (
                <div className="space-y-3">
                  <Skeleton className="h-4 w-1/4" />
                  <div className="flex gap-2 flex-wrap">
                    {[1, 2, 3].map((i) => <Skeleton key={i} className="h-8 w-24" />)}
                  </div>
                </div>
              ) : subjectEditMode ? (
                <div className="space-y-5">
                  <div>
                    <p className="text-sm font-bold mb-3" style={{ color: '#10B981' }}>
                      💪 Güçlü Derslerim
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {allSubjects.map((s) => {
                        const active = editStrong.includes(s.name)
                        return (
                          <button
                            key={s.name}
                            onClick={() => toggleSubject(editStrong, setEditStrong, s.name)}
                            className="px-3 py-1.5 rounded-full text-xs font-semibold transition-all"
                            style={{
                              background: active ? '#D1FAE5' : 'var(--bg)',
                              color: active ? '#065F46' : 'var(--text-secondary)',
                              border: `2px solid ${active ? '#10B981' : 'var(--border)'}`,
                            }}
                          >
                            {s.emoji} {s.name}
                          </button>
                        )
                      })}
                    </div>
                  </div>
                  <div>
                    <p className="text-sm font-bold mb-3" style={{ color: '#EF4444' }}>
                      📌 Geliştireceğim Dersler
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {allSubjects.map((s) => {
                        const active = editWeak.includes(s.name)
                        return (
                          <button
                            key={s.name}
                            onClick={() => toggleSubject(editWeak, setEditWeak, s.name)}
                            className="px-3 py-1.5 rounded-full text-xs font-semibold transition-all"
                            style={{
                              background: active ? '#FEE2E2' : 'var(--bg)',
                              color: active ? '#991B1B' : 'var(--text-secondary)',
                              border: `2px solid ${active ? '#EF4444' : 'var(--border)'}`,
                            }}
                          >
                            {s.emoji} {s.name}
                          </button>
                        )
                      })}
                    </div>
                  </div>
                  <div className="flex gap-3 pt-2" style={{ borderTop: '1px solid var(--border)' }}>
                    <button
                      onClick={saveSubjects}
                      disabled={savingSubjects}
                      className="px-5 py-2.5 rounded-2xl text-sm font-bold text-white disabled:opacity-60"
                      style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
                    >
                      {savingSubjects ? 'Kaydediliyor...' : '💾 Kaydet'}
                    </button>
                    <button
                      onClick={() => setSubjectEditMode(false)}
                      className="px-5 py-2.5 rounded-2xl text-sm font-semibold"
                      style={{
                        background: 'var(--bg)',
                        color: 'var(--text-secondary)',
                        border: '1px solid var(--border)',
                      }}
                    >
                      İptal
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  {(profile?.strongSubjects ?? []).length > 0 ? (
                    <div>
                      <p className="text-xs font-bold mb-2 uppercase tracking-widest" style={{ color: '#10B981' }}>
                        💪 Güçlü Dersler
                      </p>
                      <div className="flex flex-wrap gap-2">
                        {(profile?.strongSubjects ?? []).map((s) => (
                          <span
                            key={s}
                            className="px-3 py-1.5 rounded-full text-xs font-bold"
                            style={{ background: '#D1FAE5', color: '#065F46' }}
                          >
                            ✅ {s}
                          </span>
                        ))}
                      </div>
                    </div>
                  ) : null}

                  {(profile?.weakSubjects ?? []).length > 0 ? (
                    <div>
                      <p className="text-xs font-bold mb-2 uppercase tracking-widest" style={{ color: '#EF4444' }}>
                        📌 Geliştireceğim Dersler
                      </p>
                      <div className="flex flex-wrap gap-2">
                        {(profile?.weakSubjects ?? []).map((s) => (
                          <span
                            key={s}
                            className="px-3 py-1.5 rounded-full text-xs font-bold"
                            style={{ background: '#FEE2E2', color: '#991B1B' }}
                          >
                            📌 {s}
                          </span>
                        ))}
                      </div>
                    </div>
                  ) : null}

                  {(profile?.strongSubjects ?? []).length === 0 &&
                    (profile?.weakSubjects ?? []).length === 0 && (
                      <p className="text-sm" style={{ color: 'var(--text-hint)' }}>
                        Henüz ders profili oluşturulmadı. "Düzenle" ile ekleyebilirsiniz.
                      </p>
                    )}
                </div>
              )}
            </SectionCard>

            {/* Zaman ve Biyoritim */}
            <SectionCard title="⏰ Zaman ve Çalışma Düzenim">
              {profileLoading ? (
                <div className="grid grid-cols-2 gap-4">
                  {[1, 2, 3, 4].map((i) => <Skeleton key={i} className="h-20" />)}
                </div>
              ) : profile ? (
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                  {[
                    { icon: '📅', label: 'Hafta içi', value: `${profile.weekdayStudyHours} saat/gün`, color: '#4F46E5' },
                    { icon: '🌅', label: 'Hafta sonu', value: `${profile.weekendStudyHours} saat/gün`, color: '#6D28D9' },
                    { icon: '🧠', label: 'Çalışma Tipi', value: profile.studyType || '—', color: '#10B981' },
                    { icon: '🎯', label: 'Hedef Sınav', value: profile.targetExam || '—', color: '#F59E0B' },
                  ].map((item) => (
                    <div
                      key={item.label}
                      className="rounded-2xl p-4 text-center"
                      style={{ background: `${item.color}12`, border: `1px solid ${item.color}30` }}
                    >
                      <p className="text-3xl mb-2">{item.icon}</p>
                      <p className="text-xs font-bold uppercase tracking-widest mb-1" style={{ color: item.color }}>
                        {item.label}
                      </p>
                      <p className="text-base font-extrabold" style={{ color: 'var(--text-primary)' }}>
                        {item.value}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm" style={{ color: 'var(--text-hint)' }}>
                  Bilgi yüklenemedi.
                </p>
              )}
            </SectionCard>

            {/* Sınav Tarihi Countdown */}
            {daysLeft !== null && (
              <div
                className="rounded-3xl p-6 shadow-md text-center relative overflow-hidden"
                style={{
                  background:
                    daysLeft < 30
                      ? 'linear-gradient(135deg, #7F1D1D, #991B1B)'
                      : daysLeft < 90
                      ? 'linear-gradient(135deg, #78350F, #92400E)'
                      : 'linear-gradient(135deg, #064E3B, #065F46)',
                }}
              >
                <div
                  className="absolute inset-0 pointer-events-none"
                  style={{
                    background: 'radial-gradient(circle at 50% 120%, rgba(255,255,255,0.08), transparent 60%)',
                  }}
                />
                <p className="text-white/60 text-sm font-bold uppercase tracking-widest">
                  {profile?.targetExam ?? 'Sınav'} tarihine kalan
                </p>
                <p className="text-8xl font-extrabold text-white mt-2 leading-none">{daysLeft}</p>
                <p className="text-white/70 text-xl font-semibold mt-1">gün</p>
                {profile?.examDate && (
                  <p className="text-white/40 text-sm mt-3">
                    {new Date(profile.examDate).toLocaleDateString('tr-TR', {
                      day: 'numeric',
                      month: 'long',
                      year: 'numeric',
                    })}
                  </p>
                )}
              </div>
            )}
          </div>

          {/* Right Column */}
          <div className="space-y-6">
            {/* Quick Notes */}
            <div
              className="rounded-3xl overflow-hidden shadow-md"
              style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
            >
              <div className="px-5 py-5" style={{ borderBottom: '1px solid var(--border)' }}>
                <h2 className="text-lg font-extrabold" style={{ color: 'var(--text-primary)' }}>
                  📝 Notlarım
                </h2>
                <p className="text-sm mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                  Hızlı not al, anında kaydet
                </p>
              </div>
              <div className="px-5 py-5 space-y-4">
                <div className="flex gap-2">
                  <input
                    value={noteInput}
                    onChange={(e) => setNoteInput(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && addNote()}
                    placeholder="Not ekle..."
                    className="flex-1 px-4 py-3 rounded-2xl text-sm outline-none"
                    style={{
                      background: 'var(--bg)',
                      border: '2px solid var(--border)',
                      color: 'var(--text-primary)',
                    }}
                    onFocus={(e) => (e.currentTarget.style.borderColor = '#4F46E5')}
                    onBlur={(e) => (e.currentTarget.style.borderColor = 'var(--border)')}
                  />
                  <button
                    onClick={addNote}
                    className="px-4 py-3 rounded-2xl text-sm font-bold text-white hover:opacity-90 transition-opacity"
                    style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
                  >
                    Ekle
                  </button>
                </div>

                <div className="space-y-2 max-h-72 overflow-y-auto">
                  {notes.length === 0 ? (
                    <div className="text-center py-8" style={{ color: 'var(--text-hint)' }}>
                      <p className="text-4xl mb-2">📌</p>
                      <p className="text-sm">Henüz not yok</p>
                    </div>
                  ) : (
                    notes.map((n) => (
                      <div
                        key={n.id}
                        className="flex items-start gap-3 p-3 rounded-2xl"
                        style={{ background: 'var(--bg)', border: '1px solid var(--border)' }}
                      >
                        <span className="text-lg flex-shrink-0 mt-0.5">📌</span>
                        <p className="flex-1 text-sm leading-relaxed" style={{ color: 'var(--text-primary)' }}>
                          {n.content}
                        </p>
                        <button
                          onClick={() => deleteNote(n.id)}
                          className="text-xs p-1 rounded-lg opacity-50 hover:opacity-100 transition-opacity flex-shrink-0"
                          style={{ color: 'var(--error)' }}
                        >
                          ✕
                        </button>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>

            {/* Settings */}
            <div
              className="rounded-3xl overflow-hidden shadow-md"
              style={{ background: 'var(--card)', border: '1px solid var(--border)' }}
            >
              <div className="px-5 py-5" style={{ borderBottom: '1px solid var(--border)' }}>
                <h2 className="text-lg font-extrabold" style={{ color: 'var(--text-primary)' }}>
                  ⚙️ Ayarlar
                </h2>
              </div>

              {/* Dark Mode Toggle */}
              <button
                onClick={toggleDark}
                className="w-full flex items-center justify-between px-5 py-4 transition-colors"
                style={{ borderBottom: '1px solid var(--border)' }}
                onMouseEnter={(e) => (e.currentTarget.style.background = 'var(--bg)')}
                onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
              >
                <div className="flex items-center gap-3">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center text-xl"
                    style={{ background: dark ? '#312E81' : '#FEF3C7' }}
                  >
                    {dark ? '☀️' : '🌙'}
                  </div>
                  <div className="text-left">
                    <p className="text-sm font-bold" style={{ color: 'var(--text-primary)' }}>
                      {dark ? 'Aydınlık Mod' : 'Karanlık Mod'}
                    </p>
                    <p className="text-xs" style={{ color: 'var(--text-hint)' }}>
                      {dark ? 'Açık temaya geç' : 'Koyu temaya geç'}
                    </p>
                  </div>
                </div>
                {/* Toggle switch */}
                <div
                  className="relative w-12 h-6 rounded-full transition-all duration-300 flex-shrink-0"
                  style={{ background: dark ? 'var(--primary)' : 'var(--border)' }}
                >
                  <div
                    className="absolute top-1 w-4 h-4 rounded-full bg-white shadow-md transition-all duration-300"
                    style={{ left: dark ? '28px' : '4px' }}
                  />
                </div>
              </button>

              {/* Version */}
              <div className="px-5 py-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center text-xl"
                    style={{ background: '#EEF2FF' }}
                  >
                    🏆
                  </div>
                  <div>
                    <p className="text-sm font-bold" style={{ color: 'var(--text-primary)' }}>
                      Uygulama Versiyonu
                    </p>
                    <p className="text-xs" style={{ color: 'var(--text-hint)' }}>
                      AI Study Coach Web
                    </p>
                  </div>
                </div>
                <span
                  className="px-3 py-1 rounded-full text-xs font-bold"
                  style={{ background: '#EEF2FF', color: '#4F46E5' }}
                >
                  v1.0.0
                </span>
              </div>
            </div>

            {/* Logout */}
            <button
              onClick={logout}
              className="w-full flex items-center justify-center gap-3 px-6 py-4 rounded-3xl font-bold text-base transition-all hover:opacity-90 shadow-md"
              style={{
                background: 'linear-gradient(135deg, #DC2626, #991B1B)',
                color: '#fff',
              }}
            >
              <span className="text-xl">🚪</span>
              Çıkış Yap
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── InfoItem Helper ──────────────────────────────────────────────────────────

function InfoItem({ label, value, icon }: { label: string; value: string; icon: string }) {
  return (
    <div
      className="rounded-2xl p-4"
      style={{ background: 'var(--bg)', border: '1px solid var(--border)' }}
    >
      <p className="text-xs font-bold uppercase tracking-widest mb-1" style={{ color: 'var(--text-hint)' }}>
        {icon} {label}
      </p>
      <p className="text-base font-extrabold" style={{ color: 'var(--text-primary)' }}>
        {value || '—'}
      </p>
    </div>
  )
}

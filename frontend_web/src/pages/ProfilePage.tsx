import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { clearToken } from '../hooks/useAuth'
import { getUserId } from '../services/tokenService'
import api from '../services/api'
import { getSubjectsForExam, type SubjectData } from '../data/subjectsData'
import {
  getOnboardingData, saveOnboardingData,
  getExamGoal, saveExamGoal, type ExamGoal,
} from '../services/userPrefsService'
import { generateAndStorePlan, getTodayPlan, resetStudyPlan } from '../services/studyPlanLocal'
import { pushAppState } from '../services/appStateService'
import {
  getQuickNotes, saveQuickNotes, type QuickNote,
  saveTopicAssignments, saveCompletedTaskIds, saveCompletedLessons,
  getCompletedTaskIds, getCompletedLessons,
} from '../services/localData'
import { defaultOnboardingData, type OnboardingData } from '../models/OnboardingData'

// ─── Yardımcılar ──────────────────────────────────────────────────────────────

function daysUntil(dateStr: string | null | undefined): number | null {
  if (!dateStr) return null
  const d = new Date(dateStr)
  const now = new Date()
  now.setHours(0, 0, 0, 0)
  d.setHours(0, 0, 0, 0)
  const diff = Math.round((d.getTime() - now.getTime()) / 86400000)
  return diff > 0 ? diff : null
}

const EDU_LABELS: Record<string, string> = {
  ortaokul: 'Ortaokul',
  lise: 'Lise',
  universite: 'Üniversite / Mezun',
}

const DAY_LABELS = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cts', 'Paz']

// Aynı içerikli dizi mi? (sıra önemsiz)
function sameSet(a: string[] = [], b: string[] = []): boolean {
  if (a.length !== b.length) return false
  const sa = new Set(a), sb = new Set(b)
  for (const x of sa) if (!sb.has(x)) return false
  return true
}

/**
 * Sınav türü / alan / ders havuzu değişti mi?
 * Değiştiyse bugüne ait konu atamaları + tamamlanan dersler artık geçersiz —
 * yeni programın id'leriyle eşleşmez, sıfırlanmalı.
 */
function isSubjectShapeChanged(prev: OnboardingData, next: OnboardingData): boolean {
  return (
    prev.targetExam !== next.targetExam ||
    prev.selectedArea !== next.selectedArea ||
    !sameSet(prev.strongSubjects, next.strongSubjects) ||
    !sameSet(prev.weakSubjects, next.weakSubjects) ||
    !sameSet(prev.customSubjects ?? [], next.customSubjects ?? [])
  )
}

function todayStrLocal(): string {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

// ─── Profil güncelleme yardımcısı ─────────────────────────────────────────────
// localStorage'ı günceller, planı yeniden üretir, backend'e senkronlar.
// Sınav/alan/ders havuzu değiştiyse bugüne ait konu atamaları + tamamlananları
// sıfırlar (eski blok id'leri yeni planla eşleşmez). Sadece saat/biyoritim
// değişikliklerinde tamamlananlar korunur.
async function persistProfile(patch: Partial<OnboardingData>): Promise<OnboardingData | null> {
  const userId = getUserId()
  if (!userId) return null
  const current = getOnboardingData(userId) ?? { ...defaultOnboardingData }
  const updated: OnboardingData = { ...current, ...patch }

  const shapeChanged = isSubjectShapeChanged(current, updated)

  saveOnboardingData(userId, updated)
  // Zayıf ders olmadan anlamlı bir plan oluşturulamaz (uni_diger için
  // customSubjects yeterli sayılır). Bu durumda mevcut planı sıfırla ki
  // dashboard'da eski/yanıltıcı görevler kalmasın; kullanıcı Ders Profilim'den
  // zayıf ders seçince plan tekrar üretilir.
  const isOkulDiger = updated.targetExam === 'OkulSinavi' &&
    updated.selectedArea === 'uni_diger'
  const hasMinimumSubjects = isOkulDiger
    ? (updated.customSubjects?.length ?? 0) > 0
    : updated.weakSubjects.length > 0
  if (hasMinimumSubjects) {
    generateAndStorePlan(userId, updated)
  } else {
    resetStudyPlan(userId)
    pushAppState('weekly_plan', [])
  }

  if (shapeChanged) {
    // Yeni planın id'leri farklı — eski atamalar ve tamamlananlar geçersiz.
    // Bugüne ait olanları sıfırla; geçmiş günler korunur.
    saveTopicAssignments({})
    saveCompletedTaskIds(new Set())
    saveCompletedLessons(todayStrLocal(), [])
  } else {
    // Sadece saat değişti — plan yine yenilendi ama ders havuzu aynı.
    // Yeni planda artık bulunmayan blok id'leri (ders programdan çıkmış olabilir)
    // için tamamlama kayıtlarını sil — yanıltıcı görünmesin.
    const todayStr = todayStrLocal()
    const today = getTodayPlan()
    const validIds = new Set((today?.blocks ?? []).map((b) => b.id))
    // completed_tasks bugünkü id'lerini filtrele
    const cur = getCompletedTaskIds()
    const trimmed = new Set([...cur].filter((id) => validIds.has(id)))
    if (trimmed.size !== cur.size) saveCompletedTaskIds(trimmed)
    // completed_lessons bugünün detaylarını filtrele
    const lessons = getCompletedLessons(todayStr)
    const lessonsTrimmed = lessons.filter((l) => validIds.has(l.id))
    if (lessonsTrimmed.length !== lessons.length) {
      saveCompletedLessons(todayStr, lessonsTrimmed)
    }
  }

  try {
    await api.post('/UserProfile', updated)
  } catch {
    // backend senkronu kritik değil
  }
  return updated
}

// ─── Accordion bölümü ─────────────────────────────────────────────────────────

function Section({ icon, title, color, children, defaultOpen }: {
  icon: string
  title: string
  color: string
  children: React.ReactNode
  defaultOpen?: boolean
}) {
  const [open, setOpen] = useState(defaultOpen ?? false)
  return (
    <div className="rounded-2xl overflow-hidden" style={{ background: 'var(--card)', border: `1.5px solid ${color}40` }}>
      <button
        onClick={() => setOpen((v) => !v)}
        className="w-full flex items-center gap-3 px-5 py-4"
        style={{ background: `${color}14` }}
      >
        <span className="text-2xl">{icon}</span>
        <span className="flex-1 text-left text-lg font-extrabold" style={{ color }}>{title}</span>
        <span className="text-lg" style={{ color: 'var(--text-hint)' }}>{open ? '▲' : '▼'}</span>
      </button>
      {open && <div className="px-5 pb-5 pt-1" style={{ borderTop: `1px solid ${color}40` }}>{children}</div>}
    </div>
  )
}

function Toast({ message }: { message: string }) {
  return (
    <div
      className="fixed bottom-8 left-1/2 -translate-x-1/2 px-6 py-4 rounded-2xl text-white text-base font-bold shadow-xl z-50"
      style={{ background: '#10B981' }}
    >
      {message}
    </div>
  )
}

// Program yenileme onay modalı
function ProgramRefreshConfirm({ onCancel, onConfirm }: { onCancel: () => void; onConfirm: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.6)' }}>
      <div className="w-full max-w-md rounded-3xl p-7 text-center" style={{ background: 'var(--card)' }}>
        <p className="text-5xl mb-3">⚠️</p>
        <h4 className="text-xl font-extrabold mb-2" style={{ color: 'var(--text-primary)' }}>Program Yenilenecek</h4>
        <p className="text-base mb-6" style={{ color: 'var(--text-secondary)' }}>
          Profil bilgilerini güncellediğinde mevcut çalışma programın silinecek ve yeni
          ayarlarına göre baştan oluşturulacak. Devam etmek istiyor musun?
        </p>
        <div className="flex gap-3">
          <button
            onClick={onCancel}
            className="flex-1 py-3.5 rounded-xl text-base font-semibold"
            style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}
          >
            İptal
          </button>
          <button
            onClick={onConfirm}
            className="flex-1 py-3.5 rounded-xl text-base font-bold text-white"
            style={{ background: 'var(--primary)' }}
          >
            Evet, Yenile
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── Notlarım bölümü ──────────────────────────────────────────────────────────

function NotesSection() {
  const [notes, setNotes] = useState<QuickNote[]>(() => getQuickNotes())
  const [confirmId, setConfirmId] = useState<string | null>(null)

  function deleteNote(id: string) {
    const next = notes.filter((x) => x.id !== id)
    setNotes(next)
    saveQuickNotes(next)
    setConfirmId(null)
  }

  if (notes.length === 0) {
    return (
      <div className="text-center py-6">
        <p className="text-4xl mb-2">📝</p>
        <p className="text-base font-semibold" style={{ color: 'var(--text-secondary)' }}>Henüz not eklemedin.</p>
        <p className="text-base mt-1" style={{ color: 'var(--text-hint)' }}>Ana sayfadaki ✏️ butonuyla hızlı not ekle!</p>
      </div>
    )
  }
  return (
    <>
      <div className="space-y-2.5 mt-3">
        {notes.map((n) => (
          <div
            key={n.id}
            className="flex items-start gap-3 px-4 py-3 rounded-xl"
            style={{ background: 'var(--bg)', border: '1px solid var(--border)' }}
          >
            <div className="flex-1 min-w-0">
              <p className="text-base font-bold" style={{ color: 'var(--text-primary)' }}>{n.title}</p>
              <p className="text-base mt-0.5" style={{ color: 'var(--text-secondary)' }}>{n.content}</p>
            </div>
            <button
              onClick={() => setConfirmId(n.id)}
              className="text-base shrink-0"
              style={{ color: 'var(--error)' }}
            >
              ✕
            </button>
          </div>
        ))}
      </div>

      {confirmId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.6)' }}>
          <div className="w-full max-w-sm rounded-3xl p-7 text-center" style={{ background: 'var(--card)' }}>
            <p className="text-5xl mb-3">🗑️</p>
            <h4 className="text-xl font-extrabold mb-2" style={{ color: 'var(--text-primary)' }}>Notu Sil</h4>
            <p className="text-base mb-6" style={{ color: 'var(--text-secondary)' }}>
              Bu notu silmek istediğine emin misin?
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setConfirmId(null)}
                className="flex-1 py-3.5 rounded-xl text-base font-semibold"
                style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}
              >
                İptal
              </button>
              <button
                onClick={() => deleteNote(confirmId)}
                className="flex-1 py-3.5 rounded-xl text-base font-bold text-white"
                style={{ background: 'var(--error)' }}
              >
                Sil
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}

// ─── Akademik Hedef bölümü (sınav + alan değiştirilebilir) ────────────────────

const EXAMS_BY_LEVEL: Record<string, { emoji: string; name: string; value: string }[]> = {
  ortaokul: [
    { emoji: '📋', name: 'LGS', value: 'LGS' },
    { emoji: '🏫', name: 'Okul Sınavlarım', value: 'OkulSinavi' },
  ],
  lise: [
    { emoji: '🎓', name: 'YKS', value: 'YKS' },
    { emoji: '🏫', name: 'Okul Sınavlarım', value: 'OkulSinavi' },
  ],
  universite: [
    { emoji: '🏢', name: 'KPSS', value: 'KPSS' },
    { emoji: '📐', name: 'ALES', value: 'ALES' },
    { emoji: '🌐', name: 'YDS', value: 'YDS' },
    { emoji: '👩‍🏫', name: 'Öğretmenlik', value: 'Öğretmenlik' },
    { emoji: '🏛️', name: 'Okul Sınavlarım', value: 'OkulSinavi' },
  ],
}

const AREAS_BY_EXAM: Record<string, { label: string; value: string }[]> = {
  YKS: [
    { label: 'Sayısal (MF)', value: 'sayisal' },
    { label: 'Eşit Ağırlık (TM)', value: 'esit_agirlik' },
    { label: 'Sözel (TS)', value: 'sozel' },
    { label: 'Dil', value: 'dil' },
    { label: 'Sadece TYT', value: 'sadece_tyt' },
  ],
  KPSS: [
    { label: 'KPSS Lisans', value: 'kpss_lisans' },
    { label: 'KPSS Önlisans', value: 'kpss_onlisans' },
  ],
}

function okulSinaviAreas(eduLevel: string): { label: string; value: string }[] {
  if (eduLevel === 'ortaokul') {
    return [
      { label: '5. Sınıf', value: 'sinif_5' }, { label: '6. Sınıf', value: 'sinif_6' },
      { label: '7. Sınıf', value: 'sinif_7' }, { label: '8. Sınıf', value: 'sinif_8' },
    ]
  }
  if (eduLevel === 'lise') {
    return [
      { label: '9. Sınıf', value: 'lise_9' }, { label: '10. Sınıf', value: 'lise_10' },
      { label: '11-12 Sayısal (MF)', value: 'lise_1112_sayisal' },
      { label: '11-12 Eşit Ağırlık (EA)', value: 'lise_1112_ea' },
      { label: '11-12 Sözel (TS)', value: 'lise_1112_sozel' },
      { label: '11-12 Dil (YDT)', value: 'lise_1112_dil' },
    ]
  }
  return [
    { label: 'Yazılım / Bilgisayar', value: 'uni_yazilim' }, { label: 'Tıp', value: 'uni_tip' },
    { label: 'Hukuk', value: 'uni_hukuk' }, { label: 'Psikoloji', value: 'uni_psikoloji' },
    { label: 'İşletme / Ekonomi', value: 'uni_isletme' }, { label: 'Mühendislik', value: 'uni_muhendislik' },
    { label: 'Eğitim / Öğretmenlik', value: 'uni_egitim' }, { label: 'Diğer / Kendi Ekle', value: 'uni_diger' },
  ]
}

function AkademikHedefSection({ data, onConfirm }: {
  data: OnboardingData
  onConfirm: (patch: Partial<OnboardingData>) => void
}) {
  const [exam, setExam] = useState(data.targetExam)
  const [area, setArea] = useState(data.selectedArea)

  const exams = EXAMS_BY_LEVEL[data.educationLevel] ?? EXAMS_BY_LEVEL['lise']
  const areas = exam === 'OkulSinavi'
    ? okulSinaviAreas(data.educationLevel)
    : AREAS_BY_EXAM[exam] ?? null

  const dirty = exam !== data.targetExam || area !== data.selectedArea

  return (
    <div className="space-y-4 mt-3">
      <div>
        <p className="text-base font-bold mb-2" style={{ color: 'var(--text-primary)' }}>Hedef Sınav</p>
        <div className="flex flex-wrap gap-2">
          {exams.map((e) => {
            const sel = exam === e.value
            return (
              <button
                key={e.value}
                onClick={() => { setExam(e.value); setArea('') }}
                className="px-4 py-2.5 rounded-xl text-base font-bold transition-all"
                style={{
                  background: sel ? 'var(--primary)' : 'var(--bg)',
                  color: sel ? '#fff' : 'var(--text-secondary)',
                  border: `1.5px solid ${sel ? 'var(--primary)' : 'var(--border)'}`,
                }}
              >
                {sel ? '✓ ' : ''}{e.emoji} {e.name}
              </button>
            )
          })}
        </div>
      </div>

      {areas && (
        <div>
          <p className="text-base font-bold mb-2" style={{ color: 'var(--text-primary)' }}>Alanınız Nedir?</p>
          <div className="flex flex-wrap gap-2">
            {areas.map((a) => {
              const sel = area === a.value
              return (
                <button
                  key={a.value}
                  onClick={() => setArea(a.value)}
                  className="px-4 py-2.5 rounded-xl text-base font-bold transition-all"
                  style={{
                    background: sel ? '#F97316' : 'var(--bg)',
                    color: sel ? '#fff' : 'var(--text-secondary)',
                    border: `1.5px solid ${sel ? '#F97316' : 'var(--border)'}`,
                  }}
                >
                  {sel ? '✓ ' : ''}{a.label}
                </button>
              )
            })}
          </div>
        </div>
      )}

      {dirty && (
        <button
          onClick={() => onConfirm({
            targetExam: exam,
            selectedArea: area,
            strongSubjects: [],
            weakSubjects: [],
            customSubjects: [],
          })}
          className="w-full py-3.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
          style={{ background: 'var(--primary)' }}
        >
          ✅ Onayla
        </button>
      )}
    </div>
  )
}

// ─── Ders Profilim bölümü ─────────────────────────────────────────────────────

function DersProfilimSection({ data, onRequestSave }: {
  data: OnboardingData
  onRequestSave: (patch: Partial<OnboardingData>, successMsg: string) => void
}) {
  const [strong, setStrong] = useState<string[]>(data.strongSubjects)
  const [weak, setWeak] = useState<string[]>(data.weakSubjects)
  const [customSubjects, setCustomSubjects] = useState<string[]>(data.customSubjects ?? [])
  const [newSubject, setNewSubject] = useState('')
  const [dirty, setDirty] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  // Manuel ders ekleme yalnızca OkulSinavi için açık (mobil ile uyumlu).
  // Diğer sınavların dersleri sabit havuzdur, kullanıcı ekleyemez.
  const allowManualSubjects = data.targetExam === 'OkulSinavi'
  // OkulSinavi + "uni_diger" → tamamen manuel ders havuzu (sabit liste yok)
  const isFullyManual =
    data.targetExam === 'OkulSinavi' && data.selectedArea === 'uni_diger'

  const baseSubjects: SubjectData[] = useMemo(
    () => (isFullyManual ? [] : getSubjectsForExam(data.targetExam, data.selectedArea)),
    [data.targetExam, data.selectedArea, isFullyManual],
  )
  const baseNames = useMemo(() => new Set(baseSubjects.map((s) => s.name)), [baseSubjects])

  // Tüm dersler = sabit havuz + manuel eklenenler
  const allSubjects: SubjectData[] = useMemo(() => {
    const extras = customSubjects
      .filter((n) => !baseNames.has(n))
      .map((n) => ({ name: n, emoji: '📝' }) as SubjectData)
    return [...baseSubjects, ...extras]
  }, [baseSubjects, baseNames, customSubjects])

  function addCustomSubject() {
    const trimmed = newSubject.trim()
    if (!trimmed) return
    if (customSubjects.includes(trimmed) || baseNames.has(trimmed)) {
      setNewSubject('')
      return
    }
    setCustomSubjects((prev) => [...prev, trimmed])
    setNewSubject('')
    setDirty(true)
  }

  function removeCustomSubject(name: string) {
    setCustomSubjects((prev) => prev.filter((n) => n !== name))
    setStrong((prev) => prev.filter((n) => n !== name))
    setWeak((prev) => prev.filter((n) => n !== name))
    setDirty(true)
  }

  function toggle(name: string, target: 'strong' | 'weak') {
    if (target === 'strong') {
      setStrong((prev) => (prev.includes(name) ? prev.filter((s) => s !== name) : [...prev, name]))
      setWeak((prev) => prev.filter((s) => s !== name))
    } else {
      setWeak((prev) => (prev.includes(name) ? prev.filter((s) => s !== name) : [...prev, name]))
      setStrong((prev) => prev.filter((s) => s !== name))
    }
    setDirty(true)
  }

  function save() {
    // uni_diger: kullanıcı tüm dersleri manuel ekliyor → customSubjects yeterli.
    const isOkulDiger = data.targetExam === 'OkulSinavi' && data.selectedArea === 'uni_diger'
    const hasMinimum = isOkulDiger ? customSubjects.length > 0 : weak.length > 0
    if (!hasMinimum) {
      setSaveError(
        isOkulDiger
          ? 'Program oluşturmak için en az 1 ders eklemelisin.'
          : 'Program oluşturmak için en az 1 zayıf ders seçmelisin.',
      )
      return
    }
    setSaveError(null)
    setDirty(false)
    onRequestSave(
      { strongSubjects: strong, weakSubjects: weak, customSubjects },
      'Ders profilin güncellendi ✨',
    )
  }

  function chips(label: string, color: string, selected: string[], target: 'strong' | 'weak') {
    return (
      <div>
        <p className="text-base font-bold mb-2" style={{ color }}>{label}</p>
        {allSubjects.length === 0 ? (
          <p className="text-sm px-3 py-2 rounded-lg" style={{ background: 'var(--bg)', color: 'var(--text-hint)' }}>
            Önce yukarıdan ders ekle.
          </p>
        ) : (
          <div className="flex flex-wrap gap-2">
            {allSubjects.map((s) => {
              const isSel = selected.includes(s.name)
              const otherList = target === 'strong' ? weak : strong
              const disabled = otherList.includes(s.name)
              return (
                <button
                  key={s.name}
                  onClick={() => !disabled && toggle(s.name, target)}
                  disabled={disabled}
                  className="flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-base font-semibold transition-all"
                  style={{
                    background: isSel ? `${color}1A` : 'var(--bg)',
                    color: isSel ? color : 'var(--text-secondary)',
                    border: `1.5px solid ${isSel ? color : 'var(--border)'}`,
                    opacity: disabled ? 0.4 : 1,
                  }}
                >
                  <span>{s.emoji}</span> {s.name} {isSel && '✓'}
                </button>
              )
            })}
          </div>
        )}
      </div>
    )
  }

  return (
    <div className="space-y-5 mt-3">
      {/* Manuel ders ekleme yalnızca OkulSinavi'nde gösterilir — diğer sınavların
          dersleri sabit ve bellidir. */}
      {allowManualSubjects && (
      <div>
        <p className="text-base font-bold mb-2" style={{ color: 'var(--text-primary)' }}>
          ➕ Kendi Ders(ler)ini Ekle
        </p>
        <div className="flex gap-2">
          <input
            type="text"
            value={newSubject}
            onChange={(e) => setNewSubject(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addCustomSubject() } }}
            placeholder="Ders adı (örn. Fizik)"
            className="flex-1 h-11 px-4 rounded-xl text-base outline-none"
            style={{ background: 'var(--bg)', border: '1.5px solid var(--border)', color: 'var(--text-primary)' }}
          />
          <button
            onClick={addCustomSubject}
            className="h-11 w-11 rounded-xl flex items-center justify-center text-white text-xl font-bold"
            style={{ background: 'var(--primary)' }}
          >
            +
          </button>
        </div>
        {customSubjects.length > 0 && (
          <div className="mt-3">
            <p className="text-sm font-semibold mb-1.5" style={{ color: 'var(--text-secondary)' }}>
              Eklediğin Dersler
            </p>
            <div className="flex flex-wrap gap-2">
              {customSubjects.map((n) => (
                <span
                  key={n}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm"
                  style={{ background: 'var(--bg)', border: '1px solid var(--border)', color: 'var(--text-primary)' }}
                >
                  📝 {n}
                  <button
                    onClick={() => removeCustomSubject(n)}
                    className="ml-1 text-base leading-none"
                    style={{ color: 'var(--error)' }}
                    title="Kaldır"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          </div>
        )}
      </div>
      )}

      {chips('💪 Güçlü Olduğun Dersler', '#16A34A', strong, 'strong')}
      {chips('⚡ Zorlandığın Dersler', '#EA580C', weak, 'weak')}
      {saveError && (
        <div
          className="px-4 py-3 rounded-xl text-sm font-medium"
          style={{ background: '#FEF2F2', color: '#DC2626', border: '1.5px solid #FCA5A5' }}
        >
          ⚠️ {saveError}
        </div>
      )}
      {dirty && (
        <button
          onClick={save}
          className="w-full py-3.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
          style={{ background: 'var(--primary)' }}
        >
          💾 Değişiklikleri Kaydet
        </button>
      )}
    </div>
  )
}

// ─── Zaman ve Biyoritim bölümü ────────────────────────────────────────────────

function ZamanBiyoritimSection({ data, onRequestSave }: {
  data: OnboardingData
  onRequestSave: (patch: Partial<OnboardingData>, successMsg: string) => void
}) {
  const [studyType, setStudyType] = useState(data.studyType)
  const [offDays, setOffDays] = useState<number[]>(data.offDays)
  const [hasSchool, setHasSchool] = useState(data.hasWeekdaySchool)
  const [wdStart, setWdStart] = useState(data.weekdayStartTime)
  const [wdEnd, setWdEnd] = useState(data.weekdayEndTime)
  const [wdHours, setWdHours] = useState(data.weekdayStudyHours)
  const [weHours, setWeHours] = useState(data.weekendStudyHours)
  const [wdLatest, setWdLatest] = useState(data.weekdayLatestTime)
  const [weLatest, setWeLatest] = useState(data.weekendLatestTime)
  const [dirty, setDirty] = useState(false)

  function mark<T>(setter: (v: T) => void) {
    return (v: T) => { setter(v); setDirty(true) }
  }

  function toggleDay(idx: number) {
    setOffDays((prev) => (prev.includes(idx) ? prev.filter((d) => d !== idx) : [...prev, idx]))
    setDirty(true)
  }

  function save() {
    setDirty(false)
    onRequestSave({
      studyType, offDays, hasWeekdaySchool: hasSchool,
      weekdayStartTime: wdStart, weekdayEndTime: wdEnd,
      weekdayStudyHours: wdHours, weekendStudyHours: weHours,
      weekdayLatestTime: wdLatest, weekendLatestTime: weLatest,
    }, 'Çalışma düzenin güncellendi ✨')
  }

  const inputStyle = {
    background: 'var(--bg)', border: '1.5px solid var(--border)', color: 'var(--text-primary)',
  }

  return (
    <div className="space-y-5 mt-3">
      {/* Biyoritim */}
      <div>
        <p className="text-base font-bold mb-2" style={{ color: 'var(--text-primary)' }}>Biyoritim</p>
        <div className="grid grid-cols-2 gap-3">
          {[
            { v: 'sabah', emoji: '🌅', label: 'Sabah Kuşu' },
            { v: 'gece', emoji: '🌙', label: 'Gece Baykuşu' },
          ].map((o) => (
            <button
              key={o.v}
              onClick={() => mark(setStudyType)(o.v)}
              className="py-4 rounded-xl text-base font-bold transition-all"
              style={{
                background: studyType === o.v ? 'var(--primary)' : 'var(--bg)',
                color: studyType === o.v ? '#fff' : 'var(--text-secondary)',
                border: `1.5px solid ${studyType === o.v ? 'var(--primary)' : 'var(--border)'}`,
              }}
            >
              {o.emoji} {o.label}
            </button>
          ))}
        </div>
      </div>

      {/* Dinlenme günleri */}
      <div>
        <p className="text-base font-bold mb-2" style={{ color: 'var(--text-primary)' }}>Ders İstemediğin Günler</p>
        <div className="flex flex-wrap gap-2">
          {DAY_LABELS.map((d, i) => (
            <button
              key={d}
              onClick={() => toggleDay(i)}
              className="px-4 py-2.5 rounded-xl text-base font-bold transition-all"
              style={{
                background: offDays.includes(i) ? 'var(--primary)' : 'var(--bg)',
                color: offDays.includes(i) ? '#fff' : 'var(--text-secondary)',
                border: `1.5px solid ${offDays.includes(i) ? 'var(--primary)' : 'var(--border)'}`,
              }}
            >
              {d}
            </button>
          ))}
        </div>
      </div>

      {/* Hafta içi okul */}
      <div className="flex items-center justify-between">
        <span className="text-base font-bold" style={{ color: 'var(--text-primary)' }}>Hafta içi okulum var</span>
        <button
          onClick={() => mark(setHasSchool)(!hasSchool)}
          className="w-12 h-7 rounded-full transition-all relative"
          style={{ background: hasSchool ? 'var(--primary)' : 'var(--border)' }}
        >
          <span
            className="absolute top-1 w-5 h-5 rounded-full bg-white transition-all"
            style={{ left: hasSchool ? '26px' : '4px' }}
          />
        </button>
      </div>
      {hasSchool && (
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-base font-semibold mb-1" style={{ color: 'var(--text-secondary)' }}>Okul başlangıç</label>
            <input type="time" value={wdStart} onChange={(e) => mark(setWdStart)(e.target.value)}
              className="w-full h-12 px-3 rounded-xl text-base outline-none" style={inputStyle} />
          </div>
          <div>
            <label className="block text-base font-semibold mb-1" style={{ color: 'var(--text-secondary)' }}>Okul bitiş</label>
            <input type="time" value={wdEnd} onChange={(e) => mark(setWdEnd)(e.target.value)}
              className="w-full h-12 px-3 rounded-xl text-base outline-none" style={inputStyle} />
          </div>
        </div>
      )}

      {/* Çalışma saatleri */}
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="block text-base font-semibold mb-1" style={{ color: 'var(--text-secondary)' }}>Hafta içi günlük</label>
          <select value={wdHours} onChange={(e) => mark(setWdHours)(Number(e.target.value))}
            className="w-full h-12 px-3 rounded-xl text-base outline-none" style={inputStyle}>
            {Array.from({ length: 10 }, (_, i) => i + 1).map((h) => <option key={h} value={h}>{h} saat</option>)}
          </select>
        </div>
        <div>
          <label className="block text-base font-semibold mb-1" style={{ color: 'var(--text-secondary)' }}>Hafta sonu günlük</label>
          <select value={weHours} onChange={(e) => mark(setWeHours)(Number(e.target.value))}
            className="w-full h-12 px-3 rounded-xl text-base outline-none" style={inputStyle}>
            {Array.from({ length: 12 }, (_, i) => i + 1).map((h) => <option key={h} value={h}>{h} saat</option>)}
          </select>
        </div>
      </div>

      {/* En geç saatler */}
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="block text-base font-semibold mb-1" style={{ color: 'var(--text-secondary)' }}>Hafta içi en geç</label>
          <input type="time" value={wdLatest} onChange={(e) => mark(setWdLatest)(e.target.value)}
            className="w-full h-12 px-3 rounded-xl text-base outline-none" style={inputStyle} />
        </div>
        <div>
          <label className="block text-base font-semibold mb-1" style={{ color: 'var(--text-secondary)' }}>Hafta sonu en geç</label>
          <input type="time" value={weLatest} onChange={(e) => mark(setWeLatest)(e.target.value)}
            className="w-full h-12 px-3 rounded-xl text-base outline-none" style={inputStyle} />
        </div>
      </div>

      {dirty && (
        <button
          onClick={save}
          className="w-full py-3.5 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
          style={{ background: 'var(--primary)' }}
        >
          💾 Değişiklikleri Kaydet
        </button>
      )}
    </div>
  )
}

// ─── Sınav Tarihi ve Hedef bölümü ─────────────────────────────────────────────

// Mobil _goalLabels ile birebir aynı: sınav türü + alan + eğitim düzeyine göre
// hedef başlığı/alt yazı/placeholder üretir.
// Tuple: [primaryLabel, primaryHint, primarySubtitle, aytLabel, aytHint, netHint]
function goalLabels(
  exam: string,
  area: string,
  educationLevel: string,
): [string, string, string, string, string, string] {
  switch (exam) {
    case 'LGS':
      return [
        '🎓 LGS Hedefi Belirle',
        'Örn: Galatasaray Lisesi',
        'Hayalindeki liseyi ve gereken puanı gir.',
        '🎓 LGS Hedefi',
        'Örn: Kabataş Erkek Lisesi',
        'Gereken Net / Puan',
      ]
    case 'KPSS':
      return [
        '🎓 KPSS Hedefi Belirle',
        'Örn: Ankara İl Müdürlüğü Memur',
        'Hayalindeki kadroyu ve gereken neti gir.',
        '🎓 KPSS Hedefi',
        'Örn: Ankara İl Müdürlüğü Memur',
        'Gereken Net / Puan',
      ]
    case 'ALES':
      return [
        '🎓 ALES Hedefi Belirle',
        'Örn: İTÜ Yüksek Lisans',
        'Başvurmak istediğin programı gir.',
        '🎓 ALES Hedefi',
        'Örn: İTÜ Yüksek Lisans',
        'Gereken Net / Puan',
      ]
    case 'YDS':
      return [
        '🎓 YDS Hedefi Belirle',
        'Örn: 90+ puan, akademik başvuru',
        'Hedefin puanı ve amacını gir.',
        '🎓 YDS Hedefi',
        'Örn: 90+ puan',
        'Gereken Net / Puan',
      ]
    case 'Öğretmenlik':
      return [
        '🎓 AGS/ÖABT Hedefi Belirle',
        'Örn: Matematik Öğretmenliği — İstanbul',
        'Hayalindeki branş ve il tercihini gir.',
        '🎓 ÖABT Hedefi',
        'Örn: Matematik branşı',
        'Gereken Net / Puan',
      ]
    case 'OkulSinavi': {
      let goalHint: string
      let subtitle: string
      if (educationLevel === 'ortaokul') {
        goalHint = 'Örn: Kabataş Erkek Lisesi'
        subtitle = 'Hedef liseni ve gereken ortalamayı gir.'
      } else if (educationLevel === 'lise') {
        goalHint = 'Örn: ODTÜ Bilgisayar Mühendisliği'
        subtitle = 'Hedef üniversiteni ve gereken ortalamayı gir.'
      } else {
        goalHint = 'Örn: Google, Yazılım Geliştirici'
        subtitle = 'Hedef iş yerini ve gereken ortalamayı gir.'
      }
      return [
        '🏫 Not Ortalaması Hedefi',
        goalHint,
        subtitle,
        '',
        '',
        'Gereken Ortalama',
      ]
    }
    case 'YKS':
    default: {
      const aytLabel = area === 'dil' ? '🎓 YDT Hedefi Belirle' : '🎓 AYT Hedefi Belirle'
      const aytHint = area === 'dil' ? 'Örn: Boğaziçi Mütercim-Tercümanlık' : 'Örn: ODTÜ Bilgisayar'
      return [
        '🎓 TYT Hedefi Belirle',
        'Örn: Boğaziçi Üniversitesi',
        'Hayalindeki üniversite ve bölümü gir.',
        aytLabel,
        aytHint,
        'Gereken Net / Puan',
      ]
    }
  }
}

function SinavTarihiSection({ data, onSaved, onProfileChange }: {
  data: OnboardingData
  onSaved: (msg: string) => void
  onProfileChange: (d: OnboardingData) => void
}) {
  const userId = getUserId()
  const [goal, setGoal] = useState<ExamGoal>(() => (userId ? getExamGoal(userId) : { tytHedef: '', tytNet: null, aytHedef: '', aytNet: null }))
  const [examDate, setExamDate] = useState(data.examDate ? data.examDate.slice(0, 10) : '')
  const [goalDirty, setGoalDirty] = useState(false)
  const [dateDirty, setDateDirty] = useState(false)

  const exam = data.targetExam
  const isYKS = exam === 'YKS'
  const hasAyt = isYKS && ['sayisal', 'esit_agirlik', 'sozel', 'dil'].includes(data.selectedArea)

  // Mobil _goalLabels ile aynı: sınav türüne göre detaylı placeholder/açıklama
  // (primaryLabel, primaryHint, primarySubtitle, aytLabel, aytHint, netHint)
  const labels = useMemo(() => goalLabels(exam, data.selectedArea, data.educationLevel), [exam, data.selectedArea, data.educationLevel])
  const [primaryLabel, primaryHint, primarySubtitle, aytLabel, aytHint, netHint] = labels

  function saveGoal() {
    if (!userId) return
    saveExamGoal(userId, goal)
    setGoalDirty(false)
    onSaved('Hedef kaydedildi ✨')
  }

  async function saveDate() {
    if (!examDate) return
    const updated = await persistProfile({ examDate: new Date(`${examDate}T12:00:00`).toISOString() })
    if (updated) onProfileChange(updated)
    setDateDirty(false)
    onSaved('Sınav tarihi güncellendi ✅')
  }

  const daysLeft = daysUntil(examDate || data.examDate)
  const inputStyle = { background: 'var(--bg)', border: '1.5px solid var(--border)', color: 'var(--text-primary)' }

  function goalCard(
    title: string,
    subtitle: string,
    hint: string,
    netPlaceholder: string,
    hedef: string,
    net: number | null,
    setH: (v: string) => void,
    setN: (v: number | null) => void,
  ) {
    return (
      <div className="rounded-xl p-4" style={{ background: 'var(--bg)', border: '1px solid var(--border)' }}>
        <p className="text-base font-extrabold mb-1" style={{ color: 'var(--primary)' }}>{title}</p>
        <p className="text-base mb-3" style={{ color: 'var(--text-hint)' }}>{subtitle}</p>
        <input
          value={hedef}
          onChange={(e) => { setH(e.target.value); setGoalDirty(true) }}
          placeholder={`🎯 ${hint}`}
          className="w-full h-12 px-3 rounded-xl text-base outline-none mb-2.5"
          style={inputStyle}
        />
        <input
          type="number"
          value={net ?? ''}
          onChange={(e) => { setN(e.target.value ? parseFloat(e.target.value) : null); setGoalDirty(true) }}
          placeholder={`📊 ${netPlaceholder}`}
          className="w-full h-12 px-3 rounded-xl text-base outline-none"
          style={inputStyle}
        />
      </div>
    )
  }

  return (
    <div className="space-y-4 mt-3">
      {goalCard(primaryLabel, primarySubtitle, primaryHint, netHint, goal.tytHedef, goal.tytNet,
        (v) => setGoal((g) => ({ ...g, tytHedef: v })),
        (v) => setGoal((g) => ({ ...g, tytNet: v })))}

      {hasAyt && goalCard(aytLabel, primarySubtitle, aytHint, netHint, goal.aytHedef, goal.aytNet,
        (v) => setGoal((g) => ({ ...g, aytHedef: v })),
        (v) => setGoal((g) => ({ ...g, aytNet: v })))}

      {goalDirty && (
        <button
          onClick={saveGoal}
          className="w-full py-3 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
          style={{ background: 'var(--primary)' }}
        >
          Hedefi Kaydet
        </button>
      )}

      {/* Sınav tarihi */}
      <div className="rounded-xl p-4" style={{ background: 'var(--bg)', border: '1px solid var(--border)' }}>
        <div className="flex items-center justify-between mb-3">
          <p className="text-base font-extrabold" style={{ color: 'var(--text-primary)' }}>📅 Sınav Tarihi</p>
          {daysLeft !== null && (
            <span className="px-3 py-1 rounded-full text-base font-bold" style={{ background: '#EEF2FF', color: 'var(--primary)' }}>
              {daysLeft} gün
            </span>
          )}
        </div>
        <input
          type="date"
          value={examDate}
          min={new Date().toISOString().slice(0, 10)}
          onChange={(e) => { setExamDate(e.target.value); setDateDirty(true) }}
          className="w-full h-12 px-3 rounded-xl text-base outline-none"
          style={inputStyle}
        />
        {dateDirty && (
          <button
            onClick={saveDate}
            className="w-full mt-3 py-3 rounded-xl text-base font-bold text-white transition-all hover:opacity-90"
            style={{ background: 'var(--primary)' }}
          >
            Tarihi Kaydet
          </button>
        )}
      </div>
    </div>
  )
}

// ─── Ana sayfa ─────────────────────────────────────────────────────────────────

// Hızlı not ekleme modalı
function QuickNoteModal({ onClose, onAdded }: { onClose: () => void; onAdded: () => void }) {
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')

  function save() {
    if (!content.trim()) return
    const next: QuickNote[] = [
      { id: `note-${Date.now()}`, title: title.trim() || 'Not', content: content.trim(), createdAt: new Date().toISOString() },
      ...getQuickNotes(),
    ]
    saveQuickNotes(next)
    onAdded()
    onClose()
  }

  const inputStyle = { background: 'var(--bg)', border: '2px solid var(--border)', color: 'var(--text-primary)' }
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.55)' }}
      onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="w-full max-w-md rounded-3xl overflow-hidden" style={{ background: 'var(--card)' }}>
        <div className="px-7 py-5" style={{ background: 'linear-gradient(135deg, #F59E0B, #F97316)' }}>
          <h3 className="text-xl font-extrabold text-white">📝 Hızlı Not</h3>
        </div>
        <div className="p-6 space-y-4">
          <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Başlık girin..."
            className="w-full h-13 px-4 py-3 rounded-xl text-base outline-none" style={inputStyle} autoFocus />
          <textarea value={content} onChange={(e) => setContent(e.target.value)} placeholder="Aklına geleni yaz..."
            rows={4} className="w-full px-4 py-3 rounded-xl text-base outline-none resize-none" style={inputStyle} />
          <div className="flex gap-3">
            <button onClick={onClose} className="flex-1 py-3 rounded-xl text-base font-semibold"
              style={{ background: 'var(--bg)', color: 'var(--text-secondary)', border: '1.5px solid var(--border)' }}>
              İptal
            </button>
            <button onClick={save} disabled={!content.trim()}
              className="flex-1 py-3 rounded-xl text-base font-bold text-white disabled:opacity-50"
              style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}>
              ✓ Kaydet
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function ProfilePage() {
  const navigate = useNavigate()
  const [data, setData] = useState<OnboardingData | null>(null)
  const [dark, setDark] = useState(() => document.documentElement.classList.contains('dark'))
  const [toast, setToast] = useState<string | null>(null)
  const [pending, setPending] = useState<{ patch: Partial<OnboardingData>; msg: string } | null>(null)
  const [showNote, setShowNote] = useState(false)
  const [showLogout, setShowLogout] = useState(false)
  const [notesKey, setNotesKey] = useState(0)

  useEffect(() => {
    const uid = getUserId()
    if (uid) setData(getOnboardingData(uid) ?? { ...defaultOnboardingData })
  }, [])

  function showToast(msg: string) {
    setToast(msg)
    window.setTimeout(() => setToast(null), 2600)
  }

  // Profil değişikliği talebi → onay modalı açar
  function requestSave(patch: Partial<OnboardingData>, msg: string) {
    setPending({ patch, msg })
  }

  // Onaylanınca uygula: localStorage + plan yeniden üret + backend
  async function applyPending() {
    if (!pending) return
    await persistProfile(pending.patch)
    const uid = getUserId()
    if (uid) setData(getOnboardingData(uid))
    showToast(pending.msg)
    setPending(null)
  }

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

  // Ad: onboarding'de girilen ad; yoksa boş
  const displayName = (data?.name || '').trim()

  return (
    <>
      <div className="min-h-full pb-24">
        {/* Siyah header — kullanıcı adı + kademe */}
        <div
          className="px-8 sm:px-10 pt-12 pb-10 flex flex-col items-center text-center"
          style={{ background: 'linear-gradient(135deg, #1F2937 0%, #0F172A 100%)' }}
        >
          <div
            className="w-24 h-24 rounded-full flex items-center justify-center text-5xl mb-4"
            style={{ background: 'rgba(255,255,255,0.12)' }}
          >
            🎓
          </div>
          <h1 className="text-4xl font-extrabold text-white tracking-wide">
            {displayName ? displayName.toLocaleUpperCase('tr-TR') : 'ÖĞRENCİ'}
          </h1>
          <p className="text-white/60 text-lg mt-1">
            {data?.educationLevel ? (EDU_LABELS[data.educationLevel] ?? data.educationLevel) : 'Öğrenci'}
          </p>
        </div>

        <div className="px-8 sm:px-10 pt-8 space-y-5 sm:space-y-6">
          {!data ? (
            <div className="h-40 rounded-2xl animate-pulse" style={{ background: 'var(--bg)' }} />
          ) : (
            <>
              <Section icon="⚡" title="Notlarım" color="#F59E0B">
                <NotesSection key={notesKey} />
              </Section>

              <Section icon="🎓" title="Akademik Hedef" color="#4F46E5">
                <AkademikHedefSection
                  data={data}
                  onConfirm={(patch) => requestSave(patch, 'Akademik hedefin güncellendi ✨')}
                />
              </Section>

              <Section icon="📖" title="Ders Profilim" color="#2563EB">
                {/* key sınav/alan değişince re-mount tetikler — local strong/weak
                    state önceki sınavın seçimlerinden temizlenir. */}
                <DersProfilimSection
                  key={`${data.targetExam}|${data.selectedArea}`}
                  data={data}
                  onRequestSave={requestSave}
                />
              </Section>

              <Section icon="🕐" title="Zaman ve Biyoritim" color="#DB2777">
                <ZamanBiyoritimSection data={data} onRequestSave={requestSave} />
              </Section>

              <Section icon="📅" title="Sınav Tarihi ve Hedef" color="#16A34A">
                <SinavTarihiSection data={data} onSaved={showToast} onProfileChange={setData} />
              </Section>

              <Section icon="⚙️" title="Ayarlar" color="#64748B">
                <div className="space-y-3 mt-3">
                  <div className="flex items-center justify-between px-4 py-3 rounded-xl" style={{ background: 'var(--bg)' }}>
                    <div>
                      <p className="text-base font-bold" style={{ color: 'var(--text-primary)' }}>🌙 Karanlık Mod</p>
                      <p className="text-base" style={{ color: 'var(--text-hint)' }}>Koyu temaya geç</p>
                    </div>
                    <button
                      onClick={toggleDark}
                      className="w-12 h-7 rounded-full transition-all relative"
                      style={{ background: dark ? 'var(--primary)' : 'var(--border)' }}
                    >
                      <span className="absolute top-1 w-5 h-5 rounded-full bg-white transition-all" style={{ left: dark ? '26px' : '4px' }} />
                    </button>
                  </div>
                  <div className="px-4 py-3 rounded-xl" style={{ background: 'var(--bg)' }}>
                    <p className="text-base font-bold" style={{ color: 'var(--text-primary)' }}>📱 Uygulama Versiyonu</p>
                    <p className="text-base" style={{ color: 'var(--text-hint)' }}>AI Study Coach Web v1.0.0</p>
                  </div>
                </div>
              </Section>

              <div className="flex justify-center">
                <button
                  onClick={() => setShowLogout(true)}
                  className="w-1/2 py-4 rounded-2xl text-lg font-bold text-white transition-all hover:opacity-90"
                  style={{ background: '#EF4444' }}
                >
                  🚪 Çıkış Yap
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Sol-alt: Not FAB (Dashboard ile aynı konum) */}
      <button
        onClick={() => setShowNote(true)}
        className="fixed bottom-6 left-6 lg:left-[304px] w-16 h-16 rounded-full flex items-center justify-center text-3xl shadow-lg transition-all hover:opacity-90 z-40"
        style={{ background: 'linear-gradient(135deg, #F59E0B, #F97316)' }}
        title="Hızlı Not"
      >
        📝
      </button>

      {showNote && (
        <QuickNoteModal onClose={() => setShowNote(false)} onAdded={() => setNotesKey((k) => k + 1)} />
      )}
      {pending && (
        <ProgramRefreshConfirm onCancel={() => setPending(null)} onConfirm={applyPending} />
      )}
      {showLogout && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.6)' }}>
          <div className="w-full max-w-sm rounded-3xl p-7 text-center" style={{ background: 'var(--card)' }}>
            <p className="text-5xl mb-3">🚪</p>
            <h4 className="text-xl font-extrabold mb-2" style={{ color: 'var(--text-primary)' }}>Çıkış Yap</h4>
            <p className="text-base mb-6" style={{ color: 'var(--text-secondary)' }}>
              Hesabından çıkış yapmak istediğine emin misin?
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowLogout(false)}
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
        </div>
      )}
      {toast && <Toast message={toast} />}
    </>
  )
}
